module mikrobus_soc (
	output ser_tx,
	input ser_rx,

	inout AN_1,
	inout RST_1,
	inout CS_1,
	inout PWM_1,
	inout INT_1,
	inout AN_2,
	inout RST_2,
	inout CS_2,
	inout PWM_2,
	inout INT_2,

	inout SDA_1, SCL_1
	
);
	wire clk;

	SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC(.CLKHFPU(1), .CLKHFEN(1), .CLKHF(clk));

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk) begin
		reset_cnt <= reset_cnt + !resetn;
	end

	


	reg [31:0] gpio_oe;
	reg [31:0] gpio_do;
	wire [9:0] gpio_di;


	wire ip_ready;
	wire [31:0] ip_rdata; 



	
	
	
	wire ip_valid = iomem_valid && (iomem_addr[31:24] == 8'h 05);
	

	wire sdai_1, sdao_1, sdaoe_1, scli_1, sclo_1, scloe_1;

	ip_wrapper ip(
		.clock(clk),
		.reset(!resetn),
		.address(iomem_addr[23:0]),
		.write_data(iomem_wdata),
		.read_data(ip_rdata),
		.wstrb(iomem_wstrb),
		.valid(ip_valid),
		.ready(ip_ready),
		
		.pwm({pwm_r, pwm_g, pwm_b}),
		
		// I2C block 1
		.sdai_1(sdai_1), 
		.sdao_1(sdao_1), 
		.sdaoe_1(sdaoe_1),
		.scli_1(scli_1),
		.sclo_1(sclo_1),
		.scloe_1(scloe_1)
	);
	
	
	SB_IO #(
	.PIN_TYPE(6'b101001),
	.PULLUP(1'b1)
	) scl_io_1 (
	.PACKAGE_PIN(SCL_1),
	.OUTPUT_ENABLE(scloe_1),
	.D_OUT_0(sclo_1),
	.D_IN_0(scli_1)
	);


	SB_IO #(
	.PIN_TYPE(6'b101001),
	.PULLUP(1'b1)
	) sda_io_1 (
	.PACKAGE_PIN(SDA_1),
	.OUTPUT_ENABLE(sdaoe_1),
	.D_OUT_0(sdao_1),
	.D_IN_0(sdai_1)
	);

endmodule