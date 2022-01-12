module doublecrack(input logic clk, input logic rst_n,
             input logic en, output logic rdy,
             output logic [23:0] key, output logic key_valid,
             output logic [7:0] ct_addr, input logic [7:0] ct_rddata);
//SIGNALS FOR CT1
    logic en_crack_1, rdy_crack_1, key_valid_1, pt_wren_copy_1, ct_wren_1;
    logic [23:0] key_1, starting_key_1,key_increment_1;
    logic [7:0] ct_addr_1,ct_rddata_1, ct_wrdata_1,ct_addr_c1,ct_addr_1_in;
    logic [7:0] pt_addr_copy_1, pt_rddata_1;
//SIGNALS FOR CT2
    logic en_crack_2, rdy_crack_2, key_valid_2, pt_wren_copy_2, ct_wren_2;
    logic [23:0] key_2, starting_key_2,key_increment_2;
    logic [7:0] ct_addr_2,ct_rddata_2, ct_wrdata_2,ct_addr_c2,ct_addr_2_in;
    logic [7:0] pt_addr_copy_2, pt_rddata_2;
//MAIN PT CONTROL SIGNALS
    logic [7:0] pt_addr, pt_wrdata, pt_rddata;
    logic pt_wren;
//HELPER SIGNALS
    logic [3:0] double_crack_state;
    logic mask, req;
    logic [7:0] message_length;
    logic [8:0] ct_addr_reg, pt_addr_reg;
