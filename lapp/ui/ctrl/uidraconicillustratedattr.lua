---
--- Created by wzz.
--- DateTime: 2024/4/12 16:29:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicIllustratedAttr:LWnd
local UIDraconicIllustratedAttr = LxWndClass("UIDraconicIllustratedAttr", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicIllustratedAttr:UIDraconicIllustratedAttr()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicIllustratedAttr:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicIllustratedAttr:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicIllustratedAttr:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitHandler()

	self:Refresh()
end

-- 刷新界面
function UIDraconicIllustratedAttr:Refresh()
	self._uiAttrList = self._uiAttrList or {}
	local dataList = gModelDraconic:GetIllustratedAttrList()
	for i, data in ipairs(dataList) do
		local tab = self._uiAttrList[i]
		if not tab then
			local obj = CS.InstantObject(self.mAttrItem.gameObject)
			local trans = obj.transform
			trans:SetParent(self.mAttrItem.parent, false)
			tab                      = {}
			tab.obj                  = obj
			tab.trans                = trans
			tab.icon                 = CS.FindTrans(trans, "AttrIcon")
			tab.txt                  = CS.FindTrans(trans, "AttrValue")
			tab.name                 = CS.FindTrans(trans, "AttrName")
			self._uiAttrList[i] = tab
		end

		CS.ShowObject(tab.trans, true)

		local iconPath = gModelHero:GetAttributeIconById(data.refId)
		self:SetWndEasyImage(tab.icon, iconPath)

		local name = gModelHero:GetAttributeNameById(data.refId)
		self:SetWndText(tab.name, name)

		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.type, data.value)
		self:SetWndText(tab.txt, val)
	end

	for i = #dataList + 1, #self._uiAttrList do
		CS.ShowObject(self._uiAttrList[i].trans, false)
	end
end

-- 初始化协议
function UIDraconicIllustratedAttr:InitHandler()
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)
end

-- 初始界面化文本
function UIDraconicIllustratedAttr:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(41044))
	self:SetWndText(self.mTxtTips, ccClientText(41045))
end

------------------------------------------------------------------
return UIDraconicIllustratedAttr