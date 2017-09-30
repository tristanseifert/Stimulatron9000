//
//  TSLightControlTabBarController.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-23.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSLightControlTabBarController.h"

#import "TSLichtensteinConnection.h"

static void *TSKVOCtx = &TSKVOCtx;

@interface TSLightControlTabBarController ()

@property (atomic) BOOL isInKVOHandler;

@end

@implementation TSLightControlTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.delegate = self;
	
	// add some observers
	TSLichtensteinConnection *con = [TSLichtensteinConnection sharedInstance];
	[con addObserver:self forKeyPath:@"isSingleColorMode" options:0 context:TSKVOCtx];
}


/**
 * KVO Handler
 */
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	self.isInKVOHandler = YES;
	
	if(context != TSKVOCtx) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	} else {
		// update the tab controller
		if([keyPath isEqualToString:@"isSingleColorMode"]) {
			if([TSLichtensteinConnection sharedInstance].isSingleColorMode) {
				self.selectedIndex = 1;
			} else {
				self.selectedIndex = 0;
			}
		}
	}
	
	self.isInKVOHandler = NO;
}

/**
 * This will switch Lichtenstein modes.
 */
- (void) tabBarController:(UITabBarController *) tabBarController
  didSelectViewController:(UIViewController *) viewController {
	UITabBarItem *item = viewController.tabBarItem;
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	// return immediately if we're in the KVO handler
	if(self.isInKVOHandler ==  YES) {
		return;
	}
	
	// effect
	if(item.tag == 0) {
		c.isSingleColorMode = NO;
	}
	// solid color
	else if(item.tag == 1) {
		c.isSingleColorMode = YES;
	}
	
	DDLogVerbose(@"New state: %02x", c.isSingleColorMode);
}

@end
