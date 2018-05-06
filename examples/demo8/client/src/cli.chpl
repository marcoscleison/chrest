module Main{
use ChrestWebsocketsClient;
use Time;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8000;



// Datapoint to be sent via websocket
record point{
	var x:real;
	var y:real;
}

    class MyDataController:WebsocketController{
        proc init(){

        }
        proc this(cmd:WsCliCMD){
		    writeln("Data received ", cmd.data);
	    }

    }


    proc main(){


            var cli = new ChrestWebsocketClient(API_HOST, API_PORT);   
            cli.Connect();  
            
            sleep(1);

            var mycontroller = new MyDataController();
            
            cli.Subscribe("data",mycontroller);
            
            var i:int=0;
            while (i<100) {
                var p = new point(x=i,y=cos(2*3.14*i/100.0));
                writeln("Simulation step ",i);
                 
                 cli.Publish("data",p);
                 i+=1;
                 sleep(1);
            }
            cli.Close();
    }

}

