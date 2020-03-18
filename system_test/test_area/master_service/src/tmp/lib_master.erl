%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : test application calc
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_master).  

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

%% Asynchrounus Signals



%% Gen server functions

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
node_availability(all)->
    NodeInfoList=read_node_info(all),
    TestNodeInfoList=[{"glurk",#node_info{vm_name="glurk",vm='glurk@glurk_host',ip_addr="localhost",port=50100,status=glurk}}|NodeInfoList],
    PingResult=[{tcp_client:call({ND#node_info.ip_addr,
				 ND#node_info.port},{net_adm,ping,[ND#node_info.vm]}),{VmName,ND}}||{VmName,ND}<-TestNodeInfoList],
    Available=[{VmName,ND}||{R,{VmName,ND}}<-PingResult,R=:=pong],
    Missing=[{VmName,ND}||{R,{VmName,ND}}<-PingResult,R=/=pong],
    {availible,Available,missing,Missing};
node_availability(NodeId)->
    _NodeInfoList=read_node_info(NodeId),
    {glurk,not_implmented}.

update_node_info(IpAddr,Port,Mode,Status)->
    ok=etcd:update_node_info(IpAddr,Port,Mode,Status).

read_node_info(all)->
   % {?MODULE,?LINE,read_node_info}.
    etcd:read_node_info(all).


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
% -record(app_info,{service,num,nodes,source,status})}).

app_availability(all)->
    AppInfoList=read_app_info(all),
 %   [PingResult|_]=AppInfoList,
    
%    TestNodeInfoList=[{"glurk",#node_info{vm='glurk@glurk_host',ip_addr="localhost",port=50100,status=glurk}}|NodeInfoList],
    PingResult=[{ping_service(AppInfo#app_info.nodes,AppInfo#app_info.service,[]),{ServiceId,AppInfo}}||{ServiceId,AppInfo}<-AppInfoList],
    
   % X=[{ServiceId,AppInfo}||{ServiceId,AppInfo}<-AppInfoList],
  %  [PingResult|_]=X,
					  % glurk=PingResult,
    Available=[{ServiceId,AppInfo}||{{Ping,_,_},{ServiceId,AppInfo}}<-PingResult,Ping=:=pong],
    
   % Missing=lists:flatlength(PingResult),
%    Missing=[R||{R,{ServiceId,AppInfo}}<-PingResult,R=/=pong],
   % Missing=[{ServiceId,AppInfo}||{_Ping,{ServiceId,AppInfo}}<-PingResult],
   Missing=[{ServiceId,AppInfo}||{Ping,{ServiceId,AppInfo}}<-PingResult,Ping=/=pong],
 glur blir bara ett resultat   

%    PingResult;
    {availible,Available,missing,Missing,remove,[]};
   % {availible,Available,missing,Missing,remove,Remove};

app_availability(ServiceId)->
    _NodeInfoList=read_app_info(ServiceId),
    {glurk,not_implmented}.

update_app_info(ServiceId,Num,Nodes,Source,Status)->
    ok=etcd:update_app_info(ServiceId,Num,Nodes,Source,Status).

read_app_info(all)->
   % {?MODULE,?LINE,read_node_info}.
    etcd:read_app_info(all).


missing([],Missing)->
    


ping_service([],_,PingResult)->
    PingResult;
ping_service([{VmName,IpAddr,Port}|T],ServiceId,Acc)->
    R=tcp_client:call({IpAddr,Port},{list_to_atom(ServiceId),ping,[]}),
 %   R={ServiceId,VmName,IpAddr,Port},
    ping_service(T,ServiceId,[R|Acc]).
