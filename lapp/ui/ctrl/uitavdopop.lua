---
--- Created by BY.
--- DateTime: 2023/10/13 20:44:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaVdoPop:LWnd
local UITaVdoPop = LxWndClass("UITaVdoPop", LWnd)

UITaVdoPop.TYPE_TOWER = 1 					-- 试练之藤
UITaVdoPop.TYPE_MIRAGECHALLENGE = 2			-- 幻境试炼
UITaVdoPop.TYPE_BOSSTOWER = 3					-- 音乐爬塔
UITaVdoPop.TYPE_CRUSADEAGAINST = 4			-- 梦境讨伐
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaVdoPop:UITaVdoPop()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaVdoPop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaVdoPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaVdoPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UITaVdoPop:OnClickBattlelog(itemdata)
	if string.isempty(itemdata.reportId) then
		printErrorN("report id is null")
		return
	end

	local combatExtraDatas = self:GetVideoCombatExtraDatas(itemdata)

	local reportId = {}
	local winnerNumber = {}
	local reportIdArr = string.split(itemdata.reportId,"|")

	for i, v in ipairs(reportIdArr) do
		local reportArr = string.split(v,",")
		if #reportArr == 1 then
			gLFightManager:OnOpenBattleDetails(itemdata.reportId,combatExtraDatas)
			return
		else
			table.insert(reportId,reportArr[1])
			table.insert(winnerNumber,tonumber(reportArr[2]))
		end
	end
	combatExtraDatas.winnerNumber = winnerNumber
	combatExtraDatas.reportId = reportId
	combatExtraDatas.serverId =  gLGameLogin:GetActualServerId()
	gLFightManager:ShowCrossGradingBattleDetail(combatExtraDatas)
end
function UITaVdoPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.TowerFloorResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityChallengeHistoryResp,function (pb,ret)
        if pb.sid == self._sid and pb.monster == self._passId then
			self:RefreshData()
        end
	end)
	-- self:WndNetMsgRecv(LProtoIds.BossTowerLogResp,function (pb,ret)
	-- 	if self._sid ~= pb.sid then return end
	-- 	self:RefreshData()
	-- end)
	self:WndNetMsgRecv(LProtoIds.CrusadePassHistoryResp,function (pb,ret)
		self:RefreshData()
	end)
end
function UITaVdoPop:SetTowerItem(item)
	local prowerIcon = CS.FindTrans(item,"ProwerBg")
	local playerText = CS.FindTrans(item,"PlayerText")
	CS.ShowObject(prowerIcon,true)
	CS.ShowObject(playerText,true)
