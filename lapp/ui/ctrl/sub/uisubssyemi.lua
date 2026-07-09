---
--- Created by Administrator.
--- DateTime: 2023/10/20 14:15:29
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSSyemi:LChildWnd
local UISubSSyemi = LxWndClass("UISubSSyemi", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSSyemi:UISubSSyemi()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSSyemi:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSSyemi:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSSyemi:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()


	self:InitData()
	self:InitEvent()
	self:InitUIEvent()
	self:SetStaticContent()
	self:OnWndRefresh()

end

function UISubSSyemi:OpenDetail(btndata)
	if not btndata.isAfter then
		return
	end
	GF.OpenWnd("UIFightRecordMulti",{battleInfo = btndata.battleInfo})
end

function UISubSSyemi:OnSimulateGroupInfoResp(pb)
	if pb.type ~= 2 then
		return
	end

	if self._curGroupId == 0 then
		self._curGroupId = pb.group
		self._redGroupId = pb.group
	end

	if self._curGroupId ~= pb.group then
		return
	end

	if self._curGroup== 0 then
		self._curGroup = pb.groupType
	end

	if self._curGroup~= pb.groupType then
		return
	end


	self._semiFinalInfo = pb

	self:ShowPlayerContent()

	self:RefreshGroupTypeBtnShow()

	self:RefreshLowGroup()

	self:RefreshFormationRedPoint()
end

function UISubSSyemi:RefreshTopBtnShow()
	local state = self._curGroup == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnPeak,state)
	state = self._curGroup == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnElite,state)
end


function UISubSSyemi:ShowPlayerContent()
	if not self._semiFinalInfo then
		return
	end
	local playerDataList = {}

	local resultList = {}
	for k,v in ipairs(self._semiFinalInfo.infos) do
		local data = StructSimulateBattleInfo:New()
		data:CreateByPb(v)
		table.insert(resultList,data)
	end

	local getPrioty = function(sort)
		if sort == 2 then
			return 3
		elseif sort == 3 then
			return 4
		elseif sort == 4 then
			return 2
		end
		return sort
	end


	table.sort(resultList,function (a,b)
		return getPrioty(a.sort)< getPrioty(b.sort)
	end)

	if LOG_INFO_ENABLED then
		for k,v in ipairs(resultList) do
			printInfoN(string.format("UISubSSyemi  %s Vs %s  winner %s",v.attack.playerId,v.defense.playerId,v.winner))
		end
	end

	local playerRecord = nil

	playerDataList,playerRecord = gModelSimuFight:FormatSchedulePlayerList(resultList)

	self._playerRecord = playerRecord
	local lineData = gModelSimuFight:FormatLineDatas(resultList)
	self:ShowLines(lineData)

	local btnDatas = gModelSimuFight:FormatBtnDatas(resultList)
	self:ShowDetailBtn(btnDatas)

	for k=1,15 do
		local tran = self:FindWndTrans(self.mChartPlayerList,"player_"..k)
		self:OnDrawPlayer(tran,playerDataList[k],k<=8)
	end


	self:RefreshBtnFormationShow()
end

function UISubSSyemi:OnClickGroup(index)
	if self._curGroupId == index then
		return
	end

	self._curGroupId = index

	self:RefreshGroupBtnShow()
	self:ReqSemifinalData()

	self:RefreshLowGroup()
end

function UISubSSyemi:RefreshFormationRedPoint()
	local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_SEMI_FORMATION)
	local redTran = self:FindWndTrans(self.mBtnFormation,"redPoint")
	CS.ShowObject(redTran,showRed)

	local showTabRed = 1 == self._redGroupId and showRed

	redTran = self:FindWndTrans(self.mBtnGroup1,"redPoint")

	CS.ShowObject(redTran,showTabRed)
	showTabRed = 2 == self._redGroupId and showRed

	redTran = self:FindWndTrans(self.mBtnGroup1,"redPoint")

	CS.ShowObject(redTran,showTabRed)

end

function UISubSSyemi:RefreshGroupBtnShow()
	local state = self._curGroupId == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnGroup1,state)
	state = self._curGroupId == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnGroup2,state)
end

function UISubSSyemi:ShowLines(linesData)
	local lines = self._groupLines
	local cnt = 7


	CS.ShowObject(self.mLineGroup, true)
	local isUp =nil
	local showUp = nil
	local showDown = nil
	for i = 1,cnt do
		showUp = false
		showDown = false
		isUp = linesData[i] or 0
		if isUp==1 then
			showUp= true
		elseif isUp ==2 then
			showDown = true
		end
		local upIndex = 2*i-1
		local downIndex = 2*i
		CS.ShowObject(lines[upIndex],showUp)
		CS.ShowObject(lines[downIndex],showDown)


	end
end



