%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(app_controller_test_cases). 
   
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
    

 %   cleanup(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
update_test()->
    {ok,Files}=file:list_dir("appfiles"),
    AppInfoList=[file:consult(filename:join("appfiles",File))||File<-Files,filename:extension(File)=:=".spec"],

   %  ?assertEqual(glurk,AppInfoList),
    [master_service:update_app_info(ServiceId,Num,Nodes,Source,not_loaded)||{ok,
									     [{service,ServiceId},
									      {num_instances,Num},
									      {nodes,Nodes},
									      {source,Source}
									     ]
									    }<-AppInfoList],
    %Check that they are not  available
    
    ?assertMatch({availible,[],
		  missing,[{"divi_service",_},
			   {"adder_service",glurk}],
		  remove,[]},master_service:app_availability(all)),

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
