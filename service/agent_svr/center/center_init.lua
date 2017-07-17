local skynet = require "skynet"
local mysql = require "mysql"
local redis = require "redis"

function center_interface:init(self)
    if svr_config.test_flag ~= 0 and svr_config.harbor_id == svr_config.agent_svr_begin then
        -- 测试阶段 清理redis 重新加载
        local redis_db = {}
        for i = 1, svr_config.redis_maxconn do
            local db = redis.connect{
                host = svr_config.redis_info[i].host,
                port = svr_config.redis_info[i].port,
                db = svr_config.redis_dbindex,
                auth = svr_config.redis_info[i].auth,
            }

            if db then
                db:flushdb()
                table.insert(redis_db, db)
            else
                skynet.error("redis connect error")
            end
        end
        
        local db = mysql.connect({host = svr_config.mysql_host, port = svr_config.mysql_port, database = svr_config.mysql_db, user = svr_config.mysql_user, password = svr_config.mysql_pwd, max_packet_size = 5*1024*1024})
        local rs = db:query("select id, name, tb_player_id as player_id, level from tb_roles")
        for i = 1, #rs do
            local name_hashcode = hash_code(rs[i].name)
            local redis_index = svr_config.get_redis_index(name_hashcode)
            redis_db[redis_index]:sadd('name_set', rs[i].name)

            if rs[i].name ~= '' then
                redis_db[redis_index]:set('role_name:'..rs[i].name, rs[i].id)
            end

            -- local redis_index_id = svr_config.get_redis_index(rs[i].id)
            -- redis_db[redis_index_id]:hmset('role_smy:'..rs[i].id, "id", rs[i].id, "player_id", rs[i].player_id, "level", rs[i].level)
        end

        for k, v in pairs(redis_db) do
            v:disconnect()
        end
        db:disconnect()
    end

end