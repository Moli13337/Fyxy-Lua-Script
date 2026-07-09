---
--- Created by Administrator.
--- DateTime: 2025/6/4 20:13:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandStrengthen:LWnd
local UIBrandStrengthen = LxWndClass("UIBrandStrengthen", LWnd)
------------------------------------------------------------------


local PAY_BASE = 1
local PAY_SPECIAL = 2


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandStrengthen:UIBrandStrengthen()
	self.selBaseList = {}
	self.selQualityList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandStrengthen:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandStrengthen:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandStrengthen:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:UpdateInfo()
	self:OnUpdateAttr()
	self:InitCostList()
end

function UIBrandStrengthen:UpdateInfo()
	local info = gModelBadge:GetBadgeInfo(self.refId)
	local starCfg = info and info:GetStarRef()
	local leftSkill = ""
	local rightSkill = ""
	local btnName = 0
	local pos = self.mSkillLeft.anchoredPosition
	if starCfg and starCfg.nextStar>0 then
		CS.ShowObject(self.mItemStar,true)
		CS.ShowObject(self.mSkillRight,true)
		CS.ShowObject(self.mImgArrow,true)
		pos.x = -147
		local skillRef = gModelSkill:GetSkillRef(starCfg.skill)
		if skillRef then
			leftSkill = ccLngText(skillRef.description)
		end
		self:SetComStar(self.mComStarLeft, starCfg.star)

		starCfg = GameTable.BadgeStarRef[starCfg.nextStar]
		skillRef = gModelSkill:GetSkillRef(starCfg.skill)
		if skillRef then
			rightSkill = ccLngText(skillRef.description)
		end
		self:SetComStar(self.mComStarRight, starCfg.star)
		CS.ShowObject(self.mComStarRight,true)
		btnName = 47520
	else
		CS.ShowObject(self.mItemStar,info and true or false)
		self:SetComStar(self.mComStarLeft,starCfg and starCfg.star)
		CS.ShowObject(self.mAttrArrow,false)
		CS.ShowObject(self.mComStarRight,false)
		CS.ShowObject(self.mSkillRight,false)
		CS.ShowObject(self.mImgArrow,false)
		pos.x = 0
		if info then
			local skillRef = starCfg and gModelSkill:GetSkillRef(starCfg.skill)
			leftSkill = skillRef and ccLngText(skillRef.description)
			btnName = 43718
		else--未激活
			local starRefs = gModelBadge:GetBadgeStarRef(self.refId)
			starCfg = starRefs[1]
			local skillRef = starCfg and gModelSkill:GetSkillRef(starCfg.skill)
			leftSkill = skillRef and  ccLngText(skillRef.description)
			btnName = 13120
		end
	end
	self.mSkillLeft.anchoredPosition = pos
	self:SetWndText(self.mDescLeft,leftSkill)
	self:SetWndText(self.mDescRight,rightSkill)
	self:SetWndText(self.mTxtTitle,ccClientText(info and 47553 or 47555))
	self:SetWndText(self.mTxtAttrTitle,ccClientText(47555))
	self:SetWndButtonText(self.mUpLvBtn,ccClientText(btnName))

	local baseClass = self:GetCommonIcon(self.mCommonUI)
	baseClass:Create(self.mCommonUI)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_BADGE, self.refId,1)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetWndClick(self.mCommonUI,function()
		GF.OpenWnd("UIBrandTips",{refId = self.refId,noShowBtn = true})
	end)

