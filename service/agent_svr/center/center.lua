local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local socket = require "socket"
local cluster = require "cluster"
require "login_key_mgr"

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

-- 消息处理
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

	center_data.update()
end)
