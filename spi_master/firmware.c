////////
// 
//	p3starter/firmware.c
//
//	Project 3 Starter Code
//	
//	SOFTWARE multiplexed 7-segment display 
//  on the breadboard using this C program on a 
//  PICOSOC RISC-V processor instantiated on the FPGA.
//
//	Chuck Pateros
//	University of San Diego
//	20-Jun-2021
//
////////

#include <stdint.h>
#include <stdbool.h>


// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

#define reg_spictrl (*(volatile uint32_t*)0x02000000)
#define reg_uart_clkdiv (*(volatile uint32_t*)0x02000004)
#define reg_uart_data (*(volatile uint32_t*)0x02000008)
#define reg_gpio (*(volatile uint32_t*)0x03000000)

extern uint32_t _sidata, _sdata, _edata, _sbss, _ebss,_heap_start;

bool display[8][8];

uint32_t set_irq_mask(uint32_t mask); asm (
    ".global set_irq_mask\n"
    "set_irq_mask:\n"
    ".word 0x0605650b\n"
    "ret\n"
);

void spin_wait_ms(int wait_ms){
    int cycles_to_wait = 25 * wait_ms;
    while (cycles_to_wait >= 0)
      cycles_to_wait -= 1;
    }

void init_display()
{
    for(int i = 0; i < 8; i++)
    {
        for(int j = 0; j < 8; j++)
        {
            display[i][j] = 0;
        }
    }
}

void set_bit(unsigned char *num, uint32_t k, bool x) //num is pointer to number you want to set bit in, k is which bit (array from k-0), x is bit
{
    if(x)
        *num |= (1UL << k);
    else
        *num &= ~(1UL << k);
}

bool get_bit(unsigned char *num, uint32_t k)
{
    return (*num >> k) & 0x1;
}

void update_display(unsigned char *cols, unsigned char *rows, uint32_t k)
{
    for(int i = 0; i < 8; i++)
    {
        set_bit(cols, i, display[i][k]);
        set_bit(rows, i, !display[k][i]);
    }
    
}

void rotate_90()
{
    bool temp_display[8][8];
    for(int i = 0; i < 8; i++)
    {
        for(int j = 0; j < 8; j++)
            temp_display[i][j] = display[i][j];
    }
    for(int i = 0; i < 8; i++)
    {
        for(int j = 0; j < 8; j++)
        {
          display[7-i][j] = temp_display[i][j];
          
        }
    }
}

void main() {
    set_irq_mask(0xff);
    // zero out .bss section
    for (uint32_t *dest = &_sbss; dest < &_ebss;) {
        *dest++ = 0;
    }

    // switch to dual IO mode
    reg_spictrl = (reg_spictrl & ~0x007F0000) | 0x00400000;


    
    uint32_t second_timer = 0;
    uint32_t ms_timer = 0;
    uint32_t display_col = 0;
    uint32_t dbg = 0b0001; 
    unsigned char cols = 0b00000000; //active high
    unsigned char rows = 0b11111111; //active low
    uint32_t hex_to_display = 0x0;
    uint32_t counter = 0;
    char cmd_addr;
    char wr_data;
    char rd_data = 0x00;
    bool spi_busy;
    bool start_cmd;
    reg_uart_clkdiv = 1250;
    //start_cmd = true;
    wr_data = 0x88;

    //while(1)
    //{
        reg_uart_data = '{';
        spin_wait_ms(20);
        rd_data = reg_gpio >> 17;
        spi_busy = reg_gpio >> 25;

        /*
        cmd_addr = 0x00;

        reg_gpio = ((cmd_addr&0xFF) | ((wr_data & 0xFF) << 8) | (start_cmd << 16)); // debug LEDs
        start_cmd = false;
        while(spi_busy){}
        */
        cmd_addr = 0x80;
        for(int i = 0; i < 0xff; i++)
        {
            start_cmd = true;
            reg_gpio = ((start_cmd << 16) | ((wr_data & 0xFF) << 8) | (cmd_addr&0xFF));
            spi_busy = reg_gpio >> 25;
            start_cmd = false;
            rd_data = reg_gpio >> 17;
            while(spi_busy){
                //spi_busy = reg_gpio >> 25;
                reg_uart_data = 'g';
            }
            rd_data = reg_gpio >> 17;
            reg_gpio = ((cmd_addr&0xFF) | ((wr_data & 0xFF) << 8) | (start_cmd << 16));
            reg_uart_data = rd_data;

            cmd_addr += 1;
        }

        reg_uart_data = '}';
    //}

      



} // end of while(1)
 // end of main program
