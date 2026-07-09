---
--- Created by Administrator.
--- DateTime: 2024/8/8 21:28:11
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubRegressionGift:LChildWnd
local UISubRegressionGift = LxWndClass("UISubRegressionGift", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubRegressionGift:UISubRegressionGift()
	self.timeKey = "RegressionGiftKey"
	gModelRegression:OnRegressionGiftReq(1,0,"")
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubRegressionGift:OnWndClose()
	LChildWnd.OnWndClose(self)
	self:TimerStop(self.timeKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubRegressionGift:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubRegressionGift:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self.endTime = gModelRegression.endTime
	self:TimerStart(self.timeKey, 1, false, -1)
	self:WndNetMsgRecv(LProtoIds.RegressionGiftResp,function() self:InitSelGiftList() end)
	gModelRegression:OnRegressionGiftReq(1,0,"")
	self:SetTimeTxt()
	self:InitSpine()
end

function UISubRegressionGift:InitRewardList(trans,list,canScroll)
    if canScroll == nil then
        canScroll = false
    end
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans,list,function(...) self:OnDrawItemCell(...) end)
        uiList:EnableScroll(canScroll,true)
    end
end
function UISubRegressionGift:OpenCustomSelectWnd(argList)
    GF.OpenWnd("UICumSelectNew",argList)
end

function UISubRegressionGift:OnTimer(key)
	if key == self.timeKey then
		self:SetTimeTxt()
	end
end

function UISubRegressionGift:OnClickItemBuy(itemdata)
	local expend = itemdata.expend2
	if not string.isempty(expend) and not string.find(expend,"=") then
		gModelPay:GiftPayCtrl(itemdata.entryId,tonumber(expend),ModelPay.PAY_TYPE_GIFT,ModelPay.PAY_GIFT_4)
		return
	end
	local item = LxDataHelper.ParseItem_3(expend)
	if item then
		local num = gModelItem:GetNumByRefId(item.itemId)
		if(num < item.itemNum)then
			gModelGeneral:OpenGetWayWnd({itemId = item.itemId})
			return
		end
	end
	gModelRegression:OnRegressionGiftReq(3,itemdata.entryId,"")
end
function UISubRegressionGift:OnDrawItemCell(list,item,itemdata,itempos)
    self:CreateItemShow(item,itemdata,{
        clickFunc = function()
            if itemdata.customType then
                if itemdata.status then
                    gModelGeneral:ShowCommonItemTipWnd(itemdata)
                    return
                end
                self:OpenCustomSelectWnd({
                    sid = self._sid,
                    pageId = itemdata.pageId,
                    entryId = itemdata.entryId,
                    itemIndex = itemdata.index,
                    giftData = itemdata,
                    title = itemdata.title,
					callFunc = function(data)
						self:RegressionGiftReq(itemdata,data)
					end
                })
            else
                self:OpenCommonItemTipsWnd(itemdata)
            end

        end,
        isChange = not itemdata.isEmpty,
    })
end

function UISubRegressionGift:GetCustomList(customGiftList,status)
    local list = {}
    for i,v in ipairs(customGiftList or {}) do
        v.status = status
        v.customType = true
        table.insert(list,v)
    end
    return list
end

function UISubRegressionGift:GetSelGiftList()
    local list = {}
	local refs = GameTable.ReturnBackPreferentialRef
	for _, serInfo in pairs(gModelRegression.giftList) do
		local ref = refs[serInfo.refId]
		local customGiftList = {}
		local selGift = string.split(ref.rewardFree,"|")--自选
		local selGiftList = LxDataHelper.ParseItem(ref.rewardFree,"|")
		for indx, rwd in ipairs(selGift) do
			local selIndx = serInfo.selected[indx]
			local selItemStr = selGift[tonumber(selIndx)]
			local selItem = selGiftList[tonumber(selIndx)]
			table.insert(customGiftList,{
				isEmpty = true,
				itemId = selItem and selItem.itemId or -1,
				itemType = selItem and selItem.itemType,
				itemNum = selItem and selItem.itemNum or -1,
				canSel = serInfo.buyNum>0,
				isSel = true,
				selList = selGiftList,--自选列表
				index = indx,
				entryId = ref.refId,
				title =ccLngText(ref.name),
				MarketData ={
					customGift = selItemStr,--已选
					customList = ref.rewardFree--自选
				}
			})
		end
		table.insert(list,{
			isSel = true,
			customGiftList = customGiftList,
			fixReward = LxDataHelper.ParseItem(ref.reward),
			entryId = ref.refId,
			sort = ref.sort,
			title = ref.name,
			pageId = ModelActivity.DAILY_GIFT_D_SELGIFTID,
			icon = ref.webIcon,
			personal = 0,
			personalGoal = 1,
			buyNum = serInfo.buyNum,
			-- expend1 = ref.expend,
			expendType = string.find(ref.expend,"=") and gModelPay.TYPE_BUY_ITEM or gModelPay.TYPE_BUY_RMB,
			expend2 = ref.expend,
			sellOut = serInfo.buyNum>0,
			discount = ref.discount,
			getItemList = LxDataHelper.ParseItem(ref.reward),
		})
	end
	table.sort(list,function(a, b)
		local aState = a.sellOut and 1 or 0
		local bState = b.sellOut and 1 or 0
		if aState==bState then
			return a.sort<b.sort
		else
			return aState>bState
		end
	end)
    return list
end
function UISubRegressionGift:OnDrawSelGiftCell(list,item,itemdata,itempos)
    local CustomTrans = self:FindWndTrans(item,"Custom")
    local ImmobilizationTrans = self:FindWndTrans(item,"Immobilization")
    local isSel = itemdata.isSel
    CS.ShowObject(CustomTrans,isSel)
    CS.ShowObject(ImmobilizationTrans,not isSel)
    local height = item.sizeDelta.y
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
    if isSel then
        self:CreateCustom(CustomTrans,itemdata)
    else
        -- self:CreateImmobilization(ImmobilizationTrans,itemdata)
    end
end

function UISubRegressionGift:OnClickCustomBtnFunc(itemdata)
    if itemdata.buyNum<1 and itemdata.personalGoal ~= -1 then
        GF.ShowMessage(ccClientText(20811))--該禮包已售罄
        return
    end

    local fixReward = itemdata.fixReward or {}
    local costomGiftList = itemdata.customGiftList or {}
    local getItemList = itemdata.getItemList or {}
    local fixLen,costomLen,getItemLen = #fixReward,#costomGiftList,#getItemList
    local isSelFull = fixLen + costomLen == getItemLen
    local firstData = costomGiftList[1]
	local gift = gModelRegression.giftList[itemdata.entryId]
    if #gift.selected<costomLen and firstData then
        self:OpenCustomSelectWnd({
            sid = self._sid,
            pageId = firstData.pageId,
            entryId = firstData.entryId,
            itemIndex = firstData.index,
            giftData = firstData,
            title = firstData.title,
        })
        return
    else
        self:OnClickItemBuy(itemdata)
    end
end
function UISubRegressionGift:RegressionGiftReq(itemdata,selData)
	gModelRegression:OnRegressionGiftReq(2,itemdata.entryId,tostring(selData[1].customIndex))
end

function UISubRegressionGift:SetTimeTxt()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self.endTime, nowTime)
	if timeDif <= 0 then
		self:TimerStop(self.timeKey)
	end
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	self:SetWndText(self.mTxtTime,string.replace(ccClientText(45102),timeStr))
end

