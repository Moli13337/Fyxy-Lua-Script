---
--- Created by BY.
--- DateTime: 2023/10/22 11:57:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveWin:LWnd
local UIGdBraveWin = LxWndClass("UIGdBraveWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveWin:UIGdBraveWin()
	self._bossTimeKey = "bossTimeKey"
	self._callCdTimeKey = "callCdTimeKey"
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveWin:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveWin:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	if self._isVie then
		self.mBossTimeBg.sizeDelta =Vector2.New(350,26)
		self:SetAnchorPos(self.mBossTimeText,Vector2.New(110,0))
	end
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIGdBraveWin:OnClickNotice()
	GF.OpenWnd("UIGdBraveBossNotice")
end
function UIGdBraveWin:SetTime()--设置时间
	local endTime = self._endTime
	local timespan = endTime/1000 - GetTimestamp()
	if(timespan <= 0)then
		self:TimerStop(self._bossTimeKey)
		self:SetWndText(self.mBossTimeText,ccClientText(32741))
		CS.ShowObject(self.mBossTimeBg,true)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(timespan)
	self:SetWndText(self.mBossTimeText,string.replace(ccClientText(14139),timeStr))
	--self:SetWndText(self.mInspireTime,string.replace(ccClientText(14106),timeStr))
	CS.ShowObject(self.mBossTimeBg,true)
end
function UIGdBraveWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildBraveResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildBraveBuffResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildCallMemberResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildBraveChangeResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildBraveChaseResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildBuyResp,function (pb)
		if(pb.buyType==2)then
			self:RefreshData()
		end
	end)
end
function UIGdBraveWin:OnClickRank()
	local braveInfo = self._braveInfo
	if not braveInfo then return end
	local levelRef = gModelGuildBoss:GetNewGuildDungeonLevelRefByRefId(braveInfo.level)
	local rewardList = gModelGuildBoss:GetNewGuildDungeonRankRef(levelRef.level)
	-- GF.OpenWnd("UIRkPop",{refId = ModelRank.RANK_GUILDBBRAVE ,rewardList = rewardList})
	GF.OpenWnd("UIGdRk",{refId = ModelRank.RANK_GUILDBBRAVE ,rewardList = rewardList})
end
function UIGdBraveWin:OnClickLog()
	GF.OpenWnd("UIGdBraveBossLog")
