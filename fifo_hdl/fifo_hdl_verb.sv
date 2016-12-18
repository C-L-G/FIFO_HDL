/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  fifo_hdl.v
--Project Name: FIFO_HDL
--Data modified: 2016-01-19 17:16:15 +0800
--author:Young-
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module fifo_hdl_verb #(
	parameter				DSIZE		= 8,
	parameter				DEPTH		= 16,
	parameter				ALMOST		= 3,
	parameter[DSIZE-1:0]	DEF_VALUE	= 0,
    parameter               FIRST_WORD_FALL_THROUGH = "ON"
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
reg     inner_rd_en;
wire    rd_en_tri;
wire    buf_vld;
generate
if(FIRST_WORD_FALL_THROUGH=="ON")
    assign rd_en_tri = (rd_en && buf_vld) || inner_rd_en;
else
    assign rd_en_tri = rd_en;
endgenerate

localparam	RSIZE	= 	(DEPTH<16)?  4 :
						(DEPTH<32)?  5 :
      					(DEPTH<64)?  6 :
						(DEPTH<128)? 7 : 8;

reg	[RSIZE-1:0]	wr_point,rd_point;

//--->> RESET BLOCK <<-----
wire	rst_n;
assign	rst_n	= wr_rst_n && rd_rst_n;
//---<< RESET BLOCK >>-----
reg 	full_flag,empty_flag;
reg 	wr_step,rd_step;


// reg	[RSIZE-1:0]	    wr_point;
// reg [RSIZE-1:0]	    rd_point;
reg [DEPTH-1:0]     rd_b_flag;
reg [DEPTH-1:0]     wr_b_flag;

