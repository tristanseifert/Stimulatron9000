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

@property (nonatomic) IBOutlet UISlider *sliderH;
@property (nonatomic) IBOutlet UISlider *sliderS;
@property (nonatomic) IBOutlet UISlider *sliderI;

@property (nonatomic) IBOutlet UISlider *sliderBright;

@property (nonatomic) IBOutlet UIView *previewColor;

- (void) updatePreview;

@end

@implementation TSColorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self updatePreview];
	
	// update all the color values
	[self hsiUpdateHue:self.sliderH];
	[self hsiUpdateIntensity:self.sliderI];
	[self hsiUpdateSaturation:self.sliderS];
}

- (void) viewWillAppear:(BOOL)animated {
	self.sliderBright.value = [TSLichtensteinConnection sharedInstance].brightness;
}

/**
 * When called updates the HSI
 */
- (IBAction) hsiUpdateHue:(id)sender {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	c.singleColorH = self.sliderH.value;
	
	[self updatePreview];
}

- (IBAction) hsiUpdateSaturation:(id)sender {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	c.singleColorS = self.sliderS.value;
	
	[self updatePreview];
}

- (IBAction) hsiUpdateIntensity:(id)sender {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	c.singleColorI = self.sliderI.value;
	
	[self updatePreview];
}

/**
 * Update preview color
 */
- (void) updatePreview {
	CGFloat hueRad = self.sliderH.value * (M_PI / 180.f) / (M_PI * 2);
	
	self.previewColor.backgroundColor = [UIColor colorWithHue:hueRad saturation:self.sliderS.value brightness:self.sliderI.value alpha:1.f];
}

- (IBAction) updateBrightness:(id)sender {
	TSLichtensteinConnection *c = [TSLichtensteinConnection sharedInstance];
	
	c.brightness = (NSUInteger) self.sliderBright.value;
}

@end
