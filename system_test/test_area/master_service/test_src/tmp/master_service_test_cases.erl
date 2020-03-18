%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(master_service_test_cases). 
   
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
start_master_service()->
    master_service_tests:start_service(lib_service),
    master_service_tests:check_started_service(lib_service),
    ok=application:start(master_service),
    
    ?assertEqual({pong,master_service_test@asus,master_service},master_service:ping()),

    ok.

% Data structures 
% ComputerName: computer_1..
% IpAddr,Port
% Mode
% WorkerStartPort 
% NumWorkers
% Source  {dir, Path
% Files to load
%


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
test_adder_divi()->
 %   [{"pod_master",CInfo}]=ets:lookup(?ETS,"pod_master"),
 %   DnsIpAddr=CInfo#node_info.ip_addr,
 %   DnsPort=CInfo#node_info.port,
    AdderList=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["adder_service"]}),
    DiviList=tcp_client:call(?DNS_ADDRESS,{dns_service,get,["divi_service"]}),
    [{IpAdder,PortAdder,_}|_]=AdderList,
  %  42=tcp_client:call({IpAdder,PortAdder},{adder_service,add,[20,22]}),
    
    ?assertEqual([{42},{42}],[{tcp_client:call({IpAddr,Port},{adder_service,add,[20,22]})}||{IpAddr,Port,_}<-AdderList]),
    ?assertEqual([{42.0}],[{tcp_client:call({IpAddr,Port},{divi_service,divi,[420,10]})}||{IpAddr,Port,_}<-DiviList]),
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
update_dns()->
    [{"pod_master",CInfo}]=ets:lookup(?ETS,"pod_master"),
    DnsIpAddr=CInfo#node_info.ip_addr,
    DnsPort=CInfo#node_info.port,
%    ?assertEqual(glurk,ets:lookup(?ETS,started_services)),
    [{started_services,AppInfoList}]=ets:lookup(?ETS,started_services),
    ?assertEqual([[{vm,pod_landet_1@asus},
		   {vm_name,"pod_landet_1"},
		   {ip_addr,"localhost"},
		   {port,50100},
		   {service,"adder_service"}],
		  [{vm,pod_lgh_1@asus},
		   {vm_name,"pod_lgh_1"},
		   {ip_addr,"localhost"},
		   {port,40100},
		   {service,"adder_service"}],
		  [{vm,pod_lgh_2@asus},
		   {vm_name,"pod_lgh_2"},
		   {ip_addr,"localhost"},
		   {port,40200},
		   {service,"divi_service"}
		  ]
		 ],AppInfoList),
    [tcp_client:call({DnsIpAddr,DnsPort},{dns_service,add,[proplists:get_value(service,AppInfo),proplists:get_value(ip_addr,AppInfo),
							  proplists:get_value(port,AppInfo),glurk]})||AppInfo<-AppInfoList],
    ?assertEqual([{"localhost",50100,glurk},
		  {"localhost",40100,glurk}],tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["adder_service"]})),
    ?assertEqual([{"localhost",40200,glurk}],
		 tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["divi_service"]})),
    
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_apps()->
    [{appfiles,AppInfoList}]=ets:lookup(?ETS,appfiles),
 %   ?assertMatch([],AppInfoList),
%    ?assertEqual(glurk,[AppInfo||AppInfo<-AppInfoList]),
   % StartResult=[start_apps(AppInfo)||AppInfo<-AppInfoList],
    StartResult=lists:append([start_apps(AppInfo)||AppInfo<-AppInfoList]),
  %  ?assertEqual(glurk,[AppInfo||{R,AppInfo}<-StartResult]),
  %  ?assertEqual(glurk,[AppInfo||{R,AppInfo}<-StartResult,R=:=ok]),
   % ?assertEqual(glurk,[{R,Service}||{R,[_,_,_,_,{service,Service}]}<-StartResult,R=/=ok]),
   
    
    StartedServices=[AppInfo||{R,AppInfo}<-StartResult,R=:=ok],
    ?assertEqual([[{vm,pod_landet_1@asus},
		   {vm_name,"pod_landet_1"},
		   {ip_addr,"localhost"},
		   {port,50100},
		   {service,"adder_service"}],
		  [{vm,pod_lgh_1@asus},
		   {vm_name,"pod_lgh_1"},
		   {ip_addr,"localhost"},
		   {port,40100},
		   {service,"adder_service"}],
		  [{vm,pod_lgh_2@asus},
		   {vm_name,"pod_lgh_2"},
		   {ip_addr,"localhost"},
		   {port,40200},
		   {service,"divi_service"}
		  ]
		 ],StartedServices),
    NotStartedServices=[AppInfo||{R,AppInfo}<-StartResult,R=/=ok],
    PingTest=[{tcp_client:call({IpAddr,Port},{list_to_atom(ServiceId),ping,[]}),IpAddr,Port,ServiceId}||[{vm,_Vm},
										 {vm_name,_VmName},
										 {ip_addr,IpAddr},
										 {port,Port},
										 {service,ServiceId}]<-NotStartedServices],
    ServicesRemove=[{IpAddr,Port,ServiceId}||{{badrpc,_},IpAddr,Port,ServiceId}<-PingTest],
    
 %   ?assertEqual(glurk,RemoveService),
    ets:insert(?ETS,{started_services,StartedServices}),
    
    ets:insert(?ETS,{services_remove,ServicesRemove}),
    
    

    ok.

