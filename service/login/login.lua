local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local socket = require "socket"
local snax = require "snax"
local cluster = require "cluster"

local CMD = {}

skynet.register_protocol {
	name = "proto",
	id = 100,
	unpack = skynet.unpack,
	pack = skynet.pack,
	dispatch = function (_, _, ...)
        print("proto recv:")
		print(...)
        print("proto recv:")
	end
}

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)

	skynet.register('login')

    --[[local xxx = skynet.launch("aoi")
	for i=1, 50 do
	local rrr = skynet.call(xxx, 'proto', {aaa=987654321})
	end
	print("aoi addr:".. xxx)
	print(rrr)
	]]

end)
