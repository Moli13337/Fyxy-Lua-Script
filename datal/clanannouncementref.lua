local _keys = {refId=1,type=2,content=3}
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
[1]=_set({1,1,"clanannouncement_0_1"},_mt),
[2]=_set({2,1,"clanannouncement_0_2"},_mt),
[101]=_set({101,2,"clanannouncement_0_101"},_mt)
}

return _datas