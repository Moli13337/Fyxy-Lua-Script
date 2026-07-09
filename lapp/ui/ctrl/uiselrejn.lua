---
--- Created by LCM.
--- DateTime: 2024/3/6 1:34:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISelReJN:LWnd
local UISelReJN = LxWndClass("UISelReJN", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISelReJN:UISelReJN()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISelReJN:OnWndClose()

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
function UISelReJN:OnCreate()
	LWnd.OnCreate(self)
	self._skillIconList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISelReJN:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshEnterBtnName()
	self:Refresh()
end

function UISelReJN:RefreshNextSkillIndex()
	local firstIndex = self:GetNextSkillIndex()
	if firstIndex then
		self._selSkillIndex = firstIndex.index
	elseif self._selSkillIndex == nil then
		self._selSkillIndex = 1
	end
end

function UISelReJN:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(24817))
end

function UISelReJN:IsCanSelSkillStatus(skillRefId,skillIndex)
	local selIndexSkillList = self:GetSelSkillKeyList()
	local selInfo = selIndexSkillList[skillRefId]
	if not selInfo then
		return false
	end
	local index = selInfo.index
	return index == skillIndex
end

function UISelReJN:EnterFunc()
	local func = self._func
	if func then
		local tPSelSkillList = {}
		local pSelSkillList = self._pSelSkillList
		for skillGroupId,selSkillInfo in pairs(pSelSkillList) do
			local tTab = {}
			tPSelSkillList[skillGroupId] = tTab
			for k,v in pairs(selSkillInfo) do
				local index = v.index
				tTab[index] = {
					index = index,
					skillRefId = v.skillRefId,
					refId = v.refId,
				}
			end
		end
		func(tPSelSkillList)
	end
	self:WndClose()
end

function UISelReJN:GetSelSkillList()
	local list = {}
	local selIndexSkillList = self:GetSelSkillGroupAndIndexList()
	local selSkillInfoList = self._selAllSkillInfoList
	for i,v in ipairs(selSkillInfoList) do
		local skillGroupId = v.skillGroupId
		local index = v.index
		local selData = selIndexSkillList[skillGroupId]
		local selIndexData = selData and selData[index]
		table.insert(list,{
			skillRefId = selIndexData and selIndexData.skillRefId,
			index = i,
			quality = v.quality
		})
	end
	return list
end

function UISelReJN:InitSelSkillList()
	local list = self:GetSelSkillList()

	local uiSelSkillList = self._uiSelSkillList
	if uiSelSkillList then
		uiSelSkillList:RefreshList(list)
	else
		uiSelSkillList = self:GetUIScroll("uiSelSkillList")
		self._uiSelSkillList = uiSelSkillList
		uiSelSkillList:Create(self.mSelSkillList,list,function(...) self:OnDrawSelSkillCell(...) end)
	end
end

function UISelReJN:InitMsg()

end

function UISelReJN:IsHaveNextSelSkill()
	local firstIndex = self:GetNextSkillIndex()
	return firstIndex ~= nil
end

function UISelReJN:OnDrawSelSkillCell(list,item,itemdata,itempos)
	local SkillRoot = self:FindWndTrans(item,"SkillRoot")
	local SkillIconTrans = self:FindWndTrans(SkillRoot,"SkillIcon")
	local SelImg = self:FindWndTrans(item,"SelImg")
	local SkillName = self:FindWndTrans(item,"SkillName")

	local skillIconList = self._skillIconList
	if not skillIconList then
		skillIconList = {}
		self._skillIconList = skillIconList
	end

	local skillRefId = itemdata.skillRefId
	local index = itemdata.index
	local InstanceID = item:GetInstanceID()
	local baseClass = skillIconList[InstanceID]
	if not baseClass then
		baseClass = SkillIcon:New(self)
	end
	baseClass:ShowWenHao(skillRefId == nil)
	baseClass:Create(SkillIconTrans,skillRefId,function()
		self:OnClickSelSkillFunc(index)
	end)

	local isSel = index == self._selSkillIndex
	CS.ShowObject(SelImg,isSel)

	local skillNameStr = ""
	if skillRefId then
		local skillRef = gModelHero:GetSkillByStarId(skillRefId)
		if skillRef then
			skillNameStr = ccLngText(skillRef.name)
		end
	else
		local quality = itemdata.quality
		local textId = gModelRune:GetQualityTextIdByQuality(quality)
		if textId then
			skillNameStr = string.replace(ccClientText(24907),ccClientText(textId))
		end
	end
	self:SetWndText(SkillName,skillNameStr)
end

function UISelReJN:Refresh()
	self:RefreshNextSkillIndex()
	self:InitSelSkillList()
	self:InitCanSelSkillList()
end

function UISelReJN:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
end

