module Main{
    use ChrestClient;

  //this class will be used to send and receive data in json
 class MyData{
        var name:string;
        var email:string;

        proc MyData(name:string, email:string){
            this.name=name;
            this.email=email;
        }
    }



    proc main(){
        // Creates Client
        var cli = new ChrestClient("127.0.0.1",8080);
        
        // Creates objects to be sent
        var obj = new MyData("Marcos","marcos@teste.co");
        var obj2 = new MyData("Chapel","teste@teste.co");
        // makes POST request sending obj as json to /json uri
        var res = cli.Get("/");
        //Reads response body as string
        var content:string = res();
        writeln("Content Get: ",content);
        // makes PUT request sending obj as json to /json uri
        var res2 = cli.Put("/json",obj);
        //Reads response json and serializes it into object of type MyData
        var responseObj:MyData = res2(MyData);

        writeln("Content PUT Name: ",responseObj.name);
        writeln("Content PUT Email: ",responseObj.email);

        // makes Post request sending obj as json to /json uri
        var res3 = cli.Post("/json",obj2);
        //Reads response json and serializes it into object of type MyData
        var responseObj2:MyData = res3(MyData);

        writeln("Content POST Name: ",responseObj2.name);
        writeln("Content POST Email: ",responseObj2.email);
        
    } 
}