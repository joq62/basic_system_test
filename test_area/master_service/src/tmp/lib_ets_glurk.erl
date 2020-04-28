%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_ets).
 


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------


-include("common_macros.hrl").
%% --------------------------------------------------------------------
%-record(dns,{service_id,ip_addr,port,vm,timestamp}).
-define(MASTER_ETS,master_ets).

% app_spec: {ServiceId,NumInstances,[RequiredNodes]}.
% catalog_info: {{service,ServiceId},{Type,Source}}.
% node_config: {NodeId,Node,IpAddr,Port,Mode}.
% desired_services: {ServiceId,IpAddr,Port}


%% External exports
%-export([init/0,add/4,delete/3,delete/4,delete/5,
%	 clear/0,get/1,
%	 delete_expired/0,expired/0,
%	 all/0,
%	 get_expired_time/0
%	]).

-compile(export_all).




%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init()->
    ?MASTER_ETS=ets:new(?MASTER_ETS,[public,bag,named_table]),
    ok.


clear()->
    true=ets:delete(?MASTER_ETS),
    ?MASTER_ETS=ets:new(?MASTER_ETS,[public,bag,named_table]),
    ok.


all()->
    ets:tab2list(?MASTER_ETS).


%% --------------------------------------------------------------------
%% Function: _
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

%%------------- app_spec ----------------------------------------------
init_app()->
    {ok,AppInfo}=file:consult(?APP_SPEC),
    [add_app(ServiceId,NumInstances,ListRequiredNodes)
     ||{ServiceId,NumInstances,ListRequiredNodes}<-AppInfo].
	
add_app(ServiceId,NumInstances,ListRequiredNodes)->
    ets:match_delete(?MASTER_ETS,{app_spec,ServiceId,NumInstances,ListRequiredNodes}),
    ets:insert(?MASTER_ETS,{app_spec,ServiceId,NumInstances,ListRequiredNodes}),
    ok.

delete_app(ServiceId)->
    ets:match_delete(?MASTER_ETS,{app_spec,ServiceId,'_','_'}),
    ok.

all_app()->
    L=ets:tab2list(?MASTER_ETS),
    [{ServiceId,NumInstances,ListRequiredNodes}
     ||{app_spec,ServiceId,NumInstances,ListRequiredNodes}<-L].

get_app(ServiceId)->
    case ets:match(?MASTER_ETS,{app_spec,ServiceId,'$1','$2'}) of
	[]->
	    no_entry;
	Info ->
	    [{ServiceId,NumInstances,ListRequiredNodes}||
		[NumInstances,ListRequiredNodes]<-Info]
		
    end.

%%------------- desired ----------------------------------------------
add_desired(ServiceId,IpAddr,Port)->
    ets:match_delete(?MASTER_ETS,{desired_services,ServiceId,IpAddr,Port}),
    ets:insert(?MASTER_ETS,{desired_services,ServiceId,IpAddr,Port}),
    ok.
delete_desired(ServiceId)->
    ets:match_delete(?MASTER_ETS,{desired_services,ServiceId,'_','_'}),
    ok.

all_desired()->
    L=ets:tab2list(?MASTER_ETS),
    [{ServiceId,IpAddr,Port}||{desired_services,ServiceId,IpAddr,Port}<-L].

get_desired(ServiceId)->
    case ets:match(?MASTER_ETS,{desired_services,ServiceId,'$1','$2'}) of
	[]->
	    no_entry;
	Info ->
	    [{IpAddr,Port}||[IpAddr,Port]<-Info]
		
    end.

%%------------- catalog ----------------------------------------------
add_catalog(ServiceId,Type,Source)->
    ets:match_delete(?MASTER_ETS,{catalog_info,ServiceId,Type,Source}),
    ets:insert(?MASTER_ETS,{catalog_info,ServiceId,Type,Source}),
    ok.

delete_catalog(ServiceId)->
    ets:match_delete(?MASTER_ETS,{catalog_info,ServiceId,'_','_'}),
    ok.
all_catalog()->
    L=ets:tab2list(?MASTER_ETS),
    [{{service,ServiceId},{Type,Source}}
     ||{catalog_info,ServiceId,Type,Source}<-L].

get_catalog(ServiceId)->
    case ets:match(?MASTER_ETS,{catalog_info,ServiceId,'$1','$2'}) of
	[]->
	    no_entry;
	Info ->
	    [{{service,ServiceId},{Type,Source}}||
		[Type,Source]<-Info]
		
    end.

%%------------- node ----------------------------------------------
add_node(NodeId,Node,IpAddr,Port,Mode)->
    ets:match_delete(?MASTER_ETS,{node_config,NodeId,Node,IpAddr,Port,Mode}),
    ets:insert(?MASTER_ETS,{node_config,NodeId,Node,IpAddr,Port,Mode}),
    ok.

delete_node(NodeId)->
    ets:match_delete(?MASTER_ETS,{node_info,NodeId,'_','_','_','_'}),
    ok.

all_node()->
    L=ets:tab2list(?MASTER_ETS),
    [{NodeId,Node,IpAddr,Port,Mode}
     ||{node_config,NodeId,Node,IpAddr,Port,Mode}<-L].

get_node(NodeId)->
    case ets:match(?MASTER_ETS,{node_config,NodeId,'$1','$2','$3','$4'}) of
	[]->
	    no_entry;
	Info ->
	    [{NodeId,Node,IpAddr,Port,Mode}||
		[Node,IpAddr,Port,Mode]<-Info]
		
    end.


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
