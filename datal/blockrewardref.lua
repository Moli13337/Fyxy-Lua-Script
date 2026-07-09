local _keys = {refId=1,num=2,reward=3}
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
[1]=_set({1,1,"1=110033=3=0"},_mt),
[2]=_set({2,2,"1=102001=200=0"},_mt),
[3]=_set({3,3,"1=110033=4=0"},_mt),
[4]=_set({4,5,"1=102001=300=0"},_mt),
[5]=_set({5,7,"1=110033=6=0"},_mt),
[6]=_set({6,9,"1=102001=400=0"},_mt),
[7]=_set({7,11,"1=110033=8=0"},_mt),
[8]=_set({8,13,"1=102001=500=0"},_mt),
[9]=_set({9,15,"1=110033=10=0"},_mt),
[10]=_set({10,17,"1=102001=600=0"},_mt),
[11]=_set({11,20,"1=110033=12=0"},_mt),
[12]=_set({12,22,"1=102001=800=0"},_mt),
[13]=_set({13,25,"1=110033=14=0"},_mt),
[14]=_set({14,30,"1=102001=1000=0"},_mt)
}

return _datas