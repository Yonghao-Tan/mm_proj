import torch
import torch.nn.functional as F
import numpy as np
from torch import nn
import decimal
from decimal import Decimal

class RMSNorm(nn.Module):
    def __init__(self, d, p=-1., eps=1e-8, bias=False):
        """
            Root Mean Square Layer Normalization
        :param d: model size
        :param p: partial RMSNorm, valid value [0, 1], default -1.0 (disabled)
        :param eps:  epsilon value, default 1e-8
        :param bias: whether use bias term for RMSNorm, disabled by
            default because RMSNorm doesn't enforce re-centering invariance.
        """
        super(RMSNorm, self).__init__()

        self.eps = eps
        self.d = d
        self.p = p
        self.bias = bias

        self.scale = nn.Parameter(torch.ones(d))
        self.register_parameter("scale", self.scale)

        if self.bias:
            self.offset = nn.Parameter(torch.zeros(d))
            self.register_parameter("offset", self.offset)

    def forward(self, x):
        if self.p < 0. or self.p > 1.:
            norm_x = x.norm(2, dim=-1, keepdim=True)
            d_x = self.d
        else:
            partial_size = int(self.d * self.p)
            partial_x, _ = torch.split(x, [partial_size, self.d - partial_size], dim=-1)

            norm_x = partial_x.norm(2, dim=-1, keepdim=True)
            d_x = partial_size

        rms_x = norm_x * d_x ** (-1. / 2)
        x_normed = x / (rms_x + self.eps)

        if self.bias:
            return self.scale * x_normed + self.offset

        return self.scale * x_normed

def floor_to_nearest_bits_torch(x, decimal_bits):
    """

    :param x: floating input
    :param decimal_bits: bits that the input should reserve
    :return: the formatted input with specific decimal bits
    """
    scaled_value = x * (2 ** decimal_bits)
    rounded_value = torch.floor(scaled_value)  # very important
    result = rounded_value / (2 ** decimal_bits)
    y = result
    y_grad = x
    return (y - y_grad).detach() + y_grad

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

def batch_frexp(inputs, bit=8):
    """
    Decompose the scaling factor into mantissa and twos exponent.

    Parameters:
    ----------
    inputs: scaling factor
    return: (mantissa, exponent)
    """
    shape_of_input = inputs.size()

    # transform the input to be a 1-d tensor
    inputs = inputs.view(-1)

    output_m, output_e = np.frexp(inputs.cpu().detach().numpy())

    tmp_m = []
    for m in output_m:
        int_m_shifted = int(Decimal(m * (2 ** bit)).quantize(Decimal('1'), rounding=decimal.ROUND_HALF_UP))
        tmp_m.append(int_m_shifted)
    output_m = np.array(tmp_m)

    output_e = 1.0 * bit - output_e

    return torch.from_numpy(output_m).to(inputs.device).view(shape_of_input), \
        torch.from_numpy(output_e).to(inputs.device).view(shape_of_input)

def LN_hw_long_divider(numer, denom, denom_decimal_bits, output_decimal_bits):
    if torch.any(denom == 0):
        denom[denom == 0] = torch.tensor(1.0).to(numer.device)
        # denom = torch.ones_like(denom).to(numer.device)
    denom = denom.expand_as(numer)
    # Create a tensor for the quotient
    quotient = torch.empty_like(numer)

    # Handle positive and negative values
    positive_mask = (numer >= 0) & (denom >= 0)
    negative_mask = (numer < 0) & (denom < 0)
    pos_neg_mask = (numer >= 0) & (denom < 0)
    neg_pos_mask = (numer < 0) & (denom >= 0)

    quotient[positive_mask] = numer[positive_mask] / denom[positive_mask]
    quotient[negative_mask] = -numer[negative_mask] / -denom[negative_mask]
    quotient[pos_neg_mask] = numer[pos_neg_mask] / -denom[pos_neg_mask]
    quotient[neg_pos_mask] = -numer[neg_pos_mask] / denom[neg_pos_mask]

    # Apply rounding function (assuming round_to_nearest_bits_torch is defined elsewhere)
    quotient = floor_to_nearest_bits_torch(quotient, output_decimal_bits)
    quotient[positive_mask] = quotient[positive_mask]
    quotient[negative_mask] = quotient[negative_mask]
    quotient[pos_neg_mask]  = -quotient[pos_neg_mask]
    quotient[neg_pos_mask]  = -quotient[neg_pos_mask]
    return quotient


