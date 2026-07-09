---
--- Created by Administrator.
--- DateTime: 2023/10/20 14:14:16
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSuFinal:LChildWnd
local UISubSuFinal = LxWndClass("UISubSuFinal", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSuFinal:UISubSuFinal()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSuFinal:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSuFinal:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSuFinal:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()


	local audioName = LxResPathUtil.GetAudioSoundName(nil,LSoundConst.SIMULATE)
	if not string.isempty(audioName) then
		if gLGameAudio then
			gLGameAudio:PlaySound(audioName)
		end
	end


	self:InitData()
	self:InitUIEvent()
	self:InitEvent()
	self:SetStaticContent()



	self:OnWndRefresh()

end

function UISubSuFinal:ShowGameCountDown()
	local curState = gModelSimuFight:GetState()
	local isEnd = curState > ModelSimuFight.SCHEDULE_GROUP_BATTLE

	if isEnd then
		local str =ccClientText(25139) -- "已结束"
		self:SetWndText(self.mStageInfo,str)
		return false
	end

	if curState < ModelSimuFight.SCHEDULE_GROUP_BATTLE then
		local str =ccClientText(25273) --"该赛程未开启"
		self:SetWndText(self.mStageInfo,str)
		return false
	end


	local timeLeft = gModelSimuFight:GetNextStageTime() - GetTimestamp()
	if timeLeft>= 0 then
		local str = gModelSimuFight:GetTimeShowFormat()
		local timeStr =string.replace(str,LUtil.FormatTimespanNumber(timeLeft))
		--local round = gModelSimuFight:GetRound()
		--local roundStr = string.format("第%s轮",round)
		--TODO 暂时去掉总决赛的轮次显示
		--roundStr = ""
		self:SetWndText(self.mStageInfo,timeStr)
		return true
	else
		self:SetWndText(self.mStageInfo,ccClientText(25139))
		return false
	end
end

function UISubSuFinal:RefreshContent()
	self:ShowPreparePart()
	self:ShowResultPart()

	self:RefreshGroupTypeBtnShow()
	self:RefreshLowGroup()
	self:RefreshDetailBtn()

end

function UISubSuFinal:RefreshBtnEffect()
	local curState = gModelSimuFight:GetState()
	local isIng = curState == ModelSimuFight.SCHEDULE_GROUP_BATTLE

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
				if curRound <= 1 then
					showOne = true
				else
					showTwo = true
				end
			end
		end
	end

	if showOne then
		self:CreateWndEffect(self.mBtnThird,"fx_anniu_04_cheng","oneEffect",100)
	else
		self:DestroyWndEffectByKey("oneEffect")
	end

	if showTwo then
		self:CreateWndEffect(self.mBtnChampion,"fx_anniu_04_cheng","twoEffect",100)
	else
		self:DestroyWndEffectByKey("twoEffect")
	end
end

function UISubSuFinal:RefreshLowGroup()
	-- local state = self._curRound == 2 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnChampion,self._curRound ~= 2)
	-- state = self._curRound == 1 and LWnd.StateOn or LWnd.StateOff
	self:SetWndButtonGray(self.mBtnThird,self._curRound ~= 1)
end

function UISubSuFinal:RefreshGroupTypeBtnShow()
	local item = self.mBtnGroupType
	local btnOne = self:FindWndTrans(item,"btnOne")
	local btnTwo = self:FindWndTrans(item,"btnTwo")
	CS.ShowObject(btnOne,self._curGroup ==1)
	CS.ShowObject(btnTwo,self._curGroup ==2)
end

function UISubSuFinal:OnSimulateGroupInfoResp(pb)
	if pb.type ~= 3 then
		return
	end

	if self._curRound == 0 then
		self._curRound = pb.round

		self._redRound = pb.round
	end

	if self._curRound ~= pb.round then
		return
	end

	if self._curRound >2 or self._curRound<1 then
		self._curRound = 2
	end

	if self._curGroup== 0 then
		self._curGroup = pb.groupType
	end

	if self._curGroup~= pb.groupType then
		return
	end


	local info = pb.infos[1]
	if info then
		local battleInfo = StructSimulateBattleInfo:New()
		battleInfo:CreateByPb(info)

		self._battleInfo = battleInfo

		local winner = battleInfo.winner
		local winPlayer = nil
		if winner == 1 then
			winPlayer = battleInfo.attack
		else
			winPlayer = battleInfo.defense
		end

		self._winPlayer = winPlayer
	else
		self._battleInfo = nil
		self._winPlayer = nil
	end


	self:RefreshContent()

	self:RefreshBtnFormationShow()

	self:RefreshFormationRed()
end

