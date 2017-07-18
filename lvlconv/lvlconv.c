#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>

//An utility that limits v value to upper and lowe limit
#define LIMIT( b, u, v ) ( (v) < (b) ? (b) : ( (v) > (u) ? (u) : (v) ) )

//Map tile values
#define TILE_AIR 			0
#define TILE_PLAYER 		5
#define TILE_WALL 			1
#define TILE_BOX 			2
#define TILE_SOCKET 		3
#define TILE_SOCKETBOX 		4
#define TILE_SOCKETPLAYER 	6

//Map loader errors
#define MAPLOAD_OK 		0
#define MAPLOAD_EFILE 	1
#define MAPLOAD_ESIZE 	2
#define MAPLOAD_EFMT 	3
#define MAPLOAD_EPLAYER 4
#define MAPLOAD_EBOXES 	5

//Metadata load errors
#define INFLOAD_OK 		0
#define INFLOAD_ERROR 	1

//In-game viewport size
#define VIEWPORT_WIDTH 	20
#define VIEWPORT_HEIGHT 16

//Header size
#define LVL_INF_SIZE 1024

//The level header struct - has to be compatible with the one in sokoboot.asm
union
{
	struct
	{
		char magic[8];
		uint16_t id;
		char name[80];
		char desc[320];
		uint16_t playerx;
		uint16_t playery;
		uint16_t width;
		uint16_t height;
		uint16_t camx;
		uint16_t camy;
		uint16_t flags[2];
		uint16_t next;
		uint8_t last;
		uint16_t nextjmp; 
	} __attribute__( ( __packed__ ) );

	uint8_t raw[LVL_INF_SIZE];
} lvl;


//The map data - max size allowed by sokoboot
#define MAP_WIDTH 256
#define MAP_HEIGHT 256
uint8_t map[MAP_WIDTH][MAP_HEIGHT] = {0};


//Count given tiles on map
int mapCount( uint8_t id )
{
	int i, j, cnt = 0;

	//Count boxes
	for ( i = 0; i < MAP_WIDTH; i++ )
		for ( j = 0; j < MAP_HEIGHT; j++ )
			cnt += map[i][j] == id;
	return cnt;
}

//Load map data from file
int mapLoad( FILE *f )
{
	int c;
	uint16_t x = 0, y = 0;
	uint16_t maxx = 0;
	uint8_t *t;

	//Seek to the begining
	rewind( f );

	//Read by character
	while ( ( c = getc( f ) ) != EOF )
	{
		//If current x is greater than map width, abort
		if ( x >= MAP_WIDTH || y >= MAP_HEIGHT )
			return MAPLOAD_ESIZE;

		//Ignore lines starting with '~'
		if ( x == 0 && (char) c == '~' )
		{
			while ( c != '\n' && c != EOF )
				c = getc( f );
			c = EOF;
			continue;
		}

		if ( x > maxx ) maxx = x;

		//Get map pointer
		t = &map[x++][y];

		//Write various tiles into map, depending on character
		switch ( (char) c )
		{
			//Ignore CR - for DOS format handling
			case '\r':
				break;

			//Jump to next line on newline character
			case '\n':
				x = 0;
				y++;
				continue;
				break;

			case ' ':
				*t = TILE_AIR;
				break;

			case '@':
				*t = TILE_PLAYER;
				break;

			case 'w':
				*t = TILE_WALL;
				break;

			case '.':
				*t = TILE_SOCKET;
				break;

			case '&':
				*t = TILE_BOX;
				break;

			case 'P':
				*t = TILE_SOCKETPLAYER;
				break;

			case 'B':
				*t = TILE_SOCKETBOX;
				break;

			//Unsupported characters
			default:
				return MAPLOAD_EFMT;
				break;
		}
	}

	if ( mapCount( TILE_PLAYER ) + mapCount( TILE_SOCKETPLAYER ) != 1 ) return MAPLOAD_EPLAYER;
	if ( mapCount( TILE_BOX ) == 0 ) return MAPLOAD_EBOXES;

	//Store detected level dimensions
	lvl.width = maxx + 1;
	lvl.height = y + 1;

	return MAPLOAD_OK;
}

