local _keys = {refId=1,giftShowType=2,giftType=3,giftGroup=4,giftLinkType=5,giftGroupCount=6,giftNextGrade=7,activateType=8,giftGradeName=9,buyBtnTxt=10,showHero=11,showXY=12,giftName=13,popupType=14,firePriority=15,time=16,limit=17,lifetimeLimit=18,reward=19,rewardFree=20,buyType=21,expend=22,sort=23,discount=24,descriptionNo=25,description=26,descriptionSaleOut=27,icon=28}
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