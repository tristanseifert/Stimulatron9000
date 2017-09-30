//
//  ViewController.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-17.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSMainViewController.h"

#import "TSLichtensteinConnection.h"
#import "TSLichtensteinBrowserController.h"

static void *TSKVOCtx = &TSKVOCtx;

@interface TSMainViewController ()

- (void) lichtensteinDisconnected:(NSNotification *) n;

@property (nonatomic) TSLichtensteinBrowserController *browser;
@property (nonatomic) UINavigationController *browserHolder;

@end

@implementation TSMainViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	// bring up the browsing controller
	self.browser = [TSLichtensteinBrowserController new];
	
	self.browserHolder = [[UINavigationController alloc] initWithRootViewController:self.browser];
	self.browserHolder.modalPresentationStyle = UIModalPresentationFormSheet;
	
	// subscribe to notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lichtensteinDisconnected:) name:TSLichtensteinDisconnectedNotificationName object:nil];
	
	// bring up the device picker UI
	[self presentViewController:self.browserHolder animated:YES completion:nil];
}

#pragma mark Notifications
/**
 * Called when the Lichtenstein is disconnected.
 */
- (void) lichtensteinDisconnected:(NSNotification *) n {
	UIAlertController *c = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Disconnected", nil) message:NSLocalizedString(@"You were disconnected from the device. Check your network connection and try again.", nil) preferredStyle:UIAlertControllerStyleAlert];
	[c addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
	
	[self presentViewController:c animated:YES completion:nil];
	
	// bring up the device picker UI
	[self presentViewController:self.browser animated:YES completion:nil];
}

@end
