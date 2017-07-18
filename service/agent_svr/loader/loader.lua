local skynet = require "skynet"
require "skynet.manager"
local harbor = require "skynet.harbor"
local player_data = require "player_data"
local player_base = require "player_base"
local player_config = require "player_config"

local loader = {
    role_load = {},
}


function loader:load(role_id, source, proto, cmd, ...)
    if self.center == nil then
      	self.center = harbor.queryname(svr_config.agentsvr_name())
    end

    local rsp_msg = self.role_load[role_id]
    if rsp_msg ~= nil then
        table.insert(rsp_msg, table.pack(source, proto, cmd, ...))
        return
    end

    rsp_msg = {}
    self.role_load[role_id] = rsp_msg
    table.insert(rsp_msg, table.pack(source, proto, cmd, ...))


    local role_data_base = {role_id = role_id}
    local role_data = player_data.new(role_data_base)
    -- load role data
    local sql = "select * from tb_roles where id = "..role_id
    local rs = skynet.call(svr_config.sqlmgr_name(role_id), 'lua', 'call', sql)
    if #rs ~= 1 then
        self.role_load[role_id] = nil
        return
    end
    player_base.set_db(role_data.base, rs[1])
    

    local role_data_item = {
        ConfigSeting = {set_fun = player_config.set_db, data_name = 'config'},
        } 

    local role_data_sql = "select * from tb_role_data where tb_role_id = ".. role_id
    local role_data_rs = skynet.call(svr_config.sqlmgr_name(role_id), 'lua', 'call', role_data_sql)
    for i = 1, #role_data_rs do
        local item = role_data_rs[i]
        local item_cfg = role_data_item[item.type]
        if item_cfg ~= nil then
            item_cfg.set_fun(role_data[item_cfg.data_name], item)       
        end
    end
    -- end load

    
    skynet.send(self.center, 'lua', 'cache_role_data', role_id, role_data)
    for i = 1, #rsp_msg do
        skynet.send(table.unpack(rsp_msg[i]))
    end

    self.role_load[role_id] = nil
end


skynet.start(function() 
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = loader[command]
		skynet.ret(skynet.pack(f(loader, ...)))
	end)

	skynet.register('.loader')
end)
