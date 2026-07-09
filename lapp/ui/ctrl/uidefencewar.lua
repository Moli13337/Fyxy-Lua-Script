---
--- Created by wzz.
--- DateTime: 2025/2/26 16:21:43
---
------------------------------------------------------------------
local LWnd             = LWnd
---@class UIDefenceWar:LWnd
local UIDefenceWar    = LxWndClass("UIDefenceWar", LWnd)
------------------------------------------------------------------

local typeUIImage      = typeof(UnityEngine.UI.Image)
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeUIText       = typeof(CS.YXUIText)
local Tweening         = DG.Tweening
local Color            = Color
local Vector3          = Vector3
local CS               = CS
local math             = math

-- 伤害飘字间隔
local HudInterval      = 0.2

local HidPos           = Vector2(999999, 999999, 0)

local timerkey         = 1

local OneFrameAddExp   = 10


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWar:UIDefenceWar()
	self._index = 0
	self._cacheHubList = {}
	self._seqMap = {}

	self._model = gModelDefenceWar
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWar:OnWndClose()
	for k, tab in pairs(self._seqMap) do
		if tab.seq then
			tab.seq:Kill()
		end
	end


	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWar:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWar:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:IntCardList()
	self:RefreshWhenOpen()

	local func = self:GetWndArg("openCallback")
	if func then
		func()
	end
end

-- 初始事件
function UIDefenceWar:InitEvents()
	self:SetWndClick(self.mBtnHurt, function() self:OnBtnHurt() end)
	self:SetWndClick(self.mBtnPause, function() self:OnBtnPause() end)


	self:WndEventRecv(EventNames.DEFENCEWAR_MAP_LEVUP, function(...)
		self:OnMapLevUp(...)
	end)
	self:WndEventRecv(EventNames.DEFENCEWAR_SKILL_SELECT_FINISH, function(...)
		self:OnSelectSkillFinish(...)
	end)
	self:WndEventRecv(EventNames.DEFENCEWAR_BUFF_CHANGE, function(...)
		self:OnBuffChange(...)
	end)
	self:WndEventRecv(EventNames.DEFENCEWAR_CORE_HURT, function(...)
		self:OnCoreHurt(...)
	end)
	self:WndEventRecv(EventNames.DEFENCEWAR_MONSTER_WAVE, function(...)
		self:OnMonsterWave(...)
	end)
	self:WndEventRecv(EventNames.DEFENCEWAR_USE_SKILL, function(...)
		self:OnUseSkill(...)
	end)
	self:WndEventRecv(EventNames.DEFENCEWAR_GAME_OVER, function(...)
		self:OnGameOver(...)
	end)
	self:WndEventRecv(EventNames.DEFENCEWAR_GAME_START, function(...)
		self:OnGameStart(...)
	end)
end

-- 刷新卡牌列表
function UIDefenceWar:RefreshCardList()
	for index, ui in ipairs(self._cardList) do
		local data = self._cardDataList[index]
		local heroId = data.heroId
		local isShow = heroId > 0
		if isShow then
			local skillId = data.skillId or 0
			local skillLev = data.skillLev or 1
			self._model:DrawCard(self, ui.card, { heroId = heroId, lev = skillLev })
		end

		self:ShowTrans(ui.card, ui.cardInitPos, isShow)
		self:ShowTrans(ui.skillRoot, ui.skillRootInitPos, isShow)
		self:ShowTrans(ui.imgCdBg, ui.imgCdBgInitPos, isShow)
		self:ShowTrans(ui.txtIndex, ui.txtIndexInitPos, isShow)
		self:ShowTrans(ui.buffTrans, ui.buffTransInitPos, isShow)
	end

	self:RefreshSkillList()
	self:RefreshBuffList()
end

-- 播放技能特效
function UIDefenceWar:PlaySkillEffect(playIndex)
	local effName = "fx_ui_bwmnc_attack"
	local scale = 80
	if playIndex == 1 then
		scale = 100
	end

	self:CreateWndEffect(self["mEffCard" .. playIndex], effName, playIndex, scale)
end

-- 获取每次添加经验的最大值
function UIDefenceWar:GetAddExpMax(lev)
	local max = self._model:GetCurExp(lev)
	return math.ceil(max / 30), max
end

-- 波次变化
function UIDefenceWar:OnMonsterWave()
	self:RefreshMonsterWave()
end

-- buff变化
function UIDefenceWar:OnBuffChange()
	self._cardDataList = self._heroCtrl:GetCurSkillDataList()
	self:RefreshBuffList()
end

