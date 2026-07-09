---
--- Created by Administrator.
--- DateTime: 2023/10/29 10:27:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuIns:LWnd
local UISuIns = LxWndClass("UISuIns", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuIns:UISuIns()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuIns:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuIns:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuIns:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitUIEvent()
	self:InitEvent()
	self:SetStaticContent()
	self:RefreshTime()
	gModelSimuFight:OnSimulateInteractiveInfoReq()
end

function UISuIns:SetStaticContent()
	local str =ccClientText(25133) --"互动赛"
	self:SetWndText(self.mSubTitle,str)
	str = ccClientText(25114) --"详情"
	self:SetTextTile(self.mPlayerReportBtn,str)
	str = ccClientText(25134) --"其他赛事"
	self:SetTextTile(self.mBtnOther,str)
	str =ccClientText(25316)-- "我的支持")
	self:SetTextTile(self.mBtnMine,str)
	self:SetWndText(self.mTxtReturn,ccClientText(30205))

	for k,v in ipairs(self._teamBtnList) do
		CS.ShowObject(v,false)
	end

	local hyperText = self:GetUIHyperText(self.mShareText)
	local str = hyperText:AddHyper(ccClientText(25298),{func = function ()
		self:OnClickShare() end })

	self:SetWndText(self.mShareText,str)
	self:InitTextLineWithLanguage(self.mShareText, -30)
end

function UISuIns:OpenDetail()
	if not self._battleInfo then
		return
	end

	--local endTime = 0
	--if self._interactiveInfo.combatState == ModelSimuFight.INTERACT_BATTLE then
	--	endTime = self._interactiveInfo.nextTime
	--end

	GF.OpenWnd("UIFightRecordMulti",{battleInfo = self._battleInfo})
end

function UISuIns:RefreshFlowerPart()
	local flowerInfo =  self._flowerInfo --self._interactiveInfo.flowerInfo

	local str =ccClientText(25140) -- "支持人数：%s"

	local attackFlower = flowerInfo.attackFlower
	local defenceFlower = flowerInfo.defenceFlower

	if not (attackFlower > 0 or defenceFlower > 0) then
		local tmpFlowerInfo = self._battleInfo
		if tmpFlowerInfo then
			attackFlower = tmpFlowerInfo.attackFlower
			defenceFlower = tmpFlowerInfo.defenceFlower
		end
	end

	self:SetWndText(self.mLeftInfo,string.replace(str,attackFlower))
	self:SetWndText(self.mRightInfo,string.replace(str,defenceFlower))
	local total = (attackFlower or 0) + (defenceFlower or 0)
	local percent = 0
	if total>0 then
		percent = attackFlower / total
	end

	LxUiHelper.SetProgress(self.mOddsSlider,percent)

	local supportPlayer = flowerInfo.targetId
	local leftSupport = supportPlayer == self._leftPlayerId
	-- self:SetWndImageGray(self.mLSupport,leftSupport)
	local res = leftSupport and "video_btn_icon_5" or "video_btn_icon_6"
	local lSupportImg = self:FindWndTrans(self.mLSupport,"Image")
	self:SetWndEasyImage(lSupportImg,res)
	local str = leftSupport and ccClientText(25141) or ccClientText(25142)
	self:SetTextTile(self.mLSupport,str)
	local rightSupport = supportPlayer == self._rightPlayerId

	-- self:SetWndImageGray(self.mRSupport,rightSupport)
	local res = rightSupport and "video_btn_icon_5" or "video_btn_icon_6"
	local rSupportImg = self:FindWndTrans(self.mRSupport,"Image")
	self:SetWndEasyImage(rSupportImg,res)
	local str = rightSupport and ccClientText(25141) or ccClientText(25142)
	self:SetTextTile(self.mRSupport,str)

	local combatState = self._interactiveInfo.combatState
	local isNotSpport = combatState~= ModelSimuFight.INTERACT_SUPPORT
	local gray = leftSupport or rightSupport or isNotSpport

	local image = self:FindWndTrans(self.mLSupport,"icon")
	self:SetWndImageGray(image,gray)
	image = self:FindWndTrans(self.mRSupport,"icon")
	self:SetWndImageGray(image,gray)
