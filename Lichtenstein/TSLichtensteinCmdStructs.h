//
//  TSLichtensteinCmdStructs.h
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-18.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#ifndef TSLichtensteinCmdStructs_h
#define TSLichtensteinCmdStructs_h

#include <stdint.h>

typedef enum {
	kCmdNoOp		= 0,
	
	kCmdSetEffect	= 1,
	kCmdSetBright	= 3,
	kCmdSetBlanking	= 5,
	kCmdSetMode		= 7,
	kCmdSetColor	= 9,
	
	kCmdGetState	= 15
} lichtenstein_cmd_index_t;

// struct describing a command
typedef struct __attribute__((__packed__)) {
	uint8_t cmd;
	
	// these are simple parameters used by most commands
	uint8_t param[16];
	
	// any additional (or more complex) parameters are stored here
	uint16_t extraLen;
	char extra[];
} lichtenstein_cmd_t;

#endif /* TSLichtensteinCmdStructs_h */
