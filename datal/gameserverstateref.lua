local _keys = {refId=1,intervalMin=2,intervalMax=3,icon=4,name=5}
local _mt = {
    __index = function(t, k)
        local idx = _keys[k]
        if not idx then return nil end
        return rawget(t, idx)
    end,
    __newindex = function(t, k)
    end
}
local _set = setmetatable
local _datas = {
[1]=_set({1,0,1000,"login_ui_1","gameserverstate_0_1"},_mt),
[2]=_set({2,1001,1999,"login_ui_2","gameserverstate_0_2"},_mt),
[3]=_set({3,2000,-1,"login_ui_3","gameserverstate_0_3"},_mt)
}

return _datas