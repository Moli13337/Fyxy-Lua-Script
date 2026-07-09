---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMil:LWnd
local UIMil = LxWndClass("UIMil", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMil:UIMil()
    -----@type table<number,UIItemList>
    --self._uiCommonListList = {}

    self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMil:OnWndClose()
    --if self._uiCommonListList then
    --	for k,v in pairs(self._uiCommonListList) do
    --		v:Destroy()
    --	end
    --	self._uiCommonListList =nil
    --end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMil:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMil:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:InitWndPara()
    self:InitData()
    self:SetStaticContent()

    self:InitUIEvent()
    self:InitEvent()
    CS.ShowObject(self.mNormalBtn, false)
    CS.ShowObject(self.mSpecialBtn, false)
    gModelMail:MailListReq()
end

function UIMil:SetContent()
    local maxMailNum = gModelMail:GetMaxMailKeep(self._page)
    local totalMailNum = gModelMail:GetTotalMailNum(self._page)
    local unreadMailNum = gModelMail:GetUnreadMailNum(self._page)

    self:SetWndText(self.mMailNum, totalMailNum .. " / " .. maxMailNum)
    self:SetXUITextText(self.mUnread, string.replace(ccClientText(11200), unreadMailNum))

    local status = self._page == 1 and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(self.mNormalBtn, status)
    status = self._page == 2 and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(self.mSpecialBtn, status)

    CS.ShowObject(self.mDeleteBtn, self._page == 1)
    CS.ShowObject(self.mGetBtn, self._page == 1)
end

function UIMil:OnClickMailItem(itemdata)
    local wndName = "UIMilWithItem"
    if table.isempty(itemdata._attachments) then
        wndName = "UIMilContent"
    end
    GF.OpenWnd(wndName, { mail = itemdata , sendname =self.SendName })
end
function UIMil:InitUIEvent()
    self:SetWndClick(self.mDeleteBtn, function()
        self:DeleteReadMail()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mGetBtn, function()
        self:GetMailItem()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mReturnBtn, function()
        self:WndCloseAndBack()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mNormalBtn, function()
        self:ShowPage(1)
    end)
    self:SetWndClick(self.mSpecialBtn, function()
        self:ShowPage(2)
    end)

end

---@param uiItemList UIItemList
function UIMil:OnDrawRewardItem(uiItemList, list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "itemRoot")
    local iconTrans = CS.FindTrans(root, "CommonUI/Icon")
    self:CreateCommonIconImpl(iconTrans, itemdata)
end

function UIMil:OnDrawItem(list, item, itemdata, itempos)
    self:SetMailItem(item, itemdata)
end

function UIMil:InitScrollView()
    local mailDataList = gModelMail:GetSortedMailList(self._page)

    if table.isempty(mailDataList) then
        CS.ShowObject(self.mTipRoot, true)
        CS.ShowObject(self.mMailList, false)
        return
    end

    CS.ShowObject(self.mTipRoot, false)
    CS.ShowObject(self.mMailList, true)
    local uiList = self._uiList
    if not uiList then
        uiList = self:GetUIScroll("mailList")
        uiList:Create(self.mMailList, mailDataList, function(...)
            self:OnDrawItem(...)
        end, UIItemList.SUPER)
        self._uiList = uiList
    else
        uiList:RefreshList(mailDataList)
        uiList:MoveToPos(1)
    end

end

function UIMil:InitWndPara()
    self._page = self:GetWndArg("page")
    if not self._page then
        local redPointId = 10800001
        local isRed = gModelRedPoint:CheckShowRedPoint(redPointId)
        if isRed then
            self._page = 1
        else
            redPointId = 10800002
            isRed = gModelRedPoint:CheckShowRedPoint(redPointId)
            if isRed then
                self._page = 2
            end
        end
    end

    if not self._page then
        self._page = 1
    end

end

function UIMil:SetMailItem(item, itemdata)
    local bg = self:FindWndTrans(item, "bg")
    --local titleBg = self:FindWndTrans(item,"titleBg")
    --local line = self:FindWndTrans(item,"line")
    local title = self:FindWndTrans(item, "title")
    local date = self:FindWndTrans(item, "date")
    --local mailBg = self:FindWndTrans(item,"mailBg")
    local mailState = self:FindWndTrans(item, "mailState")
    local mailBrief = self:FindWndTrans(item, "mailBrief")
    local itemList = self:FindWndTrans(item, "itemList")
    local getTag = self:FindWndTrans(item, "getTag")
    local mask = self:FindWndTrans(item, "mask")
    local rewardTag = self:FindWndTrans(item, "rewardTag")

    --if self._isEnus then
    --    self:SetWndEasyImage(getTag, "public_txt_13_1_enus")
    --end
    if itemdata._refId ==604 then
        self.SendName=itemdata._sendName
    end

    self._uiMailItem[itemdata._mailId] = item

    self:SetWndClick(bg, function()
        self:OnClickMailItem(itemdata)
    end)
    local titleStr = nil
    local summary = nil
    local refId = itemdata._refId
    if refId == 0 then
        titleStr = itemdata._tile
        summary = itemdata._contentSummary
    else
        local cfg = gModelMail:GetMailCfg(refId)
        if not cfg then
            printInfoN("no mail cfg " .. refId)
            return
        end

        local cfgTitle = ccLngText(cfg.title)
        local cfgSumary = ccLngText(cfg.contentSummary)

        local itemDataTitle = itemdata._tile
        local itemDataContentSummary = itemdata._contentSummary
        if refId == 1 then
            --新角色登录游戏第一份邮件特殊处理
            local appName = LNativeHelper.GetAppName();
            itemDataTitle = "{\"a1\":\"" .. appName .. "\"}"
            itemDataContentSummary = itemDataTitle
        end

        titleStr = LUtil.GetReplacedContent(cfgTitle, itemDataTitle)
        summary = LUtil.GetReplacedContent(cfgSumary, itemDataContentSummary)
    end

    self:SetWndText(title, titleStr)
    local receiveTime = LUtil.OSDate("*t", itemdata._receiveTime / 1000)
    local timeStr = string.format("%d.%d.%d", receiveTime["year"], receiveTime["month"], receiveTime["day"])
    self:SetWndText(date, timeStr)
    local iconPath = nil
    if itemdata._read then
        iconPath = self._mailStateIconPath[2]
    else
        iconPath = self._mailStateIconPath[1]
    end
    self:SetWndEasyImage(mailState, iconPath)
    CS.ShowObject(getTag, itemdata._read)
    CS.ShowObject(mask, itemdata._read)
    local hasItem = false
    if #itemdata._attachments > 0 then

        hasItem = true
    else
        self:SetWndText(mailBrief, summary)
    end
    CS.ShowObject(itemList, hasItem)
    CS.ShowObject(mailBrief, not hasItem)

    if hasItem then
        local instanceId = item:GetInstanceID()
        local dataList = gModelMail:FormatShowItems(itemdata._attachments)
        local uiItemListCls = self:FindUIScroll(instanceId) --self._uiCommonListList[instanceId]
        if uiItemListCls then
            uiItemListCls:RefreshList(dataList)
        else
            uiItemListCls = self:GetUIScroll(instanceId)  --UIItemList:New(self)
            --self._uiCommonListList[instanceId] = uiItemListCls
            uiItemListCls:Create(itemList, dataList, function(...)
                self:OnDrawRewardItem(uiItemListCls, ...)
            end, UIItemList.WRAP)
        end
    end

    CS.ShowObject(rewardTag, hasItem)
    local icon = itemdata._fetch and "mail_icon_1_2" or "mail_icon_1_1"
    self:SetWndEasyImage(rewardTag, icon, nil, true)

    self:InitTextSizeWithLanguage(title, -2)
end

function UIMil:ShowPage(page)
    if self._page == page then
        return
    end
    self._page = page
    self:RefreshUI()
end

function UIMil:InitEvent()
    self:WndNetMsgRecv(LProtoIds.MailListResp, function()
        self:RefreshUI()
    end)
    self:WndNetMsgRecv(LProtoIds.MailRemoveResp, function()
        self:RefreshUI()
    end)
    self:WndNetMsgRecv(LProtoIds.MailReceiveResp, function()
        self:RefreshUI()
    end)
    self:WndNetMsgRecv(LProtoIds.MailReaderResp, function()
        self:RefreshUI()
    end)

    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function()
    --	self:WndClose()
    --end)
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function()
        self:WndClose()
    end)
