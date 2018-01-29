/*
 * Copyright (C) 2018 Marcos Cleison Silva Santana
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
/*
 Chrest is a Chapel Rest framework.
 */
module Chrest
{

    use SysCTypes;
    use Regexp;
    use httpev;
    use ChrestRouter;
    

    var chrstServerDomain : domain(int);
    var chrstServers : [chrstServerDomain] Chrest;

    proc generic_request_handler(req
                                 : c_ptr(evhttp_request),
                                   arg
                                 : c_void_ptr)
    {
        var returnbuffer = evbuffer_new();

        // var connection = evhttp_request_get_connection(req);

        //var base = evhttp_connection_get_base(connection,);

        //const char * 	evhttp_request_get_uri (const struct evhttp_request *req)
        //struct evhttp_uri * 	evhttp_uri_parse (const char *source_uri)
        //int evhttp_uri_get_port 	( 	const struct evhttp_uri *  	uri	)
        //const char* evhttp_uri_get_host 	( 	const struct evhttp_uri *  	uri	)

        /*evbuffer_add_printf(returnbuffer, "%s", "Thanks for the request from Chapel libevent 2!".localize().c_str());
        evhttp_send_reply(req, HTTP_OK, "Client".localize().c_str(), returnbuffer);
        evbuffer_free(returnbuffer);
        begin writeln("Response 1");
        begin writeln("Response 2");
        begin writeln("Response 3");*/
        return;
    }

    proc _gloablHandler(req
                        : c_ptr(evhttp_request), arg
                        : c_void_ptr)
    {
        var host : string = Helpers.getEvRequestHost(req);
        var port : string = Helpers.getEvRequestPort(req);

        var serverkey = new string(arg:c_string);
        
        writeln("Server Key = ", arg:int);
        
        var srv_ptr:c_ptr(Chrest) = arg:c_ptr(Chrest);
        var srv : Chrest = srv_ptr.deref();
        
        /*if (chrstServerDomain.member( arg:int))
        {
            writeln(" sending request");
            var srv : Chrest = chrstServers[ arg:int];
            srv._handler(req, arg);
        }*/
          srv  = chrstServers[ arg:int];
            srv._handler(req, arg);
        return;
    }

    class Chrest
    {
        var ebase : c_ptr(event_base);
        var server : c_ptr(evhttp);
        var addr : string;
        var port : int;
        var routes : Router;
        var id:int;

        proc Chrest(addr
                    : string = "127.0.0.1", port
                    : int = 8081)
        {
            this.addr = addr;
            this.port = port;
            this.routes = new Router(this);

            ///var cb:c_fn_ptr = c_ptrTo(Handler);

            var ptr:c_ptr(Chrest) = c_ptrTo(this);

            writeln("id =", ptr:int);

            var serverkey : string = this.addr + ":" + this.port : string;
            this.ebase = event_base_new();
            this.server = evhttp_new(this.ebase);
            evhttp_set_allowed_methods(this.server, EVHTTP_REQ_GET | EVHTTP_REQ_POST | EVHTTP_REQ_CONNECT | EVHTTP_REQ_HEAD | EVHTTP_REQ_OPTIONS | EVHTTP_REQ_PUT | EVHTTP_REQ_TRACE);

            evhttp_set_gencb(this.server, c_ptrTo(_gloablHandler), ptr: c_void_ptr);


            
            chrstServers[ptr:int] = this;   

            writeln("Creating server ", serverkey);
        }

        proc Routes():Router{
            return this.routes;
        }

        proc Listen()
        {
            if (evhttp_bind_socket(this.server, this.addr.localize().c_str(), this.port) != 0)
            {
                writeln("Could not bind");
            }
        }

        proc Close()
        {
            event_base_dispatch(this.ebase);
            evhttp_free(this.server);
            event_base_free(this.ebase);
        }

        proc _handler(req
                      : c_ptr(evhttp_request), arg
                      : c_void_ptr)
        {
            this.routes.Handler(req, arg);
        }

    }

    class Request{
        var req:c_ptr(evhttp_request);
        var arg:c_void_ptr;

        var params:evkeyvalq;
        var buffer:c_ptr(evbuffer);
        var uri:c_ptr(evhttp_uri);
        var uriStr:string;
        var OutHeaders:c_ptr(evkeyvalq);

