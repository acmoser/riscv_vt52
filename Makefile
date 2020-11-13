
MEM_DIR := mem
RTL_USB_DIR = tinyfpga_bx_usbserial/usb

MEMS = $(MEM_DIR)/empty.hex $(MEM_DIR)/test.hex \
	$(MEM_DIR)/terminus_816_latin1.hex $(MEM_DIR)/terminus_816_bold_latin1.hex \
	$(MEM_DIR)/keymap.hex
VT52_SRCS := char_buffer.v char_rom.v clock_generator.v command_handler.v cursor.v \
	cursor_blinker.v keyboard.v keymap_rom.v pll.v simple_register.v \
	video_generator.v vt52.v uart.v uart_rx.v uart_tx.v

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

hardware.json: $(PICO_SRCS) $(VT52_SRCS) $(MEMS)
	yosys -p 'synth_ice40 -top hardware -json $@' $(PICO_SRCS) $(VT52_SRCS)


hardware.asc: hardware.pcf hardware.json
	nextpnr-ice40 --lp8k --package cm81  --freq 16 --pre-pack clock_constraints.py --json hardware.json --pcf hardware.pcf --asc hardware.asc

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
	      hardware.json hardware.log hardware.asc hardware.rpt hardware.bin \
	      pll.v
