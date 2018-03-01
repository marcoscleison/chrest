module Main{

use Chrest;
use DateTime;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;

   class IndexResponse {
    var msg: string,
        n: datetime,
        v: int;
    proc IndexResponse() {}

    proc IndexResponse(msg: string, v:int, n: datetime) {
      this.msg = msg;
      this.n = n;
      this.v = v;
    }
    
  }

class IndexController:ChrestController {
    proc Get(ref req:Request,ref res:Response) {
      var r = new IndexResponse(msg="yer mama",v=71, n=datetime.now());
      res.SendJson(r);
    }
  }


proc main(){
    //Creates the server
    var srv = new Chrest(API_HOST,API_PORT);
    //Creates an instance of controller
    var controller = new IndexController();
    //Register routes to controller instance
   
    srv.Routes().Get("/",controller);
   
    srv.Listen();//Loop
    srv.Close();//Close all

}



}