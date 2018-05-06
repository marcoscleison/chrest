module ChrestWebsocketsClient{

use SysCTypes;
use ChrestUtils;
use IO.FormattedIO;
use IO;
use List;
use Time;
use ChrestUtils;
use SysError;

require"string.h";
require"websocket_client.h";



var wsPubSubClientRouter:ChrestWsClientPubSub=new ChrestWsClientPubSub();

extern "struct lws_context" record lws_context{}
extern "struct lws" record lws{};

extern proc newWsPubSubClient():c_ptr(lws_context);
extern proc connectWsPubSubClient(context:c_ptr(lws_context), addr:c_string, port:c_int):c_void_ptr;

extern proc lws_write(wsi:c_void_ptr, buf:c_uchar,  len:size_t, protocol:c_int);
extern proc lws_callback_on_writable_all_protocol(ctx:c_void_ptr, protocol:c_void_ptr);
extern proc lws_callback_on_writable(wsi:c_void_ptr);

extern proc lws_get_context(wsi:c_void_ptr):c_void_ptr;
extern proc lws_get_protocol(wsi:c_void_ptr):c_void_ptr;
extern proc lws_remaining_packet_payload(wsi:c_void_ptr):c_int;
extern proc lws_write(wsi:c_void_ptr, buf:c_string, len:c_int, protocol:c_int);

extern proc lws_service(context:c_ptr(lws_context),t:c_int);

private extern proc chpl_macro_int_errno():c_int;
private inline proc errno return chpl_macro_int_errno():c_int;


class ChrestWebsocketClient{
	var context:c_ptr(lws_context);
	var wsi:c_void_ptr;
	var port:int;
	var addr:string;
	var connected=true;
	var closed=true;

	var channelDataDom:domain(string);
	
	var channelControllersDom:domain(string);
	var channelControllers:[channelControllersDom]WebsocketControllerInterface;
	var channelData:[channelDataDom]string;

	var sendBuffer:string;

	var receiveBuffer:[1..0]string;

    proc init(addr:string="127.0.0.1", port:int=8000){
		this.wsi=c_nil;
		this.port=port;
		this.addr=addr;
		this.connected=false;
		
	}
	proc Connect(){
		if(this.wsi==c_nil){
			writeln("Connecting  to ", this.addr,":",this.port);
			this.context = newWsPubSubClient();
			this.wsi =connectWsPubSubClient(this.context, this.addr.localize().c_str(), this.port:c_int);
			this.closed=false;
			wsPubSubClientRouter.addCliente(this.wsi,this);

		}

		begin this.process_requests();
	}
	proc Close(){
		this.closed=true;
		writeln("Closing ");
	}

	proc process_requests(){
		while(!this.closed){
			 lws_service(this.context, 50:c_int);
			// writeln("Processing request");
			
          


		}
	}

	proc Subscribe(channel:string, controller:WebsocketController){
			var cmd:WsCliCMD=new WsCliCMD();
		    cmd.channel=channel;
			cmd.cmd = "subscribe";
			cmd.data="";
			this.writeCmd(cmd);
			if(!channelControllersDom.member(channel)){
				channelControllers[channel] = new WebsocketControllerInterface(controller);
			}
	}
	

	proc Publish(channel:string, obj){
		var cmd:WsCliCMD=new WsCliCMD();;
		var content = objectToJson(obj);

		cmd.channel = channel;
		cmd.cmd = "publish";
		cmd.data = content;
		this.writeCmd(cmd);
	}

	proc readFragment(data:string){
		this.receiveBuffer.push_back(data);

	}
	proc read(data:string){
		try{
			this.receiveBuffer.push_back(data);
			var str = "".join(this.receiveBuffer);
			var cmd = jsonToObject(str,WsCliCMD);
			
			this.receiveBuffer.clear();

			if(this.channelControllersDom.member(cmd.channel)){
				var controller = this.channelControllers[cmd.channel];
				if(controller!=nil){

					controller(cmd);

				}
			}
			
			

		}catch{
			writeln("readJsonDataError");
		}
		
	}	

	proc writeCmd(cmd:WsCliCMD){
		try{
			var jsonstr = objectToJson(cmd);
			this.write(jsonstr);
			
		}catch{
			writeln("Error");
		}
		
	}

	proc write(data:string){
		if(this.wsi==c_nil){
			this.Connect();
		}
		//writeln("Writing data");
		this.sendBuffer+=data;
		lws_callback_on_writable(wsi);
		
	}
}

class WebsocketControllerInterface{
	forwarding var controller:WebsocketController;
}

class WebsocketController{
	proc init(){

	}
	proc this(cmd:WsCliCMD){
		writeln("Base Websocket controller");
	}
}




class ChrestWsClientPubSub{
	var peerDom:domain(uint);
	var peersList:[peerDom]ChrestWebsocketClient;
	proc init(){

	}
	proc addCliente(wsi:c_void_ptr,client:ChrestWebsocketClient){
		if(!this.peerDom.member(wsi:uint)){
			this.peersList[wsi:uint]= client;
		}
	}
	proc getCliente(wsi:c_void_ptr):ChrestWebsocketClient{
		return this.peersList[wsi:uint];
	}

}


class WsCliCMD{
	var channel:string;
	var cmd:string;
	var data:string;
	proc init(){

	}
}








extern const LWS_CALLBACK_RECEIVE:c_int;
extern const LWS_CALLBACK_SERVER_WRITEABLE:c_int;
extern const LWS_CALLBACK_ESTABLISHED :c_int;

extern const LWS_CALLBACK_CLIENT_ESTABLISHED:c_int;
extern const LWS_CALLBACK_CLIENT_RECEIVE:c_int;
extern const LWS_CALLBACK_CLIENT_WRITEABLE:c_int;
extern const LWS_CALLBACK_CLOSED:c_int;

extern const LWS_CALLBACK_CLIENT_CONNECTION_ERROR:c_int;




extern const LWS_SEND_BUFFER_PRE_PADDING:c_int;
extern const LWS_SEND_BUFFER_POST_PADDING:c_int;

extern const LWS_WRITE_TEXT:c_int;
extern proc __getClientSendBufferPrePadding():c_int;
extern proc __getClientSendBufferPostPadding():c_int;
extern proc  __writeClientWebsocketText(wsi:c_void_ptr, text:c_string,len:c_int);

var i:int=0;
const csz = LWS_SEND_BUFFER_PRE_PADDING+LWS_SEND_BUFFER_POST_PADDING+10;

var str:string = randomString(LWS_SEND_BUFFER_PRE_PADDING);
var post_padding:string =randomString(LWS_SEND_BUFFER_POST_PADDING);
var len:int=0;

proc writeToSocket(wsi:c_void_ptr, text:string){
	var str = randomString(LWS_SEND_BUFFER_PRE_PADDING);
	var s:string = text;
	str+=text;
	str+=post_padding;
	var buf:c_string = str.localize().c_str();
	__writeClientWebsocketText(wsi,buf,str.length:c_int);
	if errno == EAGAIN {
        chpl_task_yield();
	}
}


export proc chest_pubsub_websocket_client_callback( wsi:c_void_ptr,  reason:int(32), user:c_void_ptr, inn:c_void_ptr,len:size_t):c_int{
	

		if(reason == LWS_CALLBACK_CLIENT_ESTABLISHED){
			var client = wsPubSubClientRouter.getCliente(wsi);
			client.connected=true;
			
			//writeln("Client Connected");
			
		}else if(reason == LWS_CALLBACK_CLIENT_RECEIVE){
			var s:string = new string(inn:c_string);
			var remain = lws_remaining_packet_payload(wsi);

			var client = wsPubSubClientRouter.getCliente(wsi);

			//writeln("Remains ",remain);

			if(remain==0){
				client.read(s);

			}else if(remain>0){
				client.readFragment(s);
			}
			//writeln("Client Receiving data");
			//lws_callback_on_writable_all_protocol(lws_get_context(wsi), lws_get_protocol(wsi));
			lws_callback_on_writable(wsi);
		
		}else if(reason == LWS_CALLBACK_CLIENT_WRITEABLE){
			var client = wsPubSubClientRouter.getCliente(wsi);
		    var data:string = client.sendBuffer;//"".join(client.sendBuffer);

			if(data!=""){
				 writeToSocket(wsi,data);
				 client.sendBuffer="";
				 //writeln("Client Sending data ",data);
				 sleep(50, TimeUnits.milliseconds);
			}
			
			

		}else if(reason == LWS_CALLBACK_CLOSED){

			var client = wsPubSubClientRouter.getCliente(wsi);
			client.connected=false;
			//writeln("Client Closed");

		}else if(reason == LWS_CALLBACK_CLIENT_CONNECTION_ERROR){
			var client = wsPubSubClientRouter.getCliente(wsi);
			client.connected=false;
			//writeln("Client Connection error ");
		}else{

		}

	/*if(reason == LWS_CALLBACK_RECEIVE){
		
		var s:string = new string(inn:c_string);
		var remain = lws_remaining_packet_payload(wsi);
		writeln("Remains ",remain);

		if(remain==0){
			wsPubSubRouter.Readable(wsi,s);

		}else if(remain>0){
			wsPubSubRouter.ReadableFragment(wsi,s);
		}

		lws_callback_on_writable_all_protocol(lws_get_context(wsi), lws_get_protocol(wsi));
		
	}else if(reason==LWS_CALLBACK_SERVER_WRITEABLE){
		wsPubSubRouter.Writable(wsi);
		
	}else if(reason==LWS_CALLBACK_ESTABLISHED ){
		
		writeln("Connect ",wsi:uint);
		wsPubSubRouter.addPeer(wsi);
	}
	i+=1;
	*/
	
	return 0:c_int;
}






}