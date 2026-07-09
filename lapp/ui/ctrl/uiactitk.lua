---
--- Created by ly.
--- DateTime: 2023/10/15 10:00:33
---
---活动87
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActiTk:LWnd
local UIActiTk = LxWndClass("UIActiTk", LWnd)
local Tweening = DG.Tweening
local Ease = Tweening.Ease
------------------------------------------------------------------

local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActiTk:UIActiTk()
    ---@type UIBtnTabList
    -- self._uiBtnTabList = nil
    self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActiTk:OnWndClose()
    -- if self._uiBtnTabList then
    -- 	self._uiBtnTabList:Destroy()
    -- 	self._uiBtnTabList = nil
    -- end

    if self._delayRefreshTipsTextTimer then
        LxTimer.DelayTimeStop(self._delayRefreshTipsTextTimer)
        self._delayRefreshTipsTextTimer = nil
    end

    self:ClearCommonIconList(self.commonUIList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActiTk:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActiTk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:SetWndText(self.mTxtClose, ccClientText(42010))
    self:InitMessage()
    self:InitEvent()
    self:TweenItem()
    self:InitData()
    self:RefreshForeign()
end

function UIActiTk:ShowEffect(root, effData, key)
    self:DestroyWndEffectByKey(key)
    self:DestroyWndSpineByKey(key)
    if not effData then
        return
    end

    printInfoN("res name " .. effData.resName)

    if effData.resType == 2 then
        self:CreateWndSpine(root, effData.resName, key, nil, nil, nil, true)
    else
        self:CreateWndEffect(root, effData.resName, key, 100)
    end
end

function UIActiTk:SetTabBtn()
    if not self._config then
        return
    end
    local data = {
        {
            icon = self._config.icon,
            name = gModelActivity:GetLngNameById(self._config.name)
        }
    }
    if self.tabBtn then
        self.tabList:RefreshData(data)
    else
        self.tabList = self:GetUIScroll("mTabScroll")
        self.tabList:Create(self.mTabScroll, data, function(...)
            self:OnDrawTabItem(...)
        end)
    end
end

function UIActiTk:RefreshForeign()
    if self._isVie then
        self:InitTextSizeWithLanguage(self.mTipsText2_En,-2)
    end
end

function UIActiTk:OnActivityConfigData(data, sid)

    if sid ~= self._sid then
        return
    end
    self:InitContent()
    gModelActivity:OnActivityPageReq(self._sid)
end

function UIActiTk:IsTabOpenByItemData(itemdata)
    local openData = self._openDataList[itemdata.index]
    local openDay = openData.openDay
    local isOpen
    if self._startTime <= 0 then
        isOpen = true
    else
        local daysPast = self:GetIntervalDays()
        isOpen = daysPast >= openDay
    end
    return isOpen
end

function UIActiTk:CheckPageRPState(index)
    if not self._pages then
        return false
    end

    local page = self._pages[index]
    if not page then
        return false
    end

    local entry = page.entry
    if not entry or #entry < 1 then
        return false
    end

    for i, v in ipairs(entry) do
        if v.goalData and v.goalData.status == 1 then
            return true
        end
    end

    return false
end

function UIActiTk:DrawDayItem(_, item, data)
    local on = self:FindWndTrans(item, "On")
    local off = self:FindWndTrans(item, "Off")
    local gary = self:FindWndTrans(item, "Gray")
    local redPoint = self:FindWndTrans(item, "redPoint")
    self:SetWndTabText(item, data.btnName)
    local isOpen = self:CheckTabIsOpen(data)
    local showRed = self._redRecord and self._redRecord[data.index]
    CS.ShowObject(off, isOpen)
    CS.ShowObject(gary, not isOpen)
    CS.ShowObject(on, self._taskPage == data.index)
    CS.ShowObject(redPoint, showRed)
    self:SetWndClick(item, function()
        if isOpen then
            data.clickFunc(data)
        else
            local openTime = self._startTime + (data.index - 1) * 86400
            local y, m, d = LUtil.GetYmdByTimestamp(openTime)
            GF.ShowMessage(string.replace(ccClientText(29801), m, d))
        end
    end)
end

function UIActiTk:SetUpItem(list, item, itemdata, itempos)
    local bg = self:FindWndTrans(item, "BgImage")
    local titleBg = self:FindWndTrans(item, "TitleBg")
    local title = self:FindWndTrans(item, "TitleBg/Title")
    local btn = self:FindWndTrans(item, "Btn")
    --local btnLight=self:FindWndTrans(btn,"Light")
    --local btnGray=self:FindWndTrans(btn,"Gray")
    local descText = self:FindWndTrans(item, "DescTxt")
    local doneImg = self:FindWndTrans(item, "Show")
    local gridList = self:FindWndTrans(item, "rewardList")
    --local redPoint=self:FindWndTrans(btn,"rp")

    local cellBg = self._config.cellBg or ""
    if not string.isempty(cellBg) then
        self:SetWndEasyImage(bg, cellBg)
    end
    local cellDescBg = self._config.cellDescBg or ""
    if not string.isempty(cellDescBg) then
        self:SetWndEasyImage(titleBg, cellDescBg)
    end

    local status = itemdata.status

    self:SetWndText(title, itemdata.name)
    local color = "black"
    if tonumber(itemdata.goal) <= tonumber(itemdata.schedule) then
        color = "green"
    end
    local str = string.format("%s/%s", itemdata.schedule, itemdata.goal)
    str = LUtil.FormatColorStr(str, color)
    str = string.format("(%s)", str)
    self:SetWndText(descText, str)


    --local instanceID=item:GetInstanceID()
    local dataList = itemdata.rewards

    self:CreateUIScrollImpl(nil, gridList, dataList, function(...)
        self:SetUpGrid(...)
    end, UIItemList.WRAP)

    --local key = gridList:GetInstanceID()
    --local uiList = self:FindUIScroll(key)
    --if uiList then
    --	list:RefreshList(dataList)
    --else
    --	uiList = self:GetUIScroll(key)
    --	uiList:Create(gridList,dataList,function(...) self:SetUpGrid(...) end,UIItemList.WRAP)
    --end



    --local _gridList = self:FindUIScroll(instanceID)
    --if (_gridList) then
    --	_gridList:RefreshList(rewardData)
    --else
    --	_gridList = self:GetUIScroll(instanceID)
    --	_gridList:Create(gridList,rewardData,function(...) self:SetUpGrid(...) end)
    --	_gridList:RefreshList(rewardData)
    --end
    --_gridList:DrawAllItems()
    --_gridList:EnableScroll(false,false)

    --CS.ShowObject(btn,false)
    --CS.ShowObject(btnLight,false)
    --CS.ShowObject(btnGray,false)
    --CS.ShowObject(doneImg,false)
    --CS.ShowObject(redPoint,false)

    local jumpId = itemdata.jumpId

    local isGet = status == 2
    CS.ShowObject(doneImg, isGet)
    CS.ShowObject(btn, not isGet)
    local canGet = status == 1
    self:SetWndButtonGray(btn, canGet)
    local str = status == 0 and itemdata.jumpDesc or ccClientText(18214)
    self:SetWndButtonText(btn, str)
    self:SetWndClick(btn, function()
        if status == 0 then
            gModelFunctionOpen:Jump(jumpId, self:GetWndName())
        elseif status == 1 then
            gModelActivity:OnActivityReceiveGoalReq(self._sid, self.pageId, itemdata.entryId)
        end
    end)

    local insId = btn:GetInstanceID()
    if canGet then
        self:CreateWndEffect(btn, "fx_shouchong_anniu_zhong", insId, 100)
    else
        self:DestroyWndEffectByKey(insId)
    end

    --if status==0 then
    --	CS.ShowObject(btn,true)
    --	CS.ShowObject(btnLight,true)
    --	--self:SetWndButtonText(btn,itemdata.jumpDesc)
    --	self:SetWndText(self:FindWndTrans(btnLight,"Text"),itemdata.jumpDesc)
    --	self:SetWndClick(btn,function()
    --		local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
    --		if isOpen then
    --			gModelFunctionOpen:Jump(jumpId, self:GetWndName(),function()
    --			end)
    --		end
    --	end)
    --elseif status==1 then
    --	CS.ShowObject(btn,true)
    --	CS.ShowObject(btnGray,true)
    --	--self:SetWndButtonText(btn,itemdata.jumpDesc)
    --	self:SetWndText(self:FindWndTrans(btnGray,"Text"),itemdata.jumpDesc)
    --	CS.ShowObject(redPoint,true)
    --	self:SetWndButtonText(btn,ccClientText(28301))
    --	self:SetWndClick(btn,function()
    --		gModelActivity:OnActivityReceiveGoalReq(self._sid,self.pageId,itemdata.entryId)
    --	end)
    --
    --else
    --	CS.ShowObject(doneImg,true)
    --end

    --local func=function()
    --	CS.ShowObject(redPoint,false)
    --	CS.ShowObject(btn,false)
    --	CS.ShowObject(doneImg,true)
    --end
    --
    --self.hideFunc=func;
end

function UIActiTk:InitMessage()

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityPageResp(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp, function(...)
        self:RefreshContent()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function(...)
        self:RefreshContent()
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityResp, function()
        local index = self._taskPage
        self:SetTaskPage(index)
    end)

    self:WndEventRecv(EventNames.ON_INVASION_OPEN, function()
        self:WndClose()
    end)


end

function UIActiTk:TweenItem()
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("floatItem")
    --self.mGrandPrizeBtn.localPosition = Vector3.zero
    local tween = self.mGrandPrizeBtn:DOLocalMoveY(-20, 3):SetRelative():SetEase(Ease.InOutSine)

    seq:Append(tween)
    seq:SetLoops(-1, Tweening.LoopType.Yoyo)
    seq:PlayForward()
end

function UIActiTk:OnDrawTabItem(_, item, data)
    if self._isEnus then
        self:SetWndTabText(item, data.name, -7)
    else
        self:SetWndTabText(item, data.name)
    end
    if self.jpj then
        self:SetAnchorPos(self:FindWndTrans(item, "On/Text"),Vector2.New(0,-19))
        self:SetAnchorPos(self:FindWndTrans(item, "Off/Text"),Vector2.New(0,-19))
    end
    self:SetWndTabStatus(item, 0)
    if data.icon then
        local On = self:FindWndTrans(item, "On")
        local Off = self:FindWndTrans(item, "Off")
        self:SetWndEasyImage(On, data.icon)
        self:SetWndEasyImage(Off, data.icon)
    end
end
function UIActiTk:ShowPageInfo(index)
    local _isShowGrandReward = self._isShowGrandReward or {}
    CS.ShowObject(self.mGrandPrizeBtn, _isShowGrandReward[index])
    local _tipsText = self._tipsText or {}

    if self._isEnus then
        CS.ShowObject(self.mTipsText2_En, _tipsText[index])
        CS.ShowObject(self.mTipsBg_En, true)
        CS.ShowObject(self.mTipsBg, false)
    else
        CS.ShowObject(self.mTipsText2, _tipsText[index])
        CS.ShowObject(self.mTipsBg_En, false)
        CS.ShowObject(self.mTipsBg, true)
    end

    if _tipsText[index] then
        local data = _tipsText[index]
        self:SetWndText(self.mTipsText2, data.str)
        if self._isEnus then
            self:SetWndText(self.mTipsText2_En, data.str)

            self._delayRefreshTipsTextTimer = LxTimer.DelayFrameCall(function()

                UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTipsText2_En)
                UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTipsBg_En)
            end, 1)

        end

        self:SetAnchorPosStr(self.mTipsBg, data.pos, ",")

        self:SetAnchorPosStr(self.mTipsBg_En, data.pos, ",")
    end

    if self.jpj then
        self:SetAnchorPos(self.mTipsBg,Vector2.New(-123,-155))
        self.mTipsBg.sizeDelta =Vector2.New(400,26)
        self:InitTextSizeWithLanguage(self.mTipsText2,-4)
    end
