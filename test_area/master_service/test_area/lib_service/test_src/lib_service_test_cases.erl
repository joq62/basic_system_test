%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_service_test_cases). 
   
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

pod_container_cases()->
    [create_delete_pod()].

create_delete_pod()->
    %% Typical sequence to create a pod
    %% Create the Pod, load lib_service , start assigne tcp_server 
    %% 
    {ok,Pod}=pod:create("pod_lib_1"),    
    PodServer=misc_lib:get_node_by_id("pod_lib_1"),
    ?assertEqual(PodServer,Pod),
    ?assertEqual(ok,container:create("pod_lib_1",
		     [{{service,"adder_service"},
		       {dir,"/home/pi/erlang/basic"}}
		     ])),
    timer:sleep(100),
    ?assertEqual(42,rpc:call(Pod,adder_service,add,[20,22])),

    %% FRom github 
    ?assertEqual(ok,container:create("pod_lib_1",
		     [{{service,"divi_service"},
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
