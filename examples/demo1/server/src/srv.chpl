module Main{

use Chrest;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;

    class MyData{
          var X:string;
          var Y:string;
          proc MyData(){
          }
      }

       class MyResponse{
          var xResponse:string;
          var yResponse:string;
          proc MyResponse(){}

      }

class MyController:ChrestController{
    // process Get requests
    proc Get(ref req:Request, ref res:Response){
        //Reads input request data and serializes parameter into MyData Class 
        var obj = req.InputObj(MyData);
        //make some dummy processing
        var my_response =new  MyResponse();
        my_response.xResponse = "GET processed: "+obj.X;
        my_response.yResponse = "GET processed: "+obj.Y;

        // Sends MyResponse instance as json to the client
        res.SendJson(my_response);

    }
    //process Post Requests
    proc Post(ref req:Request,ref res:Response){
        var obj = req.InputObj(MyData);
        var my_response =new  MyResponse();
        my_response.xResponse = "POST processed: "+obj.X;
        my_response.yResponse = "POST processed: "+obj.Y;
        res.SendJson(my_response);

        return;
    } 
    
    proc Put(ref req:Request,ref res:Response){

        var id = req.Param("id"); // Gets parameter from URL ex. /test/:id.

        var obj = req.InputObj(MyData);
        var my_response =new  MyResponse();
        my_response.xResponse = "PUT id = "+id+": "+obj.X;
        my_response.yResponse = "POST id ="+id+": "+obj.Y;
        res.SendJson(my_response);

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
    srv.Routes().Put("/test/:id",controller);

    srv.Listen();//Loop
    srv.Close();//Close all

}



}