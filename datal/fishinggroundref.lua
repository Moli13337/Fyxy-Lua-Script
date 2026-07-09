local _keys = {refId=1,next=2,name=3,open=4,desc=5,cell=6,bg=7,eff=8,reward=9}
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
[1]=_set({1,2,"fishingground_0_1","","fishingground_1_1","fish_cell_1","fish_bg_big_1","","101"},_mt),
[2]=_set({2,3,"fishingground_0_2","412001,412101,412201","fishingground_1_2","fish_cell_2","fish_bg_big_2","","201"},_mt),
[3]=_set({3,4,"fishingground_0_3","412002,412102,412202","fishingground_1_3","fish_cell_3","fish_bg_big_3","","301"},_mt),
[4]=_set({4,5,"fishingground_0_4","412003,412103,412203","fishingground_1_4","fish_cell_4","fish_bg_big_4","","401"},_mt),
[5]=_set({5,-1,"fishingground_0_5","412004,412104,412204","fishingground_1_5","fish_cell_5","fish_bg_big_5","","501"},_mt)
}

return _datas