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
module width_destruct #(
    parameter   DSIZE   = 1,
    parameter   NSIZE   = 8
)(
    input                           clock,
    input                           rst_n,
    input [DSIZE*NSIZE-1:0]         wr_data,
    input                           wr_vld,
    output logic                    wr_ready,
    input                           wr_last,
    output logic[DSIZE-1:0]         rd_data,
    output logic                    rd_vld,
    output logic                    rd_last,
    input                           rd_ready
);

// assign rd_vld   = wr_vld;

localparam	RSIZE	= 	(NSIZE<16)?  4 :
						(NSIZE<32)?  5 :
      					(NSIZE<64)?  6 :
						(NSIZE<128)? 7 : 8;

//
reg [RSIZE-1:0]    point;

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  point   <= {RSIZE{1'b0}};
    else begin
        if(wr_vld && rd_ready)begin
            if(point == NSIZE-1)
                    point   <= {RSIZE{1'b0}};
            else    point   <= point + 1'b1;
        end else    point   <= point;
end end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  wr_ready  <= 1'b0;
    else begin
        if(point==(NSIZE-2) && wr_vld && rd_ready)
                wr_ready <= 1'b1;
        else if(wr_ready && wr_vld)
                wr_ready <= 1'b0;
        else    wr_ready <= wr_ready;
    end
end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  rd_data <= {DSIZE{1'b0}};
    else begin
        if(wr_vld && rd_ready)
                rd_data <= wr_data[DSIZE*(NSIZE-point)-1-:DSIZE];
        else    rd_data <= rd_data;
    end
end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  rd_vld  <= 1'b0;
    else begin
        case({wr_vld,rd_vld,rd_ready})
        3'b000: rd_vld  <= 1'b0;
        3'b001: rd_vld  <= 1'b0;
        3'b010: rd_vld  <= 1'b1;
        3'b011: rd_vld  <= 1'b0;
        3'b100: rd_vld  <= 1'b0;
        3'b101: rd_vld  <= 1'b1;
        3'b110: rd_vld  <= 1'b1;
        3'b111: rd_vld  <= 1'b1;
        default:rd_vld  <= 1'b0;
        endcase
    end
end

always@(posedge clock,negedge rst_n)begin
    if(~rst_n)  rd_last  <= 1'b0;
    else begin
        case({wr_vld,rd_vld,rd_ready})
        3'b000: rd_last  <= 1'b0;
        3'b001: rd_last  <= 1'b0;
        3'b010: rd_last  <= rd_last;
        3'b011: rd_last  <= 1'b0;
        3'b100: rd_last  <= 1'b0;
        3'b101: rd_last  <= point==(NSIZE-2) && wr_last;
        3'b110: rd_last  <= rd_last;
        3'b111: rd_last  <= point==(NSIZE-2) && wr_last;
        default:rd_last  <= 1'b0;
        endcase
    end
end


endmodule
