---
--- Created by wzz.
--- DateTime: 2024/4/10 18:22:38
---
------------------------------------------------------------------

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local LWnd = LWnd
---@class UIDraconicUpStar:LWnd
local UIDraconicUpStar = LxWndClass("UIDraconicUpStar", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicUpStar:UIDraconicUpStar()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicUpStar:OnWndClose()
	LWnd.OnWndClose(self)

	-- 升星后，需要将所有布阵的龙语id变成升星后的id
	if not self._tips and self._oldStarNum > -1 then
		local starNum = gModelDraconic:GetSpeechStar(self._refId)
		if starNum ~= self._oldStarNum then
			local upRef = gModelDraconic:GetUpStarRef(self._refId, starNum)
			gModelFormation:CheckFormationDraconic(upRef.refId)
		end
	end
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicUpStar:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicUpStar:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._refId = self:GetWndArg("refId")

	self._isMaxPre = self:GetWndArg("maxPre")
	self._starNum = self:GetWndArg("starNum")
	self._tips = self:GetWndArg("tips")
	if self._isMaxPre then
		self._starNum = gModelDraconic:GetStarMax(self._refId)
	else
		self._starNum = self._starNum or gModelDraconic:GetSpeechStar(self._refId)
	end
	self._oldStarNum = self._starNum

	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

-- 星级列表 item
function UIDraconicUpStar:OnDrawStarListItem(list, item, itemdata, itempos)
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

-- 点击确认
function UIDraconicUpStar:OnClickBtnConfirm()
	if not gModelDraconic:CanActiveOrUpStar(self._refId, true) then
		return
	end
	gModelDraconic:DraconicRankUpReq(self._refId)
end

-- 刷新界面
function UIDraconicUpStar:Refresh()
	local starNum = self._starNum
	-- 卡片
	local param = {
		refId    = self._refId,
		showType = true,
		starNum  = starNum,
	}

	gModelDraconic:DrawCard(self, self.mDraconicCard, param)

	local ref = gModelDraconic:GetDraconicRef(self._refId)
	self:SetWndText(self.mTxtSkillName, ccLngText(ref.name))

	-- 属性
	self:RefreshSpeechAttr()

	-- 技能标签
	gModelDraconic:DrawSkillFlag(self, self.mSkillFlag, self._refId)

	-- 技能图标
	self:SetWndEasyImage(self.mSkillBg, ref.skillbg)
	self:SetWndEasyImage(self.mSkillIcon, ref.skillIcon)

	local starNum = self._starNum
	self:SetWndText(self.mTxtSkillLev, ccClientText(41036, starNum + 1))
	local upRef = gModelDraconic:GetUpStarRef(self._refId, math.max(0, starNum))
	local skillRef = GameTable.SnakeSkillRef[upRef.skillId]
	self:SetWndText(self.mTxtSkillDesc, "           " .. ccLngText(skillRef.description))

	LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTxtSkillDesc)
	local txtSize = self.mTxtSkillDesc.sizeDelta

	local listH = 328 - (txtSize.y - 90)
	if self._tips then
		local bottomOff = 90
		listH = listH + bottomOff
		local pos = self.mList.anchoredPosition
		pos.y = pos.y - bottomOff
		self.mList.anchoredPosition = pos

		local size = self.mCenterBg.sizeDelta
		LxUiHelper.SetSizeWithCurAnchor(self.mCenterBg, 1, size.y + bottomOff)
	end
	LxUiHelper.SetSizeWithCurAnchor(self.mList, 1, listH)
	LayoutRebuilder.ForceRebuildLayoutImmediate(self.mList)

	self:RefreshCost()

	self:RefreshStarList()
end

-- 初始界面化文本
function UIDraconicUpStar:InitTexts()
	self:SetWndText(self.mTxtTips, ccClientText(41034))
	self:SetTextTile(self.mMax, ccClientText(41031))
	self:SetTextTile(self.mStarPreview, ccClientText(41065))

	CS.ShowObject(self.mStarPreview, self._isMaxPre ~= nil)
	CS.ShowObject(self.mBottom, self._tips == nil)
end

-- 刷新星级列表
function UIDraconicUpStar:RefreshStarList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		local list = gModelDraconic:GetUpStarRefList(self._refId)
		local dataList = {}
		for k, v in pairs(list) do
			if k > 0 then
				dataList[k] = v
			end
		end
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawStarListItem(...)
		end, UIItemList.SUPER, true)
	else
		self._uiList:DrawAllItems()
	end
end

