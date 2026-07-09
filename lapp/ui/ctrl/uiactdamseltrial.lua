---
--- Created by wzz.
--- DateTime: 2024/7/31 18:29:39
--- 活动155-少女试炼
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActDamselTrial:LWnd
local UIActDamselTrial = LxWndClass("UIActDamselTrial", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActDamselTrial:UIActDamselTrial()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActDamselTrial:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActDamselTrial:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActDamselTrial:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    local sid = self:GetWndArg("sid")
    if not sid then
        local subpage = self:GetWndArg("subPage") --支持跳转
        if subpage then
            sid = gModelActivity:GetSidByUniqueJump(subpage)
        end
    end
    self._sid = sid

    if not self._sid then
        self:WndClose()
        return
    end

    gModelActivity:OnActivityPageReq(self._sid)

    local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
    if not activityCfg then
        gModelActivity:ReqActivityConfigData(self._sid)
    else
        self:InitData()
    end
    self:InitTimer()
    self:InitTexts()
    self:InitEvents()

    self:Refresh()
end

-- 刷新列表
function UIActDamselTrial:RefreshList()
    local entries = self._entries
    if not entries then
        return
    end

    local pos = 0
    for i, entry in ipairs(entries) do
        if self._moreInfo.currentLevel == entry.id then
            pos = math.max(0, i - 1)
            break
        end
    end

    if not self._uiList then
        local uiList = self:GetUIScroll("mList")
        self._uiList = uiList
        uiList:Create(self.mList, entries, function(...)
            self:OnDrawListItem(...)
        end, UIItemList.SUPER_GRID)

        self._uiList:MoveToPos(pos)
    else
        -- self._uiList:RefreshData(self._uiDataList, true)
        self._uiList:DrawAllItems()
        self._uiList:MoveToPos(pos)
    end
end

-- 页面数据回调
function UIActDamselTrial:OnPageChange(_, sid, pages)
    if self._sid ~= sid then
        return
    end

    local activityCfg = gModelActivity:GetWebActivityDataById(sid)
    if not activityCfg then
        return
    end
    self:InitData()

    self:Refresh()
end

-- 绘制列表item项
function UIActDamselTrial:OnDrawListItem(list, item, itemData, itemPos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            root = CS.FindTrans(item, "AniRoot"),
            txtTitle = CS.FindTrans(item, "AniRoot/TxtTitle"),
            txtTips = CS.FindTrans(item, "AniRoot/TxtTips"),
            itemList = CS.FindTrans(item, "AniRoot/ItemList"),
            txtNum = CS.FindTrans(item, "AniRoot/TxtNum"),
            hadPass = CS.FindTrans(item, "AniRoot/HadPass"),
            btnFight = CS.FindTrans(item, "AniRoot/BtnFight"),
            btnFast = CS.FindTrans(item, "AniRoot/BtnFast"),
            txtLockTips = CS.FindTrans(item, "AniRoot/TxtLock"),
            mask = CS.FindTrans(item, "AniRoot/Mask"),
            lockTime = CS.FindTrans(item, "AniRoot/LockTime"),
            costIcon = CS.FindTrans(item, "AniRoot/BtnFast/Cost/1/CostIcon"),
            costNum = CS.FindTrans(item, "AniRoot/BtnFast/Cost/CostNum"),
        }
        self:SetComponentCache(instanceID, itemCache)

        local uiList = UIIconEasyList:New()
        uiList:Create(self, itemCache.itemList)
        uiList:SetShowNum(true)
        uiList:SetIconParentPath("itemRoot")
        itemCache.uiList = uiList

        self:SetWndButtonText(itemCache.btnFight, ccClientText(44816))
        self:SetWndText(itemCache.txtLockTips, ccClientText(44815))
        self:SetWndText(itemCache.txtTips, ccClientText(44812))
        self:SetTextTile(itemCache.hadPass, ccClientText(44822))
    end

    local entry = itemData
    local id = entry.id
    self:SetWndText(itemCache.txtTitle, ccClientText(44811, id))

    if id == 4 then
        printInfoN2("--", "--")
    end
    local curDate =  LUtil.OSDate("*t", GetTimestamp())
    local list = string.split(entry.moreInfo, "|")
    local needDay = tonumber(list[1]) or 0
    local needDate =  LUtil.OSDate("*t", self._actData.startTime + (needDay - 1) * 24 * 3600)
    local strTime = ""
    if (curDate.month == needDate.month and curDate.day < needDate.day) or (curDate.month < needDate.month) then
        strTime = ccClientText(44819, needDate.month, needDate.day)
    end

    local passId = self._moreInfo.currentLevel

    local hadPass = passId - 1 >= id
    local showFast = passId == id
    local showFight = passId + 1 == id
    local showLock = passId + 1 < id
    local showTime = false
    if strTime ~= "" then
        showTime = passId + 1 == id
    end

    local costItem
    local strNum = ""
    local strBtnFast = ""
    local btnFastGray = false
    local btnFightGray = false
    local btnFightTips = ""
    self:SetRed(itemCache.btnFast, false)
    if showFast then
        local curNum = self._moreInfo.todaySweepCnt
        local freeNum = self._config.sweepExpendFree
        local total = freeNum + self._config.sweepExpendNum
        strNum = ccClientText(44813, curNum, total)
        if freeNum > curNum then
            strBtnFast = ccClientText(44820)
            self:SetRed(itemCache.btnFast, true)
        else
            local index = math.min(curNum - freeNum + 1, #self._costItemList)
            costItem = self._costItemList[index]
            btnFastGray = total <= curNum
        end
    elseif showFight then
        local curNum = self._moreInfo.failCnt
        local total = self._config.lossNum
        strNum = ccClientText(44814, curNum, total)
        btnFightGray = curNum >= total
        btnFightTips = ccClientText(44821)
    end
    if not btnFightGray then
        btnFightGray = strTime ~= ""
        if btnFightGray then
            btnFightTips = strTime
        end
    end

    if costItem then
        local iconPath = gModelItem:GetItemImgByRefId(costItem.itemId)
        self:SetWndEasyImage(itemCache.costIcon, iconPath)
        self:SetWndText(itemCache.costNum, costItem.itemNum)
    end

    self:SetWndButtonText(itemCache.btnFast, strBtnFast)
    self:SetWndText(itemCache.txtNum, strNum)
    self:SetWndButtonGray(itemCache.btnFast, btnFastGray)
    self:SetWndButtonGray(itemCache.btnFight, btnFightGray)
    self:SetTextTile(itemCache.lockTime, strTime)

    CS.ShowObject(itemCache.mask, showLock or showTime)
    CS.ShowObject(itemCache.lockTime, showTime)
    CS.ShowObject(itemCache.txtLockTips, (showLock or showTime) and not showFight)
    CS.ShowObject(itemCache.hadPass, hadPass)
    CS.ShowObject(itemCache.btnFight, showFight)
    CS.ShowObject(itemCache.btnFast, showFast)
    CS.ShowObject(itemCache.costNum.parent, strBtnFast == "")

    local itemList = LUtil.GetRefItemDataList((showFast or hadPass) and entry.blitzReward or entry.reward)
    itemCache.uiList:RefreshList(itemList)

    self:SetWndClick(itemCache.btnFast, function()
        self:OnClickItemBtnFast(id, costItem, btnFastGray)
    end)

    self:SetWndClick(itemCache.btnFight, function()
        self:OnClickItemBtnFight(entry, btnFightGray, btnFightTips)
    end)
end

-- 初始化数据
function UIActDamselTrial:InitData()
    local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)

    self._actData = gModelActivity:GetActivityBySid(self._sid)
    if not self._actData then
        return
    end

    self._pageId = 1
    self._config = activityCfg.config
    self._entries = activityCfg.chunk[self._pageId].entries
    self._costItemList = LUtil.GetRefItemDataList(self._config.sweepExpend)

    local info = JSON.decode(self._actData.moreInfo)
    self._moreInfo = info
end

-- 初始界面
function UIActDamselTrial:InitView()
    if self._initView then
        return
    end
    self._initView = true

    local config = self._config
    if config.isShowImage ~= "" then
        self:SetWndEasyImage(self.mImgTitle, config.isShowImage)
    end

    if config.bg ~= "" then
        self:SetWndEasyImage(self.mBg, config.bg)
    end

    self:SetWndClick(self.mBtnHelp, function()
        local title = config.name
        local content = config.helpTips
        GF.OpenWnd("UIBzTips", { title = title, text = content })
    end)
    CS.ShowObject(self.mBtnHelp, config.helpTips ~= "")

    if config.timePos ~= "" then
        local list = string.split(config.timePos, "|")
        local x = tonumber(list[1]) or 0
        local y = tonumber(list[2]) or 0
        if x ~= 0 or y ~= 0 then
            self.mTxtTitle.parent.anchoredPosition = Vector2(x, y)
        end
    end

    if config.isShowImagePos ~= "" then
        local list = string.split(config.isShowImagePos, "|")
        local x = tonumber(list[1]) or 0
        local y = tonumber(list[2]) or 0
        if x ~= 0 or y ~= 0 then
            self.mImgTitle.anchoredPosition = Vector2(x, y)
        end
    end

    if config.helpTipsPos ~= "" then
        local list = string.split(config.helpTipsPos, "|")
        local x = tonumber(list[1]) or 0
        local y = tonumber(list[2]) or 0
        if x ~= 0 or y ~= 0 then
            self.mBtnHelp.anchoredPosition = Vector2(x, y)
        end
    end
end

-- 初始事件
function UIActDamselTrial:InitEvents()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_PAGE_CHANGE, function(...)
        self:OnPageChange(...)
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function(...)
        self:Refresh()
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_LIST_CHANGE, function(...)
        self:InitData()
        self:Refresh()
    end)

