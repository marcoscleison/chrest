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
module ChrestMiddlewares{

    use IO.FormattedIO;

    use IO;
    use FileSystem;
    use Path;

    use Chrest;
    use ChrestRouter;
    use ChrestRequestResponse;

    use ChrestSession;
    use ChrestUtils;

    class ChrestMiddleware{
        proc handle(ref req:Request, ref res:Response):bool{  
           writeln("Middleware:");          
            return true;
        }
    }

    class ChrestMiddlewareInterface{
        forwarding var middleware:ChrestMiddleware;
    }

  class ChestMemSessionMiddleware:ChrestMiddleware{
      var cookie_name:string;
      var sessionDom:domain(string);
      var session:[sessionDom]SessionInterface;
  
    proc ChestMemSessionMiddleware(cookie_name:string ="SessionID"){
      this.cookie_name = cookie_name;
      //this.sessType = sessType;
    }
     proc handle(ref req:Request, ref res:Response):bool{
          //var id = randomString(12);
          //writeln("SessionID:"+id);
          var id = req.Cookie(this.cookie_name);
          writeln("Cookie id:",id);
          if(id==""){
            writeln("Session not found");
            var sess =  this.newSession();
            res.SetCookie(this.cookie_name, sess.getID());
            req.setSession(sess);
            return true;
          }
          if(sessionDom.member(id)){
            var sess = this.session[id];
            req.setSession(sess);
          }else{
            writeln("Session id not found");
            var sess =  this.newSession();
            res.SetCookie(this.cookie_name, sess.getID());
            req.setSession(sess);
          }
          
          return true;
      }

      proc newSession(key:string=""){
        var sesst = new MemorySession();
        var sess = new SessionInterface(sesst);
        if(key==""){  
          this.session[sess.getID()]=sess;
          return sess;
        }
        sess.setID(key);
        this.session[sess.getID()]=sess;
        return sess;
      }

     proc getSession(key:string=nil):SessionInterface{
        if(sessionDom.member(key)){
            return this.session[key];
        }
        return nil;
    }

  }

}