function UISelReJN:GetNextSkillIndex()
	local emptyPosList = {}
	local selIndexSkillList = self:GetSelSkillGroupAndIndexList()
	local selSkillInfoList = self._selAllSkillInfoList
	if selSkillInfoList then
		for i,v in ipairs(selSkillInfoList) do
			local skillGroupId = v.skillGroupId
			local index = v.index
			local selIndexSkillInfo = selIndexSkillList[skillGroupId]
			if not selIndexSkillInfo then
				selIndexSkillInfo = {}
				selIndexSkillList[skillGroupId] = selIndexSkillInfo
			end
			local selIndexInfo = selIndexSkillInfo[index]
			if not selIndexInfo then
				table.insert(emptyPosList,{
					index = v.sort
				})
			end
		end
		table.sort(emptyPosList,function(a,b)
			return a.index < b.index
		end)
		return emptyPosList[1]
	end
end

function UISelReJN:InitData()
	self._itemRefId = self:GetWndArg("itemRefId")
	self._func = self:GetWndArg("func")
	local selSkillList = self:GetWndArg("selSkillList") or {}

	local pSelSkillList = {}
	for skillGroupId,selSkillInfo in pairs(selSkillList) do
		local skillGroupInfo = {}
		pSelSkillList[skillGroupId] = skillGroupInfo
		for k,v in pairs(selSkillInfo) do
			local index = v.index
			skillGroupInfo[index] = {
				index = index,
				skillRefId = v.skillRefId,
				refId = v.refId,
			}
		end
	end
	self._pSelSkillList = pSelSkillList


	local selAllSkillInfoList = self:GetAllSelSkillInfoList()
	self._selAllSkillInfoList = selAllSkillInfoList
end

function UISelReJN:OnClickEnterBtnFunc()
	local haveNext = self:IsHaveNextSelSkill()
	if haveNext then
		self:RefreshNextSkillIndex()
		self:InitSelSkillList()
		self:InitCanSelSkillList()
	else
		self:EnterFunc()
	end
end

function UISelReJN:GetSelSkillGroupAndIndexList()
	local selIndexSkillList = {}
	local pSelSkillList = self._pSelSkillList
	for skillGroupId,selSkillInfo in pairs(pSelSkillList) do
		local groupList = {}
		selIndexSkillList[skillGroupId] = groupList
		for index,skillGroupInfo in pairs(selSkillInfo) do
			groupList[index] = skillGroupInfo
		end
	end
	return selIndexSkillList
end

function UISelReJN:GetCanSelSkillLIst()
	local list = {}
	local refId = self._itemRefId
	if refId then
		local runeSelInfo = gModelItem:GetRuneSelTypeDataByRefId(refId)
		if runeSelInfo then
			local selSkillInfoList = self._selAllSkillInfoList
			local selInfo = selSkillInfoList[self._selSkillIndex]
			if selInfo then
				local skillQuality = selInfo.quality
				if skillQuality then
					local qualitySkillList = gModelRune:GetQualityRuneSkillListByQuality(skillQuality)
					if qualitySkillList then
						for i,v in ipairs(qualitySkillList) do
							table.insert(list,{
								refId = v.refId,
								skillRefId = v.skillRefId,
								skillType = v.skillType,
								skillLevel = v.skillLevel,
								sort = v.sort,
								quality = v.quality,
								index = selInfo.index,
							})
							--table.insert(list,v)
						end
					end
				end
			end
		end
	end
	return list
end

function UISelReJN:IsCanSelLockStatus(skillRefId)
	local selIndexSkillList = self:GetSelSkillKeyList()
	return selIndexSkillList[skillRefId] ~= nil
end

function UISelReJN:OnClickCanSelSkillFunc(itemdata)
	local skillRefId = itemdata.skillRefId
	local selAllSkillInfoList = self._selAllSkillInfoList
	local index = self._selSkillIndex
	local selAllSkillInfo = selAllSkillInfoList[index]
	if not selAllSkillInfo then return end
	local pSelSkillList = self._pSelSkillList
	if not pSelSkillList then
		pSelSkillList = {}
		self._pSelSkillList = pSelSkillList
	end
	local skillGroupId = selAllSkillInfo.skillGroupId
	if not skillGroupId then return end
	local skillIndex = selAllSkillInfo.index
	if not skillIndex then return end
	local selIndexSkillList = pSelSkillList[skillGroupId]
	if not selIndexSkillList then
		selIndexSkillList = {}
		pSelSkillList[skillGroupId] = selIndexSkillList
	end

	for k,v in pairs(selIndexSkillList) do
		if v.skillType == itemdata.skillType then
			GF.ShowMessage(ccClientText(24851))
			return
		end
	end

	selIndexSkillList[skillIndex] = {
		index = skillIndex,
		skillRefId = skillRefId,
		refId = itemdata.refId,
		skillType = itemdata.skillType,
	}
	self:RefreshEnterBtnName()
	self:InitSelSkillList()
	self:InitCanSelSkillList(true)
