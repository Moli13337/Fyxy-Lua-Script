local _keys = {refId=1,num=2,name=3,reward=4,cell=5,bg=6}
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
[1]=_set({1,30,"petdreamland_0_1","1=1900001=30=0,1=1900002=10=0","petDreamland_role_cell_1","petDreamland_bg_big_1"},_mt),
[2]=_set({2,60,"petdreamland_0_2","1=1900001=25.5=0,1=1900002=8.5=0","petDreamland_role_cell_2","petDreamland_bg_big_2"},_mt),
[3]=_set({3,120,"petdreamland_0_3","1=1900001=21=0,1=1900002=7=0","petDreamland_role_cell_3","petDreamland_bg_big_3"},_mt),
[5]=_set({5,-1,"petdreamland_0_5","1=1900001=15=0,1=1900002=5=0","petDreamland_role_cell_5","petDreamland_bg_big_4"},_mt)
}

return _datas