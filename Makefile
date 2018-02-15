all:
	chpl -o ./bin/srv ./examples/srv.chpl -M ./src -levent -I ./src/
test:
	chpl -o ./bin/test ./examples/test.chpl -M ./src -levent -I ./src/
cli:
	chpl -o ./bin/cli ./examples/cli.chpl -M ./src -levent -I ./src/

demo_fcf:
	chpl -o ./examples/demo_falling/bin/cf ./examples/demo_falling/cf.chpl -M ./src -levent -I ./src/

demo_fcli:
	chpl -o ./examples/demo_falling/bin/chrest-test ./examples/demo_falling/chrest-test.chpl -M ./src -levent -I ./src/
