%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : test application calc
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(master_service).  

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{nodes,apps,catalog,desired_services,dns_address,tcp_servers}).


%% --------------------------------------------------------------------
%% Definitions 
%% --------------------------------------------------------------------
-define(MASTER_HEARTBEAT,20*1000).


-export([desired_services/0,catalog/0,apps/0,
	 nodes/0,
	 load_start/3,stop_unload/3,
	 update_configs/0,
	 campaign/0
	]).

-export([update_node_info/4,read_node_info/1,
	 node_availability/1,
	 update_app_info/5,read_app_info/1,delete_app_info/1,
	 app_availability/1
	]).

-export([start/0,
	 stop/0,
	 ping/0,
	 heart_beat/1
	]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

%% Asynchrounus Signals



%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).


ping()-> 
    gen_server:call(?MODULE, {ping},infinity).

%%-----------------------------------------------------------------------


load_start(ServiceId,IpAddrPod,PortPod)->
    gen_server:call(?MODULE, {load_start,ServiceId,IpAddrPod,PortPod},infinity).
stop_unload(ServiceId,IpAddrPod,PortPod)->
    gen_server:call(?MODULE, {stop_unload,ServiceId,IpAddrPod,PortPod},infinity).




update_configs()->
    gen_server:call(?MODULE, {update_configs},infinity).

catalog()->
    gen_server:call(?MODULE, {catalog},infinity).
nodes()->
    gen_server:call(?MODULE, {nodes},infinity).
apps()->
    gen_server:call(?MODULE, {apps},infinity).
desired_services()->
    gen_server:call(?MODULE, {desired_services},infinity).

%%-----------------------   Tabort ------------------------------------------------
app_availability(ServiceId)->
    gen_server:call(?MODULE, {app_availability,ServiceId},infinity).

update_app_info(ServiceId,Num,Nodes,Source,Status)->
    gen_server:call(?MODULE, {update_app_info,ServiceId,Num,Nodes,Source,Status},infinity).

read_app_info(ServiceId)->
    gen_server:call(?MODULE, {read_app_info,ServiceId},infinity).

delete_app_info(ServiceId)->
    gen_server:call(?MODULE, {delete_app_info,ServiceId},infinity).

node_availability(NodeId)->
    gen_server:call(?MODULE, {node_availability,NodeId},infinity).

update_node_info(IpAddr,Port,Mode,Status)->
    gen_server:call(?MODULE, {update_node_info,IpAddr,Port,Mode,Status},infinity).

read_node_info(NodeId)->
    gen_server:call(?MODULE, {read_node_info,NodeId},infinity).

%%-----------------------------------------------------------------------
campaign()->
    gen_server:cast(?MODULE, {campaign}).

heart_beat(Interval)->
    gen_server:cast(?MODULE, {heart_beat,Interval}).


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%
%% --------------------------------------------------------------------
init([]) ->
    {ok,NodesInfo}=file:consult(?NODE_CONFIG),
    {ok,AppInfo}=file:consult(?APP_SPEC),
    {ok,CatalogInfo}=file:consult(?CATALOG_INFO),
    DesiredServices=lib_master:create_service_list(AppInfo,NodesInfo),
    spawn(fun()->heart_beat(?MASTER_HEARTBEAT) end),
    {ok, #state{nodes=NodesInfo,apps=AppInfo,catalog=CatalogInfo,
		desired_services=DesiredServices,
		dns_address=[],tcp_servers=[]}}.   
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (aterminate/2 is called)
%% --------------------------------------------------------------------


