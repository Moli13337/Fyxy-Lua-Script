---
--- Created by Administrator.
--- DateTime: 2023/10/12 14:52:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDTDGiftPop:LWnd
local UIDTDGiftPop = LxWndClass("UIDTDGiftPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDTDGiftPop:UIDTDGiftPop()
    self._itemNumFormat = "×%s"
    self._endTimeKer = "_endTimeKer"
    self._loopScaleKey = "_loopScaleKey"
    self._itemEffName_4 = "fx_jifenlibao"
    self._itemEffName_5 = "fx_jifenlibao_02"
    self._itemEffName_6 = "fx_jifenlibao_03"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDTDGiftPop:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDTDGiftPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDTDGiftPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    if  self._isEnus then 
        self:SetWndEasyImage(self.mHelpDesc,"activity_discount_bg_1_2")
    end 
    
    self:InitEvent()
    self:InitMessage()
    self:InitParam()
end

function UIDTDGiftPop:RefreshItemList()
    local items = self._giftData.items
    local itemsNum = #items
    self._itemsNum = itemsNum

    local itemListPosType = self._itemListPosType
    if itemsNum <= 4 then
        itemListPosType = self._itemListPosType.item4
    elseif itemsNum == 5 then
        itemListPosType = self._itemListPosType.item5
    else
        itemListPosType = self._itemListPosType.item6
    end

    local posList = itemListPosType.itemPos

    for i = 1, itemsNum do
        self:SetItemData(i, items[i], posList[i])
    end
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIDTDGiftPop:RefreshView()
    if table.isempty(self._giftData) then
        return
    end

    self:RefreshItemList()
    self:RefreshPay()
    self:SetItemEffShow()
end

function UIDTDGiftPop:InitData()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end

    local config = webData.config
    local shiftItemIcons = string.split(config.shiftItemIcon, ';')
    self._shiftItemIcons = {}
    for k, v in ipairs(shiftItemIcons) do
        local itemIconData = string.split(v, '=')
        local itemRefId = tonumber(itemIconData[1])
        local iconPath = itemIconData[2]
        self._shiftItemIcons[itemRefId] = iconPath
    end
end

function UIDTDGiftPop:SetItemEffShow()
    local itemsNum = self._itemsNum
    local itemListPosType = self._itemListPosType
    if itemsNum <= 4 then
        itemListPosType = self._itemListPosType.item4
    elseif itemsNum == 5 then
        itemListPosType = self._itemListPosType.item5
    else
        itemListPosType = self._itemListPosType.item6
    end

    local effName = itemListPosType.effName
    local effPos = itemListPosType.effPos
    self:CreateWndEffect(self.mEffRoot, effName, effName, 100, false, false)
    self.mEffRoot.localPosition = effPos
    CS.ShowObject(self.mEffRoot, true)
end

function UIDTDGiftPop:RefreshEndTimeText()
    local nDayTime = LUtil.GetNextDayTimes(GetTimestamp(), 1)
    local lostTime = nDayTime - GetTimestamp()
    if lostTime <= 1 then
        --零点重置
        self:WndClose()
        return
    end

    local endTime = LUtil.FormatTimespanCn(lostTime)
    endTime = string.replace(ccClientText(15632), endTime)
    self:SetWndText(self.mTimeText, endTime)
end

function UIDTDGiftPop:RefreshData()
    local pageData = self.pages[ModelActivity.DAILY_GIFT_TYPE_INTEGRAL]
    self._giftData = {}
    for i, v in ipairs(pageData.entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, v.entryId)
        if entryCfg then
            self._giftData = {
                pageId = v.pageId,
                entryId = v.entryId,
                title = entryCfg.name,
                items = LxDataHelper.ParseItem(entryCfg.reward),
                MarketData = v.MarketData,
                activeMoreInfo = v.moreInfo,
                moreInfo = entryCfg.moreInfo,
            }
        end
    end
end

function UIDTDGiftPop:OnClickPayBtn()
    local giftData = self._giftData
    local entryId = giftData.entryId
    local pageId = giftData.pageId
    local sid = self._sid
    local welfareId = tonumber(giftData.MarketData.expend2)
    self:WndClose()
    gModelPay:GiftPayCtrl(entryId, welfareId, ModelPay.PAY_TYPE_ACTIVITY, 0, sid, pageId)
end

function UIDTDGiftPop:InitMessage()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:ResetData(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        local activities = pb.activities
        for i, v in ipairs(activities) do
            if (v.sid == self._sid) then
                gModelActivity:OnActivityPageReq(self._sid)
                return
            end
        end
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local activity = pb.activity
        if (activity.sid == self._sid) then
            gModelActivity:OnActivityPageReq(self._sid)
        end
    end)
end

function UIDTDGiftPop:ResetData(pb)
    local sid = pb.sid
    if (self._sid ~= sid) then
        return
    end

    self.pages = {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        table.insert(self.pages, page)
    end

    self:RefreshData()
    self:RefreshView()
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIDTDGiftPop:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    self:InitData()

    gModelActivity:OnActivityPageReq(self._sid)
end

function UIDTDGiftPop:RefreshPay()
    local giftData = self._giftData
    local marketData = giftData.MarketData
    local personalGoal, personal = marketData.personalGoal, marketData.personal
    local isBuy = (personalGoal - personal) == 0

    CS.ShowObject(self.mBtnPay, not isBuy)
    CS.ShowObject(self.mMaskPay, isBuy)
    if isBuy then
        return
    end

    local moreInfo = string.split(giftData.moreInfo, ',')

    local str = gModelPay:GetShowByWelfareId(tonumber(marketData.expend2))
    self:SetWndText(self.mPayText, str)

    local upNum = moreInfo[3]
    local showHelpDesc = upNum ~= nil
    CS.ShowObject(self.mHelpDescBg, showHelpDesc)
    self:SetIntegralGiftDescTween(showHelpDesc)
    if showHelpDesc then
        str = upNum .. "%"
        self:SetWndText(self.mHelpDesc, str)
    end

    self:SetTimeStr()
end

function UIDTDGiftPop:InitParam()
    self._sid = self:GetWndArg("sid")
    local _sid = self._sid

    self._itemListPosType = {
        ["item4"] = {
            effName = self._itemEffName_4,
            effPos = Vector3.New(0, 0, -10),
            itemPos = {
                Vector3.New(-12, 193, 0),
                Vector3.New(-91, 19, 0),
                Vector3.New(89, -23, 0),
                Vector3.New(-44, -154, 0),
            },
        },
        ["item5"] = {
            effName = self._itemEffName_5,
            effPos = Vector3.New(-12, -113, -10),
            itemPos = {
                Vector3.New(-100, 223, 0),
                Vector3.New(43, 129, 0),
                Vector3.New(-134, 31, 0),
                Vector3.New(100, -27, 0),
                Vector3.New(-44, -146, 0),
            },
        },

        ["item6"] = {
            effName = self._itemEffName_6,
            effPos = Vector3.New(-12, -113, -10),
            itemPos = {
                Vector3.New(-100, 223, 0),
                Vector3.New(43, 129, 0),
                Vector3.New(-134, 31, 0),
                Vector3.New(100, -27, 0),
                Vector3.New(-44, -146, 0),
                Vector3.New(100, -188, 0),
            },
        },
    }

    gModelActivity:ReqActivityConfigData(_sid)

    self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UIDTDGiftPop:SetIntegralGiftDescTween(isShow)
    local seqKey = self._loopScaleKey
    local tween = self:TweenSeqFind(seqKey)
    if not isShow then
        if tween then
            self:TweenSeqKill(seqKey)
        end
        return
    end

    if not tween then
        self:TweenSeq_DefalutScale(seqKey, self.mHelpDescBg, { x = 0.9, y = 0.9, z = 0.9, time = 1, recover = true })
    end
end

function UIDTDGiftPop:SetItemData(itemIndex, itemData, pos)
    local itemRoot = self:FindWndTrans(self.mItemList, "Item" .. itemIndex)
    if not CS.IsValidObject(itemRoot) then
        return
    end

    local itemIconTrans = self:FindWndTrans(itemRoot, "ItemIcon")
    local itemNumText = self:FindWndTrans(itemIconTrans, "ItemNum")
    local effTrans = self:FindWndTrans(itemIconTrans, "Eff")

    if pos then
        itemRoot.localPosition = pos
    end

    local itemId = itemData.itemId
    local itemNum = itemData.itemNum
    local itemImg
    local shiftItemIcon = self._shiftItemIcons[itemId]
    if not shiftItemIcon then
        itemImg = gModelItem:GetItemImgByRefId(itemData.itemId)
    else
        itemImg = shiftItemIcon
    end

    local itemNumStr = string.format(self._itemNumFormat, LUtil.NumberCoversion(itemNum))
    self:SetWndText(itemNumText, itemNumStr)

    if LxUiHelper.IsImgPathValid(itemImg) then
        self:SetWndEasyImage(itemIconTrans, itemImg)
    end

    CS.ShowObject(itemRoot, true)
    self:SetWndClick(itemIconTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)
end

function UIDTDGiftPop:OnTimer(key)
    if key == self._endTimeKer then
        self:RefreshEndTimeText()
    end
end

function UIDTDGiftPop:InitEvent()
    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnPay, function()
        self:OnClickPayBtn()
    end)
end

function UIDTDGiftPop:SetTimeStr()
    local timeKey = self._endTimeKer
    if not self:IsTimerExist(timeKey) then
        self:TimerStart(timeKey, 1, false, -1)
    end

    self:RefreshEndTimeText()
end

------------------------------------------------------------------
return UIDTDGiftPop



