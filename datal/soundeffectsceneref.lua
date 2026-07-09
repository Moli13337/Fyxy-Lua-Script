local _keys = {refId=1,soundType=2,soundName=3,surround=4}
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
LLoginScene=_set({"LLoginScene",2,"SoundM_1",""},_mt),
MapCity=_set({"MapCity",2,"SoundM_1",""},_mt),
UIMirNew=_set({"UIMirNew",1,"SoundM_2",""},_mt),
MapBtIdle001=_set({"MapBtIdle001",2,"SoundM_3",""},_mt),
MapBtIdle002=_set({"MapBtIdle002",2,"SoundM_3",""},_mt),
MapBtIdle003=_set({"MapBtIdle003",2,"SoundM_3",""},_mt),
MapBtIdle005=_set({"MapBtIdle005",2,"SoundM_3",""},_mt),
MapBtIdle006=_set({"MapBtIdle006",2,"SoundM_3",""},_mt),
MapBtIdle009=_set({"MapBtIdle009",2,"SoundM_3",""},_mt),
MapBtIdle010=_set({"MapBtIdle010",2,"SoundM_3",""},_mt),
MapBtIdle011=_set({"MapBtIdle011",2,"SoundM_3",""},_mt),
MapBtIdle012=_set({"MapBtIdle012",2,"SoundM_3",""},_mt),
UIOutts=_set({"UIOutts",2,"SoundM_3",""},_mt),
UIInvoss=_set({"UIInvoss",1,"SoundM_3",""},_mt),
MapDreamTrip=_set({"MapDreamTrip",2,"SoundM_3",""},_mt),
UISubOuttsPvpEnter=_set({"UISubOuttsPvpEnter",2,"SoundM_4",""},_mt),
UIFight=_set({"UIFight",1,"SoundM_5",""},_mt),
UIGenWin=_set({"UIGenWin",1,"SoundM_6",""},_mt),
UIFavorabilityInteract=_set({"UIFavorabilityInteract",1,"SoundM_6",""},_mt),
UISaga=_set({"UISaga",1,"SoundM_6",""},_mt),
UIAct=_set({"UIAct",1,"SoundM_6",""},_mt),
UIBlockMiniGame=_set({"UIBlockMiniGame",1,"SoundM_8",""},_mt),
UISubGdHoFightPkActually=_set({"UISubGdHoFightPkActually",1,"SoundM_7",""},_mt)
}

return _datas