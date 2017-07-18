local function get_up(f)  
        local u = {}  
        if not f then  
                return u  
        end  
        local i = 1  
        while true do  
                local name, value = debug.getupvalue(f, i)  
                if name == nil then  
                        return u  
                end  
                u[name] = {v=value, i=i}
                i = i + 1  
        end  
        return u  
end  


_G.test_func.t = function (agent)
  agent.a = agent.a + 2
  _G.print("data:"..agent.a)
end

do return end

print(_G.agent_data.a)
_G.agent_data.a = 100
do return end


local proc_func = _P.client.CLIENT_MSG['client.LoginReq']
local root_up = get_up(proc_func)

--[[print(root_up.t1.v.t)
root_up.t1.v.t()
local a = 33
root_up.t1.v.t = function ()
    _G.print("data.t11___"..a)
    a = a + 1
end
print(root_up.t1.v.t)
root_up.t1.v.t()

do return end]]

local t1_t_up = get_up(root_up.t1.v.t)
local t11_t_up = get_up(t1_t_up.t11.v.t)

local a = t11_t_up.a.v
t1_t_up.t11.v.t = function ()
    _G.print("data.t11__22_"..a)
    a = a + 1
end

--print(a)
--root_up.t1.v.t = hotfix_t11_t
-- debug.setupvalue(root_up.t1.v.t, t1_t_up.t11.i, hotfix_t11_t)


