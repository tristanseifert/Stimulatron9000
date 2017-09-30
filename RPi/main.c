#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <signal.h>
#include <stdarg.h>
#include <errno.h>
#include <inttypes.h>

#include "clk.h"
#include "gpio.h"
#include "dma.h"
#include "pwm.h"

#include "color.h"
#include "effects.h"
#include "server.h"

#include "ws2811.h"


#define ARRAY_SIZE(stuff)       (sizeof(stuff) / sizeof(stuff[0]))

// current effect
int curEffect = 0;
// brightness scale
unsigned int globalBrightness = 0xFF;

// When set, the effects are NOT run and the display is blanked.
int suspendEffects = 0;

// when set, a solid color is displayed.
int displaySolidColor = 0;
// if the above variable is set, this is the RGB color to be displayed.
HSITuple colorToDisplay;

// frames per second to use for rendering
int fps = 60;

// Set up the LED string
const int width = 150;

ws2811_t ledstring = {
    .freq = 1250000, // WS2811_TARGET_FREQ,
    .dmanum = 0,
    .channel = {
        [0] = {
            .gpionum = 10, // 21 for PCM
            .count = 150,
            .invert = 0,
            .brightness = 10,
            .strip_type = SK6812W_STRIP, // SK6812_STRIP_RGBW
        },
        [1] = {
            .gpionum = 0,
            .count = 0,
            .invert = 0,
            .brightness = 0,
        },
    },
};

// an in-memory buffer of HSI data (effects use this)
HSITuple *matrixHSI;

// when clear, the program should terminate
uint8_t running = 1;

/**
 * Copies our buffered LED matrix data into the LED string object, so that it
 * can be outputted.
 */
void matrix_render(void) {
    for (int x = 0; x < width; x++) {
        ledstring.channel[0].leds[x] = HSIToWRGB(&matrixHSI[x]);
        // printf("\tLED value: 0x%08x\n", ledstring.channel[0].leds[x]);

        // WW GG RR BB
        // ledstring.channel[0].leds[x] = 0x00FF0000;
    }
}

/**
 * Clears the contents of the matrix.
 */
void matrix_clear(void) {
    for (int x = 0; x < width; x++) {
        matrixHSI[x].i = 0;
    }
}

/**
 * Performs a single step of the currently active effect.
 */
void do_effect() {
    switch(curEffect) {
        case 0:
            effect_rainbow_sweep(matrixHSI, width);
            break;

        case 1:
            effect_movie_ticker_green(matrixHSI, width);
            break;

        case 2:
            effect_breathe_white(matrixHSI, width);
            break;

        case 3:
            effect_random(matrixHSI, width);
            break;

        case 4:
            effect_moving_rainbow_points(matrixHSI, width);
            break;

        case 5:
            effect_rainbow_fade(matrixHSI, width);
            break;

        case 6:
            effect_glob_chase_green(matrixHSI, width);
            break;

        case 7:
            effect_fire(matrixHSI, width);
            break;

        case 8:
            effect_twinkle(matrixHSI, width);
            break;

        case 9:
            effect_moving_dot_white(matrixHSI, width);
            break;

        case 10:
            effect_murica(matrixHSI, width);
            break;

        default:
            break;
    }
}

/**
 * Handle Ctrl+C signal
 */
static void ctrl_c_handler(int signum) {
    running = 0;
}

/**
 * Install signal handlers. These clean up the library on exit
 */
static void setup_handlers(void) {
    struct sigaction sa = {
        .sa_handler = ctrl_c_handler,
    };

    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
}

int main(int argc, char *argv[]) {
    ws2811_return_t ret;

	// parse arguments
	uintmax_t num = 0;

	if(argc == 1) {
		// puts("At least one argument (effect number) is required");
	} else {
		uintmax_t num = strtoumax(argv[1], NULL, 10);
		if(num == UINTMAX_MAX && errno == ERANGE) {
			puts("Couldn't parse effect number\n");
			return -1;
		}

		if(num < 0 || num > 10) {
			puts("Invalid effect number");
			return -1;
		}
	}

	curEffect = num;

    // Set up matrix and error handlers
    setup_handlers();

    matrixHSI = malloc(sizeof(HSITuple) * width);

    if ((ret = ws2811_init(&ledstring)) != WS2811_SUCCESS) {
        fprintf(stderr, "ws2811_init failed: %s\n", ws2811_get_return_t_str(ret));
        return ret;
    }

	// start command server
	server_start();

    static int didRenderDisable = 0;

    // Main loop
    while(running) {
        // Run effect
        if(suspendEffects == 0) {
			// display a solid color?
			if(displaySolidColor) {
			    for (int x = 0; x < width; x++) {
			        ledstring.channel[0].leds[x] = HSIToWRGB(&colorToDisplay);
			    }
			}
			// render an actual effect
			else {
            	do_effect();
            	matrix_render();
			}

            // update global state
            ledstring.channel[0].brightness = globalBrightness;

            // render
            if((ret = ws2811_render(&ledstring)) != WS2811_SUCCESS) {
                fprintf(stderr, "ws2811_render failed: %s\n", ws2811_get_return_t_str(ret));
                break;
            }

            didRenderDisable = 0;
        } else {
            ledstring.channel[0].brightness = 0;

            // render if we haven't before to disable LEDs
            if(didRenderDisable == 0) {
                if((ret = ws2811_render(&ledstring)) != WS2811_SUCCESS) {
                    fprintf(stderr, "ws2811_render failed: %s\n", ws2811_get_return_t_str(ret));
                    break;
                }

                didRenderDisable = 1;
            }
         }

        // 30 frames /sec
        usleep(1000000 / fps);
    }

    // Clear the matrix (turn off all LEDs)
	matrix_clear();
	matrix_render();
	ws2811_render(&ledstring);

    // Clean up library
    ws2811_fini(&ledstring);

	// kill command server
	server_fini();

    printf ("\n");
    return ret;
}
