module Main{
use ChrestWebsocketsClient;
use Time;
const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;



// Datapoint to be sent via websocket
record point{
	var x:real;
	var y:real;
}

    class MyDataController:WebsocketController{
        proc this(cmd:WsCliCMD){
		    writeln("Data received ", cmd.data);
	    }

    }


    proc main(){

        try{

            var cli = new ChrestWebsocketClient(API_HOST, API_PORT);     
            
            sleep(1);

            var mycontroller = new MyDataController();
            
            cli.Subscribe("data",mycontroller);
            
            var i:int=0;
            while (i<10000) {
                var p = new point(x=i,y=cos(2*3.14*i/10.0));
                 
                 cli.Publish("data",p);
                 i+=1;
            }
    }

}


/*



*/