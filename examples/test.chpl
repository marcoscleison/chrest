module Main{
    proc main(){
        var x = 10;

        var foo = lambda(z: int) { 
            var y = z * x;
            return y;  
        };

        writeln(foo(3));


    }
}