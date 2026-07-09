local _keys = {refId=1,hero=2,star=3,level=4,outFit=5,rune=6,runeAttr=7,runeSkill=8,giftSkill=9,awaken=10,coreLv=11,coreElement=12,coreEffect=13,openDay=14,matchStar=15,extraSkill=16}
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