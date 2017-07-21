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
#define MAPLOAD_EALLOC	6

//Metadata load errors
#define INFLOAD_OK 		0
#define INFLOAD_EWARN 	1
#define INFLOAD_EALLOC 	2

//In-game viewport size
#define VIEWPORT_WIDTH 	20
#define VIEWPORT_HEIGHT 12

//Header size
#define LVL_INF_SIZE 1024
#define MAP_WIDTH 256
#define MAP_HEIGHT 256
//The level header struct - has to be compatible with the one in sokoboot.asm
struct lvl
{
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
			uint8_t camlock;
			uint8_t camfree;
			uint16_t camxb;
			uint16_t camyb;
			uint16_t offsetx;
			uint16_t offsety;
		} __attribute__( ( __packed__ ) );

		uint8_t raw[LVL_INF_SIZE];
	};

	uint8_t map[MAP_WIDTH][MAP_HEIGHT];
};

//Main status/configuration structure
struct
{
	unsigned int forceCamx : 1;
	unsigned int forceCamy : 1;
	unsigned int forceOffsetx : 1;
	unsigned int forceOffsety : 1;
	unsigned int forceNext : 1;
	unsigned int forceId : 1;
	unsigned int : 0;

	const char *exename;
	const char *infilename, *outfilename;
	FILE *infile, *outfile;

	struct lvl *levels;
	size_t levelCount;
	char *data;
} status;


//Count given tiles on map
int mapcnt( struct lvl* level, uint8_t id )
{
	int i, j, cnt = 0;

	//Count boxes
	for ( i = 0; i < MAP_WIDTH; i++ )
		for ( j = 0; j < MAP_HEIGHT; j++ )
			cnt += level->map[i][j] == id;
	return cnt;
}

