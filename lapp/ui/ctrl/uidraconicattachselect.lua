---
--- Created by wzz.
--- DateTime: 2024/9/29 14:42:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicAttachSelect:LWnd
local UIDraconicAttachSelect = LxWndClass("UIDraconicAttachSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicAttachSelect:UIDraconicAttachSelect()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicAttachSelect:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicAttachSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicAttachSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	-- 需要附魂的龙纹
	self._mainRefId = self:GetWndArg("refId")

	-- 当前选中的龙纹
	self._refId = nil

	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

-- 初始事件
function UIDraconicAttachSelect:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
end

-- 卡片item
function UIDraconicAttachSelect:OnDrawSpeechCard(list, item, itemdata, itempos)
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
	local mainAttachRefId = gModelDraconic:GetMainAttachRefId(ref.refId)
	if mainAttachRefId > 0 then
		local ref = gModelDraconic:GetDraconicRef(mainAttachRefId)
		local color = gModelItem:GetColorStringByQualityId(ref.quality)
		txtTips = ccClientText(41021, color, ccLngText(ref.name))
		txtTips = ccClientText(40908, txtTips)
		showMask = true
	else
		if gModelDraconic:HadUsedCheckAllFormations(ref.refId) then
			txtTips = ccClientText(40916)
			showMask = true
		end
	end

	local param = {
		refId      = ref.refId,
		showName   = true,
		showSlider = starNum == -1,
		showMask   = showMask,
		select     = select,
		txtTips    = txtTips,
	}
	gModelDraconic:DrawCard(self, itemCache.card, param)

	self:SetWndClick(item, function() self:OnClickCard(ref.refId, mainAttachRefId) end)
end

-- 初始界面化文本
function UIDraconicAttachSelect:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(40903))
	self:SetWndText(self.mTxtTips1, ccClientText(40904))
	self:SetWndText(self.mTxtSkillTips, ccClientText(40904))
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	self:SetWndButtonText(self.mBtnConfirm, ccClientText(41026))
end

-- 点击卡片
function UIDraconicAttachSelect:OnClickCard(refId, attachRefId)
	if attachRefId > 0 then
		GF.ShowMessage(ccClientText(40909))
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

-- 刷新界面
function UIDraconicAttachSelect:Refresh()
	if not self._uiList then
		local uiList = self:GetUIScroll("mCardList")
		self._uiList = uiList

		local attachRefIdList = gModelDraconic:GetCanAttachRefIdList(self._mainRefId)
		local dataList = {}
		for k, refId in ipairs(attachRefIdList) do
			local ref = gModelDraconic:GetDraconicRef(refId)
			local starNum = gModelDraconic:GetSpeechStar(refId)
			dataList[k] = { ref = ref, starNum = starNum }
		end

		table.sort(dataList, function(a, b)
			if a.starNum ~= b.starNum then
				return a.starNum > b.starNum
			end
			return a.ref.refId < a.ref.refId
		end)

		self._uiDataList = dataList
		uiList:Create(self.mCardList, dataList, function(...)
			self:OnDrawSpeechCard(...)
		end, UIItemList.SUPER_GRID, true)
	else
		self._uiList:DrawAllItems()
	end

	CS.ShowObject(self.mTxtSkillTips, self._refId == nil)
	CS.ShowObject(self.mSkillRoot, self._refId ~= nil)
	self:SetWndText(self.mTxtSkillDesc, "")


	self:RefreshSkill()
end

-- 刷新技能
function UIDraconicAttachSelect:RefreshSkill()
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
	self:SetWndText(self.mTxtSkillDesc, "           " .. ccLngText(skillRef.description))

	local color = gModelItem:GetColorStringByQualityId(ref.quality)
	local strName = ccClientText(41021, color, ccLngText(ref.name))
	self:SetWndText(self.mTxtSkillName, strName)
end

-- 点击确认
function UIDraconicAttachSelect:OnClickBtnConfirm()
	local linkRefId = 0
	if self._refId then
		linkRefId = self._refId
	end

	if gModelDraconic:HadUsedCheckAllFormations(linkRefId) then
		local ref = gModelDraconic:GetDraconicRef(linkRefId)
		gModelGeneral:OpenUIOrdinTips({
			refId = 52003,
			para = { ccLngText(ref.name) },
			func = function()
				gModelDraconic:DraconicLinkReq(self._mainRefId, linkRefId)
			end,
		})
		return
	end

	gModelDraconic:DraconicLinkReq(self._mainRefId, linkRefId)

	self:WndClose()
end

------------------------------------------------------------------
return UIDraconicAttachSelect