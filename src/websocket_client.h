#ifndef __CHREST_WEBSOCKET
#define __CHREST_WEBSOCKET
#define EXAMPLE_RX_BUFFER_BYTES (1024)
#undef I
#include<libwebsockets.h>
 
int chest_pubsub_websocket_client_callback(void *wsi, int reason, void *user, void *inn, size_t len);


//Client
struct lws_context* newWsPubSubClient();
struct lws* connectWsPubSubClient(struct lws_context *context,const char *addr, int port);

//Aux

void __writeClientWebsocketText(void* wsi, const char* text,int len);

int __getClientSendBufferPrePadding();
int __getClientSendBufferPostPadding();


#endif