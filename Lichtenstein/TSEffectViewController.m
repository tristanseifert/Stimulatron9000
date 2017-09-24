//
//  TSEffectViewController.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-20.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSEffectViewController.h"

#import "TSLichtensteinConnection.h"

static void *KVOCtx = &KVOCtx;

@interface TSEffectViewController ()

@property (nonatomic) NSArray *effectNames;

@property (nonatomic) IBOutlet UIPickerView *effectPicker;
@property (nonatomic) IBOutlet UISlider *brightSlider;

@end

@implementation TSEffectViewController

/**
 * Set up the view lmdo
 */
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// load effect list
	NSBundle *main = [NSBundle mainBundle];
	NSURL *url = [main URLForResource:@"TSEffectNames" withExtension:@"plist"];
	
	self.effectNames = [NSArray arrayWithContentsOfURL:url];
	DDAssert(self.effectNames != nil, @"Couldn't load effect names from %@", url);
	
	// add KVO on the controller
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	[c addObserver:self forKeyPath:@"effect" options:0 context:KVOCtx];
	[c addObserver:self forKeyPath:@"brightness" options:0 context:KVOCtx];
	[c addObserver:self forKeyPath:@"isMuted" options:0 context:KVOCtx];
}

#pragma mark KVO
/**
 * We usually recveive a KVO notification when the remote changes/conencts and
 * the effect controller notifies us of a change.
 */
- (void) observeValueForKeyPath:(NSString *) keyPath ofObject:(id) object change:(NSDictionary<NSKeyValueChangeKey,id> *) change context:(void *) context {
	if(context != KVOCtx) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	} else {
		TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
		
		[self.effectPicker selectRow:c.effect inComponent:0 animated:YES];
		[self.brightSlider setValue:c.brightness animated:YES];
	}
}

#pragma mark Picker View
// returns the number of 'columns' to display.
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *) pickerView {
	return 1;
}

// returns the # of rows in each component..
- (NSInteger) pickerView:(UIPickerView *) pickerView numberOfRowsInComponent:(NSInteger) component {
	return self.effectNames.count;
}

// return name of effect
- (nullable NSString *) pickerView:(UIPickerView *) pickerView titleForRow:(NSInteger) row forComponent:(NSInteger) component {
	return self.effectNames[row];
}

#pragma mark Updates
/**
 * Update the brightness of the remote.
 */
- (IBAction) brightSliderChanged:(id) sender {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	c.brightness = (NSUInteger) self.brightSlider.value;
}

/**
 * Picker view has updated, so change the effect.
 */
- (void) pickerView:(UIPickerView *) pickerView didSelectRow:(NSInteger) row inComponent:(NSInteger) component {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	c.effect = row;
}

@end
