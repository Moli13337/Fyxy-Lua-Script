---
--- Created by Administrator.
--- DateTime: 2025/6/10 15:02:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandPrepareRwd:LWnd
local UIBrandPrepareRwd = LxWndClass("UIBrandPrepareRwd", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandPrepareRwd:UIBrandPrepareRwd()
	self.boxSelect = {}
	self.selBoxIndx = gModelBadge.selectIndex
	self.randomSelNum = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandPrepareRwd:OnWndClose()
	self.boxSelect = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandPrepareRwd:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandPrepareRwd:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:_InitEventClick()
	self:InitFixedReward()
	self:InitSelReward()
	self:UpdateBoxSelect()
end
function UIBrandPrepareRwd:InitFixedReward()
	local itemList = gModelBadge.fixedReward
	self.boxSelect[#itemList+1] = self.mJumpAniBgGou
	local uiList = self:FindUIScroll("mFixedRwdList")
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll("mFixedRwdList")
		uiList:Create(self.mFixedRwdList, itemList, function(...)
			self:FixedRwdItem(...)
		end)
		uiList:EnableScroll(true, true)
	end
end

function UIBrandPrepareRwd:FixedRwdItem(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item, "Icon")
	local JumpAniBg = self:FindWndTrans(item, "JumpAniBg")
	self.boxSelect[itempos] = self:FindWndTrans(JumpAniBg,"JumpAniBgGou")
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	-- local itype = LItemTypeConst.TYPE_BADGE
	local ref = GameTable.BadgeLuckRef[itemdata]
	local reward = LxDataHelper.ParseItem_4(ref.reward)
	baseClass:Create(Icon)
	-- baseClass:SetCommonReward(itype, itemdata)
	baseClass:SetCommonItemdata(reward)
	baseClass:DoApply()
	local badgeRef = GameTable.BadgeRef[itemdata]
	self:SetTextTile(item,badgeRef and ccLngText(badgeRef.name) or "")
	CS.ShowObject(self.boxSelect[itempos],self.boxSelect==itempos)
	self:SetWndClick(JumpAniBg,function()
		self.selBoxIndx = itempos
		self:UpdateBoxSelect()
	end)
	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(reward,{forceNoShowBtn = true})
	end)
end

function UIBrandPrepareRwd:SelRewardtem(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item, "Icon")
	local Empty = self:FindWndTrans(item, "Empty")
	local instanceId = Icon:GetInstanceID()
	CS.ShowObject(Empty,not itemdata.refId )
	if itemdata.refId then
		local baseClass = self:GetCommonIcon(instanceId)
		-- local itype = LItemTypeConst.TYPE_BADGE
		local ref = GameTable.BadgeLuckRef[itemdata.refId]
		local reward = LxDataHelper.ParseItem_4(ref.reward)
		baseClass:Create(Icon)
		-- baseClass:SetCommonReward(itype, itemdata.refId)
		baseClass:SetCommonItemdata(reward)
		baseClass:DoApply()
		local ref = GameTable.BadgeRef[itemdata.refId]
		self:SetTextTile(item,ccLngText(ref.name))
	else
		self:DeleteCommonIcon(instanceId)
		self:SetTextTile(item,ccClientText(47542))
	end

	self:SetWndClick(item,function()
		-- if itemdata.refId then
		-- 	GF.OpenWnd("UIBrandTips",{refId = itemdata.refId})
		-- else
		-- end
		GF.OpenWnd("UIBrandPrepareSel",{func = function(selList)
			self.randomSelNum = #selList
			self:GetSelList(selList)
			self:InitSelReward()
			self.selBoxIndx = #gModelBadge.fixedReward+1
			self:UpdateBoxSelect()
		end,rwdList = self:GetPrepareRWd(),selList = self.selList})
	end)
end
function UIBrandPrepareRwd:InitSelReward()
	local itemList = self.selList
	local uiList = self:FindUIScroll("mSelRwdList")
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll("mSelRwdList")
		uiList:Create(self.mSelRwdList, itemList, function(...)
			self:SelRewardtem(...)
		end)
		uiList:EnableScroll(true, true)
	end
end
function UIBrandPrepareRwd:GetSelList(selList)
	local randomNum = GameTable.BadgeConfigRef.badgeRandomNum
	local itemList = {}
	for i = 1, randomNum do
		table.insert(itemList,{refId = selList[i]})
	end
	self.selList = itemList
end
function UIBrandPrepareRwd:_InitEventClick()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnOk,function()
		if self.selBoxIndx>0 then
			local fixedNum = GameTable.BadgeConfigRef.badgeFixedNum
			local badgeRandomNum = GameTable.BadgeConfigRef.badgeRandomNum
			if self.selBoxIndx > fixedNum and self.randomSelNum<badgeRandomNum then
				GF.ShowMessage(ccClientText(47569))
				return
			end
			gModelBadge:BadgeSelectRewardReq(self.selList,self.selBoxIndx)
			self:WndClose()
		else
			GF.ShowMessage(ccClientText(47567))
		end
	end)
	self:SetWndClick(self.mJumpAniBg,function()
		self.selBoxIndx = #gModelBadge.fixedReward+1
		self:UpdateBoxSelect()
	end)
end

function UIBrandPrepareRwd:GetPrepareRWd()
	if not self.prepareRwd then
		self.prepareRwd = {}
		local curRound = gModelBadge.round
		local luckRef = GameTable.BadgeLuckRef
		local fixedRwd= gModelBadge:GetFixedRwd(true)
		for _, value in pairs(luckRef) do
			local randomCycle = self:GetRoundMap(value.randomCycle)
			if randomCycle[curRound] and not fixedRwd[value.refId] then
				table.insert(self.prepareRwd,{ref = value, reward = LxDataHelper.ParseItem_4(value.reward),refId = value.refId})
			end
		end
	end
	--local aItemCfg,bItemCfg = nil
	--local itemCfgs = GameTable.PlayerItemRef
	table.sort(self.prepareRwd,function(a, b)
		--aItemCfg =itemCfgs[a.reward.itemId]
		--bItemCfg =itemCfgs[b.reward.itemId]
		--return aItemCfg.order<aItemCfg.order
		return a.refId > b.refId
	end)
	return self.prepareRwd
end
function UIBrandPrepareRwd:GetRoundMap(randomCycle)
	local temps = string.split(randomCycle,"|") or {}
	local list ={}
	for k,v in ipairs(temps) do
		local value = tonumber(v) or 0
		list[value] = value
	end
	return list
end

function UIBrandPrepareRwd:UpdateBoxSelect()
	for index, value in ipairs(self.boxSelect) do
		if value then
			CS.ShowObject(value,self.selBoxIndx == index )
		end
	end
end
function UIBrandPrepareRwd:InitData()
	self:SetWndText(self.mTxtTitle,ccClientText(47540))
	self.rwdCondi = self:GetWndArg("rwdCondi")
	self:SetWndText(self.mTxtDesc,string.replace(ccClientText(47541),self.rwdCondi.itemNum))
	self:SetWndText(self.mTxtIcon,ccClientText(47543))
	self:SetWndButtonText(self.mBtnOk,ccClientText(47527))
	self:SetWndEasyImage(self.mIcon,GameTable.BadgeConfigRef.badgeRandomImg,function()
		CS.ShowObject(self.mIcon,true)
	end,true)
	local selList = gModelBadge.randomReward
	self.randomSelNum = #selList
	self:GetSelList(selList)
end
------------------------------------------------------------------
return UIBrandPrepareRwd