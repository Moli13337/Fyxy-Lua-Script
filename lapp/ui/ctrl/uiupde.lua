---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUpde:LWnd
local UIUpde = LxWndClass("UIUpde", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUpde:UIUpde()
	---@type table<number, CommonIcon>
	self._itemIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUpde:OnWndClose()
	self:ClearCommonIconList(self._itemIconList)
	self._itemIconList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUpde:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUpde:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:InitClassData()
	self:InitSkillList()
	self:InitItemList()

	self:SetXUITextText(self.mTitle,ccClientText(10032))
	self:SetXUITextText(self.mCancelBtnTxt,ccClientText(10101))
	self:SetXUITextText(self.mEnterBtnTxt,ccClientText(10032))
	self:SetXUITextText(self.mSecTxt,ccClientText(10033))
	self:SetXUITextText(self.mThreeTxt,ccClientText(10034))
	if self._unlockSkill then
		CS.ShowObject(self.mUnLockSkillTxt,true)
		self:SetWndText(self.mUnLockSkillTxt,ccClientText(10037))
	end
end

function UIUpde:InitData()
	self._id = self:GetWndArg("id")
	self._func = self:GetWndArg("func")
	-- self._id = "9002502000000059010"
	if not self._id then
		return
	end
	self._hero = gModelHero:GetHeroById(self._id)
	if not self._hero then
		print("----- 沒有找到该英雄")
		return
	end
	self._heroData = self._hero:GetServerData()
	self._skillIconList = {}

	self._skillTransList = {
		self.mSkill1,
		self.mSkill2,
		self.mSkill3,
		self.mSkill4,
	}
	self._itemTransList = {
		self.mItem1,
		self.mItem2,
		self.mItem3,
		self.mItem4,
	}
	self._unlockSkill = false
end

function UIUpde:InitSkillList()
	local heroData = self._heroData
	local grade = heroData.grade + 1
	local refId = heroData.refId
	local heroRef = gModelHero:GetHeroRef(refId)
	local classType
	if heroRef then
		classType = heroRef.classType
	end
	local skillIdList = gModelHero:GetSkillIdListById(self._id)
	if not table.isempty(skillIdList) then
		local index = 1
		local skillTransList = self._skillTransList
		for i,v in ipairs(skillIdList) do
			local openClass = v.openClass
			if grade == openClass then
				local trans = skillTransList[index]
				if trans then
					local skillIconTrans = CS.FindTrans(trans,"SkillIcon")
					if skillIconTrans then
						local skillId = v.skillId
						local baseClass = SkillIcon:New(self)
						local tempShowUp = false
						baseClass:SetSkillInfo(grade,tempShowUp,v.openClass,1)
						baseClass:Create(skillIconTrans,skillId,function()
--[[							local hero = {
								refId = refId,
								star = heroData.star,
								grade = grade,
							}
							GF.OpenWnd("UIJNInfo",{skillId = skillId,needGrade = openClass,index = i,heroData = hero})]]
							gModelGeneral:OpenHeroSkillWnd({curSkillId = skillId,curSkillIdx = i,heroData = heroData})
						end)
					end
					CS.ShowObject(trans,true)
					index = index + 1
				end
			end
		end
		self._unlockSkill = index == 1
	end
end

function UIUpde:InitEvent()
	--self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function()
		if self._func then self._func() end
		gModelHero:OnHeroUpGradeReq(self._id)
	end)
end

function UIUpde:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroUpGradeResp,function()
		GF.ShowMessage(ccClientText(10020))
		local tab = {optType = 2,id = self._id,}
		GF.OpenWnd("UISagaUpOpt",tab)
		self:WndClose()
	end)
end

function UIUpde:InitItemList()
	if not self._needItemList then return end
	local needItemList = self._needItemList
	if not string.isempty(needItemList) then
		local itemIconList = self._itemIconList
		local itemTransList = self._itemTransList
		local list = string.split(needItemList,",")
		for i = 1,#list do
			local trans = itemTransList[i]
			CS.ShowObject(trans,true)
			local data = string.split(list[i],"=")
			local itype,refId,num = tonumber(data[1]),tonumber(data[2]),tonumber(data[3])

			local iconTrans = CS.FindTrans(trans, "CommonUI/Icon")
			local baseClass = itemIconList[i]
			if not baseClass then
				baseClass = CommonIcon:New()
				itemIconList[i] = baseClass
				baseClass:Create(iconTrans)
			end
			baseClass:SetCommonReward(itype,refId, num)

			if itype == 1 then
				baseClass:EnableShowNum(true)
				self:SetIconClickScale(iconTrans, true)
			else
				self:SetIconClickScale(iconTrans, false)
				baseClass:EnableShowNum(false)
			end
			baseClass:DoApply()

			self:SetWndClick(iconTrans, function()
				if itype == 1 then
					gModelGeneral:OpenGetWayWnd({itemId = refId})
				end
			end)
		end
	end
end

