---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaAttr:LWnd
local UISagaAttr = LxWndClass("UISagaAttr", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaAttr:UISagaAttr()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaAttr:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaAttr:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaAttr:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mMinBaseTxt,ccClientText(10068))
	self:SetWndText(self.mMinSpcialTxt,ccClientText(10069))
	self:SetWndText(self.mMinAddTxt,ccClientText(10070))
	self:SetWndText(self.mMaxBaseTxt,ccClientText(10068))
	self:SetWndText(self.mMaxSpcialTxt,ccClientText(10069))
	self:SetWndText(self.mMaxAddTxt,ccClientText(10070))
	self:InitDada()
	self:InitEvent()
	self:RefreshData()
end

function UISagaAttr:RefreshData()
	local viewTrans1 = self._viewTrans1
	local viewData1 = self._viewData1
	for i = 1,#viewTrans1 do
		local trans = viewTrans1[i]
		local refId = viewData1[i]
		self:ChangeTrans(trans,refId)
	end

	local viewTrans2 = self._viewTrans2
	local viewData2 = self._viewData2
	for i = 1,#viewTrans2 do
		local trans = viewTrans2[i]
		local refId = viewData2[i]
		self:ChangeTrans(trans,refId)
	end

--[[	local shenqiLv = string.replace(ccClientText(10067),gModelDream:GetArtifactLv())
	local shenqiStr = ccClientText(15231)
	self:ChangeTrans(self.mAttr9,0,shenqiStr,shenqiLv)
	self:ChangeTrans(self.mAttrMax20,0,shenqiStr,shenqiLv)]]

	self:AddAttrList(1)
end

function UISagaAttr:OnDrawAddCell(list, item, itemdata, itempos, fromHeadTail)
	local attributeId = itemdata.attributeId
	local AttrTxtTrans = self:FindWndTrans(item,"AttrTxt")
	if AttrTxtTrans then
		local name = ""
		if attributeId == -1 then
			attributeId = 0
		else
--[[			local ref = gModelGuild:GetGuildSkillAttrRefByRefId(attributeId)
			if ref then
				attributeId = ref.level
				local Job = ref.Job
				local careerRef = gModelHero:GetCareerRefByRefId(Job)
				if careerRef then name = ccLngText(careerRef.name) end
			end]]
			local Job = itemdata.type
			local careerRef = gModelHero:GetCareerRefByRefId(Job)
			if careerRef then name = ccLngText(careerRef.name) end
		end
		local str = string.replace(ccClientText(10071),name)
		self:SetWndText(AttrTxtTrans,str)
	end
	local AttrValueTrans = self:FindWndTrans(item,"AttrValue")
	if AttrValueTrans then
		self:SetWndText(AttrValueTrans,attributeId)
	end
end

function UISagaAttr:BtnEvent(index)
	self._page = index
	local isShow = false
	if index == 2 then
		isShow = true
	end
	CS.ShowObject(self.mMinAttrView,isShow)
	CS.ShowObject(self.mMaxAttrView,not isShow)

	CS.ShowObject(self.mPullBtn,isShow)
	CS.ShowObject(self.mPackUpBtn,not isShow)

	self:AddAttrList(index)
end

function UISagaAttr:InitDada()
	self._id = self:GetWndArg("id")
	self._career = self:GetWndArg("career")
	self._data = gModelHero:GetHeroAttrAndEquipInfoById(self._id)
	self._page = 1 					-- 当前页数
	self._list = {}
	self._viewTrans1 = {
		self.mAttr1,
		self.mAttr2,
		self.mAttr3,
		self.mAttr4,
		self.mAttr5,
		self.mAttr6,
		self.mAttr7,
		self.mAttr8,
		self.mAttr9,
		self.mAttr10,
		self.mAttr11,
		self.mAttr12,
	} 								-- 第一页刷新的数量
	self._viewData1 = {
		1,3,4,5,
		103,104,101,102
	}
	self._viewTrans2 = {
		self.mAttrMax1,
		self.mAttrMax2,
		self.mAttrMax3,
		self.mAttrMax4,
		self.mAttrMax5,
		self.mAttrMax6,
		self.mAttrMax7,
		self.mAttrMax8,
		self.mAttrMax9,
		self.mAttrMax10,
		self.mAttrMax11,
		self.mAttrMax12,
		self.mAttrMax13,
		self.mAttrMax14,
		self.mAttrMax15,
		self.mAttrMax16,
		self.mAttrMax17,
		self.mAttrMax18,
		self.mAttrMax19,
--[[		self.mAttrMax20,
		self.mAttrMax21,
		self.mAttrMax22,
		self.mAttrMax23,]]
	} 								-- 第二页刷新的数量
	self._viewData2 = {
		1,3,4,5,
		103,104,101,102,
		105,106,206,207,
		208,209,203,205,
		201,202,204
	}
	self._viewShow = {[1] = false,[2] = false}
end

function UISagaAttr:ChangeTrans(trans,refId,txtName,value)
	if trans and refId then
		local iconTrans = CS.FindTrans(trans,"icon")
		if iconTrans then
			local iconImg = gModelHero:GetAttributeIconById(refId)
			if iconImg then self:SetWndEasyImage(iconTrans,iconImg) end
		end
		local txtTrans = CS.FindTrans(trans,"AttrTxt")
		if txtTrans then
			txtName = txtName or gModelHero:GetAttributeNameById(refId)
			if txtName then self:SetWndText(txtTrans,txtName) end
		end
		local valTrans = CS.FindTrans(trans,"AttrValue")
		if valTrans then
			local data = self._data[refId]
			if not data then data = 0 end
			local ref = gModelHero:GetAttributeRefById(refId)
			local numType,saveNum
			if ref then
				numType,saveNum = ref.numType,ref.saveNum
			else
				numType,saveNum = 1,0
			end
			if saveNum == 0 then
				data = math.floor(data + 0.5)
			else
				local tempPow = 10^saveNum
				local temp = math.floor(data*tempPow + 0.5)
				data = temp/tempPow
			end
			if numType == 2 then
				data = data*100 .. "%"
			end
			if value then data = value end
			self:SetWndText(valTrans,data)
		end
	end
end

function UISagaAttr:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mPullBtn,function()
		self:BtnEvent(1)
	end)
	self:SetWndClick(self.mPackUpBtn,function()
		self:BtnEvent(2)
	end)
end

function UISagaAttr:AddAttrList(index)
	if self._list[index] then return end
	local heroAttr,heroEquip,heroRune,heroTalent,heroOutfitList,guildSkillList = gModelHero:GetHeroAttrAndEquipInfoById(self._id)
	local addList = {}
	local haveGuild = guildSkillList
	local len = table.keysize(haveGuild)
	if len > 0 then
		if self._career then
			local ctype = self._career
			local attributeId = guildSkillList[ctype] or 0
			local data = {type = ctype , attributeId = attributeId}
			table.insert(addList,data)
		else
			for k,v in pairs(haveGuild) do
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
	local list
	if index == 1 and (not self._list[index]) then
		list = UIListEasy:New()
		list:Create(self,self.mMaxAddList)
		list:SetFuncOnItemDraw(function(...)
			self:OnDrawAddCell(...)
		end)
	elseif index == 2 and (not self._list[index]) then
		list = UIListEasy:New()
		list:Create(self,self.mMinAddList)
		list:SetFuncOnItemDraw(function(...)
			self:OnDrawAddCell(...)
		end)
	end
	if list then
		for i,v in ipairs(addList) do
			list:AddData(i,v)
		end
		list:RefreshList()
		self._list[index] = list
	end
end
------------------------------------------------------------------
return UISagaAttr


