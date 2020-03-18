%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(pod). 
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Data Type
%% --------------------------------------------------------------------


%% --------------------------------------------------------------------

-define(START_POD_INTERVAL,50).
-define(START_POD_TRIES,50).
-define(STOP_POD_INTERVAL,50).
-define(STOP_POD_TRIES,50).
%% External exports

-export([create/1,delete/1]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create(NodeId)->
    create_pod(NodeId).
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create_pod(PodId)->
    Result= case create_pod_dir(PodId) of
		{ok,PodStr}->
		    case start_pod(PodId,PodStr) of
			{ok,Pod}->
			    {ok,Pod};
			{error,Err}->
			    {error,Err}
		    end;
		{error,Err}->
		    {error,Err}
	    end,
    Result.

start_pod(PodId,PodStr)->
    ErlCmd="erl "++"-sname "++PodStr++" -detached",
    Result= case os:cmd(ErlCmd) of
		[]->
		    case check_if_vm_started(list_to_atom(PodStr),
					     ?START_POD_INTERVAL,
					     ?START_POD_TRIES,error) of
			error->
			    {error,[couldnt_start_pod,PodId,?MODULE,?LINE]};
			ok->
			    {ok,list_to_atom(PodStr)}
		    end;
		Err ->
		    {error,[unknown_error,Err,?MODULE,?LINE]}
	    end,
    Result.			
create_pod_dir(PodId)->
    % Pod='PodId@Host'
    Result=case inet:gethostname() of
	       {ok,Host}->
		   PodStr=PodId++"@"++Host,
		   case filelib:is_dir(PodId) of
		       true->
			   {error,[pod_already_loaded,PodId,?MODULE,?LINE]};
		       false-> 
			   case file:make_dir(PodId) of
			       ok->
				   {ok,PodStr};
   			       Err ->
				   {error,[unknown_error,Err,PodId,?MODULE,?LINE]}
			   end;
		       Err ->
			   {error,[unknown_error,Err,PodId,?MODULE,?LINE]}
		   end;
	       Err ->
		   {error,[unknown_error,Err,PodId,?MODULE,?LINE]}
	   end,
    Result.

check_if_vm_started(_Vm,_Interval,0,ok)->
    ok;
check_if_vm_started(_Vm,_Interval,0,error)->
    error;
check_if_vm_started(_Vm,_Interval,_N,ok) ->
    ok;
check_if_vm_started(Vm,Interval,N,error) ->
    timer:sleep(Interval),
    case net_adm:ping(Vm) of
	pang->
	    NewResult=error;
	pong ->
	    NewResult=ok
    end,
    check_if_vm_started(Vm,Interval,N-1,NewResult).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
delete(PodId)->
    delete_pod(PodId).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
delete_pod(PodId)->
    % Pod='PodId@Host'
    Result=case inet:gethostname() of
	       {ok,Host}->
		   PodStr=PodId++"@"++Host,
		   Pod=list_to_atom(PodStr),
		   rpc:call(Pod,init,stop,[],5000),
		    case check_if_vm_stopped(Pod,?STOP_POD_INTERVAL,
					     ?STOP_POD_TRIES,error) of
			error->
			    {error,[couldnt_stop_pod,PodId,?MODULE,?LINE]};
			ok->
			    RmCmd="rm -rf "++PodId,
			    case os:cmd(RmCmd) of
				[]->
				    {ok,stopped};
				Err ->
				    {error,[unknown_error,Err,?MODULE,?LINE]}
			    end
		    end;
	       {badrpc,Err}->
		   {error,[badrpc,Err,?MODULE,?LINE]};
	       Err ->
		   {error,[unknown_error,Err,?MODULE,?LINE]}
	   end,
    Result.
		       


check_if_vm_stopped(_Vm,_Interval,0,ok)->
    ok;
check_if_vm_stopped(_Vm,_Interval,0,error)->
    error;
check_if_vm_stopped(_Vm,_Interval,_N,ok) ->
    ok;
check_if_vm_stopped(Vm,Interval,N,error) ->
    timer:sleep(Interval),
    case net_adm:ping(Vm) of
	pong->
	    NewResult=error;
	pang->
	    NewResult=ok
    end,
    check_if_vm_stopped(Vm,Interval,N-1,NewResult).
