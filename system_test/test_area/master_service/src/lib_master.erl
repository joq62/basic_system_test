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

-define(APP_INFO_FILE,"app_info.dets").
-define(APP_DETS,?APP_INFO_FILE,[{type,set}]).



%% --------------------------------------------------------------------

%% External exports

%-export([create/2,delete/2]).

-compile(export_all).

%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
campaign()->
     %% campaign
    %% 1). Update configs - ensure that only availble nodes are part of the orchistration
    %% 2). Remove missing services from dns . Registered Service Not memeber of Desired  
    %% 3). Try to start missing services based on available nodes
    %%
    %% Will affect State !  

    %% 1).
    master_service:update_configs(),
    
    %% 2).
    DesiredServices=master_service:desired_services(),
    RegisteredServices=tcp_client:call(?DNS_ADDRESS,{dns_service,all,[]}),
    RemoveDns=[{ServiceId,IpAddr,Port}||{ServiceId,IpAddr,Port,_,_}<-RegisteredServices,
	      false==lists:member({ServiceId,IpAddr,Port},DesiredServices)],
    [tcp_client:call(?DNS_ADDRESS,{dns_service,delete,[ServiceId,IpAddr,Port]})
     ||{ServiceId,IpAddr,Port}<-RemoveDns],

    %% 3).
    start_missing(),
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

start_missing()->
    NodesInfo=lib_master:update_nodes(),
     {ok,AppInfo}=file:consult(?APP_SPEC),
    DS=lib_master:create_service_list(AppInfo,NodesInfo),
    case lib_master:check_missing_services(DS) of
	[]->
	    [];
	Missing->
	    load_start(Missing,[])
    end. 


load_start([],StartResult)->
    StartResult;
load_start([{ServiceId,IpAddrPod,PortPod}|T],Acc)->
    NewAcc=[master_service:load_start(ServiceId,IpAddrPod,PortPod)|Acc],
    load_start(T,NewAcc).

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
update_nodes()->
    {ok,NodesInfo}=file:consult(?NODE_CONFIG),
    check_available_nodes(NodesInfo).

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
check_available_nodes(NodesInfo)->
   % {ok,NodesInfo}=file:consult(?NODE_CONFIG),
    PingR=[{tcp_client:call({IpAddr,Port},{net_adm,ping,[Node]}),NodeId,Node,IpAddr,Port,Mode}||{NodeId,Node,IpAddr,Port,Mode}<-NodesInfo],
    ActiveNodes=[{NodeId,Node,IpAddr,Port,Mode}||{pong,NodeId,Node,IpAddr,Port,Mode}<-PingR],
    ActiveNodes.

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
check_missing_nodes(NodesInfo)->
%    {ok,NodesInfo}=file:consult(?NODE_CONFIG),
    PingR=[{tcp_client:call({IpAddr,Port},{net_adm,ping,[Node]}),NodeId,Node,IpAddr,Port,Mode}||{NodeId,Node,IpAddr,Port,Mode}<-NodesInfo],
    ActiveNodes=[{NodeId,Node,IpAddr,Port,Mode}||{pong,NodeId,Node,IpAddr,Port,Mode}<-PingR],
    Missing=[{DesiredNodeId,DesiredNode,DesiredIpAddr,DesiredPort,DesiredMode}||
		{DesiredNodeId,DesiredNode,DesiredIpAddr,DesiredPort,DesiredMode}<-NodesInfo,
		false=:=lists:member({DesiredNodeId,DesiredNode,DesiredIpAddr,DesiredPort,DesiredMode},ActiveNodes)],
    
    Missing.

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
check_obsolite_services(DesiredServices)->
  
