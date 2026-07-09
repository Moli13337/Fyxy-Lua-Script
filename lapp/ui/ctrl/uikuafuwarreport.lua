---
--- Created by Administrator.
--- DateTime: 2024/6/11 17:12:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarReport:LWnd
local UIKuafuWarReport = LxWndClass("UIKuafuWarReport", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarReport:UIKuafuWarReport()
	self.resultText = {
		ccClientText(42029),
		ccClientText(42030),
		ccClientText(42047),
		ccClientText(42048)
	}
	self.uiHeadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarReport:OnWndClose()
	self:ClearCommonIconList(self.uiHeadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarReport:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarReport:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitText()

	gModelCrossWar:CrossWarTempleBattleRecordReq()
	gModelRedPoint:SetRedPointClicked(13900040)
	gModelRedPoint:RedPointClickReq(13900040)
end

function UIKuafuWarReport:DrawReport(_, item, data)
	local resultText = self:FindWndTrans(item, "ResultText")
	local rankText = self:FindWndTrans(item, "RankText")
	local arrow = self:FindWndTrans(item, "Arrow")
	local rankText2 = self:FindWndTrans(item, "RankText2")
	local headIcon = self:FindWndTrans(item, "HeadIcon")
	local name = self:FindWndTrans(item, "name")
	local powerText = self:FindWndTrans(item, "PowerBg/PowerText")
	local reportBtn = self:FindWndTrans(item, "ReportBtn")
	local reportBtnText = self:FindWndTrans(reportBtn, "Text")

	self:SetWndText(resultText, self.resultText[data.battleResult])
	self:SetWndText(rankText, ccClientText(25291))
	self:SetWndText(reportBtnText, ccClientText(16340))

	local str = ccClientText(43856)
	local img =( data.rankChange > 0 and (data.battleResult == 1 or data.battleResult == 3))  and "public_arrow_3" or "actionarena_ui_arrow_1"
	local color =( data.rankChange > 0 and (data.battleResult == 1 or data.battleResult == 3)) and "#139057" or "#c81212"
	if data.newRank ~= 1 then
		str = ccClientText(10333)
	end
	if data.rankChange ~= 0 then
		str = "<color=#a1#>#a2#</color>"
		str = string.replace(str, color, data.rankChange)
	else
		local bb = ccClientText(10333)
		if data.battleResult == 2 then
			str = "<color=#a1#>#a2#</color>"
			str = string.replace(str, "#c81212", bb)
		end
		if data.battleResult == 3 then
			str = "<color=#a1#>#a2#</color>"
			str = string.replace(str, "#139057", bb)
		end
		CS.ShowObject(arrow,false)
		self:SetAnchorPos(rankText2,Vector2.New(350,-7))
	end
	self:SetWndText(rankText2, str)
	self:SetWndEasyImage(arrow, img)


	if data.npcId == 0 then
		self:SetWndText(name, data.playerInfo._name)
		self:SetWndText(powerText, LUtil.NumberCoversion(data.power))
		self:SetHeadIcon(headIcon, data.playerInfo)
	else
		local monsterCfg = gModelHero:GetMonsterFormationRefByRefId(data.npcId)
		if monsterCfg then
			self:SetWndText(name, ccLngText(monsterCfg.name))
			self:SetWndText(powerText, LUtil.NumberCoversion(monsterCfg.monsterPower))
		end
		local monsterShow = gModelCrossWar:GetMonsterShowByMonsterId(data.npcId)
		local iconRes = GameTable.CharacterEffectRef[monsterShow].icon
		local icon = self:FindWndTrans(headIcon, "IconBg/Icon")
		self:SetWndEasyImage(icon, iconRes)
	end

	self:SetWndClick(reportBtn, function()
		if data.reportUrl then
			local mapRes = gModelBattle:GetBattleMapRes({ combatType = LCombatTypeConst.COMBAT_CROSS_WAR })
			local combatExtraDatas =
			{
				battleEndfun = function()
					FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
					GF.ChangeMap("LCityMap")
					GF.OpenWndBottom("UIOutts", { childIndex = 2 })
					GF.OpenWndBottom("UIKuafuWar")
					GF.OpenWndBottom("UIKuafuWarReport")
				end,
				canSkip = true,
				battleMapName = mapRes,
				videoType = LVideoTypeConst.NORMAL,
				serverId = data.serverId
			}
			gLFightManager:OnPlayBattleVideo(data.reportUrl, combatExtraDatas)
		end
	end)
end

function UIKuafuWarReport:InitEvent()
	self:SetWndClick(self.mBg, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)

	self:WndEventRecv("CrossWarTempleBattleRecordResp", function()
		self:SetReportList()
	end)
end

function UIKuafuWarReport:InitText()
	self:SetWndText(self.mLblBiaoti, ccClientText(10359))
	local data =
	{
		refId= 5002,
		IntroTran= self.mEmptyText,
	}
	self:GetCommonEmptyList("_empty"):RefreshUI(data)
end

function UIKuafuWarReport:SetReportList()
	local list = gModelCrossWar:GetRecordInfos()
	CS.ShowObject(self.mReportList, #list > 0)
	CS.ShowObject(self.mNoRecord2, #list <= 0)
	if not self.reportList then
		self.reportList = self:GetUIScroll("mReportList")
		self.reportList:Create(self.mReportList, list, function(...) self:DrawReport(...) end, UIItemList.SUPER)
	else
		self.reportList:ResetList(list)
		self.reportList:DrawAllItems()
	end
end

function UIKuafuWarReport:SetHeadIcon(trans, data)
	local icon = self:FindWndTrans(trans, "IconBg/Icon")
	local headFrame = self:FindWndTrans(trans, "headFrame")

	if not data or (data._playerId and data._playerId == 0) then
		self:SetWndEasyImage(icon, "icon_role_chat_0")
		CS.ShowObject(headFrame, false)
		return
	end
	local InstanceID = trans:GetInstanceID()

	local playerInfo = {
		trans = trans,
		playerId = data._playerId,
		icon = data._head,
		headFrame = data._headFrame,
		level = data._grade,
	}
	if not self.uiHeadList[InstanceID] then
		self.uiHeadList[InstanceID] = HeadIcon:New(self)
	end
	self.uiHeadList[InstanceID]:SetHeadData(playerInfo)
	self:SetWndClick(trans, function()
		if data and data._playerId ~= 0 then
			gModelGeneral:PlayerShowReq(
				data._playerId,
				LCombatTypeConst.COMBAT_MAIN,
				LPlayerShowConst.OTHER_SYSTEM
			)
		end
	end)
end



------------------------------------------------------------------
return UIKuafuWarReport