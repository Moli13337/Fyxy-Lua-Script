---
--- Created by Administrator.
--- DateTime: 2023/10/5 17:11:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuRk:LWnd
local UISuRk = LxWndClass("UISuRk", LWnd)
local typeofLayoutElement = typeof(UnityEngine.UI.LayoutElement)

local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuRk:UISuRk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuRk:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuRk:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuRk:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()
	self:InitEvent()

	self:OnWndRefresh()

end

function UISuRk:OnClickCurSeason()
	self._curGroup = gModelSimuFight:GetCurGroupId()
	self._curSeason = gModelSimuFight:GetCurSeason()
	local history = gModelSimuFight:GetRankHistory()
	self._curArea = history[self._curSeason] or 1
	self:ResetPage()

	gModelSimuFight:OnSimulateGroupReq(self._curSeason)
	self:ReqData()
end


function UISuRk:ReqData()

	self:RefreshChangeBtnShow()
	self:RefreshBtnCurShow()
	self:RefreshTitle()

	local group = self._curGroup
	local groupId = self._curArea
	local season = self._curSeason
	local page = self._page
	local pageSize = 16
	gModelSimuFight:OnSimulateRankReq(group,season,page,pageSize,groupId)
end

function UISuRk:OnDrawSeason(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootSelect = self:FindWndTrans(AniRoot,"select")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootSelName = self:FindWndTrans(AniRoot,"selName")


	local isSelect = self._curSeason == itemdata.season
	CS.ShowObject(AniRootSelect,isSelect)

	self:SetWndText(AniRootUIText,itemdata.name)
	self:InitTextSizeWithLanguage(AniRootUIText, -4)
	self:SetWndText(AniRootSelName,itemdata.name)
	self:InitTextSizeWithLanguage(AniRootSelName, -4)
	CS.ShowObject(AniRootUIText,not isSelect)
	CS.ShowObject(AniRootSelName,isSelect)


	self:SetWndClick(AniRoot,function ()
		self:OnClickSeason(itemdata)
	end)
end

function UISuRk:OnClickRankReward()
	GF.OpenWnd("UISuRkAward",{groupType = self._curGroup})
end

function UISuRk:InitUIEvent()
	self:SetWndClick(self.mBtnPeak,function () self:OnClickGroup(1) end)
	self:SetWndClick(self.mBtnElite,function () self:OnClickGroup(2) end)
	self:SetWndClick(self.mBtnCurSeason,function () self:OnClickCurSeason() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnArea,function () self:ShowOptionList(2) end)
	self:SetWndClick(self.mBtnSeason,function () self:ShowOptionList(1) end)
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
	self:SetWndClick(self.mBtnGroup,function () self:OnClickServerGroup() end)
	self:SetWndClick(self.mBtnReward,function () self:OnClickRankReward() end)

	self:SetWndClick(self.mLeft,function () self:ChangeSeason(-1) end)
	self:SetWndClick(self.mRight,function () self:ChangeSeason(1) end)

end

function UISuRk:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItemOne = self:FindWndTrans(AniRoot,"itemOne")
	local AniRootItemTwo = self:FindWndTrans(AniRoot,"itemTwo")

	CS.ShowObject(AniRootItemOne,itemdata.type == 1)
	CS.ShowObject(AniRootItemTwo,itemdata.type == 2)

	local height = 242
	local root = AniRootItemOne
	if itemdata.type == 2 then
		root = AniRootItemTwo
		height = 213
	end

	LxUiHelper.SetSizeWithCurAnchor(item,1,height)

	local layoutElement = AniRoot.transform:GetComponent(typeofLayoutElement)
	if layoutElement then
		layoutElement.preferredHeight = height
	end


	for k,v in ipairs(itemdata.dataList) do
		local name = "item_"..k
		local itemRoot = self:FindWndTrans(root,name)
		self:SetPlayerItem(itemRoot,v)
	end

	self:CheckReqNext(itempos)


end

function UISuRk:RefreshBtnCurShow()
	local isCur =  self._curSeason == gModelSimuFight:GetCurSeason()
	CS.ShowObject(self.mBtnCurSeason,not isCur)
end



function UISuRk:SetFirstItem(item,itemdata)
	local Image = self:FindWndTrans(item,"Image")
	local title = self:FindWndTrans(item,"title")
	local depart = self:FindWndTrans(item,"depart")
	local departName = self:FindWndTrans(depart,"name")
	local departSever = self:FindWndTrans(depart,"sever")
	local departPowerBg = self:FindWndTrans(depart,"PowerBg")
	local PowerBgImage = self:FindWndTrans(departPowerBg,"Image")
	local PowerBgPowerText = self:FindWndTrans(departPowerBg,"PowerText")
	local emptyTip = self:FindWndTrans(item,"emptyTip")



	CS.ShowObject(depart,not itemdata.isEmpty)
	CS.ShowObject(emptyTip,itemdata.isEmpty)
	self:SetWndText(title,ccClientText(25164))
	if itemdata.isEmpty then
		self:SetWndText(emptyTip,ccClientText(25203))
		return
	end
	local headTran = self:FindWndTrans(depart,"HeadIcon")
	local playerData = itemdata.info
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


	self:SetWndText(departName,playerData.name)
	local serverName = string.format("[%s]",playerData.serverName)
	self:SetWndText(departSever,serverName)
	local powerStr = LUtil.GetPowerNumberCoversion(playerData.power)
	self:SetWndText(PowerBgPowerText,powerStr)
end

function UISuRk:SetStaticContent()
	local str = ccClientText(25159) -- "查看赛季"
	self:SetTextTile(self.mBtnSeason,str,-30, -2)
	str = ccClientText(25161) --"查看赛区"
	self:SetTextTile(self.mBtnArea,str,-30, -2)
	str = ccClientText(25162) --"分组"
	self:SetTextTile(self.mBtnGroup,str,-30, -2)
	str = ccClientText(25160) --"奖励"
	self:SetTextTile(self.mBtnReward,str,-30, -2)
	str = ccClientText(25163) --"当前赛季"
	self:SetTextTile(self.mBtnCurSeason,str)
	self:SetWndText(self.mTxtReturn,ccClientText(30205))

	str = ccLngText(gModelSimuFight:GetPara("groupName1"))
	self:SetWndButtonText(self.mBtnPeak,str)
	str = ccLngText(gModelSimuFight:GetPara("groupName2"))
	self:SetWndButtonText(self.mBtnElite,str)

	if gLGameLanguage:IsJapanRegion() then
		local layoutGroup = self.mLayout:GetComponent(typeVerticalLayoutGroup)
		if layoutGroup then
			layoutGroup.spacing = 25
		end
	end
end

function UISuRk:RefreshContent()
	local dataList = gModelSimuFight:GetRankDataList()
	local cnt = #dataList

	local limit = self:GetShowRankNum(self._curSeason)
	for k,v in ipairs(dataList) do
		v.isEmpty = v.rank < limit
	end
	if cnt == 0 then
		dataList = {}
		for k=1,64 do
			local data =
			{
				isEmpty = true,
				rank = k
			}

			table.insert(dataList,data)
		end
	end

	cnt = #dataList


	local first = dataList[1]

	local listDataList = {}
	local tempList = {}
	for k= 2,4 do
		table.insert(tempList,dataList[k])
	end

	local data =
	{
		type = 1,
		dataList = tempList
	}
	table.insert(listDataList,data)

	local dataTwo = nil
	for k = 5,cnt do
		if k%4 == 1 then
			if dataTwo then
				table.insert(listDataList,dataTwo)
			end

			dataTwo =
			{
				type = 2,
				dataList = {}
			}
		end

		table.insert(dataTwo.dataList,dataList[k])
	end
	table.insert(listDataList,dataTwo)

	self._total = cnt

	self:SetFirstItem(self.mPlayer_1,first)

	local uiList = self:FindUIScroll("rankList")
	if not uiList then
		uiList = self:GetUIScroll("rankList")
		local para =
		{
			root = self.mRankList,
			setFunc = function(...) self:OnDrawItem(...) end,
			type = UIItemList.SUPER,
			dataList = listDataList,
		}
		uiList:InitListData(para)
	else
		uiList:RefreshList(listDataList)
	end



end

function UISuRk:OnClickArea(itemdata)
	if self._curArea == itemdata.area then
		return
	end

	self._curArea = itemdata.area
	local list = self:FindUIScroll("optionList")
	if list then
		list:DrawAllItems(false)
	end

	self:ResetPage()
	gModelSimuFight:OnSimulateGroupReq(self._curSeason)
	self:ReqData()
end

function UISuRk:InitEvent()
	self:WndEventRecv(EventNames.ON_SIMULATE_RANK_RET,function (group,season,groupId)
		if group~= self._curGroup or self._curSeason ~= season or self._curArea ~= groupId then
			return
		end

		self:RefreshContent()
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateGroupResp,function (pb)
		self._seasonInfo = pb
	end)
end

function UISuRk:OnClickSeason(itemdata)
	if self._curSeason == itemdata.season then
		return
	end

	self._curSeason = itemdata.season
	local history = gModelSimuFight:GetRankHistory()
	self._curArea = history[self._curSeason] or 1

	local list = self:FindUIScroll("optionList")
	if list then
		list:DrawAllItems(false)
	end
	gModelSimuFight:OnSimulateGroupReq(self._curSeason)
	self:ResetPage()
	self:ReqData()
end

function UISuRk:RefreshChangeBtnShow()
	local maxSeason = gModelSimuFight:GetMaxSeason()
	local hasMore = maxSeason >1

	local showLeft = self._curSeason >1
	local showRight = self._curSeason < maxSeason

	CS.ShowObject(self.mLeft,hasMore and showLeft)
	CS.ShowObject(self.mRight,hasMore and showRight)
end

function UISuRk:SetPlayerItem(item,itemdata)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootRank = self:FindWndTrans(AniRoot,"rank")
	local AniRootDepart = self:FindWndTrans(AniRoot,"depart")
	local departName = self:FindWndTrans(AniRootDepart,"name")
	local departSever = self:FindWndTrans(AniRootDepart,"sever")
	local departPower = self:FindWndTrans(AniRootDepart,"power")
	local AniRootEmpty = self:FindWndTrans(AniRoot,"empty")
	local emptyImage = self:FindWndTrans(AniRootEmpty,"Image")
	local emptyUIText = self:FindWndTrans(AniRootEmpty,"UIText")
	local emptyMask = self:FindWndTrans(AniRootEmpty,"mask")


	CS.ShowObject(AniRootDepart,not itemdata.isEmpty)
	CS.ShowObject(AniRootEmpty,itemdata.isEmpty)
	self:SetWndText(AniRootRank,itemdata.rank)
	if itemdata.isEmpty then
		self:SetWndText(emptyUIText,ccClientText(25276))
		self:InitTextSizeWithLanguage(emptyUIText, -6)
		return
	end

	local headTran = self:FindWndTrans(AniRootDepart,"HeadIcon")
	local playerData = itemdata.info
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

	self:SetWndText(departName,playerData.name)
	local serverName = string.format("[%s]",playerData.serverName)
	self:SetWndText(departSever,serverName)
	--local powerStr = string.replace(ccClientText(25193) ,LUtil.NumberCoversion(playerData.power))
	self:SetWndText(departPower,LUtil.NumberCoversion(playerData.power))


end


function UISuRk:GetShowRankNum(seasonId)
	local curSeason = gModelSimuFight:GetCurSeason()
	if curSeason ~= seasonId then
		return 1
	end
	local limit = gModelSimuFight:GetRankShowLimit()

	return limit
end

function UISuRk:ResetPage()
	self._page = 1

	local list = self:FindUIScroll("rankList")
	if list then
		list:RefreshList({},false,true)
	end
end

function UISuRk:OnDrawArea(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootSelect = self:FindWndTrans(AniRoot,"select")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootSelName = self:FindWndTrans(AniRoot,"selName")


	self:SetWndText(AniRootUIText,itemdata.name)
	self:InitTextSizeWithLanguage(AniRootUIText, -4)
	self:SetWndText(AniRootSelName,itemdata.name)
	self:InitTextSizeWithLanguage(AniRootSelName, -4)
	local isSel = self._curArea == itemdata.area
	CS.ShowObject(AniRootSelect,isSel)
	CS.ShowObject(AniRootSelName,isSel)
	CS.ShowObject(AniRootUIText,not isSel)


	self:SetWndClick(AniRoot,function ()
		self:OnClickArea(itemdata)
	end)
end

function UISuRk:OnClickGroup(group)
	if self._curGroup == group then
		return
	end

	self._curGroup = group
	self:ResetPage()

	self:RefreshBtnState()
	self:ReqData()
end

function UISuRk:ChangeSeason(index)
	local maxSeason = gModelSimuFight:GetMaxSeason()
	if maxSeason <=1 then
		return
	end

	local next = self._curSeason + index
	if next >maxSeason then
		return
	elseif next <1 then
		return
	end

	local history = gModelSimuFight:GetRankHistory()
	local area = history[next] or 1
	self._curSeason = next
	self._curArea = area
	gModelSimuFight:OnSimulateGroupReq(self._curSeason)
	self:ResetPage()

	self:ReqData()
end

function UISuRk:ShowOptionList(type)
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
		if not self._seasonInfo then
			return
		end

		for k,v in ipairs(self._seasonInfo.group) do
			local data =
			{
				area = v.group,
				name = string.replace(ccClientText(25166) ,v.group)
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

	-- self.mOptionList.position = root.position
	-- self.mOptionList.localPosition = self.mOptionList.localPosition + Vector3.New(-100,-100,0)

	CS.ShowObject(self.mOptionBg,true)
	local uiList = self:GetUIScroll("optionList")
	uiList:InitListData(para)
	local pos = curPos or 1
	uiList:MoveToPos(pos)
end

function UISuRk:RefreshBtnState()
	-- local state = self._curGroup == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnPeak,self._curGroup ~= 1)
	-- local state = self._curGroup == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnElite,self._curGroup ~= 2)
end

function UISuRk:CheckReqNext(itempos)
	printInfoN("itempos "..itempos)
	if self._isReqing then
		return
	end

	local assumeTotal = self._page * 16
	if self._total < assumeTotal then
		return
	end

	local curPos = itempos * 4

	if self._total - curPos >= 4 then
		return
	end

	self._page = self._page + 1


	self:ReqData()

end

function UISuRk:OnWndRefresh()

	self._curGroup = 1
	self._curArea = gModelSimuFight:GetCurGroupId()
	self._curSeason = gModelSimuFight:GetCurSeason()
	self._page = 1

	self:RefreshBtnState()
	gModelSimuFight:OnSimulateGroupReq(self._curSeason)

	self:RefreshChangeBtnShow()

	self:RefreshBtnCurShow()

	self:ReqData()
end

function UISuRk:RefreshTitle()
	local str = ccClientText(25167) --
	str= string.replace(str,self._curSeason,self._curArea)
	self:SetWndText(self.mSeasonInfo,str)
	self:InitTextSizeWithLanguage(self.mSeasonInfo, -4)
end

function UISuRk:OnClickServerGroup()
	gModelSimuFight:ShowServerGroup(self._seasonInfo,self._curArea)
end



------------------------------------------------------------------
return UISuRk


