---
--- Created by Administrator.
--- DateTime: 2023/10/13 20:43:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTip:LWnd
local UISagaTip = LxWndClass("UISagaTip", LWnd)


UISagaTip.TYPE_LOCAL = 1
UISagaTip.TYPE_NET = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTip:UISagaTip()
	---@type table<number,CommonIcon>
	self._equipIconList = {}

	---@type table<number,CommonIcon>
	self._runeUIIconList = {}

	---@type CommonIcon
	self._heroIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTip:OnWndClose()
	self:ClearCommonIconList(self._equipIconList)
	self:ClearCommonIconList(self._runeUIIconList)
	if self._heroIconCls then
		self._heroIconCls:Destroy()
		self._heroIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()

	CS.ShowObject(self.mShareBtn,self._share == true)
	
	self:InitEvent()
	self:InitMsg()
	self:SetXUITextText(self.mShareBtnName,ccClientText(10118))
	self:SetXUITextText(self.mCommentBtnName,ccClientText(10110))
	self:SetXUITextText(self.mAttrText,ccClientText(10045))
	self:SetXUITextText(self.mSkillText,ccClientText(10046))
	self:SetXUITextText(self.mGiftText,ccClientText(10047))
	self:SetXUITextText(self.mEquipText,ccClientText(10048))
	-- self:SetXUITextText(self.mArtifactText,ccClientText(10049))

	if self._wndType == UISagaTip.TYPE_LOCAL then
		self:ShowLocalData()
	else
		self:Refresh()
	end
	CS.ShowObject(self.mArtifactDiv,false)

	--if not self._refId then
	--	if(not self._serverId)then
	--		self:SeqHeroAttribute()
	--	end
	--else
	--	self:ShowLocalData()
	--end
	--CS.ShowObject(self.mArtifactDiv,false)
	--if(self._serverId)then
	--	local heroId = self._heroData.id
	--	local attrData,equipData,heroRune,heroTalent = gModelHero:GetHeroAttrAndEquipInfoById(heroId)
	--	if(attrData)then
	--		self:Refresh()
	--	else
	--		self:SeqHeroAttribute()
	--	end
	--end
end

function UISagaTip:ShowLocalData()
	local ref,refId,star = self._ref,self._refId,self._star
	local skin = self._skin
	if not ref then return end
	local starType = ref.starType

	local starId = gModelHero:GetStarId(starType,star)
	local starRef = gModelHero:GetHeroStarById(starId)
	local maxLevel = starRef.maxLevel
	local grade = self:GetMaxClass(maxLevel)
	local gradeId = gModelHero:ConvertToHeroGradeId(self._classType,grade)

	--printInfoNR("打印而已，莫慌	====== 英雄RefId:" .. refId .. ",星级:" .. star .. ",阶级:"..grade .. ",英雄等级:" .. maxLevel)

	local data = {
		refId = refId,
		star = star,
		level = maxLevel,
		isMon = false,
		skin = skin
	}
	self:SetHeroIcon(data)

	local qualityIcon = ref.qualityIcon
	self:SetWndEasyImage(self.mHeroQuaImg,qualityIcon,function()
		CS.ShowObject(self.mHeroQuaImg,true)
	end)

	local name = gModelHero:GetHeroNameByRefId(refId,star)
	--self:SetWndText(self.mNameTxt,name)
	local color ="#"..gModelHero:GetHeroNameColorByRefId(refId,star)
	local nameStr = LUtil.FormatColorStr(name,color)
	local careerId = ref.careerType
	local careerRef = gModelHero:GetCareerRefByRefId(careerId)
	local jobName = ccLngText(careerRef.name)
	nameStr = nameStr .. "[" .. jobName .. "]"
	self:SetWndText(self.mNameTxt,nameStr)

	local quaId = gModelHero:GetHeroQualityByRefId(refId,star)
	local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
	if heroMessage then self:SetWndEasyImage(self.mHeadImg,heroMessage) end

	self._heroData = {refId = refId,star = star,grade = grade}

	CS.ShowObject(self.mEquipDiv,false)
	CS.ShowObject(self.mGiftDiv,false)
	CS.ShowObject(self.mDetailBtn,false)
	CS.ShowObject(self.mCommentBtn,false)
	CS.ShowObject(self.mCommentBtnName,false)

	local buffList = gModelHero:GetSkillBuff(refId,star)
	local power = 0
	local Atk,maxHp,Def,Speed = gModelHero:GetBaseAttrInfo(refId,maxLevel,starId,gradeId,buffList)
	local heroInitCritRatio = GameTable.CharacterConfigRef["heroInitCritRatio"] 		-- 暴伤基础
	local heroInitHit = GameTable.CharacterConfigRef["heroInitHit"] 					-- 暴伤基础
	local attrList = {Atk,maxHp,Def,Speed,heroInitCritRatio,heroInitHit}

	local baseAttr = {
		LAttrConst.Atk,
		LAttrConst.MaxHP,
		LAttrConst.Def,
		LAttrConst.Speed,
		LAttrConst.CritRatio,
		LAttrConst.Hit,
	}
	for i,v in ipairs(baseAttr) do
		local attrRef = gModelHero:GetAttributeRefById(v)
		local powerHero = attrRef.powerHero
		local value = attrList[i]
		local addPower = value * powerHero / 1000
		power = power + addPower
	end
	self:SetWndText(self.mNumTxt,LUtil.ToInteger(power))

	self._attrData = {
		[LAttrConst.Atk] = Atk,
		[LAttrConst.MaxHP] = maxHp,
		[LAttrConst.Def] = Def,
		[LAttrConst.Speed] = Speed,
	}
	self:RefreshAttr()
	self:RefreshSkillList()
