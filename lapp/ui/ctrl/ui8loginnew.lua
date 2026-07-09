---
--- Created by Administrator.
--- DateTime: 2023/10/12 10:51:33
---
---活动75 八天登录
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UI8LoginNew:LWnd
local UI8LoginNew = LxWndClass("UI8LoginNew", LWnd)
local typeSpineClick = typeof(CS.SpineClick)
local Tweening = DG.Tweening
local Ease = Tweening.Ease
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
UI8LoginNew.PAGE_SIGN = 1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UI8LoginNew:UI8LoginNew()
    self._nextGetTimer = nil
    self._viewImageScrollTimeKey = "_viewImageScrollTimeKey"
    self._viewImageScrollTweenKey = "_viewImageScrollTweenKey"
    self._viewSpineScrollTweenKey = "_viewSpineScrollTweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UI8LoginNew:OnWndClose()
    LUtil.ClearHashTable(self._uiHeroObjList)
    self._uiHeroObjList = nil

    if self._func then
        self._func()
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UI8LoginNew:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UI8LoginNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._curSelRound = 0
    self._tabList = {}
    self._isEnus = gLGameLanguage:IsForeignVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitUIEvent()
    self:InitEvent()
    self:InitPara()

    self:SetStaticContent()
end

function UI8LoginNew:SetSpineHero(heroRefId)
    local effRef = gModelHero:GetHeroEffectRef(heroRefId)

    if effRef then
        local prefabName = effRef.prefabName
        self:CreateWndSpine(self.mHeroSpinePos, prefabName, "heroSpinePos", false)
        CS.ShowObject(self.mHeroSpinePos, true)

        self:SetWndClick(self.mHeroSpinePos, function()
            local itemData = {
                itemId = heroRefId, itemType = LItemTypeConst.TYPE_HERO, itemNum = 0
            }
            gModelGeneral:ShowCommonItemTipWnd(itemData)
        end)
    else
        CS.ShowObject(self.mHeroSpinePos, false)
    end
end

function UI8LoginNew:OnClickGet()
    local entryCfg = self._dataList[self._curDay]
    if not entryCfg then
        return
    end

    local entryData = self:GetEntryData(entryCfg.entry.id)
    if not entryData then
        return
    end

    local status = entryData.goalData.status
    if status == 0 then
        local str = ccClientText(16209)
        str = string.replace(str, entryCfg.entry.sort)
        GF.ShowMessage(str)
    elseif status == 1 then
        local dataList = self:GetCanGetReward()
        if dataList then
            gModelActivity:OnActivityReceiveGoalListReq(dataList)
        end
    elseif status == 2 then
        local str = ccClientText(16214)
        GF.ShowMessage(str)
    end
end

function UI8LoginNew:InitPara()
    self._func = self:GetWndArg("func")
    self._sid = self:GetWndArg("sid")

    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        self._sid = gModelActivity:GetSidByUniqueJump(subpage)
    end

    gModelActivity:ReqActivityConfigData(self._sid)

    local wndName = self:GetWndName()
    local wndPara = {
        wndName = wndName,
        para1 = 1,
        para2 = 1,
    }

    FireEvent(EventNames.ON_WND_OPEN_TRIGGER, wndPara) --指引触发条件


end

function UI8LoginNew:DoChangeTab(index)
    if self._curSelRound == index then return end
    local oldIndex = self._curSelRound
    self._curSelRound = index
	self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[index],0,index)
    self:RefreshRewardList()
end

function UI8LoginNew:OnDrawTab(list, item, itemData, index)
    local name = string.replace(ccClientText(16219),itemData)
	self:SetWndTabText(item,name,nil,true)
	self:SetWndTabStatus(item, 1)
	self._tabList[index] = item
	self:SetWndClick(item, function (...)
        if self._curSelRound == itemData then return end
        local curDay = self:CanGetDay(itemData)
        self:OnSelectItem(curDay)
        self:DoChangeTab(itemData) end)
end