def LayerNorm_CModel_torch(ln_q_in, ln_s_out, ln_div_m, ln_div_e, ln_op=0, eps=2**-8, debug=False): # EPS根据hw需要改变
    """

    :param ln_q_in: quantization fixed point number input
    :param ln_s_out: output quantization scale
    :param ln_div_m: dyadic representation of matrix_x (m)
    :param ln_div_e: dyadic representation of matrix_x (e)
    :param eps: eps for solving divide-by-zero issue, add before sqrt unit
    :return: initial LayerNorm result with quantization, after output scale shifting
    """
    if debug: print(f"qin: {ln_q_in}")
    sum_x = torch.sum(ln_q_in, dim=-1, keepdim=True, dtype=torch.float64)
    sum_x = floor_to_nearest_bits_torch(sum_x, 0)
    mean = floor_to_nearest_bits_torch(sum_x * ln_div_m / (2 ** ln_div_e), 2)
    # mean = LN_hw_long_divider(sum_x, torch.tensor(ln_q_in.shape[-1]).to(ln_q_in.device), denom_decimal_bits=0, output_decimal_bits=2)
    mean_x_2 = torch.pow(mean, 2)
    mean_x_2 = floor_to_nearest_bits_torch(mean_x_2, 4)
    x_2 = torch.pow(ln_q_in, 2)
    x_2 = floor_to_nearest_bits_torch(x_2, 0)
    sum_x_2 = torch.sum(x_2, dim=-1, keepdim=True, dtype=torch.float64)
    sum_x_2 = floor_to_nearest_bits_torch(sum_x_2, 0)
    # e_x_2 = LN_hw_long_divider(sum_x_2, torch.tensor(ln_q_in.shape[-1]).to(ln_q_in.device), denom_decimal_bits=0,
    #                       output_decimal_bits=4)
    e_x_2 = floor_to_nearest_bits_torch(sum_x_2 * ln_div_m / (2 ** ln_div_e), 4)
    var = e_x_2 - mean_x_2 if ln_op == 0 else e_x_2
    if debug: print("mean:", mean[0, 0, 0], "sum_x_2:", sum_x_2[0, 0, 0], "e_x_2:", e_x_2[0, 0, 0], "mean_x_2:", mean_x_2[0, 0, 0])
    var = floor_to_nearest_bits_torch(var.float(), 4)
    if debug: print("var:",var[0,0,0])
    std = torch.sqrt(var + eps)
    std = floor_to_nearest_bits_torch(std, 4)
    if debug: print("std:",std[0,0,0])
    reci = LN_hw_long_divider(torch.ones_like(ln_q_in).to(ln_q_in.device), std, denom_decimal_bits=4, output_decimal_bits=14)
    if debug: print("reci: %.20f" % reci[0,0,0])
    # for i in range(reci.shape[1]):
    #     print("%.20f" % reci[0,i,0])
    initial_norm_f = reci * (ln_q_in - mean) if ln_op == 0 else reci * ln_q_in
    if debug: print("init_f_full:\n",initial_norm_f[0,0])
    initial_norm_f = floor_to_nearest_bits_torch(initial_norm_f, 12)
    if debug: print("init_f_12:\n",initial_norm_f[0,0])
    initial_norm_q = initial_norm_f / ln_s_out
    initial_norm_q = torch.clamp(initial_norm_q, -128, 127)
    initial_norm_q = torch.round(initial_norm_q).float()
    return initial_norm_q


def binary_to_decimal(binary_str, decimal_point=4):
    """

    :param binary_str: string input of binary representation
    :param deciaml_point: from left to right, e.g. if ('1000', decimal_point=0), the result is 0.5
    :return: floating output
    """
    point_index = binary_str.find('.')
    if point_index == -1:
        first_three = binary_str[:decimal_point]
        remaining = binary_str[decimal_point:]
        binary_str = first_three + '.' + remaining
        point_index = binary_str.find('.')

    # 提取整数部分和小数部分
    integer_part = binary_str[:point_index] if point_index != -1 else binary_str
    decimal_part = binary_str[point_index + 1:] if point_index != -1 else ''
    if integer_part != '': integer_decimal = int(integer_part, 2)

    decimal_decimal = 0
    for i in range(len(decimal_part)):
        if decimal_part[i] == '1':
            decimal_decimal += 2 ** (-i - 1)

    if integer_part != '':
        result = integer_decimal + decimal_decimal
    else:
        result = decimal_decimal

    return result


