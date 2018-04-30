# chrest
REST  framework for Chapel Language




# Chrest websocket

Chrest has a simple PubSub websocket server. With this server the user can publish data from server to browser using websockets.
In ther server side, Chrest has the function:
```chapel
chrestPubSubPublish(channel:string,obj:?eltType);
```
This function publishes the obj object serialized as JSON in a channel.
All websocket clients (web browsers) that is connected to the server and subscribed the channel will receive the published data as json.

Here an example:

```chapel
module Main{
use Chrest;
use ChrestWebsockets;
use ChrestUtils;
use Time;

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
   
    //Creates an HTTP server to serve html and js static files
    var srv = new Chrest(API_HOST,API_PORT);
        
    srv.Routes().setServeFiles(true); // allows to serve file
    srv.Routes().setFilePath("www"); // Configure folder where the static assets resource.

   
    //Open websockt server in the port 8000
    var ws = new ChrestWebsocketServer(WS_PORT);
    
    // Create concurrent websocket and Chrest http loop    
    begin srv.Listen(); 
    //Creates a long running process. WARNING: You should have at least avaliables 3 cores/thread processor.
    begin LongJobExample();


    ws.Listen(); //Loop over websocket connections.

    //Closes websockt server
    ws.Close();
    //Closes http server
    srv.Close();
    writeln("Fim");//The end
}

proc LongJobExample(){
    var i:real=0;

		while(true){
			//Makes some calculus.
			var p = new point(x=i/10,y=cos(2*3.14*i/10.0));

            var k=0.1;
            var x:real =0.5;
        	
            //Publishes in the "data" channel. All clientes that subscribed the "data" channel  will receive it.
            
            chrestPubSubPublish("data",p); //This is the function that publishes data into queue for each connected websocket.

            writeln("Job Publishing data",p);

            sleep(1);
			i+=1;
		}

}


}

```

In the client side, you will need to use an small Javascript code to allow the browser to connect to Chrest websocket pubsub server. Ex.:
```javascript
    <script>
      var conn = new ChrestWs("ws://localhost:8000"); //Creates a Chrest Pubsub connection  object.

      var datax = []; //These are array to store the data from server to be ploted
      var datay = [];

      //Connects to websoket server and call the callback passed as parameter when it is connected
      conn.Connect(function (ws) {
        //The parameter ws represents the connection. With this variable you can subscribe or publish data.
        
        console.log("Connected");
        

        //Subscribe "data" channel. Every time that the server publishes some data in this channel "data", the callback function passed as parameter will be called.
        ws.Subscribe("data", function ($this, datum, cmd) {
        
          var index;
          for (index = 0; index < datum.length; ++index) {// Iterate over all data array send by the server
            var p = datum[index];
            console.log("+ = ", p);
            datax.push(p.x); // pushes the data into the array. the field "x" and "y" comes from the "record point" declared in the server
            //Chapel serializes the record object (with the data fields "x" and "y") as JSON and send to the clientes that subscribed the channel to be used. 
            datay.push(p.y);

          }

          //Here is only using the plotly library to plot the data. You canuse d3js too or other plotting js library.
          var my_plot = {
            x: datax,
            y: datay,
            type: 'scatter',
          };
          Plotly.newPlot('sine-graph', [my_plot]);

          console.log("#data cb1", datum[0], " ");
          //$this.Publish("log", "Received " + datum);
        });

        //Here we are subscribing another channel with name "log"
        ws.Subscribe("log", function ($this, datum, cmd) {
          //update2(datum);
          //console.log("Log ", datum);
        });

        //Creating a timer
        var myVar = setInterval(myTimer, 1000);
        var x=0.0;
        var y=0.0;

        function myTimer() {
          x++;
          y= Math.cos(x/10); //make some calculus. 
          //Send to the server some points. 
          
          //this library does ot only sobscribes channels from the server side, but it you can publish data in any channel. 
          //In the code below, The client will publish a json object to "data" channel and all client that subscribed the "data" channel will receive the published data. 
          ws.Publish("data",{
            x:x,
            y:y
          });
            
        }

      });//End connect callback.
    </script>
```

## Websocket pubsub Status
The Chrest pubsub can:

1. Publish from server side.
2. Publish from client side (web browser).
3. Subscribe/Unsubscribe from client side (web browser).


## Todo
A lot of thing..... 


# Acknowledgment

We would like to thank [Deep 6 AI](https://deep6.ai/) for their support on this project.

# Interesting Projects
[Numsuch](https://github.com/buddha314/numsuch) numerical and Machine Learning library for Chapel Language.

[CDO](https://github.com/marcoscleison/CDO) Chapel Data Object is a database connector for Chapel language (Postgres,Mysql*,Sqlite*)

# Warning

This library is very alpha and incomplete. Please, consider that we are in early stage and many functions and features are not implemented yet.
