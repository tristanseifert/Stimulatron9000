//
//  TSLichtensteinConnection.h
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-18.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *TSLichtensteinDisconnectedNotificationName;
extern const NSString *TSLichtensteinConnectedNotificationName;

@interface TSLichtensteinConnection : NSObject <NSStreamDelegate>

+ (instancetype) sharedInstance;

- (void) connectToService:(NSNetService *) svc;

@property (nonatomic) BOOL isConnected;

@property (nonatomic) NSUInteger effect;
@property (nonatomic) NSUInteger brightness;
@property (nonatomic) BOOL isMuted;
@property (nonatomic) BOOL isSingleColorMode;

@property (nonatomic) float singleColorH;
@property (nonatomic) float singleColorS;
@property (nonatomic) float singleColorI;

@end
