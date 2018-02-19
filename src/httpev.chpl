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
module httpev
{
  use SysCTypes;
  require "event2/buffer.h";
  require "event2/event.h", "-levent";
  require "event2/http.h";
  require "event2/keyvalq_struct.h";
  require "event2/util.h";
  require "stdio.h";
  

  extern "struct event_base" record event_base{};
  extern "struct evhttp" record evhttp{};
  extern "struct evhttp_connection" record evhttp_connection{}
  extern "struct evdns_base" record evdns_base{}

  extern "struct evbuffer" record evbuffer{};
  extern "struct evkeyvalq" record evkeyvalq{

  };
  extern "struct evhttp_request" record evhttp_request
  {
    var output_headers : c_ptr(evkeyvalq);
  };
  extern "struct evhttp_uri" record evhttp_uri{};
  

  extern proc event_base_new() : c_ptr(event_base);
  extern proc evhttp_new(base) : c_ptr(evhttp);
  extern proc evhttp_set_allowed_methods(http, method);
  extern proc evhttp_set_cb(server
                            : c_ptr(evhttp), str
                            : c_string, fn
                            : c_fn_ptr, args
                            : c_void_ptr);
  extern proc evhttp_set_gencb(http, cb, arg);
  extern proc evhttp_bind_socket(server, str
                                 : c_string, port) : c_int;
  extern proc event_base_dispatch(ebase);
  extern proc evhttp_free(server);
  extern proc event_base_free(ebase);
  extern proc evbuffer_new() : c_ptr(evbuffer);
  extern proc evbuffer_free(buf
                            : c_ptr(evbuffer)) : c_void_ptr;
extern proc	evbuffer_add_printf (buf:c_ptr(evbuffer), fmt:c_string, vals...?numvals):c_int;
extern proc evbuffer_add_printf(buf
                                : c_ptr(evbuffer), fmt
                                : c_string) : c_int;
extern proc evhttp_send_reply(req, code
                              : int, reason
                              : c_string, databuf
                              : c_ptr(evbuffer)) : void;
extern proc evhttp_request_get_input_headers(req
                                             : c_ptr(evhttp_request)) : c_ptr(evkeyvalq);
extern proc evhttp_request_get_response_code(req: c_ptr(evhttp_request));
extern proc evhttp_find_header(const headers
                               : c_ptr(evkeyvalq), key
                               : c_string) : c_string;
extern proc evhttp_find_header(const ref headers
                               : evkeyvalq, key
                               : c_string) : c_string;
extern proc evhttp_add_header(headers
                              : c_ptr(evkeyvalq), key
                              : c_string, value
                              : c_string) : c_int;
extern proc evhttp_add_header(ref headers
                              : evkeyvalq, key
                              : c_string, value
                              : c_string) : c_int;
extern proc evhttp_request_get_output_headers(req
                                              : c_ptr(evhttp_request)) : c_ptr(evkeyvalq);

extern proc evhttp_request_get_command(const req
                                       : c_ptr(evhttp_request)) : c_int;
extern proc evhttp_request_get_input_buffer(req: c_ptr(evhttp_request)) : c_ptr(evbuffer);
extern proc evhttp_request_get_output_buffer(req: c_ptr(evhttp_request)) : c_ptr(evbuffer);
extern proc evbuffer_copyout(buf
                             : c_ptr(evbuffer), data_out
                             : c_ptr(uint(8)), datlen
                             : int) : int;
extern proc evbuffer_get_length(const buf
                                : c_ptr(evbuffer)) : int;
extern proc evhttp_parse_query_str(uri
                                   : c_string, ref headers
                                   : evkeyvalq) : c_int;
extern proc evhttp_request_get_uri(const req
                                   : c_ptr(evhttp_request)) : c_string;
extern proc evhttp_uri_parse_with_flags(source_uri
                                        : c_string, flags) : c_ptr(evhttp_uri);

extern proc evhttp_uri_parse(source_uri: c_string) : c_ptr(evhttp_uri);
extern proc evhttp_uri_get_path(uri
                                : c_ptr(evhttp_uri)) : c_string;
extern proc evhttp_uri_get_query(const uri
                                 : c_ptr(evhttp_uri)) : c_string;

extern proc  evhttp_uri_get_host(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_get_port(uri: c_ptr(evhttp_uri ) ):c_int;
//extern proc  evhttp_uri_get_path(uri: c_ptr(evhttp_uri ) ):c_string;
//extern proc  evhttp_uri_get_query(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_get_fragment(uri: c_ptr(evhttp_uri ) ):c_string;

extern proc  evhttp_uriencode (str:c_string, size, space_to_plus):c_string;


//extern proc   evbuffer_free(buffer:c_ptr(evbuffer));


//Main entry point for requests callback

//Some HTTP verbs
const EVHTTP_REQ_GET : int(32) = 1 << 0;
const EVHTTP_REQ_POST : int(32) = 1 << 1;
const EVHTTP_REQ_HEAD : int(32) = 1 << 2;
const EVHTTP_REQ_PUT : int(32) = 1 << 3;
const EVHTTP_REQ_DELETE : int(32) = 1 << 4;
const EVHTTP_REQ_OPTIONS : int(32) = 1 << 5;
const EVHTTP_REQ_TRACE : int(32) = 1 << 6;
const EVHTTP_REQ_CONNECT : int(32) = 1 << 7;
const EVHTTP_REQ_PATCH : int(32) = 1 << 8;
extern const HTTP_OK : int;


type uint16_t = c_ushort;



extern proc  event_init():c_ptr(event_base);
extern proc  event_dispatch():c_int;
extern proc  evhttp_start( address: c_string, port: uint16_t ):c_ptr(evhttp);
extern proc evhttp_connection_get_base( evcon:c_ptr(evhttp_connection),address:c_ptr(c_ptr(c_char)), port:c_ptr(c_short));

extern proc evhttp_connection_base_new( base:c_ptr(event_base),  dnsbase, address:c_string, port:c_ushort):c_ptr(evhttp_connection);

//extern proc	evhttp_request_get_input_buffer (req:c_ptr(evhttp_request)):c_ptr(evbuffer);

 extern proc evhttp_request_new (cb:c_fn_ptr, arg:c_void_ptr):c_ptr(evhttp_request);

 extern proc 	evhttp_make_request (evcon:c_ptr(evhttp_connection),req:c_ptr(evhttp_request), _type:c_short, uri:c_string):c_int;

extern proc  evbuffer_add_buffer(buffer, srcBuffer):c_int;
//extern proc  evhttp_set_gencb(http:c_ptr(evhttp), cb:c_fn_ptr , arg: c_void_ptr ):c_void_ptr;
/*
extern proc  evbuffer_new():c_ptr(evbuffer );
extern proc  evbuffer_free(buf: c_ptr(evbuffer ) ):c_void_ptr;

extern proc  evbuffer_add_printf(buf: c_ptr(evbuffer), fmt: c_string ):c_int;
extern proc  evhttp_send_reply(req:c_ptr(evhttp_request),code: c_int, reason: c_string, databuf: c_ptr(evbuffer ) ):c_void_ptr;

extern proc  evhttp_request_get_uri(req: c_ptr(evhttp_request ) ):c_string;
//extern proc  evhttp_uri_parse_with_flags( evhttp_uri: evhttp_uri, source_uri: c_string, flags: c_uint ):c_ptr(evhttp_uri );
extern proc  evhttp_uri_set_flags(flags: c_uint ):c_void_ptr;
extern proc  evhttp_uri_get_scheme(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_get_userinfo(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_get_host(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_get_port(uri: c_ptr(evhttp_uri ) ):c_int;
extern proc  evhttp_uri_get_path(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_get_query(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_get_fragment(uri: c_ptr(evhttp_uri ) ):c_string;
extern proc  evhttp_uri_set_scheme(scheme: c_string ):c_int;
extern proc  evhttp_uri_set_userinfo(userinfo: c_string ):c_int;
extern proc  evhttp_uri_set_host(host: c_string ):c_int;
extern proc  evhttp_uri_set_port(port: c_int ):c_int;
extern proc  evhttp_uri_set_path(path: c_string ):c_int;
extern proc  evhttp_uri_set_query(query: c_string ):c_int;
extern proc  evhttp_uri_set_fragment(fragment: c_string ):c_int;
*/

}