module crack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
             input logic [23:0] starting_key,
             input logic [23:0] key_increment,
             input logic [7:0]  pt_addr_copy,
             input logic   pt_wren_copy,
             output logic [7:0] pt_rddata
             );

    logic ct_wren;
    logic [7:0] pt_addr, pt_addr_ac4, pt_wrdata; 
    logic pt_wren,pt_wren_ac4;
    logic en_arc4, rdy_arc4, mask, req, done;
    logic [24:0] Potential_Key;
    logic [2:0] crack_state;

    `define Pause     3'b000
    `define Start     3'b001
    `define Compute   3'b010
    `define Inc_Key   3'b011
    `define Halt      3'b100
    
    assign pt_wren = (key_valid==1) ? pt_wren_copy: pt_wren_ac4;
    assign pt_addr = (key_valid==1) ? pt_addr_copy: pt_addr_ac4;

    pt_mem pt1(
	            .address (pt_addr),
	            .clock   (clk) ,
	            .data    (pt_wrdata),
	            .wren    (pt_wren),
	            .q       (pt_rddata)
            );
    arc4 a4
            (
                .clk        (clk), 
                .rst_n      (rst_n),
                .en         (en_arc4), 
                .rdy        (rdy_arc4),
                .key        (Potential_Key[23:0]),
                .ct_addr    (ct_addr), 
                .ct_rddata  (ct_rddata),
                .pt_addr    (pt_addr_ac4),
                .pt_rddata  (pt_rddata), 
                .pt_wrdata  (pt_wrdata),
                .pt_wren    (pt_wren_ac4) 
            );

    always @(posedge clk) begin
			if (!rst_n) begin 
                en_arc4 = 0; mask        = 0; 
                rdy     = 1; key_valid   = 0;
                req     = 0; crack_state = 1;
                done    = 0; end 
			else  begin
                  if (en) begin 
                    en_arc4 = 0; 
                    mask    = 0; 
                    rdy     = 0; key_valid      = 0;
                    req     = 1; crack_state    = 1;
                    done    = 0; Potential_Key  = {1'b0, starting_key};
                  end 
                  else  begin   case (crack_state)
                                `Start: if (rdy_arc4==1 && mask == 0) {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Start, 1'b1, 1'b0, 1'b1, {1'b0,key}, 24'b0, 1'b0};
                                        else if (done==1) {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Halt, 1'b1, 1'b0, 1'b1, {1'b0,key}, 24'b0, 1'b1};
                                             else  {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Compute, 1'b1, 1'b0, 1'b1, key, Potential_Key, 1'b1};

                                `Compute: if(rdy_arc4==0 && Potential_Key <= 24'hff_ff_ff) {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Compute, 1'b0, 1'b0, 1'b0, key, Potential_Key, 1'b1};
						else if( Potential_Key >24'hff_ff_ff) {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done,rdy} ={`Halt, 1'b0, 1'b0, mask, 24'hff_ff_ff, Potential_Key, 1'b1,1'b1};
							else if (rdy_arc4 == 1 && ct_addr == 8'hff) {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} ={`Halt, 1'b0, 1'b1, mask, Potential_Key[23:0], Potential_Key, 1'b1};
								else if(rdy_arc4 == 1 && ct_addr == 8'hee){crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Inc_Key, 1'b0, 1'b0, mask, key, Potential_Key, 1'b0};  
                                                                        else {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Halt, 1'b0, 1'b0, mask, 24'hff_ff_ff, Potential_Key, 1'b1};

                                `Inc_Key:  if(Potential_Key > 24'hff_ff_ff){crack_state, en_arc4, key_valid, mask, key, Potential_Key, done,rdy} ={`Halt, 1'b0, 1'b0, mask, 24'hff_ff_ff, Potential_Key, 1'b1,1'b1};
														 else {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Pause, 1'b1, 1'b0, 1'b0, key, (Potential_Key+key_increment), 1'b0};
															
                                `Pause  :  {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done} = {`Compute, 1'b0, 1'b0, 1'b0, key, Potential_Key, 1'b0};
                                `Halt: {crack_state, en_arc4, key_valid, mask, key, Potential_Key, done, req, rdy} = {`Halt, 1'b0, key_valid, mask, key, Potential_Key, 1'b1, 1'b0, 1'b1};
                                default:{crack_state, en_arc4, key_valid, mask, key, Potential_Key, done,rdy} ={`Halt, 1'b0, 1'b0, mask, 24'hff_ff_ff, Potential_Key, 1'b1,1'b1};

                                endcase
                  end
                end
			end			 
      

endmodule: crack
