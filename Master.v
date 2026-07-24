module Master (
	input clk, rst,
	input start, stop, write,
	input [6:0] addr,
	input [7:0] data,
	inout SDA,
	output reg busy, error, D_ready, SCL, ack,
	output reg [7:0] data_out
);
	
	//internal signals
	reg [2:0] bit_cnt;
	reg SDA_en, SDA_out, SCL_clk;
	reg [7:0] addr_shift, data_shift;

	//states definition
	localparam state_IDLE = 3'b000, //SDA=1, SCL=1
		state_start = 3'b001,
		state_addr = 3'b010,
		state_ack = 3'b011,
		state_write = 3'b100,
		state_read = 3'b101,
		state_stop = 3'b110;

	reg [2:0] current_state, next_state;

	//SDA transmits or recieves? ==> master or slave
	assign SDA = (SDA_en)? SDA_out : 1'bz;

	//genarate clk signal ==> SCL_clk = clk/2
	always @(negedge clk or negedge rst) begin
		if (!rst) begin
			SCL_clk <= 1'b1;
		end
		else begin
			SCL_clk <= ~SCL_clk;
		end
	end

	//SCL high while starting, stopping, or nothing happens 
	always @(*) begin
		if (current_state == state_IDLE || current_state == state_start || current_state == state_stop)
			SCL = 1'b1;
		else 
			SCL = SCL_clk;
		end

	//Initiaition ==> counter to make sure all bits transmitted or recieved & add the w/r bit after addr & write and read conditions
	always @(negedge clk or negedge rst) begin
		if (!rst) begin
			current_state <= state_IDLE;
			bit_cnt <= 3'b000;
			data_out <= 8'b00000000;
			addr_shift <= 8'b00000000;
			data_shift <= 8'b00000000;
		end
		else begin 
			current_state <= next_state;
			if (current_state == state_addr || current_state == state_write || current_state == state_read) begin 
				bit_cnt <= bit_cnt + 1'b1;
			end 
			else begin
				bit_cnt <= 3'b000;
			end

			if (current_state == state_start) begin
				addr_shift <= (addr << 1) | write;
			end
			else if (current_state == state_addr) begin
				addr_shift <= addr_shift << 1;
			end

			if (current_state == state_ack && write) begin
				data_shift <= data;
			end
			else if (current_state == state_write) begin
				data_shift <= data_shift << 1;
			end

			if (current_state == state_read) begin
				data_out <= {data_out[6:0], SDA};
			end
		end
	end

	//states
	always @(*) begin
		next_state = current_state;
		busy = 1'b1;
		error = 1'b0;
		D_ready = 1'b0;
		SDA_en = 1'b1;
		SDA_out = 1'b1;
		ack = 1'b0;

		case (current_state)
			state_IDLE: begin
				busy = 1'b0;
				SDA_out = 1'b1;
				if (start)
					next_state = state_start;
				else 
					next_state = state_IDLE;
			end

			state_start: begin
				SDA_out = 1'b0;
				next_state = state_addr;
			end

			state_addr: begin
				SDA_out = addr_shift[7];

				if (bit_cnt == 3'b111)
					next_state = state_ack;
				else	
					next_state = state_addr;
			end

			state_ack: begin
				SDA_en = 1'b0;

				if (SDA == 1'b0) begin
					ack = 1'b1;
					if (write)
						next_state = state_write;
					else
						next_state = state_read;
				end 
				else begin
					ack = 1'b0;
					error = 1'b1;
					next_state = state_stop;
				end
			end 

			state_write: begin
				SDA_out = data_shift[7];

				if (bit_cnt == 3'b111) begin
					if (stop)
						next_state = state_stop;
					else
						next_state = state_IDLE;
				end 
				else begin
					next_state = state_write;
				end
			end 

			state_read: begin
				SDA_en = 1'b0;

				if (bit_cnt == 3'b111) begin
					D_ready = 1'b1;
					if (stop)
						next_state = state_stop;
					else
						next_state = state_IDLE;
				end 
				else begin
					next_state = state_read;
				end
			end 
			
			state_stop: begin
				SDA_out = 1'b1;
				next_state = state_IDLE;
			end

			default: begin 
				next_state = state_IDLE;
			end
		endcase
	end
endmodule 