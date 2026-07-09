local _keys = {refId=1,name=2,linkNum=3,quality=4,spine=5,icon=6,itemSell=7}
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
[1910101]=_set({1910101,"magicpet_0_1910101",2,5,"CW_Yemubaowangzi","icon_pet_1910101","1=1900011=400=0"},_mt),
[1910102]=_set({1910102,"magicpet_0_1910102",2,5,"CW_Chaijunguitu","icon_pet_1910102","1=1900011=400=0"},_mt),
[1910103]=_set({1910103,"magicpet_0_1910103",2,5,"CW_Mengyuheibaiyang","icon_pet_1910103","1=1900011=400=0"},_mt),
[1910104]=_set({1910104,"magicpet_0_1910104",2,5,"CW_Leyuanxiaoyou","icon_pet_1910104","1=1900011=400=0"},_mt),
[1910201]=_set({1910201,"magicpet_0_1910201",3,6,"CW_Mengyubaozhen","icon_pet_1910201","1=1900011=800=0"},_mt),
[1910202]=_set({1910202,"magicpet_0_1910202",3,6,"CW_Xingkongdujiaoshou","icon_pet_1910202","1=1900011=800=0"},_mt),
[1910203]=_set({1910203,"magicpet_0_1910203",3,6,"CW_Wangchenghuofenghuang","icon_pet_1910203","1=1900011=800=0"},_mt),
[1910204]=_set({1910204,"magicpet_0_1910204",3,6,"CW_Sanpangci","icon_pet_1910204","1=1900011=800=0"},_mt),
[1910301]=_set({1910301,"magicpet_0_1910301",4,7,"CW_Chilingulong","icon_pet_1910301","1=1900011=1200=0"},_mt),
[1910302]=_set({1910302,"magicpet_0_1910302",4,7,"CW_Shengguangrenma","icon_pet_1910302","1=1900011=1200=0"},_mt),
[1910303]=_set({1910303,"magicpet_0_1910303",4,7,"CW_Shengdianshijiu","icon_pet_1910303","1=1900011=1200=0"},_mt),
[1910304]=_set({1910304,"magicpet_0_1910304",4,7,"CW_Yueyingsantoulang","icon_pet_1910304","1=1900011=1200=0"},_mt)
}

return _datas