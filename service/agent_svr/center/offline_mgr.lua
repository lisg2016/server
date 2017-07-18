local offline_mgr = {}


local list = {}
function list:new()
    local new_obj = {count = 0, head = nil, tail = nil}
    setmetatable(new_obj, {__index = list})

    return new_obj
end

function list:size()
    return self.count
end

function list:push_back(data)
    local node = {pre = nil, next = nil, data = nil, role_id = 0}
    return self:push_back_ex(node, data)
end

function list:push_back_ex(node, data)
    node.data = data
    if self.head == nil then
        self.head = node
    end

    if self.tail == nil then 
        self.tail = node
    else
        self.tail.next = node
        node.pre = self.tail
        self.tail = node
    end

    self.count = self.count + 1
    return node
end

function list:front()
    return self.head
end

function list:remove(node)
    if node == self.head then 
        self.head = node.next
    end
    
    if node == self.tail then
        self.tail = node.pre
    end

    if node.pre ~= nil then
        node.pre.next = node.next
    end
    
    if node.next ~= nil then
        node.next.pre = node.pre
    end

    local data = node.data
    node.pre = nil
    node.next = nil
    node.data = nil
    self.count = self.count - 1

    return data
end

function offline_mgr:new(cache_size)
    local new_obj = {}
    new_obj.cache_size = cache_size
    new_obj.cache_list = list:new()
    new_obj.role_id_map = {}
    setmetatable(new_obj, {__index = offline_mgr})

    return new_obj
end

function offline_mgr:add(role_id, data)
    local exists = self.role_id_map[role_id]
    if exists ~= nil then
        self.cache_list:remove(exists)
        self.cache_list:push_back_ex(exists, data)
        return
    end
    
    if self.cache_list:size() >= self.cache_size then
        local front = self.cache_list:front()
        self.role_id_map[front.role_id] = nil
        self.cache_list:remove(front)

        front.role_id = role_id
        self.cache_list:push_back_ex(front, data)
        self.role_id_map[front.role_id] = front    
    else
        local node = self.cache_list:push_back(data)
        node.role_id = role_id
        self.role_id_map[node.role_id] = node
    end
end

function offline_mgr:remove(role_id)
    local exists = self.role_id_map[role_id]
    if exists ~= nil then
        self.role_id_map[role_id] = nil
        return self.cache_list:remove(exists)
    end
    return nil
end

function offline_mgr:get(role_id)
    local exists = self.role_id_map[role_id]
    if exists ~= nil then
        return exists.data
    end
    return nil
end

return offline_mgr