function UI8LoginNew:OnDrawCell(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootDarkBg = self:FindWndTrans(AniRoot, "darkBg")
    local AniRootLightBg = self:FindWndTrans(AniRoot, "lightBg")
    local AniRootItemIcon = self:FindWndTrans(AniRoot, "itemIcon")
    local AniRootItemNum = self:FindWndTrans(AniRoot, "itemNum")
    local AniRootItemName = self:FindWndTrans(AniRoot, "itemName")
    local AniRootItemName_1 = self:FindWndTrans(AniRoot, "itemName_1")
    local AniRootDay = self:FindWndTrans(AniRoot, "day")
    local AniRootDay_1 = self:FindWndTrans(AniRoot, "day_1")
    local AniRootTag = self:FindWndTrans(AniRoot, "tag")
    local AniRootTagMask = self:FindWndTrans(AniRoot, "tagMask")

    local AniRootActive = self:FindWndTrans(AniRoot, "active")

    local entryCfg = itemdata.entry
    --printInfoN("------------entry icon "..entryCfg.icon)
    local strs = string.split(entryCfg.icon, '=')
    local iconPath = strs[1]
    local scale = strs[2] and tonumber(strs[2])
    scale = scale or 1

    if self._isEnus then
        self:SetAnchorPos(AniRootDay,Vector2.New(-3.4,12))
        self:SetAnchorPos(AniRootDay_1,Vector2.New(-3.4,12))
    end

    if self.jpj then
        self:SetAnchorPos(AniRootDay,Vector2.New(-3.4,19))
        self:SetAnchorPos(AniRootDay_1,Vector2.New(-3.4,19))
    end

    self:SetWndEasyImage(AniRootItemIcon, iconPath)
    AniRootItemIcon.localScale = Vector3.New(scale, scale, scale)

    local reward = itemdata.rewards[1]
    local itemNumStr = ""
    if reward and reward.itemType == 1 and reward.itemNum > 1 then
        itemNumStr = tostring(reward.itemNum)
    end
    self:SetWndText(AniRootItemNum, itemNumStr)

    local showDark = false

    local isSelect = entryCfg.id == self._curDay
    local entryData = self:GetEntryData(entryCfg.id)
    local status = 0
    if entryData then

        status = entryData.goalData.status
        CS.ShowObject(AniRootTag, status == 2) --已领取
        CS.ShowObject(AniRootTagMask, status == 2)
        CS.ShowObject(AniRootDarkBg, status == 0) --不可领取
        CS.ShowObject(AniRootLightBg, status ~= 0)

        self:SetWndClick(AniRoot, function()
            local isSelect2 = entryCfg.id == self._curDay
            if isSelect2 then
                gModelGeneral:ShowCommonItemTipWnd(reward)
                return
            end
            self:OnSelectItem(itemdata.entry.id)

        end)

        showDark = status ~= 0

    end

    if not self._listItem then
        self._listItem = {}
    end
    self._listItem[itemdata.entry.id] = item

    local showEffect = reward and reward.isShowEff and status ~= 2
    local instanceId = AniRoot:GetInstanceID()
    if showEffect then
        self:CreateWndEffect(AniRoot, "ui_fx_batianhuodong_03", instanceId, 100, false, false, 20)
    else
        self:DestroyWndEffectByKey(instanceId)
    end

    self:SetWndText(AniRootDay, entryCfg.name)
    --self:SetWndText(AniRootItemName,entryCfg.description)
    --self:InitTextLineWithLanguage(AniRootItemName, -30)
    --self:InitTextSizeWithLanguage(AniRootItemName, -4)

    self:SetWndText(AniRootDay_1, entryCfg.name)
    --self:SetWndText(AniRootItemName_1,entryCfg.description)
    --self:InitTextLineWithLanguage(AniRootItemName_1, -30)
    --self:InitTextSizeWithLanguage(AniRootItemName_1, -4)

    CS.ShowObject(AniRootDay, showDark)
    CS.ShowObject(AniRootItemName, showDark)

    CS.ShowObject(AniRootDay_1, not showDark)
    CS.ShowObject(AniRootItemName_1, not showDark)

    --local alpha = showDark and 1 or 0.8
    --self:SetImageAlpha(AniRootItemIcon,alpha)
    CS.ShowObject(AniRootActive, isSelect)
end

function UI8LoginNew:GetEntryData(entryId)
    if not self._pageData then
        return
    end

    return self._pageData:GetEntry(entryId)
end

function UI8LoginNew:OnDrawHeroNameItem(item, itemdata)
    local isShow = not table.isempty(itemdata)
    CS.ShowObject(item, isShow)
    if not isShow then
        return
    end

    local nameText = self:FindWndTrans(item, "NameText")
    local raceIcon = self:FindWndTrans(item, "RaceIcon")

    local heroId = itemdata.heroId
    local ref = gModelHero:GetHeroRef(heroId)
    if not ref then
        return
    end

    local effRef = gModelHero:GetHeroEffectRef(heroId)
    local name = ccLngText(effRef.name)
    self:SetWndText(nameText, name)

    local raceType = ref.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
    local icon = raceRef.icon
    if LxUiHelper.IsImgPathValid(icon) then
        self:SetWndEasyImage(raceIcon, icon)
    end

    local pos = itemdata.namePos
    self:SetAnchorPos(item, pos)
end

function UI8LoginNew:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end
    self:SetContent()
    gModelActivity:OnActivityPageReq(self._sid)
end

function UI8LoginNew:OnTryTcpReconnect()
    gModelActivity:ReqActivityConfigData(self._sid)
end

function UI8LoginNew:CreateHeroSpine(obj, prefabName, heroPosIndex, spineSize)
    if not prefabName then
        return
    end
    local uiHeroObjList = self._uiHeroObjList
    if not uiHeroObjList then
        uiHeroObjList = {}
        self._uiHeroObjList = uiHeroObjList
    end

    local uiHeroSpineIndexList = self._uiHeroSpineIndexList
    if not uiHeroSpineIndexList then
        uiHeroSpineIndexList = {}
        self._uiHeroSpineIndexList = uiHeroSpineIndexList
    end

    local newUIHeroObj = uiHeroObjList[prefabName]
    local oldPrefabName = uiHeroSpineIndexList[heroPosIndex]

    local oldUIHeroObj = oldPrefabName and uiHeroObjList[oldPrefabName]
    if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
        oldUIHeroObj:ShowHero(false)
    end

    if not newUIHeroObj then
        newUIHeroObj = LUIHeroObject:New(self)
        uiHeroObjList[prefabName] = newUIHeroObj
        newUIHeroObj:Create(obj, prefabName, prefabName)
        newUIHeroObj:SetScale(spineSize or 0.8)
        newUIHeroObj:ShowHero(true)
        newUIHeroObj:StartLoad()
    else
        newUIHeroObj:ShowHero(true)
    end

    uiHeroSpineIndexList[heroPosIndex] = prefabName
end

function UI8LoginNew:RefreshHeroSpineList(viewImgName)
    if not viewImgName then
        return
    end

    local dataList = self._heroNamePosDataList[viewImgName] or {}
    for i = 1, self.mHeroSpineList.childCount do
        local data = dataList[i]
        self:OnDrawHeroSpineItem(self["mHeroSpine" .. i], data, i)
    end
end

function UI8LoginNew:TweenItem()
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("floatItem")
    self.mTweenRoot.localPosition = Vector3.zero
    local tween = self.mTweenRoot:DOLocalMoveY(-20, 3):SetRelative():SetEase(Ease.InOutSine)

    seq:Append(tween)
    seq:SetLoops(-1, Tweening.LoopType.Yoyo)
    seq:PlayForward()
end

function UI8LoginNew:SetHeroNamePosList(key, heroNamePosStr)
    if string.isempty(heroNamePosStr) then
        return
    end

    local heroNamePosData = string.split(heroNamePosStr, '|')
    for i = 1, #heroNamePosData do
        local posData = string.split(heroNamePosData[i], '=')
        local data = {
            heroId = tonumber(posData[1]),
            spinePos = LxDataHelper.ParseVector2NotEmpty(posData[2]),
            spineSize = tonumber(posData[3]),
            namePos = LxDataHelper.ParseVector2NotEmpty(posData[4]),
        }
        if not self._heroNamePosDataList[key] then
            self._heroNamePosDataList[key] = {}
        end
        table.insert(self._heroNamePosDataList[key], data)
    end
end

function UI8LoginNew:ShowHeroPre(heroRefId, isSkin)
    if isSkin then
        gModelGeneral:OpenHeroSkin({ skinRefId = heroRefId, preview = true })
    else
        gModelGeneral:OpenHeroStarPre({ refId = heroRefId })
    end
end

function UI8LoginNew:GetCanGetReward()
    local pageData = self._pageData
    if not pageData then
        return
    end
    local dataList = {}
    local canGetEntryId = nil
    for k, v in ipairs(pageData.entry) do
        if v.goalData.status == 1 then
            table.insert(dataList, { sid = pageData.sid, pageId = v.pageId, entryId = v.entryId })
            if not canGetEntryId then canGetEntryId = v.entryId end
        end
    end

    return dataList,canGetEntryId
end

function UI8LoginNew:RefreshRoundList(roundList)
    local showTab =  #roundList>1
    CS.ShowObject(self.mTabBtnList,showTab)
    local uiList = self:GetUIScroll("roundtabList")
	uiList:Create(self.mTabBtnList,roundList,function(...) self:OnDrawTab(...) end)
    self._tabUiList = uiList
    self._curSelRound = 0
end

function UI8LoginNew:OnClickClose()
    local canGetReward = self:GetCanGetReward()
    if canGetReward and #canGetReward > 0 then
        local para = {
            refId = 280101,
            func = function()
                gModelActivity:OnActivityReceiveGoalListReq(canGetReward)
            end,
            leftFunc = function()
                GF.CloseWndByName("UI8LoginNew")
            end
        }

        gModelGeneral:OpenUIOrdinTips(para)
    else
        self:WndClose()
    end
end

function UI8LoginNew:RefreshTopHeroName(viewImgName)
    if not viewImgName then
        return
    end

    local dataList = self._heroNamePosDataList[viewImgName] or {}
    for i = 1, self.mHeroName.childCount do
        local data = dataList[i]
        self:OnDrawHeroNameItem(self["mHeroName" .. i], data)
    end
end

function UI8LoginNew:OnActivityPageResp(pb, ret)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end

    local cnt = 8
    self._pageData = nil
    for k, v in ipairs(pb.pages or {}) do
        local pageId = v.pageId
        if pageId == UI8LoginNew.PAGE_SIGN then
            self._pageData = gModelActivity:GenerateActivePageDataFromPb(v)
            cnt = #self._pageData.entry
        end
    end
    local curSelRound
    if self._pageData then
        local actData = gModelActivity:GetActivityBySid(self._sid)
        local actMoreInfo = JSON.decode(actData.moreInfo)
        local startTime = actMoreInfo["p-startTime"]
        self._day = LUtil.GetDayPast(startTime / 1000)

        local canGetList,canGetEntryId = self:GetCanGetReward()
        self._curDay = canGetEntryId or  math.min(self._day+1, cnt)
        curSelRound = self._idToRoundIndx[self._curDay]

        -- local hasReward = false
        -- if canGetList and #canGetList > 0 then
        --     hasReward = true
        -- end
        -- local curDay = math.min(self._day, cnt)
        -- local nextDay = curDay + 1
        -- nextDay = math.min(nextDay, cnt)
        -- if not self._isOpened then
            -- if hasReward then
            --     self._curDay = canGetEntryId or curDay
            -- else
            --     self._curDay = nextDay
            -- end

        --     self._topShowDay = nextDay
        -- end
        -- self._isOpened = true
    end
    self:DoChangeTab(curSelRound)
    self:RefreshRewardList()
    self:RefreshTopShow()
    self:RefreshGetBtnShow()
end

function UI8LoginNew:InitEvent()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
        self:OnActivityPageResp(...)
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local activity = pb.activity
        if not activity or self._sid ~= activity.sid then
            return
        end
        local status = activity.status
        if status == 3 then
            self:WndClose()
            return
        end
        self:SetContent()
    end)

    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(...)
        local actData = gModelActivity:GetActivityBySid(self._sid)
        if actData.status == 3 then
            self:WndClose()
            return
        end

        self:SetContent()
    end)

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelActivity:OnActivityPageReq(self._sid)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalListResp, function(pb)
        local _previewDays1 = self._previewDays1
        local _previewDays2 = self._previewDays2
        if not _previewDays1 or not _previewDays2 then
            return
        end
        local goalEntries = pb.goalEntries
        for i, v in ipairs(goalEntries) do
            local sid = v.sid
            if sid ~= self._sid then
                return
            end
            local entryId = v.entryId
            if _previewDays1[entryId] then
                self._type = 1
            end
            if _previewDays2[entryId] then
                self._type = 2
                break
            end
        end
    end)
    self:WndEventRecv(EventNames.CLOSE_REWARD_WND, function(...)
        local sid = self._sid
        local type = self._type
        if not type then
            return
        end
        local bool = gModelGeneral:FindAlertId(sid)
        if bool then
            return
        end
        GF.OpenWnd("UI8DaysEventsPop", { sid = sid, type = type })
    end)
