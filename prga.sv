`define s_ready 5'd0
`define s_get_length 5'd1
`define s_read_si 5'd2
`define s_read_sj 5'd3
`define s_write_sj 5'd4
`define s_write_si 5'd5
`define s_read_sij 5'd6
`define s_write_pt 5'd7


module prga(
            input  logic clk, input logic rst_n,
            input  logic en, output logic rdy, 
            input  logic [23:0] key,
            output logic false, output logic correct,

            output logic [7:0] s_addr_1, s_addr_2, 
            input  logic [7:0] s_rddata_1, s_rddata_2,
            output logic [7:0] s_wrdata_1, s_wrdata_2,
            output logic s_wren_1, s_wren_2, 
            
            output logic [7:0] ct_addr_1, ct_addr_2, 
            input  logic [7:0] ct_rddata_1, ct_rddata_2,

            output logic [7:0] pt_addr_1,pt_addr_2 ,
            input  logic [7:0] pt_rddata_1, pt_rddata_2,
            output logic [7:0] pt_wrdata_1, pt_wrdata_2,  
            output logic pt_wren_1, pt_wren_2
            );
/*
i = 0, j = 0
message_length = ciphertext[0];
plaintext[0] =  ciphertext[0];

for k = 1 to message_length:
    i = (i+1) mod 256
    j = (j+s[i]) mod 256
    swap values of s[i] and s[j]
    pad[k] = s[(s[i]+s[j]) mod 256]
    plaintext[k] = pad[k] xor ciphertext[k]  -- xor each byte
end: for-loop
*/