end
function UIGdBraveWin:OnClickInspire()
	local braveInfo = self._braveInfo
	local buffCount = braveInfo.buffCount
	local buffNum = braveInfo.buffNum
	if buffNum <= 0 then
		GF.ShowMessage(ccClientText(32742))
		return
	end
	local ref = gModelGuild:GetGuildDungeonEncourageRefByRefId(buffCount + 1)
	if not ref then
		ref = GameTable.ClanDungeonEncourageRef[#GameTable.ClanDungeonEncourageRef]
		-- GF.ShowMessage(ccClientText(14107))
		-- return
	end
	local attr = LUtil.GetRefAttr(ref.attr)
	local value = ""
	if attr.numType == 1 then
		value = attr.value
	else
		value = (attr.value * 100).."%"
	end
	local item = gModelGeneral:GetParseItem_3(ref.needItem)
	local itemId  = item.itemId
	local itemNum = item.itemNum
	local needStr = gModelItem:GetNameByRefId(itemId)..itemNum
	GF.OpenWnd("UIOrdinTip",{refId = 100013,para={needStr,value,ref.addTime/3600},func=function (...)
		local num = gModelItem:GetNumByRefId(item.itemId)
		if num < item.itemNum then
			local wndName = self:GetWndName()
			gModelGeneral:OpenGetWayWnd({itemId = item.itemId,srcWnd = wndName})
			return
		end
		gModelGuildBoss:OnGuildBraveBuffReq(buffCount)
	end , consume = {itemNum, itemId}} )
end
function UIGdBraveWin:OnClickAddNum()
	gModelGuildBoss:SetGuyNumPop(2)
end
function UIGdBraveWin:OnClickSweep()

	gModelGuildBoss:OnClickSweep()
end

function UIGdBraveWin:AwardListItem(list,item, itemdata, itempos)
	local root = CS.FindTrans(item,"CommonUI/Icon")
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
		self:SetIconClickScale(root, true)
	end
	itemdata.itemNum = -1
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	self:SetWndClick(root,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	baseClass:DoApply()
end
function UIGdBraveWin:OnClickCallMember()
	local braveInfo = self._braveInfo
	local lastCallTime = braveInfo.lastCallTime or 0
	local guildCallTime = GameTable.ClanDungeonConfigRef["GuildTime"]
	local timespan = tonumber(lastCallTime)/1000 + guildCallTime - GetTimestamp()
	if timespan >= 0 then
		local timeStr = LUtil.FormatTimespanCn(timespan)
		GF.ShowMessage(string.replace(ccClientText(32746),timeStr))
		return
	end


	GF.OpenWnd("UIOrdinTip",{refId = 100015,func=function (...)
		gModelGuildBoss:OnGuildCallMemberReq()
	end })
end

function UIGdBraveWin:RefreshData()
	local braveInfo = gModelGuildBoss:GetGuildBraveInfo()
	self._braveInfo = braveInfo
	local currentHp = braveInfo.currentHp
	local buffCount = braveInfo.buffCount
	local scoreLevel = braveInfo.scoreLevel
	local lastHurtCount = braveInfo.lastHurtCount or 0
	local buffNum = braveInfo.buffNum
	local doubleState = braveInfo.doubleState
	local lastCallTime = braveInfo.lastCallTime or 0

	local ref = ModelGuildBoss:GetNewGuildDungeonMonsterRefByRefId(braveInfo.braveId)
	local levelRef = gModelGuildBoss:GetNewGuildDungeonLevelRefByRefId(braveInfo.level)
	local buffRef = gModelGuild:GetGuildDungeonEncourageRefByRefId(buffCount)
	local scoreLevelRef = gModelGuildBoss:GetNewGuildDungeonRatingRefByRefId(scoreLevel)
	local guildCallTime = GameTable.ClanDungeonConfigRef["GuildTime"]
	local totalHp = levelRef.totalHp

	-- if not string.isempty(ref.bgImage)then
	-- 	CS.ShowObject(self.mBgImage,true)
	-- 	self:SetWndEasyImage(self.mBgImage,ref.bgImage)
	-- end
	if not string.isempty(ref.show)then
		local oldShow = self._oldShow
		if oldShow and oldShow ~= ref.show then
			self:DestroyWndSpineByKey("mBossSpine")
		end
		self:CreateWndSpine(self.mBossSpine,ref.show,"mBossSpine",false,function(dpSpine)
			dpSpine:SetScale(ref.scale)
			local pos = LxDataHelper.ParseVector2NotEmpty(ref.moveXY)
			self:SetAnchorPos(self.mBossSpine, pos)
		end)
		self._oldShow = ref.show
	end
	CS.ShowObject(self.mDefeatImg,currentHp <= 0)
	self:SetWndText(self.mBossNameText,ccLngText(ref.name))
	local inspireArrtStr,inspireTimeStr = ccClientText(14117), buffNum <= 0 and ccClientText(32738) or ccClientText(32739)
	if buffRef then
		local attr = LUtil.GetRefAttrData(buffRef.attr)[1] or {}
		local name = gModelHero:GetAttributeNameById(attr.refId)
		local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attr.refId,attr.numType,attr.value)
		inspireArrtStr = string.replace(ccClientText(12587),name,value)
		--inspireTimeStr = ccClientText(32738)
	end
	CS.ShowObject(self.mDoubleTips, doubleState == 1)
	self:SetWndText(self.mInspireArrt,inspireArrtStr)
	self:SetWndText(self.mInspireTime,inspireTimeStr)
	self.mBossHPBar.maxValue = totalHp
	self.mBossHPBar.value = currentHp
	self:SetWndText(self.mBossHPText,string.format("%s/%s",currentHp,totalHp))
	self:SetWndEasyImage(self.mBossLvIcon,scoreLevelRef.ratingIcon)
	self:SetWndText(self.mBossLvText,string.replace(ccClientText(32716),levelRef.level))
	local challengeNum = gModelGuild:GetVipBraveAddNum(1)--免费挑战次数
	local battleCount = challengeNum - braveInfo.battleCount + braveInfo.battleBuyCount + braveInfo.extraCount
	local numStr = string.replace(ccClientText(32734),battleCount)
	self:SetWndText(self.mNumText,numStr)
	self:InitTextLineWithLanguage(self.mNumText, -30)
	local buyNum = gModelGuild:GetVipBraveAddNum(2)--免费挑战次数
	local rBuyNum = buyNum - braveInfo.battleBuyCount
	local buyStr = string.replace(ccClientText(32736),rBuyNum)
	self:SetWndText(self.mBuyText,buyStr)
	self:InitTextLineWithLanguage(self.mBuyText, -30)
	self:SetWndButtonGray(self.mBtnSweep,lastHurtCount <= 0)
	local timespan = tonumber(lastCallTime)/1000 + guildCallTime - GetTimestamp()
	CS.ShowObject(self.mCallMemberTimeText,timespan >= 0)
	if timespan >= 0 then
		self:TimerStart(self._callCdTimeKey,timespan,false,1)
	end

	local _bossTimeKey = self._bossTimeKey
	if not string.isempty(braveInfo.endTime)then
		self._endTime = tonumber(braveInfo.endTime)
		self:TimerStop(_bossTimeKey)
		self:TimerStart(_bossTimeKey,1,false,-1)
		self:SetTime()
	end

	local list = LxDataHelper.ParseItem_3List(ref.showReward)
	local uiAwardList = self._uiAwardList
	if uiAwardList then
		uiAwardList:RefreshList(list)
	else
		uiAwardList = self:GetUIScroll("mAwardScroll")
		uiAwardList:Create(self.mAwardScroll,list,function (...) self:AwardListItem(...) end)
		self._uiAwardList = uiAwardList
	end
end

function UIGdBraveWin:OnTimer(key)
	if self._bossTimeKey == key then
		self:SetTime()
	elseif self._callCdTimeKey == key then
		self:RefreshData()
	end
end
function UIGdBraveWin:InitCommand()
	self:SetWndText(self.mInspireText,ccClientText(14135))
	self:SetWndButtonText(self.mChallengeBtn,ccClientText(14103))
	self:SetWndButtonText(self.mSweepBtn,ccClientText(14104))
	self:SetWndButtonText(self.mPursueBtn,ccClientText(14138))
	self:SetWndText(self.mCallMemberText,ccClientText(14137))
	self:SetWndText(self.mCallMemberTimeText,string.format("(%s)",ccClientText(32745)))
	self:SetWndText(self.mAwardTitleText,ccClientText(32731))
	self:SetWndText(self.mNoticeText,ccClientText(32720))
	self:SetWndText(self.mInformationText,ccClientText(32707))
	self:SetWndText(self.mRankText,ccClientText(32717))
	self:SetWndText(self.mAwardText,ccClientText(32718))
	self:SetWndText(self.mLogText,ccClientText(32719))
	self:SetWndText(self:FindWndTrans(self.mBtnClose, "Text"),ccClientText(41102))
	self:SetWndButtonText(self.mBtnChallenge,ccClientText(14103))
	self:SetWndButtonText(self.mBtnSweep,ccClientText(14104))
	self:SetWndButtonText(self.mBtnPursue,ccClientText(14138))
	self:SetWndText(self.mDoubleText,ccClientText(32743))
	self:InitTextLineWithLanguage(self.mDoubleText, -30)
	self:InitTextSizeWithLanguage(self.mDoubleText, -2)

	local guildInfo = gModelGuild:GetSelfGuildInfo()
	CS.ShowObject(self.mBtnCallMember,guildInfo.position <= 2)
	gModelGuildBoss:OnGuildBraveReq()

	-- local priviCom = self:GetPrivilegeCom()
	-- priviCom:Create(self.mBtnPrivile,8,self)
	CS.ShowObject(self.mBtnChallenge,true)
	CS.ShowObject(self.mBtnSweep,true)
	CS.ShowObject(self.mBtnInformation,true)
	if PRODUCT_G_VER == 0 then
		CS.ShowObject(self.mBtnRank,true)
		CS.ShowObject(self.mBtnAward,true)
	end
	CS.ShowObject(self.mBtnLog,true)
end
function UIGdBraveWin:OnClickPursue()

end
function UIGdBraveWin:OnClickChallenge()
	local braveInfo = self._braveInfo
	if not braveInfo then return end
	local battleCount = braveInfo.battleCount
	local battleBuyCount = braveInfo.battleBuyCount
	local challengeNum = gModelGuild:GetVipBraveAddNum(1)--免费挑战次数
	if battleCount - (challengeNum + battleBuyCount + braveInfo.extraCount) >= 0 then
		gModelGuildBoss:SetGuyNumPop(1)
		return
	end
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_BRAVE,{})
end
function UIGdBraveWin:OnClickAward()
	GF.OpenWnd("UIGdBraveAwardPoints")
