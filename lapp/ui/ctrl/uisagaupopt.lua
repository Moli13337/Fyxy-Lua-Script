---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaUpOpt:LWnd
local UISagaUpOpt = LxWndClass("UISagaUpOpt", LWnd)


UISagaUpOpt.TYPE_UP_STAR = 1
UISagaUpOpt.TYPE_UP_LVL = 2
UISagaUpOpt.TYPE_UP_AWAKEN = 3
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaUpOpt:UISagaUpOpt()
	self._effectKey = "paly"

	---@type CommonIcon
	self._iconHeroCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaUpOpt:OnWndClose()
    self:OnShiftAwakenSkill()
	if self._iconHeroCls then
		self._iconHeroCls:Destroy()
		self._iconHeroCls = nil
	end
	self:TweenSeqKill(self._effectKey)
	self._awakenSkillTransList = nil
    self._awakenSkillSelectIconList = nil
	LWnd.OnWndClose(self)
	gLGameAudio:StopSound()
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaUpOpt:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaUpOpt:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:SetWndText(self.mBlankTxt,ccClientText(10103))
	if not self._heroData then return end
	self:PlayEffect()
end

function UISagaUpOpt:InitHeroSkillData()
	local heroData = self._heroData
	if not heroData then return end
	local refId = heroData.refId
	local grade = heroData.grade
	local star = heroData.star
	--local form = heroData.form
	--local heroRef = gModelHero:GetHeroRef(refId)
	local skillIdList = gModelHero:GetSkillIdListById(self._id)
	self._skillTrans = {}
	if self._optType == 2 then
		if not table.isempty(skillIdList) then
			local index = 1
			local openIndex = 1
			for i,v in ipairs(skillIdList) do
				local openClass = v.openClass
				if grade == openClass then
					local trans = CS.FindTrans(self.mHeroSkillList,"Skill"..openIndex)
					if trans then
						local skillIconTrans = CS.FindTrans(trans,"SkillIcon")
						if skillIconTrans then
							local skillId = v.skillId
							local baseClass = SkillIcon:New(self)
							local tempShowUp = false
							baseClass:SetSkillInfo(grade,tempShowUp,v.openClass,1)
							baseClass:Create(skillIconTrans,skillId,function()
--[[								local hero = {
									refId = refId,
									star = star,
									grade = grade,
								}
								GF.OpenWnd("UIJNInfo",{skillId = skillId,needGrade = openClass,index = i,heroData = hero})]]

								gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = i,heroData = heroData})

							end)
							table.insert(self._skillTrans,skillIconTrans)
						end
						CS.ShowObject(trans,true)
						--self:CreateEffect(trans,"fx_ui_shengxing_4","skill"..i)
						index = index + 1
						openIndex = openIndex + 1
					end
				end
			end
			if index == 1 then
				self:ShowUnLockSkillTxt()
			end
		else
			self:ShowUnLockSkillTxt()
		end
	else
		if not table.isempty(skillIdList) then
			local oldStar = star - 1
			local oldStarRef = gModelHero:GetStarRefById(self._id,oldStar)
			if not oldStarRef then
				oldStarRef = gModelHero:GetStarRefById(self._id)
				if LOG_INFO_ENABLED then
					LogError(string.format("星级数据配置缺失  refId %s ,star %s",refId,oldStar))
				end
			end
			local skillGroup = oldStarRef.skillGroup
			local nextSkillList = string.split(skillGroup,",")
			for i,v in ipairs(skillIdList) do
				local trans = CS.FindTrans(self.mHeroSkillList,"Skill"..i)
				if trans then
					local skillIconTrans = CS.FindTrans(trans,"SkillIcon")
					if skillIconTrans then
						local skillId = v.skillId
						local openClass = v.openClass
						local baseClass = SkillIcon:New(self)
						local tempShowUp = false
						local tempData = string.split(nextSkillList[i],"=")
						local afterSkillId = tonumber(tempData[1])
						if afterSkillId < skillId then
							tempShowUp = true
						end
						baseClass:SetSkillInfo(grade,tempShowUp,openClass,1)
						baseClass:Create(skillIconTrans,skillId,function()
--[[							local hero = {
								refId = refId,
								star = star,
								grade = grade,
							}
							GF.OpenWnd("UIJNInfo",{skillId = skillId,needGrade = openClass,index = i,heroData = hero})]]

							gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = i,heroData = heroData})
						end)
						table.insert(self._skillTrans,skillIconTrans)
					end
					CS.ShowObject(trans,true)
					--self:CreateEffect(trans,"fx_ui_shengxing_4","skill"..i)
				end
			end
		else
			self:ShowUnLockSkillTxt()
		end
	end

	CS.ShowObject(self.mHeroSkillList, true)
	CS.ShowObject(self.mHeroAwakenSkillList, false)
