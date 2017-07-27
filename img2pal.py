#!/usr/bin/python
import sys
import math
import os
from PIL import Image

if len( sys.argv ) < 2:
	sys.stderr.write( "aborting - no input file!\n" );
	exit( 1 );

colors = []
image = Image.open( sys.argv[1] );
image = image.convert( "RGB" );
binstdout = os.fdopen( sys.stdout.fileno( ), "wb" )
width, height = image.size

for y in range( 0, height ):
	for x in range( 0, width ):
		r, g, b = image.getpixel( ( x, y ) );
		r >>= 2;
		g >>= 2;
		b >>= 2;
		colors.append( r | g << 8 | b << 16 );

rs = 1
gs = 1.0
bs = 1	
colors = list( set( colors ) );
colors.sort( key=lambda c: ( ( c >> 0 ) & 0xff ) * rs + ( ( c >> 8 ) & 0xff ) * gs + ( ( c >> 16 ) & 0xff ) * bs );

if len( colors ) > 254:
	sys.stderr.write( "warning - too many colors\n" );
	for i in range( len( colors ) - 254 ):
		lowdiff = 0xffffff;
		red = 0;
		for j in range( 0, len( colors ) - 1 ):
			diff = 0;
			diff += abs( ( ( colors[j] >> 0 ) & 0xff ) - ( ( colors[j + 1] >> 0 ) & 0xff ) ) * rs
			diff += abs( ( ( colors[j] >> 8 ) & 0xff ) - ( ( colors[j + 1] >> 8 ) & 0xff ) ) * gs
			diff += abs( ( ( colors[j] >> 16 ) & 0xff ) - ( ( colors[j + 1] >> 16 ) & 0xff ) ) * bs
			if ( diff  < lowdiff ):
				lowdiff = diff;
				red = j + 1;
		colors.pop( red ); 

for i in range( len( colors ), 256 ):
	colors.append( 0 );

colors.insert( 0, 0x000000 );
colors.insert( 255, 0x3f3f3f );

for i in range( 256 ):
	binstdout.write( chr( ( colors[i] >> 0 ) & 0xff  ) );
	binstdout.write( chr( ( colors[i] >> 8 ) & 0xff  ) ); 
	binstdout.write( chr( ( colors[i] >> 16 ) & 0xff ) ); 
