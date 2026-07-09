local _keys = {refId=1}
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
LH_Shilaimu01=_set({"LH_Shilaimu01"},_mt),
LH_Shayu01=_set({"LH_Shayu01"},_mt),
LH_Shuijingling01=_set({"LH_Shuijingling01"},_mt),
LH_Suolian01=_set({"LH_Suolian01"},_mt),
LH_Renleijujishou01=_set({"LH_Renleijujishou01"},_mt),
LH_Jinyuniang01=_set({"LH_Jinyuniang01"},_mt),
LH_Shuimuniang01=_set({"LH_Shuimuniang01"},_mt),
LH_Wuzeiniang01=_set({"LH_Wuzeiniang01"},_mt),
LH_Shuitaniang01=_set({"LH_Shuitaniang01"},_mt),
LH_Haixingniang01=_set({"LH_Haixingniang01"},_mt),
LH_Meiguiniang01=_set({"LH_Meiguiniang01"},_mt),
LH_Heishanyang01=_set({"LH_Heishanyang01"},_mt),
LH_RenA01=_set({"LH_RenA01"},_mt),
LH_Baiquan01=_set({"LH_Baiquan01"},_mt),
LH_Huli01=_set({"LH_Huli01"},_mt),
LH_Lu01=_set({"LH_Lu01"},_mt),
LH_Huo01=_set({"LH_Huo01"},_mt),
LH_Chaiquan01=_set({"LH_Chaiquan01"},_mt),
LH_Maniang01=_set({"LH_Maniang01"},_mt),
LH_Jiangshiniang01=_set({"LH_Jiangshiniang01"},_mt),
LH_Guiniang01=_set({"LH_Guiniang01"},_mt),
LH_Muouniang01=_set({"LH_Muouniang01"},_mt),
LH_Jiniang01=_set({"LH_Jiniang01"},_mt),
LH_Liwuniang01=_set({"LH_Liwuniang01"},_mt),
LH_Lvniang01=_set({"LH_Lvniang01"},_mt),
LH_Songshuniang01=_set({"LH_Songshuniang01"},_mt),
LH_Hudie01=_set({"LH_Hudie01"},_mt),
LH_Shujingling01=_set({"LH_Shujingling01"},_mt),
LH_Xiongmaoniang01=_set({"LH_Xiongmaoniang01"},_mt),
LH_Nainiu01=_set({"LH_Nainiu01"},_mt),
LH_Renzhe01=_set({"LH_Renzhe01"},_mt),
LH_Qingwaniang01=_set({"LH_Qingwaniang01"},_mt),
LH_Jinglingnvpu01=_set({"LH_Jinglingnvpu01"},_mt),
LH_Zhuniang01=_set({"LH_Zhuniang01"},_mt),
LH_Zhizhuniang01=_set({"LH_Zhizhuniang01"},_mt),
LH_Luoboniang01=_set({"LH_Luoboniang01"},_mt),
LH_Moguniang01=_set({"LH_Moguniang01"},_mt),
LH_Yehuaniang01=_set({"LH_Yehuaniang01"},_mt),
LH_Tianshi01=_set({"LH_Tianshi01"},_mt),
LH_Long01=_set({"LH_Long01"},_mt),
LH_Baige01=_set({"LH_Baige01"},_mt),
LH_Bailang01=_set({"LH_Bailang01"},_mt),
LH_Yunbao01=_set({"LH_Yunbao01"},_mt),
LH_Mohe01=_set({"LH_Mohe01"},_mt),
LH_Kesulu01=_set({"LH_Kesulu01"},_mt),
LH_Anubisi01=_set({"LH_Anubisi01"},_mt),
LH_Mao01=_set({"LH_Mao01"},_mt),
LH_Wanshengniang01=_set({"LH_Wanshengniang01"},_mt)
}

return _datas