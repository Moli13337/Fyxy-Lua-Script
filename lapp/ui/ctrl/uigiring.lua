---
--- Created by Administrator.
--- DateTime: 2024/7/8 20:48:14
---
------------------------------------------------------------------
local LWnd = LWnd
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local typeofCanvas = typeof(UnityEngine.Canvas)
-- local UIClipProxy = CS.UIClipProxy
-- local typeUIClipProxy = typeof(UIClipProxy)
---@class UIGiring:LWnd
local UIGiring = LxWndClass("UIGiring", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGiring:UIGiring()
	self.itemIconList = {}
	self.effList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGiring:OnWndClose()
	self:ClearTimer()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGiring:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGiring:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()

	self.sid = self:GetWndArg("sid")
	self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
	gModelActivity:ReqActivityConfigData(self.sid)
	gModelActivity:OnActivityPageReq(self.sid)
	gModelActivity:CheckActivityClickRed(true, self.sid)

	local canvas = self.mCloseBtn:GetComponent(typeofCanvas)
	canvas.sortingOrder = self:GetWndSortOrder() + 4
end

function UIGiring:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(_, sid)
		self:InitData(_, sid)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_PAGE_CHANGE, function(...)
		self:InitDatas(...)
	end)

	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:SetWndClick(self.mTipsBtn, function()
		GF.OpenWnd("UIBzTips", { title = self.uiCfg.name, text = self.uiCfg.helpTipsContent })
	end)
end

function UIGiring:SetTimeStr()
	local curTime = self.endTime - GetTimestamp()
	if curTime > 0 then
		local str = string.replace(ccClientText(15610), LUtil.FormatTimespanCn(curTime))
		self:SetWndText(self.mTimeText, string.replace(self.timeTextColor, str))
	else
		self:SetWndText(self.mTimeText, ccClientText(14301))
		self:ClearTimer()
	end
	LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTimeText)
end

function UIGiring:CreateItemIcon(root, itemData)
	if not itemData then
		return
	end
	local instanceId = root:GetInstanceID()
	if not self.itemIconList[instanceId] then
		self.itemIconList[instanceId] = CommonIcon:New()
		self.itemIconList[instanceId]:Create(root)
	end
	self.itemIconList[instanceId]:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
	self.itemIconList[instanceId]:DoApply()
	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
end

function UIGiring:ClearTimer()
	if self.timer then
		LxTimer.DelayTimeStop(self.timer)
		self.timer = nil
	end
end

function UIGiring:SetGiftList(list)
	self.listLen = #list

	for i, v in ipairs(list) do
		local itemName = "item" .. i
		local item = CS.FindTrans(self.mContent, itemName)
		if not item then
			local gameObj = LxUnity.InstantObject(self.mItemTemplate.gameObject)
			gameObj.name = itemName
			item = gameObj.transform
			LxUnity.SetParentTrans(item, self.mContent)
			CS.ShowObject(item, true)
		end
		self:DrawGift(item, v, i)
	end
end

function UIGiring:CreateTimer()
	self:ClearTimer()
	self:SetTimeStr()
	self.timer = LxTimer.LoopTimeCall(function()
		self:SetTimeStr()
	end, 1, false, -1)
end

