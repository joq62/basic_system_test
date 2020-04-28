all:
	rm -rf ebin/* src/*~;
	erlc -o ebin src/*.erl;
	cp src/*.app ebin;
	erl -pa ebin -s node_controller_service start -sname node_controller_service

git:
	rm -rf basic master_service dns_service log_service lib_service ../src/*~ test_ebin/* ../test_src/*~ ;
	git clone https://github.com/joq62/basic.git;
#	master_service
	cp -r basic/master_service .;	
	cp basic/master_service/src/*.app master_service/ebin;
	erlc -D local -I basic/include -o master_service/ebin master_service/src/*.erl;
#	lib_service
	cp -r basic/lib_service .;	
	cp basic/lib_service/src/*.app lib_service/ebin;
	erlc -D local -I basic/include -o lib_service/ebin lib_service/src/*.erl;
#	log_service
	cp -r basic/log_service .;	
	cp basic/log_service/src/*.app log_service/ebin;
	erlc -D local -I basic/include -o log_service/ebin log_service/src/*.erl;
#	dns_service
	cp -r basic/dns_service .;	
	cp basic/dns_service/src/*.app dns_service/ebin;
	erlc -D local -I basic/include -o dns_service/ebin dns_service/src/*.erl;
#	test
	erlc -D local -I basic/include -o test_ebin ../test_src/*.erl;
#	remove basic
	rm -rf basic;
	erl -pa master_service/ebin -pa log_service/ebin -pa lib_service/ebin -pa dns_service/ebin  -pa test_ebin -s master_service_tests start -sname pod_master

test:
	rm -rf dns_service log_service lib_service master_service ../ebin/* ../src/*~ test_ebin/* ../test_src/*~ ../test_src/lib_service* ../test_src/container*;
#	master_service
	cp -r /home/pi/erlang/basic/master_service .;
	cp /home/pi/erlang/basic/master_service/src/*.app master_service/ebin;
	erlc -D local -I /home/pi/erlang/basic/include -o master_service/ebin master_service/src/*.erl;
#	lib_service
	cp -r /home/pi/erlang/basic/lib_service .;
	cp /home/pi/erlang/basic/lib_service/src/*.app lib_service/ebin;
	erlc -D local -I /home/pi/erlang/basic/include -o lib_service/ebin lib_service/src/*.erl;
#	log_service
	cp -r /home/pi/erlang/basic/log_service .;
	cp /home/pi/erlang/basic/log_service/src/*.app log_service/ebin;
	erlc -D local -I /home/pi/erlang/basic/include -o log_service/ebin log_service/src/*.erl;
#	dns_service
	cp -r /home/pi/erlang/basic/dns_service .;
	cp /home/pi/erlang/basic/dns_service/src/*.app dns_service/ebin;
	erlc -D local -I /home/pi/erlang/basic/include -o dns_service/ebin dns_service/src/*.erl;
#	test
	erlc -D local -I /home/pi/erlang/basic/include -o test_ebin ../test_src/*.erl;
	erl -pa log_service/ebin -pa lib_service/ebin -pa dns_service/ebin -pa master_service/ebin -pa test_ebin -s master_service_tests start -sname pod_master
