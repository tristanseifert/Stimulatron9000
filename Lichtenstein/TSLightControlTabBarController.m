//
//  TSLightControlTabBarController.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-23.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSLightControlTabBarController.h"

#import "TSLichtensteinConnection.h"

@interface TSLightControlTabBarController ()

@end

@implementation TSLightControlTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/**
 * This will switch Lichtenstein modes.
 */
- (void) tabBarController:(UITabBarController *) tabBarController
  didSelectViewController:(UIViewController *) viewController {
	UITabBarItem *item = viewController.tabBarItem;
	
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
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