end
function UIActiTk:CheckTabIsOpen(itemdata)
    local openData = self._openDataList[itemdata.index]
    local openDay = openData.openDay
    local isOpen = self:IsTabOpenByItemData(itemdata)
    local str = itemdata.name
    local tipStr = ""
    if not isOpen then
        local openTime = self._startTime + (openDay - 1) * 86400
        local y, m, d = LUtil.GetYmdByTimestamp(openTime)
        str = string.replace(ccClientText(21742), m, d)
        tipStr = string.replace(ccClientText(29801), m, d)
    end
    return isOpen, str, tipStr
end

--function UIActiTk:SetTabBtnShow()
--
--	local isShow= self._taskPage==1
--
--	local btnTab1On=self:FindWndTrans(self.mBtnTab1,"On")
--	local btnTab1Off=self:FindWndTrans(self.mBtnTab1,"Off")
--	local btnTab2On=self:FindWndTrans(self.mBtnTab2,"On")
--	local btnTab2Off=self:FindWndTrans(self.mBtnTab2,"Off")
--	CS.ShowObject(btnTab1On,isShow)
--	CS.ShowObject(btnTab1Off,not isShow)
--	CS.ShowObject(btnTab2On,not isShow)
--	CS.ShowObject(btnTab2Off,isShow)
--end



