#include <stdint.h>
#include <stdbool.h>

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_leds (*(volatile uint32_t*)0x03000000)

extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss,_heap_start;

uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);


void putchar(char c)
{
	if (c == '\n')
		putchar('\r');
	reg_uart_data = c;
}

void print(const char *p)
{
	while (*p)
		putchar(*(p++));
}

void main() {
    set_irq_mask(0xff);

    // zero out .bss section
    for (uint32_t *dest = &_sbss; dest < &_ebss;) {
        *dest++ = 0;
    }

    // switch to dual IO mode
    reg_spictrl = (reg_spictrl & ~0x007F0000) | 0x00400000;

    reg_uart_clkdiv = 1666;
    print("Booting..\n");
    // blink the user LED
    uint32_t led_timer = 0;
    bool sent = false;

    char *msgs[4] = {"Hello PicoSOC", "Hellp VT52", "Bye PicoSOC", "Bye VT52"};

    while (1) {
        reg_leds = led_timer >> 16;
        led_timer = led_timer + 1;
        if (reg_leds & 1) {
          if (!sent) {
            // go back home & clear line
            print("\033H\033K");
            print(msgs[(reg_leds >> 1) & 3]);
            // send new message
            sent = true;
          }
        } else {
          sent = false;
        }
    }
}
