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

        proc Router(srv)
        {
            this.srv = srv;
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

        }

        proc Middleware(mdl:ChrestMiddleware){
            this.middlewares.push_back(new ChrestMiddlewareInterface(mdl));
        }

        proc getMiddlewares(){
           return this.middlewares;
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

        proc processGetPathPattern(path)
        {
            var found=false;
            for idx in this.getRoutesDomain{
                var route = this.getRoutes[idx];            
                if(route.Matched(path)){
                    route.CallGetController(path, this.req, this.arg);
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

        proc processPostPathPattern(path)
        {
            var found=false;
            for idx in this.postRoutesDomain{
                var route = this.postRoutes[idx];            
                if(route.Matched(path)){
                    route.CallPostController(path, this.req, this.arg);
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

        }

        proc processPutPathPattern(path)
        {
            var found=false;
            for idx in this.putRoutesDomain{
                var route = this.putRoutes[idx];            
                if(route.Matched(path)){
                    route.CallPutController(path, this.req, this.arg);
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
                    route.CallDeleteController(path, this.req, this.arg);
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

        

    }




 class RoutePattern
    {
        var route:string;
        var router:Router;
        var pattern:string;
        var r:regexp;
        var controller:ChrestControllerInterface;


        /*var req:c_ptr(evhttp_request)
        var arg:c_void_ptr;
        */
        proc RoutePattern(route:string, controller:ChrestController,router:Router){
           
            this.route = route;
            this.router = router;

            this.pattern = this.patternToRegex(this.route);
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
               // writeln("pattern ",this.pattern);
               // writeln("matching ",url[match]);
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
                
            }
            return false;

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
        //writeln("len = ",pathPart.domain.size," ",urlPart.domain.size);
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

    proc runMiddleWares(ref req:Request, ref res:Response):bool{
        var forward = true;
        for mdl in this.router.getMiddlewares(){
            forward = forward & mdl.handle(req,res);
            if(!forward){
                break;
            }
        }
        writeln("forward ",forward);
        return forward;
    }


    proc CallGetController(path:string,req:c_ptr(evhttp_request), arg:c_void_ptr){           
            var params = this.processParams(this.route,path);
            var request = new Request(req,arg,params);
            var response = new Response(req, arg);
            if(!this.runMiddleWares(request,response)){
                return;
            }

            if(this.controller!=nil){
               this.controller.Get(request,response);
            }
        
        }
                
        proc CallPostController(path:string,req:c_ptr(evhttp_request), arg:c_void_ptr){
                    
            var params = this.processParams(this.route,path);          
            var request = new Request(req,arg,params);
            var response = new Response(req, arg); 
            if(!this.runMiddleWares(request,response)){
                return;
            }

            if(this.controller!=nil){
               this.controller.Post(request,response);
            }
        
        }
        
        proc CallPutController(path:string,req:c_ptr(evhttp_request), arg:c_void_ptr){
                      
            var params = this.processParams(this.route,path);
            var request = new Request(req,arg,params);
            var response = new Response(req, arg); 
            
            if(!this.runMiddleWares(request,response)){
                return;
            }

            if(this.controller!=nil){
               this.controller.Put(request,response);
            }
        
        }
        
        proc CallDeleteController(path:string,req:c_ptr(evhttp_request), arg:c_void_ptr){
                      
            var params = this.processParams(this.route,path);
            var request = new Request(req,arg,params);
            var response = new Response(req, arg); 
            if(!this.runMiddleWares(request,response)){
                return;
            }
            
            if(this.controller!=nil){
               this.controller.Delete(request,response);
            }
        
        }
    }

/*proc Matched(rgx:string, url:string):bool{
            try{
                var match = this.r.search(url);
                var sm = url[match];
               // writeln("pattern ",this.pattern);
               // writeln("matching ",url[match]);
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
            }
            return false;

        }*/


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

            return "/".join(fragments);
        }



proc routerTest(){


    var purl="/user/:id/test";
    var rgx = patternToRegex(purl);
    
    writeln(rgx);

    var url = "/user/1/teste";

/*
    try{
            var r:regexp = compile(rgx);
            writeln(rgx);

                var match = r.search(url);
                var sm = url[match];
               // writeln("pattern ",this.pattern);
               // writeln("matching ",url[match]);
                var smm = sm + "/";
                if (smm == url)
                {

                    writeln("matched");
                  var params = processParams(purl,smm);
                                       
                  for k in  params.domain{
                      var v = params[k];
                      writeln("k = ",k,"v = ", v);
                  }
                }
                if (sm == url)
                {
                                        writeln("matched");

                  var params = processParams(purl,sm);
                  for k in  params.domain{
                      var v = params[k];
                      writeln("k = ",k,"v = ", v);
                  }

                }

    }catch{
         writeln("error");
    }
    */
}


}