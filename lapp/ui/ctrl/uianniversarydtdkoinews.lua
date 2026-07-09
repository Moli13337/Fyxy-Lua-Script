---
---活动83 主页弹窗 锦鲤快讯
--- Created by Ease.
--- DateTime: 2023/10/25 11:10:33
---
------------------------------------------------------------------
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local LWnd = LWnd
---@class UIAnniversaryDTDKoiNews:LWnd
local UIAnniversaryDTDKoiNews = LxWndClass("UIAnniversaryDTDKoiNews", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAnniversaryDTDKoiNews:UIAnniversaryDTDKoiNews()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAnniversaryDTDKoiNews:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAnniversaryDTDKoiNews:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAnniversaryDTDKoiNews:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
end
function UIAnniversaryDTDKoiNews:SetSelePageBtn()
	local showBtn = (self._pbData and #self._pbData > 1) and true or false
	CS.ShowObject(self.mNextBtn, showBtn)
	CS.ShowObject(self.mLastBtn, showBtn)
	local seleBtnList = { [1] = self.mLastBtn, [2] = self.mNextBtn }
	for i = 1, 2 do
		self:SetWndClick(seleBtnList[i], function()
			if (not self.botBtnSeleIndex) then
				return
			end
			local dataIndexAddValue = i == 1 and -1 or 1
			local index = self.botBtnSeleIndex + dataIndexAddValue
			if (index > #self._pbData) then
				index = 1
			elseif (index < 1) then
				index = #self._pbData
			end
			self:OnClickBotBtn(index)
		end)
	end
end
function UIAnniversaryDTDKoiNews:OnDrawBotBtn(list, item, itemdata, itempos)
	self.botBtnTransList[itempos] = item
	self:SetWndClick(item, function()
		self:OnClickBotBtn(itempos)
	end)
end
--设置日期文本
function UIAnniversaryDTDKoiNews:SetDateTxt(btnIndex)
	local date = self._pbData[btnIndex].date
	local y, m, d = LUtil.GetYmdByTimestamp(tonumber(date) / 1000)
	local dateStr = string.replace(ccClientText(29617), tostring(y), tostring(m), tostring(d))
	self:SetWndText(self.mDateTxt, dateStr)
end
--协议监听初始化
function UIAnniversaryDTDKoiNews:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp, function(pb)
		self:OnActivitySpecialOpResp(pb)    --分页数据返回
	end)
	self:WndNetMsgRecv(LProtoIds.LuckyNumNewsResp,function (...)
		self:OnLuckyNumNewsResp(...)
	end)
end
function UIAnniversaryDTDKoiNews:SetPlayerName(nameTxtTrans, serverId, name)
	local serverStr = gLGameLogin:GetServerShotNameById(serverId)
	local nameStr = string.format("[%s] %s", serverStr, name)
	self:SetWndText(nameTxtTrans, nameStr)
end
function UIAnniversaryDTDKoiNews:OnClickBotBtn(btnIndex)
	self.botBtnSeleIndex = btnIndex
	local list = self._pbData
	self._botList:MoveToPos(#list - self.botBtnSeleIndex + 1)
	self:SetBotBtnTransSelect(btnIndex)
	self:SetDateTxt(btnIndex)
	self:SetWinnerGroup(btnIndex)
	self:SetMyRewardGroup(btnIndex)
end
function UIAnniversaryDTDKoiNews:SetBotBtnList()
	if (not self._pbData or #self._pbData == 0) then
		return
	end
	local list = self._pbData
	if (self._botList) then
		self._botList:RefreshList(list)
	else
		self._botList = self:GetUIScroll("mBotList")
		self._botList:Create(self.mBotBtnList, list, function(...)
			self:OnDrawBotBtn(...)
		end, UIItemList.NORMAL)
	end
	--self._botList:EnableScroll(#list > 6, true)
	self._botList:EnableScroll(false, true)
	local itemRoot = self:FindWndTrans(self.mBotBtnList, "ItemRoot")
	local itemRootRectTrans = itemRoot.gameObject:GetComponent(typeOfRectTransform)
	if (#list > 6) then
		local leftAnchorsData = Vector2.New(0, 0.5)
		itemRootRectTrans.anchorMin = leftAnchorsData
		itemRootRectTrans.anchorMax = leftAnchorsData
		itemRootRectTrans.pivot = leftAnchorsData
	else
		local middleAnchorsData = Vector2.New(0.5, 0.5)
		itemRootRectTrans.anchorMin = middleAnchorsData
		itemRootRectTrans.anchorMax = middleAnchorsData
		itemRootRectTrans.pivot = middleAnchorsData
	end
	self:SetAnchorPos(itemRoot, Vector2.New(0, 0))
	self:OnClickBotBtn(self.botBtnSeleIndex or #list)
end
function UIAnniversaryDTDKoiNews:SetUI()
	self:SetWndText(self.mTimeTxt, ccClientText(29605))
	self:SetSelePageBtn()
	self:SetBotBtnList()
end

--初始化数据
function UIAnniversaryDTDKoiNews:InitData()
	self.botBtnTransList = {}
	self._uiCommonList = {}
	self._sid = self:GetWndArg("sid")
	local pbData = self:GetWndArg("args")
	self:SetPbData(pbData)
	self:SetWndText(self.mCloseTipTxt, ccClientText(10103))--10103 点击空白处关闭界面
	gModelActivity:OnActivitySpecialOpReq(self._sid, 1, nil, ModelActivity.LUCKY_MUM_NEWS)
	--gModelActivity:ReqActivityConfigData(self._sid)
end
--设置头像
function UIAnniversaryDTDKoiNews:SetHeadIcon(playerInfo, headClassType)
	local baseClass = headClassType == 1 and self._otherHeadBaseClass or self._myHeadBaseClass
	if baseClass then
		baseClass:SetHeadData(playerInfo)
		baseClass:RefreshUI()
	else
		baseClass = HeadIcon:New(self)
		baseClass:SetHeadData(playerInfo)
		baseClass:RefreshUI()
		self._headBaseClass = baseClass
	end
end
--设置中奖者数据
function UIAnniversaryDTDKoiNews:SetWinnerGroup(btnIndex)
	local titleTxt = self:FindWndTrans(self.mWinnerGroup, "TitleTxt")
	local dataGroup = self:FindWndTrans(self.mWinnerGroup, "DataGroup")
	local noDataTxt = self:FindWndTrans(self.mWinnerGroup, "NoDataTxt")
	local pbData = self._pbData[btnIndex]
	local otherData = pbData.other
	CS.ShowObject(dataGroup, otherData ~= nil and otherData.head ~= 0)
	CS.ShowObject(noDataTxt, otherData == nil or otherData.head == 0)
	if (otherData and otherData.head ~= 0) then
		local headIcon = self:FindWndTrans(dataGroup, "HeadIcon")
		local luckyDrawTxt = self:FindWndTrans(dataGroup, "LuckyDrawTxt")
		local nameTxt = self:FindWndTrans(dataGroup, "NameTxt")
		self:SetHeadIcon({
			trans = headIcon,
			icon = otherData.head,
			headFrame = otherData.headFrame,
			level = otherData.level,
		}, 1)
		self:SetPlayerName(nameTxt, otherData.serverId, otherData.name)
		local luckDrawStr = string.replace(ccClientText(29619), otherData.luckyNum)
		self:SetWndText(luckyDrawTxt, luckDrawStr)
		self:SetWndClick(headIcon, function()
			gModelGeneral:PlayerShowReq(otherData.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
		end)
	else
		self:SetWndText(noDataTxt, ccClientText(29618))
	end
	self:SetWndText(titleTxt, ccClientText(29622))
end

function UIAnniversaryDTDKoiNews:SetBotBtnTransSelect(btnIndex)
	for i, v in pairs(self.botBtnTransList) do
		local seleImg = self:FindWndTrans(v, "SelectImg")
		CS.ShowObject(seleImg, btnIndex == i)
	end
end

function UIAnniversaryDTDKoiNews:SetPbData(dataList)
	self._pbData = {}
	if (dataList and #dataList > 0) then
		for i, v in pairs(dataList) do
			local data = {
				sid = v.sid,
				other = self:GetLuckNumNewsPlayerInfo(v.other),
				my = self:GetLuckNumNewsPlayerInfo(v.my),
				reward = v.reward,
				receive = v.receive,
				date = v.date
			}
			if (data and not table.isempty(data)) then
				table.insert(self._pbData, data)
			end
		end
	end
end

function UIAnniversaryDTDKoiNews:OnActivitySpecialOpResp(pb)
	if(pb.opType == ModelActivity.LUCKY_NUM_RECEIVE)then
		gModelActivity:OnActivitySpecialOpReq(self._sid, 1, nil, ModelActivity.LUCKY_MUM_NEWS)
	end
end
function UIAnniversaryDTDKoiNews:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end
	self._cfgData = data.chunk[1].entries
	self:SetUI()
end
--领取按钮
function UIAnniversaryDTDKoiNews:SetGetBtn(btnIndex)
	local pbData = self._pbData[btnIndex]
	local dataGroup = self:FindWndTrans(self.mMyRewardGroup, "DataGroup")
	local btnTrans = self:FindWndTrans(dataGroup, "GetBtn")
	local btnTxt = self:FindWndTrans(btnTrans, "Txt")
	local isReceive = pbData.receive == 1
	local btnStr = isReceive and ccClientText(29616) or ccClientText(29615)--已领取/领取
	self:SetWndText(btnTxt, btnStr)
	local btnPath = isReceive and "public_btn_ash_2" or "public_btn_2_2"
	self:SetWndEasyImage(btnTrans, btnPath)
	CS.EnableClickListener(btnTrans.gameObject, not isReceive)
	self:SetWndClick(btnTrans, function()
		if (not isReceive) then
			gModelActivity:OnActivitySpecialOpReq(self._sid, 1, nil, ModelActivity.LUCKY_NUM_RECEIVE, tostring(pbData.date))
		end
	end)
end
--奖励子项
function UIAnniversaryDTDKoiNews:RewardListItem(list, item, itemdata, itempos)
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
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	--self:SetWndText(itemNum, itemdata.itemNum)
	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end
--设置我的奖励
function UIAnniversaryDTDKoiNews:SetMyRewardGroup(btnIndex)
	local titleTxt = self:FindWndTrans(self.mMyRewardGroup, "TitleTxt")
	local dataGroup = self:FindWndTrans(self.mMyRewardGroup, "DataGroup")
	local noDataGroup = self:FindWndTrans(self.mMyRewardGroup, "NoDataGroup")
	local pbData = self._pbData[btnIndex]
	local myData = pbData.my
	local rank = myData.rank
	CS.ShowObject(dataGroup, myData and rank and rank~=0)
	CS.ShowObject(noDataGroup, myData == nil or not rank or rank==0)
	if (myData and rank and rank~=0) then
		local rewardScroll = self:FindWndTrans(dataGroup, "RewardScroll")
		local headIcon = self:FindWndTrans(dataGroup, "HeadIcon")
		local rewardNameTxt = self:FindWndTrans(dataGroup, "RewardNameTxt")
		local myDrawTxt = self:FindWndTrans(dataGroup, "MyDrawTxt")
		local nameTxt = self:FindWndTrans(dataGroup, "NameTxt")
		local rankIcon = self:FindWndTrans(dataGroup, "RankIcon")
		--头像信息
		self:SetHeadIcon({
			trans = headIcon,
			icon = myData.head,
			headFrame = myData.headFrame,
			level = myData.level,
		}, 2)
		self:SetPlayerName(nameTxt, myData.serverId, myData.name)
		--我的号码
		local myDrawStr = string.replace(ccClientText(29620), myData.luckyNum)
		self:SetWndText(myDrawTxt, myDrawStr)
		--名次图标
		local rankIconPath = self._cfgData[rank].moreInfo
		self:SetWndEasyImage(rankIcon, rankIconPath)
		--名次文本
		local rankNameStr = self._cfgData[rank].name
		self:SetWndText(rewardNameTxt, rankNameStr)
		--领取按钮
		self:SetGetBtn(btnIndex)
		--奖励列表
		local rewardDataList = LxDataHelper.ParseItem(pbData.reward) or {}
		local rewardList = self:GetUIScroll(rewardScroll:GetInstanceID())
		if (rewardList:GetList()) then
			rewardList:RefreshList(rewardDataList)
		else
			rewardList:Create(rewardScroll, rewardDataList, function(...)
				self:RewardListItem(...)
			end)
		end
		rewardList:EnableScroll(#rewardDataList > 4, true)
	else
		local goToBtn = self:FindWndTrans(noDataGroup, "GoToBtn")
		local goToBtnTxt = self:FindWndTrans(goToBtn, "Txt")
		local noDataTxt = self:FindWndTrans(noDataGroup, "NoDataTxt")
		self:SetWndClick(goToBtn, function()
			self:WndClose()
			GF.OpenWnd("UIAnniversaryDTDKoi", { sid = self._sid })--打开每日锦鲤界面
		end)
		self:SetWndText(goToBtnTxt, ccClientText(29621))--前 往
		self:SetWndText(noDataTxt, ccClientText(29624))--您未参与本次抽奖
	end
	self:SetWndText(titleTxt, ccClientText(29623))--我的奖励
end
function UIAnniversaryDTDKoiNews:GetLuckNumNewsPlayerInfo(data)
	local resultData
	if (data) then
		resultData = {
			name = data.name,
			head = data.head,
			headFrame = data.headFrame,
			level = data.level,
			serverId = data.serverId,
			luckyNum = data.luckyNum,
			rank = data.rank,
			playerId = data.playerId,
		}
		return resultData
	end
end
function UIAnniversaryDTDKoiNews:InitBtnEvent()
	self:SetWndClick(self.mMask, function()
		self:WndClose()--关闭按钮
	end, LSoundConst.CLICK_CLOSE_COMMON)
end
--消息事件监听初始化
function UIAnniversaryDTDKoiNews:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)    --活动配置
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		--gModelActivity:OnActivityPageReq(self._sid)
		--gModelActivity:OnActivitySpecialOpReq(self._sid, 1, nil, ModelActivity.LUCKY_MUM_NEWS)
	end)
end

function UIAnniversaryDTDKoiNews:OnLuckyNumNewsResp(pb)
	if(not pb)then
		return
	end
	local news = pb.news
	self._sid =  pb.sid or self._sid
	self:SetPbData(news)
	gModelActivity:ReqActivityConfigData(self._sid)
end
------------------------------------------------------------------
return UIAnniversaryDTDKoiNews