start_apps(AppInfo) ->
    ServiceId=proplists:get_value(service,AppInfo),
    Source=proplists:get_value(source,AppInfo),
    UpdatedAppInfo=[{VmName,tcp_client:call({IpAddr,Port},{erlang,node,[]}),IpAddr,Port,ServiceId,Source}||{VmName,IpAddr,Port}<-proplists:get_value(nodes,AppInfo)],
    Result=[{tcp_client:call({IpAddr,Port},{container,create,[Vm,VmName,[{{service,ServiceId2},
									  Source2}]]}),[{vm,Vm},{vm_name,VmName},{ip_addr,IpAddr},
											{port,Port},{service,ServiceId2}]}
	    ||{VmName,Vm,IpAddr,Port,ServiceId2,Source2}<-UpdatedAppInfo],
    
    Result.
	      
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
store_app_files()->
    {ok,Files}=file:list_dir("appfiles"),
    AppInfo=[file:consult(filename:join("appfiles",File))||File<-Files,filename:extension(File)=:=".spec"],
    InfoList=[Info||{ok,Info}<-AppInfo],
    ets:insert(?ETS,{appfiles,InfoList}),
    %?assertMatch([{appfiles,_}],ets:lookup(?ETS,appfiles)),
    ok.
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_dns()->
    [{"pod_master",CInfo}]=ets:lookup(?ETS,"pod_master"),
    Vm=CInfo#node_info.vm,
    VmName=CInfo#node_info.vm_name,
    Source={dir,"/home/pi/erlang/simple_d/source"},
    ?assertEqual(ok,container:create(Vm,VmName,[{{service,"dns_service"},
						  Source}
						])),
    DnsIpAddr=CInfo#node_info.ip_addr,
    DnsPort=CInfo#node_info.port,
    ?assertEqual(true,tcp_client:call({DnsIpAddr,DnsPort},{dns_service,add,["glurk_service","glurkIp",666,glurk_vm]})),
     ?assertEqual([{"glurkIp",666,glurk_vm}],tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["glurk_service"]})),
    ?assertEqual(true,tcp_client:call({DnsIpAddr,DnsPort},{dns_service,add,["glurk_service","glurkIp",999,glurk_vm_2]})),
    ?assertEqual([{"glurkIp",666,glurk_vm},{"glurkIp",999,glurk_vm_2}]
		,tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["glurk_service"]})),
    ?assertEqual(true,tcp_client:call({DnsIpAddr,DnsPort},{dns_service,delete,["glurk_service","glurkIp",666,glurk_vm]})),
    ?assertEqual([{"glurkIp",999,glurk_vm_2}],tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["glurk_service"]})),
    ?assertEqual(true,tcp_client:call({DnsIpAddr,DnsPort},{dns_service,delete,["glurk_service","glurkIp",999,glurk_vm_2]})),
    ?assertEqual([],tcp_client:call({DnsIpAddr,DnsPort},{dns_service,get,["glurk_service"]})),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start_computer_pods()->
    [{_,ComputerVmList}]=ets:lookup(?ETS,computer_vm_list),
    
    % Create computer pods
    ?assertEqual([{ok,pod_landet_1@asus},
		  {ok,pod_lgh_1@asus},
		  {ok,pod_lgh_2@asus}],[pod:create(node(),VmName)||{VmName,_}<-ComputerVmList]),
    
    % Load lib_service on each computer pod
  %  ?assertEqual([ok,ok,ok,ok],[container:create(Vm,VmName,[{{service,"lib_service"},
%							  {dir,"/home/pi/erlang/simple_d/source"}}
%							])||{VmName,Vm}<-ComputerVmList]),
    
    ?assertEqual([ok,ok,ok],[container:create(Vm,VmName,[{{service,"lib_service"},
							  {dir,"/home/pi/erlang/simple_d/source"}}
							])||{VmName,Vm}<-ComputerVmList]),
    % check that lib_service is started
    ?assertEqual([{pong,pod_landet_1@asus,lib_service},
		  {pong,pod_lgh_1@asus,lib_service},
		  {pong,pod_lgh_2@asus,lib_service}],[rpc:call(Vm,lib_service,ping,[])||{_,Vm}<-ComputerVmList]),

   % start computer_service

    

   % start tcp server on each computer pod
    [{computer_list,ComputerList}]=ets:lookup(?ETS,computer_list),
    ?assertEqual([ok,ok,ok],[rpc:call(CInfo#node_info.vm,lib_service,start_tcp_server,
			     [CInfo#node_info.ip_addr,CInfo#node_info.port,CInfo#node_info.mode])
		    ||{CId,CInfo}<-ComputerList]),

    ?assertEqual([{pong,pod_landet_1@asus,lib_service},
		  {pong,pod_lgh_1@asus,lib_service},
		  {pong,pod_lgh_2@asus,lib_service}],
		 [tcp_client:call({CInfo#node_info.ip_addr,CInfo#node_info.port},{lib_service,ping,[]})||{CId,CInfo}<-ComputerList]),
    
    ok.
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------              
create_vm_info({VmName,IpAddr,Port,Mode})->
    {ok,Host}=inet:gethostname(),
    Vm=list_to_atom(VmName++"@"++Host),
    {VmName,#node_info{vm_name=VmName,vm=Vm,ip_addr=IpAddr,port=Port,mode=Mode}}.
