module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/gispisquared/Documents/MIT/Fall2024/6.2050/project/FluidPhysics/sim/sim_build/lbm.fst");
    $dumpvars(0, lbm);
end
endmodule