//Load map data from file
int mapload( struct lvl *level, const char *lvlstr )
{
	char c;
	int i = 0;
	uint16_t x = 0, y = 0;
	uint16_t maxx = 0;
	uint8_t *t;
	int ign = 0;

	//Read by character
	while ( ( c = lvlstr[i++] ) != 0 )
	{
		//Clear ignore flag on newline
		if ( ign && c == '\n' )
		{
			ign = 0;
			continue;
		}

		//Set ignore flag on ~
		if ( x == 0 && c == '~' )
			ign = 1;

		//If ignore flag is set, ignore line
		if ( ign ) continue;


		//If current x is greater than map width, abort
		if ( x >= MAP_WIDTH || y >= MAP_HEIGHT )
			return MAPLOAD_ESIZE;

		if ( x > maxx ) maxx = x;

		//Get map pointer
		t = &level->map[x++][y];

		//Write various tiles into map, depending on character
		switch ( c )
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

	if ( mapcnt( level, TILE_PLAYER ) + mapcnt( level, TILE_SOCKETPLAYER ) != 1 ) return MAPLOAD_EPLAYER;
	if ( mapcnt( level, TILE_BOX ) == 0 ) return MAPLOAD_EBOXES;

	//Store detected level dimensions
	level->width = maxx + 1;
	level->height = y + 1;

	return MAPLOAD_OK;
}


//Add offset to map position
void mapoffset( struct lvl *level )
{
	int i, j;

	if ( (int) level->width + level->offsetx > 65535 ) return;
	if ( (int) level->height + level->offsety > 65535 ) return;
	if ( level->offsetx == 0 && level->offsety == 0 ) return;

	for ( i = MAP_WIDTH - 1; i >= level->offsetx; i-- )
		for ( j = MAP_WIDTH - 1; j >= level->offsety; j-- )
		{
			level->map[i][j] = level->map[i - level->offsetx][j - level->offsety];
			level->map[i - level->offsetx][j - level->offsety] = TILE_AIR;
		}

	level->width += level->offsetx;
	level->height += level->offsety;
}

//Loads metadata form file
int infload( struct lvl *level, const char *lvlstr )
{
	char *buf = NULL;
	char tagok = 0;
	char allok = 1;
	char *str;
	char *toksave;
	 
	//Duplicate level string for strotok
	if ( ( str = strdup( lvlstr ) ) == NULL ) return INFLOAD_EALLOC;

	//Tokenize using NL
	for ( buf = strtok_r( str, "\n", &toksave ); buf != NULL; buf = strtok_r( NULL, "\n", &toksave ) )
	{
		if ( buf[0] != '~' ) continue; //Skip lines that don't begin with ~

		tagok = 0;
		tagok += sscanf( buf, "~name: \"%79[^\"\n\r]\"", level->name );
		tagok += sscanf( buf, "~desc: \"%319[^\"\n\r]\"", level->desc );
		tagok += sscanf( buf, "~author: \"%79[^\"\n\r]\"", level->author );
		tagok += ( status.forceNext |= sscanf( buf, "~next: %" SCNu16, &level->next ) );
		tagok += ( status.forceNext |= sscanf( buf, "~last: %" SCNu8, &level->last ) );
		tagok += ( status.forceNext |= sscanf( buf, "~nextjmp: %" SCNu16, &level->nextjmp ) );
		tagok += ( status.forceId |= sscanf( buf, "~id: %" SCNu16, &level->id ) );
		tagok += sscanf( buf, "~maxtime: %" SCNu16, &level->maxtime );
		tagok += sscanf( buf, "~maxstep: %" SCNu16, &level->maxstep );
		tagok += ( status.forceCamx |= sscanf( buf, "~camx: %" SCNu16, &level->camx ) );
		tagok += ( status.forceCamy |= sscanf( buf, "~camy: %" SCNu16, &level->camy ) );	
		tagok += ( sscanf( buf, "~camlock: %" SCNu8, &level->camlock ) );
		tagok += ( status.forceOffsetx |= sscanf( buf, "~offsetx: %" SCNu16, &level->offsetx ) );
		tagok += ( status.forceOffsety |= sscanf( buf, "~offsety: %" SCNu16, &level->offsety ) );	
		allok = allok && tagok;
	}

	//Free memory allocated by strdup
	free( str );

	if ( !allok ) return INFLOAD_EWARN;
	else return INFLOAD_OK;
}

//Finds first occurence of given tile on map
//On fail, returns 1
int mapfind( struct lvl *level, uint16_t *x, uint16_t *y, uint8_t id )
{
	int i, j;

	for ( i = 0; i < MAP_HEIGHT; i++ )
		for ( j = 0; j < MAP_WIDTH; j++ )
			if ( level->map[j][i] == id )
			{
				*x = j;
				*y = i;
				return 0;
			}
	return 1;
}

int main( int argc, char **argv )
{
	int ec, c, i, j, k, bytecnt;
	long len;
	char *lvlstr;
	char *toksave;
	struct lvl *level;

	status.infile = NULL;
	status.outfile = stdout;

	//We shouldn'y bother with handling this case...
	if ( argc == 0 )
	{
		fprintf( stderr, "What the hell are you doing?\n" );
		exit( 1 );
	}

	status.exename = argv[0];

	//If input filename is missing, display help-like message
	if ( argc == 1 )
	{
		fprintf( stderr, 	"%s: please specify input file name!\n" \
							"\tUsage: %s infile [outfile]\n", status.exename, status.exename );
		exit( 1 );
	}

	//Get input file name
	status.infilename = argv[1];
	status.infile = fopen( status.infilename, "r" );

	//Depending on argument count, open output file or leave it as is
	if ( argc == 3 )
	{
		status.outfilename = argv[2];
		status.outfile = fopen( status.outfilename, "w" );
	}

	//Check if input file can be opened
	if ( status.infile == NULL )
	{
		fprintf( stderr, "%s: cannot open input file!\n", status.exename );
		exit( 1 );
	}
	
	//Check if output file can be opened
	if ( status.outfile == NULL )
	{
		fprintf( stderr, "%s: cannot open output file!\n", status.exename );
		exit( 1 );
	}

	//Load text data
	i = 0;
	fseek( status.infile, 0, SEEK_END );
	len = ftell( status.infile );
	fseek( status.infile, 0, SEEK_SET );
	status.data = malloc( len + 1 );
	while ( ( c = fgetc( status.infile ) ) != EOF && i < len )
		status.data[i++] = c;
	status.data[i] = 0;

	//Count levels
	status.levelCount = 1;
	lvlstr = status.data;
	while ( ( lvlstr = strchr( lvlstr, '`' ) ) != NULL )
	{
		lvlstr++;
		status.levelCount++;
	}
	
	//Allocate memory for levels
	status.levels = calloc( status.levelCount, sizeof( struct lvl ) );

	for ( lvlstr = strtok_r( status.data, "`", &toksave ), i = 0; lvlstr != NULL; lvlstr = strtok_r( NULL, "`", &toksave ), i++ )
	{
		level = &status.levels[i];

		//Load metadata
		ec = infload( level, lvlstr );
		if ( ec != INFLOAD_OK )
		{
			switch ( ec )
			{
				case INFLOAD_EWARN:
					fprintf( stderr, "%s: [%d @ %s] some level metadata skipped!\n", status.exename, i, status.infilename );
					break;

				case INFLOAD_EALLOC:
					fprintf( stderr, "%s: [%d @ %s] memory allocation error!\n", status.exename, i, status.infilename );
					break;
			}
		}
		
		//Load map
		ec = mapload( level, lvlstr );
		if ( ec != MAPLOAD_OK )
		{
			switch ( ec )
			{
				case MAPLOAD_ESIZE:
					fprintf( stderr, "%s: [%d @ %s]  level too big!\n", status.exename, i, status.infilename );
					break;

				case MAPLOAD_EFMT:
					fprintf( stderr, "%s: [%d @ %s] bad file format!\n", status.exename, i, status.infilename );
					break;

				case MAPLOAD_EPLAYER:
					fprintf( stderr, "%s: [%d @ %s] bad player count!\n", status.exename, i, status.infilename );
					break;

				case MAPLOAD_EBOXES:
					fprintf( stderr, "%s: [%d @ %s] level already solved!\n", status.exename, i, status.infilename );
					break;
				
				case MAPLOAD_EALLOC:
					fprintf( stderr, "%s: [%d @ %s] memory allocation error!\n", status.exename, i, status.infilename );
					break;
			}
			continue;
		}
		
		//If offset is not forced and neither is camera position, center the level on screen
		if ( !status.forceCamx && !status.forceOffsetx && level->width < VIEWPORT_WIDTH ) level->offsetx = ( VIEWPORT_WIDTH - level->width ) / 2;
		if ( !status.forceCamy && !status.forceOffsety && level->height < VIEWPORT_HEIGHT ) level->offsety = ( VIEWPORT_HEIGHT - level->height ) / 2;

		fprintf( stderr, "offset %d, %d\n", level->offsetx, level->offsety );

		//Add offset
		mapoffset( level );

		//Find player
		if ( mapfind( level, &level->playerx, &level->playery, TILE_PLAYER ) )
			if ( mapfind( level, &level->playerx, &level->playery, TILE_SOCKETPLAYER ) )
			{
				fprintf( stderr, "%s: [%d @ %s] cannol locate player on the map!\n", status.exename, i, status.infilename );
				continue;
			}
		
		//Locate the camera
		if ( !status.forceCamx ) level->camx = LIMIT( 0, LIMIT( 0, MAP_WIDTH - VIEWPORT_WIDTH, level->width - VIEWPORT_WIDTH ) , level->playerx - VIEWPORT_WIDTH / 2 );
		if ( !status.forceCamy ) level->camy = LIMIT( 0, LIMIT( 0, MAP_HEIGHT - VIEWPORT_HEIGHT, level->height - VIEWPORT_HEIGHT ),level->playery - VIEWPORT_HEIGHT / 2 );
	

		//Count boxes
		level->boxcnt = mapcnt( level, TILE_BOX ) + mapcnt( level, TILE_SOCKETBOX );

		//Set some crucial stuff in level header
		memcpy( level->magic, "soko lvl", 8 );

		//If there's next level, setup jump pointer
		if ( !status.forceNext && i < status.levelCount - 1 )
		{
			fprintf( stderr, "%s: [%d @ %s] auto jump set...\n", status.exename, i, status.infilename );
			level->nextjmp = level->width * level->height / 512 + 1 + 2;
		}

		//Mark as last, if there's no next level
		if ( !status.forceNext && i == status.levelCount - 1 )
		{
			fprintf( stderr, "%s: [%d @ %s] marked as last...\n", status.exename, i, status.infilename );
			level->last = 1;
		}

		//Automatically assign ID
		if ( !status.forceId ) 
		{
			fprintf( stderr, "%s: [%d @ %s] id set...\n", status.exename, i, status.infilename );
			level->id = i;
		}

		//Output raw level data
		bytecnt = 0;
		for ( j = 0; j < 1024; j++ ) fputc( level->raw[j], status.outfile );
		for ( j = 0; j < level->height; j++ )	
		{
			for ( k = 0; k < level->width; k++ )
			{
				fputc( level->map[k][j], status.outfile );
				bytecnt++;
			}
		}

		//Pad out to full sectors
		bytecnt = ( level->width * level->height / 512 + 1 ) * 512 - bytecnt;
		while ( bytecnt-- ) fputc( 0, status.outfile );	
	}

	return 0;
}