def binary_to_decimal_signed(binary_str, decimal_point=4, binary_bits=8):
    """

    :param binary_str: string input of binary representation
    :param decimal_point: from left to right
    :param binary_bits: total bits of input binary_str
    :return: floating output
    """
    is_negative = False
    if binary_str[0] == '1':
        is_negative = True
        string_binary_str = list(binary_str)
        for i in range(len(string_binary_str)):
            if string_binary_str[i] == '0':
                string_binary_str[i] = '1'
            else:
                string_binary_str[i] = '0'
        size = len(string_binary_str)
        carry = True
        for i in range(size):
            if string_binary_str[size - 1 - i] == '0' and carry == False:
                continue
            elif string_binary_str[size - 1 - i] == '0' and carry == True:
                string_binary_str[size - 1 - i] = '1'
                carry = False
            elif string_binary_str[size - 1 - i] == '1' and carry == False:
                continue
            else:
                string_binary_str[size - 1 - i] = '0'
                carry = True
        binary_str = ''.join(string_binary_str)
        # print(binary_str)
    integer_decimal = int(binary_str[1:], 2)  # 取的是1开始的，没有取符号位所以decimal point不要算符号位在内
    result = integer_decimal * (2 ** (decimal_point - binary_bits))  # decimal_point = 0: 0.xxxx_xxxx; 1: x.xxx_xxxx
    real_result = -result if is_negative else result
    if binary_str == '10000000': real_result = -128 # special case
    return float(real_result)



def float_to_fixed_point_signed(number, fixed_bits=16, decimal_bits=4):
    """

    :param number: input signed floating number
    :param fixed_bits: total output bits
    :param decimal_bits: bits for the integer part
    :return: signed string binary output
    """
    # 将浮点数乘以 2^12，即左移 12 位
    fixed_point = int(number * 2 ** (fixed_bits - decimal_bits))

    # 限制整数部分的位数为 4 位
    fixed_point = min(fixed_point, 2 ** (fixed_bits - 1) - 1)  # 2^15 - 1 是 15 位二进制的最大正整数
    fixed_point = max(fixed_point, -2 ** (fixed_bits - 1))  # -2^15 是 15 位二进制的最小负整数

    # 将定点数转换为二进制表示
    binary = bin(fixed_point & ((2 ** fixed_bits) - 1))  # 限制为 16 位二进制
    binary_str = binary[2:].zfill(fixed_bits)  # 去掉前缀 '0b' 并补齐至 16 位二进制

    return binary_str


def float_to_fixed_point(number, fixed_bits=16, decimal_bits=4):
    """

    :param number: input floating number
    :param fixed_bits: total output bits
    :param decimal_bits: bits for the integer part
    :return: string binary output
    """
    # 将浮点数乘以 2^12，即左移 12 位
    fixed_point = int(number * 2 ** (fixed_bits - decimal_bits))

    # 限制整数部分的位数为 4 位
    fixed_point = min(fixed_point, 2 ** (fixed_bits) - 1)  # 2^15 - 1 是 15 位二进制的最大正整数
    fixed_point = max(fixed_point, 0)  # -2^15 是 15 位二进制的最小负整数

    # 将定点数转换为二进制表示
    # binary = bin(fixed_point & 0xFFFF)  # 限制为 16 位二进制
    binary = bin(fixed_point & ((2 ** fixed_bits) - 1))
    binary_str = binary[2:].zfill(fixed_bits)  # 去掉前缀 '0b' 并补齐至 16 位二进制
    return binary_str


def floor_to_nearest_bits(x, decimal_bits):
    """

    :param x: floating input
    :param decimal_bits: bits that the input should reserve
    :return: the formatted input with specific decimal bits
    """
    scaled_value = x * (2 ** decimal_bits)
    rounded_value = np.floor(scaled_value)  # very important
    result = rounded_value / (2 ** decimal_bits)
    return result

