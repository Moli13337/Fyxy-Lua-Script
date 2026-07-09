---
--- Created by Administrator.
--- DateTime: 2023/10/10 16:38:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuNews:LWnd
local UISuNews = LxWndClass("UISuNews", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuNews:UISuNews()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuNews:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuNews:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuNews:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitUIEvent()
	self:SetStaticContent()
	self:OnWndRefresh()
end

function UISuNews:SetPlayerItem(item,itemdata)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	--local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootRankIcon = self:FindWndTrans(AniRoot,"rankIcon")
	local AniRootRankBg = self:FindWndTrans(AniRoot,"rankBg")
	local AniRootRanktext = self:FindWndTrans(AniRoot,"ranktext")
	local AniRootHeadRoot = self:FindWndTrans(AniRoot,"headRoot")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootPower = self:FindWndTrans(AniRoot,"power")


	local headTran = self:FindWndTrans(AniRootHeadRoot,"HeadIcon")
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

	local showIcon = itemdata.rank<=3
	CS.ShowObject(AniRootRankIcon,showIcon)
	if showIcon then
		local iconPath = gModelGeneral:GetRankIcon(itemdata.rank)
		self:SetWndEasyImage(AniRootRankIcon,iconPath)
	else
		self:SetWndText(AniRootRanktext,itemdata.rank)
	end

	CS.ShowObject(AniRootRankIcon,showIcon)
	CS.ShowObject(AniRootRanktext,not showIcon)
	CS.ShowObject(AniRootRankBg,not showIcon)

	local nameStr = string.replace(ccClientText(25158),playerData.serverName,playerData.name)
	self:SetWndText(AniRootName,nameStr)
	local powerStr = string.replace(ccClientText(25157) ,LUtil.NumberCoversion(playerData.power))
	self:SetWndText(AniRootPower,powerStr)
end

function UISuNews:ShowPart_2(pageData)
	local dataList = {}
	for k,v in ipairs(pageData.battleInfos) do
		local battleInfo = StructSimulateBattleInfo:New()
		battleInfo:CreateByPb(v)

		table.insert(dataList,battleInfo)
	end

    self:SetWndText(self.mSubTitle,ccClientText(25155))


    local battleList = self:FindUIScroll("battleList")
	if not battleList then
		battleList = self:GetUIScroll("battleList")
		battleList:Create(self.mBattleList,dataList,function (...) self:OnDrawBattle(...) end,UIItemList.SUPER)
	else
		battleList:RefreshList(dataList)
	end

	battleList:DrawAllItems(false)
end

function UISuNews:SetPlayerContent(item,playerData,isWin)
	local name = self:FindWndTrans(item,"name")
	local rank = self:FindWndTrans(item,"rank")
	local tag = self:FindWndTrans(item,"tag")


	local headTran = self:FindWndTrans(item,"HeadIcon")
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

	CS.ShowObject(tag,isWin)
	self:CreateHeadIconImpl(playerInfo)

	local nameStr = string.replace(ccClientText(25286) ,playerData.serverName,playerData.name)
	self:SetWndText(name,nameStr)
	local str = string.replace(ccClientText(25292),playerData.rank)
	self:SetWndText(rank,str)

end

function UISuNews:OnDrawStar(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBg = self:FindWndTrans(AniRoot,"bg")
	local AniRootOn = self:FindWndTrans(AniRoot,"on")

	local isShow = itempos == self._curPage
	CS.ShowObject(AniRootOn,isShow)
end

function UISuNews:RefreshGroupBtnShow()
	local state = self._curGroupType == ModelSimuFight.GROUP_PINNACLE and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnPeak,state)
	local state = self._curGroupType == ModelSimuFight.GROUP_ELITE and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnElite,state)
end

function UISuNews:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateRaceNewsResp,function (pb)
		self:OnSimulateRaceNewsResp(pb)
	end)

	self:WndEventRecv(EventNames.ON_SIMULATE_RANK_RET,function (group,season,groupId)
		if group~= self._curGroupType or self._season ~= season or self._curGroup ~= groupId then
			return
		end

		self:RefreshContent()
	end)
end

function UISuNews:OnDrawItem(list,item,itemdata,itempos)


	self:SetPlayerItem(item,itemdata)



	self:CheckReqNext(itempos)


