module tinysoc (
  input clk,
  input resetn,

  output wire hsync,
  output wire vsync,
  output wire video,
  output wire led,
  input wire ps2_data,
  input wire ps2_clk,
);

assign ser_rx = txd;
assign ser_tx = rxd;
assign s_axis_tdata = uart_out_data;
assign s_axis_tready = uart_out_ready;
assign s_axis_tvalid = uart_out_valid;
assign m_axis_tdata = uart_in_data;
assign m_axis_tready = uart_in_ready;
assign m_axis_tvalid = uart_in_valid;
assign prescale = (16000/8*9600);

picosoc picosoc(.clk(clk), .resetn(resetn), .ser_tx(ser_tx), .ser_rx(ser_rx));

vt52 vt52(.clk(clk), .hsync(hysnc), .vsync(vsync), .video(video),
.led(led), .ps2_data(ps2_data), .ps2_clk(ps2_clk),
.pin_usb_p(pin_usb_p), .pin_usb_n(pin_usb_n), .uart_out_data(uart_out_data),
.uart_out_ready(uart_out_ready), .uart_out_valid(uart_out_valid),
.uart_in_data(uart_in_data), .uart_in_ready(uart_in_ready), .uart_in_valid(uart_in_valid));

uart uart(.clk(clk), .rst(rst), .s_axis_tdata(s_axis_tdata), .s_axis_tready(s_axis_tready),
.s_axis_tvalid(s_axis_tvalid), .m_axis_tdata(m_axis_tdata), .m_axis_tready(m_axis_tready),
.m_axis_tvalid(m_axis_tvalid), .rxd(rxd), .txd(txd), .prescale(prescale));

endmodule
