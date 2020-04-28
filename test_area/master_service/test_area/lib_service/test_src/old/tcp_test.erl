%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(tcp_test). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
%% --------------------------------------------------------------------



-compile(export_all).



%% ====================================================================
%% External functions


%------------------ misc_lib -----------------------------------
-define(SERVER_ID,"test_iaas_service").

misc_lib()->
    [node_by_id()].

node_by_id()->
    {ok,Host}=inet:gethostname(),
    PodIdServer=?SERVER_ID++"@"++Host,
    PodServer=list_to_atom(PodIdServer),
    ?assertEqual(PodServer,misc_lib:get_node_by_id(?SERVER_ID)).


unconsult()->
    L=[{vm_name,"pod_computer_1"},
       {vm,'pod_computer_1@asus'},
       {ip_addr,"localhost"},
       {port,40100},
       {mode,parallell},
       {worker_start_port,40101},
       {num_workers,5}],
    misc_lib:unconsult("computer_1.config",L),
    ?assertEqual({ok,[{vm_name,"pod_computer_1"},
		      {vm,'pod_computer_1@asus'},
		      {ip_addr,"localhost"},
		      {port,40100},
		      {mode,parallell},
		      {worker_start_port,40101},
		      {num_workers,5}]},file:consult("computer_1.config")),
    file:delete("computer_1.config"),
    ok.



%------------------ ceate and delete Pods and containers -------
% create Pod, start container - test application running - delete container
% delete Pod
-define(S_SERVER,"pod_seq_server").
-define(P_SERVER,"pod_para_server").

-define(P_IP_OK,{"joqhome.dynamic-dns.net",40000}).
-define(P_WRONG_IP,{"joqhome.dynamic-dns.glurk",40000}).
-define(P_WRONG_PORT,{"joqhome.dynamic-dns.net",22000}).

-define(L_IP_OK,{"localhost",50000}).
-define(L_WRONG_IP,{"glurk",50000}).
-define(L_WRONG_PORT,{"localhost",33000}).


start()->
    create_seq_server(),
    seq_test(),
    ok.

create_seq_servers()->
    %% Typical sequence to create a pod
    %% Create the Pod, load lib_service , start assigne tcp_server 
    %% 
    {ok,S_Server}=pod:create(?S_SERVER),    
     ?assertEqual(ok,container:create(?S_SERVER,
		     [{{service,"lib_service"},
		       {dir,"/home/pi/erlang/basic"}}
		     ])),
    timer:sleep(100),
    {I1,P1}=?P_IP_OK,
    rpc:call(S_Server,lib_service,start_tcp_server,[I1,P1,sequence]),

    

    {ok,P_Server}=pod:create(?P_SERVER),   
    ?assertEqual(ok,container:create(P_SERVER,
		     [{{service,"lib_service"},
		       {dir,"/home/pi/erlang/basic"}}
		     ])),

    ?assertEqual(42,rpc:call(Pod,adder_service,add,[20,22])),

    %% FRom github 
    ?assertEqual(ok,container:create("pod_para_server",
		     [{{service,"lib_service"},
		       {git,"https://github.com/joq62/basic.git"}}
		     ])),
  %  ?debugMsg("check if basic is present "),
    timer:sleep(100),
    ?assertEqual(24.0,rpc:call(Pod,divi_service,divi,[240,10])),

    %% ---- delete container ------------------------------------------------
    ?assertEqual([ok],container:delete("pod_lib_1",["adder_service"])),
    ?assertMatch({badrpc,_},rpc:call(Pod,adder_service,add,[20,22])),

    %%---- Delete pod -------------------------------------------------------
    D=date(),
    ?assertEqual(D,rpc:call(Pod,erlang,date,[])),
    ?assertEqual({ok,stopped},pod:delete("pod_lib_1")),
    ?assertEqual({badrpc,nodedown},rpc:call(Pod,erlang,date,[])),    
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
tcp_service()->
     start_tcp_service_seq(),
     test_tcp_service_seq(),
     stop_tcp_service_seq(),

     start_tcp_service_par(),
     test_tcp_service_par(),
     stop_tcp_service_par().

test_tcp_service_seq()->
    D=date(),
    ?assertEqual(D,rpc:call(node(),tcp_client,call,[{"localhost",52000},{erlang,date,[]}],1000)),
    ?assertMatch({error,_},rpc:call(node(),tcp_client,call,[{"glurk",52000},{erlang,date,[]}],1000)),
    ?assertMatch({error,_},rpc:call(node(),tcp_client,call,[{"localhost",6666},{erlang,date,[]}],5000)),
    
    {ok,Socket1}=tcp_client:connect("localhost",52000),
    {ok,Socket2}=tcp_client:connect("localhost",52000),
    ?assertEqual(ok,tcp_client:cast(Socket1,{erlang,date,[]})),
    ?assertEqual(ok,tcp_client:cast(Socket2,{erlang,date,[]})),

    ?assertEqual(D,tcp_client:get_msg(Socket1,1000)),
    ?assertMatch({error,_},tcp_client:get_msg(Socket2,1000)), 
    ?assertEqual(ok,tcp_client:disconnect(Socket1)),  
      
    ?assertEqual(D,tcp_client:get_msg(Socket2,1000)),  
    ?assertEqual(ok,tcp_client:disconnect(Socket2)),
    ok.

test_tcp_service_par()->
     D=date(),
    ?assertEqual(D,rpc:call(node(),tcp_client,call,[{"localhost",32000},{erlang,date,[]}],5000)),
    ?assertMatch({error,_},rpc:call(node(),tcp_client,call,[{"glurk",32000},{erlang,date,[]}],5000)),
    ?assertMatch({error,_},rpc:call(node(),tcp_client,call,[{"localhost",6666},{erlang,date,[]}],5000)),
    
    {ok,Socket1}=tcp_client:connect("localhost",32000),
    {ok,Socket2}=tcp_client:connect("localhost",32000),
    ?assertEqual(ok,tcp_client:cast(Socket1,{erlang,date,[]})),
    ?assertEqual(ok,tcp_client:cast(Socket2,{erlang,date,[]})),

    ?assertEqual(D,tcp_client:get_msg(Socket1,1000)),
    ?assertMatch(D,tcp_client:get_msg(Socket2,1000)), 
    ?assertEqual(ok,tcp_client:disconnect(Socket1)),  
      
    ?assertMatch({error,_},tcp_client:get_msg(Socket2,1000)),  
    ?assertEqual(ok,tcp_client:disconnect(Socket2)),
    ok.
   
start_tcp_service_seq()->
    ?assertEqual(ok,
		 rpc:call(node(),lib_service,start_tcp_server,["localhost",52000,sequence])),
    ?assertMatch({error,_},
		 rpc:call(node(),lib_service,start_tcp_server,["localhost",52000,sequence])).

start_tcp_service_par()->
    ?assertEqual(ok,
		 rpc:call(node(),lib_service,start_tcp_server,["localhost",32000,parallell])),
    ?assertMatch({error,_},
		 rpc:call(node(),lib_service,start_tcp_server,["localhost",32000,parallell])).
    

stop_tcp_service_seq()->
    ?assertEqual({ok,stopped},rpc:call(node(),lib_service,stop_tcp_server,["localhost",52000],1000)).

stop_tcp_service_par()->
    ?assertEqual({ok,stopped},rpc:call(node(),lib_service,stop_tcp_server,["localhost",32000],1000)).


    
