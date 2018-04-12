#ifndef __CHREST_WEBSOCKET
#define __CHREST_WEBSOCKET
#define EXAMPLE_RX_BUFFER_BYTES (1024)
#undef I
#include<libwebsockets.h>
 
int chest_pubsub_websocket_callback(void *wsi, int reason, void *user, void *inn, size_t len);

struct lws_context *newWsPubSubServer(int port);
void loopWsPubSubServer(struct lws_context* context, int timeout);
void destroyWsPubSubServer(struct lws_context* context);


void __writeWebsocketText(void* wsi, const char* text,int len);

int __getSendBufferPrePadding();
int __getSendBufferPostPadding();


#endif