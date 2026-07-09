local _keys = {refId=1,name=2,numType=3}
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
[1001]=_set({1001,"buff_txt_miss_1",""},_mt),
[1002]=_set({1002,"","common"},_mt),
[1003]=_set({1003,"buff_txt_bj_1","crit"},_mt),
[1004]=_set({1004,"buff_txt_hd_1","common"},_mt),
[1005]=_set({1005,"buff_txt_gd_2","common"},_mt),
[1006]=_set({1006,"buff_txt_kz_1","common"},_mt),
[1007]=_set({1007,"buff_txt_hx_1","heal"},_mt),
[1008]=_set({1008,"buff_txt_zjsh_1","common"},_mt),
[1009]=_set({1009,"buff_txt_zs_2","common"},_mt),
[2001]=_set({2001,"","hurt"},_mt),
[2002]=_set({2002,"buff_txt_rs_1","hurt"},_mt),
[2003]=_set({2003,"buff_txt_lyrs_1","hurt"},_mt),
[2004]=_set({2004,"","hurt"},_mt),
[2005]=_set({2005,"","hurt"},_mt),
[2007]=_set({2007,"buff_txt_ft_1","hurt"},_mt),
[2009]=_set({2009,"buff_txt_jd_1","hurt"},_mt),
[2010]=_set({2010,"buff_txt_fx_1","hurt"},_mt),
[2012]=_set({2012,"buff_txt_js_1","hurt"},_mt),
[2013]=_set({2013,"buff_txt_jl_1",""},_mt),
[2019]=_set({2019,"","common"},_mt),
[2020]=_set({2020,"","hurt"},_mt)
}

return _datas