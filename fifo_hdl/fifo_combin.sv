/**********************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
descript:
author : Young
Version: VERA.0.0
creaded: 2016/11/19 下午3:21:13
madified:
***********************************************/
`timescale 1ns/1ps
module fifo_combin #(
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

localparam	RSIZE	= 	(NSIZE<16)?  4+1 :
						(NSIZE<32)?  5+1 :
      					(NSIZE<64)?  6+1 :
						(NSIZE<128)? 7+1 : 8+1;

reg [0:DSIZE*NSIZE*2-1]    shift_regs;
reg                shift_regs_vld;
reg [RSIZE-1:0]    point;

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  shift_regs  <= {(DSIZE*NSIZE){1'b0}};
    else begin
        shift_regs  <= shift_regs;
        if(wr_vld && wr_ready)
                shift_regs[point*DSIZE+:DSIZE] <= wr_data;
        else    shift_regs[point*DSIZE+:DSIZE] <= shift_regs[point*DSIZE+:DSIZE];
    end
end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  point   <= {RSIZE{1'b0}};
    else begin
        if(wr_vld && wr_ready)begin
            if(wr_align_last)
                    point   <= {RSIZE{1'b0}};
            else begin
                if(point == NSIZE*2-1)
                        point   <= {RSIZE{1'b0}};
                else    point   <= point + 1'b1;
            end
        end else    point   <= point;
end end


assign #1 rd_vld       = shift_regs_vld;

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  wr_ready    <= 1'b0;
    else begin
        if(shift_regs_vld && !rd_ready)
                wr_ready    <= 1'b0;
        else    wr_ready    <= 1'b1;
    end
end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  point   <= {NSIZE{1'b0}};
    else begin
        if(wr_vld && wr_ready && (point == NSIZE-1 || point == 2*NSIZE-1))
            shift_regs_vld  <= 1'b1;
        else if(rd_vld && rd_ready)
            shift_regs_vld  <= 1'b0;
        else
            shift_regs_vld  <= shift_regs_vld;
    end
end

//
always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  rd_data   <= {(NSIZE*DSIZE){1'b0}};
    else begin
        if(wr_vld && wr_ready)begin
            if(point == NSIZE-1)
                    rd_data <= {shift_regs[0:NSIZE*DSIZE-1-DSIZE],wr_data};
            else if(point == 2*NSIZE-1)
                    rd_data <= {shift_regs[NSIZE*DSIZE:NSIZE*DSIZE*2-1-DSIZE],wr_data};
            else    rd_data <= rd_data;
        end else    rd_data <= rd_data;
    end
end

endmodule
