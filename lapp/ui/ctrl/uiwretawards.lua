---
--- Created by Administrator.
--- DateTime: 2023/10/24 16:51:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWretAwards:LWnd
local UIWretAwards = LxWndClass("UIWretAwards", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWretAwards:UIWretAwards()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWretAwards:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWretAwards:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWretAwards:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitEvent()
	self:InitData()
	self:InitStaticInfo()
	self:RefreshUI()
end

function UIWretAwards:InitStaticInfo()
	self:SetWndText(self.mButtomDesc, ccClientText(10103))
	self:SetWndText(self.mTitleText1, ccClientText(21909))
	self:SetWndText(self.mTitleText2, ccClientText(21910))
end

function UIWretAwards:OnDrawBoxItemFunc(list,item,itemdata,itempos)
	local boxIcon 		= self:FindWndTrans(item,"BoxIcon")
	local sellOutImg	= self:FindWndTrans(item, "SellOutImg")
	local giftName		= self:FindWndTrans(item, "GiftName")
	local itemList		= self:FindWndTrans(item,"itemList")

	local InstanceID	= item:GetInstanceID()
	local isGet 		= itemdata.isGet
	local rewards 		= itemdata.rewards or {}
	CS.ShowObject(sellOutImg, isGet)

	if self._isEnus then
		self:InitTextLineWithLanguage(giftName,-15)
		giftName.sizeDelta= Vector2.New(440,40)
	end

	local titleStr
	if isGet then
		titleStr = ccClientText(21911)
	else
		titleStr = string.replace(ccClientText(21912), itemdata.titleStr)
	end
	self:SetWndText(giftName, titleStr)

	local iconPath = itemdata.icon
	if LxUiHelper.IsImgPathValid(iconPath) then
		self:SetWndEasyImage(boxIcon, iconPath)
	end

	rewards = rewards or {}

	local uiList = self:GetUIScroll(InstanceID)
	if(uiList:GetList())then
		uiList:RefreshList(rewards)
	else
		uiList:Create(itemList, rewards,function (...) self:OnDrawItemFunc(...) end)
		uiList:EnableScroll(#rewards > 4,true)
	end
end


function UIWretAwards:OnDrawItemFunc(list,item,itemdata,itempos)
	local root = self:FindWndTrans(item,"Root")

	local itemData = itemdata
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(itemData.itemType, itemData.itemId,itemData.itemNum)
	self:SetWndClick(root,function()
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)

	----设置道具特效
	--local show = effect ~= false
	--if show and itemType == LItemTypeConst.TYPE_ITEM then
	--	LxResUtil.DestroyChildImmediate(eff)
	--	local itemRef = gModelItem:GetRefByRefId(itemId)
	--	local bgEff = itemRef and itemRef.bgEff or nil
	--	show = not string.isempty(bgEff)
	--	if show then
	--		local key = "DrawItem"..tostring(entryId)
	--		table.insert(self._effectKeyList,key)
	--		self:CreateWndEffect(eff,bgEff,instanceId,100,false,false)
	--	end
	--end

	baseClass:DoApply()
end

function UIWretAwards:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIWretAwards:RefreshUI()
	self:SetWndText(self.mTextIndex, self._txtReward)

	local boxData = self._boxData
	local uiList = self._itemsList
	if(uiList)then
		uiList:RefreshList(boxData)
	else
		uiList = self:GetUIScroll("ItemsList")
		self._itemsList = uiList
		uiList:Create(self.mRewardList,boxData,function (...) self:OnDrawBoxItemFunc(...) end)
	end

end

function UIWretAwards:InitData()
	self._txtReward = self:GetWndArg("txtReward")
	local boxName	= self:GetWndArg("boxName")
	local page		= self:GetWndArg("page")
	local title		= self:GetWndArg("title")
	local items 				= page.items
	local decodeConditions 		= page.decodeConditions
	local receiveRewardIndex 	= page.receiveRewardIndex or -1
	local moreInfo 				= string.split(page.moreInfo, '|')
	local boxNameList 			= string.split(boxName, '|')

	self._boxData = {}
	for k,v in ipairs(items) do
		local curBoxName = string.split(boxNameList[k], '=')
		local curBoxData = {
			decode 		= decodeConditions[k],
			rewards 	= LxDataHelper.ParseItem(v),
			isGet   	= receiveRewardIndex >= k - 1,
			icon		= curBoxName[1],
			titleStr	= moreInfo[k],
		}
		table.insert(self._boxData, curBoxData)
	end

	self:SetWndEasyImage(self.mTitle,title,function()
		CS.ShowObject(self.mTitle,true)
	end,true)
end


------------------------------------------------------------------
return UIWretAwards


