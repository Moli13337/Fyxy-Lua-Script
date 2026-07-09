---
--- Created by BY.
--- DateTime: 2022/7/29 11:54:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardBattlePop:LWnd
local UISorceryCardBattlePop = LxWndClass("UISorceryCardBattlePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardBattlePop:UISorceryCardBattlePop()
	self._tabList = {}
	self._heroGridList = {}
	self.showTipsList = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardBattlePop:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardBattlePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardBattlePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitEvent()
	self:InitCommand()
end

function UISorceryCardBattlePop:TabListItem(item, itemdata, itempos)
	self:SetTextTile(item, itemdata.name)
	self._tabList[itemdata.type] = item
	self:SetWndClick(item, function(...) self:OnClickTab(itemdata.type) end, LSoundConst.CLICK_PAGE_COMMON)
	-- local root = self:FindWndTrans(item, "Root")
	-- local btn1 = self:FindWndTrans(root, "BtnBlue2")
	-- local btn2 = self:FindWndTrans(root, "BtnYellow2")

	-- CS.ShowObject(btn1, itempos == 1)
	-- CS.ShowObject(btn2, itempos == 2)
	-- local btnTab = itempos == 1 and btn1 or btn2

	-- local type = itemdata.type
	-- self._tabList[type] = btnTab
	-- self:SetWndButtonText(btnTab, itemdata.name)
	-- self:SetWndClick(root, function(...) self:OnClickTab(itemdata.type) end, LSoundConst.CLICK_PAGE_COMMON)
end

function UISorceryCardBattlePop:RefreshData()
	local _type = self._type
	local _heroGridList = self._heroGridList
	local _heroGrids = _heroGridList[_type]
	if not _heroGrids then return end

	local haveCardList = {}
	for _, v in ipairs(_heroGrids) do
		local sorceryCardInfo = v.sorceryCardInfo
		if sorceryCardInfo then
			if sorceryCardInfo.scRefId > 0 then
				haveCardList[sorceryCardInfo.scRefId] = v
			end
		end
	end

	local groupList = {}
	local refList = gModelSorceryCard:GetSorceryCardRecomGroupRef()
	for _, v in ipairs(refList) do
		local cardDetail = string.split(v.cfg.cardDetail,",")
		local isActivate = true
		local cardList = {}
		for _, cardId in ipairs(cardDetail) do
			cardId = tonumber(cardId)
			if not haveCardList[cardId] then
				isActivate = false
				break
			else
				local data = haveCardList[cardId]
				table.insert(cardList, data)
			end
		end
		if isActivate then
			local data = {
				groupCfg = v,
				cardList = cardList
			}
			table.insert(groupList, data)
			for _, v in ipairs(cardList) do
				local cardId = v.sorceryCardInfo.scRefId
				haveCardList[cardId] = nil
			end
		end
	end
	local aloneList = {}
	local index = 1
	for _, v in pairs(haveCardList) do
		if not aloneList[index] then
			aloneList[index] = {}
			aloneList[index].cardList = {}
		end
		table.insert(aloneList[index].cardList, v)
		if #aloneList[index].cardList == 3 then
			index = index + 1
		end
	end

	local list = {}
	for _, v in ipairs(groupList) do
		table.insert(list, v)
	end
	for _, v in ipairs(aloneList) do
		table.insert(list, v)
	end

	CS.ShowObject(self.mNoRecord2, #list == 0)
	if self.uiList then
		self.uiList:RefreshList(list)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("uiList")
		self.uiList:Create(self.mList, list, function(...) self:DrawCard(...) end, UIItemList.SUPER)
	end
end

function UISorceryCardBattlePop:SetCard(trans, data)
	if data == nil then
		return
	end
	local cardFrame = CS.FindTrans(trans, "CardFrame")
	local cardIcon = CS.FindTrans(cardFrame, "CardIcon")
	local heroRoot = CS.FindTrans(trans, "HeroRoot")

	if self._isEnus then
		local text =  CS.FindTrans(trans, "UIText")
		self:InitTextSizeWithLanguage(text,-6)
	end

	local cfg = gModelSorceryCard:GetSorceryCardRefByRefId(data.sorceryCardInfo.scRefId)
	self:SetWndEasyImage(cardFrame, cfg.frameRes)
	self:SetWndEasyImage(cardIcon, cfg.icon)

	self:SetTextTile(trans, ccLngText(cfg.name) .. " Lv." .. data.sorceryCardInfo.level)

	data.isMon = data.monster == 1
	data.isResonance = 0
	data.skin = data.skinId
	self:CreateHeroIconImpl(heroRoot, data)
	self:SetWndClick(heroRoot, function()
		self:OnClickHeroIcon(data)
	end)
	self:SetWndClick(cardFrame, function()
		if data.sorceryCardInfo then
			local skillLvRef = gModelSorceryCard:GetSorceryCardSkillRef(cfg.skillGroup, data.sorceryCardInfo.level)
			local argList = {
				skill = skillLvRef.skill,
				wndType = 7,
				cardId = data.sorceryCardInfo.scRefId,
				skillGroup = cfg.skillGroup,
				cardLevel = data.sorceryCardInfo.level
			}
			gModelGeneral:OpenSkillWnd(argList)
		end
	end)
end

function UISorceryCardBattlePop:OnClickTab(type)
	local _type = self._type
	local _tabList = self._tabList or {}
	if _type then
		-- self:SetWndTabStatus(btnTab, LWnd.StateOff)
		local btnTab = _tabList[_type]
		local on = CS.FindTrans(btnTab, "On")
		CS.ShowObject(on, false)
	end
	self._type = type
	local btnTab = _tabList[type]
	local on = CS.FindTrans(btnTab, "On")
	CS.ShowObject(on, true)
	-- self:SetWndTabStatus(btnTab, LWnd.StateOn)

	self.showTipsList = {}
	self:RefreshData()
end

function UISorceryCardBattlePop:InitEvent()
	self:SetWndClick(self.mBgImage, function() self:WndClose() end)
end

function UISorceryCardBattlePop:InitCommand()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mCardText, ccClientText(29526))
	self:SetWndText(self.mHeroText, ccClientText(29547))

	local data = {
		refId = 10013,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	local _teamA = self:GetWndArg("heroGridA")
	local _teamB = self:GetWndArg("heroGridB")
	self._teamA = _teamA
	self._teamB = _teamB
	self._heroGridList = {
		[1] = _teamA.grids,
		[2] = _teamB.grids,
	}

	local list = {
		{ type = 1, name = ccClientText(29548), trans = self.mTab1 },
		{ type = 2, name = ccClientText(29549), trans = self.mTab2 },
	}
	for i, v in ipairs(list) do
		self:TabListItem(v.trans, v, i)
	end
	-- local uiList = self:GetUIScroll("mTabScroll_UISorceryCardBattlePop")
	-- uiList:Create(self.mTabScroll, list, function(...) self:TabListItem(...) end)
	self:OnClickTab(list[1].type)
end

function UISorceryCardBattlePop:DrawCard(_, trans, data, pos)
	local top = CS.FindTrans(trans, "Top")
	local title = CS.FindTrans(top, "Title")
	local help = CS.FindTrans(top, "Help")
	local cardRoot = CS.FindTrans(trans, "CardRoot")
	local line = CS.FindTrans(trans, "Line")
	local tips = CS.FindTrans(trans, "Tips")

	if data.groupCfg then
		self:SetTextTile(title, ccLngText(data.groupCfg.cfg.name))
		self:SetTextTile(tips, ccLngText(data.groupCfg.cfg.effectTxt))
	end
	local cardList = data.cardList
	for i = 1, 3 do
		local cardTrans = CS.FindTrans(cardRoot, "Card" .. i)
		self:SetCard(cardTrans, cardList[i])
		CS.ShowObject(cardTrans, cardList[i])
	end
	CS.ShowObject(top, data.groupCfg)
	CS.ShowObject(line, data.groupCfg)
	CS.ShowObject(tips, self.showTipsList[pos])
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(tips)
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(trans)

	self:SetWndClick(help, function()
		if not self.showTipsList[pos] then
			self.showTipsList[pos] = false
		end
		self.showTipsList[pos] = not self.showTipsList[pos]
		self.uiList:DrawAllItems()
	end)
end

function UISorceryCardBattlePop:OnClickHeroIcon(itemdata)
	local curBattle = gLFightManager:GetCurBattleUnit()
	if not curBattle then
		return
	end
	local combatType = curBattle:GetCombatType()
	if combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
		local str = ccClientText(16905) --"不可查看英雄信息"
		GF.ShowMessage(str)
		return
	end
	local combatType = curBattle:GetReportCombatType()
	local showTip = true
	local playerId
	local serverId
	local _type = self._type
	if _type == 1 then
		playerId = self._teamA.playerId
		serverId = self._teamA.serverId
	else
		playerId = self._teamB.playerId
		serverId = self._teamB.serverId
		showTip = gModelBattle:CheckShowEnemyTip(combatType)
	end

	if showTip then
		gModelHero:ReqShowHeroTipEx({ playerId = playerId, heroData = itemdata, serverId = serverId })
	else
		local str = ccClientText(16905)
		GF.ShowMessage(str)
	end
end

------------------------------------------------------------------
return UISorceryCardBattlePop