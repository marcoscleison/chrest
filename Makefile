all:
	chpl -o ./bin/srv ./examples/srv.chpl -M ./src -levent -I ./src/
test:
	chpl -o ./bin/test ./examples/test.chpl -M ./src -levent -I ./src/
cli:
	chpl -o ./bin/cli ./examples/cli.chpl -M ./src -levent -I ./src/