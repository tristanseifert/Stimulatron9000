//
//  TSLichtensteinConnection.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-18.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSLichtensteinConnection.h"
#import "TSLichtensteinCmdStructs.h"

#import "NSNetService+TSNetworkAdditions.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

static void *KVOCtx = &KVOCtx;

NSString *TSLichtensteinDisconnectedNotificationName = @"TSLichtensteinDisconnectedNotification";
NSString *TSLichtensteinConnectedNotificationName = @"TSLichtensteinDConnectedNotification";

@interface TSLichtensteinConnection ()

- (void) gatherConnectedState;

- (void) handleLichtensteinResponse:(NSData *) data;
- (void) _receivedState:(lichtenstein_cmd_t *) cmd;
- (void) _updateRemoteWithLocalState;

- (void) _configureOutputStreamOnOpen:(NSOutputStream *) stream;

@property (nonatomic) NSNetService *connectedService;
@property (nonatomic) NSInputStream *connectedInStr;
@property (nonatomic) NSOutputStream *connectedOutStr;

@end

@implementation TSLichtensteinConnection

/**
 * Initializer
 */
- (id) init {
	if(self = [super init]) {
		// add KVO
		[self addObserver:self forKeyPath:@"effect" options:0 context:KVOCtx];
		[self addObserver:self forKeyPath:@"brightness" options:0 context:KVOCtx];
		[self addObserver:self forKeyPath:@"isMuted" options:0 context:KVOCtx];
		[self addObserver:self forKeyPath:@"isSingleColorMode" options:0 context:KVOCtx];
		
		[self addObserver:self forKeyPath:@"singleColorH" options:0 context:KVOCtx];
		[self addObserver:self forKeyPath:@"singleColorS" options:0 context:KVOCtx];
		[self addObserver:self forKeyPath:@"singleColorI" options:0 context:KVOCtx];
	}
	
	return self;
}

/**
 * Returns the shared instance.
 */
+ (instancetype) sharedInstance {
	static TSLichtensteinConnection *sharedInstance;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [TSLichtensteinConnection new];
	});
	
	return sharedInstance;
}

#pragma mark Service Connection
/**
 * Actually connects to the service once we find it.
 */
- (void) connectToService:(NSNetService *) svc {
	DDLogInfo(@"Connecting to service %@ on %@", svc, svc.hostName);
	
	
	// attempt to create the IO streams
	NSInputStream *inStr = nil;
	NSOutputStream *outStr = nil;
	
	BOOL success = [svc TSGetInputStream:&inStr outputStream:&outStr];
	
	if(!success) {
		DDLogError(@"Couldn't connect streams for service!");
	} else {
		self.connectedService = svc;
		
		self.connectedInStr = inStr;
		self.connectedOutStr = outStr;
		
		// set delegate and schedule loops
		self.connectedInStr.delegate = self;
		self.connectedOutStr.delegate = self;
		
		[self.connectedInStr scheduleInRunLoop:[NSRunLoop currentRunLoop]
									   forMode:NSRunLoopCommonModes];
		[self.connectedOutStr scheduleInRunLoop:[NSRunLoop currentRunLoop]
										forMode:NSRunLoopCommonModes];
		
		// open streams
		[self.connectedInStr open];
		[self.connectedOutStr open];
		
		DDLogVerbose(@"Connected streams: %@ %@", inStr, outStr);
		
		[self gatherConnectedState];
	}
}

#pragma mark Remote Commands
/**
 * Query the device at the other end to see what its current status is.
 */
- (void) gatherConnectedState {
	NSInteger written = 0;
	
	// Create and send a "get request" packet
	lichtenstein_cmd_t cmd;
	memset(&cmd, 0, sizeof(lichtenstein_cmd_t));
	
	cmd.cmd = kCmdGetState;
	
	written = [self.connectedOutStr write:(uint8_t *) &cmd maxLength:sizeof(lichtenstein_cmd_t)];
	
	if(written <= 0) {
		DDLogWarn(@"Couldn't write 'get state' packet: %@ (wrote %li bytes)", self.connectedOutStr.streamError, (long) written);
	}
}

/**
 * Handles the given data being received from the device.
 */
- (void) handleLichtensteinResponse:(NSData *) data {
//	DDLogDebug(@"Got data: %@", data);
	lichtenstein_cmd_t *resp = (lichtenstein_cmd_t *) data.bytes;
	
	switch (resp->cmd) {
		case kCmdGetState:
			[self _receivedState:resp];
			break;
			
		default:
			break;
	}
}

