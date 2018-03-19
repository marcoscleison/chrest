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
module ChrestRouter{

use Chrest;
use Regexp;
use IO.FormattedIO;
use FileSystem;

    use IO;
    use FileSystem;
    use Path;



 class Router
    {

        var req:c_ptr(evhttp_request);
        var arg:c_void_ptr;

        var srv : Chrest;
        var routesDomain : domain(string);
        var routes : [routesDomain] ChrestController;

        var middlewares:[{1..0}]ChrestMiddlewareInterface;

        var getRoutesDomain:domain(string);
        var getRoutes:[getRoutesDomain]RoutePattern;

        var postRoutesDomain:domain(string);
        var postRoutes:[postRoutesDomain]RoutePattern;

        var putRoutesDomain:domain(string);
        var putRoutes:[putRoutesDomain]RoutePattern;

        var deleteRoutesDomain:domain(string);
        var deleteRoutes:[deleteRoutesDomain]RoutePattern;
        
        var connectRoutesDomain:domain(string);
        var connectRoutes:[connectRoutesDomain]RoutePattern;
        
        var headRoutesDomain:domain(string);
        var headRoutes:[headRoutesDomain]RoutePattern;
        
        var optionsRoutesDomain:domain(string);
        var optionsRoutes:[optionsRoutesDomain]RoutePattern;
        
        var traceRoutesDomain:domain(string);
        var traceRoutes:[traceRoutesDomain]RoutePattern;
        
        var patchRoutesDomain:domain(string);
        var patchRoutes:[patchRoutesDomain]RoutePattern;

        var serveFiles:bool;

        var filePath:string;

        

        proc Router(srv)
        {
            this.srv = srv;
            this.serveFiles=false;
            this.filePath="public";
        }

        proc Handler(req:c_ptr(evhttp_request), arg:c_void_ptr)
        {
            var req_url = evhttp_request_get_uri(req);
            var evuri = evhttp_uri_parse(req_url);
            var path = new string(evhttp_uri_get_path(evuri));
            var verb = Helpers.getEvHttpVerb(req);

            this.req = req;
            this.arg = arg;

            writeln("HTTP VERB = ", verb," path =",path);

            if(verb == "GET"){
                this.processGetPathPattern(path);
            }
            if(verb == "POST"){
                writeln("processing post");
                this.processPostPathPattern(path);
            }
            if(verb == "PUT"){
                this.processPutPathPattern(path);
            }
            if(verb == "DELETE"){
                this.processDeletePathPattern(path);
            }
            if(verb == "CONNECT"){
                this.processConnectPathPattern(path);
            }
            if(verb == "HEAD"){
                this.processHeadPathPattern(path);
            }
            if(verb == "OPTIONS"){
                this.processOptionsPathPattern(path);
            }
            if(verb == "TRACE"){
                this.processTracePathPattern(path);
            }
            if(verb == "PATCH"){
                this.processTracePathPattern(path);
            }

        }

        proc Middleware(mdl:ChrestMiddleware){
            this.middlewares.push_back(new ChrestMiddlewareInterface(mdl));
        }

        proc getMiddlewares(){
           return this.middlewares;
        }
        proc setServeFiles(b:bool=true){
            this.serveFiles=b;
        }
        proc setFilePath(path:string){
            this.filePath =path;
        }
        
