---
--- Created by Administrator.
--- DateTime: 2023/10/20 11:51:41
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSuSchedule:LChildWnd
local UISubSuSchedule = LxWndClass("UISubSuSchedule", LChildWnd)
local Tweening = DG.Tweening

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSuSchedule:UISubSuSchedule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSuSchedule:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSuSchedule:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSuSchedule:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()
	self:InitEvent()

	self._curGroup = 0
	self._curPartIndex = self:GetInitPart()
	self.curState = gModelSimuFight:GetState()
	self._curGroupId = 0

	self:ReqScheduleData()

	gModelSimuFight:OnSimulateGroupReq()
end

function UISubSuSchedule:OnClickBtnDetail()
	local groupType = self._curGroup or 1
	local page = 1
	if self._curPartIndex == 3 then
		page = 2
	elseif self._curPartIndex == 4 then
		page = 3
	elseif self._curPartIndex == 5 then
		page = 4
	elseif self._curPartIndex == 6 then
		page = 5
	end
	GF.OpenWnd("UISuMin",{page = page,pagePara ={groupType = groupType  }})
end

function UISubSuSchedule:ModifyUIPara()
	local partData = self._scheduleDataList[self._curPartIndex]
	if not partData then
		return
	end

	self:RefreshScheduleSlider()

	self.mSchedulePart.anchoredPosition = partData.pos1
	-- self.mBgpart.sizeDelta = partData.sizeDelta

	if partData.pos2 then
		self.mBtnGroupType.localPosition = partData.pos2
	end

	if partData.pos3 then
		self.mBtnExhiMatch.localPosition = partData.pos3
	end
end

