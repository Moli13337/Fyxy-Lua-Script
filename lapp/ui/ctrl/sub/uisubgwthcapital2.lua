---
--- Created by Administrator.
--- DateTime: 2023/10/19 15:30:14
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGwthCapital2:LChildWnd
local UISubGwthCapital2 = LxWndClass("UISubGwthCapital2", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGwthCapital2:UISubGwthCapital2()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGwthCapital2:OnWndClose()
	if self._itemUIList then
		self._itemUIList:OnWndClose()
	end
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGwthCapital2:OnCreate()
	self._uiCommonList = {}
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGwthCapital2:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitMsg()
	self:InitData()
end

function UISubGwthCapital2:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end
	self:SetTop()
	gModelActivity:OnActivityPageReq(self._sid)
end
function UISubGwthCapital2:RefreshUI(page)
	local dataList = {}
	page = gModelActivity:GenerateActivePageDataFromPb(page)
	self:GetCruGoodsIndex(page.entry)
	self._rewardList = {}
	for k, v in ipairs(page.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, v.entryId)
		if not entryCfg then
			return
		end
		local moreInfo = JSON.decode(v.moreInfo).moreInfo
		local moreInfoArr = string.split(moreInfo,"|")
		if(tonumber(moreInfoArr[1]) == self.curGoodsIndex)then
			local entryId = v.entryId
			local reward = LxDataHelper.ParseItem(entryCfg.reward)
			local data = {
				entryId = entryId,
				title = entryCfg.name,
				desc = entryCfg.description,
				icon = entryCfg.icon,
				state = v.goalData.status, --(0-不可领取, 1-可领取，2-已领取)
				rewards = reward,
			}
			table.insert(dataList, data)

			local conditions = string.split(entryCfg.condition, '=')
			local rewardData = {
				entryId = entryId,
				rewards = reward,
				needLvl = tonumber(conditions[3]),
			}
			table.insert(self._rewardList, rewardData)
		end
	end
	table.sort(dataList, function(a, b)
		local aPrio = self._statePriority[a.state] or 1
		local bPrio = self._statePriority[b.state] or 1
		if aPrio ~= bPrio then
			return aPrio < bPrio
		end
		return a.entryId < b.entryId
	end)
	local isGet = false
	for i, v in ipairs(dataList) do
		if (v.state == 1) then
			isGet = true
			break
		end
	end
	self._dataList = dataList

	if (not isGet) then
		gModelRedPoint:SetActivityRedClicked(self._sid)
	end
	self:InitItemList(dataList)
	self:RefreshDescIcon()
end

function UISubGwthCapital2:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
		self:OnActivityPageResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp, function()
		self:SetTop()
		self:CheckAutoGet()
	end)

	self:SetWndClick(self.mBuyTipsBtn, function(...)
		self:OnClickByTips()
	end)
end

function UISubGwthCapital2:Buy()
	if self._buyState ~= 1 then
		self._isClickBuy = true
		self._oldBuyState = self._buyState
		GF.OpenWnd("UIPkBuyPopBig",
				{ sid = self._sid, entry = self._rewardList,
				  modelActivityType = ModelActivity.Growth_Capital_2,
				  priceEntry = self.priceEntry
				})
	end
end
--获取当前档次
function UISubGwthCapital2:GetCruGoodsIndex(entry)
	for k, v in ipairs(entry) do
		local moreInfo = JSON.decode(v.moreInfo).moreInfo
		local goalData = v.goalData
		local state = goalData.status
		if(state== 0 or state == 1)then
			local moreInfoArr = string.split(moreInfo,"|")
			self.curGoodsIndex = tonumber(moreInfoArr[1])
			break
		end
	end
	if(self.oldGoodsIndex and self.oldGoodsIndex~=self.curGoodsIndex)then
		self:RefreshGoods()
	end
	self.oldGoodsIndex = self.curGoodsIndex
end

