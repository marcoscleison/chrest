all:
	chpl -o ./bin/srv ./examples/srv.chpl -M ./src -levent -I ./src/