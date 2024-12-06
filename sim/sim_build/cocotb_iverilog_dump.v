module cocotb_iverilog_dump();
initial begin
    $dumpfile("C:/Users/katri/Documents/6205/FluidPhysics/sim/sim_build/divider.fst");
    $dumpvars(0, divider);
end
endmodule
