---
---	条件描述加奖励图标列表弹框
--- Created by Ease.
--- DateTime: 2023/10/13 15:53:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITkAwardPop:LWnd
local UITkAwardPop = LxWndClass("UITkAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITkAwardPop:UITkAwardPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITkAwardPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITkAwardPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITkAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
end
function UITkAwardPop:OnDrawItemCell(list,item,itemdata,itempos)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")

	local itemId = itemdata.itemId
	local instanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemdata.itemType,itemId,itemdata.itemNum)
	baseClass:DoApply()

	self:SetWndClick(IconTrans,function()
		self:OnClickRewardItemFunc(itemdata)
	end)

	local EffRootTrans = self:FindWndTrans(item,"EffRoot")
	local isShowEff = itemdata.isShowEff
	if isShowEff then
		local itemRef = gModelItem:GetRefByRefId(itemId)
		local effName = itemRef and itemRef.bgEff or nil
		isShowEff = effName ~= nil
		if isShowEff then
			self:CreateWndEffect(EffRootTrans,effName,EffRootTrans:GetInstanceID(),88,false)
		end
	end
	CS.ShowObject(EffRootTrans,isShowEff)
end
function UITkAwardPop:InitData()
	local titleStr = self:GetWndArg("title")
	self:SetWndText(self.mTitleTxt,titleStr)
	self.itemList = self:GetWndArg("itemList")
	if(self.itemList and #self.itemList>0)then
		self:SetItemList()
	end
end
function UITkAwardPop:OnDrawShowRewardCell(list,item,itemdata,itempos)
	local TitleTrans = self:FindWndTrans(item,"TitleBg/Title")
	local ItemListTrans = self:FindWndTrans(item,"ItemList")
	self:SetWndText(TitleTrans,itemdata.description)
	local rewardList = LxDataHelper.ParseItem(itemdata.reward)
	self:InitItemList(ItemListTrans, rewardList)
end
function UITkAwardPop:SetItemList()
	local list = {}
	for i, v in ipairs(self.itemList) do
		local moreInfo = v.moreInfo
		local moreInfoArr = string.split(moreInfo, "=")
		if(moreInfoArr and moreInfoArr[3] and moreInfoArr[3] == "1")then
			table.insert(list,v)
		end
	end
	local uiShowRewardList = self._uiShowRewardList
	if uiShowRewardList then
		uiShowRewardList:RefreshList(list)
	else
		uiShowRewardList = self:GetUIScroll("uiShowRewardList")
		self._uiShowRewardList = uiShowRewardList
		uiShowRewardList:Create(self.mShowRewardList,list,function(...) self:OnDrawShowRewardCell(...) end,UIItemList.WRAP)
	end
end


function UITkAwardPop:OnClickRewardItemFunc(itemdata)
	gModelGeneral:ShowCommonItemTipWnd(itemdata)
end
function UITkAwardPop:InitItemList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans,list,function(...) self:OnDrawItemCell(...) end)
	end
end
function UITkAwardPop:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------------------------------------------------
return UITkAwardPop


