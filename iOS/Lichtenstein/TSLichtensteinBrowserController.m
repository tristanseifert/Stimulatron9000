//
//  TSLichtensteinBrowserController.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-29.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSLichtensteinBrowserController.h"

#import "TSLichtensteinConnection.h"

#import <SVProgressHUD/SVProgressHUD.h>

@interface TSLichtensteinBrowserController ()

- (void) setUpBrowser;

- (void) connectedToLichtensteinNotification:(NSNotification *) n;

@property (nonatomic) NSNetServiceBrowser *browser;
@property (nonatomic) NSMutableArray<NSNetService *> *services;

@property (nonatomic) IBOutlet UIActivityIndicatorView *browsingActivityIndicator;

@end

@implementation TSLichtensteinBrowserController

/**
 * Initialize the browser.
 */
- (instancetype) init {
	if(self = [super initWithNibName:@"TSLichtensteinBrowserController" bundle:nil]) {
		
	}
	
	return self;
}

/**
 * Perform some last minute setup.
 */
- (void) viewDidLoad {
    [super viewDidLoad];
	
	// register cell
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TSLichtensteinBrowserCell"];
	
	// set up the net service browser
	[self setUpBrowser];
	
	// set up navigation item
	self.title = NSLocalizedString(@"Select Controller", @"lichtenstein connection title");
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.browsingActivityIndicator];
	
	// add notification handler
	NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
	[c addObserver:self selector:@selector(connectedToLichtensteinNotification:)
			  name:TSLichtensteinConnectedNotificationName object:nil];
}

/**
 * When the view is about to appear, start the mDNS (Bonjour) browsing process
 * to discover devices.
 */
- (void) viewWillAppear:(BOOL) animated {
	[super viewWillAppear:animated];
	
	// begin search for services
	[self.browser searchForServicesOfType:@"_lichtenstein._tcp" inDomain:@""];
	DDLogVerbose(@"Begin searching: %@", self.browser);
}

/**
 * Once the view has disappeared, stop the mDNS browser.
 */
- (void) viewDidDisappear:(BOOL) animated {
	[super viewDidDisappear:animated];
	
	// halt the service search
	[self.browser stop];
	DDLogVerbose(@"Stopping search for services: %@", self.browser);
}

#pragma mark Browsing
/**
 * Set up mDNS browser to find the "_lichtenstein._tcp" service.
 */
- (void) setUpBrowser {
	// set up thing to store everything
	self.services = [NSMutableArray new];
	
	// set up browser
	self.browser = [[NSNetServiceBrowser alloc] init];
	
	self.browser.delegate = self;
}

// Sent when browsing begins
- (void) netServiceBrowserWillSearch:(NSNetServiceBrowser *) browser {
	DDLogInfo(@"Begin browsing");
	
	// show browsing indicator
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.browsingActivityIndicator startAnimating];
	});
}

// Sent when browsing stops
- (void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser *) browser {
	DDLogInfo(@"Browsing ended");
	
	// show browsing indicator
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.browsingActivityIndicator stopAnimating];
	});
}

// Sent if browsing fails
- (void)netServiceBrowser:(NSNetServiceBrowser *) browser
			 didNotSearch:(NSDictionary *) errorDict {
	DDLogError(@"Error browsing: %@", errorDict);
}

// Sent when a service appears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		   didFindService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing {
	DDLogVerbose(@"Got service %@ on %@ port %ld", aNetService, aNetService.addresses, (long) aNetService.port);
	DDLogVerbose(@"TXT record: %@, %@", aNetService.TXTRecordData,
				 [NSNetService dictionaryFromTXTRecordData:aNetService.TXTRecordData]);
	
	aNetService.delegate = self;
	
	[self.services addObject:aNetService];
	[aNetService resolveWithTimeout:0.0];
	
	// reload table
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.tableView reloadData];
	});
	
	// if there's not more coming, connect
	if(!moreComing) {
		DDLogVerbose(@"No more services");
	}
}

// Sent when a service disappears
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
		 didRemoveService:(NSNetService *)aNetService
			   moreComing:(BOOL)moreComing {
	DDLogVerbose(@"Removed service %@ on %@ port %ld", aNetService, aNetService.addresses, (long) aNetService.port);
	
	[self.services removeObject:aNetService];
}

#pragma mark Net Service Delegate
/**
 * Once we resolve a service's name, do stuff with it.
 */
- (void) netServiceDidResolveAddress:(NSNetService *) sender {
	DDLogVerbose(@"Resolved net service %@: %@", sender, sender.hostName);
	
	// reload just that row
	NSInteger index = [self.services indexOfObject:sender];
	DDLogDebug(@"Index of %@: %lu", sender, (unsigned long) index);
	
	if(index != NSNotFound) {
		[self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
							  withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

/**
 * Couldn't resolve this service's name. :(
 */
- (void) netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *,NSNumber *> *)errorDict {
	DDLogError(@"Didn't resolve service %@: %@", sender, errorDict);
}

#pragma mark - Table view data source
/**
 * There is just a single section.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 1;
}

/**
 * Returns the number of services available to connect to.
 */
- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	return self.services.count;
}

/*
 * Returns the cell.
 */
- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TSLichtensteinBrowserCell"
															forIndexPath:indexPath];
	
	// get the appropriate service
	NSNetService *svc = self.services[indexPath.row];
	
	if(svc.hostName.length > 0) {
		cell.textLabel.text = svc.hostName;
		
		cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
		cell.textLabel.textColor = [UIColor darkTextColor];
	} else {
		cell.textLabel.text = NSLocalizedString(@"Resolving…", nil);
		
		cell.textLabel.font = [UIFont italicSystemFontOfSize:[UIFont systemFontSize]];
		cell.textLabel.textColor = [UIColor grayColor];
	}
	
    return cell;
}

/**
 * When a cell is tapped, attempt to connect to it.
 */
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	// show the HUD
	dispatch_async(dispatch_get_main_queue(), ^{
		[SVProgressHUD showWithStatus:NSLocalizedString(@"Connecting…", nil)];
	});
	
	// and connect
	NSNetService *svc = self.services[indexPath.row];
	[[TSLichtensteinConnection sharedInstance] connectToService:svc];
}

#pragma mark Notifications
/**
 * When connected to a Lichtenstein, show a little message and hide.
 */
- (void) connectedToLichtensteinNotification:(NSNotification *) n {
	dispatch_async(dispatch_get_main_queue(), ^{
//		if([SVProgressHUD isVisible]) {
			[SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Connected!", nil)];
//		}
		
		[self dismissViewControllerAnimated:YES completion:nil];
	});
}

@end