//STATE MACROS
        `define statr_db_crack 4'b0000
        `define Read_CT_cpy    4'b0001
        `define Wait_CT        4'b0010
        `define Increment_CT   4'b0011
        `define Compute_1        4'b0100
        `define Read_PT        4'b0101
        `define Wait_PT        4'b0110
        `define Increment_PT   4'b0111
        `define Stop           4'b1000
        `define FINAL          4'b1001

 //FSM
       always@(posedge clk) begin
           if(!rst_n) begin//RESET
               en_crack_1 = 0; en_crack_2 = 0;
               req        = 0; mask       = 0;
               rdy        = 1; 
               double_crack_state = 4'b1000;
               end 
            else if (en) begin//WHENEVER EN IS ASSERTED
                double_crack_state = 4'b0000;
                rdy       = 0;
                req       = 1;
                starting_key_1  = 24'b0;
                starting_key_2  = 24'b1;
                key_increment_1 = 24'd2;
                key_increment_2 = 24'd2;
                key_valid       = 0;
					 
                mask            = 0;
                message_length  = 8'hff;

                ct_addr_1       = 8'b0;
                ct_addr_2       = 8'b0;

                ct_addr         = 8'b0;

                ct_wren_1       = 1'b0;
                ct_wren_2       = 1'b0;

                ct_addr_reg     = 9'b0;
                pt_addr_reg     = 9'b0;
                end
                else begin 
                        /*
    There should be states for start, move ct data ,wait for results, several states for moving pt results which consists of read, wait, write, increment 
    then read again untill we have moved all data. We will need a mesage length. Finally we will need a halt state
    
    */
                        case(double_crack_state)// STATE TRANSITION + ASSIGNEMT
                                
                                `statr_db_crack: if(mask==0) {double_crack_state,mask} = {`statr_db_crack,1'b1};
                                                 else        {double_crack_state, mask, message_length,ct_addr} = {`Read_CT_cpy,1'b0,ct_rddata,ct_addr_reg[7:0]};

                                `Read_CT_cpy   : if(ct_addr_reg <= {1'b0, message_length} + 9'b1) {double_crack_state,ct_addr} = {`Wait_CT,ct_addr_reg[7:0]};
                                                 else if (rdy_crack_1==1 && rdy_crack_2==1 && mask == 0){double_crack_state,en_crack_1, en_crack_2, mask,ct_addr_1,ct_addr_2} = {`Read_CT_cpy,1'b1, 1'b1, 1'b1,8'b0,8'b0};
                                                        else if(mask==1) {double_crack_state,en_crack_1, en_crack_2, mask,ct_addr_1,ct_addr_2} = {`Compute_1,1'b0, 1'b0, 1'b1,8'b0,8'b0};

                                
                                `Wait_CT       :{double_crack_state, ct_addr_reg,ct_wren_1, ct_wren_2, ct_wrdata_1, ct_wrdata_2, ct_addr_1, ct_addr_2} = {`Increment_CT, (ct_addr_reg+9'b1),1'b1, 1'b1, ct_rddata, ct_rddata, (ct_addr_reg[7:0] -8'b1),(ct_addr_reg[7:0]-8'b1) };
                                     
                                `Increment_CT  : {double_crack_state,ct_wren_1, ct_wren_2} = {`Read_CT_cpy,1'b0,1'b0};

                                `Compute_1       : if( (rdy_crack_1 && key_valid_1) ||(rdy_crack_2 && key_valid_2) ) {double_crack_state,pt_addr, pt_wren, pt_addr_copy_1,pt_wren_copy_1, pt_addr_copy_2,pt_wren_copy_2 }={`Read_PT,8'b0, 1'b0,8'b0,1'b0,8'b0,1'b0};
                                                 else if (rdy_crack_1 || rdy_crack_2){double_crack_state,key_valid,key,rdy} = {`Stop,1'b0,24'bx,1'b1};
                                                 else {double_crack_state,ct_addr_1,ct_addr_2} = {`Compute_1,8'b0,8'b0};

                                `Read_PT       : if (pt_addr_reg<=message_length){double_crack_state, pt_addr_copy_1, pt_wren_copy_1, pt_addr_copy_2, pt_wren_copy_2,pt_wren} = {`Wait_PT, pt_addr_reg[7:0],1'b0, pt_addr_reg[7:0],1'b0,1'b1};
                                                 else {double_crack_state,pt_wren}={`Stop,1'b0};

                                `Wait_PT       : {double_crack_state,pt_addr,pt_wren} = {`Increment_PT,pt_addr_reg[7:0],1'b1};



                                `Increment_PT  : if (key_valid_1) {double_crack_state,pt_wrdata, pt_addr_reg} = {`Read_PT,pt_rddata_1,(pt_addr_reg+9'b1) };
                                                    else if(key_valid_2) {double_crack_state,pt_wrdata, pt_addr_reg} = {`Read_PT,pt_rddata_2,(pt_addr_reg+9'b1) };
                                
                                `Stop:      if(key_valid_1) {double_crack_state,key_valid,key, rdy} = {`FINAL,1'b1,key_1,1'b1};
                                             else   if(key_valid_2){double_crack_state,key_valid,key,rdy} = {`FINAL,1'b1,key_2,1'b1};
                                             else  {double_crack_state,key_valid,key,rdy} = {`FINAL,1'b0,24'bx,1'b1};

                                `FINAL: double_crack_state = `FINAL;
 
                                default: double_crack_state = 4'bxxxx;
                           endcase
                end
        end

        
//USE COMBINATIONAL LOGIC TO DERTERMINE THE CONTROL SIGNALS FOR EACH CT MEM
    assign ct_addr_1_in = (double_crack_state>=4'b0100) ? ct_addr_c1:ct_addr_1;
    assign ct_addr_2_in = (double_crack_state>=4'b0100) ? ct_addr_c2:ct_addr_2;

    ct_mem  ct1(
	            .address (ct_addr_1_in),
	            .clock   (clk) ,
	            .data    (ct_wrdata_1),
	            .wren    (ct_wren_1),
	            .q       (ct_rddata_1)
            );

    
   ct_mem  ct2(
	            .address (ct_addr_2_in),
	            .clock   (clk) ,
	            .data    (ct_wrdata_2),
	            .wren    (ct_wren_2),
	            .q       (ct_rddata_2)
            );

    pt_mem pt
    (
            	.address (pt_addr),
	            .clock   (clk) ,
	            .data    (pt_wrdata),
	            .wren    (pt_wren),
	            .q       (pt_rddata)

    );
    crack c1
    ( 
                .clk(clk), 
				.rst_n(rst_n),
                .en(en_crack_1),   
				.rdy(rdy_crack_1),
                .key(key_1),  
				.key_valid(key_valid_1),
                .ct_addr(ct_addr_c1),  
                .ct_rddata(ct_rddata_1),
                .starting_key(starting_key_1),
                .key_increment(key_increment_1),
                .pt_addr_copy(pt_addr_copy_1),
                .pt_wren_copy(pt_wren_copy_1),
                .pt_rddata(pt_rddata_1)
    );
    crack c2
    ( 
                .clk(clk), 
				.rst_n(rst_n),
                .en(en_crack_2),   
				.rdy(rdy_crack_2),
                .key(key_2),  
				.key_valid(key_valid_2),
                .ct_addr(ct_addr_c2),  
                .ct_rddata(ct_rddata_2),
                .starting_key(starting_key_2),
                .key_increment(key_increment_2),
                .pt_addr_copy(pt_addr_copy_2),
                .pt_wren_copy(pt_wren_copy_2),
                .pt_rddata(pt_rddata_2)
    );
    
 
endmodule: doublecrack

