###########################################################################
## Makefile generated for component 'PiL_MARLUP_IAC26'. 
## 
## Makefile     : PiL_MARLUP_IAC26.mk
## Generated on : Thu Sep 24 20:13:40 2026
## Final product: $(RELATIVE_PATH_TO_ANCHOR)/PiL_MARLUP_IAC26.elf
## Product type : executable
## 
###########################################################################

###########################################################################
## MACROS
###########################################################################

# Macro Descriptions:
# PRODUCT_NAME            Name of the system to build
# MAKEFILE                Name of this makefile
# COMPILER_COMMAND_FILE   Compiler command listing model reference header paths
# CMD_FILE                Command file

PRODUCT_NAME              = PiL_MARLUP_IAC26
MAKEFILE                  = PiL_MARLUP_IAC26.mk
MATLAB_ROOT               = D:/Softwares/Matlab2026a
MATLAB_BIN                = D:/Softwares/Matlab2026a/bin
MATLAB_ARCH_BIN           = $(MATLAB_BIN)/win64
START_DIR                 = D:/RESEARCH/MARLUP/MARLUP/FINAL MODEL/Paper_IAC
SOLVER                    = 
SOLVER_OBJ                = 
CLASSIC_INTERFACE         = 0
TGT_FCN_LIB               = ISO_C
MODEL_HAS_DYNAMICALLY_LOADED_SFCNS = 0
RELATIVE_PATH_TO_ANCHOR   = ..
MW_FLOATING_POINT_ABI_ARGS = -mfloat-abi=hard
COMPILER_COMMAND_FILE     = PiL_MARLUP_IAC26_comp.rsp
CMD_FILE                  = PiL_MARLUP_IAC26.rsp
C_STANDARD_OPTS           = 
CPP_STANDARD_OPTS         = 

###########################################################################
## TOOLCHAIN SPECIFICATIONS
###########################################################################

# Toolchain Name:          GNU Tools for STM32
# Supported Version(s):    
# ToolchainInfo Version:   2026a
# Specification Revision:  1.0
# 
#-------------------------------------------
# Macros assumed to be defined elsewhere
#-------------------------------------------

# TARGET_LOAD_CMD_ARGS
# TARGET_LOAD_CMD
# MW_GNU_ARM_STM32_PATH
# FDATASECTIONS_FLG

#-----------
# MACROS
#-----------

LIBGCC                    = ${shell $(MW_GNU_ARM_STM32_PATH)/arm-none-eabi-gcc ${CFLAGS} -print-libgcc-file-name}
LIBC                      = ${shell $(MW_GNU_ARM_STM32_PATH)/arm-none-eabi-gcc ${CFLAGS} -print-file-name=libc.a}
LIBM                      = ${shell $(MW_GNU_ARM_STM32_PATH)/arm-none-eabi-gcc ${CFLAGS} -print-file-name=libm.a}
PRODUCT_NAME_WITHOUT_EXTN = $(basename $(PRODUCT))
PRODUCT_BIN               = $(PRODUCT_NAME_WITHOUT_EXTN).bin
PRODUCT_HEX               = $(PRODUCT_NAME_WITHOUT_EXTN).hex
CPFLAGS                   = -O binary
SHELL                     = %SystemRoot%/system32/cmd.exe

TOOLCHAIN_SRCS = 
TOOLCHAIN_INCS = 
TOOLCHAIN_LIBS = -lm

FORMAT_FOR_ECHO_CMD              = $(strip $(subst >,^>,\
	$(subst <,^<,\
	$(subst |,^|,\
	$(subst &,^&,\
	$(subst ",^",\
	$(subst ^,^^,\
	$1)))))))
