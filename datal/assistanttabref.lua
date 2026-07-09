local _keys = {refId=1,name=2,icon=3,sort=4,functionOpenId=5,tabIcon=6}
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
[1]=_set({1,"assistanttab_0_1","",1,23000010,"helper1_txt_3"},_mt),
[2]=_set({2,"assistanttab_0_2","101|102|103|104|105|116",2,23000102,"helper1_txt_5"},_mt),
[3]=_set({3,"assistanttab_0_3","112|107",3,23000103,"helper1_txt_1"},_mt),
[4]=_set({4,"assistanttab_0_4","109|113",4,23000105,"helper1_txt_2"},_mt),
[5]=_set({5,"assistanttab_0_5","110|111",5,23000106,"helper1_txt_4"},_mt)
}

return _datas