function UISubSuSchedule:OnDrawPlayer(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local frame = self:FindWndTrans(AniRoot,"frame")
	local AniRootHeadRoot = self:FindWndTrans(AniRoot,"headRoot")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootServerName = self:FindWndTrans(AniRoot,"serverName")
	local AniRootScore = self:FindWndTrans(AniRoot,"score")
	local AniRootRankIcon = self:FindWndTrans(AniRoot,"rankIcon")


	self:SetWndText(AniRootName,itemdata.playerName)
	self:InitTextModeWithLanguage(AniRootName, nil , gLGameLanguage:IsForeignRegion())
	self:SetWndText(AniRootServerName,string.format("【%s】",itemdata.serverName))
	local str =ccClientText(25195)-- "积分：%s"
	self:SetWndText(AniRootScore,string.replace(str,itemdata.score))

	local headTran = self:FindWndTrans(AniRootHeadRoot,"HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
		level = itemdata.level,
		func = function()
			gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)


	local iconPath = "herobook1_bg_di_5"
	local framePath = "hero_frame1_5"
	if itempos>2 then
		iconPath = "herobook1_bg_di_4"
		framePath = "hero_frame1_4"
	end

	self:SetWndEasyImage(AniRootImage,iconPath)
	self:SetWndEasyImage(frame,framePath)

	local showRankIcon = itempos <= 2
	local icon = self._rankIconList[itempos]
	CS.ShowObject(AniRootRankIcon,showRankIcon)
	if showRankIcon then
		self:SetWndEasyImage(AniRootRankIcon,icon)
	end
end

function UISubSuSchedule:OpenBreakRank()
	GF.OpenWnd("UIRkPop",{refId =ModelRank.RANK_1800,sid = self._curGroup})
end



function UISubSuSchedule:SelectSignGroup(index)
	local isSignState = gModelSimuFight:GetState() == ModelSimuFight.SCHEDULE_SIGN
	if not isSignState then
		local curSignGroup = self._curSignGroup or 0
		local isSignUp = curSignGroup ~= 0
		local str = ""
		if isSignUp then
			local strFormat = ccClientText(25223) --"当前已参加%s的比赛"
			local groupName = gModelSimuFight:GetGroupName(curSignGroup)
			str = string.replace(strFormat,groupName)
		else
			str = ccClientText(25278) --"报名阶段已结束"
		end
		GF.ShowMessage(str)
		return
	end

	self._selSignUpGroup = index


	self:RefreshSignSelect()
end



function UISubSuSchedule:OnDrawTab(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootOff = self:FindWndTrans(AniRoot,"off")
	local AniRootOn = self:FindWndTrans(AniRoot,"on")
	local AniRootIconOn = self:FindWndTrans(AniRoot,"iconOn")
	local AniRootIconOff = self:FindWndTrans(AniRoot,"iconOff")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootCheckbg = self:FindWndTrans(AniRoot,"checkbg")
	local AniRootCheck = self:FindWndTrans(AniRoot,"check")

	self:SetWndText(AniRootName,itemdata.name)
	local isSelect = self._curPartIndex == itemdata.index
	CS.ShowObject(AniRootOff,not isSelect)
	CS.ShowObject(AniRootOn,isSelect)
	CS.ShowObject(AniRootOff,not isSelect)

	CS.ShowObject(AniRootIconOn,isSelect)
	CS.ShowObject(AniRootIconOff,not isSelect)

	self:SetWndEasyImage(AniRootIconOn,itemdata.imageOn)
	self:SetWndEasyImage(AniRootIconOff,itemdata.imageOff)

	local isLock = itemdata.schedule > gModelSimuFight:GetState()

	CS.ShowObject(AniRootCheck,not isLock)
	self:SetWndClick(AniRoot,function() self:OnClickTab(itemdata) end)
end

function UISubSuSchedule:OnClickFlower()
	GF.OpenWnd("UISuFlowerDetail")
end

function UISubSuSchedule:ShowFinalPart()
	self:RefreshPartShow(6)
	self:RefreshTopPart()

	--local str = "夺冠对决"
	--self:SetWndText(self.mSemiTitle,str)

	local str = ccClientText(25243) --"总决赛正式开始~冠军争夺战、季军争夺战精彩对决！"
	self:SetWndText(self.mFinalTip,str)

	local info = self._scheduleData.infos
	local playerDataList = {}
	for k,v in ipairs(info) do
		local playerData =
		{
			name= v.name,
			server = v.serverName,
			head = v.head,
			headFrame = v.headFrame,
			level = v.grade,
			playerId = v.playerId,
			rank = v.rank,
		}
		table.insert(playerDataList,playerData)
	end

	table.sort(playerDataList,function (a,b)
		return a.rank < b.rank
	end)

	self:SetPlayerContent(self.mLeftPlayer,playerDataList[1])
	self:SetPlayerContent(self.mRightPlayer,playerDataList[2])

end

function UISubSuSchedule:InitData()
	self._scheduleDataList =
	{
		[1] = {
			index = 1,
			schedule = ModelSimuFight.SCHEDULE_FINALISTS,
			name = ccClientText(25101) ,--"选拔赛",
			imageOn = "simulate_btn_9_1",
			imageOff = "simulate_btn_9_2",
			sliderValue = 0.055,
			pos1 = Vector3.New(7.7,692),
			sizeDelta = Vector2.New(640,612),
			--pos2 = Vector3.New(0,0,0),
		},
		[2] = {
			index = 2,
			schedule = ModelSimuFight.SCHEDULE_SIGN,
			name = ccClientText(25102),--"报名",
			imageOn = "simulate_btn_6_1",
			imageOff = "simulate_btn_6_2",
			sliderValue = 0.24,
			pos1 = Vector3.New(7.7,678),
			sizeDelta = Vector2.New(640,612),

		},
		[3] = {
			index = 3,
			schedule = ModelSimuFight.SCHEDULE_BREAKOUT,
			name = ccClientText(25103), --"突围赛",
			imageOn = "simulate_btn_7_1",
			imageOff = "simulate_btn_7_2",
			sliderValue = 0.4,
			pos1 = Vector3.New(7.7,692),
			sizeDelta = Vector2.New(640,645),
			pos2 = Vector3.New(0,2,0),
			pos3 = Vector3.New(263.4,-11.5,0),
		},
		[4] = {
			index = 4,
			schedule = ModelSimuFight.SCHEDULE_GROUP_INIT,
			name = ccClientText(25104), --"小组赛",
			imageOn = "simulate_btn_8_1",
			imageOff = "simulate_btn_8_2",
			sliderValue = 0.6,
			pos1 = Vector3.New(7.7,840),
			sizeDelta = Vector2.New(640,840),
			pos2 = Vector3.New(0,136,0),
			pos3 = Vector3.New(263.4,139.4,0),

		},
		[5] = {
			index = 5,
			schedule = ModelSimuFight.SCHEDULE_GROUP_WARM_UP,
			name = ccClientText(25105), -- "半决赛",
			imageOn = "simulate_btn_5_1",
			imageOff = "simulate_btn_5_2",
			sliderValue = 0.78,
			pos1 = Vector3.New(7.7,826),
			sizeDelta = Vector2.New(640,828),
			pos2 = Vector3.New(0,122,0),
			pos3 = Vector3.New(263.4,147,0),

		},
		[6] = {
			index = 6,
			schedule = ModelSimuFight.SCHEDULE_GROUP_BATTLE,
			name = ccClientText(25106), -- "总决赛",
			imageOn = "simulate_btn_10_1",
			imageOff = "simulate_btn_10_2",
			sliderValue = 1,
			pos1 = Vector3.New(7.7,629),
			sizeDelta = Vector2.New(640,591),
			pos2 = Vector3.New(0,-64,0),
			pos3 = Vector3.New(458,127,0),

		},

	}


	self._groupDataList =
	{
		[1] =
		{
			index = 1,
			iconPath = "A",
		},
		[2] =
		{
			index = 2,
			iconPath = "B",
		},
		[3] =
		{
			index = 3,
			iconPath = "C",
		},
		[4] =
		{
			index = 4,
			iconPath = "D",
		},
		[5] =
		{
			index = 5,
			iconPath = "E",
		},
		[6] =
		{
			index = 6,
			iconPath = "F",
		},
		[7] =
		{
			index = 7,
			iconPath = "G",
		},
		[8] =
		{
			index = 8,
			iconPath = "H",
		},
	}

	--self._stageStrList =
	--{
	--	[1] = "准备阶段：%s",
	--	[2] = "预热阶段：%s",
	--	[3] = "战斗阶段：%s",
	--}



	self._rankIconList =
	{
		[1] = "public_num_1",
		[2] = "public_num_2",
		[3] = "public_num_3",
	}

	self._signUpCdKey = "_signUpCdKey"

	self._stateCdKey = "_stateCdKey"

	self._isForeign = gLGameLanguage:IsForeignVersion()
end
function UISubSuSchedule:OnClickSetFormation()
	gModelSimuFight:OpenSetFormation()
end

function UISubSuSchedule:InitUIEvent()
	self:SetWndClick(self.mBtnAchieve,function () self:OnClickAchieve() end)
	self:SetWndClick(self.mBtnFlower,function () self:OnClickFlower() end)
	self:SetWndClick(self.mBtnPalace,function () self:OnClickPalace() end)
	self:SetWndClick(self.mBtnGroup,function () self:OnClickServerGroup() end)
	self:SetWndClick(self.mBtnNews,function () self:OnClickNews() end)
	self:SetWndClick(self.mBtnShop,function () self:OnClickShop() end)
	self:SetWndClick(self.mBtnFlower,function () self:OnClickFlower() end)
	self:SetWndClick(self.mBtnGoRank,function () self:OnClickGoRank() end)


	--self:SetWndClick(self.mBtnPeak,function () self:OnClickGroup(1) end)
	--self:SetWndClick(self.mBtnElite,function () self:OnClickGroup(2) end)

	self:SetWndClick(self.mBtnSignUp,function () self:OnClickSignUp() end)

	self:SetWndClick(self.mPeakGroup,function () self:SelectSignGroup(1) end)
	self:SetWndClick(self.mEliteGroup,function () self:SelectSignGroup(2) end)

	self:SetWndClick(self.mBtnExhiMatch,function () self:OnClickExhi() end)

	self:SetWndClick(self.mBtnFormation,function ()
		self:OnClickSetFormation()
	end)

	self:SetWndClick(self.mBtnViewDetail,function ()
		self:OnClickBtnDetail()
	end)

	self:SetWndClick(self.mBtnHelp,function ()
		GF.OpenWnd("UIBzTips",{refId = 107})
	end)

	self:SetWndClick(self.mBtnMenu,function ()
		GF.OpenWnd("UISuBz")
	end)

	self:SetWndClick(self.mBtnBreakRank,function ()
		self:OpenBreakRank()
	end)
end

function UISubSuSchedule:ShowGroupContent()
	local groupInfo = self._scheduleData.groupInfos

	local playerDataList = {}
	for k,v in ipairs(groupInfo) do
		local playerData =
		{
			playerName= v.name,
			serverName = v.serverName,
			score = v.score,
			head = v.head,
			headFrame = v.headFrame,
			level = v.grade,
			playerId = v.playerId,
			rank = v.rank,
		}

		table.insert(playerDataList,playerData)
	end

	table.sort(playerDataList,function (a,b)
		return a.rank< b.rank
	end)


	local playerList = self:FindUIScroll("playerList")
	if not playerList then
		playerList = self:GetUIScroll("playerList")
		playerList:Create(self.mPlayerList,playerDataList,function (...) self:OnDrawPlayer(...) end,UIItemList.SUPER_GRID)
	else
		playerList:RefreshList(playerDataList)
	end

	playerList:DrawAllItems()
end

function UISubSuSchedule:ShowMsgList()
	local msgList = self._flowerMsgList or {}

	local tranList = self._msgTranList
	if not tranList then
		tranList = {}
		self._msgTranList = tranList
		for k=1,4 do
			local tran = self:FindWndTrans(self.mMsgRoot,"msg_"..k)
			local data = {index = k,tran = tran,localPos= tran.localPosition}
			table.insert(tranList,data)
		end
	end

	local cnt = #msgList

	local setFun = function()
		local msgStartIndex = self._msgIndex or 0
		if cnt <= 3 then
			for k= 1,4 do
				local index = k
				local data = msgList[index]
				self:OnDrawMsg(tranList[index],data)
			end
			return
		else
			msgStartIndex = msgStartIndex + 1
		end

		if msgStartIndex > cnt then
			msgStartIndex = 1
		end
		self._msgIndex = msgStartIndex


		local tranIndex = 1
		for k= msgStartIndex,msgStartIndex+ 3 do
			local index = k
			if k>cnt then
				index = (k - 1) % cnt + 1
			end

			local data = msgList[index]
			self:OnDrawMsg(tranList[tranIndex],data,tranIndex)
			tranIndex = tranIndex + 1
		end


		self.mMsgRoot.localPosition = Vector3.zero
	end

	if cnt<= 3 then
		setFun()
		return
	end

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("msgMove")

	seq:AppendCallback(setFun)
	seq:AppendInterval(1.5)
	local moveTween = self.mMsgRoot:DOLocalMoveY(35,0.5)
	seq:Append(moveTween)
	seq:SetLoops(-1)
	seq:PlayForward()

end


function UISubSuSchedule:OnClickAchieve()
	GF.OpenWnd("UISuResult")
end

function UISubSuSchedule:RefreshScheduleSlider()
	local curPart = self:GetInitPart()
	local curPartData = self._scheduleDataList[curPart]
	LxUiHelper.SetProgress(self.mScheduleSlider,curPartData.sliderValue)
end

function UISubSuSchedule:ShowHalfPart()
	self:RefreshPartShow(5)
	self:RefreshTopPart()


	local hyper = UIHyperText:New()
	hyper:Create(self.mIntro)
	local strFormat = ccClientText(25240) --"16名选手开始争夺冠军~将您手中的献花献给心目中的胜者吧！%s"
	local hyStr = ccClientText(25241) --"<#d2730f>点击献花</color>"
	local str = hyper:AddHyper(hyStr,{func = function () self:OnClickSendChamFlower() end})

	self:SetWndText(self.mIntro,string.replace(strFormat,str))

	local str = ccClientText(25242) --"热门夺冠选手"
	self:SetWndText(self.mSemiTitle,str)

	local fireInfos = self._scheduleData.fireInfos
	local flowerList = self._scheduleData.flowers

	local playerDataList = {}
	for k,v in ipairs(fireInfos) do
		local playerData =
		{
			name= v.name,
			serverName = v.serverName,
			head = v.head,
			headFrame = v.headFrame,
			level = v.grade,
			playerId = v.playerId,
			flower = flowerList[k]
		}
		table.insert(playerDataList,playerData)
	end

	local msgList = self._scheduleData.flowerList
	self._flowerMsgList = {}
	for k,v in ipairs(msgList) do
		local strs = string.split(v,"|")
		local data =
		{
			emoRefId = tonumber(strs[1]),
			name = strs[2],
			count = strs[3],
		}

		table.insert(self._flowerMsgList,data)

	end

	--local data =
	--{
	--	emoRefId =1,
	--	name = "lala",
	--	count =1000,
	--}
	--table.insert(self._flowerMsgList,data)
	--table.insert(self._flowerMsgList,data)
	--table.insert(self._flowerMsgList,data)
	--table.insert(self._flowerMsgList,data)


	self:ShowMsgList()


	-- local hotList = self:FindUIScroll("hotList")
	-- if not hotList then
	-- 	hotList = self:GetUIScroll("hotList")
	-- 	hotList:Create(self.mHotList,playerDataList,function (...) self:OnDrawHotPlayer(...) end)
	-- else
	-- 	hotList:RefreshList(playerDataList)
	-- end

	for i = 1, 3 do
		local item = self['mHot' .. i]
		self:OnDrawHotPlayer(nil,item,playerDataList[i],i)
	end
end

function UISubSuSchedule:OnClickSendChamFlower()
	GF.OpenWnd("UISSyendFlower",{wndType =2,groupType = self._curGroup})
end

function UISubSuSchedule:OnClickExhi()
	GF.OpenWnd("UISuIns")
end

function UISubSuSchedule:OnClickGoRank()

	local state = gModelSimuFight:GetState()
	if state > ModelSimuFight.SCHEDULE_FINALISTS then
		local str = ccClientText(25225) --"选拔赛已结束"
		GF.ShowMessage(str)
		return
	end

	GF.OpenWnd("UIringRk",{backFunc = function ()
		GF.OpenWnd("UISuMin")
	end})
	GF.CloseWndByName("UISuMin")
end

function UISubSuSchedule:GetInitPart()
	local curState = gModelSimuFight:GetState()
	printInfoN("simulate state "..curState)
	local select = 1
	for k,v in ipairs(self._scheduleDataList) do
		if curState >= v.schedule then
			select = k
		end
	end
	return select
end

function UISubSuSchedule:RefreshSignSelect()
	local select = self:FindWndTrans(self.mPeakGroup,"select")
	CS.ShowObject(select,self._selSignUpGroup == 1)
	local select = self:FindWndTrans(self.mEliteGroup,"select")
	CS.ShowObject(select,self._selSignUpGroup == 2)
end

function UISubSuSchedule:OnTimer(key)
	if self._stateCdKey == key then
		self:SetCountDown()
	elseif self._signUpCdKey == key then
		self:ShowSignUpCd()
	end
end

function UISubSuSchedule:ReqScheduleData()

	local partData = self._scheduleDataList[self._curPartIndex]
	local schedule = partData.schedule

	gModelSimuFight:OnSimulateScheduleInfoReq(self._curGroupId,schedule,self._curGroup)
end

function UISubSuSchedule:ShowGroupPart()

	self:RefreshTopPart()
	self:RefreshPartShow(4)

	local curState = gModelSimuFight:GetState()
	--
	local isInit = curState == ModelSimuFight.SCHEDULE_GROUP_INIT
	CS.ShowObject(self.mEmptyTip,isInit)
	CS.ShowObject(self.mPlayerList,not isInit)
	-- CS.ShowObject(self.mGroupList,not isInit)


	local uiList = self:FindUIScroll("groupList")
	if not uiList then
		uiList= self:GetUIScroll("groupList")
		uiList:Create(self.mGroupList,self._groupDataList,function (...) self:OnDrawGroup(...)  end)
	else
		uiList:DrawAllItems(false)
	end

	self:ShowGroupContent()
end

function UISubSuSchedule:RefreshGoRankShow()
	local state = gModelSimuFight:GetState()
	local isGray = state > ModelSimuFight.SCHEDULE_FINALISTS

	self:SetWndButtonGray(self.mBtnGoRank,isGray)
end

function UISubSuSchedule:OnDrawHotPlayer(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootframe = self:FindWndTrans(AniRoot,"frame")
	local AniRootHeadRoot = self:FindWndTrans(AniRoot,"headRoot")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootServer = self:FindWndTrans(AniRoot,"server")
	local AniRootLayout = self:FindWndTrans(AniRoot,"layout")
	local layoutIcon = self:FindWndTrans(AniRoot,"rankIcon")
	-- local layoutNum = self:FindWndTrans(AniRootLayout,"num")

	local framePath = "herobook1_bg_di_5"
	local res = "hero_frame1_5"
	local rankIcon = "public_num_1"
	if itempos == 2 then
		framePath = "herobook1_bg_di_5"
		res = "hero_frame1_5"
		rankIcon = "public_num_2"
	elseif itempos == 3 then
		framePath = "herobook1_bg_di_4"
		res = "hero_frame1_4"
		rankIcon = "public_num_3"
	end

	self:SetWndEasyImage(AniRootImage,framePath)
	self:SetWndEasyImage(AniRootframe,res)
	self:SetWndEasyImage(layoutIcon,rankIcon)


	local str = string.format("【%s】",itemdata.serverName)
	self:SetWndText(AniRootServer,str)
	self:SetWndText(AniRootName,itemdata.name)
	self:InitTextModeWithLanguage(AniRootName)
	-- self:SetWndText(layoutNum,itemdata.flower)
	local headTran = self:FindWndTrans(AniRootHeadRoot,"HeadIcon")
	local playerInfo =
	{
		trans = headTran,
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
		level = itemdata.level,
		func = function()
			gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)

end

function UISubSuSchedule:ChangeToOther()
	if self._curGroup == 1 then
		self._curGroup = 2
	else
		self._curGroup = 1
	end

	self:ReqScheduleData()

	self:RefreshGroupTypeBtnShow()
end

function UISubSuSchedule:ShowSignUpCd()
	local signUpTime = self._cancelTime
	local endTime = gModelSimuFight:GetPara("applyCd") + signUpTime
	local timeLeft = endTime - GetTimestamp()
	if timeLeft >= 0 then
		local str = string.replace(ccClientText(25236),math.ceil(timeLeft))
		self:SetWndText(self.mSignCd,str)
		return true
	else
		self:SetWndText(self.mSignCd,"")
		return false
	end
end


function UISubSuSchedule:SetPlayerContent(item,playerData)
	if not playerData then
		return
	end

	local name = self:FindWndTrans(item,"name")
	local server = self:FindWndTrans(item,"server")

	local headTran = self:FindWndTrans(item,"HeadIcon")
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

	self:SetWndText(name,playerData.name)
	self:SetWndText(server,string.format("<#30e055>【%s】</color>",playerData.server))
end

function UISubSuSchedule:OnDrawRankItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootRankIcon = self:FindWndTrans(AniRoot,"rankIcon")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootDetail = self:FindWndTrans(AniRoot,"detail")

	self:SetWndText(AniRootName,itemdata.name)
	local str = string.replace(ccClientText(25239),itemdata.winCount,itemdata.failCount)
	self:SetWndText(AniRootDetail,str)
	local iconPath = self._rankIconList[itempos]
	self:SetWndEasyImage(AniRootRankIcon,iconPath)

	self:SetWndClick(AniRoot,function () gModelGeneral:PlayerShowReq(itemdata.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM) end)
end



function UISubSuSchedule:OnSimulateScheduleInfoResp(pb)
	local partData = self._scheduleDataList[self._curPartIndex]
	local schedule = partData.schedule
	if schedule ~= pb.type then
		return
	end

	if self._curGroup == 0 then
		self._curGroup = pb.group
	end

	local groupId= pb.groupId
	if self._curGroupId == 0 then
		self._curGroupId = groupId
	end

	if self._curGroup ~= pb.group then
		return
	end

	if self._curGroupId ~= groupId then
		return
	end


	self._scheduleData = pb

	self._signInfo = self._scheduleData.signInfo


	self:ShowPartBtnList()
	self:ShowPartContent()

	self:RefreshGroupTypeBtnShow()

	self:RefreshFlowerRed()

end

function UISubSuSchedule:ShowBreakPartGroup()
	local breakInfo = self._scheduleData.breakInfo
	local peopleCnt = breakInfo.groupCount

	local strFromat = ccClientText(25231) --"参赛人数：%s"
	local str = string.replace(strFromat,peopleCnt)
	self:SetWndText(self.mPeopleNum,str)


	local str =ccClientText(25237) -- "未参加"
	if breakInfo.rank > 0 then
		str = string.replace(ccClientText(25238),breakInfo.rank)
	end
	self:SetWndText(self.mMyRank,str)


	local rankDataList = {}
	for k,v in ipairs(breakInfo.infos) do
		local winCount = breakInfo.winCount[k]
		local tempS = string.split(winCount,"_")
		local win = tempS[1] and tonumber(tempS[1]) or 0
		local total = tempS[2] and tonumber(tempS[2]) or 0
		local data =
		{
			winCount = win,
			failCount = total - win,
			rank = v.rank,
			name = v.name,
			playerId = v.playerId
		}

		table.insert(rankDataList,data)
	end

	local uiList = self:FindUIScroll("breakRankList")
	if not uiList then
		uiList= self:GetUIScroll("breakRankList")
		uiList:Create(self.mRankList,rankDataList,function (...) self:OnDrawRankItem(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(rankDataList)
	end

	uiList:DrawAllItems()
end


function UISubSuSchedule:ShowEndPart()
	self:RefreshPartShow(6)
	self:RefreshTopPart()
	CS.ShowObject(self.mEndPart,true)
	local str = ccClientText(25244) --"总决赛-冠军"
	self:SetWndText(self.mEndTitle,str)
	local format =ccClientText(25245) -- "总决赛已经结束~梦境者记得前往商店兑换奖励哦！%s"

	local hyper = self:GetUIHyperText(self.mEndTip)
	local str = ccClientText(25246)--"<#30e055>前往兑换</color>"

	str = hyper:AddHyper(str,{func = function () self:OnClickShop() end})
	local finalStr = string.replace(format,str)

	self:SetWndText(self.mEndTip,finalStr)
	self:InitTextSizeWithLanguage(self.mEndTip, -2)
	self:InitTextLineWithLanguage(self.mEndTip, -30)

	local info = self._scheduleData.infos

	local playerData = nil
	for k,v in ipairs(info) do
		if v.rank == 1 then
			playerData =
			{
				name= v.name,
				server = v.serverName,
				head = v.head,
				headFrame = v.headFrame,
				level = v.grade,
				playerId = v.playerId,
				rank = v.rank,
			}


		end

	end

	self:SetPlayerContent(self.mChamPlayer,playerData)

end

function UISubSuSchedule:SetStaticContent()
	local str = ccClientText(25186) -- "献花"
	self:SetTextTile(self.mBtnFlower,str)
	str = ccClientText(10362) -- "商店"
	self:SetTextTile(self.mBtnShop,str)
	str = ccClientText(25211) --"快讯"
	self:SetTextTile(self.mBtnNews,str)
	str = ccClientText(25162) --"分组"
	self:SetTextTile(self.mBtnGroup,str)
	str = ccClientText(25210) --"殿堂"
	self:SetTextTile(self.mBtnPalace,str)
	str = ccClientText(25212) --"成绩"
	self:SetTextTile(self.mBtnAchieve,str)

	-- str = "奥兹模拟战"
	self:SetTextTile(self.mTitle,ccClientText(25175))

	local str =ccClientText(25213) -- "选择其中一个小组报名"
	self:SetWndText(self.mSignUpIntro,str)

	--str = "精英组"
	--self:SetWndButtonText(self.mBtnElite,str)
	--str = "巅峰组"
	--self:SetWndButtonText(self.mBtnPeak,str)
	str = ccClientText(25214) -- "查看详情"
	self:SetWndButtonText(self.mBtnViewDetail,str)

	str = ccClientText(25215) --"前往排位赛"
	self:SetWndButtonText(self.mBtnGoRank,str)

	str = ccClientText(25188) --"珍稀奖励"
	self:SetWndText(self.mArrowTitle,str)

	str = ccClientText(46009) --"布阵"
	self:SetTextTile(self.mBtnFormation,str)

	str =ccClientText(11700) -- "排行榜"
	self:SetWndText(self.mRankTitle,str)

	--str = "半决赛火热进行中点击下方【赛事详情】前往观战吧"
	--self:SetWndText(self.mIntro,str)

	str =ccClientText(25217) -- "夺冠对决"
	self:SetWndText(self.mFinalTitle,str)

	str = ccClientText(25218) --"互动赛"
	self:SetTextTile(self.mBtnExhiMatch,str)

	str = ccClientText(25265)
	self:SetWndText(self.mSelectInfo1,str)
	str = ccClientText(25266)
	self:SetWndText(self.mSelectInfo2,str)

	self:ShowPartBtnList()

	self:InitGroupTypeBtn()


	self:CreateWndEffect(self.mBtnExhiMatch,"fx_baowu_kejihuo_2","exhibition",40)

	str = ccClientText(25331) --"分组中..."
	self:SetWndText(self.mEmptyTip,str)

	self:InitTextLineWithLanguage(self.mFinalTip,-40)
	local text = self:FindWndTrans(self.mBtnGroup,'UIText')
	self:InitTextLineWithLanguage(text,-40)
	text = self:FindWndTrans(self.mBtnAchieve,'UIText')
	self:InitTextLineWithLanguage(text,-40)
	text = self:FindWndTrans(self.mBtnPalace,'UIText')
	self:InitTextLineWithLanguage(text,-40)
end

function UISubSuSchedule:ShowPartBtnList()
	local tabList = self:FindUIScroll("tabList")
	if not tabList then
		tabList = self:GetUIScroll("tabList")
		tabList:Create(self.mTabList,self._scheduleDataList,function (...) self:OnDrawTab(...)  end)
	else
		tabList:RefreshList(self._scheduleDataList)
	end

	self:ModifyUIPara()

end

function UISubSuSchedule:OnDrawGroup(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootOff = self:FindWndTrans(AniRoot,"off")
	local AniRootOn = self:FindWndTrans(AniRoot,"on")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")

	local isSel = itemdata.index == self._curGroupId

	local color = "white"
	if isSel then
		color = "black"
	end
	self:SetWndText(AniRootUIText,LUtil.FormatColorStr(itemdata.iconPath,color))

	CS.ShowObject(AniRootOn,isSel)
	self:SetWndClick(AniRoot,function() self:OnClickGroupBtn(itemdata) end)

	local t = {
		"actionarena_btn_9",
		"actionarena_btn_10",
		"actionarena_btn_11",
		"actionarena_btn_12",
		"actionarena_btn_20",
		"actionarena_btn_21",
		"actionarena_btn_22",
		"actionarena_btn_23",
	}
	self:SetWndEasyImage(AniRootOff, t[itempos])
end

function UISubSuSchedule:RefreshTopPart()
	local startTime = gModelSimuFight:GetStartTime()/1000
	if not startTime then
		return
	end
	local endTime = gModelSimuFight:GetEndTime()

	local sy,sm,sd = LUtil.GetYmdByTimestamp(startTime)
	local ey,em,ed = LUtil.GetYmdByTimestamp(endTime)

	local str =string.replace(ccClientText(25305),fixedTimeToTwo(sm),fixedTimeToTwo(sd),fixedTimeToTwo(em),fixedTimeToTwo(ed))
	self:SetWndText(self.mTimeInfo,str)

	local schedule = self._scheduleDataList[self._curPartIndex]

	self:SetWndText(self.mSubTitle,schedule.name)
	self:SetWndText(self.mSubTitle_1,schedule.name)

	local state = gModelSimuFight:GetState()
	local isShopOpen = state> ModelSimuFight.SCHEDULE_GROUP_BATTLE
	if isShopOpen then
		self:CreateWndEffect(self.mBtnShop,"fx_baowu_kejihuo_2","shopOpen",40)
	else
		self:DestroyWndEffectByKey("shopOpen")
	end



	self:TimerStop(self._stateCdKey)
	if self:SetCountDown() then
		self:TimerStart(self._stateCdKey,1,false,-1)
	end

	self:RefreshScheduleSlider()

	local hasNews = gModelSimuFight:HasNews()
	CS.ShowObject(self.mBtnNews,hasNews)
end

function UISubSuSchedule:OnClickSignUp()
	if not self._signDataList then
		return
	end

	local curSignGroup = self._curSignGroup or 0

	local isSignUp = curSignGroup ~= 0

	local isSignState = gModelSimuFight:GetState() == ModelSimuFight.SCHEDULE_SIGN
	if isSignState then
		if isSignUp then
			gModelSimuFight:OnSimulateSignReq(curSignGroup)
		else
			local timeLeft =math.ceil(self._cancelTime + gModelSimuFight:GetPara("applyCd") - GetTimestamp())

			if timeLeft > 0  then
				local str = string.replace(ccClientText(25236),timeLeft)
				GF.ShowMessage(str)
				return
			end

			local selGroup = self._selSignUpGroup
			if selGroup == 0 then
				local str =ccClientText(25277) --"请选择其中一个小组进行报名"
				GF.ShowMessage(str)
				return
			end

			local signData = self._signDataList[selGroup]
			if not signData.canSigUp then
				local str =ccClientText(25221) --"未获得报名资格"
				GF.ShowMessage(str)
				return
			end

			local signLimit = signData.resonanceLevel
			local selfLv = gModelResonance:GetResonanceLv()
			if signLimit> selfLv then
				local strFormat= ccClientText(25222) --"报名%s组需要共鸣魔晶达到%s级"
				local groupName = gModelSimuFight:GetGroupName(selGroup) --self._groupNameList[selGroup]
				local str = string.replace(strFormat,groupName,signData.resonanceLevel)
				GF.ShowMessage(str)
				return
			end

			local callback = function()
				--local isEmpty = gModelFormation:IsFormationEmpty(LCombatTypeConst.COMBAT_TYPE_25)
				--if isEmpty then
				--	return
				--end
				gModelSimuFight:OnSimulateSignReq(selGroup)
			end

			--local formationList = gModelFormation:GetFormationList(LCombatTypeConst.COMBAT_TYPE_25)
			--if table.isempty(formationList) then
            --
			--	return
			--end

			gModelSimuFight:OpenSetFormation(callback)
			--callback()
		end
	else
		local str = nil
		if isSignUp then
			local strFormat = ccClientText(25223) --"当前已参加%s的比赛"
			local groupName = gModelSimuFight:GetGroupName(self._curSignGroup)
			str = string.replace(strFormat,groupName)
		else
			str = ccClientText(25278) --"报名阶段已结束"
		end

		GF.ShowMessage(str)
	end
end

function UISubSuSchedule:ShowGroupInfo(item,groupData)
	local Image = self:FindWndTrans(item,"Image")
	local select = self:FindWndTrans(item,"select")
	local name = self:FindWndTrans(item,"name")
	local layout = self:FindWndTrans(item,"layout")
	local layoutIntro_1 = self:FindWndTrans(layout,"intro_1")
	local layoutIntro_2 = self:FindWndTrans(layout,"intro_2")
	local layoutIntro_3 = self:FindWndTrans(layout,"intro_3")
	local layoutIntro_4 = self:FindWndTrans(layout,"intro_4")
	local signLimit = self:FindWndTrans(item,"signLimit")

	local addline = -40
	if gLGameLanguage:IsEnglishVersion() then
		addline = -10
	end

	self:InitTextLineWithLanguage(signLimit,addline)

	--local hide = gModelSimuFight:GetState()> ModelSimuFight.SCHEDULE_SIGN

	local name1 = ccLngText(gModelSimuFight:GetPara("groupName1"))
	local name2 = ccLngText(gModelSimuFight:GetPara("groupName2"))

	local nameStr = groupData.groupType == ModelSimuFight.GROUP_PINNACLE and name1 or name2
	self:SetWndText(name,nameStr)
	local str = string.replace(ccClientText(25231),groupData.peopleCnt)
	self:SetWndText(layoutIntro_1,str)
	str = string.replace(ccClientText(25232),LUtil.NumberCoversion(groupData.maxPower))
	self:SetWndText(layoutIntro_2,str)
	str = string.replace(ccClientText(25233),LUtil.NumberCoversion(groupData.minPower))
	self:SetWndText(layoutIntro_3,str)
	str = string.replace(ccClientText(25234),LUtil.NumberCoversion(groupData.avePower))
	self:SetWndText(layoutIntro_4,str)
	--str = string.replace(ccClientText(25235),groupData.resonanceLevel)
	--self:SetWndText(signLimit,str)

	--CS.ShowObject(layoutIntro_2,not hide)
	--CS.ShowObject(layoutIntro_3,not hide)

end


function UISubSuSchedule:OnDrawMsg(tranData,itemdata,tranIndex)
	local item = tranData.tran
	local isempty = itemdata == nil
	CS.ShowObject(item,not isempty)
	if isempty then
		return
	end

	local alpha = 1
	if tranIndex == 1 then
		alpha = 0.6
	elseif tranIndex == 2 then
		alpha = 0.8
	end

	self:SetCanvasGroupAlpha(item,alpha)
	--local Image = self:FindWndTrans(item,"Image")
	local layout = self:FindWndTrans(item,"layout")
	local layoutEmo = self:FindWndTrans(layout,"emo")
	local layoutName = self:FindWndTrans(layout,"name")
	--local layoutImage = self:FindWndTrans(layout,"Image")
	local layoutNum = self:FindWndTrans(layout,"num")


	local ref = gModelSimuFight:GetEmoRef(itemdata.emoRefId)
	if ref then
		self:SetWndEasyImage(layoutEmo,ref.icon)
	end

	local content = string.replace(ccClientText(25247),itemdata.name)
	self:SetWndText(layoutName,content)
	self:SetWndText(layoutNum,itemdata.count)

end

function UISubSuSchedule:OnClickShop()

	local isWithIn = gModelSimuFight:CanBuyRareGoods()
	local subPage
	if isWithIn then
		subPage = 2016
	else
		subPage = 2015
	end

	GF.OpenWnd("UIDian",{page = 2,subPage = subPage})
end

function UISubSuSchedule:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateScheduleInfoResp,function (...) self:OnSimulateScheduleInfoResp(...) end)
	self:WndNetMsgRecv(LProtoIds.SimulateSignResp,function (pb)
		self._signInfo = pb.info

		local signGroup = self._signInfo.group
		local str = ""
		if signGroup == 0 then
			str =ccClientText(25279) --"成功取消报名，可重新选择参赛组别"
		else
			local groupName = gModelSimuFight:GetGroupName(signGroup)
			str = string.replace(ccClientText(25280),groupName)
		end

		GF.ShowMessage(str)

		self:ShowPartContent()
	end)

	self:WndEventRecv(EventNames.SIMULATE_STATE_CHANGE,function ()
		self:RefreshTopPart()
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateGroupResp,function (pb)
		self._seasonInfo = pb
	end)

	self:RegisterRedPointFunc(ModelRedPoint.SIMU_SEMI_1_FLOWER,function ()
		self:RefreshFlowerRed()
	end)
	self:RegisterRedPointFunc(ModelRedPoint.SIMU_SEMI_2_FLOWER,function ()
		self:RefreshFlowerRed()
	end)

	self:WndEventRecv(EventNames.ON_SIMULATE_INTER_OPEN,function()
		if self.curState and self.curState ~= gModelSimuFight:GetState() then
			self._curGroup = 0
			self._curPartIndex = self:GetInitPart()
			self.curState = gModelSimuFight:GetState()
			self._curGroupId = 0
			self:ReqScheduleData()
			gModelSimuFight:OnSimulateGroupReq()
		end

		self:RefreshExhiMatch()
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateConfigResp,function ()
		self:ShowPartContent()
	end)

end

function UISubSuSchedule:SetCountDown()
	local curState = gModelSimuFight:GetState()

	local partData = self._scheduleDataList[self._curPartIndex]
	local isEnd = false
	if partData.schedule == ModelSimuFight.SCHEDULE_GROUP_INIT then
		isEnd = curState> ModelSimuFight.SCHEDULE_GROUP_READY
	else
		isEnd = curState > partData.schedule
	end

	self:InitTextSizeWithLanguage(self.mStateInfo, -2)
	self:InitTextLineWithLanguage(self.mStateInfo, -30)
	if isEnd then
		local str = ccClientText(25139) --"已结束"
		self:SetWndText(self.mStateInfo,str)
		return false
	end


	local timeLeft = gModelSimuFight:GetNextStageTime() - GetTimestamp()
	if timeLeft>= 0 then
		local str = gModelSimuFight:GetTimeShowFormat()
		local timeStr = string.replace(str,LUtil.FormatTimespanNumber(timeLeft))
		self:SetWndText(self.mStateInfo,timeStr)
		return true
	else
		self:SetWndText(self.mStateInfo,ccClientText(25139))
		return false
	end
end

function UISubSuSchedule:OnClickServerGroup()
	if not self._seasonInfo then
		return
	end

	gModelSimuFight:ShowServerGroup(self._seasonInfo)

end

function UISubSuSchedule:OnDrawReward(list,item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemRootIconRoot = self:FindWndTrans(itemRoot,"iconRoot")

    local showData =
    {
        itemId = itemdata.itemId,
        itemType = itemdata.itemType,
        itemNum = -1
    }

	self:CreateCommonIconImpl(itemRootIconRoot,showData,{showNum = false})

end

function UISubSuSchedule:OnClickGroupBtn(itemdata)
	if self._curGroupId == itemdata.index then
		return
	end

	self._curGroupId = itemdata.index

	self:ReqScheduleData()
end


function UISubSuSchedule:ShowSelectionPart()


	self:RefreshPartShow(1)

	self:RefreshTopPart()


	self:RefreshGoRankShow()
	local scheduleInfo = self._scheduleData
	local info1 =ccClientText(25226) -- "入围条件:排位赛排名前%s名,自动通过入围<br>        赛,可进入下轮报名分组环节"
	local rankLimit = gModelSimuFight:GetSignRankLimit()
	local str = string.replace(info1,rankLimit)

	self:SetWndText(self.mSelectInfo3,str)
	self:InitTextLineWithLanguage(self.mSelectInfo3, -30)
	self:InitTextSizeWithLanguage(self.mSelectInfo3, -2)

	local curRank = scheduleInfo.arenaRank
	local isIn =  curRank> 0 and curRank <= rankLimit
	str = nil
	if isIn then
		str = string.replace(ccClientText(25227) ,curRank)
	else
		if curRank < 0 then
			str = ccClientText(25330)
		else
			str = string.replace(ccClientText(25228) ,curRank)
		end

	end

	self:SetWndText(self.mSelectInfo4,str)

	local reward = gModelSimuFight:GetPlayTypeReward()
	local rewardDataList = LxDataHelper.ParseItem(reward)

	if not table.isempty(rewardDataList) then
		local uiList = self:FindUIScroll("rewardList")
		if not uiList then
			uiList = self:GetUIScroll("rewardList")
			uiList:Create(self.mRewardList,rewardDataList,function (...) self:OnDrawReward(...) end)
		else
			uiList:RefreshList(rewardDataList)
		end

		uiList:EnableScroll(true,true)
	end
end

function UISubSuSchedule:OnClickGroup(index)
	if self._curGroup == index then
		return
	end

	self._curGroup = index
	self._curGroupId = 0

	self:ReqScheduleData()
end

function UISubSuSchedule:OnClickTab(itemdata)

	if self._curPartIndex == itemdata.index then
		return
	end

	if itemdata.schedule > gModelSimuFight:GetState() then
		local str = ccClientText(25107) --"该赛程未解锁"
		GF.ShowMessage(str)
		return
	end

	self._curPartIndex =  itemdata.index

	self:ModifyUIPara()

	local uiList = self:FindUIScroll("tabList")
	if uiList then
		uiList:DrawAllItems(false)
	end

	self._curGroup = 0
	self._curGroupId = 0

	self:ReqScheduleData()
end

function UISubSuSchedule:OnClickPalace()
	GF.OpenWnd("UISuRk")
end

function UISubSuSchedule:OnClickNews()
	GF.OpenWnd("UISuNews")
end

function UISubSuSchedule:RefreshFlowerRed()
	local showRed1 = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_SEMI_1_FLOWER)
	local showRed2 = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_SEMI_2_FLOWER)


	local showRed = self._curGroup == ModelSimuFight.GROUP_PINNACLE and showRed1 or showRed2

	local redTran = self:FindWndTrans(self.mIntro,"redPoint")
	CS.ShowObject(redTran,showRed)

	local redTran = self:FindWndTrans(self.mBtnGroupType, "redPoint1")
	local isSemi = self._curPartIndex== 5
	CS.ShowObject(redTran,showRed1 and isSemi)
	redTran = self:FindWndTrans(self.mBtnGroupType, "redPoint2")
	CS.ShowObject(redTran,showRed2 and isSemi)

end

function UISubSuSchedule:RefreshPartShow(index)
	CS.ShowObject(self.mSchedule_1,index == 1)
	CS.ShowObject(self.mSchedule_2,index == 2)
	CS.ShowObject(self.mSchedule_3,index >= 3)

	CS.ShowObject(self.mBreakPart,index == 3)
	CS.ShowObject(self.mGroupPart,index == 4)
	CS.ShowObject(self.mSemiPart,index >= 5)
	CS.ShowObject(self.mHalfGamePart,index == 5)
	local state = gModelSimuFight:GetState()
	local showEnd = index == 6 and state > ModelSimuFight.SCHEDULE_GROUP_BATTLE
	local showFinal = index == 6 and state == ModelSimuFight.SCHEDULE_GROUP_BATTLE
	CS.ShowObject(self.mFinalGamePart,showFinal)
	CS.ShowObject(self.mEndPart,showEnd)


	CS.ShowObject(self.mSubTitle,index<6)
	CS.ShowObject(self.mSubTitle_1,index==6)
end

function UISubSuSchedule:ShowSignUpPart()
	self:RefreshPartShow(2)
	self:RefreshTopPart()

	local signDataList = {}

	local signInfo = self._signInfo
	self._cancelTime = signInfo.cancelSign/1000

	for k,v in ipairs(signInfo.signInfos) do
		local data = {}
		data.canSigUp = signInfo.sign == 1
		data.resonanceLevel = gModelSimuFight:GetSignLimit(k)
		data.minPower = v.minPower
		data.maxPower = v.maxPower
		data.avePower = v.avePower
		data.peopleCnt = v.groupCount
		data.groupType = k

		table.insert(signDataList,data)

	end

	self._signDataList = signDataList

	self._curSignGroup = signInfo.group

	self._selSignUpGroup = self._curSignGroup or 0
	--if self._selSignUpGroup == 0 then
	--	self._selSignUpGroup = 1
	--end
	self:RefreshSignSelect()


	local str = nil
	local isGray = false
	local isSignUp = self._curSignGroup ~= 0
	local isSignState = gModelSimuFight:GetState() == ModelSimuFight.SCHEDULE_SIGN
	local showFormationBtn = false
	if isSignState then
		showFormationBtn = true
		if isSignUp then
			str = ccClientText(25229) -- "取消报名"
		else
			str = ccClientText(25288) --"报名"
		end
	else
		if isSignUp then
			str = ccClientText(25230) --"已报名"
		else
			str = ccClientText(25288) --"报名"
		end

		isGray = true
	end

	CS.ShowObject(self.mBtnFormation,showFormationBtn)

	local tipStr = ""
	if isSignUp then
		local groupameKey = self._curSignGroup == 1 and "groupName1" or "groupName2"
		local groupName = ccLngText(gModelSimuFight:GetPara(groupameKey))
		tipStr = string.replace(ccClientText(25281),groupName)

	end

	self:SetWndText(self.mSignTip,tipStr)

	self:SetWndButtonText(self.mBtnSignUp,str,nil, -4, -30)
	self:SetWndButtonGray(self.mBtnSignUp,isGray)

	self:ShowGroupInfo(self.mPeakGroup,signDataList[1])
	self:ShowGroupInfo(self.mEliteGroup,signDataList[2])

	local isCd = self:ShowSignUpCd()
	if isCd then
		self:TimerStop(self._signUpCdKey)
		self:TimerStart(self._signUpCdKey,1,false,-1)
	end

end

function UISubSuSchedule:InitGroupTypeBtn()
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

function UISubSuSchedule:ShowBreakPart()

	self:RefreshTopPart()
	self:RefreshPartShow(3)

	self:ShowBreakPartGroup()

end

function UISubSuSchedule:RefreshExhiMatch()
	local isExhiMatchOpen = gModelSimuFight:IsInteractiveOpen()

	local curPart = self:GetInitPart()
	local isCurPart = curPart == self._curPartIndex

	CS.ShowObject(self.mBtnExhiMatch,isExhiMatchOpen and isCurPart)
end

function UISubSuSchedule:ShowPartContent()
	if not self._scheduleData then
		return
	end


	local iconPath= "simulate_bg_11"
	-- local arrowPath = "simulate_ui_3"
	if self._curPartIndex == 1 then
		self:ShowSelectionPart()
	elseif self._curPartIndex == 2 then
		self:ShowSignUpPart()
	elseif self._curPartIndex == 3 then
		self:ShowBreakPart()
	elseif self._curPartIndex == 4 then
		self:ShowGroupPart()
	elseif self._curPartIndex == 5 then
		self:ShowHalfPart()
	elseif self._curPartIndex == 6 then
		iconPath= "simulate_bg_12"
		-- arrowPath = "simulate_ui_4"

		local state = gModelSimuFight:GetState()
		if state == ModelSimuFight.SCHEDULE_GROUP_BATTLE then
			self:ShowFinalPart()
		else
			self:ShowEndPart()
		end
	end

	self:SetWndEasyImage(self.mTitleBg,iconPath)
	-- local isShowArrow = not self._isForeign
	-- if isShowArrow then
		-- self:SetWndEasyImage(self.mSubArrow_1,arrowPath)
		-- self:SetWndEasyImage(self.mSubArrow_2,arrowPath)
	-- end
	-- CS.ShowObject(self.mSubArrow_1, isShowArrow)
	-- CS.ShowObject(self.mSubArrow_2, isShowArrow)

	self:RefreshExhiMatch()
end

function UISubSuSchedule:RefreshGroupTypeBtnShow()
	local item = self.mBtnGroupType
	local btnOne = self:FindWndTrans(item,"btnOne")
	local btnTwo = self:FindWndTrans(item,"btnTwo")
	--local showOne = self._curGroup ==1
	CS.ShowObject(btnOne,self._curGroup ==1)
	CS.ShowObject(btnTwo,self._curGroup ==2)
end

------------------------------------------------------------------
return UISubSuSchedule


