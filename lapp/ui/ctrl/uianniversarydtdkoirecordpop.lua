---
---活动83Pop 每日锦鲤玩家中奖记录
--- Created by Ease.
--- DateTime: 2023/10/19 10:09:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAnniversaryDTDKoiRecordPop:LWnd
local UIAnniversaryDTDKoiRecordPop = LxWndClass("UIAnniversaryDTDKoiRecordPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAnniversaryDTDKoiRecordPop:UIAnniversaryDTDKoiRecordPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAnniversaryDTDKoiRecordPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAnniversaryDTDKoiRecordPop:OnCreate()
	LWnd.OnCreate(self)
	self._uiCommonList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAnniversaryDTDKoiRecordPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitEvent() --初始化事件
	self:InitMessage() --初始化事件
	self:InitData()  --初始化数据
end

function UIAnniversaryDTDKoiRecordPop:OnDrawItemCell(list, item, itemdata, itempos)
	local timeTxt = self:FindWndTrans(item, "TimeTxt")
	local prizeNumTxt = self:FindWndTrans(item, "PrizeNumTxt")
	local playerNumTxt = self:FindWndTrans(item, "PlayerNumTxt")
	local prizeNameTxt = self:FindWndTrans(item, "PrizeNameTxt")
	local rewardScroll = self:FindWndTrans(item, "RewardScroll")
	local getBtn = self:FindWndTrans(item, "GetBtn")
	local gotTag = self:FindWndTrans(item, "GotTag")

	local getBtnTxt = self:FindWndTrans(getBtn, "Txt")
	local year, month, day = LUtil.GetYmdByTimestamp(tonumber(itemdata.createTime) / 1000)
	local ymdTimeStr = string.replace(ccClientText(29611), year, month, day)--29611	%Y年%m月%d日
	self:SetWndText(timeTxt, ymdTimeStr)
	local prizeNumStr = string.replace(ccClientText(29612), itemdata.targetNum)--29608 中奖号码：%s  [[29612]	[中獎號碼：#a1#]
	local playerNumStr = string.replace(ccClientText(29613), itemdata.drawNum)--29609 抽奖号码：%s  [29613]	[抽獎號碼：#a1#]
	self:SetWndText(prizeNumTxt, prizeNumStr)
	self:SetWndText(playerNumTxt, playerNumStr)
	self:SetWndText(prizeNameTxt, itemdata.recordName)
	local rewardDataList = itemdata.rewards or {}
	local rewardList = self:GetUIScroll(item:GetInstanceID())
	if (rewardList:GetList()) then
		rewardList:RefreshList(rewardDataList)
	else
		rewardList:Create(rewardScroll, rewardDataList, function(...)
			self:RewardListItem(...)
		end)
	end

	if self._isEnus then
		self:SetAnchorPos(prizeNameTxt,Vector2.New(40,-67))
	end

	rewardList:EnableScroll(#rewardDataList > 3 , true)
	local createTime = itemdata.createTime
	local isReceive = itemdata.isReceive
	local btnStrIndex = isReceive == 0 and 29615 or 29616--领取/已领取
	local btnPath = isReceive == 0 and "public_btn_2_2" or "public_btn_ash_2"
	self:SetWndText(getBtnTxt,ccClientText(btnStrIndex))
	self:SetWndEasyImage(getBtn,btnPath)
	CS.EnableClickListener(getBtn.gameObject,isReceive == 0)

	CS.ShowObject(gotTag,not (isReceive == 0))
	CS.ShowObject(getBtn, (isReceive == 0))


	self:SetWndClick(getBtn, function()
		if(isReceive == 0)then
			gModelActivity:OnActivitySpecialOpReq(self._sid, 1, nil, ModelActivity.LUCKY_NUM_RECEIVE, tostring(createTime))
		end
	end)
end

function UIAnniversaryDTDKoiRecordPop:InitEvent()
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

end
function UIAnniversaryDTDKoiRecordPop:SetUI()
	CS.ShowObject(self.mMask, true)
	CS.ShowObject(self.mRecordList, true)
	self:SetWndText(self.mTitleText, ccClientText(29608))--[29608]	[中獎記錄]
	self:SetWndText(self.mDescText, ccClientText(29609)) --[29609]	[所有獎勵均通過郵件發放]
	self:SetWndText(self.mNoListTxt, ccClientText(29610))--[29610]	[暫無中獎記錄]
	CS.ShowObject(self.mNoListTxt, self._recordDataList == nil or #self._recordDataList == 0)
	local list = self._recordDataList
	--晚创建的处于上方
	table.sort(list,function(a, b) return a.createTime>b.createTime end)

	if (self._recordList) then
		self._recordList:RefreshList(list)
	else
		self._recordList = self:GetUIScroll("mRecordList")
		self._recordList:Create(self.mRecordList, list, function(...)
			self:OnDrawItemCell(...)
		end, UIItemList.NORMAL)
		self._recordList:EnableScroll(true, false)
	end
end
function UIAnniversaryDTDKoiRecordPop:InitData()
	self._sid = self:GetWndArg("sid")
	self._recordDataList = self:GetWndArg("recordList")
	self:SetUI()
end
function UIAnniversaryDTDKoiRecordPop:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end
	local page = pb.pages[1]
	local pageId = page.pageId
	local pageData = gModelActivity:GenerateActivePageDataFromPb(page)
	local entry = {}
	for i, v in ipairs(pageData.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(sid, pageId, v.entryId)
		local data = {}
		data.webData = v
		data.title = entryCfg.name
		data.moreInfo = entryCfg.moreInfo
		data.rewards = LxDataHelper.ParseItem(entryCfg.reward)
		table.insert(entry, data)
	end
	local moreInfo = JSON.decode(pageData.moreInfo)
	local playerRecord
	if moreInfo.playerRecord then
		playerRecord = JSON.decode(moreInfo.playerRecord)
	end
	if(playerRecord)then
		for i, v in pairs(playerRecord) do
			local entryData = entry[v.id]
			v.rewards = entryData.rewards
			v.recordName = entryData.title
		end
		self._recordDataList = playerRecord
		self:SetUI()
	end
end
--协议监听初始化
function UIAnniversaryDTDKoiRecordPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:OnActivityPageResp(pb)    --分页数据返回
	end)
end
function UIAnniversaryDTDKoiRecordPop:RewardListItem(list, item, itemdata, itempos)
	local itemRoot = self:FindWndTrans(item, "itemRoot")
	local root = self:FindWndTrans(itemRoot, "Icon")
	local itemNum = self:FindWndTrans(item, "itemNum")
	local InstanceID = item:GetInstanceID()
	local baseClass = self._uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
		self:SetIconClickScale(root, true)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetWndText(itemNum, itemdata.itemNum)
	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end
------------------------------------------------------------------
return UIAnniversaryDTDKoiRecordPop


