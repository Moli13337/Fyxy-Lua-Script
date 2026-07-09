---
--- Created by LCM.
--- DateTime: 2024/3/4 14:57:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReItemSel:LWnd
local UIReItemSel = LxWndClass("UIReItemSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReItemSel:UIReItemSel()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReItemSel:OnWndClose()
	if self._skillIconList then
		LUtil.ClearHashTable(self._skillIconList)
		self._skillIconList = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReItemSel:OnCreate()
	LWnd.OnCreate(self)

	self._skillIconList = {}

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReItemSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:Refresh()
end

function UIReItemSel:InitSelSkillList()
	local list = self:GetSkillList()
	local uiSelSkillList = self._uiSelSkillList
	if uiSelSkillList then
		uiSelSkillList:RefreshList(list)
	else
		uiSelSkillList = self:GetUIScroll("uiSelSkillList")
		self._uiSelSkillList = uiSelSkillList
		uiSelSkillList:Create(self.mSelSkillList,list,function(...) self:OnDrawSelSkillCell(...) end)
	end
end

function UIReItemSel:RefreshTop()
	local refId = self._refId
	if not refId then return end
	self:RefreshItemRoot()
	local itemName = gModelItem:GetNameByRefId(refId)
	self:SetWndText(self.mItemName,itemName)
	self:RefreshHaveNum()
end

function UIReItemSel:InitText()
	self:SetTextTile(self.mBaseAttrTxt,ccClientText(24836))
	self:SetTextTile(self.mSkillTxt,ccClientText(24837))
	self:SetWndButtonText(self.mAttrSelBtn,ccClientText(24830), nil, -4, -30)
	self:SetWndButtonText(self.mSkillSelBtn,ccClientText(24831), nil, -4, -30)
	self:SetWndButtonText(self.mCancelBtn,ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(10102))
end

function UIReItemSel:GetAttrList()
	local list = {}
	local refId = self._refId
	if refId then
		local selAttrList = self._selAttrList
		if not selAttrList then
			selAttrList = {}
			self._selAttrList = selAttrList
		end
		local index = 0
		local runeSelInfo = gModelItem:GetRuneSelTypeDataByRefId(refId)
		if runeSelInfo then
			local attrGroup = runeSelInfo.attrGroup
			for i,attrGroupId in ipairs(attrGroup) do
				local selAttrInfo = selAttrList[attrGroupId]
				local isSelGroupId = selAttrInfo ~= nil
				index = index + 1
				if isSelGroupId then
					for k,v in pairs(selAttrInfo) do
						table.insert(list,{
							index = index,
							isSelGroupId = isSelGroupId,
							selAttrInfo = {
								attrRefId = v.attrRefId,
								attrType = v.attrType,
								attrVal = v.attrVal,
								refId = v.refId,
								attrGroupId = attrGroupId,
							},
						})
					end
				else
					table.insert(list,{
						index = index,
						isSelGroupId = isSelGroupId,
					})
				end
			end
		end
	end
	return list
end

function UIReItemSel:RefreshCenter()
	self:InitSelAttrList()
	self:InitSelSkillList()
end

function UIReItemSel:OnClickSelSkillBtnFunc()
	local refId = self._refId
	if not refId then return end
	GF.OpenWnd("UISelReJN",{
		itemRefId = refId,
		selSkillList = self._selSkillList,
		func = function(tSelSkillList)
			if not self:IsWndValid() then return end
			local selSkillList = {}
			self._selSkillList = selSkillList
			for skillGroupId,selSkillInfo in pairs(tSelSkillList) do
				local skillGroupInfo = {}
				selSkillList[skillGroupId] = skillGroupInfo
				for k,v in pairs(selSkillInfo) do
					skillGroupInfo[k] = {
						index = v.index,
						skillRefId = v.skillRefId,
						refId = v.refId,
					}
				end
			end
			self:InitSelSkillList()
		end
	})
end

function UIReItemSel:RefreshHaveNum()
	local refId = self._refId
	if not refId then return end
	local haveNum = gModelItem:GetNumByRefId(refId)
	local color = haveNum > 0 and "green" or "red"
	local str = LUtil.FormatColorStr(haveNum,color)
	local haveNumStr = string.replace(ccClientText(24822),str)
	self:SetWndText(self.mItemNum,haveNumStr)
end

function UIReItemSel:InitData()
	self._selAttrList = {}
	self._selSkillList = {}

	local refId = self:GetWndArg("refId")
	if not refId then return end
	self._ref = gModelItem:GetRefByRefId(refId)
	self._refId = refId
end

function UIReItemSel:OnClickEnterBtnFunc()
	local refId = self._refId
	if not refId then return end
	local runeSelInfo = gModelItem:GetRuneSelTypeDataByRefId(refId)
	if not runeSelInfo then return end
	local attrGroup = runeSelInfo.attrGroup
	local selAttrList = self._selAttrList
	local selAttrStr
	local selAttrNum = 0
	local attrGroupLen = #attrGroup
	for attrGroupId,v in pairs(selAttrList) do
		for k,val in pairs(v) do
			local attrRefId = val.refId
			if selAttrStr then
				selAttrStr = selAttrStr .. "," .. attrRefId
			else
				selAttrStr = attrRefId
			end
			selAttrNum = selAttrNum + 1
		end
	end
	local isNoSelFull = selAttrNum < attrGroupLen
	if isNoSelFull then
		-- 属性没有选满
		GF.ShowMessage(ccClientText(24849))
		self:OnClickSelAttrBtnFunc()
		return
	end

	local skillGroup = runeSelInfo.skillGroup
	local selSkillList = self._selSkillList
	local selSkillStr
	local selSkillNum = 0
	local skillGroupLen = #skillGroup
	for skillGroupId,selSkillInfo in pairs(selSkillList) do
		for k,v in pairs(selSkillInfo) do
			local runeSkillRefId = v.refId
			if selSkillStr then
				selSkillStr = selSkillStr .. "," .. runeSkillRefId
			else
				selSkillStr = runeSkillRefId
			end
			selSkillNum = selSkillNum + 1
		end
	end
	isNoSelFull = selSkillNum < skillGroupLen
	if isNoSelFull then
		-- 技能没有选满
		GF.ShowMessage(ccClientText(24850))
		self:OnClickSelSkillBtnFunc()
		return
	end
	local param = selAttrStr .. "_" .. selSkillStr
	local info = {}
	table.insert(info,{refId = refId,num = 1,params = param})
	gModelItem:OnItemUseReq(info)
end

function UIReItemSel:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
	self:SetWndClick(self.mAttrSelBtn,function() self:OnClickSelAttrBtnFunc() end)
	self:SetWndClick(self.mSkillSelBtn,function() self:OnClickSelSkillBtnFunc() end)
end

function UIReItemSel:OnDrawSelSkillCell(list,item,itemdata,itempos)
	local SkillRoot = self:FindWndTrans(item,"SkillRoot")
	local SkillIconTrans = self:FindWndTrans(SkillRoot,"SkillIcon")
	local skillName = self:FindWndTrans(item,"skillName")
	local skillDesc = self:FindWndTrans(item,"SkillScroll/skillDesc")

	local skillIconList = self._skillIconList
	if not skillIconList then
		skillIconList = {}
		self._skillIconList = skillIconList
	end

	local refId = itemdata.refId
	local skillRefId = itemdata.skillRefId
	local skillData
	if refId then
		skillData = gModelRune:GetSkillInfoByRefId(refId)
	end
	local InstanceID = item:GetInstanceID()
	local baseClass = skillIconList[InstanceID]
	if not baseClass then
		baseClass = SkillIcon:New(self)
	end
	baseClass:ShowWenHao(skillRefId == nil)
	baseClass:Create(SkillIconTrans,skillRefId,function()
		if not skillData then
			self:OnClickSelSkillBtnFunc()
			return
		end
		local skillType = skillData.skillType
		gModelRune:OpenNewRuneSkillWnd(refId,skillType)
	end)

	local skill = skillData and skillData.SkillId
	local skillNameStr,skillDescStr
	if skillRefId then
		local skillRef = gModelHero:GetSkillByStarId(skill)
		if skillRef then
			skillNameStr = ccLngText(skillRef.name)
			skillDescStr = ccLngText(skillRef.description)
		end
	else
		skillNameStr = ccClientText(13222)
		skillDescStr = ""
	end
	self:SetWndText(skillName,skillNameStr)
	self:SetWndText(skillDesc,skillDescStr)
end

function UIReItemSel:OnClickSelAttrBtnFunc()
	local refId = self._refId
	if not refId then return end
	GF.OpenWnd("UIReAttrSel",{
		itemRefId = refId,
		selAttrList = self._selAttrList,
		func = function(tSelAttrList)
			if not self:IsWndValid() then return end
			self._selAttrList = {}
			for attrGroupId,selAttrInfo in pairs(tSelAttrList) do
				self._selAttrList[attrGroupId] = selAttrInfo
			end
			self:InitSelAttrList()
		end
	})
end

function UIReItemSel:InitSelAttrList()
	local list = self:GetAttrList()
	local uiSelAttrList = self._uiSelAttrList
	if uiSelAttrList then
		uiSelAttrList:RefreshList(list)
	else
		uiSelAttrList = self:GetUIScroll("uiSelAttrList")
		self._uiSelAttrList = uiSelAttrList
		uiSelAttrList:Create(self.mSelAttrList,list,function(...) self:OnDrawSelAttrCell(...) end)
	end
end

function UIReItemSel:Refresh()
	local ref = self._ref
	if not ref then return end
	self:RefreshTop()
	self:RefreshCenter()
end

function UIReItemSel:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ItemUseResp,function()
		self:WndClose()
	end)
