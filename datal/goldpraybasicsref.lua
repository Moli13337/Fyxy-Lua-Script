local _keys = {refId=1,name=2,type=3,sequence=4,buyNeed=5,ResetTime=6,basicIncome=7,timeBonus=8,crit=9,icon=10}
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
[1]=_set({1,"goldpraybasics_0_1",1,1,"","0",1,"0",1,"goldbuy_icon_1"},_mt),
[2]=_set({2,"goldpraybasics_0_2",2,2,"102001=20","0",2,"0",1,"goldbuy_icon_2"},_mt),
[3]=_set({3,"goldpraybasics_0_3",3,3,"100120=1","0",4,"0",1,"goldbuy_icon_3"},_mt)
}

return _datas