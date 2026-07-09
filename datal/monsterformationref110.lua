local _keys = {refId=1,monsterPower=2,name=3,formation=4,monster1=5,monster2=6,monster3=7,monster4=8,monster5=9,monster6=10,monster7=11,monster8=12,monster9=13,monster10=14,lv=15,draconicList=16}
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
[2000000]=_set({2000000,2161775,"monsterformation_0_2000000",5,3000001,0,0,0,0,0,0,0,0,0,0,""},_mt)
}

return _datas