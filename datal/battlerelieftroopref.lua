local _keys = {refId=1,type=2,condition=3,formation=4,freeTroop=5,confirmTroop=6,heroReplace=7,selfHero=8,treasure=9}
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
[1001]=_set({1001,1,"10070",1,"99010001","","4=0=2403=99010003;7=0=1402=99010004;2=0=3401=99010005",0,1},_mt),
[1002]=_set({1002,1,"20080",1,"","9=0=99010002;2=0=99010006","",0,1},_mt),
[2001]=_set({2001,2,"",1,"50001101;50001102;50001103;50001104;50001105;50001106;50001107;50001108;50001109;50001110","","",0,0},_mt)
}

return _datas