end
function UISagaUpOpt:InitData()
	self._optType = self:GetWndArg("optType") or UISagaUpOpt.TYPE_UP_STAR
	--self._optType = 2
	self._id = self:GetWndArg("id")
	if not self._id then return end
	self._hero = gModelHero:GetHeroById(self._id)
	if not self._hero then
		print("----- 沒有找到该英雄")
		return
	end

	self._awakenTreePointId = self:GetWndArg("awakenTreePointId")

	self._heroData = self._hero:GetServerData()
	self._uicommonList = {}

	if self._optType == UISagaUpOpt.TYPE_UP_STAR then
		self._starTransList = {self.mStarBg1,self.mLvBg1,self.mUpAtkBg1,self.mUpHpBg1}
		--A开发需求 #1553
		self:SetWndEasyImage(self.mTitle,"draconic_txt_2",function()
			--self:CreateTitleEffect()
			CS.ShowObject(self.mUpStar,true)
			self:InitStarData()
		end, true)
		self:InitHeroSkillData()
	elseif self._optType == UISagaUpOpt.TYPE_UP_LVL then
		self._starTransList = {self.mAtkBg2,self.mMaxHpBg2,self.mDefBg2,self.mSpeedBg2}
		-- #1562
		self:SetWndEasyImage(self.mTitle,"rune_txt_6",function()
			--self:CreateTitleEffect()
			CS.ShowObject(self.mUpClass,true)
			self:InitClassData()
		end, true)
		self:InitHeroSkillData()
	elseif self._optType == UISagaUpOpt.TYPE_UP_AWAKEN then
		self:SetWndEasyImage(self.mTitle,"heroup_txt_2",function()
			--self:CreateTitleEffect()
			CS.ShowObject(self.mUpAwaken,true)
		end, true)
        self._awakenSkillTransList = {}
        self._awakenSkillSelectIconList = {}
		self:InitAwakenData()
		self:InitAwakenHeroSkillList()
	end
end

function UISagaUpOpt:InitAwakenHeroSkillList()
	if not self._treePointLvRefId then return end

	local ref = gModelHero:GetHeroTreePointLvRef(self._treePointLvRefId)
	local skill = ref.skill
	local skillIdList = string.split(skill, '|')
    for i,v in ipairs(skillIdList) do
        local trans = CS.FindTrans(self.mHeroAwakenSkillList,"Skill"..i)
        if trans then
            self:OnDrawAwakenSkill(trans, v, i)
            CS.ShowObject(trans,true)
        end
    end

	CS.ShowObject(self.mHeroSkillList, false)
	CS.ShowObject(self.mHeroAwakenSkillList, true)
end

