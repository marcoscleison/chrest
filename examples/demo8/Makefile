include local.mk
cli: $(DEMO_HOME)/client/src/cli.chpl
	chpl -o $(DEMO_HOME)/client/bin/cli $(DEMO_HOME)/client/src/cli.chpl $(CHREST_HOME)/src/chrest_websocket_client.c   -lwebsockets -I $(CHREST_HOME)/src/ -M $(CHREST_HOME)/src

server: $(DEMO_HOME)/server/src/srv.chpl
	chpl -o $(DEMO_HOME)/server/bin/srv $(DEMO_HOME)/server/src/srv.chpl $(CHREST_HOME)/src/chrest_websocket.c   -lwebsockets -I $(CHREST_HOME)/src/ -M $(CHREST_HOME)/src

runcli: cli
	$(DEMO_HOME)/client/bin/cli

runsrv: server
	$(DEMO_HOME)/server/bin/srv

