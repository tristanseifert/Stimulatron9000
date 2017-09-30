#ifndef COLOR_H
#define COLOR_H

#include <stdint.h>

/**
 * Type representing an HSI tuple
 */
typedef struct {
	float h, s, i;
} HSITuple;

/**
 * Type representing an RGBW quad
 */
typedef struct {
	int r, g, b, w;
} RGBWQuad;

/**
 * Converts the given color (in the HSI - a modified HSV - color space) to
 * an RGBW quad in the output array.
 */
void hsi2rgbw(HSITuple *inColor, RGBWQuad *rgbw);

/**
 * Converts the given HSI tuple to a 32-bit hex value in the form of 0xWWRRGGBB.
 */
static uint32_t HSIToWRGB(HSITuple *inColor) {
	RGBWQuad quad;

	hsi2rgbw(inColor, &quad);

	// printf("HSI (%f, %f, %f) -> WRGB (%u, %u, %u, %u)\n", inColor->h, inColor->s, inColor->i, quad.w, quad.r, quad.g, quad.b);

	return ((quad.w & 0xFF) << 24) | ((quad.g & 0xFF) << 8)
		 | ((quad.r & 0xFF) << 16) | ((quad.b & 0xFF) << 0);
}

#endif
