module ChrestSession{


class Session{
    proc Session(){

    }

    proc NewSession(){

    }



    proc Get(key:string, default:string=nil){
        return default;
    }
    proc Put(key:string, value:string){
    
    }
    
}

class SessionInterface{
    forwarding var session:Session;
}



class MemorySession:Session{
    var kdom:domain(string);
    var data:[kdom]string;
    proc MemorySession(){

    }

    proc NewSession(){

    }


    proc Get(key:string, default:string=nil){
        return default;
    }
    proc Put(key:string, value:string){
      
    }
}



}