end

function UIMil:InitData()
    self._mailStateIconPath = {
        "mail_icon_read_no",
        "mail_icon_read_yes"
    }
    self._uiMailItem = {}

    --self._uiCommonListList ={}
end

function UIMil:RefreshUI()
    CS.ShowObject(self.mNormalBtn, true)
    CS.ShowObject(self.mSpecialBtn, true)
    self:InitScrollView()
    self:SetContent()
end

function UIMil:GetMailItem()
    gModelMail:MailReceiveReq(2)
end

function UIMil:SetStaticContent()
    self:SetXUITextText(self.mTitle, ccClientText(11202))
    self:SetWndText(self.mDeleteIntro, ccClientText(11201))
    self:InitTextLineWithLanguage(self.mDeleteIntro, -30)

    self:SetWndButtonText(self.mDeleteBtn, ccClientText(11203))

    self:SetWndButtonText(self.mGetBtn, ccClientText(11204))

    self:SetWndText(self.mTip, ccClientText(11212))

    local str = ccClientText(11215) --"普通邮件"
    self:SetWndTabText(self.mNormalBtn, str)
    str = ccClientText(11216) --"安妮来信"
    self:SetWndTabText(self.mSpecialBtn, str)

end
function UIMil:DeleteReadMail()
    gModelMail:DeleteMail(2)
end

------------------------------------------------------------------
return UIMil


