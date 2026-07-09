---
--- Created by Administrator.
--- DateTime: 2024/7/9 15:07:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGiftBuy78Pop:LWnd
local UIGiftBuy78Pop = LxWndClass("UIGiftBuy78Pop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGiftBuy78Pop:UIGiftBuy78Pop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGiftBuy78Pop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGiftBuy78Pop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGiftBuy78Pop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartScale(0,self.mPop)
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	self:InitCommand()

	self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))
end

function UIGiftBuy78Pop:InitMessage()

end

function UIGiftBuy78Pop:InitCommand()
	self:SetWndText(self.mLblBiaoti, self._title)
	self:SetWndText(self.mTimeText, self._desc)
	CS.ShowObject(self.mTimeText,not self._personalGoal or self._personalGoal~=-1)
	self:InitItemList()
	self:SetPayBtn()
	self:OnActivityConfigData()
end

function UIGiftBuy78Pop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCancelBtn, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mPayBtn, function(...) self:PayBtnOnClick() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIGiftBuy78Pop:InitItemList()

	local instanceId = self.mItemScroll:GetInstanceID()

	local itemList = self._itemList
	local uiIconEasyList = self._uiCommonList[instanceId]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiCommonList[instanceId] = uiIconEasyList

		local needScroll = #itemList > 4
		local scrollTrans = needScroll and self.mBigItemScroll or self.mItemScroll
		uiIconEasyList:Create(self, scrollTrans)
		uiIconEasyList:SetIconParentPath("Root/CommonUI/Icon")
		uiIconEasyList:SetShowNum(false)
		uiIconEasyList:SetShowExtraNum(true, "NumText")
		uiIconEasyList:EnableScroll(needScroll,true)

		CS.ShowObject(self.mItemScroll, not needScroll)
		CS.ShowObject(self.mBigItemScroll, needScroll)
	end
	uiIconEasyList:RefreshList(itemList)
end

function UIGiftBuy78Pop:OnTryTcpReconnect()
	self:WndClose()
end

function UIGiftBuy78Pop:SetPayBtn()
	local showItemPay = false
	local payItemIcon
	if self._payItemId then
		showItemPay = true
		payItemIcon = gModelItem:GetItemIconByRefId(self._payItemId)
		self:SetWndEasyImage(self.mPayIcon,payItemIcon)
	end

	local payStr = self._payStr
	if payStr then
		local setText = showItemPay and self.mPayText1 or self.mPayText
		self:SetWndText(setText, self._payStr)
	end

	CS.ShowObject(self.mPayText,  not showItemPay)
	CS.ShowObject(self.mPayText1, showItemPay)
end

function UIGiftBuy78Pop:PayBtnOnClick()
	local payFunc = self._payFunc
	if payFunc then
		payFunc()
	end

	self:WndClose()
end

function UIGiftBuy78Pop:InitData()
	self._title = self:GetWndArg("title") or ""
	self._desc	= self:GetWndArg("desc") or ""
	self._payStr = self:GetWndArg("payStr")
	self._payItemId = self:GetWndArg("payItemId")
	self._payFunc = self:GetWndArg("payFunc")
	self._itemList = self:GetWndArg("itemList")
	self._sid = self:GetWndArg("sid")
	self._noShowHero = self:GetWndArg("noShowHero")
	self._personalGoal = self:GetWndArg("personalGoal")
	self._uiCommonList = {}
end

function UIGiftBuy78Pop:OnActivityConfigData()
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then return end
	local data = activityData.config
	local giftBuyHeroImg,giftBuyHeroImgPos = data.giftBuyHeroImg,data.giftBuyHeroImgPos
	if not string.isempty(giftBuyHeroImg) then
		local imgArr = string.split(giftBuyHeroImg,"=")
		local posParent
		if imgArr[1] == "1" then
			posParent = self.mHeroImg
			self:SetWndEasyImage(posParent,imgArr[2],nil,true)
		else
			posParent = self.mHeroSpine
			local spineName = imgArr[2]
			self:CreateWndSpine(posParent,spineName,spineName.."UIGiftBuy78Pop",false)
		end
		if imgArr[3] then
			local flip = tonumber(imgArr[3])
			posParent.localScale = Vector2.New(flip,1)
		end
		CS.ShowObject(posParent,true)
		if not string.isempty(giftBuyHeroImgPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(giftBuyHeroImgPos)
			self:SetAnchorPos(posParent, pos)
		end
	else
		CS.ShowObject(self.mHeroImg,not self._noShowHero)
	end
end


------------------------------------------------------------------
return UIGiftBuy78Pop