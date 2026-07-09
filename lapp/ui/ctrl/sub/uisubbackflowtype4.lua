---
--- Created by BY.
--- DateTime: 2023/10/12 17:15:39
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubBackflowType4:LChildWnd
local UISubBackflowType4 = LxWndClass("UISubBackflowType4", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubBackflowType4:UISubBackflowType4()
	self._timeKey = "_timeKey_4"
	self._commonIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBackflowType4:OnWndClose()
	self:ClearCommonIconList(self._commonIconList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBackflowType4:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBackflowType4:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubBackflowType4:RefreshData()
	local _giftList = gModelBackflow:GetGiftList()
	local dailyGift = nil
	local list = {}
	for i, v in pairs(_giftList) do
		local data = v
		local ref = gModelBackflow:RegressionPreferentialRefByRefId(data.refId)
		data.ref = ref
		if ref.type == 1 then
			dailyGift = data
		else
			table.insert(list,data)
		end
	end
	self:RefreshDailyGift(dailyGift)
	table.sort(list,function (a,b)
		local aisBur = a.buyNum > 0 and 1 or 0
		local bisBur = b.buyNum > 0 and 1 or 0
		if aisBur ~= bisBur then
			return aisBur > bisBur
		end
		local aSort = a.ref and (a.ref.sort or 100) or 100
		local bSort = b.ref and (b.ref.sort or 100) or 100
		return aSort < bSort
	end)

	local _cellSuper = self._uiCellSuper
	if _cellSuper then
		_cellSuper:RefreshList(list)
	else
		_cellSuper = self:GetUIScroll("mCellSuper4")
		_cellSuper:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_cellSuper:EnableScroll(true,false)
		self._uiCellSuper = _cellSuper
	end
	_cellSuper:DrawAllItems()
end

function UISubBackflowType4:RefreshDailyGift(dailyGift)
	if not dailyGift then
		return
	end
	self._dailyGift = dailyGift
	local ref = dailyGift.ref
	local buyNum = dailyGift.buyNum

	self:SetWndText(self.mNameText,ccLngText(ref.name))
	self:InitTextSizeWithLanguage(self.mNameText, -6)
	local itemData = LxDataHelper.ParseItem_4(ref.reward)
	local icon = gModelItem:GetItemImgByRefId(itemData.itemId)
	CS.ShowObject(self.mAwardRoot,true)
	self:SetWndEasyImage(self.mAwardIcon,icon)
	self:SetWndText(self.mAwardNumText,itemData.itemNum)
	self:SetWndClick(self.mAwardRoot,function ()
		gModelGeneral:OpenItemInfoTipsFormChat(itemData)
	end)

    local showLine = false
	local showPriceText = not self._isForeign
	if showPriceText then
        local originalPrice = ref.originalPrice
		self:SetWndText(self.mPriceText,originalPrice)
        showLine = not string.isempty(originalPrice)
	end
	CS.ShowObject(self.mPriceText, showPriceText)
	CS.ShowObject(self.mLineImg, showLine)

	self:SetBtnBuyInfo(self.mBtnBuy,self.mBtnItemBuy,self.mStatus_On,dailyGift)
	local buyNumStr = LUtil.FormatColorStr(buyNum,buyNum > 0 and "green" or "red")
	self:SetWndText(self.mNumText,string.replace(ccLngText(ref.limitCountText),buyNumStr))
end

function UISubBackflowType4:InitEvent()
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBtnBuy,function (...)self:OnClickPay() end)
	self:SetWndClick(self.mBtnItemBuy,function (...)self:OnClickPay() end)
end
function UISubBackflowType4:InitMessage()
	self:WndNetMsgRecv(LProtoIds.RegressionGiftResp,function (pb)
		self:RefreshData()
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		gModelBackflow:RegressionGiftReq(1,0)
	end)
end
--点击购买
function UISubBackflowType4:OnClickPay()
	local dailyGift = self._dailyGift
	if not dailyGift then
		return
	end
	self:OnClickItemBuy(dailyGift)
end
function UISubBackflowType4:SetTime()--设置时间
	local time = gModelBackflow:GetResidueTime()
	if(time <= 0)then
		self:TimerStop(self._timeKey)
		CS.ShowObject(self.mTimeText,false)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(time)
	self:SetWndText(self.mTimeText,string.replace(ccClientText(23500),timeStr))
end
function UISubBackflowType4:InitCommand()
	local refId = self:GetWndArg("refId")
	local ref = gModelBackflow:RegressionBackflowRefByRefId(refId)
	self._ref = ref

	self._isForeign = gLGameLanguage:IsForeignRegion()
	CS.ShowObject(self.mBtnHelp,ref.helpId > 0)
	local showIcon,showIconPos,showTitle,showTitlePos = ref.showIcon,ref.showIconPos,ref.showTitle,ref.showTitlePos
	if LxUiHelper.IsImgPathValid(showIcon) then
		CS.ShowObject(self.mIconImg,true)
		self:SetWndEasyImage(self.mIconImg,showIcon,nil,true)
		local showIconPosArr = string.split(showIconPos,"|")
		self.mIconImg.anchoredPosition = Vector2(tonumber(showIconPosArr[1]),tonumber(showIconPosArr[2]))
	end
	if LxUiHelper.IsImgPathValid(showTitle) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,showTitle,nil,true)
		local showTitlePosArr = string.split(showTitlePos,"|")
		self.mTextImg.anchoredPosition = Vector2(tonumber(showTitlePosArr[1]),tonumber(showTitlePosArr[2]))
	end

	local time = gModelBackflow:GetResidueTime()
	CS.ShowObject(self.mTimeText,time > 0)
	if(time > 0)then
		self:SetTime()
		self:TimerStop(self._timeKey)
		self:TimerStart(self._timeKey,1,false,-1)
	end
	gModelBackflow:RegressionGiftReq(1,0)
