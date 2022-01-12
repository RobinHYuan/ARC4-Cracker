
/*
This module is used to initialize the s_mem. 
Corresponding C Code:

	for (index = 0; index < 256; index++)
		s[index] = index;

*/

module init(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            output logic [7:0] addr, output logic [7:0] wrdata, output logic wren);
    logic req, mask, done;
    always@ (posedge clk)
        if ( !rst_n ) begin //reset state
            addr   = 8'b0; wrdata = 8'b0; 
            wren   = 1'b0; rdy    = 1'b1;
            req    = 1'b0; mask   = 1'b1; 
            done   = 1'b0; end
        else begin
            if(en)  begin req = 1'b1; rdy =1'b0; end//if enable signal is high then it will staty in this state until it becomes low again 
            else   begin
                if(req) begin // start assigning values; then increment the address untill it reaches 8'hff
                            addr   = (mask) ? 8'b0 : addr + 8'b1;
                            wrdata = (mask) ? 8'b0 : addr;
                            wren   = 1'b1;
                            req    = (addr >= 8'b1111_1111) ? 1'b0 : 1'b1;
                            done   = (addr >= 8'b1111_1111) ? 1'b1 : 1'b0;
                            mask   = 1'b0;
                        end
                else if (done) begin // after it finishes the task, it will stay in this task where rdy is asserted until it recieves another enable signal
                                addr   = 8'b0; wrdata = 8'b0; 
                                wren   = 1'b0; rdy    = 1'b1;
                                req    = 1'b0; mask   = 1'b1; 
                                done   = 1'b0;end
            end
        end 
endmodule: init