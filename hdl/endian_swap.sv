module endian_swap #(
    parameter WIDTH = 32  // Width must be a multiple of 8
) (
    input  logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < WIDTH/8; i++) begin : swap
            assign data_out[8*(i+1)-1 : 8*i] = data_in[WIDTH-8*i-1 : WIDTH-8*(i+1)];
        end
    endgenerate

endmodule