-- 初始事件
function UIDraconicUpStar:InitEvents()
	self:SetWndClick(self.mReturnBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickBtnConfirm() end)

	if self._isVie then
		self:InitTextSizeWithLanguage(CS.FindTrans(self.mStarPreview,"UIText"),-4)
		self:InitTextCharacterWithLanguage(CS.FindTrans(self.mStarPreview,"UIText"),-6)
		self:SetAnchorPos(self.mStarPreview,Vector2.New(188.5,141.4))
		self.mStarPreview.sizeDelta = Vector2.New(150,20)
	end

	-- self:WndEventRecv(EventNames.On_Item_Change, function(...) self:Refresh(...) end)
	self:WndEventRecv(EventNames.DRACONIC_INFO_RETURN, function(...) self._starNum = gModelDraconic:GetSpeechStar(self._refId)  self:Refresh() end)
end

-- 龙语属性
function UIDraconicUpStar:RefreshSpeechAttr()
	local curAttrList  = {}
	local nextAttrList = {}
	local starNum = self._starNum
	local costItem = gModelDraconic:GetUpStarCostRef(self._refId, starNum)
	if starNum == -1 then
		-- 未激活
		starNum = -1
		curAttrList = gModelDraconic:GetSpeechBaseAttr(self._refId, 0)
		nextAttrList = {}
		-- for k, v in ipairs(nextAttrList) do
		-- 	curAttrList[k] = { attrId = v.attrId, value = 0 }
		-- end
	elseif costItem == nil then
		-- 满星
		curAttrList = gModelDraconic:GetSpeechBaseAttr(self._refId, starNum)
		nextAttrList = {}
	else
		curAttrList = gModelDraconic:GetSpeechBaseAttr(self._refId, starNum)
		nextAttrList = gModelDraconic:GetSpeechBaseAttr(self._refId, starNum + 1)
	end

	self._uiSpeechAttrList = self._uiSpeechAttrList or {}
	for k, data in ipairs(curAttrList) do
		local tab = self._uiSpeechAttrList[k]
		if not tab then
			local obj = CS.InstantObject(self.mSpeechAttrRoot.gameObject)
			local trans = obj.transform
			trans:SetParent(self.mSpeechAttrRoot.parent, false)
			tab                       = {}
			tab.obj                   = obj
			tab.icon                  = CS.FindTrans(trans, "AttrIcon")
			tab.txt                   = CS.FindTrans(trans, "AttrValue")
			tab.name                  = CS.FindTrans(trans, "AttrName")
			tab.add                   = CS.FindTrans(trans, "AttrValueAdd")
			self._uiSpeechAttrList[k] = tab

			CS.ShowObject(tab.obj, true)

			local iconPath = gModelHero:GetAttributeIconById(data.attrId)
			self:SetWndEasyImage(tab.icon, iconPath)

			local name = gModelHero:GetAttributeNameById(data.attrId)
			self:SetWndText(tab.name, name)
		end

		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.attrId, data.type, data.value)
		self:SetWndText(tab.txt, val)

		if nextAttrList[k] and not self._tips then
			local val = gModelHero:GetAttributeValueNoNameByIdAndVal(data.attrId, data.type,
				nextAttrList[k].value - data.value)
			self:SetWndText(tab.add, "+" .. val)
		else
			self:SetWndText(tab.add, "")
		end
	end
end

-- 绘制item
function UIDraconicUpStar:DrawItem(mItem, itemdata)
	local refId = itemdata.refId
	local instanceID = mItem:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(mItem)
	end

	baseClass:SetCommonReward(itemdata.type, refId, itemdata.count)
	self:SetWndClick(mItem, function()
		gModelGeneral:OpenGetWayWnd({ itemId = refId })
	end)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
end

-- 刷新消耗
function UIDraconicUpStar:RefreshCost()
	if self._tips then
		return
	end

	local starNum  = self._starNum
	local costItem = gModelDraconic:GetUpStarCostRef(self._refId, starNum)
	local isMax    = costItem == nil
	local btnStr   = ""
	if starNum == -1 then
		btnStr = ccClientText(41033)
	elseif isMax then
		-- 满星
	else
		btnStr = ccClientText(41032)
	end

	if not isMax then
		self:DrawItem(self.mItemRoot, costItem)

		local refId = costItem.refId
		local haveNum = gModelItem:GetNumByRefId(refId)
		local needNum = costItem.count
		local color = "139057"
		if haveNum < needNum then
			color = "c81212"
		end
		needNum = string.replace(ccClientText(41035), color, LUtil.NumberCoversion(haveNum), needNum)
		self:SetWndText(self.mCostNum, needNum)
	end

	CS.ShowObject(self.mCostRoot, not isMax)
	CS.ShowObject(self.mMax, isMax)

	self:SetWndButtonText(self.mBtnConfirm, btnStr)
	self:SetRed(self.mBtnConfirm, gModelDraconic:CanActiveOrUpStar(self._refId))
end

------------------------------------------------------------------
return UIDraconicUpStar