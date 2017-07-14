local skynet = require "skynet"
local snax = require "snax"
local cluster = require "cluster"
local sprotoloader = require "sprotoloader"
local protobuf = require "protobuf"

skynet.start(function()
	print("Server start")

	local center = skynet.uniqueservice("login")

	local console = skynet.newservice("console")
	skynet.newservice("debug_console",tonumber(skynet.getenv("debug_port")))
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = tonumber(skynet.getenv("port")),
		maxclient = tonumber(skynet.getenv("max_client")),
		nodelay = true,
	})
	print("Watchdog listen on ", tonumber(skynet.getenv("port")))
  
  
  local test_proto = {utc_time = 1234}
  local proto_data = protobuf.encode("client.Heart", test_proto)
  print("proto data"..proto_data)
  local test_proto2 = protobuf.decode("client.Heart", proto_data)
  print("111"..test_proto2.utc_time)
  print("222"..test_proto2.time_zone)

	skynet.exit()
end)