end

function UISagaTip:SetHeroIcon(heroData)
	local baseClass = self._heroIconCls
	if not baseClass then
		baseClass = CommonIcon:New()
		self._heroIconCls = baseClass
		baseClass:Create(self.mHeroIcon)
	end
	baseClass:SetHeroDataSet(heroData)
	baseClass:DoApply()
end

function UISagaTip:RefreshAttr()
	local baseAttrList = self._baseAttrList
	local attrIconTransList = self._attrIconTransList
	local attrTransList = self._attrTransList
	local attrNumTransList = self._attrNumTransList
	local attrData = self._attrData
	for i,v in ipairs(baseAttrList) do
		local iconTrans = attrIconTransList[i]
		local attrTrans = attrTransList[i]
		local attrNumTrans = attrNumTransList[i]

		local iconImg = gModelHero:GetAttributeIconById(v)
		if iconImg then self:SetWndEasyImage(iconTrans,iconImg) end

		local txtName = gModelHero:GetAttributeNameById(v)
		if txtName then self:SetWndText(attrTrans,txtName) end

		local value = attrData[v]
		local attrRef = gModelHero:GetAttributeRefById(v)
		local numType,saveNum
		if attrRef then
			numType,saveNum = attrRef.numType,attrRef.saveNum
		else
			numType,saveNum = 1,0
		end
		if saveNum == 0 then
			value = math.floor(value + 0.5)
		else
			local temp = math.floor(value*100)
			value = temp/100
		end
		if numType == 2 then
			value = value.."%"
		end
		self:SetWndText(attrNumTrans,value)
	end
end