function UISagaUpOpt:InitStarData()
	self:SetXUITextText(self.mLvTxt,ccClientText(10023))
	self:SetXUITextText(self.mUpAtkTxt,ccClientText(10026))
	self:SetXUITextText(self.mUpHpTxt,ccClientText(10027))
	local heroData = self._heroData
	if not heroData then return end
	local refId = heroData.refId
	local star = heroData.star
	local form = heroData.form
	local oldStar = star - 1


	local oldStarRef = gModelHero:GetHeroStarRef(refId,form,oldStar)
	local starRef = gModelHero:GetHeroStarRef(refId,form,star)
	if not oldStarRef then
		print("----- 上个星级的数据不存在")
		return
	end
	if not starRef then
		print("----- 当前星级的数据不存在")
		return
	end

	local oldStarImg,old_star = gModelHero:GetHeroStarImg(oldStar)
	local starImg,cur_star = gModelHero:GetHeroStarImg(star)

	--local starTransList = {self.mStarBg1,self.mLvBg1,self.mUpAtkBg1,self.mUpHpBg1}
	-- 星级显示
	for i = 1,5 do
		local starOldImgTrans = CS.FindTrans(self.mCurStarList,"Star"..i)
		if starOldImgTrans then
			if old_star >= i then
				CS.ShowObject(starOldImgTrans,true)
				self:SetWndEasyImage(starOldImgTrans,oldStarImg)
			else
				CS.ShowObject(starOldImgTrans,false)
			end
		end
		local starImgTrans = CS.FindTrans(self.mNewStarList,"Star"..i)
		if starImgTrans then
			if cur_star >= i then
				CS.ShowObject(starImgTrans,true)
				self:SetWndEasyImage(starImgTrans,starImg)
			else
				CS.ShowObject(starImgTrans,false)
			end
		end
	end
	--self:CreateEffect(starTransList[1],"fx_ui_shengxing_3","starList")
	--这里判断下 显示哪个
	if oldStar > 10 then
		CS.ShowObject(self.mCurStarList, false)
		CS.ShowObject(self.mHightStarNewHeroInfo_Cur, true)
		self:SetWndText(self.mHightStarNewHeroInforText_Cur,oldStar-10)
	else
		CS.ShowObject(self.mCurStarList, true)
		CS.ShowObject(self.mHightStarNewHeroInfo_Cur, false)
	end

	if star > 10 then
		CS.ShowObject(self.mNewStarList, false)
		CS.ShowObject(self.mHightStarNewHeroInfo_Next, true)
		self:SetWndText(self.mHightStarNewHeroInforText_Next,star-10)
	else
		CS.ShowObject(self.mNewStarList, true)
		CS.ShowObject(self.mHightStarNewHeroInfo_Next, false)
	end

	-- 等级上限
	local oldMaxLv = oldStarRef.maxLevel
	local maxLv = starRef.maxLevel
	self:SetXUITextText(self.mCurLvTxt,oldMaxLv)
	self:SetXUITextText(self.mNewLvTxt,maxLv)
	--self:CreateEffect(starTransList[2],"fx_ui_shengxing_3","lv")

	--攻击成长提升
	local oldAtkVal = oldStarRef.atkVal
	local atkVal = starRef.atkVal
	local upAtkVal = (atkVal - oldAtkVal) * 100
	local str = upAtkVal .. "%"
	self:SetXUITextText(self.mNewUpAtkTxt,str)
	--self:CreateEffect(starTransList[3],"fx_ui_shengxing_3","atk")

	--攻击成长提升
	local oldHpVal = oldStarRef.maxhpVal
	local hpVal = starRef.maxhpVal
	local upHpVal = (hpVal - oldHpVal) * 100
	str = upHpVal .. "%"
	self:SetXUITextText(self.mNewUpHpTxt,str)
	--self:CreateEffect(starTransList[4],"fx_ui_shengxing_3","hp")
end

function UISagaUpOpt:InitAwakenData()
	if not (self._id and self._awakenTreePointId) then return end

	local treeInfo = gModelHero:GetServerHeroTreePointInfo(self._id, self._awakenTreePointId)
	if not treeInfo then return end

	local skillId = treeInfo.skillId
	self._curSelectAwakenSkillId = skillId
	self._treePointLvRefId = treeInfo.lvRefId
    self._firstSelectAwakenSkillId = skillId

	local skillRef = gModelHero:GetSkillByStarId(skillId)
	if not skillRef then return end
	local nameText = ccLngText(skillRef.name)
	local str = string.replace(ccClientText(20156), nameText)
	self:SetXUITextText(self.mAwakenTxt, str)
end

function UISagaUpOpt:SetOptType(optType)
	self._optType = optType
end

function UISagaUpOpt:InitHero()
	local heroTrans = CS.FindTrans(self.mHero,"HeroIcon")
	if heroTrans then
		local baseClass = self._iconHeroCls
		if not baseClass then
			baseClass = CommonIcon:New()
			self._iconHeroCls = baseClass
			baseClass:Create(heroTrans)
		end
		baseClass:SetHeroPlayer(self._id)
		baseClass:DoApply()

		CS.ShowObject(self.mHero,true)
		self:CreateEffect(heroTrans,"fx_ui_shengxing_2")
	end
end

