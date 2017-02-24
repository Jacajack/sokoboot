#!/usr/bin/python
import sys
import Image

image = Image.open( "splash.png" );
image = image.convert( "RGB" );

for y in range( 0, 200 ):
	for x in range( 0, 320 ):
		r, g, b = image.getpixel( ( x, y ) );
		bright = ( r + g + b ) / 255;
		if ( bright == 0 ):
			sys.stdout.write( b"\x10" );
		else:
			sys.stdout.write( b"\x31" );
