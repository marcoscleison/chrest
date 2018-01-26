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

        var getRoutesDomain:domain(string);

        var getRoutes:[getRoutesDomain]RoutePattern;

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

        }
        
        proc Get(uri:string, controller:ChrestController)
        {
            this.getRoutes[uri] = new RoutePattern(uri,controller);
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

    }




 class RoutePattern
    {
        var route:string;
        var pattern:string;
        var r:regexp;
        var controller:ChrestController;

        /*var req:c_ptr(evhttp_request)
        var arg:c_void_ptr;
        */
        proc RoutePattern(route:string, controller:ChrestController){
           
            this.route = route;
            this.pattern = this.patternToRegex(this.route);
            try{
                this.r = compile(this.pattern);
            }catch{
                writeln("Error to compile url pattern");
            }

            this.controller= controller;
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

            return "/".join(fragments);
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
        proc CallGetController(path:string,req:c_ptr(evhttp_request), arg:c_void_ptr){
                       
            var params = this.processParams(this.route,path);
        
            if(controller!=nil){
                var request = new Request(req,arg,params);
                var response = new Response(req, arg);
                //writeln("Calling controller");
                controller.Get(request,response);
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

proc routerTest(){


    var purl="/user/:id/:guid";
    var rgx = patternToRegex(purl);
    

    var url = "/user/1/teste";


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
}


}