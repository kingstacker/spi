//************************************************
//  Filename      : spi_sm.v                             
//  Author        : Kingstacker                  
//  Company       : School                       
//  Email         : kingstacker_work@163.com     
//  Device        : Altera cyclone4 ep4ce6f17c8  
//  Description   : spi slaver module,mode is 0 ;data 8bit;                           
//************************************************
module  spi_sm #(parameter WIDTH = 8)(
    //input;
    input    wire    clk,
    input    wire    rst_n,
    input    wire    cs,  //slave select;
    input    wire    sck, //data exchange clock;
    input    wire    [WIDTH-1:0]    slaver_din, //the data you want send;
    input    wire    mosi, //the data form master;
    //output;
    output   reg     miso, //slaver out;
    output   reg     [WIDTH-1:0]    slaver_dout  //the data you received;
);
localparam MISO_CNT_MAX = 3'd7;
reg cs_reg1;
reg cs_reg2;
reg sck_reg1;
reg sck_reg2;
wire cs_p;  //posedge cs;
wire cs_n;  //negedge cs;
wire sck_p; //posedge sck;
wire sck_n; //negedge sck;
reg [WIDTH-1:0] slaver_din_reg; 
reg [WIDTH-1:0] slaver_dout_reg;
reg [2:0] miso_cnt;
//produce cs_p and cs_n;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        cs_reg1 <= 1'b0;
        cs_reg2 <= 1'b0;
    end //if
    else begin
        cs_reg1 <= cs;
        cs_reg2 <= cs_reg1;    
    end //else
end //always
assign cs_p = (cs_reg1 & (~cs_reg2)); //cs posedge;
assign cs_n = ((~cs_reg1) & cs_reg2); //cs negedge;
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
//you want send data registed;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        slaver_din_reg <= 0;
    end //if
    else begin
        slaver_din_reg <= (cs_n) ? slaver_din :slaver_din_reg;
    end //else
end //always
//recieved data ;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        slaver_dout <= 0;
    end //if
    else begin
        slaver_dout <= (cs_p) ? slaver_dout_reg : slaver_dout;    
    end //else
end //always
//sck negedge sample mosi; 
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        slaver_dout_reg <= 0;
    end //if
    else begin
        slaver_dout_reg <= (sck_n) ? {slaver_dout_reg[6:0],mosi} : slaver_dout_reg;    
    end //else
end //always
//miso cnt;
always @(posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		miso_cnt <= 0;
	end
	else begin
		if (sck_p) begin
			if (miso_cnt == MISO_CNT_MAX) begin
			    miso_cnt <= 0;
		    end
		    else begin
			    miso_cnt <= miso_cnt + 1'b1;
		    end
		end
		else begin
			miso_cnt <= miso_cnt;
		end
	end
end
//sck posedge output the miso;
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        miso <= 0;
    end //if
    else begin
        miso <= (sck_p) ? slaver_din_reg[MISO_CNT_MAX-miso_cnt] : miso;    
    end //else
end //always

endmodule