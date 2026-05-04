# MASM x64 Makefile for winapi_snake
#
# Requires `ml64` and `link` on PATH. Run from a "x64 Native Tools
# Command Prompt for VS" (or any shell where vcvarsall.bat x64 has
# been invoked). Compatible with both nmake and GNU make.

ASM      = ml64
LINK     = link
TARGET   = winapi_snake.exe
OBJ      = winapi_snake.obj
SRC      = winapi_snake.asm

ASMFLAGS = /nologo /c
LDFLAGS  = /nologo /subsystem:console /entry:main kernel32.lib user32.lib

all: $(TARGET)

$(TARGET): $(OBJ)
	$(LINK) $(LDFLAGS) $(OBJ)

$(OBJ): $(SRC)
	$(ASM) $(ASMFLAGS) $(SRC)

run: $(TARGET)
	$(TARGET)

clean:
	-del /Q $(OBJ) $(TARGET)
