module ChrestLogger{

    var Log:LoggerEngine = new LoggerEngine(new DefaultLogger());

    class Logger{
        proc  Fatal(v ...?eltType){

        }
        proc  Fatalf(format:string, v...?eltType){

        }
        proc  Fatalln(v...?eltType){

        }
        
        proc  Panic(v...?eltType){

        }
        proc  Panicf(format:string, v ...?eltType){

        }
        proc  Panicln(v...?eltType){

        }
        proc  Print(v...?eltType){

        }
        proc  Printf(format:string, v...?eltType){

        }
        proc  Println(v...?eltType){

            writeln((...v));
        }

    }

    class LoggerEngine{
        forwarding var log:Logger;
    }

    class DefaultLogger:Logger{
        proc DefaultLogger(){

        }
        
        proc  Fatal(v ...?eltType){
            write((...v));
        }
        proc  Fatalf(format:string, v...?eltType){
            writef(format,(...v));
        }
        proc  Fatalln(v...?eltType){
            writeln((...v));
        }
        
        proc  Panic(v...?eltType){
            writeln((...v));
        }
        proc  Panicf(format:string, v ...?eltType){
            writef(format,(...v));
        }
        proc  Panicln(v...?eltType){
            write((...v));
        }
        proc  Print(v...?eltType){
            write((...v)); 
        }
        proc  Printf(format:string, v...?eltType){
             writef(format,(...v));
        }
        proc  Println(v...?eltType){
             writeln((...v));
        }
        
        proc  Write(v...?eltType){
            write((...v)); 
        }
        proc  Writef(format:string, v...?eltType){
             writef(format,(...v));
        }
        proc  Writeln(v...?eltType){
             writeln((...v));
        }

    }

}