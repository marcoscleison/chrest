module Main{

use Chrest;
use ChrestUtils;
const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;

    

class MyController:ChrestController{
    // process Get requests
   proc Get(ref req:Request, ref res:Response){

       var str = randomString(12);

        res.Write("Oi mundo:"+str);

        res.SetCookie("name","marcos-cleison","/");
        
    }
    //process Post Requests
    proc Post(ref req:Request,ref res:Response){

        var login = req.Input("login");
        var password = req.Input("password");

       
    
        
        return;
    } 
    
     
}


proc main(){
    //Creates the server
    var srv = new Chrest(API_HOST,API_PORT);
    //Creates an instance of controller
    var controller = new MyController();
    //Register routes to controller instance
    srv.Routes().Post("/login",controller);
    srv.Routes().Get("/test",controller);
        
    srv.Routes().setServeFiles(true); // allows to serve file
    srv.Routes().setFilePath("www"); // Configure folder where the static assets re.

  

    srv.Listen();//Loop
    srv.Close();//Close all

}



}