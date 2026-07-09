---
--- Created by Administrator.
--- DateTime: 2025/5/28 21:23:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandTips:LWnd
local UIBrandTips = LxWndClass("UIBrandTips", LWnd)
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

local typeof = typeof
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandTips:UIBrandTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandTips:OnWndClose()
	local callFunc = self.callFunc
	self.callFunc = nil
	if callFunc then
		callFunc()
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitUIBtnClick()
	self:InitData()
	self:UpdateTop()
	self:RefreshStarList()
end

-- 刷新灵魂星级列表
function UIBrandTips:RefreshStarList()
	CS.ShowObject(self.mBadgeDiv,true)
	local list = gModelBadge:GetBadgeStarRef(self.refId)
	local pos = 0
	table.sort(list, function(sA, sB)
		return sA.star < sB.star
	end)
	for i,v in ipairs(list) do
		if self.star == v.star then
			pos = i
			break
		end
	end
	if not self.badgeSkillList then
		local uiList = self:GetUIScroll("mBadgeSkillList")
		self.badgeSkillList = uiList
		-- local list = gModelBadge:GetBadgeStarRef(self.refId)
		uiList:Create(self.mBadgeSkillList, list, function(...)
			self:OnDrawStarListItem(...)
		end)
		uiList:EnableScroll(true)

		-- self.badgeSkillList:MoveToPos(pos)
		self:ScrollWndList("mBadgeSkillList", pos > 0 and pos - 1 or 0)
	else
		self.badgeSkillList:DrawAllItems()
		self:ScrollWndList("mBadgeSkillList", pos > 0 and pos - 1 or 0)

	end
end

-- 星级列表 item
function UIBrandTips:OnDrawStarListItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache         = {}
		itemCache.txtDesc = CS.FindTrans(item, "TxtDesc")
		itemCache.actStar = CS.FindTrans(item, "Act")
		self:SetComponentCache(instanceID, itemCache)
	end
	local star = itemdata.star
	local actStar =self.star == star
	CS.ShowObject(itemCache.actStar,actStar)
	local starStar = itempos==1 and ccClientText(47547) or string.replace(ccClientText(47548),star)
	local skillRef = gModelSkill:GetSkillRef(itemdata.skill)
	if skillRef then
		local strDesc = ccLngText(skillRef.description)
		local str = not actStar and starStar..strDesc or string.replace(ccClientText(14106),starStar..strDesc)
		self:SetWndText(itemCache.txtDesc, str)
	else
		self:SetWndText(itemCache.txtDesc,"")
	end

	LayoutRebuilder.ForceRebuildLayoutImmediate(item)
	-- local itemSize = item.sizeDelta
	-- local textD = itemCache.txtDesc:GetComponent("YXUIText")
	-- itemSize.y = textD.preferredHeight
	-- item.sizeDelta = itemSize
end
function UIBrandTips:InitData()
	self.callFunc = self:GetWndArg("callFunc")
	self.refId = self:GetWndArg("refId")
	self.fromHero = self:GetWndArg("from")
	self.index = self:GetWndArg("index")
	self.heroId = self:GetWndArg("heroId")
	self.noShowBtn = self:GetWndArg("noShowBtn")
	local showBtnList = not self.noShowBtn
	CS.ShowObject(self.mBtnList,showBtnList)

	CS.ShowObject(self.mTipBg2,false)
	CS.ShowObject(self.mTipBg3,false)

	local layoutElement = self.mBtnBg:GetComponent(typeLayoutElement)
	layoutElement.preferredHeight = showBtnList and 100 or 50

	CS.ShowObject(self.mBtnList,not (self.noShowBtn==true))
	-- CS.ShowObject(self.mBtnBg,not (self.noShowBtn==true))
	if not self.refId then return end
	self.ref = GameTable.BadgeRef[self.refId]

	self:SetTextTile(self.mBadgeTitle,ccClientText(47550))
	self:SetWndText(self.mNameTxt,ccLngText(self.ref.name))
	self:SetWndText(self.mBtnGoToText,ccClientText(44227))
	self:SetWndButtonText(self.mBtnReplace,ccClientText(47509))
	self:SetWndButtonText(self.mBtnFull,ccClientText(43718))
	self:SetWndButtonText(self.mBtnLink,ccClientText(47552))
	local quaId = self.ref.quality
	local heroMessage = gModelItem:GetHeroMessQualityById(quaId)
	if heroMessage then
		self:SetWndEasyImage(self.mHeadImg, heroMessage)
	end
	local color = gModelItem:GetColorByQualityId(quaId)
	if color then
		self:SetXUITextColor(self.mNameTxt, color)
	end
end

function UIBrandTips:UpdateTop()
	local info  = gModelBadge:GetBadgeInfo(self.refId)
	self.star = info and info:GetBadgeStar() or nil
	self.starRef = info and info:GetStarRef()

	local baseClass = self:GetCommonIcon(self.mItemInfo)
	baseClass:Create(self.mItemInfo.transform)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_BADGE, self.refId,1)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetTextTile(self.mDescTitle,ccClientText(47549))
	local str  = ""
	if self.star then
		str = self.star==0 and ccClientText(47547) or string.replace(ccClientText(47548),self.star)
		str = str..string.replace(ccClientText(47521),self.starRef.collegeLv).."，"..
				string.replace(ccClientText(47522),self.starRef.wearNum<0 and ccClientText(47551) or self.starRef.wearNum)
	else
		local starCfgs = gModelBadge:GetBadgeStarRef(self.refId)
		local starCfg = starCfgs[1]
		str = ccClientText(47547)
		str = str..string.replace(ccClientText(47521),starCfg.collegeLv).."，"..
				string.replace(ccClientText(47522),starCfg.wearNum<0 and ccClientText(47551) or starCfg.wearNum)
	end
	self:SetWndText(self.mTxtDesc,str)
	self:SetWndButtonText(self.mBtnStar,self.star and ccClientText(47520) or ccClientText(13120))
	CS.ShowObject(self.mBtnReplace,self.fromHero and self.star)

	local showFull = self.star and self.starRef.nextStar<=0
	CS.ShowObject(self.mBtnFull,showFull)
	if showFull then
		self:SetWndButtonGray(self.mBtnFull,showFull)
	end

	local starRp = false
	local showStar = not self.starRef or self.starRef.nextStar>0
	if showStar then
		starRp = gModelBadge:BadgeActivateRed(self.refId)
		if not starRp and info then
			starRp = info:UpStarRedPoint(gModelBadge:BadgeQualityNum())
		end
	end
	CS.ShowObject(self.mBtnStar,showStar)
	self:SetRed(self.mBtnStar,starRp)
end
function UIBrandTips:InitUIBtnClick()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnStar,function()
		GF.OpenWnd("UIBrandStrengthen",{refId = self.refId})
	end)
	self:SetWndClick(self.mBtnReplace,function()
		GF.OpenWnd("UIBrandWearPop",{heroId = self.heroId,index = self.index})
		self:WndClose()
	end)
	CS.ShowObject(self.mBtnLink ,false)
	self:SetWndClick(self.mBtnLink,function()

	end)
	self:SetWndClick(self.mBtnOrigin,function()
		local cost = LxDataHelper.ParseItem_4(self.ref.activateCost)
		gModelGeneral:OpenGetWayWnd({ itemId = cost.itemId}, LGameUI.UI_SORTLAYER_UIUP)
	end)
	self:WndEventRecv(EventNames.BADGE_BAG_UPDATE,function(strengthe)
		if strengthe then
			self:UpdateTop()
			self:RefreshStarList()
		end
	end)
end


------------------------------------------------------------------
return UIBrandTips