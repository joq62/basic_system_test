%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(node_controller_test_cases). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
-include("master_service_tests.hrl").
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
	   

start()->
  %  cleanup(),
    ?assertEqual(ok,update_test()),
%    ?assertEqual(ok,status_test()),
 %   ?assertEqual(ok,delete_test()),
    

    cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
update_test()->
    {ok,I}=file:consult("node.config"),
    ComputerList=proplists:get_value(computer_list,I),
    % start test master
    [master_service:update_node_info(IpAddr,Port,Mode,no_status_info)||{_VmName,IpAddr,Port,Mode}<-ComputerList],
    ?assertEqual(["pod_lgh_2",
		  "pod_lgh_1",
		  "pod_landet_1"],[VmName||{VmName,_}<-master_service:read_node_info(all)]),
    
  
    ?assertMatch({availible,
		  [{"pod_lgh_2",_},
		   {"pod_lgh_1",_},
		   {"pod_landet_1",_}],
		  missing,
		  [{"glurk",_}]},master_service:node_availability(all)),
  %  {availible,Availible,missing,Missing}=master_service:node_availability(all),
    
    
    

    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
cleanup()->
  
   ok. 
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
