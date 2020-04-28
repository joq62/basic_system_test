%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(etcd_test_cases). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
-include("master_service_tests.hrl").
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
-define(DETS_LIST,[{"node_info.dets",[{type,set}]},
		   {"app_info.dets",[{type,set}]},
		   {"status.dets",[{type,set}]}
		  ]).
		   

start()->
    cleanup(),
    etcd:create_app_dets(),
    etcd:create_node_dets(),
    ?assertEqual(ok,node_info_test()),
    ?assertEqual(ok,app_info_test()),
    ?assertEqual(ok,read_info_test()),
    

    cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
read_info_test()->
    ?assertEqual({dir,"/home/pi/erlang/simple_d/source"},etcd:app_info_item("adder_service",source)),
    ?assertEqual({error,[undef,glurk]},etcd:app_info_item("adder_service",glurk)),
    ?assertEqual({error,[undef,"no_service"]},etcd:app_info_item("no_service",source)),
    ?assertEqual("localhost",etcd:node_info_item("pod_lgh_1",ip_addr)),
    ?assertEqual({error,[undef,glurk_item]},etcd:node_info_item("pod_lgh_1",glurk_item)),
    ?assertEqual({error,[undef,"pod_glurk"]},etcd:node_info_item("pod_glurk",ip_addr)),
    
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
app_info_test()->
    {ok,Files}=file:list_dir("appfiles"),
    AppInfo=[file:consult(filename:join("appfiles",File))||File<-Files,filename:extension(File)=:=".spec"],
    AppInfoList=[etcd:set_app_info(ServiceId,Num,Nodes,Source,not_loaded)||{ok,[{service,ServiceId},
									     {num_instances,Num},
									     {nodes,Nodes},
									     {source,Source}
									    ]
									}<-AppInfo],
   %  ?assertEqual(ok,AppInfoList),
    ?assertEqual(ok,etcd:update("app_info.dets",app_info,AppInfoList)),
    
    {ok,[{app_info,Info}]}=etcd:read("app_info.dets",app_info),
    I=proplists:get_value("adder_service",Info),
    ?assertEqual({app_info,
		  "adder_service",
		  2,
		  [{"pod_landet_1","localhost",50100},
		   {"pod_lgh_1","localhost",40100}],
		  {dir,"/home/pi/erlang/simple_d/source"},
		  not_loaded},I),
    ok=etcd:update_app_info(I#app_info.service,3,I#app_info.nodes,I#app_info.source,loaded),
    
    {ok,[{app_info,Info2}]}=etcd:read("app_info.dets",app_info),
    I2=proplists:get_value("adder_service",Info2),
    ?assertEqual({app_info,
		  "adder_service",
		  3,
		  [{"pod_landet_1","localhost",50100},
		   {"pod_lgh_1","localhost",40100}],
		  {dir,"/home/pi/erlang/simple_d/source"},
		  loaded},I2),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
node_info_test()->
    {ok,I}=file:consult("node.config"),
    ComputerList=proplists:get_value(computer_list,I),
    UpdatedComputerList=[etcd:set_node_info(IpAddr,Port,Mode,no_status_info)||{_VmName,IpAddr,Port,Mode}<-ComputerList],
    
   % ?assertEqual(glurk,UpdatedComputerList),
%    io:format("~p~n",[UpdatedComputerList]),
   % ?assertEqual(ok,etcd:update("node_info.dets",node_info,UpdatedComputerList)),
    [etcd:update_node_info(IpAddr,Port,Mode,no_status_info)||{_VmName,IpAddr,Port,Mode}<-ComputerList],
    
    {ok,[{node_info,Info}]}=etcd:read("node_info.dets",node_info),
%    ?assertEqual(glur_node_info,Info),

    ?assertEqual({node_info,
		  "pod_landet_1",
		  pod_landet_1@asus,
		  "localhost",50100,
		  parallell,no_status_info},proplists:get_value("pod_landet_1",Info)),
    X=proplists:get_value("pod_landet_1",Info),
    ?assertEqual(no_status_info,X#node_info.status),   
    % Update status info for "pod_landet_1"
    % 1) Update the record 
    % 2) Update the list 
    % 3) update dets table
   
    CurrentInfo=proplists:get_value("pod_landet_1",Info),
    etcd:update_node_info(CurrentInfo#node_info.ip_addr,CurrentInfo#node_info.port,
			  CurrentInfo#node_info.mode,running), 
    % 1)
  %  
   

    % NewInfo=etcd:set_node_info(CurrentInfo#node_info.ip_addr,CurrentInfo#node_info.port,
%			       CurrentInfo#node_info.mode,running),
   
    % 2)
   % NewUpdatedComputerList=lists:keyreplace("pod_landet_1",1,UpdatedComputerList,NewInfo),
  %  ?assertEqual(glurk,NewUpdatedComputerList),
   % ?assertEqual(glurk,NewInfo),
    % Before 
   ?assertEqual([{"pod_lgh_2",no_status_info},
		 {"pod_lgh_1",no_status_info},
		 {"pod_landet_1",no_status_info}],[{VnName,InfoList#node_info.status}||{VnName,InfoList}<-Info]),
    % After updating "pod_landet_1"
  %% ?assertEqual([{"pod_landet_1",running},
%		  {"pod_lgh_1",no_status_info},
%		  {"pod_lgh_2",no_status_info}],[{VnName,InfoList#node_info.status}||{VnName,InfoList}<-NewUpdatedComputerList]),
    % 3)
    CurrentInfo=proplists:get_value("pod_landet_1",Info),
    etcd:update_node_info(CurrentInfo#node_info.ip_addr,CurrentInfo#node_info.port,
			  CurrentInfo#node_info.mode,running), 
  
%  ?assertEqual(ok,etcd:update("node_info.dets",node_info,NewUpdatedComputerList)),
    {ok,[{node_info,Info2}]}=etcd:read("node_info.dets",node_info),
    ?assertEqual([{"pod_lgh_2",no_status_info},
		   {"pod_lgh_1",no_status_info},
		   {"pod_landet_1",running}],[{VnName,InfoList#node_info.status}||{VnName,InfoList}<-Info2]),
   
    CurrentInfo2=proplists:get_value("pod_lgh_1",Info2),
    ok=etcd:update_node_info(CurrentInfo2#node_info.ip_addr,CurrentInfo2#node_info.port,
			     CurrentInfo2#node_info.mode,running),
    
    {ok,[{node_info,Info3}]}=etcd:read("node_info.dets",node_info),
    ?assertEqual([{"pod_lgh_2",no_status_info},
		  {"pod_lgh_1",running},
		  {"pod_landet_1",running}],[{VmName,InfoList#node_info.status}||{VmName,InfoList}<-Info3]),
    
    ok.


% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------


cleanup()->
    etcd:delete_app_dets(),
    etcd:delete_node_dets(),
    ok.
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
