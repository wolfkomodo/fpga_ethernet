// `timescale 1 ns / 1 ps
// module top_level (
//     input  wire clk_100mhz,      // 100 MHz input clock
//     output wire eth_mdc,         // Management Data Clock
//     inout  wire eth_mdio,        // Management Data I/O
//     output wire eth_rstn,        // Ethernet PHY Reset
//     input  wire eth_crsdv,       // Carrier Sense/Data Valid
//     input  wire eth_rxerr,       // Receive Error
//     input  wire [1:0] eth_rxd,   // Receive Data
//     output wire eth_txen,        // Transmit Enable
//     output wire [1:0] eth_txd,   // Transmit Data
//     output wire eth_refclk,      // Reference Clock (50 MHz)
//     input  wire eth_intn         // Interrupt (Active Low)
// );

//     localparam START_RESET = 200_000;
//     localparam IFG_CYCLES = 48;
//     reg start_transmission = 1;
    
//     wire clk_50mhz;             // 50 MHz clock for Ethernet PHY
//     wire clk_50mhz_phased;      // 50 MHz clock with 45 deg phase for inputs
//     reg reset_n = 0;            // Active-low reset
//     reg [31:0] clk_divider = 32'b0;
//     reg [17:0] rst_clk = 0;
//     reg [1:0] rxd = 2'b11;
//     reg crs = 1;

//     // Frame transmission logic
//     reg [7:0] tx_frame [0:75];  // Frame data to send
//     integer tx_index;
//     reg [1:0] tx_data;
//     reg tx_enable;
//     reg [3:0] bit_counter;
//     reg [5:0] ifg_counter = 0;
    
//     typedef enum logic [1:0] {
//         IDLE = 2'b00,
//         TRANSMITTING = 2'b01,
//         IFG_WAIT = 2'b10
//     } tx_state_t;
//     tx_state_t tx_state;

//     assign eth_rstn = reset_n;
//     assign eth_txen = tx_enable;
//     assign eth_txd  = tx_data;
//     assign eth_refclk = clk_50mhz;
//     // assign eth_rxd = rxd;
//     // assign eth_crsdv = crs;

//     // logic clk_100mhz_passthrough;
//     always_ff @(posedge clk_100mhz) begin
//         clk_divider <= clk_divider + 1;
//         if (rst_clk > START_RESET) begin
//             reset_n <= 1;
//         end else begin
//             reset_n <= 0;
//             rst_clk <= rst_clk + 1;
//             // eth_crsdv = 0;
//             // eth_rxd[1] = 1;
//             // eth_rxd[0] = 1;
//         end
//     end


//     // assign clk_50mhz = clk_divider[0];
//     // clk_wiz_4_clk_wiz wizard_net
//     // (.clk_in1(clk_100mhz),
//     // //  .clk_out1(clk_100mhz_passthrough),
//     //  .clk_out2(clk_50mhz_phased),
//     //  .clk_out5(clk_50mhz),
//     //  .reset(0));
//     assign clk_50mhz_phased = clk_divider[0];
//     assign clk_50mhz = clk_divider[0];

    

//     // reg [15:0] transmission_attempts;
//     // always_ff @(posedge clk_50mhz_phased) begin
//     //     if (tx_state == IDLE && reset_n) begin
//     //         transmission_attempts <= transmission_attempts + 1;
//     //     end
//     // end
//     // assign led[3] = transmission_attempts[15];  // Blink to show attempts

//     // assign led[0] = (tx_state == IFG_WAIT);  // LED on during transmission
//     // assign led[2] = tx_enable;  // Another LED to show tx_enable signal


//     always_ff @(posedge clk_50mhz_phased) begin
//         if (reset_n) begin
//             case (tx_state)
//                 IDLE: begin
//                     if (start_transmission) begin
//                         tx_enable <= 1'b0;
//                         tx_index <= 0;
//                         bit_counter <= 0;
//                         ifg_counter <= 0;
//                         tx_state <= TRANSMITTING;
//                     end
//                 end

