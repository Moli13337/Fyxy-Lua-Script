local _keys = {refId=1,name=2,buff=3,time=4,buffFx=5,sound=6,face=7,desc=8}
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
[1]=_set({1,"","",0,"","SoundS_204","",""},_mt),
[2]=_set({2,"","atk=10,hp=50",60,"fx_buff_hudiedun","SoundS_205","blockMiniGame_face_1","blockMiniGame_txt_1"},_mt),
[3]=_set({3,"","atk=25,hp=120",60,"fx_buff_hudun","SoundS_206","blockMiniGame_face_2","blockMiniGame_txt_2"},_mt),
[4]=_set({4,"","atk=50,hp=240",60,"fx_buff_mianyidun","SoundS_207","blockMiniGame_face_3","blockMiniGame_txt_3"},_mt)
}

return _datas