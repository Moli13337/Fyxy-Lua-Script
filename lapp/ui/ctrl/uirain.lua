---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
local typeof = typeof
local typeof_LayoutElement = typeof(UnityEngine.UI.LayoutElement)
---@class UIRain:LWnd
local UIRain = LxWndClass("UIRain", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRain:UIRain()
	self:SetHideHurdle()
	self._resetRankTimeKey = "_resetRankTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRain:OnWndClose()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRain:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

	self._uiheadList={}
	self._typeBtnList={}
	self._oldType=nil
	self._type = 1--排行榜请求类型 1请求排行榜分类展示信息 2请求子排行榜展示信息
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRain:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	
	
	self:SetServerInfo()
	
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self._redFun1 = function (pb)
		self:RefreshRed(1)
	end
	self._redFun2 = function (pb)
		self:RefreshRed(2)
	end
end

function UIRain:SetServerInfo()
	self._servers, self._guildBattleGroupId  = gModelGuildHolyBattle:GetServers()
end

function UIRain:OnTargetWndClose(wndName)
	if wndName == "UIRkPop" then
		--因为排行数据被之前打开的面板覆盖，重新获取数据刷新面板
		self:TryRefreshUI()
	end
end

function UIRain:OnClickCloseWnd()
	if(self._rankType == ModelRank.RANK_TYPE_CALL)then
		local callName = gModelCallHero:GetCallWndName()
		GF.OpenWnd(callName)
	end
	self:WndClose()
end

function UIRain:OnTimer(key)
	if key == self._resetRankTimeKey then
		self:ResetRankTimeFunc()
	end
end

function UIRain:ChangeTab(trans,bool)
	local state = bool and 0 or 1
	self:SetWndTabStatus(trans, state)
end

function UIRain:ResetRankTimeFunc()
	if not self._waitResetRankTimeValue then
		return
	end

	local time = self._waitResetRankTimeValue - GetTimestamp()
	if time <= 0 then
		self:TimerStop(self._resetRankTimeKey)
		self:RefreshRankTime()
		return
	end

	local timeStr = LUtil.FormatTimespanCn(time, {hTextId = 10371})
	timeStr = string.replace(ccClientText(11735), timeStr)
	self:SetWndText(self.mTimeText, timeStr)
end

function UIRain:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(11700))

	self._rankType = self:GetWndArg("rankType") or ModelRank.RANK_TYPE_COMPLEX
	local list = gModelRank:GetRankRefType(self._rankType)
	if(#list > 1)then
		local tabList = self:GetUIScroll("tab")
		tabList:Create(self.mTabScroll,list,function (...) self:SetTabListItem(...) end)
	end
	self:OnClickTypeBtn(list[1].type)

	if(self._rankType == ModelRank.RANK_TYPE_CALL)then
		local name = ccLngText(list[1].name)
		self:SetWndText(self.mTitleText,name)
		CS.ShowObject(self.mHelpBtn,true)
	end
end

function UIRain:FormatDesStr(itemdata,value)
	local detailsRef = itemdata.detailsRef
	if string.isempty(detailsRef) then
		return value
	end

	local ref = GameTable[detailsRef]
	if not ref then
		printInfoNR("GameTable[detailsRef] is not find, detailsRef = "..detailsRef)
		return ""
	end

	local itemRef = ref[value]
	local detailsFields = string.split(itemdata.detailsFields,"=")
	local ret = itemRef[detailsFields[1]]
	if detailsFields[2] == "1" then
		ret = ccLngText(ret)
	end
	return ret
end

function UIRain:RefreshRed(index)
	if(self._oldType~=index)then
		return
	end
	for i, v in pairs(self._cellTransList) do
		local item = v
		local RedPoint=CS.FindTrans(item,"redPoint")
		local showRed =  gModelRedPoint:CheckRankShowRed(i)
		CS.ShowObject(RedPoint,showRed)
	end
end

function UIRain:SubListItem(list, item, itemdata, itempos)
	local icon = CS.FindTrans(item,"Image")
	local nameText = CS.FindTrans(item,"NameText")
	local desText = CS.FindTrans(item,"DesText")
	self._cellTransList[itemdata.refId] = item

	local rankInfo = gModelRank:GetRankInfos(itemdata.refId)
	self:SetWndEasyImage(icon,itemdata.icon)
	if not rankInfo then
		self:SetWndText(nameText,ccClientText(11706))
		self:SetWndText(desText,"")
		return
	end
	local playerData = rankInfo.info
	local name = playerData._name
	if (itemdata.type == ModelRank.RANK_TYPE_CROSSSERVER)then
		local serverName = gModelFriend:GetSevenName(playerData._serverId)
		name = string.replace(ccClientText(11718),serverName,playerData._name)
	elseif(itemdata.refId == ModelRank.RANK_GUILD_RANK)then
		name = playerData._guildName
	end
	self:SetWndText(nameText,name)

	local desStr = ""
	local score = rankInfo.score
	if itemdata.showPower == 0 then
		score = self:FormatDesStr(itemdata,score)
	else
		score = LUtil.PowerNumberCoversion(score)
	end
	desStr = string.replace(ccLngText(itemdata.description), score)
	self:SetWndText(desText,desStr)
	self:SetWndClick(item, function (...) self:OnClickCell(itemdata) end)
end

function UIRain:RefreshRankTime()
	local showTime = false
	if self._oldType == ModelRank.RANK_TYPE_CROSSSERVER and not table.isempty(self._rankRefList) then
		for k,v in ipairs(self._rankRefList) do
			local rankInfo = gModelRank:GetRankInfos(v.refId)
			if not rankInfo then
				showTime = true
				break
			end
		end
	end

	CS.ShowObject(self.mTimeBg, showTime)
	if not showTime then return end
	local crossInitialTime	= tonumber(GameTable.CrossGamePlayConfigRef["crossInitialTime"]) or 0
	local year				= math.floor(crossInitialTime / 10000)
	local month				= math.floor(crossInitialTime % 10000 / 100)
	local day				= math.floor(crossInitialTime % 100)
	local initialTime 		= LUtil.GetTimeByDateTable(year, month, day)

	local crossResetTime	= tonumber(GameTable.CrossGamePlayConfigRef["crossResetTime"]) or 0
	local resetTime			= crossResetTime * 86400
	local GetTimestamp			= GetTimestamp()
	local waitTimeValue
	if GetTimestamp >= initialTime then
		if resetTime ~= 0 then
			waitTimeValue = math.ceil((GetTimestamp - initialTime) / resetTime) * resetTime + initialTime
		else
			waitTimeValue = initialTime
		end
	else
		waitTimeValue 		= initialTime
	end

	self._waitResetRankTimeValue = waitTimeValue
	if waitTimeValue < 0 then
		self._waitResetRankTimeValue = 0
		CS.ShowObject(self.mTimeBg, false)
	else
		self:TimerStart(self._resetRankTimeKey, 1, false, -1)
		self:ResetRankTimeFunc()
	end

end

function UIRain:OnUpdateRankResp(bool)--刷新界面
	local list = gModelRank:GetRankingRef(self._type,self._oldType,bool)
	if(not list or #list<=0)then
		return
	end

	self._rankRefList = list
	self._cellTransList = {}
	if(self._uiCellList)then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("cell")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:SetCellListItem(...) end)
		self._uiCellList:EnableScroll(true, false)
	end
	self:ReleaseRedPointSingleFunc(ModelRedPoint.RANK_SCHEDULE,self._redFun1)
	self:RegisterRedPointFunc(ModelRedPoint.RANK_SCHEDULE,self._redFun1)
	self:ReleaseRedPointSingleFunc(ModelRedPoint.RANK_HERO,self._redFun2)
	self:RegisterRedPointFunc(ModelRedPoint.RANK_HERO,self._redFun2)
	self:RefreshRankTime()
end

function UIRain:SetCellListItem(list, item, itemdata, itempos)
	local rank = CS.FindTrans(item,"Rank")
	local subBg = CS.FindTrans(item,"SubBg")
	local refId = itemdata.refId
	self._cellTransList[refId] = rank
	local bgImage=CS.FindTrans(rank,"BgImage")
	local headIcon=CS.FindTrans(rank,"HeadIcon")
	local flagBg = CS.FindTrans(rank,"FlagBg")
	local flagIcon = CS.FindTrans(flagBg,"FlagIcon")
	local guildLvBg = CS.FindTrans(flagBg,"GuildLvBg")
	local guildLvText = CS.FindTrans(guildLvBg,"GuildLvText")
	local titleText=CS.FindTrans(rank,"TitleText")
	local nameText=CS.FindTrans(rank,"NameText")
	local desIcon=CS.FindTrans(rank,"DesBgImg/DesIconDiv/DesIcon")
	local powerText = CS.FindTrans(rank,"DesBgImg/PowerText")
	local icon = CS.FindTrans(rank,"Icon")
	local desBgImg=CS.FindTrans(rank,"DesBgImg")
	local desText=CS.FindTrans(rank,"DesText")
	local redPoint =CS.FindTrans(rank,"redPoint")
	local tipsText=CS.FindTrans(rank,"TipsText")

	CS.ShowObject(subBg,false)
	CS.ShowObject(redPoint,false)
	CS.ShowObject(flagBg,false)
	self:SetWndEasyImage(bgImage,itemdata.icon)
	CS.ShowObject(icon,itemdata.iconSmall ~= "")
	if itemdata.iconSmall ~= "" then
		self:SetWndEasyImage(icon,itemdata.iconSmall,nil,true)
	end
	self:SetWndText(titleText,ccLngText(itemdata.name))
	self:InitTextSizeWithLanguage(titleText, -2)

	local rankInfo = gModelRank:GetRankInfos(refId)

	if(not rankInfo)then
		CS.ShowObject(headIcon,false)
		self:SetWndText(nameText,"")
		CS.ShowObject(desBgImg,false)
		CS.ShowObject(desText,false)
		self:SetWndText(tipsText,ccClientText(11706))
		self:SetWndClick(rank, function (...)  end)
		return
	end

	local desStr = rankInfo.score
	local desImg = "icon_item_fight"
	local isShowPower = itemdata.showPower == 1
	CS.ShowObject(desBgImg,isShowPower)
	CS.ShowObject(desText,not isShowPower)
	if not isShowPower then
		desImg = "achievement_icon_3"

		if refId == ModelRank.RANK_SPIRIT_RANK then
			desStr = LUtil.PowerNumberCoversion(desStr)
		end

		desStr = self:FormatDesStr(itemdata,desStr)
		desStr = string.replace(ccLngText(itemdata.description), desStr)
	else
		desStr = LUtil.PowerNumberCoversion(desStr)
	end

	self:SetWndText(tipsText,"")
	self:SetWndEasyImage(desIcon,desImg)
	self:SetWndText(desText,desStr)
	self:SetWndText(powerText,desStr)
	self:SetWndClick(headIcon, function (...) self:OnClickCell(itemdata) end)
	self:SetWndClick(rank, function (...) self:OnClickCell(itemdata) end)

	--CS.ShowObject(headIcon,true)
	CS.ShowObject(headIcon,itemdata.showType ~= 1)
	CS.ShowObject(flagBg,itemdata.showType == 1)
	if(itemdata.showType == 1)then
		local bgRef = gModelGuild:GetGuildFlagRefByRefId(rankInfo.flagBgId)
		if bgRef then
			self:SetWndEasyImage(flagBg,bgRef.res)
		end

		local iconRef = gModelGuild:GetGuildFlagRefByRefId(rankInfo.flagId)
		if iconRef then
			self:SetWndEasyImage(flagIcon,iconRef.res)
		end

		self:SetWndText(guildLvText,rankInfo.guildLevel)
	end

	local playerData = rankInfo.info
	local playerInfo={
		trans = headIcon,
		icon = playerData._head,
		headFrame = playerData._headFrame,
		name = playerData._name,
		level = playerData._grade,
	}
	local name = playerInfo.name
	if (itemdata.type == ModelRank.RANK_TYPE_CROSSSERVER)then
		local serverName = gModelFriend:GetSevenName(playerData._serverId)
		name = playerInfo.name
		if(refId == ModelRank.RANK_CROSS_GUILD)then
			name = playerData._guildName
		end
		name = string.replace(ccClientText(11718),serverName,name)
	elseif(refId == ModelRank.RANK_GUILD_RANK)then
		name = playerData._guildName
	end

	self:SetWndText(nameText,name)

	local InstanceID = item:GetInstanceID()
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	baseClass:RefreshUI()

	local ranklist = gModelRank:GetRankingRef(self._type,self._oldType,true,true)
	local sortSmallList = {}
	local sortSmall
	for i, v in ipairs(ranklist) do
		sortSmall = v.sortSmall
		if sortSmall == refId then
			table.insert(sortSmallList,v)
		end
	end
	local len = #sortSmallList
	if len <= 0 then
		return
	end
	CS.ShowObject(subBg,true)
	local numH = math.ceil(len/2)
	local csLayoutElement = subBg:GetComponent(typeof_LayoutElement)
	if(csLayoutElement)then
		csLayoutElement.preferredHeight = numH * 72 + 5 * (numH)
	end
	local _subScroll = CS.FindTrans(subBg,"SubScroll")
	local _uiSubList = self:GetUIScroll("subcell"..InstanceID)
	if(_uiSubList:GetList())then
		_uiSubList:RefreshList(sortSmallList)
	else
		_uiSubList:Create(_subScroll,sortSmallList,function (...) self:SubListItem(...) end)
	end
end

function UIRain:SetTabListItem(list, item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab3")
	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndTabStatus(btnTab, 1)
	self._typeBtnList[itemdata.type] = btnTab
	self:SetWndClick(item, function (...) self:OnClickTypeBtn(itemdata.type) end)
end

function UIRain:InitEvent()
	--self:SetWndClick(self.mBgImage, function (...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mCloseBtn, function (...) self:OnClickCloseWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn, function (...) self:OnClickHelp() end)
end

function UIRain:TryRefreshUI()
	-- 【G公共支持】删除跨服天梯和跨服周冠玩法
	-- if self._oldType == ModelRank.RANK_TYPE_CROSSSERVER then
	-- 	local sevenList = gModelCrossServer:GetServerList()
	-- 	if not sevenList then
	-- 		self:OnUpdateRankResp(true)
	-- 		return
	-- 	end
	-- end
	gModelRank:OnRankReq(self._type,self._oldType)--排行榜请求
end

function UIRain:InitMessage()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.RANK_UPDATE_END,function (...) self:OnUpdateRankResp()  end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnTargetWndClose(...) end)
	--self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function (...) self:WndClose()  end)


end

function UIRain:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 59})
end

function UIRain:OnClickTypeBtn(type)--点击类
	if(#self._typeBtnList > 0)then
		if(self._oldType)then
			if(type ==self._oldType)then
				return
			end
			local trans = self._typeBtnList[self._oldType]
			self:ChangeTab(trans,false)
		end
		local trans= self._typeBtnList[type]
		self:ChangeTab(trans,true)
	end
	self._oldType = type

	self:TryRefreshUI()
end

function UIRain:OnClickCell(itemdata)
	local rankInfo = gModelRank:GetRankInfos(itemdata.refId)
	if(not rankInfo)then
		GF.ShowMessage(ccClientText(11707))
		return
	end
	GF.OpenWndBottom("UIRkPop",{type = self._oldType, refId=itemdata.refId})
end
------------------------------------------------------------------
return UIRain