end

function UISuNews:SetStaticContent()
	--local str = "赛事快讯"
	--self:SetWndText(self.mTitle,str)

	local str =ccClientText(25114) -- "详情"
	self:SetTextTile(self.mBtnDetail,str)

	str = ccLngText(gModelSimuFight:GetPara("groupName1"))
	self:SetWndTabText(self.mBtnPeak,str, -6, 20)
	str = ccLngText(gModelSimuFight:GetPara("groupName2"))
	self:SetWndTabText(self.mBtnElite,str, -6, 20)
end

function UISuNews:OnSimulateRaceNewsResp(pb)
	if self._curGroupType ~= pb.group then
		return
	end

	self._news = pb

	local pageDataList = {}

	local data =
	{
		type = 1,
		info = pb.info,
		battleInfo = pb.battleInfo,
		rank = pb.rank,
		battleCount = pb.battleCount,
		score = pb.score,
        group = 1,
	}

	table.insert(pageDataList,data)

	if pb.otherInfo and tonumber(pb.otherInfo.playerId) > 0 then
		data =
		{
			type = 1,
			info = pb.otherInfo,
			battleInfo = pb.otherBattleInfo,
			rank = pb.otherRank,
            group = 2,
        }

		table.insert(pageDataList,data)

	end

	if #pb.battleInfos > 0 then
		data =
		{
			type = 2,
			battleInfos = pb.battleInfos
		}

		table.insert(pageDataList,data)
	end

	if pb.status == ModelSimuFight.SCHEDULE_GROUP_BATTLE  then
		data =
		{
			type = 3,
		}

		table.insert(pageDataList,data)
	end

	self._pageDataList = pageDataList

	local cnt = #self._pageDataList
	if self._curPage > cnt then
		self._curPage = 1
	end


	self:RefreshPart()

end


function UISuNews:RefreshPart()
	self:RefreshChangeBtnShow()

	self:ShowStartList()
	local pageData = self._pageDataList[self._curPage]


	local type = pageData.type

    CS.ShowObject(self.mPart_1,type == 1)
    CS.ShowObject(self.mPart_2,type == 2)
    CS.ShowObject(self.mPart_3,type == 3)

	self:ShowTitle()

    if type == 1 then
		self:ShowPart_1(pageData)
	elseif type == 2 then
		self:ShowPart_2(pageData)
	elseif type == 3 then
		self:ShowPart_3()
	end
end

function UISuNews:OnWndRefresh()
	self._curPage = 1
	self._curGroupType = 1

	self:RefreshGroupBtnShow()
	self:ReqData()
end




