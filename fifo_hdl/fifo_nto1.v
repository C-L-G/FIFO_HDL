/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  fifo_nto1.v
--Project Name: FIFO_HDL
--Data modified: 2016-01-19 17:16:15 +0800
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module fifo_nto1 #(
	parameter				DSIZE		= 1	,
	parameter				NSIZE		= 8	,	//1 2 4 8 16
	parameter				DEPTH		= 2	,	//8*n
	parameter				ALMOST		= 2	,
	parameter[DSIZE-1:0]	DEF_VALUE 	= 0
)(
	input					wr_clk			,
	input					wr_rst_n        ,
	input					wr_en           ,
	input [DSIZE*NSIZE-1:0]	wr_data         ,
	output					wr_full         ,
	output					wr_almost_full  ,
	output[4*NSIZE-1:0]		wr_count        ,
	input					rd_clk          ,
	input					rd_rst_n		,
	input					rd_en           ,
	output[DSIZE-1:0]		rd_data         ,
	output					rd_empty        ,
	output					rd_almost_empty ,
	output[4*NSIZE-1:0]		rd_count        ,
	output					rd_vld			
);

localparam	WDEPTH	= DEPTH,
			RDEPTH	= DEPTH * NSIZE;

//--->> RESET BLOCK <<----- 
wire	rst_n;
assign	rst_n	= wr_rst_n && rd_rst_n;
//---<< RESET BLOCK >>-----
reg 	wr_full_flag,rd_full_flag;
reg		wr_empty_flag,rd_empty_flag;
reg 	wr_step,rd_step;
//--->> RING <<------
localparam	WRSIZE	= 	(WDEPTH<16)?  4 : 
						(WDEPTH<32)?  5 :
      					(WDEPTH<64)?  6 :
						(WDEPTH<128)? 7 : 8; 

localparam	RRSIZE	= 	(RDEPTH<16)?  4 : 
						(RDEPTH<32)?  5 :
      					(RDEPTH<64)?  6 :
						(RDEPTH<128)? 7 : 8; 

localparam	SFBIT	= 	(NSIZE == 1)?  0 : 
						(NSIZE == 2)?  1 :
      					(NSIZE == 4)?  2 :
						(NSIZE == 8)?  3 : 4; 


reg	[WRSIZE-1:0]	wr_point;
reg [RRSIZE-1:0]	rd_point;

