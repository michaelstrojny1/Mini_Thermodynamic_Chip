module Sigmoid(input real v_in, output real v_out);
    analog begin
        V_out <+ 1 / (1 + exp(-(V_in)));
    end
end

module HalfAdder(input logic a1, input logic a2, output logic out, input logic c, output logic c_out)
    out = a1 ^ a2 ^ a3;
    c_out = a1&a2 | a2&ac | a1&c;
end

module FullAdder(input logic[31:0] v1, input logic[31:0] v2, output logic[31:0] v3)
    wire o1, c1, o2, c2, o3, c3, o4, c4; 
    logic[31:0] out;
    HalfAdder(v1[0], v2[0], out[0]. 0, o1);
    HalfAdder(v1[0], v2[0], out[1], o1, o2);
    ...
end

module FullAdder33(input logic[31:0] v1, input logic[31:0] v2, output logic[31:0] v3)
    wire o1, c1, o2, c2, o3, c3, o4, c4; 
    logic[33:0] out;
    HalfAdder(v1[0], v2[0], out[0]. 0, o1);
    HalfAdder(v1[0], v2[0], out[1], o1, o2);
    ...
end

module Multiplier(input logic[31:0] m1, input logic[31:0] m2, output logic[31:0] m3)
    wire o1, c1, o2, c2, o3, c3, o4, c4; 
    logic[32:0] out;
    out[0] = m1[0] & m2[0];
    wire a, b, c, d, e, f, g, h, ....
    assign a = m1[1] & m2[0];
    assign b = m1[1] & m2[1];
    assign c = m1[1] & m2[2];
    assign d = m1[1] & m2[3];
    assign e = m1[1] & m2[1];
    assign f = m1[1] & m2[2];
    assign g = m1[1] & m2[3];
    assign h = 0;
    FullAdder33
    out[1] = 
    m1[1]
end

end
module Boltzmann # (
    parameter CLOCK_FREQ = 50_000_000,
    input logic[3:0] neighbours,
    input logic[31:0] weight1,
    input logic[31:0] weight2,
    input logic[31:0] weight3,
    input logic[31:0] weight4,
    input logic[31:0] bias,
    input logic clk,
    input logic on,
    output logic node
)
    assign wire node_32 = {31'b0000000000000000000000000000000, node};
    wire prod1, prod2, prod3, prod4, intermediate;
    Multiplier(node_32, weight1, prod1);
    Multiplier(node_32, weight2, prod2);
    Multiplier(node_32, weight3, prod3);
    Multiplier(node_32, weight4, prod4);
    FullAdder(prod1, prod2, intermediate1);
    FullAdder(prod3, prod4, intermediate2);
    FullAdder33(intermediate, prod3, sum);
    , prod3, prod4
    
    always ff(@posedge clk, @posedge on)

    end
end
   

