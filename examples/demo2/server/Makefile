MODULES= /home/marcos/projects/chapel/projects/chrest/src
CC=chpl
EXEC=srv

default: 
	chpl -o ./bin/$(EXEC) ./src/$(EXEC).chpl -M /home/marcos/projects/chapel/projects/chrest/src -levent -I /home/marcos/projects/chapel/projects/chrest/src  

run: default
	./bin/$(EXEC)
