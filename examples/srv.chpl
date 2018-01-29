module Main{
    use ChrestRouter;
    use Chrest;

    class HelloController:ChrestController{
        proc Get(ref req:Request,ref res:Response){

            res.Write("Hello world");
            res.Send(); 
        }
    }

    class TestController:ChrestController{
        proc Get(ref req:Request,ref res:Response){

            res.Write("teste controller");
            res.Send(); 
        }
    }

    proc main(){
        var srv = new Chrest("127.0.0.1",8080);
        srv.Routes().Get("/",new HelloController());
        srv.Routes().Get("/teste/:id",new TestController());
        srv.Listen();
        srv.Close();

        routerTest();
                writeln("Fim");
    }
}