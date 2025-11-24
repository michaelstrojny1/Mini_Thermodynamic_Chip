module p_bit_array (
`ifdef POWER_PINS
    inout dp, // digital power (1.8V)
    inout dg, // digital gnd
    inout ap, // analog power
    inout ag, // analog gnd
`endif
    // from/to PBIT_wrapper.v
    input wire clk_analog, 
    input wire [4699:0] WEIGHT_SRAM, 
    output wire [4699:0] pbits
);
endmodule