%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(log). 
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("kernel/include/file.hrl").
-include("common_macros.hrl").
%% --------------------------------------------------------------------
-define(SYSLOG_DIR,"logfiles").
-define(MAX_SIZE,1*1000*1000).
%-define(MAX_SIZE,4*100).
-define(LATEST_LOG,"latest.log").

%% External exports

%Severity  emerency,critical,error,warning,notice,info,debug



-export([init_logfile/0,store/1,
	 all/0,
	 severity/1,node/3,module/1,
	 latest_event/0,latest_events/1,
	 year/1,month/2,day/3
	]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
day(Y,M,D)->
    {ok,Info}=file:consult(?LATEST_LOG),
    L=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
	S#syslog_info.pod,S#syslog_info.module,
	S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-Info],
    day(Y,M,D,L,[]).

day(_,_,_,[],Result)->
    Result;
day(Y,M,D,[{{Y1,M1,D1},Time,IpAddr,Port,Pod,Module,Line,Severity,Msg}|T],Acc) ->
    NewAcc=case {Y,M,D}=={Y1,M1,D1} of
	       true->
		   [{{Y1,M1,D1},Time,IpAddr,Port,Pod,Module,Line,Severity,Msg}|Acc];
	       false->
		   Acc
	   end,
    day(Y,M,D,T,NewAcc).

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
month(Y,M)->
    {ok,Info}=file:consult(?LATEST_LOG),
    L=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
	S#syslog_info.pod,S#syslog_info.module,
	S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-Info],
    month(Y,M,L,[]).

month(_,_,[],Result)->
    Result;
month(Y,M,[{{Y1,M1,D},Time,IpAddr,Port,Pod,Module,Line,Severity,Msg}|T],Acc) ->
    NewAcc=case {Y,M}=={Y1,M1} of
	       true->
		   [{{Y1,M1,D},Time,IpAddr,Port,Pod,Module,Line,Severity,Msg}|Acc];
	       false->
		   Acc
	   end,
    month(Y,M,T,NewAcc).
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
year(Y)->
    {ok,Info}=file:consult(?LATEST_LOG),
    L=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
	S#syslog_info.pod,S#syslog_info.module,
	S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-Info],
    year(Y,L,[]).

year(_,[],Result)->
    Result;
year(Y,[{{Y1,M,D},Time,IpAddr,Port,Pod,Module,Line,Severity,Msg}|T],Acc) ->
    NewAcc=case Y==Y1 of
	       true->
		   [{{Y1,M,D},Time,IpAddr,Port,Pod,Module,Line,Severity,Msg}|Acc];
	       false->
		   Acc
	   end,
    year(Y,T,NewAcc).

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
latest_events(N)->
    {ok,Info}=file:consult(?LATEST_LOG),
    SubList=lists:sublist(Info,N),
    NicePrint=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
		 S#syslog_info.pod,S#syslog_info.module,
		 S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-SubList],
    NicePrint.
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
latest_event()->
    latest_events(1).
   
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
all()->
    {ok,Info}=file:consult(?LATEST_LOG),
   NicePrint=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
		S#syslog_info.pod,S#syslog_info.module,
		S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-Info],
    NicePrint.
  
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
node(IpAddr,Port,Pod)->
    {ok,Info}=file:consult(?LATEST_LOG),
    
    NicePrint=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
		S#syslog_info.pod,S#syslog_info.module,
		S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-Info,
	      {S#syslog_info.ip_addr,S#syslog_info.port,S#syslog_info.pod}=={IpAddr,Port,Pod}],
    NicePrint.

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
module(Module)->
    {ok,Info}=file:consult(?LATEST_LOG),
    NicePrint=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
	       S#syslog_info.pod,S#syslog_info.module,
	       S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-Info,
										 S#syslog_info.module==Module],
    NicePrint.
						     

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
severity(Severity)->
    {ok,Info}=file:consult(?LATEST_LOG),
    NicePrint=[{S#syslog_info.date,S#syslog_info.time,S#syslog_info.ip_addr,S#syslog_info.port,
		S#syslog_info.pod,S#syslog_info.module,
		S#syslog_info.line,S#syslog_info.severity,S#syslog_info.message}||S<-Info,
										  S#syslog_info.severity==Severity],
    NicePrint.			     


%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_logfile()->
% check if logfiles dir exists
    case filelib:is_dir(?SYSLOG_DIR) of
	false->
	    file:make_dir(?SYSLOG_DIR);
	true->
	    true
    end,
    % Check if there is an latest file and if it's > 5Mb 
    
    Result=check_size_log_file(),
    Result.
    
	    
	    
check_size_log_file()->		    
    Result=case file:read_file_info(?LATEST_LOG) of
	       {ok,Facts}->
		   if
		       Facts#file_info.size>?MAX_SIZE->
			   {{Y,M,D},{H,Min,S}}={date(),time()},
			   Time=string:join([integer_to_list(H),integer_to_list(Min),integer_to_list(S)],":"),
			   Date=string:join([integer_to_list(Y),integer_to_list(M),integer_to_list(D)],"-"),
			   F1=string:join([Date,Time],"_"),
			   FileName=string:join([F1,".log"],""),
			   {ok,_}=file:copy(?LATEST_LOG,filename:join(?SYSLOG_DIR,FileName)),
			   file:delete(?LATEST_LOG),
			   {ok,FS}=file:open(?LATEST_LOG,read_write),
			   file:close(FS),
			   ok;
		       true ->
			   ok
		   end;
	       {error,enoent}->
		   {ok,S}=file:open(?LATEST_LOG,read_write),
		   file:close(S),
		   ok;
	       Err->
		   {error,[date(),time(),node(),?MODULE,?LINE,error,["unknown_error",Err]]}
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
store(SysLogInfo)->
    ok=check_size_log_file(),
    {ok,Info}=file:consult(?LATEST_LOG),
    {ok,S}=file:open(?LATEST_LOG,write),
    NewContent=[SysLogInfo|Info],
    lists:foreach(fun(X)->io:format(S,"~p.~n",[X]) end,NewContent),
    file:close(S),
    {ok,stored}.
			      
