/* =================================================
Reference C Code:
	int message_length = ciphertext[0];
	for (index = 1, j = 0, k = 1; k < (message_length); k++, index = (index + 1) % 256)
	{
		j =  (j+s[i]) mod 256
   		temp = s[index];          //  swap s[i] and s [j]
		s[index] = s[j];
		s[j] = temp;
		plain_text[k] = s[((s[index] + s[j]) % 256)] ^ ciphertext[k];
	}
	plain_text[0] = message_length;  
==================================================*/ 
   
    module prga(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] s_addr, input logic [7:0] s_rddata, output logic [7:0] s_wrdata, output logic s_wren,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);

        logic [8:0] index, j_index, k_index;
        logic [3:0] state;
        logic req, mask , done, false;
        logic [7:0] message_length, si, sj, pad, j_hold, i_hold, CT_K_reg, pad_hold, xor_result, S_ij_addr;

        `define Initiation      4'b0000 //Get the length of ciphertext; The address ct[0] is pre-inputted wehnever we recieved en so we have actually waited in clock already; we could read s[i] but im lazy
        `define Get_S_I         4'b0001 //Read s[i]
        `define Wait_1          4'b0010 //Wait to get s[i] result; store it in "si"
        `define Get_S_J         4'b0011 //Read s[j] and update the value of "j_index"
        `define Wait_2          4'b0100 //Wait to get s[i] result; store it in "sj"
        `define write_SJ       4'b0101 //assign s[j] with the value of s[i]
        `define write_SI       4'b0110 //assign s[i] with the value of s[j]
        `define Read_S_IJ_CT    4'b0111 //Read s[ (s[i]+s[j])%256 ] and read ct[k]
        `define Wait_3          4'b1000 //Wait to get the results; and store them in pad and CT_K_reg respectively
   //   `define Write_Pad_PT    4'b0101
   //   `define Read_CT         4'b0110
        `define Xor_Write       4'b1001 //Use combinational logic to find the result of "s[((s[index] + s[j]) % 256)] ^ ciphertext[k]" and store it in pt[k]; write message length      
        `define Inc_K_I         4'b1010 //Increment i and k 
        `define Finished        4'b1011 //Store ct[0] in pt[0]  
        `define Found           4'b1100
        `define Incorrect       4'b1101
        
        assign j_hold       = ( j_index + s_rddata) % 256;
        assign i_hold       =  ( index + 9'b1) % 256;
        assign pad_hold     = (s_rddata) % 256;
        assign S_ij_addr    = (si + sj)  % 256;
        assign xor_result   = {
                                pad_hold[7]^ct_rddata[7],pad_hold[6]^ct_rddata[6],pad_hold[5]^ct_rddata[5],pad_hold[4]^ct_rddata[4],
                                pad_hold[3]^ct_rddata[3],pad_hold[2]^ct_rddata[2],pad_hold[1]^ct_rddata[1],pad_hold[0]^ct_rddata[0]
                              };
                              

        always @ (posedge clk)
            if (!rst_n) begin//reset
                req     = 0; index   = 1;
                j_index = 0; mask    = 0; 
                rdy     = 1; k_index = 1; end
            else begin
                if(en) begin//enable
                 req     = 1; rdy     = 0;
                 s_addr  = 1; s_wren  = 0;
                 ct_addr = 0; state   = 0;
                 pt_addr = 0; pt_wren = 0;
                 k_index = 1; j_index = 0;
                 index   = 1; message_length = 256;
                 false   = 0;
                  end
                 else if (req || mask) begin //computing
                     req   = ( k_index >=message_length) ? 1'b0: 1'b1;
                     false = (  pt_addr!==8'b0 && pt_wrdata !==8'bxxxx  && (pt_wrdata< 8'h20 || pt_wrdata > 8'h7e) && pt_wren==1 || false ==1 ) ? 1'b1  : 1'b0;
                     done  = (false) || (~req);

                 case (state)//state transition
                        `Initiation     : {state, mask} = !mask ?  {`Initiation,1'b1}: {`Get_S_I, 1'b0};
                        `Get_S_I        : state         =  done ?  `Finished         : `Wait_1         ;
                        `Wait_1         : state         =  done ?  `Finished         : `Get_S_J        ;
                        `Get_S_J        : state         =  done ?  `Finished         : `Wait_2         ;
                        `Wait_2         : state         =  done ?  `Finished         : `write_SJ      ;
                        `write_SJ      : state          =  done ?  `Finished         : `write_SI      ;
                        `write_SI      : state          =  done ?  `Finished         : `Read_S_IJ_CT   ;
                        `Read_S_IJ_CT   : state         =  done ?  `Finished         : `Wait_3         ;

                        `Wait_3         : state         =  done ?  `Finished         : `Xor_Write      ;
                    //  `Write_Pad_PT   : state         =  done ?  `Finished         : `Xor_Write      ;
                    //  `Read_CT        : state         =  done ?  `Finished         : `Xor_Write      ;
                        `Xor_Write      : state         =  done ?  `Finished         : `Inc_K_I        ;
                        `Inc_K_I        : state         =  done ?  `Finished         : `Get_S_I        ;
                        `Finished       : state         =  false?  `Incorrect        : `Found          ;
                        `Found          : state         =  `Found;
                        `Incorrect      : state         =  `Incorrect;
                        default         : state         =  4'bxxxx  ;
                 endcase
                   
            end 
             else if (done) begin//finsshed
                        index = 1; j_index = 8'b0; k_index = 1;
                        rdy   = 1; req     = 0; false   = 0;
                        done  = 0; state   = 0; req     = 0;
                    end 
            case (state)//Assignements for each state
            `Initiation       :   {index, j_index, k_index, message_length, s_addr     , s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg}
                              =   {index, j_index, k_index, ct_rddata     , index[7:0] , s_wrdata, s_wren, 8'b0   , pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg};

            `Get_S_I          :   {index, j_index, k_index, message_length, s_addr     , s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata     , pt_wren, si, sj, pad, CT_K_reg}
                              =   {index, j_index, k_index, message_length, index[7:0] , s_wrdata, 1'b0  , ct_addr, 8'b0   , message_length, 1'b1, si, sj, pad, CT_K_reg};

            `Wait_1          :   {index, j_index, k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg}
                             =   {index, j_index, k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, 1'b0   , si, sj, pad, CT_K_reg};
 
            `Get_S_J         :  {index, j_index      , k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata,  pt_wren, si      , sj, pad, CT_K_reg}
                             =  {index, {1'b0,j_hold},  k_index, message_length, j_hold, s_wrdata, 1'b0  , ct_addr, pt_addr, pt_wrdata, pt_wren, s_rddata, sj, pad, CT_K_reg};
            
            `Wait_2          :  {index, j_index, k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg}
                             =  {index, j_index, k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg};

            `write_SJ       :  {index, j_index, k_index, message_length, s_addr      , s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj      , pad, CT_K_reg}  
                             =  {index, j_index, k_index, message_length, j_index[7:0], si      , 1'b1  , ct_addr, pt_addr, pt_wrdata, pt_wren, si, s_rddata, pad, CT_K_reg};    

            `write_SI       :  {index, j_index, k_index, message_length, s_addr    , s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg}  
                             =  {index, j_index, k_index, message_length, index[7:0], sj      , 1'b1  , ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg};   
               
            `Read_S_IJ_CT    :  {index, j_index, k_index, message_length, s_addr   , s_wrdata, s_wren, ct_addr     , pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg} 
                             =  {index, j_index, k_index, message_length, S_ij_addr, s_wrdata, 1'b0  , k_index[7:0], pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg};  

            `Wait_3          :   {index, j_index, k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg}
                             =   {index, j_index, k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad,CT_K_reg };  

            `Xor_Write       :   {index, j_index, k_index, message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr     , pt_wren, si, sj, pad     , CT_K_reg,  pt_wrdata}
                             =   {index, j_index, k_index, message_length, s_addr, s_wrdata, 1'b0  , ct_addr, k_index[7:0], 1'b1   , si, sj, pad_hold, ct_rddata, xor_result};    

            `Inc_K_I         :   {index        , j_index, k_index       , message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren   , si, sj, pad, CT_K_reg}
                             =   {{1'b0,i_hold}, j_index, (k_index+9'b1), message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren   , si, sj, pad, CT_K_reg};

            `Finished        :   {index       , j_index       , k_index       , message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg, req}
                             =   {9'b1       ,  9'b0          , 9'b0          , message_length, s_addr, s_wrdata, 1'b0  , ct_addr, pt_addr, pt_wrdata, 1'b0   , si, sj, pad, CT_K_reg, 1'b1};

            `Found           :   {index       , j_index       , k_index       , message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg, rdy , done, req , mask, false}
                             =   {9'b1       ,  9'b0          , 9'b0          , message_length, s_addr, s_wrdata, 1'b0  , 8'hff  , pt_addr, pt_wrdata, 1'b0   , si, sj, pad, CT_K_reg, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0 };
            
            `Incorrect       :   {index       , j_index       , k_index       , message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren, si, sj, pad, CT_K_reg, rdy , done, req , mask, false}
                             =   {9'b1       ,  9'b0          , 9'b0          , message_length, s_addr, s_wrdata, 1'b0  , 8'hee  , pt_addr, pt_wrdata, 1'b0   , si, sj, pad, CT_K_reg, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0 };


            default          :   {index       , j_index       , k_index       , message_length, s_addr, s_wrdata, s_wren, ct_addr, pt_addr, pt_wrdata, pt_wren   , si, sj, pad, CT_K_reg} = 100'bx;                   
            endcase
        end
endmodule: prga