%{"dns_service","localhost",40000,pod_master@asus,1584047881}
    RegisteredServices=dns_service:all(),
    PingR=[{tcp_client:call({IpAddr,Port},{list_to_atom(ServiceId),ping,[]}),IpAddr,Port}||{ServiceId,IpAddr,Port,_,_}<-RegisteredServices],
    ActiveServices=[{atom_to_list(ServiceId),IpAddr,Port}||{{pong,_,ServiceId},IpAddr,Port}<-PingR],
    Obsolite=[{ObsoliteServiceId,ObsoliteIpAddr,ObsolitePort}||{ObsoliteServiceId,ObsoliteIpAddr,ObsolitePort}<-ActiveServices,
							   false=:=lists:member({ObsoliteServiceId,ObsoliteIpAddr,ObsolitePort},DesiredServices)],
 
   Obsolite.

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
check_missing_services(DesiredServices)->
    PingR=[{tcp_client:call({IpAddr,Port},{list_to_atom(ServiceId),ping,[]}),IpAddr,Port}||{ServiceId,IpAddr,Port}<-DesiredServices],
    ActiveServices=[{atom_to_list(ServiceId),IpAddr,Port}||{{pong,_,ServiceId},IpAddr,Port}<-PingR],
    Missing=[{DesiredServiceId,DesiredIpAddr,DesiredPort}||{DesiredServiceId,DesiredIpAddr,DesiredPort}<-DesiredServices,
							   false=:=lists:member({DesiredServiceId,DesiredIpAddr,DesiredPort},ActiveServices)],
    
    Missing.

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%%  1) Create a pod PodId on computer ComputeId with IpAddrComp  PortComp
%%  2) Start tcp_server on PodId with IpAddrPod and PortPod 
%%  3) Load and  start service ServiceId on PodId 
%%  4) Check if ServiceId is started with ping 
%%  5) Add ServiceId,IpAddrPod and PortPod in dns_service
%% 
%% Returns: non
%% --------------------------------------------------------------------
%load_start_service(IpAddrPod,PortPod,ServiceId,PodId)->
    
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% 1) Create pod 
%% 2) Load and start lib_service
%% 3) start tcp_server
%% ComputerIpInfo={IpAddrComputer,PortComputer}
%% PodArgs={ParentNode,Dir,IpAddrPod,PortPod,Mode}
%% NeedServices=[CatalogInfo1, CatalogInfo2..]
%% Returns: non
%% --------------------------------------------------------------------
start_pod(ComputerIpInfo,PodArgs,NeedServices)->
 %   D=date(),
 %   R=tcp_client:call({"localhost",40000},{erlang,date,[]}),
 %create pod
    {NodeId,IpAddrPod,PortPod,ModePod}=PodArgs,
    tcp_client:call(ComputerIpInfo,{pod,create,[NodeId]}),
 %   R=tcp_client:call(ComputerIpInfo,{net_adm,ping,[Node]}),

     % load lib_service
    [tcp_client:call(ComputerIpInfo,{container,create,
				     [NodeId,
				      [{{service,ServiceId},
					{Source,Path}}]]})
     ||{{service,ServiceId},{Source,Path}}<-NeedServices],
    
   % timer:sleep(10000),
    tcp_client:call(ComputerIpInfo,{rpc,call,[misc_lib:get_node_by_id(NodeId),
					      lib_service,start_tcp_server,
					      [IpAddrPod,PortPod,ModePod]]}),
    R=case tcp_client:call({IpAddrPod,PortPod},{net_adm,ping,[misc_lib:get_node_by_id(NodeId)]}) of
	pong->
	    ok;
	Err->
	   {error,Err}
      end,
    R.
    
		    

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
stop_pod(ComputerIpInfo,NodeId)->
    tcp_client:call(ComputerIpInfo,{pod,delete,[NodeId]}).
    
		    

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
start_service(ServiceId,NodeId,_Node,CatalogInfo,NodesInfo)->
    {{service,_Service},{Source,Path}}=lists:keyfind({service,ServiceId},1,CatalogInfo),
    {NodeId,_Node,IpAddr,Port,_Mode}=lists:keyfind(NodeId,1,NodesInfo),

    ok=container:create(NodeId,
			[{{service,ServiceId},
			  {Source,Path}}
			]),
    true=dns_service:add(ServiceId,IpAddr,Port),
    ok.

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------

service_node_info(Key,ServiceNodeInfo)->
    [{ServiceId,IpAddr,Port}||{ServiceId,IpAddr,Port}<-ServiceNodeInfo,ServiceId=:=Key].

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create_service_list(AppsInfo,NodesInfo)->
    create_service_list(AppsInfo,NodesInfo,[]).
create_service_list([],_,ServiceList)->
    ServiceList;

create_service_list([{ServiceId,_Num,[]}|T],NodesInfo,Acc)->

    %% GLURK smarter alogrithm 
    L=[{NodeId,Node,IpAddr,Port,Mode}||{NodeId,Node,IpAddr,Port,Mode}<-NodesInfo,
				       NodeId=/=?MASTER_NODEID],
    [{_NodeId,_Node,IpAddr,Port,_Mode}|_]=L,
    NewAcc=[{ServiceId,IpAddr,Port}|Acc],
    create_service_list(T,NodesInfo,NewAcc);

create_service_list([{ServiceId,_Num,Nodes}|T],NodesInfo,Acc) ->
    L=[extract_ipaddr(ServiceId,NodeId,NodesInfo)||NodeId<-Nodes],
    NewAcc=lists:append(Acc,L),
    create_service_list(T,NodesInfo,NewAcc).

extract_ipaddr(ServiceId,NodeId,NodesInfo)->
    case lists:keyfind(NodeId,1,NodesInfo) of
	false->
	    {ServiceId,glurk,ServiceId};
	{_NodeId,_Node,IpAddr,Port,_Mode}->
	    {ServiceId,IpAddr,Port}	
    end.				     
    

%App_list=[{service_id,ip_addr,port,status}], status=running|not_present|not_loaded
%app_info=[{service_id,num,nodes,source}],  
% nodes=[{ip_addr,port}]|[], num = integer. Can be mix of spefied and unspecified nodes. Ex: num=2, nodes=[{ip_addr_1,port_2}] -> one psecifed and one unspecified

%status_desired_state_apps= ok|missing|remove
%status_desired_state_nodes = ok|missing|remove
%% --------------------------------------------------------------------
%% Function:init 
%% --------------------------------------------------------------------



ping_service([],_,PingResult)->
    PingResult;
ping_service([{_VmName,IpAddr,Port}|T],ServiceId,Acc)->
    R=tcp_client:call({IpAddr,Port},{list_to_atom(ServiceId),ping,[]}),
 %   R={ServiceId,VmName,IpAddr,Port},
    ping_service(T,ServiceId,[R|Acc]).
 
