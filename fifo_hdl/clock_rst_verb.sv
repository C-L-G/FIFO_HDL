/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  clock_rst_verb.sv
--Project Name: FIFO_HDL
--Data modified: 2016-01-19 17:16:15 +0800
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module clock_rst_verb #(
	parameter bit		ACTIVE			= 1,	
	parameter longint	PERIOD_CNT		= 0,
	parameter			RST_HOLD		= 5,
	parameter real		FreqM			= 100
)(
	output			clock,
	output			rst_x
);

bit clk_pause = 1;
bit	clock_reg;
bit	rst_reg;

longint ccnt = 0;

initial begin
	clk_pause	= 1;
	clock_reg	= 0;
	rst_reg		= ACTIVE;
	#(1000/FreqM*2);
	clk_pause	= 0;
	repeat(RST_HOLD)
		@(posedge clock_reg);
	rst_reg		= ~rst_reg;
end

always #(1000/FreqM/2) begin
	if(clk_pause == 0 && (PERIOD_CNT==0 || ccnt < PERIOD_CNT))
		clock_reg	= ~clock_reg;
end

always@(posedge clock)
	ccnt	<= ccnt + 1;

assign	clock	= clock_reg;
assign	rst_x	= rst_reg;

endmodule
	
