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
    //  .clk_out1(clk_100mhz_passthrough),
    //  .clk_out2(clk_50mhz_phased),
    //  .clk_out5(clk_50mhz),
    //  .reset(0));
    
    // Can uncomment wizard to use for more fine-grained clock control. Currently we use a basic clock divider instead
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

    // junk data to send in Ethernet packet. You can use a data stream into video_reg to send stuff instead.
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
