%% This is the application resource file (.app file) for the 'base'
%% application.
{application, dns_service,
[{description, "dns_service  " },
{vsn, "1.0.0" },
{modules, 
	  [dns_service_app,dns_service_sup,dns_service,dns_lib]},
{registered,[dns_service]},
{applications, [kernel,stdlib]},
{mod, {dns_service_app,[]}},
{start_phases, []}
]}.
