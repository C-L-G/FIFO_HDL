/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  fifo_hdl_tb.sv
--Project Name: FIFO_HDL
--Data modified: 2016-01-19 17:16:15 +0800
--author:Young-����
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module data_pipe_1ton_tb;


bit		rd_clk;
bit		rd_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(148		)
)clock_rst_read(
	.clock			(rd_clk			),
	.rst_x			(rd_rst_n		)
);

bit		wr_clk;
bit		wr_rst_n;

clock_rst_verb #(
	.ACTIVE			(0			),
	.PERIOD_CNT		(0			),
	.RST_HOLD		(5			),
	.FreqM			(148		)
)clock_rst_write(
	.clock			(wr_clk			),
	.rst_x			(wr_rst_n		)
);

//---->> DATA TASK <<--------
localparam  DSIZE = 4,
            NSIZE = 2;
logic [DSIZE-1:0]		wr_data;
logic [NSIZE*DSIZE-1:0]		rd_data;
logic 			wr_vld,rd_vld;
logic           wr_ready,rd_ready;
logic			rst_n;
string			disp = "";


int     wbcnt;
task wr_data_burst (int cnt);
bit     add_en;
int     acnt;
begin
	wr_vld	= 1;
	wr_data	= 0;
    wbcnt = 0;
    acnt = 0;
	while(wbcnt < cnt)begin
		@(negedge wr_clk);
        add_en  = wr_ready;
        @(posedge wr_clk);
		wr_data	= wr_data + add_en;
        if(add_en)
            wbcnt++;
        acnt ++;
        if(acnt > 200)
            break;
	end
	wr_data = 0;
	wr_vld = 0;
	@(posedge wr_clk);
    $display("BURST WR COMPLETE");
end
endtask:wr_data_burst

task rd_data_burst (int cnt);
int bcnt;
int acnt;
begin
	rd_ready = #1 1;
    bcnt    = 0;
    acnt    = 0;
	while(bcnt < cnt)begin
		@(negedge rd_clk);
        if(rd_vld)
            bcnt++;
        @(posedge rd_clk);
        acnt++;
        if(acnt > 200)
            break;
	end
	rd_ready	= 0;
	@(posedge rd_clk);
    $display("BURST RD COMPLETE");
end
endtask:rd_data_burst

task normol_wr_rd;
begin
	disp	= "normol wr rd";
	fork
		begin
			wr_data_burst(100);
		end
		begin
			repeat(10)begin
				@(posedge wr_clk);
			end
			rd_data_burst(100/NSIZE);
		end
	join
	disp	= "";
end
endtask:normol_wr_rd


task wr_full;
begin
disp	= "write full";
	fork
		begin
			wr_data_burst(30);
		end
		begin
			repeat(10)begin
				@(posedge wr_clk);
			end
			rd_data_burst(5/NSIZE);
		end
	join
disp	= "";
end
endtask:wr_full

task rd_empty;
begin
disp	= "read empty";
	fork
		begin
			wr_data_burst(5*NSIZE);
		end
		begin
			repeat(10)begin
				@(posedge wr_clk);
			end
			rd_data_burst(30);
		end
	join
disp	= "";
end
endtask:rd_empty

task reset_task;
	wr_vld	= 0;
	rd_ready	= 0;
	rst_n	= 0;
	repeat(10)begin
		@(posedge wr_clk);
		@(posedge rd_clk);
	end
	rst_n	= 1;
endtask:reset_task

task wr_full_to_read_empty;
wr_full;
rd_empty;
endtask:wr_full_to_read_empty

//---->> DATA GEN <<-------

data_pipe_1ton #(
    .DSIZE      (4),
    .NSIZE      (2)
)data_pipe_1ton_inst(
/*    input                         */  .clock            (wr_clk       ),
/*    input                         */  .rst_n            (rst_n        ),
/*    input [DSIZE-1:0]             */  .wr_data          (wr_data      ),
/*    input                         */  .wr_vld           (wr_vld       ),
/*    output logic                  */  .wr_ready         (wr_ready     ),
/*    input                         */  .wr_align_last    (             ),
/*    output logic[DSIZE*NSIZE-1:0] */  .rd_data          (             ),
/*    output logic                  */  .rd_vld           (rd_vld       ),
/*    input                         */  .rd_ready         (rd_ready     )
);

//---->> TEST <<------
initial begin
	wait(wr_rst_n);
	reset_task;
	repeat(10);
		@(posedge wr_clk);
	normol_wr_rd;
	reset_task;
	wr_full;
	reset_task;
	rd_empty;
	reset_task;
	wr_full_to_read_empty;
end


endmodule
