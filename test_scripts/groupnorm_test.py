import decimal
from fractions import Fraction
from decimal import Decimal
import torch
import numpy as np

from Cmodels_SPU_Yonghao import *


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


denom = torch.tensor(160.0)
a = torch.tensor(1 / denom)
sum = torch.tensor(879.0)
m, e = batch_frexp(a, bit=7)
dyadic = sum * m / (2 ** e)
dyadic = round_to_nearest_bits_torch(dyadic, 4)
print(m, e)
print("dyadic:", dyadic)
divider_result = LN_hw_long_divider(sum, denom, denom_decimal_bits=0, output_decimal_bits=4)
print("divider:", divider_result)
print("ans:", sum * a)
torch.set_printoptions(8)
for i in range(8, 1024, 8):
    m, e = batch_frexp(torch.tensor(1/i), bit=7)

N = 128
C = 32
x = torch.rand(1, N, C) # B, N, C
groups = 4
# 分成 4 个 group
# 其余设定和之前相同
gn = nn.GroupNorm(num_groups=groups, num_channels=C, eps=0, affine=True)
gn.weight.data = torch.randn(gn.weight.shape)
gn.bias.data = torch.randn(gn.bias.shape)
x0 = x.permute(1, 2, 0) # B, N, C -> N, C, B ?
official_gn = gn(x0).permute(2, 0, 1)

B, N, C = x.shape
c = C // groups
x1 = x.reshape(B, N, groups, C // groups) # B, N, C -> B, N, G, c
for i in range(groups):
    ln = nn.LayerNorm(x1.shape[-1], eps=0, elementwise_affine=True)
    ln.weight.data = gn.weight[i*c:(i+1)*c]
    ln.bias.data = gn.bias[i*c:(i+1)*c]
    x1[:,:,i,:] = ln(x1[:,:,i,:])
my_gn = x1.reshape(B, N, C) # B, N, G, c -> B, N, C
print(my_gn-official_gn)