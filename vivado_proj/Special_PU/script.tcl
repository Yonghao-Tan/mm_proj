# 打开 Vivado 项目
open_project ./vivado_proj/Special_PU/Special_PU.xpr

# 添加源文件（如果需要）
# add_files ./rtl/my_design.v

# 设定仿真顶层模块
set_property top SPU_tb [current_fileset]
# 编译工程
update_compile_order

# 设置仿真运行时环境
launch_simulation -quiet
run 10000000ns
# 设置仿真时钟和其他仿真参数
# 在这里添加设置仿真时钟和其他仿真参数的代码

exit
# 启动仿真
# run_simulation

# 等待仿真结束
# wait_on_simulation

# 保存波形文件
# write_waveform -format vcd ./simulation_result.vcd

# 退出 Vivado
# exit
