module ChrestRouter{

use Regexp;


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
            this.pattern = this.convertRouterToRegex(this.route);
            try{
                this.r = compile(this.pattern);
            }catch{
                writeln("Error to compile url pattern");
            }

            this.controller= controller;
        }
        proc processUrl(url:string)
        {
           return this.extractParamFromUri(url,this.route);
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

        proc extractParamFromUri(path:string, rte:string)
        {
            var paramsDomain : domain(string);
            var params : [paramsDomain] string;
            var pfragments : [ {1..0} ] string;
            var rfragments : [ {1..0} ] string;

        for part in rte.split("/")
         {
             if (part != "")
             {
                 //writeln("Adding rte part ", part);
                 rfragments.push_back(part);
             }
         }
        var i = 1;
        var rsz : int = rfragments.domain.size;
        for part in path.split("/")
        {
            if (i <= rsz && part != "")//
            {
                if (rfragments[i].startsWith(":"))
                {
                    var tstr = rfragments[i];
                    writeln(tstr[1]);
                    params[rfragments[i]] = part;
                }
                i += 1;
            }
        }
        return params;
        }

        proc convertRouterToRegex(rte:string):string{
            var fragments:[{1..0}]string;
            var allowedParamChars:string = "[a-zA-Z0-9\\_\\-]+";
            var group:int = 1;
            try{
                for part in rte.split("/")
                {
                    if (part !="")//part != "
                    {
                        if (part.startsWith(":"))
                        {
                            
                            /*if(part.startsWith(":{")){
                                var r = compile("\\:\\{(.)+\\}(.)+");
                                //var bracket_idx = part.find();     
                                var pattr:string;
                                r.search(part,pattr);
                                fragments.push_back("(?P<"+group+">" + pattr + ")");
                            }else{
                                fragments.push_back("(?P<"+group+">" + allowedParamChars + ")");
                            }*/
                            fragments.push_back("(?P<"+group+">" + allowedParamChars + ")");

                            writeln("variable ", part);
                            
                            group+=1;
                        }else{
                            writeln("litaral ", part);
                            fragments.push_back(part);
                    }
                }
            }

                var ret:string = "\\/".join(fragments);
       // writeln("ret = ", ret);
                if(rte[1]=='/'){
                    return "\\/"+ret;
                }else{
                    return ret;
                }
                
            }catch{
                writeln("Cannot match");
                return "";
            }
            return "";
        }

        proc CallGetController(path:string,req:c_ptr(evhttp_request), arg:c_void_ptr){
            
            var params = processUrl(path);
        
            if(controller!=nil){
                var request = new Request(req,arg,params);
                var response = new Response(req, arg);
                controller.Get(request,response);
            }
        }
    }







proc processUrl(pattern:string, path:string ){

        //split the pattern
        //Replace by regex
        //match uri
        //split uri
        //compare





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
    writeln("len = ",pathPart.domain.size," ",urlPart.domain.size);
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