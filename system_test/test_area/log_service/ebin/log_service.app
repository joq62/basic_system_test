%% This is the application resource file (.app file) for the 'base'
%% application.
{application, log_service,
[{description, "log_service  " },
{vsn, "1.0.0" },
{modules, 
	  [log_service_app,log_service_sup,log_service,log]},
{registered,[log_service]},
{applications, [kernel,stdlib]},
{mod, {log_service_app,[]}},
{start_phases, []}
]}.
