%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(etcd). 
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common_macros.hrl").
%% --------------------------------------------------------------------
%% Data Type
%% --------------------------------------------------------------------
-define(NODE_INFO_FILE,"node_info.dets").
-define(APP_INFO_FILE,"app_info.dets").
-define(STATUS_INFO_FILE,"status_info.dets").

-define(NODE_DETS,?NODE_INFO_FILE,[{type,set}]).
-define(APP_DETS,?APP_INFO_FILE,[{type,set}]).
-define(STATUS_DETS,?STATUS_INFO_FILE,[{type,set}).


%% --------------------------------------------------------------------

%% External exports

%-export([create/2,delete/2]).

-compile(export_all).

%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
create_file(File,Args)->
    case filelib:is_file(File) of 
	true->
	    {ok,file_already_exsist};
	false->
	    {ok,Descriptor}=dets:open_file(File,Args),
	    dets:close(Descriptor),
	    {ok,Descriptor}
    end.


delete_file(File)->
    case filelib:is_file(File) of 
	true->
	    file:delete(File),
	    {ok,file_deleted};
	false->
	    {ok,file_not_exist}
    end.

exists_file(File)->
    filelib:is_file(File).

%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
delete(File,Key)->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    case dets:lookup(Descriptor, Key) of
		[]->
		    Reply = {error,no_entry};
		X->
		    Reply=dets:delete(Descriptor, Key)
	    end,
	    dets:close(Descriptor);
	false->
	    Reply = {error,no_file}
    end.


update(File,Key,Value)->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    ok=dets:insert(Descriptor, {Key,Value}),
	    dets:close(Descriptor),
	    ok;
	false->
	    {error,[eexits,File]}
    end.

read(File,Key)->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    Value=dets:lookup(Descriptor, Key),
	    dets:close(Descriptor),
	    {ok,Value};
	false->
	    {error,[eexits,File]}
    end.



all(File)->
    case filelib:is_file(File) of 
	true->
	    {ok,Descriptor}=dets:open_file(File),
	    Key=dets:first(Descriptor),
	    Reply=get_all(Descriptor,Key,[]),
	    dets:close(Descriptor),
	    Reply;
	false->
	    {error,[eexits,File]}
    end.


get_all(_Desc,'$end_of_table',Acc)->
    {ok,Acc};
get_all(Desc,Key,Acc)->  
    Status=dets:lookup(Desc, Key),
    Acc1=lists:append(Status,Acc),
    Key1=dets:next(Desc,Key),
    get_all(Desc,Key1,Acc1).