end

function UISelReJN:OnClickSelSkillFunc(index)
	if index == self._selSkillIndex then return end
	self._selSkillIndex = index
	self:RefreshEnterBtnName()
	self:InitCanSelSkillList()
	local uiSelSkillList = self._uiSelSkillList
	if uiSelSkillList then
		local uiList = uiSelSkillList:GetList()
		uiList:RefreshList()
	end
end

function UISelReJN:OnDrawCanSelSkillCell(list,item,itemdata,itempos)
	local SkillRoot = self:FindWndTrans(item,"SkillRoot")
	local SkillIconTrans = self:FindWndTrans(SkillRoot,"SkillIcon")
	local SkillName = self:FindWndTrans(item,"SkillName")
	local SelMask = self:FindWndTrans(item,"SelMask")
	local Gou = self:FindWndTrans(SelMask,"Gou")
	local Lock = self:FindWndTrans(SelMask,"Lock")

	local skillIconList = self._skillIconList
	if not skillIconList then
		skillIconList = {}
		self._skillIconList = skillIconList
	end

	local skillRefId = itemdata.skillRefId
	local isLock = self:IsCanSelLockStatus(skillRefId)
	local isSel = self:IsCanSelSkillStatus(skillRefId,itemdata.index)
	if isSel then
		isLock = false
	end
	local InstanceID = item:GetInstanceID()
	local baseClass = skillIconList[InstanceID]
	if not baseClass then
		baseClass = SkillIcon:New(self)
	end
	baseClass:Create(SkillIconTrans,skillRefId,function()
		if isLock then return end
		self:OnClickCanSelSkillFunc(itemdata)
	end)
	local skillNameStr
	local skillRef = gModelHero:GetSkillByStarId(skillRefId)
	if skillRef then
		skillNameStr = ccLngText(skillRef.name)
	end
	self:SetWndText(SkillName,skillNameStr)

	local isShowMask = isSel or isLock
	CS.ShowObject(Gou,isSel)
	CS.ShowObject(Lock,isLock)
	CS.ShowObject(SelMask,isShowMask)
end

function UISelReJN:RefreshEnterBtnName()
	local haveNext = self:IsHaveNextSelSkill()
	local textId = haveNext and 24814 or 24815
	self:SetWndButtonText(self.mEnterBtn,ccClientText(textId))
end

function UISelReJN:GetAllSelSkillInfoList()
	local selSkillInfoList = {}
	local refId = self._itemRefId
	if refId then
		local runeSelInfo = gModelItem:GetRuneSelTypeDataByRefId(refId)
		if runeSelInfo then
			local skillGroup = runeSelInfo.skillGroup
			local sort = 0
			for i,skillGroupId in ipairs(skillGroup) do
				local skillSplitInfo = gModelRune:GetRuneSkillGroupSplitInfoByRefId(skillGroupId)
				if skillSplitInfo then
					local qualityNum = skillSplitInfo.qualityNum
					for idx,val in ipairs(qualityNum) do
						local num = val.num
						for index = 1,num do
							sort = sort + 1
							table.insert(selSkillInfoList,{
								quality = val.quality,
								skillGroupId = skillGroupId,
								index = sort,
								sort = sort
							})
						end
					end
				end
			end
		end
	end
	return selSkillInfoList
end

function UISelReJN:GetSelSkillKeyList()
	local selIndexSkillList = {}
	local pSelSkillList = self._pSelSkillList
	for skillGroupId,selSkillInfo in pairs(pSelSkillList) do
		for index,skillGroupInfo in pairs(selSkillInfo) do
			local skillRefId = skillGroupInfo.skillRefId
			selIndexSkillList[skillRefId] = skillGroupInfo
		end
	end
	return selIndexSkillList
end

function UISelReJN:InitCanSelSkillList(click)
	local list = self:GetCanSelSkillLIst()
	local uiSkillList = self._uiSkillList
	if uiSkillList then
		if click then
			uiSkillList:RefreshData(list)
		else
			uiSkillList:RefreshList(list)
			local uiList = uiSkillList:GetList()
			uiList:RefreshList(UIListWrap.RefreshMode.Solid)
		end
	else
		uiSkillList = self:GetUIScroll("uiSkillList")
		self._uiSkillList = uiSkillList
		uiSkillList:Create(self.mSkillList,list,function(...) self:OnDrawCanSelSkillCell(...) end,UIItemList.WRAP,false)
		local uiList = uiSkillList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UISelReJN:GetSelSkillIndexList()
	local selIndexSkillList = {}
	local pSelSkillList = self._pSelSkillList
	for skillGroupId,selSkillInfo in pairs(pSelSkillList) do
		for index,skillGroupInfo in pairs(selSkillInfo) do
			selIndexSkillList[index] = skillGroupInfo
		end
	end
	return selIndexSkillList
end

------------------------------------------------------------------
return UISelReJN


