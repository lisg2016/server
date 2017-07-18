local skynet = require "skynet"
local player_base = {}


function player_base.new(base)
    local new_obj = {base = base, in_db = false, db_data = {}}

    return new_obj
end

function player_base.set_db(owner, db)
    owner.in_db = true
    owner.db_data = db
end

function player_base.save(owner)
    local oper = 'UPDATE'
    if not owner.in_db then
        oper = 'INSERT'
        owner.in_db = true
    end

    local keys = {id = owner.db_data.id}
    skynet.send(svr_config.sqlmgr_name(owner.base.role_id), 'lua', 'save', 'tb_roles', oper, keys, owner.db_data)
end

return player_base