FORMAT_FOR_ECHO                  = $(FORMAT_FOR_ECHO_CMD)
HASH                             = \#
SEMICOLON                        = ;
UNESCAPE_SEMICOLONS              = $(subst \;,;,$1)
ADD_QUOTES                       = $(foreach aPath,$1,"$(aPath)")
EMPTY                            =
SPACE                            = $(EMPTY) $(EMPTY)
SPACE_TO_QUESTION                = $(subst $(SPACE),?,$1)
ESCAPE_SPACES                    = $(subst $(SPACE),\ ,$1)
SUBSTITUTE_ESCAPED_SPACES        = $(subst \ ,__<SPACE>__,$1)
REVERT_SPACES                    = $(subst __<SPACE>__,$(SPACE),$1)
CONVERT_ESCAPED_SPACES_TO_QUOTES = $(call UNESCAPE_SEMICOLONS,$(call REVERT_SPACES,$(call ADD_QUOTES,$(call SUBSTITUTE_ESCAPED_SPACES,$1))))

#------------------------
# BUILD TOOL COMMANDS
#------------------------

# Assembler: GNU ARM Assembler
AS_PATH = $(MW_GNU_ARM_STM32_PATH)
AS = "$(AS_PATH)/arm-none-eabi-gcc"

# C Compiler: GNU ARM C Compiler
CC_PATH = $(MW_GNU_ARM_STM32_PATH)
CC = "$(CC_PATH)/arm-none-eabi-gcc"

# Linker: GNU ARM Linker
LD_PATH = $(MW_GNU_ARM_STM32_PATH)
LD = "$(LD_PATH)/arm-none-eabi-g++"

# C++ Compiler: GNU ARM C++ Compiler
CPP_PATH = $(MW_GNU_ARM_STM32_PATH)
CPP = "$(CPP_PATH)/arm-none-eabi-g++"

# C++ Linker: GNU ARM C++ Linker
CPP_LD_PATH = $(MW_GNU_ARM_STM32_PATH)
CPP_LD = "$(CPP_LD_PATH)/arm-none-eabi-g++"

# Archiver: GNU ARM Archiver
AR_PATH = $(MW_GNU_ARM_STM32_PATH)
AR = "$(AR_PATH)/arm-none-eabi-ar"

# MEX Tool: MEX Tool
MEX_PATH = $(MATLAB_ARCH_BIN)
MEX = "$(MEX_PATH)/mex"

# Binary Converter: Binary Converter
OBJCOPYPATH = $(MW_GNU_ARM_STM32_PATH)
OBJCOPY = "$(OBJCOPYPATH)/arm-none-eabi-objcopy"

# Hex Converter: Hex Converter
OBJCOPYPATH = $(MW_GNU_ARM_STM32_PATH)
OBJCOPY = "$(OBJCOPYPATH)/arm-none-eabi-objcopy"

# Download: Download
DOWNLOAD =

# Execute: Execute
EXECUTE = $(PRODUCT)

# Builder: GMAKE Utility
MAKE_PATH = %MATLAB%\bin\win64
MAKE = "$(MAKE_PATH)/gmake"


#-------------------------
# Directives/Utilities
#-------------------------

ASDEBUG             = -g
AS_OUTPUT_FLAG      = -o
CDEBUG              = -g
C_OUTPUT_FLAG       = -o
LDDEBUG             = -g
OUTPUT_FLAG         = -o
CPPDEBUG            = -g
CPP_OUTPUT_FLAG     = -o
CPPLDDEBUG          = -g
OUTPUT_FLAG         = -o
ARDEBUG             =
STATICLIB_OUTPUT_FLAG =
MEX_DEBUG           = -g
RM                  = @del /f/q
ECHO                = @echo
MV                  = @move
RUN                 =

#--------------------------------------
# "Faster Runs" Build Configuration
#--------------------------------------

ARFLAGS              = ruvs
ASFLAGS              = -MMD -MP -MF"$(@:%.s.o=%.s.dep)" -MT"$@"  \
                       -Wall \
                       -x assembler-with-cpp \
                       $(ASFLAGS_ADDITIONAL) \
                       $(DEFINES) \
                       $(INCLUDES) \
                       -c
