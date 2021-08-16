////////
// 
//	p3starter/top.v
//
//	Project 3 Starter Code
//	
//  PICOSOC RISC-V processor instantiated to support a
//	SOFTWARE multiplexed 7-segment display 
//  on the breadboard using C program firmware.c
//
//	Chuck Pateros
//	University of San Diego
//	20-Jun-2021
//
////////

`ifdef PICOSOC_V
`error "top.v must be read before picosoc.v!"
`endif

`define PICOSOC_MEM ice40up5k_spram

module top (
    input clk,


    // hardware UART
    output UART_TX,
    input UART_RX,


    // onboard SPI flash interface
    output flash_csb,
    output flash_clk,
    inout  flash_io0,
    inout  flash_io1,
    inout  flash_io2,
    inout  flash_io3

    //////////////////////////////////
    // User defined inputs and outputs
    //////////////////////////////////
    // Do not edit or remove

    //output [7:0] COLS,
    //output [7:0] ROWS
);
    ///////////////////////////////////
    // Power-on Reset
    ///////////////////////////////////
    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    always @(posedge clk) begin
        reset_cnt <= reset_cnt + !resetn;
    end


    ///////////////////////////////////
    // SPI Flash Interface
    ///////////////////////////////////
    wire flash_io0_oe, flash_io0_do, flash_io0_di;
    wire flash_io1_oe, flash_io1_do, flash_io1_di;
    wire flash_io2_oe, flash_io2_do, flash_io2_di;
    wire flash_io3_oe, flash_io3_do, flash_io3_di;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) flash_io_buf [3:0] (
        .PACKAGE_PIN({flash_io3, flash_io2, flash_io1, flash_io0}),
        .OUTPUT_ENABLE({flash_io3_oe, flash_io2_oe, flash_io1_oe, flash_io0_oe}),
        .D_OUT_0({flash_io3_do, flash_io2_do, flash_io1_do, flash_io0_do}),
        .D_IN_0({flash_io3_di, flash_io2_di, flash_io1_di, flash_io0_di})
    );



    ///////////////////////////////////
    // Peripheral Bus
    ///////////////////////////////////
    wire        iomem_valid;
    reg         iomem_ready;
    wire [3:0]  iomem_wstrb;
    wire [31:0] iomem_addr;
    wire [31:0] iomem_wdata;
    reg  [31:0] iomem_rdata;

    //reg [3:0] hex_to_display;

    reg [31:0] gpio;

// Tie outputs to GPIO lines

    reg [7:0] cmd_addr;
    reg [7:0] data;
    reg start_cmd;

    assign cmd_addr = gpio[7:0];
    assign data = gpio[15:8];
    assign start_cmd = gpio[16];

    wire [7:0] spi_rd_data;  //changed from wire


    wire spi_busy;


    //assign COLS = gpio[7:0];
    //assign ROWS = gpio[15:8];

// Corresponding C code in firmware.c
//
//     reg_gpio =  ((second_timer & 0x00F) << 0); // debug LEDs


    always @(posedge clk) begin
        if (!resetn) begin
            gpio <= 0;
        end else begin
            start_cmd <= 0;
            iomem_ready <= 0;

            ///////////////////////////
            // GPIO Peripheral
            ///////////////////////////
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h03) begin
                iomem_ready <= 1;
                iomem_rdata <= {6'h0, spi_busy, spi_rd_data, gpio[16:0]};
                gpio[7:0] <= iomem_wdata[7: 0];
                gpio[15: 8] <= iomem_wdata[15: 8];
                gpio[16] <= iomem_wdata[16];
                //if (iomem_wstrb[3]) gpio[31:24] <= iomem_wdata[31:24]; //changed from [31:24]
            end


            ///////////////////////////
            // Template Peripheral
            ///////////////////////////
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h04) begin
                iomem_ready <= 1;
                iomem_rdata <= 32'h0;
            end
        end
    end


    spi_master spi_master(
        .i_clk12(clk),
        .i_rst(resetn),

        .i_start_cmd(start_cmd),
        .i_rw_cmd(gpio[7]),
        .i_reg_addr(gpio[6:0]),
        .i_wr_data(data),
        .o_rd_data(spi_rd_data),  //changed from spi_rd_data
        .o_busy(spi_busy),

        .sclk(), //not sure what to send here
        .mosi(),
        .cs(),
        .miso()
    );

    picosoc #(
        .BARREL_SHIFTER(0), // reduces device utilization
		.ENABLE_MULDIV(0), // reduces device utilization
        .MEM_WORDS(2048)  // use 2KBytes of block RAM by default
    ) soc (
        .clk          (clk         ),
        .resetn       (resetn      ),

        .ser_tx       (UART_TX       ),
        .ser_rx       (UART_RX      ),

        .flash_csb    (flash_csb   ),
        .flash_clk    (flash_clk   ),

        .flash_io0_oe (flash_io0_oe),
        .flash_io1_oe (flash_io1_oe),
        .flash_io2_oe (flash_io2_oe),
        .flash_io3_oe (flash_io3_oe),

        .flash_io0_do (flash_io0_do),
        .flash_io1_do (flash_io1_do),
        .flash_io2_do (flash_io2_do),
        .flash_io3_do (flash_io3_do),

        .flash_io0_di (flash_io0_di),
        .flash_io1_di (flash_io1_di),
        .flash_io2_di (flash_io2_di),
        .flash_io3_di (flash_io3_di),

        .irq_5        (1'b0        ),
        .irq_6        (1'b0        ),
        .irq_7        (1'b0        ),

        .iomem_valid  (iomem_valid ),
        .iomem_ready  (iomem_ready ),
        .iomem_wstrb  (iomem_wstrb ),
        .iomem_addr   (iomem_addr  ),
        .iomem_wdata  (iomem_wdata ),
        .iomem_rdata  (iomem_rdata )
    );


endmodule
/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
