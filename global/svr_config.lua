local skynet = require "skynet"

svr_config = {}

svr_config.harbor_id = tonumber(skynet.getenv("harbor"))

svr_config.agent_svr_begin = tonumber(skynet.getenv("agent_svr_begin"))
svr_config.agent_svr_end = tonumber(skynet.getenv("agent_svr_end"))

svr_config.agent_gate_num = tonumber(skynet.getenv("agent_gate_num"))
svr_config.agent_svr_host = {}
svr_config.agent_svr_port = {}
for i=svr_config.agent_svr_begin, svr_config.agent_svr_end do
    svr_config.agent_svr_host[i] = skynet.getenv("agent_svr_host_"..i)
    svr_config.agent_svr_port[i] = tonumber(skynet.getenv("agent_svr_port_"..i))
end

svr_config.db_maxconn = tonumber(skynet.getenv("mysql_maxconn"))

function svr_config.get_agentsvr(player_id)
    return player_id % (svr_config.agent_svr_end - svr_config.agent_svr_begin + 1) + svr_config.agent_svr_begin
end

function svr_config.agentsvr_name(id)
    if id == nil then
        id = svr_config.harbor_id
    end
    return "agentsvr"..id
end

function svr_config.sqlmgr_name(player_id)
    local id = player_id % (svr_config.db_maxconn) + 1
    return ".sqlmgr"..id
end