/**
 * Handles a received "get state" packet.
 */
- (void) _receivedState:(lichtenstein_cmd_t *) cmd {
	DDLogVerbose(@"Effect %02x, bright %02x, muted %02x, mode %02x", cmd->param[0],
				 cmd->param[1], cmd->param[2], cmd->param[3]);
	
	// set properties
	[self willChangeValueForKey:@"effect"];
	[self willChangeValueForKey:@"brightness"];
	[self willChangeValueForKey:@"isMuted"];
	[self willChangeValueForKey:@"isSingleColorMode"];
	
	_effect = cmd->param[0];
	_brightness = cmd->param[1];
	_isMuted = (cmd->param[2] == 1) ? YES : NO;
	_isSingleColorMode = (cmd->param[3] == 1) ? YES : NO;
	
	[self didChangeValueForKey:@"effect"];
	[self didChangeValueForKey:@"brightness"];
	[self didChangeValueForKey:@"isMuted"];
	[self didChangeValueForKey:@"isSingleColorMode"];
	
	// hide HUD
	self.isConnected = YES;
}

/**
 * Updates the state by sending effect, brightness, and mute commands.
 */
- (void) _updateRemoteWithLocalState {
	NSInteger written = 0;
	
	lichtenstein_cmd_t cmd;
	memset(&cmd, 0, sizeof(lichtenstein_cmd_t));
	
	DDLogDebug(@"Updating remote state: effect %02x, bright %02x, muted %02x",
				 (unsigned int) self.effect, (unsigned int) self.brightness,
				 (unsigned int) self.isMuted);
	
	// Create and send a "set effect"
	cmd.cmd = kCmdSetEffect;
	cmd.param[0] = self.effect & 0xFF;
	
	written = [self.connectedOutStr write:(uint8_t *) &cmd maxLength:sizeof(lichtenstein_cmd_t)];
	
	if(written <= 0) {
		DDLogWarn(@"Couldn't write 'set effect' packet: %@ (wrote %li bytes)", self.connectedOutStr.streamError, (long) written);
	}
	
	
	// Create and send a "set brightness"
	cmd.cmd = kCmdSetBright;
	cmd.param[0] = self.brightness & 0xFF;
	
	written = [self.connectedOutStr write:(uint8_t *) &cmd maxLength:sizeof(lichtenstein_cmd_t)];
	
	if(written <= 0) {
		DDLogWarn(@"Couldn't write 'set brightness' packet: %@ (wrote %li bytes)", self.connectedOutStr.streamError, (long) written);
	}
	
	
	// Create and send a "set mute"
	cmd.cmd = kCmdSetBlanking;
	cmd.param[0] = (self.isMuted) == YES ? 1 : 0;
	
	written = [self.connectedOutStr write:(uint8_t *) &cmd maxLength:sizeof(lichtenstein_cmd_t)];
	
	if(written <= 0) {
		DDLogWarn(@"Couldn't write 'set mute' packet: %@ (wrote %li bytes)", self.connectedOutStr.streamError, (long) written);
	}
	
	// Create and send a "set mode"
	cmd.cmd = kCmdSetMode;
	cmd.param[0] = (self.isSingleColorMode) == YES ? 1 : 0;
	
	written = [self.connectedOutStr write:(uint8_t *) &cmd maxLength:sizeof(lichtenstein_cmd_t)];
	
	if(written <= 0) {
		DDLogWarn(@"Couldn't write 'set mode' packet: %@ (wrote %li bytes)", self.connectedOutStr.streamError, (long) written);
	}
	
	// Create and send "set color"
	cmd.cmd = kCmdSetColor;
	memcpy(&cmd.param[0], &_singleColorH, sizeof(typeof(self.singleColorH)));
	memcpy(&cmd.param[4], &_singleColorS, sizeof(typeof(self.singleColorS)));
	memcpy(&cmd.param[8], &_singleColorI, sizeof(typeof(self.singleColorI)));
	
	written = [self.connectedOutStr write:(uint8_t *) &cmd maxLength:sizeof(lichtenstein_cmd_t)];
	
	if(written <= 0) {
		DDLogWarn(@"Couldn't write 'set mode' packet: %@ (wrote %li bytes)", self.connectedOutStr.streamError, (long) written);
	}
}

#pragma mark KVO
/**
 * Handle KVO for the effect, brightness, isMuted properties.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary<NSKeyValueChangeKey,id> *) change context:(void *) context {
	// pass on any KVO notifications
	if(context != KVOCtx) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}
	
	// update remote state
	if(self.isConnected) {
		[self _updateRemoteWithLocalState];
	}
}

#pragma mark Stream Delegate
/**
 * Handle stream events
 */
