module Main{
use Regexp;
use Chrest;
use ChrestUtils;
use ChrestSession;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;


class MyController:ChrestController{
    // process Get requests
   proc Get(ref req:Request, ref res:Response){
       try!{
       var str = randomString(12);

        if(req.Session().Get("Logged")!="true"){
            //res.Write("Oi você não está logado:"+str);
            res.Redirect("/");
            return;
        }else{
            res.Write("Oi você está logado:",req.Session().getID());

            return;
        }
        
       
       }
    }
    //process Post Requests
    proc Post(ref req:Request,ref res:Response){

        var login = req.Input("login");
        var password = req.Input("password"); 

        if((login=="test") && (password=="password")){
            
            req.Session().Put("Logged","true");
            res.Redirect("/test");

        }

        return;
    } 
    
     
}



class MyController2:ChrestController{
    // process Get requests
   proc Get(ref req:Request, ref res:Response){

       var str = randomString(12);

        res.Write("Oi index:"+str," idx = ",req.Param("id"));
        
    }
   
    
     
}



proc main(){
    //Creates the server
    var srv = new Chrest(API_HOST,API_PORT);
    //Creates an instance of controller
    var controller = new MyController();
    var controller2 = new MyController2();
    //Register routes to controller instance
    srv.Routes().Post("/login",controller);
    srv.Routes().Get("/test",controller);
    srv.Routes().Get("/info/:id",controller2);
    // Register the session Middleware with Memory session management
    srv.Routes().Middleware(new ChestMemSessionMiddleware());
        
    srv.Routes().setServeFiles(true); // allows to serve file
    srv.Routes().setFilePath("www"); // Configure folder where the static assets re.

  

    srv.Listen();//Loop
    srv.Close();//Close all

}



}