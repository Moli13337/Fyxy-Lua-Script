local _keys = {refId=1,row=2,column=3,more=4}
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
[1]=_set({1,1,1,1},_mt),
[2]=_set({2,1,2,1},_mt),
[3]=_set({3,1,3,1},_mt),
[4]=_set({4,2,4,0},_mt),
[5]=_set({5,2,5,0},_mt),
[6]=_set({6,2,6,0},_mt),
[7]=_set({7,2,7,0},_mt),
[8]=_set({8,3,1,1},_mt),
[9]=_set({9,3,2,1},_mt),
[10]=_set({10,3,3,1},_mt)
}

return _datas