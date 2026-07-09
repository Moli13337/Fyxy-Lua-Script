---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGBuyLog:LWnd
local UIGBuyLog = LxWndClass("UIGBuyLog", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGBuyLog:UIGBuyLog()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGBuyLog:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGBuyLog:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGBuyLog:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitMsg()
	self:InitEvent()

	self:InitCommand()
end

function UIGBuyLog:ListItem( list, item, itemdata, itempos)--cell
	--local consumeText = self:FindWndTrans(item,"ConsumeText")
	local timeText = self:FindWndTrans(item,"TimeText")
	local itemScroll = self:FindWndTrans(item,"ItemScroll")

	local consumeText = self:FindWndTrans(item,"ConsumeText")
	local consumeIcon = self:FindWndTrans(item,"ConsumeText/ConsumeIcon")
	local consumeText1 = self:FindWndTrans(item,"ConsumeText/ConsumeText1")
	local consumeText2 = self:FindWndTrans(item,"ConsumeText/ConsumeText2")

	local basicsRef = gModelGoldBuy:GetGoldBuyBasicsRefById(itemdata.redId)
	local buyNeed = basicsRef.buyNeed
	local itemId = 0
	local consume = 0
	CS.ShowObject(consumeIcon,false)
	CS.ShowObject(consumeText1,false)
	CS.ShowObject(consumeText2,false)

	if(buyNeed ~= "")then
		CS.ShowObject(consumeIcon,true)
		CS.ShowObject(consumeText2,true)
		local buyNeedArr = string.split(buyNeed,"=")
		itemId = tonumber(buyNeedArr[1])
		consume = tonumber(buyNeedArr[2])
		--num = gModelItem:GetNumByRefId(itemId)
		local icon = gModelItem:GetItemImgByRefId(itemId)
		self:SetWndEasyImage(consumeIcon,icon)
		self:SetWndText(consumeText2,consume)
	else
		CS.ShowObject(consumeText1,true)
		self:SetWndText(consumeText1,ccClientText(13011))
	end

	local conStr = ccClientText(13027)
	self:SetWndText(consumeText,conStr)

	local timeStr = LUtil.FormatTimeStr(itemdata.time,ccClientText(13029))
	timeStr = string.replace(ccClientText(13028),timeStr)
	self:SetWndText(timeText,timeStr)

	local InstanceID = item:GetInstanceID()

	local reward = itemdata.reward
	local rewardList = LxDataHelper.ParseItem_3List(reward)
	local uiList1 = self._uiCellList:GetItemCls(InstanceID)
	if not uiList1 then
		uiList1 = UIIconEasyList:New(self)
		self._uiCellList:SetItemCls(InstanceID, uiList1)
		uiList1:Create(self, itemScroll)
		uiList1:SetIconParentPath("Root/CommonUI/Icon")
	end
	uiList1:RefreshList(rewardList)
end

function UIGBuyLog:InitEvent()
	self:SetWndClick(self.mBg1,function() self:WndClose() end)
end

function UIGBuyLog:InitMsg()
	--self:WndNetMsgRecv(LProtoIds.GoldBuyLogResp,function (...) self:RefreshDate(...)  end)
end

function UIGBuyLog:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(13001))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	gModelGoldBuy:GoldBuyLogReq()
end

function UIGBuyLog:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end

function UIGBuyLog:RefreshDate(pb)
	local list = pb.list
	local logList = {}
	for i, v in ipairs(list) do
		table.insert(logList,v)
	end
	local len = #logList
	CS.ShowObject(self.mNoRecord,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(16002)
	end

	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(logList)
		_uiCellList:RemoveAllData()
	else
		_uiCellList = self:GetUIScroll("logCell")
		_uiCellList:Create(self.mLogSuper,logList,function (...) self:ListItem(...) end,UIItemList.SUPER)
		self._uiCellList = _uiCellList
	end
end
------------------------------------------------------------------
return UIGBuyLog


