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

#define GETLVL_OK 0
#define GETLVL_EOF 1
#define GETLVL_ERROR 2

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
		uint16_t boxcnt;
		uint16_t maxtime;
		uint16_t maxstep;
		char author[80];
	} __attribute__( ( __packed__ ) );

	uint8_t raw[LVL_INF_SIZE];
} lvl;


//The map data - max size allowed by sokoboot
#define MAP_WIDTH 256
#define MAP_HEIGHT 256
uint8_t map[MAP_WIDTH][MAP_HEIGHT] = {0};

//Main status/configuration structure
struct
{
	unsigned int forceCamPos : 1;
	unsigned int : 0;

	char *lvlstr;
	size_t lvllen;

	const char *exename;
	const char *infilename, *outfilename;
	FILE *infile, *outfile;
} status;


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
int mapLoad( )
{
	int c;
	int i = 0;
	uint16_t x = 0, y = 0;
	uint16_t maxx = 0;
	uint8_t *t;
	int ign = 0;

	//Read by character
	while ( ( c = status.lvlstr[i++] ) != 0 )
	{

		//Ignore lines starting with '~'
		if ( ign && (char) c == '\n' )
		{
			ign = 0;
			continue;
		}
		if ( x == 0 && (char) c == '~' )
			ign = 1;
		if ( ign ) continue;


		//If current x is greater than map width, abort
		if ( x >= MAP_WIDTH || y >= MAP_HEIGHT )
			return MAPLOAD_ESIZE;

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
			case '_':
			case '-':
				*t = TILE_AIR;
				break;

			case 'p':
			case '@':
				*t = TILE_PLAYER;
				break;

			case 'w':
			case '#':
				*t = TILE_WALL;
				break;

			case '.':
				*t = TILE_SOCKET;
				break;

			case 'b':
			case '&':
			case '$':
				*t = TILE_BOX;
				break;

			case '+':
			case 'P':
				*t = TILE_SOCKETPLAYER;
				break;

			case 'B':
			case '*':
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
int infLoad( )
{
	char *buf = NULL;
	char lineok = 0;
	char allok = 1;
	char *str = strdup( status.lvlstr );
	if ( str == NULL ) return INFLOAD_ERROR;

	for ( buf = strtok( str, "\n" ); buf != NULL; buf = strtok( NULL, "\n" ) )
	{
		if ( buf[0] != '~' ) continue; //Skip 'commented out' lines
		lineok = 0;
		lineok += sscanf( buf, "~name: \"%79[^\"\n\r]\"", lvl.name );
		lineok += sscanf( buf, "~desc: \"%319[^\"\n\r]\"", lvl.desc );
		lineok += sscanf( buf, "~author: \"%79[^\"\n\r]\"", lvl.author );
		lineok += sscanf( buf, "~next: %" SCNu16, &lvl.next );
		lineok += sscanf( buf, "~last: %" SCNu8, &lvl.last );
		lineok += sscanf( buf, "~nextjmp: %" SCNu16, &lvl.nextjmp );
		lineok += sscanf( buf, "~id: %" SCNu16, &lvl.id );
		lineok += sscanf( buf, "~maxtime: %" SCNu16, &lvl.maxtime );
		lineok += sscanf( buf, "~maxstep: %" SCNu16, &lvl.maxstep );
		
		if ( sscanf( buf, "~campos: %" SCNu16 ", %" SCNu16, &lvl.camx, &lvl.camy )  == 2 )
		{
			status.forceCamPos = 1;
			lineok += 1;
		}

		allok = allok && lineok == 1;
	}

	free( str );
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

int getlvl( FILE *f )
{
	long start, end;
	int c;
	int cnt = 0;
	int delim = 0;
	
	if ( f == NULL ) return GETLVL_ERROR;
	start = ftell( f );
	
	status.lvllen = 0;
	if ( status.lvlstr != NULL ) free( status.lvlstr );
	
	while ( ( c = fgetc( f ) ) != EOF )
	{
		if ( (char) c == '~' ) cnt++;
		else cnt = 0;
		if ( cnt == 3 )
		{
			delim = 1;
			break;
		}
	}

	end = ftell( f );		
	status.lvlstr = malloc( end - start + 1 );
	if ( status.lvlstr == NULL ) return GETLVL_ERROR;
	status.lvllen = end - start;
	status.lvlstr[end - start] = 0;

	fseek( f, start, SEEK_SET );
	cnt = 0;
	while ( ( c = fgetc( f ) ) != EOF && ftell( f ) < end )
		status.lvlstr[cnt++] = c;

	return delim ? GETLVL_OK : GETLVL_EOF;
}

int main( int argc, char **argv )
{
	int ec, i, j, bytecnt;
	
	status.infile = NULL;
	status.outfile = stdout;

	if ( argc == 0 )
	{
		fprintf( stderr, "What the hell are you doing?\n" );
		exit( 1 );
	}

	status.exename = argv[0];

	if ( argc == 1 )
	{
		fprintf( stderr, 	"%s: please specify input file name!\n" \
							"\tUsage: %s infile [outfile]\n", status.exename, status.exename );
		exit( 1 );
	}

	status.infilename = argv[1];
	status.infile = fopen( status.infilename, "r" );

	if ( argc == 3 )
	{
		status.outfilename = argv[2];
		status.outfile = fopen( status.outfilename, "w" );
	}

	if ( status.infile == NULL )
	{
		fprintf( stderr, "%s: cannot open input file!\n", status.exename );
		exit( 1 );
	}

	if ( status.outfile == NULL )
	{
		fprintf( stderr, "%s: cannot open output file!\n", status.exename );
		exit( 1 );
	}


	//Make sure that the level structure is empty
	memset( &lvl, 0, sizeof lvl );

	getlvl( status.infile );

	//Load metadata
	ec = infLoad( );
	if ( ec != INFLOAD_OK )
	{
		switch ( ec )
		{
			case INFLOAD_ERROR:
				fprintf( stderr, "%s: warning [%s] - some level metadata skipped!\n", status.exename, status.infilename );
				break;
		}
	}
	
	//Load map
	ec = mapLoad( );
	if ( ec != MAPLOAD_OK )
	{
		switch ( ec )
		{
			case MAPLOAD_ESIZE:
				fprintf( stderr, "%s: level too big!\n", status.exename );
				break;

			case MAPLOAD_EFMT:
				fprintf( stderr, "%s: bad file format!\n", status.exename );
				break;

			case MAPLOAD_EPLAYER:
				fprintf( stderr, "%s: bad player count!\n", status.exename );
				break;

			case MAPLOAD_EBOXES:
				fprintf( stderr, "%s: level already solved!\n", status.exename );
				break;
		}
		exit( 1 );
	}
	
	//Find player
	findPlayer( );

	//Locate the camera
	if ( !status.forceCamPos )
	{
		lvl.camx = LIMIT( 0, LIMIT( 0, MAP_WIDTH - VIEWPORT_WIDTH, lvl.width - VIEWPORT_WIDTH ) , lvl.playerx - VIEWPORT_WIDTH / 2 );
		lvl.camy = LIMIT( 0, LIMIT( 0, MAP_HEIGHT - VIEWPORT_HEIGHT, lvl.height - VIEWPORT_HEIGHT ),lvl.playery - VIEWPORT_HEIGHT / 2 );
	}

	//Coutn boxes
	lvl.boxcnt = mapCount( TILE_BOX ) + mapCount( TILE_SOCKETBOX );

	//Set some crucial stuff in level header
	memcpy( lvl.magic, "soko lvl", 8 );

	//Output raw level data
	bytecnt = 0;
	for ( i = 0; i < sizeof lvl; i++ ) fputc( lvl.raw[i], status.outfile );
	for ( i = 0; i < lvl.height; i++ )	
	{
		for ( j = 0; j < lvl.width; j++ )
		{
			fputc( map[j][i], status.outfile );
			bytecnt++;
		}
	}

	//Pad out to full sectors
	bytecnt = ( lvl.width * lvl.height / 512 + 1 ) * 512 - bytecnt;
	while ( bytecnt-- ) fputc( 0, status.outfile );

	fclose( status.infile );
	fclose( status.outfile );
	return 0;

	
}