function UISagaTip:InitMsg()
	self:WndNetMsgRecv(LProtoIds.PowerShowResp,function(pb,ret)
		if not self._heroId then return end
		local showType = pb.type
		if showType == 2 then
			local _powers = pb.powers
			for i, v in ipairs(_powers) do
				local key = v.key
				if key == self._heroId then
					local power = v.power
					self:SetWndText(self.mNumTxt,LUtil.ToInteger(power))
				end
			end
		end
	end)
	--self:WndEventRecv(EventNames.HERO_ATTR_REQUEST_DONE,function (id)
	--	if id~= self._heroId then
	--
	--	end
	--end
	--
	--self:WndNetMsgRecv(LProtoIds.HeroAttributeResp,function(pb,ret)
	--	if pb.id ~= self._heroId then
	--		return
	--	end
	--	self:Refresh()
	--	--if pb.playerId == self._playerId then
	--	--	self:Refresh()
	--	--end
	--end)
end

function UISagaTip:Refresh()
	local heroData = self._heroData

	local refId = heroData.refId
	local star = heroData.star
	local heroId = heroData.id
	local data = {
		id = heroId,
		refId = refId,
		star = star,
		level = heroData.level or heroData.lv,
		isMon = false,
		isResonance = heroData.isResonance,
		skin = heroData.skin or 0,
	}

	self:SetHeroIcon(data)

	local name = ""
	local ref = gModelHero:GetHeroRef(refId)
	if ref then

		local qualityIcon = ref.qualityIcon
		self:SetWndEasyImage(self.mHeroQuaImg,qualityIcon,function()
			CS.ShowObject(self.mHeroQuaImg,true)
		end)

		name = gModelHero:GetHeroNameByRefId(refId,star)
	end
	if name then
		local color ="#"..gModelHero:GetHeroNameColorByRefId(refId,star)
		local nameStr = LUtil.FormatColorStr(name,color)
		local careerId = ref.careerType
		local careerRef = gModelHero:GetCareerRefByRefId(careerId)
		local jobName = ccLngText(careerRef.name)
		nameStr = nameStr .. "[" .. jobName .. "]"
		self:SetWndText(self.mNameTxt,nameStr)
	end

	local quaId = gModelHero:GetHeroQualityByRefId(refId,star)
	local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
	if heroMessage then self:SetWndEasyImage(self.mHeadImg,heroMessage) end

	local fightPower = heroData.fightPower or 0
	self:SetWndText(self.mNumTxt,LUtil.ToInteger(fightPower))

	local attrData,equipData,heroRune,heroTalent,heroOutfit = gModelHero:GetHeroAttrAndEquipInfoById(heroId)
	self._attrData = attrData
	self._equipData = heroOutfit
	self._runeData = heroRune
	self._talentData = heroTalent

	self:RefreshAttr()
	self:RefreshSkillList()
	self:RefreshEquipList()
	self:RefreshTalentList()
end

function UISagaTip:RefreshTalentList()
	local heroData = self._heroData
	local talentRefIdList = self._talentRefIdList
	local talentTransList = self._talentTransList
	local talentData = self._talentData
	for i = 3,4 do
		local runeRefId = talentRefIdList[i-2]
		local isLock = true
		local runePosRef = GameTable.MagicRunePosRef[runeRefId]
		local unlock = runePosRef.unlock
		unlock = string.split(unlock,"=")
		local condition = heroData.star
		if condition >= tonumber(unlock[2]) then isLock = false end
		local serTalentData = talentData[i]
		local skillId = i
		local ref
		if not isLock then
			if serTalentData then
				ref = gModelRune:GetSkillInfoByRefId(serTalentData)
				skillId = tonumber(ref.SkillId)
			end
		end
		local trans = CS.FindTrans(talentTransList[i-2],"SkillIcon")
		local baseClass = SkillIcon:New(self)
		baseClass:ShowLock(isLock)
		if not isLock then
			baseClass:ShowAdd(serTalentData == nil)
		else
			baseClass:ShowAdd(false)
		end
		baseClass:Create(trans,skillId,function()
			if isLock then
				GF.ShowMessage(ccClientText(10135))
			else
				if ref then
					local lv = ref.skillLevel
					local other = {lv = lv}
					GF.OpenWndUp("UIJNInfo",{skillId = skillId,other = other})
				else
					GF.ShowMessage(ccClientText(10136))
				end
			end
		end)
	end
end

function UISagaTip:GetMaxClass(lv)
	local grade = 0
	for i,v in ipairs(self._classList) do
		local tempGrade = v.grade
		local needLv = v.needLevel
		if lv >= needLv and needLv ~= -1 and grade <= tempGrade then
			grade = tempGrade
		elseif needLv == -1 and self._maxLv < lv then
			grade = tempGrade
		end
	end
	return grade
end

function UISagaTip:RefreshEquipList()
	local equipData = self._equipData
	local equipTransList = self._equipTransList
	local len = #equipTransList
	for i = 1,len do
		local serEquipData = equipData[i]
		local isSerData = true
		if not serEquipData then
			serEquipData = i
			isSerData = false
		end
		local equipTrans = equipTransList[i]
		local equipIconTrans = CS.FindTrans(equipTrans,"Icon")
		local baseClass = self._equipIconList[i]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._equipIconList[i] = baseClass
			baseClass:Create(equipIconTrans)
		end
		if isSerData then
			baseClass:SetOutfitData(serEquipData)
		else
			baseClass:SetCommonReward(LItemTypeConst.TYPE_OUTFIT, serEquipData,nil)
		end
		baseClass:EnableShowNum(false)
		self:SetIconClickScale(equipTrans, true)
		self:SetWndClick(equipTrans,function()
			if serEquipData ~= i then
				local heroData = self._heroData
				local id
				if heroData then id = heroData.id end
				--GF.OpenWndUp("UIEqInfo",{refId = serEquipData,heroId = id,noShowBtn = true})
				gModelGeneral:OpenOutfitInfoTip({heroData = heroData,curSerData = serEquipData,outfitType = 2},true)
			else
				GF.ShowMessage(ccClientText(10138))
			end
		end)
		baseClass:DoApply()
	end

--[[	local equipList = {}
	local equipData = self._equipData
	for k,v in pairs(equipData) do
		equipList[k] = v
	end
	local equipTransList = self._equipTransList
	local len = #equipTransList
	for i = 1,len do
		local serEquipData = equipList[i]
		if not serEquipData then serEquipData = i end
		local equipTrans = equipTransList[i]
		local equipIconTrans = CS.FindTrans(equipTrans,"Icon")
		local baseClass = self._equipIconList[i]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._equipIconList[i] = baseClass
			baseClass:Create(equipIconTrans)
		end
		baseClass:SetCommonReward(LItemTypeConst.TYPE_OUTFIT, serEquipData)
		baseClass:EnableShowNum(false)
		self:SetIconClickScale(equipTrans, true)
		self:SetWndClick(equipTrans,function()
			if serEquipData ~= i then
				local heroData = self._heroData
				local id
				if heroData then id = heroData.id end
				--GF.OpenWndUp("UIEqInfo",{refId = serEquipData,heroId = id,noShowBtn = true})
				gModelGeneral:OpenOutfitInfoTip({heroData = heroData,curSerData = serEquipData,outfitType = 2},true)
			else
				GF.ShowMessage(ccClientText(10138))
			end
		end)
		baseClass:DoApply()
	end]]
	--if not table.isempty(equipData) then
	--	for refId,v in pairs(equipData) do
	--		local equipRef = gModelEquip:GetEquipRefByRefId(refId)
	--		local equipType = equipRef.type
	--		print("====== refId,v,equipType = ",refId,v,equipType)
	--		local equipTrans = equipTransList[equipType]
	--		local equipIconTrans = CS.FindTrans(equipTrans,"EquipIcon")
	--		local baseClass = EquipIcon:New(self)
	--		baseClass:Create(equipIconTrans,refId,function()
	--			local heroData = self._heroData
	--			local id
	--			if heroData then id = heroData.id end
	--			GF.OpenWndUp("UIEqInfo",{refId = refId,heroId = id,noShowBtn = true})
	--		end)
	--	end
	--end

	local heroData = self._heroData
	local runeTransList = self._runeTransList
	local runeData = self._runeData
	local runeRefIdList = self._runeRefIdList
	for i = 1,2 do
		local runeRefId = runeRefIdList[i]
		local isLock = true
		local runePosRef = GameTable.MagicRunePosRef[runeRefId]
		local unlock = runePosRef.unlock
		unlock = string.split(unlock,"=")
		local unlockTxt = ccLngText(runePosRef.text)
		local condition
		if i == 1 then
			condition = heroData.level or heroData.lv
		else
			condition = heroData.star
		end
		if condition >= tonumber(unlock[2]) then isLock = false end
		local data = runeData[i]
		local runeTrans = runeTransList[i]
		local runeIconTrans = CS.FindTrans(runeTrans,"RuneIcon")
		local serverData = {}
		if data then serverData = data:GetServerData() end

		local serId = serverData.id or i
		local _runedata = {
			id = serId,
			playerId = serverData.playerId,
			refId = serverData.refId,
			heroId = serverData.heroId,
			skillId = serverData.skillId,
			attrId = serverData.attrId,
			recast = serverData.recast,
			nextSkillId = serverData.nextSkillId,
			nextAttrId = serverData.nextAttrId,
			score = serverData.score,
		}
		self:SetWndClick(runeIconTrans,function()
			if isLock then
				GF.ShowMessage(ccClientText(10139))
			else
				if not table.isempty(serverData) then
					local _data = {runeData = serverData}
					gModelGeneral:OpenRuneInfoTip(_data)
				else
					GF.ShowMessage(ccClientText(10140))
				end
			end
		end)
		local baseClass = self._runeUIIconList[i]
		if not baseClass then
			baseClass = CommonIcon:New()
			self._runeUIIconList[i] = baseClass
			baseClass:Create(runeIconTrans)
			self:SetIconClickScale(runeIconTrans, true)
		end
		baseClass:SetRuneData(serverData)
		baseClass:SetRuneLock(isLock,unlockTxt)
		baseClass:DoApply()
	end
end

function UISagaTip:RefreshSkillList()
	local heroData = self._heroData
	local refId,star,grade = heroData.refId ,heroData.star,heroData.grade

	local skillIdList = gModelHero:GetSkillListByRefIdAndStar(refId,star)
	local skillTransList = self._skillTransList
	for i,v in ipairs(skillTransList) do
		local skillData = skillIdList[i]
		local skillIconTrans = CS.FindTrans(v,"SkillIcon")
		local baseClass = SkillIcon:New(self)
		if skillData then
			local skillId,openClass = skillData.skillId,skillData.openClass
			baseClass:SetSkillInfo(grade,false,openClass,1)
			baseClass:Create(skillIconTrans,skillId,function()
				gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = i,heroData = heroData})
