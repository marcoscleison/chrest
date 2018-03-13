module Main{

use Chrest;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;

    

class MyController:ChrestController{
    // process Get requests
    proc Get(ref req:Request, ref res:Response){

        res.Write("Oi mundo");

        res.SetCookie("name","marcos-cleison","/");
        
    }
    //process Post Requests
    proc Post(ref req:Request,ref res:Response){
    
        
        return;
    } 
    
     
}


proc main(){
    //Creates the server
    var srv = new Chrest(API_HOST,API_PORT);
    //Creates an instance of controller
    var controller = new MyController();
    //Register routes to controller instance
    srv.Routes().Post("/",controller);
    srv.Routes().Get("/",controller);
    
    
    srv.Routes().setServeFiles(true); // allows to serve file
    srv.Routes().setFilePath("www"); // Configure folder where the static assets re.

  

    srv.Listen();//Loop
    srv.Close();//Close all

}



}