always@(posedge wr_clk,negedge rst_n)begin
    if(~rst_n)  wr_b_flag   <= {DEPTH{1'b0}};
    else begin
        if(wr_en && !full_flag)begin
            if(wr_b_flag[wr_point] == rd_b_flag[wr_point])
                    wr_b_flag[wr_point] <= !wr_b_flag[wr_point];
            else    wr_b_flag[wr_point] <= wr_b_flag[wr_point];
        end else    wr_b_flag           <= wr_b_flag;
end end

always@(posedge rd_clk,negedge rst_n)begin
    if(~rst_n)  rd_b_flag   <= {DEPTH{1'b0}};
    else begin
        if((/*rd_en||*/rd_en_tri) && !empty_flag)begin
            if(rd_b_flag[rd_point] != wr_b_flag[rd_point])
                    rd_b_flag[rd_point] <= ~rd_b_flag[rd_point];
            else    rd_b_flag[rd_point] <= rd_b_flag[rd_point];
        end else    rd_b_flag           <= rd_b_flag;
end end

//--->> RING <<------

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		wr_point	<= {RSIZE{1'b0}};
	else begin
		if(wr_en && !full_flag)begin
			if(wr_point == DEPTH-1)
					wr_point	<= {RSIZE{1'b0}};
			else	wr_point	<= wr_point + 1'b1;
		end else 	wr_point	<= wr_point;
	end

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_point	<= {RSIZE{1'b0}};
	else begin
		if((/*rd_en||*/rd_en_tri) && !empty_flag)begin
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
		if(rd_point == DEPTH-1 && (/*rd_en||*/rd_en_tri) && !empty_flag)
					rd_step	<= ~rd_step;
		else		rd_step	<= rd_step;
	end
//---<< STEP >>-----------
//--->> FULL EMPTY <<-----
reg	[RSIZE-1:0]	next_wr_point;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)		next_wr_point	<= {RSIZE{1'b0}}+1'b1;
	else begin
		if(wr_en && /*wr_up_rd &&*/ !full_flag)begin
			if(next_wr_point == DEPTH-1)
					next_wr_point	<= {RSIZE{1'b0}};
			else	next_wr_point	<= next_wr_point + 1'b1;
		end else 	next_wr_point	<= next_wr_point;
	end

reg	[RSIZE-1:0]	next_rd_point;

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		next_rd_point	<= {RSIZE{1'b0}}+1'b1;
	else begin
		if((/*rd_en||*/rd_en_tri) && /*wr_up_rd &&*/ !empty_flag)begin
			if(next_rd_point == DEPTH-1)
					next_rd_point	<= {RSIZE{1'b0}};
			else	next_rd_point	<= next_rd_point + 1'b1;
		end else 	next_rd_point	<= next_rd_point;
	end

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	full_flag	<= 1'b0;
	// else 		full_flag	<= wr_b_flag[wr_point] != rd_b_flag[wr_point_rd];
    else begin
        if(wr_en && !full_flag)
                full_flag	<= wr_b_flag[next_wr_point] != rd_b_flag[next_wr_point];
        else    full_flag	<= wr_b_flag[wr_point] != rd_b_flag[wr_point];
    end

    always@(posedge rd_clk,negedge rst_n)
    	if(~rst_n)	empty_flag	<= 1'b1;
    	else begin
            if((rd_en_tri) && !empty_flag && FIRST_WORD_FALL_THROUGH=="ON")
                    empty_flag	<= rd_b_flag[next_rd_point] == wr_b_flag[next_rd_point];
         	else    empty_flag	<= rd_b_flag[rd_point] == wr_b_flag[rd_point];
        end
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
		if(wr_en && !full_flag)
				data[wr_point]	<= wr_data;
		else	data[wr_point]	<= data[wr_point];
end end

reg [DSIZE-1:0]		rd_data_reg;

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)		rd_data_reg	<= DEF_VALUE;
	else
    	if(rd_en)
                rd_data_reg	<= data[rd_point];
        else    rd_data_reg <= rd_data_reg;
//---<< MEM >>-------------------
//--->> WR RD COUNTER <<---------
reg [4:0]	wr_cnt_reg,rd_cnt_reg;

always@(posedge wr_clk,negedge rst_n)
	if(~rst_n)	wr_cnt_reg	<= 5'd0;
	else if(full_flag)
				wr_cnt_reg	<= DEPTH;
	// else if(empty_flag)
	// 			wr_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				wr_cnt_reg	<= (DEPTH+wr_point)-rd_point;
	else		wr_cnt_reg	<= wr_point - rd_point;

always@(posedge rd_clk,negedge rst_n)
	if(~rst_n)	rd_cnt_reg	<= 5'd0;
	// else if(full_flag)
	// 			rd_cnt_reg	<= DEPTH;
	else if(empty_flag)
				rd_cnt_reg	<= 5'd0;
	else if(wr_step^rd_step)
				rd_cnt_reg	<= (DEPTH+wr_point)-rd_point;
	else		rd_cnt_reg	<= wr_point - rd_point;
//---<< WR RD COUNTER >>---------
//--->> FIRST_WORD_FALL_THROUGH <<--------------------
logic[DSIZE-1:0]        ff_rd_data;
logic                   ff_rd_data_vld;
logic[9-1:0]            ff_rd_count;
logic                   ff_empty;
logic                   first_ff_vld_exec;
always@(posedge rd_clk,negedge rst_n)
    if(~rst_n)      ff_rd_data_vld  <= 1'b0;
    else begin
        case({ff_rd_data_vld,rd_en,!empty_flag})
        3'b000: ff_rd_data_vld  <= 1'b0;
        3'b001: ff_rd_data_vld  <= 1'b1;
        3'b010: ff_rd_data_vld  <= 1'b0;
        3'b011: ff_rd_data_vld  <= 1'b1;
        3'b100: ff_rd_data_vld  <= 1'b1;
        3'b101: ff_rd_data_vld  <= 1'b1;
        3'b110: ff_rd_data_vld  <= 1'b0;
        3'b111: ff_rd_data_vld  <= 1'b1;
        default:ff_rd_data_vld  <= 1'b0;
        endcase
    end

always@(posedge rd_clk,negedge rst_n)
    if(~rst_n)      first_ff_vld_exec  <= 1'b0;
    else begin
        case({ff_rd_data_vld,rd_en,!empty_flag})
        3'b000: first_ff_vld_exec  <= first_ff_vld_exec;
        3'b001: first_ff_vld_exec  <= 1'b1;
        3'b010: first_ff_vld_exec  <= first_ff_vld_exec;
        3'b011: first_ff_vld_exec  <= 1'b1;
        3'b100: first_ff_vld_exec  <= 1'b1;
        3'b101: first_ff_vld_exec  <= 1'b1;
        3'b110: first_ff_vld_exec  <= first_ff_vld_exec;
        3'b111: first_ff_vld_exec  <= 1'b1;
        default:first_ff_vld_exec  <= first_ff_vld_exec;
        endcase
    end

//
always@(posedge rd_clk,negedge rst_n)
    if(~rst_n)      ff_empty  <= 1'b1;
    else begin
        case({ff_rd_data_vld,rd_en,!empty_flag})
        3'b000: ff_empty  <= ~(1'b0) || 1'b0 ;  // ~ff_rd_data_vld || inner_rd_en
        3'b001: ff_empty  <= ~(1'b1) || 1'b1 ;  //
        3'b010: ff_empty  <= ~(1'b0) || 1'b0 ;  //
        3'b011: ff_empty  <= ~(1'b1) || 1'b1 ;  //
        3'b100: ff_empty  <= ~(1'b1) || 1'b0 ;  //
        3'b101: ff_empty  <= ~(1'b1) || 1'b0 ;  //
        3'b110: ff_empty  <= ~(1'b0) || 1'b0 ;  //
        3'b111: ff_empty  <= ~(1'b1) || 1'b0 ;  //
        default:ff_empty  <= ~(1'b0) || 1'b0 ;  //
        endcase
    end

always@(posedge rd_clk,negedge rst_n)
    if(~rst_n)      ff_rd_data  <= 1'b0;
    else begin
        case({ff_rd_data_vld,rd_en,!empty_flag})
        3'b000: ff_rd_data  <= ff_rd_data;
        3'b001: ff_rd_data  <= data[rd_point];
        3'b010: ff_rd_data  <= ff_rd_data;
        3'b011: ff_rd_data  <= data[rd_point];
        3'b100: ff_rd_data  <= ff_rd_data;
        3'b101: ff_rd_data  <= ff_rd_data;
        3'b110: ff_rd_data  <= ff_rd_data;
        3'b111: ff_rd_data  <= data[rd_point];
        default:ff_rd_data  <= ff_rd_data;
        endcase
    end

generate
if(FIRST_WORD_FALL_THROUGH == "ON")
// assign inner_rd_en = rd_en && ff_rd_data_vld;
always@(posedge rd_clk,negedge rst_n)
    if(~rst_n)      inner_rd_en  <= 1'b0;
    else begin
        case({ff_rd_data_vld,rd_en,!empty_flag})
        3'b000: inner_rd_en  <= 1'b0;
        3'b001: inner_rd_en  <= 1'b1;
        3'b010: inner_rd_en  <= 1'b0;
        3'b011: inner_rd_en  <= 1'b1;
        3'b100: inner_rd_en  <= 1'b0;
        3'b101: inner_rd_en  <= 1'b0;
        3'b110: inner_rd_en  <= 1'b0;
        3'b111: inner_rd_en  <= 1'b0;
        default:inner_rd_en  <= 1'b0;
        endcase
    end
else
assign inner_rd_en = rd_en;
endgenerate

//
// always@(posedge rd_clk,negedge rst_n)
//     if(~rst_n)  ff_rd_count <= 9'd0;
//     else begin
//         if(ff_rd_data_vld)
//                 ff_rd_count <= rd_cnt_reg+1'b1;
//         else    ff_rd_count <= rd_cnt_reg;
//     end


// assign	rd_vld	= ff_rd_data_vld;
// assign	rd_empty= !ff_rd_data_vld;
assign	rd_data	= ff_rd_data;
// assign  rd_count= ff_rd_count;

assign buf_vld = ff_rd_data_vld;
//---<< FIRST_WORD_FALL_THROUGH >>--------------------

assign	full		= full_flag;
assign	empty		= FIRST_WORD_FALL_THROUGH=="OFF"? empty_flag : ff_empty;
assign	almost_full	= almost_full_flag;
assign	almost_empty= almost_empty_flag;

assign	rd_data		= FIRST_WORD_FALL_THROUGH=="OFF"? rd_data_reg : ff_rd_data;

assign	wr_count	= wr_cnt_reg;
assign	rd_count	= rd_cnt_reg;

endmodule
