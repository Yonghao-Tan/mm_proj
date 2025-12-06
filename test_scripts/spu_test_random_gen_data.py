from Cmodels_SPU_Yonghao import *
import subprocess
import torch
import torch.nn as nn

torch.set_printoptions(8)


def read_txt(point=2, signed=False):
    with open("./vivado_proj/output_spu.txt", "r") as file:
        lines = file.readlines()
        file.close()
    decimals = []
    for line in lines:
        binary = line.strip()
        if signed:
            decimal = binary_to_decimal_signed(binary, point)
        else:
            decimal = binary_to_decimal(binary, point)
        decimals.append(decimal)
    decimals = np.array(decimals)  # 转换为 NumPy 数组
    return decimals


def read_txt_new():
    decimals = []
    try:
        with open("./vivado_proj/output_spu.txt", 'r') as file:
            # 逐行读取文件内容，并将每一行的整数添加到列表中
            for line in file:
                decimals.append(int(line.strip()))
    except FileNotFoundError:
        print(f"文件未找到")
    except ValueError:
        print("文件内容包含非整数行")
    decimals = np.array(decimals)
    return decimals


def run_vivado_tcl_script(script_file):
    # 构造运行Vivado脚本的命令
    cmd = ["vivado", "-mode", "tcl", "-source", script_file]
    # 执行命令并等待完成
    subprocess.run(cmd, shell=True)


def compute_metrics(results1, results2, answer, size):
    th = 1e-10

    hw_diff = results1 - answer
    cmodel_diff = results2 - answer
    comp_diff = results2 - results1

    hw_mae = torch.mean(torch.abs(hw_diff))
    hw_mse = torch.mean(hw_diff ** 2)
    valid_count_hw = torch.sum(torch.abs(answer) >= th)
    hw_mpe_sum = torch.sum(torch.abs(hw_diff[answer >= th]) / torch.abs(answer[answer >= th]))

    cmodel_mae = torch.mean(torch.abs(cmodel_diff))
    cmodel_mse = torch.mean(cmodel_diff ** 2)
    valid_count_cmodel = torch.sum(torch.abs(answer) >= th)
    cmodel_mpe_sum = torch.sum(torch.abs(cmodel_diff[answer >= th]) / torch.abs(answer[answer >= th]))

    comp_mae = torch.mean(torch.abs(comp_diff))
    comp_mse = torch.mean(comp_diff ** 2)
    valid_count_comp = torch.sum(torch.abs(results1) >= th)
    comp_mpe_sum = torch.sum(torch.abs(comp_diff[results1 >= th]) / torch.abs(results1[results1 >= th]))

    hw_mpe = hw_mpe_sum / valid_count_hw

    cmodel_mpe = cmodel_mpe_sum / valid_count_cmodel

    comp_mpe = comp_mpe_sum / valid_count_comp

    print_metrics('hw', hw_mae, hw_mse, hw_mpe, valid_count_hw, np.prod(size))
    print_metrics('cmodel', cmodel_mae, cmodel_mse, cmodel_mpe, valid_count_cmodel, np.prod(size))
    print_metrics("python model's difference with hw model", comp_mae, comp_mse, comp_mpe, valid_count_comp,
                  np.prod(size))

    return hw_mae, hw_mpe, comp_mae, comp_mpe


def print_metrics(name, mae, mse, mpe, valid_count, total_size):
    print(f'{name} mae: {mae:.1e}')
    print(f'{name} mse: {mse:.1e}')
    print(f'{name} mpe: {mpe:.1e}')
    print(f'valid_count: {valid_count} total: {total_size}')