end

function UI8LoginNew:RefreshTopShow()

    local day = self._topShowDay or self._curDay

    self._topShowDay = nil

    local tipImgInfo = self._tipImgList[day]
    if tipImgInfo then
        self:SetWndEasyImage(self.mTipImg, tipImgInfo.imgPath, function()
            CS.ShowObject(self.mTipImg, true)
        end)
        self:SetAnchorPos(self.mTipRoot, tipImgInfo.offset)
        CS.ShowObject(self.mTipRoot, true)
        self:SetWndText(self.mTipText, tipImgInfo.descText or "")
    else
        CS.ShowObject(self.mTipRoot, false)
    end

    local entryCfg = self._dataList[day]
    if not entryCfg then
        return
    end

    local moreInfo = entryCfg.entry.moreInfo

    local strs = string.split(moreInfo, '=')
    local showType = strs[1] and tonumber(strs[1])
    local offset = LxDataHelper.ParseVector2(strs[3], '|')
    local scale = strs[4] and tonumber(strs[4])
    scale = scale or 1
    self:DestroyWndSpineByKey("drawing")

    local showItem, showHeroSpine, showHero = false, false, false
    if showType == 0 then
        showItem = true
        local iconPath = strs[2]
        self:SetWndEasyImage(self.mBigItem, iconPath)
        self.mBigItem.localScale = Vector3.New(scale, scale, scale)
        self:SetAnchorPos(self.mItemCtrl, offset)
        self:TweenItem()
    elseif showType == 2 then
        --立绘英雄轮播
        showHeroSpine = true
        local heroNamePosList = string.split(strs[2], '|')
        self._curShowViewImageIndex = nil
        local viewImageScrollTimeKey = self._viewImageScrollTimeKey
        self:TimerStop(viewImageScrollTimeKey)
        self:TweenSeqKill(self._viewImageScrollTweenKey)
        self:TweenSeqKill(self._viewSpineScrollTweenKey)
        if #heroNamePosList > 1 then
            --多个图片，需要轮播展示
            self._heroNamePosList = heroNamePosList
            self._curShowViewImageIndex = 1
            self:TimerStart(viewImageScrollTimeKey, 5, false, -1)
        end

        local key = heroNamePosList[1]
        self:RefreshTopHeroName(key)
        self:RefreshHeroSpineList(key)
        self.mHeroNameCanvasGroup.alpha = 1
        self.mHeroSpineListCanvasGroup.alpha = 1
    else
        showHero = true
        local isSkin = false
        local heroRefId = tonumber(strs[2])
        local effRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
        if not effRef then
            isSkin = true
            effRef = gModelHero:GetShowEffectById(heroRefId)
        end

        local drawing = effRef.heroDrawing

        self:SetAnchorPos(self.mDrawingRoot, offset)
        self:SetWndClick(self.mDrawingcClick, function()
            self:ShowHeroPre(heroRefId, isSkin)
        end)
        self:CreateWndSpine(self.mDrawingRoot, drawing, "drawing", nil, function(spine)

            spine:SetIgnoreTimeScale(true)
            spine:SetScale(scale)
            local spineTrans = spine:GetSpineTrans()
            local spineClick = spineTrans:GetComponent(typeSpineClick)
            if not spineClick then
                spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
                spineClick.isUISpine = true
            end
            spineClick.onClick = function()
                self:ShowHeroPre(heroRefId, isSkin)
            end
        end)

    end

    CS.ShowObject(self.mItemCtrl, showItem)
    CS.ShowObject(self.mHeroName, showHeroSpine)
    CS.ShowObject(self.mHeroSpineList, showHeroSpine)
    CS.ShowObject(self.mDrawingRoot, showHero)