end

function UIReItemSel:RefreshItemRoot()
	local refId = self._refId
	if not refId then return end
	local trans = self.mItemRoot
	local InstanceID = trans:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(trans)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM,refId,-1)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
end

function UIReItemSel:OnDrawSelAttrCell(list,item,itemdata,itempos)
	local NoSelDiv = self:FindWndTrans(item,"NoSelDiv")
	local SelDiv = self:FindWndTrans(item,"SelDiv")

	local isSelGroupId = itemdata.isSelGroupId
	CS.ShowObject(NoSelDiv,not isSelGroupId)
	CS.ShowObject(SelDiv,isSelGroupId)

	if isSelGroupId then
		local selAttrInfo = itemdata.selAttrInfo
		local AttrIcon = self:FindWndTrans(SelDiv,"AttrIcon")
		local AttrName = self:FindWndTrans(SelDiv,"AttrName")
		local AttrNum = self:FindWndTrans(SelDiv,"AttrNum")
		local refId = selAttrInfo.attrRefId
		local attrType = selAttrInfo.attrType
		local attrVal = selAttrInfo.attrVal
		local icon = gModelHero:GetAttributeIconById(refId)
		self:SetWndEasyImage(AttrIcon,icon,function() CS.ShowObject(AttrIcon,true) end)
		local name = gModelHero:GetAttributeNameById(refId)
		--local nameStr = string.replace(ccClientText(18315),name)
		self:SetWndText(AttrName,name)
		local valStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,attrType,attrVal)
		self:SetWndText(AttrNum,valStr)
	else
		local NoSelTxt = self:FindWndTrans(NoSelDiv,"NoSelTxt")
		local str = string.replace(ccClientText(24816),itemdata.index)
		self:SetWndText(NoSelTxt,str)
	end
