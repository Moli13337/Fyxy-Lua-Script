---
--- Created by wzz.
--- DateTime: 2025/3/7 10:46:04
--- 保卫战技能选择
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarSkillSelect:LWnd
local UIDefenceWarSkillSelect = LxWndClass("UIDefenceWarSkillSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarSkillSelect:UIDefenceWarSkillSelect()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarSkillSelect:OnWndClose()
	gLGpManager:FindDefenceWarGp():ResumeByTimeScale()
	
	local data = self._dataList[self._curSelectIndex]
	FireEvent(EventNames.DEFENCEWAR_SKILL_SELECT, data)

	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarSkillSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarSkillSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	GF.CloseWndByName("UIDefenceWarBattleDetail")

	self._dataList = self:GetWndArg("dataList") or {}

	gLGpManager:FindDefenceWarGp():PauseByTimeScale()
	self:InitSelect()
	self:InitTexts()
	self:InitEvents()
	self:InitList()
	self:Refresh()

	-- self:StartAutoSelect()
end

-- 初始化选择
function UIDefenceWarSkillSelect:InitSelect()
	local list = {}
	for k, v in ipairs(self._dataList) do
		local skillRef = gModelDefenceWar:GetSkillRef(v.skillId, v.skillLev)
		list[k] = { index = k, data = v, skillRef = skillRef }
	end

	table.sort(list, function(a, b)
		if a.data.skillLev ~= b.data.skillLev then
			return a.data.skillLev > b.data.skillLev
		end
		if a.skillRef.quality ~= b.skillRef.quality then
			return a.skillRef.quality > b.skillRef.quality
		end
		return a.data.skillId > b.data.skillId
	end)

	self._curSelectIndex = list[1].index
end

-- 开始自动选择
function UIDefenceWarSkillSelect:StartAutoSelect()
	self:TimerStop(1)
	self._times = 3
	local timePara = {
		key       = 1,
		loopcnt   = self._times,
		interval  = 1,
		timescale = false,
		callOnStart = true,
		func = function()
			self:AutoSelect()
		end
	}
	self:TimerStartImpl(timePara)
end

-- 自动选择
function UIDefenceWarSkillSelect:AutoSelect()
	if self._times <= 0 then
		self:WndClose()
		return
	end

	-- self:SetWndText(self.mTxtTime, ccClientText(self._times))
	self:SetWndText(self.mTxtTime, self._times)
	self._times = self._times - 1
end

-- 初初化列表
function UIDefenceWarSkillSelect:InitList()
	self._uiList = {}
	for i = 1, 3 do
		local trans     = self["mCard" .. i]
		local bg        = CS.FindTrans(trans, "Bg")
		local txtLev    = CS.FindTrans(trans, "TxtLev")
		local txtDesc   = CS.FindTrans(trans, "1/TxtDesc")
		local iconBg    = CS.FindTrans(trans, "IconBg")
		local icon      = CS.FindTrans(trans, "IconBg/Icon")
		local txtName   = CS.FindTrans(trans, "TxtName")
		local select    = CS.FindTrans(trans, "Select")

		local tab       = {
			trans   = trans,
			bg      = bg,
			txtLev  = txtLev,
			txtDesc = txtDesc,
			iconBg  = iconBg,
			icon    = icon,
			txtName = txtName,
			select  = select
		}
		self._uiList[i] = tab

		self:SetWndClick(trans, function() self:OnCardClick(i) end)
	end
end

-- 刷新界面
function UIDefenceWarSkillSelect:Refresh()
	for i, ui in ipairs(self._uiList) do
		local data = self._dataList[i]
		if data then
			local heroId = data.heroId
			local heroRef = gModelDefenceWar:GetHeroRef(heroId)

			self:SetWndEasyImage(ui.iconBg, "public_item_bg_" .. heroRef.quality)
			self:SetWndEasyImage(ui.icon, heroRef.headIcon)

			local skillRef = gModelDefenceWar:GetSkillRef(data.skillId, data.skillLev)
			local strName
			if data.isNewHero then
				strName = ccLngText(heroRef.name)
			else
				strName = ccLngText(skillRef.name)
			end

			self:SetWndText(ui.txtName, strName)
			self:SetWndText(ui.txtDesc, ccLngText(skillRef.desc))
			self:SetWndText(ui.txtLev, data.skillLev)
		end
		CS.ShowObject(ui.trans, data ~= nil)
	end

	self:RefreshSelect()
end

-- 确认按钮点击
function UIDefenceWarSkillSelect:OnBtnConfirm()
	if self._curSelectIndex == nil then
		GF.ShowMessage(ccClientText(46824))
		return
	end

	self:WndClose()
end

-- 停止自动选择
function UIDefenceWarSkillSelect:StopAutoSelect()
	self:TimerStop(1)
end

-- 刷新卡片选中
function UIDefenceWarSkillSelect:RefreshSelect()
	for i, ui in ipairs(self._uiList) do
		CS.ShowObject(ui.select, i == self._curSelectIndex)
	end
end

-- 初始界面化文本
function UIDefenceWarSkillSelect:InitTexts()
	-- self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTxtTitle, ccClientText(46823))
	self:SetWndButtonText(self.mBtnConfirm, ccClientText(46825))
end

-- 卡片点击
function UIDefenceWarSkillSelect:OnCardClick(index)
	if self._curSelectIndex == index then
		return
	end

	self._curSelectIndex = index
	self:RefreshSelect()
end

-- 初始事件
function UIDefenceWarSkillSelect:InitEvents()
	-- self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnBtnConfirm() end)
end

------------------------------------------------------------------
return UIDefenceWarSkillSelect