%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% {"pod_master",'pod_master@asus',"localhost",40000,parallell}.
%%% {"pod_landet_1",'pod_landet_1@asus',"localhost",50100,parallell}.
%%% {"pod_lgh_1",'pod_lgh_1@asus',"localhost",40100,parallell}.
%%% {"pod_lgh_2",'pod_lgh_2@asus',"localhost",40200,parallell}.
%%%
%%% {"adder_service",2,["pod_landet_1","pod_lgh_2"]}.
%%% {"divi_service",1,[]}.
%%% 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(start_test_system).  
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").

%% --------------------------------------------------------------------
-compile(export_all).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:emulate loader
%% Description: requires pod+container module
%% Returns: non
%% --------------------------------------------------------------------
start()->
    %start master already started 
    ?assertMatch({pong,_,_},tcp_client:call({"localhost",40000},{master_service,ping,[]})),
    NodeList=tcp_client:call({"localhost",40000},{master_service,nodes,[]}),
    %% test glurk
    D=date(),
    ?assertEqual(D,tcp_client:call({"localhost",40000},{erlang,date,[]})),

    WorkerList=[{NodeId,Node,IpAddr,Port,Mode}||{NodeId,Node,IpAddr,Port,Mode}<-NodeList,
						NodeId=/="pod_master"],
  %  ?assertMatch(glurk,WorkerList),
    IpInfoComputer={"localhost",40000},
    NodeComputer='pod_master@asus',
  %  ?assertEqual(glurk,tcp_client:call({"localhost",40000},{erlang,date,[]})),
    NeededServices=[{{service,"lib_service"},{dir,"/home/pi/erlang/d/source"}}],
    ?assertMatch(ok,[{test,tcp_client:call(IpInfoComputer,{lib_master,start_pod,
							   [{"localhost",40000},NodeComputer,
							    {Node,NodeId,IpAddrPod,PortPod,ModePod},
							    NeededServices]}),
			{IpInfoComputer,{NodeId,Node,IpAddrPod,PortPod,ModePod}}}
			||{NodeId,Node,IpAddrPod,PortPod,ModePod}<-WorkerList]),
    
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------


