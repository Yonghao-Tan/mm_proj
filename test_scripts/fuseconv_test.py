import torch
import torch.nn as nn
import torch.nn.functional as F

in_channels = 8
out_channels = 4
groups = 1
input = torch.randn((1, 3, 3, in_channels))

ln = nn.LayerNorm(in_channels)
ln.weight.data = torch.randn(ln.weight.shape)
ln.bias.data = torch.randn(ln.bias.shape)
conv = nn.Conv2d(in_channels, out_channels, 2, groups=groups)
ln_out_ans = ln(input)
conv_out_ans = conv(ln_out_ans.permute(0, 3, 1, 2))

ln_weight_expand = ln.weight.reshape(groups, in_channels // groups).repeat_interleave(out_channels // groups, dim=0).unsqueeze(-1).unsqueeze(-1)
print(ln.weight.shape, conv.weight.shape, ln_weight_expand.shape)
fuse_weight = ln_weight_expand * conv.weight
ln_bias_expand = ln.bias.reshape(groups, in_channels // groups).repeat_interleave(out_channels // groups, dim=0).unsqueeze(-1).unsqueeze(-1)
fuse_bias = conv.bias + torch.sum(ln_bias_expand * conv.weight, dim=(1,2,3)).reshape(conv.bias.shape[0])
ln_out = F.layer_norm(input, normalized_shape=input.shape[-1:])
conv_out = F.conv2d(ln_out.permute(0, 3, 1, 2), fuse_weight, fuse_bias, groups=groups)

print(conv_out_ans - conv_out)
# print(conv_out)