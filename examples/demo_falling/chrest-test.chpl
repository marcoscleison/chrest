use cf, ChrestClient, Spawn, Time;

const API_HOST: string = "127.0.0.1",
      API_PORT: int = 8080;


writeln("\t...running against the latest version of the binary in ./bin");

//var sub = spawn(["exec", "--API_HOST=" + API_HOST, "--API_PORT=" + API_PORT], executable= "/home/marcos/projects/chapel/projects/chrest/examples/demo_falling/bin/cf");

var sub = spawn(["/home/marcos/projects/chapel/projects/chrest/examples/demo_falling/bin/cf", "--API_HOST=" + API_HOST, "--API_PORT=" + API_PORT],stdout=PIPE);

//var sub = spawnshell("/home/marcos/projects/chapel/projects/chrest/examples/demo_falling/bin/cf --API_HOST=" + API_HOST+" --API_PORT=" + API_PORT);

sleep(1);

writeln("\n*** Building clientollah");
var clientollah = new ChrestClient(API_HOST, API_PORT);
var res = clientollah.Get("/");
var content:IndexResponse = res(IndexResponse);
writeln("\tContent Get: ",content);

sub.kill();
sub.close();
