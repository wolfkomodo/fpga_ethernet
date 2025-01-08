`timescale 1 ns / 1 ps

module tx_scheduler
(
	input wire clk_50mhz,        // ref_clk for PHY
    input wire clk_50mhz_phased, // Clock used for logic
	input wire rst_n,            // active low reset
	
	output wire eth_mdc,         // Management Data Clock
    inout  wire eth_mdio,        // Management Data I/O
    output wire eth_rstn,        // Ethernet PHY Reset
    input  wire eth_crsdv,       // Carrier Sense/Data Valid
    input  wire eth_rxerr,       // Receive Error
    input  logic [1:0] eth_rxd,   // Receive Data
    output logic eth_txen,        // Transmit Enable
    output logic [1:0] eth_txd,   // Transmit Data
    output wire eth_refclk,      // Reference Clock (50 MHz)
    input  wire eth_intn,        // Interrupt (Active Low)
	
	input  wire tx_valid,     // Data valid bit
	input logic [7:0] tx_data,     // Byte to tx
	input  wire tx_sof,     // Start Of File signal
	input  wire tx_eof,     // End Of File signal
	output logic tx_ack      // Ack
);

	localparam STATE_IDLE = 0;
	localparam STATE_PREAMBLE = 1;
	localparam STATE_BODY = 2;
	localparam STATE_PAD = 3;
	localparam STATE_CRC1 = 4;
	localparam STATE_CRC2 = 5;
	localparam STATE_CRC3 = 6;
	localparam STATE_IFG = 7;
	logic [2:0] state, next_state;
	always_ff @(posedge clk_50mhz_phased) begin
		if(eth_rstn)
			state <= next_state;
		else
			state <= STATE_IDLE;
	end
	
	logic [1:0] bit_counter = 0;
	wire toggle_byte;
    assign toggle_byte = &bit_counter;
	logic [7:0] current_byte, next_byte;
	logic current_valid, next_valid;
	always_ff @(posedge clk_50mhz_phased) begin
		bit_counter <= bit_counter + 1;
		if(bit_counter == 3) begin
			current_byte <= next_byte;
			current_valid <= next_valid;
		end
		
		eth_txen <= current_valid && eth_rstn;
		case(bit_counter)
			0: eth_txd <= current_byte[1:0];
			1: eth_txd <= current_byte[3:2];
			2: eth_txd <= current_byte[5:4];
			3: eth_txd <= current_byte[7:6];
		endcase
	end
	// logic [10:0] tester;
	logic [10:0] byte_counter;
	logic [4:0]  ifg_counter;
	always_ff @(posedge clk_50mhz_phased) begin
		if(state == STATE_IDLE)
			byte_counter <= 0;
		else
			byte_counter <= byte_counter + toggle_byte;
			
		if(state == STATE_IFG)
			ifg_counter <= ifg_counter + toggle_byte;
		else
			ifg_counter <= 0;
	end
	
	logic [31:0] crc32_code;
	logic push_crc;
	crc32 crc32_inst
	(
		.clk (clk_50mhz_phased),
		.rst (state == STATE_IDLE),
		.valid (toggle_byte && push_crc),
		.data(next_byte),
		.crc (crc32_code)
	);
	
	always @(*) begin
		next_state = state;
		next_byte = 0;
		next_valid = 0;
		tx_ack = 0;
		push_crc = 0;
		
		case(state)
			STATE_IDLE: begin
				if(tx_sof) 
					next_state = STATE_PREAMBLE;
			end STATE_PREAMBLE: begin
				if(toggle_byte) begin
					next_valid = 1;
					if(byte_counter < 7) begin
						next_byte = 8'h55;
					end else begin
						next_byte = 8'hd5;
						next_state = STATE_BODY;
					end
				end
			end STATE_BODY: begin
				if(toggle_byte) begin
                    tx_ack = 1;
					if(tx_eof) begin
						if(byte_counter < 72) begin
							next_state = STATE_PAD;
							next_byte = 0;
							next_valid = 1;
							push_crc = 1;
                            // tester <= byte_counter;

						end else begin
							next_state = STATE_CRC1;
							next_byte = crc32_code[31:24];
							next_valid = 1;
						end
					end else begin
						next_byte = tx_data;
						next_valid = 1;
						push_crc = 1;
					end
				end
			end STATE_PAD: begin
				if(toggle_byte) begin
					if(byte_counter < 72) begin
						next_valid = 1;
						next_byte = 0;
						push_crc = 1;
					end else begin
						next_valid = 1;
						next_byte = crc32_code[31:24];
						next_state = STATE_CRC1;
					end
				end
			end STATE_CRC1: begin
				if(toggle_byte) begin
					next_valid = 1;
					next_byte = crc32_code[23:16];
					next_state = STATE_CRC2;
				end
			end STATE_CRC2: begin
				if(toggle_byte) begin
					next_valid = 1;
					next_byte = crc32_code[15:8];
					next_state = STATE_CRC3;
				end
			end STATE_CRC3: begin
				if(toggle_byte) begin
					next_valid = 1;
					next_byte = crc32_code[7:0];
					next_state = STATE_IFG;
				end
			end STATE_IFG: begin
				if(ifg_counter >= 13)
					next_state = STATE_IDLE;
			end
		endcase
	end
    localparam START_RESET = 20000;
    logic [31:0] clk_divider = 32'b0;
    logic reset_n = 0;
    assign eth_rstn = reset_n;
    logic [17:0] rst_clk = 0;
    always_ff @(posedge clk_50mhz) begin
        clk_divider <= clk_divider + 1;
        if (rst_clk > START_RESET) begin
            reset_n <= 1;
        end else begin
            reset_n <= 0;
            rst_clk <= rst_clk + 1;
        end
    end
    assign eth_mdio = 1'bz;
    assign eth_mdc = clk_divider[4];
    assign eth_refclk = clk_50mhz;

    logic [15:0] transmission_attempts;
    always_ff @(posedge clk_50mhz_phased) begin
        if (state == STATE_IDLE && reset_n) begin
            transmission_attempts <= transmission_attempts + 1;
        end
    end


endmodule