local skynet = require "skynet"

login_key_mgr = {}
login_key_mgr.__index = login_key_mgr

function login_key_mgr:new()
    local obj = {}
    setmetatable(obj, login_key_mgr)
    obj.login_key = {}
    obj.wait_remove = {}
    obj.remove_time = 100*60
    
    return obj
end

function login_key_mgr:update()
    local now_tick = skynet.now()
    for k, v in pairs(self.wait_remove) do
        if now_tick > v then 
            self.login_key[k] = nil
            self.wait_remove[k] = nil
        end
    end
end

function login_key_mgr:add(login_info)
    self.login_key[login_info.PlayerId] = login_info
    self.wait_remove[login_info.PlayerId] = skynet.now() + self.remove_time;
end

function login_key_mgr:offline(player_id)
    self.wait_remove[player_id] = skynet.now() + self.remove_time;
end

function login_key_mgr:online(player_id)
    self.wait_remove[player_id] = nil
end

function login_key_mgr:find(player_id)
    return self.login_key[player_id]
end

function login_key_mgr:kick(player_id)
    self.login_key[player_id] = nil
    self.wait_remove[player_id] = nil
end