end
function UIBrandStrengthen:OnDrawAttrCell(list,item,itemdata,itempos)
	local AttrArrow = self:FindWndTrans(item,"AttrArrow")
	local AttrLeft = self:FindWndTrans(item,"AttrLeft")
	local AttrValue = self:FindWndTrans(item,"AttrValue")
	local leftStr = ""
	local rightStr = ""
	if itemdata.curLv then
		leftStr = string.replace(ccClientText(47521),string.replace(ccClientText(17606),"aa5803",itemdata.curLv))
		rightStr = string.replace(ccClientText(47521),string.replace(ccClientText(17606),"0f6f23",itemdata.newLv))
	elseif itemdata.curStar then
		local lStr = itemdata.curStar>0 and itemdata.curStar or ccClientText(47551)
		leftStr = string.replace(ccClientText(47522),string.replace(ccClientText(17606),"aa5803",lStr))
		local rStr = (itemdata.newStar and itemdata.newStar>0) and itemdata.newStar or ccClientText(47551)
		rightStr = string.replace(ccClientText(47522),string.replace(ccClientText(17606),"0f6f23",rStr))
	end
	self:SetWndText(AttrLeft,leftStr)
	self:SetWndText(AttrValue,rightStr)
	CS.ShowObject(AttrValue,(itemdata.newLv or itemdata.newStar) and true or false)
	CS.ShowObject(AttrArrow,(itemdata.newLv or itemdata.newStar) and true or false)
end

function UIBrandStrengthen:RewardListItem(list, item, itemdata, itempos)
	local AniRoot = self:FindWndTrans(item, "AniRoot")
	local item = self:FindWndTrans(AniRoot, "item")
	local TxtNum = self:FindWndTrans(AniRoot, "TxtNum")
	local IcomNull = self:FindWndTrans(AniRoot, "IcomNull")
	local Icon = self:FindWndTrans(IcomNull, "Icon")
	local RedPoint = self:FindWndTrans(IcomNull,"RedPoint")
	local has,need = 0,itemdata.itemNum
	if itemdata.itemId then
		has = gModelItem:GetNumByRefId(itemdata.itemId)
		local instanceId = item:GetInstanceID()
		local baseClass = self:GetCommonIcon(instanceId)
		baseClass:Create(item)
		baseClass:SetCommonItemdata(itemdata)
		baseClass:EnableShowNum(false)
		baseClass:DoApply()
		CS.ShowObject(IcomNull,false)
	else
		has = itemdata.selNum or 0
		CS.ShowObject(IcomNull,true)
		local quality = GameTable.RarityRef[itemdata.quality]
		self:SetWndEasyImage(IcomNull,quality.iconBg)
	end
	self:SetWndText(TxtNum,string.replace(ccClientText(10249),has,need))
	local color = LUtil.ColorByHex(has>=need and "0f6f23ff" or "b20000ff")
	local xuitxt = self:FindWndText(TxtNum)
	self:SetXUITextColor(xuitxt, color)
	self:SetWndClick(AniRoot,function()
		if itemdata.itemId then
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		else
			GF.OpenWnd("UIBrandStrengthenSel",{
				baseItem = self.selBaseList,
				quality = itemdata.quality,
				itemNum = itemdata.itemNum,
				selList = self.selQualityList[itemdata.quality],
				funcCall = function(selList,selListNum,ownNum)
					if selListNum > 0 then
						self.selQualityList[itemdata.quality] = {
							selList = selList,
							selListNum = selListNum,
							ownNum = ownNum
						}
					end
					self:InitCostList()
				end
			})
		end
	end)
end
function UIBrandStrengthen:InitCostList()
	local info = gModelBadge:GetBadgeInfo(self.refId)
	local itemList = {}
	if info then
		local starCfg = info:GetStarRef()
		local item = LxDataHelper.ParseItem_4(starCfg.nextCostBase)
		table.insert(itemList,item)
		table.insert(self.selBaseList,item)


		local selItems = string.split(starCfg.nextCostSpecial,",")
		for _, value in pairs(selItems) do
			local cost = string.split(value,"=")
			local selList = self.selQualityList[tonumber(cost[1])]
			if selList then
				table.insert(itemList,{quality = tonumber(cost[1]),itemNum = tonumber(cost[2]),selNum = selList.selListNum})
			else
				table.insert(itemList,{quality = tonumber(cost[1]),itemNum = tonumber(cost[2])})
			end
		end
	else
		local ref = GameTable.BadgeRef[self.refId]
		local item = LxDataHelper.ParseItem_4(ref.activateCost)
		table.insert(itemList,item)
	end
	local uiList = self:FindUIScroll("priviRewardList")
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll("priviRewardList")
		uiList:Create(self.mPriviReward, itemList, function(...)
			self:RewardListItem(...)
		end)
		uiList:EnableScroll(true, true)
	end
