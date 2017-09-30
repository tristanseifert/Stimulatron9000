#ifndef EFFECTS_H
#define EFFECTS_H

#include "color.h"

/**
 * A standard rainbow effect that sweeps across the LED strip.
 */
void effect_rainbow_sweep(HSITuple *buffer, int width);

/**
 * A fancy movie theatre-type ticker effect.
 */
void effect_movie_ticker_green(HSITuple *buffer, int width);

/**
 * A sort of "breathing" effect of the white color.
 */
void effect_breathe_white(HSITuple *buffer, int width);

/**
 * Totally random colors
 */
void effect_random(HSITuple *buffer, int width);

/**
 * A couple points of light (in a rainbow pattern) cycle across the entire
 * length of the display.
 */
void effect_moving_rainbow_points(HSITuple *buffer, int width);

/**
 * Display one color of the rainbow, fade out, then fade in with the next color.
 */
void effect_rainbow_fade(HSITuple *buffer, int width);

/**
 * A small glob of lights chasing from left to right and back again in the green
 */
void effect_glob_chase_green(HSITuple *buffer, int width);

/**
 * A sort of fire effect, where there's a small red ember starting at the
 * bottom of the strip, slowly moving upwards as the fire heats up.
 */
void effect_fire(HSITuple *buffer, int width);

/**
 * Simulates a twinkling star effect. 10% of the strip's LEDs will be lit at
 * a given time, as a star that starts at 100% intensity, then gradually fades
 * off to zero.
 */
void effect_twinkle(HSITuple *buffer, int width);

/**
 * Moves a single dot from the bottom to the top of the strip very quickly.
 */
void effect_moving_dot_white(HSITuple *buffer, int width);

/**
 * Alternate between red, white and blue.
 */
void effect_murica(HSITuple *buffer, int width);


#endif
