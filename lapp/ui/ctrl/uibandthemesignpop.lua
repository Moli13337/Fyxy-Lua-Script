---
--- Created by Administrator.
--- DateTime: 2021/10/28 16:36:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBandThemeSignPop:LWnd
local UIBandThemeSignPop = LxWndClass("UIBandThemeSignPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBandThemeSignPop:UIBandThemeSignPop()
	---@type table<number,CommonIcon>
	self._uicommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBandThemeSignPop:OnWndClose()
	if self._uicommonList then
		local list = self._uicommonList
		for k,v in pairs(list) do
			v:Destroy()
			list[k] = nil
		end
		self._uicommonList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBandThemeSignPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBandThemeSignPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:RefreshUIView()
end

function UIBandThemeSignPop:InitData()
	self._sid = self:GetWndArg("sid") 				-- 活动的sid
	self._bigGiftStatus = self:GetWndArg("bigGiftStatus")
	self._itemList = self:GetWndArg("itemList") or {}	-- 要展示的道具
	self._closeFunc = self:GetWndArg("closeFunc")		-- 关闭按钮的回调
	self._okBtnName = self:GetWndArg("okBtnName")
	local signBoxState = self:GetWndArg("signBoxState") --宝箱图片
	if signBoxState then
		self:SetWndEasyImage(self.mBigGiftIcon,signBoxState[1],function()
			self:ResetGiftIconSizeDelta(self.mBigGiftIcon)
		end, true)
		self:SetWndEasyImage(self.mBigGiftGetIcon,signBoxState[3],function()
			self:ResetGiftIconSizeDelta(self.mBigGiftGetIcon)
		end, true)
	end

	local str = self:GetWndArg("text1")
	self:SetWndText(self.mTips_1,str)
	str = self:GetWndArg("text2")
	self:SetWndText(self.mTips_2,str)

	local bigGiftPosY = self:GetWndArg("bigGiftPosY")
	if bigGiftPosY then
		self.mBigGiftIcon.localPosition = Vector3(0,bigGiftPosY,0)
		self.mBigGiftGetIcon.localPosition = Vector3(0,bigGiftPosY,0)
	end

	local bigGiftPos = self:GetWndArg("bigGiftPos")
	if bigGiftPos then
		self.mBigGiftIcon.localPosition = bigGiftPos
		self.mBigGiftGetIcon.localPosition = bigGiftPos
	end

	local bigGiftScale = self:GetWndArg("bigGiftScale")
	if bigGiftScale then
		self.mBigGiftIcon.localScale = Vector3(bigGiftScale,bigGiftScale,bigGiftScale)
		self.mBigGiftGetIcon.localScale = Vector3(bigGiftScale,bigGiftScale,bigGiftScale)
	end
end

function UIBandThemeSignPop:RefreshUIView()
	local bigGiftStatus = self._bigGiftStatus
	local isGet = bigGiftStatus == 2
	CS.ShowObject(self.mBigGiftIcon, not isGet)
	CS.ShowObject(self.mBigGiftGetIcon, isGet)

	--self:SetWndButtonGray(self.mOkBtn,isGet)
	CS.ShowObject(self.mOkBtn,not isGet)
	CS.ShowObject(self.mBtnMask,isGet)

	self:SetWndText(self.mTitle, ccClientText(23223))

	local okBtnName = self._okBtnName or ccClientText(10102)
	self:SetWndButtonText(self.mOkBtn,okBtnName)

	self:InitItemScrollView()
end

function UIBandThemeSignPop:ResetGiftIconSizeDelta(giftTrans)
	if not CS.IsValidObject(giftTrans) then return end
	local rectWidth = giftTrans.rect.width
	local rectHeight = giftTrans.rect.height
	if rectWidth < 120 or rectHeight < 120 then
		giftTrans.sizeDelta = Vector2(rectWidth * 1.8,rectHeight * 1.8)
	end
end

function UIBandThemeSignPop:InitItemScrollView()
	local data = self._itemList
	local rewardNum = #data

	local uiList = self._uiList
	if not uiList then
		local isEnable = false
		local list
		if rewardNum < 5 then
			isEnable = false
			list = self.mLimitList
		else
			isEnable = true
			list = self.mRewardList
		end
		uiList = UIListEasy:New()
		uiList:Create(self,list)
		uiList:EnableScroll(isEnable,true)
		uiList:SetFuncOnItemDraw(function(...)
			self:InitOnItemDraw(...)
		end)
		self._uiList = uiList
		CS.ShowObject(list, true)
	end
	uiList:RemoveAll()
	local rewardList = data or {}
	for k,v in ipairs(rewardList) do
		uiList:AddData(k,v)
	end
	uiList:RefreshList()
end

function UIBandThemeSignPop:OnClickCloseButton()
	if self._closeFunc then self._closeFunc() end
	self:WndClose()
end

function UIBandThemeSignPop:InitOnItemDraw(list, item, itemdata, itempos)
	local itype = itemdata.itype or itemdata.type
	if itype == nil then itype = itemdata.itemType end

	local refId = itemdata.heroId or tonumber(itemdata.itemId or itemdata.refId)
	local num = itemdata.count or itemdata.itemNum

	local instanceId = item:GetInstanceID()
	local iconRootTrans = CS.FindTrans(item,"IconRoot")
	local uicommonlist = self._uicommonList
	local baseClass = uicommonlist[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceId] = baseClass
		baseClass:Create(CS.FindTrans(iconRootTrans,"Icon"))
	end
	if itype == LItemTypeConst.TYPE_HERO and itemdata.heroId then
		baseClass:SetHeroPlayer(itemdata.heroId)
	elseif itype == LItemTypeConst.TYPE_HERO and itemdata.heroData then
		baseClass:SetHeroDataSet(itemdata.heroData)
	else
		baseClass:SetCommonReward(itype, refId, num)
	end
	if itemdata.hideNum then
		baseClass:EnableShowNum(false)
	else
		baseClass:EnableShowNum(true)
	end


	baseClass:DoApply()

	self:SetWndClick(iconRootTrans, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	self:SetIconClickScale(iconRootTrans, true)

	local uiNameTrans = CS.FindTrans(item, "UIName")
	local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
	if uiNameText then
		local itemname,itemcolor = baseClass:GetName()
		self:SetXUITextText(uiNameText, itemname or "")
		if itemcolor then
			self:SetXUITextColor(uiNameText, itemcolor)
		end
		self:InitTextModeWithLanguage(uiNameTrans)
	end
end

function UIBandThemeSignPop:InitEvent()
	self:SetWndClick(self.mMaskCell,function() self:OnClickCloseButton() end)
	self:SetWndClick(self.mCloseBtn,function () self:OnClickCloseButton() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOkBtn,function () self:OnClickCloseButton() end, LSoundConst.CLICK_BUTTON_COMMON)
end



------------------------------------------------------------------
return UIBandThemeSignPop


