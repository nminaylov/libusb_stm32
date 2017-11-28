CMSIS       ?=../../CMSIS
CMSISDEV    ?= $(CMSIS)/Device
CMSISCORE   ?= $(CMSIS)/CMSIS/Include $(CMSIS)/CMSIS/Core/Include
FLASH       ?= st-flash
TOOLSET     ?= arm-none-eabi-
CC           = $(TOOLSET)gcc
LD           = $(TOOLSET)gcc
AR           = $(TOOLSET)gcc-ar
OBJCOPY      = $(TOOLSET)objcopy

ifeq ($(OS),Windows_NT)
	RM = del /Q
	fixpath = $(strip $(subst /,\, $1))
else
	RM = rm -f
	fixpath = $(strip $1)
endif

MODULE      ?= libusb.a
CFLAGS      ?= -mcpu=cortex-m3
DEFINES     ?= STM32F1 STM32F103x6

ARFLAGS      = -cvq
LDFLAGS      = --specs=nano.specs -nostartfiles -Wl,--gc-sections
INCLUDES     = $(CMSISDEV)/ST $(CMSISCORE) inc
CFLAGS2      = -mthumb -Os -std=gnu99

OBJDIR       = obj
SOURCES      = $(wildcard src/*.c) $(wildcard src/*.S)
OBJECTS      = $(addprefix $(OBJDIR)/, $(addsuffix .o, $(notdir $(basename $(SOURCES)))))
DSRC         = $(wildcard demo/*.c) $(wildcard demo/*.S) $(STARTUP)
DOBJ         = $(addprefix $(OBJDIR)/, $(addsuffix .o, $(notdir $(basename $(DSRC)))))
DOUT         = cdc_loop

SRCPATH      = $(sort $(dir $(SOURCES) $(DSRC)))
vpath %.c $(SRCPATH)
vpath %.S $(SRCPATH)
vpath %.s $(SRCPATH)


help all:
	@echo 'Usage: make target [program]'
	@echo 'Available targets are:'
	@echo '  bluepill'
	@echo '  stm32f103x6   CDC loopback demo for STM32F103 based boards'
	@echo '  32l100c-disco'
	@echo '  stm32l100xc   CDC loopback demo for STM32L100xC based boards'
	@echo '  32l476rg-nucleo'
	@echo '  stm32l476rg   CDC loopback demo for STM32L476xG based boards'
	@echo '  stm32l052x8   CDC loopback demo for STM32L052x8 based boards'
	@echo '  doc           DOXYGEN documentation'
	@echo '  module        static library module using following envars (defaults)'
	@echo '                MODULE  module name (libusb.a)'
	@echo '                CFLAGS  mcu specified compiler flags (-mcpu=cortex-m3)'
	@echo '                DEFINES mcu and module specified defines (STM32F1 STM32F103x6)'
	@echo '                        see USB Device HW driver and core API section for the'
	@echo '                        compile-time control macros'
	@echo ' '
	@echo 'Environmental variables (defaults):'
	@echo '  CMSIS         Path to the CMSIS V4 or CMSIS V5 root folder ($(CMSIS))'
	@echo '  CMSISCORE     Path to the CMSIS Core include folder(s) ($(CMSISCORE))'
	@echo '  CMSISDEV      Path to the CMSIS Device folder ($(CMSISDEV))'
	@echo '  FLASH         st-link flash utility ($(FLASH))'
	@echo ' '
	@echo 'Examples:'
	@echo '  make bluepill program'
	@echo '  make module MODULE="usbd.a" CFLAGS="-mcpu=cotrex-m4" DEFINES="STM32L4 STM32L476xx USBD_VBUS_DETECT"'

$(OBJDIR):
	@mkdir $@

program: $(DOUT).hex
	$(FLASH) --reset --format ihex write $(DOUT).hex

demo: $(DOUT).hex

$(DOUT).hex : $(DOUT).elf
	@echo building $@
	@$(OBJCOPY) -O ihex $< $@

$(DOUT).elf : $(OBJDIR) $(DOBJ) $(OBJECTS)
	@echo building $@
	@$(LD) $(CFLAGS) $(CFLAGS2) $(LDFLAGS) -Wl,--script='$(LDSCRIPT)' -Wl,-Map=$(DOUT).map $(DOBJ) $(OBJECTS) -o $@

clean:
	@$(RM) $(DOUT).*
	@$(RM) $(call fixpath, $(OBJDIR)/*.*)

doc:
	doxygen

module: clean $(MODULE)

$(MODULE): $(OBJDIR) $(OBJECTS)
	@$(AR) $(ARFLAGS) $(MODULE) $(OBJECTS)

$(OBJDIR)/%.o: %.c
	@echo compiling $<
	@$(CC) $(CFLAGS) $(CFLAGS2) $(addprefix -D, $(DEFINES)) $(addprefix -I, $(INCLUDES)) -c $< -o $@

$(OBJDIR)/%.o: %.S
	@echo assembling $<
	@$(CC) $(CFLAGS) $(CFLAGS2) $(addprefix -D, $(DEFINES)) $(addprefix -I, $(INCLUDES)) -c $< -o $@

$(OBJDIR)/%.o: %.s
	@echo assembling $<
	@$(CC) $(CFLAGS) $(CFLAGS2) $(addprefix -D, $(DEFINES)) $(addprefix -I, $(INCLUDES)) -c $< -o $@

.PHONY: module doc demo clean program help all

stm32f103x6 bluepill:
	@$(MAKE) clean demo STARTUP='$(CMSISDEV)/ST/STM32F1xx/Source/Templates/gcc/startup_stm32f103x6.s' \
						LDSCRIPT='demo/stm32f103x6.ld' \
						DEFINES='STM32F1 STM32F103x6 USBD_SOF_DISABLED USBD_ASM_DRIVER' \
						CFLAGS='-mcpu=cortex-m3 -mthumb'

stm32l052x8:
	@$(MAKE) clean demo STARTUP='$(CMSISDEV)/ST/STM32L0xx/Source/Templates/gcc/startup_stm32l052xx.s' \
						LDSCRIPT='demo/stm32l052x8.ld' \
						DEFINES='STM32L0 STM32L052xx USBD_SOF_DISABLED' \
						CFLAGS='-mcpu=cortex-m0plus -mthumb'

stm32l100xc 32l100c-disco:
	@$(MAKE) clean demo STARTUP='$(CMSISDEV)/ST/STM32L1xx/Source/Templates/gcc/startup_stm32l100xc.s' \
						LDSCRIPT='demo/stm32l100xc.ld' \
						DEFINES='STM32L1 STM32L100xC USBD_SOF_DISABLED' \
						CFLAGS='-mcpu=cortex-m3 -mthumb'

stm32l476xg 32l476rg-nucleo:
	@$(MAKE) clean demo STARTUP='$(CMSISDEV)/ST/STM32L4xx/Source/Templates/gcc/startup_stm32l476xx.s' \
						LDSCRIPT='demo/stm32l476xg.ld' \
						DEFINES='STM32L4 STM32L476xx USBD_SOF_DISABLED' \
						CFLAGS='-mcpu=cortex-m4 -mthumb'