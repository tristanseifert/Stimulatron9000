#include "server.h"
#include "color.h"

#include <pthread.h>

#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <sys/ioctl.h>

// current effect
extern int curEffect;
// brightness scale
extern unsigned int globalBrightness;
// When set, the effects are NOT run and the display is blanked.
extern int suspendEffects;
// frames per second to use for rendering
extern int fps;
// when clear, the program shall terminate
extern uint8_t running;


// when set, a solid color is displayed.
extern int displaySolidColor;
// if the above variable is set, this is the RGB color to be displayed.
extern HSITuple colorToDisplay;

// background server thread
static pthread_t serverThread;

// socket fd
int sockFd;

// struct describing a client
typedef struct {
	int fd;

	int addrLen;
	struct sockaddr_in addr;
} server_client_t;

static void *server_thread_entry(void *ctx);
static void *server_client_entry(void *ctx);

static void server_cmd_set_color(lichtenstein_cmd_t *cmd);

/**
 * Starts the server listening.
 */
void server_start() {
	// Start thread
	pthread_create(&serverThread, NULL, server_thread_entry, NULL);
}

/**
 * Stops the server.
 */
void server_fini() {
    // wait for menu thread to finish
    // pthread_join(serverThread, NULL);
}

/**
 * Open the listening socket and prepare the server.
 */
static void server_init() {
     struct sockaddr_in servAddr;

	 // create a socket
	 sockFd = socket(AF_INET, SOCK_STREAM, 0);
     if(sockFd < 0) {
		 perror("Couldn't open socket");
	 }

	 // Set up listening
	 bzero((char *) &servAddr, sizeof(servAddr));
     servAddr.sin_family = AF_INET;
     servAddr.sin_addr.s_addr = INADDR_ANY;
     servAddr.sin_port = htons(6969);

	 // allow re-use of the port
	 int reuse = 1;
	 if(setsockopt(sockFd, SOL_SOCKET, SO_REUSEADDR, (const char*)&reuse, sizeof(reuse)) < 0) {
		 perror("setsockopt(SO_REUSEADDR) failed");
	 }

	 // Bind to port
	 if(bind(sockFd, (struct sockaddr *) &servAddr, sizeof(servAddr)) < 0) {
		 perror("Couldn't bind socket");
	 }

	 // Begin listening
	 if(listen(sockFd, 5) != 0) {
		 perror("Couldn't listen on socket");
	 }

	 printf("Listening on port 6969\n");
}

/**
 * Server thread entry
 */
static void *server_thread_entry(void *ctx) {
	// initialize socket
	server_init();

	// Accept any and all connections while running
	while(running) {
		// prepare client struct
		server_client_t *client = calloc(sizeof(server_client_t), 1);
		client->addrLen = sizeof(client->addr);

		// accept incoming connections
		client->fd = accept(sockFd, (struct sockaddr *) &client->addr, &client->addrLen);

	    if(client->fd < 0) {
			printf("Error accepting connection");
		}

		// spawn a thread to handle this client
		pthread_t clientThread;
		pthread_create(&clientThread, NULL, server_client_entry, client);
	}
}

/**
 * Handles a single connected client.
 */
static void *server_client_entry(void *ctx) {
	server_client_t *client = (server_client_t *) ctx;
	int isConnected = 1;

	// print some info
	struct sockaddr_in *ipv4 = (struct sockaddr_in *) &client->addr;
	char ipAddress[INET_ADDRSTRLEN];
	inet_ntop(AF_INET, &(ipv4->sin_addr), ipAddress, INET_ADDRSTRLEN);

	printf("Got connection from %s\n", ipAddress);

	// set up socket (no delay on write)
	int one = 1;
	setsockopt(client->fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));

	while(isConnected) {
		// Attempt to read everything that is available
		int len = 0;
		ioctl(client->fd, FIONREAD, &len);

		if(len != 0) {
			// read 19 bytes at first
			void *buf = malloc(len);
			len = read(client->fd, buf, 19);
			
			lichtenstein_cmd_t *cmd = (lichtenstein_cmd_t *) buf;

			/*// printf("\tRead %i bytes from %s\n", len, ipAddress);
		    time_t timer;
		    char buffer[26];
		    struct tm* tm_info;

		    time(&timer);
		    tm_info = localtime(&timer);

		    strftime(buffer, 26, "%Y-%m-%d %H:%M:%S", tm_info);

			// parse it as a command struct
			printf("\t[%s] Got command %02x\n", buffer, cmd->cmd);*/

			switch(cmd->cmd) {
				case kCmdSetEffect:
					curEffect = cmd->param[0];
					break;

				case kCmdSetBright:
					globalBrightness = cmd->param[0];
					break;

				case kCmdSetBlanking:
					suspendEffects = cmd->param[0];
					break;

				case kCmdSetMode:
					displaySolidColor = cmd->param[0];
					break;

				case kCmdSetColor:
					server_cmd_set_color(cmd);
					break;

				case kCmdGetState: {
					lichtenstein_cmd_t cmdOut;
			   	 	bzero(&cmdOut, sizeof(cmdOut));

					cmdOut.cmd = kCmdGetState;
					cmdOut.param[0] = curEffect;
					cmdOut.param[1] = globalBrightness;
					cmdOut.param[2] = suspendEffects;
					cmdOut.param[3] = displaySolidColor;

					len = write(client->fd, &cmdOut, sizeof(cmdOut));

					printf("\tWrote %i bytes to %s\n", len, ipAddress);
					break;
				}
			}
		} else {
			// no data available, sleep for 5ms
			usleep(5000);
		}
	}

	// we're done with this client (probably connection closed) so cleean up
	free(client);

	// flush stdio
	printf("Closed connection from %s\n", ipAddress);
	fflush(stdout);

	// exit
	pthread_exit(0);
}


/**
 * Handles the "set color" command. There are three floats (4 bytes) packed into
 * param[0..3], param[4..7], and param[8..12], representing the HSI values.
 */
static void server_cmd_set_color(lichtenstein_cmd_t *cmd) {
	size_t floatSz = sizeof(float);

	// copy HSI values
	memcpy(&colorToDisplay.h, &cmd->param[0], floatSz);
	memcpy(&colorToDisplay.s, &cmd->param[4], floatSz);
	memcpy(&colorToDisplay.i, &cmd->param[8], floatSz);

}
