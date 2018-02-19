
// This client serializes an chapel Object and send it as Json to the server
module Main{
use ChrestClient;
const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;
      
//This class is the model data to be sent to the server

      class MyData{
          var X:string="my X data";
          var Y:string="my Y data";
          proc My(){

          }
      }

      class MyResponse{
          var xResponse:string;
          var yResponse:string;
          proc MyResponse(){}

      }

    proc main(){

        try{
        // Creates a Client access point

            var cli = new ChrestClient(API_HOST, API_PORT);
            var obj = new MyData();
        
            // GET will serialize the data as form data. It never serializes as JSON
            var res = cli.Get("/", obj); //Makes the request

            var response_content = res(); //Gets response as text

            var my_response = res(MyResponse); // Gets the json response and serializes in an object
       
            writeln("Response content = ",response_content);
            writeln("xResponse = ", my_response.xResponse,"  yResponse = ",my_response.yResponse);
        
            //POST and other verbs serializes by default to json.
            var res2 = cli.Post("/", obj);
            //Gets server response as text
            var response_content2 = res2();
            // Serializes json into MyResponse class instance
            var my_response2 = res2(MyResponse);

            writeln("Response content2 = ",response_content2);
            writeln("xResponse = ", my_response2.xResponse,"  yResponse = ",my_response2.yResponse);
       
            var res3 = cli.Put("/test/2", obj);
            //Gets server response as text
            var response_content3 = res3();
            // Serializes json into MyResponse class instance
            var my_response3 = res3(MyResponse);
    
            writeln("Response content3 = ",response_content3);
            writeln("xResponse = ", my_response3.xResponse,"  yResponse = ",my_response3.yResponse);
        }catch e:ConnectionError{
            writeln(e);
            halt(-1);
        }catch{
            writeln("Some Error");
            halt(-1);
        }
    }

}