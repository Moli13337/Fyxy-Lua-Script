---
--- Created by Administrator.
--- DateTime: 2024/5/14 20:01:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOpenSerGiftWin:LWnd
local UIOpenSerGiftWin = LxWndClass("UIOpenSerGiftWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOpenSerGiftWin:UIOpenSerGiftWin()
    ---@type table<StructActivityPage>
    self.pageList = nil
    self._tabList = {}
    self._tabStr = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOpenSerGiftWin:OnWndClose()
    LWnd.OnWndClose(self)
    if self.openServerGift then
        self.openServerGift:WndClose()
        self.openServerGift = nil
    end
    if self._delayTimer then
        LxTimer.DelayTimeStop(self._delayTimer)
        self._delayTimer = nil
    end
    if self.entrance then
        self.activityData.groupId = nil
    end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOpenSerGiftWin:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOpenSerGiftWin:OnStart()
    LWnd.OnStart(self)
    ---@type StructActivity
    self.activityData = self:GetWndArg("activityData")
    self.pageId = self:GetWndArg("pageId")
    self.entryId = self:GetWndArg("entryId")
    self.entrance = self:GetWndArg("entrance")
    self.webConfig = gModelActivity:GetWebActivityDataById(self.activityData.sid)
    self._sid = self.activityData.sid
    self:InitUI()
    self:InitEvents()
    gModelActivity:OnActivityPageReq(self.activityData.sid)
end

function UIOpenSerGiftWin:OpenChildCtrl()
    local params = { sid = self.activityData.sid, pageId = self.pageId, entryId = self.entryId }
    if not self.openServerGift then
        self.openServerGift = self:CreateChildWnd(self.mChildRoot, "UISubOpenSerGift", params)
    else
        self.openServerGift:SetData(params)
    end
end

function UIOpenSerGiftWin:DoChangeTab(index)
    if self._curTabIndex == index then
        return
    end
    local oldIndex = self._curTabIndex
    self._curTabIndex = index
    self.pageId = self.pageList[index].pageId
    local oldSelect = CS.FindTrans(self._tabList[oldIndex], "ImgSelect")
    CS.ShowObject(oldSelect, false)

    local oldTxtName = CS.FindTrans(self._tabList[oldIndex], "TxtName")
    local oldstr = self._tabStr[oldIndex]
    oldstr = LUtil.FormatColorStr(oldstr, "#e1e7ff")
    self:SetWndText(oldTxtName, oldstr)

    local newSelect = CS.FindTrans(self._tabList[index], "ImgSelect")
    CS.ShowObject(newSelect, true)

    local newTxtName = CS.FindTrans(self._tabList[index], "TxtName")
    local newstr = self._tabStr[index]
    newstr = LUtil.FormatColorStr(newstr, "#fffdda")
    self:SetWndText(newTxtName, newstr)

    self:OpenChildCtrl()
end
function UIOpenSerGiftWin:InitDatas()
    --礼包列表
    local activityPageList = gModelActivity:GetActivityPagesListBySid(self.activityData.sid)
    if not activityPageList or not self.webConfig then
        return
    end
    if self.webConfig and self.webConfig.config then
        local webCfg = self.webConfig.config
        local pageForm = string.split(webCfg.pageForm, "|")
        --local pageForm = string.split(self.webConfig.config.pageForm, "|")
        self.pageBtnImg = {}
        for index, value in ipairs(pageForm) do
            local info = string.split(value, "=")
            self.pageBtnImg[tonumber(info[1])] = info
        end
        self._webConfig = webCfg
    end
    if not self.activityData.groupId then
        local groupid = {}
        self.activityData.groupId = groupid
        local info = JSON.decode(self.activityData.moreInfo)
        local pageRemain = LxDataHelper.ParseItem(info.pageRemain or "", "|")
        local activityDay = math.ceil((GetTimestamp() - self.activityData.startTime) / 86400)
        for k, p in ipairs(pageRemain or {}) do
            if p.itemId <= activityDay then
                groupid[p.itemType] = p.itemType
            end
        end
    end
    self.pageList = {}
    local isAllBuyShowCfg =  self._webConfig and self._webConfig.isShow == 1
    for i, v in pairs(activityPageList) do
        if self.activityData.groupId[v.pageId] then
            --这里还要去判断里面是否可以购买有则插入
            local isCanInSert = false
            for _, entry in ipairs(v.entry) do
                local marketData = entry.MarketData

                isCanInSert = not (marketData.personal >= marketData.personalGoal)

                if isCanInSert then
                    break
                end
            end
            if isCanInSert or isAllBuyShowCfg then
                table.insert(self.pageList, v)
            end
        end
    end
    table.sort(self.pageList, function(a, b)
        return a.pageId > b.pageId
    end)
    if not self._curTabIndex then
        if self.pageId then
            for i, v in ipairs(self.pageList) do
                if v.pageId == self.pageId then
                    self._curTabIndex = i
                end
            end
        else
            self._curTabIndex = 1
            self.pageId = self.pageList[self._curTabIndex].pageId
        end
    end
    CS.ShowObject(self.mTabScroll, #self.pageList > 1)
    self:InitTabList()

    self:RefreshConvertBtn()
end

function UIOpenSerGiftWin:InitEvents()
    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mConvertBtn, function(...)
        self:OnClickConvertBtn()
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_PAGE_CHANGE, function()
        self:InitDatas()
        self:OpenChildCtrl()
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self._delayTimer = LxTimer.DelayTimeCall(function()
            if self.activityData then
                self.activityData.groupId = nil
                self._curTabIndex = nil
                self.pageId = nil
            end
            self:InitDatas()
            self:OpenChildCtrl()
            LxTimer.DelayTimeStop(self._delayTimer)
            self._delayTimer = nil
        end, 3)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function(data,sid)
        if sid ~= self.activityData.sid then return end
        self:InitDatas()
        self:OpenChildCtrl()
    end)
end

function UIOpenSerGiftWin:OnDrawTab(list, item, itemdata, index)
    local ImgIcon = CS.FindTrans(item, "ImgIcon")
    local ImgSelect = CS.FindTrans(item, "ImgSelect")
    local TxtName = CS.FindTrans(item, "TxtName")
    -- local redPoint = CS.FindTrans(item,"redPoint")
    local tabData = self.pageBtnImg[itemdata.pageId]

    CS.ShowObject(ImgSelect, self._curTabIndex == index)

    local color = self._curTabIndex == index and "#fffdda" or "#e1e7ff"
    local str = LUtil.FormatColorStr(tabData[2], color)
    local isEn = LGameLanguage:IsEnglishVersion()
    if isEn then
        local xuiTextTrans = self:FindWndText(TxtName)
        self:SetXUITextFontSize(xuiTextTrans, 16)
    end
    self:SetWndText(TxtName, str)

    self:SetWndEasyImage(ImgIcon, tabData[4])
    local csImage = LxUiHelper.FindImageCtrl(ImgIcon)
    csImage:SetNativeSize()
    self:SetWndClick(item, function(...)
        self:DoChangeTab(index)
    end)
    self._tabList[index] = item
    self._tabStr[index] = tabData[2]

    if gLGameLanguage:IsVieVersion() then
        self:InitTextSizeWithLanguage(TxtName,-6)
    end
end

function UIOpenSerGiftWin:InitTabList()
    local uiList = self:GetUIScroll("openserverGift")
    uiList:Create(self.mTabScroll, self.pageList or {}, function(...)
        self:OnDrawTab(...)
    end)
    self._tabUiList = uiList

    uiList:MoveToPos(1)
end

--region 无损转换入口 A开发需求 #6228
function UIOpenSerGiftWin:RefreshConvertBtn()
    local cfg = self._webConfig
    local heroConvert = cfg.heroConvert
    local isShowBtn = heroConvert and heroConvert == 1
    if(isShowBtn and cfg.heroConvertTxt1)then
        self:SetWndText(self.mConvertBtnTxt,ccLngText(cfg.heroConvertTxt1))--冰火转换
        self:SetWndEasyImage(self.mConvertBtn,cfg.heroConvertIcon)
        local convertIconPos = cfg.convertIconPos
        if(not string.isempty(convertIconPos))then
            self:SetAnchorPos(self.mConvertBtn,LxDataHelper.ParseVector2NotEmpty(convertIconPos))
        end
    end
    --isShowBtn = false-- 无ui隐藏入口
    self._isShowBtn = isShowBtn
    CS.ShowObject(self.mConvertBtn,isShowBtn)
end
function UIOpenSerGiftWin:OnClickConvertBtn()
    if(self._isShowBtn)then
        local args = {
            cfg = self._webConfig,
            sid = self._sid,
            pageId = self.pageId
        }
        GF.OpenWnd("UIActivityLosslessConvertPop",args)
    end
end
--endregion

------------------------------------------------------------------
return UIOpenSerGiftWin