-- 使用技能
function UIDefenceWar:OnUseSkill(param)
	if not param.isBaseSkill then
		return
	end

	local playIndex
	for index, data in ipairs(self._cardDataList) do
		if data.heroId == param.heroId then
			playIndex = index
			break
		end
	end

	if not playIndex then
		return
	end
	self:PlaySkillEffect(playIndex)
end

-- update
function UIDefenceWar:Update()
	if self._mgr:IsPause() then
		return
	end
	self:RefreshCardCD()
	self:UpdateExp()
end

-- 弹出一个对象
function UIDefenceWar:PopHubObj()
	local data = table.remove(self._cacheHubList)
	if not data then
		data = self:CreateHubObj()
	end
	return data
end

-- 地图等级提升
function UIDefenceWar:OnMapLevUp(param)
	local addExp = param.addExp
	self._addExp = self._addExp + addExp
end

-- 点击伤害
function UIDefenceWar:OnBtnHurt()
	GF.OpenWnd("UIDefenceWarBattleDetail")
end

-- 创建一个对象
function UIDefenceWar:CreateHubObj()
	local data      = {}
	data.gameObject = LxUnity.InstantObject(self.mTxtHud.gameObject)
	data.transform  = data.gameObject.transform
	data.txt        = data.transform:GetComponent(typeUIText)

	return data
end

-- region 伤害飘字 ----------------------------------------------------
--

-- 伤害飘字
function UIDefenceWar:ShowHub(num)
	self._index   = self._index + 1
	local index   = self._index

	local obj     = self:PopHubObj()
	local trans   = obj.transform
	local hurtTxt = obj.txt
	trans:SetParent(self.mHudRoot, false)

	hurtTxt.text = self:FormatHurtNumSpriteText(-num)

	local color = hurtTxt.color
	color.a = 0
	hurtTxt.color = color
	trans.localPosition = Vector3(0, 0, 0)
	trans.localScale = Vector3(0.1, 0.1, 0.1)

	local tw1 = YXTween.TweenFloat(0, 1, 0.3, function(ival)
		hurtTxt.color = Color(color.r, color.g, color.b, ival)
	end)
	local tw2 = trans:DOScale(1.2, 0.3)
	local tw22 = trans:DOScale(1, 0.2)
	local tw3 = trans:DOLocalMoveY(100, 1.2)
	local tw4 = YXTween.TweenFloat(1, 0, 1, function(ival)
		hurtTxt.color = Color(color.r, color.g, color.b, ival)
	end)


	local delayTime = 0
	if not self._nextSeqTime then
		self._nextSeqTime = 0
	else
		local curTime = os.clock()
		if curTime > self._nextSeqTime then
			self._nextSeqTime = curTime + HudInterval
		else
			delayTime = self._nextSeqTime - curTime
			self._nextSeqTime = curTime + HudInterval + delayTime
		end
	end

	local seq = Tweening.DOTween.Sequence()
	seq:Insert(delayTime, tw1)
	seq:Insert(delayTime, tw2)
	seq:Insert(delayTime + 0.3, tw22)
	seq:Insert(delayTime + 0.3, tw3)
	seq:Insert(delayTime + 1, tw4)
	seq:Play()
	seq:OnComplete(function()
		self._seqMap[index].seq = nil
		self:RecycleHubObj(obj)
	end)

	self._seqMap[index] = { seq = seq }



	-- self:SetWndText(self.mTxtHub, ccClientText(46801))
end

-- 绘制buff列表项
function UIDefenceWar:OnDrawBuffItem(uilist, root, data)
	if not uilist then
		uilist = {}
		uilist.icon = CS.FindTrans(root, "icon")
	end

	local skillRef = self._model:GetSkillRef(data.skillId, data.skillLev)
	self:SetWndEasyImage(uilist.icon, skillRef.bufficon)

	return uilist
end

-- 刷新界面
function UIDefenceWar:RefreshWhenOpen()
	local ref = self._stageRef
	self:SetWndEasyImage(self.mBg, ref.wall)
	self:SetWndText(self.mTitle, ccLngText(ref.name))

	self:RefreshCardList()
	self:RefreshHp()
	self:RefreshExp()
	self:RefreshMonsterWave()
end

-- 回收一个对象
function UIDefenceWar:RecycleHubObj(data)
	data.transform:SetParent(self.mHudPool, false)
	table.insert(self._cacheHubList, data)
end

-- 刷新buff列表
function UIDefenceWar:RefreshBuffList()
	for index, ui in ipairs(self._cardList) do
		local data = self._cardDataList[index]
		local heroId = data.heroId
		local isShow = heroId > 0
		if isShow then
			self:SetComList(ui.buffList, data.buffList, function(...) return self:OnDrawBuffItem(...) end)
			ui.buffScrollRect.horizontal = #data.buffList > 3
		end
	end
