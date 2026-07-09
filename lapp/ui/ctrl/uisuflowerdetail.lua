---
--- Created by Administrator.
--- DateTime: 2023/10/5 10:44:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuFlowerDetail:LWnd
local UISuFlowerDetail = LxWndClass("UISuFlowerDetail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuFlowerDetail:UISuFlowerDetail()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuFlowerDetail:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuFlowerDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuFlowerDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()
	self:InitUIEvent()
	self:SetStaticContent()
	self:OnWndRefresh()
end

function UISuFlowerDetail:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootTitle = self:FindWndTrans(AniRoot,"title")
	local AniRootPlayer_1 = self:FindWndTrans(AniRoot,"player_1")
	--local player_1HeadRoot = self:FindWndTrans(AniRootPlayer_1,"headRoot")
	--local player_1Name = self:FindWndTrans(AniRootPlayer_1,"name")
	--local player_1Server = self:FindWndTrans(AniRootPlayer_1,"server")
	local player_1Tag = self:FindWndTrans(AniRootPlayer_1,"tag")
	local player_1Flower = self:FindWndTrans(AniRootPlayer_1,"flower")
	local AniRootVs = self:FindWndTrans(AniRoot,"vs")
	local AniRootPlayer_2 = self:FindWndTrans(AniRoot,"player_2")
	--local player_2HeadRoot = self:FindWndTrans(AniRootPlayer_2,"headRoot")
	--local player_2Name = self:FindWndTrans(AniRootPlayer_2,"name")
	--local player_2Server = self:FindWndTrans(AniRootPlayer_2,"server")
	local player_2Tag = self:FindWndTrans(AniRootPlayer_2,"tag")
	local player_2Flower = self:FindWndTrans(AniRootPlayer_2,"flower")
	local AniRootVertical = self:FindWndTrans(AniRoot,"vertical")
	local verticalLayout_1 = self:FindWndTrans(AniRootVertical,"layout_1")
	local layout_1Intro = self:FindWndTrans(verticalLayout_1,"intro")
	local layout_1Icon = self:FindWndTrans(verticalLayout_1,"icon")
	local layout_1Num = self:FindWndTrans(verticalLayout_1,"num")
	local verticalLayout_3 = self:FindWndTrans(AniRootVertical,"layout_3")
	local layout_3Intro = self:FindWndTrans(verticalLayout_3,"intro")
	local layout_3Icon = self:FindWndTrans(verticalLayout_3,"icon")
	local layout_3Num = self:FindWndTrans(verticalLayout_3,"num")
	local verticalLayout_2 = self:FindWndTrans(AniRootVertical,"layout_2")
	local layout_2Intro = self:FindWndTrans(verticalLayout_2,"intro")
	local AniRootGameInfo = self:FindWndTrans(AniRoot,"gameInfo")



	self:SetPlayerInfo(AniRootPlayer_1,itemdata.attackInfo)
	self:SetPlayerInfo(AniRootPlayer_2,itemdata.defenceInfo)

	local isGroup = false
	local str = nil
	if itemdata.type == 1 then
		local roundStr = self._roundStrList[itemdata.round]
		local groupStr = self._groupStrList[itemdata.groupIndex]
		local format = ccClientText(25127) --
		str = string.replace(format,roundStr,groupStr)

		CS.ShowObject(player_1Tag,itemdata.result == 1)
		CS.ShowObject(player_2Tag,itemdata.result == 2)
		isGroup = true
		local isLeft = itemdata.targetId == itemdata.attackInfo.playerId
		CS.ShowObject(player_1Flower,isLeft)
		CS.ShowObject(player_2Flower,not isLeft)
	elseif itemdata.type == 2 then
		str = ccClientText(25125) --"冠军献花"
		CS.ShowObject(player_1Tag,false)
		CS.ShowObject(player_1Flower,false)
	end

	CS.ShowObject(AniRootPlayer_2,isGroup)
	CS.ShowObject(AniRootVs,isGroup)


	self:SetWndText(AniRootTitle,str)
	self:InitTextSizeWithLanguage(AniRootTitle, -2)


	self:SetWndText(layout_1Intro,ccClientText(25128))
	local flowerNum = gModelSimuFight:GetFlowerNum(itemdata.type,itemdata.groupId)
	self:SetWndText(layout_1Num,flowerNum)

	local isEnd = itemdata.result ~= 0
	local gameInfo = nil
	if isEnd then
		gameInfo = ccClientText(25130)--"比赛已结束"
	else
		gameInfo = ccClientText(25129)--"比赛尚未结束"
	end

	self:SetWndText(AniRootGameInfo,gameInfo)
	self:InitTextSizeWithLanguage(AniRootGameInfo, -2)

	CS.ShowObject(verticalLayout_2,isEnd)
	CS.ShowObject(verticalLayout_3,isEnd)


	if isEnd then
		local reward= LxDataHelper.ParseItem_3(itemdata.reward)
		if reward then
			self:SetWndText(layout_3Intro,ccClientText(25131))
			self:SetWndText(layout_3Num,reward.itemNum)
			local iconPath = gModelItem:GetItemImgByRefId(reward.itemId)
			self:SetWndEasyImage(layout_3Icon,iconPath)
		end



		if not isGroup then
			str = string.replace(ccClientText(25132),itemdata.result)
			self:SetWndText(layout_2Intro,str)
		end
	end

	CS.ShowObject(layout_2Intro,not isGroup and isEnd)


	self:CheckReqNext(itempos)
end

function UISuFlowerDetail:OnClickType(type)
	if self._curType == type then
		return
	end

	self._curType = type

	self._page = 1
	self:RefreshBtnState()
	self:ReqData()
end

function UISuFlowerDetail:InitData()
	self._groupStrList =
	{
	 	"A", "B", "C", "D", "E", "F", "G", "H",
	}

	self._roundStrList =
	{
		ccClientText(25115),
		ccClientText(25116),
		ccClientText(25117),
		ccClientText(25118),
		ccClientText(25119),
		ccClientText(25120),
		ccClientText(25121),

	}
end

function UISuFlowerDetail:OnWndRefresh()
	self._page = 1
	self._curType = 1
	self._curGroup = 1

	self:RefreshBtnState()
	self:ReqData()
end

function UISuFlowerDetail:OnClickGroup(group)
	if self._curGroup == group then
		return
	end

	self._curGroup = group

	self:RefreshBtnState()
	self._page = 1
	self:ReqData()
end

function UISuFlowerDetail:ReqData()

	local type = self._curType
	local groupType = self._curGroup
	local page = self._page
	local pageSize = 25

	gModelSimuFight:OnSimulateFlowerMessageReq(type,groupType,page,pageSize)
end

function UISuFlowerDetail:InitEvent()
	self:WndEventRecv(EventNames.ON_FLOWER_DETAIL_RET,function (type,groupType)
		if type ~= self._curType or groupType ~= self._curGroup then
			return
		end

		self._isReqing = false
		self:RefreshList()
	end)
end

function UISuFlowerDetail:OnClickRank()
	GF.OpenWnd("UIRkPop",{refId =ModelRank.RANK_1802})

end

function UISuFlowerDetail:SetPlayerInfo(item,playerData)

	local headRoot = self:FindWndTrans(item,"headRoot")
	local name = self:FindWndTrans(item,"name")
	local server = self:FindWndTrans(item,"server")
	--local tag = self:FindWndTrans(item,"tag")

	local headTran = self:FindWndTrans(headRoot,"HeadIcon")
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

	self:SetWndText(name,playerData.name)
	self:SetWndText(server,string.format("[%s]",playerData.serverName))
end

function UISuFlowerDetail:CheckReqNext(itempos)
	if self._isReqing then
		return
	end
	local total = #self._flowerDataList
	local assumeTotal = self._page * 25
	if total < assumeTotal then
		return
	end

	if itempos > total - 3 then
		self._page = self._page + 1
		self:ReqData()
	end
end

function UISuFlowerDetail:InitUIEvent()
	self:SetWndClick(self.mBtnPeak,function () self:OnClickGroup(1) end)
	self:SetWndClick(self.mBtnElite,function () self:OnClickGroup(2) end)

	self:SetWndClick(self.mBtnGroup,function () self:OnClickType(1) end)
	self:SetWndClick(self.mBtnChampion,function () self:OnClickType(2) end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnRank,function () self:OnClickRank() end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)
end

function UISuFlowerDetail:RefreshList()


	local dataList = gModelSimuFight:GetFlowerDetailList(self._curType,self._curGroup)

	local totalNum = 0
	for k,v in ipairs(dataList) do
		local isEnd = v.result ~= 0
		if isEnd then
			local reward= LxDataHelper.ParseItem_3(v.reward)
			if reward then
				totalNum =totalNum + reward.itemNum
			end
		end
	end

	local str =ccClientText(25295) --"累计获得圣殿水晶：%s"

	self:SetWndText(self.mIntro_1,string.replace(str,totalNum))

	self._flowerDataList = dataList

	local isEmpty =  #dataList == 0

	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mItemList,not isEmpty)
	if isEmpty then
		return
	end

	local uiList = self:FindUIScroll("uiList")
	if not uiList then
		uiList = self:GetUIScroll("uiList")
		local para =
		{
			root = self.mItemList,
			dataList = dataList,
			setFunc = function (...) self:OnDrawItem(...) end,
			type = UIItemList.SUPER,
		}

		uiList:InitListData(para)
	else
		uiList:RefreshList(dataList)
	end

	uiList:DrawAllItems(false)
