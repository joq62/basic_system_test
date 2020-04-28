%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(misc_test). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
%% --------------------------------------------------------------------



-compile(export_all).



%% ====================================================================
%% External functions


%------------------ misc_lib -----------------------------------
-define(SERVER_ID,"test_misc_lib").

start()->
    node_by_id(),
    unconsult(),
    pmap(),
    ok.



pmap()->
    
    L=[[1,2],[4,5],[10,11]],
    ?assertMatch([21,9,3],misc_lib:pmap(fun adder/1,L)),

    L1=[{"joqhome.dynamic-dns.net",40200},{"joqhome.dynamic-dns.net",40200},
	{"joqhome.dynamic-dns.net",40200},{"joqhome.dynamic-dns.net",40200},
	{"joqhome.dynamic-dns.net",40200}],

    S=self(),
    Ref=erlang:make_ref(),
    PidList=[spawn(fun()-> do_fn(S,Ref,I) end)||I<-L1],
    N=length(PidList),
    ?assertMatch([{error,_},{error,_},
		  {error,_},{error,_},{error,_}],gather(N,Ref,[])).

adder([A,B])->
    A+B.


do_fn(Parent,Ref,I)->
    Parent!{Ref,catch(tcp_client:call(I,{lib_service,ping,[]},5000))}.

gather(0,_,Result)->
    Result;
gather(N,Ref,Acc) ->
    receive
	{Ref,Ret}->
	    gather(N-1,Ref,[Ret|Acc])
    end.
	

node_by_id()->
    {ok,Host}=inet:gethostname(),
    PodIdServer=?SERVER_ID++"@"++Host,
    PodServer=list_to_atom(PodIdServer),
    ?assertEqual(PodServer,misc_lib:get_node_by_id(?SERVER_ID)).


unconsult()->
    L=[{vm_name,"pod_computer_1"},
       {vm,'pod_computer_1@asus'},
       {ip_addr,"localhost"},
       {port,40100},
       {mode,parallell},
       {worker_start_port,40101},
       {num_workers,5}],
    misc_lib:unconsult("computer_1.config",L),
    ?assertEqual({ok,[{vm_name,"pod_computer_1"},
		      {vm,'pod_computer_1@asus'},
		      {ip_addr,"localhost"},
		      {port,40100},
		      {mode,parallell},
		      {worker_start_port,40101},
		      {num_workers,5}]},file:consult("computer_1.config")),
    file:delete("computer_1.config"),
    ok.
