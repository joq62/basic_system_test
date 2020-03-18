%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(catalog_test). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").

%% --------------------------------------------------------------------
-compile(export_all).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:emulate loader
%% Description: requires pod+container module
%% Returns: non
%% --------------------------------------------------------------------
% {"pod_landet_1",'pod_landet_1@asus',"localhost",50100}.
start()->
    ?assertEqual([{dir,"adder_service",
		   "/home/pi/erlang/simple_d/source/adder_service"},
		  {dir,"boot_service",
		   "/home/pi/erlang/simple_d/source/boot_service"}],master_service:catalog()),
   
    ?assertEqual({dir,"boot_service",
		  "/home/pi/erlang/simple_d/source/boot_service"},
		 lists:keyfind("boot_service",2,master_service:catalog())),
   

    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