end

function UISuFlowerDetail:RefreshBtnState()
	-- local state = self._curType == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnGroup,self._curType ~= 1)
	-- self:SetWndTabTextLine(self.mBtnGroup, 20)
	-- local state = self._curType == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnChampion,self._curType ~= 2)
	-- self:SetWndTabTextLine(self.mBtnChampion, 20)
	local state = self._curGroup == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnPeak,state)
	self:SetWndTabTextLine(self.mBtnPeak, 20)
	local state = self._curGroup == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnElite,state)
	self:SetWndTabTextLine(self.mBtnElite, 20)
end

function UISuFlowerDetail:SetStaticContent()
	--local str = "献花详情"
	--self:SetWndText(self.mTitle,str)
	local str =ccClientText(25122) --"献花榜结算时间：总决赛结束"
	self:SetWndText(self.mIntro,str)
	--str =ccClientText(25123) -- "已献花的比赛结束后，自动发放奖励"
	--self:SetWndText(self.mIntro_1,str)

	str = ccClientText(25124) --"小组献花"
	self:SetWndButtonText(self.mBtnGroup,str)
	str =ccClientText(25125) -- "冠军献花"
	self:SetWndButtonText(self.mBtnChampion,str)
	str = ccLngText(gModelSimuFight:GetPara("groupName1"))
	self:SetWndTabText(self.mBtnPeak,str)
	self:SetWndTabText(self.mBtnPeak,str, -6)
	str = ccLngText(gModelSimuFight:GetPara("groupName2"))
	self:SetWndTabText(self.mBtnElite,str)
	self:SetWndTabText(self.mBtnElite,str, -6)
	str = ccClientText(25126) --"排名"
	self:SetTextTile(self.mBtnRank,str)

	local data = {
		refId = 25005,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	--self:InitTextLineWithLanguage(self.mIntro,-40)
	--self:InitTextLineWithLanguage(self.mIntro_1,-40)

end


------------------------------------------------------------------
return UISuFlowerDetail


