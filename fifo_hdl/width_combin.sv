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
module width_combin #(
    parameter   DSIZE   = 1,
    parameter   NSIZE   = 8
)(
    input                           clock,
    input                           rst_n,
    input [DSIZE-1:0]               wr_data,
    input                           wr_vld,
    output logic                    wr_ready,
    input                           wr_last,
    input                           wr_align_last,
    output logic[DSIZE*NSIZE-1:0]   rd_data,
    output logic                    rd_vld,
    input                           rd_ready,
    output logic                    rd_last
);

assign wr_ready = rd_ready;

localparam	RSIZE	= 	(NSIZE<16)?  4 :
						(NSIZE<32)?  5 :
      					(NSIZE<64)?  6 :
						(NSIZE<128)? 7 : 8;

//
reg [RSIZE-1:0]    point;

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  point   <= {RSIZE{1'b0}};
    else begin
        if(wr_vld && wr_ready)begin
            if(wr_align_last || wr_last)
                    point   <= {RSIZE{1'b0}};
            else begin
                if(point == NSIZE-1)
                        point   <= {RSIZE{1'b0}};
                else    point   <= point + 1'b1;
            end
        end else    point   <= point;
end end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  rd_data <= {(DSIZE*NSIZE){1'b0}};
    else begin
        if(wr_vld && wr_ready)
                rd_data[DSIZE*(NSIZE-point)-1-:DSIZE]   <= wr_data;
        else    rd_data[DSIZE*(NSIZE-point)-1-:DSIZE]   <= rd_data[DSIZE*(NSIZE-point)-1-:DSIZE];
    end
end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  rd_vld  <= 1'b0;
    else begin
        if(point==(NSIZE-1) && wr_vld && wr_ready )
                rd_vld  <= 1'b1;
        else if(rd_vld && rd_ready)
                rd_vld  <= 1'b0;
        else    rd_vld  <= rd_vld;
    end
end


always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  rd_last     <= 1'b0;
    else begin
        if(point==(NSIZE-1) && wr_vld && wr_ready )
                rd_last <= wr_last;
        else if(rd_vld && rd_ready)
                rd_last <= 1'b0;
        else    rd_last <= rd_last;
    end
end

endmodule
