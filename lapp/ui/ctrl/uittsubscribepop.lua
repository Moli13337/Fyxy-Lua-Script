---
--- Created by Administrator.
--- DateTime: 2026/3/24 17:36:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITTSubscribePop:LWnd
local UITTSubscribePop = LxClass("UITTSubscribePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITTSubscribePop:UITTSubscribePop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITTSubscribePop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITTSubscribePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITTSubscribePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitStaticTxt()
	self:InitEvents()
	self:RefreshView()
end
--region
function UITTSubscribePop:InitEvents()
	self:WndEventRecv(EventNames.ON_SUBSCRIBE_FEED_RESULT, function(...)
		self:RefreshView(...)
	end)
	
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mGetBtn, function() self:OnClickGetBtn() end)
end
--endregion
--region 初始化静态文本
function UITTSubscribePop:InitStaticTxt()
	self:SetWndText(self.mTitleTxt,ccClientText(48100))--订阅有奖
	self:SetWndText(self.mTipsTxt1,ccClientText(48101))--1.授权允许推荐页游戏进程提醒
	self:SetWndText(self.mTipsTxt2,ccClientText(48102))--2.完成授权即可领取奖励
	self:SetWndText(self.mCloseTip,ccClientText(10103))--点击空白处关闭界面
	
	self:SetWndButtonText(self.mGetBtn,ccClientText(48103))
end
--endregion
--region 奖励列表
function UITTSubscribePop:RefreshView(isOk)
	--local isSubs = isOk or gModelPlayer:GetIsTTSubsFeed()
	--self.SetWndButtonGray(self.mGetBtn)
	local isGet = gModelPlayer:InAccoutBindingReward(ModelSubscriber.TT_SUBSCRIBER_FEED)
	self._isGet = isOk or isGet
	CS.ShowObject(self.mGetTag,isGet)
	CS.ShowObject(self.mGetBtn,not isGet)
	
	---@type V_InnerActivityNameAndInnerndRef
	local ref = gModelActivity:GetVerifyConfig(ModelSubscriber.TT_SUBSCRIBER_FEED)
	if not ref then return end
	
	local rdList = LxDataHelper.ParseItem(ref.reward)
	
	local uiItemList = self:FindUIScroll("ItemList")
	if not uiItemList then
		uiItemList = self:GetUIScroll("ItemList")
		uiItemList:Create(self.mItemList,rdList, function (...)  self:OnDrawItem(...)	end)
	else
		uiItemList:RefreshList(rdList)
	end

	local cnt = #rdList
	if cnt>3 then
		uiItemList:EnableScroll(true,true)
	end
end
function UITTSubscribePop:OnDrawItem(list, item, itemdata, itemPos)
	local iconTrans = CS.FindTrans(item, "CommonUI/Icon")
	local isGet = self._isGet
	self:CreateCommonIconImpl(iconTrans,itemdata,{showshowGou =  isGet})
end
--endregion
--region 点击获取奖励按钮
function UITTSubscribePop:OnClickGetBtn()
	gModelDYFeed:OnRequestFeedSubscribeOnline()
	--gModelPlayer:OnAuthOnetimeStateReq(22)
end
--endregion

------------------------------------------------------------------
return UITTSubscribePop