function UISubGwthCapital2:InitData()
	self._sid = self:GetWndArg("sid")
	self._entryIdToIndex = {}
	self._btnStrs = {
		[0] = ccClientText(12206), -- "未完成"),
		[1] = ccClientText(12207), --"领  取",
		[2] = ccClientText(12208), --"已领取",
	}
	---(0-不可领取, 1-可领取，2-已领取)
	self._statePriority = {
		[0] = 2,
		[1] = 1,
		[2] = 3,
	}

	self._isClickBuy = false
	self._oldBuyState = nil

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubGwthCapital2:RefreshDescIcon()
	local data = self._config
	if not data then return end
	local number = data["number"..self.curGoodsIndex]
	if not string.isempty(number) then
		self:SetWndText(self.mDescIconNumA, number)
		local numberPost = data.numberPost
		if not string.isempty(numberPost) then
			self:SetAnchorPos(self.mDescIconNumA, LxDataHelper.ParseVector2NotEmpty(numberPost))
		end
		CS.ShowObject(self.mDescIconNumA, true)
	end
end
function UISubGwthCapital2:OnActivityReceiveGoalResp(pb, ret)
	if self._sid ~= pb.sid or self._pageId ~= pb.pageId then
		return
	end
	local index = self._entryIdToIndex[pb.entryId]
	if not index then
		return
	end
	local list = self._itemUIList:GetList()
	local data = list:GetDataByIndex(index)
	data.state = 2
	list:DrawItemByIndex(index)
end

function UISubGwthCapital2:OnClickEntry(itemdata)
	local state = itemdata.state
	if state == 0 then
		GF.ShowMessage(ccClientText(12215)) --"未完成"
	elseif state == 1 then
		if self._buyState == 0 then
			local func = function()
				self:Buy()
			end
			func()
		else
			local sid = self._sid
			local pageId = self._pageId
			local entryId = itemdata.entryId
			gModelActivity:OnActivityReceiveGoalReq(sid, pageId, entryId)
		end
	elseif state == 2 then
		GF.ShowMessage(ccClientText(15807))
	end
end

function UISubGwthCapital2:OnTimer(key)
	if key == "delaySetRect" then
		self:ChangeEffMaskRect()
	end
end

function UISubGwthCapital2:OnClickOneKeyGet()
	--一键领取
	local list = {}
	for i, v in ipairs(self._dataList) do
		if (v.state == 1) then
			local data1 = { sid = self._sid, pageId = self._pageId, entryId = v.entryId }
			table.insert(list, data1)
		end
	end

	if #list == 0 then
		return
	end

	gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UISubGwthCapital2:InitItemList(dataList)
	if (self._itemUIList) then

		self._itemUIList:RefreshList(dataList)
	else
		self._itemUIList = self:GetUIScroll("itemList")
		self._itemUIList:Create(self.mItemList, dataList, function(...)
			self:OnDrawItem(...)
		end, UIItemList.WRAP)
	end
end

function UISubGwthCapital2:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end
	local page =pb.pages
	if not page then
		return
	end
	for i, v in ipairs(page) do
		if(v.pageType == 3)then
			self:RefreshGoods(v)
			self:InitItemList(self._dataList)
		else
			self:RefreshUI(v)
			self._pageId = v.pageId
		end
	end
end

function UISubGwthCapital2:RefreshGoods(page)
	local pageData
	if(not page)then
		pageData = self.tmpPageData
	else
		pageData = gModelActivity:GenerateActivePageDataFromPb(page)
	end
	self.tmpPageData = pageData
	local entry = pageData.entry
	local curGoodsIndex = self.curGoodsIndex
	local curEntryData = entry[curGoodsIndex]
	local marketData = curEntryData.MarketData
	local personal = marketData.personal
	local personalGoal = marketData.personalGoal
	local buyState = personalGoal-personal>0 and 0 or 1
	self._buyState = buyState
	if (curEntryData ~= nil) then
		local priceArr = string.split(self._buyPrice, ";")
		local priceId
		for i, v in pairs(priceArr) do
			local priceData = string.split(v, "=")
			if (tonumber(priceData[2]) == curEntryData.entryId) then
				priceId = tonumber(priceData[1])
				break
			end
		end
		self.priceEntry = {
			priceId = priceId,
			entryId = self.curGoodsIndex
		}
		local rmbPayPoint = gModelPay:GetRMBValueByWelfareId(priceId)
		if rmbPayPoint then
			local str
			self._rmbPayPoint = rmbPayPoint
			if self._buyState == 0 then
				str = gModelPay:GetShowByWelfareId(priceId) --string.replace(ccClientText(15601),rmbPayPoint)
			else
				str = ccClientText(15808)
			end
			self:SetWndButtonText(self.mPayBtn, str)
			self:SetWndClick(self.mPayBtn, function()
				self:Buy()
			end)
		end

	end
	self:SetWndButtonGray(self.mPayBtn, buyState == 1)
	CS.EnableClickListener(self.mPayBtn.gameObject, buyState ~= 1)
	CS.ShowObject(self.mPayBtn, buyState == 0)
	CS.ShowObject(self.mStatusImg, buyState ~= 0)
