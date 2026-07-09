---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringRecord:LWnd
local UIringRecord = LxWndClass("UIringRecord", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringRecord:UIringRecord()
	self._pageSize = 10
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringRecord:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringRecord:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringRecord:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitList()

	self:SetStaticContent()

	self:InitUIMsg()
	self:InitUIEvent()

	self:InitData()
end


function UIringRecord:Watch(reportId,leftName,rightName)
	local mapRes = gModelBattle:GetBattleMapRes({combatType = LCombatTypeConst.COMBAT_ARENA_ATTACK})


	local combatExtraDatas =
	{
		battleEndfun = function() self:OnPlayEnd()  end,
		canSkip = true,
		meName = leftName,
		otherName = rightName,
		battleMapName =mapRes,
		videoType = LVideoTypeConst.ARENA_RANK,
	}
	gLFightManager:OnPlayBattleVideo(reportId,combatExtraDatas)
	GF.CloseWndByName("UIringRk")
	self:WndClose()
end

function UIringRecord:ShowReport(reportId,leftName,rightName)

	local extraData =
	{
		meName = leftName,
		otherName = rightName,
		videoType = LVideoTypeConst.ARENA_RANK,
		closeAfterVideo = function() self:OnPlayEnd() end
	}

	gLFightManager:OnOpenBattleDetails(reportId,extraData)
end

function UIringRecord:OnPlayEnd()
	GF.CloseWndByName("UIFight")
	GF.ChangeMap("LCityMap")

	GF.OpenWndBottom("UIringRk")
	GF.OpenWnd("UIringRecord")
end

function UIringRecord:SetStaticContent()
	self:SetWndText(self.mTitle,ccClientText(10328))

	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId= 5001,
		IntroTran= text,
		--TextBgTran,
		--IconTran,
		--GetBtn,
		--GetBtnText
		--ButtonRoot,
	}
	emptyList:RefreshUI(data)
end

function UIringRecord:InitList()
	self._resultStr=
	{
		ccClientText(10329),--进攻成功
		ccClientText(10330),--进攻失败
		ccClientText(10331),--防守成功
		ccClientText(10332),--防守失败

	}


	self._scoreStateIcon=
	{
		"public_arrow_3",
		"actionarena_ui_arrow_1",

	}

	self._dataList ={}

	self._reqedList = {}
end

function UIringRecord:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

--function UIringRecord:OnPlayerArenaBattleHistoryResp()
--	self:InitScrollView()
--end

function UIringRecord:InitScrollView()
	local recordList = self._dataList
	if not recordList or #recordList == 0 then
		--self:SetXUITextText(self.mNoRecord,ccClientText(10337))
		CS.ShowObject(self.mNoRecord2,true)
		CS.ShowObject(self.mRecordList,false)
		return
	end
	CS.ShowObject(self.mNoRecord2,false)
	CS.ShowObject(self.mRecordList,true)

	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mRecordList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawItem(...)
		end)
		uiList:SetFuncOnItemReachTail(function (...) self:OnReachEnd(...) end)

		self._uiList = uiList
	end
	uiList:RemoveAllData()
	for i=1,#recordList do
		local data = recordList[i]
		local itemdata = {}
		local selfPlayerId = gModelPlayer:GetPlayerId()
		local otherPlayer = nil
		local selfPlayer = nil
		local result = 1
		if selfPlayerId == data.attack.playerId then
			selfPlayer = data.attack
			otherPlayer = data.defense
			if data.winner==1 then
				result =1
			else
				result =2
			end
		else
			selfPlayer = data.defense
			otherPlayer = data.attack
			if data.winner==1 then
				result =4
			else
				result =3
			end
		end
		itemdata.playerId = otherPlayer.playerId
		itemdata.name = otherPlayer.name
		--itemdata.score = otherPlayer.score
		itemdata.power = otherPlayer.power
		itemdata.playerLv = otherPlayer.grade
		itemdata.result = result
		itemdata.change = selfPlayer.change
		itemdata.head = otherPlayer.head
		local reportId = data.reportId
		itemdata.watchFunc = function() self:Watch(reportId,data.attack.name,data.defense.name) end
		itemdata.reportFunc = function() self:ShowReport(reportId,data.attack.name,data.defense.name) end
		--itemdata.playerFunc = function() print("playerid") end
		uiList:AddData(i,itemdata)
	end

	if self._curPage == 1 then
		uiList:RefreshList()
	else
		uiList:RefreshSilent()
	end

