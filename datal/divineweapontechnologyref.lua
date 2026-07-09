local _keys = {refId=1,nextSktill=2,precondition=3,group=4,name=5,icon=6,iconBg=7}
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
[10001]=_set({10001,"","",1,"divineweapontechnology_0_10001","weapon_skill_1",""},_mt),
[20001]=_set({20001,"10001","3=1",2,"divineweapontechnology_0_20001","guildskill_13","public_skill_bg"},_mt),
[20002]=_set({20002,"10001","3=1",2,"divineweapontechnology_0_20002","buff_hudiezhen","public_skill_bg"},_mt),
[20003]=_set({20003,"10001","3=1",2,"divineweapontechnology_0_20003","buff_sp_up","public_skill_bg"},_mt),
[20004]=_set({20004,"10001","3=1",2,"divineweapontechnology_0_20004","buff_shihua","public_skill_bg"},_mt),
[30001]=_set({30001,"20001","3=20",3,"divineweapontechnology_0_30001","icon_skill_33011","public_skill_bg"},_mt),
[30002]=_set({30002,"20002","3=20",3,"divineweapontechnology_0_30002","buff_zhuoshao1","public_skill_bg"},_mt),
[30003]=_set({30003,"20003","3=20",3,"divineweapontechnology_0_30003","buff_shuidun","public_skill_bg"},_mt),
[30004]=_set({30004,"20004","3=20",3,"divineweapontechnology_0_30004","buff_dongjie","public_skill_bg"},_mt),
[40001]=_set({40001,"30001|30002|30003|30004","1=50|2=20",4,"divineweapontechnology_0_40001","weapon_skill_2",""},_mt),
[50001]=_set({50001,"40001","3=5",5,"divineweapontechnology_0_50001","guildskill_12","public_skill_bg"},_mt),
[50002]=_set({50002,"40001","3=5",5,"divineweapontechnology_0_50002","guildskill_5","public_skill_bg"},_mt),
[50003]=_set({50003,"40001","3=5",5,"divineweapontechnology_0_50003","buff_def1_up","public_skill_bg"},_mt),
[50004]=_set({50004,"40001","3=5",5,"divineweapontechnology_0_50004","buff_senzhizhufu","public_skill_bg"},_mt),
[60001]=_set({60001,"50001","3=20",6,"divineweapontechnology_0_60001","icon_skill_32011","public_skill_bg"},_mt),
[60002]=_set({60002,"50002","3=20",6,"divineweapontechnology_0_60002","buff_shuangdong","public_skill_bg"},_mt),
[60003]=_set({60003,"50003","3=20",6,"divineweapontechnology_0_60003","buff_linyou","public_skill_bg"},_mt),
[60004]=_set({60004,"50004","3=20",6,"divineweapontechnology_0_60004","guildskill_1","public_skill_bg"},_mt),
[70001]=_set({70001,"60001|60002|60003|60004","1=130|2=40",7,"divineweapontechnology_0_70001","weapon_skill_3",""},_mt),
[80001]=_set({80001,"70001","3=5",8,"divineweapontechnology_0_80001","buff_xiwangzhifeng","public_skill_bg"},_mt),
[80002]=_set({80002,"70001","3=5",8,"divineweapontechnology_0_80002","buff_zhuoshao","public_skill_bg"},_mt),
[80003]=_set({80003,"70001","3=5",8,"divineweapontechnology_0_80003","buff_huyou","public_skill_bg"},_mt),
[80004]=_set({80004,"70001","3=5",8,"divineweapontechnology_0_80004","guildskill_2","public_skill_bg"},_mt),
[90001]=_set({90001,"80001","3=20",9,"divineweapontechnology_0_90001","buff_mianyi","public_skill_bg"},_mt),
[90002]=_set({90002,"80002","3=20",9,"divineweapontechnology_0_90002","buff_wlyinji","public_skill_bg"},_mt),
[90003]=_set({90003,"80003","3=20",9,"divineweapontechnology_0_90003","buff_shang","public_skill_bg"},_mt),
[90004]=_set({90004,"80004","3=20",9,"divineweapontechnology_0_90004","buff_fengyin","public_skill_bg"},_mt)
}

return _datas