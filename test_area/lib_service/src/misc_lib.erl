%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(misc_lib).
  


%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------

%% External exports
%-export([unconsult/2,
%	 get_node_by_id/1,get_vm_id/0,get_vm_id/1,
%	 app_start/1
%	]).
	 

-export([unconsult/2,get_node_by_id/1,get_vm_id/0,get_vm_id/1,
	 app_start/1,log_event/4]).
%-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
log_event(Module,Line,Severity,Info)->
    SysLog=#syslog_info{date=date(),
			time=time(),
			ip_addr=na,
			port=na,
			pod=node(),
			module=Module,
			line=Line,
			severity=Severity,
			message=Info
		       },
    case tcp_client:call(?DNS_ADDRESS,{dns_service,get,["log_service"]}) of
	[]->
	    {error,[eexists,"log_service"]};
	IpAddresses->
	    [{IpAddr,Port}|_]=IpAddresses,
	    tcp_client:call({IpAddr,Port},{log_service,store,[SysLog]})
    end.

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

unconsult(File, L) ->
    {ok, S} = file:open(File, write),
    lists:foreach(fun(X) -> io:format(S, "~p.~n",[X]) end, L),
    file:close(S).

%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
get_node_by_id(Id)->
    {ok,Host}=inet:gethostname(),
    list_to_atom(Id++"@"++Host).

get_vm_id()->
    get_vm_id(node()).
get_vm_id(Node)->
    % "NodeId@Host
    [NodeId,Host]=string:split(atom_to_list(Node),"@"), 
    {NodeId,Host}.
    
    
%% --------------------------------------------------------------------
%% Function: 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
app_start(Module)->
    Result=case rpc:call(node(),lib_service,dns_address,[],5000) of
	      {error,Err}->
		   {error,[eexists,dns_address,Err,?MODULE,?LINE]};
	      {DnsIpAddr,DnsPort}->
		   {MyIpAddr,MyPort}=lib_service:myip(),
		   {ok,Socket}=tcp_client:connect(DnsIpAddr,DnsPort),
		   ok=rpc:call(node(),tcp_client,cast,[Socket,{dns_service,add,[atom_to_list(Module),MyIpAddr,MyPort,node()]}]),
		   {ok,[{MyIpAddr,MyPort},{DnsIpAddr,DnsPort},Socket]};
	       Err ->
		   {error,[unmatched,Err,?MODULE,?LINE]}
	  end,   
    Result.
    
