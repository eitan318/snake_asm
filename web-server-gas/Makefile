# GNU as / ld Makefile for the x86_64 Linux HTTP server.

AS     = as
LD     = ld
TARGET = server
OBJ    = server.o
SRC    = server.s

all: $(TARGET)

$(TARGET): $(OBJ)
	$(LD) -o $(TARGET) $(OBJ)

$(OBJ): $(SRC)
	$(AS) -o $(OBJ) $(SRC)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(OBJ) $(TARGET)

.PHONY: all run clean
