#
# embedXcode
# ----------------------------------
# Embedded Computing on Xcode
#
# Copyright © Rei VILO, 2010-2016
# http://embedxcode.weebly.com
# All rights reserved
#
#
# Last update: Mar 11, 2016 release 4.4.0



# Energia CC3200 EMT specifics
# ----------------------------------
#
APPLICATION_PATH := $(ENERGIA_PATH)
ENERGIA_RELEASE  := $(shell tail -c2 $(APPLICATION_PATH)/lib/version.txt)
ARDUINO_RELEASE  := $(shell head -c4 $(APPLICATION_PATH)/lib/version.txt | tail -c3)

ifeq ($(shell if [[ '$(ENERGIA_RELEASE)' -ge '17' ]] ; then echo 1 ; else echo 0 ; fi ),0)
    WARNING_MESSAGE = Energia 17 or later is required.
endif

PLATFORM         := Energia
BUILD_CORE       := cc2600emt
PLATFORM_TAG      = ENERGIA=$(ENERGIA_RELEASE) ARDUINO=$(ARDUINO_RELEASE) EMBEDXCODE=$(RELEASE_NOW) $(filter __%__ ,$(GCC_PREPROCESSOR_DEFINITIONS)) ENERGIA_MT
MULTI_INO         := 1

UPLOADER          = DSLite
UPLOADER_PATH     = $(APPLICATION_PATH)/tools/common/DSLite
UPLOADER_EXEC     = $(UPLOADER_PATH)/DebugServer/bin/DSLite
UPLOADER_OPTS     = $(UPLOADER_PATH)/CC2650F128_TIXDS110_Connection.ccxml

# StellarPad requires a specific command
#
UPLOADER_COMMAND = prog

APP_TOOLS_PATH  := $(APPLICATION_PATH)/hardware/tools/lm4f/bin
CORES_PATH      := $(APPLICATION_PATH)/hardware/cc2600emt/cores/cc2600emt
APP_LIB_PATH    := $(APPLICATION_PATH)/hardware/cc2600emt/libraries
BOARDS_TXT      := $(APPLICATION_PATH)/hardware/cc2600emt/boards.txt


# Sketchbook/Libraries path
# wildcard required for ~ management
# ?ibraries required for libraries and Libraries
#
ifeq ($(USER_LIBRARY_DIR)/Energia/preferences.txt,)
    $(error Error: run Energia once and define the sketchbook path)
endif

ifeq ($(wildcard $(SKETCHBOOK_DIR)),)
    SKETCHBOOK_DIR = $(shell grep sketchbook.path $(wildcard ~/Library/Energia/preferences.txt) | cut -d = -f 2)
endif

ifeq ($(wildcard $(SKETCHBOOK_DIR)),)
    $(error Error: sketchbook path not found)
endif

USER_LIB_PATH  = $(wildcard $(SKETCHBOOK_DIR)/?ibraries)


# Rules for making a c++ file from the main sketch (.pde)
#
PDEHEADER      = \\\#include \"Energia.h\"  


# Tool-chain names
#
CC      = $(APP_TOOLS_PATH)/arm-none-eabi-gcc
CXX     = $(APP_TOOLS_PATH)/arm-none-eabi-g++
AR      = $(APP_TOOLS_PATH)/arm-none-eabi-ar
OBJDUMP = $(APP_TOOLS_PATH)/arm-none-eabi-objdump
OBJCOPY = $(APP_TOOLS_PATH)/arm-none-eabi-objcopy
SIZE    = $(APP_TOOLS_PATH)/arm-none-eabi-size
NM      = $(APP_TOOLS_PATH)/arm-none-eabi-nm
# ~
GDB     = $(APP_TOOLS_PATH)/arm-none-eabi-gdb
# ~~


BOARD            = $(call PARSE_BOARD,$(BOARD_TAG),board)
VARIANT          = $(call PARSE_BOARD,$(BOARD_TAG),build.variant)
VARIANT_PATH     = $(APPLICATION_PATH)/hardware/cc2600emt/variants/$(VARIANT)
CORE_A           = $(CORES_PATH)/driverlib/libdriverlib.a
#LDSCRIPT         = $(VARIANT_PATH)/linker.cmd
LDSCRIPT         = $(APPLICATION_PATH)/hardware/emt/ti/runtime/wiring/cc26xx/linker.cmd


# ~
ifeq ($(MAKECMDGOALS),debug)
    OPTIMISATION   ?= -O0 -ggdb
else
    OPTIMISATION   ?= -Os
endif
# ~~

