---
--- Created by Administrator.
--- DateTime: 2024/4/10 20:02:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandGameVdo:LWnd
local UIBrandGameVdo = LxWndClass("UIBrandGameVdo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandGameVdo:UIBrandGameVdo()
	self.refId = 0
	 --初始化信息
	 self.str = {ccClientText(32307),ccClientText(32326),ccClientText(40233)}
     self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandGameVdo:OnWndClose()
	LWnd.OnWndClose(self)
    if self._componentCache then self._componentCache = nil end
    self:ClearCommonIconList(self._uiheadList)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandGameVdo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandGameVdo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()



	self._isVie =gLGameLanguage:IsVieVersion()
	self:SetWndText(self.mTxtBiaoti,ccClientText(40223))
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mImgMask,function() self:WndClose() end)

	self.refId = self:GetWndArg('refId')
    gModelBadgeGame:BadgeGameBattleVideoReq(self.refId)
    local barrierRef = GameTable.BadgeGameBarrierRef[self.refId]
    self:WndEventRecv(EventNames.BADGE_VIDEO_UPDATE,function() self:OnCreateList() end)
    self:SetWndText(self.mTxtLevelTitle, string.replace(ccClientText(40202),ccLngText(barrierRef.name)))
    -- self:OnCreateList()
end

function UIBrandGameVdo:OnDrawVideoItem(list, item, itemData, index)
    local instanceId = item:GetInstanceID()
    local itemCache = self._componentCache and self._componentCache[instanceId]-- self:GetComponentCache(instanceId)
    if not itemCache then
        itemCache = {
            roleIcon = self:FindWndTrans(item,"GroupInfo/RoleIcon"),
			level = self:FindWndTrans(item,"GroupInfo/RoleIcon/lvBg/level"),
            txtTitle = self:FindWndTrans(item,"TxtVideoTitle"),
            txtName = self:FindWndTrans(item,"GroupInfo/TxtRoleName"),
            txtPower = self:FindWndTrans(item,"GroupInfo/ProwerBg/TxtGroupPower"),
            txtTips = self:FindWndTrans(item,"TxtNull"),
            ShareBtn = self:FindWndTrans(item,"GroupInfo/ShareBtn"),
            ReportBtn = self:FindWndTrans(item,"GroupInfo/ReportBtn"),
            LookBtn = self:FindWndTrans(item,"GroupInfo/LookBtn"),
            txtShareBtn = self:FindWndTrans(item,"GroupInfo/ShareBtn/XUIText"),
            txtReportBtn = self:FindWndTrans(item,"GroupInfo/ReportBtn/XUIText"),
            txtLookBtn = self:FindWndTrans(item,"GroupInfo/LookBtn/XUIText"),
            groupInfo = self:FindWndTrans(item,"GroupInfo"),
        }
        self:SetComponentCache(instanceId,itemCache)
    end
    CS.ShowObject(itemCache.groupInfo, itemData.isNull)
    CS.ShowObject(itemCache.txtTips, not itemData.isNull)
    self:SetWndText(itemCache.txtTitle, self.str[index])
    self:SetWndText(itemCache.txtTips, ccClientText(20808))
    if not itemData.isNull then return end

    self:SetWndText(itemCache.txtName, itemData.roleInfo.name)
    local power = LUtil.NumberCoversion (itemData.power)
    self:SetWndText(itemCache.txtPower,power)
    self:SetWndText(itemCache.txtShareBtn,ccClientText(21179))
    self:SetWndClick(itemCache.ShareBtn,function()
        self:OnClickTowerShare(itemCache.ShareBtn,itemData)
    end)
    self:SetWndText(itemCache.txtReportBtn,ccClientText(21809))
    self:SetWndClick(itemCache.ReportBtn,function()
        self:OnClickBattlelog(itemData)
    end)
    self:SetWndText(itemCache.txtLookBtn,ccClientText(25309))
    self:SetWndClick(itemCache.LookBtn,function()
        self:OnClickVideo(itemData)
    end)

    self:OnCreateRoleList(itemCache.listRoles,itemData.heroes)
    self:SetHeadIcon(itemCache.roleIcon,itemData)

	if self._isVie then
		self:InitTextLineWithLanguage(itemCache.txtReportBtn,30)
		self:SetAnchorPos(itemCache.level,Vector2.New(0,-8))
	end

end

function UIBrandGameVdo:OnClickRoleHead(roleId)
    -- CtrlCenter.Chat:OnChatLookAtPlayer({roleId = roleId})
end

function UIBrandGameVdo:OnCreateRoleList(obj,heroes)
	-- self:CreateUIScrollImpl(nil,obj,heroes,function(...) self:OnDrawHeroItem(...) end ,UIItemList.WRAP)
end

function UIBrandGameVdo:OnClickTowerShare(shareBtn,itemdata)
	local ref = GameTable.BadgeGameBarrierRef[self.refId]
    local combatRef = GameTable.BattleGameRef[LCombatTypeConst.COMBAT_BADGE_GAME]
	local name = string.replace(ccClientText(12157),ccLngText(combatRef.name))
    local monsterRef = GameTable.MonsterFormationRef[ref.monster]
	local combatData = {
		meName = itemdata.roleInfo.name,
		otherName = monsterRef and ccLngText(monsterRef.name) or "",
		reportUrl = gLGameLogin:GetHttpReportUrl(),
		serverId = gLGameLogin:GetActualServerId(),
		reportId = itemdata.reportUrl,
		battleName = name,
		battleMapName = gModelBattle:GetBattleMapRes({combatType =combatRef.refId })
	}
	local jsonStr = JSON.encode(combatData)
	local data = {
		root = shareBtn,
		shareType = ModelChat.CHAT_SHARE_42,
		shareData = jsonStr
	}
	gModelGeneral:OpenShareTip(data)