function UIActiTk:RefreshUI()
    local page = self._pages[self._taskPage]
    if not page then
        return
    end
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end
    local config = webData.config
    local isShowGrandReward
    if (config.isShowGrandReward and not string.isempty(config.isShowGrandReward)) then
        local sgRewardArr = string.split(config.isShowGrandReward, "|")
        local curisShowGrandReward = sgRewardArr[self._taskPage]
        if (curisShowGrandReward and not string.isempty(curisShowGrandReward)) then
            local tmp = string.split(curisShowGrandReward, "=")
            isShowGrandReward = tmp[2] == "1"
        end
    end
    local showBigReward = false
    if config["7daysReward"] == 1 then
        self:ShowBigReward()
        CS.ShowObject(self.mBigRewardObj, true)
        isShowGrandReward = false
        showBigReward = true
    end
    self._redRecord = {}
    for k, v in pairs(self._pages) do
        local pageId = v.pageId
        local has = false
        if self:CheckPageOpen(pageId) then
            for k1, v2 in pairs(v.entry) do
                if showBigReward then
                    if v2.goalData.status == 1 and k1 ~= #v.entry then
                        has = true
                        break
                    end
                else
                    if v2.goalData.status == 1 then
                        has = true
                        break
                    end
                end
            end
        end

        self._redRecord[pageId] = has
    end
    if self.dayList then
        self.dayList:DrawAllItems(false)
    end
    local thePrize = {}
    local list = {}
    local cnt = #page.entry
    for i, v in ipairs(page.entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, v.pageId, v.entryId)
        self.pageId = v.pageId
        if not entryCfg then
            return
        end
        local rewards = LxDataHelper.ParseItem(entryCfg.reward)

        local sort = 0
        local status = v.goalData.status

        if status == 1 then
            sort = 5
        end    --特定排序处理
        if status == 0 then
            sort = 6
        end
        if status == 2 then
            sort = 7
        end

        local data = {
            entryId = v.entryId,
            status = status,
            rewards = rewards,
            name = entryCfg.name,
            jumpId = entryCfg.jumpId,
            jumpDesc = entryCfg.jumpDesc,
            jumpDesc = entryCfg.jumpDesc,
            schedule = v.goalData.schedules[1].schedule,
            goal = v.goalData.schedules[1].goal,
            entryCfg = entryCfg,
            --sort=sort,
            sort = entryCfg.sort,
            icon = entryCfg.icon,
        }

        if showBigReward then
            if i ~= cnt then
                table.insert(list, data)
            end
        else
            if isShowGrandReward == false or i ~= cnt then
                table.insert(list, data)
            else
                thePrize = data            --悬赏大奖数据
            end
        end
    end

    --[[	table.sort(list,function(a,b)         --特定排序处理
            if a.sort<b.sort then
                return true
            elseif a.sort==b.sort then
                if a.entryId>b.entryId then
                    return true
                end
            end
        end)]]

    local statusList = {
        [0] = 1,
        [1] = 2,
        [2] = 0,
    }
    table.sort(list, function(a, b)
        local statusA, statusB = a.status, b.status
        if statusA ~= statusB then
            return statusList[statusA] > statusList[statusB]
        end
        return a.sort < b.sort
    end)

    self:InitItemList(list)

    if (isShowGrandReward == false) then
        return
    end
    --local pbText=self:FindWndTrans(self.mGrandPrizeBtn,"Text")
    local pbMask = self:FindWndTrans(self.mPrizeShow, "Mask")
    local lockImg = self:FindWndTrans(pbMask, "LockImg")
    local doneImg = self:FindWndTrans(pbMask, "DoneImg")

    --local root=self:FindWndTrans(self.mGrandPrizeBtn,"Root/Icon")
    self:SetWndText(self.mPrizeText, thePrize.name)

    local pbStatus = thePrize.status
    local isMask = pbStatus == 2 or pbStatus == 0
    CS.ShowObject(pbMask, isMask)
    CS.ShowObject(lockImg, pbStatus == 0)

    local showDone = pbStatus == 2
    if showDone and self._checkPos then
        self:SetAnchorPos(doneImg, LxDataHelper.ParseVector2NotEmpty(self._checkPos))
    end
    CS.ShowObject(doneImg, showDone)

    CS.ShowObject(self.mPrizeOn, pbStatus ~= 0)
    CS.ShowObject(self.mPrizeOff, pbStatus == 0)

    local effData = nil
    if pbStatus == 0 then
        effData = self._unavailableEffect
    elseif pbStatus == 1 then
        effData = self._availableEffect
    end
    if self._curEffData == nil or effData ~= self._curEffData then
        self._curEffData = effData
        self:ShowEffect(self.mEffRoot, effData, "prizeEff")
    end

    local pbReward = thePrize.rewards[1]

    local rp = self:FindWndTrans(self.mGrandPrizeBtn, "redPoint")
    --self:PlayEff(self.mGrandPrizeBtn,"fx_ui_lianmenghuzhu","fx_ui_lianmenghuzhu")
    local showRed = pbStatus == 1
    if showRed and self._redpointPos then
        self:SetAnchorPos(rp, LxDataHelper.ParseVector2NotEmpty(self._redpointPos))
    end
    CS.ShowObject(rp, showRed)
    local showIcon = thePrize.icon
    if string.isempty(showIcon) then
        showIcon = gModelGeneral:GetCommonItemImgRef(pbReward)
    end
    local itemNum = pbReward.itemNum or 1
    local showItemNum = itemNum > 1
    if showItemNum then
        self:SetWndText(self.mItemShowNum, LUtil.NumberCoversion(itemNum))
    end
    CS.ShowObject(self.mItemShowNum, showItemNum)
    self:SetWndEasyImage(self.mItemIcon, showIcon, function()
        CS.ShowObject(self.mItemIcon, true)
    end)
    --self:CreateCommonIconImpl(root,pbReward)
    if pbStatus == 0 then
        self:SetWndClick(self.mGrandPrizeBtn, function()
            gModelGeneral:ShowCommonItemTipWnd(pbReward)
            GF.ShowMessage(ccClientText(30001))
        end)
    end
    if pbStatus == 1 then
        self:SetWndClick(self.mGrandPrizeBtn, function()
            gModelActivity:OnActivityReceiveGoalReq(self._sid, self.pageId, thePrize.entryId)
            gModelActivity:OnActivityPageReq(self._sid)
        end)
    end
    if pbStatus == 2 then
        self:SetWndClick(self.mGrandPrizeBtn, function()
            gModelGeneral:ShowCommonItemTipWnd(pbReward)
        end)
        --self:SetWndClick(self.pbMask,function() gModelGeneral:ShowCommonItemTipWnd(pbReward) end)
    end
