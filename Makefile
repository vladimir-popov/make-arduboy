#==================================================	
#                 Project structure
#==================================================	

TARGET=hello_world

# Path to the arduino installation:
ARDUINO_DIR=$(HOME)/Library/Arduino15/packages/arduino

# Path to the directory with already installed arduino libraries:
LIBS_DIR=$(HOME)/Projects/Arduino/libraries

# Path to the directory with avr binaries:
AVR_DIR=$(ARDUINO_DIR)/tools/avr-gcc/7.3.0-atmel3.6.1-arduino7/bin

# Path to the ArdensPlayer - arduboy emmulator, to run the final *.hex file.
# Reed more here: https://github.com/tiberiusbrown/Ardens
ARDENS=$(HOME)/Projects/Arduino/Ardens/ArdensPlayer

# Path to the directory with hardware libs:
ARDUINO_HARDWARE_DIR=$(ARDUINO_DIR)/hardware/avr/1.8.6

# Path to the directory with core lib sources:
ARDUINO_CORE_DIR=$(ARDUINO_HARDWARE_DIR)/cores/arduino

# Path to the directory with EEPROM lib sources:
ARDUINO_EEPROM=$(ARDUINO_HARDWARE_DIR)/libraries/EEPROM/src

# Path to the directory with Arduboy2 sources:
ARDUBOY2_DIR=$(LIBS_DIR)/Arduboy2/src

# Project structure:
SRC_DIR=./src
OUTPUT_DIR=./output

#==================================================	
#             Compilation settings
#==================================================	

# The c compiler
CC=$(AVR_DIR)/avr-gcc

# The c++ compiler
CPP=$(AVR_DIR)/avr-g++

# The compilers options:

# Arduboy is equal to Leaonardo, which is atmega32u4;
MCU=-mmcu=atmega32u4
#
# CPU speed for Leonardo is:
CPU_SPEED=-DF_CPU=16000000UL

# Add add directories with headers:
HEADERS=-I$(ARDUINO_CORE_DIR) -I$(ARDUINO_HARDWARE_DIR)/variants/leonardo -I$(ARDUINO_EEPROM)

# The common for gcc and  g++ compilers flags:
# -Os 				- Optimize for size;
# -MMD				- Instead of outputting the result of preprocessing, output a rule 
#  				  suitable for make describing the dependencies of the header file.
# -flto				- This option runs the standard link-time optimizer. When invoked with 
#  				  source code, it generates GIMPLE (one of GCC’s internal representations)
#  				  and writes it to special ELF sections in the object file. When the 
#  				  object files are linked together, all the function bodies are read from 
#  				  these ELF sections and instantiated as if they had been part of the same 
#  				  translation unit.
# -ffunction-sections 		- Generates a separate ELF section for each function in the source file. 
#  				  The unused section elimination feature of the linker can then remove 
#  				  unused functions at link time.
# -fdata-sections		  Enables the generation of one ELF section for each variable in the 
#  				  source file.
CFLAGS= -Os -MMD -flto \
	-ffunction-sections \
	-fdata-sections \
	$(MCU) \
	$(CPU_SPEED) \
	$(HEADERS)

# C++ specified flags:
# -fno-threadsafe-statics 	- Do not emit the extra code to use the routines specified in 
#  			     	  the C++ ABI for thread-safe initialization of local statics;
# -fno-exceptions 		- We're not going to handle errors, so, let's
#  				  turn it off;
# -fpermissive 			- Downgrade some diagnostics about nonconformant code from 
#  				  errors to warnings;
CPPFLAGS = $(CFLAGS) \
	   -fno-threadsafe-statics \
	   -fno-exceptions \
	   -fpermissive \

# The linker options:
LDFLAGS = $(MCU)

# Tool to build *.hex files:
OBJCPY=$(AVR_DIR)/avr-objcopy

#==================================================	
#              Compile core library
#==================================================	

