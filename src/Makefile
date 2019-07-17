CC=gcc
CFLAGS=-O2 -Wall -g -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_GNU_SOURCE
LDFLAGS=
PROGS=ksudo

all: $(PROGS)

ksudo: ksudo.o
	$(CC) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f *.o *.d $(PROGS)
