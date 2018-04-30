MODULES= /home/marcos/projects/chapel/projects/chrest/src
CC=chpl
EXEC=srv

default: 
	chpl -o ./bin/$(EXEC) ./src/srv.chpl ~/projects/chapel/projects/chrest/src/chrest_websocket.c  -M ~/projects/chapel/projects/chrest/src -lwebsockets -I /home/marcos/projects/chapel/projects/chrest/src   

run: default
	./bin/$(EXEC)