def round_to_nearest_bits(x, decimal_bits):
    """

    :param x: floating input
    :param decimal_bits: bits that the input should reserve
    :return: the formatted input with specific decimal bits
    """
    scaled_value = x * (2 ** decimal_bits)
    rounded_value = np.round(scaled_value)  # very important
    result = rounded_value / (2 ** decimal_bits)
    return result



def SoftMax_CModel_torch(sm_q_in, sm_s_in, exp_s_out, sm_s_out, debug=False):
    """

    :param sm_q_in: fix point input
    :param sm_s_in: quantization scale of x
    :param exp_s_out: quantization scale of exp
    :param sm_s_out: quantization scale of output
    :param q_upperbound: positive upperbound of quantization
    :return: 8 bit output
    """
    if debug: print(f"qin: {sm_q_in}")
    sm_q_in_max, _ = torch.max(sm_q_in, dim=-1, keepdim=True)
    if debug: print(f"qmax: {sm_q_in.max()}")
    if debug: print(f"expu A output: {spu_exp(sm_q_in - sm_q_in_max, sm_s_in, exp_s_out, debug=True)}")
    sum_exp = torch.sum(spu_exp(sm_q_in - sm_q_in_max, sm_s_in, exp_s_out), dim=-1)
    if debug: print(f"sum_exp: {sum_exp}")
    reci_sum_exp = LN_hw_long_divider(torch.ones_like(sum_exp), (sum_exp), denom_decimal_bits=0, output_decimal_bits=20)
    if debug: print("reci: %.20f" % reci_sum_exp)
    expu_out_b = spu_exp(sm_q_in - sm_q_in_max, sm_s_in, exp_s_out)
    if debug: print(f"expu B output: {expu_out_b}")
    x_out = reci_sum_exp.unsqueeze(-1).expand_as(expu_out_b) * expu_out_b
    x_out = floor_to_nearest_bits_torch(x_out, 12)
    if debug: print(f"x_out_pre: {x_out}")
    x_out = x_out / sm_s_out
    x_out = torch.clamp(x_out, -128, 127)
    x_out = torch.round(x_out)
    return x_out

def spu_exp_pwl(input, sm_s_in, debug=False):
    device = input.device
    seg_point = torch.tensor([-5.5, -3.3125, -2.375, -1.5625, -1.375, -0.75, -0.3125]).to(device)  # 1, 3, 4
    coeff = torch.tensor([0.0, 0.015625, 0.0625, 0.140625, 0.234375, 0.359375, 0.59375, 0.859375]).to(device)  # 1, 1, 6
    intercept = torch.tensor([0.0, 0.078125, 0.234375, 0.421875, 0.578125, 0.734375, 0.90625, 1.0]).to(
        device)  # 1, 1, 6
    seg_point = floor_to_nearest_bits_torch(seg_point, 4)
    coeff = floor_to_nearest_bits_torch(coeff, 6)
    intercept = floor_to_nearest_bits_torch(intercept, 6)

    seg_point_scale = seg_point / sm_s_in  # 1, 3, 4
    coeff_scale = coeff  # 1, 1, 6
    intercept_scale = intercept / sm_s_in  # 1, 1, 6

    seg_point_scale = floor_to_nearest_bits_torch(seg_point_scale, 0)  # 1, 7, 0 ?
    intercept_scale = floor_to_nearest_bits_torch(intercept_scale, 6)  # 1, 1, 6
    if debug:
        print("seg_point_scale:", seg_point_scale)
        print("coeff_scale:", coeff_scale)
        print("intercept_scale:", intercept_scale)

    pwl_func = torch.zeros_like(input).to(device)
    mask = input.lt(seg_point_scale[0])
    pwl_func = torch.where(mask, intercept_scale[0] + coeff_scale[0] * input, pwl_func)
    for i in range(1, len(seg_point_scale)):
        mask = input.ge(seg_point_scale[i - 1]) & input.lt(seg_point_scale[i])  # >=, <
        pwl_func = torch.where(mask, intercept_scale[i] + coeff_scale[i] * input, pwl_func)
    mask = input.ge(seg_point_scale[-1])
    pwl_func = torch.where(mask, intercept_scale[-1] + coeff_scale[-1] * input, pwl_func)
    pwl_func = pwl_func.clamp(0, 511)
    if debug:
        print(pwl_func)
    return pwl_func