function UISubSSyemi:OnDrawPlayer(item,itemdata,showName)

	CS.ShowObject(item,not itemdata.isEmpty)

	if itemdata.isEmpty then
		return
	end

	local headTran = self:FindWndTrans(item,"HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
		level = itemdata.grade,
		func = function()
			gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)

	if showName then
		local infoPart = self:FindWndTrans(item,"infoPart")
		local infoPartName = self:FindWndTrans(infoPart,"name")
		local infoPartServer = self:FindWndTrans(infoPart,"server")

		self:SetWndText(infoPartName,itemdata.name)
		self:InitTextLineWithLanguage(infoPartName, -30)
		self:SetWndText(infoPartServer,string.format("[%s]",itemdata.serverName))
	end

end

function UISubSSyemi:ShowDetailBtn(btndatas)
	local btnList = self._groupBtns
	local default =
	{
		isAfter = false
	}

	for k,v in ipairs(btnList) do
		local btndata = btndatas[k] or default
		CS.ShowObject(v,btndata.isAfter)
		self:SetWndClick(v,function () self:OpenDetail(btndata) end)
	end
end

function UISubSSyemi:ShowGameCountDown()
	local curState = gModelSimuFight:GetState()
	local isEnd = curState > ModelSimuFight.SCHEDULE_GROUP_WARM_UP

	if isEnd then
		local str = ccClientText(25139) --"已结束"
		self:SetWndText(self.mStageInfo,str)
		return false
	end

	if curState < ModelSimuFight.SCHEDULE_GROUP_WARM_UP then
		local str =ccClientText(25273) --"该赛程未开启"
		self:SetWndText(self.mStageInfo,str)
		return false
	end


	local timeLeft = gModelSimuFight:GetNextStageTime() - GetTimestamp()
	if timeLeft>= 0 then
		local str = gModelSimuFight:GetTimeShowFormat()
		local timeStr =string.replace(str,LUtil.FormatTimespanNumber(timeLeft))
		local combatState = gModelSimuFight:GetCombatState()

		local roundStr = ""
		if combatState > ModelSimuFight.BATTLE_READY then
			local round = gModelSimuFight:GetRound() % 3
			if round == 0 then
				round = 3
			end
			roundStr = string.replace(ccClientText(25321),round)
		end
		self:SetWndText(self.mStageInfo,roundStr..timeStr)
		return true
	else
		self:SetWndText(self.mStageInfo,ccClientText(25139))
		return false
	end
end

function UISubSSyemi:OnStateUpdate()
	self:RefreshContent()

	self:RefreshBtnEffect()
	self:ReqSemifinalData()
end

function UISubSSyemi:OnWndRefresh()
	self:RefreshContent()
	self._curGroup = self:GetWndArg("groupType") or 0
	local groupId = self:GetWndArg("groupId") or 0

	self._curGroupId = groupId
	local isSelTwo = self:RefreshBtnEffect()
	self._curGroupId = isSelTwo and 2 or self._curGroupId
	self:ReqSemifinalData()
end

function UISubSSyemi:GetPara()
	return {groupType = self._curGroup,groupId = self._curGroupId}
end


function UISubSSyemi:RefreshBtnFormationShow()
	local isShow = true
	if not gModelSimuFight:IsInStage(ModelSimuFight.SCHEDULE_GROUP_WARM_UP,ModelSimuFight.BATTLE_READY) then
		isShow = false
	end

	local playerId = gModelPlayer:GetPlayerId()
	local isIn = self._playerRecord and self._playerRecord[playerId]

	if not isIn then
		isShow = false
	end

	CS.ShowObject(self.mBtnFormation,isShow)
end



function UISubSSyemi:InitUIEvent()


	self:SetWndClick(self.mBtnGroup1,function () self:OnClickGroup(1) end)
	self:SetWndClick(self.mBtnGroup2,function () self:OnClickGroup(2) end)
	self:SetWndClick(self.mBtnHelp,function ()
		GF.OpenWnd("UIBzTips",{refId =110})
	end)

	self:SetWndClick(self.mBtnFormation,function ()
		gModelSimuFight:OpenSetFormation()
	end)
end

function UISubSSyemi:RefreshGroupTypeBtnShow()
	local item = self.mBtnGroupType
	local btnOne = self:FindWndTrans(item,"btnOne")
	local btnTwo = self:FindWndTrans(item,"btnTwo")
	--local showOne = self._curGroup ==1
	CS.ShowObject(btnOne,self._curGroup ==1)
	CS.ShowObject(btnTwo,self._curGroup ==2)
end

function UISubSSyemi:ChangeToOther()
	if self._curGroup == 1 then
		self._curGroup = 2
	else
		self._curGroup = 1
	end

	self:ReqSemifinalData()

	self:RefreshGroupTypeBtnShow()
end