end

function UISuIns:OnSimulateFlowerResp(pb)
	self._flowerInfo = pb.info

	self:RefreshFlowerPart()

	--gModelSimuFight:OnSimulateInteractiveInfoReq()
end

function UISuIns:OnStateChange()
	local isEnd = self:IsBattleEnd()

	local isEqual = false
	local winIcon_1 = self:FindWndTrans(self.mPlayer1,"winIcon")
	local winIcon_2 = self:FindWndTrans(self.mPlayer2,"winIcon")

	if isEnd then
		local winPath = "settlement_txt_2"
		local failPath = "settlement_txt_3"

		if self._battleInfo.winner == 1 then
			self:SetWndEasyImage(winIcon_1,winPath)
			self:SetWndEasyImage(winIcon_2,failPath)
		elseif self._battleInfo.winner == 2 then
			self:SetWndEasyImage(winIcon_1,failPath)
			self:SetWndEasyImage(winIcon_2,winPath)
		else
			isEqual = true
		end
	end
	CS.ShowObject(winIcon_1,isEnd and not isEqual)
	CS.ShowObject(winIcon_2,isEnd and not isEqual)
	CS.ShowObject(self.mEqual,isEqual)

	self:ShowReportBtnOrVs()
end

function UISuIns:ShowFormationContent()
	self._isEmptyFormation = false

	local reportInfo = self._reportList[self._curTeam + 1]
	if not reportInfo then
		return
	end

	local isEmpty = string.find(reportInfo.reportId,"EMPTY")
	self._isEmptyFormation = isEmpty
	if isEmpty then
		self:RefreshFormationContent()
		return
	end

	local reqInfo =
	{
		reportId = reportInfo.reportId,
		serverId = reportInfo.serverId,
		callback = function(reportTable)
			if self:IsWndClosed() then
				return
			end
			self:RefreshFormationContent(reportTable)
		end
	}

	self:GetReportTableCache(reqInfo)

end