-------------------------------- 定制礼包 ----------------------------------------
function UISubRegressionGift:CreateCustom(item,itemdata)
    local OverImgTrans = self:FindWndTrans(item,"OverImg")

    local RewardMaskTrans = self:FindWndTrans(item,"RewardMask")
    local RewardDivTrans = self:FindWndTrans(RewardMaskTrans,"RewardDiv")

    local FixRewardListTrans = self:FindWndTrans(RewardDivTrans,"FixRewardList")
    local GameObjectTrans = self:FindWndTrans(RewardDivTrans,"GameObject")
    local RewardListTrans = self:FindWndTrans(RewardDivTrans,"RewardList")

    local AddImgTrans = self:FindWndTrans(item,"Image")

    local DiscountImgTrans = self:FindWndTrans(item,"DiscountImg")
    local DiscountTxtTrans = self:FindWndTrans(DiscountImgTrans,"DiscountTxt")

    local BuyBtnTrans = self:FindWndTrans(item,"BuyBtn")
    local AutoDivTrans = self:FindWndTrans(BuyBtnTrans,"AutoDiv")
    local IconImgTrans = self:FindWndTrans(AutoDivTrans,"Image")
    local BtnTxtTrans = self:FindWndTrans(AutoDivTrans,"Txt")
    local EffTrans = self:FindWndTrans(BuyBtnTrans,"Eff")

    local CountDownTxtTrans = self:FindWndTrans(item,"CountDownTxt")

    local TxtBgTrans = self:FindWndTrans(item,"TxtBg")
    local TxtTrans = self:FindWndTrans(TxtBgTrans,"Txt")

    self:SetWndEasyImage(TxtBgTrans,itemdata.icon)
    self:SetWndText(TxtTrans,ccLngText(itemdata.title))

    local fixReward = itemdata.fixReward or {}
    local fixRewardLen = #fixReward
    local fixRewardEmpty = fixRewardLen < 1

    local buyNum = itemdata.buyNum
    local isEmpty = buyNum < 1
    local show = not isEmpty

    local customGiftList = self:GetCustomList(itemdata.customGiftList,isEmpty)
    local customGiftLen = #customGiftList
    local haveGift = customGiftLen > 0
    CS.ShowObject(AddImgTrans,haveGift)
    CS.ShowObject(RewardListTrans,haveGift)
    if not fixRewardEmpty then
        self:InitRewardList(FixRewardListTrans,fixReward)
    end
    CS.ShowObject(FixRewardListTrans,not fixRewardEmpty)
    CS.ShowObject(GameObjectTrans,customGiftLen ~= 0)

    if haveGift then--有自选礼包
        self:InitRewardList(RewardListTrans,customGiftList,customGiftLen > 3)
    end
    --CS.ShowObject(GameObjectTrans,customGiftLen>0)

    local showDis = false
    if show then
        local buyCountText = string.replace(ccClientText(20810), buyNum)
        self:SetWndText(CountDownTxtTrans,buyCountText)

        local expendType = itemdata.expendType
        local expend2 = itemdata.expend2
        local txt,showIconImg,iconImg = string.isempty(expend2) and ccClientText(42505) or gModelPay:GetPayType(expendType,expend2)
        if iconImg then
            self:SetWndEasyImage(IconImgTrans,iconImg)
        end
        CS.ShowObject(IconImgTrans,showIconImg)
        self:SetWndText(BtnTxtTrans,txt)

        local isFree = expendType == gModelPay.TYPE_BUY_FREE
        if isFree then
            local effKey = EffTrans:GetInstanceID()
            self:CreateWndEffect(EffTrans,"fx_anniu_02",effKey,100,false,false,10)
        end
        CS.ShowObject(EffTrans,isFree)

        local discount = itemdata.discount
        showDis = discount > 0
        if showDis then
            self:SetWndText(DiscountTxtTrans, discount.."%")
        end

        self:SetWndClick(BuyBtnTrans,function()
            self:OnClickCustomBtnFunc(itemdata)
        end)
    end
    CS.ShowObject(DiscountImgTrans,showDis)
    CS.ShowObject(OverImgTrans,isEmpty)
    CS.ShowObject(BuyBtnTrans,show)
    CS.ShowObject(CountDownTxtTrans,show)
