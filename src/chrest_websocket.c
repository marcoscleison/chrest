#include <libwebsockets.h>
#include <string.h>
#include <stdlib.h>

#include"websocket.h"


int __getSendBufferPrePadding(){

    return LWS_SEND_BUFFER_PRE_PADDING; 
} 

int __getSendBufferPostPadding(){

    return LWS_SEND_BUFFER_POST_PADDING; 
} 

void __writeWebsocketText(void* wsi, const char* text,int len){

    lws_write(wsi, (unsigned char*)&text[LWS_SEND_BUFFER_PRE_PADDING], len-LWS_SEND_BUFFER_PRE_PADDING-LWS_SEND_BUFFER_POST_PADDING, LWS_WRITE_TEXT);

}


static int callback_http(struct lws *wsi, enum lws_callback_reasons reason, void *user, void *in, size_t len)
{

    switch (reason)
    {
    case LWS_CALLBACK_HTTP:
        lws_serve_http_file(wsi, "./wsindex.html", "text/html", NULL, 0);
        break;
    default:
        break;
    }

    return 0;
}


struct payload
{
    unsigned char data[LWS_SEND_BUFFER_PRE_PADDING + EXAMPLE_RX_BUFFER_BYTES + LWS_SEND_BUFFER_POST_PADDING];
    size_t len;
} received_payload;

unsigned char *buf;

static int pubsub_callback(struct lws *wsi, enum lws_callback_reasons reason, void *user, void *in, size_t len)
{
    
    return chest_pubsub_websocket_callback(wsi,reason, user, in, len);
}

enum protocols
{
    PROTOCOL_HTTP = 0,
    PROTOCOL_EXAMPLE,
    PROTOCOL_COUNT
};

static struct lws_protocols protocols[] =
    {
        /* The first protocol must always be the HTTP handler */
        {
            "http-only",   /* name */
            callback_http, /* callback */
            0,             /* No per session data. */
            0,             /* max frame size / rx buffer */
        },
        {
            "chrest-pubsub",
            pubsub_callback,
            0,
            EXAMPLE_RX_BUFFER_BYTES,
        },
        {NULL, NULL, 0, 0} /* terminator */
};

struct lws_context* newWsPubSubServer(int port)
{
    struct lws_context_creation_info info;
    memset(&info, 0, sizeof(info));

    info.port = port;
    info.protocols = protocols;
    info.gid = -1;
    info.uid = -1;

    struct lws_context *context = lws_create_context(&info);
    return context;
}

void loopWsPubSubServer(struct lws_context* context, int timeout){
    while (1)
    {
        lws_service(context, /* timeout_ms = */ timeout);
    }
}

void destroyWsPubSubServer(struct lws_context* context){

    lws_context_destroy(context);
}

