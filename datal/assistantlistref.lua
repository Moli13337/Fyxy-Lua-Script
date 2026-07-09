local _keys = {refId=1,open=2,name=3,helpTips=4,desd=5,text=6,desd1=7,desd2=8}
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
[101]=_set({101,"1=35","assistantlist_0_101","","assistantlist_2_101","assistantlist_3_101","assistantlist_4_101","assistantlist_5_101"},_mt),
[102]=_set({102,"1=50","assistantlist_0_102","","assistantlist_2_102","assistantlist_3_102","assistantlist_4_102","assistantlist_5_102"},_mt),
[103]=_set({103,"1=35","assistantlist_0_103","","assistantlist_2_103","assistantlist_3_103","assistantlist_4_103","assistantlist_5_103"},_mt),
[104]=_set({104,"1=35","assistantlist_0_104","","assistantlist_2_104","assistantlist_3_104","assistantlist_4_104","assistantlist_5_104"},_mt),
[105]=_set({105,"1=35","assistantlist_0_105","","assistantlist_2_105","assistantlist_3_105","assistantlist_4_105","assistantlist_5_105"},_mt),
[106]=_set({106,"1=60","assistantlist_0_106","","assistantlist_2_106","assistantlist_3_106","assistantlist_4_106","assistantlist_5_106"},_mt),
[107]=_set({107,"1=35","assistantlist_0_107","","assistantlist_2_107","assistantlist_3_107","assistantlist_4_107","assistantlist_5_107"},_mt),
[109]=_set({109,"1=35","assistantlist_0_109","","","assistantlist_3_109","assistantlist_4_109","assistantlist_5_109"},_mt),
[110]=_set({110,"1=50,5=1","assistantlist_0_110","","","assistantlist_3_110","assistantlist_4_110","assistantlist_5_110"},_mt),
[111]=_set({111,"1=50,5=1","assistantlist_0_111","","","assistantlist_3_111","assistantlist_4_111","assistantlist_5_111"},_mt),
[112]=_set({112,"1=50","assistantlist_0_112","","assistantlist_2_112","assistantlist_3_112","assistantlist_4_112","assistantlist_5_112"},_mt),
[113]=_set({113,"1=40","assistantlist_0_113","","","assistantlist_3_113","assistantlist_4_113","assistantlist_5_113"},_mt),
[114]=_set({114,"1=999","assistantlist_0_114","","","","",""},_mt),
[115]=_set({115,"1=50","assistantlist_0_115","","","assistantlist_3_115","assistantlist_4_115","assistantlist_5_115"},_mt),
[116]=_set({116,"1=35","assistantlist_0_116","","","assistantlist_3_116","assistantlist_4_116","assistantlist_5_116"},_mt)
}

return _datas