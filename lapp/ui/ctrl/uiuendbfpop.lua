---
--- Created by BY.
--- DateTime: 2023/10/5 17:14:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUendBfPop:LWnd
local UIUendBfPop = LxWndClass("UIUendBfPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUendBfPop:UIUendBfPop()
	---@type table<number, CommonIcon>
	self._heroIconList = {}

	self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUendBfPop:OnWndClose()
	self:ClearCommonIconList(self._heroIconList)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUendBfPop:OnCreate()
	LWnd.OnCreate(self)
	self._buffTransList = {}
	self._buffIndex = -1
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUendBfPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	--self:InitMessage()
	self:InitCommand()

end

function UIUendBfPop:OnClickConfirm()--点击确定
	local _buffIndex = self._buffIndex
	if(_buffIndex <= 0)then
		GF.ShowMessage(ccClientText(17248))
		return
	end
	local currBuff = self._buffList[_buffIndex] -- 选择的buff

	local combatData = self._combatData

	local autoBuff = 0
	if self._togglevalue then
		autoBuff = _buffIndex
	end
	combatData.buffId = currBuff.addAttrSkill
	combatData.isFromBuffWnd = true
	combatData.autoBuff = autoBuff
	gModelBattle:StartEndlessBattle(combatData)

	gModelEndles:ClearNewSelectBuff()
	self:WndClose()
end

function UIUendBfPop:ChangeBuff(trans,bool)
	local onImage = CS.FindTrans(trans,"OnImage")
	CS.ShowObject(onImage,bool)
end

function UIUendBfPop:BuffListItem(list,item, itemdata, itempos)
	self._buffTransList[itempos] = item
	local icon = CS.FindTrans(item,"Icon")
	local image = CS.FindTrans(item,"Image")
	local titleText = CS.FindTrans(item,"TitleText")
	local desText = CS.FindTrans(item,"DesText")
	local selTab = CS.FindTrans(item,"SelTab")
	local selTabEn = self:FindWndTrans(item, "SelTabEn")
	local selTabTrans = self._isForeignVersion and selTabEn or selTab
	local selText = CS.FindTrans(selTabTrans,"SelText")

	local ref = itemdata
	if(ref.icon~="")then
		self:SetWndEasyImage(icon,ref.icon)
	end
	if(ref.iconBg~="")then
		self:SetWndEasyImage(image,ref.iconBg)
	end
	local _lastBuff = self._lastBuff or 0
	CS.ShowObject(selTabTrans,_lastBuff == itempos)
	local skillRef = gModelHero:GetSkillByStarId(ref.addAttrSkill)
	self:SetWndText(selText,ccClientText(17268))
	self:SetWndText(titleText,ccLngText(skillRef.name))
	self:InitTextLineWithLanguage(titleText, -30)
	self:InitTextSizeWithLanguage(titleText, -2)
	self:SetWndText(desText,ccLngText(skillRef.description))
	self:SetWndClick(item, function(...) self:OnClickBuff(itempos) end,LSoundConst.CLICK_PAGE_COMMON)
end

function UIUendBfPop:OnClickClose()
	gModelBattle:DestroyBattleStatement(self._combatType)
	FireEvent(EventNames.ON_ENDLESS_BUFF_RETURN)
	self:WndClose()
end

function UIUendBfPop:HeroListItem(list,item, itemdata, itempos)
	local heroIcon = CS.FindTrans(item,"Root/HeroIcon")
	local barTrans = CS.FindTrans(item,"HpBar")
	local deadTag = CS.FindTrans(item,"DeadTag")
	local deadTagIcon = CS.FindTrans(item,"DeadTag/DeadIcon")
	local deadText = CS.FindTrans(item,"DeadTag/deadText")
	CS.ShowObject(deadTag,false)
	local hpBar = itemdata.isHeroInfo and 1 or itemdata.curHp/itemdata.maxHp
	LxUiHelper.SetProgress(barTrans,hpBar)
	if(itemdata.maxHp)then
		if(itemdata.curHp == 0)then
			CS.ShowObject(deadTag,true)
			self:SetWndText(deadText,ccClientText(16611))
		end
	end
	local heroInfo =itemdata.isHeroInfo and itemdata or itemdata:GetHeroIconInfo()

	local isEndlesHero = itemdata.playerId and itemdata.playerId~=gModelPlayer:GetPlayerId()
	--heroInfo.isEndlesHero = isEndlesHero
	heroInfo.heroType = isEndlesHero and 3 or 1
	local playerId = itemdata.playerId or gModelPlayer:GetPlayerId()

	local InstanceID = item:GetInstanceID()
	local baseClass = self._heroIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._heroIconList[InstanceID] = baseClass
		baseClass:Create(heroIcon)
		self:SetIconClickScale(heroIcon, true)
	end
	baseClass:SetHeroDataSet(heroInfo)
	baseClass:DoApply()

	self:SetWndClick(heroIcon,function ()
		gModelHero:ReqShowHeroTip(playerId,heroInfo)
	end)

	self:SetWndEasyImage(deadTagIcon,"timecopy_txt_1")
end

function UIUendBfPop:OnClickBuff(index)
	if(self._buffIndex>0)then
		local trans = self._buffTransList[self._buffIndex]
		self:ChangeBuff(trans,false)
	end
	local trans = self._buffTransList[index]
	self:ChangeBuff(trans,true)
	self._buffIndex = index
end

function UIUendBfPop:InitEvent()
	--self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mConfirmBtn, function(...) self:OnClickConfirm() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndToggleDelegate(self.mShowToggle,function (value)
		self._togglevalue = value
	end)
end

function UIUendBfPop:InitCommand()
	self._isForeignVersion = gLGameLanguage:IsForeignVersion()

	self:SetWndText(self.mTitleText,ccClientText(17244))
	self:SetWndText(self.mToggleText,ccClientText(17267))
	self:SetWndButtonText(self.mConfirmBtn,ccClientText(17246))
	self:SetWndButtonText(self.mBtnClose,ccClientText(17265))
	local hasNewSelect = gModelEndles:HaveNewSelectBuff()
	local str = nil
	if hasNewSelect then
		local timeS = gModelEndles:GetEndlessConfigRefByKey("autoSelectTime")
		str = string.replace(ccClientText(17247),timeS)
	else
		str = ccClientText(17261)
	end
	--local timeS = gModelEndles:GetEndlessConfigRefByKey("autoSelectTime")
	self:SetWndText(self.mTipsText,str)
	local _combatData = self:GetWndArg("combatData")
	local isOne = self:GetWndArg("isOne")
	CS.ShowObject(self.mBtnClose,isOne)
	self._combatData = _combatData
	--self._func = self:GetWndArg("func")
	local info
	if(_combatData)then
		local specialType = gModelEndles:GetEndlessTypeByCombatType(_combatData.combatType)
		info = gModelEndles:GetEndlesData(specialType)
	else
		info = gModelEndles:GetCurrTypeEndlesData()
	end
	local nextNode
	if(info.nowNode == info.initNode or info.nowNode<=0)then
		local ref = gModelEndles:GetEndlessCheckpointRefByRefId(info.initNode)
		nextNode = ref.id
	else
		local ref = gModelEndles:GetEndlessCheckpointRefByRefId(info.nowNode)
		local nexRef = gModelEndles:GetEndlessCheckpointRefByRefId(ref.nextRedId)
		nextNode = nexRef.id
	end
	self:SetWndText(self.mBattleNumText,string.replace(ccClientText(17245),nextNode))

	local _lastBuffType = 0
	local lastBuff = info.lastBuff
	if lastBuff > 0 then
		local skillRef = gModelEndles:GetEndlessBuffRefBySkillId(lastBuff)
		_lastBuffType = skillRef.bufftype
	end
	self._lastBuff = _lastBuffType
	local cfg = gModelEndles:GetEndlessRefByType(info.type)

	local combatType = cfg.combatTyep
	local formation = gModelEndles:GetFormationInfo(combatType)
	self._combatType = combatType
	if formation then
		--if(formation.artifactId>0)then
		--	local artRef = gModelDream:GetArtifactConfig(formation.artifactId)
		--	self:SetWndText(self.mArtifactText,ccLngText(artRef.name))
		--	self:SetWndEasyImage(self.mArtifactImage,artRef.icon,function ()
		--		CS.ShowObject(self.mArtifactImage,true)
		--	end)
		--end
		if(formation.formationRefId)then
			local forRef = gModelFormation:GetFormationByRefId(formation.formationRefId)
			self:SetWndText(self.mArrayText,ccLngText(forRef.name))
			self:SetWndEasyImage(self.mArrayImage,forRef.icon,function ()
				CS.ShowObject(self.mArrayImage,true)
			end)
		end
	end


	local newBuffList = gModelEndles:GetBuffList()
	local buffList = {}
	for i, v in ipairs(newBuffList) do
		local ref = gModelEndles:GetEndlessBuffRefBySkillId(v)
		table.insert(buffList,ref)
	end
	table.sort(buffList,function (a,b)
		return a.bufftype < b.bufftype
	end)
	self._buffList = buffList
	local _uiBuffList = self:GetUIScroll("_uiBuffList")
	_uiBuffList:Create(self.mBuffScroll,self._buffList,function (...) self:BuffListItem(...) end)

	local heroList = {}
	local battleHeroList = gModelEndles:GetBattleHeroList()
	if(#battleHeroList>0)then
		heroList = battleHeroList
	else
		if formation then
			for i, v in pairs(formation.grids) do
				local hero = gModelEndles:GetEndlessHeroData(combatType,v.id)
				local info = {
					playerId = hero.playerId,
					id = hero.id,
					refId = hero.refId,
					star = hero.star,
					level = hero.lv,
					fightPower = hero.fightPower,
					grade = hero.grade,
					isResonance = hero.isResonance,
					isHeroInfo = true,
					skin = hero.skin,
					form = hero.form,
				}
				table.insert(heroList,info)
			end
		end

	end
	local _uiHeroList = self:GetUIScroll("_uiHeroList")
	_uiHeroList:Create(self.mHeroScroll,heroList,function (...) self:HeroListItem(...) end)

	self:SetWndToggleValue(self.mShowToggle,false)
end
------------------------------------------------------------------
return UIUendBfPop


