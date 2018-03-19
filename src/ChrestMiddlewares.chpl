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
    proc ChestMemSessionMiddleware(){
     
    }
     proc handle(ref req:Request, ref res:Response):bool{
          //var id = randomString(12);
          //writeln("SessionID:"+id);
          var id = req.Cookie("SessionID");

          if(id==""){
            writeln("Session not found");
            return true;
          }
          writeln("Session  found:"+id);

          return true;
        }
  }

}