---
--- Created by Administrator.
--- DateTime: 2023/10/27 10:34:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReeResult:LWnd
local UIReeResult = LxWndClass("UIReeResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReeResult:UIReeResult()
    ---@type CommonIcon
    self._heroIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReeResult:OnWndClose()
    self:TweenSeqKill(self._effectKey)
    if self._heroIconCls then
        self._heroIconCls:Destroy()
        self._heroIconCls = nil
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReeResult:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReeResult:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:InitData()
    self:InitEvent()
    self:RefreshView()
end

function UIReeResult:CreateEffect(trans, effectName, effectKey)
    effectKey = effectKey or effectName
    self:CreateWndEffect(trans, effectName, effectKey, 100, false, false)
end

function UIReeResult:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end

function UIReeResult:InitData()
    self._heroId = self:GetWndArg("heroId")
    local oldHero = self:GetWndArg("oldHero")
    local newHero = self:GetWndArg("newHero")

    self._baseAttrList = { LAttrConst.Atk, LAttrConst.MaxHP, LAttrConst.Def, LAttrConst.Speed }
    self._oldData = { oldHero.atk, oldHero.maxHp, oldHero.def, oldHero.speed }
    self._newData = { newHero.atk, newHero.maxHp, newHero.def, newHero.speed }
    self._oldLv = oldHero.level
    self._newLv = newHero.level

    self._baseIconList = { self.mIcon2, self.mIcon3, self.mIcon4, self.mIcon5 }
    self._attrNameList = { self.mAttrName2, self.mAttrName3, self.mAttrName4, self.mAttrName5 }
    self._oldValueList = { self.mAttrOldValue2, self.mAttrOldValue3, self.mAttrOldValue4, self.mAttrOldValue5 }
    self._newValueList = { self.mAttrNewValue2, self.mAttrNewValue3, self.mAttrNewValue4, self.mAttrNewValue5 }

    self._attrDivList = {
        self.mAttrDiv1,
        self.mAttrDiv2,
        self.mAttrDiv3,
        self.mAttrDiv4,
        self.mAttrDiv5
    }
    self._attrEffList = {
        self.mAttrEff1,
        self.mAttrEff2,
        self.mAttrEff3,
        self.mAttrEff4,
        self.mAttrEff5,
    }

    self._effectKey = "resonance"
end

function UIReeResult:CreateTitleEffect()

    if self._isEnus then
        self:SetWndEasyImage(self.mTitle, "resonance_txt_1", function()
            CS.ShowObject(self.mTitle, true)
        end)
    else
        CS.ShowObject(self.mTitle, true)
    end

    self:CreateEffect(self.mShengxingTitle, "fx_ui_shengxing_1")
end

function UIReeResult:PlayEffect()
    local seqTween
    self:TweenSeqKill(self._effectKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._effectKey, function(seq)
            local showTopTime = 0.2
            local showAttrTime = 0.1
            seq:AppendCallback(function()
                self:CreateTitleEffect()
            end)
            seq:AppendInterval(showTopTime)
            seq:AppendCallback(function()
                self:InitHero()
            end)
            seq:AppendInterval(showTopTime)
            for i, v in ipairs(self._attrEffList) do
                seq:AppendCallback(function()
                    local parentTrans = self._attrDivList[i]
                    CS.ShowObject(parentTrans, true)
                    self:CreateEffect(v, "fx_ui_shengxing_3", "eff" .. i)
                end)
                seq:AppendInterval(showAttrTime)
            end
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._effectKey)
    end)
end

function UIReeResult:InitHero()
    local id = self._heroId

    local baseClass = self._heroIconCls
    if not baseClass then
        baseClass = CommonIcon:New()
        self._heroIconCls = baseClass
        baseClass:Create(self.mHeroIcon)
    end
    baseClass:SetHeroPlayer(id)
    baseClass:DoApply()

    CS.ShowObject(self.mHeroIcon, true)

    self:CreateEffect(self.mHeroIcon, "fx_ui_shengxing_2")
end

function UIReeResult:RefreshView()

    self:SetWndText(self.mAttrOldValue1, self._oldLv)
    self:SetWndText(self.mAttrNewValue1, self._newLv)
    self:SetWndText(self.mAttrName1, ccClientText(10057))

    local oldData = self._oldData
    local newData = self._newData
    local iconTransList = self._baseIconList
    local attrNameTransList = self._attrNameList
    local attrOldTransList = self._oldValueList
    local attrNewTransList = self._newValueList
    for i, v in ipairs(self._baseAttrList) do
        local iconImg = gModelHero:GetAttributeIconById(v)
        local iconTrans, nameTrans, oldTrans, newTrans = iconTransList[i], attrNameTransList[i], attrOldTransList[i], attrNewTransList[i]
        self:SetWndEasyImage(iconTrans, iconImg)
        local attrName = gModelHero:GetAttributeNameById(v)
        self:SetWndText(nameTrans, attrName)
        self:SetWndText(oldTrans, math.floor(oldData[i] + 0.5))
        self:SetWndText(newTrans, math.floor(newData[i] + 0.5))
    end
    self:PlayEffect()
end
------------------------------------------------------------------
return UIReeResult


