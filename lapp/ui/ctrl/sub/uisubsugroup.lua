---
--- Created by Administrator.
--- DateTime: 2023/10/20 14:14:45
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSuGroup:LChildWnd
local UISubSuGroup = LxWndClass("UISubSuGroup", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSuGroup:UISubSuGroup()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSuGroup:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSuGroup:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSuGroup:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()
	self:InitUIEvent()
	self:SetStaticContent()

	self:OnWndRefresh()

end

function UISubSuGroup:OnSimulateGroupInfoResp(pb)
	local type = pb.type
	if type ~= 1 then
		return
	end

	if self._curRound == 0 then

		self._needScroll = true

		self._curRound = pb.round
	end
	if self._curRound ~= pb.round then
		return
	end

	if self._curGroupId == 0 then
		self._curGroupId = pb.group

		--self._redGroupId = pb.group
	end

	if self._curGroup ==0 then
		self._curGroup = pb.groupType
		--self._redGroup = pb.groupType
	end


	if self._curGroupId ~= pb.group then
		return
	end

	if self._curGroup ~= pb.groupType then
		return
	end



	self._groupInfo = pb
	self:ShowGroupReportList()

	self:RefreshGroupTypeBtnShow()

	self:RefreshFormationRedPoint()
end


function UISubSuGroup:ShowGroupReportList()
	if not self._groupInfo then
		return
	end

	self:ShowSelectionPart()

	local dataList = {}

	for k,v in ipairs(self._groupInfo.infos) do
		local data = StructSimulateBattleInfo:New()
		data:CreateByPb(v)
		table.insert(dataList,data)
	end

	if #dataList == 0  then
		for k = 1,4 do
			table.insert(dataList,{isEmpty = true})
		end
	end
	local flowerTarget = self._groupInfo.flowerInfo.targetId


	self._hasSendFlower = tonumber(flowerTarget) > 0
	self._flowerTargetId = flowerTarget


	self:RefreshFormationRedData()

	local playList = self:FindUIScroll("playlist")
	if not playList then
		playList = self:GetUIScroll("playlist")
		playList:Create(self.mPlayerList,dataList,function (...) self:OnDrawPlay(...) end,UIItemList.SUPER)
	else
		playList:RefreshList(dataList)
	end

	playList:DrawAllItems()


	self:TimerStop(self._refreshReport)

	local state = gModelSimuFight:GetState()
	if state ~= ModelSimuFight.SCHEDULE_GROUP_READY then
		return
	end

	self:TimerStart(self._refreshReport,60,false,-1)

end

function UISubSuGroup:GetPara()
	return {groupType = self._curGroup,round = self._curRound,groupId = self._curGroupId}
end

function UISubSuGroup:ShowTimeContent()
	self:TimerStop(self._countDownKey)
	if self:ShowGameCountDown() then
		self:TimerStart(self._countDownKey,1,false,-1)
	end
end

function UISubSuGroup:RefreshGroupTypeBtnShow()
	local item = self.mBtnGroupType
	local btnOne = self:FindWndTrans(item,"btnOne")
	local btnTwo = self:FindWndTrans(item,"btnTwo")
	--local showOne = self._curGroup ==1
	CS.ShowObject(btnOne,self._curGroup ==1)
	CS.ShowObject(btnTwo,self._curGroup ==2)
end

function UISubSuGroup:OnTimer(key)
	if self._countDownKey == key then
		self:ShowGameCountDown()
	elseif self._refreshReport == key then
		self:RefreshReportShow()
	end
end

function UISubSuGroup:OnDrawPlay(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	--local AniRootBg = self:FindWndTrans(AniRoot,"bg")
	local AniRootVS = self:FindWndTrans(AniRoot,"VS")
	local AniRootEmpty = self:FindWndTrans(AniRoot,"empty")
	local emptyEmpty_1 = self:FindWndTrans(AniRootEmpty,"empty_1")
	--local empty_1Image = self:FindWndTrans(emptyEmpty_1,"Image")
	local empty_1UIText = self:FindWndTrans(emptyEmpty_1,"UIText")
	--local empty_1Mask = self:FindWndTrans(emptyEmpty_1,"mask")
	local emptyEmpty_2 = self:FindWndTrans(AniRootEmpty,"empty_2")
	--local empty_2Image = self:FindWndTrans(emptyEmpty_2,"Image")
	local empty_2UIText = self:FindWndTrans(emptyEmpty_2,"UIText")
	--local empty_2Mask = self:FindWndTrans(emptyEmpty_2,"mask")
	local AniRootDePart = self:FindWndTrans(AniRoot,"dePart")
	local dePartLeft = self:FindWndTrans(AniRootDePart,"left")
	--local leftName = self:FindWndTrans(dePartLeft,"name")
	local leftLayout = self:FindWndTrans(dePartLeft,"layout")
	--local layoutImage = self:FindWndTrans(leftLayout,"Images")
	--local layoutNum = self:FindWndTrans(leftLayout,"num")
	local dePartRight = self:FindWndTrans(AniRootDePart,"right")
	--local rightName = self:FindWndTrans(dePartRight,"name")
	local rightLayout = self:FindWndTrans(dePartRight,"layout")
	--local layoutImage = self:FindWndTrans(rightLayout,"Image")
	--local layoutNum = self:FindWndTrans(rightLayout,"num")
	local dePartLayout = self:FindWndTrans(AniRootDePart,"layout")
	local layoutBtnFormation = self:FindWndTrans(dePartLayout,"btnFormation")
	--local btnFormationImage = self:FindWndTrans(layoutBtnFormation,"Image")
	local btnFormationRedPoint = self:FindWndTrans(layoutBtnFormation,"redPoint")
	local layoutBtnVideo = self:FindWndTrans(dePartLayout,"btnVideo")
	--local btnVideoImage = self:FindWndTrans(layoutBtnVideo,"Image")
	local layoutBtnFlower = self:FindWndTrans(dePartLayout,"btnFlower")
	--local btnFlowerImage = self:FindWndTrans(layoutBtnFlower,"Image")
	local btnFlowerRedPoint = self:FindWndTrans(layoutBtnFlower,"redPoint")
	--local dePartStatebg = self:FindWndTrans(AniRootDePart,"statebg")
	local dePartState = self:FindWndTrans(AniRootDePart,"state")
	local dePartBtnDetail = self:FindWndTrans(AniRootDePart,"btnDetail")
	--local btnDetailImage = self:FindWndTrans(dePartBtnDetail,"Image")






	CS.ShowObject(AniRootDePart,not itemdata.isEmpty)
	CS.ShowObject(AniRootEmpty,itemdata.isEmpty)
	if itemdata.isEmpty then
		local str = ccClientText(25276)
		self:SetWndText(empty_1UIText,str)
		self:InitTextLineWithLanguage(empty_1UIText, -30)
		self:InitTextSizeWithLanguage(empty_1UIText, -2)
		self:SetWndText(empty_2UIText,str)
		self:InitTextLineWithLanguage(empty_2UIText, -30)
		self:InitTextSizeWithLanguage(empty_2UIText, -2)
		return
	end


	local playerId = gModelPlayer:GetPlayerId()
	local isPaticipate = playerId == itemdata.attack.playerId or playerId== itemdata.defense.playerId

	local isCurReady = gModelSimuFight:IsCurGroupBattleReady(itemdata)
	local showFormation = isCurReady and isPaticipate


	CS.ShowObject(layoutBtnFormation,showFormation)


	self:SetPlayerContent(dePartLeft,itemdata.attack,itemdata.attackFlower)
	self:SetPlayerContent(dePartRight,itemdata.defense,itemdata.defenceFlower)


	self:SetWndClick(layoutBtnFormation,function () self:OnClickFormation(itemdata) end)
	self:SetWndClick(dePartBtnDetail,function () self:OnClickDetail(itemdata) end)
	self:SetWndClick(layoutBtnFlower,function () self:OnClickFlower(itemdata) end)
	self:SetWndClick(layoutBtnVideo,function () self:OnClickVideo(itemdata) end)


	local showLeftWin = false
	local showRightWin = false
	local state = gModelSimuFight:GetBattleInfoState(itemdata)
	local stateStr = nil
	if state == 1 then
		stateStr = ccClientText(25207) --"等待中..."
	elseif state == 2 then
		stateStr = ccClientText(25208) --"战斗中..."
	elseif state == 3 then
		local winc,failc = itemdata:GetWinNumberShow()
		stateStr = string.replace(ccClientText(25209),winc,failc)
		showLeftWin = itemdata.winner == 1
		showRightWin = itemdata.winner == 2
	end

	local tagTran = self:FindWndTrans(dePartLeft,"winTag")
	CS.ShowObject(tagTran,showLeftWin)
	tagTran = self:FindWndTrans(dePartRight,"winTag")
	CS.ShowObject(tagTran,showRightWin)

	self:SetWndText(dePartState,stateStr)

	local showDetail = state== 2 or state == 3
	CS.ShowObject(dePartBtnDetail,showDetail)
	CS.ShowObject(AniRootVS,not showDetail)
	CS.ShowObject(layoutBtnVideo,isPaticipate and isCurReady)
	CS.ShowObject(layoutBtnFlower,isCurReady and not self._hasSendFlower)

	CS.ShowObject(btnFlowerRedPoint,true)

	self._formationRedTran = btnFormationRedPoint

	local isFlowerShow = isCurReady
	--TODO
	isFlowerShow = true --暂时全部显示
	CS.ShowObject(leftLayout,isFlowerShow)
	CS.ShowObject(rightLayout,isFlowerShow)

	local instanceId = layoutBtnFlower:GetInstanceID()
	self:CreateWndEffect(layoutBtnFlower,"fx_baowu_kejihuo_2",instanceId,40)

	local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_GROUP_FORMATION)

	CS.ShowObject(btnFormationRedPoint,showRed and self._redGroupType == self._curGroup)
end

function UISubSuGroup:InitUIEvent()
	self:SetWndClick(self.mBtnHelp,function ()
		GF.OpenWnd("UIBzTips",{refId = 109})
	end)

	self:SetWndClick(self.mBtnElite,function ()
		self:OnClickTopGroup(2)
	end)

	self:SetWndClick(self.mBtnPeak,function ()
		self:OnClickTopGroup(1)
	end)
end

function UISubSuGroup:OnClickFormation(battleInfo)
	local battleRound = battleInfo.round
	local combatDataList = nil
	if battleRound <= 2 then
		combatDataList =
		{
			[1]=
			{
				index = 1,
				round = 1,
				combatType = LCombatTypeConst.COMBAT_TYPE_25,
			},
			[2]=
			{
				index = 2,
				round = 2,
				combatType = LCombatTypeConst.COMBAT_TYPE_251,
			},
		}

	elseif battleRound <= 4 then
		combatDataList =
		{
			[1]=
			{
				index = 1,
				round = 3,
				combatType = LCombatTypeConst.COMBAT_TYPE_25,
			},
			[2]=
			{
				index = 2,
				round = 4,
				combatType = LCombatTypeConst.COMBAT_TYPE_251,
			},
		}
	else
		combatDataList =
		{
			[1]=
			{
				index = 1,
				round = 5,
				combatType = LCombatTypeConst.COMBAT_TYPE_25,
			},
			[2]=
			{
				index = 2,
				round = 6,
				combatType = LCombatTypeConst.COMBAT_TYPE_251,
			},
			[3]=
			{
				index = 3,
				round = 7,
				combatType = LCombatTypeConst.COMBAT_TYPE_252,
			},
		}
	end

	local groupIndex = 1
	local combatType = LCombatTypeConst.COMBAT_TYPE_25
	for k,v in ipairs(combatDataList) do
		if v.round == battleRound then
			groupIndex = k
			combatType = v.combatType
			break
		end
	end


	gModelSimuFight:OpenSetFormation(nil,combatDataList,groupIndex,combatType)
end

function UISubSuGroup:InitGroupTypeBtn()
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

function UISubSuGroup:RefreshFormationRedData()
	local groupId = nil
	local groupType = nil
	local redPointData = gModelRedPoint:GetRedPointNetData(ModelRedPoint.SIMU_GROUP_FORMATION)
	if redPointData then
		local info = redPointData.defaultInfo
		local tempStrs = LxDataHelper.ParseNumber_Sign(info,'=')
		groupId = tempStrs[2] and tonumber(tempStrs[2])
		groupType = tempStrs[3] and tonumber(tempStrs[3])
	end

	self._redGroupId = groupId
	self._redGroupType = groupType

end

function UISubSuGroup:SetStaticContent()
	--local str = "巅峰组"
	--self:SetWndTabText(self.mBtnPeak,str)
	--str = "精英组"
	--self:SetWndTabText(self.mBtnElite,str)

	local str =ccClientText(25206) -- "每一轮只可以选择一场比赛进行献花"
	self:SetWndText(self.mIntro,str)

	self:InitTextLineWithLanguage(self.mIntro,-40)

	self._curRound = 0
	self._curGroupId = 0
	self._curGroup = 0

	self:InitGroupTypeBtn()
	self:ShowSelectionPart()
end

function UISubSuGroup:ShowGameCountDown()
	local curState = gModelSimuFight:GetState()
	local isEnd = curState > ModelSimuFight.SCHEDULE_GROUP_READY

	if isEnd then
		local str = ccClientText(25139)--"已结束"
		self:SetWndText(self.mStageInfo,str)
		return false
	end

	if curState < ModelSimuFight.SCHEDULE_GROUP_INIT then
		local str =ccClientText(25273) --"该赛程未开启"
		self:SetWndText(self.mStageInfo,str)
		return false
	end


	local timeLeft = gModelSimuFight:GetNextStageTime() - GetTimestamp()
	if timeLeft>= 0 then
		local str = gModelSimuFight:GetTimeShowFormat()
		local timeStr =string.replace(str,LUtil.FormatTimespanNumber(timeLeft))
		local combatState = gModelSimuFight:GetCombatState()

		--TODO 暂时去掉小组赛的轮次显示
		local roundStr = ""
		if combatState > ModelSimuFight.BATTLE_READY then
			local round = gModelSimuFight:GetRound()
			roundStr = string.replace(ccClientText(25321),round)
		end

		self:SetWndText(self.mStageInfo,roundStr..timeStr)
		return true
	else
		self:SetWndText(self.mStageInfo,ccClientText(25139))
		return false
	end
end

function UISubSuGroup:RefreshReportShow()
	local playList = self:FindUIScroll("playlist")
	if playList then
		playList:DrawAllItems()
	end
end

function UISubSuGroup:OnDrawTab(list,item,itemdata,itempos)
	local BtnTab = self:FindWndTrans(item,"BtnTab")
	-- local redPoint = self:FindWndTrans(BtnTab,"redPoint")
	self:SetWndButtonText(BtnTab,itemdata.name)
	local isSel = self._curRound == itemdata.index

	-- local state = isSel and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(BtnTab,not isSel)

	self:SetWndClick(BtnTab,function()
		self:OnClickRound(itemdata.index)
	end)

	if not self._roundItemRecord then
		self._roundItemRecord = {}
	end

	self._roundItemRecord[itemdata.index] = redPoint

	local instanceID = item:GetInstanceID()
	self:DestroyWndEffectByKey(instanceID)
	local roundMap = gModelSimuFight:GetGroupRunning()
	if roundMap[itemdata.index] then
		self:CreateWndEffect(BtnTab,"fx_anniu_04_cheng",instanceID,100)
	end
end

function UISubSuGroup:OnClickGroup(index)
	if self._curGroupId == index then
		return
	end

	self._curGroupId = index

	--local uiList = self:FindUIScroll("groupList")
	--if uiList then
	--	uiList:DrawAllItems(false)
	--end

	--self:ShowGroupReportList()

	self:ReqGroupData()
end

function UISubSuGroup:OnDrawGroup(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootOff = self:FindWndTrans(AniRoot,"off")
	local AniRootOn = self:FindWndTrans(AniRoot,"on")
	-- local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootRedPoint = self:FindWndTrans(AniRoot,"redPoint")


	local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_GROUP_FORMATION)
	CS.ShowObject(AniRootRedPoint,showRed and itemdata.index == self._redGroupId)

	local isSel = self._curGroupId == itemdata.index

	local color = "white"
	if isSel then
		color = "black"
	end
	-- self:SetWndText(AniRootUIText,LUtil.FormatColorStr(itemdata.icon,color))
	self:SetWndEasyImage(AniRootOff, itemdata.icon)


	CS.ShowObject(AniRootOn,isSel)

	self:SetWndClick(AniRoot,function ()
		self:OnClickGroup(itemdata.index)
	end)

	if not self._groupItemRecord then
		self._groupItemRecord= {}
	end

	self._groupItemRecord[itemdata.index] = AniRootRedPoint
end

function UISubSuGroup:SetPlayerContent(item,playerData,flower)
	local name = self:FindWndTrans(item,"name")
	local layout = self:FindWndTrans(item,"layout")
	local layoutImage = self:FindWndTrans(layout,"Image")
	local layoutNum = self:FindWndTrans(layout,"num")
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
	self:CreateHeadIconImpl(playerInfo)

	local nameStr = string.replace(ccClientText(25286),playerData.serverName,playerData.name)
	self:SetWndText(name,nameStr)
	--self:SetWndText(server,playerData.serverName)
	self:SetWndText(layoutNum,flower)

	local isTarget = self._flowerTargetId == playerData.playerId
	CS.ShowObject(tag,isTarget)
end

function UISubSuGroup:OnWndRefresh()

	local round = gModelSimuFight:GetPrepareGroupRound()
	if round == 0 then
		local state = gModelSimuFight:GetState()
		if state == ModelSimuFight.SCHEDULE_GROUP_READY then
			round = gModelSimuFight:GetRound()
		else
			round = 1
		end
	end

	self._curGroup = self:GetWndArg("groupType") or 0
	self._curRound = self:GetWndArg("round") or round
	self._curGroupId = self:GetWndArg("groupId") or 0


	self:ShowTimeContent()

	self._needScroll = true
	self:ReqGroupData()
	--self:ShowGroupReportList()
end

function UISubSuGroup:ReqGroupData()
	local type = 1
	local group = self._curGroupId
	local round = self._curRound
	local groupType = self._curGroup
	gModelSimuFight:OnSimulateGroupInfoReq(type,group,round,groupType)
end

function UISubSuGroup:ChangeToOther()
	if self._curGroup == 1 then
		self._curGroup = 2
	else
		self._curGroup = 1
	end

	self:ReqGroupData()

	self:RefreshGroupTypeBtnShow()
end

function UISubSuGroup:RefreshFormationRedPoint()

	self:RefreshFormationRedData()

	local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_GROUP_FORMATION)
	local red1 = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_GROUP_1_FLOWER)
	local red2 = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_GROUP_2_FLOWER)

	local roundMap = {}

	local redId = nil
	if self._curGroup == ModelSimuFight.GROUP_PINNACLE then
		redId = ModelRedPoint.SIMU_GROUP_1_FLOWER
	else
		redId = ModelRedPoint.SIMU_GROUP_2_FLOWER
	end

	local redPointData = gModelRedPoint:GetRedPointNetData(redId)
	if redPointData then
		local info = redPointData.defaultInfo
		local numList = LxDataHelper.ParseNumber_Sign(info,'|')
		for k,v in ipairs(numList) do
			roundMap[v] = true
		end
	end

	local redTran = self:FindWndTrans(self.mBtnGroupType,"redPoint1")
	CS.ShowObject(redTran,red1)
	redTran = self:FindWndTrans(self.mBtnGroupType,"redPoint2")
	CS.ShowObject(redTran,red2)

	local formationRed = showRed and self._redGroupType == self._curGroup

	if self._groupItemRecord then
		for k,v in pairs(self._groupItemRecord) do
			CS.ShowObject(v,formationRed and k == self._redGroupId)
		end
	end

	local round = gModelSimuFight:GetPrepareGroupRound()

	if self._roundItemRecord then
		for k,v in pairs(self._roundItemRecord) do
			local isRed = (formationRed and k == round) or roundMap[k]
			CS.ShowObject(v,isRed)
		end
	end

	if self._formationRedTran then
		CS.ShowObject(self._formationRedTran,formationRed)
	end


