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
module ChrestRequestResponse{

use Chrest;
use ChrestRouter;
use httpev;
use IO.FormattedIO;

use IO;
use FileSystem;
use Path;
    

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

        var bodyData:string;

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
            if(this.getCommand()=="DELETE"){
                this.ParseBody();
            }
            if(this.getCommand()=="CONNECT"){
                this.ParseBody();
            }
            if(this.getCommand()=="HEAD"){
                this.ParseBody();
            }
            if(this.getCommand()=="OPTIONS"){
                this.ParseBody();
            }
            if(this.getCommand()=="TRACE"){
                this.ParseBody();
            }
            if(this.getCommand()=="PATCH"){
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
        
        this.bodyData = dados;

        evhttp_parse_query_str(dados.localize().c_str(), this.params);
    }

    proc InputJson(ref obj:?eltType){
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
var issent:bool;

  proc Response(request:c_ptr(evhttp_request),  privParams:c_void_ptr){
    this.issent=false;
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
    this.issent=true;
    //evhttp_clear_headers(&headers);
    //evbuffer_free(this.buffer);
  }
  proc isSent():bool{
      return this.issent;
  }

proc SendJson(obj:?eltType,code:int=HTTP_OK,motiv:string="OK"){
        
        try{
            this.AddHeader("X-Powered-By","Chrest Framework");
            this.AddHeader("Content-Type","application/json");
            var jsonstr:string = "%jt".format(obj);
            this.Write(jsonstr);
            //evhttp_send_reply(this.handle, code, motiv.localize().c_str(), this.buffer);
        }catch{
            this.E500();
        }
}

  /*
  Error msg
  */
  proc E404(str:string="Not Found"){
    this.Write(str);
    this.Send(404,str);
  }
  proc E500(str:string="Cannot process data"){
    this.Write(str);
    this.Send(500,str);
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

}