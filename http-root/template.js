

// let bp_url = 'https://dataexplorer.azure.com/clusters/azcore.centralus/databases/OvlProd?query=';
// let backplane_template = ''+
//                 'let _ContainerId = "";\n'+
//                 'let _NodeId = "PLACEHOLDER_NODEID";\n'+
//                 'let _startTime = datetime(PLACEHOLDER_STARTTIME);\n'+
//                 'let _endTime = datetime(PLACEHOLDER_ENDTIME);\n'+
//                 'let impactedContainerId = tolower(["_ContainerId"]);\n'+
//                 'let impactStartTime =["_startTime"];\n'+
//                 'let impactEndTime = ["_endTime"];\n'+
//                 'let latestNodeId = materialize(cluster("azurehn.kusto.windows.net").database("Azurehn").f_getNodeIdFromContainerId(impactedContainerId, impactStartTime - 6h, impactEndTime + 2h) | project NodeId);\n'+
//                 'let impactedNodeId = tolower(iff(isnotempty(["_NodeId"]), ["_NodeId"], toscalar(latestNodeId)));\n'+
//                 'let socID = toscalar(cluster("azuredcm.kusto.windows.net").database("AzureDCMDb").GetSocOrNodeFromResourceId(impactedNodeId));\n'+
//                 'cluster("azcore.centralus.kusto.windows.net").database("OvlProd").LinuxOverlakeSystemd()\n'+
//                 '| where NodeId =~ socID\n'+
//                 '| where PreciseTimeStamp between (impactStartTime .. impactEndTime)\n'+
//                 '| where _SYSTEMD_UNIT == "backplane.service"\n'+
//                 '| project PreciseTimeStamp, Severity=case(PRIORITY == 2, "Crit", PRIORITY == 3, "Error", PRIORITY == 4, "Warn", PRIORITY == 5, "Notice", PRIORITY == 6, "Info", PRIORITY == 7, "Debug", "Undef"),\n'+
//                 '          MESSAGE, _PID, _SYSTEMD_UNIT\n';


// let sma_url = 'https://dataexplorer.azure.com/clusters/azcore.centralus/databases/OvlProd?query=';
//        let sma_template = ''+
//                'let _ContainerId = "";\n'+
//                'let _NodeId = "PLACEHOLDER_NODEID";\n'+
//                'let _startTime = datetime(PLACEHOLDER_STARTTIME);\n'+
//                'let _endTime = datetime(PLACEHOLDER_ENDTIME);\n'+
//                'let impactedContainerId = tolower(["_ContainerId"]);\n'+
//                'let impactStartTime =["_startTime"];\n'+
//                'let impactEndTime = ["_endTime"];\n'+
//                'let latestNodeId = materialize(cluster("azurehn.kusto.windows.net").database("Azurehn").f_getNodeIdFromContainerId(impactedContainerId, impactStartTime - 6h, impactEndTime + 2h) | project NodeId);\n'+
//                'let impactedNodeId = tolower(iff(isnotempty(["_NodeId"]), ["_NodeId"], toscalar(latestNodeId)));\n'+
//                'let socID = toscalar(cluster("azuredcm.kusto.windows.net").database("AzureDCMDb").GetSocOrNodeFromResourceId(impactedNodeId));\n'+
//                'cluster("azcore.centralus.kusto.windows.net").database("OvlProd").LinuxOverlakeSystemd()\n'+
//                '| where NodeId =~ socID\n'+
//                '| where PreciseTimeStamp between (impactStartTime .. impactEndTime)\n'+
//                '| where _SYSTEMD_UNIT startswith_cs "smagent"\n'+
//                '| project PreciseTimeStamp, Severity=case(PRIORITY == 2, "Crit", PRIORITY == 3, "Error", PRIORITY == 4, "Warn", PRIORITY == 5, "Notice", PRIORITY == 6, "Info", PRIORITY == 7, "Debug", "Undef"),\n'+
//                '          MESSAGE, _PID, _SYSTEMD_UNIT\n';

let bp_url = 'https://dataexplorer.azure.com/clusters/overlakedata.southcentralus/databases/overlake-syslog?query=';
let bp_template = ''+
'let startTime = datetime(PLACEHOLDER_STARTTIME);\n'+
'let endTime   = datetime(PLACEHOLDER_ENDTIME);\n'+
'let socID = toscalar(cluster("azuredcm.kusto.windows.net").database("AzureDCMDb").GetSocOrNodeFromResourceId("PLACEHOLDER_NODEID"));\n'+
'LinuxOverlakeSystemdView\n'+
'| where NodeId =~ socID\n'+
'and (_SYSTEMD_UNIT == "backplane.service" or _SYSTEMD_UNIT contains "systemd")\n'+
'| where TIMESTAMP between (startTime .. endTime)\n'+
'| project PreciseTimeStamp, _SYSTEMD_UNIT, _PID, MESSAGE, _HOSTNAME\n'+
'//| summarize min(PreciseTimeStamp) by _PID\n'+
	'';
let bp_template_name = ''+
'let startTime = datetime(PLACEHOLDER_STARTTIME);\n'+
'let endTime   = datetime(PLACEHOLDER_ENDTIME);\n'+
'LinuxOverlakeSystemdView\n'+
'| where _HOSTNAME contains "PLACEHOLDER_NODEID"\n'+
'and (_SYSTEMD_UNIT == "backplane.service" or _SYSTEMD_UNIT contains "systemd")\n'+
'| where TIMESTAMP between (startTime .. endTime)\n'+
'| project PreciseTimeStamp, _SYSTEMD_UNIT, _PID, MESSAGE, _HOSTNAME\n'+
'//| summarize min(PreciseTimeStamp) by _PID\n'+
	'';


let sma_url = 'https://dataexplorer.azure.com/clusters/overlakedata.southcentralus/databases/overlake-syslog?query=';
let sma_template = ''+
'let startTime = datetime(PLACEHOLDER_STARTTIME);\n'+
'let endTime   = datetime(PLACEHOLDER_ENDTIME);\n'+
'let socID = toscalar(cluster("azuredcm.kusto.windows.net").database("AzureDCMDb").GetSocOrNodeFromResourceId("PLACEHOLDER_NODEID"));\n'+
'LinuxOverlakeSystemdView\n'+
'| where NodeId =~ socID\n'+
'and (_SYSTEMD_UNIT contains "smagent" or _SYSTEMD_UNIT contains "systemd")\n'+
'| where TIMESTAMP between (startTime .. endTime)\n'+
'| project PreciseTimeStamp, _SYSTEMD_UNIT, _PID, MESSAGE, _HOSTNAME\n'+
'//| summarize min(PreciseTimeStamp) by _PID\n'+
	'';
let sma_template_name = ''+
'let startTime = datetime(PLACEHOLDER_STARTTIME);\n'+
'let endTime   = datetime(PLACEHOLDER_ENDTIME);\n'+
'LinuxOverlakeSystemdView\n'+
'| where _HOSTNAME contains "PLACEHOLDER_NODEID"\n'+
'and (_SYSTEMD_UNIT == "smagent.service" or _SYSTEMD_UNIT contains "systemd")\n'+
'| where TIMESTAMP between (startTime .. endTime)\n'+
'| project PreciseTimeStamp, _SYSTEMD_UNIT, _PID, MESSAGE, _HOSTNAME\n'+
'//| summarize min(PreciseTimeStamp) by _PID\n'+
	'';








