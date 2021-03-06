#!/usr/bin/python
#Script usage: ./img2palbin.py <image file> <pallete file> > <binary file>

import sys
import math
import os
import struct
from PIL import Image

if len( sys.argv ) < 2:
	sys.stderr.write( "aborting - no input file!\n" );
	exit( 1 );

if len( sys.argv ) < 3:
	sys.stderr.write( "aborting - no palette file!\n" );
	exit( 1 );

#Read palette into array
pal = []
rawpal = open( sys.argv[2], "rb" ).read( )
for i in range( 256 ):
	r = ord( rawpal[i*3] )
	g = ord( rawpal[i*3 + 1] )
	b = ord( rawpal[i*3 + 2] )
	pal.append( [r, g, b] );

#The less one of these numbers is, the less important color becomes
rs = 0.8
gs = 1.0
bs = 0.9

#Load image
image = Image.open( sys.argv[1] );
image = image.convert( "RGB" );
binstdout = os.fdopen( sys.stdout.fileno( ), "wb" )
width, height = image.size

#Iterate through pixels
for y in range( 0, height ):
	for x in range( 0, width ):
		r, g, b = image.getpixel( ( x, y ) );
		r >>= 2;
		g >>= 2;
		b >>= 2;
		lowdiff = 0xffff;
		match = 0;
		for i in range( 256 ): #Attempt to find closest color match
			diff = 0;
			diff += abs( pal[i][0] - r ) * rs
			diff += abs( pal[i][1] - g ) * gs
			diff += abs( pal[i][2] - b ) * bs
			if ( diff < lowdiff ):
				lowdiff = diff;
				match = i;
		binstdout.write( chr( match ) ); #Output color ID