--[[function UIUpde:InitClassData()
	local heroData = self._heroData
	local refId = heroData.refId
	local grade = heroData.grade + 1
	local oldGrade = grade - 1
	local heroRef = gModelHero:GetHeroRef(refId)
	local classType = heroRef.classType
	local classOldId = classType * 10 + oldGrade
	local classId = classType * 10 + grade
	local classOldRef = gModelHero:GetHeroClassById(classOldId)
	local classRef = gModelHero:GetHeroClassById(classId)

	if not classOldRef then
		print("----- 上个阶级的数据不存在")
		return
	end
	if not classRef then
		print("----- 当前阶级的数据不存在")
		return
	end
	self._needItemList = classOldRef.needItem
	-- 攻击提升
	local name = gModelHero:GetAttributeNameById(1)
	if name then
		self:SetXUITextText(self.mClassAtkTxt,name)
	end

	local id = self._id
	local heroAttrList = gModelHero:GetHeroAttrAndEquipInfoById(id)
	if not heroAttrList then heroAttrList = {} end

	local atkVal = heroAttrList[LAttrConst.Atk] or 0
	local old = atkVal + classOldRef.atkEx
	local cur = atkVal + classRef.atkEx
	old = math.floor(old + 0.5)
	cur = math.floor(cur + 0.5)
	self:SetXUITextText(self.mCurAtkTxt,old)
	self:SetXUITextText(self.mNewAtkTxt,cur)

	-- 生命提升
	name = gModelHero:GetAttributeNameById(3)
	if name then
		self:SetXUITextText(self.mClassHpTxt,name)
	end
	local maxHpVal = heroAttrList[LAttrConst.MaxHP] or 0
	old = maxHpVal + classOldRef.maxhpEx
	cur = maxHpVal + classRef.maxhpEx
	old = math.floor(old + 0.5)
	cur = math.floor(cur + 0.5)
	self:SetXUITextText(self.mCurHpTxt,old)
	self:SetXUITextText(self.mNewHpTxt,cur)

	-- 防御提升
	name = gModelHero:GetAttributeNameById(4)
	if name then
		self:SetXUITextText(self.mClassDefTxt,name)
	end
	local DefVal = heroAttrList[LAttrConst.Def] or 0
	old = DefVal + classOldRef.defEx
	cur = DefVal + classRef.defEx
	old = math.floor(old + 0.5)
	cur = math.floor(cur + 0.5)
	self:SetXUITextText(self.mCurDefTxt,old)
	self:SetXUITextText(self.mNewDefTxt,cur)

	-- 速度提升
	name = gModelHero:GetAttributeNameById(5)
	if name then
		self:SetXUITextText(self.mClassSpeedTxt,name)
	end
	local speedVal = heroAttrList[LAttrConst.Speed] or 0
	old = speedVal + classOldRef.speedEx
	cur = speedVal + classRef.speedEx
	old = math.floor(old + 0.5)
	cur = math.floor(cur + 0.5)
	self:SetXUITextText(self.mCurSpeedTxt,old)
	self:SetXUITextText(self.mNewSpeedTxt,cur)
end]]

function UIUpde:InitClassData()
	local heroData = self._heroData
	local refId = heroData.refId
	--local star = heroData.star
	--local lv = heroData.lv
	local curGrade = heroData.grade
	local nextGrade = curGrade + 1
	local heroRef = gModelHero:GetHeroRef(refId)
	local classType = heroRef.classType
	--local starId = gModelHero:GetStarId(starType,star)

	local curClassId = classType * 10 + curGrade
	--local classId = classType * 10 + grade

	local curGradeRef = gModelHero:GetHeroClassById(curClassId)
	self._needItemList = curGradeRef.needItem

	--local buffList = gModelHero:GetSkillBuff(refId,star)
	local oldAtk,oldMaxHp,oldDef,oldSpeed = gModelHero:GetBaseAttrInfoById(self._id)
	--if oldGrade == 0 then
	--	oldAtk,oldMaxHp,oldDef,oldSpeed = gModelHero:GetBaseAttrInfo(refId,lv,starId,classOldId)
	--else
	--	oldAtk,oldMaxHp,oldDef,oldSpeed = gModelHero:GetBaseAttrInfo(refId,lv,starId,classOldId,buffList)
	--end
	local atk,maxHp,def,speed = gModelHero:GetBaseAttrInfoById(self._id, nextGrade)

	local oldAttrList = {oldAtk,oldMaxHp,oldDef,oldSpeed}
	local attrList = {atk,maxHp,def,speed}
	local baseAttr = {
		LAttrConst.Atk,
		LAttrConst.MaxHP,
		LAttrConst.Def,
		LAttrConst.Speed,
	}
	local nameTransList = {
		self.mClassAtkTxt,
		self.mClassHpTxt,
		self.mClassDefTxt,
		self.mClassSpeedTxt,
	}
	local oldTransList = {
		self.mCurAtkTxt,
		self.mCurHpTxt,
		self.mCurDefTxt,
		self.mCurSpeedTxt,
	}
	local newTransList = {
		self.mNewAtkTxt,
		self.mNewHpTxt,
		self.mNewDefTxt,
		self.mNewSpeedTxt,
	}
	for i,v in ipairs(baseAttr) do
		local oldValue = oldAttrList[i]
		local newValue = attrList[i]

		local attrRef = gModelHero:GetAttributeRefById(v)
		local attrName = ccLngText(attrRef.name)
		local numType = attrRef.numType
		local saveNum = attrRef.saveNum
		if LOG_INFO_ENABLED then
			printInfoNR("打印而已，莫慌（客户端显示为四舍五入） ".. "属性名字:" .. attrName.. ",进阶前属性值:" .. oldValue.. ",进阶后属性值:" .. newValue)
		end
		if saveNum == 0 then
			oldValue = math.floor(oldValue + 0.5)
			newValue = math.floor(newValue + 0.5)
		end
		if numType == 2 then
			oldValue = (oldValue * 100) .. "%"
			newValue = (newValue * 100) .. "%"
		end
		self:SetXUITextText(nameTransList[i],attrName)

		self:SetXUITextText(oldTransList[i],oldValue)
		self:SetXUITextText(newTransList[i],newValue)
	end
end
------------------------------------------------------------------
return UIUpde


