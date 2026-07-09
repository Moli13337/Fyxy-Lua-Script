---
--- Created by Administrator.
--- DateTime: 2023/10/24 21:14:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINewSagaAttr:LWnd
local UINewSagaAttr = LxWndClass("UINewSagaAttr", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINewSagaAttr:UINewSagaAttr()
	---@type LUIHeroObject
	self._curUIHeroObj = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINewSagaAttr:OnWndClose()

	if self._curUIHeroObj and self._curUIHeroObj.Destroy then
		self._curUIHeroObj:Destroy()
	end
	self._curUIHeroObj = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINewSagaAttr:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINewSagaAttr:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitData()
	self:RefreshBtnShow()

	self:CreateSpine()

	self:RefreshView()
	self:RefreshAddAttrList()
end

function UINewSagaAttr:CreateUIAttrList(trans,list)
	local key = trans:GetInstanceID()
	local uiTransList = self:FindUIScroll(key)
	if uiTransList then
		uiTransList:RefreshList(list)
	else
		uiTransList = self:GetUIScroll(key)
		uiTransList:Create(trans,list,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UINewSagaAttr:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local refId = itemdata.refId
	local value = itemdata.value
	if value < 0 then
		value = 0
	end
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon,function()
			CS.ShowObject(AttrIcon,true)
		end)
	end
	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
		self:InitTextModeWithLanguage(AttrName)
	end
	if AttrValue then
		local ref = gModelHero:GetAttributeRefById(refId)
		local numType,saveNum
		if ref then
			numType,saveNum = ref.numType,ref.saveNum
		else
			numType,saveNum = 1,0
		end
		if saveNum == 0 then
			value = math.floor(value + 0.5)
		else
			local tempPow = 10 ^ saveNum
			local temp = math.floor(value * tempPow + 0.5)
			value = temp / tempPow
		end
		if numType == 2 then
			value = value * 100 .. "%"
		end
		self:SetWndText(AttrValue,value)
	end
end

function UINewSagaAttr:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMinArrowBtn,function() self:ShowMaxEvent(1) end)
	self:SetWndClick(self.mMaxArrowBtn,function() self:ShowMaxEvent(0) end)
end

function UINewSagaAttr:RefreshView()
	local baseList,specialList = {},{}

	local attrList = self._attrList or {}
	for i,refId in ipairs(self._baseAttrList) do
		local value = attrList[refId] or 0
		table.insert(baseList,{
			refId = refId,
			value = value,
		})
	end

	local specialDataList
	local showMax = self._maxShow == 1
	if showMax then
		specialDataList = self._specialAttrList
	else
		specialDataList = self._minSpecialAttrList
	end
	for i,refId in ipairs(specialDataList or {}) do
		local value = attrList[refId] or 0
		table.insert(specialList,{
			refId = refId,
			value = value,
		})
	end

	self:CreateUIAttrList(self.mBaseAttrList,baseList)

	local len = #specialList
	local noEmpty = len > 0
	if noEmpty then
		self:CreateUIAttrList(self.mSpecialAttrList,specialList)
	end
	CS.ShowObject(self.mCenterView,noEmpty)
end

function UINewSagaAttr:RefreshBtnShow()
	local showMax = self._maxShow == 1
	CS.ShowObject(self.mMinArrowBtn,not showMax)
	CS.ShowObject(self.mMaxArrowBtn,showMax)
end

function UINewSagaAttr:InitText()
	self:SetWndText(self.mCenterViewTitle,ccClientText(10069))
	self:SetWndText(self.mBotViewTitle,ccClientText(10070))
end

function UINewSagaAttr:OnDrawAddAttrCell(list,item,itemdata,itempos)
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local ArrowBtn = self:FindWndTrans(item,"ArrowBtn")
	local attributeId = itemdata.attributeId
	local Job = itemdata.type
	if AttrName then
		local name = ""
		if attributeId == -1 then
			attributeId = 0
		else
			local careerRef = gModelHero:GetCareerRefByRefId(Job)
			if careerRef then name = ccLngText(careerRef.name) end
		end
		local str = string.replace(ccClientText(10071),name)
		self:SetWndText(AttrName,str)
	end
	if AttrValue then
		self:SetWndText(AttrValue,attributeId)
	end
	if ArrowBtn then
		self:SetWndClick(ArrowBtn,function()
			local heroJumpGuildSkill = gModelHero:GeConfigByKey("heroJumpGuildSkill")
			if gModelFunctionOpen:CheckIsOpened(heroJumpGuildSkill,true) then
				gModelFunctionOpen:Jump(heroJumpGuildSkill)
				self:WndClose()
			end
		end)
	end
end

