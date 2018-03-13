module ChrestClient{
use httpev;
use SysCTypes;
use Random;
use Utils;
use SysCTypes;
use Types;
use Reflection;
use SysError;
use  DateTime;


proc datetime.readWriteThis(f) {
  var dash  = new ioLiteral("-"),
      colon = new ioLiteral(":");
  f <~> new ioLiteral("{") <~> chpl_date.chpl_year <~> dash
    <~> chpl_date.chpl_month <~> dash <~> chpl_date.chpl_day
    <~> new ioLiteral(" ") <~> chpl_time.chpl_hour <~> colon
    <~> chpl_time.chpl_minute <~> colon <~> chpl_time.chpl_second
    <~> new ioLiteral(".") <~> chpl_time.chpl_microsecond
    <~> new ioLiteral("}");
}


 




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

class ChrestConnectionError:Error{
    var msg:string;
    proc init(){
        super.init();
        this.msg="Connection refused.";
    }
    
    proc message(){
        return this.msg;
    }
}

class ChrestRequestError:Error{
    var msg:string;

    proc init(req:string){
        super.init();
        this.msg="Request failure or Invalid ("+req+")";
    }
    
    proc message(){
        return this.msg;
    }
}

class ChrestJsonError:Error{
    var msg:string;

    proc init(){
        super.init();
        this.msg="Could not process JSON.";
    }
    
    proc message(){
        return this.msg;
    }
}

//client reponse
class ClientResponse{
    
    var xx:domain(string);
    var rxx:[xx]string;

    var req:c_ptr(evhttp_request);
    var buffer:c_ptr(evbuffer);
    var bodyData:string;
    var headers:c_ptr(evkeyvalq); 
    var client: ChrestClient;
    var response_header_dom:domain(string);
    var response_headers:[response_header_dom]string;
    


    proc ClientResponse(){
    }

    proc _setRequest(req:c_ptr(evhttp_request)){
        this.req=req;
    }

    proc _setClient(cli:ChrestClient){
        this.client = cli;
    }

    proc _getHeader(key:string){
        return new string(evhttp_find_header(this.headers,key.localize().c_str()));
    }
    proc getHeader(key:string){
        if(this.response_header_dom.member(key)){
            return this.response_headers[key];
        }
        return "";
    }

    proc isRefused():bool{
        return this.responseCode()==0;
    }

    proc responseCode():int{
        return evhttp_request_get_response_code(this.req):int;
    }

    proc responseOK():bool{
        return (this.responseCode()==200) ||  (this.responseCode()==203);
    }
    
    proc responseError():bool{
        return (this.responseCode()>=400);
    }

    proc _verifyExceptions() throws{
        var status:int =this.responseCode(); 
        if (status == 0) {
            throw new ChrestConnectionError();
            return;
        }    
    }


    // used by the callback router to get response, you cannot use this directly
    proc this(req:c_ptr(evhttp_request),buffer:c_ptr(evbuffer)){
        this._setRequest(req);
        this.buffer=buffer;
        this.headers = evhttp_request_get_input_headers(this.req);
        
        for h in this.client.allow_response_headers{
            var s = this._getHeader(h);      
            this.response_headers[h] = s;
        }

    }
    // Get response content as string
    proc this():string throws{
        this._verifyExceptions();         
        return this.ParseBody();
    }
    // Get response as Chapel Object
    proc this(type eltType):eltType throws{
        var obj:eltType = new eltType();
        
        this._verifyExceptions();

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
  
    var  _headers:c_ptr(evkeyvalq);
    var headersDom:domain(string);
    var headers:[headersDom]string;
    //var paramsDom:domain(string);
    //var params:[paramsDom]string;



    var req:c_ptr(evhttp_request);
    var buffer:c_ptr(evbuffer);
    var response:ClientResponse=nil;

    var formEncoded=true;
    var urlGetparams:string;



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
        this._headers = evhttp_request_get_output_headers(this.req);
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
        this.headers[header_name]=header_value;
    }
    

    proc OnResponse(req:c_ptr(evhttp_request),buffer:c_ptr(evbuffer)){
        if(this.response==nil){
            this.response = new ClientResponse();
        }

        this.response._setClient(this.client);
        this.response(req,buffer);
    }
    
    //Sends the requests and returns the response object
    proc this():ClientResponse throws{
        this.formEncoded=false;
        try! this.Send();
        return this.response;
    }
    //Sends the requests and returns the response object
    proc this(b:bool):ClientResponse throws{
        this.formEncoded=bool;
       try! this.Send();
        return this.response;
    }


//Sends object as Json and returns the response object
    proc this(obj:?eltType, b:bool=false):ClientResponse throws{
        this.formEncoded=b;
        this.Write(obj);  
        this.Send();
        return this.response;
    } 

    proc Write(str ...?vparams) throws{
     for param el in 1..vparams{     
         if(!isArray(el)){
             this._print(str[el]);
         }else{
             this._printArr(str[el]);
         }
    }
  }

  proc _printArr(str:[?D]?eltType) throws{
        if(!this.formEncoded){
            try{
                var jsonstr:string = "%jt".format(str);
                evbuffer_add_printf(this.buffer, "%s".localize().c_str(), jsonstr.localize().c_str());
            }catch{
                throw new ChrestJsonError();
            }
       
       }else{
            //Encode form
            var formStr:string;
            formStr=Utils.ArrayToUrlEncode(str);
            evbuffer_add_printf(this.buffer, "%s".localize().c_str(), formStr.localize().c_str());
        }
  } 
  
  proc _print(str:?eltType) throws{
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
          if(!this.formEncoded){
            try{
                var jsonstr:string = "%jt".format(str);
                 
                evbuffer_add_printf(this.buffer, "%s".localize().c_str(), jsonstr.localize().c_str());
            }catch{
                
                throw new ChrestJsonError();
            }
       
       }else{
            //Encode form
            var formStr:string;
            if(isArray(str)){
                
                formStr=Utils.ArrayToUrlEncode(str);

                if(this.verb=="GET"){
                    this.urlGetparams=formStr;
                    return;
                }

                 

            }else{
                var obj = str; 
                var objArr = Utils.objToArray(obj);
                formStr=Utils.ArrayToUrlEncode(objArr);
                if(this.verb=="GET"){
                    this.urlGetparams=formStr;
                    return;
                }
                
            }
            
            evbuffer_add_printf(this.buffer, "%s".localize().c_str(), formStr.localize().c_str());
        }

      }
    }
  }

    proc Send() throws{
        this.AddHeader( "Host", this.client.host);
        this.AddHeader( "Connection", "close");
        this.AddHeader( "Accept","*/*"); 	
        this.AddHeader( "User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36 ChrestClient/0.0.1"); 	
        if(this.formEncoded){
            this.AddHeader( "Content-Type","application/x-www-form-urlencoded");
        }
        for header_name in this.headersDom{
            var header_value = this.headers[header_name];
            evhttp_add_header(this._headers, header_name.localize().c_str(), header_value.localize().c_str());            
        }
        var path= this.path;
        if(this.verb=="GET"&& this.urlGetparams!=""){
           path+= "?"+this.urlGetparams;
        }
        var errCode = evhttp_make_request(this.client.con, this.req, this.verbToConstant(this.verb), path.localize().c_str());
        if(errCode<0){
            throw new  ChrestRequestError(path);
        }
        this.client.Dispatch();
    }
    
    proc getResponse():ClientRequest{
        return this.response;
    }

}



