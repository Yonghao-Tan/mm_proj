import torch
from Cmodels_SPU_Yonghao import batch_frexp
def round_to_nearest_bits_torch(x, decimal_bits):
    """

    :param x: floating input
    :param decimal_bits: bits that the input should reserve
    :return: the formatted input with specific decimal bits
    """
    scaled_value = x * (2 ** decimal_bits)
    rounded_value = torch.round(scaled_value)  # very important
    result = rounded_value / (2 ** decimal_bits)
    y = result
    y_grad = x
    return (y - y_grad).detach() + y_grad

# definition of scale: x_fp32 = q_int8 * scale
q_in = torch.arange(-4, 4, 1) - 3
scale_list = []
for i in range(-4, 5):
    scale_list.append(2**(i))
dict = {}
exp_quan_upperbound = 2 ** 8 - 1
for i in range(len(scale_list)):
    print(f"scale, int-8 value, exp value:")
    s = torch.tensor(scale_list[i])
    lut_max = torch.tensor(1.0)
    s_out = (lut_max / exp_quan_upperbound)
    s_out = torch.pow(2, torch.round(torch.log2(s_out))) # 可能导致刚好越界,256->255，但是影响应该极小
    for j in range(q_in.shape[0]):
        q = q_in[j]
        exp_long = torch.exp(q * s)
        exp_lut = round_to_nearest_bits_torch(exp_long.clamp(0, 1 - 2 ** -16), 16)
        print(f"{s}, {q+3}, {exp_lut}")
    print()
