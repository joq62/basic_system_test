%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : test application calc
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_app).  

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------


-compile(export_all).

%-export([]).


%% ====================================================================
%% External functions
%% ====================================================================

-define(APP_INFO_FILE,"app_info.dets").
-define(APP_DETS,?APP_INFO_FILE,[{type,set}]).



%% --------------------------------------------------------------------

%% External exports

%-export([create/2,delete/2]).

-compile(export_all).

%% ====================================================================
%% External functions
%% ====================================================================

%App_list=[{service_id,ip_addr,port,status}], status=running|not_present|not_loaded
%app_info=[{service_id,num,nodes,source}],  
% nodes=[{ip_addr,port}]|[], num = integer. Can be mix of spefied and unspecified nodes. Ex: num=2, nodes=[{ip_addr_1,port_2}] -> one psecifed and one unspecified

%status_desired_state_apps= ok|missing|remove
%status_desired_state_nodes = ok|missing|remove
%% --------------------------------------------------------------------
%% Function:init 
%% --------------------------------------------------------------------

set_app_list(ServiceId,IpAddr,Port,Status)->
    #app_list{service=ServiceId,ip_addr=IpAddr,port=Port,status=Status}.

update_app_list(ServiceId,IpAddr,Port,Status)->
    NewAppList=set_app_list(ServiceId,IpAddr,Port,Status),
    UpdatedList=case etcd:read(?APP_INFO_FILE,app_list) of
		    {ok,[]}->
		       %NoEntries 
			[NewAppList];
		    {ok,[{app_list,AppListList}]}->
			case [AppList||AppList<-AppListList,
				       AppList#app_list.service=:=ServiceId,
				       AppList#app_list.ip_addr=:=IpAddr,
				       AppList#app_list.port=:=Port] of
			    []->
			%	glurk=NewAppInfo,
				[NewAppList|AppListList];
			    [AppList]->
			%	glurk=AppInfo,
				[NewAppList|[X||X<-AppListList,
						X#app_list.service=/=ServiceId,
						X#app_list.ip_addr=/=IpAddr,
						X#app_list.port=/=Port]]
			end
		end,
   
    etcd:update(?APP_INFO_FILE,app_list,UpdatedList).

delete_app_list(ServiceId,IpAddr,Port,Source,Status)->
    etcd:delete(app_list,ServiceId,IpAddr,Port).

%%------------- app_info START ----------------------------------------
set_app_info(ServiceId,Num,Nodes,Source,Status)->
    #app_info{service=ServiceId,num=Num,nodes=Nodes,source=Source,status=Status}.

update_app_info(ServiceId,Num,Nodes,Source,Status)->
    NewAppInfo=set_app_info(ServiceId,Num,Nodes,Source,Status),
    UpdatedList=case etcd:read(?APP_INFO_FILE,app_info) of
		    {ok,[]}->
		       %NoEntries 
			[NewAppInfo];
		    {ok,[{app_info,AppInfoList}]}->
			[NewAppInfo|[X||X<-AppInfoList,X#app_info.service=/=ServiceId]]
	%		case [AppInfo||AppInfo<-AppInfoList,AppInfo#app_info.service=:=ServiceId] of
	%		    []->
			%	glurk=NewAppInfo,
	%			[NewAppInfo|AppInfoList];
	%		    [AppInfo]->
			%	glurk=AppInfo,
	%			[NewAppInfo|[X||X<-AppInfoList,X#app_info.service=/=ServiceId]]
	%		end
		end,
   
    etcd:update(?APP_INFO_FILE,app_info,UpdatedList).


delete_app_info(ServiceId)->
    {ok,[{app_info,AppInfoList}]}=etcd:read(?APP_INFO_FILE,app_info),
    UpdatedAppInfoList=[AppInfo||AppInfo<-AppInfoList,AppInfo#app_info.service=/=ServiceId],
    etcd:update(?APP_INFO_FILE,app_info,UpdatedAppInfoList).

read_app_info(all)->
    {ok,[{app_info,AppInfoList}]}=etcd:read(?APP_INFO_FILE,app_info),
    AppInfoList;
    
read_app_info(ServiceId)->
    {ok,[{app_info,AppInfoList}]}=etcd:read(?APP_INFO_FILE,app_info),
    [AppInfo||AppInfo<-AppInfoList,AppInfo#app_info.service=:=ServiceId].


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% 1) Update the record 
%% 2) Update the list 
%% 3) update dets table
%% --------------------------------------------------------------------
create_dets()->
    etcd:create_file(?APP_DETS),
    ok.

delete_dets()->
    etcd:delete_file(?APP_INFO_FILE),
    ok.
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
app_info_item(Key,Item)->
    {ok,[{app_info,AppInfo}]}=etcd:read(?APP_INFO_FILE,app_info),
    case proplists:get_value(Key,AppInfo) of
	undefined->
	    {error,[undef, Key]};
	I->
	    case Item of
		service->
		    I#app_info.service;
		num ->
		    I#app_info.num;
		nodes ->
		    I#app_info.nodes;
		source ->
		    I#app_info.source;
		status ->
		    I#app_info.status;
		_->
		    {error,[undef, Item]}
	    end
    end.



%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
% -record(app_info,{service,num,nodes,source,status})}).

%app_availability(all)->
 %   AppInfoList=read_app_info(all),
 %   [PingResult|_]=AppInfoList,
    
%    TestNodeInfoList=[{"glurk",#node_info{vm='glurk@glurk_host',ip_addr="localhost",port=50100,status=glurk}}|NodeInfoList],
 %   PingResult=[{ping_service(AppInfo#app_info.nodes,AppInfo#app_info.service,[]),{ServiceId,AppInfo}}||{ServiceId,AppInfo}<-AppInfoList],
    
   % X=[{ServiceId,AppInfo}||{ServiceId,AppInfo}<-AppInfoList],
  %  [PingResult|_]=X,
					  % glurk=PingResult,
  %  Available=[{ServiceId,AppInfo}||{{Ping,_,_},{ServiceId,AppInfo}}<-PingResult,Ping=:=pong],
    
   % Missing=lists:flatlength(PingResult),
%    Missing=[R||{R,{ServiceId,AppInfo}}<-PingResult,R=/=pong],
   % Missing=[{ServiceId,AppInfo}||{_Ping,{ServiceId,AppInfo}}<-PingResult],
  % Missing=[{ServiceId,AppInfo}||{Ping,{ServiceId,AppInfo}}<-PingResult,Ping=/=pong],
 %glur blir bara ett resultat   

%    PingResult;
  %  {availible,Available,missing,Missing,remove,[]};
   % {availible,Available,missing,Missing,remove,Remove};

%app_availability(ServiceId)->
 %   _NodeInfoList=read_app_info(ServiceId),
  %  {glurk,not_implmented}.

ping_service([],_,PingResult)->
    PingResult;
ping_service([{VmName,IpAddr,Port}|T],ServiceId,Acc)->
    R=tcp_client:call({IpAddr,Port},{list_to_atom(ServiceId),ping,[]}),
 %   R={ServiceId,VmName,IpAddr,Port},
    ping_service(T,ServiceId,[R|Acc]).