end

-- 显示/隐藏对象
function UIDefenceWar:ShowTrans(trans, initPos, show)
	if show then
		trans.localPosition = initPos
	else
		trans.localPosition = HidPos
	end
end

-- 点击暂停
function UIDefenceWar:OnBtnPause()
	self._mgr:SetPause(true)
	GF.OpenWnd("UIDefenceWarPause")
end

-- 刷新生命值
function UIDefenceWar:RefreshHp()
	local cur = self._curHp
	local max = self._hpMax

	self:SetWndText(self.mTxtHp, ccClientText(46800, cur, max))
	self._ImgHp.fillAmount = cur / max
end

-- 初始化卡牌列表
function UIDefenceWar:IntCardList()
	self._cardList = {}
	for i = 1, 5 do
		-- 卡牌
		local trans = self["mCard" .. i]
		local tab = {}
		tab.trans = trans
		tab.card = CS.FindTrans(trans, "DefenceWarCard")
		tab.cardInitPos = tab.card.localPosition

		-- 下标
		tab.txtIndex = self["mTxtIndex" .. i]
		tab.txtIndexInitPos = tab.txtIndex.localPosition

		-- 本体cd
		tab.imgCdBg = self["mImgCdBg" .. i]
		local imgCdTrans = CS.FindTrans(tab.imgCdBg, "ImgCd")
		tab.imgCd = imgCdTrans:GetComponent(typeUIImage)
		tab.imgCdBgInitPos = tab.imgCdBg.localPosition

		-- 技能列表
		local skillRoot = self["mSkillList" .. i]
		local list = {}
		for j = 1, 3 do
			local trans   = CS.FindTrans(skillRoot, "Item" .. j)
			local bg      = CS.FindTrans(trans, "Bg")
			local icon    = CS.FindTrans(trans, "Icon")
			local mask    = CS.FindTrans(trans, "Mask")
			local txtTime = CS.FindTrans(trans, "TxtTime")
			mask          = mask:GetComponent(typeUIImage)
			list[j]       = { bg = bg, icon = icon, trans = trans, mask = mask, txtTime = txtTime }
		end
		tab.skillList = list
		tab.skillRoot = skillRoot
		tab.skillRootInitPos = skillRoot.localPosition

		-- buff列表
		local buffTrans = self["mBuff" .. i]
		tab.buffTrans = buffTrans
		tab.buffTransInitPos = buffTrans.localPosition
		tab.buffScrollRect = buffTrans:GetComponent(typeOfScrollRect)
		tab.buffList = CS.FindTrans(buffTrans, "Viewport/BuffList")

		self._cardList[i] = tab

		self:SetWndText(tab.txtIndex, i)
		self:SetWndClick(tab.card, function() self:OnClickCard(i) end)
	end
end

-- 转成数字
function UIDefenceWar:FormatHurtNumSpriteText(num)
	local text = LUtil.FormatHurtNumSpriteText(math.abs(num), false, 100)
	return text
end

-- 初始界面化数据
function UIDefenceWar:InitData()
	self._mgr = gLGpManager:FindDefenceWarGp()
	self._heroCtrl = self._mgr:GetCtrl("Hero")

	self._hpMax = self._model:GetCoreMaxHp() + self._model:GetInitCoreHp()
	self._curHp = self._hpMax
	self._stageId = self._mgr:GetPlayingStageId()

	self._stageRef = gModelDefenceWar:GetStageRef(self._stageId)

	-- 最大等级
	self._expMaxLev = self._stageRef.levelMax

	self._exp = 0
	self._expLev = 1
	self._addExp = 0

	self._cardDataList = self._heroCtrl:GetCurSkillDataList()
end

-- 刷新技能列表
function UIDefenceWar:RefreshSkillList()
	for index, ui in ipairs(self._cardList) do
		local data = self._cardDataList[index]
		local heroId = data.heroId
		local isShow = heroId > 0
		if isShow then
			for j, skillUi in ipairs(ui.skillList) do
				local skillData = data.skillList[j + 1] -- 第一个技能列表为本体技能
				isShow = skillData.skillId > 0
				if isShow then
					local skillRef = self._model:GetSkillRef(skillData.skillId, skillData.skillLev)
					-- self:SetWndEasyImage(skillUi.bg, skillRef.icon)
					self:SetWndEasyImage(skillUi.icon, skillRef.skillicon)
				end
				CS.ShowObject(skillUi.trans, isShow)
			end
		end
	end
