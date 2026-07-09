---
--- Created by wzz.
--- DateTime: 2024/9/11 11:32:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDesireTrailMonsterTips:LWnd
local UIDesireTrailMonsterTips = LxWndClass("UIDesireTrailMonsterTips", LWnd)
------------------------------------------------------------------

local typeUIImage = typeof(UnityEngine.UI.Image)

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDesireTrailMonsterTips:UIDesireTrailMonsterTips()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDesireTrailMonsterTips:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDesireTrailMonsterTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end

function UIDesireTrailMonsterTips:OnStartCreate()
	self:InitData()

	self:WndEventRecv(EventNames.DESIRE_TRAIL_MONSTER_INFO, function(...) self:OnMonsterInfo(...) end)
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDesireTrailMonsterTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:InitSpine()
	self:Refresh()
end

-- 刷新顶部列表
function UIDesireTrailMonsterTips:RefreshTopList()
	if not self._pb then
		return
	end

	if self._tabIndex == 1 then
		self:RefreshHeroList()
	else
		self:RefreshDraconic()
	end
	CS.ShowObject(self.mHeroList, self._tabIndex == 1)
	CS.ShowObject(self.mDraconicList, self._tabIndex == 2)

	self:SetWndText(self.mTitle, ccLngText(self._pb.formationName))
end

-- 奖励列表 item
function UIDesireTrailMonsterTips:OnDrawAwardItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.itemRoot = CS.FindTrans(root, "itemRoot")
		uilist.random = CS.FindTrans(root, "random")
	end
	CS.ShowObject(uilist.random, data.isRandom)
    self:SetWndEasyImage(uilist.random, "wonderland_txt_1")
	self:CreateCommonIconImpl(uilist.itemRoot, data, { showNum = true })
	return uilist
end

-- 怪物信息 返回
function UIDesireTrailMonsterTips:OnMonsterInfo(pb)
	self._pb = pb
	if not self:IsWndValid() then
		return
	end
	self:RefreshTopList()
end

-- 切换标签页
function UIDesireTrailMonsterTips:OnTabChange(index)
	if index == self._tabIndex then
		return
	end

	if index == 2 then
		if self._pb and #self._pb.treasureSkilIds == 0 then
			GF.ShowMessage(ccClientText(45429))
			return
		end
	end
	self._tabIndex = index

	self:RefreshButtonState()
	self:RefreshTopList()
end

-- 刷新界面
function UIDesireTrailMonsterTips:Refresh()
	local floor = self._floor
	local eventRefId = self._eventRefId
	local canMove = self._canMove

	self:SetWndButtonGray(self.mBtnFight, not canMove)

	if not self._ref then
		printInfoN("奖励配置为空，eventRefId=" .. tostring(eventRefId) .. " floor=" .. tostring(floor))
		return
	end

	local challengeCount = gModelDesireTrail:GetChallengeCount()
	self:SetWndText(self.mTxtLeftTime, ccClientText(45412, challengeCount))

	self:RefreshTopList()
	self:RefreshAward()
	self:RefreshButtonState()
end

-- 初始化数据
function UIDesireTrailMonsterTips:InitData()
	self._tabIndex   = 1

	local argMap     = self:GetWndArgList()
	self._floor      = argMap.y
	self._eventRefId = argMap.eventRefId
	self._canMove    = argMap.canMove
	self._x          = argMap.x
	self._y          = argMap.y
	self._ref        = gModelDesireTrail:GetEventAwardRef(self._eventRefId, self._floor)

	self._gridData   = gModelDesireTrail:GetGridData(self._y, self._x)
	self._canMove    = false
	local status     = self._gridData.status
	if status == ModelDesireTrail.GridStatus.CanMove or status == ModelDesireTrail.GridStatus.Selected then
		self._canMove = true
	end

	gModelDesireTrail:DesireTrailMonsterReq(self._x, self._y)
end

-- 刷新龍紋
function UIDesireTrailMonsterTips:RefreshDraconic()
	if not self._pb then
		return
	end

	local itemDataList = {}
	for _, v in ipairs(self._pb.treasureSkilIds) do
		local ref, upRef = gModelDraconic:GetDraconicRefBySkillId(v)
		if ref and ref.effetcType == 1 then
			table.insert(itemDataList, {
				ref = ref,
				upRef = upRef,
			})
		end
	end

	self:SetComList(self.mDraconicList, itemDataList, function(...) return self:OnDrawDraconicSkillItem(...) end)
end

-- 初始精灵
function UIDesireTrailMonsterTips:InitSpine()
	local ref = gModelDesireTrail:GetEventConfig(self._eventRefId)
	self:CreateWndSpine(self.mSpine, ref.prefabSize, "key", false, function(dpSpine)

	end)

	local strChat = ccLngText(ref.choose)
	self:SetWndText(self.mChat, strChat)
	CS.ShowObject(self.mChat, strChat ~= "")
end

-- 初始界面化文本
function UIDesireTrailMonsterTips:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndButtonText(self.mBtnFight, ccClientText(45409))
	self:SetWndText(self.mTips, ccClientText(45413))
	self:SetWndTabText(self.mTab1, ccClientText(45410))
	self:SetWndTabText(self.mTab2, ccClientText(45411))
end

-- 刷新奖励
function UIDesireTrailMonsterTips:RefreshAward()
	local ref = self._ref

	local itemList = LUtil.GetRefItemDataList(ref.reward)

	-- 随机奖励
	local itemList2 = LUtil.GetRefItemDataList(self._gridData.moreInfo) or {}
	for k, v in ipairs(itemList2) do
		v.isRandom = true
		table.insert(itemList, v)
	end
	self:SetComList(self.mItemList, itemList, function(...) return self:OnDrawAwardItem(...) end)
