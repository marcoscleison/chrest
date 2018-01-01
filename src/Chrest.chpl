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
    use httpev;

    proc generic_request_handler(req
                                 : c_ptr(evhttp_request), arg
                                 : c_void_ptr)
    {
        var returnbuffer = evbuffer_new();
        evbuffer_add_printf(returnbuffer, "%s", "Thanks for the request from Chapel libevent 2!".localize().c_str());
        evhttp_send_reply(req, HTTP_OK, "Client".localize().c_str(), returnbuffer);
        evbuffer_free(returnbuffer);
        begin writeln("Response 1");
        begin writeln("Response 2");
        begin writeln("Response 3");
        return;
    }

    proc ChrestTest()
    {
     
        begin writeln("init Async");

        var ch = new Chrest();
        ch.Listen();
        ch.Close();
    }

    class Chrest
    {

        var ebase : c_ptr(event_base);
        var server : c_ptr(evhttp);
        var addr : string;
        var port : int;

        proc Chrest(addr
                    : string = "127.0.0.1", port
                    : int = 8081)
        {
            this.addr = addr;
            this.port = port;

            this.ebase = event_base_new();
            this.server = evhttp_new(this.ebase);
            evhttp_set_allowed_methods(this.server, EVHTTP_REQ_GET | EVHTTP_REQ_POST | EVHTTP_REQ_CONNECT | EVHTTP_REQ_HEAD | EVHTTP_REQ_OPTIONS | EVHTTP_REQ_PUT | EVHTTP_REQ_TRACE);
            evhttp_set_gencb(this.server, c_ptrTo(this.Handler), nil
                             : c_void_ptr);
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

        proc Handler(req
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
    }

    /*
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++==
*/
}