OBJCOPYFLAGS_BIN     = -O binary $(PRODUCT) $(PRODUCT_BIN)
CFLAGS               = $(FDATASECTIONS_FLG) \
                       -Wall \
                       -c \
                       -MMD -MP -MF"$(@:%.c.o=%.c.dep)" -MT"$@"  \
                       -O2
CPPFLAGS             = -std=gnu++14 \
                       -fno-rtti \
                       -fno-exceptions \
                       $(FDATASECTIONS_FLG) \
                       -Wall \
                       -c \
                       -MMD -MP -MF"$(@:%.cpp.o=%.cpp.dep)" -MT"$@"  \
                       -O2
CPP_LDFLAGS          = -Wl,--gc-sections \
                       -Wl,-Map="$(PRODUCT_NAME).map" \
                       -Wl,--print-memory-usage
CPP_SHAREDLIB_LDFLAGS  =
DOWNLOAD_FLAGS       =
EXECUTE_FLAGS        =
OBJCOPYFLAGS_HEX     = -O ihex $(PRODUCT) $(PRODUCT_HEX)
LDFLAGS              = -Wl,--gc-sections \
                       -Wl,-Map="$(PRODUCT_NAME).map" \
                       -Wl,--print-memory-usage
MEX_CPPFLAGS         =
MEX_CPPLDFLAGS       =
MEX_CFLAGS           =
MEX_LDFLAGS          =
MAKE_FLAGS           = -f $(MAKEFILE)
SHAREDLIB_LDFLAGS    =



###########################################################################
## OUTPUT INFO
###########################################################################

PRODUCT = $(RELATIVE_PATH_TO_ANCHOR)/PiL_MARLUP_IAC26.elf
PRODUCT_TYPE = "executable"
BUILD_TYPE = "Top-Level Standalone Executable"

###########################################################################
## INCLUDE PATHS
###########################################################################

INCLUDES_BUILDINFO = 

INCLUDES = $(INCLUDES_BUILDINFO)

###########################################################################
## DEFINES
###########################################################################

DEFINES_ = -D__MW_TARGET_USE_HARDWARE_RESOURCES_H__ -DMW_TIMEBASESOURCE=TIM5 -D__FPU_USED=1U
DEFINES_BUILD_ARGS = -DCLASSIC_INTERFACE=0 -DALLOCATIONFCN=0 -DTERMFCN=1 -DONESTEPFCN=1 -DMAT_FILE=0 -DMULTI_INSTANCE_CODE=0 -DINTEGER_CODE=0 -DMT=0
DEFINES_CUBEMXDEFINES = -DSTM32F446xx -DUSE_FULL_LL_DRIVER -DUSE_HAL_DRIVER
DEFINES_CUSTOM = 
DEFINES_OPTS = -DTID01EQ=0
DEFINES_SKIPFORSIL = -DXCP_CUSTOM_PLATFORM -DXCP_MEM_DAQ_RESERVED_POOL_BLOCKS_NUMBER=10 -D__FPU_PRESENT=1U -DSTACK_SIZE=512 -DRT
DEFINES_STANDARD = -DMODEL=PiL_MARLUP_IAC26 -DNUMST=1 -DNCSTATES=0 -DHAVESTDIO -DMODEL_HAS_DYNAMICALLY_LOADED_SFCNS=0
DEFINES_STM32DEVICEDRIVERBLOCKS = -DIO_AUTOGEN_ANALOG_TO_DIGITAL_CONVERTER=0 -DIO_AUTOGEN_DIGITAL_PORT=0 -DIO_AUTOGEN_I2C=0 -DIO_AUTOGEN_REGISTER_RW=0 -DIO_AUTOGEN_PWM_OUTPUT=0

DEFINES = $(DEFINES_) $(DEFINES_BUILD_ARGS) $(DEFINES_CUBEMXDEFINES) $(DEFINES_CUSTOM) $(DEFINES_OPTS) $(DEFINES_SKIPFORSIL) $(DEFINES_STANDARD) $(DEFINES_STM32DEVICEDRIVERBLOCKS)

