---
--- Created by wzz.
--- DateTime: 2025/3/21 15:05:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarHeroActive:LWnd
local UIDefenceWarHeroActive = LxWndClass("UIDefenceWarHeroActive", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarHeroActive:UIDefenceWarHeroActive()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarHeroActive:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarHeroActive:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarHeroActive:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._heroId = self:GetWndArg("heroId")

	self:InitTexts()
	self:InitEvents()
	self:InitEff()
	self:Refresh()
end

-- 初始事件
function UIDefenceWarHeroActive:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 初始特效
function UIDefenceWarHeroActive:InitEff()
	local effName = "fx_ui_bwmnc_jihuomengniang"

	self:CreateWndEffect(self.mEff, effName, effName, 100, nil, nil, 100)
end

-- 刷新界面
function UIDefenceWarHeroActive:Refresh()
	local heroId     = self._heroId
	local heroLev    = 1
	local heroRef    = gModelDefenceWar:GetHeroRef(heroId, heroLev)
	local heroLevRef = gModelDefenceWar:GetHeroLevRef(heroId, heroLev)

	local color      = gModelItem:GetColorStringByQualityId(heroRef.quality)
	local strName    = ccClientText(46842, color, ccLngText(heroRef.name))
	self:SetWndText(self.mTxtName, strName)
	self:SetWndText(self.mTxtDesc, ccLngText(heroRef.desc))
	self:SetWndEasyImage(self.mHeadIcon, heroRef.headIcon)
	self:SetWndEasyImage(self.mHeadBg, "public_item_bg_" .. heroRef.quality)

	-- 属性
	self:SetWndText(self.mTxtAttr1, ccClientText(46843))
	self:SetWndText(self.mTxtAttr2, heroLevRef.atk)
	self:SetWndText(self.mTxtAttr3, ccClientText(46844))
	self:SetWndText(self.mTxtAttr4, heroLevRef.addattr)
end

-- 播放动画
function UIDefenceWarHeroActive:PlayEffect()
	-- local seqTween
	-- local effectKey = "UIDefenceWarHeroActive"
	-- self:TweenSeqKill(effectKey)
	-- seqTween = self:TweenSeqCreate(effectKey, function(seq)
	-- 	local tw1 = self.mImgTitle:DOScale(Vector3.New(1, 1, 1), 0.15)
	-- 	local tw5 = self.mTxtDesc:DOScale(Vector3.New(1, 1, 1), 0.1)
	-- 	seq:Insert(0, tw1)
	-- 	seq:Insert(0.2, tw5)

	-- 	return seq
	-- end)
	-- seqTween:PlayForward()
	-- seqTween:OnComplete(function()
	-- 	self:TweenSeqKill(effectKey)
	-- 	self._playEndEffect = true
	-- end)

	self:CreateWndEffect(self.mEff, "fx_ui_shengxing_1", 1, 100)
end

-- 初始界面化文本
function UIDefenceWarHeroActive:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

------------------------------------------------------------------
return UIDefenceWarHeroActive