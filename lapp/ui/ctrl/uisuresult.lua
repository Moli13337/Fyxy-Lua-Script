---
--- Created by Administrator.
--- DateTime: 2023/10/10 17:14:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuResult:LWnd
local UISuResult = LxWndClass("UISuResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuResult:UISuResult()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuResult:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()
	self:InitUIEvent()
	self:SetStaticContent()

	self:OnWndRefresh()

end


function UISuResult:SetStaticContent()
	-- local str =ccClientText(25175)-- "奥兹模拟战"
	-- self:SetWndText(self.mTitle,str)

	for k,v in  pairs(self._subTitles) do
		self:SetWndText(v.root,v.str)
	end

	for k,v in ipairs(self._emptyTips) do
		self:SetWndText(v,ccClientText(25176))
	end

	local data = {
		refId = 25002,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("emptyList")
	emptyList:RefreshUI(data)

	str = ccClientText(10103)
	self:SetWndText(self.mCloseTip,str)

	str =ccClientText(25148) --"分享"
	self:SetWndButtonText(self.mBtnShare,str)

	-- CS.ShowObject(self.mPinyinImage, not gLGameLanguage:IsForeignRegion())
end

function UISuResult:RefreshChangeBtnShow()
	local total = self._history and #self._history or 0
	local isShow = total > 0
	local hideLeft = self._curIndex == 1
	local hideRight = self._curIndex == total
	CS.ShowObject(self.mBtnLeft,isShow and not hideLeft )
	CS.ShowObject(self.mBtnRight,isShow and not hideRight)

end

function UISuResult:InitData()


	self._subTitles =
	{
		[1] =
		{
			root = self.mSubTitle_1,
			str = ccClientText(25174),--"报名分组",
		},
		[2] =
		{
			root = self.mSubTitle_2,
			str = ccClientText(25103),--"突围赛",
		},
		[3] =
		{
			root = self.mSubTitle_3,
			str = ccClientText(25104),--"小组赛",
		},
		[4] =
		{
			root = self.mSubTitle_4,
			str = ccClientText(25106),--"总决赛",
		}
	}

	self._emptyTips =
	{
		self.mEmptyTip,self.mEmptyTip_1,self.mEmptyTip_2
	}


end



function UISuResult:OnSimulateSeasonInfoResp(pb)

	if self._seasonId == 0 then
		self._seasonId = pb.seasonId
	end

	if self._seasonId ~= pb.seasonId then
		return
	end

	self._info = pb.info


	local history = {}
	for k, v in ipairs(pb.history) do
		local strs = string.split(v,"_")
		local _seasonId = tonumber(strs[1])
		local _groupId = tonumber(strs[2])

		if _seasonId and _groupId then
			table.insert(history,{seasonId = _seasonId,groupId = _groupId})
		end
	end

	local isIn = false
	local curSeason = gModelSimuFight:GetCurSeason()
	for k,v in ipairs(history) do
		if curSeason == v.seasonId then
			isIn = true
			break
		end
	end

	if not isIn then
		table.insert(history,{seasonId = curSeason,groupId = 1})
	end

	table.sort(history,function (a,b)
		return a.seasonId < b.seasonId
	end)

	for k,v in ipairs( history) do
		if v.seasonId == self._seasonId then
			self._curIndex = k
			break
		end
	end

	self._history = history

	self:RefreshContent()
end

function UISuResult:RefreshContent()


	self:RefreshChangeBtnShow()
	local info = self._info
	local groupId =info.groupId
	if groupId == 0 then
		groupId = 1
	end
	local str = string.replace(ccClientText(25167),self._seasonId,groupId)
	self:SetWndText(self.mGameSeason,str)

	local isEmpty = false
	local name =nil
	if info.group == 2 then
		name =ccLngText(gModelSimuFight:GetPara("groupName2"))
	elseif info.group == 1 then
		name =ccLngText(gModelSimuFight:GetPara("groupName1"))
	else
		isEmpty = true
	end

	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mContent,not isEmpty)
	CS.ShowObject(self.mBtnShare,not isEmpty)
	if isEmpty then
		return
	end

	self:SetWndText(self.mGroup,name)

	str = ccClientText(25171) --"人数：%s"
	str = string.replace(str,info.groupCount)
	self:SetWndText(self.mNumInfo,str)

	local noResult = tonumber(info.seasonRank) <= 0
	CS.ShowObject(self.mEmptyTip,noResult)
	CS.ShowObject(self.mRank_2,not noResult)
	CS.ShowObject(self.mBattleInfo,not noResult)
	CS.ShowObject(self.mBattleInfo_1,not noResult)

	local bg = self:FindWndTrans(self.mBreakPart,"bg")
	CS.ShowObject(bg,not noResult)
	if not noResult then
		str = ccClientText(25196) --"排名:%s"
		str = string.replace(str,info.seasonRank)
		self:SetWndText(self.mRank_2,str)

		str = ccClientText(25194) --"战绩:%s胜/%s败"
		str = string.replace(str,info.seasonWinCount,info.seasonBattleCount - info.seasonWinCount)
		self:SetWndText(self.mBattleInfo,str)

		str = ccClientText(25172) --"连胜:%s场"
		str= string.replace(str,info.seasonWinAllCount)
		self:SetWndText(self.mBattleInfo_1,str)
	end

	noResult = tonumber(info.groupRank) <= 0
	CS.ShowObject(self.mEmptyTip_1,noResult)
	CS.ShowObject(self.mRank_3,not noResult)
	CS.ShowObject(self.mBattleInfo_3,not noResult)

	local bg = self:FindWndTrans(self.mGroupPart,"bg")
	CS.ShowObject(bg,not noResult)
	if not noResult then
		str =ccClientText(25173) -- "排名:小组第%s"
		local group = gModelSimuFight:GetGroupTag(tonumber(info.groupNum)) or ""
		str = string.replace(str,group,info.groupRank)

		self:SetWndText(self.mRank_3,str)

		str = ccClientText(25194) --"战绩:%s胜/%s败"
		str = string.replace(str,info.groupWinCount,info.groupBattleCount - info.groupWinCount)
		self:SetWndText(self.mBattleInfo_3,str)
	end

	noResult = tonumber(info.rank) <= 0
	CS.ShowObject(self.mEmptyTip_2,noResult)
	CS.ShowObject(self.mRank_4,not noResult)

	local bg = self:FindWndTrans(self.mFinalPart,"bg")
	CS.ShowObject(bg,not noResult)
	if not noResult then
		str = ccClientText(25196) --"排名:%s"
		str = string.replace(str,info.rank)
		self:SetWndText(self.mRank_4,str)
	end

	local isShare = self:GetWndArg("isShare")
	CS.ShowObject(self.mBtnShare,not isShare)


	--CS.ShowObject(self.mBtnLeft,not isShare)
	--CS.ShowObject(self.mBtnRight,not isShare)

	CS.ShowObject(self.mPlayerPart,isShare)
	if not isShare then
		return
	end
	local playerData = self:GetWndArg("playerInfo")

	local headTran = self:FindWndTrans(self.mPlayerPart,"headRoot/HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = playerData.head,
		headFrame = playerData.headFrame,
		level = playerData.level,
		func = function()
			gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)

	local nameStr = string.replace(ccClientText(25287),playerData.serverName,playerData.name)
	self:SetWndText(self.mName,nameStr)
	local powerStr = string.replace(ccClientText(25193),LUtil.NumberCoversion(playerData.power))
	self:SetWndText(self.mPower,powerStr)
end

function UISuResult:ShowShareOption()
	local info = self._info
	local data =
	{
		resultInfo =
		{
			seasonId           = info.seasonId         ,
			group              = info.group            ,
			groupCount         = info.groupCount       ,
			seasonRank         = info.seasonRank       ,
			seasonWinCount     = info.seasonWinCount   ,
			seasonWinAllCount  = info.seasonWinAllCount,
			seasonBattleCount  = info.seasonBattleCount,
			groupRank          = info.groupRank        ,
			groupWinCount      = info.groupWinCount    ,
			groupWinAllCount   = info.groupWinAllCount ,
			groupBattleCount   = info.groupBattleCount ,
			rank               = info.rank             ,
			groupId            = info.groupId          ,
		},
		playerInfo =
		{
			playerId = gModelPlayer:GetPlayerId(),
			head = gModelPlayer:GetPlayerHead(),
			headFrame = gModelPlayer:GetPlayerHeadFrame(),
			level = gModelPlayer:GetPlayerLv(),
			name = gModelPlayer:GetPlayerName(),
			power = gModelPlayer:GetPlayerFightPower(),
			serverName = gModelPlayer:GetServerName()
		},
	}
	local data = {
		root = self.mBtnShare,
		shareType = ModelChat.CHATSHARE_29,
		shareData = JSON.encode(data),
	}
	gModelGeneral:OpenShareTip(data)

end

function UISuResult:OnWndRefresh()
	CS.ShowObject(self.mBtnLeft,false)
	CS.ShowObject(self.mBtnRight,false)

	local isShare = self:GetWndArg("isShare")
	if not isShare then
		self._seasonId = 0
		gModelSimuFight:OnSimulateSeasonInfoReq()
	else
		self._info = self:GetWndArg("resultInfo")
		self._seasonId = self._info.seasonId

		self:RefreshContent()
	end
end

function UISuResult:InitUIEvent()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnLeft,function ()
		self:ChangeSeason(true)
	end)

	self:SetWndClick(self.mBtnRight,function ()
		self:ChangeSeason(false)

	end)

	self:SetWndClick(self.mCloseTip,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnShare,function ()
		self:ShowShareOption()
	end)
end

function UISuResult:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateSeasonInfoResp,function (pb)
		self:OnSimulateSeasonInfoResp(pb)
	end)
end


function UISuResult:ChangeSeason(left)

	if not self._curIndex then
		return
	end

	local newIndex = nil
	if left then
		newIndex = self._curIndex - 1
	else
		newIndex = self._curIndex + 1
	end
	local total = #self._history



	if newIndex<=0 then
		return
	elseif newIndex > total then
		return
	end



	self._curIndex = newIndex

	self:RefreshChangeBtnShow()

	local seasonId = self._history[newIndex].seasonId
	self._seasonId = seasonId
	gModelSimuFight:OnSimulateSeasonInfoReq(seasonId)
end


------------------------------------------------------------------
return UISuResult


