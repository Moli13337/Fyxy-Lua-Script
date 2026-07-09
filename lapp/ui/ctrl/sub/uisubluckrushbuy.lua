---
--- Created by BY.
--- DateTime: 2023/10/19 14:16:03
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubLuckRushBuy:LChildWnd
local UISubLuckRushBuy = LxWndClass("UISubLuckRushBuy", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubLuckRushBuy:UISubLuckRushBuy()
	self._timeEndKey = "timeEndKey"
	self._timeStartKey = "timeStartKey"
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubLuckRushBuy:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubLuckRushBuy:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubLuckRushBuy:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubLuckRushBuy:ItemListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local root1 = CS.FindTrans(item,"Root1")
	local root2 = CS.FindTrans(item,"Root2")

	CS.ShowObject(root1,false)
	CS.ShowObject(root2,false)
	local type = itemdata.type
	local itemRoot
	local originalText,originalIcon
	local marketData = itemdata.MarketData
	local expendType = marketData.expendType
	local originalStr,originalStr2 = marketData.expend1,marketData.expend2
	local money,money2 = "",""
	local isPersonal,buyBtn,buyCountBtn,buyCountText,buyCountIcon
	local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
	if type == 1 then
		CS.ShowObject(root1,true)
		itemRoot = CS.FindTrans(root1,"ItemIcon")
		originalText = CS.FindTrans(root1,"OriginalObj/OriginalText")
		originalIcon = CS.FindTrans(root1,"OriginalObj/OriginalIcon")
		local nameText = CS.FindTrans(root1,"NameText")
		local buyMask = CS.FindTrans(root1,"BuyMask")
		buyCountBtn = CS.FindTrans(root1,"BuyCountBtn")
		buyCountText = CS.FindTrans(root1,"BuyCountBtn/BuyCountText")
		buyCountIcon = CS.FindTrans(root1,"BuyCountBtn/BuyCountText/BuyCountIcon")
		buyBtn = CS.FindTrans(root1,"BuyBtn")
		local buyNum = CS.FindTrans(root1,"BuyNum")

		local _item = itemList[1]
		local itemName = gModelGeneral:GetItemName(_item.itemType,_item.itemId,nil,nil,_item)
		self:SetWndText(nameText,itemName)
		local marketBuyNum = marketData.personalGoal - marketData.personal
		isPersonal = marketBuyNum > 0
		CS.ShowObject(buyMask,not isPersonal)
		if marketData.serverGoal > 0 then
			self:SetWndText(buyNum,string.replace(ccClientText(19234),marketData.serverGoal - marketData.server))
		end
	else
		CS.ShowObject(root2,true)
		itemRoot = CS.FindTrans(root2,"ItemIcon")
		originalText = CS.FindTrans(root2,"OriginalObj/OriginalText")
		originalIcon = CS.FindTrans(root2,"OriginalObj/OriginalIcon")
	end

	--local isItemBuy = string.find(originalStr,"=")
	if expendType == 0 then
		money = ccClientText(19246)
		money2 = ccClientText(19246)
		CS.ShowObject(originalIcon,false)
	elseif expendType == 1 then
		CS.ShowObject(originalIcon,true)
		local originalArr = string.split(originalStr,"=")
		local originalArr2 = string.split(originalStr2,"=")
		local icon = gModelItem:GetItemIconByRefId(tonumber(originalArr[2]))
		self:SetWndEasyImage(originalIcon,icon)
		if buyCountIcon then
			self:SetWndEasyImage(buyCountIcon,icon)
		end
		money = originalArr[3]
		money2 = LUtil.NumberCoversion(tonumber(originalArr2[3]))
	elseif expendType == 2 then
		CS.ShowObject(originalIcon,false)
		--money = gModelPay:GetRMBValueByWelfareId(tonumber(originalStr))
		money = string.replace(ccClientText(19206),originalStr)
		--money2 = gModelPay:GetRMBValueByWelfareId(tonumber(originalStr2))
		money2 = gModelPay:GetShowByWelfareId(tonumber(originalStr2)) -- string.replace(ccClientText(19206),money2)
		money = gModelPay:GetShowByWelfareId(tonumber(originalStr))
	end
	if type == 2 and expendType ~= 0 then
		money = "???"
		if expendType == 2 then
			--money = string.sub(money,1,1).."X"
			money = string.replace(ccClientText(19206),money)
		--else
		--	money = string.sub(money,1,1).."XX"
		end
	end
	if buyBtn then
		self:SetWndText(buyCountText,money2)
		self:SetWndButtonText(buyBtn,money2)
		CS.ShowObject(buyCountBtn,isPersonal and expendType == 1)
		CS.ShowObject(buyBtn,isPersonal and expendType ~= 1)
		self:SetWndClick(buyCountBtn,function ()
			self:OnClickBuyGift(itemdata,expendType ~= 2)
		end)
		self:SetWndClick(buyBtn,function ()
			self:OnClickBuyGift(itemdata,expendType ~= 2)
		end)
	end
	self:SetWndText(originalText,money)

	local _itemdata = itemList[1]
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()..type
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(itemRoot)
	end
	baseClass:SetCommonReward(_itemdata.itemType, _itemdata.itemId, _itemdata.itemNum)
	self:SetWndClick(itemRoot,function()
		gModelGeneral:ShowCommonItemTipWnd(_itemdata)
	end)
	baseClass:DoApply()
end

function UISubLuckRushBuy:InitEvent()

end

function UISubLuckRushBuy:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
end

function UISubLuckRushBuy:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		if self._pageId == v.pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self._entry = page.entry
			break
		end
	end
	self:RefreshData()
end

function UISubLuckRushBuy:OnTimer(key)
	if(key == self._timeEndKey)then
		self:SetTime(self._endTimeText,self._endTime,key)
	elseif(key == self._timeStartKey)then
		self:SetTime(self._startTimeText,self._startTime,key)
	end
end

function UISubLuckRushBuy:SetTime(text,time,key)
	local stime = GetTimestamp()
	local endTime = time
	local timespan = endTime - stime
	local timeStr = ""
	if(timespan <= 0)then
		self:TimerStop(key)
		gModelActivity:OnActivityPageReq(self._sid)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		if(key == self._timeEndKey)then
			timeStr = string.replace(ccClientText(19203),timeStr)
		elseif(key == self._timeStartKey)then
			timeStr = string.replace(ccClientText(19204),timeStr)
		end
	end
	self:SetWndText(text,timeStr)
end

function UISubLuckRushBuy:ListItem(list,item, itemdata, itempos)
	local titleText = CS.FindTrans(item,"TitleBg/TitleText")
	local timeText = CS.FindTrans(item,"TitleBg/TimeText")
	local itemScroll = CS.FindTrans(item,"ItemScroll")
	local desText = CS.FindTrans(item,"DesText")
	local title = ""
	self:SetWndText(timeText,"")
	if itemdata.type == 1 then
		title = ccClientText(19201)
		self._endTimeText = timeText
	elseif itemdata.type == 2 then
		if self._cellList[1] then
			title = ccClientText(19202)
		else
			title = ccClientText(19221)
		end
		self._startTimeText = timeText
	elseif itemdata.type == 3 then
		title = ccClientText(19202)
	end
	self:SetWndText(titleText,title)

	local list = itemdata.list

	local isEmpty = #list <= 0
	CS.ShowObject(desText,isEmpty)
	if isEmpty then
		local desStr = ""
		if self._cellList[1] then
			desStr = self._seckillEndTxt--ccClientText(19208)

		else
			desStr = self._seckillNextTxt--ccClientText(19207)
		end
		self:SetWndText(desText,desStr)
	end
	local InstanceID = item:GetInstanceID()
	local uilist = self:GetUIScroll("itemList"..InstanceID)
	if uilist:GetList() then
		uilist:RefreshList(list)
	else
		uilist:Create(itemScroll,list,function (...) self:ItemListItem(...) end)
	end
	uilist:EnableScroll(#list > 3,true)
end

function UISubLuckRushBuy:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UISubLuckRushBuy:OnClickBuyGift(itemdata,isItemBuy)
	if isItemBuy then
		gModelActivity:OnActivityMarkeyBuyReq(self._sid, itemdata.pageId, itemdata.entryId)
	else
		local welfareId = tonumber(itemdata.MarketData.expend2)
		gModelPay:GiftPayCtrl(itemdata.entryId,welfareId,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,itemdata.pageId)
	end
end

function UISubLuckRushBuy:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry

	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	local seckillHero,seckillHeroPos,seckillHeroTxt,seckillHeroTxtImage,seckillHeroTxtImagePos
	= data.seckillHero,data.seckillHeroPos,data.seckillHeroTxt,data.seckillHeroTxtImage,data.seckillHeroTxtImagePos
	local newImage,newImageFrame2
	= data.newImage1,data.newImageFrame2
	if LxUiHelper.IsImgPathValid(newImage) then
		local paint = self.mTopBg
		self:SetWndEasyImage(paint,newImage,function ()
			CS.ShowObject(paint,true)
		end ,true)
	end
	if not string.isempty(newImageFrame2) then
		local arr = string.split(newImageFrame2,"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			self:SetWndEasyImage(self.mTopImg,arr[1])
		end
		if LxUiHelper.IsImgPathValid(arr[2]) then
			self:SetWndEasyImage(self.mBottonImg,arr[2])
		end
		if LxUiHelper.IsImgPathValid(arr[3]) then
			self:SetWndEasyImage(self.mCentreImg,arr[3])
		end
	end
	if not string.isempty(seckillHero) then
		local paint
		local arr = string.split(seckillHero,"=")
		if arr[1] == "1" then
			paint = self.mHeroImg
			self:SetWndEasyImage(paint,arr[2],nil,true)
		elseif arr[1] == "2" then
			paint = self.mHeroPaint
			self:CreateWndSpine(paint,arr[2],"seckillHero")
		elseif tonumber(seckillHero) > 0 then
			local ref = gModelHero:GetShowEffectById(tonumber(seckillHero))
			if ref then
				paint = self.mHeroPaint
				self:CreateWndSpine(paint,ref.heroDrawing,"seckillHero",false,function(dpSpine)
					dpSpine:SetScale(0.8)
				end)
			end
		end
		if paint and not string.isempty(seckillHeroPos) then
			CS.ShowObject(paint,true)
			local pos = LxDataHelper.ParseVector2NotEmpty2(seckillHeroPos)
			self:SetAnchorPos(paint, pos)
		end
	end
	if seckillHeroTxt and seckillHeroTxt ~= "" then
		local str = string.gsub(seckillHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
	end
	if LxUiHelper.IsImgPathValid(seckillHeroTxtImage) then
		local paint = self.mTextImg
		self:SetWndEasyImage(paint,seckillHeroTxtImage,function ()
			CS.ShowObject(paint,true)
		end ,true)
		if paint and not string.isempty(seckillHeroTxtImagePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(seckillHeroTxtImagePos)
			self:SetAnchorPos(paint, pos)
		end
	end
	self._seckillNextTxt = data.seckillNextTxt
	self._seckillEndTxt = data.seckillEndTxt
	self._seckillEndEmpty = data.seckillEndEmpty
	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubLuckRushBuy:RefreshData()
	local _entry = self._entry or {}
	local periodsList = {}
	for i, v in ipairs(_entry) do
		local marketData = v.MarketData
		local day = string.split(marketData.day,"|")
		local time = string.split(marketData.time,"|")
		local timestamp = LUtil.OSTime({ year = tonumber(day[1]), month = tonumber(day[2]), day = tonumber(day[3]), hour = tonumber(time[1]), minute = tonumber(time[2]), second = tonumber(time[3])})
		local continueTime = marketData.continueTime
		local sTime = GetTimestamp()
		if timestamp + continueTime > sTime then
			local type = 1
			local countDownTime = 0
			if timestamp > sTime then
				type = 2
				countDownTime = timestamp
			else
				countDownTime = timestamp + continueTime
			end
			local periods = marketData.periods
			local data = periodsList[periods]

			if not data then
				data = {
					timestamp = countDownTime,
					periods = periods,
					type = type,
					list = {}
				}
			end
			v.type = type
			table.insert(data.list,v)
			periodsList[periods] = data
		end
	end
	local list = {}
	for i, v in pairs(periodsList) do
		table.insert(list,v)
	end
	table.sort(list,function (a,b)
		return a.periods < b.periods
	end)
	local periodsList = list
	local cellList = {}
	local list = {}
	for i, v in pairs(periodsList) do
		local type = v.type
		if not cellList[type] then
			cellList[type] = v
			table.insert(list,v)
		end
		if cellList[2] then
			break
		end
	end
	self._cellList = cellList
	if #list == 1 then
		local data = {
			type = 3,
			list = {}
		}
		table.insert(list,data)
	end
	local isEmpty = #list <= 0
	CS.ShowObject(self.mNoRecord,isEmpty)
	if isEmpty then
		self:CreateEmptyShow(self._seckillEndEmpty)
	end
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("rushBuyList")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
	end
	self._uiCellList:EnableScroll(#list > 1,false)
	self:TimerStop(self._timeEndKey)
	self:TimerStop(self._timeStartKey)
	if cellList[1] then
		self._endTime = cellList[1].timestamp
		self:TimerStart(self._timeEndKey,1,false,-1)
		self:SetTime(self._endTimeText,self._endTime,self._timeEndKey)
	end
	if cellList[2] then
		self._startTime = cellList[2].timestamp
		self:TimerStart(self._timeStartKey,1,false,-1)
		self:SetTime(self._startTimeText,self._startTime,self._timeStartKey)
	end
end
------------------------------------------------------------------
return UISubLuckRushBuy