function UIGiring:DrawGift(item, data, pos)
	local light = CS.FindTrans(item, "Light")
	local itemBg = CS.FindTrans(item, "ItemBg")
	local itemEff = CS.FindTrans(item, "Eff")
	local discountBg = CS.FindTrans(itemBg, "DiscountBg")
	local discountText = CS.FindTrans(discountBg, "DiscountText")
	local buyBtn = CS.FindTrans(itemBg, "BuyBtn")
	local buyBtnIcon = CS.FindTrans(buyBtn, "ItemIcon")
	local buyBtnText = CS.FindTrans(buyBtn, "Text")
	local buyBtnLock = CS.FindTrans(buyBtn, "Lock")
	local redpoint = CS.FindTrans(buyBtn, "redPoint")
	local getBg = CS.FindTrans(itemBg, "GetBg")
	local getText = CS.FindTrans(getBg, "GetText")
	local itemObj = CS.FindTrans(itemBg, "ItemObj")
	local jia = CS.FindTrans(itemObj, "Jia")
	local addItem = CS.FindTrans(itemObj, "AddItem")
	local add = CS.FindTrans(addItem, "Add")
	local addItemRoot = CS.FindTrans(addItem, "ItemRoot")
	local changeBtn = CS.FindTrans(addItem, "ChangeBtn")
	local link = CS.FindTrans(item, "Link")

	local instanceId = item:GetInstanceID()
	local key = instanceId .. "itemBg"
	if not self.effList[key] then
		local canvas = itemBg:GetComponent(typeofCanvas)
		canvas.sortingOrder = self:GetWndSortOrder() + 3
		local canvas = itemEff:GetComponent(typeofCanvas)
		canvas.sortingOrder = self:GetWndSortOrder() + 2
		self.effList[key] = self:CreateWndEffect(itemEff, "fx_ui_act154_paopao", key, 100, false, false)
		CS.ShowObject(item, false)
		local uiClipProxy = itemBg:GetComponent(typeof(UIClipProxy))
		LxTimer.DelayTimeCall(function()
			uiClipProxy:AddFunc()
			CS.ShowObject(item, true)
		end, 0.1)
	end
	key = instanceId .. "light"
	if not self.effList[key] then
		local canvas = light:GetComponent(typeofCanvas)
		canvas.sortingOrder = self:GetWndSortOrder() + 1
		self.effList[key] = self:CreateWndEffect(light, "fx_ui_act154_guang", key, 100, false, false)
	end
	key = instanceId .. "link"
	if not self.effList[key] then
		self.effList[key] = self:CreateWndEffect(link, "fx_ui_act154_lianjie", key, 100, false, false)
	end

	self:SetAnchorPos(itemBg, Vector2.New(pos % 2 == 1 and -137 or 137, 0))
	self:SetAnchorPos(itemEff, Vector2.New(pos % 2 == 1 and -137 or 137, 0))
	self:SetAnchorPos(light, Vector2.New(pos % 2 == 1 and -137 or 137, 0))
	self:SetAnchorPos(link, Vector2.New(pos % 2 == 1 and 141 or -141, 0))
	link.localRotation = Quaternion.Euler(0, pos % 2 == 0 and 180 or 0, 0)

	local discount = data.MarketData.discount or 0
	self:SetWndText(discountText, discount .. "%")
	CS.ShowObject(discountBg, discount > 0)
	CS.ShowObject(link, pos ~= self.listLen)

	local s = ccClientText(14903)
	local textId = 15618
	if data.MarketData.expendType == 1 then
		local item = LxDataHelper.ParseItem_4(data.MarketData.expend2)
		local icon = gModelGeneral:GetCommonItemImgRef(item)
		self:SetWndEasyImage(buyBtnIcon, icon)
		s = item.itemNum
		textId = 15623
	elseif data.MarketData.expendType == 2 then
		s = gModelPay:GetShowByWelfareId(tonumber(data.MarketData.expend2))
		textId = 15623
	end
	self:SetWndText(buyBtnText, s)
	LxTimer.DelayTimeCall(function()
		LayoutRebuilder.ForceRebuildLayoutImmediate(buyBtnText)
	end, 0.1)
	self:SetWndText(getText, ccClientText(textId))
	CS.ShowObject(buyBtn, data.MarketData.personal == 0)
	CS.ShowObject(buyBtnIcon, data.MarketData.expendType == 1)
	-- CS.ShowObject(getBg, data.MarketData.personal == 1)
	CS.ShowObject(buyBtnLock, self.curGift + 1 < data.entryId)
	CS.ShowObject(light, self.curIndex == data.entryId)
	CS.ShowObject(redpoint, data.MarketData.expendType == 0 and self.curGift + 1 >= data.entryId)

	for i = 1, 4 do
		local root = CS.FindTrans(itemObj, "Item" .. i)
		if data.items[i] then
			local itemData = {
				itemType = data.items[i].type,
				itemId = data.items[i].itemId,
				itemNum = data.items[i].count
			}
			self:CreateItemIcon(root, itemData)
		end
		CS.ShowObject(root, data.items[i] ~= nil)
	end
	local isSelectItem = data.MarketData.customList and not string.isempty(data.MarketData.customList)
	local selectItem = LxDataHelper.ParseItem_4(data.MarketData.customGift) or {}
	self:CreateItemIcon(addItemRoot, selectItem)
	CS.ShowObject(jia, isSelectItem)
	CS.ShowObject(addItem, isSelectItem)
	CS.ShowObject(addItemRoot, isSelectItem and not table.isempty(selectItem))
	CS.ShowObject(changeBtn, isSelectItem and not table.isempty(selectItem) and data.MarketData.personal ~= 1)

	self:SetWndClick(add, function()
		self:OpenUICumSelectNew(data)
	end)
	self:SetWndClick(addItem, function()
		self:OpenUICumSelectNew(data)
	end)
	self:SetWndClick(buyBtn, function()
		if self.curGift + 1 >= data.entryId then
			if isSelectItem and table.isempty(selectItem) then
				GF.ShowMessage(ccClientText(44602))
				self:OpenUICumSelectNew(data)
				return
			end
			self:ClickBuyBtn(data)
		else
			GF.ShowMessage(ccClientText(44601))
		end
	end)
