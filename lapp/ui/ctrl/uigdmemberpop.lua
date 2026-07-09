---
--- Created by BY.
--- DateTime: 2023/10/21 22:00:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdMemberPop:LWnd
local UIGdMemberPop = LxWndClass("UIGdMemberPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdMemberPop:UIGdMemberPop()
	self:SetHideHurdle()
	self._uiheadList = {}
	self._playerOnlineIds = {}
	self._playerOnlineKey = "_playerOnlineKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdMemberPop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdMemberPop:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdMemberPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignRegion()
	
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdMemberPop:OnClickOver(_guildMemberInfo)--转让
	if( not gModelGuild:GetAssignCDRByTime())then
		return
	end
	local playerId = _guildMemberInfo.info._playerId
	local position=1
	local taposition = _guildMemberInfo.position
	local positionStr
	if(taposition==2)then
		positionStr=ccClientText(12513)
	else
		positionStr=ccClientText(12406)
	end
	GF.OpenWnd("UIOrdinTip",{refId = 100004,para = {_guildMemberInfo.info._name,positionStr},func=function ()
		gModelGuild:OnGuildPositionChangeReq(playerId , position)
	end})
end

function UIGdMemberPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildPositionChangeResp,function (pb)
		GF.CloseWndByName("UIBtnLPop")
	end)
	self:WndNetMsgRecv(LProtoIds.DeletGuildMemberResp,function (pb)
		GF.CloseWndByName("UIBtnLPop")
	end)
	self:WndNetMsgRecv(LProtoIds.GuildChangeResp,function (pb)
		GF.CloseWndByName("UIBtnLPop")
	end)
	self:WndNetMsgRecv(LProtoIds.PlayerOnlineResp,function (pb)
		local playerIdList = pb.playerIdList
		local moreInfo = pb.moreInfo
		if moreInfo ~= "3" then return end
		local _playerOnlineIds = {}
		for i, v in ipairs(playerIdList) do
			_playerOnlineIds[v] = true
		end
		self._playerOnlineIds = _playerOnlineIds
		self:RefreshData()
	end)

	self:WndEventRecv("OnGuildMemberListResp",function (...)
		self:RefreshData()
		self:OnReqPlayerOnline()
	end)
	self:WndEventRecv("OnGuildInfoResp",function (...)
		local guildInfo = gModelGuild:GetGuildInfo()
		gModelGuild:OnGuildMemberListReq(guildInfo.guildId)
	end)
end

function UIGdMemberPop:OnClickSetFree(_guildMemberInfo)--罢免
	local playerId = _guildMemberInfo.info._playerId
	gModelGuild:OnGuildPositionChangeReq(playerId , ModelGuild.GUILD_MEMBER)
end

function UIGdMemberPop:RefreshData()
	self:RefreshSelfInfo()
	local guildInfo = gModelGuild:GetGuildInfo()
	local list = gModelGuild:GetGuildMemberList()

	if(self._uiList)then
		self._uiList:RefreshList(list)
		self._uiList:DrawAllItems()
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
	end
	local isOwnFriend = false
	local playerIdList = {}
	for i, v in ipairs(list) do
		table.insert(playerIdList,v.info._playerId)
		isOwnFriend = true
	end
	self._playerIdList = playerIdList
	local _playerOnlineKey = self._playerOnlineKey
	if not isOwnFriend then
		self:TimerStop(_playerOnlineKey)
	elseif not self:IsTimerExist(_playerOnlineKey) then
		self:TimerStart(_playerOnlineKey,60,false,-1)
	end

	local secondaryNum = 0
	local len = #list
	for i, v in ipairs(list) do
		if(v.position == 2)then
			secondaryNum = secondaryNum + 1
		end
	end
	local numLimit = gModelGuild:GetGuildNumByLv(guildInfo.level)
	local viceLimit = gModelGuild:GetSecondaryNumberByLv(guildInfo.level)
	local color1,color2 = len >= numLimit and "red" or "lightGreen",secondaryNum >= viceLimit and "red" or "lightGreen"
	self:SetWndText(self.mNumText,LUtil.FormatColorStrs(len,numLimit,color1))
	self:SetWndText(self.mViceText,LUtil.FormatColorStrs(secondaryNum,viceLimit,color2))
end

function UIGdMemberPop:OnTimer(key)
	if self._playerOnlineKey == key then
		self:OnReqPlayerOnline()
	end
end

