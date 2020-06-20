prog = drones
oFiles = ass3.o scheduler.o drone.o printer.o target.o

all: exec

exec: $(oFiles)
	gcc -m32 -Wall -g $(oFiles) -o $(prog)
	rm -f $(oFiles)

ass3.o: ass3.s
	nasm -f elf ass3.s -o ass3.o

scheduler.o: scheduler.s
	nasm -f elf scheduler.s -o scheduler.o

drones.o: drones.s
	nasm -f elf drone.s -o drone.o

printer.o: printer.s
	nasm -f elf printer.s -o printer.o

target.o: target.s
	nasm -f elf target.s -o target.o

.PHONY: clean

clean:
	rm -f *.o  $(prog)