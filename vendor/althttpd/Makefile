# Makefile for althttpd and utilities.  Summary of targets:
#
#    make althttpd                 <--  althttpd without OpenSSL
#    make althttpsd                <--  althttpd including OpenSSL for TLS support
#    make static-althttpd          <--  statically linked version of althttpd
#    make static-althttpsd         <--  statically linked version of althttpsd
#    make logtodb                  <--  Program to build SQLite database from log file
#    make static-logtodb           <--  Statically linked version of the same
#
# Pass LDFLAGS to add system-specific libs. e.g. Haiku needs LDFLAGS=-lnetwork.
default: althttpd althttpsd
CC=cc
CFLAGS=-Os -Wall -Wextra -I.


VERSION.h:	VERSION manifest manifest.uuid mkversion.c
	$(CC) -o mkversion mkversion.c
	./mkversion manifest.uuid manifest VERSION >VERSION.h

althttpd:	althttpd.c VERSION.h
	$(CC) $(CFLAGS) -o althttpd althttpd.c $(LDFLAGS)

althttpsd:	althttpd.c VERSION.h
	$(CC) $(CFLAGS) -fPIC -o althttpsd -DENABLE_TLS althttpd.c $(LDFLAGS) -lssl -lcrypto

static-althttpd:	althttpd.c VERSION.h
	$(CC) $(CFLAGS) -static -o static-althttpd althttpd.c $(LDFLAGS)

static-althttpsd:	althttpd.c VERSION.h
	$(CC) $(CFLAGS) -static -fPIC -o static-althttpsd -DENABLE_TLS althttpd.c $(LDFLAGS) -lssl -lcrypto -lpthread -ldl

sqlite3.o:	sqlite3.c
	$(CC) $(CFLAGS) -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_THREADSAFE=0 -c -o sqlite3.o sqlite3.c

static-logtodb:	logtodb.c sqlite3.o VERSION.h
	$(CC) $(CFLAGS) -static -o static-logtodb logtodb.c sqlite3.o

logtodb:	logtodb.c VERSION.h
	$(CC) $(CFLAGS) -o logtodb logtodb.c -lsqlite3 -lm -ldl -lpthread

clean:
	rm -f althttpd althttpsd VERSION.h sqlite3.o static-althttpd \
              static-althttpsd logtodb static-logtodb
