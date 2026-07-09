---
--- Created by Administrator.
--- DateTime: 2024/11/20 20:26:36
---
------------------------------------------------------------------
---
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local LWnd = LWnd
---@class UIDivineWeaponAttachPop:LWnd
local UIDivineWeaponAttachPop = LxWndClass("UIDivineWeaponAttachPop", LWnd)
------------------------------------------------------------------
local TabDataList = {
	[1] = { tabName = ccClientText(41098) },
	[2] = { tabName = ccClientText(41099) },
}
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponAttachPop:UIDivineWeaponAttachPop()
	self._initView = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponAttachPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponAttachPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponAttachPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndText(self.mTitle,ccClientText(46124))
	self:SetWndText(self.mCloseTip,ccClientText(41037))
	self._refId = self:GetWndArg("refId")
	self._starNum = gModelDivineWeapon:GetCurStar(self._refId) or 0
	self._curTabIndex = 1
	self:InitTab()
	self:Refresh()
	self:RefreshSkill()
end

-- 刷新星级列表
function UIDivineWeaponAttachPop:RefreshStarList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		local list = gModelDivineWeapon:GetDiviWeaponStarByRefId(self._refId)
		local refList = {}
		for _, value in ipairs(list) do
			if value.rankNow>0 then table.insert(refList,value) end
		end
		uiList:Create(self.mList, refList, function(...)
			self:OnDrawStarListItem(...)
		end, UIItemList.SUPER, true)
	end
end

-- 刷新界面
function UIDivineWeaponAttachPop:Refresh()
	CS.ShowObject(self.mView1, self._curTabIndex == 1)
	CS.ShowObject(self.mView2, self._curTabIndex == 2)

	if self._curTabIndex == 1 and not self._initView[self._curTabIndex] then
		self:RefreshStarList()
	elseif not self._initView[self._curTabIndex] then
		self:RefresList2()
	end
	self._initView[self._curTabIndex] = true
end
-- 星级列表 item
function UIDivineWeaponAttachPop:OnDrawStarListItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache         = {}
		itemCache.txtDesc = CS.FindTrans(item, "TxtDesc")
		local list        = {}
		local list2       = {}
		for i = 1, 10 do
			list[i] = CS.FindTrans(item, "starRoot/star" .. i)
			list2[i] = CS.FindTrans(item, "starRoot/star" .. i .. "/gray")
		end
		itemCache.starList = list
		itemCache.starList2 = list2
		self:SetComponentCache(instanceID, itemCache)
	end

	local starNum = itemdata.rankNow
	local gray = self._starNum < starNum

	local strDesc = ccLngText(itemdata.effectExtraDesc)
	if gray then
		strDesc = string.gsub(strDesc, "<color.->", "")
		strDesc = string.gsub(strDesc, "</color>", "")
		strDesc = "<color=#5f6d7b>" .. strDesc .. "</color>"
	end

	self:SetWndText(itemCache.txtDesc, strDesc)
	LayoutRebuilder.ForceRebuildLayoutImmediate(item)

	-- 星星
	if starNum then
		if starNum <= 5 then
			for i = 1, 5 do
				CS.ShowObject(itemCache.starList[i], i <= starNum)
				CS.ShowObject(itemCache.starList2[i], gray)
			end
			for i = 6, 10 do
				CS.ShowObject(itemCache.starList[i], false)
			end
		else
			for i = 1, 5 do
				CS.ShowObject(itemCache.starList[i], false)
			end
			for i = 6, 10 do
				CS.ShowObject(itemCache.starList[i], i <= starNum)
				CS.ShowObject(itemCache.starList2[i], gray)
			end
		end
	end
end