def write_tensor_to_hex(tensor, filepath, im_base_addr=0, max_addr=0):
    """
    Converts a 3D bfloat16 tensor to a hex file with pre-padding and offset writing.
    It creates the full buffer content in memory and writes it to the file at once to avoid seek errors.
    """
    hex_line_zeros = '0' * (2 * 4)  # 32 bits = 8 hex chars
 
    # Step 1: Create the full buffer content in a list of strings in memory.
    buffer_lines = [hex_line_zeros] * max_addr

    # Step 2: Prepare the tensor data to be written.
    # Reshape to combine the first two dimensions, giving number of rows for hex file
    num_rows = tensor.shape[1] * tensor.shape[2]
    tensor_2d = tensor.reshape(num_rows, 4)
    
    data_lines = []
    for i in range(tensor_2d.shape[0]):
        row = tensor_2d[i]
        # Cast to int8 to get the integer values (e.g. 123.0 -> 123)
        int8_repr = row.to(torch.int8).numpy()
        # # Convert each 8-bit int to a 2-char hex string and join them
        # Reverse the order of bytes for little-endian representation if needed by hardware
        hex_strings = [format(val & 0xFF, '02x') for val in int8_repr][::-1]
        hex_line = "".join(hex_strings)
        data_lines.append(hex_line)

    # Step 3: Overwrite the zero lines in the list with the actual data at the correct offset.
    if im_base_addr + len(data_lines) > len(buffer_lines):
        raise ValueError(f"Data with size {len(data_lines)} at offset {im_base_addr} exceeds max_addr {max_addr}")
    
    buffer_lines[im_base_addr : im_base_addr + len(data_lines)] = data_lines

    # Step 4: Write the complete, final buffer content to the file.
    with open(filepath, 'w') as f:
        f.write('\n'.join(buffer_lines) + '\n')

