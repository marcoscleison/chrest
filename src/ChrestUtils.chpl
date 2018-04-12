module ChrestUtils{

use Random;


proc randomString(size:int, dicts:string="01234567890abcdefghijklmnopqrstuwvxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"){
    ///var randCh: [1..#size] uint(8);
    var randStream:RandomStream(real) = new RandomStream(real);
    var str:string;
    var i=1;
    while (i<=size ) {
        var nextRand = randStream.getNext();
        var idx = (nextRand*(dicts.length-1)+1):int;
        str += dicts[idx];
         i+=1;
    }
    return str;
}

proc jsonToObject(str:string, type eltType):eltType{
    try{
        var obj = new eltType();
        var mem = openmem();
        var writer = mem.writer().write(str);
        var reader = mem.reader();
        reader.readf("%jt", obj);
        return obj;

    }catch{
        writeln("Could not convert json to object");
        return new eltType();
    }

}


}