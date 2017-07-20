
-- 添加登录key
function center_data.CMD:login_notify(req)
    center_data.login_key_mgr:add(req)
end
