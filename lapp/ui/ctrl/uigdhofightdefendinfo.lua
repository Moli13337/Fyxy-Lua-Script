---
--- Created by Administrator.
--- DateTime: 2024/6/20 18:18:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightDefendInfo:LWnd
local UIGdHoFightDefendInfo = LxWndClass("UIGdHoFightDefendInfo", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightDefendInfo:UIGdHoFightDefendInfo()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightDefendInfo:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightDefendInfo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightDefendInfo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitEvent()
	self:InitPara()


	self:OpenReq()
end

--region 初始化 --------------------------------------------------------------------------------
function UIGdHoFightDefendInfo:InitEvent()
	self:WndEventRecv(gModelGuildHolyBattle.EventArgs.StrongholdDataChange, function()
		self:OnStrongholdData()
	end)

	--ui
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)

	self:SetWndClick(self.mClose, function()
		self:WndClose()
	end)
end

function UIGdHoFightDefendInfo:SetSuccesssTimes()
	local str = string.replace(ccClientText(44027), self._playerShrongholdData.defence)
	self:SetWndText(self.mSuccessTimes, str)
end

function UIGdHoFightDefendInfo:CreateHeroList(list, item, itemdata, itempos)
	local root = CS.FindTrans(item, "HeroRoot")

	local InstanceID = root:GetInstanceID()

	local uiCommonList = self._uiHeroCommonList
	if not uiCommonList then
		uiCommonList = {}
	end
	--
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	local heroData = {
		index = itempos,
		id = itemdata.id,
		refId = itemdata.refId,
		star = itemdata.star,
		level = itemdata.level,
		isResonance = itemdata.isResonance,
		skin = itemdata.skin
	}

	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()

	local playerInfo = self._para.itemData
	local serverId = self._para.serverId

	self:SetWndClick(item, function()
		gModelHero:ReqShowHeroTip(playerInfo.playerId, itemdata, nil, nil, nil, serverId)
	end)

	item.localScale = Vector3.one * 0.8
end

function UIGdHoFightDefendInfo:OpenReq()
	local playerId = self._para.itemData.playerId
	gModelGuildHolyBattle:SendGuildBattleViewStrongholdReq(playerId)
end

--设置英雄的列表
function UIGdHoFightDefendInfo:SetHero()
	local heros
	if self._playerShrongholdData.monsterRefId > 0 then
		heros = gModelGuildHolyBattle:GetMonsterList(self._playerShrongholdData.monsterRefId)
	else
		local formation = self._playerShrongholdData.formation
		heros = formation:GetHeros()
	end

	local uiList = self._heroList
	if not uiList then
		uiList = self:GetUIScroll(self.mHeroItemList:GetInstanceID())
		uiList:Create(self.mHeroItemList, heros, function(...)
			self:CreateHeroList(...)
		end, UIItemList.SUPER)

		self._heroList = uiList
	else
		uiList:RefreshList(heros)
	end

	uiList:EnableScroll(true, true)
end

function UIGdHoFightDefendInfo:InitText()
	self:SetWndText(self.mTitle, ccClientText(44032))  --[44032] [我方防守成員]
	self:SetWndText(self.mRewardTitle, ccClientText(44023))  --[44023] [獎勵預覽]
	self:SetWndText(self.mInfo_Title_1, ccClientText(44024))  --[44024] [防守陣容]
	self:SetWndText(self.mRewardInfo, ccClientText(44033))  --[44033] [己方據點無法進攻]
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UIGdHoFightDefendInfo:OnStrongholdData()
	self._playerShrongholdData = gModelGuildHolyBattle:GetShrongholdInfo(self._para.itemData.playerId)
	self:SetSuccesssTimes()
	self:SetHero()
end

function UIGdHoFightDefendInfo:InitPara()
	self._para = self:GetWndArg("para")

	self:SetSpine()
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightDefendInfo:SetSpine()
	local heroTran = self:FindWndTrans(self.mHeroDetialRoot, "Hero")
	local instanceId = heroTran:GetInstanceID()
	if not self._heroSpine then
		self._heroSpine = LUIHeroObject:New(self)
		self._heroSpine:Create(heroTran, instanceId, self._para.spineName)
		self._heroSpine:SetScale(1.3)
		self._heroSpine:ShowHero(true)
		self._heroSpine:StartLoad()


	else
		self._heroSpine:ShowHero(true)
		self._heroSpine:StartLoad()
	end

	--星星
	for i = 1, 3 do
		local starRoot = self:FindWndTrans(self.mHeroDetialRoot, "StarRoot")

		local starKey = "Star_" .. i

		local star = self:FindWndTrans(starRoot, starKey)

		if i <= self._para.itemData.star then
			self:SetWndEasyImage(star, "hero_icon_star1")
		else
			self:SetWndEasyImage(star, "guildwar1_star -hui")
		end
	end
	local UIText = self:FindWndTrans(self.mHeroDetialRoot, "UIText")
	self:SetWndText(UIText, self._para.itemData.name)

	--战力
	local PowerText = self:FindWndTrans(self.mHeroDetialRoot, "PowerBg/Power")
	self:SetWndText(PowerText, LUtil.NumberCoversion(self._para.itemData.power))

end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIGdHoFightDefendInfo