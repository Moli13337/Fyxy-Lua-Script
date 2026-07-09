---
--- Created by LCM.
--- DateTime: 2024/3/4 11:32:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReAttrSel:LWnd
local UIReAttrSel = LxWndClass("UIReAttrSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReAttrSel:UIReAttrSel()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReAttrSel:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReAttrSel:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReAttrSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:Refresh()
end

function UIReAttrSel:GetSelAttrList()
	local list = {}
	local itemRefId = self._itemRefId
	if itemRefId then
		local pSelAttrList = self._pSelAttrList
		if not pSelAttrList then
			pSelAttrList = {}
			self._pSelAttrList = pSelAttrList
		end
		local runeSelInfo = gModelItem:GetRuneSelTypeDataByRefId(itemRefId)
		if runeSelInfo then
			local attrGroup = runeSelInfo.attrGroup or {}
			for i,attrGroupId in ipairs(attrGroup) do
				local data = {}
				local selInfo = pSelAttrList[attrGroupId]
				local isSel = selInfo ~= nil
				if isSel then
					for attrRefId,v in pairs(selInfo) do
						data.attrRefId = v.attrRefId
						data.attrType = v.attrType
						data.attrVal = v.attrVal
					end
				else
					data.index = i
				end
				data.isSel = isSel
				table.insert(list,data)
			end
		end
	end
	return list
end

function UIReAttrSel:OnClickEnteBtnFunc()
	local func = self._func
	if func then
		func(self._pSelAttrList)
	end
	self:WndClose()
end

function UIReAttrSel:InitSelAttrList()
	local list = self:GetSelAttrList()

	local uiSelAttrList = self._uiSelAttrList
	if uiSelAttrList then
		uiSelAttrList:RefreshList(list)
	else
		uiSelAttrList = self:GetUIScroll("uiSelAttrList")
		self._uiSelAttrList = uiSelAttrList
		uiSelAttrList:Create(self.mSelAttrList,list,function(...) self:OnDrawSelAttrCell(...) end)
	end
end

function UIReAttrSel:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function() self:OnClickEnteBtnFunc() end)
end

function UIReAttrSel:InitAttrList()
	local list = self:GetAttrList()
	local uiAttrShowList = self._uiAttrShowList
	if uiAttrShowList then
		uiAttrShowList:RefreshList(list)
	else
		uiAttrShowList = self:GetUIScroll("uiAttrShowList")
		self._uiAttrShowList = uiAttrShowList
		uiAttrShowList:Create(self.mAttrShowList,list,function(...) self:OnDrawAttrShowCell(...) end,UIItemList.WRAP)
	end
end

function UIReAttrSel:CreateAttrInfo(attrInfo)
	local AttrIcon = attrInfo.AttrIcon
	local AttrName = attrInfo.AttrName
	local AttrNum = attrInfo.AttrNum

	local refId = attrInfo.attrRefId
	local attrType = attrInfo.attrType
	local attrVal = attrInfo.attrVal

	local icon = gModelHero:GetAttributeIconById(refId)
	self:SetWndEasyImage(AttrIcon,icon,function() CS.ShowObject(AttrIcon,true) end)
	local name = gModelHero:GetAttributeNameById(refId)
	--local nameStr = string.replace(ccClientText(18315),name)
	self:SetWndText(AttrName,name)
	local valStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,attrType,attrVal)
	self:SetWndText(AttrNum,valStr)
end

function UIReAttrSel:GetCanSelAttrList(selAttrList)
	selAttrList = selAttrList or {}
	local list = {}
	for i,v in ipairs(selAttrList) do
		local attrGroupId = v.attrGroupId
		table.insert(list,{
			attrType = v.attrType,
			attrRefId = v.attrRefId,
			attrVal = v.attrVal,
			refId = v.refId,
			attrGroupId = attrGroupId,
		})
	end
	return list
end

function UIReAttrSel:IsAttrRefIdSel(attrGroupId,refId)
	local pSelAttrList = self._pSelAttrList
	if not pSelAttrList then
		pSelAttrList = {}
		self._pSelAttrList = pSelAttrList
	end
	local attrGroupInfo = pSelAttrList[attrGroupId]
	if not attrGroupInfo then
		return false
	end
	return attrGroupInfo[refId] ~= nil or false
end

function UIReAttrSel:InitMsg()
end

