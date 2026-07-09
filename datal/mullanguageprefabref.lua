local _keys = {refId=1,zhcn=2}
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
fx_ui_shengli=_set({"fx_ui_shengli","fx_ui_shengli_zhcn"},_mt),
fx_ui_shibai=_set({"fx_ui_shibai","fx_ui_shibai_zhcn"},_mt),
fx_zhandoujinchangtuzi=_set({"fx_zhandoujinchangtuzi","fx_zhandoujinchangtuzi_zhcn"},_mt),
effect_yincangchengjiu=_set({"effect_yincangchengjiu","effect_yincangchengjiu_zhcn"},_mt),
fx_ui_jingcaichenggong=_set({"fx_ui_jingcaichenggong","fx_ui_jingcaichenggong_zhcn"},_mt),
fx_ui_jingcaishibai=_set({"fx_ui_jingcaishibai","fx_ui_jingcaishibai_zhcn"},_mt),
fx_ui_shengqi_buff_dengji=_set({"fx_ui_shengqi_buff_dengji","fx_ui_shengqi_buff_dengji_zhcn"},_mt),
fx_huodelongwen=_set({"fx_huodelongwen","fx_huodelongwen_zhcn"},_mt),
fx_ui_gongxihuode=_set({"fx_ui_gongxihuode","fx_ui_gongxihuode_zhcn"},_mt),
fx_GHJN_jinengshengji_biaoti=_set({"fx_GHJN_jinengshengji_biaoti","fx_GHJN_jinengshengji_biaoti_zhcn"},_mt),
fx_ui_wushendian_wqny_1=_set({"fx_ui_wushendian_wqny_1","fx_ui_wushendian_wqny_1_zhcn"},_mt),
fx_ui_zhaohuanouqi=_set({"fx_ui_zhaohuanouqi","fx_ui_zhaohuanouqi_zhcn"},_mt),
fx_VIP_biaoti=_set({"fx_VIP_biaoti","fx_VIP_biaoti_zhcn"},_mt),
fx_zhanbao_liansheng=_set({"fx_zhanbao_liansheng","fx_zhanbao_liansheng_zhcn"},_mt),
fx_ui_duanweitisheng=_set({"fx_ui_duanweitisheng","fx_ui_duanweitisheng_zhcn"},_mt),
fx_ui_xiannv_biaoti_1=_set({"fx_ui_xiannv_biaoti_1","fx_ui_xiannv_biaoti_1_zhcn"},_mt),
fx_ui_xiannv_biaoti_2=_set({"fx_ui_xiannv_biaoti_2","fx_ui_xiannv_biaoti_2_zhcn"},_mt),
ui_hero_btn_xingtai_2=_set({"ui_hero_btn_xingtai_2","ui_hero_btn_xingtai_2_zhcn"},_mt)
}

return _datas