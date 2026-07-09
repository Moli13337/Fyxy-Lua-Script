local _keys = {refId=1,type=2,pos=3,unlock=4,text=5}
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
[1001]=_set({1001,1,1,"1=100","magicrunepos_0_1001"},_mt),
[1002]=_set({1002,1,2,"2=7","magicrunepos_0_1002"},_mt),
[2001]=_set({2001,2,3,"2=6,3=75","magicrunepos_0_2001"},_mt),
[2002]=_set({2002,2,4,"2=11,3=75","magicrunepos_0_2002"},_mt)
}

return _datas