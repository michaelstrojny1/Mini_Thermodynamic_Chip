
// spi with CPU or MCU

module Pbit_Wrapper(
    input wire clk, rstn
    input wire [7:0] analog_rng; // random 8 bits from analog
    output reg clk_analog,
    output reg [7:0] weights // not EMB weights; these are weights to tune the analog RNG
    input wire spi_in, spi_out, off   // spi and chip_OFF button (we only have 1 SPI but many connected chips)
);
    reg [5:0] counter;
    always @(posedge clk or negedge rstn) 
    begin
        if (!rst_n) begin
            clk_counter <= 0;
            clk_analog <= 0;
        end 
        else 
        begin
            counter <= counter + 1;
            if (counter == 32) 
            begin 
                clk_analog <= ~clk_analog; 
                clk_counter <= 0;
            end
        end
    end

    // we generate 8 pbits at a time per clk_analog; we have parallel input into our wrapper

    reg [7:0] pbits;

    // shift register
    
    always @(posedge clk_analog) 
    begin
        pbits <= analog_rng; 
    end

    always @(posedge clk) 
    begin
        if (!off) 
        begin
            spi_in <= pbits[7];
            pbits <= {pbits[6:0], 1'b0}; // shift left
        end
    end

    // set weights / shift register

    always @(posedge clk) begin
        if (!off) begin
            weights <= {weights[6:0], spi_out};
        end
    end

endmodule