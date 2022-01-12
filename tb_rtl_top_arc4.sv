`timescale 1 ps / 1 ps
module tb_rtl_top_arc4();
logic clk, err;
logic [3:0] KEY;
logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
logic [9:0] SW, LEDR;

top_arc4 DUT (
            clk, KEY, SW,
            HEX0, HEX1, HEX2,
            HEX3, HEX4, HEX5,
            LEDR
          );
initial forever begin
    clk = ! clk; #1;
end

initial begin
$readmemh("memh1.memh", DUT.ct.altsyncram_component.m_default.altsyncram_inst.mem_data);
        KEY[3] = 1; clk = 0; #5;
        KEY[3] = 0; err=0; #15;
        KEY[3] = 1; 
        #260000;

end
endmodule