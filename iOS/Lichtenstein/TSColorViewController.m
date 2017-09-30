//
//  TSColorViewController.m
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-20.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSColorViewController.h"

#import "TSLichtensteinConnection.h"

@interface TSColorViewController ()

@property (nonatomic) IBOutlet UISlider *sliderBright;
@property (nonatomic) IBOutlet TSHueWheel *wheel;

- (void) updatePreview;

@end

@implementation TSColorViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self updatePreview];
}

- (void) viewWillAppear:(BOOL)animated {
	self.sliderBright.value = [TSLichtensteinConnection sharedInstance].brightness;
	self.wheel.brightness = self.sliderBright.value / 255.f;
	
	// extract the color
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	self.wheel.currentColor = [UIColor colorWithHue:c.singleColorH / 360.f
										 saturation:c.singleColorS
										 brightness:1.f
											  alpha:1.f];
}

/**
 * When the color wheel is changed, update the preview, and send a command to
 * the remote as well.
 */
- (void) colorWheelDidChangeColor:(TSHueWheel *) colorWheel {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	// Get HSI values
	CGFloat h, s;
	
	[colorWheel.currentColor getHue:&h saturation:&s brightness:nil alpha:nil];
	
	c.singleColorH = h * 360.f;
	c.singleColorS = s;
	c.singleColorI = 1.f;
	
//	DDLogVerbose(@"HSI (%g, %g, %g)", c.singleColorH, c.singleColorS, c.singleColorI);
}

/**
 * Update preview color
 */
- (void) updatePreview {
//	CGFloat hueRad = self.sliderH.value * (M_PI / 180.f) / (M_PI * 2);
//	self.previewColor.backgroundColor = [UIColor colorWithHue:hueRad saturation:self.sliderS.value brightness:self.sliderI.value alpha:1.f];
}

- (IBAction) updateBrightness:(id)sender {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	c.brightness = (NSUInteger) self.sliderBright.value;
	
	// also, update the color wheel
	self.wheel.brightness = self.sliderBright.value / 255.f;
}

@end
