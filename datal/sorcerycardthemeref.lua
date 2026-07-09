local _keys = {refId=1,name=2,icon=3,cardFrame=4,bgImg=5,sort=6,selectIcon=7}
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
[1]=_set({1,"sorcerycardtheme_0_1","card_cell_1","card_di_3","card_bg_big_2",1,""},_mt),
[2]=_set({2,"sorcerycardtheme_0_2","card_cell_2","card_di_3","card_bg_big_2",2,""},_mt)
}

return _datas