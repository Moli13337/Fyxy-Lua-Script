local _keys = {refId=1,name=2,difficultyLimit=3,openDay=4,clearLimit=5,icon=6,exhibition=7,bg=8,strategyBg=9,skillData=10,strategyText=11}
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
[1001]=_set({1001,"dreamcrusadedifficulty_0_1001",10,"1;4;7",10,"golem_tab1","LH_Xiongmaoniang01","activity152_bg3","activity87_cell_bg_2","12233,22233,32233,42233","dreamcrusadedifficulty_1_1001"},_mt),
[1002]=_set({1002,"dreamcrusadedifficulty_0_1002",10,"2;5;7",10,"golem_tab2","LH_Munaiyi01","activity152_bg5","activity87_cell_bg_2","12233,22233,32233,42233","dreamcrusadedifficulty_1_1002"},_mt),
[1003]=_set({1003,"dreamcrusadedifficulty_0_1003",10,"3;6;7",10,"golem_tab3","LH_Tianshi01","activity152_bg4","activity87_cell_bg_2","12233,22233,32233,42233","dreamcrusadedifficulty_1_1003"},_mt)
}

return _datas