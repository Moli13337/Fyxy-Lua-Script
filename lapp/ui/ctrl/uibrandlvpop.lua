---
--- Created by Administrator.
--- DateTime: 2025/6/5 22:33:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandLvPop:LWnd
local UIBrandLvPop = LxWndClass("UIBrandLvPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandLvPop:UIBrandLvPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandLvPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandLvPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandLvPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTxtTitle,ccClientText(47560))
	self:SetWndText(self.mAttrTitle,ccClientText(47561))
	self.lvList,self.lvAttrMap = gModelBadge:GetBadgeLvTargetRef()
	self:OnClickEvent()
	self:UpdateAttrs()
	self:InitLevelList()
end

function UIBrandLvPop:OnDrawHeroShenCell(list, item, itemdata, itempos)
	CS.ShowObject(item,true)

	local ListAttrs = self:FindWndTrans(item, "ListAttrs")
	local ImgLv = self:FindWndTrans(item, "ImgLv")
	local NoAct = self:FindWndTrans(ImgLv, "NoAct")
	local Act = self:FindWndTrans(ImgLv, "Act")
	local TxtLv = self:FindWndTrans(ImgLv, "TxtLv")
	local TxtState = self:FindWndTrans(ImgLv, "TxtState")


	self:OnUpdateAttr(ListAttrs,itemdata,itempos)
	local activated = self.curLv>=itemdata.refId

	CS.ShowObject(NoAct,not activated)
	CS.ShowObject(Act,activated)

	self:SetWndText(TxtState,ccClientText(32738))
	self:SetWndText(TxtLv,itemdata.refId)
	CS.ShowObject(TxtState,activated)
end

function UIBrandLvPop:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	if AttrIcon then
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon)
	end

	if AttrName then
		local name = gModelHero:GetAttributeNameById(refId)
		self:SetWndText(AttrName,name)
	end
	self:SetWndText(AttrValue,"")
	if AttrValue then
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
		self:SetWndText(AttrValue,valueStr)
	end
end
function UIBrandLvPop:OnClickEvent()
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)

end
function UIBrandLvPop:UpdateAttrs()
	local badgePerLvAttr = GameTable.BadgeConfigRef.badgePerLvAttr
	local curlist = LxDataHelper.ParseAttrList(badgePerLvAttr)
	self:SetWndText(self.mLvTitle,string.replace(ccClientText(47546),gModelBadge:GetBadgeLv()))
	local uiAttrList = self._uiAttrList
	if uiAttrList then
		uiAttrList:RefreshList(curlist)
	else
		uiAttrList = self:GetUIScroll("levelAttrList")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,curlist,function(...) self:OnDrawAttrCell(...) end)
	end
end

function UIBrandLvPop:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
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
		self:SetWndText(AttrValue,valueStr)
	end
end

function UIBrandLvPop:OnUpdateAttr(uiList,itemdata,index)
	local attrList = self.lvAttrMap[itemdata.refId]
	self:CreateUIScrollImpl(nil,uiList,attrList,function(...) self:OnDrawAttrCell(...) end)
end

function UIBrandLvPop:InitLevelList()
	local moveIndx = 0
	local list = self.lvList
	self.curLv  = gModelBadge:GetBadgeLv()
	for index, value in ipairs(list) do
		if self.curLv>=value.refId then
			moveIndx = index
		else
			break
		end
	end
	---@type UIItemList
	local superList = self._uiLvList
	if superList then
		superList:RefreshList(list)
	else
		superList = self:GetUIScroll("mLevelList")
		self._uiLvList = superList
		superList:Create(self.mLevelList, list, function(...)
			self:OnDrawHeroShenCell(...)
		end, UIItemList.NORMAL)
		superList:EnableScroll(true)
	end
	superList:MoveToPos(moveIndx)
end
------------------------------------------------------------------
return UIBrandLvPop