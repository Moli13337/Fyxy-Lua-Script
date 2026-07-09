---
--- Created by Administrator.
--- DateTime: 2024/11/14 18:32:09
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
---@class UISubDivineStar:LChildWnd
local UISubDivineStar = LxWndClass("UISubDivineStar", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineStar:UISubDivineStar()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineStar:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineStar:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineStar:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self.refId = self:GetWndArg("refId")
	self.divineCfg = gModelDivineWeapon:GetDivineWeaponRef(self.refId)
	self:InitStatic()
	self:UpdateStar()
	self:UpdateAttr()
	self:UpdateCost()
	self:UpdateRed()
end


function UISubDivineStar:OnDrawAttrCell(list,item,itemdata,itempos)
	local lAttrIcon = self:FindWndTrans(item,"LeftAttr/AttrIcon")
	local lAttrName = self:FindWndTrans(item,"LeftAttr/AttrName")
	local lAttrValue = self:FindWndTrans(item,"LeftAttr/AttrValue")
	local rAttrIcon = self:FindWndTrans(item,"RightAttr/AttrIcon")
	local rAttrName = self:FindWndTrans(item,"RightAttr/AttrName")
	local rAttrValue = self:FindWndTrans(item,"RightAttr/AttrValue")
	local RightAttr = self:FindWndTrans(item,"RightAttr")
	local arrow = self:FindWndTrans(item,"Image")
	local numType,refId,value = itemdata.type,itemdata.refId,itemdata.value
	local right = not not self.nexAttrMap[refId]

	local icon = gModelHero:GetAttributeIconById(refId)
	if lAttrIcon then self:SetWndEasyImage(lAttrIcon,icon) end
	local name = gModelHero:GetAttributeNameById(refId)
	if lAttrName then self:SetWndText(lAttrName,name) end
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,value)
	-- if type(valueStr) == "number" then
	-- 	valueStr = LUtil.NumberCoversion(valueStr)
	-- end
	if lAttrValue then self:SetWndText(lAttrValue,"+"..valueStr) end

	CS.ShowObject(RightAttr,right)
	CS.ShowObject(arrow,right)
	if right then
		self:SetWndEasyImage(rAttrIcon,icon)
		self:SetWndText(rAttrName,name)
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,numType,self.nexAttrMap[refId][numType])
		-- if type(valueStr) == "number" then
		-- 	valueStr = LUtil.NumberCoversion(valueStr)
		-- end
		self:SetWndText(rAttrValue,"<color=#c57313>+"..valueStr.."</color>")
	end
end
function UISubDivineStar:UpdateCost()
	local cost = gModelDivineWeapon:GetUpStarCost(self.refId)
	self.cost = cost
	CS.ShowObject(self.mTxtCost,not not cost)
	CS.ShowObject(self.mBtnStar,not not cost)
	CS.ShowObject(self.mImgFlag,not not cost)
	CS.ShowObject(self.mCostItem,not not cost)
	CS.ShowObject(self.mImgFull,not cost)
	if not cost then return end --满星
	local curNum =  gModelItem:GetNumByRefId(cost.itemId)
	local color = curNum>=cost.itemNum and "#38962e" or "#FF2010"
	self:SetWndText(self.mTxtCost,string.replace("<color=#a1#>#a2#</color>/#a3#",color,curNum,cost.itemNum))
	self.cost.isUp = curNum>=cost.itemNum

	local instanceId = self.mCostItem:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(self.mCostItem)

	baseClass:SetCommonReward(cost.itemType, cost.itemId, cost.itemNum)
	baseClass:DoApply()
	self:SetWndClick(self.mCostItem,function()
        --gModelGeneral:ShowCommonItemTipWnd(cost)
		gModelGeneral:OpenGetWayWnd({ itemId = cost.itemId })
	end)
end