end

function UISubGwthCapital2:CheckAutoGet()
	if not self._oldBuyState or self._oldBuyState == self._buyState then
		return
	end

	if self._oldBuyState ~= 1 and self._buyState == 1 then
		self._oldBuyState = nil
		self:OnClickOneKeyGet()
	end
end

function UISubGwthCapital2:SetTop()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end

	local activityMoreInfo = JSON.decode(activityData.moreInfo)

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	local data = webData.config
	self._config = data
	local path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop, path)
	end
	path = data.descIconA
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mDescIconA, path, function()
			CS.ShowObject(self.mDescIconA, true)
		end, true)
	end

	local text = ccClientText(156)
	if not string.isempty(text) then
		self._helpTipsContent = text
		self:SetWndText(self.mBuyTipsText, text)
		CS.ShowObject(self.mBuyTipsText, true)
	end

	CS.ShowObject(self.mHelpBtn, data.helpTips == 1)
	self:SetWndClick(self.mHelpBtn, function()
		GF.OpenWnd("UIBzTips", { title = activityData.title, text = data.helpTipsContent })
	end)

	local price = data.price
	self._buyPrice = price
end

function UISubGwthCapital2:OnClickByTips()
	if not self._helpTipsContent then
		return
	end

	local title = gModelActivity:GetLngNameByActivitySid(self._sid)
	GF.OpenWnd("UIBzTips", { title = title, text = self._helpTipsContent })
end

function UISubGwthCapital2:OnDrawItem(list, item, itemdata, itempos)
	local state = itemdata.state
	local entryId = itemdata.entryId
	local titleTrans = self:FindWndTrans(item, "title")
	if titleTrans then
		self:SetWndText(titleTrans, itemdata.title)
	end
	local yaoqiuTxtTrans = self:FindWndTrans(item, "yaoqiuTxt")
	if yaoqiuTxtTrans then
		self:SetWndText(yaoqiuTxtTrans, itemdata.desc)
	end
	local btnTrans = self:FindWndTrans(item, "btn")
	if btnTrans then
		local EffTrans = self:FindWndTrans(btnTrans, "Eff")
		local InstanceID = item:GetInstanceID()
		self:DestroyWndEffectByKey(InstanceID)

		local showBtn = state ~= 2
		local showEff = state == 1
		if self._buyState == 0 then
			showEff = false
		end

		CS.ShowObject(EffTrans, showBtn)

		CS.ShowObject(btnTrans, showBtn)
		if showBtn then
			if showEff then
				self:CreateWndEffect(EffTrans, "fx_anniu_02", InstanceID, 100)
				CS.ShowObject(EffTrans, true)
			end

			self:SetWndClick(btnTrans, function()
				self:OnClickEntry(itemdata)
			end)
			self:SetWndButtonText(btnTrans, state == 1 and ccClientText(12207) or ccClientText(12217))
			self:SetWndButtonGray(btnTrans, state ~= 1)
		end
	end
	local stateImgTrans = self:FindWndTrans(item, "stateImg")
	if stateImgTrans then
		CS.ShowObject(stateImgTrans, state == 2)
	end
	local rewards = itemdata.rewards[1]

	local root = self:FindWndTrans(item, "Icon")

	local formatData = {
		itemId = rewards.itemId,
		itemType = rewards.itemType,
		itemNum = rewards.itemNum,
	}
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(formatData.itemType, formatData.itemId, -1)
	baseClass:DoApply()
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(formatData)
	end)

	local ItemNumTrans = self:FindWndTrans(item, "ItemNum")
	if ItemNumTrans then
		self:SetWndText(ItemNumTrans, formatData.itemNum)
	end
	self._entryIdToIndex[itemdata.entryId] = itempos
end

------------------------------------------------------------------
return UISubGwthCapital2


