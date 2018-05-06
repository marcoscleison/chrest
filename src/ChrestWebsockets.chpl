module ChrestWebsockets{

use SysCTypes;
use ChrestUtils;
use IO.FormattedIO;
use IO;
use List;
use Time;
use Chrest;

require"string.h";
require"websocket.h";



var wsPubSubRouter:ChrestWsPubSub=new ChrestWsPubSub();

extern "struct lws_context" record lws_context{}

extern proc newWsPubSubServer(portc_int):c_ptr(lws_context);
extern proc loopWsPubSubServer( context:c_ptr(lws_context),timeout:c_int);
extern proc destroyWsPubSubServer(context:c_ptr(lws_context));


extern "struct lws" record lws{};
extern proc lws_write(wsi:c_void_ptr, buf:c_uchar,  len:size_t, protocol:c_int);
extern proc lws_callback_on_writable_all_protocol(ctx:c_void_ptr, protocol:c_void_ptr);
extern proc lws_get_context(wsi:c_void_ptr):c_void_ptr;
extern proc lws_get_protocol(wsi:c_void_ptr):c_void_ptr;
extern proc lws_remaining_packet_payload(wsi:c_void_ptr):c_int;
extern proc lws_write(wsi:c_void_ptr, buf:c_string, len:c_int, protocol:c_int);


class ChrestWebsocketServer{
	var context:c_ptr(lws_context);

    proc init(port:int=8000){
		this.context = newWsPubSubServer(port:c_int);	
		
	}

	proc Listen(){
		 loopWsPubSubServer(this.context,10000:c_int);
	}

	proc ListenWithChrest(ch:Chrest){
		cobegin{
			begin ch.Listen(); 
			loopWsPubSubServer(this.context,10000:c_int);
			
		}
		
	}

	proc Close(){
		destroyWsPubSubServer(this.context);
	}

}





class WsCMD{
	var channel:string;
	var cmd:string;
	var data:string;
	proc init(){

	}
}

class DummyInfo{
	var time:string;
	proc init(){

	}
}


proc chrestPubSubPublish(channel:string,ref obj:?eltType){
    wsPubSubRouter.Publish(channel,obj);
}


class wsChannel{
	var name:string;
	var data:list(string);
	proc init(name:string){
		this.name = name;
		this.data=makeList("");
	}
	proc push(str:string){
		this.data.push_back(str);
	}
	proc pop(){
		if(this.data.length>0){
			return this.data.pop_front();
		}
		return "";
	}

	proc dataAsString(){
		try{
			return "%jt".format(this.data);
		}catch{
			return "[]";
		}
	}
}

class WebsocketPeer{
	var wsi:c_void_ptr;
	var data:string;
	
	var channelsDom:domain(string);
	var channels:[channelsDom]wsChannel;
	var last_channel:string;
	var max_queue_len:int =0;
	var next_queue:wsChannel;

	proc init(wsi:c_void_ptr){
		this.wsi=wsi;
	}
	proc Write(text:string){
		writeToSocket(this.wsi,text);
	}
	proc publish(channel:string, msg:string){
		if(this.channelsDom.member(channel)){
			this.channels[channel].push(msg);		
		}else{
			this.subscribe(channel);
			this.channels[channel].push(msg);
		}
	}
	proc subscribe(channel:string){
		if(!this.channelsDom.member(channel)){
			this.channels[channel] = new wsChannel(channel);		
		}
	}
	proc unsubscribe(channel:string){
		if(!this.channelsDom.member(channel)){
			this.channelsDom-=channel;		
		}
	}

	proc popMsg(channel:string){
		if(this.channelsDom.member(channel)){
			return this.channels[channel].pop();
		}
		return "";
	}

	proc isMember(channel:string){
		return this.channelsDom.member(channel);
	}
	
}

class ChrestWsPubSub{

	var peerDom:domain(uint);
	var peersList:[peerDom]WebsocketPeer;
	var data:string;
	

	proc init(){

	}

	proc addPeer(wsi:c_void_ptr){
		if(!this.peerDom.member(wsi:uint)){
			this.peersList[wsi:uint]= new WebsocketPeer(wsi);
		}
	}

	proc getPeer(wsi:c_void_ptr):WebsocketPeer{
		return this.peersList[wsi:uint];
	}

	
	proc Publish(channel:string,ref obj:?eltType){
		try{
			
			var jsonstr:string = "%jt".format(obj);
			writeln("Publishing extern:",channel);
			for peer in this.peersList{
				//if(peer.isMember(channel)){
					if(peer==nil){
						writeln("Error: null peer");
					}else{
						peer.publish(channel,jsonstr);
						lws_callback_on_writable_all_protocol(lws_get_context(peer.wsi), lws_get_protocol(peer.wsi));
					}
					
				//}
			}

		}catch e:Error{
			writeln("Error ",e);
		}
	}

	proc Writable(wsi:c_void_ptr){
		var wscli = this.getPeer(wsi);
		if(wscli!=nil){
			
			for ch in wscli.channels{
				if(wscli.max_queue_len < ch.data.length ){
					wscli.max_queue_len = ch.data.length;
					wscli.next_queue = ch;	
				}
		    }
			var ch = wscli.next_queue;

		  	if(ch!=nil&&ch.data.length>0){
					writeln("Queue@",wsi," #",ch.name,"=",ch.data.length);
					var data = ch.dataAsString();
					if(data!=""){
						var wscmd = new WsCMD();
						try{
							wscmd.cmd = "response";
							wscmd.channel = ch.name;
							wscmd.data = data;
							var cmd = "%jt".format(wscmd);
							writeln("Sending to client ",ch.name,"@",wsi);
							wscli.Write(cmd);
							wscli.last_channel = ch.name;
							ch.data.destroy();
							wscli.max_queue_len=0;
						}catch  e: Error{
							writeln("Cannot serialize :",e);
						}
						//delete data;
						delete wscmd;
						
					}
				   }
				}
				wscli.data="";
	}

	proc ReadableFragment(wsi:c_void_ptr, data:string){
		var wscli = this.getPeer(wsi);
		if(wscli!=nil){
			wscli.data += data;
			//writeln("Fragment ", data);
		}

	}
	proc Readable(wsi:c_void_ptr, data:string){
		var wscli = this.getPeer(wsi);
		if(wscli!=nil){
			//writeln("Sending to ", wscli.wsi:uint);
			wscli.data += data; 
			try{
				var obj= jsonToObject(wscli.data,WsCMD);
				//writef("%jt\n", obj);
				//writeln("cmd = ",obj);
				//writeln("obj.data = ",obj.data);

				var cmd = obj.cmd;
				var channel_name = obj.channel;
				var channel_data =obj.data;
				//var channel =this.findOrNewChannel(channel_name);

				if(cmd=="publish"){
					for cli in this.peersList{
						if(wsi!=cli.wsi){
							cli.publish(channel_name,channel_data);
						}
					}

				}else if(cmd=="subscribe"){
					wscli.subscribe(channel_name);
				    	
				}else if(cmd=="unsubscribe"){
					wscli.unsubscribe(channel_name);
				}else{
					writeln("Command not recognized");
				}

				delete obj;
             
			}catch{
				writeln("Formated ");

			}
			
		}
	}

}



//const LWS_CALLBACK_RECEIVE:c_int = 6;
//const LWS_CALLBACK_SERVER_WRITEABLE:c_int = 11;

extern const LWS_CALLBACK_RECEIVE:c_int;
extern const LWS_CALLBACK_SERVER_WRITEABLE:c_int;
extern const LWS_CALLBACK_ESTABLISHED :c_int;


extern const LWS_SEND_BUFFER_PRE_PADDING:c_int;
extern const LWS_SEND_BUFFER_POST_PADDING:c_int;

extern const LWS_WRITE_TEXT:c_int;
extern proc __getSendBufferPrePadding():c_int;
extern proc __getSendBufferPostPadding():c_int;
extern proc  __writeWebsocketText(wsi:c_void_ptr, text:c_string,len:c_int);

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
	__writeWebsocketText(wsi,buf,str.length:c_int);
}


export proc chest_pubsub_websocket_callback( wsi:c_void_ptr,  reason:int(32), user:c_void_ptr, inn:c_void_ptr,len:size_t):c_int{
	
	if(reason == LWS_CALLBACK_RECEIVE){
		
		var s:string = new string(inn:c_string);
		var remain = lws_remaining_packet_payload(wsi);
		writeln("Remains ",remain);

		if(remain==0){
			wsPubSubRouter.Readable(wsi,s);
			writeln("Received ",s);

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
	
	return 0:c_int;
}






}