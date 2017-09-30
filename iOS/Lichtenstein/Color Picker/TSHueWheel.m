//
//  TSHueWheel.h
//  Lichtenstein
//
//  Created by Tristan Seifert on 2017-09-24.
//  Copyright © 2017 Tristan Seifert. All rights reserved.
//

#import "TSHueWheel.h"

static void *KVOCtx = &KVOCtx;

typedef struct {
	unsigned char r;
	unsigned char g;
	unsigned char b;
} TSHueWheelPixelRGB;

/**
 * Calculate the distance between two points.
 */
static CGFloat TSHueWheel_PointDistance(CGPoint p1, CGPoint p2) {
	return sqrtf((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}

/**
 * A fast (but a little rough) conversion between HSB to RGB.
 */
static TSHueWheelPixelRGB TSHueWheel_HSBToRGB(CGFloat h, CGFloat s, CGFloat v) {
	h *= 6.0f;
	
	NSInteger i = (NSInteger)floorf(h);
	CGFloat f = h - (CGFloat)i;
	CGFloat p = v *  (1.0f - s);
	CGFloat q = v * (1.0f - s * f);
	CGFloat t = v * (1.0f - s * (1.0f - f));
	
	CGFloat r;
	CGFloat g;
	CGFloat b;
	
	switch (i) {
		case 0:
			r = v;
			g = t;
			b = p;
			break;
		case 1:
			r = q;
			g = v;
			b = p;
			break;
		case 2:
			r = p;
			g = v;
			b = t;
			break;
		case 3:
			r = p;
			g = q;
			b = v;
			break;
		case 4:
			r = t;
			g = p;
			b = v;
			break;
		default:        // case 5:
			r = v;
			g = p;
			b = q;
			break;
	}
	
	TSHueWheelPixelRGB pixel;
	pixel.r = r * 255.0f;
	pixel.g = g * 255.0f;
	pixel.b = b * 255.0f;
	
	return pixel;
}

@interface TSHueWheelKnobView : UIView

@property(nonatomic, strong) UIColor *fillColor;

@end

/**
 * The color knob is used to indicate the user's selected color
 */
@implementation TSHueWheelKnobView

- (id) initWithFrame:(CGRect) frame {
	if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor clearColor];
		self.fillColor = [UIColor clearColor];
		
	}
	return self;
}

/**
 * Draw a solid circle filled with the selected color, and then a stroke around
 * the circle.
 */
- (void) drawRect:(CGRect) rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	CGFloat borderWidth = 2.0f;
	CGRect borderFrame = CGRectInset(self.bounds, borderWidth / 2.0, borderWidth / 2.0);
	
	CGContextSetFillColorWithColor(ctx, _fillColor.CGColor);
	CGContextAddEllipseInRect(ctx, borderFrame);
	CGContextFillPath(ctx);
	
	
	CGContextSetLineWidth(ctx, borderWidth);
	CGContextSetStrokeColorWithColor(ctx, [UIColor blackColor].CGColor);
	CGContextAddEllipseInRect(ctx, borderFrame);
	CGContextStrokePath(ctx);
}

@end


@interface TSHueWheel ()

/// this contains the actual colors on top of which everything else is drawn
@property (nonatomic) CGImageRef radialImage;
/// pixel data for the above image
@property (nonatomic) TSHueWheelPixelRGB *imageData;
/// length of the image data, in bytes
@property (nonatomic) size_t imageDataLength;

/// radius of the circle
@property (nonatomic) CGFloat radius;

/// which point the touch is at
@property (nonatomic) CGPoint touchPoint;

/// knob to indicate selected color
@property (nonatomic) TSHueWheelKnobView *knobView;


- (TSHueWheelPixelRGB) colorAtPoint:(CGPoint)point;

- (CGPoint) viewToImageSpace:(CGPoint)point;
- (void) updateKnob;

- (void) _sharedInit;

@end



@implementation TSHueWheel

#pragma mark Initializers
- (id) initWithFrame:(CGRect) frame {
	if((self = [super initWithFrame:frame])) {
		[self _sharedInit];
		
		// set defaults for border color and such
		self.borderColor = [UIColor blackColor];
		self.borderWidth = 3.0;
		
		self.knobSize = CGSizeMake(28, 28);
	}
	
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	if(self = [super initWithCoder:aDecoder]) {
		[self _sharedInit];
	}
	
	return self;
}

/**
 * Contains shared initialization code; this sets up some defaults for variables
 * and will prepare the view for drawing.
 */
- (void) _sharedInit {
	// add some observers
	[self addObserver:self forKeyPath:@"brightness" options:0 context:KVOCtx];
	[self addObserver:self forKeyPath:@"knobView" options:0 context:KVOCtx];
	[self addObserver:self forKeyPath:@"touchPoint" options:0 context:KVOCtx];
	
	// set defaults
	self.radialImage = nil;
	self.imageData = nil;
	self.imageDataLength = 0;
	
	self.brightness = 1.0;
	
	self.touchPoint = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
	
	self.knobView = [[TSHueWheelKnobView alloc] init];
	
	self.backgroundColor = [UIColor clearColor];
	
	self.continuous = YES;
}

