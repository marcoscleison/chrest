
// This client serializes an chapel Object and send it as Json to the server
module Main{
use ChrestClient;

use  DateTime;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;
      
//This class is the model data to be sent to the server

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

    proc main(){
 
 
        try{
        // Creates a Client access point

            var cli = new ChrestClient(API_HOST, API_PORT);

            var res = cli.Get("/"); //Makes the request

            var response_content = res(); //Gets response as text

            var my_response:IndexResponse = res(IndexResponse); // Gets the json response and serializes in an object
       
            writeln("Response content = ",response_content);
            writeln("msg = ", my_response.msg,"  n = ",my_response.n,"v = ",my_response.v);      
            
        }catch e:ChrestConnectionError{
            writeln(e);
            
        }catch{
            writeln("Some Error");
            halt(-1);
        }
    }
}