---
--- Created by BY.
--- DateTime: 2023/10/23 14:34:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdInfoPop:LWnd
local UIGdInfoPop = LxWndClass("UIGdInfoPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdInfoPop:UIGdInfoPop()
	self:SetHideHurdle()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdInfoPop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdInfoPop:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdInfoPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	
	self._isForeign =	gLGameLanguage:IsForeignVersion()
	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdInfoPop:InitCommand()
	local _guildInfo = self:GetWndArg("guildInfo")
	local _guildMemberList = self:GetWndArg("guildMemberList")
	self:SetWndText(self.mLblBiaoti,ccClientText(12471))
	self:SetWndText(self.mPassText,ccClientText(12473))
	self:SetWndText(self.mNameText,_guildInfo.guildName)
	if _guildInfo.chairman then
		self:SetWndText(self.mCdrText,ccClientText(12448).._guildInfo.chairman._name)
	end
	self:SetWndText(self.mLvText,string.replace(ccClientText(12449),_guildInfo.level))
	self:SetWndText(self.mNumText,string.replace(ccClientText(12401),_guildInfo.count,gModelGuild:GetGuildNumByLv(_guildInfo.level)))
	--self:SetWndText(self.mActiveText,_guildInfo.activityWeek)
	-- local powerStr = LUtil.FormatPowerShowStr(_guildInfo.power)
	self:SetWndText(self.mPowerName, ccClientText(12623))
	self:SetWndText(self.mPowerText, LUtil.NumberCoversion(_guildInfo.power))
	CS.ShowObject(self.mApplyForBtn,false)
	self:RefreshData(_guildMemberList,_guildInfo)
	local bgRef = gModelGuild:GetGuildFlagRefByRefId(_guildInfo.flagBgId)
	local iconRef = gModelGuild:GetGuildFlagRefByRefId(_guildInfo.flagId)
	if bgRef then
		self:SetWndEasyImage(self.mFlagBg,bgRef.res)
	end
	if iconRef then
		self:SetWndEasyImage(self.mFlagIcon,iconRef.res)
	end
	local _serverId = gModelPlayer:GetServerId()
	local _guildId = gModelPlayer:GetGuildId()
	if (_guildInfo.serverId == 0 or _guildInfo.serverId == _serverId) and _guildId == 0 then
		self:AddOnClickApplyForFun(self.mApplyForBtn,_guildInfo)
	end


	CS.ShowObject(self.mPowerName_enus,true)
	CS.ShowObject(self.mPowerName,false)

end

function UIGdInfoPop:RefreshData(_guildMemberList,_guildInfo)
	self:SetWndText(self.mSloganText,ccLngText(_guildInfo.guildNotice))
	local list = _guildMemberList
	if(self._uiList)then
		self._uiList:RefreshList(list)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
	end

end

function UIGdInfoPop:ListItem(list,item, itemdata, itempos)


	local AniRoot = self:FindWndTrans(item,"AniRoot")

	local nameText = self:FindWndTrans(AniRoot,"NameText")
	local serverText = self:FindWndTrans(AniRoot,"ServerText")
	local jobText = self:FindWndTrans(AniRoot,"JobText")
	local timeText = self:FindWndTrans(AniRoot,"TimeText")
	--local activeText = self:FindWndTrans(AniRoot,"ActiveText")
	--local activityWeekText = self:FindWndTrans(AniRoot,"ActivityWeekText")
	local AniRootPowerBg_1 = self:FindWndTrans(AniRoot,"PowerBg_1")
	local powerText = self:FindWndTrans(AniRootPowerBg_1,"PowerText")
	local powerName = self:FindWndTrans(AniRootPowerBg_1,"PowerName")
	local powerName_enus = self:FindWndTrans(AniRootPowerBg_1,"PowerName_enus")
	-- local dedicationBg = self:FindWndTrans(AniRoot,"DedicationBg_1")
	-- local dedicationText = self:FindWndTrans(AniRoot,"DedicationBg_1/DedicationText")
	local headIcon = CS.FindTrans(AniRoot,"HeadIcon")
	-- local jobImg = self:FindWndTrans(AniRoot,"NameText/JobImg")
	local AllContText = self:FindWndTrans(AniRoot,"AllContText")
	local WeekContText = self:FindWndTrans(AniRoot,"WeekContText")

	if self._isEnus then
		AllContText = self:FindWndTrans(AniRoot,"AllContText_Enus")
		WeekContText = self:FindWndTrans(AniRoot,"WeekContText_Enus")
	end

	local playerInfo = itemdata.info
	self:SetWndText(nameText,playerInfo._name)
	self:SetWndText(serverText,gModelFriend:GetSevenName(playerInfo._serverId))
	-- local otherJob = itemdata.position
	-- local jobStr = "guild_icon_17"
	-- if otherJob == 2 then
	-- 	jobStr = "guild_icon_18"
	-- end
	-- CS.ShowObject(jobImg,otherJob <= 2)
	-- self:SetWndEasyImage(jobImg,jobStr)
	local jobStr = ccClientText(12403)
	if(itemdata.position==1)then
		jobStr = string.replace(jobStr,ccClientText(12404))
	elseif(itemdata.position==2)then
		jobStr = string.replace(jobStr,ccClientText(12405))
	else
		jobStr = string.replace(jobStr,ccClientText(12406))
	end
	self:SetWndText(jobText,jobStr)

	local timeTextStr = gModelFriend:GetLastLogoutTime(playerInfo)
	self:SetWndText(timeText,timeTextStr)

	-- self:SetWndText(dedicationText,LUtil.NumberCoversion(itemdata.weekDonate))
	--self:SetWndText(activeText,string.replace(ccClientText(12571),LUtil.PowerNumberCoversion(itemdata.activityGuild)))
	--self:SetWndText(activityWeekText,string.replace(ccClientText(12572),LUtil.PowerNumberCoversion(itemdata.activityWeek)))
	self:SetWndText(powerText,LUtil.PowerNumberCoversion(playerInfo._power))
	self:SetWndText(powerName, ccClientText(12623))
	self:SetWndText(AllContText, string.replace(ccClientText(12625), itemdata.guildDonate))
	self:SetWndText(WeekContText, string.replace(ccClientText(12626), itemdata.weekDonate))
	--self:SetWndText(powerText,LUtil.FormatHurtNumSpriteText(playerInfo._power))
	local playerData = {
		trans = headIcon,
		icon = playerInfo._head,
		headFrame = playerInfo._headFrame,
		level = playerInfo._grade,
	}

	local uiheadlist = self._uiheadList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()

	self:SetWndClick(headIcon, function(...)
		self:OnClickHeadIcon(playerInfo)
	end)
	self:SetWndClick(AniRoot, function(...)
		self:OnClickHeadIcon(playerInfo)
	end)
	self:SetWndClick(dedicationBg,function ()
		local title,desc,other
		title = ccClientText(12598)
		desc = ccClientText(12599)
		other = {itemdata.weekDonate,itemdata.guildDonate}
		GF.OpenWnd("UIExTips",{root = jobImg,title = title,desc = desc,other = other})
	end)
	self:SetWndClick(jobImg,function ()
		local title,desc
		if otherJob == 1 then
			title = ccClientText(12594)
			desc = ccClientText(12595)
		elseif otherJob == 2 then
			title = ccClientText(12596)
			desc = ccClientText(12597)
		end
		GF.OpenWnd("UIExTips",{root = jobImg,title = title,desc = desc})
	end)


	CS.ShowObject(powerName_enus,true)
	CS.ShowObject(powerName,false)

end

function UIGdInfoPop:AddOnClickApplyForFun(applyForBtn,itemdata)
	CS.ShowObject(applyForBtn,true)
	local btnText = ""
	local btnFunc = nil
	local applyByBool,limitBool,lvBool
	lvBool=gModelPlayer:GetPlayerLv() >= itemdata.levelLimit
	limitBool = gModelGuild:GetGuildNumByLv(itemdata.level) >= itemdata.count
	applyByBool = gModelGuild:GetBApplyByGuildId(itemdata.guildId)
	local isGray = not applyByBool or not limitBool or  not lvBool
	if(not applyByBool)then
		btnText = ccClientText(12465)
		btnFunc = function(...)
			GF.ShowMessage(ccClientText(12504))
		end
	else
		btnText = ccClientText(12466)
		if(not limitBool)then
			btnFunc = function(...) GF.ShowMessage(ccClientText(12505)) end
		elseif(not lvBool)then
			btnFunc = function(...) GF.ShowMessage(ccClientText(12503)) end
		else
			btnFunc = function(...) self:OnClickApplyFor(itemdata.guildId) end
		end
	end
	self:SetWndButtonText(applyForBtn,btnText)
	self:SetWndButtonGray(applyForBtn,isGray)
	self:SetWndClick(applyForBtn,function ()
		if btnFunc then
			btnFunc()
		end
	end)
end

function UIGdInfoPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.JoinGuildResp,function (...)
		self:WndClose()
	end)
end

function UIGdInfoPop:OnClickApplyFor(guildId)
	gModelGuild:OnJoinGuildReq(1,guildId)
end

function UIGdInfoPop:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end)
end

function UIGdInfoPop:OnClickHeadIcon(playerInfo)
	gModelGeneral:PlayerShowReq(playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIGdInfoPop:OnClickClose()
	FireEvent(EventNames.ON_GUILD_MELEE_RESULT,true)
	self:WndClose()
end
------------------------------------------------------------------
return UIGdInfoPop


