module Main{
    use ChrestRouter;
    use Chrest;

    class HelloController:ChrestController{
        proc Get(ref req:Request,ref res:Response){
            //This wites to the response.
            res.Write("Hello world");
            //this sends the content to browser
            res.Send(); 
        }
    }

    class TestController:ChrestController{
        proc Get(ref req:Request,ref res:Response){
            res.Write("teste controller");
            //This gets the parameter id 
            res.Write(" id = ", req.Param("id"));
            res.Write(" name = ", req.Param("name"));
            
            res.Send(); 
        }
    }

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
    }

    proc main(){

        //Open the server
        var srv = new Chrest("127.0.0.1",8080);
        //Regiser Get urls
        srv.Routes().Get("/",new HelloController());
        srv.Routes().Get("/teste/:id/:name",new TestController());
        srv.Routes().Get("/json",new JsonController());
        //Listen loop
        srv.Listen();
        //Closes connection
        srv.Close();
        writeln("Fim");
    }
}