function UINewSagaAttr:CreateSpine()
	local heroData = self._heroData
	if not heroData then return end
	local refId,star = heroData.refId,heroData.star
	local skin = heroData.skin
	local showEffId
	if skin and skin > 0 then
		showEffId = skin
	else
		showEffId = gModelHero:GetHeroEffectByRefId(refId,star)
	end
	local effRef = gModelHero:GetShowEffectById(showEffId)
	if not effRef then return end
	local prefabName = effRef.prefabName

	local newUIHeroObj = LUIHeroObject:New(self)
	self._curUIHeroObj = newUIHeroObj
	newUIHeroObj:Create(self.mHeroPos,prefabName,prefabName)
	newUIHeroObj:SetScale(2)
	newUIHeroObj:SetHeroData(nil, refId, star, nil,true)
	newUIHeroObj:ShowHero(true)
	newUIHeroObj:StartLoad()
end

function UINewSagaAttr:RefreshAddAttrList()
	local addList = {}
	local heroAttr,heroEquip,heroRune,heroTalent,heroOutfitList,guildSkillList = gModelHero:GetHeroAttrAndEquipInfoById(self._id)
	local len = table.keysize(guildSkillList)
	if len > 0 then
		local ctype = self._career
		if ctype then
			local attributeId = guildSkillList[ctype] or 0
			table.insert(addList,{type = ctype , attributeId = attributeId})
		else
			for k,v in pairs(guildSkillList) do
				local data = {type = k , attributeId = v}
				table.insert(addList,data)
			end
			table.sort(addList,function(attr1,attr2)
				return attr1.type < attr2.type
			end)
		end
	else
		table.insert(addList,{type = 0,attributeId = -1}) 			-- 没有工会的情况
	end

	local uiAddAttrList = self._uiAddAttrList
	if uiAddAttrList then
		uiAddAttrList:RefreshList(addList)
	else
		uiAddAttrList = self:GetUIScroll("uiAddAttrList")
		self._uiAddAttrList = uiAddAttrList
		uiAddAttrList:Create(self.mAddAttrList,addList,function(...) self:OnDrawAddAttrCell(...) end)
	end
end

function UINewSagaAttr:InitData()
	self._id = self:GetWndArg("id")
	self._career = self:GetWndArg("career")
	self._heroData = self:GetWndArg("heroData")
	self._attrList = gModelHero:GetHeroAttrAndEquipInfoById(self._id)
	self._maxShow = 1

	self._baseAttrKeyList = {
		[LAttrConst.Atk] = LAttrConst.Atk,
		[LAttrConst.MaxHP] = LAttrConst.MaxHP,
		[LAttrConst.Def] = LAttrConst.Def,
		[LAttrConst.Speed] = LAttrConst.Speed,
	}
	self._baseAttrList = {
		LAttrConst.Atk,
		LAttrConst.MaxHP,
		LAttrConst.Def,
		LAttrConst.Speed,
	}
	self._minSpecialAttrList = {
		LAttrConst.Hit,LAttrConst.Dodge,LAttrConst.Crit,LAttrConst.DefCrit,
	}
	--self._specialAttrList = {
	--	LAttrConst.Hit,LAttrConst.Dodge,LAttrConst.Crit,LAttrConst.DefCrit,
	--	LAttrConst.Ctrl,LAttrConst.DefCtrl,LAttrConst.PHurt,LAttrConst.PAvoidHurt,
	--	LAttrConst.MHurt,LAttrConst.MAvoidHurt,LAttrConst.CritRatio,LAttrConst.CritRatioR,
	--	LAttrConst.Treat,LAttrConst.BeTreat,LAttrConst.AddHurt, LAttrConst.AvoidHurt,LAttrConst.Strike,
	--	LAttrConst.DefStrike,LAttrConst.BreakDef,
	--}

	self._specialAttrList = {
		LAttrConst.Hit,LAttrConst.Dodge,LAttrConst.Crit,LAttrConst.DefCrit,
		LAttrConst.Ctrl,LAttrConst.DefCtrl,LAttrConst.PHurt,LAttrConst.PAvoidHurt,
		LAttrConst.MHurt,LAttrConst.MAvoidHurt,LAttrConst.CritRatio,LAttrConst.CritRatioR,
		LAttrConst.Treat,LAttrConst.BeTreat,LAttrConst.AddHurt, LAttrConst.AvoidHurt,
	}
end

function UINewSagaAttr:ShowMaxEvent(showMax)
	if self._maxShow == showMax then return end
	self._maxShow = showMax
	self:RefreshBtnShow()
	self:RefreshView()
end
------------------------------------------------------------------
return UINewSagaAttr


