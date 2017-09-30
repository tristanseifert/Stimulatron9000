#include "color.h"

#include <math.h>
#include <string.h>
#include <stdlib.h>

#include "effects.h"

#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))

#define random(a, b) (rand() % (b + 1 - a) + a)

/**
 * This is a fancy schmanzy rainbow that animates across the entire width of
 * the LED strip.
 */
void effect_rainbow_sweep(HSITuple *buffer, int width) {
	float hAddend = 360.f / ((float) width / 1);

	static float hue = 0.f;

	for(int x = 0; x < width; x++) {
		buffer[x].h = hue + (((float) x) * hAddend);
		buffer[x].s = 1.f;
		buffer[x].i = 1.f;
	}

	// on the next invocation, advance the rainbow slightly
	hue += 1;
}


/**
 * A fancy movie theatre-type ticker effect.
 */
void effect_movie_ticker(HSITuple *buffer, int width, float h, float s) {
	static int frame = 0;
	static int timer = 0;

	for(int x = 0; x < width; x++) {
		buffer[x].h = h;
		buffer[x].s = s;

		if((x & 1) && (frame & 1)) {
			buffer[x].i = 1.f;
		} else if((x & 1) == 0 && (frame & 1)) {
			buffer[x].i = 0.f;
		} else if((x & 1) && (frame & 1) == 0) {
			buffer[x].i = 0.f;
		} else if((x & 1) == 0 && (frame & 1) == 0) {
			buffer[x].i = 1.f;
		}
	}

	// do the next frame
	if(timer++ == 3) {
		frame++;

		timer = 0;
	}
}

/**
 * A fancy movie theatre-type ticker effect, in green.
 */
void effect_movie_ticker_green(HSITuple *buffer, int width) {
	effect_movie_ticker(buffer, width, 90, 1.f);
}

/**
 * A sort of "breathing" effect of the white color.
 */
void effect_breathe_white(HSITuple *buffer, int width) {
	static int timer = 0;
	static float step = 0;

	for(int x = 0; x < width; x++) {
		buffer[x].h = 120;
		buffer[x].s = 1.f;

		buffer[x].i = (1 - fabs(sin(step))) * 0.74f;
	}

	timer++;
	step += 0.015f;
}

/**
 * Totally random colors
 */
void effect_random(HSITuple *buffer, int width) {
	static int timer = 0;

	if(timer == 3) {
		for(int x = 0; x < width; x++) {
			buffer[x].h = random(0, 360);
			buffer[x].s = fmax(0.9, ((float)rand()/(float)(RAND_MAX)));
			buffer[x].i = ((float)rand()/(float)(RAND_MAX/0.75f));
		}

		timer = 0;
	}

	timer++;
}

/**
 * A couple points of light (in a rainbow pattern) cycle across the entire
 * length of the display.
 */
static const HSITuple rainbowHSI[] = {
	{0, 1, 1},
	{18, 1, 1},
	{50, 1, 1,},
	{106, 1, 1},
	{229, 1, 1},
	{260, 1, 1},
	{280, 1, 1},

	{0, 1, 1},
	{18, 1, 1},
	{50, 1, 1,},
	{106, 1, 1},
	{229, 1, 1},
	{260, 1, 1},
	{280, 1, 1},
};

void effect_moving_rainbow_points(HSITuple *buffer, int width) {
	static int frame = 0;
	static int timer = 0;

	for(int x = 0; x < width; x++) {
		int index = x % 7;

		buffer[x].h = rainbowHSI[6 - index + frame].h;
		buffer[x].s = rainbowHSI[6 - index + frame].s;
		buffer[x].i = rainbowHSI[6 - index + frame].i;
	}

	// increment timer
	if(timer++ == 2) {
		timer = 0;
		frame = (frame + 1) % 7;
	}
}

/**
 * Display one color of the rainbow, fade out, then fade in with the next color.
 */
