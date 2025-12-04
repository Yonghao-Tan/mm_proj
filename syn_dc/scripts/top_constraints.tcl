# clocks setup

# 600MHz clk
create_clock [get_ports core_clk] -name core_clk -period 1.66 -waveform {0 0.83}
# 500MHz clk
#create_clock [get_ports core_clk] -name core_clk -period 2.0 -waveform {0 1.0}
# 400MHz clk
#create_clock [get_ports core_clk] -name core_clk -period 2.5 -waveform {0 1.25}
# 250MHz clk
#create_clock [get_ports core_clk] -name core_clk -period 4.0 -waveform {0 2.0}
# 200MHz clk
#create_clock [get_ports core_clk] -name core_clk -period 5.0 -waveform {0 2.5}

set_clock_uncertainty 0.2 core_clk
set_clock_transition 0.1 core_clk
set_ideal_network core_clk

# I/O constraints
set_fanout_load 0.1 [all_outputs]
set_load 0.5 [all_outputs]
set_input_transition 0.1 [all_inputs]
set_drive 0 core_clk

set_input_delay 0.1 -clock core_clk [remove_from_collection [all_inputs] [get_ports "core_clk"]]
set_output_delay 0.1 -clock core_clk [all_outputs]

# Other
set_max_area 0

set_max_transition 0.25 [current_design]

# ideal networks
set_ideal_network [get_ports rst_n]
#set_ideal_network [get_ports cfg_rst_n]

