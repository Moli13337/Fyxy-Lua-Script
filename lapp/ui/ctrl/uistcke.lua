---
--- Created by ly.
--- DateTime: 2023/10/13 12:03:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIStCke:LWnd
local UIStCke = LxWndClass("UIStCke", LWnd)

local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
local typeScrollRect = typeof(UnityEngine.UI.ScrollRect)
--local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIStCke:UIStCke()
    self._delayScrollKey = "_delayScrollKey"
    self._countDownKey = "_countDownKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIStCke:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIStCke:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIStCke:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mTotaCakeCount, -5, true)
        local uiText = LxUiHelper.FindXTextCtrl(self.mTotaCakeCount)
        uiText.enableWordWrapping = true

        local activeBtnTxt = CS.FindTrans(self.mActiveBtn, "Text")
        self:InitTextSizeWithLanguage(activeBtnTxt, -5, true)
        uiText = LxUiHelper.FindXTextCtrl(activeBtnTxt)
        uiText.enableWordWrapping = true
        LxUiHelper.SetSizeWithCurAnchor(activeBtnTxt, 0, 67)
    end

    self:InitMessage()
    self:InitEvent()
    self:InitData()
end

function UIStCke:OnActivityConfigData(data, sid)

    if sid ~= self._sid then
        return
    end

    self:InitContent()
    gModelActivity:OnActivityPageReq(self._sid)

end

--滑动列表
function UIStCke:InitList(page)
    local page = page
    if page == nil then
        return
    end
    local pageEntry = page.entry
    local targetList = {}
    local pageId = 0

    for i, v in pairs(pageEntry) do
        local goalData = v.goalData
        local schedules = goalData.schedules
        local items = v.items
        pageId = v.pageId
        local status = goalData.status
        local entryId = v.entryId
        local reward = {
            count = items[1].count,
            effect = items[1].effect,
            itemId = items[1].itemId,
            type = items[1].type,
        }

        local target = {
            eventType = schedules[1].eventType,
            goal = schedules[1].goal,
            multiple = schedules[1].multiple,
            schedule = schedules[1].schedule,
            status = status,
            entryId = entryId,
            reward = reward,
            pageId = v.pageId,
            index = i
        }
        table.insert(targetList, target)

    end

    table.sort(targetList, function(a, b)
        return a.index < b.index
    end)

    self._rewardList = targetList
    local allGoal = 0
    local nowSchedule = 0

    self._objPool:ReturnAllObj()

    local index = 0
    for k, v in ipairs(targetList) do
        local obj = self._objPool:GetObj()
        CS.ShowObject(obj, true)
        CS.SetParentTrans(obj, self.mBoxRoot)
        self:SetTargetItem(obj.transform, v)
        allGoal = tonumber(v.goal)
        local targetSchedule = tonumber(v.schedule)
        if targetSchedule ~= 0 then
            nowSchedule = targetSchedule
        end

        local status = v.status
        if status ~= 0 then
            index = k
            nowSchedule = targetSchedule
        end
    end

    local itemCnt = #targetList

    if not index then
        index = itemCnt
    end

    local progress = index / itemCnt

    LxUiHelper.SetProgress(self.mBoxProgress, progress)
    self:SetWndText(self.mTotaCakeCount, ccClientText(29711))

    self._delayScrollFun = function()
        self:DelayScrollTo(index, itemCnt)
    end
    self:TimerStop(self._delayScrollKey)
    self:TimerStart(self._delayScrollKey, 0, false, 1)
    self._pageId = pageId

end

function UIStCke:UpdateGameBtnRedPoint()
    local red = CS.FindTrans(self.mGameStartBtn, "redPoint")
    CS.ShowObject(red, self._Count > 0)
end

function UIStCke:SetRank(pb)
    if pb.activityId ~= self._sid then
        return
    end
    if pb.infos then
        for i = 1, 3 do
            local trans = CS.FindTrans(self.mRank, "Rank" .. i)
            self:SetRankTrans(trans, pb.infos[i])
        end

        local trans = CS.FindTrans(self.mRank, "SelfRank")
        if pb.selfRank and pb.selfRank.rank > 0 then
            self:SetRankTrans(trans, pb.selfRank)
        end
        CS.ShowObject(trans, pb.selfRank and pb.selfRank.rank > 0)
    end
end

