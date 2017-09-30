#include "color.h"

#include <math.h>

// This section is modified by the addition of white so that it assumes
// fully saturated colors, and then scales with white to lower saturation.
//
// Next, scale appropriately the pure color by mixing with the white channel.
// Saturation is defined as "the ratio of colorfulness to brightness" so we will
// do this by a simple ratio wherein the color values are scaled down by (1-S)
// while the white LED is placed at S.

// This will maintain constant brightness because in HSI, R+B+G = I. Thus,
// S*(R+B+G) = S*I. If we add to this (1-S)*I, where I is the total intensity,
// the sum intensity stays constant while the ratio of colorfulness to brightness
// goes down by S linearly relative to total Intensity, which is constant.
#define DEG_TO_RAD(X) (M_PI*(X)/180)

void hsi2rgbw(HSITuple *inColor, RGBWQuad *rgbw) {
	float H = inColor->h;
	float S = inColor->s;
	float I = inColor->i;

	int r, g, b, w;
	float cos_h, cos_1047_h;

	// early abort if I is 0
	if(I == 0.f) {
		r = g = b = w = 0;
		goto end;
	}

	// Cycle H to [0, 360] and convert to rad
	H = fmod(H,360);
	H = 3.14159*H/(float)180;

	// Clamp S and I to [0, 1]
	S = S>0?(S<1?S:1):0;
	I = I>0?(I<1?I:1):0;

	if(H < 2.09439) {
		cos_h = cos(H);
		cos_1047_h = cos(1.047196667-H);
		r = S*255*I/3*(1+cos_h/cos_1047_h);
		g = S*255*I/3*(1+(1-cos_h/cos_1047_h));
		b = 0;
		w = 255*(1-S)*I;
	} else if(H < 4.188787) {
		H = H - 2.09439;
		cos_h = cos(H);
		cos_1047_h = cos(1.047196667-H);
		g = S*255*I/3*(1+cos_h/cos_1047_h);
		b = S*255*I/3*(1+(1-cos_h/cos_1047_h));
		r = 0;
		w = 255*(1-S)*I;
	} else {
		H = H - 4.188787;
		cos_h = cos(H);
		cos_1047_h = cos(1.047196667-H);
		b = S*255*I/3*(1+cos_h/cos_1047_h);
		r = S*255*I/3*(1+(1-cos_h/cos_1047_h));
		g = 0;
		w = 255*(1-S)*I;
	}

end: ;
	rgbw->r = r;
	rgbw->g = g;
	rgbw->b = b;
	rgbw->w = w;
}
