local t11 = require"agent_t11"
local data = {}

local a = 0
function data.t()    
    t11.t()
    print("data.t1 "..a)
    a = a + 1
end

return data