local skynet = require "skynet"
local snax = require "snax"
local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local protobuf = require "protobuf"
local sharedata = require "skynet.sharedata"


skynet.start(function()
	print("Server start")
  
	-- 配置
	local cfg_data = require "config.Config"
	sharedata.new("config_data", cfg_data)

	-- 公共服务
	local log = skynet.uniqueservice("log")
		skynet.call(log, "lua", "start")
		local console = skynet.newservice("console")
		skynet.newservice("debug_console",tonumber(skynet.getenv("debug_console_port_"..svr_config.harbor_id)))

	-- 数据库  
	for i = 1, svr_config.db_maxconn do      
		local sqlmgr = skynet.newservice("sql_mgr")
		skynet.call(sqlmgr, "lua", "start", svr_config.mysql_host, svr_config.mysql_user, svr_config.mysql_pwd, svr_config.mysql_db, svr_config.mysql_port, i)
	end
	skynet.newservice("redis_mgr")
	skynet.call(".redismgr", 'lua', 'start')
	
	skynet.newservice('loader')
  
	local center = skynet.uniqueservice("center")
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = svr_config.agent_svr_port[svr_config.harbor_id],
		maxclient = svr_config.agent_gate_num,
		nodelay = true,
	})
	LOG_INFO("%s %d", "Watchdog listen on:", svr_config.agent_svr_port[svr_config.harbor_id])

	skynet.exit()
end)
