---
--- Created by Administrator.
--- DateTime: 2024/11/21 22:19:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponBookAttr:LWnd
local UIDivineWeaponBookAttr = LxWndClass("UIDivineWeaponBookAttr", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponBookAttr:UIDivineWeaponBookAttr()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponBookAttr:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponBookAttr:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponBookAttr:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTxtTitle,self:GetWndArg("title"))
	self:SetWndText(self.mTxtDesc,self:GetWndArg("desc"))
	self:SetWndText(self.mCloseTip,ccClientText(41037))
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:UpdateAttrs()
end

function UIDivineWeaponBookAttr:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = math.max(itemdata.attrType or itemdata.type,1),itemdata.attrRefId or itemdata.refId,itemdata.attrNum or itemdata.value
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
		local attrRef = gModelHero:GetAttributeRefById(refId)
		if numType==1 and attrRef.numType==1 then
			valueStr = math.floor(valueStr)
		end
		self:SetWndText(AttrValue,valueStr)
	end
end
function UIDivineWeaponBookAttr:UpdateAttrs()
	local attrList = self:GetWndArg("attrList")
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(attrList)
	else
		uiAttrList = self:GetUIScroll("favorAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,attrList,function(...) self:OnDrawAttrCell(...) end)
	end
end


------------------------------------------------------------------
return UIDivineWeaponBookAttr