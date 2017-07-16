local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local socket = require "socket"
local snax = require "snax"
local cluster = require "cluster"
local luadebug = require "LuaDebug_luasockt2_0"

local CMD = {}

skynet.start(function() 
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	skynet.register('login')	
	luadebug("192.168.1.101", 7003)
end)