function UISubSuFinal:SetPlayer(item,itemdata,isWin)
    local depart = self:FindWndTrans(item,"depart")
    local departPower = self:FindWndTrans(depart,"power")
    local departName = self:FindWndTrans(depart,"name")
    local departWintag = self:FindWndTrans(depart,"wintag")
    local empty = self:FindWndTrans(item,"empty")
    local emptyImage = self:FindWndTrans(empty,"Image")
    local emptyEmptyTips = self:FindWndTrans(empty,"emptyTips")
    local emptyMask = self:FindWndTrans(empty,"mask")


    CS.ShowObject(depart,not itemdata.isEmpty)
	CS.ShowObject(empty,itemdata.isEmpty)

	if itemdata.isEmpty then
		self:SetWndText(emptyEmptyTips,ccClientText(25276))
		self:InitTextSizeWithLanguage(emptyEmptyTips, -2)
		self:InitTextLineWithLanguage(emptyEmptyTips, -30)
		return
	end

    CS.ShowObject(departWintag,isWin)

	local headTran = self:FindWndTrans(depart,"HeadIcon")
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
	self:SetWndText(departPower,string.replace(ccClientText(25284),LUtil.NumberCoversion(itemdata.power)))

	local nameStr = string.replace(ccClientText(25192),itemdata.serverName,itemdata.name)
	self:SetWndText(departName,nameStr)
end

function UISubSuFinal:ReqFinalData()
	local type = 3
	local group = 0
	local round = self._curRound
	local groupType = self._curGroup
	gModelSimuFight:OnSimulateGroupInfoReq(type,group,round,groupType)
end

function UISubSuFinal:SetStaticContent()
	--local str = "巅峰组"
	--self:SetWndTabText(self.mBtnPeak,str)
	--str = "精英组"
	--self:SetWndTabText(self.mBtnElite,str)

	local str =ccClientText(25201) -- "冠军"
	self:SetWndText(self.mTitleChampion,str)
	str =ccClientText(25200)-- "冠军争夺"
	self:SetWndButtonText(self.mBtnChampion,str)
	str = ccClientText(25202) --"季军争夺"
	self:SetWndButtonText(self.mBtnThird,str)

	str = ccClientText(25114)--"详情"
	self:SetTextTile(self.mBtnDetail,str)

	str =ccClientText(25203) -- "虚位以待"

	self:SetWndText(self.mEmptyTips,str)

	str = ccClientText(46009) --"布阵"
	self:SetTextTile(self.mBtnFormation,str)

	--str = "虚位以待"
	--self:SetWndText(self.mEmptyTips,str)
	self:InitGroupTypeBtn()
	self:RefreshLowGroup()

	-- self:CreateWndSpine(self.mSpineRoot,"Guangjunqizhi","flag")
	-- self:CreateWndSpine(self.mSpineRoot_1,"Aozimonizhan","bgSpine")

end

function UISubSuFinal:ChangeToOther()
	if self._curGroup == 1 then
		self._curGroup = 2
	else
		self._curGroup = 1
	end

	self:ReqFinalData()

	self:RefreshGroupTypeBtnShow()
end

function UISubSuFinal:RefreshFormationRed()
	local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_FINAL_FORMATION)

	local redPointData = gModelRedPoint:GetRedPointNetData(ModelRedPoint.SIMU_FINAL_FORMATION)
	local groupType = nil
	if redPointData then
		local info = redPointData.defaultInfo
		groupType = tonumber(info)
	end



	local showFormation = self:CheckShowFormationSet()
	local redRound = self._curRound
	if not showFormation then
		redRound = self._curRound == 1 and 2 or 1
	end

	local redTran = self:FindWndTrans(self.mBtnFormation,"redPoint")
	CS.ShowObject(redTran,showRed)

	local showTabRed = showRed and redRound == 1 and groupType == self._curGroup
	redTran =self:FindWndTrans(self.mBtnThird,"redPoint")
	CS.ShowObject(redTran,showTabRed)
	showTabRed = showRed and redRound == 2 and groupType == self._curGroup
	redTran =self:FindWndTrans(self.mBtnChampion,"redPoint")
	CS.ShowObject(redTran,showTabRed)

end

function UISubSuFinal:OnClickLowGroup(index)
	if self._curRound == index then
		return
	end

	self._curRound = index

	--self:RefreshContent()
	self:ReqFinalData()
end

function UISubSuFinal:CheckShowFormationSet()
	local show = true
	if not gModelSimuFight:IsInStage(ModelSimuFight.SCHEDULE_GROUP_BATTLE,ModelSimuFight.BATTLE_READY) then
		show = false
	end

	local playerId = gModelPlayer:GetPlayerId()

	local info = self._battleInfo
	if info then
		if playerId ~= info.attack.playerId and playerId ~= info.defense.playerId then
			show = false
		end
	else
		show = false
	end

	return show
end

