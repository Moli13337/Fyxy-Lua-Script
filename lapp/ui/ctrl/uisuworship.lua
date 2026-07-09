---
--- Created by Administrator.
--- DateTime: 2023/10/6 21:30:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuWorship:LWnd
local UISuWorship = LxWndClass("UISuWorship", LWnd)

local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuWorship:UISuWorship()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuWorship:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuWorship:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuWorship:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitUIEvent()
	self:Initvent()
	self:SetStaticContent()
	self._curArea = 0
	self._curSeason = 0

	gModelSimuFight:OnSimulateGroupReq()

	self:ReqData()

end

function UISuWorship:Initvent()
	self:WndNetMsgRecv(LProtoIds.SimulateTopInfoResp,function (pb)
		self:OnSimulateTopInfoResp(pb)
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateTopLikeResp,function ()

		gModelSimuFight:OnSimulateStateReq()

		self:ReqData()
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateGroupResp,function (pb)
		self:OnSimulateGroupResp(pb)
	end)

	self:WndEventRecv(EventNames.SIMULATE_STATE_CHANGE,function ()
		self:RefreshAdmireBtn()
	end)

	self:WndEventRecv(EventNames.ON_TIME_ZERO,function ()
		self:ReqData()
	end)
end

function UISuWorship:OnClickArea(area)
	if self._curArea == area then
		return
	end

	self._curArea = area

	local list = self:FindUIScroll("optionList")
	if list then
		list:DrawAllItems(false)
	end

	self:ReqData()
end

