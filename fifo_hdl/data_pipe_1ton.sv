/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/19 下午4:18:02
madified:
***********************************************/
`timescale 1ns/1ps
module data_pipe_1ton #(
    parameter   DSIZE   = 1,
    parameter   NSIZE   = 8
)(
    input                           clock,
    input                           rst_n,
    input [DSIZE-1:0]               wr_data,
    input                           wr_vld,
    output logic                    wr_ready,
    input                           wr_align_last,
    output logic[DSIZE*NSIZE-1:0]   rd_data,
    output logic                    rd_vld,
    input                           rd_ready
);


logic[DSIZE*NSIZE-1:0]  cb_rd_data         ;
logic                   cb_rd_vld          ;
logic                   cb_rd_ready        ;

fifo_combin #(
    .DSIZE   (DSIZE     ),
    .NSIZE   (NSIZE     )
)fifo_combin_inst(
/*  input                         */  .clock               (clock           ),
/*  input                         */  .rst_n               (rst_n           ),
/*  input [DSIZE-1:0]             */  .wr_data             (wr_data         ),
/*  input                         */  .wr_vld              (wr_vld          ),
/*  output logic                  */  .wr_ready            (wr_ready        ),
/*  input                         */  .wr_align_last       (wr_align_last   ),
/*  output logic[DSIZE*NSIZE-1:0] */  .rd_data             (cb_rd_data      ),
/*  output logic                  */  .rd_vld              (cb_rd_vld       ),
/*  input                         */  .rd_ready            (cb_rd_ready     )
);

logic   fifo_empty;
logic   fifo_full;

fifo_hdl_verb #(
	.DSIZE		(DSIZE*NSIZE		),
	.DEPTH		(4     ),
	.ALMOST		(1      ),
	.DEF_VALUE	(0      ),
    .FIRST_WORD_FALL_THROUGH    ("ON")
)fifo_hdl_inst(
	//--->> WRITE PORT <<-----
/*	input				*/	.wr_clk			(clock		),
/*	input				*/	.wr_rst_n       (rst_n		),
/*	input				*/	.wr_en          (cb_rd_vld   ),
/*	input [DSIZE-1:0]	*/	.wr_data        (cb_rd_data ),
/*	output[4:0]			*/	.wr_count       (           ),
/*	output				*/	.full           (fifo_full  ),
/*	output				*/	.almost_full    (           ),
	//--->> READ PORT <<------
/*	input				*/	.rd_clk			(clock		),
/*	input				*/	.rd_rst_n       (rst_n      ),
/*	input				*/	.rd_en          (rd_ready   ),
/*	output[DSIZE-1:0]	*/	.rd_data        (rd_data    ),
/*	output[4:0]			*/	.rd_count       (           ),
/*	output				*/	.empty          (fifo_empty ),
/*	output				*/	.almost_empty   (           )
);


assign  cb_rd_ready = !fifo_full;
assign  rd_vld      = !fifo_empty;

endmodule
