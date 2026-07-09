local _splitNames = { 
{"MonsterFormationRef0", 0},
{"MonsterFormationRef1", 9901001},
{"MonsterFormationRef110", 2000000},

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