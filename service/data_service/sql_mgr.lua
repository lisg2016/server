
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

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
