local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local socket = require "socket"
local cluster = require "cluster"
local login_key_mgr = require "login_key_mgr"
local offline_mgr = require "offline_mgr"
local online_mgr = require "online_mgr"


center_interface = {
    -- 服务间消息
	CMD = {},
}

center_data =  {
	login_agent_id = {},
	login_player_id = {},
}
setmetatable(center_data, {__index = center_interface})

center_data.login_key_mgr = login_key_mgr:new()
center_data.offline_mgr = offline_mgr:new(10)
center_data.online_mgr = online_mgr:new()

-- 消息处理
require "center_init"
require "center_login"

-- 定时器
function center_data.update()
    skynet.timeout(20, center_data.update)

	center_data.login_key_mgr:update()
end

skynet.start(function() 
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = center_interface.CMD[command]
		skynet.ret(skynet.pack(f(center_data, ...)))
	end)

	skynet.register(svr_config.agentsvr_name(svr_config.harbor_id))	

	center_interface.init(center_data)

	center_data.update()
end)
