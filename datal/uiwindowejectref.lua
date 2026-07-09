local _keys = {refId=1,uiName=2,windowAttRefId=3,sort=4}
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
[1]=_set({1,"UIOrdinResult",0,1},_mt),
[3]=_set({3,"UIOrdinTip",30001,15},_mt),
[4]=_set({4,"UIOrdinTip",50602,16},_mt),
[5]=_set({5,"UIOrdinTip",50603,17},_mt),
[6]=_set({6,"UIPop5Gift",0,11},_mt),
[7]=_set({7,"UIPop4Gift",0,12},_mt),
[8]=_set({8,"UIPop2Gift",0,14},_mt),
[9]=_set({9,"UIPop3Gift",0,13},_mt),
[10]=_set({10,"WndPrePost",0,19},_mt),
[11]=_set({11,"UIringFightResult",0,1},_mt),
[12]=_set({12,"UILvUp",0,3},_mt),
[13]=_set({13,"UIGjAwardReceive",0,2},_mt),
[14]=_set({14,"UIAdLogNotion",0,20},_mt),
[15]=_set({15,"UIHuiY",0,-1},_mt),
[16]=_set({16,"UIAward",0,-2},_mt),
[17]=_set({17,"UIAppsal",0,1},_mt)
}

return _datas