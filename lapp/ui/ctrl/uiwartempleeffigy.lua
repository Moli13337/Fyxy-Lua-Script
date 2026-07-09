---
--- Created by wzz.
--- DateTime: 2024/5/9 15:06:06
---


local ViewType = {
	Attr = 1,
	Log = 2
}

------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleEffigy:LWnd
local UIWarTempleEffigy = LxWndClass("UIWarTempleEffigy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleEffigy:UIWarTempleEffigy()
	self.noNeedRegisterRed = true
	self._upEffectIndex = 0
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleEffigy:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleEffigy:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleEffigy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._viewType = ViewType.Attr

	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

-- 刷新属性
function UIWarTempleEffigy:RefreshAttr()
	local lev = gModelWarTemple:GetEffigyLev()
	local attrList = gModelWarTemple:GetWarTempleAttrList(lev)

	self._uiAttrList = self._uiAttrList or {}
	for i, data in ipairs(attrList) do
		local tab = self._uiAttrList[i]
		if not tab then
			local obj = CS.InstantObject(self.mAttrRoot.gameObject)
			local trans = obj.transform
			trans:SetParent(self.mAttrRoot.parent, false)
			tab                 = {}
			tab.obj             = obj
			tab.trans           = trans
			tab.icon            = CS.FindTrans(trans, "AttrIcon")
			tab.txt             = CS.FindTrans(trans, "AttrValue")
			tab.name            = CS.FindTrans(trans, "AttrName")
			self._uiAttrList[i] = tab

			local iconPath = gModelHero:GetAttributeIconById(data.refId)
			self:SetWndEasyImage(tab.icon, iconPath)

			local name = gModelHero:GetAttributeNameById(data.refId)
			self:SetWndText(tab.name, name)

			CS.ShowObject(tab.trans, true)
		end

		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.numType, data.value)
		local addVal = data.addValue or 0
		if addVal > 0 then
			addVal = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.numType, addVal)
			val = ccClientText(42025, val, addVal)
		end

		self:SetWndText(tab.txt, val)
	end
end

-- 初始界面化文本
function UIWarTempleEffigy:InitTexts()
	self:SetWndText(self.mTxtClose, ccClientText(42010))
	self:SetWndText(self.mTitle, ccClientText(42009))
	self:SetWndText(self.mTxtTips1, ccClientText(42019))
	self:SetWndText(self.mTxtTips2, ccClientText(42024))

	self:SetTextTile(self.mBtnEffigy, ccClientText(42022))
	self:SetTextTile(self.mBtnLog, ccClientText(42023))

	self:CreateWndEffect(self.mEffBg, "fx_wushendian_beijing", "bg", 100)
end

-- 点击雕像
function UIWarTempleEffigy:OnClickBtnEffigy()
	self._viewType = ViewType.Attr
	self:RefreshPage()
end

-- 点击传记
function UIWarTempleEffigy:OnClickBtnLog()
	self._viewType = ViewType.Log
	self:RefreshPage()
end

-- 刷新界面页
function UIWarTempleEffigy:RefreshPage()
	CS.ShowObject(self.mAttr, self._viewType == ViewType.Attr)
	CS.ShowObject(self.mLog, self._viewType == ViewType.Log)
end

-- 点击升级
function UIWarTempleEffigy:OnClickBtnUp()

	local enough = gModelWarTemple:CanLvUpEgffigy(true)
	if not enough then
		return
	end
	gModelWarTemple:WarTempleEgffigyLvUpReq()


	self._upEffectIndex = self._upEffectIndex  + 1
	self:CreateWndEffect(self.mEffUp, "fx_wushendian_shengji", self._upEffectIndex, 100, nil, nil, nil,nil,nil,nil,nil,nil,30)

	self._upEffectKeyList = self._upEffectKeyList or {}
	table.insert(self._upEffectKeyList, self._upEffectIndex)

	if #self._upEffectKeyList > 10 then
		local key = table.remove(self._upEffectKeyList, 1)
		self:DestroyWndEffectByKey(key)
	end
end

-- 刷新界面
function UIWarTempleEffigy:Refresh()
	local lev = gModelWarTemple:GetEffigyLev()
	self:SetWndText(self.mTxtLev, ccClientText(42018, lev))

	self:RefreshAttr()
	self:RefreshCost()
	self:RefreshPage()
end

-- 刷新消耗
function UIWarTempleEffigy:RefreshCost()
	local enough, costList, isMax = gModelWarTemple:CanLvUpEgffigy(false)

	for i = 1, 2 do
		local data = costList[i]
		if not data then
			return
		end
		self:CreateCommonIconImpl(self["mItemRoot" .. i], data, {showNum = false, showBg = false})
		local haveNum = gModelItem:GetNumByRefId(data.refId)
		local needNum = data.count
		local strNum
		if haveNum < needNum then
			haveNum = LUtil.NumberCoversion(haveNum)
			needNum = LUtil.NumberCoversion(needNum)
			strNum = ccClientText(42026, haveNum, needNum)
		else
			haveNum = LUtil.NumberCoversion(haveNum)
			needNum = LUtil.NumberCoversion(needNum)
			strNum = ccClientText(42027, haveNum, needNum)
		end
		self:SetWndText(self["mTxtCost" .. i], strNum)
	end

	local btnStr
	if isMax then
		btnStr = ccClientText(42021)
	else
		btnStr = ccClientText(42020)
	end
	self:SetWndButtonText(self.mBtnUp, btnStr)
	self:SetWndButtonGray(self.mBtnUp, isMax)

	self:SetRed(self.mBtnUp, enough)
end

-- 初始事件
function UIWarTempleEffigy:InitEvents()
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnEffigy, function() self:OnClickBtnEffigy() end)
	self:SetWndClick(self.mBtnLog, function() self:OnClickBtnLog() end)
	self:SetWndClick(self.mBtnUp, function() self:OnClickBtnUp() end)
	self:SetWndClick(self.mBtnHelp, function() GF.OpenWnd("UIBzTips", { refId = 172 }) end)

	self:WndEventRecv(EventNames.WARTEMPLE_INFO_RETURN,
	function(...)
		self:Refresh(...)
	end)

	self:WndEventRecv(EventNames.On_Item_Change, function(...) self:RefreshCost(...) end)
end

------------------------------------------------------------------
return UIWarTempleEffigy