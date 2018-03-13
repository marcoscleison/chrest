
// This client serializes an chapel Object and send it as Json to the server
module Main{
use ChrestClient;
const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;

//This class is the model data to be sent to the server


    proc main(){

        try{
        // Creates a Client access point

            var cli = new ChrestClient(API_HOST, API_PORT);
            
        
            // GET will serialize the data as form data. It never serializes as JSON
            var res = cli.Get("/"); //Makes the request
            res();

            writeln("Set-Cookie:",res.getHeader("Set-Cookie"));



           
        }catch e:ChrestConnectionError{
            writeln(e);
            
        }catch{
            writeln("Some Error");
            halt(-1);
        }
    }

}


/*



*/