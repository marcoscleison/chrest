use Chrest,
    ChrestRouter;

config const API_HOST: string,
             API_PORT: int;


class IndexResponse {
  var msg: string;
  //proc IndexResponse(msg: string) {
  proc IndexResponse(msg: string) {
    this.msg = "I am the default message";
  }

}
/*
 */
class IndexController:ChrestController {
  proc Get(ref req:Request,ref res:Response) {
    var r = new IndexResponse(msg = "Don't be Chrest Fallen! I'm here!");
    res.SendJson(r);
  }
}

proc main() {
  writeln("\n===== MAIN!! =====");
  var srv = new Chrest(API_HOST, API_PORT);
  var indexController = new IndexController();
  srv.Routes().Get("/", indexController);

  writeln("\t...starting server on host:port ", API_HOST, ":", API_PORT);
  srv.Listen();
  srv.Close();
}