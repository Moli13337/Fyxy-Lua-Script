---
--- Created by Administrator.
--- DateTime: 2024/11/14 15:59:23
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSorceryCardGroup:LChildWnd
local UISubSorceryCardGroup = LxWndClass("UISubSorceryCardGroup", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSorceryCardGroup:UISubSorceryCardGroup()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSorceryCardGroup:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSorceryCardGroup:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSorceryCardGroup:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:UpdateList()
end

function UISubSorceryCardGroup:SetCardTrans(trans, refId)
	if not refId then
		return
	end
	local heroRoot = CS.FindTrans(trans, "Hero/Root")
	local heroLock = CS.FindTrans(trans, "Hero/Lock")
	local heroAdd = CS.FindTrans(trans, "Hero/Add")
	local cardIcon = CS.FindTrans(trans, "Card/CardIcon")
	local cardFrame = CS.FindTrans(trans, "Card/CardFrame")
	local tag = CS.FindTrans(trans, "Tag")
	local name = CS.FindTrans(trans, "Name")

	local cardList = gModelSorceryCard:GetCardList()
	local cardInfo = cardList[tonumber(refId)]
	local heroId = cardInfo and cardInfo.heroId or 0
	local isHero = tonumber(heroId) > 0
	local isCard = cardInfo ~= nil
	CS.ShowObject(heroRoot, isHero)
	CS.ShowObject(heroLock, not isCard)
	CS.ShowObject(heroAdd, not isHero and isCard)
	if isHero then
		local commonIconCls = self:GetCommonIcon(trans:GetInstanceID())
		commonIconCls:Create(heroRoot)
		commonIconCls:SetHeroPlayer(heroId)
		commonIconCls:DoApply()
	end

	if gLGameLanguage:IsJapanVersion() then
		LxUiHelper.SetSizeWithCurAnchor(CS.FindTrans(name,"UIText"),1,50)
	end

	local cfg = gModelSorceryCard:GetSorceryCardRefByRefId(tonumber(refId))
	self:SetWndEasyImage(cardIcon, cfg.icon)
	self:SetWndEasyImage(cardFrame, cfg.frameRes)
	self:SetTextTile(name, ccLngText(cfg.name))

	local limitCfg = gModelSorceryCard:GetSorceryCardUseLimitRefByRefId(cfg.equipLimit)
	local jobList = {}
	if limitCfg.suitCareer ~= "" then
		local jobData = string.split(limitCfg.suitCareer, "|")
		for _, v in ipairs(jobData) do
			jobList[tonumber(v)] = true
		end
	else
		jobList = { true, true, true, true }
	end
	for i = 1, 4 do
		local icon = CS.FindTrans(tag, "Icon" .. i)
		self:SetWndEasyImage(icon, "public_career_icon_" .. i)
		CS.ShowObject(icon, jobList[i])
	end

	self:SetWndClick(heroRoot, function()
		GF.OpenWnd("UISorceryCardSpeedHero", { refId = tonumber(refId), heroId = heroId })
	end)
	self:SetWndClick(heroAdd, function()
		GF.OpenWnd("UISorceryCardSpeedHero", { refId = tonumber(refId), heroId = heroId })
	end)
	self:SetWndClick(heroLock, function()
		GF.ShowMessage(ccClientText(29576))
	end)
	self:SetWndClick(cardIcon, function()
		local curLv = cardInfo and cardInfo.level or 0
		local skillGroup = cfg.skillGroup
		local skillRef = gModelSorceryCard:GetSorceryCardSkillRef(skillGroup, curLv)
		local argList = {
			skill = skillRef.skill,
			wndType = 7,
			cardId = tonumber(refId),
			skillGroup = skillRef.group,
			cardLevel = curLv
		}
		gModelGeneral:OpenSkillWnd(argList)
	end)
end

function UISubSorceryCardGroup:DrawList(_, trans, data, pos)
	local title = CS.FindTrans(trans, "Title")
	local more = CS.FindTrans(trans, "More")
	local cardObj = CS.FindTrans(trans, "CardObj")
	local downObj = CS.FindTrans(trans, "DownObj")
	local desTitle = CS.FindTrans(downObj, "DesTitle")
	local des = CS.FindTrans(downObj, "Des")

	data = data.cfg
	self:SetTextTile(title, ccLngText(data.name))
	self:SetWndText(desTitle, ccClientText(29568))
	self:SetWndText(des, ccLngText(data.effectTxt))

	local cardS = data.cardDetail
	local cardData = string.split(cardS, ",")
	for i = 1, 3 do
		local cardTrans = CS.FindTrans(cardObj, "Card" .. i)
		local cfg = cardData[i]
		self:SetCardTrans(cardTrans, cfg)
		CS.ShowObject(cardTrans, cfg ~= nil)
	end

    local uiText = LxUiHelper.FindXTextCtrl(des)
	local desH = uiText.preferredHeight
	local h = self.showMoreTrans[pos] and 212 + desH + 65 or 212
	trans.sizeDelta = Vector2.New(592, h)
	CS.ShowObject(downObj, self.showMoreTrans[pos])

	self:SetWndClick(more, function()
		if not self.showMoreTrans[pos] then
			self.showMoreTrans[pos] = false
		end
		self.showMoreTrans[pos] = not self.showMoreTrans[pos]
		self.uiList:DrawAllItems()
		if self.showMoreTrans[pos] then
			self.uiList:MoveToPos(pos)
		end
	end)
end

function UISubSorceryCardGroup:UpdateList()
	local list = ModelSorceryCard:GetSorceryCardRecomGroupRef()
	if self.bShowLock then
		local cardList = gModelSorceryCard:GetCardList()
		local t = {}
		for _, v in ipairs(list) do
			local cardS = v.cfg.cardDetail
			local cardData = string.split(cardS, ",")
			local isAll = true
			for _, refId in ipairs(cardData) do
				local cardInfo = cardList[tonumber(refId)]
				if not cardInfo then
					isAll = false
				end
			end
			if isAll then
				table.insert(t, v)
			end
		end
		list = t
	end

	if self.uiList then
		self.uiList:ResetList(list)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("List")
		self.uiList:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
	end
	CS.ShowObject(self.mNoRecord2, #list == 0)
end

function UISubSorceryCardGroup:InitCommon()
	------------------------------------------------------------------
	---member
	self.bShowLock = false
	self.showMoreTrans = {}

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mShowLock, ccClientText(29574))
	self:SetWndText(self.mEmptyText, ccClientText(29575))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mShowLock, function()
		self.bShowLock = not self.bShowLock
		CS.ShowObject(self.mYes, self.bShowLock)
		self:UpdateList()
	end)

	------------------------------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp, function()
		if self.uiList then
			self.uiList:DrawAllItems()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.SorceryCardUnloadResp, function()
		if self.uiList then
			self.uiList:DrawAllItems()
		end
	end)
end


------------------------------------------------------------------
return UISubSorceryCardGroup