function UISagaUpOpt:PlayEffect()
	local seqTween
	self:TweenSeqKill(self._effectKey)
	if not seqTween then
        local optType = self._optType
		seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
			local showTopTime = 0.2
			local showAttrTime = 0.1
			seq:AppendCallback(function ()
				self:CreateTitleEffect()
			end)
			seq:AppendInterval(showTopTime)

			seq:AppendCallback(function ()
				self:OnPlayUpStarSound()
--[[				if self._optType == 2 then
				end]]
                if optType == UISagaUpOpt.TYPE_UP_STAR or optType == UISagaUpOpt.TYPE_UP_LVL then
                    self:InitHero()
                end
			end)
			seq:AppendInterval(showTopTime)

            if self._starTransList then
                for i,v in ipairs(self._starTransList) do
                    seq:AppendCallback(function ()
                        self:CreateEffect(v,"fx_ui_shengxing_3","eff"..i)
                        CS.ShowObject(v,true)
                    end)
                    seq:AppendInterval(showAttrTime)
                end
            end

            if self._skillTrans then
                for i,v in ipairs(self._skillTrans) do
                    seq:AppendCallback(function ()
                        self:CreateEffect(v,"fx_ui_shengxing_4","skill"..i,180)
                        CS.ShowObject(v,true)
                    end)
                    seq:AppendInterval(showAttrTime)
                end
            end

            if self._awakenSkillTransList then
                for i,v in ipairs(self._awakenSkillTransList) do
                    seq:AppendCallback(function ()
                        local trans = v.skillIconTrans
                        self:CreateEffect(trans,"fx_ui_shengxing_4","awakenSkill"..i,180)
                        CS.ShowObject(trans,true)
                        CS.ShowObject(v.selectBg,true)
                    end)
                    seq:AppendInterval(showAttrTime)
                end
            end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._effectKey)
	end)

end

function UISagaUpOpt:CreateTitleEffect()
	CS.ShowObject(self.mTitle,true)
	self:CreateEffect(self.mShengxingTitle,"fx_ui_shengxing_1")
end

function UISagaUpOpt:OnShiftAwakenSkill()
    if self._optType ~= UISagaUpOpt.TYPE_UP_AWAKEN then return end
    if self._firstSelectAwakenSkillId == self._curSelectAwakenSkillId then
        return
    end

    local heroId = self._id
    local pointRefId = self._awakenTreePointId
    local skillId = self._curSelectAwakenSkillId
    gModelHero:OnHeroTreePointSelectSkillReq(heroId,pointRefId, skillId)
end

function UISagaUpOpt:InitEvent()
	self:SetWndClick(self.mBg,function()
		--这里判断是否需要展示新的皮肤
		if self._optType == UISagaUpOpt.TYPE_UP_STAR then
			local heroData = self._heroData
			local refId = heroData.refId
			local star = heroData.star
			local oldStar = star - 1

			local oldRefId,newRefId=ModelHero:GetUpStarPolymorphism(refId, oldStar, star)

			if newRefId>0 then
				GF.OpenWnd("UISagaBaoYiDisPy",{oldRefId = oldRefId,newRefId = newRefId})
			end
		end


		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaUpOpt:OnClickAwakenSkill(skillId)
	local skillData = gModelHero:GetSkillByStarId(skillId)
	if not skillData then return end

	local lv = skillData.level
	local other = {lv = lv}
	GF.OpenWndTop("UIJNInfo",{skillId = skillId,other = other})
end

function UISagaUpOpt:OnDrawAwakenSkill(item,itemdata,itempos)
	local skillId = tonumber(itemdata)

	local skillParantTrans =self:FindWndTrans(item, "Skill")
	local skillIconTrans = CS.FindTrans(item,"Skill/SkillIcon")
	if skillIconTrans then
		local baseClass = SkillIcon:New(self)
		baseClass:SetSkillInfo(nil,false,nil,1)
		baseClass:ShowLvl(false)
		baseClass:ShowLock(false)
		baseClass:Create(skillIconTrans,skillId,function()
			self:OnClickAwakenSkill(skillId)
		end)
		baseClass:SetIconAndIconBgGray(false)
	end

	local isSelect = self._curSelectAwakenSkillId == skillId
	local selectBg   = self:FindWndTrans(item, "SelectBg")
	local selectIcon = self:FindWndTrans(selectBg, "SelectIcon")
	self._awakenSkillSelectIconList[skillId] = selectIcon
    self._awakenSkillTransList[itempos] = {
        skillIconTrans = skillIconTrans,
        selectBg = selectBg,
    }

	CS.ShowObject(selectIcon, isSelect)
	self:SetWndClick(selectBg, function()
		self:OnClickSkillSelect(skillId)
	end)
end

function UISagaUpOpt:OnClickSkillSelect(skillId)
	if self._curSelectAwakenSkillId == skillId then
		return
	end

	self._curSelectAwakenSkillId = skillId
	for k,v in pairs(self._awakenSkillSelectIconList) do
		CS.ShowObject(v, k == skillId)
	end
end
function UISagaUpOpt:OnPlayUpStarSound()
    local favorRef = gModelHero:GetHeroSpActionSoundRef().heroStarUpSound
	local effRefId = self._hero._skin>0 and self._hero._skin or (self._hero._refId)
	local loveLevel = gModelHero:GetHeroLoveLvByRefId(self._hero._refId) or 0
    if loveLevel >= favorRef.refId then
        local sound = GameTable.CharacterEffectRef[effRefId][favorRef.SpActionSound]
        if sound and sound~="" then  gLGameAudio:PlaySound(sound) end
	else
		LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_UPGRADE_COMMON)
    end
end

function UISagaUpOpt:ShowUnLockSkillTxt()
	CS.ShowObject(self.mUnLockSkillTxt,true)
	self:SetWndText(self.mUnLockSkillTxt,ccClientText(10037))
end

function UISagaUpOpt:InitClassData()
	local heroData = self._heroData
	if not heroData then return end
	--local refId,grade,star,lv = heroData.refId,heroData.grade,heroData.star,heroData.lv
	local grade = heroData.grade
	local oldGrade = grade - 1
	--local heroRef = gModelHero:GetHeroRef(refId)
	--local classType = heroRef.classType
	--local classOldId = gModelHero:ConvertToHesroGradeId(classType,oldGrade)
	--local classId = gModelHero:ConvertToHeroGradeId(classType,grade)

	--local buffList = gModelHero:GetSkillBuff(refId,star)
	local oldAtk,oldMaxHp,oldDef,oldSpeed = gModelHero:GetBaseAttrInfoById(self._id,oldGrade)
	--if oldGrade == 0 then
	--	oldAtk,oldMaxHp,oldDef,oldSpeed = gModelHero:GetBaseAttrInfo(refId,lv,starId,classOldId)
	--else
	--	oldAtk,oldMaxHp,oldDef,oldSpeed = gModelHero:GetBaseAttrInfo(refId,lv,starId,classOldId,buffList)
	--end
	local Atk,maxHp,Def,Speed = gModelHero:GetBaseAttrInfoById(self._id)

	oldAtk = math.floor(oldAtk + 0.5)
	Atk = math.floor(Atk + 0.5)

	oldMaxHp = math.floor(oldMaxHp + 0.5)
	maxHp = math.floor(maxHp + 0.5)

	oldDef = math.floor(oldDef + 0.5)
	Def = math.floor(Def + 0.5)

	oldSpeed = math.floor(oldSpeed + 0.5)
	Speed = math.floor(Speed + 0.5)

    --
	--local starTransList = {self.mAtkBg2,self.mMaxHpBg2,self.mDefBg2,self.mSpeedBg2}
	-- 攻击提升
	local name = gModelHero:GetAttributeNameById(1)
	if name then self:SetXUITextText(self.mClassAtkTxt,name) end

	self:SetXUITextText(self.mCurAtkTxt,oldAtk)
	self:SetXUITextText(self.mNewAtkTxt,Atk)
	--self:CreateEffect(starTransList[1],"fx_ui_shengxing_3","atk")

	-- 生命提升
	name = gModelHero:GetAttributeNameById(3)
	if name then self:SetXUITextText(self.mClassHpTxt,name) end

	self:SetXUITextText(self.mCurHpTxt,oldMaxHp)
	self:SetXUITextText(self.mNewHpTxt,maxHp)
	--self:CreateEffect(starTransList[2],"fx_ui_shengxing_3","maxHp")

	-- 防御提升
	name = gModelHero:GetAttributeNameById(4)
	if name then self:SetXUITextText(self.mClassDefTxt,name) end

	self:SetXUITextText(self.mCurDefTxt,oldDef)
	self:SetXUITextText(self.mNewDefTxt,Def)
	--self:CreateEffect(starTransList[3],"fx_ui_shengxing_3","def")

	-- 速度提升
	name = gModelHero:GetAttributeNameById(5)
	if name then self:SetXUITextText(self.mClassSpeedTxt,name) end

	self:SetXUITextText(self.mCurSpeedTxt,oldSpeed)
	self:SetXUITextText(self.mNewSpeedTxt,Speed)
	--self:CreateEffect(starTransList[4],"fx_ui_shengxing_3","speed")
end

function UISagaUpOpt:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or effectName
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end

function UISagaUpOpt:SetHeroId(id)
	self._id = id
end
------------------------------------------------------------------
return UISagaUpOpt