end
------------------------------------------------time--------------------------------------------------------------------
function UISubBackflowType4:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	end
end

function UISubBackflowType4:OnClickOpentSel(itemdata)
	local type = itemdata.type
	if type == 1 then
		return
	end
	local rewardFree = itemdata.rewardFree
	local refId = itemdata.refId
	local name = itemdata.name
	local selected = itemdata.selected
	local para = {
		name = name,
		rewardFree = rewardFree,
		selected = selected,
		callFunc = function(selectedStr)
			gModelBackflow:RegressionGiftReq(2,refId,selectedStr)
		end
	}
	GF.OpenWnd("UICumSelectNew2",{para = para})
end

function UISubBackflowType4:SetBtnBuyInfo(btn1,btn2,btnMask,itemdata)
	local ref = itemdata.ref
	local buyNum = itemdata.buyNum
	local expend = ref.expend
	CS.ShowObject(btn1,false)
	CS.ShowObject(btn2,false)
	CS.ShowObject(btnMask,buyNum <= 0)
	if buyNum > 0 then
		if string.find(expend,"=")then
			CS.ShowObject(btn2,true)
			local btnItemText = self:FindWndTrans(btn2,"BtnItemText")
			local itemBuyIcon = self:FindWndTrans(btn2,"BtnItemText/ItemBuyIcon")
			local item = LxDataHelper.ParseItem_3(expend)
			local icon = gModelItem:GetItemIconByRefId(item.itemId)
			local payStr = item.itemNum
			self:SetWndEasyImage(itemBuyIcon,icon)
			self:SetWndText(btnItemText,payStr)
		else
			CS.ShowObject(btn1,true)
			local payStr = gModelPay:GetShowByWelfareId(tonumber(expend))
			self:SetWndButtonText(btn1,payStr)
		end
	end
end

function UISubBackflowType4:ItemListItem(list, item, itemdata, itempos)
	local image = self:FindWndTrans(item,"Image")
	local root = self:FindWndTrans(item,"Root")
	local btnCut = self:FindWndTrans(item,"BtnCut")
	local type = itemdata.type
	local data = itemdata.data
	local isBuy = itemdata.isBuy
	local isSel = data ~= ""
	CS.ShowObject(image,not isSel)
	CS.ShowObject(root,isSel)
	CS.ShowObject(btnCut,isSel and isBuy)
	if not isSel then
		self:SetWndClick(image,function ()
			self:OnClickOpentSel(itemdata)
		end)
		return
	end
	self:SetWndClick(btnCut,function ()
		self:OnClickOpentSel(itemdata)
	end)
	local itemInfo = LxDataHelper.ParseItem_4(data)
	local InstanceID = item:GetInstanceID()
	local func = function()
		if type == 1 then
			gModelGeneral:OpenItemInfoTipsFormChat(itemdata)
		else
			self:OnClickOpentSel(itemdata)
		end
	end
	self:InitCommonIcon(InstanceID,root,itemInfo,func)
end

