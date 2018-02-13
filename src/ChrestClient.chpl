module ChrestClient{
use httpev;
use SysCTypes;
use Random;
use Utils;
use SysCTypes;


//Callback router for the responses
proc response_cb(req:c_ptr(evhttp_request), arg:c_void_ptr){
    var request = arg:ClientRequest;

    if((request!=nil) && (req!=nil)){
            var buffer = evbuffer_new ();
            var srcBuffer = evhttp_request_get_input_buffer(req);
            evbuffer_add_buffer(buffer, srcBuffer);
            request.OnResponse(req,buffer);
        }
   
}

//client reponse
class ClientResponse{
    var req:c_ptr(evhttp_request);
    var buffer:c_ptr(evbuffer);
    var bodyData:string;
    
    proc ClientResponse(){
    }
    proc _setRequest(req:c_ptr(evhttp_request)){
        this.req=req;
    }
    // used by the callback router to get response, you cannot use this directly
    proc this(req:c_ptr(evhttp_request),buffer:c_ptr(evbuffer)){
        this._setRequest(req);
        this.buffer=buffer;
    }
    // Get response content as string
    proc this():string{
         
        return this.ParseBody();
    }
    // Get response as Chapel Object
    proc this(type eltType):eltType{
        var obj:eltType = new eltType();
        this.ParseBody();
         try{
            var mem = openmem();
            var writer = mem.writer().write(this.bodyData);
            var reader = mem.reader();
            reader.readf("%jt", obj);
            return obj;

        }catch{
            writeln("Cannot parse JSon Request");
            writeln("body content ");
            writeln(this.bodyData);
            return obj;
        } 
    }

    proc ParseBody(){
        var len = evbuffer_get_length(this.buffer);
        var data = c_calloc(uint(8), (len+1):size_t);
        data[len]=0:uint(8);

        if(evbuffer_copyout(this.buffer, data:c_ptr(uint(8)), len)==-1){
           return "";
        }
        var dados = new string(buff=data, length=len, size=len+1, owned=true, needToCopy=false);
        this.bodyData = dados;
        return this.bodyData;
    }
    
}
//Client Request 
class ClientRequest{
    
    var client:ChrestClient;
    var verb:string;
    var path:string;
  
    var  headers:c_ptr(evkeyvalq);
    var req:c_ptr(evhttp_request);
    var buffer:c_ptr(evbuffer);
    var response:ClientResponse=nil;

    proc ClientRequest(){
        this.response=new ClientResponse();

        this.req = evhttp_request_new(c_ptrTo(response_cb), this:c_void_ptr);
        this.headers = evhttp_request_get_output_headers(this.req);
        this.buffer= evhttp_request_get_output_buffer(this.req);
    }

    proc ClientRequest(client:ChrestClient, verb:string="GET", path:string){
        this.client=client;
        this.verb=verb;
        this.path=path;
        this.response=new ClientResponse();
        
        this.req = evhttp_request_new(c_ptrTo(response_cb), this:c_void_ptr);
        this.headers = evhttp_request_get_output_headers(this.req);
        this.buffer= evhttp_request_get_output_buffer(this.req);

    }

    proc configure(client:ChrestClient, verb:string="GET", path:string){
        this.client=client;
        this.verb=verb;
        this.path=path;
        if(this.response==nil){
            this.response=new ClientResponse();
        }
        
    }

    proc verbToConstant(verb:string):c_short{
        
        if(verb=="GET"||verb=="get"){
            return EVHTTP_REQ_GET;
        }
        if(verb=="POST"||verb=="post"){
            return EVHTTP_REQ_POST;
        }
        if(verb=="PUT"||verb=="put"){
            return EVHTTP_REQ_PUT;
        }
        if(verb=="DELETE"||verb=="delete"){
            return EVHTTP_REQ_DELETE;
        }
        if(verb=="CONNECT"||verb==" connect"){
            return EVHTTP_REQ_CONNECT;
        }
        if(verb=="HEAD"||verb=="head"){
            return EVHTTP_REQ_HEAD;
        }
        if(verb=="OPTIONS"||verb=="options"){
            return EVHTTP_REQ_OPTIONS;
        }
        if(verb=="TRACE"||verb=="TRACE"){
            return EVHTTP_REQ_TRACE;
        }
        if(verb=="PATCH"||verb=="patch"){
            return EVHTTP_REQ_PATCH;
        }

        return 0:c_short;

    }
    //Adds custom header to Request
    proc AddHeader(header_name:string,header_value:string){
         evhttp_add_header(this.headers, header_name.localize().c_str(), header_value.localize().c_str());
    }
    
    proc addParams(header_name:string, header_value:string){

    }

    proc OnResponse(req:c_ptr(evhttp_request),buffer:c_ptr(evbuffer)){
        if(this.response==nil){
            this.response = new ClientResponse();
        }
        this.response(req,buffer);
    }
    
    //Sends the requests and returns the response object
    proc this():ClientResponse{
        this.Send();
        
        return this.response;
    }

//Sends object as Json and returns the response object
    proc this(obj:?eltType):ClientResponse{
        this.Write(obj);  
        this.Send();
        return this.response;
    } 

    proc Write(str ...?vparams){
    for param el in 1..vparams{     
         this._print(str[el]);
    }
  }
  proc _print(str:?eltType){
    select eltType{
      when int{
        evbuffer_add_printf(this.buffer, "%d".localize().c_str(), str);
      }
      when real{
        evbuffer_add_printf(this.buffer, "%f".localize().c_str(), str);
      }
      when string{
        evbuffer_add_printf(this.buffer, "%s".localize().c_str(), str.localize().c_str());
      }
      otherwise{
        try{
            var jsonstr:string = "%jt".format(str);
            evbuffer_add_printf(this.buffer, "%s".localize().c_str(), jsonstr.localize().c_str());
        }catch{
            writeln("Cannot serialize content");
        }
      }
    }
  }
    proc Send(){
        this.AddHeader( "Host", this.client.host);
        this.AddHeader( "Connection", "close");
        this.AddHeader( "Accept","*/*"); 	
        this.AddHeader( "User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36 ChrestClient/0.0.1"); 	
        evhttp_make_request(this.client.con, this.req, this.verbToConstant(this.verb), this.path.localize().c_str());        
        this.client.Dispatch();
    }
    
    proc getResponse():ClientRequest{
        return this.response;
    }

}

class ChrestClient{
    var ebase : c_ptr(event_base);   
    var host:string;
    var port:int=80;
    var con:c_ptr(evhttp_connection);
    

    proc ChrestClient(host:string, port:int){
        this.host = host;
        this.port = port;
        this.ebase = event_base_new();
        this.con = evhttp_connection_base_new(this.ebase, c_nil, this.host.localize().c_str(), this.port:c_ushort);
    }
    // make GET call using custom request data
    proc Get(path:string, req:ClientRequest){
     var req:ClientRequest;
        if(req==nil){
         req = new ClientRequest(this,"GET",path);
        }
        req.configure(this,"GET",path);
        var res = req();
        return res;
    }

    proc Get(path:string){
        var req = new ClientRequest(this,"GET",path);
        return req();
    }
    proc Post(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"POST",path);
        }else{
            req= _req;
        }
        req.configure(this,"POST",path);
        var res = req();
        return res;
    }
    // makes Post call send obj as json
    proc Post(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"POST",path);
        }else{
            req= _req;
        }
        req.configure(this,"POST",path);
        var res = req(obj);
        return res;
    }

    proc Post(path:string){
        var req = new ClientRequest(this,"POST",path);
        return req();
    }
    proc Put(path:string){
        var req = new ClientRequest(this,"PUT",path);
        return req();
    }
    proc Put(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PUT",path);
        }else{
            req= _req;
        }
        req.configure(this,"PUT",path);
        var res = req();
        return res;
    }
     // makes Put call send obj as json
    proc Put(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PUT",path);
        }else{
            req= _req;
        }
        req.configure(this,"PUT",path);
        var res = req(obj);
        return res;
    }
    proc Delete(path:string){
        var req = new ClientRequest(this,"DELETE",path);
        return req();
    }
    proc Delete(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"DELETE",path);
        }else{
            req= _req;
        }
        req.configure(this,"DELETE",path);
        var res = req();
        return res;
    }
     // makes Delete call send obj as json
    proc Delete(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"DELETE",path);
        }else{
            req= _req;
        }
        req.configure(this,"DELETE",path);
        var res = req(obj);
        return res;
    }
    proc Connect(path:string){
        var req = new ClientRequest(this,"CONNECT",path);
        return req();
    }
    proc Connect(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"CONNECT",path);
        }else{
            req= _req;
        }
        req.configure(this,"CONNECT",path);
        var res = req();
        return res;
    }
     // makes Connect call send obj as json
    proc Connect(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"CONNECT",path);
        }else{
            req= _req;
        }
        req.configure(this,"CONNECT",path);
        var res = req(obj);
        return res;
    }
    proc Options(path:string){
        var req = new ClientRequest(this,"OPTIONS",path);
        return req();
    }
    proc Options(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"OPTIONS",path);
        }else{
            req= _req;
        }
        req.configure(this,"OPTIONS",path);
        var res = req();
        return res;
    }
     // makes Options call send obj as json
    proc Options(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"OPTIONS",path);
        }else{
            req= _req;
        }
        req.configure(this,"OPTIONS",path);
        var res = req(obj);
        return res;
    }
    proc Trace(path:string){
        var req = new ClientRequest(this,"TRACE",path);
        return req();
    }
    proc Trace(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"TRACE",path);
        }else{
            req= _req;
        }
        req.configure(this,"TRACE",path);
        var res = req();
        return res;
    }
     // makes Trace call send obj as json
    proc Trace(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"TRACE",path);
        }else{
            req= _req;
        }
        req.configure(this,"TRACE",path);
        var res = req(obj);
        return res;
    }
    proc Head(path:string){
        var req = new ClientRequest(this,"HEAD",path);
        return req();
    }
    proc Head(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"HEAD",path);
        }else{
            req= _req;
        }
        req.configure(this,"HEAD",path);
        var res = req();
        return res;
    }
     // makes Head call send obj as json
    proc Head(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"HEAD",path);
        }else{
            req= _req;
        }
        req.configure(this,"HEAD",path);
        var res = req(obj);
        return res;
    }
    proc Patch(path:string){
        var req = new ClientRequest(this,"PATCH",path);
        return req();
    }
    proc Patch(path:string, _req:ClientRequest){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PATCH",path);
        }else{
            req= _req;
        }
        req.configure(this,"PATCH",path);
        var res = req();
        return res;
    }
     // makes Patch call send obj as json
    proc Patch(path:string, obj:?eltType, _req:ClientRequest=nil){
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PATCH",path);
        }else{
            req= _req;
        }
        req.configure(this,"PATCH",path);
        var res = req(obj);
        return res;
    }

   
   proc Dispatch(){
        event_base_dispatch(this.ebase);
    }
 }

    module Utils{
        proc getPath(req: c_ptr(evhttp_request)):string{
            var uri_str = evhttp_request_get_uri(req);
            var uri = evhttp_uri_parse(uri_str);
             var path = new string(evhttp_uri_get_path(uri):c_string);
            return path;
            
        }

    }


}