wire	rd_down_wr,wr_up_rd;
assign	rd_down_wr	= (wr_step^rd_step) || (rd_point < (wr_point<<SFBIT));
assign	wr_up_rd	= !(wr_step^rd_step)|| (wr_point < rd_point[RRSIZE-1:SFBIT]);

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		wr_point	<= {WRSIZE{1'b0}};
	else begin
		if(wr_en && wr_up_rd && !wr_full_flag)begin
			if(wr_point == WDEPTH-1)
					wr_point	<= {WRSIZE{1'b0}};
			else	wr_point	<= wr_point + 1'b1;
		end else 	wr_point	<= wr_point;
	end

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_point	<= {RRSIZE{1'b0}};
	else begin
		if(rd_en && rd_down_wr)begin
			if(rd_point == RDEPTH-1)
					rd_point	<= {RRSIZE{1'b0}};
			else	rd_point	<= rd_point + 1'b1;
		end else	rd_point	<= rd_point;
	end

//---<< RING >>------
//--->> STEP <<------

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		wr_step	<= 1'b0;
	else begin
		if(wr_point == WDEPTH-1 && wr_en && !wr_full_flag)
					wr_step	<= ~wr_step;
		else		wr_step	<= wr_step;
	end

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_step	<= 1'b0;
	else begin
		if(rd_point == RDEPTH-1 && rd_en && !rd_empty_flag)
					rd_step	<= ~rd_step;
		else		rd_step	<= rd_step;
	end
//---<< STEP >>-----------
//--->> FULL EMPTY <<-----
wire		rd_point_tail;
localparam	TT_SFBIT = (SFBIT==0)? 1 : SFBIT;
assign	rd_point_tail	= (SFBIT==0)? 1'b0 : |rd_point[0+:TT_SFBIT];

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_full_flag	<= 1'b0;
	else 		wr_full_flag	<= 	(wr_step ^ rd_step) && 
									(wr_point >= rd_point[RRSIZE-1:SFBIT]);

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_full_flag	<= 1'b0;
	else 		rd_full_flag	<= (wr_step ^ rd_step) && ((wr_point<<SFBIT) >= rd_point);

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_empty_flag	<= 1'b1;
	else 		rd_empty_flag	<= !(wr_step^rd_step) && ((wr_point<<SFBIT) <= rd_point);

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_empty_flag	<= 1'b1;
	else 		wr_empty_flag	<= !(wr_step^rd_step) && ((wr_point<<SFBIT) <= rd_point);
//---<< FULL EMPTY >>------------
//--->> ALMOST FULL EMPTY <<-----
reg 	wr_almost_full_flag,rd_almost_full_flag;
reg		wr_almost_empty_flag,rd_almost_empty_flag;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_almost_full_flag	<= 1'b0;
	else 		wr_almost_full_flag	<= {wr_step^rd_step,wr_point,{SFBIT{1'b0}}} >= (((WDEPTH-ALMOST)<<SFBIT) + rd_point);

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_almost_full_flag	<= 1'b0;
	else 		rd_almost_full_flag	<= {wr_step^rd_step,wr_point,{SFBIT{1'b0}}} >= (((WDEPTH-ALMOST)<<SFBIT) + rd_point);

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_almost_empty_flag	<= 1'b1;
	else 		rd_almost_empty_flag	<= {wr_step^rd_step,wr_point,{SFBIT{1'b0}}} <= (ALMOST+rd_point);

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_almost_empty_flag	<= 1'b1;
	else 		wr_almost_empty_flag	<= {wr_step^rd_step,wr_point,{SFBIT{1'b0}}} <= (ALMOST+rd_point);
//---<< ALMOST FULL EMPTY >>-----
//--->> MEM <<-------------------
reg [DSIZE-1:0]	data [RDEPTH-1:0];

always@(posedge wr_clk,negedge rst_n)begin:MEM_BLOCK
integer	II;
	if(~rst_n)begin
		for(II=0;II<RDEPTH;II=II+1)
			data[II]	<= DEF_VALUE;
	end else begin
		if(wr_en && !wr_full_flag)begin
			for(II=0;II<NSIZE;II=II+1)
				data[wr_point*NSIZE+II]	<= wr_data[DSIZE*(NSIZE-1-II)+:DSIZE];
		end else begin
			for(II=0;II<RDEPTH;II=II+1)
				data[II]	<= data[II];
end end end

reg [DSIZE-1:0]		rd_data_reg;

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_data_reg	<= DEF_VALUE;
	else			rd_data_reg	<= data[rd_point];
//---<< MEM >>-------------------
//--->> WR RD COUNTER <<---------
reg [4*NSIZE:0]	wr_cnt_reg,rd_cnt_reg;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_cnt_reg	<= 5'd0;
	else if(wr_full_flag)
				wr_cnt_reg	<= RDEPTH;
	else if(wr_empty_flag)
				wr_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				wr_cnt_reg	<= ((WDEPTH+wr_point)<<SFBIT)-rd_point;
	else		wr_cnt_reg	<= (wr_point<<SFBIT) - rd_point;

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_cnt_reg	<= 5'd0;
	else if(rd_full_flag)
				rd_cnt_reg	<= RDEPTH;
	else if(rd_empty_flag)
				rd_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				rd_cnt_reg	<= ((WDEPTH+wr_point)<<SFBIT)-rd_point;
	else		rd_cnt_reg	<= (wr_point<<SFBIT) - rd_point;
//---<< WR RD COUNTER >>---------
//--->> VALID <<-----------------
wire 	rd_en_lat2	;
latency #(
	.LAT		(1		),
	.DSIZE		(1		)
)latency_inst(
	.clk		(rd_clk			),
	.rst_n      (rst_n			),
	.d          (rd_en			),
	.q          (rd_en_lat2		)
);  

assign	rd_vld	= rd_en_lat2 && !rd_empty_flag;
//---<< VALID >>-----------------

assign	wr_full			= wr_full_flag;
assign	rd_empty		= rd_empty_flag;
assign	wr_almost_full	= wr_almost_full_flag;
assign	rd_almost_empty	= rd_almost_empty_flag;

assign	rd_data		= rd_data_reg;

assign	wr_count	= wr_cnt_reg;
assign	rd_count	= rd_cnt_reg;

endmodule

