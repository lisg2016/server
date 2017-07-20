local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local protobuf = require "protobuf"
local sharedata = require "skynet.sharedata"
local os = require "os"


agent_data = {
	-- service
	WATCHDOG = nil,
	center = nil,
	gate = nil,

	client_fd = 0,
    login_time = 0,
	recv_pack_last_time = 0,    
	is_login = 0,

    -- 客户端消息
	CLIENT_MSG = {}, 
    -- 服务间消息
	CMD = {},
}

require "agent_login"

function agent_data:send_client(pack)
    send_client_package(self.client_fd, pack)
end

-- 关闭
function agent_data:close_agent()
	if self.client_fd then
		skynet.call(self.gate, "lua", "kick", self.client_fd)
	end

	skynet.exit()
end

-- 客户端消息处理
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return netpack.msg_unpack(msg, sz)
	end,
	dispatch = function (_, _, msg_type, msg_data)
        local recv_msg = protobuf.decode(msg_type, msg_data)
        if not recv_msg then
          return
        end

	    agent_data.recv_pack_last_time = skynet.now()
	    if agent_data.is_login == 1 or msg_type == 'client.AgentLoginReq' then
		    pcall(agent_data.CLIENT_MSG[msg_type], agent_data, recv_msg)
	    end
	end
}

-- 服务消息处理
agent_data.CMD['start'] = function (self, conf)
	local fd = conf.client
	self.gate = conf.gate
	self.WATCHDOG = conf.watchdog
	self.client_fd = fd
	self.recv_pack_last_time = skynet.now()
    self.login_time = skynet.now()

	skynet.call(self.gate, "lua", "forward", fd)

	self.center = skynet.queryservice(svr_config.agentsvr_name())
    print(svr_config.agentsvr_name())    

	skynet.fork(function()
		while true do
            print(self.is_login, skynet.now() - self.login_time)
            if self.is_login ~= 1 and skynet.now() - self.login_time >= 100 * 10 then
                self:close_agent()
                break
            end
			if skynet.now() - self.recv_pack_last_time >= 100 * 60 then
				-- self:close_agent()
                break
			end      
			skynet.sleep(500)
		end
	end)

end

agent_data.CMD['disconnect'] = function (self)
    print("agent disconnect")
    self:close_agent()
end

agent_data.CMD['kick'] = function (self)
    skynet.call(self.WATCHDOG, 'lua', 'close', self.client_fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = agent_data.CMD[command]
		skynet.ret(skynet.pack(f(agent_data, ...)))
	end)

	agent_data.cfg_data = sharedata.query("config_data")
end)