        proc Get(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("GET: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.getRoutes[rp.getRegexPattern()] = rp;
        }
        proc Post(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("POST: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.postRoutes[rp.getRegexPattern()] = rp;
        }
        proc Put(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("PUT: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.putRoutes[rp.getRegexPattern()] = rp;
        }
        proc Delete(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("DELETE: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.deleteRoutes[rp.getRegexPattern()] = rp;
        }

        proc Connect(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("CONNECT: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.connectRoutes[rp.getRegexPattern()] = rp;
        }

        proc Head(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("HEAD: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.headRoutes[rp.getRegexPattern()] = rp;
        }
        
        proc Options(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("OPTIONS: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.optionsRoutes[rp.getRegexPattern()] = rp;
        }

        proc Trace(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("TRACE: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.traceRoutes[rp.getRegexPattern()] = rp;
        }
       
        proc Patch(uri:string, controller:ChrestController)
        {
            var rp = new RoutePattern(uri,controller,this);
            writeln("patch: Registering uri ",uri," pattern ",rp.getRegexPattern());
            this.traceRoutes[rp.getRegexPattern()] = rp;
        }

        proc processGetPathPattern(path)
        {
            var found=false;
            for idx in this.getRoutesDomain{
                var route = this.getRoutes[idx];            
                if(route.Matched(path)){
                    writeln("Mathed path =",path," idx=",idx);

                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    if(!this.runMiddleWares(request,response)){
                          found=true;
                        return;
                    }
                    route.CallGetController(path, request, response);
                    
                    found=true;
                    
                    return;
                }else{
                    writeln("Not match path=", path);

                    
                    found=false;
                }
            }
            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);

                var (found,filename) = this.GetLoadableFileName(path);
                var content = this.loadFileContent(filename);
                    
                if(!found){
                    response.E404();
                }else{
                    response.Write(content);
                    response.Send();
                }

                
                
            }

        }


 /*proc processFile(ref req:Request, ref res:Response){

      try{
       var uri= req.getUri();
        writeln("Tring to load file", uri);


       var (isloadable,filepath) = this.GetLoadableFileName(uri);
       if(isloadable==true){
         var content = this.loadFileContent(filepath);
         res.Write(content);
         res.Send();
         return true;
       }else{
         //res.E404("Url Or File Not Found");
         return false;
       }

      }catch{
        return false;
      }
      return false;
    }*/

    proc GetLoadableFileName(uri:string):(bool,string){
      try{
           var fullpath = here.cwd()+"/"+this.filePath;


      if(exists(fullpath+uri)){
        if(isDir(fullpath+uri)){
          if(isFile(fullpath+uri+"/index.html")){
            
            return (true,fullpath+uri+"/index.html");
          
          }else if(isFile(fullpath+uri+"/index.htm")){
            
            return (true,fullpath+uri+"/index.htm");
          }else{
            return (false,"");
          }

        }else if(isFile(fullpath+uri)){
          return (true,fullpath+uri);
        }else{
          return (false,"");
        }
      }else{
        return (false,"");
      }
        return (false,"");
      }catch{
        return (false,"");
      }
      return (false,"");
    }

    proc loadFileContent(filepath:string):string{
      var content:string ="";
      var fullpath = filepath;
      try{
          var o:syserr;
          //var fullpath = here.cwd()+"/"+filepath;
          writeln("Current Path=",here.cwd());
      var f = open(fullpath, iomode.r,
                 hints=IOHINT_RANDOM|IOHINT_CACHED|IOHINT_PARALLEL);
      for line in f.lines() {
         content+=line;
      }
        return content;
      }catch{
        writeln("Error on read file",fullpath);
        return "";
      }
      
     }

    



/****************************************************/



        proc processPostPathPattern(path)
        {
            var found=false;
            for idx in this.postRoutesDomain{
                var route = this.postRoutes[idx];            
                if(route.Matched(path)){

                   var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    /*if(!this.runMiddleWares(request,response)){
                        return;
                    }*/

                    route.CallPostController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("Not match path =", path);
                }
            }
            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();
                
            }

        }

        proc processPutPathPattern(path)
        {
            var found=false;
            for idx in this.putRoutesDomain{
                var route = this.putRoutes[idx];            
                if(route.Matched(path)){
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    if(!this.runMiddleWares(request,response)){
                        return;
                    }

                    route.CallPutController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("Not match path=", path);
                }
            }
            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();
                
            }

            /*writeln("Is match =",route.Matched(s));
            var params = route.processUrl(s); 
            for k in params.domain{
                writeln("key = ",k," value = ",params[k]);
            }*/
        }

        proc processDeletePathPattern(path)
        {
            var found=false;
            for idx in this.deleteRoutesDomain{
                var route = this.deleteRoutes[idx];            
                if(route.Matched(path)){
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    if(!this.runMiddleWares(request,response)){
                        return;
                    }
                    route.CallDeleteController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("Delete: Not match path=", path);
                }
            }
            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();
                
            }
        }
        proc processConnectPathPattern(path)
        {
            var found=false;
            for idx in this.connectRoutesDomain{
                var route = this.connectRoutes[idx];            
                if(route.Matched(path)){
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);

                    if(!this.runMiddleWares(request,response)){
                        return;
                    }

                    route.CallConnectController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("Connect: Not match path=", path);
                }
            }
            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();
                
            }
        }

        proc processHeadPathPattern(path)
        {
            var found=false;
            for idx in this.headRoutesDomain{
                var route = this.headRoutes[idx];            
                if(route.Matched(path)){
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    if(!this.runMiddleWares(request,response)){
                        return;
                    }
                    route.CallHeadController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("HEAD: Not match path=", path);
                }
            }
            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();
                
            }
        }

