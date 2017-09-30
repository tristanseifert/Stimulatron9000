//
//  TSHueWheel.h
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-24.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TSHueWheel;
@protocol TSHueWheelDelegate <NSObject>
@required

- (void) colorWheelDidChangeColor:(TSHueWheel *) colorWheel;
@end


IB_DESIGNABLE
@interface TSHueWheel : UIControl

@property(nonatomic, weak) IBOutlet id <TSHueWheelDelegate> delegate;

@property(nonatomic, assign) IBInspectable CGSize knobSize;

@property(nonatomic, assign) IBInspectable CGFloat brightness;
@property(nonatomic, assign) IBInspectable BOOL continuous;

@property(nonatomic, strong) IBInspectable UIColor* borderColor;
@property(nonatomic, assign) IBInspectable CGFloat borderWidth;

@property(nonatomic, strong) UIColor *currentColor;

- (void) updateImage;

@end
