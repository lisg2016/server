local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local socket = require "socket"
local cluster = require "cluster"

center =  {


    -- 服务间消息
	CMD = {},
}

function center.CMD:login_notify(req)
    print(req)
end


skynet.start(function() 
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = center.CMD[command]
		skynet.ret(skynet.pack(f(center, ...)))
	end)

	skynet.register(svr_config.agentsvr_name(svr_config.harbor_id))	
end)
