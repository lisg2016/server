local skynet = require "skynet"
local player_config = {}


function player_config.new(base)
    local new_obj = {base = base, in_db = false, db_data = {}}

    return new_obj
end

function player_config.set_db(owner, db)
    owner.in_db = true
    owner.db_data = db

    -- 解析
end

function player_config.save(owner)
    -- 打包
    local data = nil -- "111"

    local oper = 'UPDATE'
    if data == nil then
        if not owner.in_db then
            return
        else
            oper = "DELETE"
        end
    else
        if not owner.in_db then
            oper = 'INSERT'
            owner.in_db = true
        end
    end

    local data_type = 'ConfigSeting'

    owner.db_data.data = data
    if oper == "INSERT" then
        owner.db_data.tb_role_id = owner.base.role_id
        owner.db_data.type = data_type
    else
        owner.db_data.tb_role_id = nil
        owner.db_data.type = nil
    end

    local keys = {tb_role_id = owner.base.role_id, type = data_type}
    skynet.send(svr_config.sqlmgr_name(owner.base.role_id), 'lua', 'save', 'tb_role_data', oper, keys, owner.db_data)
end

return player_config