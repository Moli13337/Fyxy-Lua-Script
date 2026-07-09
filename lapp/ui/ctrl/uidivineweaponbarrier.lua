---
--- Created by Administrator.
--- DateTime: 2024/12/9 15:01:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponBarrier:LWnd
local UIDivineWeaponBarrier = LxWndClass("UIDivineWeaponBarrier", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponBarrier:UIDivineWeaponBarrier()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponBarrier:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponBarrier:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponBarrier:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitData()
end

function UIDivineWeaponBarrier:InitTeam()
	local monsterId = self.cfg.monster
	local monsterCfg = gModelHero:GetMonsterFormationRefByRefId(monsterId)
	self:SetWndText(self.mPowerText, LUtil.NumberCoversion(monsterCfg.monsterPower))
	local heroList = {}
	for i = 1, 10 do
		local monster = monsterCfg["monster" .. i]
		if monster > 0 then
			local cfg = GameTable.MonsterAttrRef[monster]
			local data = {
				refId = monster,
				level = cfg.lv,
				star = 0,
				isMon = true
			}
			table.insert(heroList, data)
		end
	end
	for i, v in ipairs(heroList) do
		local trans = CS.FindTrans(self.mTeamList, "Root" .. i)
		local commonIconCls = self:GetCommonIcon(i)
		commonIconCls:Create(trans)
		commonIconCls:SetHeroDataSet(v)
		commonIconCls:DoApply()
		CS.ShowObject(trans, true)
	end
end

function UIDivineWeaponBarrier:InitCommon()
	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	self.cfg = GameTable.DescendsBarrierRef[self.id]

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccLngText(self.cfg.name))
	self:SetWndText(self.mTeamText, ccClientText(46204))
	self:SetWndText(self.mCondText, ccClientText(46205))
	self:SetTextTile(self.mRewardTitle, ccClientText(46206))
	self:SetTextTile(self.mGaryBtn, ccClientText(46208))
	self:SetWndButtonText(self.mFightBtn, ccClientText(46207))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mFightBtn, function()
		local monsterId = self.cfg.monster
		local monsterCfg = gModelHero:GetMonsterFormationRefByRefId(monsterId)
		local chapterId = self.cfg.chapterId
		gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_47, {
			refId = self.id,
			otherName = ccLngText(self.cfg.name),
			power = monsterCfg.monsterPower,
			monsterRefId = monsterId,
			wndType = 1,
			returnFunc = function()
				FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
				GF.ChangeMap("LCityMap")
				GF.OpenWndBottom("UIOutts", { childIndex = 1 })
				GF.OpenWnd("UIOuttsList", { listRefId = 10102 })
				GF.OpenWnd("UIDivineWeaponFight")
				GF.OpenWnd("UIDivineWeaponChapter", { id = chapterId })
			end,
		})
		gModelDivineWeaponFight:SetFightChapter(chapterId)
	end)
end

function UIDivineWeaponBarrier:InitReward()
	for i = 1, 3 do
		local trans = CS.FindTrans(self.mRewardObj, "Root" .. i)
		local root = CS.FindTrans(trans, "Root")
		local starReward = CS.FindTrans(trans, "StarReward")

		local reward = LxDataHelper.ParseItem_4(self.cfg["reward" .. i])
		local commonIconCls = self:GetCommonIcon("reward" .. i)
		commonIconCls:Create(root)
		commonIconCls:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
		commonIconCls:DoApply()

		self:SetTextTile(starReward, string.replace(ccClientText(46213), i))

		self:SetWndClick(trans, function()
			gModelGeneral:ShowCommonItemTipWnd(reward)
		end)
	end
end

function UIDivineWeaponBarrier:InitBtn()
	local curBarrierId = gModelDivineWeaponFight:GetCurBarrierId()
	local chapterInfo = gModelDivineWeaponFight:GetChapterInfoById(self.cfg.chapterId)
	local notFullStarBarriers = chapterInfo.notFullStarBarriers
	local isPass = notFullStarBarriers[self.id] ~= nil
	local isFullStar = false
	if isPass then
		isFullStar = true
		for _, v in ipairs(notFullStarBarriers[self.id].star) do
			if not v then
				isFullStar = false
				break
			end
		end
	end
	CS.ShowObject(self.mIsPass, isPass and isFullStar)
	CS.ShowObject(self.mFightBtn, (isPass and not isFullStar) or not isPass)
	CS.ShowObject(self.mGaryBtn, curBarrierId < self.id)
end

function UIDivineWeaponBarrier:InitStarCond()
	local chapterInfo = gModelDivineWeaponFight:GetChapterInfoById(self.cfg.chapterId)
	local notFullStarBarriers = chapterInfo.notFullStarBarriers
	local isPass = notFullStarBarriers[self.id] ~= nil
	for i = 1, 3 do
		local trans = CS.FindTrans(self.mStarObj, "Star" .. i)
		local starOn = CS.FindTrans(trans, "StarOn")
		local condText = CS.FindTrans(trans, "Cond")

		local showOn = false
		if isPass then
			local starInfo = notFullStarBarriers[self.id].star
			showOn = starInfo[i]
		end
		CS.ShowObject(starOn, showOn)

		local cond = self.cfg["star" .. i]
		local condStr = cond and gModelDivineWeaponFight:GetStarStrByCond(cond) or ccClientText(46212)
		self:SetWndText(condText, condStr)
	end
end

function UIDivineWeaponBarrier:InitData()
	self:InitTeam()
	self:InitStarCond()
	self:InitReward()
	self:InitBtn()
end



------------------------------------------------------------------
return UIDivineWeaponBarrier