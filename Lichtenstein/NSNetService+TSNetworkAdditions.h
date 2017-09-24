//
//  NSNetService+TSNetworkAdditions.h
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-18.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNetService (TSNetworkAdditions)

- (BOOL) TSGetInputStream:(out NSInputStream **)inputStreamPtr outputStream:(out NSOutputStream **)outputStreamPtr;

@end
