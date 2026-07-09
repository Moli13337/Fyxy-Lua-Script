---
--- Created by wzz.
--- DateTime: 2025/3/12 21:24:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarResult:LWnd
local UIDefenceWarResult = LxWndClass("UIDefenceWarResult", LWnd)
------------------------------------------------------------------

local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarResult:UIDefenceWarResult()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarResult:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._stageId    = self:GetWndArg("stageId")
	self._isWin      = self:GetWndArg("isWin")
	self._itemList    = self:GetWndArg("itemList") or {}
	self._hasAward   = #self._itemList > 0
	self._stageMaxId = gModelDefenceWar:GetMaxStageId()

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 点击报告
function UIDefenceWarResult:OnClickBtnReport()
	GF.OpenWnd("UIDefenceWarBattleDetail", {isWin = self._isWin})
end

-- 刷新界面
function UIDefenceWarResult:Refresh()
	local stageRef = gModelDefenceWar:GetStageRef(self._stageId)

	self:SetWndText(self.mTxtTime, ccLngText(stageRef.name))
	-- CS.ShowObject(self.mBtnBack, self._stageId < self._stageMaxId)
	CS.ShowObject(self.mBtnBack, true)

	self:CreateWndSpine(self.mHeroSpine1, stageRef.paint, stageRef.paint, false, function(dpSpine)
		dpSpine:SetScale(1)
		self:StartHeroTween()
	end)

	self:ShowTitleEff(self._isWin)

	local resultTips = ""
	if self._isWin then
		if not self._hasAward then
			resultTips = ccLngText(stageRef.winText)
		end
	else
		resultTips = ccLngText(stageRef.loseText)
	end

	self:SetWndText(self.mTxtResultTips, resultTips)

	self:RefreshReward()
end

-- 初始事件
function UIDefenceWarResult:InitEvents()
	-- self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnBack, function() self:OnClickBtnBack() end)
	self:SetWndClick(self.mBtnNext, function() self:OnClickBtnNext() end)
	self:SetWndClick(self.mBtnReport, function() self:OnClickBtnReport() end)
end

-- 点击击返回
function UIDefenceWarResult:OnClickBtnBack()
	self:WndClose()

	GF.ChangeMap("LCityMap")
	GF.OpenWnd("UIDefenceWarMain")
end

-- 显示标题特效
function UIDefenceWarResult:ShowTitleEff(isSuc)
	CS.ShowObject(self.mTitleEff, true)
	CS.ShowObject(self.mWinBg, true)

	local effName = "fx_ui_shibai"
	local imgName = "settlement_bg_title_4"
	--local pos= Vector3.New(0,31,0)
	if isSuc then
		effName = "fx_ui_shengli"
		imgName = "settlement_bg_title_3"
		--pos = Vector3.New(0,-135,0)
	end
	self:CreateWndEffect(self.mTitleEff, effName, effName, 100)
	--self.mTitleEff.localPosition = pos
	local pos = Vector2.New(-13.85, 10)
	if gLGameLanguage:IsForeignVersion() then
		pos = Vector2.New(-13.85, 10)
	end
	self:SetAnchorPos(self.mTitleEff, pos)
	self:SetWndEasyImage(self.mWinBg, imgName)
end

-- 初始界面化文本
function UIDefenceWarResult:InitTexts()
	-- self:SetWndText(self.mCloseTip, ccClientText(10103))

	self:SetTextTile(self.mBtnReport, ccClientText(46845))
	self:SetWndButtonText(self.mBtnBack, ccClientText(30205))
	self:SetWndButtonText(self.mBtnNext, ccClientText(43520))
end

-- 停止立绘缩放动画
function UIDefenceWarResult:StopHeroTween()
	local seq = self._heroTweem
	if seq then
		seq:Kill(false)
		self._heroTweem = nil
	end
end

-- 显示奖励
function UIDefenceWarResult:RefreshReward()
	if not self._hasAward then
		return
	end

	-- local stageRef = gModelDefenceWar:GetStageRef(self._stageId)
	local itemList = self._itemList  --LUtil.GetRefItemDataList(stageRef.reward1)
	local uiList = UIIconEasyList:New()
	uiList:Create(self, self.mItemList)
	uiList:SetShowNum(true)
	uiList:SetIconParentPath("itemRoot")
	uiList:RefreshList(itemList)
end

-- 点击下一步
function UIDefenceWarResult:OnClickBtnNext()
	local stageId = self._stageId + 1
	FireEvent(EventNames.DEFENCEWAR_RESTART, { stageId = stageId })
	self:WndClose()
end

-- 开始立绘缩放动画
function UIDefenceWarResult:StartHeroTween()
	self:StopHeroTween()
	local tween = Tweening.DOTween.Sequence()
	self._heroTweem = tween

	local Tween1 = self.mHeroDrawing:DOScale(Vector3(1.1, 1.1, 1.1), 0.4):SetEase(EaseOutCubic)
	tween:Append(Tween1)
	local Tween2 = self.mHeroDrawing:DOScale(Vector3(1, 1, 1), 0.001):SetEase(EaseOutCubic)
	tween:Append(Tween2)

	tween:Play()
end

------------------------------------------------------------------
return UIDefenceWarResult