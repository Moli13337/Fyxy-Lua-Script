local _keys = {refId=1,path=2,default=3,music=4,spring=5,sea=6,halloween=7,fantasy=8}
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
[1]=_set({1,"AniRoot/MainBottom/BtnList/CityBtn/CityImageBg","","spine=fx_ui_yinye_rukoubeijing","","","",""},_mt),
[2]=_set({2,"AniRoot/MainBottom/BtnList/HeroBtn/HeroImageBg","","spine=fx_ui_yinye_rukoubeijing","","","",""},_mt),
[3]=_set({3,"AniRoot/MainBottom/BtnList/FightBtn/FightImageBg","","spine=fx_ui_yinye_rukoubeijing","","","",""},_mt),
[4]=_set({4,"AniRoot/MainBottom/BtnList/GuildBtn/GuildImageBg","","spine=fx_ui_yinye_rukoubeijing","","","",""},_mt),
[5]=_set({5,"AniRoot/MainBottom/BtnList/ArtifactBtn/ArtifactImageBg","","spine=fx_ui_yinye_rukoubeijing","","","",""},_mt),
[6]=_set({6,"AniRoot/MainTop/ExpImg/ExpEff","","spine=fx_ui_yinye_jindutiao","","","",""},_mt)
}

return _datas