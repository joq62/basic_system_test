%%% -------------------------------------------------------------------
%%% Author  : Joq Erlang
%%%  
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dns_service). 

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------
%% Key Data structures
%% 
%% --------------------------------------------------------------------
-record(state,{services}).

%% --------------------------------------------------------------------
%% Exported functions
%% --------------------------------------------------------------------

%% dns functions 
-export([add/3,delete/3,clear/0,
	 get/1,all/0,
	 ping/0
	]
      ).


-export([start/0,
	 stop/0
	]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================

%% Gen server functions

start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop()-> gen_server:call(?MODULE, {stop},infinity).


%%--------------------- Server call ------------------------------------
ping()-> 
    gen_server:call(?MODULE, {ping},infinity).

get(ServiceId)->
    gen_server:call(?MODULE, {get,ServiceId},infinity).
all()->
    gen_server:call(?MODULE, {all},infinity).
    

%%----------------------Server cast --------------------------------------
add(ServiceId,IpAddr,Port)->
    gen_server:cast(?MODULE,{add,ServiceId,IpAddr,Port}).  

delete(ServiceId,IpAddr,Port)->
    gen_server:cast(?MODULE,{delete,ServiceId,IpAddr,Port}).
clear()->
    gen_server:cast(?MODULE,{clear}).  
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
   {ok, #state{services=[]}}. 
    
%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({ping},_From,State) ->
    Reply={pong,node(),?MODULE},
    {reply, Reply, State};

handle_call({get,ServiceId},_From,State) ->
    Reply=[{I1,P1}||{S1,I1,P1}<-State#state.services,
		       S1=:=ServiceId],
    {reply, Reply, State};

handle_call({all},_From,State) ->
    Reply=State#state.services,
    {reply, Reply, State};
    
handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    io:format("unmatched  ~p~n",[{time(),?MODULE,?LINE,Request}]),
     Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast({clear}, State) ->
    NewState=State#state{services=[]},
    {noreply, NewState};

handle_cast({delete,ServiceId,IpAddr,Port}, State) ->
    UpdatedList=[{S1,I1,P1}||{S1,I1,P1}<-State#state.services,
			     {S1,I1,P1}=/={ServiceId,IpAddr,Port}],
     NewState=State#state{services=UpdatedList},
    {noreply, NewState};

handle_cast({add,ServiceId,IpAddr,Port}, State) ->
    UpdatedList=[{ServiceId,IpAddr,Port}|[{S1,I1,P1}||{S1,I1,P1}<-State#state.services,
			     {S1,I1,P1}=/={ServiceId,IpAddr,Port}]],
    NewState=State#state{services=UpdatedList},
    {noreply, NewState};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{time(),?MODULE,?LINE,Msg}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------


handle_info(Info, State) ->
    io:format("unmatched match cast ~p~n",[{time(),?MODULE,?LINE,Info}]),
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


%% --------------------------------------------------------------------
%% Internal functions
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
