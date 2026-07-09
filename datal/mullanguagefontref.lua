local _keys = {refId=1,enus=2,zhcn=3}
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
common_num=_set({"common_num","enus/common_num_enus","zhcn/common_num_zhcn"},_mt),
crit_num=_set({"crit_num","enus/crit_num_enus","zhcn/crit_num_zhcn"},_mt),
heal_num=_set({"heal_num","enus/heal_num_enus","zhcn/heal_num_zhcn"},_mt),
hurt_num=_set({"hurt_num","enus/hurt_num_enus","zhcn/hurt_num_zhcn"},_mt),
strike_num=_set({"strike_num","enus/strike_num_enus","zhcn/strike_num_zhcn"},_mt),
ce_num=_set({"ce_num","enus/ce_num_enus","zhcn/ce_num_zhcn"},_mt)
}

return _datas