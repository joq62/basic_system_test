all:
	rm -rf ebin/* src/*~;
	erlc -o ebin src/*.erl;
	cp src/*.app ebin;
	erl -pa ebin -s node_controller_service start -sname node_controller_service

w:
	rm -rf dns_service log_service lib_service ebin/* ../src/*~ test_ebin/* ../test_src/*~ ../test_src/lib_service* ../test_src/container*;
	cp ../src/*.app ebin;
	cp ../src/*.app ../ebin;
	cp -r /home/pi/erlang/basic/dns_service .;
	cp /home/pi/erlang/basic/dns_service/src/*.app dns_service/ebin;
	erlc -W0 -D local -I /home/pi/erlang/basic/include -o dns_service/ebin dns_service/src/*.erl;
	cp -r /home/pi/erlang/basic/lib_service .;
	cp /home/pi/erlang/basic/lib_service/src/*.app lib_service/ebin;
	erlc  -W0 -D local -I /home/pi/erlang/basic/include -o lib_service/ebin lib_service/src/*.erl;
	cp -r /home/pi/erlang/basic/log_service .;
	cp /home/pi/erlang/basic/log_service/src/*.app log_service/ebin;
	erlc  -W0 -D local -I /home/pi/erlang/basic/include -o log_service/ebin log_service/src/*.erl;
	erlc  -W0 -D local -I /home/pi/erlang/basic/include -o test_ebin ../test_src/*.erl;
	erlc  -W0 -D local -I /home/pi/erlang/basic/include -o ebin ../src/*.erl;
	erl -pa */ebin -pa ebin -pa test_ebin -s master_service_tests start -sname pod_master

test:
	rm -rf dns_service log_service lib_service ebin/* ../src/*~ test_ebin/* ../test_src/*~ ../test_src/lib_service* ../test_src/container*;
	cp ../src/*.app ebin;
	cp ../src/*.app ../ebin;
	cp -r /home/pi/erlang/basic/dns_service .;
	cp /home/pi/erlang/basic/dns_service/src/*.app dns_service/ebin;
	erlc -D local -I /home/pi/erlang/basic/include -o dns_service/ebin dns_service/src/*.erl;
	cp -r /home/pi/erlang/basic/lib_service .;
	cp /home/pi/erlang/basic/lib_service/src/*.app lib_service/ebin;
	erlc -D local -I /home/pi/erlang/basic/include -o lib_service/ebin lib_service/src/*.erl;
	cp -r /home/pi/erlang/basic/log_service .;
	cp /home/pi/erlang/basic/log_service/src/*.app log_service/ebin;
	erlc -D local -I /home/pi/erlang/basic/include -o log_service/ebin log_service/src/*.erl;
	erlc -D local -I /home/pi/erlang/basic/include -o test_ebin ../test_src/*.erl;
	erlc -D local -I /home/pi/erlang/basic/include -o ebin ../src/*.erl;
	erl -pa */ebin -pa ebin -pa test_ebin -s master_service_tests start -sname pod_master
