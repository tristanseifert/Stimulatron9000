//
//  ViewController.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-17.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSMainViewController.h"

#import "TSLichtensteinConnection.h"

@interface TSMainViewController ()

- (void) lichtensteinDisconnected:(NSNotification *) n;

@end

@implementation TSMainViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[TSLichtensteinConnection sharedInstance] connectToLast];
	
	// subscribe to notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lichtensteinDisconnected:) name:TSLichtensteinDisconnectedNotificationName object:nil];
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
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
}

@end
