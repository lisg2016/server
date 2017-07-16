local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
-- local json = require "cjson.safe"
local snax = require "snax"
local protobuf = require "protobuf"
local sharedata = require "skynet.sharedata"
local os = require "os"

-- init
login_agent =  {
	-- service
	WATCHDOG = nil,
	login = nil,
	gate = nil,

	host = "",
	agent_uid = 0,

	client_fd = 0,
	recv_pack_last_time = 0,
	is_login = 0,

    -- 客户端消息
	CLIENT_MSG = {}, 
    -- 服务间消息
	CMD = {},
}

require "agent_login"


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

	    login_agent.recv_pack_last_time = skynet.now()
	    if is_login == 1 or msg_type == 'client.LoginReq' then
		    pcall(login_agent.CLIENT_MSG[msg_type], login_agent, recv_msg)
	    end
	end
}

-- 服务消息处理
function login_agent.CMD:start(conf)
	local fd = conf.client
	self.gate = conf.gate
	self.WATCHDOG = conf.watchdog
	self.client_fd = fd
	self.recv_pack_last_time = skynet.now()
	skynet.call(self.gate, "lua", "forward", fd)

	self.login = skynet.queryservice("login")
  
	skynet.fork(function()
		while true do
			if skynet.now() - self.recv_pack_last_time >= 1000 then
				-- self:close_agent()
			end      
			skynet.sleep(500)
		end
	end)

    -- 测试
	--local obj2 = sharedata.query "config_data"
    --print(obj2.CharacterInfo[1][1][1].Name)
    --print(#obj2.CharacterInfo[1][1][1].Name)
end

function login_agent.CMD:disconnect()
    print("agent disconnect")
    self:close_agent()
end

function login_agent.CMD:kick()
    skynet.call(self.WATCHDOG, 'lua', 'close', self.client_fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = login_agent.CMD[command]
		skynet.ret(skynet.pack(f(login_agent, ...)))
	end)
end)
