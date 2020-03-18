%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : 
%%% Three computers 
%%% {"pod_computer_1", "localhost",40100,parallell, 40101, 10}
%%% {"pod_computer_2", "localhost" 40200,parallell, 40201, 10}
%%% {"pod_computer_3", "localhost" 40300,parallell, 40301,10}
%%% Each pod has its port number as vm name pod_40101@asus
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(log_service_tests). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
%% --------------------------------------------------------------------

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
    eunit_start(),
    
    log_service_test_cases:store_all_severity(),
    
    clean_stop(),
    eunit_stop().


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start()->
    spawn(fun()->eunit:test({timeout,30,log_service}) end).

clean_start()->
    os:cmd("rm latest.log"),
    ok=application:start(lib_service),
    ok=application:start(log_service),
    
    ok.
eunit_start()->
    
    ok.

clean_stop()->
    ok.

eunit_stop()->
    stop_service(lib_service),
    stop_service(log_service),
    timer:sleep(1000),
    init:stop().

%% --------------------------------------------------------------------
%% Function:support functions
%% Description: Stop eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

start_service(Service)->
    ?assertEqual(ok,application:start(Service)).
check_started_service(Service)->
    ?assertMatch({pong,_,Service},Service:ping()).
stop_service(Service)->
    ?assertEqual(ok,application:stop(Service)),
    ?assertEqual(ok,application:unload(Service)).

