---
--- Created by Administrator.
--- DateTime: 2024/11/14 20:43:50
---
local LWnd = LWnd
---@class UIDivineUpLvPop:LWnd
local UIDivineUpLvPop = LxWndClass("UIDivineUpLvPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineUpLvPop:UIDivineUpLvPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineUpLvPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineUpLvPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineUpLvPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.refId = self:GetWndArg("refId")
	self.divineCfg = gModelDivineWeapon:GetDivineWeaponRef(self.refId)
	self:InitStatic()
	self:UpdateAttrLevel()
	self:UPdateCost()
	self:UpdateAttrs()
end
function UIDivineUpLvPop:OnClickUp()
	local isUp ,needStar = gModelDivineWeapon:DivineWeaponUpRedById(self.refId)
	if isUp then
		gModelDivineWeapon:OnDivineWeaponUpLevelReq(self.refId)
	elseif not isUp and needStar then
		GF.ShowMessage(string.replace(ccClientText(46178),needStar))
	else
		if self.cost then gModelGeneral:OpenGetWayWnd({ itemId = self.cost.itemId,jumpBackCB = function()
			GF.CloseWndByName("UIDivineWeaponInfoWin")
			GF.CloseWndByName("UIDivineUpLvPop")
		end}) end
	end
end
function UIDivineUpLvPop:UpdateAttrLevel()
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	local curLv = info and info.level or 0
	self:SetWndText(self.mTxtCurLv,string.replace(ccClientText(14734),curLv))
	self:SetWndText(self.mTxtNextLv,string.replace(ccClientText(14735),curLv+1))
	local curAttr,nextAttr = gModelDivineWeapon:GetLevelAttr(self.refId)
	local curAttrStr = ""
	local leng = curAttr and #curAttr or 0
	local add = gModelDivineWeapon:GetDivineLevelAttrAdd(self.refId)
	for index, value in ipairs(curAttr or {}) do
		local name = gModelHero:GetAttributeNameById(value.refId)
		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(value.refId,value.type,value.value+(math.floor(value.value*(add/100))))
		curAttrStr = curAttrStr..name.."："..val
		if index ~= leng then curAttrStr = curAttrStr.."\n" end
	end
	self:SetWndText(self.mTxtCurAttr,curAttrStr)
	curAttrStr = ""
	local leng = nextAttr and #nextAttr or 0
	for index, value in ipairs(nextAttr or {}) do
		local name = gModelHero:GetAttributeNameById(value.refId)
		local val = gModelHero:GetAttributeValueNoNameByIdAndVal(value.refId,value.type,value.value+(math.floor(value.value*(add/100))))
		curAttrStr = curAttrStr..name.."：<color=#c57313>"..val.."</color>"
		if index ~= leng then curAttrStr = curAttrStr.."\n" end
	end
	self:SetWndText(self.mTxtNextAttr,curAttrStr)
	if not nextAttr then
		CS.ShowObject(self.mImgArrow,false)
		CS.ShowObject(self.mTxtNextLv,false)
		local pos = self.mTxtCurLv.anchoredPosition
		pos.x = 0
		self.mTxtCurLv.anchoredPosition = pos
		local alignmentEnum = LxUiHelper.GetTMPAlignment()
		if alignmentEnum then
			local uiText = self:FindWndText(self.mTxtCurAttr)
			local uiText2 = self:FindWndText(self.mTxtCurLv)
			uiText.alignment = alignmentEnum
			uiText2.alignment = alignmentEnum
			alignmentEnum = LxUiHelper.GetTMPAlignment(2)
			uiText.alignment = alignmentEnum
			uiText2.alignment = alignmentEnum
		end
	end

	local curMaxLv = gModelDivineWeapon:GetStarUpLvMaxLimit(info.star)
	self:SetWndText(self.mTxtLvTips,string.replace(ccClientText(46171),curMaxLv or 0))
end

function UIDivineUpLvPop:UpdateAttrs()
	local uiAttrList = self._uiAttrList
	local list = gModelDivineWeapon:GetDiviWeaponLvAddRefByRefId(self.refId) or {}
	self.info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	if uiAttrList then
		uiAttrList:RefreshList(list)
	else
		uiAttrList = self:GetUIScroll("DivineUpLv")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,list,function(...) self:OnDrawAttrCell(...) end)
	end
	uiAttrList:EnableScroll(true)
	local pos = 1
	local curLv = self.info and self.info.level or 0
	for index, value in ipairs(list) do
		if value.level>curLv then break end
		pos = index
	end
	uiAttrList:MoveToPos(math.max(1,pos-1))
	CS.ShowObject(self.mEmptyText, #list == 0)
end

function UIDivineUpLvPop:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrName = self:FindWndTrans(item,"AttrName")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	self:SetWndText(AttrName,"Lv."..itemdata.level)
	self:SetWndText(AttrValue,ccLngText(itemdata.desc))
	local color = itemdata.level > (self.info and self.info.level or 0)  and "7c7c7cff" or "38962eff"
	self:SetXUITextTransColor(AttrName,color)
	self:SetXUITextTransColor(AttrValue,color)
end
function UIDivineUpLvPop:UPdateCost()
	local cost = gModelDivineWeapon:GetLevelCost(self.refId)
	self.cost = cost
	CS.ShowObject(self.mBtnUpLv,not not cost)
	CS.ShowObject(self.mTxtCost,not not cost)
	CS.ShowObject(self.mCostItem,not not cost)
	CS.ShowObject(self.mImgFull, not cost)
	self:SetRed(self.mBtnUpLv,false)
	if not cost then return end--滿級
	local curNum  = cost.itemId and gModelItem:GetNumByRefId(cost.itemId) or 0
	local needNum = cost.itemNum or 0
	local color = curNum>=needNum and "#38962e" or "#FF2010"
	self.cost.isUp = curNum>=needNum
	self:SetWndText(self.mTxtCost,string.replace("<color=#a1#>#a2#</color>/#a3#",color,curNum,needNum))

	local instanceId = self.mCostItem:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(self.mCostItem)
	local isRed = gModelDivineWeapon:DivineWeaponUpRedById(self.refId)
	self:SetRed(self.mBtnUpLv,isRed)

	baseClass:SetCommonReward(cost.itemType, cost.itemId, needNum)
	baseClass:DoApply()
	self:SetWndClick(self.mCostItem,function()
        gModelGeneral:ShowCommonItemTipWnd(cost)
	end)
end

function UIDivineUpLvPop:InitStatic()
	self:SetWndText(self.mLblBiaoti,ccClientText(46110))
	self:SetTextTile(self.mImgFull,ccClientText(10044))
	self:SetWndButtonText(self.mBtnUpLv,ccClientText(46172))
	self:SetWndClick(self.mBtnUpLv,function() self:OnClickUp() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndEasyImage(self.mItemIcon,self.divineCfg.icon,nil,true)
	self:SetWndText(self.mTxtName,ccLngText(self.divineCfg.name))
	local quality = GameTable.RarityRef[self.divineCfg.quality]
	LxUiHelper.SetXTextColor(self.mTxtName,LUtil.ColorByHex(quality.nameColor))
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:UPdateCost()
	end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function()
		self:UpdateAttrLevel()
		self:UPdateCost()
		self:UpdateAttrs()
	end)
end


------------------------------------------------------------------
return UIDivineUpLvPop