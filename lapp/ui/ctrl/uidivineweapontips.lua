---
--- Created by wzz.
--- DateTime: 2024/9/27 17:08:31
---
------------------------------------------------------------------

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

local LWnd = LWnd
---@class UIDivineWeaponTips:LWnd
local UIDivineWeaponTips = LxWndClass("UIDivineWeaponTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponTips:UIDivineWeaponTips()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponTips:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end


function UIDivineWeaponTips:OnWndRefresh()
	LWnd.OnWndRefresh(self)

	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()



	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 刷新附魂
function UIDivineWeaponTips:RefreshAttach()
	local ref      = gModelDivineWeapon:GetDivineWeaponRef(self._refId)
	local refId = ref.linkGoal and ref.linkGoal[1]
	if refId then
		local upStarRef = gModelDivineWeapon:GetCurStarRef(refId)
		CS.ShowObject(self.mLock,not not upStarRef)
		if not upStarRef then
			local starCfgs = gModelDivineWeapon:GetDiviWeaponStarByRefId(refId)
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
			if self.jpj then
				local layout = trans:GetComponent(typeof(UnityEngine.UI.HorizontalLayoutGroup))
				layout.padding.left = 5
				layout.padding.right = 5
				self:SetTextTile(trans,ccLngText(skillFlagTxt[indx]),nil,-2)

			end
		end
		CS.ShowObject(self.mLSkillFlag,false)
	end
	self:SetWndText(self.mLTxtTips,ccClientText(41034))
	self:SetWndClick(self.mBtnTips,function()
		GF.OpenWnd("UIDivineWeaponTips",{refId = refId})
	end)
	-- CS.ShowObject(self.mSkill2, refId ~= nil)
end

-- 属性列表 item
function UIDivineWeaponTips:OnDrawAttrItem(uiList, item, data)
	if not uiList then
		uiList      = {}
		uiList.icon = CS.FindTrans(item, "AttrIcon")
		uiList.txt  = CS.FindTrans(item, "AttrValue")
		uiList.name = CS.FindTrans(item, "AttrName")
	end

	local iconPath = gModelHero:GetAttributeIconById(data.refId)
	self:SetWndEasyImage(uiList.icon, iconPath)

	local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.type, data.value)
	self:SetWndText(uiList.txt, val)

	local name = gModelHero:GetAttributeNameById(data.refId)
	self:SetWndText(uiList.name, name)
	return uiList
end

-- 调整窗口大小
function UIDivineWeaponTips:AdjustWndSize()
	-- 正常显示文本、显示附魂，时的各ui初始值
	-- 变量名为：控件名_标识
	local Panel_H = 800
	local List_H = 225
	local List_Y = -180
	local Skill2_H = 127
	local Skill2_Y = 147
	local TxtSkillDesc_H = 90

	-- 文本增加的高度
	local txtAddH = self.mTxtSkillDesc1.rect.height - TxtSkillDesc_H

	-- 列表高度
	local listH = List_H

	-- 技能文本增加的高度
	local txtSkillAddH = 0
	if self.mSkill2.gameObject.activeSelf then
		txtSkillAddH = self.mSkill2.rect.height - Skill2_H
		self.mSkill2.anchoredPosition = Vector2(0, Skill2_Y + txtSkillAddH)
	else
		listH = List_H + 63
		txtSkillAddH = -55
	end

	LxUiHelper.SetSizeWithCurAnchor(self.mPanel, 1, Panel_H + txtAddH + txtSkillAddH)
	LayoutRebuilder.ForceRebuildLayoutImmediate(self.mPanel)

	LxUiHelper.SetSizeWithCurAnchor(self.mList, 1, listH)
	self.mList.anchoredPosition = Vector2(0, List_Y - txtAddH)
end

-- 刷新属性
function UIDivineWeaponTips:RefreshAttr()
	local curAttrList = {}
	local upRef = self.listMap[self._starNum]
	curAttrList = LxDataHelper.ParseAttrList(upRef.attr)

	self:SetComList(self.mAttrList, curAttrList, function(...) return self:OnDrawAttrItem(...) end)
end

-- 初始事件
function UIDivineWeaponTips:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 刷新星级列表
function UIDivineWeaponTips:RefreshStarList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		local list = gModelDivineWeapon:GetDiviWeaponStarByRefId(self._refId)
		local refList = {}
		self.listMap = {}
		for _, value in ipairs(list) do
			if value.rankNow>0 then table.insert(refList,value) end
			self.listMap[value.rankNow] = value
		end
		uiList:Create(self.mList, refList, function(...)
			self:OnDrawStarListItem(...)
		end, UIItemList.SUPER, true)
	else
		self._uiList:DrawAllItems()
	end
end

-- 星级列表 item
function UIDivineWeaponTips:OnDrawStarListItem(list, item, itemdata, itempos)
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
	local gray = (self._starNum or 0) < starNum

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

-- 初始化数据
function UIDivineWeaponTips:InitData()
	self._refId       = self:GetWndArg("refId")
	local star = self:GetWndArg("starNum")
	self._starNum     = star or gModelDivineWeapon:GetCurStar(self._refId)
end

-- 初始界面化文本
function UIDivineWeaponTips:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTxtTips, ccClientText(41034))
end

-- 界面刷新
function UIDivineWeaponTips:Refresh()
	self:RefreshStarList()
	local refId    = self._refId
	local ref      = gModelDivineWeapon:GetDivineWeaponRef(refId)
	local upRef = self.listMap[self._starNum]
	self:SetWndEasyImage(self.mImgIcon,ref.icon)
	local skillRef = GameTable.SnakeSkillRef[upRef.skillId]
	self:SetWndEasyImage(self.mSkillIcon,skillRef.icon)

	--
	local color = gModelItem:GetColorStringByQualityId(ref.quality)
	local strName = ccClientText(41021, color, ccLngText(ref.name))
	self:SetWndText(self.mTxtSkillName, strName)

	-- 属性
	self:RefreshAttr()

	-- 技能标签
	local skillFlagTxt = ref and string.split(ccLngText(ref.logoTxt),"|")
	local skillFlagIcon = ref and string.split(ref.logoIcon,"|")
	local instanceId = self.mSkillFlag:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	local skillFlags = itemCache and itemCache.skillFlags or {}
	if not itemCache then
		itemCache = {
			skillFlags = skillFlags
		}
		for index, value in ipairs(skillFlagIcon) do
			local obj = CS.InstantObject(self.mSkillFlag.gameObject)
			obj.transform:SetParent(self.mSkillFlag.parent,false)
			skillFlags[index] = obj.transform
		end
	end
	for indx, trans in ipairs(skillFlags) do
		self:SetWndEasyImage(trans,skillFlagIcon[indx])
		self:SetTextTile(trans,ccLngText(skillFlagTxt[indx]))
		if self.jpj then
			local layout = trans:GetComponent(typeof(UnityEngine.UI.HorizontalLayoutGroup))
			layout.padding.left = 5
			layout.padding.right = 5
			self:SetTextTile(trans,ccLngText(skillFlagTxt[indx]),nil,-2)
		end
	end
	CS.ShowObject(self.mSkillFlag,false)

	self:SetWndText(self.mTxtSkillLev, ccClientText(41036, skillRef.level))
	self:SetWndText(self.mTxtSkillDesc1, "           " .. ccLngText(skillRef.description))
	LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTxtSkillDesc1)

	-- 附魂
	-- self:RefreshAttach()

end

------------------------------------------------------------------
return UIDivineWeaponTips