CC = gcc
CFLAGS = -Wall

all: clean lvlconv

lvlconv: lvlconv.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	-rm lvlconv
