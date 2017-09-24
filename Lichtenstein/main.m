//
//  main.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-17.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSAppDelegate.h"

int main(int argc, char * argv[]) {
	@autoreleasepool {
		[DDLog addLogger:[DDOSLogger sharedInstance]];
		[DDLog addLogger:[DDTTYLogger sharedInstance]];
		
		DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
		fileLogger.rollingFrequency = (60 * 60 * 24) * 7;
		[DDLog addLogger:fileLogger];
		
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([TSAppDelegate class]));
	}
}
