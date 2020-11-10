
MEM_DIR := mem
RTL_USB_DIR = tinyfpga_bx_usbserial/usb

MEMS = $(MEM_DIR)/empty.hex $(MEM_DIR)/test.hex \
	$(MEM_DIR)/terminus_816_latin1.hex $(MEM_DIR)/terminus_816_bold_latin1.hex \
	$(MEM_DIR)/keymap.hex
VT52_SRCS := char_buffer.v char_rom.v clock_generator.v command_handler.v cursor.v \
	cursor_blinker.v keyboard.v keymap_rom.v pll.v simple_register.v \
	video_generator.v vt52.v
USB_SRCS = \
	$(RTL_USB_DIR)/edge_detect.v \
	$(RTL_USB_DIR)/serial.v \
	$(RTL_USB_DIR)/usb_fs_in_arb.v \
	$(RTL_USB_DIR)/usb_fs_in_pe.v \
	$(RTL_USB_DIR)/usb_fs_out_arb.v \
	$(RTL_USB_DIR)/usb_fs_out_pe.v \
	$(RTL_USB_DIR)/usb_fs_pe.v \
	$(RTL_USB_DIR)/usb_fs_rx.v \
	$(RTL_USB_DIR)/usb_fs_tx_mux.v \
	$(RTL_USB_DIR)/usb_fs_tx.v \
	$(RTL_USB_DIR)/usb_reset_det.v \
	$(RTL_USB_DIR)/usb_serial_ctrl_ep.v \
	$(RTL_USB_DIR)/usb_uart_bridge_ep.v \
	$(RTL_USB_DIR)/usb_uart_core.v \
	$(RTL_USB_DIR)/usb_uart_i40.v \

PICO_SRCS := \
	hardware.v \
	spimemio.v \
	simpleuart.v \
	picosoc.v \
	picorv32.v

GCC_PATH = riscv32i/bin

DEVICE = lp8k
PACKAGE = cm81

CLK_MHZ = 48
CLK_CONSTRAINTS = clock_constraints.py

.PHONY: all clean

upload: hardware.bin firmware.bin
	tinyprog -p hardware.bin -u firmware.bin

riscv_vt52.json: $(PICO_SRCS) $(VT52_SRCS) $(USB_SRCS) $(MEMS)  riscv_vt52.v
	yosys -p 'synth_ice40 -json $@' $(PICO_SRCS) $(VT52_SRCS) $(USB_SRCS) riscv_vt52.v 


hardware.asc: hardware.pcf riscv_vt52.json
	nextpnr-ice40 --lp8k --package cm81  --freq 48 --pre-pack clock_constraints.py --json riscv_vt52.json --pcf hardware.pcf --asc hardware.asc

hardware.bin: hardware.asc
	icetime -d hx8k -c 12 -mtr hardware.rpt hardware.asc
	icepack hardware.asc hardware.bin


firmware.elf: sections.lds start.S firmware.c
	riscv32-unknown-elf-gcc -march=rv32imc -nostartfiles -Wl,-Bstatic,-T,sections.lds,--strip-debug,-Map=firmware.map,--cref  -ffreestanding -nostdlib -o firmware.elf start.S firmware.c

firmware.bin: firmware.elf
	riscv32-unknown-elf-objcopy -O binary firmware.elf /dev/stdout > firmware.bin


pll.v:
	icepll -i 16 -o $(CLK_MHZ) -m -f $@

clean:
	rm -f firmware.elf firmware.hex firmware.bin firmware.o firmware.map \
	      hardware.blif hardware.log hardware.asc hardware.rpt hardware.bin \
	 			vt52.bin vt52.asc vt52.json pll.v
