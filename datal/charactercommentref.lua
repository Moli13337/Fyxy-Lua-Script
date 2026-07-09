local _keys = {refId=1,hero=2,commentTxt=3,criticName=4,initialLike=5,intitialDislike=6}
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
[250101]=_set({250101,2501,"charactercomment_0_250101","charactercomment_1_250101",4,4},_mt),
[250102]=_set({250102,2501,"charactercomment_0_250102","charactercomment_1_250102",2,2},_mt),
[250103]=_set({250103,2501,"charactercomment_0_250103","charactercomment_1_250103",3,3},_mt),
[250104]=_set({250104,2501,"charactercomment_0_250104","charactercomment_1_250104",3,3},_mt),
[250105]=_set({250105,2501,"charactercomment_0_250105","charactercomment_1_250105",4,4},_mt)
}

return _datas