function UIGdMemberPop:OnClickHeadIcon(playerInfo)
	gModelGeneral:PlayerShowReq(playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIGdMemberPop:OnClickDissolve()
	local bool = gModelGuildMelee:GetIsMayQuitGuild(true)
	if not bool then
		return
	end
	local guildInfo=gModelGuild:GetGuildInfo()
	GF.OpenWnd("UIOrdinTip",{refId=100007,para={guildInfo.guildName},func=function (...)
		gModelGuild:OnQuitGuildReq()
		self:WndClose()
	end })
end

function UIGdMemberPop:OnClickRecruit()
	GF.OpenWnd("UIGdRecruitPop")
	self:WndClose()
end

function UIGdMemberPop:OnClickHelf(refId)
	GF.OpenWnd("UIBzTips",{refId = refId})
end

function UIGdMemberPop:InitCommand()
	local guildInfo = gModelGuild:GetGuildInfo()
	self:SetWndText(self.mLblBiaoti,ccClientText(12400))
	self:SetWndButtonText(self.mRecruitBtn,ccClientText(12411))
	self:RefreshSelfInfo()
	gModelGuild:OnGuildMemberListReq(guildInfo.guildId)
end

function UIGdMemberPop:OnClickAppoint(_guildMemberInfo)--任命
	local playerId = _guildMemberInfo.info._playerId
	gModelGuild:OnGuildPositionChangeReq(playerId , ModelGuild.GUILD_VICE_CHAIRMAN)
end

function UIGdMemberPop:OnClickAccuse()
	local item = gModelGuild:GetImpeachmentSpend()
	local itemRefId = item.refId
	local itemCount = item.count
	GF.OpenWnd("UIOrdinTip",{refId = 100006,para = {itemCount},func = function (...)
		gModelGuild:OnImpeachChairmanReq()
	end , consume = {itemCount, itemRefId} })
end

function UIGdMemberPop:OnClickSetBtn(item,itemdata)
	local selfInfo = gModelGuild:GetSelfGuildInfo()
	local _position = selfInfo.position
	local list = {}
	if(_position==1)then
		if(itemdata.position==2)then
			table.insert(list,{title = ccClientText(12512),img = "public_btn_1_3",func = function ()
				self:OnClickSetFree(itemdata)
			end})
		else
			table.insert(list,{title = ccClientText(12425),img = "public_btn_1_2",func = function ()
				self:OnClickAppoint(itemdata)
			end})
		end
		table.insert(list,{title = ccClientText(12424),img = "public_btn_1_1",func = function ()
			self:OnClickOver(itemdata)
		end})
	end
	table.insert(list,{title = ccClientText(12426),img = "public_btn_1_3",func = function ()
		self:OnClickOut(itemdata)
	end})
	GF.OpenWnd("UIBtnLPop",{root = item,list = list,other = itemdata.info._name})
end

function UIGdMemberPop:OnClickClose()
	GF.OpenWnd("UIGdWin")
	self:WndClose()
end
function UIGdMemberPop:OnReqPlayerOnline()
	local playerIdList = self._playerIdList
	if not playerIdList then return end
	gModelChat:PlayerOnlineReq(playerIdList,"3")
end

function UIGdMemberPop:OnClickOut(_guildMemberInfo)--剔除
	local playerId = _guildMemberInfo.info._playerId
	GF.OpenWnd("UIOrdinTip",{refId = 100005,para = {_guildMemberInfo.info._name},func = function ()
		gModelGuild:OnDeletGuildMemberReq(playerId )
	end})
end

function UIGdMemberPop:OnClickQuit()
	local bool = gModelGuildMelee:GetIsMayQuitGuild(true)
	if not bool then
		return
	end
	local guildInfo=gModelGuild:GetGuildInfo()
	local isExceed,time = gModelGuild:GetSignOutGuildCd()
	local refId,para
	if isExceed then
		refId = 100008
		para = {guildInfo.guildName,time}
	else
		local cd = gModelGuild:GetGuildConfigRefByKey("specialSignOutGuildCd")
		local cdArr = string.split(cd,",")
		refId = 100019
		para = {guildInfo.guildName,time,cdArr[1]}
	end
	GF.OpenWnd("UIOrdinTip",{refId = refId,para = para,func=function (...)
		gModelGuild:OnQuitGuildReq()
		self:WndClose()
	end })
end

function UIGdMemberPop:RefreshSelfInfo()
	local selfInfo = gModelGuild:GetSelfGuildInfo()
	self._meJob = selfInfo.position
	CS.ShowObject(self.mRecruitBtn,self._meJob == 1)
	local btnFunc = nil
	local btnStr = ""
	if self._meJob == 1 then
		btnFunc = function() self:OnClickDissolve() end
		btnStr = ccClientText(12412)
	else
		btnFunc = function() self:OnClickQuit() end
		btnStr = ccClientText(12577)
	end
	self:SetWndButtonText(self.mQuitBtn,btnStr)
	self:SetWndClick(self.mQuitBtn,function ()
		if btnFunc then btnFunc() end
	end)
end

function UIGdMemberPop:ListItem(list,item, itemdata, itempos)

	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local nameText = self:FindWndTrans(AniRoot,"NameText")
	local serverText = self:FindWndTrans(AniRoot,"ServerText")
	--local jobText = self:FindWndTrans(AniRoot,"PostText")
	--local activeText = self:FindWndTrans(AniRoot,"ActiveText")
	local dedicationBg = self:FindWndTrans(AniRoot,"DedicationBg_1")
	local dedicationText = self:FindWndTrans(AniRoot,"DedicationBg_1/DedicationText")
	local timeText = self:FindWndTrans(AniRoot,"TimeText")
	local accuseBtn = self:FindWndTrans(AniRoot,"AccuseBtn")
	--local accuseText = self:FindWndTrans(accuseBtn,"AccuseText")
	local AniRootPowerBg_1 = self:FindWndTrans(AniRoot,"PowerBg_1")
	local powerText = self:FindWndTrans(AniRootPowerBg_1,"PowerText")
	local powerName = self:FindWndTrans(AniRootPowerBg_1,"PowerName")
	local setBtn = self:FindWndTrans(AniRoot,"SetBtn")
	--local setText = self:FindWndTrans(setBtn,"SetText")
	local headIcon = CS.FindTrans(AniRoot,"HeadIcon")
	local jobImg = self:FindWndTrans(AniRoot,"JobImg")

	--self:SetWndText(accuseText,ccClientText(12578))
	--self:SetWndText(setText,ccClientText(12579))

	if self._isEnus then
		self:SetAnchorPos(jobImg,Vector2.New(58,-6.1))
	end

	CS.ShowObject(accuseBtn,false)
	CS.ShowObject(setBtn,false)

	local playerInfo = itemdata.info
	local _meJob = self._meJob
	local otherJob = itemdata.position
	local jobStr = "guild_icon_17"
	if otherJob == 2 then
		jobStr = "guild_icon_18"
	end
	CS.ShowObject(jobImg,otherJob <= 2)
	self:SetWndEasyImage(jobImg,jobStr)
	if _meJob == 1 then
		CS.ShowObject(setBtn,otherJob > 1)
	elseif _meJob == 2 then
		CS.ShowObject(setBtn,otherJob > 2)
	else
		CS.ShowObject(setBtn,false)
	end
	self:SetWndText(nameText,playerInfo._name)
	self:SetWndText(serverText,gModelFriend:GetSevenName(playerInfo._serverId))
	--self:SetWndText(activeText,string.replace(ccClientText(12571),LUtil.NumberCoversion(itemdata.activityGuild)))
	self:SetWndText(dedicationText,LUtil.NumberCoversion(itemdata.weekDonate))
	local playerInfoOn = {
		_lastLogoutTime = playerInfo._lastLogoutTime,
		_playerState = self._playerOnlineIds[playerInfo._playerId] and 1 or 0
	}
	if(playerInfoOn._playerState ~= 1)then
		local time = GetTimestamp()
		local _lastLogoutTime = playerInfo._lastLogoutTime/1000
		local h = (time - _lastLogoutTime)/3600
		local hNum = math.floor(h)
		local timeVice = gModelGuild:GetGuildConfigRefByKey("impeachmentVicePresidentTime")
		local timeMembers = gModelGuild:GetGuildConfigRefByKey("impeachmentMembersTime")
		if otherJob == ModelGuild.GUILD_CHAIRMAN then
			if((_meJob == ModelGuild.GUILD_VICE_CHAIRMAN and hNum >= timeVice) or (_meJob > ModelGuild.GUILD_VICE_CHAIRMAN and hNum >= timeMembers))then
				CS.ShowObject(accuseBtn,true)
			end
		end
	end


	local timeTextStr = gModelFriend:GetLastLogoutTime(playerInfoOn)
	self:SetWndText(timeText,timeTextStr)
	self:SetWndText(powerText,LUtil.PowerNumberCoversion(playerInfo._power))
	self:SetWndText(powerName, ccClientText(12623))
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

	self:SetWndClick(headIcon, function(...) self:OnClickHeadIcon(playerInfo) end)
	self:SetWndClick(AniRoot, function(...) self:OnClickHeadIcon(playerInfo) end)
	self:SetWndClick(setBtn, function(...) self:OnClickSetBtn(setBtn,itemdata) end)
	self:SetWndClick(accuseBtn, function(...) self:OnClickAccuse() end)
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
	self:SetWndClick(dedicationBg,function ()
		local title,desc,other
		title = ccClientText(12598)
		desc = ccClientText(12599)
		other = {itemdata.weekDonate,itemdata.guildDonate}
		GF.OpenWnd("UIExTips",{root = jobImg,title = title,desc = desc,other = other})
	end)
end

function UIGdMemberPop:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function (index)
		if index == 4 then self:OnClickClose() end
	end)
	self:SetWndClick(self.mCloseBtn, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end)
	--self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mHelfBtn, function(...) self:OnClickHelf(20) end)
	self:SetWndClick(self.mRecruitBtn, function(...) self:OnClickRecruit() end)
	self:SetWndClick(self.mNumAddBtn, function(...) self:OnClickHelf(64) end)
	self:SetWndClick(self.mViceAddBtn, function(...) self:OnClickHelf(65) end)
end
------------------------------------------------------------------
return UIGdMemberPop


