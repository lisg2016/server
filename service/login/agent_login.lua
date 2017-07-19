
local skynet = require "skynet"
local netpack = require "netpack"
local protobuf = require "protobuf"
local os = require "os"


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
  send_client_package(self.client_fd, rsp)
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
		send_client_package(self.client_fd, login_rsp)
		self.is_login = 0
		return
	end
  
	local player_id = 0
	local login_sql = "select id from tb_players where login = '"..req.Login.."';"
	local rs = skynet.call(".sqlmgr1", "lua", "call", login_sql)
	if #rs ~= 0 then
		player_id = tonumber(rs[1]["id"])
	end

	if player_id == 0 then
		login_sql = string.format("insert into tb_players(login, created_date, status) values('%s', NOW(), 1)", req.Login)
		rs = skynet.call(".sqlmgr1", "lua", "call", login_sql)
		player_id = rs.insert_id
	end

	if player_id == 0 then
	    login_rsp.Result = 'SYSTEM_ERR'
		send_client_package(self.client_fd, login_rsp)
		self.is_login = 0
		return	    
	end

	self.agent_uid = player_id

	-- 获取AgentSvr

    -- 通知AgentSvr
	local login_game = skynet.call(center, 'lua', 'login_center', agent_head(), player_data)
	if login_game ~= 0 then
		login_rsp.result = 'login game error:' .. login_game
		send_package(login_rsp)
		return
	end

	login_rsp.PlayerId = self.agent_uid
	
	send_package(login_rsp)
end

