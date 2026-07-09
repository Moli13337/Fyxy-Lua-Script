---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringPkAward:LWnd
local UIringPkAward = LxWndClass("UIringPkAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringPkAward:UIringPkAward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringPkAward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringPkAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringPkAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	if self._rewardList then
		self:ShowRewardList(self._rewardList)
	else
		self:ShowPeakReward()
	end
	self:InitUIEvent()
end

function UIringPkAward:ShowPeakReward()

	local rewardList = gModelArena:GetPeakRewardConfig()
	local dataList ={}
	for k,v in pairs(rewardList) do
		local itemdata = {}
		itemdata.index = k
		local cfg = gModelArena:GetRankArenaPeakAwardRefT(v.refId)
		itemdata.rank =cfg.rankT
		itemdata.itemList = cfg.rewardT
		table.insert(dataList,itemdata)

	end
	table.sort(dataList,function (a,b) return a.index<b.index end)
	self:ShowRewardList(dataList)
end

function UIringPkAward:OnDrawRewardItem(list, item, itemdata, itempos, fromHeadTail)
	local rankIcon = self:FindWndTrans(item,"rankIcon")
	local rankText = self:FindWndTrans(item,"rankNum")

	local min = itemdata.rank.left
	local max = itemdata.rank.right
	if not min or not max then
		return
	end
	if min <4 then
		self:SetWndEasyImage(rankIcon,self._rankIconPathList[itemdata.rank.left])
	else
		local maxStr = tostring(max)
		if self._rewardList and max == "-1" then
			maxStr = "100+"
		end
		local rankStr = nil
		if min == max then
			rankStr = maxStr
		else
			rankStr = string.format("%s-%s",min,maxStr)
		end
		self:SetWndText(rankText,rankStr)
		CS.ShowObject(rankIcon.gameObject,false)
	end

	local rewardList= self:FindWndTrans(item,"itemList")

	local instanceId = item:GetInstanceID()
	local uiIconEasyList = self._uiList:GetItemCls(instanceId)
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._uiList:SetItemCls(instanceId, uiIconEasyList)
		uiIconEasyList:Create(self, rewardList)
	end
	uiIconEasyList:RefreshList(itemdata.itemList)
end

function UIringPkAward:InitUIEvent()

	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mMask, function() self:WndClose() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIringPkAward:SetStaticContent()
	local intro1,intro2 = ccClientText(11853),ccClientText(11854)
	if self._rewardList then
		intro1 = ccClientText(10315)
		intro2 = ccClientText(16212)
	end
	self:SetWndText(self.mTitleText,intro1)
	self:SetWndText(self.mIntro,intro2)
end

function UIringPkAward:InitData()
	self._rewardList = self:GetWndArg("rewardList")
	self._uiItemListList ={}
	self._rankIconPathList =
	{
		"public_num_1",
		"public_num_2",
		"public_num_3",
	}
end

function UIringPkAward:ShowRewardList(rewardList)
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("rewardList")
		self._uiList = uiList
		uiList:Create(self.mRewardList, rewardList, function (...) self:OnDrawRewardItem(...) end, UIItemList.NORMAL)
		uiList:EnableScroll(true,false)
	else
		uiList:RefreshList(rewardList)
	end
end

------------------------------------------------------------------
return UIringPkAward


