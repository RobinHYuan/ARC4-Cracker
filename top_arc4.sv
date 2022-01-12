module top_arc4(input logic CLOCK_50, input logic [3:0] KEY, input logic [9:0] SW,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5,
             output logic [9:0] LEDR);

logic en, rdy, key_valid,  ct_wren, mask;
logic [7:0]  ct_rddata, ct_addr,ct_wrdata;
logic [4:0] Hold_0, Hold_1, Hold_2, Hold_3, Hold_4, Hold_5;
logic [23:0] key;
logic [24:0] key_reg;
logic [3:0] state;
assign ct_wren = 0;

    ct_mem ct (
	            .address (ct_addr),
	            .clock   (CLOCK_50) ,
	            .data    (ct_wrdata),
	            .wren    (ct_wren),
	            .q       (ct_rddata)
            );
    doublecrack dc ( 
                .clk(CLOCK_50), 
				.rst_n(KEY[3]),
                .en(en),   
				.rdy(rdy),
                .key(key),  
				.key_valid(key_valid),
                .ct_addr(ct_addr),  
                .ct_rddata(ct_rddata)
                 );
assign LEDR[0] = key_valid;
assign LEDR[1] = rdy;
 //SIMPLE FSM   
always @(posedge CLOCK_50) begin
			if (!KEY[3]) begin en = 0; mask = 0; end //RESET
			else  
				if   (rdy == 1 && en == 0 && mask==0 ) {en,mask} = 2'b11;//ASSERT ENABLE
                else  {en, mask} = {2'b01};//MAKE SURE EN IS ONLY HIGH ONCE
end		
 sseg hex0 (Hold_0,HEX0);
 sseg hex1 (Hold_1,HEX1);
 sseg hex2 (Hold_2,HEX2);
 sseg hex3 (Hold_3,HEX3);
 sseg hex4 (Hold_4,HEX4);
 sseg hex5 (Hold_5,HEX5);

always_comb begin //DETERMINES WHAT TO DISPLAY ON THE 7-SEG LED
    casex({rdy,key_valid})
    2'b0x: {Hold_0,Hold_1,Hold_2,Hold_3,Hold_4,Hold_5}={5'b10_001,5'b10_001,5'b10_001,5'b10_001,5'b10_001,5'b10_001}; //COMPUTING SHOW NOTHING
    2'b10: {Hold_0,Hold_1,Hold_2,Hold_3,Hold_4,Hold_5}={5'b10_000,5'b10_000,5'b10_000,5'b10_000,5'b10_000,5'b10_000}; //NO VALID KEY; HORIZONTAL LINES
    2'b11: {Hold_5,Hold_4,Hold_3,Hold_2,Hold_1,Hold_0}={ {1'b0,key[23:20]}, {1'b0,key[19:16]}, {1'b0,key[15:12]},{1'b0,key[11:8]}, {1'b0,key[7:4]}, {1'b0,key[3:0]} };//KEY
    default:{Hold_0,Hold_1,Hold_2,Hold_3,Hold_4,Hold_5}={5'b10_001,5'b10_001,5'b10_001,5'b10_001,5'b10_001,5'b10_001} ;//SHOW NOTHING BY DEFAULT
	 endcase
end
endmodule

module sseg(in,segs);//HEX DISPLAY MODULE FROM CPEN211
  input [4:0] in;
  output [6:0] segs;
  reg [6:0] segs;

 always@(in)begin
	case(in)
	5'b00_000: segs= 7'b1_000_000; //0
	5'b00_001: segs= 7'b1_111_001; //1
	5'b00_010: segs= 7'b0_100_100; //2
	5'b00_011: segs= 7'b0_110_000; //3
	5'b00_100: segs= 7'b0_011_001; //4
	5'b00_101: segs= 7'b0_010_010; //5
	5'b00_110: segs= 7'b0_000_010; //6
	5'b00_111: segs= 7'b1_111_000; //7 
	5'b01_000: segs= 7'b0_000_000; //8
	5'b01_001: segs= 7'b0_011_000; //9
	5'b01_010: segs= 7'b0_001_000; //A or 10
	5'b01_011: segs= 7'b0_000_011; //b or 11
	5'b01_100: segs= 7'b1_000_110; //c or 12
	5'b01_101: segs= 7'b0_100_001; //d or 13
	5'b01_110: segs= 7'b0_000_110; //E or 14
	5'b01_111: segs= 7'b0_001_110; //F or 15
   5'b10_000: segs= 7'b0_111_111; //No Key
   5'b10_001: segs= 7'b1_111_111; //calculating
	default : segs= 7'b1_111_111;
	endcase
  end

endmodule