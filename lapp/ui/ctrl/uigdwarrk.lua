---
--- Created by BY.
--- DateTime: 2023/10/14 10:07:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdWarRk:LWnd
local UIGdWarRk = LxWndClass("UIGdWarRk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdWarRk:UIGdWarRk()
	self:SetHideHurdle()
	self._uiheadList = {}
	self._tabTrans = {}
	self._type = 2--排行榜请求类型 1请求排行榜分类展示信息 2请求子排行榜展示信息
	self._pageSize = 25--数据大小25
	self._page = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdWarRk:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdWarRk:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdWarRk:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	self:InitCommand()
end

function UIGdWarRk:OnClickPlayer(_playerId)
	gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIGdWarRk:InitRankItem(item,info,isThree)--isThree=1前面3，=2列表，=3自
	local playIcon
	local rankImg = CS.FindTrans(item, "RankImg")
	local rankText = CS.FindTrans(item, "RankText")

	local nameText = CS.FindTrans(item, "NameText")
	local powerBg = CS.FindTrans(item, "PowerBg")
	local powerText = CS.FindTrans(item, "PowerBg/PowerText")

	local desBg = CS.FindTrans(item, "DesBg")
	local desText = CS.FindTrans(item, "DesBg/DesText")

	if(isThree == 1)then
		playIcon = CS.FindTrans(item, "Mask/PlayIcon")
		desText = CS.FindTrans(item, "DesText")
		self:SetWndText(desText,"")
		self:SetHeroPaint(playIcon,info.info,info.rank)
	else
		CS.ShowObject(rankImg,false)
		self:SetWndText(rankText, info.index)
		if(isThree == 3)then
			self:SetWndText(rankText, ccClientText(11708))
		end
		CS.ShowObject(desBg,false)
		self:SetHeadIcon(item,info.info)
	end
	self:SetWndText(nameText,ccClientText(11711))
	CS.ShowObject(powerBg,false)

	if(not info.info or info.info._playerId == 0)then
		return
	end
	CS.ShowObject(desBg,true)
	CS.ShowObject(powerBg,true)

	local rank = info.rank
	if(info.rank >= 1 and info.rank <= 3)then
		local rankIcon = ""
		if(rank == 1)then
			rankIcon = "public_num_1"
		elseif(rank == 2)then
			rankIcon = "public_num_2"
		elseif(rank == 3)then
			rankIcon = "public_num_3"
		end
		self:SetWndEasyImage(rankImg,rankIcon)
		CS.ShowObject(rankImg,true)
		self:SetWndText(rankText, "")
	elseif(rank > 0)then
		self:SetWndText(rankText, rank)
	end

	local meleeInfo = info.guildMeleeRankInfo
	if(meleeInfo)then
		local ref= gModelRank:GetRankingRefData(self._refId)
		local desStr = ""
		local power = ""
		if(self._refId == ModelRank.RANK_MELEE)then
			desStr = string.replace(ccLngText(ref.descriptionDetail), meleeInfo.num)
			power = meleeInfo.power
		else
			desStr = string.replace(ccLngText(ref.descriptionDetail), info.score)
			power = meleeInfo.power --info.info._figure
		end
		self:SetWndText(desText,desStr)
		self:SetWndText(powerText,LUtil.ToInteger(power))
	end

	local player = info.info
	local serverName = gModelFriend:GetSevenName(player._serverId)
	local nameStr = ""
	if self._refId == ModelRank.RANK_MELEE then
		nameStr = string.replace(ccClientText(17941),player._guildName,serverName)
	elseif self._refId == ModelRank.RANK_INTEGRAL then
		nameStr = string.replace(ccClientText(17941),player._name,serverName)
	end
	self:SetWndText(nameText,nameStr)
	self:SetWndClick(item, function (...)
		self:OnClickPlayer(player._playerId)
	end)
end

function UIGdWarRk:TabListItem(list, item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab3")
	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndTabStatus(btnTab, 1)
	self._tabTrans[itemdata.refId] = btnTab
	self:SetWndClick(item, function (...) self:OnClickTab(itemdata.refId) end,LSoundConst.CLICK_PAGE_COMMON)
end

--刷新排行榜列表
function UIGdWarRk:RefreshRank()
	local ref = gModelRank:GetRankingRefData(self._refId)
	self:SetWndText(self.mTitleText,ccLngText(ref.name))
	self:InitTextLineWithLanguage(self.mTitleText, -30)
	self:InitTextSizeWithLanguage(self.mTitleText, -2)
	local threeList = {}
	local cellList = {}
	local ranks = gModelRank:GetRankListInfo(self._type,self._refId)
	for i, v in pairs(ranks) do
		v.index = i
		if(v.rank > 3) then
			table.insert(cellList,v)
		else
			table.insert(threeList,v)
		end
	end

	local len = #threeList
	if(len < 3)then
		for i = 1, 3 - len do
			table.insert(threeList,{index = i + len})
		end
	end
	self:RefreshThreeRank(threeList)--刷新前3

	len = #cellList
	for i, v in ipairs(cellList) do
		v.index = i
	end
	if(len < 7)then
		for i = 1, 7 - len do
			table.insert(cellList,{index = 4 + #cellList})
		end
	end
	table.sort(cellList , function(a , b)
		return a.index < b.index
	end)

	if(self._uiRankList)then
		if self._oldRefId and self._oldRefId ~= self._refId then
			self._uiRankList:RefreshSimpleList(cellList)
		else
			self._uiRankList:RefreshData(cellList,true)
			local _uiList = self._uiRankList:GetList()
			_uiList:RefreshSilent()
		end

	else
		self._uiRankList = self:GetUIScroll("rank")
		self._uiRankList:Create(self.mCellScroll,cellList,function (...) self:ListItem(...) end,UIItemList.WRAP)
	end
	self._oldRefId = self._refId
	local info = gModelRank:GetMeRank()
	self:InitRankItem(self.mMeRankItem,info,3)--刷新自己
end

function UIGdWarRk:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function (...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIGdWarRk:ChangeTab(trans,bool)
	local state = bool and 0 or 1
	self:SetWndTabStatus(trans, state)
end

function UIGdWarRk:OnCutRank()
	local ranks = gModelRank:GetRankListInfo(self._type,self._refId)
	if(#ranks > 1)then
		self:RefreshRank()
	else
		self._page = 0
		self:NewPage()
	end
end
--设置立绘
function UIGdWarRk:SetHeroPaint(paintTans,info,rank)
	CS.ShowObject(paintTans,false)
	if(not info)then
		return
	end
	local ref = gModelPlayer:GetRoleAdventureImage(info._figure)
	if(not ref)then
		return
	end
	CS.ShowObject(paintTans,true)
	local key = "paintKey"..rank
	local paintFlip = ref.paintFlip2 == 1
	local paintMultiple = ref.paintMultiple2
	self:DestroyWndSpineByKey(key)
	self:CreateWndSpine(paintTans,ref.spine,key,false,function(dpSpine)
		dpSpine:SetScale(paintMultiple)
		dpSpine:SetFlipX(paintFlip)
		local dpTrans = dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
	end)
end
------------------------------------------------------------------
--设置玩家头像
function UIGdWarRk:SetHeadIcon(item,info)
	local iconBg = CS.FindTrans(item, "IconBg")
	local headIcon = CS.FindTrans(item, "HeadIcon")
	CS.ShowObject(iconBg,true)
	CS.ShowObject(headIcon,false)
	if(not info or info._playerId == 0)then
		return
	end
	CS.ShowObject(iconBg,false)
	CS.ShowObject(headIcon,true)
	local InstanceID = item:GetInstanceID()
	local playerInfo={
		trans = headIcon,
		playerId = info._playerId,
		icon = info._head,
		headFrame = info._headFrame,
		level = info._grade,
	}
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	self:SetWndClick(headIcon, function (...)
		self:OnClickPlayer(info._playerId)
	end)
end

function UIGdWarRk:ListItem(list, item, itemdata, itempos)
	if itemdata.index >= (self._page * self._pageSize - 3) then
		local num = gModelRank:GetRankQuantity(self._refId)
		if(self._page * self._pageSize < num)then
			self:NewPage()
		end
	end
	self:InitRankItem(item,itemdata,2)
end

function UIGdWarRk:OnClickTab(refId)
	if(self._refId)then
		local trans = self._tabTrans[self._refId]
		self:ChangeTab(trans,false)
	end
	local trans = self._tabTrans[refId]
	self:ChangeTab(trans,true)
	self._refId = refId
	self:OnCutRank()
end

function UIGdWarRk:InitMessage()
	self:WndEventRecv(EventNames.RANK_UPDATE_END,function (...)
		self:RefreshRank()
	end)
end

function UIGdWarRk:NewPage()
	self._page = self._page + 1
	gModelRank:OnRankReq(self._type,self._refId,self._page,self._pageSize)--排行榜请求
end

function UIGdWarRk:InitCommand()
	local list = {}
	local ref = gModelRank:GetRankingRefData(1001)
	table.insert(list,ref)
	ref = gModelRank:GetRankingRefData(1002)
	table.insert(list,ref)
	table.sort(list,function (a,b)
		return a.sort < b.sort
	end)
	local _tabList = self:GetUIScroll("_tabList")
	_tabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
	self:OnClickTab(list[1].refId)
end

function UIGdWarRk:RefreshThreeRank(list)
	for i = 1, #list do
		self:InitRankItem(self._rankThree[i],list[i],1)
	end
end

function UIGdWarRk:InitData()
	self._rankThree={
		self.mRank1,
		self.mRank2,
		self.mRank3,
	}
end
------------------------------------------------------------------
return UIGdWarRk


