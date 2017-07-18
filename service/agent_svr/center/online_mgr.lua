local online_mgr = {}


function online_mgr:new()
    local new_obj = {}
    setmetatable(new_obj, {__index = online_mgr})

    return new_obj
end

function online_mgr:add(role_id, data)

end

function online_mgr:remove(role_id)

end

return online_mgr