- (void) dealloc {
	if(self.radialImage) {
		CGImageRelease(self.radialImage);
		self.radialImage = nil;
	}
	
	if (_imageData) {
		free(_imageData);
	}
	
	self.knobView = nil;
}

/**
 * Returns the RGB color at the given point.
 */
- (TSHueWheelPixelRGB) colorAtPoint:(CGPoint) point {
	CGPoint center = CGPointMake(self.radius, self.radius);
	
	CGFloat angle = atan2(point.x - center.x, point.y - center.y) + M_PI;
	CGFloat dist = TSHueWheel_PointDistance(point, CGPointMake(center.x, center.y));
	
	CGFloat hue = angle / (M_PI * 2.0f);
	
	hue = MIN(hue, 1.0f - .0000001f);
	hue = MAX(hue, 0.0f);
	
	CGFloat sat = dist / (self.radius);
	
	sat = MIN(sat, 1.0f);
	sat = MAX(sat, 0.0f);
	
	return TSHueWheel_HSBToRGB(hue, sat, _brightness);
}

- (CGPoint) viewToImageSpace:(CGPoint) point {
	CGFloat width = self.bounds.size.width;
	CGFloat height = self.bounds.size.height;
	
	point.y = height - point.y;
	
	CGPoint min = CGPointMake(width / 2.0 - self.radius, height / 2.0 - self.radius);
	
	point.x = point.x - min.x;
	point.y = point.y - min.y;
	
	return point;
}

/**
 * Updates the color of the selection knob.
 */
- (void) updateKnob {
	if(!self.knobView) {
		return;
	}
	
	self.knobView.bounds = CGRectMake(0, 0, _knobSize.width, _knobSize.height);
	self.knobView.center = self.touchPoint;
	
	self.knobView.fillColor = self.currentColor;
}

/**
 * Updates the image that actually holds the hues and colors.
 */
- (void)updateImage {
	if (self.bounds.size.width == 0 || self.bounds.size.height == 0) {
		return;
	}
	
	if(self.radialImage) {
		CGImageRelease(self.radialImage);
		self.radialImage = nil;
	}
	
	int width = self.radius * 2.0;
	int height = width;
	
	int dataLength = sizeof(TSHueWheelPixelRGB) * width * height;
	
	if(dataLength != _imageDataLength) {
		if (_imageData) {
			free(_imageData);
		}
		
		_imageData = malloc(dataLength);
		_imageDataLength = dataLength;
	}
	
	for(int y = 0; y < height; ++y) {
		for(int x = 0; x < width; ++x) {
			_imageData[x + y * width] = [self colorAtPoint:CGPointMake(x, y)];
		}
	}
	
	// generate a CGImage from the raw pixel data
	CGBitmapInfo bitInfo = kCGBitmapByteOrderDefault;
	
	CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, _imageData, dataLength, NULL);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	self.radialImage = CGImageCreate(width,
								 height,
								 8,
								 24,
								 width * 3,
								 colorspace,
								 bitInfo,
								 ref,
								 NULL,
								 true,
								 kCGRenderingIntentDefault);
	
	CGColorSpaceRelease(colorspace);
	CGDataProviderRelease(ref);
	
	[self setNeedsDisplay];
}

/**
 * Returns the current UIColor.
 */
- (UIColor *) currentColor {
	TSHueWheelPixelRGB pixel = [self colorAtPoint:[self viewToImageSpace:self.touchPoint]];
	return [UIColor colorWithRed:pixel.r / 255.0f green:pixel.g / 255.0f blue:pixel.b / 255.0f alpha:1.0];
}

/**
 * Decomposes the passed color into HSB components.
 */
- (void) setCurrentColor:(UIColor *) color {
	CGFloat h = 0.0;
	CGFloat s = 0.0;
	CGFloat b = 1.0;
	CGFloat a = 1.0;
	
	[color getHue:&h saturation:&s brightness:&b alpha:&a];
	
	self.brightness = b;
	
	CGPoint center = CGPointMake(self.radius, self.radius);
	
	CGFloat angle = (h * (M_PI * 2.0)) + M_PI / 2;
	CGFloat dist = s * self.radius;
	
	CGPoint point;
	point.x = center.x + (cosf(angle) * dist);
	point.y = center.y + (sinf(angle) * dist);
	
	self.touchPoint = point;
	[self updateImage];
}

/**
 * Actually draw the view. This will draw the circular radial image, and a then
 * a border around it.
 */
