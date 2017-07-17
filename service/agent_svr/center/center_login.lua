local skynet = require "skynet"

-- 添加登录key
center_interface.CMD['login_notify'] = function (self, req)
    center_data.login_key_mgr:add(req)
end

center_interface.CMD['login_check_key'] = function (self, agent_head, req)
print(req)
    local login_key = center_data.login_key_mgr:find(req.PlayerId)
    if true or login_key == nil or login_key.LoginKey ~= req.LoginKey then
        local rsp = {Result = "KEY_ERR"}
        skynet.send(agent_head.agent, 'lua', 'login_check_key_rsp', rsp)
        return
    end

    self.login_agent_id[agent_head.agent] = { agent_head = agent_head, player_id = 0 }
    



end