end

function UI8LoginNew:OnDrawHeroSpineItem(item, itemdata, itemPos)
    local isShow = not table.isempty(itemdata)
    CS.ShowObject(item, isShow)
    if not isShow then
        return
    end

    local heroId = itemdata.heroId
    local effectRef = gModelHero:GetHeroShowRefByRefId(heroId)
    local heroDrawing = effectRef.heroDrawing
    if heroDrawing then
        local spineSize = itemdata.spineSize
        self:CreateHeroSpine(item, heroDrawing, itemPos, spineSize)
    end

    local pos = itemdata.spinePos
    self:SetAnchorPos(item, pos)
end
function UI8LoginNew:CanGetDay(roundIndx)
    local pageData = self._pageData
    if not pageData then
        return
    end
    local canGetEntryId = nil
    local roundMaxDay = nil
    local roundMinDay = nil
    for k, v in ipairs(pageData.entry) do
        local ok = self._idToRoundIndx[v.entryId] == roundIndx
        if ok and v.goalData.status == 1 then
            canGetEntryId = v.entryId
        end
        if ok then
            roundMaxDay = v.entryId
            if not roundMinDay then roundMinDay = v.entryId end
        end
    end

    return canGetEntryId or (self._day<roundMinDay and roundMinDay or math.min(self._day+1,roundMaxDay))
