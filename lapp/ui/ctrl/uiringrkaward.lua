---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringRkAward:LWnd
local UIringRkAward = LxWndClass("UIringRkAward", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringRkAward:UIringRkAward()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringRkAward:OnWndClose()
	if self._selfIconEasyList then
		self._selfIconEasyList:Destroy()
		self._selfIconEasyList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringRkAward:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringRkAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()

	self:InitData()
	self:ShowTabList()
	self:ShowDayReward()
end

function UIringRkAward:OnDrawItem(list, item, itemdata, itempos, fromHeadTail)
	local rankIcon = self:FindWndTrans(item,"RankIcon")
	local rankText = self:FindWndTrans(item,"RankText")
	local isIcon = false
	if itemdata.rank.left <4 then
		isIcon = true
		self:SetWndEasyImage(rankIcon,self._rankIconPathList[itemdata.rank.left])
	else
		local rankStr = string.format("%d-%d",itemdata.rank.left,itemdata.rank.right)
		self:SetWndText(rankText,rankStr)
	end
	CS.ShowObject(rankIcon,isIcon)
	CS.ShowObject(rankText,not isIcon)

	local instanceId = item:GetInstanceID()
	local rewardList= self:FindWndTrans(item,"AwardScroll")
	local uiIconEasyList = self._uiList:GetItemCls(instanceId)
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._uiList:SetItemCls(instanceId, uiIconEasyList)
		uiIconEasyList:Create(self, rewardList)
		uiIconEasyList:SetIconParentPath("Root/CommonUI/Icon")
	end
	uiIconEasyList:RefreshList(itemdata.itemList)
end

function UIringRkAward:ChangeTab(trans,bool)
	local state = bool and 0 or 1
	self:SetWndTabStatus(trans, state)
end

function UIringRkAward:TabItem(list, item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab3")
	self:SetWndTabText(btnTab,itemdata.title)

	local isSelect =  self._curSelect == itemdata.type
	self:ChangeTab(btnTab,isSelect)
	self._tabTrans[itemdata.type] = btnTab

	self:SetWndClick(item, function (...) self:OnClickTab(itemdata.type) end,LSoundConst.CLICK_PAGE_COMMON)
end

function UIringRkAward:ShowRewardList(rewardList)
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("rewardList")
		self._uiList = uiList
		uiList:Create(self.mAwardScroll, rewardList, function(...) self:OnDrawItem(...) end, UIItemList.NORMAL)
		uiList:EnableScroll(true,false)
	else
		uiList:RefreshList(rewardList)
	end
end


function UIringRkAward:SetStaticContent()
	self:SetWndText(self.mTitleText,ccClientText(10338))
	self:SetWndText(self.mMeTitleText2,ccClientText(11726))

	self:InitTextSizeWithLanguage(self.mTimeText, -2)
end

function UIringRkAward:OnCloseWnd()--关闭界面
	local _callFun = self._callFun
	if _callFun ~= nil then
		_callFun()
	end
	self:WndClose()
end



function UIringRkAward:ShowSeasonReward()

	local seasonEndTime = gModelArena:GetRankSeasonTime()
	local nowTime = GetTimestamp()
	local timespan= seasonEndTime-nowTime
	local timeStr = LUtil.FormatTimespanCn(timespan)
	timeStr = LUtil.FormatColorStr(timeStr,"green")
	self:SetWndText(self.mTimeText,string.replace(ccClientText(10325),timeStr))

	local selfItemData = {}
	selfItemData.rank = gModelArena:GetRank()

	local rewardList = gModelArena:GetRankRewardConfig()
	local dataList ={}
	for k,v in pairs(rewardList) do
		local itemdata = {}
		itemdata.index = k
		local cfg = gModelArena:GetRankAwardRefT(v.refId)
		itemdata.rank = cfg.rankT
		itemdata.itemList = cfg.seasonRewardT

		if not selfItemData.itemList and selfItemData.rank>=itemdata.rank.left and selfItemData.rank<=itemdata.rank.right then
			selfItemData.itemList = itemdata.itemList
		end

		table.insert(dataList,itemdata)
	end

	table.sort(dataList,function (a,b) return a.index<b.index end)
	self:ShowRewardList(dataList)

	self:SetSelfItem(selfItemData)
end

function UIringRkAward:OnClickTab(type)
	if type == self._curSelect then
		return
	end

	local trans = self._tabTrans[self._curSelect]
	self:ChangeTab(trans,false)
	self._curSelect = type
	local trans = self._tabTrans[type]
	self:ChangeTab(trans,true)

	if type == 1 then
		self:ShowDayReward()
	elseif type == 2 then
		self:ShowSeasonReward()
	end
end

function UIringRkAward:ShowTabList()
	local list = self._tabDataList
	self._curSelect = 1
	self._tabList = self:GetUIScroll("tabCell")
	self._tabList:Create(self.mTabScroll,list,function (...) self:TabItem(...) end)

end

function UIringRkAward:ShowDayReward()

	local accountTime = gModelArena:GetArenaPara("AccountTime")
	local str = string.gsub(accountTime,"=",":")
	self:SetWndText(self.mTimeText,string.replace(ccClientText(10352),str))

	local selfItemData = {}
	selfItemData.rank = gModelArena:GetRank()

	local rewardList = gModelArena:GetRankRewardConfig()
	local dataList ={}
	for k,v in pairs(rewardList) do
		local itemdata = {}
		itemdata.index = k
		local cfg = gModelArena:GetRankAwardRefT(v.refId)
		itemdata.rank = cfg.rankT
		itemdata.itemList = cfg.dailyRewardT

		if not selfItemData.itemList and selfItemData.rank>=itemdata.rank.left and selfItemData.rank<=itemdata.rank.right then
			selfItemData.itemList = itemdata.itemList
		end

		table.insert(dataList,itemdata)

	end
	table.sort(dataList,function (a,b) return a.index<b.index end)
	self:ShowRewardList(dataList)

	self:SetSelfItem(selfItemData)
end


function UIringRkAward:SetSelfItem(itemdata)
	local item = self.mAwardRank

	local rankIcon = self:FindWndTrans(item,"RankIcon")
	local rankText = self:FindWndTrans(item,"RankText")
	local showIcon = false
	if itemdata.rank <4 and itemdata.rank>0 then
		showIcon = true
		self:SetWndEasyImage(rankIcon,self._rankIconPathList[itemdata.rank])
	else
		local rankStr = string.format("%d",itemdata.rank)
		self:SetWndText(rankText,rankStr)

	end
	CS.ShowObject(rankIcon,showIcon)
	CS.ShowObject(rankText,not showIcon)

	local rewardList= self:FindWndTrans(item,"AwardScroll")

	local uiIconEasyList  = self._selfIconEasyList
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._selfIconEasyList = uiIconEasyList
		uiIconEasyList:Create(self, rewardList)
		uiIconEasyList:SetIconParentPath("Root/CommonUI/Icon")
	end

	--self:SetWndText(self.mRankText,ccClientText(11716))
	--self:SetWndText(self.mDesText,ccClientText(11722))

	local list = itemdata.itemList
	if not list then
		self:SetWndText(self.mRankText,ccClientText(11716))
		self:SetWndText(self.mDesText,ccClientText(11722))
		list ={}
	end
	uiIconEasyList:RefreshList(list)
end

function UIringRkAward:InitUIEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function (...) self:OnCloseWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIringRkAward:InitData()
	self._rankIconPathList =
	{
		"public_num_1",
		"public_num_2",
		"public_num_3",
	}


	self._uiItemListList ={}

	self._tabDataList = {
		[1] = {type =1 ,title = ccClientText(11727)},
		[2] = {type =2 ,title = ccClientText(11728)},
	}

	self._tabTrans = {}
end

------------------------------------------------------------------
return UIringRkAward


