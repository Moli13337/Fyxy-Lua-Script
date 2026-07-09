---
--- Created by BY.
--- DateTime: 2023/10/21 11:14:44
---
---活动74 在线奖励
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActOnlineAwards:LWnd
local UIActOnlineAwards = LxWndClass("UIActOnlineAwards", LWnd)
local typeof = typeof
local typeUIImage = typeof(UnityEngine.UI.Image)
local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActOnlineAwards:UIActOnlineAwards()
    self._timeKey = "UIActOnlineAwards"
    --self._noticeTweenKey = "_noticeTweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActOnlineAwards:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActOnlineAwards:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActOnlineAwards:OnStart()
    LWnd.OnStart(self)

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isForeignRegion = gLGameLanguage:IsForeignRegion()
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UIActOnlineAwards:OnClickRewardRoot(status, entryCfg, itemdata, reward)
    if status == 0 then
        GF.ShowMessage(string.replace(ccClientText(28500), entryCfg.name))
        gModelGeneral:ShowCommonItemTipWnd(reward)
    elseif status == 1 then
        self:OnClickReward(itemdata)
    else
        gModelGeneral:ShowCommonItemTipWnd(reward)
    end
end

function UIActOnlineAwards:OnActivityConfigData(data, sid)
    if self._sid ~= sid then
        return
    end
    local _sid = self._sid
    local activityData = gModelActivity:GetWebActivityDataById(_sid)
    if not activityData then
        return
    end
    local data = activityData.config
    self._actWebConfig = data
    local descIconA, descIconAPos, activityIcon, iconDescription, numberPos, name, uniqueJump1, uniqueJump2 = data.descIconA, data.descIconAPos, data.activityIcon, data.iconDescription, data.numberPos, data.name, data.uniqueJump1, data.uniqueJump2
    self._awardTipsA, self._awardTipsB, self._DescriptionA, self._DescriptionB = data.awardTipsA, data.awardTipsB, data.DescriptionA, data.DescriptionB
    self._uniqueJump1, self._uniqueJump2 = uniqueJump1, uniqueJump2
    if LxUiHelper.IsImgPathValid(descIconA) then
        local posParent = self.mTextImg
        self:SetWndEasyImage(posParent, descIconA, nil, true)
        if not string.isempty(descIconAPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty2(descIconAPos)
            self:SetAnchorPos(posParent, pos)
        end
    end
    if not string.isempty(numberPos) then
        local pos = LxDataHelper.ParseVector2NotEmpty2(numberPos)
        self:SetAnchorPos(self.mTextNumText, pos)
    end
    if not string.isempty(name) then
        self:SetWndText(self.mTitleText, name)
    end

    --self:SetWndEasyImage(self.mNoticeIcon,activityIcon)
    --self:SetWndText(self.mNoticeText,iconDescription)
    gModelActivity:OnActivityPageReq(_sid)
    --self:RefreshData()
end
function UIActOnlineAwards:RefreshData()
    local _pages = self._pages or {}
    local page = _pages[1]
    if not page then
        return
    end
    local entry = page.entry
    local len = #entry
    local curEntryId = 0
    local list = {}
    for i, v in ipairs(entry) do
        local goalData = v.goalData
        local status = goalData.status
        if status == 0 and curEntryId == 0 then
            curEntryId = v.entryId
        end
        if i < len then
            table.insert(list, v)
        end
    end
    self._curEntryId = curEntryId
    self._onlineData = gModelActivity:GetOnlineRewardData(self._sid)

    --占位
    local dataLen = #list
    if dataLen > 6 then
        table.insert(list, 7, { isEmpty = true })
        table.insert(list, 7, { isEmpty = true })
    end
    if dataLen > 8 then
        table.insert(list, 11, { isEmpty = true })
        table.insert(list, 11, { isEmpty = true })
    end

    self._timeT = nil

    ---@type UIItemList
    local uiList = self._uiList
    if uiList then
        uiList:RefreshList(list)
        uiList:DrawAllItems(false)
    else
        uiList = self:GetUIScroll("mCellScroll")
        self._uiList = uiList
        uiList:Create(self.mCellScroll, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER_GRID)
        uiList:EnableScroll(#list > 12, false)
    end

    local endItem = entry[len]
    if endItem then
        CS.ShowObject(self.mRootEight, true)
        local goalData = endItem.goalData
        local schedules = goalData.schedules[1]
        local status = goalData.status
        local goal = tonumber(schedules.goal)
        local schedule = tonumber(schedules.schedule)
        local timespan = goal - schedule
        local num = LUtil.FormatHurtNumSpriteText(goal / 60)
        self:SetWndText(self.mTextNumText, num)
        self._timespan = timespan
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, endItem.pageId, endItem.entryId)

        local rewards = LxDataHelper.ParseItem(entryCfg.reward)
        local reward = rewards[1]
        local iconStr = gModelGeneral:GetCommonItemImgRef(reward)
        self:SetWndEasyImage(self.mItemIcon, iconStr)
        self:SetWndText(self.mItemNum, reward.itemNum)
        CS.ShowObject(self.mAwardsGetBg, status ~= 0)

        CS.ShowObject(self.mItemIconMask, status == 2)
        CS.ShowObject(self.mItemGetMask, status == 1)
        CS.ShowObject(self.mItemTimeText, status == 0)

        local timeT
        if curEntryId == endItem.entryId then
            timeT = {
                textTrans = self.mItemTimeText,
                time = timespan,
                count = 0,
            }
            self._timeT = timeT
            self._timeReq = false
        else
            self:SetWndText(self.mAwardsTimeText, entryCfg.description)
        end

        --local isOpenTwoAct = false
        --local _uniqueJump1 = self._uniqueJump1
        --if _uniqueJump1 and _uniqueJump1 > 0 then
        --	local activityData = gModelActivity:GetSpecialActivity(_uniqueJump1)
        --	isOpenTwoAct = activityData
        --	self._isOpenTwoAct = isOpenTwoAct
        --end
        --local noTimeStr = string.replace(self._DescriptionA or "%s",goal/60)
        --if isOpenTwoAct then
        --	noTimeStr = self._DescriptionB or ""
        --	noTimeStr = string.gsub(noTimeStr,"\\n","\n")
        --	self:SetTowee(self.mNoticeIcon,self._noticeTweenKey)
        --end
        --self:SetWndText(self.mNoticeTimeText,noTimeStr)

        CS.ShowObject(self.mAwardsEff, status == 1)
        if status == 1 then
            self:CreateWndEffect_Ex({
                trans = self.mAwardsEff,
                effName = "ui_fx_zaixianjiangli_02",
                effKey = "ui_fx_zaixianjiangli_02",
                scale = Vector3.New(65, 230, 100)
            })
        end
        self:SetWndClick(self.mAwardsBg, function()
            self:OnClickRewardRoot(status, entryCfg, endItem, reward)
        end)

        local _timeKey = self._timeKey
        if status == 0 then
            if not self:IsTimerExist(_timeKey) then
                self:TimerStart(_timeKey, 0.3, false, -1)
                self:SetTime()
            end
        else
            self:SetWndText(self.mTimeText, self._awardTipsB or "")
            self:TimerStop(_timeKey)
        end
    end
    self:SetItemTime()
end
function UIActOnlineAwards:InitCommand()
    self:SetWndText(self.mCloseTip, ccClientText(10103))

    CS.ShowObject(self.mRootEight, false)
    local sid = self:GetWndArg("sid")
    local _page = self:GetWndArg("page") --支持跳转
    local _subPage = self:GetWndArg("subPage")
    if _subPage then
        sid = gModelActivity:GetSidByUniqueJump(_subPage)
    end
    self._sid = sid
    gModelActivity:ReqActivityConfigData(sid)
end
function UIActOnlineAwards:ResetData(pb)
    local _pages = self._pages or {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        _pages[v.pageId] = page
    end
    self._pages = _pages
    self:RefreshData()
end

function UIActOnlineAwards:SetTowee(trans, key)
    local seqTween
    self:TweenSeqKill(key)
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            local time = 1.5
            local scale = trans.localScale
            local downPos = Vector3.New(0.95, 0.95, 0.95)
            local tweener = trans:DOScale(downPos, time)
            seq:Append(tweener)
            local tweener = trans:DOScale(scale, time)
            seq:Append(tweener)
            seq:SetLoops(-1, Tweening.LoopType.Restart)
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)
    end)
