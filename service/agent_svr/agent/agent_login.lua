local skynet = require "skynet"

-- 清除退出 
function agent_interface:quit_agent()
    if self.login_status == agent_login_status_logined then
        -- update smy
        -- write all
    end

    skynet.send(self.center, 'lua', 'agent_offline', self:agent_head())
    if self.game ~= nil then
        skynet.send(self.game, 'lua', 'exit_game', self:agent_head())
    end

	skynet.exit()
end

-- 关闭
function agent_interface:close_agent()
	if self.client_fd then
		skynet.call(self.gate, "lua", "kick", self.client_fd)
	end
end

-- socket 断开
function agent_interface:on_socket_close()
    if self.shutdown == true or self.login_status ~= agent_login_status_logined then
        self:quit_agent()
        return
    end

    skynet.send(self.center, 'lua', 'user_offline', self:agent_head())
    if self.game ~= nil then
        skynet.send(self.game, 'lua', 'user_offline', self:agent_head())
    end
    
    self:quit_agent()
    --self.wait_quit_agent_time = skynet.now() + 5 * 100    
end

-- 被踢下线
agent_interface.CMD['kick_agent'] = function (self, req)
    self:send_client(req)
    self.shutdown = true
	self:close_agent()
end


agent_interface.CLIENT_MSG['client.AgentLoginReq'] = function(self, req)
    if self.login_status ~= agent_login_status_waitlogin then
        return
    end
    self.player_id = req.PlayerId
    self.login_status = agent_login_status_logining
    skynet.send(self.center, 'lua', 'login_check_key', self:agent_head(), req)
end


function agent_interface:send_role_list()
    local role_msg = { msg_name = 'client.UserRoleList', RoleData = self.role_list }   
    self:send_client(role_msg)    
end

agent_interface.CMD['login_check_key_rsp'] = function(self, req)
    if self.login_status ~= agent_login_status_logining then
        return
    end

    self:send_client(req)

    if req.Result == "OK" then
        -- 取角色列表
        local sql = "select id, name, level, role_index from tb_roles where tb_player_id = "..self.player_id..";"
	    local rs = skynet.call(svr_config.sqlmgr_name(self.player_id), "lua", "call", sql)

        self.role_list = {}
        for k, v in pairs(rs) do
            table.insert(self.role_list, {RoleId = v.id, RoleIndex = v.role_index, Name = v.name, Level = v.level})
        end
        self:send_role_list()

        self.login_status = agent_login_status_logined
    else
        self.login_status = agent_login_status_waitlogin
    end    
end