//
//  NSNetService+TSNetworkAdditions.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-18.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "NSNetService+TSNetworkAdditions.h"

@implementation NSNetService (TSNetworkAdditions)

- (BOOL) TSGetInputStream:(out NSInputStream **)inputStreamPtr outputStream:(out NSOutputStream **)outputStreamPtr {
	BOOL                result;
	CFReadStreamRef     readStream;
	CFWriteStreamRef    writeStream;
	
	result = NO;
	
	readStream = NULL;
	writeStream = NULL;
	
	if ( (inputStreamPtr != NULL) || (outputStreamPtr != NULL) ) {
		CFNetServiceRef     netService;
		
		netService = CFNetServiceCreate(
										NULL,
										(__bridge CFStringRef) [self domain],
										(__bridge CFStringRef) [self type],
										(__bridge CFStringRef) [self name],
										0
										);
		if (netService != NULL) {
			CFStreamCreatePairWithSocketToNetService(
													 NULL,
													 netService,
													 ((inputStreamPtr  != NULL) ? &readStream : NULL),
													 ((outputStreamPtr != NULL) ? &writeStream : NULL)
													 );
			CFRelease(netService);
		}
		
		// We have failed if the client requested an input stream and didn't
		// get one, or requested an output stream and didn't get one. We also
		// fail if the client requested neither the input nor the output
		// stream, but we don't get here in that case.
		
		result = ! ((( inputStreamPtr != NULL) && ( readStream == NULL)) ||
					((outputStreamPtr != NULL) && (writeStream == NULL)));
	}
	if (inputStreamPtr != NULL) {
		*inputStreamPtr  = CFBridgingRelease(readStream);
	}
	if (outputStreamPtr != NULL) {
		*outputStreamPtr = CFBridgingRelease(writeStream);
	}
	
	return result;
}

@end