function UIReAttrSel:OnDrawCanSelAttrCell(list,item,itemdata,itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrNum = self:FindWndTrans(item,"AttrNum")
	local GouBg = self:FindWndTrans(item,"GouBg")
	local Gou = self:FindWndTrans(GouBg,"Gou")

	local refId = itemdata.attrRefId
	local attrType = itemdata.attrType
	local attrVal = itemdata.attrVal

	self:CreateAttrInfo({
		AttrIcon = AttrIcon,
		AttrName = AttrName,
		AttrNum = AttrNum,
		attrRefId = refId,
		attrType = attrType,
		attrVal = attrVal,
	})

	local attrGroupId = itemdata.attrGroupId
	local isSel = self:IsAttrRefIdSel(attrGroupId,refId)
	CS.ShowObject(Gou,isSel)

	self:SetWndClick(GouBg,function()
		self:OnClickGouBgFunc(itemdata)
	end)
end

function UIReAttrSel:OnClickGouBgFunc(itemdata)
	local pSelAttrList = self._pSelAttrList
	if not pSelAttrList then
		pSelAttrList = {}
		self._pSelAttrList = pSelAttrList
	end
	local attrRefId = itemdata.attrRefId
	local attrGroupId = itemdata.attrGroupId
	local selAttrTransList = self._selAttrTransList
	if not selAttrTransList then return end
	local attrGroupIdInfo = {}
	attrGroupIdInfo[attrRefId] = {
		attrRefId = attrRefId,
		attrType = itemdata.attrType,
		attrVal = itemdata.attrVal,
		refId = itemdata.refId,
		attrGroupId = attrGroupId,
	}
	pSelAttrList[attrGroupId] = attrGroupIdInfo

	self:InitSelAttrList()

	local uiListKey = selAttrTransList[attrGroupId]
	local uiAttrShowList = self:FindUIScroll(uiListKey)
	if uiAttrShowList then
		local uiList = uiAttrShowList:GetList()
		uiList:RefreshList()
	end
end

function UIReAttrSel:GetAttrList()
	local list = {}
	local itemRefId = self._itemRefId
	if itemRefId then
		local runeSelInfo = gModelItem:GetRuneSelTypeDataByRefId(itemRefId)
		if runeSelInfo then
			local attrGroup = runeSelInfo.attrGroup or {}
			for i,attrGroupId in ipairs(attrGroup) do
				local attrList = gModelRune:GetAttrGroupAttrListByAttrGroupId(attrGroupId)
				if attrList then
					local tAttrList = {}
					for idx,val in ipairs(attrList) do
						local refId = val.refId
						for _i,_v in ipairs(val.attr) do
							table.insert(tAttrList,{
								attrType = _v.attrType,
								attrRefId = _v.attrRefId,
								attrVal = _v.attrVal,
								attrGroupId = attrGroupId,
								refId = refId,
							})
						end
					end
					table.insert(list,{
						index = i,
						attrList = tAttrList,
						attrGroupId = attrGroupId,
					})
				end
			end
		end
	end
	return list
end

function UIReAttrSel:InitCanSelAttrList(trans,selAttrList,attrGroupId)
	selAttrList = selAttrList or {}
	local list = self:GetCanSelAttrList(selAttrList)
	local key = trans:GetInstanceID()

	local selAttrTransList = self._selAttrTransList
	if not selAttrTransList then
		selAttrTransList = {}
		self._selAttrTransList = selAttrTransList
	end
	selAttrTransList[attrGroupId] = key

	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawCanSelAttrCell(...) end)
	end
end

function UIReAttrSel:OnDrawSelAttrCell(list,item,itemdata,itempos)
	local ShowAttrDiv = self:FindWndTrans(item,"ShowAttrDiv")
	local NoSelDiv = self:FindWndTrans(item,"NoSelDiv")

	local isSel = itemdata.isSel
	CS.ShowObject(ShowAttrDiv,isSel)
	CS.ShowObject(NoSelDiv,not isSel)
	if isSel then
		local AttrIcon = self:FindWndTrans(ShowAttrDiv,"AttrIcon")
		local AttrName = self:FindWndTrans(ShowAttrDiv,"AttrName")
		local AttrNum = self:FindWndTrans(ShowAttrDiv,"AttrNum")
		self:CreateAttrInfo({
			AttrIcon = AttrIcon,
			AttrName = AttrName,
			AttrNum = AttrNum,
			attrRefId = itemdata.attrRefId,
			attrType = itemdata.attrType,
			attrVal = itemdata.attrVal,
		})
	else
		local NoSelDesc = self:FindWndTrans(NoSelDiv,"NoSelDesc")
		local index = itemdata.index
		local indexStr = string.replace(ccClientText(24816),index)
		self:SetWndText(NoSelDesc,indexStr)
	end
end

function UIReAttrSel:Refresh()
	self:InitSelAttrList()
	self:InitAttrList()
end

function UIReAttrSel:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(24830))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(24815))
end

function UIReAttrSel:InitData()
	self._itemRefId = self:GetWndArg("itemRefId")
	self._func = self:GetWndArg("func")
	local selAttrList = self:GetWndArg("selAttrList") or {}

	local pSelAttrList = {}
	for attrGroupId,selAttrInfo in pairs(selAttrList) do
		local attrGroupIdInfo = {}
		pSelAttrList[attrGroupId] = attrGroupIdInfo
		for k,v in pairs(selAttrInfo) do
			local attrRefId = v.attrRefId
			attrGroupIdInfo[attrRefId] = {
				attrRefId = attrRefId,
				attrType = v.attrType,
				attrVal = v.attrVal,
				attrGroupId = attrGroupId,
				refId = v.refId
			}
		end
	end
	self._pSelAttrList = pSelAttrList

	self._selAttrTransList = {}
end

function UIReAttrSel:OnDrawAttrShowCell(list,item,itemdata,itempos)
	local TopDiv = self:FindWndTrans(item,"TopDiv")
	local SelAttrList = self:FindWndTrans(item,"SelAttrList")

	local TextTitle2 = self:FindWndTrans(TopDiv,"TextTitle2")
	local index = itemdata.index
	local indexStr = string.replace(ccClientText(24816),index)
	self:SetTextTile(TextTitle2,indexStr)

	local attrGroupId = itemdata.attrGroupId
	self:InitCanSelAttrList(SelAttrList,itemdata.attrList,attrGroupId)
end

------------------------------------------------------------------
return UIReAttrSel