        proc processOptionsPathPattern(path)
        {
            var found=false;
            for idx in this.optionsRoutesDomain{
                var route = this.optionsRoutes[idx];            
                if(route.Matched(path)){
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    if(!this.runMiddleWares(request,response)){
                        return;
                    }
                    route.CallOptionsController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("Options: Not match path=", path);
                }
            }
            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();
                
            }
        }
        
        proc processTracePathPattern(path)
        {
            var found=false;
            
            for idx in this.traceRoutesDomain{
                var route = this.traceRoutes[idx];            
                if(route.Matched(path)){
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    if(!this.runMiddleWares(request,response)){
                        return;
                    }
                    route.CallTraceController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("Trace: Not match path=", path);
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    
                    if(!this.runMiddleWares(request,response)){
                        return;
                    }
                }
            }

            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();   
            }
        }
         proc processPatchPathPattern(path)
        {
            var found=false;
            
            for idx in this.patchRoutesDomain{
                var route = this.patchRoutes[idx];            
                if(route.Matched(path)){
                    var params = route.getUrlParams(path);
                    var request = new Request(this.req,this.arg,params);
                    var response = new Response(this.req, arg);
                    if(!this.runMiddleWares(request,response)){
                        return;
                    }
                    route.CallPatchController(path, request, response);
                    found=true;
                    break;
                }else{
                    writeln("Patch: Not match path=", path);
                }
            }

            if(!found){
                //Error controller
                var response = new Response(this.req, this.arg);
                response.E404();   
            }
        }

        proc runMiddleWares(ref req:Request, ref res:Response):bool{
        var forward = true;
        var i=0;
        for mdl in this.getMiddlewares(){
            forward = forward & mdl.handle(req,res);
            if(!forward){
                writeln("Middleware ",i," blocking the request");
                break;
            }
        }
        writeln("==================forward ",forward);
        return forward;
    }





    }//class




 class RoutePattern
    {
        var route:string;
        var router:Router;
        var pattern:string;
        var r:regexp;
        var controller:ChrestControllerInterface;
        var middlewares:[{1..0}]ChrestMiddlewareInterface;
        proc RoutePattern(route:string, controller:ChrestController,router:Router){
           
            this.route = route;
            this.router = router;

            this.pattern = "^"+this.patternToRegex(this.route);
            try{
                this.r = compile(this.pattern);
            }catch{
                writeln("Error to compile url pattern");
            }

            this.controller = new ChrestControllerInterface(controller);
        }

        proc getRegexPattern():string{
            return this.pattern;
        }

        proc patternToRegex(pattern:string):string{
            var fragments:[{1..0}]string;
            var allowedParamChars:string = "[a-zA-Z0-9\\_\\-]+";
            var group:int = 1;

            for part in pattern.split('/'){
                if(part.startsWith(":")){
                    var rgx ="(?P<"+group+">" + allowedParamChars + ")";
                    fragments.push_back(rgx);
                    group+=1;
                }else{
                    fragments.push_back(part);
                }
            }

            return "/".join(fragments)+"$";
        }

        
        proc Matched(url:string):bool{
            try{
                var match = this.r.search(url);
                var sm = url[match];

                 writeln("patthern ",this.pattern);

                 if(!this.r.match(url)){
                    writeln("Does not match ",url);
                    return false;
                }

               
                var smm = sm + "/";
                if (smm == url)
                {
                    return true;
                }

               

                if (sm == url)
                {
                    return true;
                }
                return false;
            }catch{
                writeln("Error to find url pattern");
                return false;
                
            }
            return false;

        }

        proc getUrlParams(path:string){
            return this.processParams(this.route,path);
        }

    proc processParams(url:string,path:string){

        var urlPart:[{1..0}]string;
        var pathPart:[{1..0}]string;

        var retDom:domain(string);
        var ret:[retDom]string;

        for p in url.split("/"){
            urlPart.push_back(p);
        }
        for p in path.split("/"){
            pathPart.push_back(p);
        }
       
        if(pathPart.domain.size != urlPart.domain.size){
            return ret;
        }
        var i=1;
        for idx in pathPart.domain{
            if(urlPart[i].startsWith(":")){
                ret[urlPart[i]]=pathPart[i];
            }
            i+=1;
        }
        return ret;
    }
    proc getMiddlewares(){
        return this.middlewares;
    }

    proc runMiddleWares(ref req:Request, ref res:Response):bool{
        var forward = true;
        var i=0;
        for mdl in this.getMiddlewares(){
            forward = forward & mdl.handle(req,res);
            if(!forward){
                writeln("Middleware ",i," blocking the request");
                break;
            }
        }
        writeln("==================forward ",forward);
        return forward;
    }


    proc CallGetController(path:string,ref request:Request, ref response:Response){           
            
            if(!this.runMiddleWares(request,response)){
                return;
            }

            if(this.controller!=nil){
               this.controller.Get(request,response);
            }
            if(!response.isSent()){
                response.Send();
            }
        
        }
                
        proc CallPostController(path:string,ref request:Request, ref response:Response){
                     
            /*if(!this.runMiddleWares(request,response)){
                return;
            }*/

            writeln("Calling post");

            if(this.controller!=nil){
               this.controller.Post(request,response);
            }
            //if(!response.isSent()){
                response.Send();
           // }
        
        }
        
        proc CallPutController(path:string,ref request:Request, ref response:Response){
            
            if(!this.runMiddleWares(request,response)){
                return;
            }

            if(this.controller!=nil){
               this.controller.Put(request,response);
            }
            if(!response.isSent()){
                response.Send();
            }
        
        }
        
        proc CallDeleteController(path:string,ref request:Request, ref response:Response){
                      
            
            if(!this.runMiddleWares(request,response)){
                return;
            }
            
            if(this.controller!=nil){
               this.controller.Delete(request,response);
            }
            if(!response.isSent()){
                response.Send();
            }
        
        }
       
        proc CallConnectController(path:string,ref request:Request, ref response:Response){
                      
           
            if(!this.runMiddleWares(request,response)){
                return;
            }
            
            if(this.controller!=nil){
               this.controller.Connect(request,response);
            }
            if(!response.isSent()){
                response.Send();
            }
        
        }
        proc CallHeadController(path:string,ref request:Request, ref response:Response){
                      
            
            if(!this.runMiddleWares(request,response)){
                return;
            }
            
            if(this.controller!=nil){
               this.controller.Head(request,response);
            }

            if(!response.isSent()){
                response.Send();
            }
        
        }

        proc CallOptionsController(path:string,ref request:Request, ref response:Response){
                      
            
            if(!this.runMiddleWares(request,response)){
                return;
            }
            
            if(this.controller!=nil){
               this.controller.Options(request,response);
            }
            
            if(!response.isSent()){
                response.Send();
            }
        
        }
        proc CallTraceController(path:string,ref request:Request, ref response:Response){
                      
            
            if(!this.runMiddleWares(request,response)){
                return;
            }
            if(this.controller!=nil){
               this.controller.Trace(request,response);
            }
            if(!response.isSent()){
                response.Send();
            }
        }
        proc CallPatchController(path:string,ref request:Request, ref response:Response){
            if(!this.runMiddleWares(request,response)){
                return;
            }
            if(this.controller!=nil){
               this.controller.Patch(request,response);
            }
            if(!response.isSent()){
                response.Send();
            }
        }
    }

}