###########################################################################
## SOURCE FILES
###########################################################################

SRCS = "$(START_DIR)/PiL_MARLUP_IAC26_ert_rtw/PiL_MARLUP_IAC26.c" "$(START_DIR)/PiL_MARLUP_IAC26_ert_rtw/PiL_MARLUP_IAC26_data.c" $(MATLAB_ROOT)/toolbox/stm32b/stm32shared/src/overrideHALDelay.c $(MATLAB_ROOT)/toolbox/stm32b/stm32shared/src/platform_timer.c $(MATLAB_ROOT)/toolbox/target/shared/armcortexmbase/scheduler/src/SysTickScheduler.c $(MATLAB_ROOT)/toolbox/target/shared/armcortexmbase/scheduler/src/m3m4m4f_multitasking.c "$(START_DIR)/MARLUP_PiL/Core/Src/main.c" "$(START_DIR)/MARLUP_PiL/Core/Src/stm32f4xx_hal_msp.c" "$(START_DIR)/MARLUP_PiL/Core/Src/stm32f4xx_hal_timebase_tim.c" "$(START_DIR)/MARLUP_PiL/Core/Src/stm32f4xx_it.c" "$(START_DIR)/MARLUP_PiL/Core/Src/system_stm32f4xx.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim_ex.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_dma.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_exti.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_gpio.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_rcc.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_usart.c" "$(START_DIR)/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_utils.c" "$(START_DIR)/MARLUP_PiL/STM32CubeIDE/Application/User/Core/syscalls.c" "$(START_DIR)/MARLUP_PiL/STM32CubeIDE/Application/User/Core/sysmem.c" "$(START_DIR)/MARLUP_PiL/STM32CubeIDE/Application/User/Startup/startup_stm32f446retx.s"

MAIN_SRC = "$(START_DIR)/PiL_MARLUP_IAC26_ert_rtw/ert_main.c"

ALL_SRCS = $(SRCS) $(MAIN_SRC)

###########################################################################
## OBJECTS
###########################################################################

OBJS = PiL_MARLUP_IAC26.c.o PiL_MARLUP_IAC26_data.c.o overrideHALDelay.c.o platform_timer.c.o SysTickScheduler.c.o m3m4m4f_multitasking.c.o main.c.o stm32f4xx_hal_msp.c.o stm32f4xx_hal_timebase_tim.c.o stm32f4xx_it.c.o system_stm32f4xx.c.o stm32f4xx_hal.c.o stm32f4xx_hal_cortex.c.o stm32f4xx_hal_dma.c.o stm32f4xx_hal_dma_ex.c.o stm32f4xx_hal_exti.c.o stm32f4xx_hal_flash.c.o stm32f4xx_hal_flash_ex.c.o stm32f4xx_hal_flash_ramfunc.c.o stm32f4xx_hal_gpio.c.o stm32f4xx_hal_pwr.c.o stm32f4xx_hal_pwr_ex.c.o stm32f4xx_hal_rcc.c.o stm32f4xx_hal_rcc_ex.c.o stm32f4xx_hal_tim.c.o stm32f4xx_hal_tim_ex.c.o stm32f4xx_ll_dma.c.o stm32f4xx_ll_exti.c.o stm32f4xx_ll_gpio.c.o stm32f4xx_ll_rcc.c.o stm32f4xx_ll_usart.c.o stm32f4xx_ll_utils.c.o syscalls.c.o sysmem.c.o startup_stm32f446retx.s.o

MAIN_OBJ = ert_main.c.o

ALL_OBJS = $(OBJS) $(MAIN_OBJ)

###########################################################################
## PREBUILT OBJECT FILES
###########################################################################

PREBUILT_OBJS = 

###########################################################################
## LIBRARIES
###########################################################################

LIBS = $(MATLAB_ROOT)/toolbox/stm32b/stm32shared/lib/GCC/libmw_pdmfilter_m4_spfp.lib