end

function UIBrandGameVdo:OnClickBattlelog(itemdata)
	if string.isempty(itemdata.reportUrl) then
		printErrorN("report id is null")
		return
	end

    local ref = GameTable.BadgeGameBarrierRef[self.refId]
    local combatRef = GameTable.BattleGameRef[LCombatTypeConst.COMBAT_BADGE_GAME]
	local name = string.replace(ccClientText(12157),ccLngText(combatRef.name))
    local monsterRef = GameTable.MonsterFormationRef[ref.monster]

	local combatExtraDatas = {
        meName = itemdata.roleInfo.name,
        otherName = monsterRef and ccLngText(monsterRef.name) or "",
        battleMapName = gModelBattle:GetBattleMapRes({combatType =LCombatTypeConst.COMBAT_BADGE_GAME}),
        closeAfterVideo = function()
            GF.OpenWndBottom("UIOutts")
            GF.OpenWndBottom("UIBrandGameWin",{
				chapterId = ref.chapterId,
			})
            -- GF.OpenWnd("UITaVdoPop",{refId = refId,towerType = _towerType,openType = openType})
            GF.CloseWndByName("UIFight")
            GF.ChangeMap("LCityMap")
            --self:WndClose()
        end,
        canSkip = true
    }

	local reportId = {}
	local winnerNumber = {}
	local reportIdArr = string.split(itemdata.reportUrl,"|")

	for i, v in ipairs(reportIdArr) do
		local reportArr = string.split(v,",")
		if #reportArr == 1 then
			gLFightManager:OnOpenBattleDetails(itemdata.reportUrl,combatExtraDatas)
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
function UIBrandGameVdo:SetComponentCache(instanceId,itemCache)
	if not self._componentCache then self._componentCache = {} end
	self._componentCache[instanceId] = itemCache
end

function UIBrandGameVdo:OnClickVideo(itemdata)
	if string.isempty(itemdata.reportUrl) then
		printErrorN("report id is null")
		return
	end

    local ref = GameTable.BadgeGameBarrierRef[self.refId]
    local combatRef = GameTable.BattleGameRef[LCombatTypeConst.COMBAT_BADGE_GAME]
	local name = string.replace(ccClientText(12157),ccLngText(combatRef.name))
    local monsterRef = GameTable.MonsterFormationRef[ref.monster]
	local combatExtraDatas = {
        meName = itemdata.roleInfo.name,
        otherName = monsterRef and ccLngText(monsterRef.name) or "",
        battleMapName = gModelBattle:GetBattleMapRes({combatType =LCombatTypeConst.COMBAT_BADGE_GAME}),
        closeAfterVideo = function()
            GF.OpenWndBottom("UIOutts")
            GF.OpenWndBottom("UIBrandGameWin",{chapterId = ref.chapterId})
            -- GF.OpenWnd("UITaVdoPop",{refId = refId,towerType = _towerType,openType = openType})
            GF.CloseWndByName("UIFight")
            GF.ChangeMap("LCityMap")
            --self:WndClose()
        end,
        canSkip = true
    }

	combatExtraDatas.battleEndfun = combatExtraDatas.closeAfterVideo
	local reportId = {}
	local winnerNumber = {}
	local reportIdArr = string.split(itemdata.reportUrl,"|")
	for i, v in ipairs(reportIdArr) do
		local reportArr = string.split(v,",")
		if #reportArr == 1 then
			gLFightManager:OnPlayBattleVideo(itemdata.reportUrl,combatExtraDatas)
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

--设置玩家头像
function UIBrandGameVdo:SetHeadIcon(item,info)

    local headIcon = item
	CS.ShowObject(headIcon,false)
	if info.roleInfo.playerId == 0 then return end
	CS.ShowObject(headIcon,true)
	local InstanceID = item:GetInstanceID()

	local playerInfo={
		trans = headIcon,
		playerId = info.roleInfo.playerId,
		icon = info.roleInfo.head,
		headFrame = info.roleInfo.headFrame,
		level = info.roleInfo.grade,
	}
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	self:SetWndClick(headIcon, function (...)
		self:OnClickPlayer(info.roleInfo.playerId)
	end)
end
function UIBrandGameVdo:OnClickPlayer(_playerId)
	if(_playerId==gModelPlayer:GetPlayerId() )then
		GF.ShowMessage(ccClientText(11522))
		return
	end
	gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_BADGE_GAME,LPlayerShowConst.OTHER_SYSTEM)
end

function UIBrandGameVdo:OnDrawHeroItem(list, item, itemData, index)
    local heroPosInfo = nil
    local isFormation = heroPosInfo ~= nil
    local heroIcon, iconData = self:CreateHeroIconImpl(item,itemData)-- GetIcon(item, ThingType.Hero)
    iconData.refId = itemData
    iconData.sel = isFormation
    iconData.formation = false
    iconData.showSpeed = isFormation and true or false
    -- iconData.speed = isFormation and self:GetSpeed(itemData) or 0
    iconData.hideNum = true
    iconData.hideName = true
    heroIcon:Show()
end

function UIBrandGameVdo:OnCreateList()
    local infos = gModelBadgeGame:GetVideoList(self.refId) or {{},{},{}}
	self:CreateUIScrollImpl(nil,self.mListRecords,infos,function(...) self:OnDrawVideoItem(...) end,UIItemList.WRAP)
end

------------------------------------------------------------------
return UIBrandGameVdo