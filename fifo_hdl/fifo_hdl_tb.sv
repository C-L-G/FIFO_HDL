/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  fifo_hdl_tb.sv
--Project Name: FIFO_HDL
--Data modified: 2016-01-19 17:16:15 +0800
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module fifo_hdl_tb;


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
logic [7:0]		wr_data;
logic [7:0]		rd_data;
logic 			wr_en,rd_en;
logic			rst_n;
string			disp = "";

task wr_data_burst (int cnt);
begin
	wr_en	= 1;
	wr_data	= 0;
	repeat(cnt)begin
		@(posedge wr_clk);
		wr_data	= wr_data + 1;
	end
	wr_data = 0;
	wr_en = 0;
	@(posedge wr_clk);
end
endtask:wr_data_burst

task rd_data_burst (int cnt);
begin
	rd_en	= 1;
	repeat(cnt)begin
		@(posedge rd_clk);  
	end
	rd_en	= 0;
	@(posedge rd_clk);
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
			rd_data_burst(100);
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
			rd_data_burst(5);
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
			wr_data_burst(5);
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
	wr_en	= 0;
	rd_en	= 0;
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


fifo_hdl #(
	.DSIZE		(8		),
	.DEPTH		(16     ),
	.ALMOST		(3      ),
	.DEF_VALUE	(0      )
)fifo_hdl_inst(
	//--->> WRITE PORT <<-----
/*	input				*/	.wr_clk			(wr_clk		),	 			
/*	input				*/	.wr_rst_n       (rst_n		), 
/*	input				*/	.wr_en          (wr_en      ),
/*	input [DSIZE-1:0]	*/	.wr_data        (wr_data    ),
/*	output[4:0]			*/	.wr_count       (           ),
/*	output				*/	.full           (           ),
/*	output				*/	.almost_full    (           ),
	//--->> READ PORT <<------                          
/*	input				*/	.rd_clk			(rd_clk		),		
/*	input				*/	.rd_rst_n       (rst_n      ),
/*	input				*/	.rd_en          (rd_en      ),
/*	output[DSIZE-1:0]	*/	.rd_data        (           ),
/*	output[4:0]			*/	.rd_count       (           ),
/*	output				*/	.empty          (           ),
/*	output				*/	.almost_empty   (           )
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

logic test;

always_comb
	test	= fifo_hdl_inst.wr_step^fifo_hdl_inst.rd_step;

endmodule
