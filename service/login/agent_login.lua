local skynet = require "skynet"
local netpack = require "netpack"
local protobuf = require "protobuf"
local os = require "os"


function login_agent:send_client(pack)
    send_client_package(self.client_fd, pack)
end

-- 关闭
function login_agent:close_agent()
	if self.client_fd then
		skynet.call(self.gate, "lua", "kick", self.client_fd)
	end

	skynet.exit()
end

local function agent_head()
	return {agent = skynet.self(), fd = client_fd, uid = agent_uid}
end

login_agent.CLIENT_MSG['client.Heart'] = function (self, req)
	local rsp = {
		msg_name = "client.Heart",
		timestamp = skynet.now(),
		utc_time = os.time(),    
	}
    self:send_client(rsp)
end

login_agent.CLIENT_MSG['client.LoginReq'] = function (self, req)  
	if self.is_login ~= 0 then
		return
	end
	self.is_login = 1

	local login_rsp = {
		msg_name = "client.LoginRsp",
		Result = 'OK',
	}
    
	-- token校验


	if req.Login == '' then
		login_rsp.Result = 'SYSTEM_ERR'
		self:send_client(login_rsp)
		self.is_login = 0
		return
	end
  
	local player_id = 0
	local login_sql = "select id from tb_players where login = '"..req.Login.."';"
	local rs = skynet.call(svr_config.sqlmgr_name(0), "lua", "call", login_sql)
	if #rs ~= 0 then
		player_id = tonumber(rs[1]["id"])
	end

	if player_id == 0 then
		login_sql = string.format("insert into tb_players(login, created_date, status) values('%s', NOW(), 1)", req.Login)
		rs = skynet.call(svr_config.sqlmgr_name(0), "lua", "call", login_sql)
		player_id = rs.insert_id
	end

	if player_id == 0 then
	    login_rsp.Result = 'SYSTEM_ERR'
		self:send_client(login_rsp)
		self.is_login = 0
		return	    
	end

	self.agent_uid = player_id

	-- 获取AgentSvr
	local agent_svr_id = svr_config.get_agentsvr(player_id)

	login_rsp.PlayerId = self.agent_uid
	login_rsp.AgentHost = svr_config.agent_svr_host[agent_svr_id]
	login_rsp.AgentPort = svr_config.agent_svr_port[agent_svr_id]
	login_rsp.LoginKey = "123456"

    -- 通知AgentSvr	
	skynet.send(svr_config.agentsvr_name(agent_svr_id), 'lua', 'login_notify', login_rsp)
	
	self:send_client(login_rsp)
end