--[[				local hero = {
					refId = refId,
					star = star,
					grade = grade,
				}
				GF.OpenWndUp("UIJNInfo",{skillId = skillId,needGrade = openClass,index = i,heroData = hero})]]
			end)
		else
			baseClass:SetShowIcon(false,false)
			baseClass:Create(skillIconTrans,0)
		end
		CS.ShowObject(v,true)
	end
end

--function UISagaTip:SeqHeroAttribute()
--	if self._playerId and self._heroId then
--		local type = 1
--		if(self._isWonderHero)then
--			type = 2
--		elseif(self._isEndlesHero)then
--			type = 3
--		end
--		gModelHero:OnHeroAttributeReq(self._heroId,self._playerId,type)
--	end
--end

function UISagaTip:InitData()

	self._wndType = self:GetWndArg("wndType")

	self._playerId = self:GetWndArg("playerId")
	if string.isempty(self._playerId) then
		self._playerId = gLGameLogin:GetPlayerId()
	end
	local heroData = self:GetWndArg("heroData")
	self._share = self:GetWndArg("share")
	self._shareFunc = self:GetWndArg("shareFunc")
	self._refId = self:GetWndArg("refId")
	self._star = self:GetWndArg("star")
	self._skin = self:GetWndArg("skin")
	self._serverId = self:GetWndArg("serverId")
	self._heroData = heroData
	if heroData then
		self._heroId = heroData.id
		gModelHero:FindHeroPowStateById(self._heroId)
	end
	--self._isEndlesHero = heroData and heroData.isEndlesHero or false
	--self._isWonderHero = heroData and heroData.isWonderHero or false

	self._baseAttrList = {LAttrConst.Atk,LAttrConst.MaxHP,LAttrConst.Def,LAttrConst.Speed}
	self._attrIconTransList = {self.mIcon1,self.mIcon2,self.mIcon3,self.mIcon4}
	self._attrTransList = {self.mAttr1,self.mAttr2,self.mAttr3,self.mAttr4}
	self._attrNumTransList = {self.mAttrNum1,self.mAttrNum2,self.mAttrNum3,self.mAttrNum4}
	self._skillTransList = {self.mSkill1,self.mSkill2,self.mSkill3,self.mSkill4}
	self._equipTransList = {self.mEquip1,self.mEquip2,self.mEquip3,self.mEquip4}
	self._runeTransList = {self.mEquip5,self.mEquip6}
	self._talentTransList = {self.mGift1,self.mGift2}
	self._equipTypeList = {1,3,2,4}
	self._runeRefIdList = {1001,1002}
	self._talentRefIdList = {2001,2002}
	self._classList = {}
	if self._refId then
		local maxLv = 0
		local ref = gModelHero:GetHeroRef(self._refId)
		self._ref = ref
		if not self._star then self._star = ref.initStar end
		local classType = ref.classType
		self._classType = classType
		for k,v in pairs(GameTable.CharacterClassRef) do
			if v.type == classType then
				if maxLv < v.needLevel then
					maxLv = v.needLevel
				end
				table.insert(self._classList,v)
			end
		end
		table.sort(self._classList,function(c1,c2)
			return c1.grade < c2.grade
		end)
		self._maxLv = maxLv
	end
end

function UISagaTip:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mCommentBtn,function() GF.ShowMessage(ccClientText(11108)) end)
	self:SetWndClick(self.mDetailBtn,function()
		local career
		local refId = self._heroData and self._heroData.refId
		if refId then
			career = gModelHero:GetHeroCareerType(refId)
		end
		GF.OpenWndUp("UINewSagaAttr",{id = self._heroId,career = career,heroData = self._heroData})
	end)
	self:SetWndClick(self.mShareBtn,function()
		if self._shareFunc then self._shareFunc() end
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UISagaTip