function UISubBackflowType4:OnClickItemBuy(dailyGift)
	local ref = dailyGift.ref
	local refId = dailyGift.refId
	local expend = ref.expend
	if not string.find(expend,"=")then
		gModelPay:GiftPayCtrl(refId,tonumber(ref.expend),ModelPay.PAY_TYPE_GIFT,ModelPay.PAY_GIFT_4)
		return
	end
	local item = LxDataHelper.ParseItem_3(expend)
	local num = gModelItem:GetNumByRefId(item.itemId)
	if(num < item.itemNum)then
		gModelGeneral:OpenGetWayWnd({itemId = item.itemId})
		return
	end
	gModelBackflow:RegressionGiftReq(3,refId)
end

function UISubBackflowType4:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local titleText = self:FindWndTrans(root,"TitleBg/TitleText")
	local awardRoot1 = self:FindWndTrans(root,"AwardRoot1")
	local awardRoot2 = self:FindWndTrans(root,"AwardRoot2")
	local numText = self:FindWndTrans(root,"NumText")
	local btnBuy = self:FindWndTrans(root,"BtnMar/BtnBuy")
	local btnItemBuy = self:FindWndTrans(root,"BtnMar/BtnItemBuy")
	local status_On = self:FindWndTrans(root,"BtnMar/Status_On")
	local discountImg = self:FindWndTrans(root,"DiscountImg")
	local discountTxt = self:FindWndTrans(root,"DiscountImg/DiscountTxt")

	local InstanceID = item:GetInstanceID()
	local ref = itemdata.ref
	local buyNum = itemdata.buyNum
	local selected = itemdata.selected
	local name = ccLngText(ref.name)
	local discount = ref.discount

	CS.ShowObject(discountImg,discount > 0)
	self:SetWndText(discountTxt,discount.."%")
	self:SetWndText(titleText,name)
	self:InitTextSizeWithLanguage(titleText, -4)
	self:InitTextLineWithLanguage(titleText, -30)
	self:SetBtnBuyInfo(btnBuy,btnItemBuy,status_On,itemdata)
	local isBuy = buyNum > 0
	local buyNumStr = LUtil.FormatColorStr(buyNum,isBuy and "green" or "red")
	self:SetWndText(numText,string.replace(ccLngText(ref.limitCountText),buyNumStr))
	local itemList1 = string.split(ref.reward,"|")
	local arr2 = string.split(ref.rewardFree,"|")
	local itemList2 = {}
	for i, v in ipairs(arr2) do
		table.insert(itemList2,"")
	end
	if selected ~= "" then
		itemList2 = string.split(selected,",")
	end
	local list1 = {}
	for i, v in ipairs(itemList1) do
		table.insert(list1,{type = 1,data = v})
	end
	local list2 = {}
	for i, v in ipairs(itemList2) do
		local data2 = {
			type = 2,
			data = v,
			rewardFree = ref.rewardFree,
			refId = itemdata.refId,
			name = name,
			selected = selected,
			isBuy = isBuy
		}
		table.insert(list2,data2)
	end
	--self:InitItemList(InstanceID.."1",awardRoot1,itemList1)
	local _cellSuper1 = self:GetUIScroll(InstanceID.."1")
	if _cellSuper1:GetList() then
		_cellSuper1:RefreshList(list1)
	else
		_cellSuper1:Create(awardRoot1,list1,function (...) self:ItemListItem(...) end)
	end
	local _cellSuper2 = self:GetUIScroll(InstanceID.."2")
	if _cellSuper2:GetList() then
		_cellSuper2:RefreshList(list2)
	else
		_cellSuper2:Create(awardRoot2,list2,function (...) self:ItemListItem(...) end)
	end

	self:SetWndClick(btnBuy,function ()
		if selected ~= "" then
			self:OnClickItemBuy(itemdata)
		else
			self:OnClickOpentSel(list2[1])
		end
	end)
	self:SetWndClick(btnItemBuy,function ()
		if selected ~= "" then
			self:OnClickItemBuy(itemdata)
		else
			self:OnClickOpentSel(list2[1])
		end
	end)
end

function UISubBackflowType4:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = self._ref.helpId})
end

function UISubBackflowType4:InitCommonIcon(key,root,itemInfo,func)
	local baseClass = self._commonIconList[key]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconList[key] = baseClass
		baseClass:Create(root)
		self:SetIconClickScale(root, true)
	end
	baseClass:SetCommonReward(itemInfo.itemType, itemInfo.itemId, itemInfo.itemNum)
	baseClass:DoApply()
	self:SetWndClick(root,function () if func then func() end end)
end
------------------------------------------------------------------
return UISubBackflowType4


