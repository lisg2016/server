
agent_interface.CLIENT_MSG['client.AgentLoginReq'] = function(self, req)
    if self.login_status ~= agent_login_status_waitlogin then
        return
    end
    self.player_id = req.PlayerId
    self.login_status = agent_login_status_logining
    skynet.send(self.center, 'lua', 'login_check_key', self:agent_head(), req)
end

agent_interface.CMD['login_check_key_rsp'] = function(self, req)
print(req)
end