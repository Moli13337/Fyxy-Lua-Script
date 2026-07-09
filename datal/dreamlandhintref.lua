local _keys = {refId=1,event=2,hint=3,text=4}
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
[101]=_set({101,"104;303;304","buff_txt_ss_1","wonderhint_0_101"},_mt),
[102]=_set({102,"201","buff_txt_hqqs_1","wonderhint_0_102"},_mt),
[103]=_set({103,"2","buff_txt_hx_1","wonderhint_0_103"},_mt),
[104]=_set({104,"3","buff_txt_fh_1","wonderhint_0_104"},_mt),
[105]=_set({105,"302","buff_txt_zd_1","wonderhint_0_105"},_mt)
}

return _datas