function UISuIns:OnDrawMsg(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootTitleBg = self:FindWndTrans(AniRoot,"titleBg")
	local titleBgTitle = self:FindWndTrans(AniRootTitleBg,"title")
	local AniRootContent = self:FindWndTrans(AniRoot,"content")

	local titleStr =""
	local color
	-- local iconPath = ""
	if itemdata.type == 2 then
		titleStr = ccClientText(25142) --"支持"
		-- iconPath = "simulate_bg_18"
		color = "#0095FF"
	else
		titleStr = ccClientText(25145) --"主持人"
		-- iconPath = "simulate_bg_17"
		color = "#33C772"
	end

	local showBg = itempos %2 ==0
	CS.ShowObject(AniRootImage,showBg)

	-- self:SetWndEasyImage(AniRootTitleBg,iconPath, function()
	-- 	if self._isForeign then
	-- 		self:SetAnchorPos(AniRootTitleBg, self._titleBgForeignPos)
	-- 	end
	-- end)
	self:SetWndImageColor(AniRootTitleBg, color)
	for i = 1, 4 do
		local trans = CS.FindTrans(AniRootTitleBg, "Image" .. i)
		self:SetWndImageColor(trans, color)
	end
	self:SetWndText(titleBgTitle,titleStr)

	self:SetWndText(AniRootContent,itemdata.content)
	self:InitTextLineWithLanguage(AniRootContent, -30)
end

function UISuIns:RefreshWinTagShow()
	if not self._interactiveInfo then
		return
	end
	local index = self._curTeam + 1
	local isEnd = self:IsBattleEnd()
	local winTag = self:FindWndTrans(self.mPlayerTeam1,"winIcon")
	local winState = self._battleInfo:GetTeamWinState(index)
	local winPath = "settlement_txt_2"
	local failPath = "settlement_txt_3"
	CS.ShowObject(winTag,isEnd)

	self:SetWndEasyImage(winTag,winState == 1 and winPath or failPath)
	local winTag = self:FindWndTrans(self.mPlayerTeam2,"winIcon")
	CS.ShowObject(winTag,isEnd)
	self:SetWndEasyImage(winTag,winState == 2 and winPath or failPath)
end

function UISuIns:OnClickShare()
	if not self._battleInfo then
		return
	end
	local jsonStr = self._battleInfo:ToJson()
	local data = {
		root = self.mShareText,
		shareType = ModelChat.CHATSHARE_28,
		shareData = jsonStr,
	}
	gModelGeneral:OpenShareTip(data)
end

function UISuIns:OnTimer(key)
	if self._countdownKey == key then

		self:RefreshMsgList()
		self:ShowCountDown()
	end
end

function UISuIns:InitData()
	self._combatStrList =
	{
		[0] = ccClientText(25135), --"未开始:%s",
		[1] = ccClientText(25136), --"支持阶段:%s",
		[2] = ccClientText(25137), --"战斗阶段:%s",
		[3] = ccClientText(25138), --"过渡阶段:%s",
	}

	self._countdownKey = "_countdownKey"

	self._reportDataRecord = {}
	self._teamNumStr =
	{
		[1] = "I",
		[2] = "II",
		[3] = "III",
		[4] = "IV",
		[5] = "V",
	}

	self._teamBtnList =
	{
		[1] = self.mTeam_1,
		[2] = self.mTeam_2,
		[3] = self.mTeam_3,
		[4] = self.mTeam_4,
		[5] = self.mTeam_5,
	}

	self._isForeign = gLGameLanguage:IsForeignVersion()
	self._titleBgForeignPos = Vector2.New(-185, -1)

	self:InitHeroGrids()
end

function UISuIns:RefreshPlayerContent(battleInfo)
	self._leftPlayerId = battleInfo.attack.playerId
	self._rightPlayerId = battleInfo.defense.playerId

	self._leftName = battleInfo.attack.name
	self._rightName = battleInfo.defense.name

	self:SetPlayerContent(self.mPlayer1,battleInfo.attack)
	self:SetPlayerContent(self.mPlayer2,battleInfo.defense)

	self:ClearReportGetter()
	self:ShowTeamSwitch()

end


function UISuIns:ShowCountDown()
	if not self._interactiveInfo then
		return
	end

	self:RefreshWinTagShow()

	local nextTime = self._interactiveInfo.nextTime /1000
	local combatState = self._interactiveInfo.combatState
	local timeLeft = nextTime - GetTimestamp()
	if timeLeft > 0  then
		local str = self._combatStrList[combatState]
		local timeStr = string.replace(str,LUtil.FormatTimespanNumber(timeLeft))
		self:SetWndText(self.mStageInfo,timeStr)
		return true
	else
		self:SetWndText(self.mStageInfo,ccClientText(25139))
		return false
	end
end

function UISuIns:ShowTeamSwitch()

	self._reportList = {}
	for k,v in ipairs(self._battleInfo.reportId) do
		local data =
		{
			reportId = v,
			serverId = self._battleInfo.serverId
		}
		table.insert(self._reportList,data)
	end

	local teamCnt = #self._reportList
	local isEmpty = teamCnt == 0
	CS.ShowObject(self.mTeamSelection,teamCnt > 1)
	self._curTeam = 0

	if isEmpty then
		return
	end

	self._teamCnt = teamCnt

	local teamRootList = {}
	for k=1,teamCnt do
		table.insert(teamRootList,self._teamBtnList[k])
	end

	self._teamRootList = teamRootList



	for k,v in ipairs(teamRootList) do
		local image = CS.FindTrans(v, "Image")
		local off = CS.FindTrans(v, "off")
		local on = CS.FindTrans(v, "on")
		local res
		local layoutElement = v:GetComponent(typeof(UnityEngine.UI.LayoutElement))
		if #teamRootList > 1 then
			if k == 1 then
				res = "trial2_bg_3"
				layoutElement.preferredWidth = 87
				self:SetAnchorPos(off, Vector2.New(15.9, 0))
				self:SetAnchorPos(on, Vector2.New(15.9, 0))
			elseif k == #teamRootList then
				res = "trial2_bg_3"
				layoutElement.preferredWidth = 87
				self:SetAnchorPos(off, Vector2.New(-14.7, 0))
				self:SetAnchorPos(on, Vector2.New(-14.7, 0))
				image.localScale = Vector3(-1, 1, 1)
			else
				res = "trial2_bg_4"
				layoutElement.preferredWidth = 56
				self:SetAnchorPos(off, Vector2.New(0, 0))
				self:SetAnchorPos(on, Vector2.New(0, 0))
			end
		else
			res = "trial2_bg_4"
			layoutElement.preferredWidth = 56
			self:SetAnchorPos(off, Vector2.New(0, 0))
			self:SetAnchorPos(on, Vector2.New(0, 0))
		end
		self:SetWndEasyImage(image, res, nil, true)
		CS.ShowObject(v,true)
		self:SetWndClick(v,function () self:OnClickTeam(k-1) end)
	end


	self:RefreshTeamSel()

	self:ShowFormationContent()

	self:ShowReportBtnOrVs()

end

function UISuIns:RefreshMsgList()
	local dataList =  gModelSimuFight:FormatInteractiveText(self._interactiveInfo)

	local cnt = #dataList
	if self._oldCnt and self._oldCnt == cnt then
		return
	end
	self._oldCnt = cnt

	local uiList = self:FindUIScroll("msgList")
	if not uiList then
		uiList = self:GetUIScroll("msgList")
		uiList:Create(self.mMsgList,dataList,function (...) self:OnDrawMsg(...) end,UIItemList.SUPER)
	else
		uiList:RefreshList(dataList)
	end

	--uiList:DrawAllItems(false)

	local superList = uiList:GetList()
	if superList then
		superList:MoveToBottom()
	end
end

function UISuIns:ShowReportBtnOrVs()
	if not self._interactiveInfo then return end
	local combatState = self._interactiveInfo.combatState
	local isStart = combatState>= ModelSimuFight.INTERACT_BATTLE

	if self._isEmptyFormation then
		isStart = false
	end

	CS.ShowObject(self.mPlayerReportBtn,isStart)
	CS.ShowObject(self.mReportVS,not isStart)
end

function UISuIns:RefreshFormationContent(reportTable)
	if self._heroIconKeys then
		for k,v in pairs(self._heroIconKeys) do
			self:DeleteCommonIcon(v)
		end
		self._heroIconKeys = {}
	end

	local powerA = 0
	local powerB = 0

	-- 空战报不显示
	if reportTable then
		local reportData  = LFightReportData:New()
		reportData:CreateNoRound(reportTable)
		self:ShowHeroFormation(self._heroOneGrid,reportData.formationA)
		self:ShowHeroFormation(self._heroTwoGrid,reportData.formationB)
		powerA = math.floor(reportData.formationA.power)
		powerB = math.floor(reportData.formationB.power)
	end

	local powerTran = self:FindWndTrans(self.mPlayerTeam1,"PowerBg/PowerText")
	local powerStr = LUtil.NumberCoversion(powerA)
	self:SetWndText(powerTran,powerStr)
	powerTran = self:FindWndTrans(self.mPlayerTeam2,"PowerBg/PowerText")
	powerStr = LUtil.NumberCoversion(powerB)
	self:SetWndText(powerTran,powerStr)

	self:RefreshWinTagShow()
end

function UISuIns:ShowHeroFormation(tranList,formation)

	local heroGrids = formation.grids
	local playerId = formation.playerId


	local heroIconKeyList = self._heroIconKeys or {}
	for k,v in pairs(heroGrids) do
		local grid = v.index

		-- local tran =self:FindWndTrans( tranList[grid],"heroIcon")
		local tran =tranList[grid]
		local heroData =
		{
			id = v.id,
			refId = v.refId,
			star = v.star,
			level = v.level,
			skin = v.skinId,
			isResonance = v.resonance,
			grade = v.grade,
			fightPower = v.fightPower,
			form = v.form,
		}

		local clickFunc = function()
			gModelHero:ReqShowHeroTip(playerId,heroData)
		end

		heroData.clickFunc = clickFunc

		local key = self:CreateHeroIconImpl(tran,heroData)

		table.insert(heroIconKeyList,key)
	end

	self._heroIconKeys = heroIconKeyList

end

function UISuIns:RefreshTeamSel()
	if not self._teamRootList then
		return
	end
	for k,v in ipairs(self._teamRootList) do
		CS.ShowObject(v,true)
		local isSelect = self._curTeam == k-1

		local off = self:FindWndTrans(v,"off")
		local on = self:FindWndTrans(v,"on")
		-- local num = self:FindWndTrans(v,"num")
		CS.ShowObject(off,not isSelect)
		CS.ShowObject(on,isSelect )

		-- local color = "yellow_2"
		-- if isSelect then
		-- 	color = "black"
		-- end

		-- local str = LUtil.FormatColorStr(self._teamNumStr[k],color)
		-- self:SetWndText(num,str)
	end
end

function UISuIns:IsBattleEnd()
	local combatState = self._interactiveInfo.combatState
	return combatState> ModelSimuFight.INTERACT_BATTLE
end

function UISuIns:RefreshTime()
	self:TimerStop(self._countdownKey)
	if self:ShowCountDown() then
		self:TimerStart(self._countdownKey,1,false,-1)
	end
end

function UISuIns:InitEvent()
	self:WndNetMsgRecv(LProtoIds.SimulateInteractiveInfoResp,function (...)
		self:OnSimulateInteractiveInfoResp(...)
	end)

	self:WndNetMsgRecv(LProtoIds.SimulateFlowerResp,function (pb)
		self:OnSimulateFlowerResp(pb)
	end)


end

function UISuIns:OnSimulateInteractiveInfoResp(pb)

	self._interactiveInfo = pb

	local battleInfo = StructSimulateBattleInfo:New()
	battleInfo:CreateByPb(pb.battleInfo)
	self._battleInfo = battleInfo


	--printInfoN(string.format("next time %s ,battle start time %s",pb.nextTime,battleInfo.startTime))

	self._flowerInfo = pb.flowerInfo

	if not self._round or self._round ~= pb.round then
		self:RefreshPlayerContent(battleInfo)
	end

	self:RefreshFlowerPart()
	self:OnStateChange()

	self:RefreshMsgList()
	self:RefreshTime()

	local cnt = pb.rewardCount

	local max = gModelSimuFight:GetPara("supportRewardDaily")
	local left = max - cnt
	local color = "red"
	if left > 0 then
		color = "lightGreen"
	end

	--local str = string.format("%s/%s",left,max)
	local tipStr = string.replace(ccClientText(25312),LUtil.FormatColorStr(left,color))
	self:SetWndText(self.mSupportTimes,tipStr)
	-- self:InitTextLineWithLanguage(self.mSupportTimes, -30)
end

function UISuIns:InitUIEvent()
	self:SetWndClick(self.mRSupport,function ()
		self:OnClickSupport(2)
	end)
	self:SetWndClick(self.mLSupport,function ()
		self:OnClickSupport(1)
	end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mPlayerReportBtn,function ()

		self:OpenDetail()
	end)

	self:SetWndClick(self.mBtnMenu,function ()
		GF.OpenWnd("UIGuePost",{refId = 1008})
	end)

	self:SetWndClick(self.mBtnHelp,function ()
		GF.OpenWnd("UIBzTips",{refId =112})
	end)

	self:SetWndClick(self.mBtnOther,function ()
		GF.OpenWnd("UISuInsPop")
	end)
	self:SetWndClick(self.mBtnMine,function ()
		GF.OpenWnd("UISuInsPop",{page = 2})
	end)
end

function UISuIns:OnClickTeam(teamIndex)
	if teamIndex == self._curTeam then
		return
	end

	self._curTeam = teamIndex

	self:RefreshTeamSel()

	self:ShowFormationContent()

	self:ShowReportBtnOrVs()

end

function UISuIns:SetPlayerContent(item,itemdata)
	local name = self:FindWndTrans(item,"name")
	-- local winIcon = self:FindWndTrans(item,"winIcon")
	-- local powerbg = self:FindWndTrans(item,"powerbg")
	-- local powerIcon = self:FindWndTrans(item,"powerIcon")
	local powerText = self:FindWndTrans(item,"PowerBg/PowerText")


	local headTran = self:FindWndTrans(item,"HeadIcon")

	self:SetWndText(name,itemdata.name)
	self:SetWndText(powerText,LUtil.NumberCoversion(itemdata.power))

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

end

function UISuIns:InitHeroGrids()
	local datalist =
	{
		1,2,3,4,5,6,7,8,9,10
	}

	-- local list = self:FindUIScroll("herogrid_1")
	-- if not list then
	-- 	list = self:GetUIScroll("herogrid_1")
	-- 	local gridRoot = self:FindWndTrans(self.mPlayerTeam1,"heroGrid")
	-- 	list:Create(gridRoot,datalist,function(list,item,itemdata,itempos)
	-- 		if not self._heroOneGrid then
	-- 			self._heroOneGrid = {}
	-- 		end

			-- self._heroOneGrid[itemdata] = item
	-- 	end)
	-- end
	if not self._heroOneGrid then
		self._heroOneGrid = {}
		local heroList = self:FindWndTrans(self.mPlayerTeam1,"heroList")
		for i, _ in ipairs(datalist) do
			local item = CS.FindTrans(heroList, i)
			self._heroOneGrid[i] = item
		end
	end
	if not self._heroTwoGrid then
		self._heroTwoGrid = {}
		local heroList = self:FindWndTrans(self.mPlayerTeam2,"heroList")
		for i, _ in ipairs(datalist) do
			local item = CS.FindTrans(heroList, i)
			self._heroTwoGrid[i] = item
		end
	end

	-- list = self:FindUIScroll("herogrid_2")
	-- if not list then
	-- 	list = self:GetUIScroll("herogrid_2")
	-- 	local gridRoot = self:FindWndTrans(self.mPlayerTeam2,"heroGrid")
	-- 	list:Create(gridRoot,datalist,function(list,item,itemdata,itempos)
	-- 		if not self._heroTwoGrid then
	-- 			self._heroTwoGrid = {}
	-- 		end

	-- 		self._heroTwoGrid[itemdata] = item
	-- 	end)
	-- end
end

function UISuIns:OnClickSupport(index)
	if not self._interactiveInfo then
		return
	end

	local supportId = index == 1 and self._leftPlayerId or self._rightPlayerId

	local curPlayer = self._interactiveInfo.flowerInfo.targetId

	if tonumber(curPlayer) > 0  then
		local str = ccClientText(25313)--"本次已支持"
		GF.ShowMessage(str)
		return
	end

	local combatState = self._interactiveInfo.combatState
	if combatState~= ModelSimuFight.INTERACT_SUPPORT then
		local str = ccClientText(25144) --"当前不能支持，请等待下一场"
		GF.ShowMessage(str)
		return
	end

	local id = self._battleInfo.id
	local name = index == 1 and self._leftName or self._rightName
	local itemCfg = gModelSimuFight:GetPara("supportReward1")
	local itemList = LxDataHelper.ParseItem(itemCfg)
	local para =
	{
		refId = 250004,
		para = {name},
		func = function()
			gModelSimuFight:OnSimulateFlowerReq(supportId,3,0,0,id)
		end,
		itemList = itemList,
	}

	gModelGeneral:OpenUIOrdinTips(para)


end


------------------------------------------------------------------
return UISuIns


