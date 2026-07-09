local _keys = {refId=1,value=2}
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
[1]=_set({1,"clanwarpeakranking_0_1"},_mt),
[2]=_set({2,"clanwarpeakranking_0_2"},_mt),
[3]=_set({3,"clanwarpeakranking_0_3"},_mt),
[4]=_set({4,"clanwarpeakranking_0_4"},_mt),
[5]=_set({5,"clanwarpeakranking_0_5"},_mt),
[6]=_set({6,"clanwarpeakranking_0_6"},_mt)
}

return _datas