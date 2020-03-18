%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dbase).

-behaviour(gen_server).

-define(VERSION,'1.0.0').


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%%  -include("").
%% --------------------------------------------------------------------
%% External exports

-export([delete/1,exists/1,new/1,create/2,get/2,get_tuple/3,store/3,store_tuple/4,all/1,remove/2,start/0,stop/0,ver/0]).

%% gen_server callbacks
-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start()-> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
stop()-> gen_server:call(?MODULE, {stop},infinity).
ver()->  {?MODULE,?VERSION}.


% new_dbase(DbaseName)
% 
delete(File)-> 
    gen_server:call(?MODULE, {delete,File},infinity).
exists(File)-> 
    gen_server:call(?MODULE, {exists,File},infinity).
new(File)-> 
    gen_server:call(?MODULE, {create,File},infinity).
create(Type,File)-> 
    gen_server:call(?MODULE, {create,Type,File},infinity).
store(Key,Value,File)->
    gen_server:call(?MODULE, {store,Key,Value,File},infinity).    
store_tuple(Key,TupleKey,Value,File)->
    gen_server:call(?MODULE, {store_tuple,Key,TupleKey,Value,File},infinity).  
get(Key,File)->
    gen_server:call(?MODULE, {get,Key,File},infinity).
get_tuple(Key,TupleKey,File)->
    gen_server:call(?MODULE, {get,Key,TupleKey,File},infinity).
all(File)->
    gen_server:call(?MODULE, {all,File},infinity).
remove(Key,File)->
    gen_server:call(?MODULE, {remove,Key,File},infinity).

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
%% --------------------------------------------------------------------
init([]) ->
    io:format("Starting ~p~n",[{?MODULE,?VERSION}]),
%    application:load(tcp),
%    application:start(tcp),
%    {ok,[_Type,_Addr,{port,Port},{setup_server,Setup_server},_Setup_client]}=sd:address(dbase),
 %   io:format(" ~p~n",[{?MODULE,?LINE,Port}]),
  %  {ok,_SessionId}=tcp_server:init(seq,Port,Setup_server,dbase_mm),
    {ok, #state{}}.

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

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
handle_call({delete,File},_From,State) ->
    case filelib:is_file(File) of 
	true->
	    Reply={ok,file_not_exist};
	false->
	    file:delete(File),
	    Reply={ok,file_deleted}
    end,
    {reply, Reply, State};

handle_call({exists,File},_From,State) ->
    Reply=filelib:is_file(File),
    {reply, Reply, State};

handle_call({create,Type,File},_From,State) ->
    case filelib:is_file(File) of 
	true->
	    Reply={ok,file_already_exsist};
	false->
	    {ok,Descriptor}=dets:open_file(File,[{type,Type}]),
	    dets:close(Descriptor),
	    Reply={ok,file_created}
    end,
    {reply, Reply, State};


handle_call({store,Key,Value,File},_From,State) ->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    ok=dets:insert(Descriptor, {Key,Value}),
	    dets:close(Descriptor),
	    Reply={ok,store};
	false->
	    Reply = {error,no_file}
    end,
    {reply, Reply, State};

handle_call({store_tuple,Key,TupleKey,Value,File},_From,State) ->
% io:format(" ~p~n",[{?MODULE,?LINE,Key,TupleKey,File}]),
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    case dets:lookup(Descriptor, Key) of
		[]->
		    Reply = {error,no_entry};
		X->
		  %  io:format("X= ~p~n",[{?MODULE,?LINE,X}]),
		    [{Key,{Key,Record}}]=X,
		    {TupleKey,_CurrentValue}=lists:keyfind(TupleKey,1,Record),
		  %  io:format("Record= ~p~n",[{?MODULE,?LINE,Record}]),
		   % io:format("TupleKey,Value= ~p~n",[{?MODULE,?LINE,TupleKey,Value}]),
		    UpdatedRecord=lists:keyreplace(TupleKey, 1, Record, {TupleKey,Value}),
		    ok=dets:insert(Descriptor,{Key,{Key,UpdatedRecord}}),
		    dets:close(Descriptor),
		    Reply=UpdatedRecord
	    end,
	    dets:close(Descriptor);
	false->
	    Reply = {error,no_file}
    end,
    {reply, Reply, State};


handle_call({get,Key,File},_From,State) ->
    Reply=l_get(Key,File),
    {reply, Reply, State};

handle_call({get,Key,TupleKey,File},_From,State) ->
    {ok,Value}=l_get(Key,File),
    case l_get(Key,File) of
	{ok,Value}-> 
	    Reply=lists:keyfind(TupleKey,1,Value);
	{error,Err}->
	    Reply={error,Err}
    end,
    {reply, Reply, State};
    

handle_call({all,File},_From,State) ->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    Key=dets:first(Descriptor),
	    Reply=get_all(Descriptor,Key,[]),
	    dets:close(Descriptor);
	false->
	    Reply = {error,no_file}
    end,
    {reply, Reply, State};

handle_call({remove,Key,File},_From,State) ->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    case dets:lookup(Descriptor, Key) of
		[]->
		    Reply = {error,no_entry};
		X->
		    ok=dets:delete(Descriptor, Key),
		    [{Key,Value}]=X,
		    Reply={ok,Value}
	    end,
	    dets:close(Descriptor);
	false->
	    Reply = {error,no_file}
    end,
    {reply, Reply, State};
% --------------------------------------------------------------------
%% Function: stop/0
%% Description:
%% 
%% Returns: non
%% --------------------------------------------------------------------
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


handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{Msg,?MODULE,time()}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
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
%% Function: get_all/0
%% Description:if needed creates dets file with name ?MODULE, and
%% initates the debase
%% Returns: non
%% --------------------------------------------------------------------
get_all(_Desc,'$end_of_table',Acc)->
    {ok,Acc};
get_all(Desc,Key,Acc)->  
    Status=dets:lookup(Desc, Key),
    Acc1=lists:append(Status,Acc),
    Key1=dets:next(Desc,Key),
    get_all(Desc,Key1,Acc1).

%% Function: l_get/0
%% Description:local get funtion used by several server functions
%% Returns: {ok,Value}|{error,Errcode}
%% --------------------------------------------------------------------
l_get(Key,File)->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    Value=dets:lookup(Descriptor, Key),
	    Reply={ok,Value},
	    dets:close(Descriptor);
	false->
	    Reply = {error,no_file}
    end,
    Reply.