//Loads metadata form file
int infLoad( FILE *f )
{
	char buf[4096];
	char lineok = 0;
	char allok = 1;

	//Rewind the file
	rewind( f );

	while ( fgets( buf, sizeof buf, f ) != NULL )
	{
		if ( buf[0] != '~' ) continue; //Skip 'commented out' lines
		lineok += sscanf( buf, "~name: \"%79[0-9a-zA-Z ]\"", lvl.name );
		lineok += sscanf( buf, "~desc: \"%319[0-9a-zA-Z ]\"", lvl.desc );
		lineok += sscanf( buf, "~next: %" SCNu16, &lvl.next );
		lineok += sscanf( buf, "~last: %" SCNu8, &lvl.last );
		lineok += sscanf( buf, "~nextjmp: %" SCNu16, &lvl.nextjmp );
		lineok += sscanf( buf, "~id: %" SCNu16, &lvl.id );
		allok = allok && lineok == 1;
	}

	if ( !allok ) return INFLOAD_ERROR;
	else return INFLOAD_OK;
}

//Gets player position into level header
void findPlayer( )
{
	int i, j;
	for ( i = 0; i < MAP_HEIGHT; i++ )
		for ( j = 0; j < MAP_WIDTH; j++ )
			if ( map[j][i] == TILE_PLAYER || map[j][i] == TILE_SOCKETPLAYER )
			{
				lvl.playerx = j;
				lvl.playery = i;
				return;
			}
}

int main( int argc, char **argv )
{
	FILE *infile;
	FILE *outfile = stdout; //For future!
	int ec, i, j, bytecnt;
	
	if ( argc == 0 )
	{
		fprintf( stderr, "What the hell are you doing?\n" );
		exit( 1 );
	}

	if ( argc == 1 )
	{
		fprintf( stderr, 	"%s: please specify input file name!\n" \
							"\tUsage: %s infile [outfile]\n", argv[0], argv[0] );
		exit( 1 );
	}

	infile = fopen( argv[1], "r" );
	if ( argv[2] != NULL ) outfile = fopen( argv[2], "w" );

	if ( infile == NULL )
	{
		fprintf( stderr, "%s: cannot open input file!\n", argv[0] );
		exit( 1 );
	}

	if ( outfile == NULL )
	{
		fprintf( stderr, "%s: cannot open output file!\n", argv[0] );
		exit( 1 );
	}


	//Make sure that the level structure is empty
	memset( &lvl, 0, sizeof lvl );

	//Load metadata
	ec = infLoad( infile );
	if ( ec != INFLOAD_OK )
	{
		switch ( ec )
		{
			case INFLOAD_ERROR:
				fprintf( stderr, "%s: warning - some level metadata skipped!\n", argv[0] );
				break;
		}
	}

	//Load map
	ec = mapLoad( infile );
	if ( ec != MAPLOAD_OK )
	{
		switch ( ec )
		{
			case MAPLOAD_ESIZE:
				fprintf( stderr, "%s: level too big!\n", argv[0] );
				break;

			case MAPLOAD_EFMT:
				fprintf( stderr, "%s: bad file format!\n", argv[0] );
				break;

			case MAPLOAD_EPLAYER:
				fprintf( stderr, "%s: bad player count!\n", argv[0] );
				break;

			case MAPLOAD_EBOXES:
				fprintf( stderr, "%s: level already solved!\n", argv[0] );
				break;
		}
		exit( 1 );
	}
	
	//Find player
	findPlayer( );

	//Locate the camera
	lvl.camx = LIMIT( 0, LIMIT( 0, MAP_WIDTH - VIEWPORT_WIDTH, lvl.width - VIEWPORT_WIDTH ) , lvl.playerx - VIEWPORT_WIDTH / 2 );
	lvl.camy = LIMIT( 0, LIMIT( 0, MAP_HEIGHT - VIEWPORT_HEIGHT, lvl.height - VIEWPORT_HEIGHT ),lvl.playery - VIEWPORT_HEIGHT / 2 );
	
	//Set some crucial stuff in level header
	memcpy( lvl.magic, "soko lvl", 8 );

	//Output raw level data
	bytecnt = 0;
	for ( i = 0; i < sizeof lvl; i++ ) fputc( lvl.raw[i], outfile );
	for ( i = 0; i < lvl.height; i++ )	
	{
		for ( j = 0; j < lvl.width; j++ )
		{
			fputc( map[j][i], outfile );
			bytecnt++;
		}
	}

	//Pad out to full sectors
	bytecnt = ( lvl.width * lvl.height / 512 + 1 ) * 512 - bytecnt;
	while ( bytecnt-- ) fputc( 0, outfile );

	fclose( infile );
	fclose( outfile );
	return 0;
}

