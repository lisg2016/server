local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
-- local json = require "cjson.safe"
local snax = require "snax"
local protobuf = require "protobuf"
local sharedata = require "skynet.sharedata"
local os = require "os"
local t1 = require "agent_t1"

local WATCHDOG
local gate
local host
local send_request
local agent_uid

local CMD = {}
local client_fd
local recv_pack_last_time
local login

local function close_agent()
	if client_fd then
		skynet.call(gate, "lua", "kick", client_fd)
	end

	skynet.exit()
end

local function agent_head()
	return {agent = skynet.self(), fd = client_fd, uid = agent_uid}
end

local CLIENT_MSG = {}
CLIENT_MSG['client.Heart'] = function (req)
	local rsp = {
		timestamp = skynet.now(),
		utc_time = os.time(),    
	}
  send_client_package(client_fd, "client.Heart", rsp)
end

CLIENT_MSG['client.LoginReq'] = function (req)
  t1.t()
  is_login = 1
  send_client_package(client_fd, "client.LoginReq", req)
  do return end
  
	if is_login ~= 0 then
		return
	end

	local login_rsp = {
		result = 'ok',
	}
	if req.login == '' then
		login_rsp.result = 'login error'
		send_package(login_rsp)
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

function CLIENT_MSG.create_role(req)
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
end

-- 玩家登录消息
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return netpack.msg_unpack(msg, sz)
	end,
	dispatch = function (_, _, msg_type, msg_data)
    print("recv:"..msg_type)
                
    local obj2 = sharedata.query "config_data"
    print(obj2.CharacterInfo[1][1][1].Name)
    print(#obj2.CharacterInfo[1][1][1].Name)

    local recv_msg = protobuf.decode(msg_type, msg_data)
    if not recv_msg then
      return
    end

		recv_pack_last_time = skynet.now()
		--if is_login == 1 or msg_type == 'client.LoginReq' then
			pcall(CLIENT_MSG[msg_type], recv_msg)
		--end
	end
}

-- 服务消息处理
function CMD.start(conf)
	local fd = conf.client
	gate = conf.gate
	WATCHDOG = conf.watchdog
  
	skynet.fork(function()
		while true do
			if skynet.now() - recv_pack_last_time >= 1000 then
				-- close_agent()
			end      
			skynet.sleep(500)
		end
	end)

	client_fd = fd
	recv_pack_last_time = skynet.now()
	skynet.call(gate, "lua", "forward", fd)

	center = skynet.queryservice("login")
  
  local rsp = {
		timestamp = skynet.now(),
		utc_time = os.time(),    
	}
  send_client_package(client_fd, "client.Heart", rsp)

end

function CMD.disconnect()
  print("agent disconnect")
	close_agent()
end

function CMD.kick()
    skynet.call(WATCHDOG, 'lua', 'close', client_fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