void effect_rainbow_fade(HSITuple *buffer, int width) {
	static int frame = 0;
	static int timer = 0;
	static int changedFrame = 0;

	static float t = 0;
	float I = (1 - fabs(sin(t)));

	for(int x = 0; x < width; x++) {
		buffer[x].h = rainbowHSI[frame].h;
		buffer[x].s = rainbowHSI[frame].s;
		buffer[x].i = I * 0.9f;
	}

	// go to the next color
	if(I <= 0.001f && changedFrame == 0) {
		frame = (frame + 1) % 7;
		changedFrame = 1;
	} else if(I > 0.001f) {
		changedFrame = 0;
	}

	// increment x
	t += 0.01;
}


/**
 * A small glob of lights chasing from left to right and back again in the given
 * color.
 */
void effect_glob_chase(HSITuple *buffer, int width, float H, float S) {
	static int frame = 0;
	static int incrementFrame = 1;
	int globWidth = (int) fmin(12, fmax(6, (((float) width) * 0.2f)));

	for(int x = 0; x < width; x++) {
		if(x >= frame && (x - frame) <= globWidth) {
			buffer[x].h = H;
			buffer[x].s = S;
			buffer[x].i = 0.9;
		} else {
			buffer[x].i = 0.f;
		}
	}

	// Increase frame?
	if(incrementFrame == 1) {
		frame++;
	}
	// Otherwise, decrement it.
	else {
		frame--;
	}

	// Determine what to do next frame.
	if(frame >= (width - globWidth)) {
		incrementFrame = 0;
	} else if(frame == 0) {
		incrementFrame = 1;
	}
}

/**
 * A small glob of lights chasing from left to right and back again in the green
 */
void effect_glob_chase_green(HSITuple *buffer, int width) {
	effect_glob_chase(buffer, width, 90, 1.f);
}


/**
 * Sets a pixel's color based on its heat.
 */
void effect_fire_set_pixel_heat_color(HSITuple *pixel, uint8_t temperature) {
	const float initialHue = 0; // 106 for green

	// Between 0x00 and 0x40, scale intensity from 0 to 1 with a hue of 0
	if(temperature <= 0x40) {
		pixel->h = initialHue;
		pixel->s = 1;

		pixel->i = fmin(0.95, ((float) temperature) / 64.f);
	}
	// Between 0x40 and 0x80, scale hue from 0 to 40
	if(temperature > 0x40 && temperature <= 0x80) {
		pixel->h = initialHue + (((float) (temperature - 0x40)) / 1.6f);

		pixel->s = 1;
		pixel->i = 0.95;
	}
	// Between 0x80 and 0xFF, scale intensity from 1 to 0
	if(temperature > 0x80) {
		pixel->h = initialHue + 40;
		pixel->s = fmin(0, 1 - (((float) (temperature - 0x80)) / 80.f));
		pixel->i = 0.95;
	}

	// Hue is on 0 to 40 from 0x00 to 0x80
	/*pixel->h = max(40, (((float) heatramp) / 3.2));
	pixel->s = 1;
	pixel->i = ((float) heatramp) / 252.f*/
}

/**
 * A sort of fire effect, where there's a small red ember starting at the
 * bottom of the strip, slowly moving upwards as the fire heats up.
 */
