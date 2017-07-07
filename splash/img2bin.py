#!/usr/bin/python
import sys
import math
import os
import Image

image = Image.open( "splash.png" );
image = image.convert( "RGB" );
binstdout = os.fdopen( sys.stdout.fileno( ), "wb" )

for y in range( 0, 200 ):
	for x in range( 0, 320 ):
		r, g, b = image.getpixel( ( x, y ) );
		r = int( math.floor( r / 32 ) );
		g = int( math.floor( g / 32 ) );
		b = int( math.floor( b / 64 ) );
		binstdout.write( chr( ( b << 6 ) | ( g << 3 ) | r ) );