logic [7:0] i_index_1, i_index_2, j_index_1, j_index_2, k, message_length;
logic [7:0] temp_si_1, temp_si_2, temp_sj_1, temp_sj_2;
logic [4:0] state;
logic flag_rlength, flag_ri, flag_rj, flag_rij, flag_conflict;
logic conflict;
assign conflict = (j_index_1 + s_rddata_1 === i_index_2 || i_index_1 === j_index_1 + s_rddata_1 + s_rddata_2  || i_index_2  >= i_index_1 + 2'd2);



    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin

            {s_addr_1,  s_wrdata_1, s_wren_1} <= {8'd1, 8'b0, 1'b0}; 
            {s_addr_2,  s_wrdata_2, s_wren_2} <= {8'd2, 8'b0, 1'b0};
            
            {ct_addr_1, ct_addr_2 } <= {2{8'b0}}; // ct is read only
            
            {pt_addr_1, pt_wrdata_1, pt_wren_1} <= {8'd0, 8'b0, 1'b0};
            {pt_addr_2, pt_wrdata_2, pt_wren_2} <= {8'd0, 8'b0, 1'b0};

            {i_index_1, i_index_2} <= {8'b1, 8'd2}; 
            {j_index_1, j_index_2} <= {8'b0,8'b1}; 
            k <= 8'd1;

            {temp_si_1, temp_si_2, temp_sj_1, temp_si_2} <= {4{8'b0}};
            {flag_conflict, flag_ri , flag_rj, flag_rij} <= 4'b0;

            state <= `s_ready; 

            rdy <= 1;
        end
        
        else begin
            case(state)
                `s_ready: begin
                    if(en) begin  //start to get length
                        rdy <= 0;
                        state <= `s_get_length;
                    end
                    else begin state <= `s_ready; rdy <= 1; end             
                end
                    

                `s_get_length: begin
                        message_length <= ct_rddata_1;  //value in ct[0]
                        // write plain text
                        {pt_addr_1, pt_wrdata_1, pt_wren_1} <= {8'd0, ct_rddata_1, 1'b1};

                        //prepare the data for read si
                        {s_addr_1,  s_addr_2} <= {i_index_1, i_index_2}; 
                        state <= `s_read_si;

                end

                    `s_read_si: begin
                        if(!flag_ri) begin
                            flag_ri <= 1;
                            pt_wren_1 = 0;
                            state <= `s_read_si;
                        end

                        else begin
                            flag_ri <= 0;
                            {temp_si_1,temp_si_2} <= (conflict) ? {s_rddata_1,8'bz}: {s_rddata_1,s_rddata_2};
                            //prepare the data for read sj
                            {i_index_2, flag_conflict} <={i_index_2 ,conflict} ; 
                            {j_index_1, j_index_2} <= (conflict) ? {j_index_1 + s_rddata_1, 8'bz} :  {j_index_1 + s_rddata_1,j_index_1 + s_rddata_1 + s_rddata_2 }; 
                            {s_addr_1,  s_addr_2} <= (conflict) ? {j_index_1 + s_rddata_1, 8'bz} :  {j_index_1 + s_rddata_1, j_index_1 + s_rddata_1 + s_rddata_2}; 
                            state <= `s_read_sj;
                        end
                    end

                    `s_read_sj: begin
                        if(!flag_rj) begin
                            flag_rj <= 1;
                            state <= `s_read_sj;
                        end

                        else begin
                            flag_rj <= 0;
                            //prepare for writing s[j] = i_temp
                            {s_wrdata_1, s_wren_1} <={temp_si_1, 1'b1};
                            {s_wrdata_2, s_wren_2} <={temp_si_2, 1'b1^flag_conflict};
                            {temp_sj_1, temp_sj_2} <= (flag_conflict) ?{s_rddata_1, 8'bz} : {s_rddata_1, s_rddata_2};
                            state <= `s_write_sj;
                            //store s[j]
                            
                        end
                    end

                    `s_write_sj: begin
                        //prepare for s[i] = j_temp

                        {s_addr_1, s_wrdata_1, s_wren_1} <={i_index_1,temp_sj_1, 1'b1};
                        {s_addr_2, s_wrdata_2, s_wren_2} <={i_index_2,temp_sj_2, 1'b1^flag_conflict};

                        state <= `s_write_si;
                    end
                

                    `s_write_si: begin
                        //prepare for reading s[s[i]+s[j]]

                        {s_addr_1,  s_wren_1} <={temp_si_1 + temp_sj_1, 1'b0};
                        {s_addr_2,  s_wren_2} <={temp_si_2 + temp_sj_2, 1'b0};
                        state <= `s_read_sij;
                        // we will also read ct[k] in the following state
                        {ct_addr_1, ct_addr_2} <= {k[7:0],k[7:0]+1'b1};
                    end

                     `s_read_sij: begin
                        if(!flag_rij) begin
                            flag_rij <= 1;
                            state <= `s_read_sij;
                        end

                        else begin
                            // At this clk rsing edge, we should have s[s[i]+s[j]] and ct[k] rdy to go
                            // Therefore, we can directly write pt[k] in the following state

                            //write pt[k]
   
                            {pt_wrdata_1,pt_addr_1, pt_wren_1} <= {ct_rddata_1^ s_rddata_1, k[7:0], 1'b1};
                            {pt_wrdata_2,pt_addr_2, pt_wren_2} <= (k < (message_length-1 ))? {ct_rddata_2^ s_rddata_2, k[7:0]+1'b1, 1'b1^flag_conflict}:{ct_rddata_2^ s_rddata_2, k[7:0]+1'b1, 1'b0};


                            flag_rij <= 0;
                            state <= `s_write_pt;
                        end
                    end


                    `s_write_pt: begin
                        if(k < (message_length )) begin

                            k <= k + 2'd2 - flag_conflict;
                            j_index_1<= flag_conflict? j_index_1:j_index_2;
                            {i_index_1, i_index_2} <= {i_index_1 + 2'd2 - flag_conflict, i_index_2 +2'd2 - flag_conflict};  
                            {s_addr_1, s_addr_2} <= {i_index_1 + 2'd2 - flag_conflict, i_index_2 +2'd2 - flag_conflict};  
                            {pt_wren_1, pt_wren_2} <= 0;

                            state <= `s_read_si;
                        end

                        else begin
                            state <= `s_ready;
                            {s_addr_1,  s_wrdata_1, s_wren_1} <= {8'd1, 8'b0, 1'b0}; 
                            {s_addr_2,  s_wrdata_2, s_wren_2} <= {8'd2, 8'b0, 1'b0};
            
                            {ct_addr_1, ct_addr_2 } <= {2{8'b0}}; // ct is read only
            
                            {pt_addr_1, pt_wrdata_1, pt_wren_1} <= {8'd0, 8'b0, 1'b0};
                            {pt_addr_2, pt_wrdata_2, pt_wren_2} <= {8'd0, 8'b0, 1'b0};

                            {i_index_1, i_index_2} <= {8'b0, 8'b1}; 
                            {j_index_1, j_index_2} <= {2{8'b0}}; 
                            k <= 8'd1;

                            {temp_si_1, temp_si_2, temp_sj_1, temp_si_2} <= {4{8'b0}};
                            {flag_conflict, flag_ri , flag_rj, flag_rij} <= 4'b0;                       
                        end
                    end

                    default: begin
                            state <= 5'dx;
                           {s_addr_1,  s_wrdata_1, s_wren_1} <= {8'dx, 8'bx, 1'bx}; 
                            {s_addr_2,  s_wrdata_2, s_wren_2} <= {8'dx, 8'bx, 1'bx};
            
                            {ct_addr_1, ct_addr_2 } <= {2{8'bx}}; // ct is read only
            
                            {pt_addr_1, pt_wrdata_1, pt_wren_1} <= {8'dx, 8'bx, 1'bx};
                            {pt_addr_2, pt_wrdata_2, pt_wren_2} <= {8'dx, 8'bx, 1'bx};

                            {i_index_1, i_index_2} <= {8'bx, 8'bx}; 
                            {j_index_1, j_index_2} <= {2{8'bx}}; 
                            k <= 8'd1;

                            {temp_si_1, temp_si_2, temp_sj_1, temp_si_2} <= {4{8'bx}};
                            {flag_conflict, flag_ri , flag_rj, flag_rij} <= 4'bx;                        
                    end
                    
            endcase
        end  //end of reset else
    end

endmodule: prga