end

function UIActiTk:OnDrawTab(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootBg = self:FindWndTrans(AniRoot, "Bg")
    local AniRootBtnTab = self:FindWndTrans(AniRoot, "btnTab")
    local btnTabOff = self:FindWndTrans(AniRootBtnTab, "Off")
    --local OffText = self:FindWndTrans(btnTabOff,"Text")
    local btnTabOn = self:FindWndTrans(AniRootBtnTab, "On")
    --local OnText = self:FindWndTrans(btnTabOn,"Text")
    local btnTabRedPoint = self:FindWndTrans(AniRootBtnTab, "redPoint")
    local AniRootLock = self:FindWndTrans(AniRoot, "lock")

    local isOn = self._taskPage == itemdata.index
    CS.ShowObject(AniRootBg, isOn)

    local openData = self._openDataList[itemdata.index]
    local openDay = openData.openDay
    local isOpen
    local str = itemdata.name
    if self._startTime <= 0 then
        isOpen = true
    else
        local daysPast = self:GetIntervalDays()
        isOpen = daysPast >= openDay
    end

    local tipStr = ""
    if not isOpen then
        local openTime = self._startTime + (openDay - 1) * 86400
        local y, m, d = LUtil.GetYmdByTimestamp(openTime)
        str = string.replace(ccClientText(21742), m, d)
        tipStr = string.replace(ccClientText(29801), m, d)
    end

    self:SetWndTabText(AniRootBtnTab, str)
    local state = isOn and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(AniRootBtnTab, state)
    CS.ShowObject(AniRootLock, not isOpen)

    local alpha = 1
    if not isOpen then
        alpha = 0.6
    end
    self:SetImageAlpha(btnTabOff, alpha)

    self:SetWndEasyImage(btnTabOff, itemdata.offIcon, nil, true)
    self:SetWndEasyImage(btnTabOn, itemdata.onIcon, nil, true)
    local showRed = self._redRecord and self._redRecord[itemdata.index]
    CS.ShowObject(btnTabRedPoint, showRed)

    self:SetWndClick(AniRoot, function()
        if isOpen then
            self:SetTaskPage(itemdata.index)
        else
            GF.ShowMessage(tipStr)
        end
    end)
end

function UIActiTk:CheckPageOpen(index)
    if not self._startTime then
        return
    end
    local isOpen
    if self._startTime <= 0 then
        isOpen = true
    else
        local openData = self._openDataList[index]
        local openDay = openData.openDay
        local daysPast = self:GetIntervalDays()
        isOpen = daysPast >= openDay
    end
    return isOpen
end

function UIActiTk:RefreshContent()
    if not self._headLineList then
        return
    end
    local page = self._taskPage or 1
    local path = self._headLineList[page]
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mBgImg, path, function()
            CS.ShowObject(self.mBgImg, true)
        end, true, true)
    end

    local tabData = self._tabDataList[page]
    --self:SetWndText(self.mPrizeText,tabData.name)

    local icon = tabData and tabData.icon or ""
    if LxUiHelper.IsImgPathValid(icon) then
        self:SetWndEasyImage(self.mGrandPrizeBtn, icon, function()
            CS.ShowObject(self.mGrandPrizeBtn, true)
        end, true)
    end