end

function UIBrandStrengthen:InitData()
	self.refId = self:GetWndArg("refId")

	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mUpLvBtn,function()
		self:OnStrengthen()
	end)
	self:WndEventRecv(EventNames.BADGE_BAG_UPDATE,function (strengthe)
		if strengthe then
			self.selBaseList = {}
			self.selQualityList = {}
			local info = gModelBadge:GetBadgeInfo(self.refId)
			local starCfg = info and info:GetStarRef()
			if starCfg.nextStar<0 then
				self:WndClose()
				return
			end
			self:UpdateInfo()
			self:OnUpdateAttr()
			self:InitCostList()
		end
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:InitCostList()
	end)
end

function UIBrandStrengthen:OnStrengthen()
	local costStr = nil
	local info = gModelBadge:GetBadgeInfo(self.refId)
	local item = nil
	local starCfg
	if info then
		starCfg = info:GetStarRef()
		if starCfg.nextStar<0 then return end
		item = starCfg.nextCostBase
	else
		local ref =GameTable.BadgeRef[self.refId]
		item = ref.activateCost
	end
	item = LxDataHelper.ParseItem_4(item)
	local func = function()
		GF.CloseWndByName("UIBrandTips")
		self:WndClose()
	end
	if not gModelGeneral:CheckItemEnough(item.itemId,item.itemNum,true,nil,nil,nil,func) then  return end
	if starCfg and not string.isempty(starCfg.nextCostSpecial) then
		local selItems = string.split(starCfg.nextCostSpecial,",")
		local needCost = nil
		local needNum = 0
		local quality = nil
		for _, value in pairs(selItems) do
			needCost = string.split(value,"=")
			quality = tonumber(needCost[1])
			needNum = tonumber(needCost[2])
			local selList = self.selQualityList[quality]
			if not selList or (selList.selListNum<needNum and selList.ownNum>=needNum) then
				GF.ShowMessage(ccClientText(47558))
				return
			elseif selList.ownNum < needNum then
				GF.ShowMessage(11335)
				return
			end
			if selList then
				local slist = {}
				--1=道具id=数量
				for i, refId in pairs(selList.selList or {}) do
					slist[refId] = (slist[refId] or 0) + 1
				end
				for refId, num in pairs(slist) do
					local str = string.replace(ccClientText(47559),LItemTypeConst.TYPE_ITEM,refId,num)
					costStr = costStr and costStr..","..str or str
				end
			end
		end
	end
	gModelBadge:BadgeStrengthenStarReq(self.refId,costStr)
end
function UIBrandStrengthen:OnUpdateAttr()
	---@type BadgeInfo
	local info = gModelBadge:GetBadgeInfo(self.refId)
	local attrs = {}
	local starCfg = info and info:GetStarRef()
	if starCfg and (starCfg.nextStar>0) then
		local newStarRef =  GameTable.BadgeStarRef[starCfg.nextStar]
		table.insert(attrs,{curLv = info:GetBadgeLv(),newLv = newStarRef.collegeLv})
		table.insert(attrs,{curStar = starCfg.wearNum,newStar = newStarRef.wearNum})
	else
		local starRefs = gModelBadge:GetBadgeStarRef(self.refId)
		starCfg = starCfg and starCfg or starRefs[1]
		table.insert(attrs,{curLv = starCfg.collegeLv})
		table.insert(attrs,{curStar = starCfg.wearNum})
	end
	local uiAttrList = self:GetUIScroll("PetLvAttrList")
	uiAttrList:Create(self.mListAttrs,attrs,function(...) self:OnDrawAttrCell(...) end)
end
------------------------------------------------------------------
return UIBrandStrengthen