end
function UIGdBraveWin:OnClickInformation()
	GF.OpenWnd("UIGdBraveBossInformation")
end
function UIGdBraveWin:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 38})
end

function UIGdBraveWin:OnClickCloseWnd()
	if not self:WndCloseAndBack() then
		GF.OpenWnd("UIGdWin")
	end
end

function UIGdBraveWin:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function (index)
		if index == 4 then self:OnClickCloseWnd() end
	end)
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickCloseWnd() end)
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBtnCallMember, function(...) self:OnClickCallMember() end)
	self:SetWndClick(self.mInspireMange, function(...) self:OnClickInspire() end)
	self:SetWndClick(self.mBtnChallenge, function(...) self:OnClickChallenge() end)
	self:SetWndClick(self.mBtnSweep, function(...) self:OnClickSweep() end)
	self:SetWndClick(self.mBtnPursue, function(...) self:OnClickPursue() end)
	self:SetWndClick(self.mBtnAddNum, function(...) self:OnClickAddNum() end)
	self:SetWndClick(self.mBtnNotice, function(...) self:OnClickNotice() end)
	self:SetWndClick(self.mBtnInformation, function(...) self:OnClickInformation() end)
	self:SetWndClick(self.mBtnRank, function(...) self:OnClickRank() end)
	self:SetWndClick(self.mBtnAward, function(...) self:OnClickAward() end)
	self:SetWndClick(self.mBtnLog, function(...) self:OnClickLog() end)
end
------------------------------------------------------------------
return UIGdBraveWin