###########################################################################
## SYSTEM LIBRARIES
###########################################################################

SYSTEM_LIBS = 

###########################################################################
## ADDITIONAL TOOLCHAIN FLAGS
###########################################################################

#---------------
# C Compiler
#---------------

CFLAGS_SKIPFORSIL = -mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -mfpu=fpv4-sp-d16  -ffp-contract=off -mfloat-abi=hard
CFLAGS_BASIC = $(DEFINES) $(INCLUDES) @$(COMPILER_COMMAND_FILE)

CFLAGS += $(CFLAGS_SKIPFORSIL) $(CFLAGS_BASIC)

#-----------------
# C++ Compiler
#-----------------

CPPFLAGS_SKIPFORSIL = -mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -mfpu=fpv4-sp-d16  -ffp-contract=off -mfloat-abi=hard
CPPFLAGS_BASIC = $(DEFINES) $(INCLUDES) @$(COMPILER_COMMAND_FILE)

CPPFLAGS += $(CPPFLAGS_SKIPFORSIL) $(CPPFLAGS_BASIC)

#---------------
# C++ Linker
#---------------

CPP_LDFLAGS_SKIPFORSIL = -mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -mfpu=fpv4-sp-d16  --entry Reset_Handler --specs=nosys.specs  --specs=nano.specs -mfloat-abi=hard -T "D:\RESEARCH\MARLUP\MARLUP\FINAL MODEL\Paper_IAC\MARLUP_PiL\STM32CubeIDE\STM32F446RETX_FLASH.ld"

CPP_LDFLAGS += $(CPP_LDFLAGS_SKIPFORSIL)

#------------------------------
# C++ Shared Library Linker
#------------------------------

CPP_SHAREDLIB_LDFLAGS_SKIPFORSIL = -mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -mfpu=fpv4-sp-d16  --entry Reset_Handler --specs=nosys.specs  --specs=nano.specs -mfloat-abi=hard -T "D:\RESEARCH\MARLUP\MARLUP\FINAL MODEL\Paper_IAC\MARLUP_PiL\STM32CubeIDE\STM32F446RETX_FLASH.ld"

CPP_SHAREDLIB_LDFLAGS += $(CPP_SHAREDLIB_LDFLAGS_SKIPFORSIL)

#-----------
# Linker
#-----------

LDFLAGS_SKIPFORSIL = -mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -mfpu=fpv4-sp-d16  --entry Reset_Handler --specs=nosys.specs  --specs=nano.specs -mfloat-abi=hard -T "D:\RESEARCH\MARLUP\MARLUP\FINAL MODEL\Paper_IAC\MARLUP_PiL\STM32CubeIDE\STM32F446RETX_FLASH.ld"

LDFLAGS += $(LDFLAGS_SKIPFORSIL)

#---------------------
# MEX C++ Compiler
#---------------------

MEX_CPP_Compiler_BASIC =  @$(COMPILER_COMMAND_FILE)

MEX_CPPFLAGS += $(MEX_CPP_Compiler_BASIC)

#-----------------
# MEX Compiler
#-----------------

MEX_Compiler_BASIC =  @$(COMPILER_COMMAND_FILE)

MEX_CFLAGS += $(MEX_Compiler_BASIC)

#--------------------------
# Shared Library Linker
#--------------------------

SHAREDLIB_LDFLAGS_SKIPFORSIL = -mcpu=cortex-m4 -mthumb -mlittle-endian -mthumb-interwork -mfpu=fpv4-sp-d16  --entry Reset_Handler --specs=nosys.specs  --specs=nano.specs -mfloat-abi=hard -T "D:\RESEARCH\MARLUP\MARLUP\FINAL MODEL\Paper_IAC\MARLUP_PiL\STM32CubeIDE\STM32F446RETX_FLASH.ld"

SHAREDLIB_LDFLAGS += $(SHAREDLIB_LDFLAGS_SKIPFORSIL)