end

function UIringRecord:OnReachEnd(list,bIn)
	if bIn then
		self:ReqData()
	end
end
------------------------------------------------------------------
function UIringRecord:InitData()
	self._curPage =1
	self:ReqData()
end

function UIringRecord:OnDrawItem(list, item, itemdata, itempos, fromHeadTail)

	local lookBtn = self:FindWndTrans(item,"LookBtn")
	local lookBtnText = self:FindWndTrans(lookBtn,"XUIText")

	local reportBtn = self:FindWndTrans(item,"ReportBtn")
	local reportBtnText = self:FindWndTrans(reportBtn,"XUIText")

	local playertext = self:FindWndTrans(item,"PlayerText")
	local headIcon = self:FindWndTrans(item,"HeadIcon")

	local force = self:FindWndTrans(item,"PowerBg")
	local forceText = self:FindWndTrans(force,"PowerText")

	local score = self:FindWndTrans(item,"Score")
	local scoreIconText = self:FindWndTrans(score,"score_text")
	local scoreIcon = self:FindWndTrans(score,"icon")
	local scoreSign = self:FindWndTrans(score,"sign")
	local scoreText = self:FindWndTrans(score,"text")

	local title = self:FindWndTrans(item,"TitleImg")
	local titleResult = self:FindWndTrans(title,"TitleText")
	self:SetWndText(scoreIconText,ccClientText(17989))
	self:SetWndText(playertext,itemdata.name)

	local powerStr = LUtil.PowerNumberCoversion(LUtil.ToInteger(itemdata.power))
	self:SetWndText(forceText,powerStr)

	local scoreStateIcon =nil
	if itemdata.change>0 then
		scoreStateIcon = self._scoreStateIcon[1]
	elseif itemdata.change<0 then
		scoreStateIcon = self._scoreStateIcon[2]
	end
	if scoreStateIcon then
		self:SetWndEasyImage(scoreSign,scoreStateIcon)
		local color = "green"
		if itemdata.change <0 then
			color = "#c81212"
		end
		self:SetWndText(scoreText,LUtil.FormatColorStr(math.abs(itemdata.change),color))
		CS.ShowObject(scoreSign,true)
	else
		self:SetWndText(scoreText,LUtil.FormatColorStr(ccClientText(10333),"green")) --不变
		CS.ShowObject(scoreSign,false)
	end

	local resultStr = self._resultStr[itemdata.result]
	local color = "#c81212"
	if itemdata.result == 1 or itemdata.result == 3 then
		color = "#1b62a3"
	end
	self:SetWndText(titleResult,LUtil.FormatColorStr(resultStr,color))

	self:SetWndClick(lookBtn,itemdata.watchFunc)
	self:SetWndText(lookBtnText,ccClientText(11844))
	self:InitTextLineWithLanguage(lookBtnText,-30)


	self:SetWndClick(reportBtn,itemdata.reportFunc)
	self:SetWndText(reportBtnText,ccClientText(17516))
	self:InitTextLineWithLanguage(reportBtnText,-30)

	local playerInfo={
		trans=headIcon,
		icon=itemdata.head,
		headFrame=itemdata.headFrame,
		name=itemdata.name,
		level=itemdata.grade,
	}

	local InstanceID = item:GetInstanceID()
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)

	self:SetWndClick(headIcon,function ()
		gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
end

function UIringRecord:OnDataReturn(pb)
	self._isReqing = false
	local itemList = pb.historyList
	local cnt = #itemList
	if cnt< self._pageSize then
		self._isEnd = true
	end

	for k,v in ipairs(pb.historyList) do
		table.insert(self._dataList,v)
	end

	self:InitScrollView()

	self._curPage= self._curPage +1
end

function UIringRecord:ReqData()
	if self._isReqing  or self._isEnd then
		return
	end

	local page = self._curPage

	if self._reqedList[page] then
		return
	end
	self._reqedList[page] = true
	self._isReqing = true
	gModelArena:OnPlayerArenaBattleHistoryReq(page,self._pageSize)
end

function UIringRecord:InitUIMsg()
	self:WndNetMsgRecv(LProtoIds.PlayerArenaBattleHistoryResp,function (...) self:OnDataReturn(...) end)
	--self:WndEventRecv(EventNames.ARENA_RECORDDATA_END,function (...) self:OnPlayerArenaBattleHistoryResp()  end)
end

------------------------------------------------------------------
return UIringRecord


