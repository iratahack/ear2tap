.PHONY: clean dis

ASM = z88dk-z80asm
DIS = z88dk-dis
TARGET = ear2tap
ASM_SRC = $(TARGET).asm
ORG = 8192

$(TARGET): $(ASM_SRC)
	$(ASM) -m -b $< -o$@

dis: $(TARGET)
	$(DIS) -x $(TARGET).map -o $(ORG) $(TARGET) | less

clean:
	rm -f $(TARGET) *.o *.map
