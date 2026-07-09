---dotween 创建销毁
---@class SequenceCom
local SequenceCom = LxClass("SequenceCom",nil)

local Tweening = DG.Tweening


function SequenceCom:SequenceCom()

end

function SequenceCom:CreateSeq(key)
    if not self._seqMap  then
        self._seqMap = {}
    end
    local seq = self._seqMap[key]
    if seq then
        seq:Kill(false)
    end
    seq = Tweening.DOTween.Sequence()
    self._seqMap[key] = seq
    return seq
end

function SequenceCom:Destroy()
    if not self._seqMap then
        return
    end
    for k,v in pairs(self._seqMap) do
        v:Kill(false)
    end
    self._seqMap = nil
end

function SequenceCom:FindSeq(key)
    return self._seqMap and self._seqMap[key]
end

function SequenceCom:DeleteSeq(key)
    if not self._seqMap then
        return
    end
    local seq = self._seqMap[key]
    if seq then
        self._seqMap[key] = nil
        seq:Kill(false)
    end
end

function SequenceCom:DeleteAllSeq()
    if not self._seqMap then return end

    for k,v in pairs(self._seqMap) do
        v:Kill(false)
    end
    self._seqMap = nil
end

return SequenceCom