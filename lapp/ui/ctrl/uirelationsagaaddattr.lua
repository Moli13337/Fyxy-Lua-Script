---
--- Created by Administrator.
--- DateTime: 2023/10/10 18:11:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRelationSagaAddAttr:LWnd
local UIRelationSagaAddAttr = LxWndClass("UIRelationSagaAddAttr", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRelationSagaAddAttr:UIRelationSagaAddAttr()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRelationSagaAddAttr:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRelationSagaAddAttr:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRelationSagaAddAttr:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitData()
	self:RefreshAttrList()
end

function UIRelationSagaAddAttr:RefreshAttrList()
	local list = self:GetAttrList()
	local uiAttrList = self._uiAttrList
	if uiAttrList then
	else
		uiAttrList = self:GetUIScroll("uiAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mAllAddAttrList,list,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UIRelationSagaAddAttr:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIRelationSagaAddAttr:InitText()
	self:SetWndText(self.mAllAddAttrTitle,ccClientText(19747))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mDescTXT,ccClientText(19740))
end

function UIRelationSagaAddAttr:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local TargetImg = self:FindWndTrans(item,"TargetImg")
	local numType,refId,value = itemdata.numType,itemdata.refId,itemdata.value
	local target = itemdata.target
	local showTarget = target ~= nil or false
	-- if showTarget then
	-- 	local typeId = itemdata.typeId
	-- 	local img
	-- 	if target == ModelTreasure.TYPE_EFFECT_HERO then
	-- 		img = gModelHero:GetHeroOutfitIconByRefId(typeId)
	-- 	elseif target == ModelTreasure.TYPE_EFFECT_JOB then
	-- 		img = gModelHero:GetCareerImgById(typeId)
	-- 	elseif target == ModelTreasure.TYPE_EFFECT_RACE then
	-- 		img = gModelHero:GetRaceImgByRefId(typeId)
	-- 	end
	-- 	self:SetWndEasyImage(TargetImg,img)
	-- end
	CS.ShowObject(TargetImg,showTarget)

	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end

	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		valueStr = "+" .. valueStr
		self:SetWndText(AttrValue,valueStr)
	end
end

function UIRelationSagaAddAttr:InitData()
	self._attrList = self:GetWndArg("attrList")


	local baseList = {}
	local heroBookAttrShow = gModelHero:GeConfigByKey("heroBookAttrShow")
	if heroBookAttrShow == nil then
		baseList = {
			[LAttrConst.Atk] = LAttrConst.Atk,
			[LAttrConst.MaxHP] = LAttrConst.MaxHP,
			[LAttrConst.Speed] = LAttrConst.Speed,
		}
	else
		heroBookAttrShow = string.split(heroBookAttrShow,"|")
		for i,v in ipairs(heroBookAttrShow) do
			v = tonumber(v)
			baseList[v] = v
		end
	end

	self._baseAttrList = baseList
end

function UIRelationSagaAddAttr:GetAttrList()
	local retList = {}
	local attrList = self._attrList or {}
	for i,v in ipairs(attrList) do
		local refId,numType,value = v.refId,v.numType,v.value
		local info = retList[refId]
		if not info then
			info = {}
			retList[refId] = info
		end
		local valInfo = info[numType] or 0
		info[numType] = valInfo + value
	end
	local keyList = {}
	local list = {}
	for refId,info in pairs(retList) do
		for numType,value in pairs(info) do
			keyList[refId] = numType
			table.insert(list,{
				refId = refId,
				numType = numType,
				value = value
			})
		end
	end
	--self._baseAttrList
	for k,v in pairs(self._baseAttrList) do
		if not keyList[k] then
			table.insert(list,{
				refId = v,
				numType = 1,
				value = 0.
			})
		end
	end
	table.sort(list,function(a,b)
		return a.refId < b.refId
	end)
	return list
end


------------------------------------------------------------------
return UIRelationSagaAddAttr


