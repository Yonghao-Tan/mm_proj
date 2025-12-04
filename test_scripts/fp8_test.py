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
q_in = torch.arange(-8, 8, 1) - 7
scale_list = []
for i in range(-4, 4):
    scale_list.append(2**(i))
dict = {}
exp_quan_upperbound = 2 ** 8 - 1
for i in range(len(scale_list)):
    print(f"scale, int-8 value, exp value:")
    s = torch.tensor(scale_list[i])
    lut_max = torch.tensor(1.0)
    for j in range(q_in.shape[0]):
        q = q_in[j]
        exp_long = torch.exp(q * s)
        fp8_e = torch.floor(torch.log2(1 / exp_long))
        fp8_m_org = exp_long / (2 ** -fp8_e)
        fp8_m = round_to_nearest_bits_torch(fp8_m_org, 5)
        print(fp8_e, fp8_m_org, fp8_m, exp_long, fp8_m * (2 ** -fp8_e))
        exp_lut = round_to_nearest_bits_torch(exp_long.clamp(0, 1 - 2 ** -16), 16)
        print(f"{s}, {q+3}, {exp_lut}")
    print()

bit = 7
test_a = torch.tensor(0.9876)
fp8_e_a = torch.floor(torch.log2(1 / test_a))
fp8_m_org_a  = test_a / (2 ** -fp8_e_a)
fp8_m_a  = round_to_nearest_bits_torch(fp8_m_org_a, bit)
fp8_a = fp8_m_a * (2 ** -fp8_e_a)

test_b = torch.tensor(0.03)
fp8_e_b = torch.floor(torch.log2(1 / test_b))
fp8_m_org_b  = test_b / (2 ** -fp8_e_b)
fp8_m_b = round_to_nearest_bits_torch(fp8_m_org_b, bit)
fp8_b = fp8_m_b * (2 ** -fp8_e_b)

test_c = test_a + test_b
fp8_e_c = torch.floor(torch.log2(1 / test_c))
fp8_m_org_c  = test_c / (2 ** -fp8_e_c)
fp8_m_c = round_to_nearest_bits_torch(fp8_m_org_c, bit)
fp8_c = fp8_m_c * (2 ** -fp8_e_c)
print(fp8_a + fp8_b, fp8_c)