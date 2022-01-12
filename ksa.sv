module ksa(input logic clk, input logic rst_n,
           input logic en, output logic rdy,
           input logic [23:0] key,
           output logic [7:0] addr, input logic [7:0] rddata, output logic [7:0] wrdata, output logic wren);

    `define Read_S_I  4'b0000
    `define Read_S_J  4'b0001
    `define Write_S_J 4'b0010
    `define Write_S_I 4'b0011
    `define Inc       4'b0100
    `define Hold_1    4'b0101
    `define Hold_2    4'b0110
    `define Done    4'b0111
    logic [8:0] index;
    logic [7:0] hold, j, si, sj;
    logic [3:0] state;
    logic req, done;
    //Combinational logic is used to compute next j

    always_comb begin 
          if((index % 3) == 0)  hold = ((j + rddata + key[23:16]) % 256);
            else if ((index % 3) == 1)   hold = ((j + rddata + key[15:8]) % 256);
                 else  hold = ((j + rddata + key[7:0]) % 256);
    end
    //FSM
    /*
    Reference C Code:
    for (index = 0, j = 0; index <256; index++)
	{
		j = (j + s[index] + key[(index % 3)]) % 256;
		temp = s[index];
		s[index] = s[j];
		s[j] = temp;
	}
	
	int message_length = ciphertext[0];

    Note: Hold states are used to wait till the output of the meorry is ready to be read; I wait two cycles for every read instruction
    and one cycle for each write instruction
    */

    always@ (posedge clk) 
        if (!rst_n) begin 
                rdy   = 1'b1;  index  = 8'b0;
                req   = 1'b0;  j      = 8'b0; end
        else begin
            if(en) begin 
                req    = 1'b1;  rdy   = 1'b0; 
                addr   = 8'b0;  wren  = 1'b0; 
                state = 3'b0;   j      = 8'b0;end
            else if (req) begin 
                req    = (index > 8'b1111_1111) ? 1'b0 : 1'b1;
                done   = (index > 8'b1111_1111) ? 1'b1 : 1'b0;
                case(state)
                    `Read_S_I      :  state = !done ? `Hold_1 : `Done;     //read  s[i]
                    `Hold_1        :  state = !done ? `Read_S_J: `Done;
                    `Read_S_J      :  state = !done ? `Hold_2: `Done;     //read  s[j]
                    `Hold_2        :  state = !done ? `Write_S_J: `Done;
                    `Write_S_J     :  state = !done ? `Write_S_I: `Done;      //write s[j] with s[i]
                    `Write_S_I     :  state = !done ? `Inc: `Done;      //write s[i] with s[j]
                    `Inc           :  state = !done ? `Read_S_I: `Done;      //increment i
                    `Done          :  state = !done;
                    default:  state = 3'bxxx; 
                endcase
            end
        case(state)
            `Read_S_I : {j, addr, wrdata, wren, si, sj, index} = {j,    index[7:0],   wrdata,       1'b0,     si,             sj,             index     };
            `Hold_1   : {j, addr, wrdata, wren, si, sj, index} = {j,    index[7:0],   wrdata,       wren,     si,             sj,             index     };
            `Read_S_J : {j, addr, wrdata, wren, si, sj, index} = {hold, hold,         wrdata,       1'b0,     rddata,         sj,             index     };
            `Hold_2   : {j, addr, wrdata, wren, si, sj, index} = {j,    j,            wrdata,       wren,     si,             sj,             index     };
            `Write_S_J: {j, addr, wrdata, wren, si, sj, index} = {j,    j,            si,           1'b1,     si,             rddata,             index     };
            `Write_S_I: {j, addr, wrdata, wren, si, sj, index} = {j,    index[7:0],   sj,           1'b1,     si,             sj,             index     };
            `Inc      : {j, addr, wrdata, wren, si, sj, index} = {j,    addr,         wrdata,       1'b0,     si,             sj,          (index+9'b1) };
            `Done     : {j, addr, wrdata, wren, si, sj, index, done, req, rdy} = {8'b0,8'b0000_0000,wrdata,1'b0,si,j,8'b0000_0000, 1'b0, 1'b0 ,1'b1};
        endcase
            
        end
endmodule: ksa
