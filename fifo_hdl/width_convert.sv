/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/21 上午9:48:19
madified:
***********************************************/
`timescale 1ns/1ps
module width_convert #(
    parameter   ISIZE   = 8,
    parameter   OSIZE   = 8
)(
    input                           clock,
    input                           rst_n,
    input [ISIZE-1:0]               wr_data,
    input                           wr_vld,
    output logic                    wr_ready,
    input                           wr_last,
    input                           wr_align_last,
    output logic[OSIZE-1:0]         rd_data,
    output logic                    rd_vld,
    input                           rd_ready,
    output                          rd_last
);

generate
if(ISIZE > OSIZE)begin
width_destruct #(
    .DSIZE      (OSIZE          ),
    .NSIZE      (ISIZE/OSIZE    )
)width_destruct_inst(
/*  input                    */       .clock        (clock        ),
/*  input                    */       .rst_n        (rst_n        ),
/*  input [DSIZE*NSIZE-1:0]  */       .wr_data      (wr_data      ),
/*  input                    */       .wr_vld       (wr_vld       ),
/*  output logic             */       .wr_ready     (wr_ready     ),
/*  input                    */       .wr_last      (wr_last      ),
/*  output logic[DSIZE-1:0]  */       .rd_data      (rd_data      ),
/*  output logic             */       .rd_vld       (rd_vld       ),
/*  output logic             */       .rd_last      (rd_last      ),
/*  input                    */       .rd_ready     (rd_ready     )
);
end else if(ISIZE<OSIZE)begin
width_combin #(
    .DSIZE  (ISIZE      ),
    .NSIZE  (OSIZE/ISIZE)
)width_combin_inst(
/*   input                        */   .clock             (clock         ),
/*   input                        */   .rst_n             (rst_n         ),
/*   input [DSIZE-1:0]            */   .wr_data           (wr_data       ),
/*   input                        */   .wr_vld            (wr_vld        ),
/*   output logic                 */   .wr_ready          (wr_ready      ),
/*   input                        */   .wr_last           (wr_last       ),
/*   input                        */   .wr_align_last     (wr_align_last ),
/*   output logic[DSIZE*NSIZE-1:0]*/   .rd_data           (rd_data       ),
/*   output logic                 */   .rd_vld            (rd_vld        ),
/*   input                        */   .rd_ready          (rd_ready      ),
/*   output                       */   .rd_last           (rd_last       )
);
end else begin

assign    wr_ready  = rd_ready;
assign    rd_data   = wr_data;
assign    rd_vld    = wr_vld;
assign    rd_last   = wr_last;

end
endgenerate

endmodule
