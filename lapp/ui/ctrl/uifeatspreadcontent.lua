---
--- Created by Administrator.
--- DateTime: 2023/10/23 19:58:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFeatSpreadContent:LWnd
local UIFeatSpreadContent = LxWndClass("UIFeatSpreadContent", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFeatSpreadContent:UIFeatSpreadContent()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFeatSpreadContent:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFeatSpreadContent:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFeatSpreadContent:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	CS.ShowObject(self.mRateBg,not self._isEnus)
	CS.ShowObject(self.mRateBg_enus,self._isEnus)
	self:InitData()
	self:InitEvent()
	self:InitContent()

	self:SetWndText(self.mButtomDesc, ccClientText(19532))
end

function UIFeatSpreadContent:OnClickShowAchievement()
	local isOpen = gModelAchievement:GetAchievementOpen(true)
	if not isOpen then
		return
	end

	self:WndClose()
	GF.CloseWndByName("UISayPop")
	local refId = self._refId
	GF.OpenWndBottom("UIFeat", {refId = refId})
end

function UIFeatSpreadContent:InitEvent()
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)
	self:SetWndClick(self.mClickBg, function(...) self:OnClickShowAchievement() end)
end

function UIFeatSpreadContent:InitHead()
	local playerData = self._playerInfo
	local roleName	 = playerData.name
	local playerInfo={
		trans	= self.mHeadIcon,
		icon	= playerData.icon,
		headFrame=playerData.headFrame,
		name	= roleName,
		level	= playerData.level,
	}

	local baseClass = self._uihead
	if not baseClass then
		baseClass = HeadIcon:New(self)
		self._uihead = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	baseClass:RefreshUI()

	self:SetWndText(self.mNameText, roleName)
	self:SetWndText(self.mDesText, LUtil.PowerNumberCoversion(self._fightPower))
end

function UIFeatSpreadContent:InitContent()
	self:InitHead()
	self:InitDesc()
end

function UIFeatSpreadContent:InitDesc()
	local isComplete = self._state ~= ModelAchievement.ACHIEVEMENT_UNFINISH
	local completeStr
	local refId = self._refId
	local activeName = gModelAchievement:GetAchievementName(refId)
	local contentStr = gModelAchievement:GetAchievementDescription(refId)
	local dataStr   = ""

	if isComplete then
		completeStr = string.replace(ccClientText(19523), activeName)

		local year,month,day  = LUtil.GetYmdByTimestamp(tonumber(self._date))
		dataStr		= string.replace(ccClientText(19535), year, month, day)
		dataStr		= string.replace(ccClientText(19524), dataStr)
	else
		completeStr = string.replace(ccClientText(19522), activeName)
	end

	self:SetWndText(self.mDesc, completeStr)
	self:SetWndText(self.mData, dataStr)
	self:SetWndText(self.mTitle, activeName)
	self:SetWndText(self.mText, contentStr)


	local achievementData = gModelAchievement:GetAchievementDataByRefId(refId)
	local rate
	if not achievementData then
		rate 		= self._rate
	else
		rate		= achievementData:GetServerVal()
	end

	local rateStr
	if rate == 100 or rate == 0 then
		rateStr = rate
	elseif rate < 0.1 then
		rateStr = ccClientText(19517)..0.1
	elseif rate > 99.9 then
		rateStr = ccClientText(19516)..99.9
	else
		rateStr = math.floor(rate * 10) / 10
	end

	rateStr  	= string.replace(ccClientText(19525), rateStr)
	self:SetWndText(self.mRate, rateStr)
	self:SetWndText(self.mRate_Enus, rateStr)
end

function UIFeatSpreadContent:InitData()
	self._refId		= self:GetWndArg("refId")
	self._state		= self:GetWndArg("state")
	self._date		= self:GetWndArg("date")
	self._rate		= self:GetWndArg("rate")
	self._playerInfo = self:GetWndArg("playerInfo")
	self._fightPower = self:GetWndArg("fightPower")
end



------------------------------------------------------------------
return UIFeatSpreadContent



