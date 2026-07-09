---
--- Created by wzz.
--- DateTime: 2024/4/16 14:35:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicSelect:LWnd
local UIDraconicSelect = LxWndClass("UIDraconicSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicSelect:UIDraconicSelect()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicSelect:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self._pos = self:GetWndArg("pos")
	self._refId = gModelDraconic:GetUseRefId(self._pos)

	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

-- 卡片item
function UIDraconicSelect:OnDrawSpeechCard(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			card = CS.FindTrans(item, "DraconicCard")
		}
		CS.ShowObject(item, true)
		self:SetComponentCache(instanceID, itemCache)
	end

	local ref = itemdata.ref
	local select = self._refId == ref.refId
	local starNum = itemdata.starNum
	local showMask = starNum == -1
	local txtTips = ""
	if not showMask then
		local attachMainRefId = gModelDraconic:GetMainAttachRefId(ref.refId)
		if attachMainRefId > 0 then
			showMask = true

			local ref = gModelDraconic:GetDraconicRef(attachMainRefId)
			local name = ccLngText(ref.name)
			txtTips = ccClientText(40915, name)
		end
	end

	local param = {
		refId      = ref.refId,
		showName   = true,
		starNum    = starNum,
		showSlider = starNum == -1,
		showMask   = showMask,
		select     = select,
		txtTips    = txtTips
	}
	gModelDraconic:DrawCard(self, itemCache.card, param)

	self:SetWndClick(item, function() self:OnClickCard(ref.refId) end)
end

-- 点击卡片
function UIDraconicSelect:OnClickCard(refId)
	local attachMainRefId = gModelDraconic:GetMainAttachRefId(refId)
	if attachMainRefId > 0 then
		local ref = gModelDraconic:GetDraconicRef(attachMainRefId)
		local name = ccLngText(ref.name)
		GF.ShowMessage(ccClientText(40913, name))
		return
	end

	if self._refId == refId then
		self._refId = nil
	else
		local starNum = gModelDraconic:GetSpeechStar(refId)
		if starNum == -1 then
			GF.ShowMessage(ccClientText(41055))
			return
		end
		self._refId = refId
	end
	self:Refresh()
end

-- 刷新技能
function UIDraconicSelect:RefreshSkill()
	if not self._refId then
		return
	end

    local ref = GameTable.DraconicRef[self._refId]
	self:SetWndEasyImage(self.mSkillBg, ref.skillbg)
	self:SetWndEasyImage(self.mSkillIcon, ref.skillIcon)

	local starNum = gModelDraconic:GetSpeechStar(self._refId)
	self:SetWndText(self.mTxtSkillLev, ccClientText(41036, starNum + 1))
	local upRef = gModelDraconic:GetUpStarRef(self._refId, math.max(0, starNum))

	local skillRef = GameTable.SnakeSkillRef[upRef.skillId]

	if self._isEnus then
		self:SetWndText(self.mTxtSkillDesc, "             " .. ccLngText(skillRef.description))
		self:InitTextLineWithLanguage(self.mTxtSkillDesc,25)
	self:SetAnchorPos(self.mTxtSkillName,Vector2.New(-229.3,-15))
	else
		self:SetWndText(self.mTxtSkillDesc, "           " .. ccLngText(skillRef.description))

	end

	local color = gModelItem:GetColorStringByQualityId(ref.quality)
	local strName = ccClientText(41021, color, ccLngText(ref.name))
	self:SetWndText(self.mTxtSkillName, strName)



end

-- 初始界面化文本
function UIDraconicSelect:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(41051))
	self:SetWndText(self.mTxtTips1, ccClientText(41052))
	self:SetWndText(self.mTxtSkillTips, ccClientText(41056))

	self:SetWndButtonText(self.mBtnConfirm, ccClientText(41026))
end

-- 初始事件
function UIDraconicSelect:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
end

-- 刷新界面
function UIDraconicSelect:Refresh()
	if not self._uiList then
		local uiList = self:GetUIScroll("mCardList")
		self._uiList = uiList

		local list = gModelDraconic:GetAllSpeechRefList2()
		local dataList = {}
		for k, v in ipairs(list) do
			if v.effetcType == 1 and not gModelDraconic:HadUsed(v.refId) or self._refId == v.refId then
				table.insert(dataList, {index = k, ref = v, starNum = gModelDraconic:GetSpeechStar(v.refId)})
			end
		end

		table.sort(dataList, function(a, b)
			local starNumA = a.starNum
			local starNumB = b.starNum
			if starNumA >= 0  then
				starNumA = 0
			end
			if starNumB >= 0  then
				starNumB = 0
			end
			if starNumA ~= starNumB then
				return starNumA > starNumB
			end
			return a.index < b.index
		end)

		self._uiDataList = dataList
		uiList:Create(self.mCardList, dataList, function(...)
			self:OnDrawSpeechCard(...)
		end, UIItemList.SUPER_GRID, true)
	else
		self:RefreshSuperList(self._uiList, self._uiDataList)
	end

	CS.ShowObject(self.mTxtSkillTips, self._refId == nil)
	CS.ShowObject(self.mSkillRoot, self._refId ~= nil)
	self:RefreshSkill()
end

-- 点击确认
function UIDraconicSelect:OnClickBtnConfirm()
	local refId = gModelDraconic:GetUseRefId(self._pos)
	if self._refId == refId then
		self:WndClose()
		return
	end


	local type = 1
	local id = self._refId
	if not self._refId then
		type = 2
		id = 0
	end

	gModelDraconic:DraconicOperateReq(type, id, self._pos)
	self:WndClose()
end

------------------------------------------------------------------
return UIDraconicSelect