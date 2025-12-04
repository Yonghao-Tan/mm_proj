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


def spu_test(matrix_y, matrix_x_h, matrix_x_w, scale1, scale0, scale_exp, mode, input_lowerbound, input_upperbound, debug=False,
             RLATENCY=2, sm_op=0, ln_op=0):  # mode 1: LayerNorm; 0: SoftMax
    size = (1, matrix_y, matrix_x_h, matrix_x_w)
    h_pad = 4 - matrix_x_h % 4
    w_pad = 4 - matrix_x_w % 4
    h_pad = h_pad if h_pad < 4 else 0
    w_pad = w_pad if w_pad < 4 else 0
    matrix_x_h_pad = matrix_x_h + h_pad
    matrix_x_w_pad = matrix_x_w + w_pad
    matrix_x_pad = matrix_x_h_pad * matrix_x_w_pad
    test_random_input = torch.randint(input_lowerbound, input_upperbound, size, dtype=torch.float)
    test_random_input_2 = test_random_input
    valid_matrix_x = matrix_x_h * matrix_x_w
    im_base_addr = 0
    om_base_addr = 0
    ifm_block_align = matrix_x_pad / 8 + 0
    ofm_block_align = matrix_x_pad / 8
    if (im_base_addr + matrix_y * ifm_block_align // 16 > 8192) or (
            om_base_addr + matrix_y * ofm_block_align // 16 > 8192):
        raise NotImplementedError("Current not support bf addr > 8191")
    if mode == 0:
        ln_div_m = 0
        ln_div_e = 0
    else:
        ln_div_m, ln_div_e = batch_frexp(torch.tensor(1 / valid_matrix_x), bit=7)
    # print(test_random_input)
    print("input range:", test_random_input.min(), test_random_input.max())
    # test_random_input = torch.tensor([[[  40.,  -60.,   -7.,   86.,   68.,   99.,  -88.,   84.,   -4.,   63.,
    #           -102.,  -94.,   50.,  -60.,   35.,  115.,   32., -107., -116.,   14.,
    #            -22.,  -61.,   46.,   77., -128.,  103.,  -38.,  114., -127.,  127.,
    #             88., -112.,  -62.,  127.,  -87.,  -46.,   39.,  109.,  -27.,  107.,
    #             40.,  -66.,   59.,   25.,   56.,   30.,  -37.,   92.,  113.,   36.,
    #              6., -119.,  -69.,    3.,   86.,   27.,  -74.,  -15.,   36.,  103.,
    #            -18.,  -64.,   46.,  -50.,   60.,   13., -107.,   64., -103.,  -77.,
    #           -118.,  -17.,  -38.,   97.,  116.,  -31.,  -70.,   12.,   63.,   39.,
    #            111.,   56.,   15.,   49., -124.,   92.,    5., -122.,  122.,   63.,
    #             -5.,  -43.,  -57.,   44.,   90.,   27., -109., -103.,   16.,   26.,
    #             75.,  -18.,  -69.,   24., -108.,   26., -101.,  -24.,  126.,  125.,
    #             28.,  -96.,  -32.,  -56., -119., -101.,  126.,  -66.,   35.,    4.,
    #             -6.,   50.,   -6.,  -59., -104.,   75.,   85.,   48.,   73.,   46.,
    #           -113.,   25.,  -27.,   73.,  -53., -110.,   40.,  -43., -128.,   99.,
    #             39.,   39.,  -76.,  -67., -101.,   85., -128.,   71.,  -67.,   56.,
    #             58.,   84.,   47.,   38.,  -98.,   93., -111.,  118.,  -31.,  107.]]]).reshape(1, 1, matrix_x_h, matrix_x_w).expand(1, matrix_y, matrix_x_h, matrix_x_w)
    cmodel_test_random_input = test_random_input.reshape(1, matrix_y, -1)
    if mode == 0:
        if sm_op == 0:  # pwl mode
            print('pwl mode')
            cmodel_results = SoftMax_CModel_torch(cmodel_test_random_input, sm_s_in=scale1, exp_s_out=scale_exp,
                                                  sm_s_out=scale0)
        else:  # lut mode
            print('lut mode')
            cmodel_results = SoftMax_CModel_torch_lut(cmodel_test_random_input, sm_s_in=scale1, exp_s_out=scale_exp,
                                                      sm_s_out=scale0)
            cmodel_test_random_input = cmodel_test_random_input.clamp(-4, 3)  # change here
        test_random_input_for_answer = cmodel_test_random_input * scale1  # Q * S = F
        test_random_input_for_answer = floor_to_nearest_bits_torch(test_random_input_for_answer, 4)
        answer = F.softmax(test_random_input_for_answer, dim=-1) / scale0
        answer = torch.clamp(answer, -128, 127)
        answer = torch.round(answer)
    elif mode == 1:
        if ln_op == 0:  # pwl mode
            print('layernorm mode')
        else:
            print('rmsnorm mode')
        cmodel_test_random_input = floor_to_nearest_bits_torch(cmodel_test_random_input, 8)
        cmodel_results = LayerNorm_CModel_torch(cmodel_test_random_input, scale0, ln_div_m, ln_div_e, ln_op=ln_op)
        if ln_op == 0:
            correct_LayerNorm = nn.LayerNorm(cmodel_test_random_input.shape[-1], elementwise_affine=False)
        else:
            correct_LayerNorm = RMSNorm(d=cmodel_test_random_input.shape[-1], p=-1, eps=2**-8, bias=False)
        answer = correct_LayerNorm(cmodel_test_random_input)
        answer = answer / scale0
        answer = torch.clamp(answer, -128, 127)
        answer = torch.round(answer)
    else:
        raise NotImplementedError("Not supported mode!")

    test_random_input = F.pad(test_random_input, (0, w_pad, 0, h_pad), 'constant', 0) # 1, Y, X_h_all, X_w_all
    test_random_input = test_random_input.reshape(1, matrix_y, matrix_x_h_pad // 4, 4, matrix_x_w_pad) # 1, Y, X_h_all // 4, 4, X_w_all
    test_random_input = test_random_input.reshape(1, matrix_y, matrix_x_h_pad // 4, 4, matrix_x_w_pad // 4, 4) # 1, Y, X_h_all // 4, 4, X_w_all // 4, 4
    test_random_input = test_random_input.permute(0, 1, 2, 4, 3, 5) # 1, Y, X_h_all // 4, X_w_all // 4, 4, 4
    test_random_input = test_random_input.reshape(1, matrix_y, matrix_x_h_pad // 4, matrix_x_w_pad // 4, 16) # 1, Y, X_h_all // 4, X_w_all // 4, 16
    test_random_input = test_random_input.reshape(1, matrix_y, matrix_x_pad) # 1, Y, X
    # pre process
    with open('./verification/FeatureMap_Bank_all.v', 'r', errors="ignore") as f:
        lines = f.readlines()
        f.close()
    for j, line in enumerate(lines):
        if '/*' in line:
            # 替换原始赋值语句
            line_new = line.replace('/*', '')
            lines[j] = line_new
            # break  # 找到并修改后立即退出循环
        if '*/' in line:
            # 替换原始赋值语句
            line_new = line.replace('*/', '')
            lines[j] = line_new
            # break  # 找到并修改后立即退出循环
    with open('./verification/FeatureMap_Bank_all.v', 'w') as f:
        f.writelines(lines)
        f.close()
    print("FeatureMap_Bank_all.v已去除注释部分")

    with open('./verification/FeatureMap_Bank_all.v', 'r') as f:
        lines = f.readlines()
        f.close()
    vivado_input = test_random_input.reshape(-1, 16, matrix_x_pad)  # matrix_y, matrix_x -> depth_bn, bn, matrix_x
    vivado_input = vivado_input.reshape(-1, 16, matrix_x_pad // 8,
                                        8)  # depth_bn, bn, matrix_x -> depth_bn, bn, depth_bw, bw
    vivado_input = vivado_input.permute(1, 0, 2,
                                        3)  # depth_bn, bn, depth_bw, bw -> bn, depth_bn, depth_bw, bw = 16, depth_bn, depth_bw, 8
    occupy_line = 0
    for bn in range(vivado_input.shape[0]):
        depth_bn_addr = 0
        for depth_bn in range(vivado_input.shape[1]):
            depth_bw_addr = 0
            for depth_bw in range(vivado_input.shape[2]):
                binary_str_fuse = ''
                # print(vivado_input[bn, depth_bn, depth_bw, :])
                for bw in range(vivado_input.shape[3]):
                    binary_str = float_to_fixed_point_signed(vivado_input[bn, depth_bn, depth_bw, bw], fixed_bits=8,
                                                             decimal_bits=8)
                    binary_str_fuse = binary_str + binary_str_fuse
                for j, line in enumerate(lines[occupy_line + 1:], start=occupy_line + 1):
                    if 'ram_%d[%d] = 64' % (bn, im_base_addr + depth_bn_addr + depth_bw_addr) in line:
                        # 替换原始赋值语句
                        lines[j] = "\tram_%d[%d] = 64'b%s;\n" % (
                        bn, im_base_addr + depth_bn_addr + depth_bw_addr, binary_str_fuse)
                        # print(lines[j])
                        occupy_line = j
                        break  # 找到并修改后立即退出循环
                depth_bw_addr += 1
            depth_bn_addr += ifm_block_align
    # 将修改后的内容写入新的Verilog文件
    with open('./verification/FeatureMap_Bank_all.v', 'w') as f:
        f.writelines(lines)
        f.close()
    print("FeatureMap_Bank_all.v文件已录入随机输入数据")

    # post process
    line_occupy = (matrix_y // 16 - 1) * ifm_block_align + matrix_x_pad // 8 + im_base_addr
    with open('./verification/FeatureMap_Bank_all.v', 'r') as f:
        lines = f.readlines()
        f.close()
    if line_occupy < 8192:
        for j, line in enumerate(lines):
            if 'ram_' in line and '[%d]' % line_occupy in line and "64'b" in line:
                # 替换原始赋值语句
                line_new = '/*' + line
                lines[j] = line_new
                # break  # 找到并修改后立即退出循环 有可能是同一行所以分两个for循环编写
        for j, line in enumerate(lines):
            if 'ram_' in line and '[%d]' % 8191 in line and "64'b" in line:
                # 替换原始赋值语句
                line_new = line + '*/'
                lines[j] = line_new
                # break  # 找到并修改后立即退出循环
    # 将修改后的内容写入新的Verilog文件
    with open('./verification/FeatureMap_Bank_all.v', 'w') as f:
        f.writelines(lines)
        f.close()
    print("FeatureMap_Bank_all.v已增加注释部分并保存")

    with open('./verification/SPU_tb.v', 'r') as f:
        lines = f.readlines()
        f.close()
    for j, line in enumerate(lines):
        if 'RLATENCY' in line:
            lines[j] = "localparam RLATENCY = %d;\n" % (RLATENCY)
            break
    for j, line in enumerate(lines):
        if 'assign SPU_OP = ' in line:
            # 替换原始赋值语句
            lines[j] = "assign SPU_OP = 1'b%d;\n" % (mode)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign spu_sm_op = ' in line:
            # 替换原始赋值语句
            lines[j] = "assign spu_sm_op = 1'b%d;\n" % (sm_op)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign spu_ln_op = ' in line:
            # 替换原始赋值语句
            lines[j] = "assign spu_ln_op = 1'b%d;\n" % (ln_op)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):  # output scale of softmax and layernorm
        if 'assign shift0 =' in line:
            # 替换原始赋值语句
            scale_0_str = float_to_fixed_point(-np.log2(scale0), fixed_bits=4, decimal_bits=4)  # output scale must > 0
            lines[j] = "assign shift0 = 4'b%s;\n" % (scale_0_str)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign shift1 =' in line:  # input scale of softmax
            # 替换原始赋值语句
            if sm_op == 0:  # pwl mode
                scale_1_str = float_to_fixed_point(-np.log2(scale1), fixed_bits=4, decimal_bits=4)
            else:  # lut mode
                scale_1_str = float_to_fixed_point_signed(np.log2(scale1), fixed_bits=4,
                                                          decimal_bits=4)  # 其实没用了 不需要他 input scale from -4~4
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
            lines[j] = "assign matrix_y = 16'd%s;\n" % (matrix_y - 1)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign matrix_x_h =' in line:
            # 替换原始赋值语句
            lines[j] = "assign matrix_x_h = 16'd%s;\n" % (matrix_x_h - 1)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign matrix_x_w =' in line:
            # 替换原始赋值语句
            lines[j] = "assign matrix_x_w = 16'd%s;\n" % (matrix_x_w - 1)
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign h_pad =' in line:
            # 替换原始赋值语句
            lines[j] = "assign h_pad = 2'd%s;\n" % h_pad  # only for tb
            break  # 找到并修改后立即退出循环
    for j, line in enumerate(lines):
        if 'assign w_pad =' in line:
            # 替换原始赋值语句
            lines[j] = "assign w_pad = 2'd%s;\n" % w_pad  # only for tb
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
    for j, line in enumerate(lines):
        if 'assign sm_lut_config =' in line:
            # 替换原始赋值语句
            sm_lut_config_str = ''
            for i in range(-4, 4):
                sm_lut_config_sub = get_sm_config(torch.tensor(i - 3), scale1)
                # print(sm_lut_config_sub)
                sm_lut_config_str = float_to_fixed_point(sm_lut_config_sub, fixed_bits=16,
                                                         decimal_bits=0) + sm_lut_config_str
            # print(sm_lut_config_str)
            lines[j] = "assign sm_lut_config = 128'b%s;\n" % (sm_lut_config_str)
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
    vivado_results = vivado_results.reshape(1, matrix_y * matrix_x_pad // 128, 16, 8)  # 1, depth, banks, dim_per_head
    vivado_results = vivado_results.permute(0, 2, 1, 3)  # 1, banks, depth, dim_per_head
    vivado_results = vivado_results.reshape(1, 16, -1, matrix_x_pad)  # 1, banks, depth, X
    vivado_results = vivado_results.permute(0, 2, 1, 3)  # 1, depth, banks, X
    vivado_results = vivado_results.reshape(1, -1, matrix_x_pad)  # 1, Y, X_all
    vivado_results = vivado_results.reshape(1, -1, matrix_x_pad // 16, 16)  # 1, Y, X_all//16, 16
    vivado_results = vivado_results.reshape(1, -1, matrix_x_pad // 16, 16)  # 1, Y, X_all//16, 16
    vivado_results = vivado_results.reshape(1, -1, matrix_x_h_pad // 4, matrix_x_w_pad // 4, 16)  # 1, Y, X_all//16, 16
    vivado_results = vivado_results.reshape(1, -1, matrix_x_h_pad // 4, matrix_x_w_pad // 4, 4, 4)  # 1, Y, X_all//16, 4, 4
    vivado_results = vivado_results.permute(0, 1, 2, 4, 3, 5)  # 1, Y, X_h_pad//4, 4, X_w_pad//4, 4
    vivado_results = vivado_results.reshape(1, -1, matrix_x_h_pad, matrix_x_w_pad)  # 1, Y, X_h+h_pad, X_w+w_pad
    vivado_results = vivado_results[:, :, :matrix_x_h, :matrix_x_w]
    vivado_results = vivado_results.reshape(1, -1, valid_matrix_x)  # 1, Y, X
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
            if sm_op == 0:
                cmodel_results_debug = SoftMax_CModel_torch(new_array, sm_s_in=scale1, exp_s_out=scale_exp,
                                                            sm_s_out=scale0, debug=True)
            else:
                cmodel_results_debug = SoftMax_CModel_torch_lut(new_array, sm_s_in=scale1, exp_s_out=scale_exp,
                                                                sm_s_out=scale0, debug=True)
            print(f"cmodel output: {cmodel_results_debug}")
            print(f"vivado output: {vivado_results[0, unique_indices]}")
            print(f"difference: {diff[0, unique_indices]}")
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
            cmodel_results_debug = LayerNorm_CModel_torch(new_array, scale0, ln_div_m, ln_div_e, ln_op=ln_op, debug=True)
            print(f"cmodel output: {cmodel_results_debug}")
            print(f"vivado output: {vivado_results[0, unique_indices]}")
            print(f"difference: {diff[0, unique_indices]}")

    hw_mae, hw_mpe, comp_mae, comp_mpe = compute_metrics(vivado_results, cmodel_results, answer, size)
    return hw_mae, hw_mpe, comp_mae, comp_mpe


if __name__ == "__main__":
    print("Loop test of Special PU Starts")
    mode = 0  # mode 0: SoftMax; 1: LayerNorm

    sm_op = 0  # for Softmax, 0: 8bit w/ rowmax & pwl; 1: 3bit w/o rowmax & lut
    sm_op_str = 'pwl' if sm_op == 0 else 'lut'
    ln_op = 0 # for Norm, 0: LayerNorm; 1: RMSNorm
    ln_op_str = 'layernorm' if sm_op == 0 else 'rmsnorm'

    # matrix configuration for softmax
    matrix_y_list_sm = [1024]
    matrix_x_list_sm = [(7, 7), (15, 16), (4, 60)]  # from segformer_b0 quantization version, with 512 x 480
    if sm_op == 0:
        scales_list_sm = [(2 ** -3, 2 ** -5, 2 ** -12), (2 ** -4, 2 ** -4, 2 ** -11), (2 ** -3, 2 ** -4, 2 ** -10),
                          (2 ** -3, 2 ** -5, 2 ** -9), (2 ** -3, 2 ** -6, 2 ** -9), (2 ** -6, 2 ** -2, 2 ** -11),
                          (2 ** -4, 2 ** -4, 2 ** -10), (2 ** -3, 2 ** -4, 2 ** -10), (2 ** -3, 2 ** -6, 2 ** -10),
                          (2 ** -2, 2 ** -6, 2 ** -10), (2 ** -1, 2 ** -7, 2 ** -10),
                          (2 ** -0, 2 ** -7, 2 ** -10)]  # from segformer_b0 quantization version, with 512 x 480
        # scales_list_sm = [(2 ** -5, 2 ** -3, 2 ** -8), (2 ** -4, 2 ** -3, 2 ** -7), (2 ** -3, 2 ** -2, 2 ** -7),
        #                   (2 ** -4, 2 ** -3, 2 ** -8), (2 ** -5, 2 ** -3, 2 ** -8), (2 ** -3, 2 ** -3, 2 ** -7),
        #                   (2 ** -3, 2 ** -5, 2 ** -7), (2 ** -4, 2 ** -4, 2 ** -8), (2 ** -4, 2 ** -4, 2 ** -7),]  # SR
        # (scale1, scale_exp, scale0) 这里用数值进行设置，test内部会按照shift形式 即scale1->shift1
        matrix_y_list_sm = [1024]
        matrix_x_list_sm = [(4, 3), (3, 16), (7, 8), (16, 15), (16, 13), (16, 16), (29, 32)]  # from segformer_b0 quantization version, with 512 x 480
        scales_list_sm = [(2**-3,2**-6,2**-12)]
    else:
        scales_list_sm = [(2 ** 3, 2 ** -21, 2 ** -11), (2 ** 2, 2 ** -11, 2 ** -10), (2 ** 2, 2 ** -10, 2 ** -12),
                          (2 ** 1, 2 ** -8, 2 ** -10),
                          (2 ** 2, 2 ** -8, 2 ** -11), (2 ** 2, 2 ** -10, 2 ** -11), (2 ** 1, 2 ** -8, 2 ** -10), (2 ** 2, 2 ** -11, 2 ** -10),
                          (2 ** 1, 2 ** -8, 2 ** -10), (2 ** 1, 2 ** -8, 2 ** -9)]
        # matrix_y_list_sm = [512]
        # matrix_x_list_sm = [(16, 16)]  # from segformer_b0 quantization version, with 512 x 480
        # scales_list_sm = [(2 ** 3, 2 ** -21, 2 ** -11)]

    # matrix configuration for layernorm
    matrix_y_list_ln = [1024]
    matrix_x_list_ln = [(4, 8), (8, 8), (8, 16), (8, 20), (16, 16), (64, 32)]  # from segformer_b0 quantization version, with 512 x 480
    scales_list_ln = [2 ** -11, 2 ** -7, 2 ** -6, 2 ** -5, 2 ** -4, 2 ** -3, 2 ** -2]  # from segformer_b0 quantization version, with 512 x 480
    matrix_y_list_ln = [256]
    matrix_x_list_ln = [(4, 3), (3, 16), (7, 8), (16, 15), (16, 13), (16, 16), (29, 32)] # from segformer_b0 quantization version, with 512 x 480
    scales_list_ln = [2 ** -5] # from segformer_b0 quantization version, with 512 x 480

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
        for (matrix_x_h, matrix_x_w) in matrix_x_list:
            if mode == 0:
                for (scale1, scale_exp, scale0) in scales_list_sm:
                    if sm_op == 0:
                        hw_mae_tmp, hw_mpe_tmp, comp_mae_tmp, comp_mpe_tmp = spu_test(matrix_y, matrix_x_h, matrix_x_w, scale1,
                                                                                      scale0, scale_exp, mode, -128,
                                                                                      128,
                                                                                      debug=False, RLATENCY=RLATENCY)
                    else:
                        hw_mae_tmp, hw_mpe_tmp, comp_mae_tmp, comp_mpe_tmp = spu_test(matrix_y, matrix_x_h, matrix_x_w, scale1,
                                                                                      scale0, scale_exp, mode, -5,
                                                                                      5,
                                                                                      debug=False, RLATENCY=RLATENCY,
                                                                                      sm_op=sm_op)  # change here
                    hw_mae_list.append(hw_mae_tmp.item())
                    hw_mpe_list.append(hw_mpe_tmp.item())
                    comp_mae_list.append(comp_mae_tmp.item())
                    comp_mpe_list.append(comp_mpe_tmp.item())
            else:
                for scale0 in scales_list_ln:
                    scale1, scale_exp = 1, 1
                    hw_mae_tmp, hw_mpe_tmp, comp_mae_tmp, comp_mpe_tmp = spu_test(matrix_y, matrix_x_h, matrix_x_w, scale1, scale0,
                                                                                  scale_exp, mode, -128, 128,
                                                                                  # for random, upperbound is ), [low, upp), therefore should plus 1
                                                                                  debug=False, RLATENCY=RLATENCY, ln_op=ln_op)
                    hw_mae_list.append(hw_mae_tmp.item())
                    hw_mpe_list.append(hw_mpe_tmp.item())
                    comp_mae_list.append(comp_mae_tmp.item())
                    comp_mpe_list.append(comp_mpe_tmp.item())

    result_cnt = 0
    for i in range(len(matrix_y_list)):
        for (matrix_x_h, matrix_x_w) in matrix_x_list:
            h_pad = 4 - matrix_x_h % 4
            w_pad = 4 - matrix_x_w % 4
            h_pad = h_pad if h_pad < 4 else 0
            w_pad = w_pad if w_pad < 4 else 0
            matrix_x = (matrix_x_h + h_pad) * (matrix_x_w + w_pad)
            if mode == 0:
                for (scale1, scale0, scale_exp) in scales_list_sm:
                    scale1 = np.log2(scale1)
                    scale0 = np.log2(scale0)
                    scale_exp = np.log2(scale_exp)
                    if sm_op == 0:
                        t = 1 + 28 * matrix_y_list[i] / 16 + (3 * matrix_y_list[i] / 16) * (
                                    matrix_x / 8 - 1) + (matrix_y_list[i] / 16) * (RLATENCY - 2)
                    else:
                        t = 1 + 25 * matrix_y_list[i] / 16 + (2 * matrix_y_list[i] / 16) * (
                                    matrix_x / 8 - 1) + (matrix_y_list[i] / 16) * (RLATENCY - 2)
                    print(
                        f"sm_op = {sm_op_str}, matrix_y = {matrix_y_list[i]}, matrix_x_h = {matrix_x_h}, matrix_x_w = {matrix_x_w}, scale1 = {scale1}, scale0 = {scale0}, "
                        f"scale_exp = {scale_exp} | hw & answer mae: {hw_mae_list[result_cnt]:.2e}; hw & answer mpe: {hw_mpe_list[result_cnt]:.2e}; "
                        f"hw & cmodel mae: {comp_mae_list[result_cnt]:.2e}; hw & cmodel mpe: {comp_mpe_list[result_cnt]:.2e}; "
                        f"rd latency = {RLATENCY}; time = {int(t)} cycles")
                    result_cnt += 1
            else:
                for scale0 in scales_list_ln:
                    scale0 = np.log2(scale0)
                    t = 1 + 37 * matrix_y_list[i] / 16 + (2 * matrix_y_list[i] / 16) * (matrix_x / 8 - 1) + (matrix_y_list[i] / 16) * (RLATENCY - 2)
                    print(
                        f"ln_op = {ln_op_str}, matrix_y = {matrix_y_list[i]}, matrix_x_h = {matrix_x_h}, matrix_x_w = {matrix_x_w}, scale0 = {scale0} | hw & answer mae: {hw_mae_list[result_cnt]:.2e}; "
                        f"hw & answer mpe: {hw_mpe_list[result_cnt]:.2e}; hw & cmodel mae: {comp_mae_list[result_cnt]:.2e}; hw & cmodel mpe: {comp_mpe_list[result_cnt]:.2e}; "
                        f"rd latency = {RLATENCY}; time = {int(t)} cycles")
                    result_cnt += 1
    print("Loop test of Special PU Ends")
