%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(log_service_test_cases). 
   
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
%-record(syslog_info,{date,time,ip_addr,port, pod,module,line, severity, message }).

store_all_severity()->
    E1=#syslog_info{date=d1,time=t1,ip_addr=na,port=na,pod=node,module=m1,line=l1,severity=error,message=["test 1",glurk]},
    E2=#syslog_info{date=d1,time=t1,ip_addr=na,port=na,pod=node,module=m2,line=l2,severity=warning,message=["test 2",glurk]},
    E3=#syslog_info{date=d1,time=t1,ip_addr=na,port=na,pod=node,module=m3,line=l3,severity=info,message=["test 3",glurk]},
    E4=#syslog_info{date=d1,time=t1,ip_addr=na,port=na,pod=node,module=m4,line=l4,severity=info,message=["test 4",glurk]},
    log_service:store(E1),
    log_service:store(E2),
    log_service:store(E3),     
    log_service:store(E4),

    ?assertMatch([{d1,t1,na,na,node,m4,l4,info,["test 4",glurk]},
                      {d1,t1,na,na,node,m3,l3,info,_},
                      {d1,t1,na,na,node,m2,l2,warning,_},
                      {d1,t1,na,na,node,m1,l1,error,_}],log_service:all()),

    [{d1,t1,na,na,node,m1,l1,error,["test 1",glurk]}]=log_service:severity(error),
    []=log_service:severity(glurk),
    ok.

latest_event_node_module()->
  [{{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]}
  ]=log_service:latest_event(),
    
    [{{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]},
     {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]},
     {{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]}
    ]=log_service:latest_events(3),

   [{{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]}
   ]=log_service:node(ipaddr2,port2,pod2),
    [{{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]}
    ]=log_service:module(module_1),
    ok.

date_day_month_year()->
    [{{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]},
     {{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]},
     {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]},
     {{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]}
    ]=log_service:year(2019),

   [{{2019,10,20}, {22,0,10},ipaddr1,port1,pod1,module_1,1,error, ["test 1",glurk]},
    {{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning, ["test 2",glurk]},
    {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]},
    {{2019,10,21},{13,10,0},ipaddr4,port4,pod4,module_4,4,warning,["test 4",glurk]}
   ]=log_service:month(2019,10),
    
    [{{2019,10,20},{22,0,10},ipaddr1,port1,pod1,module_1,1,error,["test 1",glurk]},
     {{2019,10,20},{22,0,0},ipaddr1,port1,pod1,module_3,3,info,["test 3",glurk]}
    ]=log_service:day(2019,10,20),
    [{{2019,10,10},{1,32,55},ipaddr2,port2,pod2,module_2,2,warning,["test 2",glurk]}]=log_service:day(2019,10,10),
    ok.
