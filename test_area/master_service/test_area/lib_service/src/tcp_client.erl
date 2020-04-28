%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%1
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(tcp_client).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------
-define (CLIENT_SETUP,[binary, {packet,4}]).
-define (TIMEOUT_TCPCLIENT,5*1000).
-define (TIMEOUT_CONNECT,3*1000).

-define(KEY_M_OS_CMD,89181808).
-define(KEY_F_OS_CMD,"95594968").
-define(KEY_MSG,'100200273').

%% External exports
%-compile(export_all).

-export([connect/2,connect/3,disconnect/1,
	 call/2,call/3,call/6,call/7,cast/2,
	 get_msg/2
	]).

%% ====================================================================
%% External functions
%% ====================================================================
call(ServiceId,M,F,A,NumTries,Delay)->
    tcp_client:call(ServiceId,M,F,A,NumTries,Delay,error).

call(_ServiceId,_M,_F,_A,0,_Delay,Result)->
    {error,[exhausted_num_tries,Result,?MODULE,?LINE]};

call(ServiceId,M,F,A,NumTries,Delay,Result)->
    IpAddrList=tcp_client:call(?DNS_ADDRESS,{dns_service,get,[ServiceId]}),
    call(IpAddrList,ServiceId,M,F,A,NumTries,Delay,Result).

call([],ServiceId,M,F,A,NumTries,Delay,_Result)->
    timer:sleep(Delay),
    IpAddrList=tcp_client:call(?DNS_ADDRESS,{dns_service,get,[ServiceId]}),
    call(IpAddrList,ServiceId,M,F,A,NumTries-1,Delay,error);

call([{IpAddr,Port,_Node}|T],ServiceId,M,F,A,NumTries,Delay,_Result)->
    case tcp_client:call({IpAddr,Port},{M,F,A}) of
	{error,_}->
	    timer:sleep(Delay),
	    call(T,ServiceId,M,F,A,NumTries-1,Delay,error);
	{badrpc,_}->
	    timer:sleep(Delay),
	    call(T,ServiceId,M,F,A,NumTries-1,Delay,error);
	Reply->
	    Reply 
    end.

%% --------------------------------------------------------------------
%% Function: connect(IpAddr,Port)
%% Description:
%% Returns: {ok,Socket}|{error,Err}
%% --------------------------------------------------------------------
connect(IpAddr,Port)->
    Result=case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP) of
	       {ok,Socket}->
		   {ok,Socket};
	       {error,Err} ->
		   {error,[Err,?MODULE,?LINE]}
	   end,
    Result.
    
connect(IpAddr,Port,Timeout)->
    Result=case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP,Timeout) of
	       {ok,Socket}->
		   {ok,Socket};
	       {error,Err} ->
		   {error,[Err,IpAddr,Port,?MODULE,?LINE]}
	   end,
    Result.

disconnect(Socket)->
    gen_tcp:close(Socket).

cast(Socket,{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,call,{M,F,A}}
	end, 
    gen_tcp:send(Socket,term_to_binary(Msg)).

get_msg(Socket,Timeout)->
    Result=receive
	       {tcp,Socket,Bin}->
		   case binary_to_term(Bin) of
		       {?KEY_MSG,R}->
			   R;
		       Err->
			   {error,[unmatched,Socket,Err,?MODULE,?LINE]}
		   end;
	       {tcp_closed, Socket}->
		   {error,[tcp_closed,Socket]}	       
	   after Timeout ->
		   {error,[tcp_timeout,Socket,?MODULE,?LINE]}
	   end,
    Result.


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
call({IpAddr,Port},{M,F,A},TimeOut)->
    case connect(IpAddr,Port,TimeOut) of
	{error,[timeout,connect,IpAddr,Port,?MODULE,?LINE]}->
	    {error,[timeout,connect,IpAddr,Port,?MODULE,?LINE]};
	 {ok,Socket}->
	    cast(Socket,{M,F,A}),
	    get_msg(Socket,TimeOut);
	X ->
	    X
    end.
call({IpAddr,Port},{M,F,A})->
    Msg=case {M,F,A} of
	    {os,cmd,A}->
		{?KEY_MSG,call,{?KEY_M_OS_CMD,?KEY_F_OS_CMD,A}};
	    {M,F,A}->
		{?KEY_MSG,call,{M,F,A}}
	end,
    send(IpAddr,Port,Msg).

send(IpAddr,Port,Msg)->
    case gen_tcp:connect(IpAddr,Port,?CLIENT_SETUP) of
	{ok,Socket}->
	    ok=gen_tcp:send(Socket,term_to_binary(Msg)),
	    receive
		{tcp,Socket,Bin}->
		    Result=case binary_to_term(Bin) of
			       {?KEY_MSG,R}->
				   R;
			       Err->
				   {error,[Err,IpAddr,Port,Msg,?MODULE,?LINE]}
			   end;
		{tcp_closed, Socket}->
		    Result={error,tcp_closed}
	    after ?TIMEOUT_TCPCLIENT ->
		    Result={error,[tcp_timeout,IpAddr,Port,Msg],?MODULE,?LINE}
	    end,
	    ok=gen_tcp:close(Socket);
	{error,Err}->
	    Result={error,[Err,?MODULE,?LINE]}
    end,
   Result.
			   
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