def pwl_exp_gqa(input, sm_s_in):
    pwl_func = spu_exp_pwl(input, sm_s_in)
    return (pwl_func - torch.exp(input * sm_s_in) / sm_s_in).detach() + torch.exp(input * sm_s_in) / sm_s_in

def spu_exp(input, sm_s_in, exp_s_out, debug=False):
    pwl_func = spu_exp_pwl(input, sm_s_in, debug)
    pwl_func = pwl_func / exp_s_out
    pwl_func = torch.clamp(pwl_func, 0, 255)
    pwl_func = torch.round(pwl_func)
    return pwl_func

def SoftMax_CModel_torch_lut(sm_q_in, sm_s_in, exp_s_out, sm_s_out, debug=False):
    """

    :param sm_q_in: fix point input
    :param sm_s_in: quantization scale of x
    :param exp_s_out: quantization scale of exp
    :param sm_s_out: quantization scale of output
    :param q_upperbound: positive upperbound of quantization
    :return: 8 bit output
    """
    if debug: print(f"qin: {sm_q_in}")
    sm_q_in = torch.clamp(sm_q_in, -4, 3) # change here
    q_upper_bound = torch.tensor(3.0)
    if debug: print(f"qin-qmax: {sm_q_in - q_upper_bound}")
    if debug: print(f"expu A output: {lut_exp(sm_q_in - q_upper_bound, sm_s_in, exp_s_out)}")
    sum_exp = torch.sum(lut_exp(sm_q_in - q_upper_bound, sm_s_in, exp_s_out), dim=-1)
    if debug: print(f"sum_exp: {sum_exp}")
    reci_sum_exp = LN_hw_long_divider(torch.ones_like(sum_exp), (sum_exp), denom_decimal_bits=0, output_decimal_bits=20)
    if debug: print("reci: %.20f" % reci_sum_exp)
    expu_out_b = lut_exp(sm_q_in - q_upper_bound, sm_s_in, exp_s_out)
    if debug: print(f"expu B output: {expu_out_b}")
    x_out = reci_sum_exp.unsqueeze(-1).expand_as(expu_out_b) * expu_out_b
    x_out = floor_to_nearest_bits_torch(x_out, 12)
    if debug: print(f"x_out_pre: {x_out}")
    x_out = x_out / sm_s_out
    x_out = torch.clamp(x_out, -128, 127)
    x_out = torch.round(x_out)
    return x_out


def lut_exp(sm_q_in, sm_s_in, exp_s_out):
    exp_long = torch.exp(sm_q_in * sm_s_in)
    exp_lut = round_to_nearest_bits_torch(exp_long.clamp(0, 1 - 2 ** -16), 16)
    pwl_func = exp_lut / exp_s_out
    pwl_func = torch.clamp(pwl_func, 0, 255)
    exp_out = torch.round(pwl_func)
    return exp_out

def get_sm_config(q_in, sm_s_in):
    s = sm_s_in
    f = q_in * s # fp = q * s
    f_exp = torch.exp(f)
    # q_exp = f_exp / s
    # q_exp = q_exp.clamp(0, 16 - 2 ** (-12))
    q_exp = f_exp
    # q_exp_lut = round_to_nearest_bits_torch(q_exp, 12) # 12 may have the same acc as 16, since no diff after quan
    q_exp_lut = round_to_nearest_bits_torch(q_exp, 16) # 12 may have the same acc as 16, since no diff after quan
    # print(q_in, sm_s_in, q_exp_lut)
    return q_exp_lut

if __name__ == '__main__':
    sum_x_2 = torch.tensor(925957.0, dtype=torch.float64)
    ln_div_m = torch.tensor(102.0, dtype=torch.float64)
    print(sum_x_2 * ln_div_m)
    print(925957 * 102)
    ln_div_e = torch.tensor(14.0)
    print(floor_to_nearest_bits_torch(sum_x_2 * ln_div_m / (2 ** ln_div_e), 4))

