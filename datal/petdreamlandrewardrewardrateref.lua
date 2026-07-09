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
[1]=_set({1,"1,1"},_mt),
[2]=_set({2,"1.04,1.1"},_mt),
[3]=_set({3,"1.1,1.22"},_mt),
[4]=_set({4,"1.16,1.34"},_mt),
[5]=_set({5,"1.24,1.48"},_mt),
[6]=_set({6,"1.32,1.62"},_mt),
[7]=_set({7,"1.4,1.76"},_mt),
[8]=_set({8,"1.5,1.92"},_mt),
[9]=_set({9,"1.6,2.08"},_mt),
[10]=_set({10,"1.7,2.24"},_mt),
[11]=_set({11,"1.8,2.4"},_mt)
}

return _datas