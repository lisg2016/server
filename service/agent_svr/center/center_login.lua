local skynet = require "skynet"
local player_data = require "player_data"

-- 添加登录key
center_interface.CMD['login_notify'] = function (self, req, req_ex)
    req.login_req = req_ex
    center_data.login_key_mgr:add(req)
end

-- 踢agent
function center_interface:close_agent(agent) 
    local kick_rsp = { msg_name = 'client.KickUser',  type = 'KICK' }
	skynet.send(agent, 'lua', 'kick_agent', kick_rsp)
end

-- 登录成功处理
function center_interface:agent_login_success(agent_login_info, player_id, svr_id) 
    agent_login_info.player_id = player_id
    agent_login_info.svr_id = svr_id

    self.login_player_id[player_id] = agent_login_info
    self.login_key_mgr:online(player_id)
    
    local login_rsp = { msg_name = 'client.AgentLoginRsp', Result = "OK", PlayerId = player_id, SvrId = svr_id}
    skynet.send(agent_login_info.agent_head.agent, 'lua', 'login_check_key_rsp', login_rsp)
end

-- user断线
center_interface.CMD['user_offline'] = function (self, agent_head)

end

-- agent退出
center_interface.CMD['agent_offline'] = function (self, agent_head, role_id, role_data)
    local login_info = self.login_agent_id[agent_head.agent]
    if login_info == nil then
        return 
    end
    self.login_agent_id[agent_head.agent] = nil
    
    if login_info.player_id ~= 0 then
        self.login_key_mgr:offline(login_info.player_id)
        self.login_player_id[login_info.player_id] = nil

        -- 数据放回缓存
        if role_data ~= nil then
            self.offline_mgr:add(role_id, role_data)
        end
    end

    if login_info.next_agent ~= nil then
        local next_login = self.login_agent_id[login_info.next_agent]
        if next_login ~= nil then
            self:agent_login_success(next_login, login_info.player_id, login_info.svr_id)
        end
    end
end

-- 登录验证
center_interface.CMD['login_check_key'] = function (self, agent_head, req)
    local login_key = center_data.login_key_mgr:find(req.PlayerId)
    if login_key == nil or login_key.LoginKey ~= req.LoginKey then
        local rsp = { msg_name = 'client.AgentLoginRsp', Result = "KEY_ERR"}
        skynet.send(agent_head.agent, 'lua', 'login_check_key_rsp', rsp)
        return
    end

    local agent_login_info = { agent_head = agent_head, player_id = 0, svr_id = 0 }
    self.login_agent_id[agent_head.agent] = agent_login_info
    
    -- 处理旧登录
    local old_info = self.login_player_id[req.PlayerId]
    if old_info ~= nil then
        if old_info.next_agent ~= nil then
            self:close_agent(old_info.next_agent)

            old_info.next_agent = nil
        end

        -- 如果online_mgr 则重连

        self:close_agent(old_info.agent_head.agent)
        old_info.next_agent = agent_login_info.agent_head.agent
        return
    end

    self:agent_login_success(agent_login_info, req.PlayerId, login_key.login_req.SvrId)
end

center_interface.CMD['cache_role_data'] = function (self, role_id, data)
    self.offline_mgr:add(role_id, data)
end

function center_interface:on_center_login_proc(role_id, role_data)

end

function center_interface:send_personal_info()

end

center_interface.CMD['agent_login_role_req'] = function (self, agent_head, role_id)
    local role_data = self.offline_mgr:remove(role_id)
    if role_data == nil then
        -- load
        skynet.send('.loader', 'lua', 'load', role_id, skynet.self(), 'lua', 'agent_login_role_req', agent_head, role_id)
        return
    end
    
    -- 检测旧agent存在
    if self.login_agent_id[agent_head.agent] == nil then
        self.offline_mgr:add(role_id, role_data)
        return
    end

    self:on_center_login_proc(role_id, role_data)

    skynet.send(agent_head.agent, 'lua', 'agent_login_role_rsp', role_id, role_data)
end
