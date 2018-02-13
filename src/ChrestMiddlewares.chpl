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


    class ChrestMiddleware{
        proc handle(ref req:Request, ref res:Response):bool{
            
            return true;
        }
    }
    class ChrestMiddlewareInterface{
        forwarding var middleware:ChrestMiddleware;
    }

    class FileMiddleware:ChrestMiddleware{

        var ROOT_PATH:string;
        var public_dir:string;
        proc FileMiddleware(public_dir:string="public"){

        var err: syserr = ENOERR;

        var cwds:string =".";
    
      try{
       // cwds =locale.cwd(err);
        if err != ENOERR then ioerror(err, "in Opening Current Server Public Path.");

      }catch{
        writeln("Cannot to open path");
      }
        

        this.ROOT_PATH = cwds+"/"+public_dir;
        this.public_dir = public_dir;
    }
    proc handle(ref req:Request, ref res:Response):bool{


    
      if(req.getCommand()=="GET"){
         
        return !this.processFile(req,res);
      }

      return true;
    }

    proc processFile(ref req:Request, ref res:Response){

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
    }

    proc GetLoadableFileName(uri:string):(bool,string){
      try{
      if(exists(this.ROOT_PATH+uri)){
        if(isDir(this.ROOT_PATH+uri)){
          if(isFile(this.ROOT_PATH+uri+"/index.html")){
            return (true,this.ROOT_PATH+uri+"/index.html");
          }else{
            return (false,"");
          }
        }else if(isFile(this.ROOT_PATH+uri)){
          return (true,this.ROOT_PATH+uri);
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
      try{
      var f = open(filepath, iomode.r,
                 hints=IOHINT_RANDOM|IOHINT_CACHED|IOHINT_PARALLEL);
      for line in f.lines() {
         content+=line;
      }
        return content;
      }catch{
        return "";
      }
      
     }

    }
}