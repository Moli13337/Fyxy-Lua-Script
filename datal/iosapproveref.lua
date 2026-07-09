local _keys = {refId=1,ios=2}
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
ClanBargainShopRef=_set({"ClanBargainShopRef",1},_mt),
CharacterConfigRef=_set({"CharacterConfigRef",1},_mt),
PlayerGradeLvRef=_set({"PlayerGradeLvRef",1},_mt),
FeatureOpenRef=_set({"FeatureOpenRef",1},_mt),
BattleTemplePalaceRef=_set({"BattleTemplePalaceRef",1},_mt),
CharacterEffectRef=_set({"CharacterEffectRef",1},_mt),
featureopen=_set({"featureopen",1},_mt),
DraconicRef=_set({"DraconicRef",1},_mt),
PopupPackageRef=_set({"PopupPackageRef",1},_mt),
FunctionOpenShieldRef=_set({"FunctionOpenShieldRef",1},_mt),
SnakeRoleConfigRef=_set({"SnakeRoleConfigRef",1},_mt),
MainInstanceMissionRef=_set({"MainInstanceMissionRef",1},_mt),
StorylineConfigRef=_set({"StorylineConfigRef",1},_mt),
TopupRef=_set({"TopupRef",1},_mt),
TopupPayRef=_set({"TopupPayRef",1},_mt),
SdkChnResources=_set({"SdkChnResources",1},_mt)
}

return _datas