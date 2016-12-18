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
module fifo_destruct #(
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


logic       odd_even;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  odd_even    <= 1'b0;
    else begin
        if(wr_ready && wr_vld)
                odd_even    <= ~odd_even;
        else    odd_even    <= odd_even;
    end

logic [DSIZE*NSIZE-1:0]     wr_data_buf;
logic                       wr_buf_vld;
logic                       wr_buf_req;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  wr_buf_vld  <= 1'b0;
    else begin
        case({wr_vld,wr_buf_vld,wr_buf_req})
        3'b000:     wr_buf_vld  <= 1'b0;
        3'b001:     wr_buf_vld  <= 1'b0;
        3'b010:     wr_buf_vld  <= 1'b1;
        3'b011:     wr_buf_vld  <= 1'b0;
        3'b100:     wr_buf_vld  <= 1'b1;
        3'b101:     wr_buf_vld  <= 1'b1;
        3'b110:     wr_buf_vld  <= 1'b1;
        3'b111:     wr_buf_vld  <= 1'b0;
        default:    wr_buf_vld  <= 1'b0;
        endcase
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n)  wr_data_buf  <= {(DSIZE*NSIZE){1'b0}};
    else begin
        case({wr_vld,wr_buf_vld,wr_buf_req})
        3'b000:     wr_data_buf  <= wr_data_buf;
        3'b001:     wr_data_buf  <= wr_data_buf;
        3'b010:     wr_data_buf  <= wr_data_buf;
        3'b011:     wr_data_buf  <= wr_data_buf;
        3'b100:     wr_data_buf  <= wr_data;
        3'b101:     wr_data_buf  <= wr_data;
        3'b110:     wr_data_buf  <= wr_data_buf;
        3'b111:     wr_data_buf  <= wr_data;
        default:    wr_data_buf  <= wr_data_buf;
        endcase
    end

// assign wr_buf_req = wr_ready;


localparam	RSIZE	= 	(NSIZE<16)?  4 :
						(NSIZE<32)?  5 :
      					(NSIZE<64)?  6 :
						(NSIZE<128)? 7 : 8;

logic [RSIZE-1:0]       point;

always@(posedge clock,negedge rst_n)
    if(~rst_n)  point   <= {RSIZE{1'b0}}+1'b0;
    else begin
        if(rd_vld && rd_ready)begin
            if(point < NSIZE-1)
                    point <= point + 1'b1;
            else    point <= {RSIZE{1'b0}};
        end else    point <= point;
    end



always@(posedge clock,negedge rst_n)
    if(~rst_n) rd_data  <= {DSIZE{1'b0}};
    else begin
        case({wr_buf_vld,rd_vld,rd_ready})
        3'b000: rd_data <= rd_data;
        3'b001: rd_data <= rd_data;
        3'b010: rd_data <= rd_data;
        3'b011: rd_data <= rd_data;
        3'b100: rd_data <= wr_buf_req? wr_data[DSIZE*(NSIZE-point)-1-:DSIZE] : wr_data_buf[DSIZE*(NSIZE-point)-1-:DSIZE];
        3'b101: rd_data <= wr_buf_req? wr_data[DSIZE*(NSIZE-point)-1-:DSIZE] : wr_data_buf[DSIZE*(NSIZE-point)-1-:DSIZE];
        3'b110: rd_data <= rd_data;
        3'b111: rd_data <= wr_buf_req? wr_data[DSIZE*(NSIZE-point)-1-:DSIZE] : wr_data_buf[DSIZE*(NSIZE-point)-1-:DSIZE];
        default:rd_data <= rd_data;
        endcase
    end

always@(posedge clock,negedge rst_n)
    if(~rst_n) rd_vld  <= {1{1'b0}};
    else begin
        case({wr_buf_vld,rd_vld,rd_ready})
        3'b000: rd_vld <= 1'b0;
        3'b001: rd_vld <= 1'b0;
        3'b010: rd_vld <= 1'b1;
        3'b011: rd_vld <= 1'b0;
        3'b100: rd_vld <= 1'b1;
        3'b101: rd_vld <= 1'b1;
        3'b110: rd_vld <= 1'b1;
        3'b111: rd_vld <= 1'b1;
        default:rd_vld <= 1'b0;
        endcase
    end


// always@(posedge clock,negedge rst_n)
//     if(~rst_n)  wr_ready    <= 1'b0;
//     else begin
//         if(rd_vld && rd_ready && point==(NSIZE-1))
//                 wr_ready    <= 1'b1;
//         else if(wr_ready && wr_vld)
//                 wr_ready    <= 1'b0;
//         else    wr_ready    <= wr_ready;
//     end

// always@(posedge clock,negedge rst_n)
//     if(~rst_n)  wr_buf_req    <= 1'b0;
//     else begin
//         if(rd_vld && rd_ready && point==(NSIZE-1))
//                 wr_buf_req    <= 1'b1;
//         else if(wr_buf_vld)
//                 wr_buf_req    <= 1'b0;
//         else    wr_buf_req    <= wr_buf_req;
//     end

//
assign wr_buf_req = rd_vld && rd_ready && point==(NSIZE-1);

assign wr_ready = !wr_buf_vld;

endmodule
