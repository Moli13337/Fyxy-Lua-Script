local _keys = {refId=1,filterType=2,sort=3,name=4,value=5}
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
[100000]=_set({100000,1000,1,"mediafiltertype_0_100000",""},_mt),
[100101]=_set({100101,1001,1,"mediafiltertype_0_100101",""},_mt),
[100102]=_set({100102,1001,2,"mediafiltertype_0_100102","1,50"},_mt),
[100103]=_set({100103,1001,3,"mediafiltertype_0_100103","51,100"},_mt),
[100104]=_set({100104,1001,4,"mediafiltertype_0_100104","101,150"},_mt),
[100105]=_set({100105,1001,5,"mediafiltertype_0_100105","151,-1"},_mt),
[100301]=_set({100301,1003,1,"mediafiltertype_0_100301",""},_mt),
[100302]=_set({100302,1003,7,"mediafiltertype_0_100302",""},_mt),
[100303]=_set({100303,1003,6,"mediafiltertype_0_100303",""},_mt),
[100304]=_set({100304,1003,5,"mediafiltertype_0_100304",""},_mt),
[100305]=_set({100305,1003,4,"mediafiltertype_0_100305",""},_mt),
[100306]=_set({100306,1003,3,"mediafiltertype_0_100306",""},_mt),
[100307]=_set({100307,1003,2,"mediafiltertype_0_100307",""},_mt),
[100401]=_set({100401,1004,1,"mediafiltertype_0_100401",""},_mt),
[100402]=_set({100402,1004,2,"mediafiltertype_0_100402",""},_mt),
[100601]=_set({100601,1006,1,"mediafiltertype_0_100601",""},_mt),
[100602]=_set({100602,1006,2,"mediafiltertype_0_100602","1,10"},_mt),
[100603]=_set({100603,1006,3,"mediafiltertype_0_100603","11,50"},_mt),
[100604]=_set({100604,1006,4,"mediafiltertype_0_100604","51,-1"},_mt),
[101001]=_set({101001,1010,1,"mediafiltertype_0_101001",""},_mt),
[101002]=_set({101002,1010,2,"mediafiltertype_0_101002",""},_mt),
[101003]=_set({101003,1010,3,"mediafiltertype_0_101003",""},_mt),
[101004]=_set({101004,1010,4,"mediafiltertype_0_101004",""},_mt),
[101005]=_set({101005,1010,5,"mediafiltertype_0_101005",""},_mt),
[101006]=_set({101006,1010,6,"mediafiltertype_0_101006",""},_mt),
[101007]=_set({101007,1010,7,"mediafiltertype_0_101007",""},_mt),
[101008]=_set({101008,1010,8,"mediafiltertype_0_101008",""},_mt),
[101009]=_set({101009,1010,9,"mediafiltertype_0_101009",""},_mt),
[101010]=_set({101010,1010,10,"mediafiltertype_0_101010",""},_mt),
[101011]=_set({101011,1010,11,"mediafiltertype_0_101011",""},_mt)
}

return _datas