PROGLANG ?= brainfuck
MAKEDEPS  = Makefile
CAT      ?= cat

all: wodscipe.img tools/encode tools/decode

wodscipe.img: mbr.bin $(PROGLANG).bin source-$(PROGLANG).bin
	test -e wodscipe.img || dd if=/dev/zero of=wodscipe.img bs=1024 count=1440
	dd if=mbr.bin of=wodscipe.img conv=notrunc bs=512 count=1
	dd if=$(PROGLANG).bin of=wodscipe.img conv=notrunc bs=512 count=1 seek=1
	dd if=source-$(PROGLANG).bin of=wodscipe.img conv=notrunc bs=512 seek=2

mbr.bin: ide/main.asm ide/io.asm ide/disk.asm ide/editor.asm $(MAKEDEPS)
	cd ide; nasm -fbin -o ../mbr.bin main.asm

$(PROGLANG).bin: langs/$(PROGLANG).asm langs/wodscipe.inc $(MAKEDEPS)
	cd langs; nasm -fbin -o ../$(PROGLANG).bin $(PROGLANG).asm

source-%.bin: example/%.txt tools/encode
	tools/encode < $< > $@

%: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $<

disasm: mbr.bin $(PROGLANG).bin
	$(CAT) mbr.bin $(PROGLANG).bin | ndisasm -b 16 - > disasm.tmp

clean:
	rm -f wodscipe.img *.bin cat *.tmp

.PHONY: all disasm clean

cat: $(MAKEDEPS)
	echo 'void cat(int f){char c;while(read(f,&c,1)>0)write(1,&c,1);}int main(int a,char**b){int f;if(!b[1])cat(0);else while(*++b)if(!strcmp(*b,"-"))cat(0);else if((f=open(*b,0))>0){cat(f);close(f);}return 0;}' | $(CC) -x c -o cat -