-- tab item
function UIDivineWeaponAttachPop:OnDrawTabItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root   = item,
			btnTab = CS.FindTrans(item, "BtnTab1"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end

	self:SetWndTabStatus(itemCache.btnTab, self._curTabIndex ~= itempos and 1 or 0)
	self:SetWndTabText(itemCache.btnTab, itemdata.tabName)
	self:SetWndClick(itemCache.btnTab, function()
		if self._curTabIndex == itempos then
			return
		end
		self._curTabIndex = itempos
		list:DrawAllItems()
		self:Refresh()
	end)
end

-- 星级列表 item
function UIDivineWeaponAttachPop:OnDrawListItem2(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache          = {}
		itemCache.txtTips1 = CS.FindTrans(item, "txtTips1")
		itemCache.txtTips2 = CS.FindTrans(item, "txtTips2")
		itemCache.txtTips3 = CS.FindTrans(item, "txtTips3")
		local list         = {}
		local list2        = {}
		for i = 1, 10 do
			list[i] = CS.FindTrans(item, "txtTips1/starRoot/star" .. i)
			list2[i] = CS.FindTrans(item, "txtTips1/starRoot/star" .. i .. "/gray")
		end
		itemCache.starList = list
		itemCache.starList2 = list2
		self:SetComponentCache(instanceID, itemCache)
	end

	local starNum = itemdata.rankNow
	self:SetWndText(itemCache.txtTips1, ccClientText(46123))
	self:SetWndText(itemCache.txtTips2, ccClientText(46114, itemdata.linkRate))

	local strTips3 = ""
	if self._starNum == starNum then
		strTips3 = ccClientText(40902)
	end
	self:SetWndText(itemCache.txtTips3, strTips3)

	-- 星星
	local starMax = gModelDivineWeapon:GetMaxStar(itemdata.type)
	for i, obj in ipairs(itemCache.starList) do
		CS.ShowObject(itemCache.starList2[i], i <= starMax)
		CS.ShowObject(obj, i <= starMax)
	end

	if starNum > 0 then
		for i, obj in ipairs(itemCache.starList) do
			CS.ShowObject(itemCache.starList2[i], i > starNum)
		end
	end
end

-- 初始tab
function UIDivineWeaponAttachPop:InitTab()
	local uilist = self:GetUIScroll("mTabScroll")
	uilist:Create(self.mTabScroll, TabDataList, function(...)
		self:OnDrawTabItem(...)
	end)
end

-- - 刷新星级列表
function UIDivineWeaponAttachPop:RefresList2()
	if not self._uiList2 then
		local uiList = self:GetUIScroll("DivineWeaponAttach")
		self._uiList2 = uiList

		local list = gModelDivineWeapon:GetDiviWeaponStarByRefId(self._refId)
		local pos = 1
		for k, v in ipairs(list) do
			if v.rankNow == self._starNum then
				pos = k
			end
		end

		uiList:Create(self.mList2, list, function(...)
			self:OnDrawListItem2(...)
		end, UIItemList.SUPER, true)

		uiList:MoveToPos(pos)
	end
end

-- 刷新附
function UIDivineWeaponAttachPop:RefreshSkill()
	local ref  = gModelDivineWeapon:GetDivineWeaponRef(self._refId)
	local upStarRef = gModelDivineWeapon:GetCurStarRef(self._refId)
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self._refId)
	self:SetWndEasyImage(self.mImgIcon,ref.icon)
	self:SetTextTile(self.mImgIcon,ccLngText(ref.name))

	CS.ShowObject(self.mLock,not info)
	if not upStarRef then
		local starCfgs = gModelDivineWeapon:GetDiviWeaponStarByRefId(self._refId)
		upStarRef = starCfgs[1]
	end
	local skillRef = GameTable.SnakeSkillRef[upStarRef.skillId]
	self:SetWndEasyImage(self.mLSkillIcon,skillRef.icon)
	self:SetWndText(self.mLTxtDesc,"        " .. ccLngText(skillRef.description))
	self:SetWndText(self.mLTxtSkillLv, ccClientText(41036, skillRef.level))
	self:SetWndText(self.mLTxtTips2,string.replace(ccClientText(46114),upStarRef.linkRate))

	local skillFlagTxt = ref and string.split(ccLngText(ref.logoTxt),"|")
	local skillFlagIcon = ref and string.split(ref.logoIcon,"|")
	local instanceId = self.mLSkillFlag:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	local skillFlags = itemCache and itemCache.skillFlags or {}
	if not itemCache then
		itemCache = {
			skillFlags = skillFlags
		}
		for index, value in ipairs(skillFlagIcon) do
			local obj = CS.InstantObject(self.mLSkillFlag.gameObject)
			obj.transform:SetParent(self.mLSkillFlag.parent,false)
			skillFlags[index] = obj.transform
		end
	end
	for indx, trans in ipairs(skillFlags) do
		self:SetWndEasyImage(trans,skillFlagIcon[indx])
		self:SetTextTile(trans,ccLngText(skillFlagTxt[indx]))
	end
	CS.ShowObject(self.mLSkillFlag,false)
	self:SetWndText(self.mLTxtTips,ccClientText(41034))
end
------------------------------------------------------------------
return UIDivineWeaponAttachPop