def spu_test(matrix_y, matrix_x, scale1, scale0, scale_exp, mode, input_lowerbound, input_upperbound, debug=False,
             RLATENCY=2):  # mode 1: LayerNorm; 0: SoftMax
    size = (1, matrix_y, matrix_x)
    test_random_input = torch.randint(input_lowerbound, input_upperbound, size, dtype=torch.float)
    test_random_input_2 = test_random_input
    im_base_addr = 0
    om_base_addr = 0
    ifm_block_align = matrix_x // 4
    ofm_block_align = matrix_x // 4
    if (im_base_addr + matrix_y * ifm_block_align // 16 > 8192) or (
            om_base_addr + matrix_y * ofm_block_align // 16 > 8192):
        raise NotImplementedError("Current not support bf addr > 8191")
    if mode == 0:
        ln_div_m = 0
        ln_div_e = 0
    else:
        ln_div_m, ln_div_e = batch_frexp(torch.tensor(1 / matrix_x), bit=7) 
    # print(test_random_input)
    print("input range:", test_random_input.min(), test_random_input.max())
    # test_random_input = torch.tensor([[[  71.,   -6.,   67.,  110.,  -35.,  127., -125.,  -64.]]]).reshape(1, 1, matrix_x).expand(1, matrix_y, matrix_x)
    cmodel_test_random_input = test_random_input.reshape(1, matrix_y, -1)
    if mode == 0:
        cmodel_results = SoftMax_CModel_torch(cmodel_test_random_input, sm_s_in=scale1, exp_s_out=scale_exp,
                                                sm_s_out=scale0)
        test_random_input_for_answer = cmodel_test_random_input * scale1  # Q * S = F
        test_random_input_for_answer = floor_to_nearest_bits_torch(test_random_input_for_answer, 4)
        answer = F.softmax(test_random_input_for_answer, dim=-1) / scale0
        answer = torch.clamp(answer, -128, 127)
        answer = torch.round(answer)
    elif mode == 1:
        cmodel_test_random_input = floor_to_nearest_bits_torch(cmodel_test_random_input, 8)
        cmodel_results = LayerNorm_CModel_torch(cmodel_test_random_input, scale0, ln_div_m, ln_div_e, ln_op=0)
        correct_LayerNorm = nn.LayerNorm(cmodel_test_random_input.shape[-1], elementwise_affine=False)
        answer = correct_LayerNorm(cmodel_test_random_input)
        answer = answer / scale0
        answer = torch.clamp(answer, -128, 127)
        answer = torch.round(answer)
    else:
        raise NotImplementedError("Not supported mode!")

    vivado_input = test_random_input.reshape(1, matrix_y, matrix_x // 4, 4)
    max_addr = max(im_base_addr + matrix_y * ifm_block_align, om_base_addr + matrix_y * ofm_block_align)
    write_tensor_to_hex(vivado_input, './test_scripts/data/lbuf_input.hex', im_base_addr=im_base_addr, max_addr=max_addr)


    with open('./verification/SPU_tb.v', 'r') as f:
        lines = f.readlines()
        f.close()
    for j, line in enumerate(lines):
        if 'RLATENCY' in line:
            lines[j] = "localparam RLATENCY = %d;\n" % (RLATENCY)
            break
    for j, line in enumerate(lines):
        if 'assign spu_op = ' in line:
            # 替换原始赋值语句
            lines[j] = "assign spu_op = 1'b%d;\n" % (mode)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign shift0 =' in line:
            # 替换原始赋值语句
            scale_0_str = float_to_fixed_point(-np.log2(scale0), fixed_bits=4, decimal_bits=4)  # output scale must > 0
            lines[j] = "assign shift0 = 4'b%s;\n" % (scale_0_str)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign shift1 =' in line:  # input scale of softmax
            # 替换原始赋值语句
            scale_1_str = float_to_fixed_point(-np.log2(scale1), fixed_bits=4, decimal_bits=4)
            lines[j] = "assign shift1 = 4'b%s;\n" % (scale_1_str)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):  # output scale of exp in softmax
        if 'assign shift2 =' in line:
            # 替换原始赋值语句
            scale_2_str = float_to_fixed_point(-np.log2(scale_exp), fixed_bits=5, decimal_bits=5)  # exp scale must > 0
            lines[j] = "assign shift2 = 5'b%s;\n" % (scale_2_str)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign ln_div_m =' in line:
            # 替换原始赋值语句
            lines[j] = "assign ln_div_m = 7'd%d;\n" % (ln_div_m)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign ln_div_e =' in line:
            # 替换原始赋值语句
            lines[j] = "assign ln_div_e = 5'd%d;\n" % (ln_div_e)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign matrix_y =' in line:
            # 替换原始赋值语句
            lines[j] = "assign matrix_y = 16'd%s;\n" % matrix_y
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign matrix_x =' in line:
            # 替换原始赋值语句
            lines[j] = "assign matrix_x = 16'd%s;\n" % matrix_x
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign im_base_addr =' in line:
            # 替换原始赋值语句
            lines[j] = "assign im_base_addr = 16'd%s;\n" % (im_base_addr)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign om_base_addr =' in line:
            # 替换原始赋值语句
            lines[j] = "assign om_base_addr = 16'd%s;\n" % (om_base_addr)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign im_block_align =' in line:
            # 替换原始赋值语句
            ifm_block_align_str = float_to_fixed_point(ifm_block_align, fixed_bits=12, decimal_bits=12)
            lines[j] = "assign im_block_align = 12'b%s;\n" % (ifm_block_align_str)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign om_block_align =' in line:
            # 替换原始赋值语句
            ofm_block_align_str = float_to_fixed_point(ofm_block_align, fixed_bits=12, decimal_bits=12)
            lines[j] = "assign om_block_align = 12'b%s;\n" % (ofm_block_align_str)
            break  # 找到并修改后立即退出循环
    # 将修改后的内容写入新的Verilog文件
    with open('./verification/SPU_tb.v', 'w') as f:
        f.writelines(lines)
        f.close()
    print("SPU_tb.v已成功修改并保存")

    # 运行Tcl脚本
    run_vivado_tcl_script("./vivado_proj/Special_PU/script.tcl")
    # print(cmodel_results)
    vivado_results = read_txt_new()

    vivado_results = torch.tensor(vivado_results)
    vivado_results = vivado_results.reshape(1, matrix_y, matrix_x // 4, 4)  # 1, depth, banks, dim_per_head
    vivado_results = vivado_results.reshape(1, matrix_y, matrix_x)  # 1, Y, X
    if debug:
        print("correct_results:\n", answer)
        print("cmodel_results:\n", cmodel_results)
        print("hw_results:\n", vivado_results)
        print("comparison:\n", cmodel_results - vivado_results)
    if mode == 0:
        diff = cmodel_results - vivado_results
        non_zero_indices = np.where(diff != 0)
        unique_indices = np.unique(non_zero_indices[1])
        exact_wrong = np.unique(non_zero_indices[2])
        is_identical = len(unique_indices) == 0
        if not is_identical:
            print("Detect difference between vivado simulation with cmodel. Start debug process:")
            # exact_wrong = exact_wrong[0]
            # print(f"wrong entry: {exact_wrong}")
            unique_indices = unique_indices[0]
            print(f"Block: {unique_indices % 16}. Test group: {unique_indices // 16}")
            extracted_data = test_random_input[:, unique_indices, :]
            new_array = extracted_data.reshape(1, 1, -1)
            print(test_random_input_2[0,unique_indices])
            cmodel_results_debug = SoftMax_CModel_torch(new_array, sm_s_in=scale1, exp_s_out=scale_exp,
                                                            sm_s_out=scale0, debug=True)
            print(f"cmodel output: {cmodel_results_debug}")
            print(f"vivado output: {vivado_results[0, unique_indices]}")
            print(f"difference: {diff[0, unique_indices]}")
            exit()
    elif mode == 1:
        diff = cmodel_results - vivado_results
        non_zero_indices = np.where(diff != 0)
        unique_indices = np.unique(non_zero_indices[1])
        exact_wrong = np.unique(non_zero_indices[2])
        is_identical = len(unique_indices) == 0
        if not is_identical:
            print("Detect difference between vivado simulation with cmodel. Start debug process:")
            # exact_wrong = exact_wrong[0]
            # print(f"wrong entry: {exact_wrong}")
            unique_indices = unique_indices[0]
            print(f"Block: {unique_indices % 16}. Test group: {unique_indices // 16}")
            extracted_data = test_random_input[:, unique_indices, :]
            new_array = extracted_data.reshape(1, 1, -1)
            cmodel_results_debug = LayerNorm_CModel_torch(new_array, scale0, ln_div_m, ln_div_e, ln_op=0, debug=True)
            print(f"cmodel output: {cmodel_results_debug}")
            print(f"vivado output: {vivado_results[0, unique_indices]}")
            print(f"difference: {diff[0, unique_indices]}")

    hw_mae, hw_mpe, comp_mae, comp_mpe = compute_metrics(vivado_results, cmodel_results, answer, size)
    return hw_mae, hw_mpe, comp_mae, comp_mpe


if __name__ == "__main__":
    print("Loop test of Special PU Starts")
    mode = 1  # mode 0: SoftMax; 1: LayerNorm

    # matrix configuration for softmax
    matrix_y_list_sm = [1, 3, 5]
    matrix_x_list_sm = [8, 16, 32]  # from segformer_b0 quantization version, with 512 x 480
    scales_list_sm = [(2 ** -3, 2 ** -5, 2 ** -12),
                        (2 ** -3, 2 ** -5, 2 ** -9),
                        (2 ** -2, 2 ** -6, 2 ** -10),
                        (2 ** -0, 2 ** -7, 2 ** -10)]
                     
    # matrix configuration for layernorm
    matrix_y_list_ln = [1, 3, 5]
    matrix_x_list_ln = [8, 16, 32]  # from segformer_b0 quantization version, with 512 x 480
    scales_list_ln = [2 ** -9, 2 ** -6,  2 ** -4, 2 ** -2]  # from segformer_b0 quantization version, with 512 x 480

    if mode == 0:
        matrix_y_list = matrix_y_list_sm
        matrix_x_list = matrix_x_list_sm
    else:
        matrix_y_list = matrix_y_list_ln
        matrix_x_list = matrix_x_list_ln

    RLATENCY = 2  # 对于buffer中ren延时的设置，默认为2
    hw_mae_list = []
    hw_mpe_list = []  # vivado simulation和正确结果进行对比的mpe
    comp_mae_list = []  # vivado simulation的结果和cmodel结果对比
    comp_mpe_list = []
    for matrix_y in matrix_y_list:
        for matrix_x in matrix_x_list:
            if mode == 0:
                for (scale1, scale_exp, scale0) in scales_list_sm:
                    hw_mae_tmp, hw_mpe_tmp, comp_mae_tmp, comp_mpe_tmp = spu_test(matrix_y, matrix_x, scale1,
                                                                                    scale0, scale_exp, mode, -128,
                                                                                    128,
                                                                                    debug=False, RLATENCY=RLATENCY)
                    hw_mae_list.append(hw_mae_tmp.item())
                    hw_mpe_list.append(hw_mpe_tmp.item())
                    comp_mae_list.append(comp_mae_tmp.item())
                    comp_mpe_list.append(comp_mpe_tmp.item())
            else:
                for scale0 in scales_list_ln:
                    scale1, scale_exp = 1, 1
                    hw_mae_tmp, hw_mpe_tmp, comp_mae_tmp, comp_mpe_tmp = spu_test(matrix_y, matrix_x, scale1, scale0,
                                                                                  scale_exp, mode, -128, 128,
                                                                                  # for random, upperbound is ), [low, upp), therefore should plus 1
                                                                                  debug=False, RLATENCY=RLATENCY)
                    hw_mae_list.append(hw_mae_tmp.item())
                    hw_mpe_list.append(hw_mpe_tmp.item())
                    comp_mae_list.append(comp_mae_tmp.item())
                    comp_mpe_list.append(comp_mpe_tmp.item())

    result_cnt = 0
    for i in range(len(matrix_y_list)):
        for matrix_x in matrix_x_list:
            if mode == 0:
                for (scale1, scale0, scale_exp) in scales_list_sm:
                    scale1 = np.log2(scale1)
                    scale0 = np.log2(scale0)
                    scale_exp = np.log2(scale_exp)
                    t = 1 + 28 * matrix_y_list[i] / 16 + (3 * matrix_y_list[i] / 16) * (
                                matrix_x / 8 - 1) + (matrix_y_list[i] / 16) * (RLATENCY - 2)
                    print(
                        f"softmax: matrix_y = {matrix_y_list[i]}, matrix_x = {matrix_x}, scale1 = {scale1}, scale0 = {scale0}, "
                        f"scale_exp = {scale_exp} | hw & answer mae: {hw_mae_list[result_cnt]:.2e}; hw & answer mpe: {hw_mpe_list[result_cnt]:.2e}; "
                        f"hw & cmodel mae: {comp_mae_list[result_cnt]:.2e}; hw & cmodel mpe: {comp_mpe_list[result_cnt]:.2e}; "
                        f"rd latency = {RLATENCY}; time = {int(t)} cycles")
                    result_cnt += 1
            else:
                for scale0 in scales_list_ln:
                    scale0 = np.log2(scale0)
                    t = 1 + 37 * matrix_y_list[i] / 16 + (2 * matrix_y_list[i] / 16) * (matrix_x / 8 - 1) + (matrix_y_list[i] / 16) * (RLATENCY - 2)
                    print(
                        f"layernorm: matrix_y = {matrix_y_list[i]}, matrix_x = {matrix_x}, scale0 = {scale0} | hw & answer mae: {hw_mae_list[result_cnt]:.2e}; "
                        f"hw & answer mpe: {hw_mpe_list[result_cnt]:.2e}; hw & cmodel mae: {comp_mae_list[result_cnt]:.2e}; hw & cmodel mpe: {comp_mpe_list[result_cnt]:.2e}; "
                        f"rd latency = {RLATENCY}; time = {int(t)} cycles")
                    result_cnt += 1
    print("Loop test of Special PU Ends")