end

function UIActiTk:SetTaskPage(index)
    self._taskPage = index
    self:RefreshContent()
    self:RefreshUI()

    local list = self:FindUIScroll("mDayList")
    if list then
        list:DrawAllItems(false)
    end

    self:ShowPageInfo(index)
end

function UIActiTk:SetUpGrid(list, item, itemdata, itempos)
    local aniRoot = self:FindWndTrans(item, "Root")
    local root = self:FindWndTrans(aniRoot, "Icon")
    self:CreateCommonIconImpl(root, itemdata)
end

function UIActiTk:ShowBigReward()
    local list = {}
    for i, v in ipairs(self._pages) do
        local data = v.entry[#v.entry]
        local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, data.pageId, data.entryId)
        list[i] = {
            rewards = LxDataHelper.ParseItem(entryCfg.reward),
            status = data.goalData.status,
            pageId = i,
            entryId = data.entryId,
            index = i
        }
    end
    for i = 1, 7 do
        local item = self:FindWndTrans(self.mBigRewardObj, "Reward" .. i)
        self:SetBigRewardItem(item, list[i])
    end
end

function UIActiTk:OnActivityPageResp(pb, ret)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end
    local pages = {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        pages[page.pageId] = page
    end
    self._pages = pages

    self:RefreshContent()
    self:RefreshUI()

    local moveTo
    for i, v in ipairs(self._taskPageList or {}) do
        if v.checkRPFunc and v.checkRPFunc(v) then
            moveTo = v.index
            break
        end
    end
    if moveTo and (self._taskPage ~= moveTo) then
        self._taskPage = moveTo
        -- self._uiBtnTabList:MoveToPos(moveTo)
        -- self._uiBtnTabList:SetCurSel(moveTo)
    end

    --local list = self:FindUIScroll('tabList')
    --if list then
    --	list:DrawAllItems(false)
    --end
    -- if self._uiBtnTabList then
    -- 	self._uiBtnTabList:RefreshTabScroll()
    -- end
end

function UIActiTk:SetDayList(list)
    if #list <= 1 then
        CS.ShowObject(self.mDayList, false)
        self.mTaskScroll.sizeDelta = Vector2.New(588, 640)
        return
    end
    CS.ShowObject(self.mDayList, true)
    if not self.dayList then
        self.dayList = self:GetUIScroll("mDayList")
        self.dayList:Create(self.mDayList, list, function(...)
            self:DrawDayItem(...)
        end, UIItemList.SUPER_GRID)
    else
        self.dayList:RefreshList(list)
        self.dayList:DrawAllItems()
    end
end

--function UIActiTk:PlayEff(trans,eff,key)
--	if self:FindWndEffectByKey(key) then
--		return
--	end
--	self:CreateWndEffect(trans,eff,key,100)
--end

function UIActiTk:InitItemList(list)

    local _uiTaskList = self._uiTaskList
    if (_uiTaskList) then
        _uiTaskList:RefreshList(list)
        _uiTaskList:DrawAllItems()
    else
        _uiTaskList = self:GetUIScroll("entryList")
        self._uiTaskList = _uiTaskList
        _uiTaskList:Create(self.mTaskScroll, list, function(...)
            self:SetUpItem(...)
        end, UIItemList.SUPER)
        _uiTaskList:DrawAllItems()
    end

end

function UIActiTk:InitContent()
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end
    local activityMoreInfo = JSON.decode(activityData.moreInfo)
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end
    local config = webData.config
    self._config = config
    self._actData = activityData
    self._startTime = activityData.startTime
    self._endTime = activityData.endTime                               --活动结束时间
    self:SetWndText(self.mTipsText, ccClientText(30001))

    self._timeTextColor = "#ffffff"
    if not string.isempty(config.timeTxtColor) then
        self._timeTextColor = "#" .. config.timeTxtColor
    end

    self:SetAnchorPosStr(self.mDeadlineImg, config.timePos, '|')

    if LxUiHelper.IsImgPathValid(config.mask) then
        self:SetWndEasyImage(self.mMask, config.mask, nil, true)
    end

    if LxUiHelper.IsImgPathValid(config.lockImage) then
        self:SetWndEasyImage(self.mLockImg, config.lockImage, nil, true)
    end

    if LxUiHelper.IsImgPathValid(config.availableGrand) then
        self:SetWndEasyImage(self.mPrizeOn, config.availableGrand, nil, true)
    end

    if LxUiHelper.IsImgPathValid(config.unavailableGrand) then
        self:SetWndEasyImage(self.mPrizeOff, config.unavailableGrand, nil, true)
    end

    if LxUiHelper.IsImgPathValid(config.timeBg) then
        self:SetWndEasyImage(self.mDeadlineImg, config.timeBg)
    end

    if LxUiHelper.IsImgPathValid(config.pageBg) then
        self:SetWndEasyImage(self.mDayListBg, config.pageBg)
    end

    if LxUiHelper.IsImgPathValid(config.tipsTextBg) then
        self:SetWndEasyImage(self.mTipsBg, config.tipsTextBg)
        self:SetWndEasyImage(self.mTipsBg_En, config.tipsTextBg)
    end

    self:SetTabBtn()

    local signHelpTips = config.signHelpTips
    local isShowHelpBtn = not string.isempty(signHelpTips)
    CS.ShowObject(self.mHelpBtn, isShowHelpBtn)

    self._redpointPos = config.redpointPos

    self._checkPos = config.checkPos

    local showInfo = {
        showStr = config.ImageHero,
        showPos = config.ImageHeroPos,
        parentRoot = self.mShowPos,
        imgRoot = self.mImgPos,
        spineRoot = self.mLHPos,
    }
    self:SetActivityShowInfo(showInfo)

    self:SetAnchorPosStr(self.mTipsText, config.TipsTextPos, "|")
    self:SetAnchorPosStr(self.mPrizeShow, config.grandPos, "|")
    self:SetAnchorPosStr(self.mMask, config.lockImagePos, "|")
    self:SetAnchorPosStr(self.mBgImg, config.headlinePos, "|")

    local scale = Vector3.one
    if config.grandSize then
        scale = Vector3.one * config.grandSize
    end
    self.mPrizeShow.localScale = scale

    self._unavailableEffect = LxDataHelper.ParseResConfig(config.unavailableEffect)
    self._availableEffect = LxDataHelper.ParseResConfig(config.availableEffect)

    local timePara = {
        key = "timer",
        interval = 1,
        func = function()
            self:SetCountDown()
        end,
        loopcnt = -1,
        callOnStart = true
    }

    self:TimerStartImpl(timePara)

    local headline = activityMoreInfo.headline
    self._headLineList = string.split(headline, '|')

    local taskPageInfos = string.split(config.taskPage, '|')
    local dataList = {}
    for k, v in ipairs(taskPageInfos) do
        local temps = string.split(v, "=")
        local data = {
            index = tonumber(temps[1]),
            btnType = tonumber(temps[1]),
            name = temps[2],
            btnName = temps[2],
            onIcon = temps[3],
            offIcon = temps[4],
            clickFunc = function(itemdata)
                self:SetTaskPage(itemdata.index)
            end,
            checkRPFunc = function(itemdata)
                if not self:IsTabOpenByItemData(itemdata) then
                    return false
                end
                if self:CheckPageRPState(itemdata.index) then
                    return true
                end
                return gModelRedPoint:GetActivityRedPointPage(self._sid, itemdata.index)
            end
        }
        data.offIcon = data.offIcon or data.onIcon
        dataList[data.index] = data
    end

    local taskPageList = {}
    for i, v in ipairs(dataList) do
        table.insert(taskPageList, v)
    end
    self._taskPageList = taskPageList

    table.sort(dataList, function(a, b)
        return a.index < b.index
    end)

    self._tabDataList = dataList

    local taskOpenStr = string.split(config.taskOpen, '|')
    self._openDataList = {}
    for k, v in ipairs(taskOpenStr) do
        local temps = string.split(v, '=')
        local data = {
            index = tonumber(temps[1]),
            btnType = tonumber(temps[1]),
            openDay = tonumber(temps[2])
        }
        self._openDataList[data.index] = data
    end

    local moveTo
    for i, v in ipairs(dataList) do
        if v.checkRPFunc and v.checkRPFunc(v) then
            moveTo = v.index
            self._taskPage = moveTo
            break
        end
    end

    self:SetWndEasyImage(self.mBgImage, config.signImageHero, function()
        CS.ShowObject(self.mBgImage, true)
    end)


    -- ---@type UIBtnTabList
    -- self._uiBtnTabList = UIBtnTabList:New()
    -- self._uiBtnTabList:SetCheckLockFunc(function(itemData, itemPos)
    -- 	return self:CheckTabIsOpen(itemData, itemPos)
    -- end)
    -- self._uiBtnTabList:SetData(self,self.mTabList,dataList,self._taskPage)

    -- if moveTo then
    -- 	self._uiBtnTabList:MoveToPos(moveTo)
    -- end
    self:SetDayList(dataList)

    --self:CreateUIScrollImpl("tabList",self.mTabList,dataList,function (...)
    --	self:OnDrawTab(...)
    --end)

    local isShowGrandReward = config.isShowGrandReward
    if not string.isempty(isShowGrandReward) then
        local arr = string.split(isShowGrandReward, "|")
        local list = {}
        for i, v in ipairs(arr) do
            local ar = string.split(v, "=")
            list[tonumber(ar[1])] = ar[2] == "1"
        end
        self._isShowGrandReward = list
    end
    local tipsText = config.tipsText
    if not string.isempty(tipsText) then
        local arr = string.split(tipsText, "|")
        local list = {}
        for i, v in ipairs(arr) do
            local ar = string.split(v, "=")
            list[tonumber(ar[1])] = {
                str = ar[2],
                pos = ar[3]
            }
        end
        self._tipsText = list
    end
    self:ShowPageInfo(self._taskPage)
end

function UIActiTk:SetCountDown()
    local endTime = self._endTime
    local time = GetTimestamp()
    local timespan = endTime - time
    timespan = math.max(0, timespan)
    local timeStr = LUtil.FormatTimespanCn(timespan)
    --local timeLeftStr=string.replace(ccClientText(29205),timeStr)
    local timeLeftStr = string.replace(ccClientText(11637), timeStr)
    timeLeftStr = LUtil.FormatColorStr(timeLeftStr, self._timeTextColor)
    self:SetWndText(self.mDeadlineText, timeLeftStr)
end
function UIActiTk:InitEvent()

    self:SetWndClick(self.mCloseBtn, function()
        --GF.OpenWnd("UIMotifActEntrance")
        self:WndClose()
    end)

    self:SetWndClick(self.mHelpBtn, function()
        local title = gModelActivity:GetLngNameByActivitySid(self._sid)
        local helpTip = self._config.signHelpTips
        local str = string.gsub(helpTip, '\\n', '\n')
        GF.OpenWnd("UIBzTips", { title = title, text = str })
    end)

end

function UIActiTk:InitData()

    self._sid = self:GetWndArg("sid")
    local subPage = self:GetWndArg("subPage")
    if subPage then
        self._sid = gModelActivity:GetSidByUniqueJump(subPage)
    end
    self._taskPage = 1
    gModelActivity:ReqActivityConfigData(self._sid)

end

--获取活动开启距离现在间隔天数
function UIActiTk:GetIntervalDays()
    local actData = gModelActivity:GetActivityBySid(self._sid)
    local dayPast = LUtil.GetDayPast(actData.startTime)
    return dayPast
end

function UIActiTk:SetBigRewardItem(item, data)
    if not data then
        return
    end
    local iconRoot = self:FindWndTrans(item, "IconRoot")
    local lock = self:FindWndTrans(item, "Lock")
    local get = self:FindWndTrans(item, "Get")
    local text = self:FindWndTrans(item, "Text")
    local redPoint = self:FindWndTrans(item, "redPoint")

    local isOpen = self:IsTabOpenByItemData(data)
    CS.ShowObject(lock, not isOpen)
    CS.ShowObject(redPoint, data.status == 1 and isOpen)
    CS.ShowObject(get, data.status == 2 and isOpen)

    local textName = self._taskPageList[data.pageId]

    if textName then
        self:SetWndText(text, textName.btnName)
    else
        self:SetWndText(text, string.replace(ccClientText(15706), data.pageId))
    end

    if data.status == 1 and isOpen then
        self:CreateWndEffect(iconRoot, "fx_ui_qiandao_lingqutishi", item.gameObject.name, 100, false, false)
    else
        self:DestroyWndEffectByKey(item.gameObject.name)
    end
    local instanceId = item:GetInstanceID()
    local reward = data.rewards[1]
    if not self.commonUIList[instanceId] then
        self.commonUIList[instanceId] = CommonIcon:New()
        self.commonUIList[instanceId]:Create(iconRoot)
    end
    self.commonUIList[instanceId]:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
    self.commonUIList[instanceId]:DoApply()

    self:SetWndClick(item, function()
        if data.status == 0 then
            GF.ShowMessage(ccClientText(30001))
        elseif data.status == 1 and isOpen then
            gModelActivity:OnActivityReceiveGoalReq(self._sid, data.pageId, data.entryId)
            gModelActivity:OnActivityPageReq(self._sid)
            return
        end
        gModelGeneral:ShowCommonItemTipWnd(reward)
    end)
end

------------------------------------------------------------------
return UIActiTk