void effect_fire(HSITuple *buffer, int width) {
	static int timer = 0;

	if(timer++ != 2) {
		return;
	}

	timer = 0;

	// behavior of the fire effect
	const int Cooling = 55;
	const int Sparking = 142;

	// Set up structures for the effect
	static int heatSz = 0;
	static uint8_t *heat = NULL;

	if(heat == NULL || heatSz != width) {
		if(heat) {
			free(heat);
		}

		heatSz = width;
		heat = malloc(sizeof(uint8_t) * heatSz);

		memset(heat, 0, heatSz);
	}

	int cooldown;

	// Step 1.  Cool down every cell a little
	for(int i = 0; i < width; i++) {
		cooldown = random(0, ((Cooling * 10) / width) + 2);

		if(cooldown > heat[i]) {
			heat[i] = 0;
		} else {
			heat[i] = (heat[i] - cooldown);
		}
	}

	// Step 2.  Heat from each cell drifts 'up' and diffuses a little
	for(int k = (width - 1); k >= 2; k--) {
		heat[k] = (heat[k - 1] + heat[k - 2] + heat[k - 2]) / 3;
	}

	// Step 3.  Randomly ignite new 'sparks' near the bottom
	if(random(0, 255) < Sparking) {
		int y = random(0, 7);
		heat[y] = heat[y] + random(160, 255);
		//heat[y] = random(160,255);
	}

/*	for(int i = 0; i < width; i++) {
		heat[i] = i * (256 / width);
	}
*/

	// Step 4.  Convert heat to LED colors
	for(int j = 0; j < width; j++) {
		effect_fire_set_pixel_heat_color(&buffer[j], heat[j]);
	}
}


/**
 * Simulates a twinkling star effect. 10% of the strip's LEDs will be lit at
 * a given time, as a star that starts at 100% intensity, then gradually fades
 * off to zero.
 */
void effect_twinkle(HSITuple *buffer, int width) {
	int starsToLight = width / 8;

	// allocate a heat buffer
	static int heatSz = 0;
	static int16_t *heat = NULL;

	if(heat == NULL || heatSz != width) {
		if(heat) {
			free(heat);
		}

		heatSz = width;
		heat = malloc(sizeof(uint16_t) * heatSz);

		memset(heat, 0, heatSz * sizeof(uint16_t));
	}

	// Determine how many nonzero heat values we have
	int litStars = 0;

	for(int i = 0; i < heatSz; i++) {
		if(heat[i] != 0) {
			litStars++;

			heat[i] = MAX(0, (heat[i] - random(0, 0x20)));
		}
	}

	// If there's stars to be lit, light them.
	while(litStars <= starsToLight) {
		int i = random(0, (heatSz - 1));

		if(heat[i] == 0) {
			heat[i] = random(0x100, 0x420);
			litStars++;
		}
	}

	// Generate an output from this
	for(int x = 0; x < width; x++) {
		buffer[x].h = 48;
		buffer[x].s = 0.42f;

		buffer[x].i = ((float) heat[x]) / 1024.f;
	}
}


/**
 * Moves a single dot from the bottom to the top of the strip very quickly.
 */
void effect_moving_dot(HSITuple *buffer, int width, HSITuple color) {
	static int frame = 0;
	static int timer = 0;

	// Draw
	for(int x = 0; x < width; x++) {
		if(x == frame) {
			buffer[x] = color;
		} else {
			buffer[x].i = 0;
		}
	}

	// Increment frame
	if(timer++ == 2) {
		frame = (frame + 2) % width;
		timer = 0;
	}
}

/**
 * Moves a single dot from the bottom to the top of the strip very quickly.
 */
void effect_moving_dot_white(HSITuple *buffer, int width) {
	effect_moving_dot(buffer, width, (HSITuple) {.h = 0, .s = 0, .i = 1});
}


static const HSITuple muricaColors[] = {
	{.h = 0, .s = .98, .i = 0.8},
	{.h = 0, .s = 0, .i = 0.8},
	{.h = 216.92, .s = 1, .i = 0.42}
};

/**
 * Alternate between red, white and blue.
 */
void effect_murica(HSITuple *buffer, int width) {
	static int timer = 0;
	static int frame = 0;

	int blockSz = width / 3;

	for(int x = 0; x < width; x++) {
		int offset = (abs(x + frame) / blockSz) % 3;

		buffer[x] = muricaColors[offset];
	}

	if(timer++ == 2) {
		frame--;

		timer = 0;
	}
}
