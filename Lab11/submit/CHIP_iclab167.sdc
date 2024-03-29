###################################################################
set sdc_version 1.7

#define your sdc here
create_clock -name "CLK" -add -period 6 -waveform {0 3} [get_ports clk]
set_propagated_clock [all_clocks]

set_clock_gating_check -setup 0
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports rst_n]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports in_valid]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[0]}]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[1]}]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[2]}]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[3]}]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[4]}]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[5]}]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[6]}]
set_input_delay -clock [get_clocks CLK] -add_delay 3 [get_ports {in_image[7]}]

set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports out_valid]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[0]}]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[1]}]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[2]}]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[3]}]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[4]}]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[5]}]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[6]}]
set_output_delay -clock [get_clocks CLK] -add_delay 1.0 [get_ports {out_image[7]}]