end

function UI8LoginNew:SetStaticContent()

    self:SetWndText(self.mCloseTip, ccClientText(10103))
    --if not gLGameLanguage:IsForeignRegion() then
    --	--海外不显示该特效
    --	self:CreateWndEffect(self.mEffRoot,"ui_fx_batianhuodong","eff1",125)
    --end

    --self:CreateWndEffect(self.mLight1,"ui_fx_batianhuodong_02","eff2",100)
    --self:CreateWndEffect(self.mLight2,"ui_fx_batianhuodong_02","eff3",100)

end

function UI8LoginNew:OnSelectItem(day)
    if self._curDay == day then
        return
    end

    local oldDay = self._curDay
    self._curDay = day

    if oldDay and self._listItem[oldDay] then
        local oldItem = self._listItem[oldDay]
        local AniRoot = self:FindWndTrans(oldItem, "AniRoot")
        local AniRootActive = self:FindWndTrans(AniRoot, "active")
        CS.ShowObject(AniRootActive, false)
    end
    if day and self._listItem[day] then
        local selItem = self._listItem[day]
        local AniRoot = self:FindWndTrans(selItem, "AniRoot")
        local AniRootActive = self:FindWndTrans(AniRoot, "active")
        CS.ShowObject(AniRootActive, true)
    end

    --local list = self:FindUIScroll("rewardList")
    --if list then
    --	list:DrawAllItems(false)
    --end

    self:RefreshTopShow()
    self:RefreshGetBtnShow()