//                 TRANSMITTING: begin
//                     if (tx_index < 76) begin
//                         case (bit_counter)
//                             2'b00: tx_data <= tx_frame[tx_index][1:0];
//                             2'b01: tx_data <= tx_frame[tx_index][3:2];
//                             2'b10: tx_data <= tx_frame[tx_index][5:4];
//                             2'b11: begin
//                                 tx_data <= tx_frame[tx_index][7:6];
//                                 tx_index <= tx_index + 1;
//                             end
//                         endcase
//                         bit_counter <= (bit_counter == 2'b11) ? 0 : bit_counter + 1;
//                         tx_enable <= 1'b1;
//                     end else begin
//                         tx_enable <= 1'b0;
//                         tx_index <= 0;
//                         bit_counter <= 0;
//                         tx_data <= 0;
//                         tx_state <= IFG_WAIT;
//                     end
//                 end

//                 IFG_WAIT: begin
//                     if (ifg_counter < IFG_CYCLES) begin
//                         ifg_counter <= ifg_counter + 1;
//                     end else begin
//                         ifg_counter <= 0;
//                         tx_state <= IDLE;
//                     end
//                 end
//             endcase
//         end else begin
//             tx_enable <= 1'b0;
//             tx_index <= 0;
//             bit_counter <= 0;
//             ifg_counter <= 0;
//             tx_state <= IDLE;
//         end
//     end

//     initial begin
//         tx_index = 0;
//         bit_counter = 0;
//         tx_enable = 0;
//         tx_data = 2'b00;

//         // // Preamble and SFD
//         // tx_frame[0]  = 8'h55; tx_frame[1]  = 8'h55; tx_frame[2]  = 8'h55; 
//         // tx_frame[3]  = 8'h55; tx_frame[4]  = 8'h55; tx_frame[5]  = 8'h55;
//         // tx_frame[6]  = 8'h55; tx_frame[7]  = 8'hD5;

//         // // Destination MAC Address
//         // tx_frame[8]  = 8'hFF; tx_frame[9]  = 8'hFF; tx_frame[10]  = 8'hFF; 
//         // tx_frame[11]  = 8'hFF; tx_frame[12]  = 8'hFF; tx_frame[13]  = 8'hFF; 
        
//         // // Source MAC Address
//         // tx_frame[14]  = 8'h02; tx_frame[15]  = 8'h00; tx_frame[16]  = 8'h00; 
//         // tx_frame[17]  = 8'h00; tx_frame[18] = 8'h00; tx_frame[19] = 8'h01; 
        
//         // // EtherType (IPv4)
//         // // tx_frame[12] = 8'h08; tx_frame[13] = 8'h00;
//         // tx_frame[20] = 8'h88; tx_frame[21] = 8'hB5;
        
//         // // Payload: "Hello!"
//         // tx_frame[22] = 8'h48; tx_frame[23] = 8'h65; tx_frame[24] = 8'h6C; 
//         // tx_frame[25] = 8'h6C; tx_frame[26] = 8'h6F; tx_frame[27] = 8'h21; 
        
//         // // Padding (zeros)
//         // tx_frame[28] = 8'h00; 
//         // tx_frame[29] = 8'h00; tx_frame[30] = 8'h00; tx_frame[31] = 8'h00; 
//         // tx_frame[32] = 8'h00; tx_frame[33] = 8'h00; tx_frame[34] = 8'h00; 
//         // tx_frame[35] = 8'h00; tx_frame[36] = 8'h00; tx_frame[37] = 8'h00; 
//         // tx_frame[38] = 8'h00; tx_frame[39] = 8'h00; tx_frame[40] = 8'h00; 
//         // tx_frame[41] = 8'h00; tx_frame[42] = 8'h00; tx_frame[43] = 8'h00; 
//         // tx_frame[44] = 8'h00; tx_frame[45] = 8'h00; tx_frame[46] = 8'h00; 
//         // tx_frame[47] = 8'h00; tx_frame[48] = 8'h00; tx_frame[49] = 8'h00; 
//         // tx_frame[50] = 8'h00; tx_frame[51] = 8'h00; tx_frame[52] = 8'h00; 
//         // tx_frame[53] = 8'h00; tx_frame[54] = 8'h00; tx_frame[55] = 8'h00; 
//         // tx_frame[56] = 8'h00; tx_frame[57] = 8'h00; tx_frame[58] = 8'h00; 
//         // tx_frame[59] = 8'h00; tx_frame[60] = 8'h00; tx_frame[61] = 8'h00;
//         // tx_frame[62] = 8'h00; tx_frame[63] = 8'h00; tx_frame[64] = 8'h00; 
//         // tx_frame[65] = 8'h00; tx_frame[66] = 8'h00; tx_frame[67] = 8'h00;
//         // tx_frame[68] = 8'h00; tx_frame[69] = 8'h00; 
        
