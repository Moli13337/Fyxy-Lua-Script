---
--- Created by Administrator.
--- DateTime: 2023/10/27 14:37:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITreadRecord:LWnd
local UITreadRecord = LxWndClass("UITreadRecord", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITreadRecord:UITreadRecord()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITreadRecord:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITreadRecord:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITreadRecord:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local str =ccClientText(19436) --"寻宝日志"
	self:SetXUITextText(self.mTitle,str)
	local cnt = gModelTreaFind:GetPara("treasureDropRecordNum")
	str = ccClientText(19437) --"最多保留%s条寻宝记录"
	str = string.replace(str,cnt)
	self:SetXUITextText(self.mDesc,str)
	local emptyList = self:GetCommonEmptyList("_empty")
	local data = {
		refId = 18004,
		IntroTran = self:FindWndTrans(self.mNoRecord,"text"),
	}
	emptyList:RefreshUI(data)

	self:WndNetMsgRecv(LProtoIds.FindTreasureLogResp,function (...)
		self:OnRecordResp(...)
	end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	gModelTreaFind:OnFindTreasureLogReq()
end


function UITreadRecord:OnDrawConsume(list,item,itemdata,itempos)
	local PayIcon = self:FindWndTrans(item,"PayIcon")
	local PayNum = self:FindWndTrans(item,"PayNum")

	if PayIcon then
		local icon
		if itemdata.itemType == LItemTypeConst.TYPE_ITEM then
			icon = gModelItem:GetItemIconByRefId(itemdata.itemId)
		end
		if icon then
			self:SetWndEasyImage(PayIcon,icon,function()
				CS.ShowObject(PayIcon,true)
			end)
		end
	end

	if PayNum then
		local number = tonumber(itemdata.itemNum)
		local num = LUtil.NumberCoversion(number)
		self:SetWndText(PayNum,num)
	end
end

function UITreadRecord:OnDrawRecord(list,item,itemdata,itempos)

	--local ListBg = self:FindWndTrans(item,"ListBg")
	--local TopDiv = self:FindWndTrans(item,"TopDiv")
	local HeroList = self:FindWndTrans(item,"HeroList")
	local BottomDiv = self:FindWndTrans(item,"BottomDiv")
	local BottomDivTopDiv = self:FindWndTrans(BottomDiv,"TopDiv")
	local TopDivXHTxt = self:FindWndTrans(BottomDivTopDiv,"XHTxt")
	local TopDivFreeTxt = self:FindWndTrans(TopDivXHTxt,"FreeTxt")
	local TopDivPayList = self:FindWndTrans(TopDivXHTxt,"PayList")
	local TopDivCallTime = self:FindWndTrans(BottomDivTopDiv,"CallTime")


	--local ListBg = self:FindWndTrans(item,"ListBg")
	--local HeroList = self:FindWndTrans(item,"HeroList")
	--local XHTxt = self:FindWndTrans(item,"XHTxt")
	--local FreeTxt = self:FindWndTrans(item,"FreeTxt")
	--local PayList = self:FindWndTrans(item,"PayList")
	--local CallTime = self:FindWndTrans(item,"CallTime")

	local InstanceID = item:GetInstanceID()
	local uiIconEasyList = self._recordList:GetItemCls(InstanceID)
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._recordList:SetItemCls(InstanceID, uiIconEasyList)
		uiIconEasyList:Create(self, HeroList)
		uiIconEasyList:SetIconParentPath("CommonUI/Icon")
	end
	uiIconEasyList:RefreshList(itemdata.reward, true)
	--local enableScroll = #itemdata.reward>5
	--uiIconEasyList:EnableScroll(enableScroll,true)

	self:SetWndText(TopDivXHTxt,ccClientText(11654))
	local isFree = #itemdata.consume == 0
	CS.ShowObject(TopDivFreeTxt,isFree)
	self:SetWndText(TopDivFreeTxt,ccClientText(11657))

	local str =ccClientText(19438) -- "寻宝时间:%s"
	local timeStr = LUtil.FormatTimeStr(itemdata.time,"%Y/%m/%d %H:%M")
	str = string.replace(str,timeStr)
	self:SetWndText(TopDivCallTime,str)

	local instanceId = TopDivPayList:GetInstanceID()
	local payList = self._recordList:GetItemCls(instanceId)
	if not payList then
		payList = self:GetUIScroll(instanceId)
		payList:Create(TopDivPayList,itemdata.consume,function (...) self:OnDrawConsume(...) end)
	end

	local cnt = #itemdata.reward
	local height = 128
	if cnt > 6 then
		height = 208
	end

	LxUiHelper.SetSizeWithCurAnchor(item,1,height)

end


function UITreadRecord:OnRecordResp(pb)
	local cnt = #pb.logList
	local isEmpty = cnt == 0
	CS.ShowObject(self.mNoRecord,isEmpty)
	CS.ShowObject(self.mCallLogList,not isEmpty)
	CS.ShowObject(self.mDesc,not isEmpty)
	if isEmpty then
		return
	end

	local rewardFix= gModelTreaFind:GetPara("rewardFix")
	local fixedReward = LxDataHelper.ParseNumber_Sign(rewardFix,"=")
	local fixItemId = fixedReward[2]

	local dataList = {}
	for k,v in ipairs(pb.logList) do
		local data = {}
		data.reward = {}
		local fixedReward
		for k1,v1 in ipairs(v.reward) do
			local itemdata =
			{
				itemId = v1.itemId,
				itemNum = v1.count,
				itemType = v1.type,
			}

			if v.itemId == fixItemId then
				fixedReward = itemdata
			else
				table.insert(data.reward,itemdata)
			end


		end

		if fixedReward then
			table.insert(data.reward,1,fixedReward)
		end



		data.consume = {}
		for k1,v1 in ipairs(v.consume) do
			local itemdata =
			{
				itemId = v1.itemId,
				itemNum = v1.count,
				itemType = v1.type,
			}

			table.insert(data.consume,itemdata)
		end

		data.time = v.time
		table.insert(dataList,data)

	end

	table.sort(dataList,function (a,b)
		return a.time>b.time
	end)

	local list = self._recordList
	if not list then
		list = self:GetUIScroll("recordList")
		self._recordList = list
	end
	list:Create(self.mCallLogList,dataList,function (...) self:OnDrawRecord(...) end,UIItemList.SUPER)

end

------------------------------------------------------------------
return UITreadRecord


