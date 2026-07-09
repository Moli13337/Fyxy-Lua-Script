local _keys = {refId=1,name=2,icon=3,lv=4,collectionDegree=5,desc=6}
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
[1001]=_set({1001,"magictype_0_1001","magic_btn_icon_1","1",0,"magictype_1_1001"},_mt),
[1002]=_set({1002,"magictype_0_1002","magic_btn_icon_2","100",100,"magictype_1_1002"},_mt),
[1003]=_set({1003,"magictype_0_1003","magic_btn_icon_3","120",200,"magictype_1_1003"},_mt),
[1004]=_set({1004,"magictype_0_1004","magic_btn_icon_4","130",300,"magictype_1_1004"},_mt)
}

return _datas