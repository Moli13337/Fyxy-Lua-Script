local _keys = {refId=1,name=2,sort=3,nextStage=4,list=5,icon=6,effName=7,playerMax=8,playerShow=9,rankScope=10,reward=11,titleReward=12,like=13,defendShow=14}
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
[101]=_set({101,"battletemplepalace_0_101",1,102,"I","warTemple_cell_bg_103","fx_ui_shaonvdiantang_01",99999,0,"","1=102001=50=0,1=112009=50=0,1=100211=1=0","",0,0},_mt),
[102]=_set({102,"battletemplepalace_0_102",2,103,"II","warTemple_cell_bg_102","fx_ui_shaonvdiantang_02",400,100,"651,1050","1=102001=100=0,1=112009=100=0,1=100211=2=0","",0,1602},_mt),
[103]=_set({103,"battletemplepalace_0_103",3,104,"III","warTemple_cell_bg_101","fx_ui_shaonvdiantang_03",300,50,"351,650","1=102001=200=0,1=112008=5000=0,1=100211=3=0","1=1501020=1=0",0,2601},_mt),
[104]=_set({104,"battletemplepalace_0_104",4,105,"IV","warTemple_cell_bg_104","fx_ui_shaonvdiantang_04",200,50,"151,350","1=102001=300=0,1=112008=20000=0,1=100211=5=0","1=1501021=1=0",0,3502},_mt),
[105]=_set({105,"battletemplepalace_0_105",5,106,"V","warTemple_cell_bg_105","fx_ui_shaonvdiantang_05",100,50,"51,150","1=102001=400=0,1=112008=50000=0,1=100212=1=0","1=1501022=1=0",1003,4706},_mt),
[106]=_set({106,"battletemplepalace_0_106",6,0,"VI","warTemple_cell_bg_106","fx_ui_shaonvdiantang_06",50,50,"1,50","1=102001=500=0,1=112008=100000=0,1=100212=2=0","1=1501023=1=0",1005,5704},_mt)
}

return _datas