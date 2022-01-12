onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Clock
add wave -noupdate /tb_rtl_top_arc4/DUT/CLOCK_50
add wave -noupdate -divider {Top Module RDY and EN}
add wave -noupdate /tb_rtl_top_arc4/DUT/en
add wave -noupdate /tb_rtl_top_arc4/DUT/rdy
add wave -noupdate /tb_rtl_top_arc4/DUT/key_valid
add wave -noupdate /tb_rtl_top_arc4/DUT/mask
add wave -noupdate -divider {DBL Crack}
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/en
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/rdy
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/rst_n
add wave -noupdate -divider {DBL Crack State}
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/double_crack_state
add wave -noupdate -divider {Key Valid}
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/key_valid_1
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/key_valid_2
add wave -noupdate -divider KEY
add wave -noupdate -radix hexadecimal /tb_rtl_top_arc4/DUT/dc/key_1
add wave -noupdate -radix hexadecimal /tb_rtl_top_arc4/DUT/dc/key_2
add wave -noupdate -divider {PT MEM}
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/c1/pt1/altsyncram_component/m_default/altsyncram_inst/mem_data
add wave -noupdate /tb_rtl_top_arc4/DUT/dc/c2/pt1/altsyncram_component/m_default/altsyncram_inst/mem_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 2} {15 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {12 ps} {34 ps}