//         // // CRC pre-calculated using crc32.sv
//         // tx_frame[70] = 8'hBF; tx_frame[71] = 8'h0A; tx_frame[72] = 8'h3D; tx_frame[73] = 8'hEA;

//         tx_frame[0] = 8'h55;
//         tx_frame[1] = 8'h55;
//         tx_frame[2] = 8'h55;
//         tx_frame[3] = 8'h55;
//         tx_frame[4] = 8'h55;
//         tx_frame[5] = 8'h55;
//         tx_frame[6] = 8'h55;
//         tx_frame[7] = 8'hD5;
//         tx_frame[8] = 8'h00;
//         tx_frame[9] = 8'h10;
//         tx_frame[10] = 8'hA4;
//         tx_frame[11] = 8'h7B;
//         tx_frame[12] = 8'hEA;
//         tx_frame[13] = 8'h80;
//         tx_frame[14] = 8'h00;
//         tx_frame[15] = 8'h12;
//         tx_frame[16] = 8'h34;
//         tx_frame[17] = 8'h56;
//         tx_frame[18] = 8'h78;
//         tx_frame[19] = 8'h90;
//         tx_frame[20] = 8'h08;
//         tx_frame[21] = 8'h00;
//         tx_frame[22] = 8'h45;
//         tx_frame[23] = 8'h00;
//         tx_frame[24] = 8'h00;
//         tx_frame[25] = 8'h2E;
//         tx_frame[26] = 8'hB3;
//         tx_frame[27] = 8'hFE;
//         tx_frame[28] = 8'h00;
//         tx_frame[29] = 8'h00;
//         tx_frame[30] = 8'h80;
//         tx_frame[31] = 8'h11;
//         tx_frame[32] = 8'h05;
//         tx_frame[33] = 8'h40;
//         tx_frame[34] = 8'hC0;
//         tx_frame[35] = 8'hA8;
//         tx_frame[36] = 8'h00;
//         tx_frame[37] = 8'h2C;
//         tx_frame[38] = 8'hC0;
//         tx_frame[39] = 8'hA8;
//         tx_frame[40] = 8'h00;
//         tx_frame[41] = 8'h04;
//         tx_frame[42] = 8'h04;
//         tx_frame[43] = 8'h00;
//         tx_frame[44] = 8'h04;
//         tx_frame[45] = 8'h00;
//         tx_frame[46] = 8'h00;
//         tx_frame[47] = 8'h1A;
//         tx_frame[48] = 8'h2D;
//         tx_frame[49] = 8'hE8;
//         // tx_frame[50] = 8'h00;
//         // tx_frame[51] = 8'h01;
//         // tx_frame[52] = 8'h02;
//         // tx_frame[53] = 8'h03;
//         // tx_frame[54] = 8'h04;
//         // tx_frame[55] = 8'h05;
//         // tx_frame[56] = 8'h06;
//         // tx_frame[57] = 8'h07;
//         // tx_frame[58] = 8'h08;
//         // tx_frame[59] = 8'h09;
//         // tx_frame[60] = 8'h0A;
//         // tx_frame[61] = 8'h0B;
//         // tx_frame[62] = 8'h0C;
//         // tx_frame[63] = 8'h0D;
//         // tx_frame[64] = 8'h0E;
//         // tx_frame[65] = 8'h0F;
//         // tx_frame[66] = 8'h10;
//         // tx_frame[67] = 8'h11;
//         // tx_frame[1467:68] = 1400'b0;
//         // for (int i = 68; i <= 1467; i++) begin
//         //     tx_frame[i] = 8'h00;
//         // end
//         for (int i = 50; i <= 71; i++) begin
//             tx_frame[i] = 8'h00;
//         end
//         // 0010A47BEA8000123456789008004500002EB3FE000080110540C0A8002CC0A8000404000400001A2DE800000000000000000000000000000000000000000000FFE6FC98
//         tx_frame[72] = 8'hFF;
//         tx_frame[73] = 8'hE6;
//         tx_frame[74] = 8'hFC;
//         tx_frame[75] = 8'h98;
//         // tx_frame[1468] = 8'h03;
//         // tx_frame[1469] = 8'h4C;
//         // tx_frame[1470] = 8'hB2;
//         // tx_frame[1471] = 8'h54;
//         // start_transmission = 0;
//         // #1000;
//         // start_transmission = 1;
//         // 100#;
//         // start_transmission = 0;
//     end