end
function UISubRegressionGift:CreateItemShow(trans,itemdata,extraData)
    local IconTrans = self:FindWndTrans(trans,"itemRoot/Icon")
    local itemNumTrans = self:FindWndTrans(trans,"itemNum")
    local ShiftTrans = self:FindWndTrans(trans,"Shift")
    local EffTrans = self:FindWndTrans(trans,"Eff")

    local itemNum = itemdata.itemNum
    local instanceID = IconTrans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId,itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local showItemNum = itemNum > 0
    if showItemNum then
        self:SetWndText(itemNumTrans,LUtil.NumberCoversion(itemNum))
    end
    CS.ShowObject(itemNumTrans,showItemNum)

    extraData = extraData or {}
    local isChange = extraData.isChange
    CS.ShowObject(ShiftTrans,isChange)
    CS.ShowObject(EffTrans,false)

    local instanceId = trans:GetInstanceID()
	if itemdata.isShowEff then
		local quality = gModelGeneral:GetCommonItemQualityRef(itemdata)
		local eff = GameTable.RarityRef[quality].itemFx
		if not string.isempty(eff) then
			self:CreateWndEffect(IconTrans,eff,instanceId,100,false,false)
		end
	else
		self:DestroyWndEffectByKey(instanceId)
	end

    local clickFunc = extraData.clickFunc
    if clickFunc then
        self:SetWndClick(IconTrans,function()
            clickFunc()
        end)
    end
end

function UISubRegressionGift:InitSelGiftList()
    local list = self:GetSelGiftList()
    local uiSelGiftList = self._uiSelGiftList
    if uiSelGiftList then
        uiSelGiftList:RefreshData(list)
    else
        uiSelGiftList = self:GetUIScroll("uiSelGiftList")
        self._uiSelGiftList = uiSelGiftList
        uiSelGiftList:Create(self.mSelGiftList,list,function(...) self:OnDrawSelGiftCell(...) end,UIItemList.WRAP,false)
        local uiList = uiSelGiftList:GetList()
        uiList:RefreshList(UIListWrap.RefreshMode.Solid)
    end
end

function UISubRegressionGift:InitSpine()
	local refId = self:GetWndArg("refId")
	local ref = GameTable.ReturnBackBackflowRef[refId]
	if not ref or string.isempty(ref.showImage) then return end
	local dpSpine = self:CreateWndSpine(self.mSpine,ref.showImage,nil,true,function (dpLoaded)
		dpLoaded:PlayAnimation(0,"idle",true)
	end,true)
	dpSpine:StartLoad()
	self:SetWndEasyImage(self.mImgText,ref.showTitle)
end
function UISubRegressionGift:OpenCommonItemTipsWnd(itemdata)
    gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

------------------------------------------------------------------
return UISubRegressionGift