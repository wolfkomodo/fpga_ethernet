module write_scheduler (
    input  wire clk_50mhz,
    input wire tx_ack,
    input wire eth_rstn,
    output logic [7:0] tx_data,
    output logic tx_valid,
    output logic tx_sof,
    output logic tx_eof,
    input logic new_data,
    input logic [31:0] video_reg [299:0],
    input logic [10:0] num_words,
    input logic [7:0] audio_reg [1023:0],
    input logic audio_video
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        HEADER = 2'b01,
        PAYLOAD = 2'b10
    } state_t;
    
    state_t current_state, next_state;
    
    reg [7:0] headers [41:0];
    logic [10:0] byte_counter = 0;
    
    assign tx_sof = new_data;
    
    // Combined state transition and output logic
    always_ff @(posedge clk_50mhz) begin
        case (current_state)
            IDLE: begin
                tx_valid <= 0;
                if (tx_ack) begin
                    tx_eof <= 0;
                end
                if (eth_rstn & !tx_eof & tx_sof) begin
                    current_state <= HEADER;
                    byte_counter <= 0;
                    tx_data <= headers[0];
                end
            end
            HEADER: begin
                if (tx_ack) begin
                    tx_valid <= 1;
                    
                    if (byte_counter == 41) begin
                        byte_counter <= 0;
                        current_state <= PAYLOAD;
                        if (num_words > 0) begin
                            if (audio_video) begin
                                tx_data <= audio_reg[0];
                            end else begin
                                case(byte_counter[1:0])
                                    0: tx_data <= video_reg[0][31:24];
                                    1: tx_data <= video_reg[0][23:16];
                                    2: tx_data <= video_reg[0][15:8];
                                    3: tx_data <= video_reg[0][7:0];
                                endcase
                            end
                        end else begin
                            tx_eof <= 1;
                            current_state <= IDLE;
                        end
                    end else begin
                        byte_counter <= byte_counter + 1;
                        tx_data <= headers[byte_counter + 1];
                    end
                end
            end
            
            PAYLOAD: begin
                if (tx_ack) begin
                    tx_valid <= 1;
                    if (byte_counter >= num_words - 1) begin
                        byte_counter <= 0;
                        tx_eof <= 1;
                        current_state <= IDLE;
                    end else begin
                        byte_counter <= byte_counter + 1;
                        if (audio_video) begin
                            tx_data = audio_reg[byte_counter+1];
                        end else begin
                            case(byte_counter[1:0])
                                0: tx_data = video_reg[(byte_counter+1) >> 2][31:24];
                                1: tx_data = video_reg[(byte_counter+1) >> 2][23:16];
                                2: tx_data = video_reg[(byte_counter+1) >> 2][15:8];
                                3: tx_data = video_reg[(byte_counter+1) >> 2][7:0];
                            endcase
                        end
                    end
                end
            end
            
            default: current_state <= IDLE;
        endcase
    end

    initial begin
        headers[0] = 8'h00;
        headers[1] = 8'h10;
        headers[2] = 8'hA4;
        headers[3] = 8'h7B;
        headers[4] = 8'hEA;
        headers[5] = 8'h80;
        headers[6] = 8'h00;
        headers[7] = 8'h12;
        headers[8] = 8'h34;
        headers[9] = 8'h56;
        headers[10] = 8'h78;
        headers[11] = 8'h90;
        headers[12] = 8'h08;
        headers[13] = 8'h00;
        headers[14] = 8'h45;
        headers[15] = 8'h00;
        headers[16] = 8'h00;
        headers[17] = 8'h2E;
        headers[18] = 8'hB3;
        headers[19] = 8'hFE;
        headers[20] = 8'h00;
        headers[21] = 8'h00;
        headers[22] = 8'h80;
        headers[23] = 8'h11;
        headers[24] = 8'h05;
        headers[25] = 8'h40;
        headers[26] = 8'hC0;
        headers[27] = 8'hA8;
        headers[28] = 8'h00;
        headers[29] = 8'h2C;
        headers[30] = 8'hC0;
        headers[31] = 8'hA8;
        headers[32] = 8'h00;
        headers[33] = 8'h04;
        headers[34] = 8'h04;
        headers[35] = 8'h00;
        headers[36] = 8'h04;
        headers[37] = 8'h00;
        headers[38] = 8'h00;
        headers[39] = 8'h1A;
        headers[40] = 8'h2D;
        headers[41] = 8'hE8;
    end

endmodule