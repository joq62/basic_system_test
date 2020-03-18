%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%% Description : log_service 
%%% One and centralized log service in the system   
%%% Solution is based on  syslog 
%%% Log files max 10 Mb. 
%%% current file = latest.log
%%% full file =date_time.log stored in syslog_dir
%%%  
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(log_service).  

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------


-record(state,{myip,dns_address,dns_socket}).

%% Definitions 
-define(HB_INTERVAL,1*20*1000).

%% --------------------------------------------------------------------

%% Application interfaces
%% Syslog Severity=emerg,alert,crit,err,warning,notice,info,debug
%% log_service_agent feeds the centralized log_service part of lib_service 
%% lib_service:log_event(?MODULE,?LINE,Severity,Msg).
%% tpc_client:cast({LogIpAddr,LogPort},{log_service,event,[node(),?MODULE,?LINE,Severity,Msg)


-export([ping/0,
	 store/1,all/0,
	 severity/1,node/3,module/1,
	 latest_event/0,latest_events/1,
	 year/1,month/2,day/3
	]).

-export([start/0,
	 stop/0,
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



%%-----------------------------------------------------------------------
ping()->
    gen_server:call(?MODULE, {ping},infinity).

year(Year)->
    gen_server:call(?MODULE, {year,Year},infinity).
month(Year,Month)->
    gen_server:call(?MODULE, {month,Year,Month},infinity).
day(Year,Month,Day)->
    gen_server:call(?MODULE, {day,Year,Month,Day},infinity).

latest_events(N)->
    gen_server:call(?MODULE, {latest_events,N},infinity).

latest_event()->
    gen_server:call(?MODULE, {latest_event},infinity).

severity(Severity)->
    gen_server:call(?MODULE, {severity,Severity},infinity).

node(IpAddr,Port,Pod)->
    gen_server:call(?MODULE, {node,IpAddr,Port,Pod},infinity).

module(Module)->
    gen_server:call(?MODULE, {module,Module},infinity).

all()->
    gen_server:call(?MODULE, {all},infinity).


%%-----------------------------------------------------------------------
 
store(SysLog)->
    gen_server:call(?MODULE, {store,SysLog}).

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
       % Initiated the app
   
    ok=log:init_logfile(),	
       
    {ok, #state{}}.
    
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

handle_call({store,SysLog}, _From, State) ->
     Reply=log:store(SysLog),
    {reply, Reply, State};


handle_call({ping}, _From, State) ->
     Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({year,Year}, _From, State) ->
     Reply=rpc:call(node(),log,year,[Year]),
    {reply, Reply, State};
handle_call({month,Year,Month}, _From, State) ->
     Reply=rpc:call(node(),log,month,[Year,Month]),
    {reply, Reply, State};

handle_call({day,Year,Month,Day}, _From, State) ->
     Reply=rpc:call(node(),log,day,[Year,Month,Day]),
    {reply, Reply, State};


handle_call({latest_events,N}, _From, State) ->
     Reply=rpc:call(node(),log,latest_events,[N]),
    {reply, Reply, State};

handle_call({latest_event}, _From, State) ->
     Reply=rpc:call(node(),log,latest_event,[]),
    {reply, Reply, State};

handle_call({severity,Severity}, _From, State) ->
     Reply=rpc:call(node(),log,severity,[Severity]),
    {reply, Reply, State};

handle_call({node,IpAddr,Port,Pod}, _From, State) ->
     Reply=rpc:call(node(),log,node,[IpAddr,Port,Pod]),
    {reply, Reply, State};

handle_call({module,Module}, _From, State) ->
     Reply=rpc:call(node(),log,module,[Module]),
    {reply, Reply, State};

handle_call({all}, _From, State) ->
     Reply=rpc:call(node(),log,all,[]),
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
handle_cast({store,SysLog}, State) ->
    ok=log:store(SysLog),
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