function UISubSSyemi:InitData()


	self._countDownKey = "_countDownKey"

	local lineRoot = self:FindWndTrans(self.mLineGroup,"dynaLine")
	self._groupLines = {}
	for i=1,14 do
		local line = self:FindWndTrans(lineRoot,"bgLine_"..i)
		table.insert(self._groupLines,line)
	end

	local btnRoot = self:FindWndTrans(self.mLineGroup,"btns")
	self._groupBtns = {}
	for i=1,7 do
		local btn = self:FindWndTrans(btnRoot,"midBtn_"..i)
		table.insert(self._groupBtns,btn)
	end

	for i = 1, 14 do
		local str
		if i <= 8 then
			str = "16"
		elseif i == 9 or i == 11 or i == 12 or i == 14 then
			str = "8"
		else
			str = "4"
		end
		local trans = CS.FindTrans(self.mIcon, "Image" .. i)
		self:SetTextTile(trans, str)
	end
end

function UISubSSyemi:SetStaticContent()


	local str =ccClientText(25248) -- "A组"
	self:SetWndButtonText(self.mBtnGroup1,str)
	str = ccClientText(25249) --"B组"
	self:SetWndButtonText(self.mBtnGroup2,str)
	str =ccClientText(46009) --"布阵"
	self:SetTextTile(self.mBtnFormation,str)

	self:InitGroupTypeBtn()

	self:RefreshLowGroup()
end

function UISubSSyemi:RefreshContent()
	self:TimerStop(self._countDownKey)
	if self:ShowGameCountDown() then
		self:TimerStart(self._countDownKey,1,false,-1)
	end

	self:ShowPlayerContent()


end

function UISubSSyemi:RefreshBtnEffect()
	local selTwo
	local curState = gModelSimuFight:GetState()
	local isIng = curState == ModelSimuFight.SCHEDULE_GROUP_WARM_UP

	local showOne = false
	local showTwo = false

	if isIng then
		local combatState = gModelSimuFight:GetCombatState()
		local isPrepare = combatState == ModelSimuFight.BATTLE_READY
		if isPrepare then
			showOne = true
			showTwo = true
		else
			if combatState == ModelSimuFight.BATTLE_WARM_UP or combatState == ModelSimuFight.BATTLE_BATTLE then
				local curRound = gModelSimuFight:GetRound()
				if curRound <= 3 then
					showOne = true
				else
					showTwo = true
					selTwo = true
				end
			end
		end
	end

	if showOne then
		self:CreateWndEffect(self.mBtnGroup1,"fx_anniu_04_cheng","oneEffect",100)
	else
		self:DestroyWndEffectByKey("oneEffect")
	end

	if showTwo then
		self:CreateWndEffect(self.mBtnGroup2,"fx_anniu_04_cheng","twoEffect",100)
	else
		self:DestroyWndEffectByKey("twoEffect")
	end
	return selTwo
end

function UISubSSyemi:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateGroupInfoResp,function (pb)
		self:OnSimulateGroupInfoResp(pb)
	end)

	self:WndEventRecv(EventNames.SIMULATE_STATE_CHANGE,function ()
		self:OnStateUpdate()
	end)

	self:RegisterRedPointFunc(ModelRedPoint.SIMU_SEMI_FORMATION,function ()
		self:RefreshFormationRedPoint()
	end)
end

function UISubSSyemi:ReqSemifinalData()
	local type = 2
	local group = self._curGroupId
	local round = 0
	local groupType = self._curGroup
	gModelSimuFight:OnSimulateGroupInfoReq(type,group,round,groupType)
end

function UISubSSyemi:OnTimer(key)
	if key == self._countDownKey then
		self:ShowGameCountDown()
	end
end

function UISubSSyemi:InitGroupTypeBtn()
	local item = self.mBtnGroupType
	local textOne = self:FindWndTrans(item,"textOne")
	local textTwo = self:FindWndTrans(item,"textTwo")
	local btnOne = self:FindWndTrans(item,"btnOne")
	local btnOneTextOne = self:FindWndTrans(btnOne,"textOne")
	local btnTwo = self:FindWndTrans(item,"btnTwo")
	local btnTwoTextTwo = self:FindWndTrans(btnTwo,"textTwo")

	local name1 =ccLngText(gModelSimuFight:GetPara("groupName1"))
	local name2 =ccLngText(gModelSimuFight:GetPara("groupName2"))


	self:SetWndText(textOne,name1)
	self:SetWndText(btnOneTextOne,name1)
	self:SetWndText(textTwo,name2)
	self:SetWndText(btnTwoTextTwo,name2)

	self:SetWndClick(item,function ()
		self:ChangeToOther()
	end)
	self:SetWndClick(btnOne,function () end)
	self:SetWndClick(btnTwo,function () end)

	self:RefreshGroupTypeBtnShow()

end


function UISubSSyemi:RefreshLowGroup()
	-- local state = self._curGroupId == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnGroup1,self._curGroupId ~= 1)
	-- state = self._curGroupId == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnGroup2,self._curGroupId ~= 2)
end

function UISubSSyemi:OnClickTopGroup(index)
	if self._curGroup == index then
		return
	end

	self._curGroup = index

	self:RefreshTopBtnShow()

	self:ReqSemifinalData()

end

------------------------------------------------------------------
return UISubSSyemi


