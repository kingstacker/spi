//************************************************
//  Filename      : spi_ms_test1.v                             
//  Author        : Kingstacker                  
//  Company       : School                       
//  Email         : kingstacker_work@163.com     
//  Device        : Altera cyclone4 ep4ce6f17c8  
//  Description   : spi master module;data 8bit;sck is 4 div of the clk;                              
//************************************************
module  spi_ms #(parameter WIDTH = 8)(
    //input;
    input    wire    clk, 
    input    wire    rst_n,
    input    wire    wr, //send request;
    input    wire    [WIDTH-1:0]    master_din, //the data you want send;
    input    wire    miso, //the data form slave;
    //output;
    output   reg     cs, //slave select;
    output   reg     sck, //data exchange clock;
    output   reg     mosi,    //master out;
    output   reg     [WIDTH-1:0]    master_dout //the data you received;
);
localparam CLK_HZ = 50_000_000;  //clk frequency;  
localparam SCK_HZ = 12_500_000;  //sck frequency;
localparam DIV_NUMBER = CLK_HZ / SCK_HZ;
localparam CNT_MAX = (DIV_NUMBER >>1) - 1'b1; 
localparam DATA_CNT_MAX = 5'd31;
localparam MOSI_CNT_MAX = 3'd7;
localparam IDEL = 2'b00;
localparam SEND = 2'b01;
localparam FINISH = 2'b10; 
reg cnt; //sck cnt;
reg sck_en; //enable sck;
reg data_cnt_en;
reg sck_reg1;
reg sck_reg2;
wire sck_p; //posedge sck;
wire sck_n; //negedge sck;
wire send_over;
reg [1:0] cstate;
reg [4:0] data_cnt; //cnt the send data;
reg [2:0] mosi_cnt;
reg [WIDTH-1:0] master_din_reg; 
reg [WIDTH-1:0] master_dout_reg;
//produce sck;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cnt <= 0;
        sck <= 1'b0;
    end //if
    else begin
        if (sck_en == 1'b1) begin
        	if (cnt == CNT_MAX) begin
        		cnt <= 0;
        		sck <= ~sck;
        	end
        	else begin
        		cnt <= cnt + 1'b1;
        		sck <= sck;
        	end
        end
        else begin
        	cnt <= 0;
        	sck <= 1'b0;
        end
    end //else
end //always
//produce sck_p and sck_n;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sck_reg1 <= 1'b0;
        sck_reg2 <= 1'b0;
    end //if
    else begin
        sck_reg1 <= sck;
        sck_reg2 <= sck_reg1;    
    end //else
end //always
assign sck_p = (sck_reg1 & (~sck_reg2)); //sck posedge;
assign sck_n = ((~sck_reg1) & sck_reg2); //sck negedge;
//fsm;hot code;
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cstate <= IDEL;
	end
	else begin
		case (cstate)
	        IDEL:    cstate <= (wr)? SEND : IDEL; 
	        SEND:    cstate <= (send_over) ? FINISH : SEND; 
	        FINISH:  cstate <= IDEL;
	        default: cstate <= IDEL;
	    endcase //case
	end
end
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		cs <= 1'b1;
		data_cnt_en <= 1'b0;
		sck_en <= 1'b0;
		master_din_reg <= 0;
		master_dout <= 0;
	end
	else begin
	    case (cstate)
	        IDEL: begin
	        data_cnt_en <= 1'b0;
	        master_din_reg <= (wr) ? master_din : master_din_reg; //load the data you want send to slaver;
	        end 
	        SEND: begin
	            data_cnt_en <= 1'b1;
	            cs <= 1'b0; 
	            sck_en <= 1'b1;
	        	master_dout <= (send_over) ? master_dout_reg : master_dout; //master receiverd data;
	        end
	        FINISH: begin                  //send and load ok;
	        	sck_en <= 1'b0;
	        	cs <= 1'b1;
	        	data_cnt_en <= 1'b0;
	        end
	        default: begin
	        	cs <= 1'b1;
	        	sck_en <= 1'b0;
	        	data_cnt_en <= 1'b0;
	        end
	    endcase //case
	end
end
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		data_cnt <= 0;
	end
	else begin
		data_cnt <= (data_cnt_en) ? (data_cnt + 1'b1) : 5'd0; //4 div * 8bit = 32 cnt;
	end
end
assign send_over = (data_cnt == DATA_CNT_MAX) ? 1'b1 : 1'b0;
//rising edge miso;
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		master_dout_reg <= 0;
	end
	else begin
	    master_dout_reg <= (sck_p) ? {master_dout_reg[6:0],miso} : master_dout_reg;
	end
end
//mosi;
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mosi_cnt <= 0;
	end
	else begin
		if (sck_n) begin
			if (mosi_cnt == MOSI_CNT_MAX) begin
			    mosi_cnt <= 0;
		    end
		    else begin
			    mosi_cnt <= mosi_cnt + 1'b1;
		    end
		end
		else begin
			mosi_cnt <= mosi_cnt;
		end
	end
end
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		mosi <= 1'b0;
	end
	else begin
		mosi <= (sck_n) ? master_din_reg[MOSI_CNT_MAX-mosi_cnt] : mosi;
	end
end
endmodule