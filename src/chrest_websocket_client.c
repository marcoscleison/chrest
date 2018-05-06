#include <libwebsockets.h>
#include <string.h>
#include <stdlib.h>

#include"websocket_client.h"


int __getClientSendBufferPrePadding(){

    return LWS_SEND_BUFFER_PRE_PADDING; 
} 

int __getClientSendBufferPostPadding(){

    return LWS_SEND_BUFFER_POST_PADDING; 
} 

void __writeClientWebsocketText(void* wsi, const char* text,int len){

    lws_write(wsi, (unsigned char*)&text[LWS_SEND_BUFFER_PRE_PADDING], len-LWS_SEND_BUFFER_PRE_PADDING-LWS_SEND_BUFFER_POST_PADDING, LWS_WRITE_TEXT);
	
}





struct payload
{
    unsigned char data[LWS_SEND_BUFFER_PRE_PADDING + EXAMPLE_RX_BUFFER_BYTES + LWS_SEND_BUFFER_POST_PADDING];
    size_t len;
} received_payload;

unsigned char *buf;



enum protocols
{
    //PROTOCOL_HTTP = 0,
    PROTOCOL_EXAMPLE=0,
    PROTOCOL_COUNT
};


///////////////////////Client 



static int pubsub_callback_client( struct lws *wsi, enum lws_callback_reasons reason, void *user, void *in, size_t len )
{


	/*switch( reason )
	{
		case LWS_CALLBACK_CLIENT_ESTABLISHED:
			lws_callback_on_writable( wsi );
			break;

		case LWS_CALLBACK_CLIENT_RECEIVE:
			// Handle incomming messages here.
			break;

		case LWS_CALLBACK_CLIENT_WRITEABLE:
		{
			unsigned char buf[LWS_SEND_BUFFER_PRE_PADDING + EXAMPLE_RX_BUFFER_BYTES + LWS_SEND_BUFFER_POST_PADDING];
			unsigned char *p = &buf[LWS_SEND_BUFFER_PRE_PADDING];
			size_t n = sprintf( (char *)p, "%u", rand() );
			lws_write( wsi, p, n, LWS_WRITE_TEXT );
			break;
		}

		case LWS_CALLBACK_CLOSED:
		case LWS_CALLBACK_CLIENT_CONNECTION_ERROR:
			//web_socket = NULL;
			break;

		default:
			break;
	}*/

	return chest_pubsub_websocket_client_callback(wsi,reason, user, in, len);
}


static struct lws_protocols client_protocols[] =
    {
        {
            "chrest-pubsub",
            pubsub_callback_client,
            0,
            EXAMPLE_RX_BUFFER_BYTES,
        },
        {NULL, NULL, 0, 0} /* terminator */
};

struct lws_context* newWsPubSubClient()
{
   struct lws_context_creation_info info;
	memset( &info, 0, sizeof(info) );
	info.port = CONTEXT_PORT_NO_LISTEN;
	info.protocols = client_protocols;
	info.gid = -1;
	info.uid = -1;

    struct lws_context *context = lws_create_context( &info );

    return context;
}

struct lws* connectWsPubSubClient(struct lws_context *context,const char *addr, int port){
            struct lws_client_connect_info ccinfo = {0};
			ccinfo.context = context;
			ccinfo.address = addr;
			ccinfo.port = port;
			ccinfo.path = "/";
			ccinfo.host = lws_canonical_hostname(context);
			ccinfo.origin = "origin";
			ccinfo.protocol = "chrest-pubsub";
            return lws_client_connect_via_info(&ccinfo);
}