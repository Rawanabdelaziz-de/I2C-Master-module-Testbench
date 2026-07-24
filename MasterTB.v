`timescale 1ns/100ps 

module Master_tb;
	//Inputs & Outputs
	reg clk, rst, start, stop, write;
	reg [6:0] addr;
	reg [7:0] data;
	wire SCL, busy, error, D_ready, ack;
	wire [7:0] data_out;

	//Bidirectional signals
	wire SDA;
	reg SDA_en, SDA_out;

	assign SDA = (SDA_en)? SDA_out : 1'bz;
	
	//Instantiation
	Master dut ( .clk(clk), .rst(rst), .start(start), .stop(stop), .write(write), .addr(addr), .data(data),
	.SDA(SDA),  .SCL(SCL), .busy(busy), .error(error), .D_ready(D_ready), .ack(ack), .data_out(data_out)
	);
	
	//clk
	always #20 clk = ~clk;

	//Inputs intialization 
	initial begin 
	clk = 0;
	rst = 0;
	start = 0;
	stop = 0;
	write = 0;
	addr = 7'b0000000;
	data = 8'b00000000;
	SDA_en = 0;
	SDA_out = 1;


	// case 1: reset 
	$display ("Case: Reset");
	rst = 0;
	@(negedge clk);
	rst = 1;
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("Reset is successful, IDLE is the current state");
	else
		$display ("Reset failed, current state is %b", dut.current_state);


	// case 2: IDLE
	$display ("Case: IDLE");
	start = 0;
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("Stays in IDLE!");
	else
		$display ("Left IDLE, current state is %b", dut.current_state);


	rst = 0; 
	@(negedge clk);
	rst = 1; 
	@(negedge clk);


	// case 3: Start
	$display ("Case: Start");
	addr = 7'b0000000;
	data = 8'b00000000;
	write = 1;
	stop = 1;
	start = 1;
	@(negedge clk);
	if (dut.current_state == 3'b001)
		$display ("Started...");
	else
		$display ("Start failed, current state is %b", dut.current_state);

	start = 0;
	@(negedge clk);
	if (dut.current_state == 3'b010)
		$display ("Passed");
	else
		$display ("Start failed, current state is %b", dut.current_state);


	rst = 0; 
	@(negedge clk);
	rst = 1; 
	@(negedge clk);


	//case 4: write with ack
	$display (" Write with ack");
	addr = 7'b1010101;
	data = 8'hAC;
	write = 1;
	stop = 1;
	start = 1;
	@(negedge clk);
	start = 0;
	repeat(8) @(negedge clk);
	if (dut.current_state == 3'b011)
		$display ("Passed: Here in state ack");
	else
		$display ("Failed: current state is %b", dut.current_state);
	
	SDA_en = 1;
	SDA_out = 0;
	@(negedge clk);
	if (ack == 1'b1)
		$display ("Ack siganl raised");
	else
		$display ("Failed: ack = %b", ack);

	if (dut.current_state == 3'b100)
		$display ("To state write after ack...");
	else
		$display ("Failed: current state is %b", dut.current_state);
	
	SDA_en = 0;

	repeat(8) @(negedge clk);
	if (dut.current_state == 3'b110)
		$display ("Stopped after data");
	else
		$display ("Failed: current state is %b", dut.current_state);
	
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("To IDLE...");
	else
		$display ("Failed: current state is %b", dut.current_state);
	

	//case 5: reset again
	rst = 0;
	@(negedge clk);
	rst = 1;
	@(negedge clk);


	//case 6: Nack
	$display (" No slave response");
	addr = 7'b1010111;
	data = 8'h00;
	write = 1;
	stop = 1;
	start = 1;
	@(negedge clk);
	start = 0;
	repeat(8) @(negedge clk);
	if (dut.current_state == 3'b011)
		$display ("Passed: Here in state ack");
	else
		$display ("Failed: current state is %b", dut.current_state);
	
	SDA_en = 0;
	@(negedge clk);
	if (error == 1'b1)
		$display ("Error! Nack");
	else
		$display ("Failed: error should be 1, got %b", error);

	if (ack == 1'b0)
		$display ("Not Acknowledged");
	else
		$display ("Failed: ack is %b", ack);

	if (dut.current_state == 3'b110)
		$display ("Stopped after Nack");
	else
		$display ("Failed: current state is %b", dut.current_state);
	
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("To IDLE...");
	else
		$display ("Failed: current state is %b", dut.current_state);
	

	rst = 0; 
	@(negedge clk);
	rst = 1; 
	@(negedge clk);


	//Case: 7 Read
	$display ("Reading...");
	addr = 7'b0110011;
	write = 0;
	stop = 1;
	start = 1;
	@(negedge clk);
	start = 0;
	repeat(8) @(negedge clk);
	if (dut.current_state == 3'b011)
		$display ("Passed: Here in state ack");
	else
		$display ("Failed: current state is %b", dut.current_state);
	
	SDA_en = 1;
	SDA_out = 0;
	@(negedge clk);

	if (dut.current_state == 3'b101)
		$display ("To read state after ack...");
	else
		$display ("Failed: current state is %b", dut.current_state);

	SDA_out = 1'b0; @(negedge clk);
	SDA_out = 1'b0; @(negedge clk);
	SDA_out = 1'b1; @(negedge clk);
	SDA_out = 1'b1; @(negedge clk);
	SDA_out = 1'b1; @(negedge clk);
	SDA_out = 1'b1; @(negedge clk);
	SDA_out = 1'b0; @(negedge clk);
	SDA_out = 1'b0; @(negedge clk);
	SDA_en = 0;

	// bits driven MSB-first: 0,0,1,1,1,1,0,0 = 8'h3C
	if (data_out == 8'h3C)
		$display ("Data passed: %h as expected", data_out);
	else
		$display ("Data passed: %h not as expected", data_out);
	
	if (D_ready == 1'b1)
		$display ("Data is ready!");
	else
		$display ("Data isn't ready!");
	
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("To IDLE...");
	else
		$display ("Failed: current state is %b", dut.current_state);
	

	rst = 0; 
	@(negedge clk);
	rst = 1; 
	@(negedge clk);
	 

	//case 8: SCL (Is it high at IDLE / Start / Stop?)
	$display ("SCL behavior");
	if (SCL == 1'b1)
		$display ("SCL = 1 in IDLE");
	else 
		$display ("SCL doesn't work right!");

	addr = 7'b0010010;
	data = 8'hFF;
	write = 1;
	stop = 1;
	start = 1;
	@(negedge clk);
	if (SCL == 1'b1)
		$display ("SCL = 1 in start state");
	else 
		$display ("SCL doesn't work right!");
	start = 0;

	rst = 0; 
	@(negedge clk);
	rst = 1; 
	@(negedge clk);


	//case 9: Mid transaction reset 
	$display ("Reset");
	addr = 7'b1111111;
	data = 8'hFF;
	write = 1;
	stop = 1;
	start = 1;
	@(negedge clk);
	start = 0;
	repeat (4) @(negedge clk);
	rst = 0;
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("To IDLE...");
	else
		$display ("Failed: current state is %b", dut.current_state);
	if (busy == 1'b0)
		$display ("Busy drops to 0");
	else 
		$display ("Failed, Busy is %b", busy);
	rst = 1;
	@(negedge clk);


	//case 10: Edge-values
	$display ("Edge- value all zeros");
	addr = 7'b0000000;
	data = 8'h00;
	write = 1;
	stop = 1;
	start = 1;
	@(negedge clk);
	start = 0;
	repeat (8) @(negedge clk);
	SDA_en = 1;
	SDA_out = 0;
	@(negedge clk);
	SDA_en = 0;
	repeat (8) @(negedge clk);
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("To IDLE...");
	else
		$display ("Failed: current state is %b", dut.current_state);

	rst = 0; 
	@(negedge clk);
	rst = 1; 
	@(negedge clk);

	$display ("Edge- value all ones");
	addr = 7'b1111111;
	data = 8'hFF;
	write = 1;
	stop = 1;
	start = 1;
	@(negedge clk);
	start = 0;
	repeat (8) @(negedge clk);
	SDA_en = 1;
	SDA_out = 0;
	@(negedge clk);
	SDA_en = 0;
	repeat (8) @(negedge clk);
	@(negedge clk);
	if (dut.current_state == 3'b000)
		$display ("To IDLE...");
	else
		$display ("Failed: current state is %b", dut.current_state);


	rst = 0; 
	@(negedge clk);
	rst = 1; 
	@(negedge clk);


	// case 11: Busy 
	$display ("Busy signal check");
	addr = 7'b0011100;
	data = 8'h77;
	write = 1;
	stop = 1;
	if (busy == 1'b0)
		$display ("Busy drops to 0");
	else 
		$display ("Failed, Busy is %b", busy);

	start = 1;
	@(negedge clk);
	if (busy == 1'b1)
		$display ("Busy going to 1 during starting...");
	else 
		$display ("Failed, Busy is %b", busy);

	start = 0;
	@(negedge clk);
	if (busy == 1'b1)
		$display ("Busy going to 1 during address state...");
	else 
		$display ("Failed, Busy is %b", busy);

	repeat(7) @(negedge clk);
	SDA_en = 1;
	SDA_out = 0;
	@(negedge clk);
	if (busy == 1'b1)
		$display ("Busy going to 1 during writing...");
	else 
		$display ("Failed, Busy is %b", busy);
	
	SDA_en = 0;
	repeat(8) @(negedge clk);
	@(negedge clk);
	if (busy == 1'b1)
		$display ("Busy going to 1 during stopping...");
	else 
		$display ("Failed, Busy is %b", busy);

	@(negedge clk);
	if (busy == 1'b0)
		$display ("Busy back to 0 in IDLE...");
	else 
		$display ("Failed, Busy is %b", busy);

	#50;
	$display("Finished :)");
	$finish;
	end
endmodule