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


proc main(){
   
     //Open websockt in the port 8000
    var ws = new ChrestWebsocketServer(WS_PORT);
    
    //begin LongJobExample(); // Do a big job and send data to the queue of the channel 
    ws.Listen(); //this is running

    //Closes websockt server
    ws.Close();
    //Closes http server
    writeln("Fim");
}

proc LongJobExample(){
    var i:real=0;
		while(true){
			
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