end

-- 游戏开始
function UIDefenceWar:OnGameStart()
	self:InitData()
	self:RefreshWhenOpen()
	self:InitTimer()
end

-- 游戏结束
function UIDefenceWar:OnGameOver()
	self:TimerStop(timerkey)
end

-- 添加经验
function UIDefenceWar:UpdateExp()
	if self._addExp <= 0 then
		return
	end

	if self._pauseAddExp then
		return
	end

	local addExpMax, curMax = self:GetAddExpMax(self._expLev)
	local addExp = addExpMax
	if self._addExp < addExpMax * 1.5 then
		addExp = self._addExp
		self._addExp = 0
	else
		self._addExp = self._addExp - addExpMax
	end

	self._exp = self._exp + addExp
	local cur = self._exp
	local newLev = self._model:GetLevByExp(self._exp, self._expLev)
	if self._expLev ~= newLev and newLev <= self._expMaxLev then
		self._mgr:ShowSkillSelect()
		self._pauseAddExp = true
		self._expLev = newLev

		cur = curMax

		self._addExp = self._exp - curMax
		self._exp = curMax
	end

	self:SetWndText(self.mTxtLev, ccClientText(46802, self._expLev))
	self:SetWndText(self.mTxtExp, ccClientText(46803, cur, curMax))
	self._ImgExp.fillAmount = cur / curMax
end

-- 核心受伤
function UIDefenceWar:OnCoreHurt(param)
	local hurt = param.hurt
	self._curHp = self._curHp - hurt
	if self._curHp < 0 then
		self._curHp = 0
	end
	self:ShowHub(-hurt)
	self:RefreshHp()
end

-- 刷新怪物波次
function UIDefenceWar:RefreshMonsterWave()
	local cur, max = self._mgr:GetMonsterWave()
	self:SetWndText(self.mTxtTimes, ccClientText(46801, cur, max))
end

-- 初始时间
function UIDefenceWar:InitTimer()
	if self:IsTimerExist(timerkey) then
		return
	end

	local timePara = {
		key = timerkey,
		loopcnt = -1,
		interval = 0.02,
		timescale = false,
		callOnStart = true,
		func = function()
			self:Update()
		end
	}
	self:TimerStartImpl(timePara)
end

-- 初始界面化文本
function UIDefenceWar:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetTextTile(self.mBtnHurt, ccClientText(46804))

	self._ImgHp = self:FindCommonComponent(self.mHp, typeUIImage)
	self._ImgExp = self:FindCommonComponent(self.mExp, typeUIImage)
end

-- 技能选择结束
function UIDefenceWar:OnSelectSkillFinish()
	self._cardDataList = self._heroCtrl:GetCurSkillDataList()
	self:RefreshCardList()

	self._pauseAddExp = nil
	self._mgr:SetPause(false)
end

-- 刷新经验
function UIDefenceWar:RefreshExp()
	local cur = self._exp
	local lev = self._expLev
	local max = self._model:GetCurExp(lev)

	self:SetWndText(self.mTxtLev, ccClientText(46802, lev))
	self:SetWndText(self.mTxtExp, ccClientText(46803, cur, max))

	self._ImgExp.fillAmount = cur / max
end

-- 点击卡牌
function UIDefenceWar:OnClickCard(index)
	self:ShowHub(index)
end

-- 刷新卡牌cd
function UIDefenceWar:RefreshCardCD()
	self._cardDataList = self._heroCtrl:GetCurSkillDataList()

	local data, heroId, skillData, isShow, fillAmount
	for index, ui in ipairs(self._cardList) do
		data = self._cardDataList[index]
		heroId = data.heroId
		isShow = heroId > 0
		if isShow then
			skillData = data.skillList[1]

			fillAmount = (skillData.skillInitCd - skillData.skillCd) / skillData.skillInitCd
			-- 本体卡
			ui.imgCd.fillAmount = fillAmount

			-- 持能列表
			for j, skillUi in ipairs(ui.skillList) do
				skillData = data.skillList[j + 1]

				if skillData.skillCd <= 0.01 then
					self:SetWndText(skillUi.txtTime, "")
					fillAmount = 0
				else
					fillAmount = skillData.skillCd / skillData.skillInitCd
					self:SetWndText(skillUi.txtTime, math.ceil(skillData.skillCd))
				end
				skillUi.mask.fillAmount = fillAmount
			end
		end
	end
end

-- endregion 伤害飘字 ----------------------------------------------------



------------------------------------------------------------------
return UIDefenceWar