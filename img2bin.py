#!/usr/bin/python
#Script usage: ./img2bin.py <image file> > <binary file>

import sys
import math
import os
from PIL import Image

if len( sys.argv ) < 2:
	sys.stderr.write( "aborting - no input file!\n" );
	exit( 1 );

image = Image.open( sys.argv[1] );
image = image.convert( "RGB" );
binstdout = os.fdopen( sys.stdout.fileno( ), "wb" )
width, height = image.size

#Just output the binary data in 8bpp (bbgggrrr)
for y in range( 0, height ):
	for x in range( 0, width ):
		r, g, b = image.getpixel( ( x, y ) );
		r = int( math.floor( r / 32 ) );
		g = int( math.floor( g / 32 ) );
		b = int( math.floor( b / 64 ) );
		binstdout.write( chr( ( b << 6 ) | ( g << 3 ) | r ) );