- (void) stream:(NSStream *) aStream handleEvent:(NSStreamEvent) eventCode {
	DDLogDebug(@"Event %lu on stream %@", eventCode, aStream);
	
	// we've received shit from the remote end
	if(aStream == self.connectedInStr) {
		switch(eventCode) {
			case NSStreamEventHasBytesAvailable: {
				// read into a buffer
				lichtenstein_cmd_t *cmd = malloc(512);
				memset(cmd, 0, sizeof(lichtenstein_cmd_t));
				
				NSInteger read = [self.connectedInStr read:(uint8_t *) cmd
												 maxLength:512];
				
				if(read > 0) {
					DDLogDebug(@"Read %li bytes", (long) read);
					
					NSData *data = [NSData dataWithBytes:cmd length:read];
					[self handleLichtensteinResponse:data];
					
					// clean up the buffer again
					free(cmd);
				} else {
					DDLogWarn(@"Couldn't read buffer: %@", self.connectedInStr.streamError);
				}
				
				break;
			}
				
			// we don't care about other events
			default:
				break;
		}
	} else if(aStream == self.connectedOutStr) {
		switch(eventCode) {
			case NSStreamEventOpenCompleted: {
				[self _configureOutputStreamOnOpen:(NSOutputStream *) aStream];
				
				// post notification
				NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
				[c postNotificationName:TSLichtensteinConnectedNotificationName
								 object:self.connectedService];
				break;
			}
				
			default:
				break;
		}
	}
	
	// handle disconnection
	if(eventCode == NSStreamEventEndEncountered) {
		DDLogWarn(@"Disconnected: %@", aStream.streamError);
		
		self.isConnected = NO;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TSLichtensteinDisconnectedNotificationName object:nil];
	}
	
	// handle any errors
	if(eventCode == NSStreamEventErrorOccurred) {
		DDLogError(@"Socket error: %@", aStream.streamError);
		self.isConnected = NO;
	}
}

/**
 * Sets some socket options on the output stream.
 */
- (void) _configureOutputStreamOnOpen:(NSOutputStream *) stream {
	NSData *data = (NSData *) [stream propertyForKey:(__bridge NSString *)kCFStreamPropertySocketNativeHandle];
	DDAssert(data != nil, @"Couldn't get native socket handle for stream %@", stream);
	
	CFSocketNativeHandle fd = *(CFSocketNativeHandle *) [data bytes];
	DDLogVerbose(@"Configuring output stream %@", stream);
	
	//SO_KEEPALIVE option to activate
	int option = 1;
	//TCP_NODELAY option to activate
	int option2 = 1;
	//Idle time used when SO_KEEPALIVE is enabled. Sets how long connection must be idle before keepalive is sent
	int keepaliveIdle = 10;
	//Interval between keepalives when there is no reply. Not same as idle time
	int keepaliveIntvl = 2;
	//Number of keepalives before close (including first keepalive packet)
	int keepaliveCount = 4;
	//Time after which tcp packet retransmissions will be stopped and the connection will be dropped.Stream is closed
	int retransmissionTimeout = 5;

	if (setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &option, sizeof (int)) == -1) {
		DDLogWarn(@"setsockopt SO_KEEPALIVE failed: %s", strerror(errno));
	}
	
	if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPCNT, &keepaliveCount, sizeof(int)) == -1) {
		DDLogWarn(@"setsockopt TCP_KEEPCNT failed: %s", strerror(errno));
	}
	
	if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPALIVE, &keepaliveIdle, sizeof(int)) == -1) {
		DDLogWarn(@"setsockopt TCP_KEEPALIVE failed: %s", strerror(errno));
	}
	
	if (setsockopt(fd, IPPROTO_TCP, TCP_KEEPINTVL, &keepaliveIntvl, sizeof(int)) == -1) {
		DDLogWarn(@"setsockopt TCP_KEEPINTVL failed: %s", strerror(errno));
	}
	
	if (setsockopt(fd, IPPROTO_TCP, TCP_RXT_CONNDROPTIME, &retransmissionTimeout, sizeof(int)) == -1) {
		DDLogWarn(@"setsockopt TCP_RXT_CONNDROPTIME failed: %s", strerror(errno));
	}
	
	if (setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &option2, sizeof(int)) == -1) {
		DDLogWarn(@"setsockopt TCP_NODELAY failed: %s", strerror(errno));
	}
}

@end