end

function UISubSuGroup:OnClickRound(index)
	if self._curRound == index then
		return
	end

	self._curRound = index

	self:ReqGroupData()
	--self:ShowGroupReportList()

	self:RefreshFormationRedPoint()
end

function UISubSuGroup:OnClickDetail(itemdata)
	GF.OpenWnd("UIFightRecordMulti",{battleInfo = itemdata})
end

function UISubSuGroup:OnClickFlower(itemdata)
	GF.OpenWnd("UISSyendFlower",{battleInfo = itemdata,flowerInfo = self._groupInfo.flowerInfo,groupType = self._curGroup})
end

function UISubSuGroup:OnClickVideo(itemdata)
	local other = nil
	local playerId = gModelPlayer:GetPlayerId()
	if playerId == itemdata.attack.playerId then
		other = itemdata.defense.playerId
	else
		other = itemdata.attack.playerId
	end

	GF.OpenWnd("UISuBreakVdo",{playerId = other})
end

function UISubSuGroup:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateGroupInfoResp,function (pb)
		self:OnSimulateGroupInfoResp(pb)
	end)

	self:WndEventRecv(EventNames.SIMULATE_STATE_CHANGE,function ()
		self:OnStateUpdate()
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateFlowerResp,function (pb)
		self:ReqGroupData()
	end)

	self:RegisterRedPointFunc(ModelRedPoint.SIMU_GROUP_FORMATION,function ()
		self:RefreshFormationRedPoint()
	end)
	self:RegisterRedPointFunc(ModelRedPoint.SIMU_GROUP_1_FLOWER,function ()
		self:RefreshFormationRedPoint()
	end)
	self:RegisterRedPointFunc(ModelRedPoint.SIMU_GROUP_2_FLOWER,function ()
		self:RefreshFormationRedPoint()
	end)
