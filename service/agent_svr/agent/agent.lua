local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local protobuf = require "protobuf"
local sharedata = require "skynet.sharedata"
local harbor = require "skynet.harbor"
local os = require "os"

agent_login_status_waitlogin = 1
agent_login_status_logining = 2
agent_login_status_logined = 3

agent_interface = {

    -- 客户端消息
	CLIENT_MSG = {}, 
    -- 服务间消息
	CMD = {},
}

config_data = nil
agent_data = {
	-- service
	WATCHDOG = nil,
	center = nil,
	gate = nil,

	client_fd = 0,
    login_time = 0,
	recv_pack_last_time = 0,    
	wait_quit_agent_time = 0,
	shutdown = false,

	login_status = agent_login_status_waitlogin,
	player_id = 0,
	role_list = nil,
}
setmetatable(agent_data, {__index = agent_interface})

require "agent_login"

function agent_interface:send_client(pack)
    send_client_package(self.client_fd, pack)
end

function agent_interface:agent_head()
	return {agent = skynet.self(), fd = self.client_fd, pid = self.player_id}
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
	    if agent_data.login_status == agent_login_status_logined or msg_type == 'client.AgentLoginReq' then
		    local f = agent_interface.CLIENT_MSG[msg_type]
			f(agent_data, recv_msg)
		    -- pcall(agent_interface.CLIENT_MSG[msg_type], agent_data, recv_msg)			
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

	self.center = harbor.queryname(svr_config.agentsvr_name())

	skynet.fork(function()
		while true do
            if self.login_status ~= agent_login_status_logined and skynet.now() - self.login_time >= 100 * 10 then
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
	self:on_socket_close()	
end

agent_data.CMD['kick'] = function (self)
    skynet.call(self.WATCHDOG, 'lua', 'close', self.client_fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = agent_interface.CMD[command]
		skynet.ret(skynet.pack(f(agent_data, ...)))
	end)

	config_data = sharedata.query("config_data")
end)
