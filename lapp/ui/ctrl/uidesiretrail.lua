---
--- Created by wzz.
--- DateTime: 2024/9/9 20:11:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDesireTrail:LWnd
local UIDesireTrail = LxWndClass("UIDesireTrail", LWnd)
------------------------------------------------------------------

local BottomBtnList = {
	[3] = { id = 1, name = ccClientText(45403), icon = "kf_ladder_btn_2" },
	[2] = { id = 2, name = ccClientText(45404), icon = "trial_btn_icon_2", redFunc = function() return gModelDesireTrail:HadTaskRed(nil) end },
	[1] = { id = 3, name = ccClientText(45405), icon = "public_btn_icon_18_3", redFunc = function() return gModelDesireTrail:HadActivityRed() end },
}

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDesireTrail:UIDesireTrail()
	self._gridMap = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDesireTrail:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDesireTrail:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDesireTrail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._themeRef = gModelDesireTrail:GetCurThemeRef()

	gModelDesireTrail:SaveChallengeRed()
	gModelDesireTrail:SaveTodyResetRed()
	

	self:InitTexts()
	self:InitEvents()
	self:InitLevList()
	self:InitBottomBtnList()
	self:Refresh()
end

-- 初始事件
function UIDesireTrail:InitEvents()
	self:SetWndClick(self.mReturnBtn, function() self:OnClickBtnReturn() end)
	self:SetWndClick(self.mBtnHelp, function() self:OnBtnHelp() end)
	self:SetWndClick(self.mBtnAdd, function() self:OnBtnAdd() end)
	self:SetWndClick(self.mBtnReset, function() self:OnBtnReset() end)
	self:SetWndClick(self.mBtnCrushing, function() self:OnBtnCrushing() end)

	self:WndEventRecv(EventNames.DESIRE_TRAIL_BUY_CHALLENGE, function(...) self:RefreshChallengeCount(...) end)
	self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...) self:InitBottomBtnList() end)
	self:WndEventRecv(EventNames.DESIRE_TRAIL_RESET, function(...)
		self._themeRef = gModelDesireTrail:GetCurThemeRef()
		self:InitLevList()
		self:Refresh()
	end)
	self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function(...)
		self:InitBottomBtnList()
	end)
end

-- 点击增加
function UIDesireTrail:OnBtnAdd()
	if gModelDesireTrail:IsSweeping(true) then
		return
	end

	GF.OpenWnd("UIDesireTrailBuyTimes")
end

-- 难度列表 item
function UIDesireTrail:OnDrawLevItem(uiList, item, data)
	if not uiList then
		uiList       = {}
		uiList.icon  = CS.FindTrans(item, "icon")
		uiList.title = CS.FindTrans(item, "title")
		uiList.eff   = CS.FindTrans(item, "eff")
	end

	local ref = data
	local pattern = ref.pattern
	local icon = "wonderland_btn_" .. pattern
	self:SetWndEasyImage(uiList.icon, icon)
	self:SetWndText(uiList.title, ccLngText(ref.patternName))
	self:SetWndClick(item, function()
		local curPattern = self._themeRef.pattern
		if pattern == curPattern then
		elseif curPattern > pattern then
			GF.ShowMessage(ccClientText(45401))
		else
			GF.ShowMessage(ccClientText(45402))
		end
	end)

	if ref.refId == self._themeRef.refId then
		self:CreateWndEffect(uiList.eff, "fx_ui_aiyu_yeqian", self._levEffKey, 100)
	end
	return uiList
end

-- 点击重置
function UIDesireTrail:OnBtnReset()
	if gModelDesireTrail:IsSweeping(true) then
		return
	end

	local can = gModelDesireTrail:CanReset(true)
	if not can then
		return
	end

	local itemRefId, cost = gModelDesireTrail:GetResetCost()
	local itemName = gModelItem:GetNameByRefId(itemRefId)
	local refId = 70001
	local para = {}
	if cost > 0 then
		para[1] = cost .. itemName
		refId = 70002
	end

	gModelGeneral:OpenUIOrdinTips({
		refId = refId,
		para = para,
		func = function()
			gModelDesireTrail:DesireTrailResetReq()
		end,
	})
end