end

function UIActOnlineAwards:OnTimer(key)
    if key == self._timeKey then
        self:SetTime()
        self:SetItemTime()
    end
end
function UIActOnlineAwards:OnClickReward(itemdata)
    --领取奖励
    gModelActivity:OnActivityReceiveGoalReq(self._sid, itemdata.pageId, itemdata.entryId)
end
function UIActOnlineAwards:ListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    if itemdata.isEmpty then
        CS.ShowObject(root, false)
        return
    end
    CS.ShowObject(root, true)
    local entryId = itemdata.entryId
    local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, entryId)

    local image = self:FindWndTrans(root, "Image")
    local time1Text = self:FindWndTrans(root, "Time1Text")
    local time2Text = self:FindWndTrans(root, "Time2Text")
    local time3Text = self:FindWndTrans(root, "Time3Text")

    local timeMask = self:FindWndTrans(root, "TimeMask")
    local icon = self:FindWndTrans(root, "Icon")
    local iconMask = self:FindWndTrans(root, "IconMask")
    local numText = self:FindWndTrans(root, "NumText")
    local num2Text = self:FindWndTrans(root, "Num2Text")
    local eff = self:FindWndTrans(root, "Eff")

    local instanceID = item:GetInstanceID()
    local goalData = itemdata.goalData
    local schedules = goalData.schedules[1]
    local goal = tonumber(schedules.goal)
    local schedule = tonumber(schedules.schedule)
    local timespan = goal - schedule
    local min = math.floor(timespan / 60)
    local sec = math.floor(timespan) % 60
    local timeStr = string.format("%02d:%02d", min, sec)
    local status = goalData.status
    local _curEntryId = self._curEntryId or 0
    local timeT
    if _curEntryId == entryId then
        timeT = {
            textTrans = time2Text,
            time = timespan,
            count = 0,
        }
        self._timeT = timeT
        self._timeReq = false
    end

    local rewards = LxDataHelper.ParseItem(entryCfg.reward)
    local reward = rewards[1]

    local imagePath = ""
    if status == 2 then
        imagePath = "activity74_cell1"
    else
        imagePath = (status == 1 or _curEntryId == entryId) and "activity74_cell3" or "activity74_cell2"
    end
    self:SetWndEasyImage(image, imagePath)
    CS.ShowObject(timeMask, status == 1)
    CS.ShowObject(eff, status == 1)
    if status == 1 then
        self:CreateWndEffect_Ex({
            trans = eff,
            effName = "ui_fx_zaixianjiangli",
            effKey = instanceID .. "ui_fx_zaixianjiangli",
            scale = Vector3.New(100, 110, 100)
        })
    end
    self:SetWndText(time1Text, entryCfg.name)
    self:SetWndText(time2Text, timeStr)
    if status ~= 1 and self._curEntryId == entryId then
        CS.ShowObject(time2Text, true)
        CS.ShowObject(time1Text, false)
        CS.ShowObject(time3Text, false)
    else
        CS.ShowObject(time2Text, false)
        if status == 2 then
            CS.ShowObject(time3Text, true)
            CS.ShowObject(time1Text, false)
        elseif status == 1 then
            CS.ShowObject(time3Text, false)
            CS.ShowObject(time1Text, false)
        else
            CS.ShowObject(time3Text, false)
            CS.ShowObject(time1Text, true)
        end
    end

    local iconStr = gModelGeneral:GetCommonItemImgRef(reward)

    self:SetWndEasyImage(icon, iconStr)
    CS.ShowObject(iconMask, status == 2)

    local bShowNum2 = (status ~= 2) and (status == 1 or _curEntryId == entryId)
    local showNum = LUtil.NumberCoversion(reward.itemNum)

    if self._isEnus then
        showNum = LUtil.FormatColorStr(showNum, "#ffffff")
        self:SetWndTextMat(numText, "NarkisimMJ_475a9f_2")
        self:SetWndTextMat(num2Text, "NarkisimMJ_475a9f_2")
    elseif self._isForeignRegion then
        showNum = LUtil.FormatColorStr(showNum, "#ffffff")
        self:SetWndTextMat(numText, "OPPOSansRMixB_475a9f_2")
        self:SetWndTextMat(num2Text, "OPPOSansRMixB_475a9f_2")
    end

    self:SetWndText(numText, showNum)
    CS.ShowObject(numText, not bShowNum2)
    self:SetWndText(num2Text, showNum)
    CS.ShowObject(num2Text, bShowNum2)

    local uiImage = icon:GetComponent(typeUIImage)
    local uiText = self:FindWndText(numText)
    if uiImage and uiText then
        local isAlpha = status ~= 1 and _curEntryId ~= entryId
        --uiImage.color = Color.New(1, 1, 1, isAlpha and 0.7 or 1)
        --uiText.color = Color.New(1, 1, 1, isAlpha and 0.7 or 1)
    end

    self:SetWndClick(root, function()
        self:OnClickRewardRoot(status, entryCfg, itemdata, reward)
    end)