function UISubDivineStar:InitStatic()
	local quality = GameTable.RarityRef[self.divineCfg.quality]
	self:SetWndText(self.mTxtTitle,ccLngText(self.divineCfg.name))
	self:SetTextTile(self.mImgFull,ccClientText(14437))
	LxUiHelper.SetXTextColor(self.mTxtTitle,LUtil.ColorByHex(quality.nameColor))
	self:SetWndText(self.mTxtTips,ccClientText(46112))
	self:SetWndButtonText(self.mBtnStar,ccClientText(43711))
	self:SetWndClick(self.mBtnStar,function() self:OnClickUpStar() end)
	self:SetWndClick(self.mSkillIcon,function() GF.OpenWnd("UIDivineWeaponTips",{refId = self.refId}) end)

	-- self:SetWndEasyImage(self.mRightItem,self.divineCfg.icon,nil,true)
	-- self:SetWndEasyImage(self.mLeftItem,self.divineCfg.icon,nil,true)
	local ins = self.mLeftEffect:GetInstanceID()
	self:CreateWndEffect(self.mLeftEffect,self.divineCfg.effect,ins, 100, false, false)
	self:CreateWndEffect(self.mRightEffect,self.divineCfg.effect,self.mRightEffect:GetInstanceID(), 100, false, false)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function()
		self:UpdateStar()
		self:UpdateAttr()
		self:UpdateCost()
		self:UpdateRed()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:UpdateCost()
		self:UpdateRed()
	end)
end

function UISubDivineStar:UpdateAttr()
	local skillId = gModelDivineWeapon:GetSkillId(self.refId)
	local skillCfg = GameTable.SnakeSkillRef[skillId]
	self:SetWndEasyImage(self.mSkillIcon,skillCfg.icon)
	self:SetTextTile(self.mSkillLv,skillCfg.level)

	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	local level = info and info.level
	self:SetWndText(self.mTxtLv,level and string.replace(ccClientText(14734),level) or ccClientText(46109))
	local uiAttrList = self._uiAttrList
	local attrList,nexAttrList = gModelDivineWeapon:GetStarAttr(self.refId)
	local nexAttrMap =  {}
	for _, value in ipairs(nexAttrList or {}) do
		if not nexAttrMap[value.refId] then nexAttrMap[value.refId] = {} end
		nexAttrMap[value.refId][value.type] = value.value
	end
	self.nexAttrMap = nexAttrMap
	if not attrList then --最高級預覽
		local lvRefs = gModelDivineWeapon:GetDiviWeaponLvRefByRefId(self.refId)
		attrList = LxDataHelper.ParseAttrList(lvRefs[#lvRefs].attr)
	end
	if uiAttrList then
		uiAttrList:RefreshList(attrList)
	else
		uiAttrList = self:GetUIScroll("childDivineStar")
		self._uiAttrList = uiAttrList
		uiAttrList:Create(self.mListAttrs,attrList,function(...) self:OnDrawAttrCell(...) end)
	end
end
function UISubDivineStar:OnClickUpStar()
	if self.cost and self.cost.isUp then
		gModelDivineWeapon:OnDivineWeaponUpStarReq(self.refId)
	else
		if self.cost then gModelGeneral:OpenGetWayWnd({ itemId = self.cost.itemId,jumpBackCB = function()
			GF.CloseWndByName("UIDivineWeaponInfoWin")
		end}) end
	end
end
function UISubDivineStar:UpdateRed()
	local isShow = gModelDivineWeapon:DivineWeaponStarRedById(self.refId)
	self:SetRed(self.mBtnStar,isShow)
end

function UISubDivineStar:UpdateStar()
	local sizeDe = self.mLeftStarBg.sizeDelta
	local maxStar = gModelDivineWeapon:GetMaxStar(self.refId)
	local curStar = gModelDivineWeapon:GetCurStar(self.refId) or 0
	sizeDe.x = 40*maxStar
	self.mLeftStarBg.sizeDelta = sizeDe
	self.mRightStarBg.sizeDelta = sizeDe
	sizeDe = self.mLeftStar.sizeDelta
	sizeDe.x = 40* curStar
	self.mLeftStar.sizeDelta = sizeDe
	if maxStar==curStar then
		CS.ShowObject(self.mRightItemParent,false)
		CS.ShowObject(self.mImgArrow,false)
		local pos = self.mLeftItemParent.anchoredPosition
		pos.x = 0
		self.mLeftItemParent.anchoredPosition = pos
	else
		sizeDe = self.mRightStar.sizeDelta
		sizeDe.x = 40*(curStar+1)
		self.mRightStar.sizeDelta = sizeDe
	end
end
------------------------------------------------------------------
return UISubDivineStar