# Sources:
ARDUINO_CORE_SRC:=$(notdir $(wildcard $(ARDUINO_CORE_DIR)/*.S) $(wildcard $(ARDUINO_CORE_DIR)/*.c) $(wildcard $(ARDUINO_CORE_DIR)/*.cpp))

# Output directory:
OUTPUT_CORE=$(OUTPUT_DIR)/core

# List of object files:
ARDUINO_CORE_OBJ=$(ARDUINO_CORE_SRC:%=$(OUTPUT_CORE)/%.o)

#Additional compiler options:

# Arduino core has assembler files, so, we have to be ready to compile them
ASM=-xassembler-with-cpp
# List of arduino options:
DARDUINO=-DARDUINO=10607 -DARDUINO_AVR_LEONARDO -DARDUINO_ARCH_AVR
# List of USB options:
DUSB=-DUSB_VID=0x2341 -DUSB_PID=0x8036 -DUSB_MANUFACTURER="\"Unknown\"" -DUSB_PRODUCT="\"Arduino Leonardo\""

# Create directory if it doesn't exist:
$(OUTPUT_CORE):
	[ -d $(OUTPUT_CORE) ] || mkdir -p $(OUTPUT_CORE)

# Compile *.S files in the core lib:
$(OUTPUT_CORE)/%.S.o: $(ARDUINO_CORE_DIR)/%.S 
	$(CC) $(MCU) $(ASM) -c $< -o $@

# Compile *.c files in the core lib:
$(OUTPUT_CORE)/%.c.o: $(ARDUINO_CORE_DIR)/%.c 
	$(CC) $(CFLAGS) $(DARDUINO) $(DUSB) -c $< -o $@

# Compile *.cpp files in the core lib:
$(OUTPUT_CORE)/%.cpp.o: $(ARDUINO_CORE_DIR)/%.cpp 
	$(CPP) $(CPPFLAGS) $(DARDUINO) $(DUSB) -c $< -o $@

core: $(OUTPUT_CORE) $(ARDUINO_CORE_OBJ)
	@echo '----------------------------------------------'
	@echo ' Arduino core has been compiled successfully'
	@echo '----------------------------------------------'

#==================================================	
#                Compile Arduboy2
#==================================================	

# Sources (arduboy uses only *.cpp files):
ARDUBOY2_SRC:=$(notdir $(wildcard $(ARDUBOY2_DIR)/*.cpp))

# Output directory:
OUTPUT_ARDUBOY2=$(OUTPUT_DIR)/arduboy2

# List of object files:
ARDUBOY2_OBJ=$(ARDUBOY2_SRC:%=$(OUTPUT_ARDUBOY2)/%.o)

# Create directory if it doesn't exist:
$(OUTPUT_ARDUBOY2):
	[ -d $(OUTPUT_ARDUBOY2) ] || mkdir -p $(OUTPUT_ARDUBOY2)

# Compile *.cpp files in the core lib:
$(OUTPUT_ARDUBOY2)/%.cpp.o: $(ARDUBOY2_DIR)/%.cpp
	$(CPP) $(CPPFLAGS) -c $< -o $@

arduboy2: $(OUTPUT_ARDUBOY2) $(ARDUBOY2_OBJ)
	@echo '----------------------------------------------'
	@echo '    Arduboy2 has been compiled successfully'
	@echo '----------------------------------------------'

#==================================================	
#                Build project
#==================================================	

# Sources:
SRC=$(notdir $(wildcard $(SRC_DIR)/*.cpp))

# List of all object files from the project and dependencies:
OBJ=$(SRC:%=$(OUTPUT_DIR)/%.o)


# Create directory if it doesn't exist:
$(OUTPUT_DIR):
	[ -d $(OUTPUT_DIR) ] || mkdir -p $(OUTPUT_DIR)

# Compile *.cpp files in the core lib:
$(OUTPUT_DIR)/%.cpp.o: $(SRC_DIR)/%.cpp
	$(CPP) $(CPPFLAGS) -I$(ARDUBOY2_DIR) -c $< -o $@

# Link all together:
compile: $(OUTPUT_DIR) $(OBJ) core arduboy2
	$(CPP) $(LDFLAGS) -o $(OUTPUT_DIR)/$(TARGET) $(OBJ) $(ARDUINO_CORE_OBJ) $(ARDUBOY2_OBJ)
	@echo '=============================================='
	@echo '    $(TARGET) has been built successfully.'
	@echo '               Congratulations!'
	@echo '=============================================='

# Create the hex file:
hex: compile
	$(OBJCPY) -O ihex -R .eeprom $(OUTPUT_DIR)/$(TARGET) $(OUTPUT_DIR)/$(TARGET).hex

# Run the final hex file in the emulator:
run: hex
	$(ARDENS) file=$(OUTPUT_DIR)/$(TARGET).hex

upload:
	@echo 'Not implemented yet'

# Clean up the project:
clean:
	rm -rf $(OUTPUT_DIR)