end

function UI8LoginNew:OnTimer(key)
    if key == self._viewImageScrollTimeKey then
        self:ViewImageChangeAnim()
    end
end

function UI8LoginNew:InitUIEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBtnGet, function()
        self:OnClickGet()
    end)
    self:SetWndClick(self.mBtnHelp, function()
        GF.OpenWndUp("UIBzTips", { title = self._helpTipsTitle, text = self._helpTipsContent })
    end)

    self:SetWndClick(self.mMask, function()
        self:OnClickClose()
    end)
end

function UI8LoginNew:RefreshRewardList()
    local list = self:FindUIScroll("rewardList")
    if not list then
        list = self:GetUIScroll("rewardList")
        list:Create(self.mItemList, self._dataMap[self._curSelRound], function(...)
            self:OnDrawCell(...)
        end, UIItemList.SUPER_GRID)
    else
        list:RefreshList(self._dataMap[self._curSelRound])
        list:DrawAllItems(false)
    end

    --list:DrawAllItems(false)

    list:MoveToPos(self._curDay)
end

function UI8LoginNew:RefreshGetBtnShow()
    local entryCfg = self._dataList[self._curDay]
    if not entryCfg then
        return
    end

    local entryData = self:GetEntryData(entryCfg.entry.id)
    if not entryData then
        return
    end

    local str = ""
    local status = entryData.goalData.status
    local isGray = false
    local showGetTag = false
    if status == 0 then
        str = ccClientText(16206) --"不可领取"
        isGray = true
    elseif status == 1 then
        str = ccClientText(16207) --"领 取"
        --self:CreateWndEffect(self.mBtnGet,"fx_anniu_01","btnEff",100,false,false,20)

    elseif status == 2 then
        showGetTag = true
    end

    self:SetWndButtonText(self.mBtnGet, str)
    self:SetWndButtonGray(self.mBtnGet, isGray)

    CS.ShowObject(self.mGetTag, showGetTag)
    CS.ShowObject(self.mBtnGet, not showGetTag)

    local redTran = CS.FindTrans(self.mBtnGet, "redPoint")
    CS.ShowObject(redTran, status == 1)

    if status ~= 1 then
        self:DestroyWndEffectByKey("btnEff")
    end

