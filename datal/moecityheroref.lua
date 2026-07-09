local _keys = {refId=1,heroId=2,name=3,icon=4,headIcon=5,quality=6,level=7,startSkill=8,skillId=9,desc=10}
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
[10001]=_set({10001,100001,"moecityhero_0_10001","icon_herobook_3705","icon_hero_3705",7,0,1000100,"1000110","moecityhero_1_10001"},_mt),
[10002]=_set({10002,100001,"moecityhero_0_10002","icon_herobook_3705","icon_hero_3705",7,1,1000101,"1000110","moecityhero_1_10002"},_mt),
[10003]=_set({10003,100001,"moecityhero_0_10003","icon_herobook_3705","icon_hero_3705",7,3,1000101,"1000110,1000120","moecityhero_1_10003"},_mt),
[10004]=_set({10004,100001,"moecityhero_0_10004","icon_herobook_3705","icon_hero_3705",7,5,1000101,"1000111,1000120","moecityhero_1_10004"},_mt),
[10005]=_set({10005,100001,"moecityhero_0_10005","icon_herobook_3705","icon_hero_3705",7,7,1000101,"1000111,1000120,1000130","moecityhero_1_10005"},_mt),
[10006]=_set({10006,100001,"moecityhero_0_10006","icon_herobook_3705","icon_hero_3705",7,9,1000101,"1000111,1000121,1000130","moecityhero_1_10006"},_mt),
[10007]=_set({10007,100001,"moecityhero_0_10007","icon_herobook_3705","icon_hero_3705",7,10,1000101,"1000111,1000121,1000131","moecityhero_1_10007"},_mt),
[20001]=_set({20001,100002,"moecityhero_0_20001","icon_herobook_2705","icon_hero_2705",7,0,1000200,"1000210","moecityhero_1_20001"},_mt),
[20002]=_set({20002,100002,"moecityhero_0_20002","icon_herobook_2705","icon_hero_2705",7,1,1000201,"1000210","moecityhero_1_20002"},_mt),
[20003]=_set({20003,100002,"moecityhero_0_20003","icon_herobook_2705","icon_hero_2705",7,3,1000201,"1000210,1000220","moecityhero_1_20003"},_mt),
[20004]=_set({20004,100002,"moecityhero_0_20004","icon_herobook_2705","icon_hero_2705",7,5,1000201,"1000211,1000220","moecityhero_1_20004"},_mt),
[20005]=_set({20005,100002,"moecityhero_0_20005","icon_herobook_2705","icon_hero_2705",7,7,1000201,"1000211,1000220,1000230","moecityhero_1_20005"},_mt),
[20006]=_set({20006,100002,"moecityhero_0_20006","icon_herobook_2705","icon_hero_2705",7,9,1000201,"1000211,1000221,1000230","moecityhero_1_20006"},_mt),
[20007]=_set({20007,100002,"moecityhero_0_20007","icon_herobook_2705","icon_hero_2705",7,10,1000201,"1000211,1000221,1000231","moecityhero_1_20007"},_mt),
[30001]=_set({30001,100003,"moecityhero_0_30001","icon_herobook_1701","icon_hero_1701",7,0,1000300,"1000310","moecityhero_1_30001"},_mt),
[30002]=_set({30002,100003,"moecityhero_0_30002","icon_herobook_1701","icon_hero_1701",7,1,1000301,"1000310","moecityhero_1_30002"},_mt),
[30003]=_set({30003,100003,"moecityhero_0_30003","icon_herobook_1701","icon_hero_1701",7,3,1000301,"1000310,1000320","moecityhero_1_30003"},_mt),
[30004]=_set({30004,100003,"moecityhero_0_30004","icon_herobook_1701","icon_hero_1701",7,5,1000301,"1000311,1000320","moecityhero_1_30004"},_mt),
[30005]=_set({30005,100003,"moecityhero_0_30005","icon_herobook_1701","icon_hero_1701",7,7,1000301,"1000311,1000320,1000330","moecityhero_1_30005"},_mt),
[30006]=_set({30006,100003,"moecityhero_0_30006","icon_herobook_1701","icon_hero_1701",7,9,1000301,"1000311,1000321,1000330","moecityhero_1_30006"},_mt),
[30007]=_set({30007,100003,"moecityhero_0_30007","icon_herobook_1701","icon_hero_1701",7,10,1000301,"1000311,1000321,1000331","moecityhero_1_30007"},_mt),
[40001]=_set({40001,100004,"moecityhero_0_40001","icon_herobook_4706","icon_hero_4706",7,0,1000400,"1000410","moecityhero_1_40001"},_mt),
[40002]=_set({40002,100004,"moecityhero_0_40002","icon_herobook_4706","icon_hero_4706",7,1,1000401,"1000410","moecityhero_1_40002"},_mt),
[40003]=_set({40003,100004,"moecityhero_0_40003","icon_herobook_4706","icon_hero_4706",7,3,1000401,"1000410,1000420","moecityhero_1_40003"},_mt),
[40004]=_set({40004,100004,"moecityhero_0_40004","icon_herobook_4706","icon_hero_4706",7,5,1000401,"1000411,1000420","moecityhero_1_40004"},_mt),
[40005]=_set({40005,100004,"moecityhero_0_40005","icon_herobook_4706","icon_hero_4706",7,7,1000401,"1000411,1000420,1000430","moecityhero_1_40005"},_mt),
[40006]=_set({40006,100004,"moecityhero_0_40006","icon_herobook_4706","icon_hero_4706",7,9,1000401,"1000411,1000421,1000430","moecityhero_1_40006"},_mt),
[40007]=_set({40007,100004,"moecityhero_0_40007","icon_herobook_4706","icon_hero_4706",7,10,1000401,"1000411,1000421,1000431","moecityhero_1_40007"},_mt),
[50001]=_set({50001,100005,"moecityhero_0_50001","icon_herobook_5701","icon_hero_5701",7,0,1000500,"1000510","moecityhero_1_50001"},_mt),
[50002]=_set({50002,100005,"moecityhero_0_50002","icon_herobook_5701","icon_hero_5701",7,1,1000501,"1000510","moecityhero_1_50002"},_mt),
[50003]=_set({50003,100005,"moecityhero_0_50003","icon_herobook_5701","icon_hero_5701",7,3,1000501,"1000510,1000520","moecityhero_1_50003"},_mt),
[50004]=_set({50004,100005,"moecityhero_0_50004","icon_herobook_5701","icon_hero_5701",7,5,1000501,"1000511,1000520","moecityhero_1_50004"},_mt),
[50005]=_set({50005,100005,"moecityhero_0_50005","icon_herobook_5701","icon_hero_5701",7,7,1000501,"1000511,1000520,1000530","moecityhero_1_50005"},_mt),
[50006]=_set({50006,100005,"moecityhero_0_50006","icon_herobook_5701","icon_hero_5701",7,9,1000501,"1000511,1000521,1000530","moecityhero_1_50006"},_mt),
[50007]=_set({50007,100005,"moecityhero_0_50007","icon_herobook_5701","icon_hero_5701",7,10,1000501,"1000511,1000521,1000531","moecityhero_1_50007"},_mt)
}

return _datas