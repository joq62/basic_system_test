%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dns_service_tests). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
%% --------------------------------------------------------------------

-define(TEST_VECTOR,[{"s1","ip1",1},{"s11","ip1",2},
		     {"s2","ip2",1},{"s21","ip1",1},
		     {"s3","ip1",2},{"s21","ip1",1},
		     {"s1","ip2",1},{"s21","ip2",1}]).

%% External exports
%-export([start/0]).
-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
cases_test()->
    clean_start(),
    add_services(),
    get_services_1(),
    delete_services(),
    get_services_2(),
    cd_dir(),
    clean_stop().


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start()->
    spawn(fun()->eunit:test({timeout,1*60,dns_service}) end).

clean_start()->
    ok=application:start(dns_service),
    ok.

clean_stop()->
    application:stop(dns_service),
    timer:sleep(1000),
    init:stop(),
    ok.



%% --------------------------------------------------------------------
%% Function:support functions
%% Description: Stop eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
cd_dir()->
    {ok,Cwd}=file:get_cwd(), 
    Parent=self(),
    spawn(fun()->do_cd(filename:join([Cwd,"dir_1"]),Parent) end),
    receive
	ok->
	    ok
    end,
    c:cd(Cwd),
    ?assertEqual({ok,Cwd},file:get_cwd()),
    os:cmd("mkdir "++"test_22"),
    ok.

do_cd(Path,Parent)->
    c:cd(Path),
    {ok,Cwd}=file:get_cwd(), 
    ?assertEqual(Cwd,Path),
    file:make_dir("test_22"),
    Parent!ok,
    ok.
    
    
    

%% --------------------------------------------------------------------
%% Function:support functions
%% Description: Stop eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
delete_services()->
    dns_service:delete("s21","ip2",1),
    dns_service:delete("s3","ip1",2),
    dns_service:delete("s1","glurk",1),    
    ok.


add_services()->
    [dns_service:add(S,I,P)||{S,I,P}<-?TEST_VECTOR],
    [dns_service:add(S,I,P)||{S,I,P}<-?TEST_VECTOR],
    ok.

get_services_2()->
    ?assertEqual([{"s1","ip2",1},
                      {"s21","ip1",1},
                      {"s2","ip2",1},
                      {"s11","ip1",2},
                      {"s1","ip1",1}]  ,dns_service:all()),
   ?assertEqual([{"ip1",1}],dns_service:get("s21")),
		
   ?assertEqual([],dns_service:get("s3")),
   ?assertEqual([],dns_service:get("glurk")),
   ?assertEqual([{"ip2",1},
		 {"ip1",1}],dns_service:get("s1")), 
    ok.

get_services_1()->
    ?assertEqual([{"s21","ip2",1},
		  {"s1","ip2",1},
		  {"s21","ip1",1},
		  {"s3","ip1",2},
		  {"s2","ip2",1},
		  {"s11","ip1",2},
		  {"s1","ip1",1}],dns_service:all()),
   ?assertEqual([{"ip2",1},
		 {"ip1",1}],dns_service:get("s21")),
		
   ?assertEqual([{"ip1",2}],dns_service:get("s3")),
   ?assertEqual([],dns_service:get("glurk")),    
    ok.
    
