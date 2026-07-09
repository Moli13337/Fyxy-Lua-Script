local _keys = {refId=1,name=2,nameIcon=3,icon=4,combatTyep=5,rankRefId=6,firstInstanceId=7,map=8}
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
[1]=_set({1,"maininstancepattern_0_1","instance_txt_2","instance_btn_icon_1",1,2,10010,"map_world_bg_1,map_world_bg_2,map_world_bg_3"},_mt)
}

return _datas