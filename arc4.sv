module arc4(input logic clk, input logic rst_n,
            input logic en, output logic rdy,
            input logic [23:0] key,
            output logic [7:0] ct_addr, input logic [7:0] ct_rddata,
            output logic [7:0] pt_addr, input logic [7:0] pt_rddata, output logic [7:0] pt_wrdata, output logic pt_wren);


    /*===============================
     S Memory Signals
    ===============================*/
    logic wren;
    logic [7:0] addr, wrdata, q_out;

    /*===============================
    Control Signals
    ===============================*/
    logic[3:0] state;

    /*===============================
     Init Signals
    ===============================*/
    logic en_init, rdy_init;
    logic wren_init;
    logic [7:0] wr_data_init, addr_init;

    /*===============================
     KSA Signals
    ===============================*/
    logic en_ksa, rdy_ksa;
    logic wren_ksa;
    logic [7:0]  wr_data_ksa, addr_ksa;

    /*===============================
     PRGA Signals
    ===============================*/
    logic en_prga, rdy_prga;
    logic s_wren_prga;
    logic [7:0] addr_prga, s_wr_data_prga;

    /*===============================
     Module Instantiations
    ===============================*/ 
    s_mem s
            (
	            .address (addr),
	            .clock   (clk) ,
	            .data    (wrdata),
	            .wren    (wren),
	            .q       (q_out)
            );


    signal_control Ctrl(
                        .s_wr_data_init(wr_data_init) ,
                        .s_wr_data_ksa (wr_data_ksa),
                        .s_wr_data_prga(s_wr_data_prga),
                        .state(state),
                        .s_wren_init(wren_init),
                        .s_wren_ksa(wren_ksa),
                        .s_wren_prga(s_wren_prga),
                        .s_addr_ksa(addr_ksa),
                        .s_addr_init(addr_init),
                        .s_addr_prga(addr_prga),
                        
                        .s_addr(addr),
                        .s_wrdata(wrdata),
                        .s_wren(wren)

                    );
    init INT(
                .clk    (clk), 
                .rst_n  (rst_n),
                .en     (en_init), 
                .rdy    (rdy_init),
                .addr   (addr_init), 
                .wrdata (wr_data_init), 
                .wren   (wren_init)
            );

    ksa KSA ( 
                .clk    (clk),  
                .rst_n  (rst_n),
                .en     (en_ksa),  
                .rdy    (rdy_ksa) ,
                .key    (key),
                .addr   (addr_ksa),  
                .rddata (q_out)  ,  
                .wrdata (wr_data_ksa),  
                .wren   (wren_ksa) 
            );
   prga PRGA(
                .clk        (clk), 
                .rst_n      (rst_n),
                .en         (en_prga),
                .rdy        (rdy_prga),
                .key        (key),      //Not Used
                .s_addr     (addr_prga),
                .s_rddata   (q_out),
                .s_wrdata   (s_wr_data_prga),
                .s_wren     (s_wren_prga), 
                .ct_addr    (ct_addr),
                .ct_rddata  (ct_rddata),
                .pt_addr    (pt_addr),
                .pt_rddata  (pt_rddata),
                .pt_wrdata  (pt_wrdata),
                .pt_wren    (pt_wren)
            );        

    fsm FSM (
                .clk            (clk),  
                .rst_n          (rst_n),
                .en_ksa         (en_ksa),  
                .rdy_ksa        (rdy_ksa) ,

                .addr           (addr),  
                .en_init        (en_init), 
                .rdy_init       (rdy_init),
                .present_state  (state),
                .en_arc4        (en),
                .en_prga        (en_prga),  
                .rdy_prga       (rdy_prga),
                .rdy_arc4       (rdy)
            );



endmodule: arc4
    /*===============================
    FSM is used to contol which module is 
    activiely writing/read the memories
    ===============================*/