end

-- Update
function UIActDamselTrial:Update()
    local data = gModelActivity:GetActivityBySid(self._sid)
    if not data then
        return
    end

    local endTime = data.endTime
    local curTime = GetTimestamp()
    local leftTime = endTime - curTime
    if leftTime <= 0 then
        self:SetWndText(self.mTxtTitle, ccClientText(44817))
        return
    end
    local str = LUtil.FormatTimespanCn(leftTime)
    self:SetWndText(self.mTxtTitle, ccClientText(44818, str))
end

-- 点击列表item 挑战按钮
function UIActDamselTrial:OnClickItemBtnFight(entry, btnGray, tips)
    if btnGray then
        if not tips then
            tips = ccClientText(44821)
        end
        GF.ShowMessage(tips)
        return
    end
    GF.OpenWnd("UIActDamselTrialEnter", { sid = self._sid, pageId = self._pageId, entry = entry })
end

-- 点击列表item 扫荡按钮
function UIActDamselTrial:OnClickItemBtnFast(id, costItem, btnGray)
    if btnGray then
        GF.ShowMessage(ccClientText(44821))
        return
    end

    local function Send()
        gModelActivity:OnActivitySpecialOpReq(self._sid, self._pageId, id, 78)
    end

    if not costItem then
        Send()
        return
    end

    local haveNum = gModelItem:GetNumByRefId(costItem.itemId)
    if haveNum < costItem.itemNum then
        gModelGeneral:OpenGetWayWnd({ itemId = costItem.itemId })
        return
    end

    local strName = gModelItem:GetNameByRefId(costItem.itemId)
    gModelGeneral:OpenUIOrdinTips({
        refId = 470002,
        para = { costItem.itemNum, strName },
        func = Send,
    })
end

-- 配置数据回调
function UIActDamselTrial:OnActivityConfigData(_, sid)
    if self._sid ~= sid then
        return
    end

    local activityCfg = gModelActivity:GetWebActivityDataById(sid)
    if not activityCfg then
        return
    end
    self:InitData()

    self:Refresh()
end

-- 初始界面化文本
function UIActDamselTrial:InitTexts()
    self:SetWndText(self.mTxtClose, ccClientText(42010))
end

-- 初始时间
function UIActDamselTrial:InitTimer()
    local timePara = {
        key = 1,
        loopcnt = -1,
        interval = 1,
        timescale = false,
        callOnStart = true,
        func = function()
            self:Update()
        end
    }
    self:TimerStartImpl(timePara)
end

-- 刷新界面
function UIActDamselTrial:Refresh()
    local config = self._config
    if not config then
        return
    end

    self:InitView()

    self:SetTopAssetList(self.mTopAsset, { self._costItemList[1].refId })
    self:RefreshList()
end

------------------------------------------------------------------
return UIActDamselTrial