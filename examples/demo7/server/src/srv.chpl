module Main{
use Chrest;
use ChrestWebsockets;
use ChrestUtils;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080,
      WS_PORT: int=8000;


// Datapoint to be sent via websocket
record point{
	var x:real;
	var y:real;
}

var i:int=0;

class TestController:ChrestController {
    proc Get(ref req:Request,ref res:Response) {
        
        var p = new point(x=i,y=cos(2*3.14*i/10.0));
        
        writeln("Job Publishing data",p);
        chrestPubSubPublish("data",p); // Sends jobs to the queue of the channel "data"
		i+=1;
        LongJobExample(); // Do a big job and send data to the queue of the channel 
        
        res.SendJson(p); //returns a data
    }
  }

proc main(){
   
     //Creates the server
    var srv = new Chrest(API_HOST,API_PORT);
        
    srv.Routes().setServeFiles(true); // allows to serve file
    srv.Routes().setFilePath("www"); // Configure folder where the static assets resource.

     var controller = new TestController();
    //Register routes to controller instance
   
    srv.Routes().Get("/test",controller); // teste controller where we find a job

     //Open websockt in the port 8000
    var ws = new ChrestWebsocketServer(WS_PORT);
    // Create concurrent websooket and Chrest http loop    
    
    begin srv.Listen(); 
    ws.Listen(); //this is running

    //Closes websockt server
    ws.Close();
    //Closes http server
    srv.Close();
    writeln("Fim");
}

proc LongJobExample(){
    var i:real=0;
		while(i<1000){
			
			var p = new point(x=i/10,y=cos(2*3.14*i/10.0));

            var k=0.1;
            var x:real =0.5;
        	
            //Publishes in the "data" channel. All clientes will receive it.
            writeln("Job Publishing data",p);
            chrestPubSubPublish("data",p);
            
			i+=1;
		}

}


}