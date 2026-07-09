local _splitNames = { 
{"MonsterAttrRef0", 0},
{"MonsterAttrRef1", 19606},
{"MonsterAttrRef2", 100082},
{"MonsterAttrRef3", 230126},
{"MonsterAttrRef4", 330006},
{"MonsterAttrRef5", 338006},
{"MonsterAttrRef6", 358006},
{"MonsterAttrRef7", 378006},
{"MonsterAttrRef8", 398006},
{"MonsterAttrRef9", 432006},
{"MonsterAttrRef10", 560601},
{"MonsterAttrRef11", 660206},
{"MonsterAttrRef12", 720006},
{"MonsterAttrRef13", 732006},
{"MonsterAttrRef14", 752006},
{"MonsterAttrRef15", 772006},
{"MonsterAttrRef16", 792006},
{"MonsterAttrRef17", 854006},
{"MonsterAttrRef18", 900046},
{"MonsterAttrRef19", 1030106},
{"MonsterAttrRef20", 1121056},
{"MonsterAttrRef21", 1310306},
{"MonsterAttrRef23", 2020115},
{"MonsterAttrRef26", 2206006},
{"MonsterAttrRef27", 2350106},
{"MonsterAttrRef30", 3000001},
{"MonsterAttrRef50", 50003206},
{"MonsterAttrRef99", 99100005},

}
local _splitTables = {}

local _mt = {}
_mt.__index = function(t, k)
    k = tonumber(k)
    if not k then return nil end
    local name
    for limit, v in ipairs(_splitNames) do
        if k <= v[2] then
            name = v[1]
            break
        end
    end
    if not name then return nil end
    local tbl = _splitTables[name]
    if not tbl then
        tbl = xnrequire("datal."..name)
        _splitTables[name] = tbl
    end

    if not tbl then return nil end
    return tbl[k]
end

local exportTbl = {}
setmetatable(exportTbl, _mt)

return exportTbl