//     assign eth_mdc = clk_divider[4]; // ~1.5625 MHz
//     assign eth_mdio = 1'bz;
// endmodule


`timescale 1 ns / 1 ps
module top_level (
    input  wire clk_100mhz,      // 100 MHz input clock
    output wire eth_mdc,         // Management Data Clock
    inout  wire eth_mdio,        // Management Data I/O
    output wire eth_rstn,        // Ethernet PHY Reset
    input  wire eth_crsdv,       // Carrier Sense/Data Valid
    input  wire eth_rxerr,       // Receive Error
    input  wire [1:0] eth_rxd,   // Receive Data
    output wire eth_txen,        // Transmit Enable
    output wire [1:0] eth_txd,   // Transmit Data
    output wire eth_refclk,      // Reference Clock (50 MHz)
    input  wire eth_intn,         // Interrupt (Active Low)
    output logic [15:0] led
);
    wire tx_ack;
    wire tx_valid;
    wire tx_sof;
    wire tx_eof;
    logic [7:0] tx_data;
    logic clk_50mhz;
    logic clk_50mhz_phased;
    logic [31:0] video_reg [299:0];
    logic [7:0] audio_reg [1023:0];

    // clk_wiz_4_clk_wiz wizard_net
    // (.clk_in1(clk_100mhz),
    // //  .clk_out1(clk_100mhz_passthrough),
    //  .clk_out2(clk_50mhz_phased),
    //  .clk_out5(clk_50mhz),
    //  .reset(0));

    reg [31:0] clk_divider = 32'b0;
    always_ff @(posedge clk_100mhz) begin
        clk_divider <= clk_divider + 1;
    end

    assign clk_50mhz = clk_divider[0];
    assign clk_50mhz_phased = clk_divider[0];


    tx_scheduler tx_inst (
        .clk_50mhz(clk_50mhz),
        .clk_50mhz_phased(clk_50mhz_phased),
        .rst_n(1),
        .eth_mdc(eth_mdc),
        .eth_mdio(eth_mdio),
        .eth_rstn(eth_rstn),
        .eth_crsdv(eth_crsdv),
        .eth_rxerr(eth_rxerr),
        .eth_rxd(eth_rxd),
        .eth_txen(eth_txen),
        .eth_txd(eth_txd),
        .eth_refclk(eth_refclk),
        .eth_intn(eth_intn),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_sof(tx_sof),
        .tx_eof(tx_eof),
        .tx_ack(tx_ack)
    );

    write_scheduler write_inst (
        .clk_50mhz(clk_50mhz_phased),
        .tx_ack(tx_ack),
        .eth_rstn(eth_rstn),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_sof(tx_sof),
        .tx_eof(tx_eof),
        .new_data(1),
        .video_reg(video_reg),
        .audio_reg(audio_reg),
        .num_words(2),
        .audio_video(1)
    );

    initial begin
        video_reg[0] = 32'b11111111111111111111111111111111;
        video_reg[1] = 32'b11111111111111111111111111111111;
        video_reg[2] = 32'b11111111111111111111111111111111;
        video_reg[3] = 32'b11111111111111111111111111111111;
        video_reg[4] = 32'b11111111111111111111111111111111;
        video_reg[5] = 32'b11111111111111111111111111111111;
        video_reg[6] = 32'b11111111111111111111111111111111;
        video_reg[7] = 32'b11111111111111111111111111111111;
        video_reg[8] = 32'b11111111111111111111111111111111;

        audio_reg[0] = 8'b11110000;
        audio_reg[1] = 8'b11111111;
        audio_reg[2] = 8'b11111111;
    end

    assign led[0] = video_reg[0][0];

endmodule