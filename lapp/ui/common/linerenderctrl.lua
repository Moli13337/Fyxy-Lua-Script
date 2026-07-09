---@class LineRenderCtrl
local LineRenderCtrl = LxClass("LineRenderCtrl", nil)
function LineRenderCtrl:LineRenderCtrl(trans)
    self.lineRender = trans:GetComponent(typeof(UnityEngine.LineRenderer))
    self.nodeCount = 20
    self.isDestroy = false
end

function LineRenderCtrl:SetLine(startPos, endPos, rotPos)
    if self.lineRender == nil then
        return
    end
    if startPos == nil or endPos == nil then
        return
    end
    self.startPos = startPos
    self.endPos = endPos
    self.rotPos = rotPos
    self.lineRender.positionCount = self.nodeCount + 1
    for i = 0, self.nodeCount do
        local to
        if rotPos then
            to = self:quardaticBezier(i / self.nodeCount)
        else
            to = self:lineBezier(i / self.nodeCount)
        end
        self.lineRender:SetPosition(i, to)
    end
end

function LineRenderCtrl:lineBezier(t)
    local a = self.startPos
    local b = self.endPos
    return a + (b - a) * t
end

function LineRenderCtrl:quardaticBezier(t)
    local a = self.startPos
    local b = self.rotPos
    local c = self.endPos
    local aa = a + (b - a) * t;
    local bb = b + (c - b) * t;
    return aa + (bb - aa) * t;
end

function LineRenderCtrl:SetSortingOrder(v)
    if self.lineRender == nil then
        return
    end
    self.lineRender.sortingOrder = v
end

function LineRenderCtrl:Destroy()
    self.lineRender = nil
    self.startPos = nil
    self.endPos = nil
    self.rotPos = nil
    self.isDestroy = true
end

return LineRenderCtrl