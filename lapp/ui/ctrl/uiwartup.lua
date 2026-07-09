---
--- Created by wzz.
--- DateTime: 2024/9/23 20:39:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTUp:LWnd
local UIWarTUp = LxWndClass("UIWarTUp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTUp:UIWarTUp()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTUp:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTUp:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTUp:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitTexts()
    self:InitEvents()
    self:PlayEffect()
    self:Refresh()
    self:RefreshForeign()
end
-- 初始界面化文本
function UIWarTUp:InitTexts()
    self:SetWndText(self.mTxtDesc, ccClientText(42080))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
end

-- 播放动画
function UIWarTUp:PlayEffect()
    local seqTween
    local effectKey = "UIWarTUp"
    self:TweenSeqKill(effectKey)
    seqTween = self:TweenSeqCreate(effectKey, function(seq)

        local tw1 = self.mImgTitle:DOScale(Vector3.New(1, 1, 1), 0.15)
        local tw2 = self.mBg1.parent:DOLocalRotate(Vector3.New(0, 0, 360), 0.15)
        local tw3 = self.mBg2.parent:DOLocalRotate(Vector3.New(0, 0, 0), 0.15)
        local tw4 = self.mImgTag:DOScale(Vector3.New(1, 1, 1), 0.1)
        local tw5 = self.mTxtDesc:DOScale(Vector3.New(1, 1, 1), 0.1)
        seq:Insert(0, tw1)
        seq:Insert(0.1, tw4)
        seq:Insert(0, tw2)
        seq:Insert(0.2, tw3)
        seq:Insert(0.2, tw5)

        return seq
    end)
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(effectKey)
        self._playEndEffect = true
    end)

    self:CreateWndEffect(self.mEff, "fx_ui_shengxing_1", 1, 100)
end

function UIWarTUp:RefreshForeign()
    if self._isVie then
        LxUiHelper.SetSizeWithCurAnchor(self.mImg1_Txt,0,250)
        LxUiHelper.SetSizeWithCurAnchor(self.mImg2_Txt,0,250)
    end
end

-- 刷新界面
function UIWarTUp:Refresh()
    local placeRefId1 = self:GetWndArg("placeRefId1")
    local placeRefId2 = self:GetWndArg("placeRefId2")

    local ref1 = gModelWarTemple:GetWarTempleRef(placeRefId1)
    local ref2 = gModelWarTemple:GetWarTempleRef(placeRefId2)

    self:SetWndText(self.mTxtName1, ccLngText(ref1.name))
    self:SetWndText(self.mTxtName2, ccLngText(ref2.name))

    self:SetWndEasyImage(self.mBg1, ref1.icon, nil, true)
    self:SetWndEasyImage(self.mBg2, ref2.icon, nil, true)
end

-- 初始事件
function UIWarTUp:InitEvents()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end

------------------------------------------------------------------
return UIWarTUp