function UIStCke:OnActivityPageResp(pb, ret)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end

    local pages = {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        table.insert(pages, page)
    end
    self._pages = pages
    self:FillScrollRectContent()

    self:UpdateActiveRedPoint()
    self:UpdateGameBtnRedPoint()
end

function UIStCke:SetRankTrans(trans, data)
    local num = CS.FindTrans(trans, "Num")
    local icon = CS.FindTrans(trans, "Icon")
    local name = CS.FindTrans(trans, "Name")

    if data and data.rank > 0 then
        if data.rank > 3 then
            self:SetWndText(num, data.rank)
        else
            local res = "public_num_" .. data.rank
            self:SetWndEasyImage(icon, res)
        end
        self:SetWndText(name, data.info.name)
        CS.ShowObject(num, data.rank > 3)
        CS.ShowObject(icon, data.rank <= 3)
    else
        self:SetWndText(name, ccClientText(11707))
    end
end

function UIStCke:UpdateActiveRedPoint()
    local page = {}
    for _, v in ipairs(self._pages) do
        if v.data == "手动领取奖励" then
            page = v.entry
        end
    end

    local isRed = false
    for _, v in ipairs(page) do
        if v.goalData.status == 1 then
            isRed = true
            break
        end
    end
    local red = CS.FindTrans(self.mActiveBtn, "redPoint")
    CS.ShowObject(red, isRed)
end

function UIStCke:FillScrollRectContent()
    --填充滑动条内容

    local isRe = #self._pages <= 1
    local page
    if isRe then
        --只返回全服奖励 刷新列表
        page = self._pages[1]
        self:InitList(page)
        return
    else
        page = self._pages[3]
    end

    self:InitList(page)

    -- local rewardList = LxDataHelper.SevenParseRewardList(self._sid,self._pages[2])
    -- --gModelFunctionOpen:Jump(810001, self:GetWndName())
    -- local isOpen = gModelFunctionOpen:CheckIsOpened(810001,true)
    -- self:SetWndClick(self.mMyRankBtn,function()
    -- 	GF.OpenWndBottom("UIRkPop",{refId = 2300,sid = self._sid,rewardList = rewardList,rankTips = self._rankTips,callFunc=function()
    -- 		gModelFunctionOpen:Jump(10480002, self:GetWndName(),function()
    -- 		end)
    -- 	end })
    -- 	self:WndClose()
    -- end)

    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end
    local activityMoreInfo = JSON.decode(activityData.moreInfo)
    self._Count = tonumber(activityMoreInfo.remainTime)
    self:SetTotalCount()

end

function UIStCke:InitData()
    CS.ShowObject(self.mGameDiv, false)
    local sid = self:GetWndArg("sid")
    self._page = self:GetWndArg("page") or 0 --支持跳转
    local _subPage = self:GetWndArg("subPage")
    if _subPage then
        sid = gModelActivity:GetSidByUniqueJump(_subPage)
    end
    local modelId = gModelActivity:GetActivityModeIdBySid(sid)
    self._sid = sid
    self._modelId = modelId
    gModelActivity:ReqActivityConfigData(self._sid)
    self._objPool = UIObjPool:New()
    self._objPool:Create(self.mUnuseRoot, self.mItemTemplate)

    self:SetWndText(CS.FindTrans(self.mReturnBtn, "TxtClose"), ccClientText(41102))
    self:SetWndText(CS.FindTrans(self.mActiveBtn, "Text"), ccClientText(29713))
    self:SetWndText(self.mLookText, ccClientText(43105))
    self:SetWndText(self.mRankTitle, ccClientText(11700))
    gModelRank:OnRankReq(2, 2301, 1, 3, sid)
end

function UIStCke:SetTotalCount()
    local str = ""                                                      --今天剩余次数
    -- local count=tonumber(self._Count)
    -- if count==0 then
    -- 	str=string.replace(ccClientText(29700),count)
    -- else
    -- 	str=string.replace(ccClientText(29701),count)
    -- end

    if self._Count == 0 then
        local payCount = self.allPayCount - self.buyTime
        if payCount > 0 then
            str = string.replace(ccClientText(29714), payCount)
        else
            str = string.replace(ccClientText(29715), 0)
        end
    else
        str = string.replace(ccClientText(29701), self._Count)
    end

    self:SetWndButtonGray(self.mGameStartBtn, self._Count == 0 and (self.allPayCount - self.buyTime == 0))

    self:SetWndText(self.mCountText, str)
end

function UIStCke:InitContent()

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

    self._Count = tonumber(activityMoreInfo.remainTime)                                    --叠蛋糕：每日剩余次数
    self.allPayCount = tonumber(data.residueDegreePayNum)
    self.payMoney = LxDataHelper.ParseItem(data.residueDegreePay)
    self.buyTime = tonumber(activityMoreInfo.buyTime)

    self:SetTotalCount()
    self:UpdateGameBtnRedPoint()

    self._totalTime = activityMoreInfo.countDown
    self._doubleTime = activityMoreInfo.doubleTime
    self._hSpeed = activityMoreInfo.displacementTime
    self._vSpeed = activityMoreInfo.dropTime
    self._upperIimit = activityMoreInfo.upperIimit  --数量上限
    self._skewingSection = activityMoreInfo.skewingSection  --数量上限
    self._gameSpineName = data.gameSpineName
    self._rankTips = data.rankTips

    local bgs = string.split(data.signImage, '|') or {}
    self._signImage = bgs

    local rank = data.rank or 1
    if rank == 0 then
        CS.ShowObject(self.mRank, false)
    end

    local endTime = activityData.endTime or 0                               --活动结束时间
    self._endTime = endTime
    self:TimerStop(self._countDownKey)
    self:RefreshCountDown()
    self:TimerStart(self._countDownKey, 1, false, -1)

    self:SetWndClick(self.mHelpTipsBtn, function()
        --帮助说明
        GF.OpenWnd("UIBzTips", { title = activityData.title, text = data.pileHelpTips })
    end)

    local imgPath = data.headline                               --标题图片
    if LxUiHelper.IsImgPathValid(imgPath) then
        self:SetWndEasyImage(self.mTitleImg, imgPath, function()
            CS.ShowObject(self.mTitleImg, true)
        end, true)
    end

    imgPath = data.interfaceImage                               --背景图片
    if LxUiHelper.IsImgPathValid(imgPath) then
        self:SetWndEasyImage(self.mCakeBgImg, imgPath, function()
            CS.ShowObject(self.mCakeBgImg, true)
        end, true)
    end

    imgPath = data.cakeIcon                               --背景图片
    if LxUiHelper.IsImgPathValid(imgPath) then
        self:SetWndEasyImage(self.mCakeIcon, imgPath, function()
            CS.ShowObject(self.mCakeIcon, true)
        end, true)
    end
end

function UIStCke:DelayScrollTo(index, itemCnt)
    local rect = self.mItemList.rect
    local viewLength = rect.width
    rect = self.mContent.rect
    local contentLength = rect.width
    if contentLength <= viewLength then
        return
    end
    local total = itemCnt

    local padding = 0
    local layout = self.mBoxRoot:GetComponent(typeHorizontalLayoutGroup)
    padding = layout.padding.left

    local factor = (padding + (index - 0.5) * contentLength / total - viewLength / 2) / (contentLength - viewLength)
    factor = Mathf.Clamp(factor, 0, 1)

    local scrollRect = self.mItemList:GetComponent(typeScrollRect)
    scrollRect.normalizedPosition = Vector2(0, factor)
end

function UIStCke:InitEvent()

    self:SetWndText(self.mReturnBtnTxt, ccClientText(29703))  --返回按钮
    self:SetWndClick(self.mReturnBtn, function()

        self:WndClose()
        GF.OpenWnd("UIMotifActEntrance")
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndButtonText(self.mGameStartBtn, ccClientText(29712))
    self:SetWndClick(self.mGameStartBtn, function()
        --开始游戏
        local count = tonumber(self._Count)
        if count == 0 then
            local payCount = self.allPayCount - self.buyTime
            if payCount > 0 then
                local data = self.payMoney[self.buyTime + 1]
                data = data ~= nil and data or self.payMoney[#self.payMoney]
                if gModelGeneral:CheckItemEnough(data.itemId, data.itemNum, true) then
                    GF.OpenWnd("UIOrdinTip", {
                        refId = 470201,
                        para = {
                            data.itemNum,
                            gModelGeneral:GetCommonItemName(data)
                        },
                        func = function()
                            gModelActivity:OnActivitySpecialOpReq(self._sid, nil, nil, 47)
                        end
                    })
                end
            else
                GF.ShowMessage(ccClientText(29702))
            end
            return
        end
        local data = {
            time = self._totalTime,
            doubleTime = self._doubleTime,
            hSpeed = self._hSpeed,
            vSpeed = self._vSpeed,
            upperIimit = self._upperIimit,
            pages = self._pages,
            sid = self._sid,
            pageId = self._pageId,
            skewingSection = self._skewingSection,
            signImage = self._signImage,
            spineName = self._gameSpineName,
            config = self._config
        }

        GF.OpenWnd("UIStCkeGame", data)

    end)

    -- self:SetWndText(self.mBtnMyRankText,ccClientText(29704))       --我的排行


end

function UIStCke:InitMessage()


    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:InitContent()
        self:OnActivityPageResp(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityResp, function()
        self:InitContent()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndNetMsgRecv(LProtoIds.SpecialWindowResp, function(pb)
        self:InitContent()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp, function(pb)
        self:InitContent()
        gModelActivity:OnActivityPageReq(self._sid)
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:InitContent()
        gModelActivity:OnActivityPageReq(self._sid)
    end)
    self:WndNetMsgRecv(LProtoIds.RankResp, function(...)
        self:SetRank(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp, function(pb)
        if pb.sid == self._sid and pb.opType == 47 then
            local data = {
                time = self._totalTime,
                doubleTime = self._doubleTime,
                hSpeed = self._hSpeed,
                vSpeed = self._vSpeed,
                upperIimit = self._upperIimit,
                pages = self._pages,
                sid = self._sid,
                pageId = self._pageId,
                skewingSection = self._skewingSection,
                signImage = self._signImage,
                spineName = self._gameSpineName,
                config = self._config
            }

            GF.OpenWnd("UIStCkeGame", data)
        end
    end)

    self:SetWndClick(self.mRank, function()
        GF.OpenWndBottom("UIRkPop", { refId = 2301, sid = self._sid })
    end)
    self:SetWndClick(self.mActiveBtn, function()
        GF.OpenWndBottom("UIStCkeTk", { sid = self._sid })
    end)
end

function UIStCke:OnTimer(key)
    if self._delayScrollKey == key then
        if self._delayScrollFun then
            self._delayScrollFun()
        end
    elseif key == self._countDownKey then
        self:RefreshCountDown()
    end
end
function UIStCke:SetTargetItem(item, itemdata)

    local Image = self:FindWndTrans(item, "Image")
    local icon = self:FindWndTrans(item, "icon")
    local UIText = self:FindWndTrans(item, "UIText")
    local num = self:FindWndTrans(item, "num")
    local tag = self:FindWndTrans(item, "tag")
    local mark = self:FindWndTrans(item, "mark")

    CS.ShowObject(tag, false)
    CS.ShowObject(mark, false)

    local reward = itemdata.reward
    local iconPath = gModelItem:GetItemImgByRefId(reward.itemId)
    self:SetWndEasyImage(icon, iconPath)

    self:SetWndText(num, reward.count)
    local num = tonumber(itemdata.goal)
    num = self:GetNum(num)
    self:SetWndText(UIText, num)

    local status = itemdata.status
    if status == 1 then
        CS.ShowObject(tag, true)
        self:SetWndClick(tag, function()
            local list = {}
            local len = 0
            for k, v in ipairs(self._rewardList) do
                if v.status == 1 then
                    local data = { sid = self._sid, pageId = self._pageId, entryId = v.entryId }
                    table.insert(list, data)
                    len = len + 1
                end
            end
            if len > 1 then
                gModelActivity:OnActivityReceiveGoalListReq(list)
            else
                gModelActivity:OnActivityReceiveGoalReq(self._sid, self._pageId, itemdata.entryId)
            end
        end)
    end

    if status == 0 then
        --未达成
        self:SetWndClick(icon, function()
            gModelGeneral:ShowCommonItemTipWnd(reward)
        end)
    end

    if status == 2 then
        CS.ShowObject(mark, true)
        self:SetWndClick(mark, function()
            gModelGeneral:ShowCommonItemTipWnd(reward)
        end)
    end


end

function UIStCke:RefreshCountDown()
    local endTime = self._endTime
    if not endTime then
        CS.ShowObject(self.mBarImg, false)
        return
    end
    local time = GetTimestamp()
    local timespan = endTime - time
    if timespan > 0 then
        local timeStr = LUtil.FormatTimespanCn(timespan)
        local timeLeftStr = string.replace(ccClientText(29205), timeStr)
        self:SetWndText(self.mDeadlineText, timeLeftStr)
    else
        self:SetWndText(self.mDeadlineText, ccClientText(14301))
    end
    CS.ShowObject(self.mBarImg, true)
end

function UIStCke:GetNum(data)
    --转换单位
    local num = tonumber(data)
    if num ~= nil then
        local str = math.floor(num)
        if num >= 100000000 then
            num = num / 100000000
            str = math.floor(num) .. ccClientText(2014)  --*** 亿
        elseif num > 10000 then
            num = num / 10000
            str = math.floor(num) .. ccClientText(2013)  --*** 万
        end
        return str
    end
    return data
end

------------------------------------------------------------------
return UIStCke