        var paramsDomain:domain(string);
        var url_params:[paramsDomain] string;
        var queriesParamsDomain:domain(string);
        var queriesParams:[queriesParamsDomain]string;
        var CookieDomain: domain(string);
        var cookies:[CookieDomain]string; 



        proc Request(req,arg,params:[?D]string){
            
            this.req = req;
            this.arg = arg;
            this.paramsDomain = D;
            this.url_params = params;
            
            

            this.buffer = evhttp_request_get_input_buffer(this.req);
            this.uriStr = new string( evhttp_request_get_uri(this.req));
            this.uri =  evhttp_uri_parse_with_flags(this.uriStr.localize().c_str(),0);
            this.OutHeaders = evhttp_request_get_input_headers(this.req);

            if(this.getCommand()=="GET"){
                this.ParseUriParams();
            }
            if(this.getCommand()=="POST"){
                this.ParseBody();
            }

            if(this.getCommand()=="PUT"){
                this.ParseBody();
            }

            var str=this.GetHeader("Cookie");
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

        }
        proc Param(key:string,default:string=""):string{
            if(paramsDomain.member(":"+key)){
                return this.url_params[":"+key];
            }
            return default;
        }

/*
Parses the uri parametrs
*/
  proc ParseUriParams(){
    var query = evhttp_uri_get_query(this.uri);
    evhttp_parse_query_str(query, this.params);
  }
/*
Parses the body of POST,PUT etc. requests
*/
    proc ParseBody(){
        var len = evbuffer_get_length(this.buffer);
        var data = c_calloc(uint(8), (len+1):size_t);
        evbuffer_copyout(this.buffer, data, len);
        var dados = new string(buff=data, length=len, size=len+1, owned=true, needToCopy=false);
        evhttp_parse_query_str(dados.localize().c_str(), this.params);
    }

    proc getUri():string{
        return this.uriStr;
    }
    proc GetHeader(header:string ):string{
        return new string(evhttp_find_header(this.OutHeaders,header.localize().c_str()));
    }
/*
Gets request parameter by name.
*/
    proc Input(key:string):string{
      return new string(evhttp_find_header(this.params, key.localize().c_str()));
    }

/*
Gets Request Command Verb.
*/
    proc getCommand():string{
        return Helpers.getEvHttpVerb(this.req);
    }

 }

class Response{
var buffer:c_ptr(evbuffer);
var handle:c_ptr(evhttp_request);
var http_code:int;
var http_msg:string;

  proc Response(request:c_ptr(evhttp_request),  privParams:c_void_ptr){
    this.handle = request;
    this.buffer = evbuffer_new();
    this.http_code=200;
  }
  /*
  
  Writes contents
  */
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
          var val = str:string;
           evbuffer_add_printf(this.buffer, "%s".localize().c_str(), val.localize().c_str());
      }
    }
  }
/*
Sends the content to the client
*/
  proc Send(code:int=HTTP_OK,motiv:string="OK"){
    this.AddHeader("X-Powered-By","Chrest Framework");
    evhttp_send_reply(this.handle, code, motiv.localize().c_str(), this.buffer);
    //evhttp_clear_headers(&headers);
    //evbuffer_free(this.buffer);
  }
  /*
  Error msg
  */
  proc E404(str:string="Not Found"){
    this.Write(str);
    this.Send(404,str);
  }

  proc isError():bool{
    return this.http_code >= 400;
  }
  /*
  
  Adds a HTTP header to response
  */
  proc AddHeader(header:string,value:string):int{     
     return evhttp_add_header(evhttp_request_get_output_headers(this.handle) ,header.localize().c_str(),value.localize().c_str()):int;
  }