MCU_FLAG_NAME    = mcpu
MCU              = $(call PARSE_BOARD,$(BOARD_TAG),build.mcu)
F_CPU            = $(call PARSE_BOARD,$(BOARD_TAG),build.f_cpu)

SUB_PATH         = $(sort $(dir $(wildcard $(1)/*/))) # */

INCLUDE_PATH     = $(call SUB_PATH,$(CORES_PATH))
INCLUDE_PATH    += $(call SUB_PATH,$(VARIANT_PATH))
INCLUDE_PATH    += $(call SUB_PATH,$(APPLICATION_PATH)/hardware/common)
INCLUDE_PATH    += $(APPLICATION_PATH)/hardware/tools/lm4f/include
INCLUDE_PATH    += $(APPLICATION_PATH)/hardware/emt
INCLUDE_PATH    += $(APPLICATION_PATH)/hardware/emt/ti/runtime/wiring/cc26xx
INCLUDE_PATH    += $(APPLICATION_PATH)/hardware/emt/ti/runtime/wiring/

INCLUDE_LIBS     = $(APPLICATION_PATH)/hardware/common
INCLUDE_LIBS    += $(APPLICATION_PATH)/hardware/tools/lm4f/lib
INCLUDE_LIBS    += $(APPLICATION_PATH)/hardware/common/libs
INCLUDE_LIBS    += $(APPLICATION_PATH)/hardware/emt/ti/runtime/wiring/cc26xx
INCLUDE_LIBS    += $(APPLICATION_PATH)/hardware/emt/ti/runtime/wiring/cc26xx/variants/CC2650STK_BLE
INCLUDE_LIBS    += $(APPLICATION_PATH)/hardware/emt
INCLUDE_LIBS    += $(APPLICATION_PATH)/hardware/cc2600emt/variants/CC2650STK_BLE

# Flags for gcc, g++ and linker
# ----------------------------------
#
# Common CPPFLAGS for gcc, g++, assembler and linker
#
CPPFLAGS     = $(OPTIMISATION) $(WARNING_FLAGS)
CPPFLAGS    += @$(APPLICATION_PATH)/hardware/emt/ti/runtime/wiring/cc26xx/compiler.opt
CPPFLAGS    += $(addprefix -I, $(INCLUDE_PATH))
CPPFLAGS    += $(addprefix -D, $(PLATFORM_TAG))
CPPFLAGS    += -DF_CPU=$(F_CPU) -D$(call PARSE_BOARD,$(BOARD_TAG),build.hardware)
CPPFLAGS    += -DBOARD_$(call PARSE_BOARD,$(BOARD_TAG),build.hardware)
CPPFLAGS    += $(addprefix -D, TARGET_IS_CC2650 xdc__nolocalstring=1)
CPPFLAGS    += -ffunction-sections -fdata-sections

# Specific CFLAGS for gcc only
# gcc uses CPPFLAGS and CFLAGS
#
CFLAGS       = #

# Specific CXXFLAGS for g++ only
# g++ uses CPPFLAGS and CXXFLAGS
#
CXXFLAGS    = -fno-exceptions -fno-rtti

# Specific ASFLAGS for gcc assembler only
# gcc assembler uses CPPFLAGS and ASFLAGS
#
ASFLAGS      = --asm_extension=S

# Specific LDFLAGS for linker only
# linker uses CPPFLAGS and LDFLAGS
#
LDFLAGS      = $(OPTIMISATION) $(WARNING_FLAGS) $(addprefix -D, $(PLATFORM_TAG))
LDFLAGS     += -Wl,-T $(LDSCRIPT) $(CORE_A) $(addprefix -L, $(INCLUDE_LIBS))
LDFLAGS     += @$(APPLICATION_PATH)/hardware/emt/ti/runtime/wiring/cc26xx/compiler.opt
LDFLAGS     += -nostartfiles -Wl,--no-wchar-size-warning -Wl,-static -Wl,--gc-sections
LDFLAGS     += $(CORES_PATH)/driverlib/libdriverlib.a
LDFLAGS     += -lstdc++ -lgcc -lc -lm -lnosys

# Specific OBJCOPYFLAGS for objcopy only
# objcopy uses OBJCOPYFLAGS only
#
OBJCOPYFLAGS  = -v -Oihex

# Target
#
TARGET_HEXBIN = $(TARGET_HEX)


# Commands
# ----------------------------------
#
COMMAND_LINK = $(CC) $(OUT_PREPOSITION)$@ $(LOCAL_OBJS) $(LOCAL_ARCHIVES) $(TARGET_A) $(LDFLAGS)

COMMAND_UPLOAD = $(UPLOADER_EXEC) load --config $(UPLOADER_OPTS) --file $(TARGET_HEX)