end

-- 刷新英雄列表 item
function UIDesireTrailMonsterTips:OnDrawHeroItem(uilist, root, itemdata)
	if not uilist then
		uilist           = {}
		uilist.heroIcon  = CS.FindTrans(root, "heroIcon")
		uilist.die       = CS.FindTrans(root, "die")
		local hp         = CS.FindTrans(root, "1/hp")
		uilist.hp        = self:FindCommonComponent(hp, typeUIImage)

		uilist.baseClass = CommonIcon:New()
		uilist.baseClass:Create(uilist.heroIcon)
		self:SetIconClickScale(uilist.heroIcon, true)
	end

	local heroData = {
		index       = itemdata.index,
		id          = itemdata.id,
		refId       = itemdata.refId,
		star        = itemdata.star,
		level       = itemdata.lvl,
		grade       = itemdata.grade,
		fightPower  = itemdata.power,
		isResonance = itemdata.resonance,
		skin        = itemdata.skin,
		treeInfo    = itemdata.treeInfo,
		form        = itemdata.form,
		isMon       = itemdata.heroType == 3
	}

	uilist.baseClass:SetHeroDataSet(heroData)
	uilist.baseClass:DoApply()

	local curHp = itemdata.curHp
	local maxHp = itemdata.maxHp
	uilist.hp.fillAmount = curHp / maxHp
	CS.ShowObject(uilist.die, curHp <= 0)

	if itemdata.heroType == 1 then
		self:SetWndClick(uilist.heroIcon, function()
			-- gModelHero:ReqShowHeroTip(self._playerInfo._playerId, heroData, nil, nil, nil, self._playerInfo._serverId)
		end)
	end

	return uilist
end

-- 战斗按钮
function UIDesireTrailMonsterTips:OnBtnFight()
	if not self._canMove then
		local str
		if self._pb then
			str = ccLngText(self._pb.formationName)
		else
			str = ccClientText(45434)
		end
		GF.ShowMessage(ccClientText(45432, str))
		return
	end

	local challengeCount = gModelDesireTrail:GetChallengeCount()
	if challengeCount <= 0 then
		local itemRefId, exchangeNum = gModelDesireTrail:GetChallengeExchange()
		local haveNum = gModelItem:GetNumByRefId(itemRefId)
		local num = math.floor(haveNum / exchangeNum)
		if num <= 0 then
			local itemName = gModelItem:GetNameByRefId(itemRefId)
			GF.ShowMessage(ccClientText(45424, itemName))
			gModelGeneral:OpenGetWayWnd({ itemId = itemRefId })
			return
		end

		GF.ShowMessage(ccClientText(45430))
		GF.OpenWnd("UIDesireTrailBuyTimes")
		return
	end

	local x = self._x
	local y = self._y
	local eventRefId = self._eventRefId
	local otherName = ccLngText(self._pb.formationName)
	local skipBattle = false

	local bossList = self._pb.heroInfo or {}
	local grids = self._pb.grids
	local formationRefId = self._pb.formationRefId
	local power = tonumber(self._pb.power)

	local callback = function()
		gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_DESIRETRAIL, {
			x = x,
			y = y,
			otherName = otherName,
			eventRefId = eventRefId,
			skipBattle = skipBattle,
			bossList = bossList,
			grids = grids,
			formationRefId = formationRefId,
			power = power,
		})
	end


	local data = gModelDesireTrail:GetGridData(y, x)

	if data.status ~= gModelDesireTrail.GridStatus.CanMove then
		callback()
		return
	end


	local param = {
		x = x,
		y = y,
		type = 0,
		callback = callback,
	}

	gModelDesireTrail:DesireTrailOpsReq(param)
end

-- 刷新龙紋列表 item
function UIDesireTrailMonsterTips:OnDrawDraconicSkillItem(uilist, root, itemdata)
	if not uilist then
		uilist = {}
		uilist.draconicSkill = CS.FindTrans(root, "DraconicSkill")
	end

	local upRef = itemdata.upRef

	local param = {
		showName = true,
		showType = true,
		showStar = true,
		upRefId = upRef.refId,
	}
	gModelDraconic:DrawSkillItem(self, uilist.draconicSkill, param)

	self:SetWndClick(root, function()
		GF.OpenWnd("UIDraconicUpStar", { refId = upRef.type, starNum = upRef.rankNow, tips = true })
	end)

	return uilist
end

-- 刷新按钮状态
function UIDesireTrailMonsterTips:RefreshButtonState()
	self:SetWndTabStatus(self.mTab1, self._tabIndex == 1 and LWnd.StateOn or LWnd.StateOff)
	self:SetWndTabStatus(self.mTab2, self._tabIndex == 2 and LWnd.StateOn or LWnd.StateOff)
end

-- 初始事件
function UIDesireTrailMonsterTips:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mTab1, function() self:OnTabChange(1) end)
	self:SetWndClick(self.mTab2, function() self:OnTabChange(2) end)
	self:SetWndClick(self.mBtnFight, function() self:OnBtnFight() end)


	self:WndEventRecv(EventNames.DESIRE_TRAIL_BUY_CHALLENGE, function(...) self:Refresh(...) end)
end

-- 刷新英雄列表
function UIDesireTrailMonsterTips:RefreshHeroList()
	if not self._pb then
		return
	end

	local itemDataList = self._pb.heroInfo
	self:SetComList(self.mHeroList, itemDataList, function(...) return self:OnDrawHeroItem(...) end)

	local str = LUtil.PowerNumberCoversion(tonumber(self._pb.power))
	self:SetWndText(self.mTxtPower, str)
end

------------------------------------------------------------------
return UIDesireTrailMonsterTips