class ChrestClient{
   // var cookieDom:domain(string); // if I declare any associative array here, it triggers error 
   // var cookies:[cookieDom]string;
    
    var ebase : c_ptr(event_base);   
    var host:string;
    var port:int=80;
    var con:c_ptr(evhttp_connection);

    var allow_response_headers:[{1..0}]string;
    
    

    var formEncoded=false;

    proc ChrestClient(host:string, port:int){
        this.host = host;
        this.port = port;
        this.ebase = event_base_new();
        this.con = evhttp_connection_base_new(this.ebase, c_nil, this.host.localize().c_str(), this.port:c_ushort);
       
        this.allowReadResponseHeaders("Content-Length");
        this.allowReadResponseHeaders("Access-Control-Allow-Origin");
        this.allowReadResponseHeaders("Access-Control-Allow-Credentials");
        this.allowReadResponseHeaders("Access-Control-Expose-Headers");
        this.allowReadResponseHeaders("Access-Control-Max-Age");
        this.allowReadResponseHeaders("Access-Control-Allow-Methods");
        this.allowReadResponseHeaders("Access-Control-Allow-Headers");
        this.allowReadResponseHeaders("Accept-Patch");
        this.allowReadResponseHeaders("Accept-Ranges");
        this.allowReadResponseHeaders("Age");
        this.allowReadResponseHeaders("Allow");
        this.allowReadResponseHeaders("Alt-Svc");
        this.allowReadResponseHeaders("Cache-Control");
        this.allowReadResponseHeaders("Connection");
        this.allowReadResponseHeaders("Content-Disposition");
        this.allowReadResponseHeaders("Content-Encoding");
        this.allowReadResponseHeaders("Content-Language");
        this.allowReadResponseHeaders("Content-Length");
        this.allowReadResponseHeaders("Content-Location");
        this.allowReadResponseHeaders("Content-MD5");
        this.allowReadResponseHeaders("Content-Range");
        this.allowReadResponseHeaders("Content-Type");
        this.allowReadResponseHeaders("Date");
        this.allowReadResponseHeaders("ETag");
        this.allowReadResponseHeaders("Expires");
        this.allowReadResponseHeaders("Last-Modified");
        this.allowReadResponseHeaders("Link");
        this.allowReadResponseHeaders("Location");
        this.allowReadResponseHeaders("P3P");
        this.allowReadResponseHeaders("Pragma");
        this.allowReadResponseHeaders("Proxy-Authenticate");
        this.allowReadResponseHeaders("Public-Key-Pins");
        this.allowReadResponseHeaders("Retry-After");
        this.allowReadResponseHeaders("Server");
        this.allowReadResponseHeaders("Set-Cookie");
        this.allowReadResponseHeaders("Strict-Transport-Security");
        this.allowReadResponseHeaders("Trailer");
        this.allowReadResponseHeaders("Transfer-Encoding");
        this.allowReadResponseHeaders("Tk");
        this.allowReadResponseHeaders("Upgrade");
        this.allowReadResponseHeaders("Vary");
        this.allowReadResponseHeaders("Via");
        this.allowReadResponseHeaders("Warning");
        this.allowReadResponseHeaders("WWW-Authenticate");
        this.allowReadResponseHeaders("X-Frame-Options");
    }

