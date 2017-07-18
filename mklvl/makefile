CC = gcc
CFLAGS = -Wall

all: clean mklvl

mklvl: mklvl.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	-rm mklvl
