version 0312:
softmax和layernorm的padding输出置零

version 0203:
增加了softmax和layernorm的支持output shift范围

version 0131:
修改layernorm最大支持ch数为2048
修改pad_en和ln_div_m ln_div_e以应对时序问题

version 0120:
修改了所有除法器stage_list定义，定为一拍完成2bit
修改了延时公式
修改了表格中OP表达
新增了表格中SRAM读写情况

version 0110:
修改了延时公式
替换ASIC SRAM，频率625M下DC面积51W

version 0109:
新增了layernorm对padding的处理
spu_test_read_data.py因为对实际数据padding处理咱未修改，所以暂时无法使用
修改了cache的enable错误

version 0107:
softmax的第一次exp结果写回cache，第二次取出后直接和分母的倒数相乘，优化了周期数
测试中发现layernorm的python model中，可能因为float32乘法中浮点数运算舍入误差带来问题，将sum_x和sum_x_2的计算改为float64

version 0106:
新增了softmax对padding的处理

version 0103:
更改parameter书写规范
优化3bit lut通过指令传入LUT数据
更改了指令集，共256位，于./doc的表格中，指令集截图和IO截图在review ppt中也有，timing公式在ppt P4
新增对rmsnorm的支持，另外本身layernorm通过channel操作可以支持groupnorm，实际需要讨论
初步DC面积：46W

version 0102:
将layernorm中计算均值的两个除法器改为dyadic形式，即mean=sum*m>>e，减少15%面积，对指令有更改
新增利用模型实际推理时摘取的数据进行更实际的测试脚本spu_test_real_data.py，严谨验证

version 1231:
新增cache buffer，最多支持4096有效token数目
更改了scale_shift的位数为4以节省资源，三个都是，但是编译器无需更改，只需要内部截取4位即可，对指令有更改
支持softmax 3bit lut方式

version 1221:
修改了layernorm的output时遇到大于7的initial norm值，目前可支持-32~31

version 1218:
修改了layernorm的output quan里面-127.x被判定为出界的错误

version 1217:
更改Exp近似版本为线性近似
修复code review的大部分问题，暂未增加额外buffer
另外修改了tb和test script使得仿真速度加快

Special PU项目文件组织形式：
根目录下
./doc -> 有关的所有文档
./lib -> 工艺库，为空文件夹以免占存储空间
./rtl -> SPU项目rtl代码
./syn_dc -> dc的filelist和constraint等
./test_scripts -> python cmodel以及python自动进行vivado仿真 & cmodel等结果对比脚本
./verification -> SPU测试代码
./vivado_proj -> vivado项目存放位置

./test_scripts目录下
Cmodels_SPU_Yonghao.py 为SPU的cmodel函数集合
spu_test_random_gen_data.py 随机样本测试自动脚本，附有一些注释。环境要求：torch, subprocess
spu_test_real_data.py 从模型用数据集推理实际摘取数据后的测试自动脚本，附有一些注释。
./layernorm_data, ./softmax_data, ./softmax_data_lut 是从模型摘录的实际输入数据

./vivado_proj目录下
Special_PU目录是自动脚本会调用的项目目录，也是rtl存放的根目录
Special_PU_simu是手动debug时可以用vivado打开的项目，为了方便同时进行自动脚本仿真和手动测试（若只用一个项目会造成读写冲突），simu中所有的rtl都来自于Special_PU下对应文件，如修改则会一并修改，只有一份文件。
两个proj的rtl都位于主目录./rtl下
两个proj的仿真文件都位于主目录./verification下

谢谢阅读！