end

function UIReItemSel:GetSkillList()
	local list = {}
	local refId = self._refId
	if refId then
		local selSkillList = self._selSkillList
		if not selSkillList then
			selSkillList = {}
			self._selSkillList = selSkillList
		end
		local runeSelInfo = gModelItem:GetRuneSelTypeDataByRefId(refId)
		if runeSelInfo then
			local skillGroup = runeSelInfo.skillGroup
			for i,skillGroupId in ipairs(skillGroup) do
				local skillSplitInfo = gModelRune:GetRuneSkillGroupSplitInfoByRefId(skillGroupId)
				if skillSplitInfo then
					local selSkillInfo = selSkillList[skillGroupId]
					local isSelGroupId = selSkillInfo ~= nil
					if isSelGroupId then
						local skillList = {}
						for idx,val in pairs(selSkillInfo) do
							table.insert(skillList,{
								skillRefId = val.skillRefId,
								refId = val.refId,
								index = val.index,
							})
						end
						table.sort(skillList,function(a,b)
							return a.index < b.index
						end)
						for idx,val in ipairs(skillList) do
							table.insert(list,{
								skillRefId = val.skillRefId,
								refId = val.refId,
							})
						end
					else
						local qualityNumList = skillSplitInfo.qualityNum or {}
						for idx,val in ipairs(qualityNumList) do
							local num = val.num
							for index = 1,num do
								table.insert(list,{
									quality = val.quality,
								})
							end
						end
					end
				end
			end
		end
	end
	return list
end



------------------------------------------------------------------
return UIReItemSel


