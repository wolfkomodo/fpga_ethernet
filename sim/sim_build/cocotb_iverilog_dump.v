module cocotb_iverilog_dump();
initial begin
    $dumpfile("/Users/akshayattaluri/Desktop/Akshay/MIT/Year 3/6.2050/always_comm/sim/sim_build/top_level.fst");
    $dumpvars(0, top_level);
end
endmodule
