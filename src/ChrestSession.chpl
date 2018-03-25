module ChrestSession{

use ChrestUtils;

class Session{
    var ID:string;
    proc Session(){
      this.ID =  randomString(12);
    }

    proc NewSession(){

    }



    proc Get(key:string, default:string=""){
        return default;
    }
    proc Put(key:string, value:string){
    
    }

    proc getID(){
        return this.ID;

    }
    proc setID(id:string){
        this.ID=id;
    }

    
    
}

class SessionInterface{
    forwarding var session:Session;
}



class MemorySession:Session{
    var kdom:domain(string);
    var data:[kdom]string;
    proc MemorySession(){
        
         this.ID =  randomString(12);
         //writeln("Creating session ID:",this.ID);
         writeln("Creating session ID:",this.getID());
    }


    proc Get(key:string, default:string=""){
        if(kdom.member(key)){
            return this.data[key];
        }
        return default;
    }
    proc Put(key:string, value:string){
      writeln("Session ID:", this.getID()," Key:",key," Value:",value);
      this.data[key]=value;
    }
}



}