handle_call({load_start,ServiceId,IpAddrPod,PortPod}, _From, State) ->
   % {"pod_master",'pod_master@asus',"localhost",40000,parallell}
    L=[{NodeId,Node,IpAddrNode,PortNode}
       ||{NodeId,Node,IpAddrNode,PortNode,_Mode}<-State#state.nodes,
	 {IpAddrNode,PortNode}=:={IpAddrPod,PortPod}],
    
    case L of
	[]->
	    Reply={error,[eexists,IpAddrPod,PortPod,?MODULE,?LINE]};
	L->
	    [{NodeId,_Node,IpAddrNode,PortNode}]=L,
						%  {{service,"adder_service"},{dir,"/home/pi/erlang/d/source"}}
	    CatalogInfo=lists:keyfind({service,ServiceId},1,State#state.catalog),
  
%    Reply=[ServiceId,{IpAddrNode,PortNode},[Node,NodeId,[CatalogInfo]]],
	     Reply={tcp_client:call({IpAddrNode,PortNode},
				    {container,create,[NodeId,[CatalogInfo]]}),
		    ServiceId,IpAddrPod,PortPod},
	    case Reply of
		{ok,ServiceId,IpAddrPod,PortPod}->
		    lib_service:log_event(?MODULE,?LINE,info,["ok Started ",ServiceId,IpAddrPod,PortPod]),
		    ok=tcp_client:call(?DNS_ADDRESS,{dns_service,add,[ServiceId,IpAddrNode,PortNode]});
		Err->
		    lib_service:log_event(?MODULE,?LINE,info,["Error Started Service ",ServiceId,IpAddrPod,PortPod,Err])
	    end
    end,
    {reply, Reply,State};


handle_call({stop_unload,ServiceId,IpAddrPod,PortPod}, _From, State) ->
    [L]=[{NodeId,Node,IpAddrNode,PortNode}
	 ||{NodeId,Node,IpAddrNode,PortNode,_Mode}<-State#state.nodes,
	   {IpAddrNode,PortNode}=:={IpAddrPod,PortPod}],
    {NodeId,_Node,IpAddrNode,PortNode}=L,
    [ok]=tcp_client:call({IpAddrNode,PortNode},{container,delete,[NodeId,[ServiceId]]}),
    ok=tcp_client:call(?DNS_ADDRESS,{dns_service,delete,[ServiceId,IpAddrNode,PortNode]}),
    lib_service:log_event(?MODULE,?LINE,info,["ok Stopped Service ",ServiceId,IpAddrPod,PortPod]),
    Reply=ok,
    {reply, Reply,State};


handle_call({update_configs}, _From, State) ->
    NodesInfo=lib_master:update_nodes(),
    %% Remove services on missing nodes from dns
    %% 
    {ok,AppInfo}=file:consult(?APP_SPEC),
    {ok,CatalogInfo}=file:consult(?CATALOG_INFO),
    DesiredServices=lib_master:create_service_list(AppInfo,NodesInfo),
    NewState=State#state{nodes=NodesInfo,apps=AppInfo,
			 catalog=CatalogInfo,
			 desired_services=DesiredServices},
    Reply=ok,			 

    {reply, Reply,NewState};

handle_call({apps}, _From, State) ->
    Reply=State#state.apps,
    {reply, Reply,State};

handle_call({nodes}, _From, State) ->
    Reply=State#state.nodes,
    {reply, Reply,State};

handle_call({catalog}, _From, State) ->
    Reply=State#state.catalog,
    {reply, Reply,State};

handle_call({desired_services}, _From, State) ->
    Reply=State#state.desired_services,
    {reply, Reply,State};


%%%%%%%=========================================================================


handle_call({app_availability,ServiceId}, _From, State) ->
    Reply=rpc:call(node(),lib_app,app_availability,[ServiceId]),
    {reply, Reply,State};

handle_call({update_app_info,ServiceId,Num,Nodes,Source,Status}, _From, State) ->
    Reply=rpc:call(node(),lib_app,update_app_info,[ServiceId,Num,Nodes,Source,Status]),
    {reply, Reply,State};

handle_call({read_app_info,ServiceId}, _From, State) ->
    Reply=rpc:call(node(),lib_app,read_app_info,[ServiceId]),
    {reply, Reply,State};


handle_call({delete_app_info,ServiceId}, _From, State) ->
    Reply=rpc:call(node(),lib_app,delete_app_info,[ServiceId]),
    {reply, Reply,State};

handle_call({node_availability,NodeId}, _From, State) ->
    Reply=rpc:call(node(),lib_master,node_availability,[NodeId]),
    {reply, Reply,State};

handle_call({update_node_info,IpAddr,Port,Mode,Status}, _From, State) ->
    Reply=rpc:call(node(),lib_master,update_node_info,[IpAddr,Port,Mode,Status]),
    {reply, Reply,State};


handle_call({read_node_info,NodeId}, _From, State) ->
    Reply=rpc:call(node(),lib_master,read_node_info,[NodeId]),
    {reply, Reply,State};

handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({campaign}, State) ->
    spawn(fun()->lib_master:campaign() end),    
    {noreply, State};

handle_cast({heart_beat,Interval}, State) ->
    spawn(fun()->h_beat(Interval) end),    
    {noreply, State};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(Info, State) ->
    io:format("unmatched match info ~p~n",[{?MODULE,?LINE,Info}]),
    {noreply, State}.


%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
h_beat(Interval)->
    lib_master:campaign(), 
    timer:sleep(Interval),
    rpc:cast(node(),?MODULE,heart_beat,[Interval]).

%% --------------------------------------------------------------------
%% Internal functions
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
