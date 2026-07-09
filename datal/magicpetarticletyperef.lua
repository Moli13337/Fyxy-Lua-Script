local _keys = {refId=1,name=2,emptyIcon=3}
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
[1]=_set({1,"magicpetarticletype_0_1","icon_petEquip_1"},_mt),
[2]=_set({2,"magicpetarticletype_0_2","icon_petEquip_2"},_mt),
[3]=_set({3,"magicpetarticletype_0_3","icon_petEquip_3"},_mt),
[4]=_set({4,"magicpetarticletype_0_4","icon_petEquip_4"},_mt)
}

return _datas