- (void) drawRect:(CGRect) rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSaveGState (ctx);
	
	NSInteger width = self.bounds.size.width;
	NSInteger height = self.bounds.size.height;
	CGPoint center = CGPointMake(width / 2.0, height / 2.0);
	
	CGRect wheelFrame = CGRectMake(center.x - self.radius, center.y - self.radius, self.radius * 2.0, self.radius * 2.0);
	CGRect borderFrame = CGRectInset(wheelFrame, -self.borderWidth / 2.0, -self.borderWidth / 2.0);
	
	// draw a border around the hue image
	if(self.borderWidth > 0.0f) {
		CGContextSetLineWidth(ctx, self.borderWidth);
		CGContextSetStrokeColorWithColor(ctx, [_borderColor CGColor]);
		CGContextAddEllipseInRect(ctx, borderFrame);
		CGContextStrokePath(ctx);
	}
	
	// draw the image containing the colors
	CGContextAddEllipseInRect(ctx, wheelFrame);
	CGContextClip(ctx);
	
	if (self.radialImage) {
		CGContextDrawImage(ctx, wheelFrame, self.radialImage);
	}
	
	CGContextRestoreGState (ctx);
}

/**
 * When the view's size changes, update some variables.
 */
- (void) layoutSubviews {
	[super layoutSubviews];
	self.radius = (MIN(self.bounds.size.width, self.bounds.size.height) / 2.0) - MAX(0.0f, self.borderWidth);
	
	// force KVO
	self.touchPoint = self.touchPoint;
	
	[self updateImage];
}

#pragma mark KVO Stuff
/**
 * Handle KVO events. This updates brightness, the knob view, and the touch points.
 */
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
	if(context != KVOCtx) {
		return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	} else {
		// update brightness
		if([keyPath isEqualToString:@"brightness"]) {
			[self updateImage];
			
			if([self.knobView respondsToSelector:@selector(setFillColor:)]) {
				[self.knobView performSelector:@selector(setFillColor:) withObject:self.currentColor afterDelay:0.0f];
				[self.knobView setNeedsDisplay];
			}
			
			[self.delegate colorWheelDidChangeColor:self];
		}
		// update knob view
		else if([keyPath isEqualToString:@"knobView"]) {
			if(self.knobView) {
				[self addSubview:self.knobView];
			}
			
			[self updateKnob];
		}
		// update touch point
		else if([keyPath isEqualToString:@"touchPoint"]) {
			CGPoint point = self.touchPoint;
			
			CGFloat width = self.bounds.size.width;
			CGFloat height = self.bounds.size.height;
			
			CGPoint center = CGPointMake(width / 2.0, height / 2.0);
			
//			DDLogVerbose(@"KVO touch point: %@", NSStringFromCGPoint(point));
//			DDLogVerbose(@"Size %g x %g; center %@", width, height, NSStringFromCGPoint(center));
			
			// Check if the touch is outside the wheel
			if(TSHueWheel_PointDistance(center, point) > self.radius) {
				// If so we need to create a drection vector and calculate the constrained point
				CGPoint vec = CGPointMake(point.x - center.x, point.y - center.y);
				
				CGFloat extents = sqrtf((vec.x * vec.x) + (vec.y * vec.y));
//				DDLogVerbose(@"%@ extent %g", NSStringFromCGPoint(vec), extents);
				
				vec.x /= extents;
				vec.y /= extents;
				
				if(extents > 0) {
					_touchPoint = CGPointMake(center.x + vec.x * self.radius, center.y + vec.y * self.radius);
				}
			}
			
//			DDLogVerbose(@"Touch point: %@", NSStringFromCGPoint(self.touchPoint));
			[self updateKnob];
		}
	}
}

#pragma mark User Interaction
/**
 * Handle the start of a touch event.
 */
- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
	[self willChangeValueForKey:@"currentColor"];
	
	self.touchPoint = [[touches anyObject] locationInView:self];
	
	if([self.knobView respondsToSelector:@selector(setFillColor:)]) {
		[self.knobView performSelector:@selector(setFillColor:)
							withObject:self.currentColor
							afterDelay:0.0f];
		[self.knobView setNeedsDisplay];
	}
	
	[self didChangeValueForKey:@"currentColor"];
	
	[self.delegate colorWheelDidChangeColor:self];
}

/**
 * When touches are moved, update the touch point.
 */
- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
	[self willChangeValueForKey:@"currentColor"];
	
	self.touchPoint = [[touches anyObject] locationInView:self];
	
	if([self.knobView respondsToSelector:@selector(setFillColor:)]) {
		[self.knobView performSelector:@selector(setFillColor:)
							withObject:self.currentColor
							afterDelay:0.0f];
		[self.knobView setNeedsDisplay];
	}
	
	[self didChangeValueForKey:@"currentColor"];
	
	if(_continuous) {
		[self.delegate colorWheelDidChangeColor:self];
	}
}

/**
 * Finally, update the delegate at the very end of the interaction.
 */
- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
	[self.delegate colorWheelDidChangeColor:self];
}

@end