###########################################################################
## INLINED COMMANDS
###########################################################################


ALL_DEPS:=$(patsubst %.o,%.dep,$(ALL_OBJS))
all:

ifndef DISABLE_GCC_FUNCTION_DATA_SECTIONS
FDATASECTIONS_FLG := -ffunction-sections -fdata-sections
endif



-include codertarget_assembly_flags.mk
-include ../codertarget_assembly_flags.mk
-include ../../codertarget_assembly_flags.mk
-include mw_gnu_tools_for_stm32_path.mk
-include ../mw_gnu_tools_for_stm32_path.mk
-include ../../mw_gnu_tools_for_stm32_path.mk
-include $(ALL_DEPS)


###########################################################################
## PHONY TARGETS
###########################################################################

.PHONY : all build buildobj clean info prebuild postbuild download execute


all : build postbuild
	@echo $(call FORMAT_FOR_ECHO,### Successfully generated all binary outputs.)


build : prebuild $(PRODUCT)


buildobj : prebuild $(OBJS) $(PREBUILT_OBJS) $(LIBS)
	@echo $(call FORMAT_FOR_ECHO,### Successfully generated all binary outputs.)


prebuild : 


postbuild : $(PRODUCT)
	@echo $(call FORMAT_FOR_ECHO,### Invoking postbuild tool Binary Converter ...)
	$(OBJCOPY) $(OBJCOPYFLAGS_BIN)
	@echo $(call FORMAT_FOR_ECHO,### Done invoking postbuild tool.)
	@echo $(call FORMAT_FOR_ECHO,### Invoking postbuild tool Hex Converter ...)
	$(OBJCOPY) $(OBJCOPYFLAGS_HEX)
	@echo $(call FORMAT_FOR_ECHO,### Done invoking postbuild tool.)


download : postbuild


execute : download
	@echo $(call FORMAT_FOR_ECHO,### Invoking postbuild tool Execute ...)
	$(EXECUTE) $(EXECUTE_FLAGS)
	@echo $(call FORMAT_FOR_ECHO,### Done invoking postbuild tool.)


###########################################################################
## FINAL TARGET
###########################################################################

#-------------------------------------------
# Create a standalone executable            
#-------------------------------------------

$(PRODUCT) : $(OBJS) $(PREBUILT_OBJS) $(LIBS) $(MAIN_OBJ)
	@echo $(call FORMAT_FOR_ECHO,### Creating standalone executable "$(PRODUCT)" ...)
	$(LD) $(LDFLAGS) -o $(PRODUCT) @$(CMD_FILE) $(call CONVERT_ESCAPED_SPACES_TO_QUOTES,$(LIBS)) $(SYSTEM_LIBS) $(TOOLCHAIN_LIBS)
	@echo $(call FORMAT_FOR_ECHO,### Created: "$(PRODUCT)")


###########################################################################
## INTERMEDIATE TARGETS
###########################################################################

#---------------------
# SOURCE-TO-OBJECT
#---------------------

%.c.o : %.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.cpp.o : %.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : %.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : %.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : %.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.s.o : %.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.s.o : %.S
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.c.o : $(RELATIVE_PATH_TO_ANCHOR)/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.cpp.o : $(RELATIVE_PATH_TO_ANCHOR)/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(RELATIVE_PATH_TO_ANCHOR)/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(RELATIVE_PATH_TO_ANCHOR)/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(RELATIVE_PATH_TO_ANCHOR)/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.s.o : $(RELATIVE_PATH_TO_ANCHOR)/%.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.s.o : $(RELATIVE_PATH_TO_ANCHOR)/%.S
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.c.o : $(call SPACE_TO_QUESTION,$(START_DIR))/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.s.o : $(call SPACE_TO_QUESTION,$(START_DIR))/%.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.s.o : $(call SPACE_TO_QUESTION,$(START_DIR))/%.S
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.c.o : $(call SPACE_TO_QUESTION,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(call SPACE_TO_QUESTION,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.s.o : $(call SPACE_TO_QUESTION,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/%.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.s.o : $(call SPACE_TO_QUESTION,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/%.S
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.c.o : $(MATLAB_ROOT)/rtw/c/src/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/rtw/c/src/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/rtw/c/src/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/rtw/c/src/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/rtw/c/src/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.s.o : $(MATLAB_ROOT)/rtw/c/src/%.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.s.o : $(MATLAB_ROOT)/rtw/c/src/%.S
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.c.o : $(MATLAB_ROOT)/simulink/src/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/simulink/src/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/simulink/src/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/simulink/src/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/simulink/src/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.s.o : $(MATLAB_ROOT)/simulink/src/%.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.s.o : $(MATLAB_ROOT)/simulink/src/%.S
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.c.o : $(MATLAB_ROOT)/toolbox/simulink/blocks/src/%.c
	$(CC) $(CFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/toolbox/simulink/blocks/src/%.cpp
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/toolbox/simulink/blocks/src/%.cc
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/toolbox/simulink/blocks/src/%.C
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.cpp.o : $(MATLAB_ROOT)/toolbox/simulink/blocks/src/%.cxx
	$(CPP) $(CPPFLAGS) -o "$@" "$<"


%.s.o : $(MATLAB_ROOT)/toolbox/simulink/blocks/src/%.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


%.s.o : $(MATLAB_ROOT)/toolbox/simulink/blocks/src/%.S
	$(AS) $(ASFLAGS) -o "$@" "$<"


PiL_MARLUP_IAC26.c.o : $(call ESCAPE_SPACES,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/PiL_MARLUP_IAC26.c
	$(CC) $(CFLAGS) -o "$@" "$<"


PiL_MARLUP_IAC26_data.c.o : $(call ESCAPE_SPACES,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/PiL_MARLUP_IAC26_data.c
	$(CC) $(CFLAGS) -o "$@" "$<"


ert_main.c.o : $(call ESCAPE_SPACES,$(START_DIR))/PiL_MARLUP_IAC26_ert_rtw/ert_main.c
	$(CC) $(CFLAGS) -o "$@" "$<"


overrideHALDelay.c.o : $(MATLAB_ROOT)/toolbox/stm32b/stm32shared/src/overrideHALDelay.c
	$(CC) $(CFLAGS) -o "$@" "$<"


platform_timer.c.o : $(MATLAB_ROOT)/toolbox/stm32b/stm32shared/src/platform_timer.c
	$(CC) $(CFLAGS) -o "$@" "$<"


SysTickScheduler.c.o : $(MATLAB_ROOT)/toolbox/target/shared/armcortexmbase/scheduler/src/SysTickScheduler.c
	$(CC) $(CFLAGS) -o "$@" "$<"


m3m4m4f_multitasking.c.o : $(MATLAB_ROOT)/toolbox/target/shared/armcortexmbase/scheduler/src/m3m4m4f_multitasking.c
	$(CC) $(CFLAGS) -o "$@" "$<"


main.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Core/Src/main.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_msp.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Core/Src/stm32f4xx_hal_msp.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_timebase_tim.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Core/Src/stm32f4xx_hal_timebase_tim.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_it.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Core/Src/stm32f4xx_it.c
	$(CC) $(CFLAGS) -o "$@" "$<"


system_stm32f4xx.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Core/Src/system_stm32f4xx.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_cortex.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_dma.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_dma_ex.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_exti.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_flash.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_flash_ex.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_flash_ramfunc.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_gpio.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_pwr.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_pwr_ex.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_rcc.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_rcc_ex.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_tim.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_hal_tim_ex.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim_ex.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_ll_dma.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_dma.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_ll_exti.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_exti.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_ll_gpio.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_gpio.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_ll_rcc.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_rcc.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_ll_usart.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_usart.c
	$(CC) $(CFLAGS) -o "$@" "$<"


stm32f4xx_ll_utils.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_ll_utils.c
	$(CC) $(CFLAGS) -o "$@" "$<"


syscalls.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/STM32CubeIDE/Application/User/Core/syscalls.c
	$(CC) $(CFLAGS) -o "$@" "$<"


sysmem.c.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/STM32CubeIDE/Application/User/Core/sysmem.c
	$(CC) $(CFLAGS) -o "$@" "$<"


startup_stm32f446retx.s.o : $(call ESCAPE_SPACES,$(START_DIR))/MARLUP_PiL/STM32CubeIDE/Application/User/Startup/startup_stm32f446retx.s
	$(AS) $(ASFLAGS) -o "$@" "$<"


###########################################################################
## DEPENDENCIES
###########################################################################

$(ALL_OBJS) : rtw_proj.tmw $(COMPILER_COMMAND_FILE) $(MAKEFILE)


###########################################################################
## MISCELLANEOUS TARGETS
###########################################################################

info : 
	@echo $(call FORMAT_FOR_ECHO,### PRODUCT = $(PRODUCT))
	@echo $(call FORMAT_FOR_ECHO,### PRODUCT_TYPE = $(PRODUCT_TYPE))
	@echo $(call FORMAT_FOR_ECHO,### BUILD_TYPE = $(BUILD_TYPE))
	@echo $(call FORMAT_FOR_ECHO,### INCLUDES = $(INCLUDES))
	@echo $(call FORMAT_FOR_ECHO,### DEFINES = $(DEFINES))
	@echo $(call FORMAT_FOR_ECHO,### ALL_SRCS = $(ALL_SRCS))
	@echo $(call FORMAT_FOR_ECHO,### ALL_OBJS = $(ALL_OBJS))
	@echo $(call FORMAT_FOR_ECHO,### LIBS = $(LIBS))
	@echo $(call FORMAT_FOR_ECHO,### MODELREF_LIBS = $(MODELREF_LIBS))
	@echo $(call FORMAT_FOR_ECHO,### SYSTEM_LIBS = $(SYSTEM_LIBS))
	@echo $(call FORMAT_FOR_ECHO,### TOOLCHAIN_LIBS = $(TOOLCHAIN_LIBS))
	@echo $(call FORMAT_FOR_ECHO,### ASFLAGS = $(ASFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### CFLAGS = $(CFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### LDFLAGS = $(LDFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### SHAREDLIB_LDFLAGS = $(SHAREDLIB_LDFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### CPPFLAGS = $(CPPFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### CPP_LDFLAGS = $(CPP_LDFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### CPP_SHAREDLIB_LDFLAGS = $(CPP_SHAREDLIB_LDFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### ARFLAGS = $(ARFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### MEX_CFLAGS = $(MEX_CFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### MEX_CPPFLAGS = $(MEX_CPPFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### MEX_LDFLAGS = $(MEX_LDFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### MEX_CPPLDFLAGS = $(MEX_CPPLDFLAGS))
	@echo $(call FORMAT_FOR_ECHO,### OBJCOPYFLAGS_BIN = $(OBJCOPYFLAGS_BIN))
	@echo $(call FORMAT_FOR_ECHO,### OBJCOPYFLAGS_HEX = $(OBJCOPYFLAGS_HEX))
	@echo $(call FORMAT_FOR_ECHO,### DOWNLOAD_FLAGS = $(DOWNLOAD_FLAGS))
	@echo $(call FORMAT_FOR_ECHO,### EXECUTE_FLAGS = $(EXECUTE_FLAGS))
	@echo $(call FORMAT_FOR_ECHO,### MAKE_FLAGS = $(MAKE_FLAGS))


clean : 
	$(ECHO) "### Deleting all derived files ..."
	$(RM) $(subst /,\,$(PRODUCT))
	$(RM) $(subst /,\,$(ALL_OBJS))
	$(RM) *.c.dep
	$(RM) *.cpp.dep
	$(RM) *.s.dep
	$(ECHO) "### Deleted all derived files."