end

function UIGiring:ClickBuyBtn(data)
	if self.endTime - GetTimestamp() < 0 then
		GF.ShowMessage(ccClientText(29200))
		return
	end
	if data.MarketData.expendType == 0 then
		gModelActivity:OnActivityMarkeyBuyReq(self.sid, self.pageId, data.entryId)
	elseif data.MarketData.expendType == 1 then
		local item = LxDataHelper.ParseItem_4(data.MarketData.expend2)
		local name = gModelGeneral:GetCommonItemName(item)
		local func = function()
			if gModelGeneral:CheckItemEnough(item.itemId, item.itemNum, true, self:GetWndName()) then
				gModelActivity:OnActivityMarkeyBuyReq(self.sid, self.pageId, data.entryId)
			end
		end
		local para =
		{
			refId = 50401,
			func = func,
			para = { item.itemNum .. name, data.title },
			consume = { item.itemNum, item.itemId },
		}
		gModelGeneral:OpenUIOrdinTips(para)
	elseif data.MarketData.expendType == 2 then
		gModelPay:GiftPayCtrl(data.entryId, tonumber(data.MarketData.expend2), ModelPay.PAY_TYPE_ACTIVITY, nil, self.sid, self.pageId)
	end
end

function UIGiring:InitData(_, sid)
	if sid ~= self.sid then return end

	local activityData = gModelActivity:GetActivityBySid(self.sid)
	if not activityData then return end

	local activityCfg = gModelActivity:GetWebActivityDataById(self.sid)
	if not activityCfg then return end
	self.uiCfg = activityCfg.config

	if not string.isempty(self.uiCfg.descIcon) then
		self:SetWndEasyImage(self.mBanner, self.uiCfg.descIcon, nil, true)
	end
	self:SetAnchorPos(self.mBanner, LxDataHelper.ParseVector(self.uiCfg.descIconPosition))

	self:SetWndText(self.mDesText, self.uiCfg.desc)
	self:SetAnchorPos(self.mDesBg, LxDataHelper.ParseVector(self.uiCfg.descPos))

	CS.ShowObject(self.mTimeBg, self.uiCfg.endTime == 1)
	self.timeTextColor = "<color=#" .. self.uiCfg.timeTxtColor .. ">#a1#</color>"
	self:SetAnchorPos(self.mTimeBg, LxDataHelper.ParseVector(self.uiCfg.endTimePosition))

	CS.ShowObject(self.mTipsBtn, self.uiCfg.helpTips == 1)
	self:SetAnchorPos(self.mTipsBtn, LxDataHelper.ParseVector(self.uiCfg.helpTipsPosition))

	if not string.isempty(self.uiCfg.ImageHero) then
		local imageInfo = string.split(self.uiCfg.ImageHero, "=")
		if imageInfo[1] == "1" then
			self:SetWndEasyImage(self.mRoleImage, imageInfo[2])
			self:SetAnchorPos(self.mRoleImage, imagePos)
			CS.ShowObject(self.mRoleImage, true)
		elseif imageInfo[1] == "2" then
			self:CreateWndSpine(self.mRoleSpine, imageInfo[2], "heroSpineKey", false)
			CS.ShowObject(self.mRoleSpine, true)
		end
	end

	self.endTime = activityData.endTime
	self:CreateTimer()
end

function UIGiring:OpenUICumSelectNew(data)
	local t = {
		sid = self.sid,
		pageId = self.pageId,
		entryId = data.entryId,
		itemIndex = 1,
		giftData = data,
		title = data.title,
	}
	GF.OpenWnd("UICumSelectNew", t)
end

function UIGiring:InitDatas(_, sid, pages)
	if sid ~= self.sid then
		return
	end

	local moreInfo = JSON.decode(pages[1].moreInfo)
	self.curGift = moreInfo.giftRefId
	self.pageId = pages[1].pageId

	local list = pages[1].entry
	table.sort(list, function(a, b)
		return a.sort < b.sort
	end)
	local needMove = false
	for i, v in ipairs(list) do
		if v.MarketData.personal == 0 then
			if self.curIndex ~= i then
				self.curIndex = i
				needMove = true
			end
			break
		end
	end
	self:SetGiftList(list)
	if needMove then
		LxTimer.DelayTimeCall(function()
			local y = (self.curIndex - 1) * 226
			self:SetAnchorPos(self.mContent, Vector2.New(0, y))
		end, 0.2)
	end
end



------------------------------------------------------------------
return UIGiring