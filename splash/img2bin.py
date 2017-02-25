#!/usr/bin/python
import sys
import math
import Image

image = Image.open( "splash.png" );
image = image.convert( "RGB" );

for y in range( 0, 200 ):
	for x in range( 0, 320 ):
		r, g, b = image.getpixel( ( x, y ) );
		r = int( math.floor( r / 128 ) );
		g = int( math.floor( g / 128 ) );
		b = int( math.floor( b / 128 ) );
		sys.stdout.write( unichr( b | ( g << 1 ) | ( r << 2 ) ) );
