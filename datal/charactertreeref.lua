local _keys = {refId=1,treePb=2,initPoint=3,bg=4,iconHd=5,icon1=6,icon2=7,initPointLv=8}
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
[1701]=_set({1701,"AwakenTree_1001",170101,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[1702]=_set({1702,"AwakenTree_1001",170201,"heroup_bg_big_3","heroup_road3","heroup_road_302","heroup_road_301",0},_mt),
[1703]=_set({1703,"AwakenTree_1001",170301,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[1704]=_set({1704,"AwakenTree_1001",170401,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[1705]=_set({1705,"AwakenTree_1001",170501,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[1731]=_set({1731,"AwakenTree_1001",173101,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[1732]=_set({1732,"AwakenTree_1001",173201,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[1601]=_set({1601,"AwakenTree_1001",160101,"heroup_bg_big_3","heroup_road3","heroup_road_302","heroup_road_301",0},_mt),
[1602]=_set({1602,"AwakenTree_1001",160201,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[1603]=_set({1603,"AwakenTree_1001",160301,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[2701]=_set({2701,"AwakenTree_1001",270101,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[2702]=_set({2702,"AwakenTree_1001",270201,"heroup_bg_big_3","heroup_road3","heroup_road_302","heroup_road_301",0},_mt),
[2703]=_set({2703,"AwakenTree_1001",270301,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[2704]=_set({2704,"AwakenTree_1001",270401,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[2705]=_set({2705,"AwakenTree_1001",270501,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[2601]=_set({2601,"AwakenTree_1001",260101,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[2731]=_set({2731,"AwakenTree_1001",273101,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[2602]=_set({2602,"AwakenTree_1001",260201,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[2603]=_set({2603,"AwakenTree_1001",260301,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[3701]=_set({3701,"AwakenTree_1001",370101,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[3702]=_set({3702,"AwakenTree_1001",370201,"heroup_bg_big_3","heroup_road3","heroup_road_302","heroup_road_301",0},_mt),
[3703]=_set({3703,"AwakenTree_1001",370301,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[3704]=_set({3704,"AwakenTree_1001",370401,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[3705]=_set({3705,"AwakenTree_1001",370501,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[3601]=_set({3601,"AwakenTree_1001",360101,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[3602]=_set({3602,"AwakenTree_1001",360201,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[3603]=_set({3603,"AwakenTree_1001",360301,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[4701]=_set({4701,"AwakenTree_1001",470101,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[4702]=_set({4702,"AwakenTree_1001",470201,"heroup_bg_big_3","heroup_road3","heroup_road_302","heroup_road_301",0},_mt),
[4703]=_set({4703,"AwakenTree_1001",470301,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[4704]=_set({4704,"AwakenTree_1001",470401,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[4705]=_set({4705,"AwakenTree_1001",470501,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[4706]=_set({4706,"AwakenTree_1001",470601,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[4707]=_set({4707,"AwakenTree_1001",470701,"heroup_bg_big_2","heroup_road2","heroup_road_102","heroup_road_101",0},_mt),
[4708]=_set({4708,"AwakenTree_1001",470801,"heroup_bg_big_2","heroup_road2","heroup_road_102","heroup_road_101",0},_mt),
[4711]=_set({4711,"AwakenTree_1001",471101,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[4731]=_set({4731,"AwakenTree_1001",473101,"heroup_bg_big_2","heroup_road2","heroup_road_102","heroup_road_101",0},_mt),
[4732]=_set({4732,"AwakenTree_1001",473201,"heroup_bg_big_2","heroup_road2","heroup_road_102","heroup_road_101",0},_mt),
[4737]=_set({4737,"AwakenTree_1001",473701,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[5701]=_set({5701,"AwakenTree_1001",570101,"heroup_bg_big_4","heroup_road4","heroup_road_402","heroup_road_401",0},_mt),
[5702]=_set({5702,"AwakenTree_1001",570201,"heroup_bg_big_3","heroup_road3","heroup_road_302","heroup_road_301",0},_mt),
[5703]=_set({5703,"AwakenTree_1001",570301,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[5704]=_set({5704,"AwakenTree_1001",570401,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[5705]=_set({5705,"AwakenTree_1001",570501,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[5706]=_set({5706,"AwakenTree_1001",570601,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[5707]=_set({5707,"AwakenTree_1001",570701,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[5708]=_set({5708,"AwakenTree_1001",570801,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[5709]=_set({5709,"AwakenTree_1001",570901,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[5710]=_set({5710,"AwakenTree_1001",571001,"heroup_bg_big_1","heroup_road1","heroup_road_102","heroup_road_101",0},_mt),
[5712]=_set({5712,"AwakenTree_1001",571201,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[5731]=_set({5731,"AwakenTree_1001",573101,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[5732]=_set({5732,"AwakenTree_1001",573201,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[6701]=_set({6701,"AwakenTree_1001",670101,"heroup_bg_big_2","heroup_road2","heroup_road_102","heroup_road_101",0},_mt),
[6702]=_set({6702,"AwakenTree_1001",670201,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt),
[6703]=_set({6703,"AwakenTree_1001",670301,"heroup_bg_big_3","heroup_road3","heroup_road_302","heroup_road_301",0},_mt),
[6704]=_set({6704,"AwakenTree_1001",670401,"heroup_bg_big_2","heroup_road2","heroup_road_202","heroup_road_201",0},_mt)
}

return _datas