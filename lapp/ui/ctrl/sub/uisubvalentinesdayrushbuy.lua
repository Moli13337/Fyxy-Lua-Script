---
--- Created by Administrator.
--- DateTime: 2023/10/24 14:20:05
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubValentinesDayRushBuy:LChildWnd
local UISubValentinesDayRushBuy = LxWndClass("UISubValentinesDayRushBuy", LChildWnd)

UISubValentinesDayRushBuy.HERO_REF_ID = 1
UISubValentinesDayRushBuy.HERO_IMG = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubValentinesDayRushBuy:UISubValentinesDayRushBuy()
	self._timeEndKey = "timeEndKey"
	self._timeStartKey = "timeStartKey"
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubValentinesDayRushBuy:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubValentinesDayRushBuy:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubValentinesDayRushBuy:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

--#####################################################################################################################
--# Common ############################################################################################################
--#####################################################################################################################
function UISubValentinesDayRushBuy:ResetData(pb)
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

function UISubValentinesDayRushBuy:InitEvent()

end

function UISubValentinesDayRushBuy:RefreshData()
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

function UISubValentinesDayRushBuy:OnTimer(key)
	if(key == self._timeEndKey)then
		self:SetTime(self._endTimeText,self._endTime,key)
	elseif(key == self._timeStartKey)then
		self:SetTime(self._startTimeText,self._startTime,key)
	end
end

