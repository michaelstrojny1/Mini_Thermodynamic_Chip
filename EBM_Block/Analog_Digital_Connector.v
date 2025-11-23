module p_bit_array (
`ifdef POWER_PINS
    inout dp, // digital power (1.8V)
    inout dg, // digital gnd
    inout ap, // analog power
    inout ag, // analog gnd
`endif
    // from/to PBIT_wrapper.v
    input wire analog_clk, 
    input wire [7:0] weights, 
    output wire [7:0] rng_data
);
endmodule