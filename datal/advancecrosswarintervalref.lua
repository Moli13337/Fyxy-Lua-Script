local _keys = {refId=1,next=2,name=3,nameColor=4,sort=5,icon=6,iconEffect=7,playerNum=8,combat=9,playerNum1=10,win=11,monster=12,monsterIcon=13,txt=14,num=15,robot=16,combatNum=17,team=18,reward=19,banNum=20}
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
[1]=_set({1,2,"advancecrosswarinterval_0_1","30e055FF",1,"crossGradingHigh_icon_1","fx_ui_heifengyongzhe1",300,"0",150,10,"214481,214482|214481,214482","icon_hero_2101","",5,10,15,"2|2","",0},_mt),
[2]=_set({2,3,"advancecrosswarinterval_0_2","30e055FF",2,"crossGradingHigh_icon_2","fx_ui_heifengyongzhe1",50,"15000000",35,10,"215211,215212,215221|215211,215212,215221","icon_hero_2101","",5,10,15,"2|2","",0},_mt),
[3]=_set({3,4,"advancecrosswarinterval_0_3","30e055FF",3,"crossGradingHigh_icon_3","fx_ui_heifengyongzhe1",50,"30000000",35,10,"215951,215952,215953|215951,215952,215953","icon_hero_2101","",5,10,15,"3|3","",0},_mt),
[4]=_set({4,5,"advancecrosswarinterval_0_4","1b62a3FF",4,"crossGradingHigh_icon_4","fx_ui_yinyuexianfeng1",100,"50000000",70,10,"216761,216762,216763,216764|216761,216762,216763","icon_hero_2101","",5,10,15,"3|3","",1},_mt),
[5]=_set({5,-1,"advancecrosswarinterval_0_5","1b62a3FF",5,"crossGradingHigh_icon_5","fx_ui_yinyuexianfeng1",9999,"70000000",5000,10,"","","",5,10,15,"4|3","",3},_mt)
}

return _datas