/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/20 上午10:42:40
madified:
***********************************************/
`timescale 1ns/1ps
module data_pipe_nto1 #(
    parameter   DSIZE   = 1,
    parameter   NSIZE   = 8
)(
    input                           clock,
    input                           rst_n,
    input [DSIZE*NSIZE-1:0]         wr_data,
    input                           wr_vld,
    output logic                    wr_ready,
    output logic[DSIZE-1:0]         rd_data,
    output logic                    rd_vld,
    input                           rd_ready
);


logic[NSIZE-1:0]   fifo_full;
logic[NSIZE-1:0]   fifo_empty;

logic[DSIZE-1:0]            ds_wr_data  [NSIZE-1:0];
logic[NSIZE-1:0]            ds_wr_vld;
logic[NSIZE-1:0]            ds_wr_en;

genvar KK;
generate
for(KK=0;KK<NSIZE;KK++)begin
fifo_hdl_verb #(
	.DSIZE		(DSIZE		),
	.DEPTH		(4     ),
	.ALMOST		(1      ),
	.DEF_VALUE	(0      ),
    .FIRST_WORD_FALL_THROUGH    ("ON")
)fifo_hdl_inst(
	//--->> WRITE PORT <<-----
/*	input				*/	.wr_clk			(clock		),
/*	input				*/	.wr_rst_n       (rst_n		),
/*	input				*/	.wr_en          (wr_vld     ),
/*	input [DSIZE-1:0]	*/	.wr_data        (wr_data[DSIZE*KK+:DSIZE]    ),
/*	output[4:0]			*/	.wr_count       (           ),
/*	output				*/	.full           (fifo_full[KK]  ),
/*	output				*/	.almost_full    (           ),
	//--->> READ PORT <<------
/*	input				*/	.rd_clk			(clock		),
/*	input				*/	.rd_rst_n       (rst_n      ),
/*	input				*/	.rd_en          (ds_wr_en[KK]   ),
/*	output[DSIZE-1:0]	*/	.rd_data        (ds_wr_data[KK] ),
/*	output[4:0]			*/	.rd_count       (           ),
/*	output				*/	.empty          (fifo_empty[KK] ),
/*	output				*/	.almost_empty   (           )
);

assign ds_wr_vld[KK]    = !fifo_empty[KK];
end
endgenerate

assign wr_ready     = !fifo_full[0];

localparam	RSIZE	= 	(NSIZE<16)?  4 :
						(NSIZE<32)?  5 :
      					(NSIZE<64)?  6 :
						(NSIZE<128)? 7 : 8;

logic [RSIZE-1:0]       point;
logic                   en_point;

assign en_point = |(ds_wr_en & (~fifo_empty));

always@(posedge clock,negedge rst_n)
    if(~rst_n)  point   <= NSIZE-1;
    else begin
        if(en_point)begin
            if(point != {RSIZE{1'b0}})
                    point <= point - 1'b1;
            else    point <= NSIZE-1;
        end else    point <= point;
    end


logic   out_fifo_full;
logic   out_fifo_empty;

generate
for(KK=0;KK<NSIZE;KK++)
    assign ds_wr_en[KK]  = !out_fifo_full && (point==KK);
endgenerate

fifo_hdl_verb #(
	.DSIZE		(DSIZE		),
	.DEPTH		(4     ),
	.ALMOST		(1      ),
	.DEF_VALUE	(0      ),
    .FIRST_WORD_FALL_THROUGH    ("ON")
)fifo_hdl_inst_out(
	//--->> WRITE PORT <<-----
/*	input				*/	.wr_clk			(clock		),
/*	input				*/	.wr_rst_n       (rst_n		),
/*	input				*/	.wr_en          (ds_wr_vld[point]    ),
/*	input [DSIZE-1:0]	*/	.wr_data        (ds_wr_data[point]   ),
/*	output[4:0]			*/	.wr_count       (           ),
/*	output				*/	.full           (out_fifo_full       ),
/*	output				*/	.almost_full    (           ),
	//--->> READ PORT <<------
/*	input				*/	.rd_clk			(clock		),
/*	input				*/	.rd_rst_n       (rst_n      ),
/*	input				*/	.rd_en          (rd_ready   ),
/*	output[DSIZE-1:0]	*/	.rd_data        (rd_data    ),
/*	output[4:0]			*/	.rd_count       (           ),
/*	output				*/	.empty          (out_fifo_empty ),
/*	output				*/	.almost_empty   (           )
);

assign rd_vld   = !out_fifo_empty;

endmodule
