local _keys = {refId=1,type=2,sort=3,text=4}
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
[101]=_set({101,1,1,"chattingbarrage_0_101"},_mt),
[102]=_set({102,1,2,"chattingbarrage_0_102"},_mt),
[103]=_set({103,1,3,"chattingbarrage_0_103"},_mt),
[104]=_set({104,1,4,"chattingbarrage_0_104"},_mt),
[105]=_set({105,1,5,"chattingbarrage_0_105"},_mt),
[106]=_set({106,1,6,"chattingbarrage_0_106"},_mt),
[201]=_set({201,2,1,"chattingbarrage_0_201"},_mt),
[202]=_set({202,2,2,"chattingbarrage_0_202"},_mt),
[203]=_set({203,2,3,"chattingbarrage_0_203"},_mt),
[204]=_set({204,2,4,"chattingbarrage_0_204"},_mt),
[205]=_set({205,2,5,"chattingbarrage_0_205"},_mt),
[206]=_set({206,2,6,"chattingbarrage_0_206"},_mt)
}

return _datas