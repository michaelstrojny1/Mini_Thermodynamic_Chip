module Pbit_Wrapper (
    input wire clk, // spi clock
    input wire rstn, // rst low
    input wire [4699:0] bit_flips, // pbit values from analog
    output reg clk_analog, // pbit sampling clk (slow)
    
    // SPI
    output reg MISO, 
    input wire MOSI,
    input wire off, // chip enable (active low)
    input wire write_mode // 1 = weight load, 0 = pbit read
);
    parameter NUM_PBIT = 4700; // number pbits
    parameter ADDR_WIDTH = 13; // address (log2(NUM_PBIT))
    parameter DATA_WIDTH = 8; // 8 bit weights (words)
    parameter analog_counter = 6'd31; // analog clock counter
    
    // SRAM
    reg [DATA_WIDTH-1:0] WEIGHT_SRAM [0:NUM_PBIT - 1]; 
    reg [ADDR_WIDTH-1:0] addr_buffer;  // temp hold address 
    reg [DATA_WIDTH-1:0] data_buffer;  // temp hold data
    reg [4:0] bit_counter;   // number of bits recieved durint spi write
    
    // analog clock and pbit registers
    reg [5:0] clk_counter;    // analog clock counter
    
    // pbit buffering
    reg [NUM_PBIT-1:0] pbits;  // pbit register (clk_analog)
    reg [NUM_PBIT-1:0] pbits_shift; // shift register (clk)

    // if the input changes as a flip flop switches from 0 to 1 (or vice versa), we get stuck in metastability
    // to avoid this, we use 3 flip flops. The first absorbs the metastability, the second flip flop recieves 
    // a stable value since by the 2nd clock edge, we get stable value. the third flip flop is used for edge detection (since the 3rd flop holds the old input on the 2nd clock cycle)
    // For instance, ckc_slow might modify the data when clk_fast samples it
    reg capture_toggle; // this value flips every time the slow clock modifies data
    // since we don't want to read capture_toggle when it switches (metastability), we use synchronizers (i.e the 3 flip flops) 
    reg capture_sync1, capture_sync2;  // synchronizers (flops 1,2)
    reg capture_sync3;  // edge detect (flop 3)
    // we can XOR capture_sync2 and capture_sync3 to detect edges safely in clk domain
    
    reg [ADDR_WIDTH-1:0] pbit_shift_counter; // remaining bits
    
    // SPI FSM
    typedef enum reg [1:0] {
        IDLE = 2'b00,
        LOAD_ADDR = 2'b01,
        LOAD_DATA = 2'b10,
        WRITE_SRAM = 2'b11
    } spi_state_t;
    
    spi_state_t spi_state;
    
    // analog clk
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_counter <= 6'd0;
            clk_analog <= 1'b0;
        end else begin
            if (clk_counter == analog_counter) begin 
                clk_analog <= ~clk_analog; 
                clk_counter <= 6'd0;
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end
    
    // pbit storage (update every time analog clk rises)
    always @(posedge clk_analog or negedge rstn) begin
        if (!rstn) begin
            pbits <= {NUM_PBIT{1'b0}};
            capture_toggle <= 1'b0;
        end else begin
            pbits <= bit_flips; // load pbits in parallel
            capture_toggle <= ~capture_toggle;
        end
    end
    
    // synchronizer for clk_analog, clk
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            capture_sync1 <= 1'b0;
            capture_sync2 <= 1'b0;
            capture_sync3 <= 1'b0;
        end else begin
            capture_sync1 <= capture_toggle;
            capture_sync2 <= capture_sync1;
            capture_sync3 <= capture_sync2;
        end
    end
    
    // edge detection
    wire trigger = (capture_sync2 ^ capture_sync3);
    
    // pbit shift register and counter (clk domain)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pbits_shift <= {NUM_PBIT{1'b0}};
            pbit_shift_counter <= {ADDR_WIDTH{1'b0}};
        end else if (off) begin
            pbit_shift_counter <= {ADDR_WIDTH{1'b0}};
        end else if (trigger) begin    // triggers the loading of new pbits when new ones arrive
            pbits_shift <= pbits;
            pbit_shift_counter <= NUM_PBIT; // shift counter init
        end else if (!write_mode && pbit_shift_counter > 0) 
        begin
            // shift out old pbits
            pbits_shift <= {pbits_shift[NUM_PBIT - 2:0], 1'b0}; // shft left
            pbit_shift_counter <= pbit_shift_counter - 1; // counter --1
        end
    end
    
    // SPI MISO
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
        begin
            MISO <= 1'b0;
        end else if (off) 
        begin
            MISO <= 1'b0;
        end else if (!write_mode && pbit_shift_counter > 0) 
        begin
            MISO <= pbits_shift[NUM_PBIT - 1]; // shift out pbit shift register into MISO
        end else 
        begin
            MISO <= 1'b0; // shift done? set MISO to 0
        end
    end
    
    // SPI FSM for write mode. infinitely cycles between these states

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            spi_state <= IDLE;
        end 
        else if (off) begin
            spi_state <= IDLE;
        end 
        else begin
            case (spi_state)
                IDLE: begin
                    if (write_mode && bit_counter == 0) begin
                        spi_state <= LOAD_ADDR;
                    end
                end
                LOAD_ADDR: begin
                    if (write_mode && bit_counter == ADDR_WIDTH - 1) begin
                        spi_state <= LOAD_DATA;
                    end else if (!write_mode) begin
                        spi_state <= IDLE;
                    end
                end
                LOAD_DATA: begin
                    if (write_mode && bit_counter == (ADDR_WIDTH + DATA_WIDTH - 1)) begin
                        spi_state <= WRITE_SRAM;
                    end else if (!write_mode) begin
                        spi_state <= IDLE;
                    end
                end
                WRITE_SRAM: begin
                    spi_state <= IDLE;
                end
                default: spi_state <= IDLE;
            endcase
        end
    end
    
    // write_mode = 1
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bit_counter <= 5'd0;
            addr_buffer <= {ADDR_WIDTH{1'b0}};
            data_buffer <= {DATA_WIDTH{1'b0}};
        end else if (off || !write_mode) begin
            bit_counter <= 5'd0;
            addr_buffer <= {ADDR_WIDTH{1'b0}};
            data_buffer <= {DATA_WIDTH{1'b0}};
        end else begin
            case (spi_state)
                IDLE: begin
                    bit_counter <= 5'd0;
                end
                LOAD_ADDR: begin
                    addr_buffer <= {addr_buffer[ADDR_WIDTH-2:0], MOSI}; // shift in new address from SPI. This is why we need addr buffer
                    bit_counter <= bit_counter + 1;
                end
                LOAD_DATA: begin
                    data_buffer <= {data_buffer[DATA_WIDTH-2:0], MOSI}; // shift in data
                    bit_counter <= bit_counter + 1;
                end
                WRITE_SRAM: begin
                    if (addr_buffer < NUM_PBIT) begin // is address legit?
                        WEIGHT_SRAM[addr_buffer] <= data_buffer; // write data to address in SRAM
                    end
                    bit_counter <= 5'd0; // reset
                end
            endcase
        end
    end
    
endmodule