    proc setFormEncoded(b:bool){
        this.formEncoded=b;
    }


    proc allowReadResponseHeaders(header:string){
        this.allow_response_headers.push_back(header);
    }

    // make GET call using custom request data
    proc Get(path:string, req:ClientRequest) throws{
        var req:ClientRequest;
        if(req==nil){
         req = new ClientRequest(this,"GET",path);
        }
        req.configure(this,"GET",path);
        var res =  req(this.formEncoded);
        return res;
        
    }

    proc Get(path:string) throws{
        var req = new ClientRequest(this,"GET",path);

        var res=req();

       // this.getResponseCookie(res);
               
        return res;
    }

    // makes Post call send obj as json
    proc Get(path:string, obj, _req:ClientRequest=nil) throws {
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"GET",path);
        }else{
            req= _req;
        }
        req.configure(this,"GET",path);
        var res = req(obj, true);
        return res;
    }
    proc Post(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"POST",path);
        }else{
            req= _req;
        }
        req.configure(this,"POST",path);
        var res =  req( this.formEncoded);
        return res;
    }
    // makes Post call send obj as json
    proc Post(path:string, obj, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"POST",path);
        }else{
            req= _req;
        }
        req.configure(this,"POST",path);
        var res =  req(obj, this.formEncoded);
        return res;
    }

    proc Post(path:string) throws{
        var req = new ClientRequest(this,"POST",path);
        return req();
    }
    proc Put(path:string) throws{
        var req = new ClientRequest(this,"PUT",path);
        return req();
    }
    proc Put(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PUT",path);
        }else{
            req= _req;
        }
        req.configure(this,"PUT",path);
        var res =  req( this.formEncoded);
        return res;
    }
     // makes Put call send obj as json
    proc Put(path:string, obj:?eltType, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PUT",path);
        }else{
            req= _req;
        }
        req.configure(this,"PUT",path);
        var res = req(obj, this.formEncoded);
        return res;
    }
    proc Delete(path:string) throws{
        var req = new ClientRequest(this,"DELETE",path);
        return req();
    }
    proc Delete(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"DELETE",path);
        }else{
            req= _req;
        }
        req.configure(this,"DELETE",path);
        var res =  req( this.formEncoded);
        return res;
    }
     // makes Delete call send obj as json
    proc Delete(path:string, obj:?eltType, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"DELETE",path);
        }else{
            req= _req;
        }
        req.configure(this,"DELETE",path);
        var res = req(obj, this.formEncoded);
        return res;
    }
    proc Connect(path:string) throws{
        var req = new ClientRequest(this,"CONNECT",path);
        return req();
    }
    proc Connect(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"CONNECT",path);
        }else{
            req= _req;
        }
        req.configure(this,"CONNECT",path);
        var res =  req( this.formEncoded);
        return res;
    }
     // makes Connect call send obj as json
    proc Connect(path:string, obj:?eltType, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"CONNECT",path);
        }else{
            req= _req;
        }
        req.configure(this,"CONNECT",path);
        var res =  req(obj, this.formEncoded);
        return res;
    }
    proc Options(path:string) throws{
        var req = new ClientRequest(this,"OPTIONS",path);
        return req();
    }
    proc Options(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"OPTIONS",path);
        }else{
            req= _req;
        }
        req.configure(this,"OPTIONS",path);
        var res =  req( this.formEncoded);
        return res;
    }
     // makes Options call send obj as json
    proc Options(path:string, obj:?eltType, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"OPTIONS",path);
        }else{
            req= _req;
        }
        req.configure(this,"OPTIONS",path);
        var res = try!  req(obj, this.formEncoded);
        return res;
    }
    proc Trace(path:string) throws{
        var req = new ClientRequest(this,"TRACE",path);
        return req();
    }
    proc Trace(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"TRACE",path);
        }else{
            req= _req;
        }
        req.configure(this,"TRACE",path);
        var res =  req( this.formEncoded);
        return res;
    }
     // makes Trace call send obj as json
    proc Trace(path:string, obj:?eltType, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"TRACE",path);
        }else{
            req= _req;
        }
        req.configure(this,"TRACE",path);
        var res = try!  req(obj, this.formEncoded);
        return res;
    }
    proc Head(path:string) throws{
        var req = new ClientRequest(this,"HEAD",path);
        return req();
    }
    proc Head(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"HEAD",path);
        }else{
            req= _req;
        }
        req.configure(this,"HEAD",path);
        var res =  req( this.formEncoded);
        return res;
    }
     // makes Head call send obj as json
    proc Head(path:string, obj:?eltType, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"HEAD",path);
        }else{
            req= _req;
        }
        req.configure(this,"HEAD",path);
        var res =  req(obj, this.formEncoded);
        return res;
    }
    proc Patch(path:string) throws{
        var req = new ClientRequest(this,"PATCH",path);
        return req();
    }
    proc Patch(path:string, _req:ClientRequest) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PATCH",path);
        }else{
            req= _req;
        }
        req.configure(this,"PATCH",path);
        var res =  req( this.formEncoded);
        return res;
    }
     // makes Patch call send obj as json
    proc Patch(path:string, obj:?eltType, _req:ClientRequest=nil) throws{
        var req:ClientRequest;
        if(_req==nil){
         req = new ClientRequest(this,"PATCH",path);
        }else{
            req= _req;
        }
        req.configure(this,"PATCH",path);
        var res =  req(obj, this.formEncoded);
        return res;
    }

   
   proc Dispatch(){
        event_base_dispatch(this.ebase);
    }

   /* proc getResponseCookie(ref res:ClientResponse){
        var str = res.getHeader("Set-Cookie");
        writeln("Got cookie",str);

        var parts = str.split("; ");
            for part in parts{
                var kv = part.split("=");
                writeln(kv.length);
                var i=0;
                for x in kv{
                    i+=1;
                }
                if( i>=2){
                    this.cookies[kv[1]]=kv[2];
                }
            }
    }*/

    
 }



   




    module Utils{
        proc getPath(req: c_ptr(evhttp_request)):string{
            var uri_str = evhttp_request_get_uri(req);
            var uri = evhttp_uri_parse(uri_str);
             var path = new string(evhttp_uri_get_path(uri):c_string);
            return path;
            
        }
        proc objToArray(ref el:?eltType){

        var cols_dim:domain(string);
        var cols:[cols_dim]string;

            for param i in 1..numFields(eltType) {
            var fname = getFieldName(eltType,i);
            var value = getFieldRef(el, i);// =  row[fname];
            cols[fname:string] = value:string;
            }

            return cols;
    }

    proc ArrayToUrlEncode(A:[?D]?eltType):string{
        var i=0;
        var prefix="";
        var params="";
        for key in D{
            if(i>0){
                prefix="&";
            }
            var ukey:string = new string(evhttp_uriencode(key.localize().c_str(),key.length:c_int,1:c_int));
            var value = A[key];
            var uvalue:string = new string(evhttp_uriencode(value.localize().c_str(),value.length:c_int,1:c_int));
            params += prefix+ukey+"="+uvalue; 
            i+=1;
        }

        return params;
    }

    }//subodule


}