function UISuWorship:OnDrawItem(list,item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	self:CreateCommonIconImpl(itemRoot,itemdata)
end


function UISuWorship:RefreshContent(pb)

	self:RefreshChangeBtnShow()

	local playerData = StructPlayerData:New()
	playerData:CreateByPb(pb.info)

	self:SetPlayerInfo(self.mPlayer,playerData)

	self._likeCount = pb.likeCount

	self:RefreshAdmireBtn()
	local canWorship = self:CanWorship()

	CS.ShowObject(self.mRewardPart,canWorship)
	if canWorship then
		local rewards = gModelSimuFight:GetWorshipShowReward()
		local list = self:FindUIScroll("uiList")
		if not list then
			list= self:GetUIScroll("uiList")
			list:Create(self.mItemList,rewards,function (...) self:OnDrawItem(...) end)
		else
			list:RefreshList(rewards)
		end

		list:EnableScroll(true,true)
	end

	local dataList = {}
	for k,v in ipairs(pb.likeInfos) do
		local textRef = gModelSimuFight:GetWorshipText(tonumber(v.text))
		local text = ccLngText(textRef.description)
		local sendName = v.info.name
		local receiveName = playerData.name
		local str = string.replace(text,sendName,receiveName)
		table.insert(dataList,str)
	end

	local msgList = self:FindUIScroll("msgList")
	if not msgList then
		msgList= self:GetUIScroll("msgList")
		msgList:Create(self.mMesgList,dataList,function (...) self:OnDrawMsg(...) end,UIItemList.SUPER)
	else
		msgList:RefreshList(dataList)
	end

	msgList:MoveToPos(1)

end

function UISuWorship:OnDrawMsg(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootContent = self:FindWndTrans(AniRoot,"content")

	local showImage = itempos%2 == 1
	CS.ShowObject(AniRootImage,showImage)
	self:SetWndText(AniRootContent,itemdata)

	self:InitTextLineWithLanguage(AniRootContent,-40)
end

function UISuWorship:ReqSeasonInfo(seasonId)
	local seasonInfoMap = self._seasonInfoMap or {}
	local seasonInfo = seasonInfoMap[seasonId]
	if seasonInfo then
		return
	end

	gModelSimuFight:OnSimulateGroupReq(seasonId)
end

function UISuWorship:OnClickCurSeason()
	self._curArea = 0
	self._curSeason = 0

	self:ReqData()
end

function UISuWorship:ShowOptionList(type)
	self._optionType = type

	local dataList = {}

	local root = nil
	local para = nil
	local curPos = nil
	if type == 1 then
		root = self.mBtnSeason
		local maxSeason = gModelSimuFight:GetMaxSeason()
		for k= 1,maxSeason do
			local data =
			{
				season = k,
				name =string.replace( ccClientText(25165),k),
			}

			table.insert(dataList,data)
		end

		curPos = self._curSeason
		para =
		{
			root = self.mOptionList,
			dataList = dataList,
			setFunc = function(...) self:OnDrawSeason(...) end,
			type = UIItemList.SUPER
		}
	elseif type == 2 then

		root = self.mBtnArea

		local seasonInfo = self:GetSeasonInfo(self._curSeason)
		if not seasonInfo then
			return
		end

		for k,v in ipairs(seasonInfo.group) do
			local data =
			{
				area = v.group,
				name = string.replace(ccClientText(25166),v.group)
			}
			table.insert(dataList,data)
		end

		table.sort(dataList,function (a,b)
			return a.area< b.area
		end)

		for k,v in ipairs(dataList) do
			if v.area == self._curArea then
				curPos = k
			end
		end

		para =
		{
			root = self.mOptionList,
			dataList = dataList,
			setFunc = function(...) self:OnDrawArea(...) end,
			type = UIItemList.SUPER
		}

	end

	self.mOptionList.position = root.position
	self.mOptionList.localPosition = self.mOptionList.localPosition + Vector3.New(-100,-100,0)

	CS.ShowObject(self.mOptionBg,true)
	local uiList = self:GetUIScroll("optionList")
	uiList:InitListData(para)
	--uiList:DrawAllItems(false)
	local pos = curPos or 1
	uiList:MoveToPos(pos)
end

function UISuWorship:SetStaticContent()
	self:SetTextTile(self.mBtnSeason,ccClientText(25159),-30)
	self:SetTextTile(self.mBtnArea,ccClientText(25161),-30)
	self:SetTextTile(self.mBtnGroup,ccClientText(25162),-30)
	self:SetWndText(self.mRewardTitle,ccClientText(25188))
	self:SetWndButtonText(self.mBtnWorship,ccClientText(25189))
	self:SetTextTile(self.mBtnCurSeason,ccClientText(25163), nil, -2)


	if gLGameLanguage:IsJapanRegion() then
		local group = self.mLayout:GetComponent(typeVerticalLayoutGroup)
		group.spacing = 14
	end
end

function UISuWorship:SetPlayerInfo(item,playerData)
	local Image = self:FindWndTrans(item,"Image")
	local title = self:FindWndTrans(item,"title")
	local name = self:FindWndTrans(item,"name")
	local sever = self:FindWndTrans(item,"sever")
	local powerIcon = self:FindWndTrans(item,"powerIcon")
	local power = self:FindWndTrans(item,"power")


	local headTran = self:FindWndTrans(item,"HeadIcon")

	self:SetWndText(name,playerData.name)
	self:SetWndText(sever,string.format("[%s]",playerData.serverName))

	local playerInfo =
	{
		trans = headTran,
		icon = playerData.head,
		headFrame = playerData.headFrame,
		level = playerData.grade,
		func = function()
			gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)

	self:SetWndText(power,LUtil.NumberCoversion(playerData.power))

	self:SetWndText(title,ccClientText(25190))
end

function UISuWorship:GetSeasonInfo(season)
	local seasonInfo = self._seasonInfoMap and self._seasonInfoMap[season]
	return seasonInfo
end

function UISuWorship:OnClickSeason(season)
	if self._curSeason == season then
		return
	end

	self._curSeason = season

	self._curArea =  self._gameHistory and self._gameHistory[season] or 1
	local list = self:FindUIScroll("optionList")
	if list then
		list:DrawAllItems(false)
	end

	self:ReqSeasonInfo(season)
	self:ReqData()
end

function UISuWorship:RefreshTitle()
	local str = ccClientText(25167)
	str= string.replace(str,self._curSeason,self._curArea)
	self:SetWndText(self.mSeasonInfo,str)
	self:InitTextSizeWithLanguage(self.mSeasonInfo, -2)
	self:InitTextLineWithLanguage(self.mSeasonInfo, -30)
end

function UISuWorship:RefreshBtnCurShow()
	local isCur =  self._curSeason == gModelSimuFight:GetCurSeason()
	CS.ShowObject(self.mBtnCurSeason,not isCur)
end

function UISuWorship:OnClickServerGroup()
	local seasonInfo = self:GetSeasonInfo(self._curSeason)
	gModelSimuFight:ShowServerGroup(seasonInfo,self._curArea)
end

function UISuWorship:OnSimulateGroupResp(pb)
	local seasonId = pb.seasonId
	local seasonInfoMap = self._seasonInfoMap or {}
	seasonInfoMap[seasonId] = pb
	self._seasonInfoMap = seasonInfoMap
end

function UISuWorship:CanWorship()

	local belongGroup = gModelSimuFight:GetCurGroupId()
	if belongGroup ~= self._curArea then
		return false
	end

	local curSeason = gModelSimuFight:GetCurSeason()
	if curSeason ~= self._curSeason then
		return false
	end

	return true
end

function UISuWorship:OnSimulateTopInfoResp(pb)
	if self._curArea == 0 then
		self._curArea = pb.groupId
	end

	if self._curSeason == 0 then
		self._curSeason = pb.seasonId
	end

	if self._curArea ~= pb.groupId then
		return
	end

	if self._curSeason ~= pb.seasonId then
		return
	end

	local historyRecord = pb.history
	local history = {}
	if historyRecord then

		for k,v in ipairs(historyRecord) do
			local temps = string.split(v,"_")
			local _seasonId = tonumber(temps[1])
			local _groupId = tonumber(temps[2])

			if _seasonId and _groupId then
				history[_seasonId] = _groupId
			end
		end
	end
	self._gameHistory = history

	self:RefreshTitle()
	self:RefreshBtnCurShow()
	self:RefreshContent(pb)


end



function UISuWorship:ReqData()
	local groupId = self._curArea
	local seasonId = self._curSeason

	gModelSimuFight:OnSimulateTopInfoReq(groupId,seasonId)

	self:RefreshBtnCurShow()
	self:RefreshChangeBtnShow()

end

function UISuWorship:OnDrawArea(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootSelect = self:FindWndTrans(AniRoot,"select")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootSelName = self:FindWndTrans(AniRoot,"selName")

	local isSel = self._curArea == itemdata.area
	CS.ShowObject(AniRootSelect,isSel)

	self:SetWndText(AniRootUIText,itemdata.name)
	self:SetWndText(AniRootSelName,itemdata.name)
	CS.ShowObject(AniRootSelName,isSel)
	CS.ShowObject(AniRootUIText,not isSel)

	self:SetWndClick(AniRoot,function ()
		self:OnClickArea(itemdata.area)
	end)
end

function UISuWorship:RefreshChangeBtnShow()
	local maxSeason = gModelSimuFight:GetMaxSeason()
	local hasMore = maxSeason >1

	local showLeft = self._curSeason >1
	local showRight = self._curSeason < maxSeason

	CS.ShowObject(self.mLeft,hasMore and showLeft)
	CS.ShowObject(self.mRight,hasMore and showRight)
end

function UISuWorship:RefreshAdmireBtn()
	local isLiked = gModelSimuFight:IsAdmired()
	self:SetWndButtonGray(self.mBtnWorship,isLiked)
end

function UISuWorship:OnChangeSeason(index)
	local maxSeason = gModelSimuFight:GetMaxSeason()
	if maxSeason <= 1 then
		return
	end

	local next = self._curSeason  + index
	if next>maxSeason then
		return
	elseif next <1 then
		return
	end

	self._curSeason = next
	self._curArea =  self._gameHistory and self._gameHistory[next] or 1

	self:ReqData()
end

function UISuWorship:OnDrawSeason(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootSelect = self:FindWndTrans(AniRoot,"select")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootSelName = self:FindWndTrans(AniRoot,"selName")



	local isSelect = self._curSeason == itemdata.season
	CS.ShowObject(AniRootSelect,isSelect)

	self:SetWndText(AniRootUIText,itemdata.name)
	self:SetWndText(AniRootSelName,itemdata.name)
	CS.ShowObject(AniRootSelName,isSelect)
	CS.ShowObject(AniRootUIText,not isSelect)



	self:SetWndClick(AniRoot,function ()
		self:OnClickSeason(itemdata.season)
	end)
end

function UISuWorship:OnClickWorship()
	if not self:CanWorship() then
		return
	end

	local isLiked = gModelSimuFight:IsAdmired()
	if isLiked then
		local str =ccClientText(25191)-- "今日已膜拜"
		GF.ShowMessage(str)
		return
	end

	gModelSimuFight:OnSimulateTopLikeReq()
end

function UISuWorship:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnArea,function () self:ShowOptionList(2) end)
	self:SetWndClick(self.mBtnGroup,function () self:OnClickServerGroup() end)
	self:SetWndClick(self.mBtnSeason,function () self:ShowOptionList(1) end)
	self:SetWndClick(self.mBtnWorship,function () self:OnClickWorship() end)
	self:SetWndClick(self.mBtnCurSeason,function () self:OnClickCurSeason() end)
	self:SetWndClick(self.mLeft,function () self:OnChangeSeason(-1) end)
	self:SetWndClick(self.mRight,function () self:OnChangeSeason(1) end)
	self:SetWndClick(self.mOptionBg,function ()
		CS.ShowObject(self.mOptionBg,false)
		local uiList = self:GetUIScroll("optionList")
		if not uiList then
			return
		end
		local uiCom = uiList:GetList()
		uiCom:RemoveAll()
		uiCom:ResetList()

	end)

end

------------------------------------------------------------------
return UISuWorship