-- 点击底部按钮
function UIDesireTrail:OnClickBottomBtn(id)
	if gModelDesireTrail:IsSweeping(true) then
		return
	end

	if id == 1 then
		gModelFunctionOpen:Jump(14600011)
		-- 商店
		--GF.OpenWnd("UIDian", { shopId = 2001 })
		--gLGameUI:SaveBackWnd("UIDian")
		self:WndClose()
	elseif id == 2 then
		-- 任务
		GF.OpenWnd("UIDesireTrailTask")
	elseif id == 3 then
		-- 活动战令

		GF.ChangeMap("LCityMap")
		FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.ACTIVITY })

		local dataList = gModelActivity:GetActivityDataByModelId(gModelActivity.MODEL_PASSC)
		local uniqueJump
		for _, v in ipairs(dataList) do
			uniqueJump = v.uniqueJump
			break
		end
		GF.OpenWndBottom("UIAct", { subPage = uniqueJump })
		self:WndClose()
	end
end

-- 刷新界面红点
function UIDesireTrail:RefreshRed()

end

-- 点击返回
function UIDesireTrail:OnClickBtnReturn()
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIOutts")
	if not self:WndCloseAndBack() then
		local ref = GameTable.DailyGamePlayRef[102]
		local group = ref and ref.group
		if group and group > 0 then
			GF.OpenWnd("UIOuttsList", { listRefId = group })
		end
	end
	self:WndClose()
end

-- 刷新界面
function UIDesireTrail:Refresh()
	local itemRefId, cost = gModelDesireTrail:GetResetCost()
	CS.ShowObject(self.mBtnResetTips, cost > -1)

	self:SetWndButtonGray(self.mBtnReset, cost == -1)
	self:SetWndButtonGray(self.mBtnCrushing, not gModelDesireTrail:IsCrushingOpen())
	CS.ShowObject(self.mBtnCrushing, gModelFunctionOpen:CheckIsOpened(16800070, false))

	if cost > -1 then
		local str
		if cost == 0 then
			str = ccClientText(45415)
		else
			local itemName = gModelItem:GetNameByRefId(itemRefId)
			str = ccClientText(45416, itemName, cost)
		end
		self:SetTextTile(self.mBtnResetTips, str)
	end

	local themeRef = gModelDesireTrail:GetCurThemeRef()
	self:SetWndText(self.mTitle, ccLngText(themeRef.name))

	self:RefreshChallengeCount()
	self:RefreshRed()
end

-- 初始化底部按钮
function UIDesireTrail:InitBottomBtnList()
	self:SetComList(self.mBottom, BottomBtnList, function(...) return self:OnDrawBottomBtnItem(...) end)
end

-- 初始化难度列表
function UIDesireTrail:InitLevList()
	local dataList = gModelDesireTrail:GetLevList()

	self._levEffKey = "lev_eff"
	self:DestroyWndEffectByKey(self._levEffKey)

	self:SetComList(self.mLevList, dataList, function(...) return self:OnDrawLevItem(...) end)
end

-- 刷新挑战次数
function UIDesireTrail:RefreshChallengeCount()
	local challengeCount = gModelDesireTrail:GetChallengeCount()
	self:SetWndText(self.mTxtReset, ccClientText(45412, challengeCount))
end

-- 底部按钮 item
function UIDesireTrail:OnDrawBottomBtnItem(uiList, item, data)
	if not uiList then
		uiList       = {}
		uiList.icon  = CS.FindTrans(item, "ImgIcon")
		uiList.title = CS.FindTrans(item, "UIText")
	end

	self:SetWndEasyImage(uiList.icon, data.icon)
	self:SetWndText(uiList.title, data.name)
	self:SetWndClick(item, function()
		self:OnClickBottomBtn(data.id)
	end)

	local showRed = false
	if data.redFunc then
		showRed = data.redFunc()
	end
	self:SetRed(item, showRed)

	return uiList
end

-- 初始界面化文本
function UIDesireTrail:InitTexts()
	self:SetWndText(self.mTxtReturn, ccClientText(20723))
	self:SetWndButtonText(self.mBtnReset, ccClientText(45406))
	self:SetWndButtonText(self.mBtnCrushing, ccClientText(45438))
end

-- 点击一键碾压
function UIDesireTrail:OnBtnCrushing()
	if gModelDesireTrail:IsSweeping(true) then
		return
	end

	if not gModelDesireTrail:IsCrushingOpen(true) then
		return
	end

	local x, y = gModelDesireTrail:GetRolePos()
	if gModelDesireTrail:IsLastGrid(y + 1) and gModelDesireTrail:IsMaxTheme() then
		GF.ShowMessage(ccClientText(45443))
		return
	end


	gModelDesireTrail:DesireTrailCrushingReq()
end

-- 点击帮助
function UIDesireTrail:OnBtnHelp()
	GF.OpenWnd("UIBzTips", { refId = 10 })
end

------------------------------------------------------------------
return UIDesireTrail