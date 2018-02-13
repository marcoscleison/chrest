module Main{
    use ChrestRouter;
    use Chrest;

    class HelloController:ChrestController{
        proc Get(ref req:Request,ref res:Response){
            //This wites to the response.
            res.Write("Hello from ",req.getCommand());
         
        }
        proc Post(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }
        proc Put(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }
        proc Delete(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }
        proc Head(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }
        proc Options(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }
        proc Trace(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }
        proc Connect(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }

        proc Patch(ref req:Request, ref res:Response){
                //This wites to the response.
            res.Write("Hello from ",req.getCommand());
        }
    }

    class TestController:ChrestController{
        proc Get(ref req:Request,ref res:Response){
            res.Write("teste controller");
            //This gets the parameter id 
            res.Write(" id = ", req.Param("id"));
            res.Write(" name = ", req.Param("name"));
            
            //you do not need this; Now router do the work.
            //res.Send(); 
        }
    }

    // this is a class data
    class MyData{
        var name:string;
        var email:string;

        proc MyData(name:string, email:string){
            this.name=name;
            this.email=email;
        }
    }
    
    class JsonController:ChrestController{
        proc Get(ref req:Request,ref res:Response){
            var obj = new MyData("Marcos", "marcoscleison@m.co");
            //Sends obj as json
            
            res.SendJson(obj); 
        }

        proc Post(ref req:Request,ref res:Response){
            var obj = new MyData("", "");
            writeln("json post");
            // Gets object from client    
            obj = req.InputJson(obj);
            // Send it backs
            res.SendJson(obj); 
        }
        proc Put(ref req:Request,ref res:Response){
           var obj = new MyData("", "");
            writeln("json post");
            //Sends obj as json
            // Gets object from client  
            obj = req.InputJson(obj);
             // Send it backs
            res.SendJson(obj); 
        }

        
    }

//This is only a middleware that intercepts all Requests and write out in the terminal
    class LogMiddleware:ChrestMiddleware{

        proc handle(ref req:Request,ref res:Response):bool{

            writeln("Middleware logging verb: ",req.getCommand());

            return true;
        }

    }
// This is another middleware example which blocks Post requests
    class BlockPostMiddleware:ChrestMiddleware{

        proc handle(ref req:Request,ref res:Response):bool{
            if(req.getCommand()=="POST"){
                res.Send(403, "You cannot send post");
                return false;
            }
            return true;
        }

    }


    proc main(){

        //Open the server
        var srv = new Chrest("127.0.0.1",8080);
        
        //Creating another server in the port 8081
        var srv2 = new Chrest("127.0.0.1",8081);
        //Regiser Get urls
        
        var helloController = new HelloController();

        srv.Routes().Get("/",helloController);
        srv.Routes().Post("/",helloController);
        srv.Routes().Put("/",helloController);
        srv.Routes().Delete("/",helloController);
        srv.Routes().Head("/",helloController);
        srv.Routes().Connect("/",helloController);
        srv.Routes().Options("/",helloController);
        srv.Routes().Trace("/",helloController);
        srv.Routes().Patch("/",helloController);
        
        srv2.Routes().Get("/",helloController);
        srv2.Routes().Post("/",helloController);



        srv.Routes().Get("/teste/:id/:name",new TestController());
        // Controller
        var jsoncontroller = new JsonController();

        //Register routers
        srv.Routes().Get("/json", jsoncontroller);
        srv.Routes().Post("/json", jsoncontroller);
        srv.Routes().Put("/json", jsoncontroller);
         //Add some middleware // Optional
        srv.Routes().Middleware(new LogMiddleware());
        
        //srv.Routes().Middleware(new FileMiddleware("public")); //register file serrver




        ///srv.Routes().Middleware(new BlockPostMiddleware());

        //Listen loop in parallel
        cobegin{        
            srv.Listen();
            srv2.Listen();
        }

        writeln("closing");
        
        
        //Closes connection
        
            srv.Close();
            srv2.Close();
        
        //The end
        writeln("Fim");
    }
}