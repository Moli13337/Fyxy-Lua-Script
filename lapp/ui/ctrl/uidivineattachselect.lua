---
--- Created by Administrator.
--- DateTime: 2024/12/5 17:15:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineAttachSelect:LWnd
local UIDivineAttachSelect = LxWndClass("UIDivineAttachSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineAttachSelect:UIDivineAttachSelect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineAttachSelect:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineAttachSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineAttachSelect:OnStart()
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

-- 点击卡片
function UIDivineAttachSelect:OnClickCard(refId, attachRefId)
	if attachRefId > 0 then
		GF.ShowMessage(ccClientText(46167))
		return
	end


	if self._refId == refId then
		self._refId = nil
	else
		local starNum =  gModelDivineWeapon:GetCurStar(refId) or -1
		if starNum == -1 then
			GF.ShowMessage(ccClientText(46168))
			return
		end
		self._refId = refId
	end
	self:Refresh()
end

-- 卡片item
function UIDivineAttachSelect:OnDrawSpeechCard(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			icon = CS.FindTrans(item, "Card/icon"),
			star = CS.FindTrans(item, "Card/star"),
			name = CS.FindTrans(item, "Card/name"),
			txtTips = CS.FindTrans(item, "Card/txtTips"),
			select = CS.FindTrans(item, "Card/select"),
			mask = CS.FindTrans(item, "Card/mask"),
			imgLock = CS.FindTrans(item, "Card/mask/ImgLock"),
		}
		CS.ShowObject(item, true)
		self:SetComponentCache(instanceID, itemCache)
	end

	local ref = itemdata.ref
	local select = self._refId == ref.refId
	local starNum = itemdata.starNum
	local showMask = starNum == -1

	local txtTips = ""
	local mainAttachRefId = gModelDivineWeapon:GetMainAttachRefId(ref.refId)
	local color = gModelItem:GetColorStringByQualityId(ref.quality)
	if mainAttachRefId > 0 then
		local ref = GameTable.DivineWeaponRef[mainAttachRefId]
		txtTips = ccClientText(41021, color, ccLngText(ref.name))
		txtTips = ccClientText(46180, txtTips)
		showMask = true
	else
		if gModelDivineWeapon:HadUsedCheckAllFormations(ref.refId) then
			txtTips = ccClientText(40916)
			showMask = true
		end
	end
	self:SetWndEasyImage(itemCache.icon,ref.icon)
	self:SetWndImageGray(itemCache.icon,showMask)
	CS.ShowObject(itemCache.mask,showMask)
	CS.ShowObject(itemCache.imgLock,starNum == -1)
	local sizeDe = itemCache.star.sizeDelta
	sizeDe.x = 40*(math.max(starNum,0))
	itemCache.star.sizeDelta = sizeDe
	self:SetWndText(itemCache.name,ccLngText(ref.name))
	self:SetWndText(itemCache.txtTips,txtTips)
	CS.ShowObject(itemCache.select,select)
	LxUiHelper.SetXTextColor(itemCache.name,LUtil.ColorByHex(color))
	self:SetWndClick(item, function() self:OnClickCard(ref.refId, mainAttachRefId) end)
end

-- 刷新技能
function UIDivineAttachSelect:RefreshSkill()
	if not self._refId then
		return
	end

	local ref = GameTable.DivineWeaponRef[self._refId]
	local Skill = gModelDivineWeapon:GetSkillId(self._refId)
	local skillCfg = GameTable.SnakeSkillRef[Skill]
	self:SetWndEasyImage(self.mSkillIcon, skillCfg.icon)

	local starNum = gModelDivineWeapon:GetCurStar(self._refId)
	self:SetWndText(self.mTxtSkillLev, ccClientText(41036, starNum + 1))
	self:SetWndText(self.mTxtSkillDesc, "           " .. ccLngText(skillCfg.description))

	local color = gModelItem:GetColorStringByQualityId(ref.quality)
	local strName = ccClientText(41021, color, ccLngText(ref.name))
	self:SetWndText(self.mTxtSkillName, strName)
end

-- 初始界面化文本
function UIDivineAttachSelect:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(46153))
	self:SetWndText(self.mTxtTips1, ccClientText(46166))
	self:SetWndText(self.mTxtSkillTips, ccClientText(46166))
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	self:SetWndButtonText(self.mBtnConfirm, ccClientText(41026))
end

-- 点击确认
function UIDivineAttachSelect:OnClickBtnConfirm()
	local linkRefId = 0
	if self._refId then
		linkRefId = self._refId
	end

	if gModelDivineWeapon:HadUsedCheckAllFormations(linkRefId) then
		local ref = GameTable.DivineWeaponRef[linkRefId]
		gModelGeneral:OpenUIOrdinTips({
			refId = 52003,
			para = { ccLngText(ref.name) },
			func = function()
				gModelDivineWeapon:OnDivineWeaponLinkReq(self._mainRefId, linkRefId)
			end,
		})
		return
	end

	gModelDivineWeapon:OnDivineWeaponLinkReq(self._mainRefId, linkRefId)

	self:WndClose()
end

-- 刷新界面
function UIDivineAttachSelect:Refresh()
	if not self._uiList then
		local uiList = self:GetUIScroll("mCardList")
		self._uiList = uiList

		local ref = GameTable.DivineWeaponRef[self._mainRefId]
		local attachRefIdList = ref.linkGoal or {}
		local dataList = {}
		for k, refId in ipairs(attachRefIdList) do
			local ref = GameTable.DivineWeaponRef[refId]
			local starNum = gModelDivineWeapon:GetCurStar(refId) or -1
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

-- 初始事件
function UIDivineAttachSelect:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
end


------------------------------------------------------------------
return UIDivineAttachSelect