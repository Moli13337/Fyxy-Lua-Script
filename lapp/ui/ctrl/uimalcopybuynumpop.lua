---
--- Created by BY.
--- DateTime: 2023/10/18 14:50:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMalCopyBuyNumPop:LWnd
local UIMalCopyBuyNumPop = LxWndClass("UIMalCopyBuyNumPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMalCopyBuyNumPop:UIMalCopyBuyNumPop()
	self._buyNum = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMalCopyBuyNumPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMalCopyBuyNumPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMalCopyBuyNumPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIMalCopyBuyNumPop:GetIsBuyCard()
	local _pages = self.pages
	if not _pages then return end
	local pages = _pages[self._turnPrivilegeEnum]
	local _cardList = pages.entry
	local _privilegeCard = _cardList[1]
	local marketData = _privilegeCard.MarketData
	local personal = marketData.personal
	local personalGoal = marketData.personalGoal
	local isGuy = personal >= personalGoal
	return isGuy
end
function UIMalCopyBuyNumPop:InitEvent()
	self:SetWndClick(self.mBg,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnCancel,function () self:WndClose() end)
	self:SetWndClick(self.mBtnBuy,function () self:OnClickBuy() end)
	self:SetWndClick(self.mBtnJump,function () self:OnClickJump() end)
	self:SetWndClick(self.mBtnLessen,function () self:OnClickLessen() end)
	self:SetWndClick(self.mBtnAdd,function () self:OnClickAdd() end)
	self:SetWndClick(self.mBtnMax,function () self:OnClickMax() end)

	self:SetWndText(self.mLblBiaoti,ccClientText(27617))
	self:SetWndText(self.mJumpText,ccClientText(27618))
	self:SetWndText(self.mNumDesText,ccClientText(27619))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(27620))
	self:SetWndButtonText(self.mBtnBuy,ccClientText(27621))

	CS.ShowObject(self.mBtnJump,true)
	CS.ShowObject(self.mBuyText,true)
end
function UIMalCopyBuyNumPop:InitData()
	self._modelPrivilegeEnum = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {ModelActivity.SWEET_COUNTRY_19,ModelActivity.BUY_BOSS_CHALLENGE_COUNT}
	}
end
function UIMalCopyBuyNumPop:OnClickLessen()
	local num = self._buyNum
	num = num - 1
	if num <= 0 then
		num = 1
	end
	self._buyNum = num
	self:RefreshCount()
end
function UIMalCopyBuyNumPop:OnClickMax()
	local _buyChallengeNum = self._buyChallengeNum					--购买次数
	local _buyTimeLimit = self._buyTimeLimit						--购买上限
	local num = _buyTimeLimit - _buyChallengeNum
	self._buyNum = num
	self:RefreshCount()
end

function UIMalCopyBuyNumPop:OnClickBuy()
	local num = self._buyNum
	local _bossItem = self._bossItem

	if self._buyChallengeNum + num > self._buyTimeLimit then
		GF.ShowMessage(ccClientText(27614))
		return
	end
	gModelActivity:OnActivitySpecialOpReq(self._sid,_bossItem.pageId,_bossItem.entryId,0,tostring(num),self._turnBossCountEnum)
end
function UIMalCopyBuyNumPop:OnClickJump()
	local jump = self._privilegeCardJump
	gModelFunctionOpen:Jump(jump,self:GetWndName())
end
function UIMalCopyBuyNumPop:RefreshCount()
	local _payTimeCost = self._payTimeCost
	if not _payTimeCost then return end
	local num = self._buyNum
	local _buyChallengeNum = self._buyChallengeNum

	local itemNum = gModelItem:GetNumByRefId(_payTimeCost[1].itemId)
	local buyNumCount = 0
	local mNum = _buyChallengeNum + num
	for i = _buyChallengeNum + 1, mNum do
		local cost = _payTimeCost[i] or _payTimeCost[#_payTimeCost]
		buyNumCount = buyNumCount + cost.itemNum
	end
	--local buyNumCount = _payTimeCost.itemNum * num
	local buyStr = LUtil.FormatColorStr(itemNum,itemNum >= buyNumCount and "green" or "red")

	self:SetWndText(self.mNumText,num)
	self:SetWndText(self.mBuyText,buyStr.."/"..buyNumCount)
end
function UIMalCopyBuyNumPop:InitCommand()
	local sid = self:GetWndArg("sid")
	local bossItem = self:GetWndArg("bossItem")
	self.pages = self:GetWndArg("pages")

	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	self._bossItem = bossItem
	local enums = self._modelPrivilegeEnum[modelId]
	self._turnPrivilegeEnum = enums[1]
	self._turnBossCountEnum = enums[2]
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local _buyTimeLimit = data.buyTimeLimit									--购买上限
	local candyCardbuyTimeTxt = data.candyCardbuyTimeTxt					--特权加的次数
	local privilegeCardJump = data.privilegeCardJump						--限时特权卡跳转id
	--local costList = string.split(data.payTimeCost,"|")
	--local payTimeCost = {}
	--for i, v in ipairs(costList) do
	--	local cost = LxDataHelper.ParseItem_3(v)
	--	table.insert(payTimeCost,cost)
	--end
	local payTimeCost = LxDataHelper.ParseItem_3List(data.payTimeCost)			--次数购买单价
	local privilegeCardIcon = data.privilegeCardIcon						--限时特权卡图标

	local moreInfo = JSON.decode(bossItem.moreInfo)
	local buyChallengeNum = moreInfo.buyChallengeNum						--购买次数

	self._buyTimeLimit = _buyTimeLimit
	self._privilegeCardJump = privilegeCardJump
	self._payTimeCost = payTimeCost
	self._buyChallengeNum = buyChallengeNum
	self._candyCardbuyTimeTxt = candyCardbuyTimeTxt

	self:SetWndText(self.mCardText,string.replace(ccClientText(27622),candyCardbuyTimeTxt))
	local icon,iconBg = gModelItem:GetItemImgByRefId(payTimeCost[1].itemId)
	self:SetWndEasyImage(self.mBuyIcon,icon)
	if LxUiHelper.IsImgPathValid(privilegeCardIcon) then
		CS.ShowObject(self.mCardIcon,true)
		self:SetWndEasyImage(self.mCardIcon,privilegeCardIcon,nil,true)
	end

	self:RefreshData()
end
function UIMalCopyBuyNumPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
end
function UIMalCopyBuyNumPop:ResetData(pb)
	local _pages = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local pageId = v.pageId
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		_pages[pageId] = page
	end
	self.pages = _pages
	self:RefreshData()
end

function UIMalCopyBuyNumPop:OnTryTcpReconnect()
	self:WndClose()
end
function UIMalCopyBuyNumPop:RefreshData()
	local isGard = self:GetIsBuyCard()
	if isGard then
		self._buyTimeLimit = self._buyTimeLimit + self._candyCardbuyTimeTxt
	end
	self:RefreshCount()
end
function UIMalCopyBuyNumPop:OnClickAdd()
	local num = self._buyNum
	local _buyChallengeNum = self._buyChallengeNum					--购买次数
	local _buyTimeLimit = self._buyTimeLimit						--购买上限
	num = num + 1
	if _buyChallengeNum + num <= _buyTimeLimit then
		self._buyNum = num
		self:RefreshCount()
		return
	end
	GF.ShowMessage(ccClientText(27614))
	self:OnClickMax()
end
------------------------------------------------------------------
return UIMalCopyBuyNumPop