/*
Sets Cookie.
TODO: Add options.
*/
  proc SetCookie(key:string, value:string, path:string ="/"){
    //Set-Cookie: sessionid=38afes7a8; httponly; Path=/
      this.AddHeader("Set-Cookie", key+"="+value+"; httponly; Path="+path);
  } 

}

    class Middleware{

    }

    class ChrestController
    {
        proc Get(ref req:Request, ref res:Response){
            writeln("Base");
            res.Send();
        }
        proc Post(ref Req:Request, ref res:Response){
            
        }
        proc Put(ref Req:Request, ref res:Response){
            
        }
        proc Delete(ref Req:Request, ref res:Response){
            
        }
        proc Head(ref Req:Request, ref res:Response){
            
        }
        proc Options(ref Req:Request, ref res:Response){
            
        }
        proc Trace(ref Req:Request, ref res:Response){
            
        }
        proc Connect(ref Req:Request, ref res:Response){
            
        }

        proc Patch(ref Req:Request, ref res:Response){
            
        }

    }

    class ChrestControllerInterface{
        forwarding var controller: ChrestController;
    }


    class MyController:ChrestController{
        
        proc Get(ref Req:Request, ref res:Response){
             
             writeln("Get recebendo");
             res.Write("Oi Mundo");

             res.Send();    
        }
    }

    class MyCon:ChrestController{
        
        proc Get(ref req:Request, ref res:Response){
             
             writeln("Get recebendo2");
             res.Write("Oi Mundo2");
             //res.Write(req.Params(":id"));

             res.Send();    
        }
    }
    /*class MyController2:ChrestController{
        
        proc Get(ref req:Request, ref res:Response){
             
             writeln("Get recebendo 2");
             res.Write("Oi Mundo controler 2");

             //res.Write(req.Params(":id"));
             res.Send();    
        }
    }*/

    proc ChrestTest()
    {

        var srv = new Chrest("127.0.0.1",8080);
        srv.Routes().Get("/",new MyController());
        srv.Routes().Get("/teste",new MyCon());
        srv.Listen();
        srv.Close();
        

         

  /*

            writeln("Is match =",route.Matched(s));

            var params = route.processUrl(s); 
            for k in params.domain{
                writeln("
                key = ",k," value = ",params[k]);
            }

            
            writeln("");
            writeln("");
            writeln("");*/
    }

    /*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++==
*/

    proc _Handler(req
                  : c_ptr(evhttp_request), arg
                  : c_void_ptr)
    {
        var returnbuffer = evbuffer_new();
        evbuffer_add_printf(returnbuffer, "%s", "Thanks for the request from Chapel libevent 2!".localize().c_str());
        evhttp_send_reply(req, HTTP_OK, "Client".localize().c_str(), returnbuffer);
        evbuffer_free(returnbuffer);
        begin writeln("H Response 1");
        begin writeln("H Response 2");
        begin writeln("H Response 3");
        return;
    }

    module Helpers
    {

        proc getEvRequestHost(req
                              : c_ptr(evhttp_request)) : string
        {
            var uri_str = evhttp_request_get_uri(req);
            var uri = evhttp_uri_parse(uri_str);
            return new string(evhttp_uri_get_host(uri));
        }
        proc getEvRequestPort(req
                              : c_ptr(evhttp_request)) : string
        {

            //const char * 	evhttp_request_get_uri (const struct evhttp_request *req)
            //struct evhttp_uri * 	evhttp_uri_parse (const char *source_uri)
            //int evhttp_uri_get_port 	( 	const struct evhttp_uri *  	uri	)
            //const char* evhttp_uri_get_host 	( 	const struct evhttp_uri *  	uri	)

            var uri_str = evhttp_request_get_uri(req);
            var s = new string(uri_str);
            writeln("uri_str = ",s);
            var uri = evhttp_uri_parse(uri_str);
            var port : int = evhttp_uri_get_port(uri) : int;
            return "" + port;
        }

        proc getEvHttpVerb(req:c_ptr(evhttp_request)):string{

            var cmd = evhttp_request_get_command (req);
            select( cmd ){
                when EVHTTP_REQ_GET do return "GET";
                when EVHTTP_REQ_POST do return "POST";
                when EVHTTP_REQ_PUT do return "PUT";
                when EVHTTP_REQ_HEAD do return "HEAD";
                when EVHTTP_REQ_OPTIONS do return "OPTIONS";
                when EVHTTP_REQ_TRACE do return "TRACE";
                when EVHTTP_REQ_CONNECT do return "CONNECT";
                when EVHTTP_REQ_PATCH do return "PATCH";     
                otherwise {
                    return "UNKNOWN";
                }
            
            }
        }
    }
}