function UISuNews:RefreshContent()
	local dataList = gModelSimuFight:GetRankDataList()
	local cnt = #dataList
	if cnt == 0 then
		return
	end

	local first = dataList[1]

	local tempList = {}
	for k= 2,cnt do
		table.insert(tempList,dataList[k])
	end

	self._total = cnt

	self:SetChampionItem(first.info)

	local uiList = self:FindUIScroll("rankList")
	if not uiList then
		uiList = self:GetUIScroll("rankList")
		uiList:Create(self.mRankList,tempList,function (...) self:OnDrawItem(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(tempList)
	end

	uiList:DrawAllItems(false)

end


function UISuNews:ShowPart_3()
	self._curGroup = gModelSimuFight:GetCurGroupId()
	self._season = gModelSimuFight:GetCurSeason()
	self._page = 1

    self:SetWndText(self.mSubTitle,ccClientText(25156))

    self:ReqRankData()
end

function UISuNews:OnClickGroup(index)

	if self._curGroupType == index then
		return
	end
	self._curGroupType = index


	self:RefreshGroupBtnShow()

	--self:RefreshPart()

	self:ReqData()

end

function UISuNews:ShowTitle()
	local status = self._news.status
	local round = self._news.round
	local scheduleName = gModelSimuFight:GetScheduleName(status)

    local strFormat = ccClientText(25149)
    if status >= ModelSimuFight.SCHEDULE_GROUP_WARM_UP then
        strFormat =ccClientText(25301) --"昨日比赛：%s"
    end
	local str = string.replace(strFormat,scheduleName,round)

	self:SetWndText(self.mStageInfo,str)
end

function UISuNews:SetChampionItem(playerData)
	local item = self.mChampion
	--local Image = self:FindWndTrans(item,"Image")
	local name = self:FindWndTrans(item,"name")
	local power = self:FindWndTrans(item,"power")
	local layout = self:FindWndTrans(item,"layout")
	--local layoutImage = self:FindWndTrans(layout,"Image")
	local layoutChamTitle = self:FindWndTrans(layout,"chamTitle")


	local headTran = self:FindWndTrans(item,"HeadIcon")
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


	local nameStr = string.replace(ccClientText(25158),playerData.serverName,playerData.name)
	self:SetWndText(name,nameStr)
	local powerStr = string.replace(ccClientText(25157) ,LUtil.NumberCoversion(playerData.power))
	self:SetWndText(power,powerStr)
	local groupName = nil
	if self._curGroupType == 1 then
		groupName = ccLngText(gModelSimuFight:GetPara("groupName1"))
	else
		groupName = ccLngText(gModelSimuFight:GetPara("groupName2"))
	end
	local str =string.replace(ccClientText(25282),groupName)
	self:SetWndText(layoutChamTitle,str)
end

function UISuNews:OnDrawBattle(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootLeftPlayer = self:FindWndTrans(AniRoot,"leftPlayer")

	local AniRootRightPlayer = self:FindWndTrans(AniRoot,"rightPlayer")

	local AniRootBtnDetail = self:FindWndTrans(AniRoot,"btnDetail")
	--local btnDetailImage = self:FindWndTrans(AniRootBtnDetail,"Image")
	local btnDetailUIText = self:FindWndTrans(AniRootBtnDetail,"UIText")

	self:SetWndText(btnDetailUIText,ccClientText(25114) )

	local winner = itemdata.winner
	self:SetPlayerContent(AniRootLeftPlayer,itemdata.attack,winner== 1)
	self:SetPlayerContent(AniRootRightPlayer,itemdata.defense,winner == 2)

	self:SetWndClick(AniRootBtnDetail,function()
		GF.OpenWnd("UIFightRecordMulti",{battleInfo = itemdata})
	end)
end


function UISuNews:ShowPart_1(pageData)
	local playerData = pageData.info
	local playerInfo =
	{
		trans = self.mBestPlayer,
		icon = playerData.head,
		headFrame = playerData.headFrame,
		level = playerData.grade,
		func = function()
			gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}

    self:SetWndText(self.mSubTitle,ccClientText(25150))

	self:CreateHeadIconImpl(playerInfo)

	local nameStr = string.replace(ccClientText(25293),playerData.serverName,playerData.name)
	self:SetWndText(self.mName,nameStr)
	local powerStr = string.replace(ccClientText(25151),LUtil.NumberCoversion(math.floor(playerData.power)))
	self:SetWndText(self.mPower,powerStr)

    local status = self._news.status
    local strFormat = ccClientText(25152)
	local str = nil
	if status == ModelSimuFight.SCHEDULE_GROUP_WARM_UP then
		strFormat =ccClientText(25302) --"排名：%s组第一"
		local groupName = gModelSimuFight:GetGroupTag(pageData.group)
		str = string.replace(strFormat,groupName)
	elseif status == ModelSimuFight.SCHEDULE_GROUP_READY then
		local strs = string.split(pageData.battleCount,"=")
		local groupId = strs[2] and tonumber(strs[2])
		local rank = strs[3] and tonumber(strs[3])
		local groupName = gModelSimuFight:GetGroupTag(groupId)
		strFormat =ccClientText(25322)
		str = string.replace(strFormat,groupName,rank)
	else
		str = string.replace(strFormat ,pageData.rank)
	end

	self:SetWndText(self.mRank,str)
	local hideRank = self._news.status == ModelSimuFight.SCHEDULE_GROUP_READY
	CS.ShowObject(self.mRank,not hideRank)

	local scoreStr = ""
	local isHide = not pageData.score or pageData.score <= 0
	if not isHide then
		scoreStr = string.replace(ccClientText(25153),pageData.score)
	end
	self:SetWndText(self.mScore,scoreStr)
	CS.ShowObject(self.mScore,not isHide)

	local infoStr = ""
	local isHide = string.isempty(pageData.battleCount)
	if not isHide then
		local strs = string.split(pageData.battleCount,"=")
		local battleRet = strs[1]
		local tempStr = string.split(battleRet,"_")
		local win = tempStr[1] and tonumber(tempStr[1]) or 0
		local total = tempStr[2] and tonumber(tempStr[2]) or 0
		local fail = total - win
		infoStr = string.replace(ccClientText(25154),win,fail)
	end
	self:SetWndText(self.mBattleInfo,infoStr)
	CS.ShowObject(self.mBattleInfo,not isHide)

	local battleInfo = StructSimulateBattleInfo:New()
	battleInfo:CreateByPb(pageData.battleInfo)

	local winner = battleInfo.winner

	self:SetPlayerContent(self.mLeftPlayer,battleInfo.attack,winner == 1)
	self:SetPlayerContent(self.mRightPlayer,battleInfo.defense,winner == 2)
	local nilAttack = battleInfo.attack.playerId == 0 or string.isempty(battleInfo.attack.playerId)
	local nilDefense = battleInfo.defense.playerId == 0 or string.isempty(battleInfo.defense.playerId)
	CS.ShowObject(self.mLeftPlayer,not nilAttack)
	CS.ShowObject(self.mRightPlayer,not nilDefense)
	CS.ShowObject(self.mBtnDetail_1,not nilDefense and not nilAttack)
	CS.ShowObject(self.mImgPlayer,not nilDefense and not nilAttack)

	self:SetWndClick(self.mBtnDetail_1,function()
		GF.OpenWnd("UIFightRecordMulti",{battleInfo = battleInfo})
	end)


	self:DestroyWndSpineByKey("roleSpine")

	local figure = playerData.figure
	local figureRef = gModelPlayer:GetRoleAdventureImage(figure)
	if figureRef then
		self:CreateWndSpine(self.mRoleRoot,figureRef.spine,"roleSpine")
	end

end

function UISuNews:ShowStartList()
	local list = self:FindUIScroll("starList")
	if not list then
		list = self:GetUIScroll("starList")
		list:Create(self.mTabList,self._pageDataList,function (...)  self:OnDrawStar(...) end)
	else
		list:RefreshList(self._pageDataList)
	end
end

function UISuNews:ReqRankData()
	local groupType = self._curGroupType
	local group = self._curGroup
	local season = self._season
	local page = self._page
	local pageSize = 16
	gModelSimuFight:OnSimulateRankReq(groupType,season,page,pageSize,group)
end

function UISuNews:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnPeak,function ()
		self:OnClickGroup(1)
	end)

	self:SetWndClick(self.mBtnElite,function ()
		self:OnClickGroup(2)
	end)

	self:SetWndClick(self.mLeftBtn,function ()
		self:OnClickChange(-1)
	end)

	self:SetWndClick(self.mRightBtn,function ()
		self:OnClickChange(1)
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end

function UISuNews:RefreshChangeBtnShow()
	local cnt = #self._pageDataList
	local showLeft = self._curPage >1
	local showRight = self._curPage < cnt
	CS.ShowObject(self.mLeftBtn,cnt >1 and showLeft)
	CS.ShowObject(self.mRightBtn,cnt >1 and showRight)
end


function UISuNews:ReqData()
	local group = self._curGroupType
	gModelSimuFight:OnSimulateRaceNewsReq(group)
end

function UISuNews:OnClickChange(index)
	if not self._pageDataList then
		return
	end

	local cnt = #self._pageDataList
	if cnt <= 1 then
		return
	end

	local nextPage = self._curPage + index

	if nextPage >cnt then
		return
	elseif nextPage <=0 then
		return
	end

	self._curPage = nextPage
	self:RefreshPart()
end

function UISuNews:CheckReqNext(itempos)
	if self._isReqing then
		return
	end

	local assumeTotal = self._page * 16
	if self._total < assumeTotal then
		return
	end

	local curPos = 1 + itempos

	if self._total - curPos > 4 then
		return
	end

	self._page = self._page + 1

	self:ReqRankData()

end

------------------------------------------------------------------
return UISuNews


