local _keys = {refId=1,buyCount=2,price=3}
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
[1]=_set({1,1,"1=102001=50"},_mt),
[2]=_set({2,2,"1=102001=100"},_mt),
[3]=_set({3,3,"1=102001=200"},_mt),
[4]=_set({4,4,"1=102001=200"},_mt),
[5]=_set({5,5,"1=102001=200"},_mt),
[6]=_set({6,6,"1=102001=200"},_mt),
[7]=_set({7,7,"1=102001=200"},_mt),
[8]=_set({8,8,"1=102001=200"},_mt),
[9]=_set({9,9,"1=102001=200"},_mt),
[10]=_set({10,10,"1=102001=200"},_mt),
[11]=_set({11,11,"1=102001=200"},_mt),
[12]=_set({12,12,"1=102001=200"},_mt)
}

return _datas