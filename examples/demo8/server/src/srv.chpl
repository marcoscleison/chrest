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
    ws.Listen(); //this is running
    //Closes websockt server
    ws.Close();
    //Closes http server
    writeln("Fim");
}


}