
local LxNodeBase = require("LApp.component.LxNodeBase")
---@class LWonderHud:LxNodeBase
local LWonderHud = LxClass("LWonderHud",LxNodeBase)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic
function LWonderHud:LWonderHud()
    self._path = "UI/Prefabs/Com"
    self._name = "WonderHud"

    ---@type LDisplayPrefab
    self._dpPrefab = nil

    self._seqCom = SequenceCom:New()
end

--[[
data =
{
    root,
    icon,
    text,
    pos,
    onTweenEnd,
}
]]

function LWonderHud:Create(data)
    self._data = data
    if self:IsHudValid() then
        self:SetContent()
        return
    end

    self:ClearPrefab()
    local dpPrefab = LDisplayPrefab:New()
    self._dpPrefab = dpPrefab
    dpPrefab:CreatePrefab(data.root, self._path, self._name)
    dpPrefab:SetLoadedFunction(function (dp)
        self:OnLoaded(dp)
    end)
    dpPrefab:StartLoad()
end

function LWonderHud:OnLoaded(dp)
    if self._isDetroyed then return end

    local instanceTrans = dp:GetDisplayTrans()
    if instanceTrans then
        self._hudTran = instanceTrans
        self:SetContent()
    end
end

function LWonderHud:SetContent()
    if not self:IsHudValid() then return end

    local data = self._data
    local trans = CS.FindTrans(self._hudTran,"root/Image")
    local imagePath = data.icon
    CS.ShowObject(trans,false)
    self:SetImage(trans, imagePath, function ()
        CS.ShowObject(trans,true)
    end)

    trans = CS.FindTrans(self._hudTran,"root/Text")
    local text = data.text
    self:SetXTextContent(trans,text)

    self._hudTran.position = data.pos
    self:StartTween()
end

function LWonderHud:IsHudValid()
    return CS.IsValidObject(self._hudTran)
end

function LWonderHud:StartTween()
    local seqtween = self._seqCom:CreateSeq("moveTween")
    local trans = self._hudTran
    local canvasGroup = trans:GetComponent(typeofCanvasGroup)
    canvasGroup.alpha = 1

    local stayTime = 0.5
    local moveY = 20
    local moveTime = 0.5
    local alphaTime = 0.5 -- alpha 消失时间
    --local large = Vector3(2,2,2)        -- 大
    local middle = Vector3(1.5,1.5,1.5) -- 中
    local small = Vector3(1,1,1)        -- 小
    local size = middle

    local alphaStartPos = stayTime + moveTime - alphaTime + 0.5

    --放大
    local sizeTween = trans:DOScale(size,0.1):SetEase(EaseOutCubic)
    seqtween:Append(sizeTween)

    --缩小
    local smallTween = trans:DOScale(small,0.1):SetEase(EaseOutCubic)
    seqtween:Append(smallTween)

    seqtween:AppendInterval(stayTime)

    --alpha 动画消失
    local alphaTween = canvasGroup:DOFade(0,alphaTime):SetEase(DG.Tweening.Ease.InSine)

    -- Y移动动画
    local moveTween = trans:DOLocalMoveY(trans.localPosition.y + moveY,moveTime)

    seqtween:Append(moveTween)
    seqtween:Insert(alphaStartPos,alphaTween)

    seqtween:OnComplete(function()
        self._seqCom:DeleteSeq("moveTween")
        if self._data.onTweenEnd then
            self._data.onTweenEnd(self)
        end
    end)

    seqtween:PlayForward()
end

function LWonderHud:ClearPrefab()
    if self._dpPrefab then
        self._dpPrefab:Destroy()
        self._dpPrefab = nil
    end
end

function LWonderHud:Destroy()
    if self._isDetroyed then return end

    self:ClearPrefab()

    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end
    LxNodeBase.Dispose(self)
    self._isDetroyed = true
end



return LWonderHud