function UISubValentinesDayRushBuy:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UISubValentinesDayRushBuy:ItemListItem(list,item, itemdata, itempos)
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
			self:SetWndText(buyNum,string.replace(ccClientText(25004),marketData.serverGoal - marketData.server))
			self:InitTextLineWithLanguage(buyNum, -30)
			self:InitTextSizeWithLanguage(buyNum, -2)
		end
	else
		CS.ShowObject(root2,true)
		itemRoot = CS.FindTrans(root2,"ItemIcon")
		originalText = CS.FindTrans(root2,"OriginalObj/OriginalText")
		originalIcon = CS.FindTrans(root2,"OriginalObj/OriginalIcon")
	end

	local itemData
	if expendType == 0 then
		money = ccClientText(25005)
		money2 = ccClientText(25005)
		CS.ShowObject(originalIcon,false)
	elseif expendType == 1 then
		CS.ShowObject(originalIcon,true)
		local originalArr = string.split(originalStr,"=")
		local originalArr2 = string.split(originalStr2,"=")
		local itemId=  tonumber(originalArr[2])
		local icon = gModelItem:GetItemIconByRefId(itemId)
		self:SetWndEasyImage(originalIcon,icon)
		if buyCountIcon then
			self:SetWndEasyImage(buyCountIcon,icon)
		end
		local itemNum = tonumber(originalArr2[3])
		money = originalArr[3]
		money2 = LUtil.NumberCoversion(itemNum)
		itemData = {
			itemId = itemId,
			itemNum = itemNum,
		}
	elseif expendType == 2 then
		CS.ShowObject(originalIcon,false)
		money = gModelPay:GetShowByWelfareId(tonumber(originalStr))--string.replace(ccClientText(25006),originalStr)
		money2 = gModelPay:GetShowByWelfareId(tonumber(originalStr2))
	end
	if type == 2 and expendType ~= 0 then
		money = "???"
		if expendType == 2 then
			money = string.replace(ccClientText(25006),money)
		end
	end
	if buyBtn then
		self:SetWndText(buyCountText,money2)
		self:SetWndButtonText(buyBtn,money2)
		CS.ShowObject(buyCountBtn,isPersonal and expendType == 1)
		CS.ShowObject(buyBtn,isPersonal and expendType ~= 1)
		self:SetWndClick(buyCountBtn,function ()
			self:OnClickBuyGift(itemdata,expendType, itemData)
		end)
		self:SetWndClick(buyBtn,function ()
			self:OnClickBuyGift(itemdata,expendType, itemData)
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

function UISubValentinesDayRushBuy:ListItem(list,item, itemdata, itempos)
	local titleBg = self:FindWndTrans(item, "TitleBg")
	local titleText = CS.FindTrans(item,"TitleBg/TitleText")
	local timeText = CS.FindTrans(item,"TitleBg/TimeText")
	local itemScroll = CS.FindTrans(item,"ItemScroll")
	local desText = CS.FindTrans(item,"DesText")

	if LxUiHelper.IsImgPathValid(self._seckillHeroContentTitleBgImage) then
		self:SetWndEasyImage(titleBg, self._seckillHeroContentTitleBgImage)
	end

	local title = ""
	self:SetWndText(timeText,"")
	if itemdata.type == 1 then
		title = ccClientText(25001)
		self._endTimeText = timeText
	elseif itemdata.type == 2 then
		if self._cellList[1] then
			title = ccClientText(25002)
		else
			title = ccClientText(25003)
		end
		self._startTimeText = timeText
	elseif itemdata.type == 3 then
		title = ccClientText(25002)
	end
	self:SetWndText(titleText,title)

	local list = itemdata.list

	local isEmpty = #list <= 0
	CS.ShowObject(desText,isEmpty)
	if isEmpty then
		local desStr = ""
		if self._cellList[1] then
			desStr = self._seckillEndTxt

		else
			desStr = self._seckillNextTxt
		end
		self:SetWndText(desText,desStr)
	end
	local InstanceID = item:GetInstanceID()
	local uilist = self:GetUIScroll("itemList"..InstanceID)
	if uilist:GetList() then
		uilist:RefreshList(list)
	else
		uilist:Create(itemScroll,list,function (...) self:ItemListItem(...) end,UIItemList.WRAP)
		uilist:EnableScroll(true,true)
	end
end

function UISubValentinesDayRushBuy:OnClickBuyGift(itemdata,expendTupe,itemData)
	if expendTupe ~= 2 then
		if itemData then
			local itemId = itemData.itemId
			local dia = gModelItem:GetNumByRefId(itemId)
			local value = itemData.itemNum
			if dia < value then
				gModelGeneral:OpenGetWayWnd({itemId = itemId})
				return
			end
		end

		-- 钻石购买
		gModelActivity:OnActivityMarkeyBuyReq(self._sid, itemdata.pageId, itemdata.entryId)
	else
		local welfareId = tonumber(itemdata.MarketData.expend2)
		gModelPay:GiftPayCtrl(itemdata.entryId,welfareId,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,itemdata.pageId)
	end
end

function UISubValentinesDayRushBuy:SetTime(text,time,key)
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
			timeStr = string.replace(ccClientText(25007),timeStr)
		elseif(key == self._timeStartKey)then
			timeStr = string.replace(ccClientText(25008),timeStr)
		end
	end
	self:SetWndText(text,timeStr)
end

function UISubValentinesDayRushBuy:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry

	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local path = data.seckillHeroBgImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mBg, path)
	end
	CS.ShowObject(self.mBg, true)

	path = data.seckillHeroPopImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mPopImage, path)
	end
	CS.ShowObject(self.mPopImage, true)

	path = data.seckillHeroContentImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mContetBg, path)
	end
	CS.ShowObject(self.mContetBg, true)

	self._seckillHeroContentTitleBgImage = data.seckillHeroContentTitleBgImage

	local seckillHero,seckillHeroPos,seckillHeroTxt,seckillHeroTxtImage,seckillHeroTxtImagePos
	= data.seckillHero,data.seckillHeroPos,data.seckillHeroTxt,data.seckillHeroTxtImage,data.seckillHeroTxtImagePos
	if not string.isempty(seckillHero) then
		local paintTr
		local dropHeroArr = string.split(seckillHero,"=")
		local tempType = tonumber(dropHeroArr[1])
		if tempType == UISubValentinesDayRushBuy.HERO_IMG then
			local imagePath = dropHeroArr[2] or dropHeroArr[1]
			if LxUiHelper.IsImgPathValid(imagePath) then
				paintTr = self.mHeroImage
				self:SetWndEasyImage(paintTr,imagePath,nil,true)
			end
		else
			local effRefId = tonumber(dropHeroArr[2] or dropHeroArr[1])
			local ref = gModelHero:GetShowEffectById(effRefId)
			paintTr = self.mHeroPaint
			self:CreateWndSpine(paintTr,ref.heroDrawing,"seckillHero",false,function(dpSpine)
				dpSpine:SetScale(0.8)
			end)
		end

		CS.ShowObject(paintTr,true)
		if not string.isempty(seckillHeroPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(seckillHeroPos)
			self:SetAnchorPos(paintTr, pos)
		end
	end

	if seckillHeroTxt and seckillHeroTxt ~= "" then
		local str = string.gsub(seckillHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
		self:InitTextLineWithLanguage(self.mDesText, -30)
		CS.ShowObject(self.mDesTextBg, true)
	end
	if LxUiHelper.IsImgPathValid(seckillHeroTxtImage) then
		self:SetWndEasyImage(self.mTextImg,seckillHeroTxtImage,nil,true)
		local seckillHeroTxtImagePosArr = string.split(seckillHeroTxtImagePos,"|")
		self.mTextImg.anchoredPosition = Vector3(tonumber(seckillHeroTxtImagePosArr[1]),tonumber(seckillHeroTxtImagePosArr[2]),0)
		CS.ShowObject(self.mTextImg, true)
	end
	self._seckillNextTxt = data.seckillNextTxt
	self._seckillEndTxt = data.seckillEndTxt
	self._seckillEndEmpty = data.seckillEndEmpty
	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubValentinesDayRushBuy:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
end

------------------------------------------------------------------
return UISubValentinesDayRushBuy


