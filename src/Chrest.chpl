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
    
    use IO.FormattedIO;

    use IO;
    use FileSystem;
    use Path;

    use ChrestRouter;
    use ChrestRequestResponse;
    use ChrestMiddlewares;
    use ChrestControllers;

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


            var ptr:c_ptr(Chrest) = c_ptrTo(this);

            writeln("id =", ptr:int);

            var serverkey : string = this.addr + ":" + this.port : string;
            this.ebase = event_base_new();
            this.server = evhttp_new(this.ebase);
            evhttp_set_allowed_methods(this.server, EVHTTP_REQ_GET | EVHTTP_REQ_POST | EVHTTP_REQ_CONNECT | EVHTTP_REQ_HEAD | EVHTTP_REQ_OPTIONS | EVHTTP_REQ_PUT | EVHTTP_REQ_TRACE| EVHTTP_REQ_DELETE);

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