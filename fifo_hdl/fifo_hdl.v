/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  fifo_hdl.v
--Project Name: FIFO_HDL
--Data modified: 2016-01-19 17:16:15 +0800
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module fifo_hdl #(
	parameter				DSIZE		= 8,
	parameter				DEPTH		= 16,
	parameter				ALMOST		= 3,
	parameter[DSIZE-1:0]	DEF_VALUE	= 0
)(
	//--->> WRITE PORT <<-----
	input				wr_clk 			,
	input				wr_rst_n        ,
	input				wr_en           ,
	input [DSIZE-1:0]	wr_data         ,
	output[4:0]			wr_count        ,
	output				full            ,
	output				almost_full     ,
	//--->> READ PORT <<------
	input				rd_clk			,
	input				rd_rst_n        ,
	input				rd_en           ,
	output[DSIZE-1:0]	rd_data         ,
	output[4:0]			rd_count        ,
	output				empty           ,
	output				almost_empty
);
//--->> RESET BLOCK <<----- 
wire	rst_n;
assign	rst_n	= wr_rst_n && rd_rst_n;
//---<< RESET BLOCK >>-----
reg 	full_flag,empty_flag;
reg 	wr_step,rd_step;
//--->> RING <<------
localparam	RSIZE	= 	(DEPTH<16)?  4 : 
						(DEPTH<32)?  5 :
      					(DEPTH<64)?  6 :
						(DEPTH<128)? 7 : 8; 

reg	[RSIZE-1:0]	wr_point,rd_point;

wire	rd_down_wr,wr_up_rd;
assign	rd_down_wr	= (wr_step^rd_step) || (rd_point < wr_point);
assign	wr_up_rd	= !(wr_step^rd_step)|| (wr_point < rd_point);

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		wr_point	<= {RSIZE{1'b0}};
	else begin
		if(wr_en && wr_up_rd)begin
			if(wr_point == DEPTH-1)
					wr_point	<= {RSIZE{1'b0}};
			else	wr_point	<= wr_point + 1'b1;
		end else 	wr_point	<= wr_point;
	end

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_point	<= {RSIZE{1'b0}};
	else begin
		if(rd_en && rd_down_wr)begin
			if(rd_point == DEPTH-1)
					rd_point	<= {RSIZE{1'b0}};
			else	rd_point	<= rd_point + 1'b1;
		end else	rd_point	<= rd_point;
	end

//---<< RING >>------
//--->> STEP <<------

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		wr_step	<= 1'b0;
	else begin
		if(wr_point == DEPTH-1 && wr_en && !full_flag)
					wr_step	<= ~wr_step;
		else		wr_step	<= wr_step;
	end

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_step	<= 1'b0;
	else begin
		if(rd_point == DEPTH-1 && rd_en && !empty_flag)
					rd_step	<= ~rd_step;
		else		rd_step	<= rd_step;
	end
//---<< STEP >>-----------
//--->> FULL EMPTY <<-----
always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	full_flag	<= 1'b0;
	else 		full_flag	<= (wr_step ^ rd_step) && (wr_point >= rd_point);

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	empty_flag	<= 1'b1;
	else 		empty_flag	<= !(wr_step^rd_step) && (wr_point <= rd_point);
//---<< FULL EMPTY >>------------
//--->> ALMOST FULL EMPTY <<-----
reg 	almost_full_flag,almost_empty_flag;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	almost_full_flag	<= 1'b0;
	else 		almost_full_flag	<= {wr_step^rd_step,wr_point} >= ((DEPTH-ALMOST) + rd_point);

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	almost_empty_flag	<= 1'b1;
	else 		almost_empty_flag	<= {wr_step^rd_step,wr_point} <= (ALMOST+rd_point);
//---<< ALMOST FULL EMPTY >>-----
//--->> MEM <<-------------------
reg [DSIZE-1:0]	data [DEPTH-1:0];

always@(posedge wr_clk,negedge rst_n)begin:MEM_BLOCK
integer	II;
	if(~rst_n)begin
		for(II=0;II<DEPTH;II=II+1)
			data[II]	<= DEF_VALUE;
	end else begin
		if(wr_en)
				data[wr_point]	<= wr_data;
		else	data[wr_point]	<= data[wr_point];
end end

reg [DSIZE-1:0]		rd_data_reg;

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_data_reg	<= DEF_VALUE;
	else			rd_data_reg	<= data[rd_point];
//---<< MEM >>-------------------
//--->> WR RD COUNTER <<---------
reg [4:0]	wr_cnt_reg,rd_cnt_reg;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_cnt_reg	<= 5'd0;
	else if(full_flag)
				wr_cnt_reg	<= DEPTH;
	else if(empty_flag)
				wr_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				wr_cnt_reg	<= (DEPTH+wr_point)-rd_point;
	else		wr_cnt_reg	<= wr_point - rd_point;

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_cnt_reg	<= 5'd0;
	else if(full_flag)
				rd_cnt_reg	<= DEPTH;
	else if(empty_flag)
				rd_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				rd_cnt_reg	<= (DEPTH+wr_point)-rd_point;
	else		rd_cnt_reg	<= wr_point - rd_point;
//---<< WR RD COUNTER >>---------

assign	full		= full_flag;
assign	empty		= empty_flag;
assign	almost_full	= almost_full_flag;
assign	almost_empty= almost_empty_flag;

assign	rd_data		= rd_data_reg;

assign	wr_count	= wr_cnt_reg;
assign	rd_count	= rd_cnt_reg;

endmodule

