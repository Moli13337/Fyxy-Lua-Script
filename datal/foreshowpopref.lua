local _keys = {refId=1,sort=2,image=3,imagePos=4,cellBgTxt=5,cellBgTxtPos=6,cellNameDec=7,cellNameDecPos=8,jumpBtnIcon=9,jumpBtnText=10,jumpBtnPos=11,functionOpen=12,tip=13,tipPos=14,tipDesc=15,tipInitial=16}
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
[101]=_set({101,10000,"plan5_bg_big_1","0,60","","","foreshowpop_0_101","","","foreshowpop_1_101","",13200000,1,0,"foreshowpop_2_101",0},_mt),
[102]=_set({102,9999,"plan5_bg_big_1","0,60","","","foreshowpop_0_102","","","foreshowpop_1_102","",24000000,0,0,"",0},_mt),
[103]=_set({103,10001,"plan5_bg_big_1","0,60","","","foreshowpop_0_103","","","foreshowpop_1_103","",12111007,1,0,"foreshowpop_2_103",1},_mt),
[104]=_set({104,10002,"plan5_bg_big_1","0,60","","","foreshowpop_0_104","","","foreshowpop_1_104","",12111009,0,0,"",0},_mt)
}

return _datas