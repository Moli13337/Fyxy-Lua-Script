local _keys = {refId=1,type=2,icon=3,num=4}
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
[1]=_set({1,0,"hero_icon_star1",1},_mt),
[2]=_set({2,0,"hero_icon_star1",2},_mt),
[3]=_set({3,0,"hero_icon_star1",3},_mt),
[4]=_set({4,0,"hero_icon_star1",4},_mt),
[5]=_set({5,0,"hero_icon_star1",5},_mt),
[6]=_set({6,0,"hero_icon_star2",1},_mt),
[7]=_set({7,0,"hero_icon_star2",2},_mt),
[8]=_set({8,0,"hero_icon_star2",3},_mt),
[9]=_set({9,0,"hero_icon_star2",4},_mt),
[10]=_set({10,0,"hero_icon_star2",5},_mt),
[11]=_set({11,0,"hero_icon_star3",1},_mt),
[12]=_set({12,0,"hero_icon_star3",2},_mt),
[13]=_set({13,0,"hero_icon_star3",3},_mt),
[14]=_set({14,0,"hero_icon_star3",4},_mt),
[15]=_set({15,0,"hero_icon_star3",5},_mt),
[16]=_set({16,0,"hero_icon_star4",1},_mt),
[17]=_set({17,0,"hero_icon_star4",2},_mt),
[18]=_set({18,0,"hero_icon_star4",3},_mt),
[19]=_set({19,0,"hero_icon_star4",4},_mt),
[20]=_set({20,0,"hero_icon_star4",5},_mt)
}

return _datas