module fsm(
            input  logic clk,   input  logic rdy_init, 
            input  logic rdy_ksa,    input  logic rst_n,
            input  logic [7:0] addr, 
            output logic en_init,    output logic en_ksa,
            output logic en_prga,    input  logic rdy_prga,  
            
            input  logic en_arc4,
            output logic rdy_arc4,
            output [3:0] present_state
          );

        logic[3:0] current_state;
        logic arc_req;
        logic[2:0] mask;
        assign present_state = current_state;
        
        always @(posedge clk) 
            if(!rst_n) begin// reset
                current_state = 4'b0000;
                en_init = 0; rdy_arc4 = 1;
                en_ksa  = 0; arc_req  = 0;
                mask    = 0; en_prga = 0; end
            else begin 
                if(en_arc4) begin//enabled
                    arc_req = 1; current_state=4'b0; rdy_arc4=0;
                    en_init = 0; en_ksa       = 0  ;
                    mask    = 0; en_prga      = 0  ;
                end
                else begin
                    if (arc_req==1) //computing
                        case (current_state)
                            4'b0000: if( rdy_init) {current_state, en_init, en_ksa,mask, en_prga} = {4'b0001, 1'b1, 1'b0,3'b000,1'b0};//if init is ready then enable it otherwise wait
                             else {current_state, en_init ,en_ksa,mask, en_prga} = {4'b0000,1'b0,1'b0,3'b000, 1'b0};

                            4'b0001: if( addr==8'b1111_1111 && rdy_ksa){current_state, en_init ,en_ksa,mask, en_prga} = {4'b0010,1'b0,1'b1,3'b000, 1'b0};//if ksa is ready and init is finished then enable it otherwise wait
                             else {current_state, en_init ,en_ksa,mask,en_prga} = {4'b0001,1'b0,1'b0,3'b000, 1'b0};

                            4'b0010: if ( addr==8'b0000_0000 &&  mask ==0 ) {current_state,en_init,en_ksa,mask,en_prga }= {4'b0010,1'b0,1'b0, 3'b001,1'b0};
                                else if ( addr==8'b0000_0000 &&  mask >0 && mask < 6 ){current_state,en_init,en_ksa,mask,en_prga }= {4'b0010,1'b0,1'b0, (mask+3'b001),1'b0};
                                        else if ( addr==8'b0000_0000 &&  mask >=6  && rdy_ksa ==1 ){current_state,en_init,en_ksa,mask,en_prga }= {4'b0011,1'b0,1'b0, 3'b000,1'b1};
                                                else  {current_state,en_init,en_ksa,mask,en_prga} = {4'b0010,1'b0,1'b0,3'b000,1'b0};//if prga is ready and ksa is finished then enable it otherwise wait
                                                
                            4'b0011:if(rdy_prga==1 && mask == 0 ){current_state, en_init ,en_ksa,mask, en_prga} = {4'b0011,1'b0,1'b0,3'b001, 1'b1};
                                 else if (!rdy_prga){current_state, en_init ,en_ksa,mask,en_prga} = {4'b0011,1'b0,1'b0,mask, 1'b0};
                                        else {current_state, en_init ,en_ksa,mask,en_prga} = {4'b0100,1'b0,1'b0,3'b000, 1'b0};//after prga finshes its computation it goes to a halt state
                            
                            4'b0100: {current_state,arc_req, rdy_arc4} = {4'b0100,1'b0, 1'b1};//halting

                             
                            default: {current_state, en_init ,en_ksa,mask,en_prga, rdy_arc4} = {4'b0000,1'b0,1'b0,3'b000,1'b0, 1'b1};
                        endcase
                    
                end
            end
       

endmodule

//combinational logic used to assgin control signals of the memory
module signal_control(
                        input logic [7:0]s_wr_data_init,
                        input logic [7:0]s_wr_data_ksa,
                        input logic [7:0]s_wr_data_prga,
                        input logic [3:0]state,
                        input logic s_wren_init,
                        input logic s_wren_ksa,
                        input logic s_wren_prga,
                        input logic [7:0]s_addr_ksa,
                        input logic [7:0]s_addr_init,
                        input logic [7:0]s_addr_prga,
                        
                        output logic [7:0] s_addr,
                        output logic [7:0] s_wrdata,
                        output logic s_wren

                    );
    always_comb begin
        case(state)
        
        4'b0001: {s_wren,s_wrdata,s_addr}={s_wren_init,s_wr_data_init,s_addr_init}; //Init is using the meorry
        4'b0010: {s_wren,s_wrdata,s_addr}={s_wren_ksa,s_wr_data_ksa,s_addr_ksa};   //ksa is using the meorry
        4'b0011: {s_wren,s_wrdata,s_addr}={s_wren_prga,s_wr_data_prga,s_addr_prga}; //prga is using the meorry
        default: {s_wren,s_wrdata,s_addr}= 0;
        endcase
    end
endmodule