end

function UI8LoginNew:ViewImageChangeAnim()
    if not self._curShowViewImageIndex then
        self._curShowViewImageIndex = 0
    end

    self.mHeroNameCanvasGroup.alpha = 0
    self.mHeroSpineListCanvasGroup.alpha = 0

    local heroNamePosList = self._heroNamePosList
    local imgMaxNum = #heroNamePosList
    local nextIndex = self._curShowViewImageIndex + 1
    if nextIndex > imgMaxNum then
        nextIndex = 1
    end
    self._curShowViewImageIndex = nextIndex
    local key = self._heroNamePosList[nextIndex]
    self:RefreshTopHeroName(key)
    self:RefreshHeroSpineList(key)

    self:TweenSeq_AlphaCanvasTrans(self._viewImageScrollTweenKey, self.mHeroName, 0, 1, 0.5)
    self:TweenSeq_AlphaCanvasTrans(self._viewSpineScrollTweenKey, self.mHeroSpineList, 0, 1, 0.3)
end

function UI8LoginNew:SetContent()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end

    local actData = gModelActivity:GetActivityBySid(self._sid)
    if not actData then
        return
    end

    local config = webData.config

    self._helpTipsTitle = actData.title
    self._helpTipsContent = config.helpTipsContent or ""
    self._signTip = config.signTips
    local previewDays1, previewDays2 = config.previewDays1, config.previewDays2

    if LxUiHelper.IsImgPathValid(config.title) then
        self:SetWndEasyImage(self.mTitle, config.title)
    end
    if not string.isempty(config.hero) then
        local heroId = tonumber(config.hero)
        self:SetSpineHero(heroId)
    else
        CS.ShowObject(self.mHeroSpinePos, false)
    end

    if not string.isempty(config.titlePos) then
        local pos = LxDataHelper.ParseVector2(config.titlePos, '|')
        self:SetAnchorPos(self.mTitle, pos)
    end

    if not string.isempty(previewDays1) then
        local list = {}
        local arr = string.split(previewDays1, ",")
        for i, v in ipairs(arr) do
            list[tonumber(v)] = true
        end
        self._previewDays1 = list
    end
    if not string.isempty(previewDays2) then
        local list = {}
        local arr = string.split(previewDays2, ",")
        for i, v in ipairs(arr) do
            list[tonumber(v)] = true
        end
        self._previewDays2 = list
    end

    local pageData = gModelActivity:GetWebActivityPageData(self._sid, UI8LoginNew.PAGE_SIGN)

    local dataList = {}
    local roundData = {}
    for k, v in ipairs(pageData.entries) do
        local rewards = LxDataHelper.ParseItem(v.reward)
        local data = {
            sid = self._sid,
            pageId = pageData.id,
            entry = v,
            rewards = rewards,
            roundIndx = v.turn or 1,
        }
        table.insert(dataList, data)
    end

    table.sort(dataList, function(a, b)
        return a.entry.sort < b.entry.sort
    end)
    local temp = {}
    local roundIndxs = {}
    for _, data in ipairs(dataList) do
        if not roundData[data.roundIndx] then
            roundData[data.roundIndx] = {}
            table.insert(roundIndxs,data.roundIndx)
        end
        table.insert(roundData[data.roundIndx],data)
        temp[data.entry.id] = data.roundIndx
    end
    self._dataList = dataList
    self._dataMap = roundData
    self._idToRoundIndx = temp

    self._tipImgList = {}

    local cnt = #pageData.entries

    for k = 1, cnt do
        local key = "descIcon" .. k
        local posKey = string.format("descIcon%sPos", k)
        local data = {
            imgPath = config[key],
            offset = LxDataHelper.ParseVector2(config[posKey], '|'),
            descText = config["descTxt" .. k]
        }

        self._tipImgList[k] = data
    end

    self._heroNamePosList = {}
    self._heroNamePosDataList = {}
    for i = 1, cnt do
        local key = "heroNamePos" .. i
        local heroNamePos = config[key]
        self:SetHeroNamePosList(key, heroNamePos)
    end
    self:RefreshRoundList(roundIndxs)
end

------------------------------------------------------------------
return UI8LoginNew


