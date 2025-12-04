define_design_lib work -path ./work

set cache_read ""
set cache_write ""

set_host_options -max_cores 16
set compile_disable_hierarchical_inverter_opt true
set verilogout_no_tri true

set TOP special_pu
set OUTPUTS_DIR ./outputs
set REPORTS_DIR ./reports

source ./scripts/lib.tcl

analyze -vcs "-sverilog +define+ASIC -f ./scripts/syn_filelist.f"
elaborate $TOP

current_design $TOP
link

check_design > ${REPORTS_DIR}/${TOP}_check_design.rpt

source scripts/top_constraints.tcl

set clk_list [get_object_name [all_clocks]]
foreach from_clk $clk_list {
	foreach to_clk $clk_list {
		group_path -name ${from_clk}_${to_clk} -critical 0.5 -from [get_clocks $from_clk] -to [get_clocks $to_clk]
	}
}

set_wire_load_mode top

set_fix_multiple_port_nets -all -buf

uniquify
#ungroup -flatten -all

#compile_ultra -no_autoungroup -no_seq_output_inversion -gate_clock
compile_ultra -no_autoungroup -no_seq_output_inversion

change_name -rule verilog -hier

check_timing > ${REPORTS_DIR}/${TOP}_check_timing.rpt
report_area -hier -nosplit > ${REPORTS_DIR}/${TOP}_area.rpt
report_qor > ${REPORTS_DIR}/${TOP}_qor.rpt
report_constraint -all_violators > ${REPORTS_DIR}/${TOP}_violators.rpt
report_timing -delay max -max_paths 100 -nosplit > ${REPORTS_DIR}/${TOP}_max_timing.rpt
report_timing -delay min -max_paths 100 > ${REPORTS_DIR}/${TOP}_min_timing.rpt

# power estimation
#set power_default_toggle_rate 0.1
#set power_default_static_probability 0.1
#set_switching_activity -period 5.0 -toggle 0.5 -static 0.05 [all_inputs]
#set_case_analysis 1 [get_ports rst_n]
echo $power_default_toggle_rate
echo $power_default_static_probability

report_power > ${REPORTS_DIR}/${TOP}_power.rpt
#report_power_calculation > ${REPORTS_DIR}/${TOP}_power_calc.rpt
# ==============================

#write_file -f ddc -hier -o ${OUTPUTS_DIR}/${TOP}.ddc
write_file -f verilog -hier -o ${OUTPUTS_DIR}/${TOP}.v
#write_sdf -version 1.0 ${OUTPUTS_DIR}/${TOP}.sdf
write_sdc ${OUTPUTS_DIR}/${TOP}.sdc

#exit
