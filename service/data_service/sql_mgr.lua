
local skynet = require "skynet"
require "skynet.manager"
local mysql = require "mysql"


local CMD = {}
local db

local function db_check()
    skynet.timeout(500, db_check)	
	local ping_result = db:query("select 1;")	
end

function CMD.start(host, user, passwd, db_name, port, index)
    db = mysql.connect({host = host, port = port, database = db_name, user = user, password = passwd, max_packet_size = 5*1024*1024})
	if not db then
	    LOG_ERROR("mysql connect error")
		return
	end

	db:query("set charset utf8;")
	db_check()

	skynet.register('.sqlmgr'..index)
end

function CMD.call(sql)
    local rs = db:query(sql)
    return rs
end

function CMD.set()

	if rs.affected_rows == 0 then
	    LOG_WARNING(tostring(rs)..sql)
	end
end

function CMD.get()

end


function CMD.save(tb_name, oper, keys, data)
    if oper == 'INSERT' then		
		local data_k = {}
		local data_v = {}
		for k, v in pairs(data) do
		    table.insert(data_k, '`'..k..'`')
			table.insert(data_v, "'"..v.."'")
		end
		
	    local sql = 'insert into '..tb_name..'('..table.concat(data_k, ', ')..') values('..table.concat(data_v, ', ')..');'
		local rs = db:query(sql)
	    return rs
	end

	if oper == 'UPDATE' then
	    local keys_v = {}
		for k, v in pairs(keys) do
		    table.insert(keys_v, k.." = '"..v.."'")
		end

	    local data_v = {}
		for k, v in pairs(data) do
		    table.insert(data_v, k.." = '"..v.."'")
		end

		local sql = 'update '..tb_name..' set '..table.concat(data_v, ', ')..' where '..table.concat(keys_v, ' and ')		
		local rs = db:query(sql)
		return rs
	end

	if oper == 'DELETE' then
	    local keys_v = {}
		for k, v in pairs(keys) do
		    table.insert(keys_v, k.." = '"..v.."'")
		end

		local sql = 'delete from '..tb_name..' where '..table.concat(keys_v, ' and ')
		local rs = db:query(sql)
		return rs
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
