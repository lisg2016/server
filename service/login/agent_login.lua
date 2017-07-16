
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

	local login_rsp = {
		msg_name = "client.LoginRsp",
		Result = 'OK',
	}
    
	if req.login == '' then
		login_rsp.Result = 'SYSTEM_ERR'
		send_client_package(client_fd, login_rsp)
		return
	end
  
	local player_id = 0
	local login_sql = "select uid from tb_player where login = '"..req.login.."';"
	local rs = skynet.call("mysqlpool", "lua", "execute", login_sql)
	if #rs ~= 0 then
		player_id = tonumber(rs[1]["uid"])
	end

	if player_id == 0 then
		local uid = playerdc.req.get_nextid()
		playerdc.req.add({uid=uid, login=req.login, passwd='123456'})
		player_id = uid
	end

	agent_uid = player_id
	playerdc.req.load(player_id)

	local player_data = playerdc.req.get(player_id)
	if not player_data['name'] or player_data['name'] == '' then
		login_rsp.result = 'have create role'
		send_package(login_rsp)
		return
	end

	local login_game = skynet.call(center, 'lua', 'login_center', agent_head(), player_data)
	if login_game ~= 0 then
		login_rsp.result = 'login game error:' .. login_game
		send_package(login_rsp)
		return
	end

	is_login = 1
	send_package(login_rsp)

	if req.game ~= nil then
		local enter_game = {game = req.game, room = req.room}
		CLIENT_MSG.enter_game(enter_game)
	end

end


--[[function CLIENT_MSG.create_role(req)
	if is_login ~= 0 or agent_uid == 0 then
		return
	end

	if req.role_name == '' then
		return
	end

	local login_rsp = {
		name = 'create_role_rsp',
		result = 'ok',
	}
	local player_data = playerdc.req.get(agent_uid)
	if player_data['name'] and player_data['name'] ~= '' then
		login_rsp.result = 'create role err'
		send_package(login_rsp)
		return
	end

	player_data['name'] = req.role_name
	player_data['icon'] = 1
	player_data['money'] = 10000
	player_data['status'] = 1

	playerdc.req.update(player_data)

	local login_game = skynet.call(center, 'lua', 'login_center', agent_head(), player_data)
	if login_game ~= 0 then
		login_rsp.result = 'login game error:' .. login_game
		send_package(login_rsp)
		return
	end

	is_login = 1
	send_package(login_rsp)

	if req.game ~= nil then
		local enter_game = {game = req.game, room = req.room}
		CLIENT_MSG.enter_game(enter_game)
	end
end

function CLIENT_MSG.enter_game(req)
	local lobby_data_rsp = {
		name = 'enter_game_rsp',
		ret = 0,
		login_key = nil,
	}

	lobby_data_rsp.ret, lobby_data_rsp.login_key = skynet.call(center, 'lua', 'login_game', agent_uid, req.game, req.room)
	send_package(lobby_data_rsp)
end]]