end
function UIActOnlineAwards:OnClickHelp()
    local _isOpenTwoAct = self._isOpenTwoAct
    if _isOpenTwoAct then
        local _uniqueJump2 = self._uniqueJump2
        local bool = gModelFunctionOpen:CheckIsOpened(_uniqueJump2, true)
        if not bool then
            return
        end
        gModelFunctionOpen:Jump(_uniqueJump2)
        self:WndClose()
        return
    end
    local config = self._actWebConfig
    if not config then
        return
    end
    local content = config.helpTipsContent1
    local title = config.iconDescription
    GF.OpenWnd("UIBzTips", { title = title, text = content })
end
function UIActOnlineAwards:SetItemTime()
    local _timeT = self._timeT
    if not _timeT then
        return
    end
    local trans = _timeT.textTrans
    local count = _timeT.count + 1
    --local time = _timeT.time - count
    local time = _timeT.time
    local nowSinceTime = Time.RawUnityEngineTime.realtimeSinceStartup
    local passTime = nowSinceTime - self._onlineData.time
    if passTime < 0 then
        passTime = 0
    end
    time = time - passTime

    self._timeT.count = count
    if time < 0 then
        if passTime > 2 and not self._timeReq and not self._onlineData.isReqing then

            if nowSinceTime >= self._onlineData.nextTime then
                self._onlineData.isReqing = true
                self._timeReq = true
                self._onlineData.nextTime = Time.RawUnityEngineTime.realtimeSinceStartup + 2
                gModelActivity:OnActivityPageReq(self._sid)
                return
            end
        end
        return
    end

    local min = math.floor(time / 60)
    local sec = math.floor(time) % 60
    local timeStr = string.format("%02d:%02d", min, sec)
    self:SetWndText(trans, timeStr)
