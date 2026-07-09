local _keys = {refId=1,name=2,sort=3,allSort=4}
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
[101]=_set({101,"playeritembagtab_0_101",101,0},_mt),
[201]=_set({201,"playeritembagtab_0_201",201,1},_mt),
[202]=_set({202,"playeritembagtab_0_202",202,2},_mt),
[203]=_set({203,"playeritembagtab_0_203",203,3},_mt),
[204]=_set({204,"playeritembagtab_0_204",204,4},_mt),
[205]=_set({205,"playeritembagtab_0_205",205,5},_mt),
[206]=_set({206,"playeritembagtab_0_206",206,6},_mt),
[207]=_set({207,"playeritembagtab_0_207",207,7},_mt),
[208]=_set({208,"playeritembagtab_0_208",208,8},_mt),
[209]=_set({209,"playeritembagtab_0_209",209,9},_mt)
}

return _datas