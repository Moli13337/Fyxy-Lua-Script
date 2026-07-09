local _keys = {refId=1,name=2,description=3,textResource=4,bg=5,bg1=6,reward=7,packId=8}
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
[1]=_set({1,"inneractivitynameandinnernd_0_1","inneractivitynameandinnernd_1_1","bind_txt","bind_bg","bind_role","1=100212=1=0,1=1200704=5=0,1=100110=500=0",""},_mt),
[6]=_set({6,"inneractivitynameandinnernd_0_6","","","","","1=102001=500,1=100211=5","0;201;205;501"},_mt),
[7]=_set({7,"inneractivitynameandinnernd_0_7","","","","","1=102001=500","0;201;205;501"},_mt),
[8]=_set({8,"inneractivitynameandinnernd_0_8","","","","","1=102001=500",""},_mt),
[9]=_set({9,"inneractivitynameandinnernd_0_9","","","","","1=102001=500,1=100211=5",""},_mt)
}

return _datas