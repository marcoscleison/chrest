#/bin/sh

curl -i \
    -H "Accept: application/json" \
    -H "X-HTTP-Method-Override: PUSH" \
    -X POST -d '{"name":"Marcos","email":"teste@teste.co"}'\
     http://localhost:8080/json

curl -i \
    -H "Accept: application/json" \
    -H "X-HTTP-Method-Override: PUT" \
    -X PUT -d '{"verb":"put","msg":"this is a test for put"}'\
     http://localhost:8080/json