end
function UITaVdoPop:OnClickTowerShare(shareBtn,itemdata)
	local _towerType = self._towerType
	local ref = gModelTower:GetTowerPatternRefByRefId(_towerType)
	local name = string.replace(ccClientText(12157),ccLngText(ref.name))
	local combatData = {
		meName = itemdata.playerName,
		otherName = gModelTower:GetMonsterName(self._refId,_towerType),
		reportUrl = gLGameLogin:GetHttpReportUrl(),
		serverId = gLGameLogin:GetActualServerId(),
		reportId = itemdata.reportId,
		battleName = name,
		battleMapName = gModelBattle:GetBattleMapRes({combatType = ref.combatTyep })
	}
	local jsonStr = JSON.encode(combatData)
	local data = {
		root = shareBtn,
		shareType = ModelChat.SHARE_TOWER,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end
function UITaVdoPop:SetMirageChallengeItem(item,itemdata)
	local prowerIcon = CS.FindTrans(item,"ProwerBg")
	local playerText = CS.FindTrans(item,"PlayerText")
	local HeadIcon = CS.FindTrans(item,"HeadIcon")
	local desText = CS.FindTrans(item,"DesText")
	local shareBtn = CS.FindTrans(item,"ShareBtn")

	local isHaveReport = not string.isempty(itemdata.reportId)

	CS.ShowObject(prowerIcon,isHaveReport)
	CS.ShowObject(playerText,isHaveReport)
	CS.ShowObject(HeadIcon,isHaveReport)
	local tStr = not isHaveReport and ccClientText(12138) or ""
	self:SetWndText(desText,tStr)
	CS.ShowObject(shareBtn,false)
end

function UITaVdoPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImageObj, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
function UITaVdoPop:SetBossTowerItem(item,itemdata)
	-- local prowerIcon = CS.FindTrans(item,"ProwerBg")
	-- local playerText = CS.FindTrans(item,"PlayerText")
	-- local HeadIcon = CS.FindTrans(item,"HeadIcon")
	-- local desText = CS.FindTrans(item,"DesText")

	-- local isHaveReport = not string.isempty(itemdata.reportId)

	-- CS.ShowObject(prowerIcon,isHaveReport)
	-- CS.ShowObject(playerText,isHaveReport)
	-- CS.ShowObject(HeadIcon,isHaveReport)
	-- local tStr = not isHaveReport and ccClientText(12138) or ""
	-- self:SetWndText(desText,tStr)
end
function UITaVdoPop:OnClickBossTowerShare(shareBtn,itemdata)
	-- local insRefId = self._insRefId
	-- local insName = gModelBossTower:GetBossTowerInsNameByRefId(insRefId)
	-- local combatData = {
	-- 	meName = itemdata.playerName,
	-- 	otherName = insName,
	-- 	reportUrl = gLGameLogin:GetHttpReportUrl(),
	-- 	serverId =  gLGameLogin:GetActualServerId(),
	-- 	reportId = itemdata.reportId,
	-- 	battleName = insName,
	-- 	battleMapName = gModelBattle:GetBattleMapRes({combatType = gModelBossTower:GetBossTowerConfigRefByKey("towerFightType")})
	-- }
	-- local jsonStr = JSON.encode(combatData)
	-- local data = {
	-- 	root = shareBtn,
	-- 	shareType = ModelChat.SHARE_BOSSTOWER,
	-- 	shareData = jsonStr
	-- }
	-- gModelGeneral:OpenShareTip(data)
end
function UITaVdoPop:OnClickVideo(itemdata)
	if string.isempty(itemdata.reportId) then
		printErrorN("report id is null")
		return
	end

	local combatExtraDatas = self:GetVideoCombatExtraDatas(itemdata)
	combatExtraDatas.battleEndfun = combatExtraDatas.closeAfterVideo
	local reportId = {}
	local winnerNumber = {}
	local reportIdArr = string.split(itemdata.reportId,"|")
	for i, v in ipairs(reportIdArr) do
		local reportArr = string.split(v,",")
		if #reportArr == 1 then
			gLFightManager:OnPlayBattleVideo(itemdata.reportId,combatExtraDatas)
			return
		else
			table.insert(reportId,reportArr[1])
			table.insert(winnerNumber,tonumber(reportArr[2]))
		end
	end
	combatExtraDatas.winnerNumber = winnerNumber
	combatExtraDatas.reportId = reportId
	combatExtraDatas.serverId =  gLGameLogin:GetActualServerId()
	gLFightManager:OnPlayMultiVideo(reportId,combatExtraDatas)
end
function UITaVdoPop:ListItem(list,item, itemdata, itempos)
	local titleText = CS.FindTrans(item,"TitleImg/TitleText")
	local playerText = CS.FindTrans(item,"PlayerText")
	local desText = CS.FindTrans(item,"DesText")
	local prowerIcon = CS.FindTrans(item,"ProwerBg")
	local prowerText = CS.FindTrans(item,"ProwerBg/ProwerText")

	local shareBtn = CS.FindTrans(item,"ShareBtn")
	local shareText = CS.FindTrans(shareBtn,"XUIText")
	local reportBtn = CS.FindTrans(item,"ReportBtn")
	local reportText = CS.FindTrans(reportBtn,"XUIText")
	local lookBtn = CS.FindTrans(item,"LookBtn")
	local lookText = CS.FindTrans(lookBtn,"XUIText")
	local tipsText = CS.FindTrans(item,"TipsText")

	local openType = self._openType
	local playerStr,titleStr = "",""
	if itempos == 1 then
		titleStr = ccClientText(12110)
		playerStr = ccClientText(12137)
	elseif itempos == 2 then
		titleStr = ccClientText(12111)
		playerStr = ccClientText(12137)
	elseif itempos == 3 then
		titleStr = ccClientText(12115)
		playerStr = ccClientText(12138)
	end
	CS.ShowObject(shareBtn,false)
	CS.ShowObject(reportBtn,false)
	CS.ShowObject(lookBtn,false)
	CS.ShowObject(prowerIcon,false)
	self:SetWndText(prowerText,"")
	self:SetWndText(titleText,titleStr)
	self:SetWndText(desText,playerStr)
	self:SetWndText(shareText,ccClientText(12116))
	self:SetWndText(reportText,ccClientText(12117))
	self:SetWndText(lookText,ccClientText(12118))
	self:InitTextSizeWithLanguage(shareText,-2)
	self:InitTextSizeWithLanguage(reportText,-2)
	self:InitTextSizeWithLanguage(lookText,-2)
	self:SetHeadIcon(item,itemdata)

	if itemdata.playerId == 0 then return end

	local isHaveReport = not string.isempty(itemdata.reportId)
	CS.ShowObject(reportBtn,isHaveReport)
	CS.ShowObject(lookBtn,isHaveReport)
	CS.ShowObject(tipsText,not isHaveReport)
	CS.ShowObject(shareBtn,isHaveReport and itempos == 3)
	self:SetWndText(desText,"")
	self:SetWndText(tipsText,ccClientText(12182))
	self:SetWndText(prowerText,LUtil.PowerNumberCoversion(itemdata.power))
	self:SetWndText(playerText,itemdata.playerName)

	if openType == UITaVdoPop.TYPE_TOWER then
		self:SetTowerItem(item)
	elseif openType == UITaVdoPop.TYPE_MIRAGECHALLENGE then
		self:SetMirageChallengeItem(item,itemdata)
	-- elseif openType == UITaVdoPop.TYPE_BOSSTOWER then
	-- 	self:SetBossTowerItem(item,itemdata)
	elseif openType == UITaVdoPop.TYPE_CRUSADEAGAINST then
		CS.ShowObject(prowerIcon,true)
	end
	self:SetWndClick(shareBtn, function(...)
		self:OnClickShare(shareBtn,itemdata)
	end)
	self:SetWndClick(reportBtn, function(...)
		self:OnClickBattlelog(itemdata)
	end)
	self:SetWndClick(lookBtn, function(...)
		self:OnClickVideo(itemdata)
	end)
end
function UITaVdoPop:OnClickShare(shareBtn,itemdata)
	local openType = self._openType
	if openType == UITaVdoPop.TYPE_TOWER then
		self:OnClickTowerShare(shareBtn,itemdata)
	-- elseif openType == UITaVdoPop.TYPE_BOSSTOWER then
	-- 	self:OnClickBossTowerShare(shareBtn,itemdata)
	end
end

function UITaVdoPop:RefreshData()
	local list
	local openType = self._openType
	if openType == UITaVdoPop.TYPE_TOWER then
		list = gModelTower:GetFloorPlayerInfoList()
		local layer = gModelTower:GetTasLayer(self._towerType)
		if layer - self._refId > GameTable.SnakeTowerConfigRef.myRecordNum then
			table.remove(list,3)
		end
	elseif openType == UITaVdoPop.TYPE_MIRAGECHALLENGE then
		list = gModelActivity:GetFloorPlayerInfo(self._sid,self._passId)
	 --elseif openType == UITaVdoPop.TYPE_BOSSTOWER then
	 --	list = gModelBossTower:GetBossTowerLogList()
	elseif openType == UITaVdoPop.TYPE_CRUSADEAGAINST then
		list = gModelCrusadeAgainst:GetCrusadePassList()
	end

	local _uiList = self._uiList
	if _uiList then
		_uiList:RefreshList(list)
	else
		_uiList = self:GetUIScroll("uiList")
		self._uiList = _uiList
		_uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
	end
end
function UITaVdoPop:InitCommand()
	local openType = self:GetWndArg("openType")
	self._openType = openType
	local titleStr
	if openType == UITaVdoPop.TYPE_TOWER then
		self._refId = self:GetWndArg("refId")
		self._towerType = self:GetWndArg("towerType")
		-- self._passId =
		self:RefreshData()
		titleStr = ccClientText(12112)
	elseif openType == UITaVdoPop.TYPE_MIRAGECHALLENGE then
		self:RefreshData()
		self._sid = self:GetWndArg("sid")
		self._passId = self:GetWndArg("passId")
		self._map = self:GetWndArg("map")
		gModelActivity:OnActivityChallengeHistoryReq(self._sid,self._passId)
		titleStr = self:GetWndArg("title") or ccClientText(12112)
	 --elseif openType == UITaVdoPop.TYPE_BOSSTOWER then
	 --	self:RefreshData()
	 --	self._sid = self:GetWndArg("sid")
	 --	self._insRefId = self:GetWndArg("insRefId")
	 --	gModelBossTower:OnBossTowerLogReq(self._sid,self._insRefId)
	 --	titleStr = gModelBossTower:GetBossTowerInsNameByRefId(self._insRefId)
	elseif openType == UITaVdoPop.TYPE_CRUSADEAGAINST then
		local refId = self:GetWndArg("refId")
		self._refId = refId
		gModelCrusadeAgainst:OnCrusadePassHistoryReq(refId)
		titleStr = ccClientText(11000)
	end
	self:SetWndText(self.mTitleTextObj,titleStr)
end
function UITaVdoPop:GetVideoCombatExtraDatas(itemdata)
	local combatExtraDatas
	local openType = self._openType
	if openType == UITaVdoPop.TYPE_TOWER then
		local refId = self._refId
		local _towerType = self._towerType
		combatExtraDatas = {
			meName = itemdata.playerName,
			otherName = gModelTower:GetMonsterName(refId,_towerType),
			battleMapName = gModelBattle:GetBattleMapRes({combatType =LCombatTypeConst.COMBAT_TOWER_BATTLE}),
			closeAfterVideo = function()
				GF.OpenWndBottom("UITaWin",{towerType = _towerType,noOpentPrivile = true})
				GF.OpenWnd("UITaVdoPop",{refId = refId,towerType = _towerType,openType = openType})
				GF.CloseWndByName("UIFight")
				GF.ChangeMap("LCityMap")
				--self:WndClose()
			end,
			canSkip = true
		}
	elseif openType == UITaVdoPop.TYPE_MIRAGECHALLENGE then
		local sid,monsterId = self._sid,self._passId
		local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterId)
		combatExtraDatas = {
			sid = sid,
			monsterId = monsterId,
			meName = itemdata.playerName,
			otherName = ccLngText(monsterFormationRef.name),
			battleMapName = self._map,
			closeAfterVideo = function()
				local page,subPage = gModelActivity:GetActivityPosBySid(sid)
				GF.OpenWndBottom("UIAct",{page = page,subPage = subPage})
				GF.OpenWnd("UITaVdoPop",{sid = sid,passId = monsterId,openType = openType})
				GF.ChangeMap("LCityMap")
				--self:WndClose()
			end,
			canSkip = true
		}
	elseif openType == UITaVdoPop.TYPE_BOSSTOWER then
		-- local sid = self._sid
		-- local insRefId = self._insRefId
		-- local insName = gModelBossTower:GetBossTowerInsNameByRefId(insRefId)
		-- combatExtraDatas = {
		-- 	sid = sid,
		-- 	meName = itemdata.playerName,
		-- 	otherName = insName,
		-- 	closeAfterVideo = function()
		-- 		GF.OpenWnd("UIActTower",{sid = sid,page = ModelBossTower.TYPE_BTN_ADVENTURE})
		-- 		GF.CloseWndByName("UIFight")
		-- 		GF.ChangeMap("LCityMap")
		-- 		--self:WndClose()
		-- 	end,
		-- 	canSkip = true
		-- }
	elseif openType == UITaVdoPop.TYPE_CRUSADEAGAINST then
		local refId = self._refId
		local nodeRef = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(refId)
		local bossRef = gModelCrusadeAgainst:GetDreamCrusadeDifficultyRefByRefId(nodeRef.boosType)
		combatExtraDatas = {
			meName = itemdata.playerName,
			otherName = ccLngText(bossRef.name),
			targetId = refId,
			battleMapName = gModelBattle:GetBattleMapRes({combatType = LCombatTypeConst.COMBAT_CRUSADE_AGAINST}),
			closeAfterVideo = function()
				GF.OpenWnd("UIDreamKillWin")
				GF.OpenWnd("UITaVdoPop",{refId = refId,openType = openType})
				GF.CloseWndByName("UIFight")
				GF.ChangeMap("LCityMap")
			end,
			canSkip = true
		}
	end
	return combatExtraDatas
end

function UITaVdoPop:OnClickPlayer(_playerId)
	if(_playerId==gModelPlayer:GetPlayerId() )then
		GF.ShowMessage(ccClientText(11522))
		return
	end
	gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

--设置玩家头像
function UITaVdoPop:SetHeadIcon(item,info)
	local headIcon = CS.FindTrans(item, "HeadIcon")
	CS.ShowObject(headIcon,false)
	if info.playerId == 0 then return end
	CS.ShowObject(headIcon,true)
	local InstanceID = item:GetInstanceID()

	local playerInfo={
		trans = headIcon,
		playerId = info.playerId,
		icon = info.head,
		headFrame = info.headFrame,
		level = info.level,
	}
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	self:SetWndClick(headIcon, function (...)
		self:OnClickPlayer(info.playerId)
	end)
end
------------------------------------------------------------------
return UITaVdoPop