end

function UIActOnlineAwards:InitEvent()
    self:SetWndClick(self.mBg, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnHelp, function()
        UIHelper.OnClickHelpBtn(self._sid)
    end)
    --self:SetWndClick(self.mNoticeIcon,function() self:OnClickHelp() end)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
end
function UIActOnlineAwards:SetTime()
    local time = self._timespan or 0
    local _awardTipsA = self._awardTipsA or "#a1#"
    local passTime = Time.RawUnityEngineTime.realtimeSinceStartup - self._onlineData.time
    if passTime < 0 then
        passTime = 0
    end
    time = time - passTime
    if time < 0 then
        self:SetWndText(self.mTimeText, self._awardTipsB or "")
        return
    end
    local min = math.floor(time / 60)
    self:SetWndText(self.mTimeText, string.replace(_awardTipsA, min))
end
function UIActOnlineAwards:InitMessage()
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        local sid = pb.sid
        if self._sid ~= sid then
            return
        end
        self:ResetData(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        local activities = pb.activities
        for i, v in ipairs(activities) do
            local sid = v.sid
            if sid == self._sid then
                self:RefreshData()
                return
            end
        end
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local activity = pb.activity
        if activity.sid ~= self._sid then
            return
        end
        self:RefreshData()
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
end
------------------------------------------------------------------
return UIActOnlineAwards


