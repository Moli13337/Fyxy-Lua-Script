local _keys = {refId=1,resExt=2,mainRes=3,dependList=4}
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
ui_prefabs_wnd_wndactivity4104=_set({"ui_prefabs_wnd_wndactivity4104","prefab.jet",1,""},_mt)
}

return _datas