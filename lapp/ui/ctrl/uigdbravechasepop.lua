---
--- Created by BY.
--- DateTime: 2023/10/21 21:25:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveChasePop:LWnd
local UIGdBraveChasePop = LxWndClass("UIGdBraveChasePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveChasePop:UIGdBraveChasePop()
	self._uiListTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveChasePop:OnWndClose()
	LWnd.OnWndClose(self)
	self:ClearCommonIconList(self._uiListTbl)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveChasePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveChasePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdBraveChasePop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnJian,function () self:SetBuyNum(false) end)
	self:SetWndClick(self.mBtnAdd,function () self:SetBuyNum(true) end)
	self:SetWndClick(self.mBtnYellow2,function () self:OnClickConfirm() end)
end

function UIGdBraveChasePop:SetTotalBuyNum(isAll)
	local _currNum = self._currNum
	if isAll then
		_currNum = self._residueNum
	else
		_currNum = self._freeNum
	end
	self._currNum = _currNum
	self:UpdateBuyPrice()
end

function UIGdBraveChasePop:UpdateBuyPrice()
	local itemdata
	local num = self._currNum - self._freeNum
	if num > 0 then
		for i = 1, num do
			local item = gModelGuild:GetGuildBuyNumNeed(i)
			if not itemdata then
				itemdata = item
			else
				itemdata.itemNum = itemdata.itemNum + item.itemNum
			end
		end
	else
		local item = gModelGuild:GetGuildBuyNumNeed(1)
		itemdata = item
		itemdata.itemNum = 0
	end

	self._itemdata = itemdata
	self:SetWndText(self.mGatherText,itemdata.itemNum)
	if itemdata.itemId then
		local ImageTrans = self:FindWndTrans(self.mGatherText,"Image")
		local icon = gModelItem:GetItemImgByRefId(itemdata.itemId)
		self:SetWndEasyImage(ImageTrans,icon)
	end
	self:SetWndText(self.mBuyNumText,self._currNum)

	local braveInfo = gModelGuild:GetGuildBraveInfo()
	local ref = gModelGuild:GetGuildDungeonMonsterRefByRefId(braveInfo.braveId)
	local rewardList = gModelGeneral:GetParseItem_3List(ref.challengeReward)
	local rareNum = self._currNum > 0 and self._currNum or 1
	for i, v in ipairs(rewardList) do
		v.itemNum = v.itemNum * rareNum
	end
	self:InitItemList(self.mAwardList,rewardList)
end

function UIGdBraveChasePop:OnClickConfirm()
	local _currNum = self._currNum
	if _currNum <= 0 then
		GF.ShowMessage(ccClientText(14146))
		return
	end
	local item = self._itemdata
	local num = gModelItem:GetNumByRefId(item.itemId)
	if(num < item.itemNum)then
		gModelGeneral:OpenGetWayWnd({itemId = item.itemId})
		return
	end
	gModelGuild:OnGuildBraveChaseReq(nil,_currNum)
end

function UIGdBraveChasePop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildBraveChaseResp,function (...)
		self:WndClose()
	end)
	self:SetWndToggleDelegate(self.mFreeToggle,function (value)
		if(value)then
			self:SetWndToggleValue(self.mAllToggle,false)
			self:SetTotalBuyNum(false)
		end
	end)
	self:SetWndToggleDelegate(self.mAllToggle,function (value)
		if(value)then
			self:SetWndToggleValue(self.mFreeToggle,false)
			self:SetTotalBuyNum(true)
		end
	end)
end

function UIGdBraveChasePop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(14140))
	self:SetWndText(self.mDesText,ccClientText(14141))
	self:SetWndText(self.mFreeText,ccClientText(14142))
	self:SetWndText(self.mAllText,ccClientText(14143))
	self:SetWndButtonText(self.mBtnYellow2,ccClientText(14144))
	self:InitTextSizeWithLanguage(self.mDesText,-2)

	local braveInfo = gModelGuild:GetGuildBraveInfo()
	local challengeNum = gModelGuild:GetVipBraveAddNum(1)--免费挑战次数
	local battleCount = challengeNum - braveInfo.battleCount + braveInfo.battleBuyCount + braveInfo.extraCount
	local freeNum = battleCount >= 0 and battleCount or 0

	local guyNum = gModelGuild:GetVipBraveAddNum(2)
	local buyNum = guyNum - braveInfo.battleBuyCount

	local allNum = freeNum + buyNum
	self._freeNum = freeNum
	self._residueNum = allNum
	if allNum > 0 then
		self._currNum = 1
	else
		self._currNum = 0
	end
	self:UpdateBuyPrice()
	self:SetWndText(self.mResidueNumText,string.replace(ccClientText(14145),self._residueNum))
end

function UIGdBraveChasePop:InitItemList(root,itemList)
	local instanceId = root:GetInstanceID()
	local uiList = self._uiListTbl[instanceId]
	if not uiList then
		uiList = UIIconEasyList:New()
		self._uiListTbl[instanceId] = uiList
		uiList:Create(self, root)
		--uiList:SetShowNum(false)
		uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
		--uiList:SetShowExtraNum(true, "itemNum")
		uiList:EnableScroll(true,true)
	end
	uiList:RefreshList(itemList)
end

function UIGdBraveChasePop:SetBuyNum(isAdd)
	local _currNum = self._currNum
	if isAdd and _currNum < self._residueNum then
		_currNum = _currNum + 1
	elseif not isAdd and _currNum > 1 then
		_currNum = _currNum - 1
	elseif isAdd then
		GF.ShowMessage(ccClientText(12554))
	end
	self._currNum = _currNum
	self:UpdateBuyPrice()
end
------------------------------------------------------------------
return UIGdBraveChasePop