end

function UISubSuGroup:OnStateUpdate()
	self:ShowTimeContent()
	self:ReqGroupData()
	--self:ShowGroupReportList()

end

function UISubSuGroup:OnClickTopGroup(index)
	if self._curGroup == index then
		return
	end

	self._curGroup = index

	self:ReqGroupData()
end

function UISubSuGroup:InitData()
	--self._stateStrs =
	--{
	--	[1] = ccClientText(25204), -- "准备阶段：%s",
	--	[2] = ccClientText(25205), -- "预热阶段：%s",
	--}

	self._groupDataList =
	{
		[1] =
		{
			index = 1,
			icon = "actionarena_btn_9",
		},
		[2] =
		{
			index = 2,
			icon = "actionarena_btn_10",
		},
		[3] =
		{
			index = 3,
			icon = "actionarena_btn_11",
		},
		[4] =
		{
			index = 4,
			icon = "actionarena_btn_12",
		},
		[5] =
		{
			index = 5,
			icon = "actionarena_btn_20",
		},
		[6] =
		{
			index = 6,
			icon = "actionarena_btn_21",
		},
		[7] =
		{
			index = 7,
			icon = "actionarena_btn_22",
		},
		[8] =
		{
			index = 8,
			icon = "actionarena_btn_23",
		},
	}

	self._roundDataList =
	{
		[1] =
		{
			index = 1,
			name = ccClientText(25115), --
		},
		[2] =
		{
			index = 2,
			name =ccClientText(25116), -- "第二轮"
		},
		[3] =
		{
			index = 3,
			name = ccClientText(25117), --"第三轮"
		},
		[4] =
		{
			index = 4,
			name = ccClientText(25118), --"第四轮"
		},
		[5] =
		{
			index = 5,
			name = ccClientText(25119), --"第五轮"
		},
		[6] =
		{
			index = 6,
			name = ccClientText(25120), --"第六轮"
		},
		[7] =
		{
			index = 7,
			name = ccClientText(25121), --"第七轮"
		},
	}

	self._countDownKey = "_countDownKey"

	self._refreshReport = "_refreshReport"
end

function UISubSuGroup:ShowSelectionPart()
	local groupList = self:FindUIScroll("groupList")
	if not groupList then
		groupList = self:GetUIScroll("groupList")
		groupList:Create(self.mGroupList,self._groupDataList,function (...) self:OnDrawGroup(...) end)
	else
		groupList:DrawAllItems(false)
	end

	local roundList = self:FindUIScroll("roundList")
	if not roundList then
		roundList = self:GetUIScroll("roundList")
		roundList:Create(self.mTabList,self._roundDataList,function (...) self:OnDrawTab(...) end)

		roundList:EnableScroll(true,true)
	else
		roundList:DrawAllItems(false)
	end

	if self._needScroll then
		local uiCom = roundList:GetList()
		uiCom:DelayScrollTo(self._curRound)

		self._needScroll = false
	end

end





------------------------------------------------------------------
return UISubSuGroup


