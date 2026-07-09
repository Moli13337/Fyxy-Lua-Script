local _keys = {refId=1,wndName=2,textPath=3,size=4,spacing=5,alignment=6,enus=7,ko=8,th=9,fr=10,de=11,vie=12}
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

}

return _datas