local skynet = require "skynet"
local player_base = require "player_base"

local player_data = {}

function player_data.new(base)
    local new_obj = {}
    new_obj.base = player_base.new(base)

    return new_obj
end

-- 初始化创建新角色
function player_data.create_role(owner, role_id, player_id, svr_id, role_index, name)
     owner.base.db_data = {
     id = role_id,
     tb_player_id = player_id,
     svr_id = svr_id,
     role_index = role_index,
     name = name,
     level = 1,
     created_date = os.date("%Y-%m-%d %H:%M:%S"),
     }
     

end

function player_data.save(owner)
    player_base.save(owner.base)
    
end

return player_data