function UISubSuFinal:ShowPreparePart()
	local battleInfo = self._battleInfo
	if battleInfo then

        local leftWin = false
        local rightWin = false
        local state = gModelSimuFight:GetBattleInfoState(battleInfo)
        if state == 3 then
            leftWin = battleInfo.winner == 1
            rightWin = battleInfo.winner == 2
        end

		self:SetPlayer(self.mLeftPart,battleInfo.attack,leftWin)
		self:SetPlayer(self.mRightPart,battleInfo.defense,rightWin)
	else
		self:SetPlayer(self.mLeftPart,{isEmpty = true})
		self:SetPlayer(self.mRightPart,{isEmpty = true})

	end

	CS.ShowObject(self.mVS,not battleInfo)
	CS.ShowObject(self.mBtnDetail,battleInfo ~= nil)
end

function UISubSuFinal:InitGroupTypeBtn()
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

function UISubSuFinal:OnWndRefresh()

	local curState = gModelSimuFight:GetState()
	local isNotStart =curState< ModelSimuFight.SCHEDULE_GROUP_BATTLE
	local initRound = nil
	if isNotStart then
		initRound = 2
	else
		initRound = 0
	end

	self._curGroup = self:GetWndArg("groupType") or 0
	self._curRound = self:GetWndArg("round") or initRound

	self:OnStateUpdate()

	--self:RefreshContent()

	self:ReqFinalData()
end

function UISubSuFinal:OnClickFormation()
	gModelSimuFight:OpenSetFormation()
end

function UISubSuFinal:OpenDetail()
	GF.OpenWnd("UIFightRecordMulti",{battleInfo = self._battleInfo})
end

function UISubSuFinal:OnTimer(key)
	if self._countDownKey == key then
		self:ShowGameCountDown()
	end
end

function UISubSuFinal:GetPara()
	return {groupType = self._curGroup,round = self._curRound}
end

function UISubSuFinal:InitData()

	self._countDownKey = "_countDownKey"
end

function UISubSuFinal:InitUIEvent()
	--self:SetWndClick(self.mBtnPeak,function () self:OnClickTopGroup(1) end)
	--self:SetWndClick(self.mBtnElite,function () self:OnClickTopGroup(2) end)

	self:SetWndClick(self.mBtnThird,function () self:OnClickLowGroup(1) end)
	self:SetWndClick(self.mBtnChampion,function () self:OnClickLowGroup(2) end)

	self:SetWndClick(self.mBtnDetail,function () self:OpenDetail() end)
	self:SetWndClick(self.mBtnHelp,function ()
		GF.OpenWnd("UIBzTips",{refId =111})
	end)

	self:SetWndClick(self.mBtnFormation, function ()
		self:OnClickFormation()
	end)
end


function UISubSuFinal:OnStateUpdate()
	self:TimerStop(self._countDownKey)
	if self:ShowGameCountDown() then
		self:TimerStart(self._countDownKey,1,false,-1)
	end

	self:ReqFinalData()

	--self:RefreshDetailBtn()
	--self:RefreshBtnFormationShow()

	self:RefreshBtnEffect()

end

function UISubSuFinal:RefreshBtnFormationShow()
	local show = self:CheckShowFormationSet()

	CS.ShowObject(self.mBtnFormation,show)
end

function UISubSuFinal:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateGroupInfoResp,function (pb)
		self:OnSimulateGroupInfoResp(pb)
	end)

	self:WndEventRecv(EventNames.SIMULATE_STATE_CHANGE,function ()
		self:OnStateUpdate()
	end)

	self:RegisterRedPointFunc(ModelRedPoint.SIMU_FINAL_FORMATION,function ()
		self:RefreshFormationRed()
	end)
end

function UISubSuFinal:ShowResultPart()

	local hide = self._curRound == 1
	CS.ShowObject(self.mResultPart,not hide)
	if hide then
		return
	end

	local curState = gModelSimuFight:GetState()
	local isFinish = curState > ModelSimuFight.SCHEDULE_GROUP_BATTLE

	local isShow = isFinish and self._curRound == 2

	CS.ShowObject(self.mChamPart,isShow)
	CS.ShowObject(self.mEmptyTips,not isShow)


	local itemdata = self._winPlayer
	if not itemdata then
		return
	end

	local playerInfo =
	{
		trans = self.mHeadIconCham,
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
		level = itemdata.grade,
		func = function()
			gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)

	self:SetWndText(self.mNameCham,itemdata.name)
    self:SetWndText(self.mServerCham,itemdata.serverName)
end

function UISubSuFinal:RefreshDetailBtn()
	if not self._battleInfo then
		return
	end
	local isStart = gModelSimuFight:IsBattleInfoStart(self._battleInfo)
	CS.ShowObject(self.mVS,not isStart)
	CS.ShowObject(self.mBtnDetail,isStart)
end

function UISubSuFinal:OnClickGroup(index)
	if self._curRound == index then
		return
	end

	self._curRound = index

	self:RefreshLowGroup()
	--self:RefreshContent()
	self:ReqFinalData()


end

------------------------------------------------------------------
return UISubSuFinal


