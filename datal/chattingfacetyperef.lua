local _keys = {refId=1,type=2,faceType=3,textType=4,icon=5,iconChecked=6,openLv=7}
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
[1]=_set({1,1,1,1,"chat_btn_face1","fight_ui_race_select",0},_mt),
[2]=_set({2,1,2,2,"chat_btn_sticker1","fight_ui_race_select",0},_mt),
[3]=_set({3,1,3,2,"chat_sticker_105","fight_ui_race_select",0},_mt)
}

return _datas