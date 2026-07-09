---
--- Created by BY.
--- DateTime: 2023/10/15 14:28:04
---
---活动62 首充
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActInitPay:LWnd
local UIActInitPay = LxWndClass("UIActInitPay", LWnd)
local Tweening = DG.Tweening

local typeof = typeof
local UnityEngine = UnityEngine
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActInitPay:UIActInitPay()
    self._pageSelList = {}
    self._pageId = nil
    self._pages = {}
    self._uiCommonList = {}

    self._moveTime = 0.8
    self._moveX = 640
    self._timeKey = "UIActInitPay"
    self._alternateTime = 5
    self._playKey = "_playKey"
    self._raceBgs = {
        [1] = "firstcharge1_bg_frame_1",
        [2] = "firstcharge1_bg_frame_2",
        [3] = "firstcharge1_bg_frame_3"
    }
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActInitPay:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActInitPay:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActInitPay:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    if self.jpj then
        self:SetAnchorPos(self.mCostPerformance, Vector2.New(-135, 322))
    end

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:RefreshForeign()
end
-- function UIActInitPay:ListItem(list, item, itemdata, itempos)   by.lkt
-- 	local image = self:FindWndTrans(item,"Image")
-- 	local selImg = self:FindWndTrans(item,"SelImg")
-- 	local text = self:FindWndTrans(item,"UIText")
-- 	local redPoint = self:FindWndTrans(item,"redPoint")

-- 	local pageId = itemdata.pageId
-- 	local _tabIcon = self._tabIcon or {}
-- 	local img = _tabIcon[pageId]
-- 	local redBool = gModelRedPoint:GetActivityRedPointPage(self._sid,pageId)
-- 	local _tabName = self._tabName or {}
-- 	local nameText = _tabName[pageId] or itemdata.data
-- 	local pageData = self._pageList[itempos]
-- 	local textStr = pageData.textStr or nameText

-- 	CS.ShowObject(redPoint,redBool)
-- 	self:SetWndEasyImage(image,img)
-- 	self._pageSelList[pageId] = selImg

-- 	self:SetWndText(text,textStr)
-- 	self:SetWndClick(item,function ()
-- 		self:OnClickPage(pageId)
-- 	end)
-- end

function UIActInitPay:OnDrawTab(_, item, itemdata, itempos)
    local redPoint = self:FindWndTrans(item, "redPoint")

    local pageId = itemdata.pageId
    local _tabIcon = self._tabIcon or {}
    local img = _tabIcon[pageId]
    local _tabName = self._tabName or {}
    local nameText = _tabName[pageId] or itemdata.data
    local pageData = self._pageList[pageId]
    local textStr = pageData.textStr or nameText
    --local textStr = nameText
    self:SetWndTabText(item, textStr)

    self:SetWndEasyImage(self:FindWndTrans(item, "Off"), img)
    self:SetWndEasyImage(self:FindWndTrans(item, "On"), img)
    self._pageSelList[pageId] = item

    local redBool = gModelRedPoint:GetActivityRedPointPage(self._sid, pageId)
    CS.ShowObject(redPoint, redBool)

    self:SetWndTabStatus(item, 1)

    self:SetWndClick(item, function()
        self:OnClickPage(pageId)
    end)
end

function UIActInitPay:OnTimer(key)
    if (key == self._timeKey) then
        self:SetHeroImageArr()
    end
end
function UIActInitPay:OnClickPage(pageId)
    self._pageId = pageId
    local _pageSelList = self._pageSelList
    for i, v in pairs(_pageSelList) do
        self:SetWndTabStatus(v, 1)
    end
    self:SetWndTabStatus(_pageSelList[pageId], 0)
    local _pageId = self._pageId
    local _pages = self._pageList
    local pageData = _pages[_pageId]
    local isRecharge = pageData.isRecharge == 1

    CS.ShowObject(self.mNumText, not isRecharge)

    self:RefreshPageData()
end

function UIActInitPay:OnCustomRewardCell(list, item, itemdata, itempos)
    local Icon = self:FindWndTrans(item, "Root/CommonUI/Icon")
    local shiftBtn = self:FindWndTrans(item, "ShiftBtn")
    local pbData = itemdata
    local goalData = pbData.goalData
    local goalGift = goalData.goalGift
    local customRewards = string.split(goalGift, ",")
    local isFixedReward = itemdata.isFixedReward
    self.seleGift = goalGift
    local goalStatus = goalData.status
    local canSel = goalStatus ~= 2
    local instanceID = Icon:GetInstanceID()
    local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pbData.pageId, pbData.entryId)
    local itemData
    if (isFixedReward) then
        local reward = entryCfg.reward
        itemData = LxDataHelper.ParseItem_4(reward)
    elseif (customRewards and #customRewards > 0) then
        local reward = customRewards[itempos]
        itemData = LxDataHelper.ParseItem_4(reward)
    else
        itemData = {
            isEmpty = true,
            itemId = 0,
            itemNum = -1,
        }
    end
    CS.ShowObject(shiftBtn, not isFixedReward and not itemData.isEmpty)
    local commonInfo = {
        instanceID = instanceID,
        trans = Icon,
        itemType = itemData.itemType,
        itemId = itemData.itemId,
        itemNum = itemData.itemNum,
    }
    self:CreateCommonIcon(commonInfo)
    local rewardFree = entryCfg.rewardFree
    self:SetWndClick(Icon, function()
        --if(goalStatus == 1 and not string.isempty(goalGift))then
        --	self:OnClickGetReward(pbData.pageId,pbData.entryId)
        --else
        if not isFixedReward and canSel and not string.isempty(rewardFree) then
            self:OpenUICumSelectNew(pbData.pageId, pbData.entryId, itemData)
        else
            gModelGeneral:ShowCommonItemTipWnd(itemData)
        end
    end)
    self:SetWndClick(shiftBtn, function()
        if canSel then
            self:OpenUICumSelectNew(pbData.pageId, pbData.entryId, nil, true)
        end
    end)

end

function UIActInitPay:RefreshPageData()
    local _pageId = self._pageId
    local _pages = self._pages
    local pageData = _pages[_pageId]
    if not pageData then
        return
    end
    local _pageList = self._pageList
    local _pageWebData = _pageList[_pageId]
    if not _pageWebData then
        return
    end

    -------------------------------------------------显示-----------------------------------------
    local image, imagePos, title, titleBg, titlePos, advertisement, advertisementPos, imageEffect, imageEffectPos = _pageWebData.image, _pageWebData.imagePos, _pageWebData.title, _pageWebData.titleBg, _pageWebData.titlePos, _pageWebData.advertisement, _pageWebData.advertisementPos, _pageWebData.imageEffect, _pageWebData.imageEffectPos

    local heroLH, heroLHPos = _pageWebData.heroLH, _pageWebData.heroLHPos
    local showHero, showHeroPos = _pageWebData.showHero, _pageWebData.showHeroPos
    local titleDesc, titleDescPos, battlePreview, battlePreviewPos, detailsPreview, detailsPreviewPos = _pageWebData.titleDesc, _pageWebData.titleDescPos, _pageWebData.battlePreview, _pageWebData.battlePreviewPos, _pageWebData.detailsPreview, _pageWebData.detailsPreviewPos


    --这里加上判断是否为6元 activityCfg.config
    local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
    if not activityCfg then
        return
    end

    local isPageId1 = self._pageId == 1

    local costPerformance

    if isPageId1 then
        title = activityCfg.config.heroNameImage
        titleBg = activityCfg.config.heroNameImage
        titlePos = activityCfg.config.heroNameImagePos

        costPerformance = activityCfg.config.costPerformance
    elseif self._pageId == 2 then
        title = activityCfg.config.heroNameImage1
        titleBg = activityCfg.config.heroNameImage1
        titlePos = activityCfg.config.heroNameImagePos1

        costPerformance = activityCfg.config.costPerformance1
    elseif self._pageId == 3 then
        title = activityCfg.config.heroNameImage2
        titleBg = activityCfg.config.heroNameImage2
        titlePos = activityCfg.config.heroNameImagePos2

        costPerformance = activityCfg.config.costPerformance2
    elseif self._pageId == 5 then
        title = activityCfg.config.heroNameImage5
        titleBg = activityCfg.config.heroNameImage5
        titlePos = activityCfg.config.heroNameImagePos5

        costPerformance = activityCfg.config.costPerformance5
    elseif self._pageId == 6 then
        title = activityCfg.config.heroNameImage6
        titleBg = activityCfg.config.heroNameImage6
        titlePos = activityCfg.config.heroNameImagePos6

        costPerformance = activityCfg.config.costPerformance6
    end

    self._battlePreview, self._detailsPreview = battlePreview, detailsPreview
    -------------------------------------------------通用-----------------------------------------
    --价值的百分比
    if not string.isempty(costPerformance) then
        CS.ShowObject(self.mCostPerformance, true)
        local rateStr = LUtil.FormatHurtNumSpriteText(costPerformance)

        self:SetWndText(self.mCostPerformanceRateStr, rateStr)

        if self._isEnus then
            self:InitTextSizeWithLanguage(self.mCostPerformanceRateStr, 10)
        end

        local delayCallWhenLoad = function()
            LxTimer.DelayFrameCall(function()
                UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mCostPerformanceRateStr)
                UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mCostPerformance)

                local x1 = self.mCostPerformanceRateStr.rect.width
                x1 = x1 + 25 + 34
                x1 = x1 / 2
                --补正 20
                if x1 < 100 then
                    x1 = x1 + 20
                end

                self:SetAnchorPos(self.mCostPerformanceImg, Vector2.New(x1, 24))


            end, 1)
        end

        delayCallWhenLoad()

    else
        CS.ShowObject(self.mCostPerformance, false)
    end

    if LxUiHelper.IsImgPathValid(image) then
        CS.ShowObject(self.mBg, true)
        self:SetWndEasyImage(self.mBg, image)
        if not string.isempty(imagePos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(imagePos)
            self:SetAnchorPos(self.mBg, pos)
        end
    end
    if not string.isempty(title) then
        --self:SetWndText(self.mTitleText, title)
        if LxUiHelper.IsImgPathValid(titleBg) then
            self:SetWndEasyImage(self.mTitleBg, titleBg, nil, true)
            -- self:SetWndEasyImage(self.mTitleBg1,titleBg,nil,true) by.lkt
            if not string.isempty(titlePos) then
                local pos = LxDataHelper.ParseVector2NotEmpty(titlePos)
                self:SetAnchorPos(self.mTitleBg, pos)
            end
        end
    end
    CS.ShowObject(self.mTitleBg, not string.isempty(title))
    if LxUiHelper.IsImgPathValid(advertisement) then
        CS.ShowObject(self.mADImg, true)
        self:SetWndEasyImage(self.mADImg, advertisement, nil, true)
        if not string.isempty(advertisementPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(advertisementPos)
            self:SetAnchorPos(self.mADImg, pos)
        end
    end
    CS.ShowObject(self.mBgEff, false)
    if not string.isempty(imageEffect) then
        CS.ShowObject(self.mBgEff, true)
        local _imageEffect = self._imageEffect
        if _imageEffect and _imageEffect ~= imageEffect then
            self:DestroyWndEffectByKey("bgEff")
        end
        self:CreateWndEffect(self.mBgEff, imageEffect, "bgEff", 100)
        self._imageEffect = imageEffect
        if not string.isempty(imageEffectPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(imageEffectPos)
            self:SetAnchorPos(self.mBgEff, pos)
        end
    end
    -------------------------------------------------通用-----------------------------------------
    if not string.isempty(heroLH) then
        local heroLHArr = string.split(heroLH, "=")
        if heroLHArr[1] == "1" then
            CS.ShowObject(self.mHeroImage, true)
            self:SetWndEasyImage(self.mHeroImage, heroLHArr[2], nil, true)
        else
            CS.ShowObject(self.mHeroSpine, true)
            self:CreateWndSpine(self.mHeroSpine, heroLHArr[2], "mHeroSpine", false, function(dpSpine)
                --dpSpine:SetScale(paintMultiple)
                --dpSpine:SetFlipX(paintFlip)
                local dpTrans = dpSpine:GetDisplayTrans()
                dpTrans.anchorMin = Vector2.New(0.5, 0.5)
                dpTrans.anchorMax = Vector2.New(0.5, 0.5)
            end)
        end
        if not string.isempty(heroLHPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(heroLHPos)
            self:SetAnchorPos(self.mHeroSpine, pos)
            self:SetAnchorPos(self.mHeroImage, pos)
        end
    else
        CS.ShowObject(self.mHeroSpine, false)
        CS.ShowObject(self.mHeroImage, false)
    end
    if not string.isempty(titleDesc) then
        CS.ShowObject(self.mTitleDesText, true)
        self:SetWndText(self.mTitleDesText, titleDesc)
        if not string.isempty(titleDescPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(titleDescPos)
            self:SetAnchorPos(self.mTitleDesText, pos)
        end
    else
        CS.ShowObject(self.mTitleDesText, false)
    end
    CS.ShowObject(self.mBtnBattle, battlePreview)
    if battlePreview then
        if not string.isempty(battlePreviewPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(battlePreviewPos)
            self:SetAnchorPos(self.mBtnBattle, pos)
        end
    end
    local detailsPreviewArr = detailsPreview and string.split(detailsPreview, "|") or nil
    CS.ShowObject(self.mBtnDetails, detailsPreview and (not detailsPreviewArr or #detailsPreviewArr == 1))
    CS.ShowObject(self.mRaceImg, false)
    self:SetRolePartList()
    CS.ShowObject(self.mRolePartList, _pageId == 1)
    CS.ShowObject(self.mBotJumpEff, true)
    if detailsPreview and (not detailsPreviewArr or #detailsPreviewArr == 1) then
        local ref = gModelHero:GetHeroRef(detailsPreview)
        local raceType = ref.raceType
        local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
        local icon = raceRef.icon
        CS.ShowObject(self.mRaceImg, true)
        self:SetWndEasyImage(self.mRaceImg, icon)
        if not string.isempty(detailsPreviewPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty(detailsPreviewPos)
            self:SetAnchorPos(self.mBtnDetails, pos)
        end
        CS.ShowObject(self.mRolePartList, false)
        CS.ShowObject(self.mBotJumpEff, false)
    end

    local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
    if activityCfg then
        local txtImage
        local data = activityCfg.config
        local isRound1 = data.isRound1

        if not string.isempty(showHero) then
            self._showHero = showHero
            self._showMode1 = _pageWebData.showMode1
            if not string.isempty(showHeroPos) then
                local arr = string.split(showHeroPos, "=")
                local pos = LxDataHelper.ParseVector2NotEmpty(arr[1])
                local pos2 = LxDataHelper.ParseVector2NotEmpty(arr[2] or arr[1])
                self._pos = pos
                self._pos2 = pos2
            end
            if isRound1 == 1 then
                self:TimerStop(self._timeKey)
                self:TimerStart(self._timeKey, self._alternateTime, false, -1)
            end
            self:SetHeroImageArr()
        else
            --CS.ShowObject(self.mShowHeroSpine,false)
            CS.ShowObject(self.mShowHeroImage, false)
            CS.ShowObject(self.mShowHeroImage2, false)
            self:TimerStop(self._timeKey)
        end

        local showTxt, showTxtPos
        if _pageId == 1 then
            txtImage = data.txtImage
            showTxt, showTxtPos = data.showTxt, data.showTxtPos
        elseif _pageId == 2 then
            txtImage = data.txtImage1
            showTxt, showTxtPos = data.showTxt1, data.showTxtPos1
        end
        if not string.isempty(txtImage) then
            self:SetWndEasyImage(self.mShowTipsNodeImg, txtImage)
        end
        ----显示文本-------
        if string.isempty(showTxt) then
            CS.ShowObject(self.mShowTipsNode, false)
        else
            CS.ShowObject(self.mShowTipsNode, true)
            self:SetWndText(self.mShowTipsText, showTxt)
            local showTxtPosArr = string.split(showTxtPos or "", ",") or {}
            if #showTxtPosArr == 2 then
                self:SetAnchorPos(self.mShowTipsNode, Vector2(checknumber(showTxtPosArr[1]), checknumber(showTxtPosArr[2])))
            end
        end
    end

    -------------------------------------------------显示-----------------------------------------
    local list = pageData.entry
    local len = #list

    local payDay = 0

    if _pageId == 1 then
        payDay = self._firstDay
    elseif _pageId == 2 then
        payDay = self._allDay
    elseif _pageId == 3 then
        payDay = self._thirdDay
    elseif _pageId == 5 then
        payDay = self._thirdDay5
    elseif _pageId == 6 then
        payDay = self._thirdDay6
    end

    local getEntryId = 0                        --可领取标签id
    local isGetEnd = true                        --是否领取完
    for i, v in ipairs(list) do
        if getEntryId == 0 and v.goalData.status == 1 then
            if payDay >= v.entryId then
                getEntryId = v.entryId
            elseif v.entryId <= len then
                getEntryId = -1
            end
            isGetEnd = false
        end
    end
    if getEntryId > 0 then
        self._getDay = getEntryId
    else
        self._getDay = nil
    end
    local btnFun = nil
    local btnStr = ccClientText(15703)
    self:SetWndButtonGray(self.mBtnPay, getEntryId == -1)


    --这里设置特效部分  -- 改成设置红点
    --CS.ShowObject(self.mPayEff,getEntryId > 0)
    local payRedpoint = CS.FindTrans(self.mBtnPay, "redPoint")
    CS.ShowObject(payRedpoint, getEntryId > 0)
    local isCanGetBtnStr = false
    if not isGetEnd then
        if getEntryId > 0 then
            isCanGetBtnStr = true
            btnStr = ccClientText(15704)
            btnFun = function()
                self:OnClickGetReward(_pageId, getEntryId)
            end
        elseif getEntryId == -1 then
            btnStr = ccClientText(15705)
            isCanGetBtnStr = true
        end
    else
        btnFun = function()
            self:OnClickPay()
        end
    end

    local _pageId = self._pageId
    local _pages = self._pageList
    local pageData = _pages[_pageId]
    local _isRecharge = pageData.isRecharge == 1
    if _isRecharge and (not isCanGetBtnStr) then
        local pag = _pageId
        if pag > 3 then
            pag = pag - 1
        end
        local shopData = self._shopPage.entry[pag]
        local expend2 = checknumber(shopData.MarketData.expend2)
        local valueShow = gModelPay:GetShowByWelfareId(expend2)
        btnStr = valueShow
    end

    self:SetWndButtonText(self.mBtnPay, btnStr)
    local lens = 0
    for i, v in ipairs(list) do
        if v.goalData.status == 2 then
            lens= lens +1
        end
    end
    if lens>=3 then
        CS.ShowObject(self.mBotJumpEff,false)
        btnStr = ccClientText(18711)
        self:SetWndButtonText(self.mBtnPay, btnStr)
        self:SetWndButtonGray(self.mBtnPay, true)
    end
    if self._isVie then
        local Gray = CS.FindTrans(self.mBtnPay,"Gray/Text")
        self:InitTextSizeWithLanguage(Gray,-10)
        self:InitTextCharacterWithLanguage(Gray,-5)
    end
    self:SetWndClick(self.mBtnPay, function(...)
        if btnFun then
            btnFun()
        end
    end, LSoundConst.CLICK_BUTTON_COMMON)

    self._listLen = len
    local _uiItemList = self._uiItemList
    if _uiItemList then
        _uiItemList:RefreshList(list)
    else
        self._uiItemList = self:GetUIScroll("mItemScroll")
        self._uiItemList:Create(self.mItemScroll, list, function(...)
            self:ItemListItem(...)
        end)
    end

end

function UIActInitPay:PlayEff(trans, eff, key, isDes)
    if (isDes) then
        self:DestroyWndEffectByKey(key)
    end
    self:CreateWndEffect(trans, eff, key, 100)
end

function UIActInitPay:OnClickPay()
    local _pageId = self._pageId
    local _pages = self._pageList
    local pageData = _pages[_pageId]
    local isRecharge = pageData.isRecharge == 1
    if _pageId > 3 then
        _pageId = _pageId - 1
    end
    local shopData = self._shopPage.entry[_pageId]
    local expend2 = checknumber(shopData.MarketData.expend2)
    if isRecharge then
        gModelPay:GiftPayCtrl(_pageId, expend2, ModelPay.PAY_TYPE_ACTIVITY, 0, self._sid, 4)
    else
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_FIRST_RECHARGE, "recharge", self._heroRefId)
        local isOpen = gModelFunctionOpen:CheckIsOpened(self._jump, false)

        if isOpen then
            gModelFunctionOpen:Jump(self._jump, self:GetWndName())
        else
            gModelFunctionOpen:Jump(self._exJump, self:GetWndName())
        end
    end
end

function UIActInitPay:OnClickGetReward(pageId, entryId)
    --领取奖励
    local isOpen = self:OpenUICumSelectNew(pageId, entryId)
    if isOpen then
        return
    end
    gModelActivity:OnActivityReceiveGoalReq(self._sid, pageId, entryId)
end

function UIActInitPay:SpineMove(pos, key, speedTime)
    local seqTween
    self:TweenSeqKill(key)
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            local spineTrans, endPos
            if pos == 1 then
                spineTrans = self.mShowHeroImage
                endPos = self._pos or Vector3.zero
                spineTrans.localPosition = Vector2.New(-self._moveX, spineTrans.localPosition.y)
            else
                spineTrans = self.mShowHeroImage2
                endPos = self._pos2 or Vector3.zero
                spineTrans.localPosition = Vector2.New(self._moveX, spineTrans.localPosition.y)
            end
            CS.ShowObject(spineTrans, true)
            local tweener = spineTrans:DOLocalMove(endPos, speedTime)
            seq:Append(tweener)
            local itemCanvasGroup = spineTrans:GetComponent(typeofCanvasGroup)
            itemCanvasGroup.alpha = 0
            local tween = itemCanvasGroup:DOFade(1, speedTime * 1.2)
            seq:Join(tween)
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)
    end)
end

function UIActInitPay:RefreshData()
    local _pageId = self._pageId
    local _pages = self._pages
    if not _pages then
        return
    end

    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end

    local firstPay = JSON.decode(activityData.moreInfo)
    self._firstDay = firstPay.first_charge_time    --6元充值时间
    self._allDay = firstPay.all_charge_time        --100元充值时间
    self._thirdDay = firstPay.all_charge_time2        --100元充值时间
    self._thirdDay5 = firstPay.all_charge_time5        --328元充值时间
    self._thirdDay6 = firstPay.all_charge_time6        --648元充值时间
    self:SetWndText(self.mNumText, string.replace(ccClientText(15701), firstPay.all_charge))
    CS.ShowObject(self.mNumText, false)
    local list = {}
    for i, v in pairs(_pages) do
        if v.pageId == 4 then
            self._shopPage = v
        else
            table.insert(list, v)
        end

    end
    table.sort(list, function(a, b)
        return a.pageId > b.pageId
    end)
    -- local _uiPageList = self._uiPageList  by.lkt
    -- if _uiPageList then
    -- 	_uiPageList:RefreshList(list)
    -- else
    -- 	_uiPageList = self:GetUIScroll("mPageScroll")
    -- 	_uiPageList:Create(self.mPageScroll,list,function (...) self:ListItem(...) end)
    -- 	self._uiPageList = _uiPageList
    -- end

    if self._botTabList then
        self._botTabList:RefreshList(list)
    else
        self._botTabList = self:GetUIScroll("TabScroll")
        self._botTabList:Create(self.mTabScroll, list, function(...)
            self:OnDrawTab(...)
        end)
    end
    if not _pageId then

        if self._jumpPageId then
            self:OnClickPage(self._jumpPageId)
            return
        end

        for i, v in ipairs(list) do
            local entrys = v.entry
            local pageId = v.pageId
            local currDay = pageId == 1 and firstPay.first_charge_time or firstPay.all_charge_time
            for j, k in ipairs(entrys) do
                local status = k.goalData.status
                if status == 1 and currDay >= k.entryId then
                    --第一次进入时候的判断
                    local jumpPage = self._jumpPageId or k.pageId

                    self:OnClickPage(jumpPage)
                    return
                end
            end
        end

    end
    if not _pageId then
        local pageLen = #list
        if pageLen > 0 then
            _pageId = list[pageLen].pageId
        else
            _pageId = 0
        end
    end
    if LOG_INFO_ENABLED then
        printInfoNR("打印而已，莫慌 	活动测试打印		_pageId = " .. _pageId .. ",#list = " .. #list)
    end
    if _pageId and _pageId > 0 then
        self:OnClickPage(_pageId)
    end
end

function UIActInitPay:SetHeroName(item, itemdata, pos, showMode1)
    local isImg = showMode1 == 1
    local nameBg = self:FindWndTrans(item, "NameBg")
    local nameBgEn = self:FindWndTrans(item, "NameBgEn")
    local bgTrans = self:FindWndTrans(nameBgEn, "Bg")
    local isForeign = gLGameLanguage:IsForeignVersion()
    local nameBgTrans = isForeign and nameBgEn or nameBg
    local nameBgImgTrans = isForeign and bgTrans or nameBg
    local raceIcon = self:FindWndTrans(nameBgTrans, "RaceIcon")
    local nameText = self:FindWndTrans(nameBgTrans, "NameText")
    local SpineRoot = self:FindWndTrans(item, "SpineRoot")
    CS.ShowObject(nameBgTrans, false)
    CS.ShowObject(SpineRoot, false)
    if not itemdata then
        return
    end

    if not self._wndSpineKey then
        self._wndSpineKey = {}
    end

    local showSpine = false
    local heroId = tonumber(itemdata)
    local spinekey = item:GetInstanceID() .. heroId
    if isImg then
        local ref = gModelHero:GetHeroRef(heroId)
        local effRef = gModelHero:GetHeroEffectRef(heroId)
        local name = ccLngText(effRef.name)
        local raceType = ref.raceType
        local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
        local icon = raceRef.icon
        local bg = self._raceBgs[raceType]
        self:SetWndEasyImage(raceIcon, icon)
        self:SetWndText(nameText, name)
        self:InitTextSizeWithLanguage(nameText, -2)
        self:InitTextLineWithLanguage(nameText, -30)
        self:SetWndEasyImage(nameBgImgTrans, bg)
        if not string.isempty(pos) then
            local posS = LxDataHelper.ParseVector2NotEmpty(pos)
            self:SetAnchorPos(nameBgTrans, posS)
        end
    else
        local heroDrawing = gModelHero:GetHeroDrawing(heroId)

        if not self._curSpineKey then
        else
            self._wndSpineKey[self._curSpineKey]:SetVisible(false)
        end

        if heroDrawing then
            if self._wndSpineKey[spinekey] then
                self._wndSpineKey[spinekey]:SetVisible(true)
            else
                self._wndSpineKey[spinekey] = self:CreateWndSpine(SpineRoot, heroDrawing, spinekey, false)
            end

            showSpine = true
        end
    end
    self._curSpineKey = spinekey

    CS.ShowObject(nameBgTrans, isImg)
    CS.ShowObject(SpineRoot, showSpine)
end
function UIActInitPay:SetRolePartList()
    local actData = gModelActivity:GetWebActivityDataById(self._sid)
    if not actData then
        return
    end
    local mainCfg = actData.config
    local showHero1 = mainCfg.showHero1--首充六元，展示伙伴id和位置
    local titlePos = mainCfg.titlePos
    local heroLHSize = mainCfg.heroLHSize--首充六元，展示伙伴立绘倍数
    local battlePreview = mainCfg.battlePreview--首充六元，战斗预览（接入通用战报系统）和位置
    local battlePreviewArr = string.split(battlePreview, "|")
    local detailsPreview = battlePreview--mainCfg.detailsPreview
    local detailsPreviewArr = string.split(detailsPreview, "|")

    local jump1 = mainCfg.jump1
    local text3 = mainCfg.text3

    local jump2 = mainCfg.jump2
    local text4 = mainCfg.text4

    local jump3 = mainCfg.jump3
    local text6 = mainCfg.text6

    local text7 = mainCfg.text7
    local text8 = mainCfg.text8

    local isPageId1 = self._pageId == 1
    local jumpId
    local texStr

    local skinBg, skinSpineHd
    if isPageId1 then
        skinBg, skinSpineHd = mainCfg.skinBg, mainCfg.skinSpineHd

        jumpId = jump1
        texStr = text3
    elseif self._pageId == 2 then
        skinBg, skinSpineHd = mainCfg.skinBg1, mainCfg.skinSpineHd1

        jumpId = jump2
        texStr = text4
    elseif self._pageId == 3 then
        skinBg, skinSpineHd = mainCfg.skinBg2, mainCfg.skinSpineHd2

        jumpId = jump3
        texStr = text6
    elseif self._pageId == 5 then
        skinBg, skinSpineHd = mainCfg.skinBg5, mainCfg.skinSpineHd5

        --jumpId = jump3
        texStr = text7
    elseif self._pageId == 6 then
        skinBg, skinSpineHd = mainCfg.skinBg6, mainCfg.skinSpineHd6

        --jumpId = jump3
        texStr = text8
    end

    local showeBg = not string.isempty(skinBg)

    --缓存下旧的动态背景 不要频繁创建
    self._roleSpine = self._roleSpine or {}

    if showeBg then

        if not self._roleSpine[skinBg] then

            self._roleSpine[skinBg] = self:CreateWndSpine(self.mRoleSpineBg, skinBg, skinBg, false, function(dpSpine)
            end)
        else
            self._roleSpine[skinBg]:SetVisible(true)
        end
    end
    CS.ShowObject(self.mRoleSpineBg, showeBg)

    --判断下旧的有没有
    if self._oldSpineKey then
        if self._oldSpineKey ~= skinBg then
            self._roleSpine[self._oldSpineKey]:SetVisible(false)

        end
    end
    self._oldSpineKey = skinBg

    local showeHd = not string.isempty(skinSpineHd)
    if showeHd then
        self:CreateWndSpine(self.mRoleSpineHd, skinSpineHd, skinSpineHd, false, function(dpSpine)
        end)
    end
    CS.ShowObject(self.mRoleSpineHd, showeHd)

    local rolePartList = self.mRolePartList
    local showHeroArr = string.split(showHero1, "|")
    local heroNameGroupPosArr = string.split(titlePos, "|")
    for i = 1, 3 do
        local rolepartGroup = rolePartList:GetChild(i)
        CS.ShowObject(rolepartGroup, showHeroArr[i])
    end
    for i = 1, #showHeroArr do
        local rolepartGroup = rolePartList:GetChild(i)
        local spineList = self:FindWndTrans(rolePartList, "SpineList")
        local rolepart = spineList:GetChild(spineList.childCount - i)

        local roleSpine = self:FindWndTrans(rolepart, "roleSpine")

        local jumpGroup = self:FindWndTrans(rolepartGroup, "JumpGroup")
        local raceImg = self:FindWndTrans(jumpGroup, "RaceImg")
        local bgImg = self:FindWndTrans(jumpGroup, "Bg")
        local nameTxt = self:FindWndTrans(jumpGroup, "NameTxt")
        local descTxt = self:FindWndTrans(jumpGroup, "DescTxt")
        local previewBtn = self:FindWndTrans(rolepartGroup, "PreviewBtn")
        --local detailsBtm = self:FindWndTrans(jumpGroup,"DetailsBtm")
        local previewBtnTxt = self:FindWndTrans(previewBtn, "Txt")
        local heroDataArr = string.split(showHeroArr[i], "=")
        local heroNameGroupPosData = string.split(heroNameGroupPosArr[i], "=")
        local heroNameGroupPos = heroNameGroupPosData[2]
        local refId = tonumber(heroDataArr[1])
        local heroSpinePos = heroDataArr[2]
        local heroEffRef = gModelHero:GetShowEffectById(refId)
        local heroRef = gModelHero:GetHeroRef(heroEffRef.heroType)
        local heroName = heroEffRef.name
        local heroDrawing = heroEffRef.heroDrawing
        local heroLHSizeDataArr = string.split(heroLHSize[i], "=")

        if self._isVie then
            self:InitTextLineWithLanguage(previewBtnTxt, 0)
        end
        if self.jpj then
            self:InitTextLineWithLanguage(previewBtnTxt, -30)
        end
        self:CreateWndSpine(roleSpine, heroDrawing, heroDrawing, false, function(dpSpine)
            if (heroLHSizeDataArr[2]) then
                dpSpine:SetScale(tonumber(heroLHSizeDataArr[2]))
            end
        end)

        if not string.isempty(heroSpinePos) then
            local v2 = LxDataHelper.ParseVector2NotEmpty(heroSpinePos)
            self:SetAnchorPos(roleSpine, v2)
        end

        if not string.isempty(heroNameGroupPos) then
            local v2 = LxDataHelper.ParseVector2NotEmpty(heroNameGroupPos)
            self:SetAnchorPos(jumpGroup, v2)
        end

        local battlePreviewData = battlePreviewArr[i]
        local battlePreviewDataArr = string.split(battlePreviewData, "=")
        if not string.isempty(battlePreviewDataArr[3]) then
            local v2 = LxDataHelper.ParseVector2NotEmpty(battlePreviewDataArr[3])
            self:SetAnchorPos(previewBtn, v2)
        end

        local detailsPreviewData = detailsPreviewArr[i]
        local detailsPreviewDataArr = string.split(detailsPreviewData, "=")
        --if not string.isempty(detailsPreviewDataArr[2]) then
        --	local v2 = LxDataHelper.ParseVector2NotEmpty(detailsPreviewDataArr[2])
        --	self:SetAnchorPos(detailsBtm,v2)
        --end

        local careerType = heroRef.careerType
        local careerRef = gModelHero:GetCareerRefByRefId(careerType)
        local careerName = ccLngText(careerRef.name)

        local raceType = heroRef.raceType
        local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
        local raceImgPath = raceRef.icon

        local location = ccLngText(heroEffRef.location)
        local descTxtFormatStr = "#a1# <color=#68e6ac>[#a2#]</color>"
        local descStr = string.replace(descTxtFormatStr, careerName, location)

        self:SetWndText(nameTxt, ccLngText(heroName))
        self:SetWndText(descTxt, descStr)
        self:SetWndText(previewBtnTxt, ccClientText(15708))
        self:SetWndEasyImage(raceImg, raceImgPath)
        self:SetWndEasyImage(bgImg, "public_race_bg_" .. raceType)

        --self.mBotJumpEff
        --self:CreateWndEffect(self.mBotJumpEff,"ui_fx_mengjingxueyuan_qipao","ui_fx_mengjingxueyuan_qipao",200)
        local botJumpTxt = self:FindWndTrans(self.mBotJumpEff, "Txt")
        --self:DOScaleTxt(botJumpTxt)
        self:SetWndText(botJumpTxt, texStr)

        self:DOBotJumpLoopScale(self.mBotJumpEff, "BotJump")

        self:SetWndClick(self.mBotJumpEff, function()
            local functionId = jumpId
            if functionId and not gModelFunctionOpen:CheckIsOpened(functionId, true) then
                return
            end
            gModelFunctionOpen:Jump(functionId, self:GetWndName())
        end)

        self:SetWndClick(previewBtn, function()
            gModelBattle:OnClickShamBattle(tonumber(battlePreviewDataArr[2]))
        end)
        self:SetWndClick(jumpGroup, function()
            local _heroRefId = tonumber(detailsPreviewDataArr[1])
            gModelGeneral:OpenHeroStarPre({ refId = _heroRefId })
            gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_FIRST_RECHARGE, "hero_preview", _heroRefId)
        end)

        CS.ShowObject(rolepartGroup, true)
        CS.ShowObject(roleSpine, true)
        CS.ShowObject(self.mBtnBattle, false)
        CS.ShowObject(jumpGroup, false)
    end
end

function UIActInitPay:DOBotJumpLoopScale(trans, key)
    local seqTween
    local scaleKey = key--"BotJumpTxt"
    --self:TweenSeqKill(scaleKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(scaleKey, function(seq)
            local tweener = trans:DOScale(Vector3(0.8, 0.8, 1), 1)
            seq:Append(tweener)
            seq:SetLoops(-1, Tweening.LoopType.Yoyo)
            return seq
        end)
    end
    seqTween:PlayForward()
end

function UIActInitPay:InitMessage()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if sid ~= self._sid then
            return
        end
        self:OnActivityConfigData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local activity = pb.activity
        if activity.sid ~= self._sid then
            return
        end
        local status = activity.status
        if status == 3 then
            self:WndClose()
            return
        end

        gModelActivity:ReqActivityConfigData(self._sid)
        --self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        local activities = pb.activities
        for i, v in ipairs(activities) do
            if v.sid == self._sid then
                if v.status == 3 then
                    self:WndClose()
                    return
                end
                self:RefreshData()
                return
            end
        end
    end)
    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshData() end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:ResetData(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerChangeResp, function(pb)
        if not self._sid then
            return
        end
        gModelActivity:ReqActivityConfigData(self._sid)
    end)
    --self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end

function UIActInitPay:OnClickBattle()
    local _battlePreview = self._battlePreview
    gModelBattle:OnClickShamBattle(_battlePreview)
end

function UIActInitPay:ResetData(pb)
    local sid = pb.sid
    if (self._sid ~= sid) then
        return
    end
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        self._pages[v.pageId] = page
    end
    self:RefreshData()
end

function UIActInitPay:OnClickDetails()
    local _heroRefId = self._detailsPreview
    gModelGeneral:OpenHeroStarPre({ refId = _heroRefId })
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_FIRST_RECHARGE, "hero_preview", _heroRefId)
end
function UIActInitPay:OpenUICumSelectNew(pageId, entryId, itemData, isClickChangBtn)
    local _pages = self._pages
    local pageData = _pages[pageId]
    local entry = pageData.entry[entryId]
    local goalData = entry.goalData
    local goalGift = goalData.goalGift
    local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, pageId, entryId)
    local rewardFree = entryCfg.rewardFree
    local giftData = {
        marketData = {
            customList = rewardFree,
            customGift = goalGift
        }
    }
    if ((not string.isempty(rewardFree) and string.isempty(goalGift)) or isClickChangBtn) then
        GF.OpenWnd("UICumSelectNew", {
            sid = self._sid,
            pageId = pageId,
            entryId = entryId,
            itemIndex = entryId,
            giftData = giftData,
            title = entryCfg.description,
        })
    elseif (itemData) then
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end
    return not string.isempty(rewardFree) and string.isempty(goalGift)
end

function UIActInitPay:InitCommand()
    self:SetWndText(self.mBattleText, ccClientText(15708))
    self:SetWndText(self.mDetailsText, ccClientText(15709))
    -- self:SetWndText(self.mCloseText,ccClientText(15710)) by.lkt
    self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
    local _sid = self:GetWndArg("sid")

    local functionId = self:GetWndArg("functionId")
    local pageId = self:GetWndArg("page")

    if not _sid then
        local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_62)
        if dataList[1] then
            _sid = dataList[1].sid
        else
            return
        end
    end

    --local text = ccClientText(156)
    --if not string.isempty(text) then
    --	self:SetWndText(self.mBuyTipsText, text)
    --	CS.ShowObject(self.mBuyTipsText, true)
    --end

    self._sid = _sid
    gModelActivity:ReqActivityConfigData(_sid)
    self._functionId = functionId
    self._jumpPageId = pageId
    -- self:PlayYuanAni() by.lkt
end

function UIActInitPay:SetHeroImageArr()
    local _showHero = self._showHero
    if not _showHero then
        return
    end

    local _showHeroRefId, _showHeroNamePos = self._showHeroRefId, self._showHeroNamePos
    local _arrIndex = self._arrIndex or 1
    local herosArr = string.split(_showHero, "=")

    local showMode1 = self._showMode1

    local isImg = showMode1 == 1
    local showHeroImage, showHeroImage2 = self.mShowHeroImage, self.mShowHeroImage2
    if isImg then
        local heroArr = string.split(herosArr[_arrIndex], "|")
        CS.ShowObject(showHeroImage, false)
        CS.ShowObject(showHeroImage2, false)
        self:SetWndEasyImage(showHeroImage, heroArr[1], nil, true)
        self:SetWndEasyImage(showHeroImage2, heroArr[2], nil, true)
        local itemCanvasGroup = showHeroImage:GetComponent(typeofCanvasGroup)
        local itemCanvasGroup2 = showHeroImage2:GetComponent(typeofCanvasGroup)
        itemCanvasGroup.alpha = 0
        itemCanvasGroup2.alpha = 0

        if not string.isempty(_showHeroRefId) and not string.isempty(_showHeroNamePos) then
            local heroRefIdsArr = string.split(_showHeroRefId, "=")
            local heroRefId = string.split(heroRefIdsArr[_arrIndex], "|")
            local heroNamePossArr = string.split(_showHeroNamePos, "=")
            local heroNamePos = string.split(heroNamePossArr[_arrIndex], "|")
            self:SetHeroName(showHeroImage, heroRefId[1], heroNamePos[1], showMode1)
            self:SetHeroName(showHeroImage2, heroRefId[2], heroNamePos[2], showMode1)
        end

        self:SpineMove(1, "heroLH", self._moveTime)
        self:SpineMove(2, "heroLH2", self._moveTime)
        if _arrIndex >= #herosArr then
            _arrIndex = 0
        end
        self._arrIndex = _arrIndex + 1
    else
        local pos1 = Vector2.zero
        local pos2 = Vector2.zero
        self:SetHeroName(showHeroImage, herosArr[1], pos1, showMode1)
        CS.ShowObject(showHeroImage, herosArr[1])

        self:SetHeroName(showHeroImage2, herosArr[2], pos2, showMode1)
        CS.ShowObject(showHeroImage2, herosArr[2])
    end


end

function UIActInitPay:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnBattle, function(...)
        self:OnClickBattle()
    end)
    self:SetWndClick(self.mBtnDetails, function(...)
        self:OnClickDetails()
    end)
end

function UIActInitPay:PlayEffEx(trans, eff, key, scaleV3, isDes)
    if (isDes) then
        self:DestroyWndEffectByKey(key)
    end
    self:CreateWndEffect_Ex({
        trans = trans,
        effName = eff,
        effKey = key,
        scale = scaleV3
    })
end
function UIActInitPay:CreateCommonIcon(data)
    local instanceID = data.instanceID
    local trans = data.trans
    local itemType, itemId, itemNum = data.itemType, data.itemId, data.itemNum
    local baseClass = self._uiCommonList[instanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._uiCommonList[instanceID] = baseClass
        baseClass:Create(trans)
    end
    baseClass:SetCommonReward(itemType, itemId, itemNum, 2)
    local showNum = itemNum > 0
    baseClass:EnableShowNum(showNum)
    baseClass:DoApply()
end

function UIActInitPay:OnActivityConfigData()
    local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
    if not activityCfg then
        return
    end
    local data = activityCfg.config
    local showMode1 = data.showMode1
    local pageList = {}
    --背景图,背景图位置,标题,标题背景图,标题位置,广告语,广告语位置,背景大图特效,背景大图特效位置
    local data1 = {}
    data1.showMode1 = showMode1
    data1.image, data1.imagePos, data1.title, data1.titleBg, data1.titlePos, data1.advertisement, data1.advertisementPos, data1.imageEffect, data1.imageEffectPos = data.image, data.imagePos, data.title, data.titleBg, data.titlePos, data.advertisement, data.advertisementPos, data.imageEffect, data.imageEffectPos
    data1.heroLH, data1.heroLHPos = data.heroLH, data.heroLHPos
    data1.titleDesc, data1.titleDescPos, data1.battlePreview, data1.battlePreviewPos, data1.detailsPreview, data1.detailsPreviewPos = data.titleDesc, data.titleDescPos, data.battlePreview, data.battlePreviewPos, data.detailsPreview, data.detailsPreviewPos
    data1.textStr = data.text1
    data1.showTxt = data.showTxt
    data1.showTxtPos = data.showTxtPos
    data1.isRecharge = data.isRecharge1 or 0
    pageList[1] = data1

    local data2 = {}
    data2.showMode1 = showMode1
    data2.image, data2.imagePos, data2.title, data2.titleBg, data2.titlePos, data2.advertisement, data2.advertisementPos, data2.imageEffect, data2.imageEffectPos = data.accImage, data.accImagePos, data.accTitle, data.accTitleBg, data.accTitlePos, data.accAdvertisement, data.accAdvertisementPos, data.accImageEffect, data.accImageEffectPos
    data2.showHero, data2.showHeroPos = data.showHero, data.showHeroPos
    data2.textStr = data.text2
    data2.isRecharge = data.isRecharge2 or 0

    pageList[2] = data2

    local data3 = {}
    data3.showMode1 = showMode1
    data3.image, data3.imagePos, data3.title, data3.titleBg, data3.titlePos, data3.advertisement, data3.advertisementPos, data3.imageEffect, data3.imageEffectPos =
    data.accImage1, data.accImagePos1, data.accTitle1, data.accTitleBg1, data.accTitlePos1, data.accAdvertisement1, data.accAdvertisementPos1, data.accImageEffect1,
    data.accImageEffectPos1
    data3.showHero, data3.showHeroPos = data.showHero2, data.showHeroPos1
    data3.textStr = data.text5
    data3.isRecharge = data.isRecharge3 or 0
    pageList[3] = data3

    local data4 = {}
    data4.showMode1 = showMode1
    data4.image, data4.imagePos, data4.advertisement, data4.advertisementPos =
    data.accImage5, data.accImagePos5, data.accAdvertisement5, data.accAdvertisementPos5
    data4.showHero = data.showHero5
    data4.textStr = data.text9
    data4.isRecharge = data.isRecharge5 or 0
    pageList[5] = data4

    local data5 = {}
    data5.showMode1 = showMode1
    data5.image, data5.imagePos, data5.advertisement, data5.advertisementPos =
    data.accImage6, data.accImagePos6, data.accAdvertisement6, data.accAdvertisementPos6
    data5.showHero = data.showHero6
    data5.textStr = data.text10
    data5.isRecharge = data.isRecharge6 or 0
    pageList[6] = data5

    self._pageList = pageList
    self._selectEffect, self._jump = data.selectEffect, data.jump

    self._exJump = data.exJump
    self._showHeroRefId, self._showHeroNamePos = data.showHeroRefId, data.showHeroNamePos
    self._selectEffect = "ui_fx_zaixianjiangli"
    local heroLHSize = data.heroLHSize
    if heroLHSize then
        self.mHeroImage.localScale = Vector2.New(heroLHSize, heroLHSize)
        self.mHeroSpine.localScale = Vector2.New(heroLHSize, heroLHSize)
    end
    --local tabEffect = data.tabEffect
    --self:PlayEff(self.mPayEff,tabEffect,"btnEff",true)
    local tabIcon = data.tabIcon
    if not string.isempty(tabIcon) then
        local arr = string.split(tabIcon, ";")
        local list = {}
        for i, v in ipairs(arr) do
            local imgArr = string.split(v, "=")
            list[tonumber(imgArr[1])] = imgArr[2]
        end
        self._tabIcon = list
    end

    local tabName = data.tabName
    if not string.isempty(tabName) then
        local arr = string.split(tabName, ";")
        local list = {}
        for i, v in ipairs(arr) do
            local imgArr = string.split(v, "=")
            list[tonumber(imgArr[1])] = imgArr[2]
        end
        self._tabName = list
    end

    local btnPos = data.btnPos
    if not string.isempty(btnPos) then
        local pos = LxDataHelper.ParseVector2NotEmpty(btnPos)
        self:SetAnchorPos(self.mBtnPay, pos)
        --self:SetAnchorPos(self.mPayEff, pos)
    end
    gModelActivity:OnActivityPageReq(self._sid)
end

function UIActInitPay:RefreshForeign()
    if self._isVie then

    end
end

function UIActInitPay:ItemListItem(list, item, itemdata, itempos)
    local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, itemdata.pageId, itemdata.entryId)
    local selImg = self:FindWndTrans(item, "SelImg")
    local titleText = self:FindWndTrans(item, "TitleText")
    local itemScroll = self:FindWndTrans(item, "ItemScroll")
    local customItemScroll = self:FindWndTrans(item, "CustomItemScroll")
    local mask = self:FindWndTrans(item, "Mask")
    local eff = self:FindWndTrans(item, "Eff")

    local InstanceID = item:GetInstanceID()
    local _getDay = self._getDay
    local status = itemdata.goalData.status
    local moreInfo = entryCfg.moreInfo            --领取天数
    local payDay = itemdata.pageId == 1 and self._firstDay or self._allDay
    --local isShowSel = _getDay and _getDay == moreInfo or (moreInfo == payDay or (moreInfo == self._listLen and  payDay > moreInfo))
    local isShowSel = status == 1 and payDay >= moreInfo
    --CS.ShowObject(eff,isShowSel)
    --if isShowSel then
    --	self:PlayEffEx(eff,self._selectEffect,InstanceID, Vector3(165, 115, 100))
    --end

    --
    isShowSel = isShowSel or status == 2
    CS.ShowObject(selImg, isShowSel)
    CS.ShowObject(mask, status == 2)
    self:SetWndText(titleText, LUtil.FormatColorStr(entryCfg.name, isShowSel and "#82461a" or "#a9287c"))

    local rewardFree = entryCfg.rewardFree
    local reward = entryCfg.reward
    local fingerEff = self:FindWndTrans(item, "FingerEff")
    if (not string.isempty(rewardFree)) then
        local freeArr = string.split(rewardFree, "|")
        local rewardArr = string.split(reward, ",")
        local list = {}
        for i, v in ipairs(freeArr) do
            table.insert(list, itemdata)
        end
        for i, v in ipairs(rewardArr) do
            local cloneData = table.clone(itemdata)
            cloneData.isFixedReward = true
            table.insert(list, cloneData)
        end
        local key = customItemScroll:GetInstanceID()
        local uiRankList = self:FindUIScroll(key)
        if uiRankList then
            uiRankList:RefreshList(list)
        else
            uiRankList = self:GetUIScroll(key)
            uiRankList:Create(customItemScroll, list, function(...)
                self:OnCustomRewardCell(...)
            end)
        end

        local fingerEffName = "fx_ui_shou"
        self:CreateWndEffect(fingerEff, fingerEffName, fingerEffName, 100,
                nil, nil,
                nil, nil, nil, nil,
                nil, nil, 1)
    else
        local items = itemdata.items
        local rewardList = LxDataHelper.SevenParseItems(items)
        local uiList1 = self._uiItemList:GetItemCls(InstanceID)
        if not uiList1 then
            uiList1 = UIIconEasyList:New(self)
            self._uiItemList:SetItemCls(InstanceID, uiList1)
            uiList1:Create(self, itemScroll)
            uiList1:SetIconParentPath("Root/CommonUI/Icon")
        end
        uiList1:RefreshList(rewardList)
    end
    local pbData = itemdata
    local goalData = pbData.goalData
    local goalGift = goalData.goalGift
    --CS.ShowObject(fingerEff,(not goalGift or string.isempty(goalGift)) and not string.isempty(rewardFree) and goalData.status == 0)
    CS.ShowObject(fingerEff, (not goalGift or string.isempty(goalGift)) and not string.isempty(rewardFree))
    CS.ShowObject(itemScroll, string.isempty(rewardFree))
    CS.ShowObject(customItemScroll, not string.isempty(rewardFree))
end

-- function UIActInitPay:PlayYuanAni() by.lkt
-- 	local seqTween
-- 	self:TweenSeqKill(self._playKey)
-- 	if not seqTween then
-- 		local showTime = 18
-- 		seqTween = self:TweenSeqCreate(self._playKey,function(seq)
-- 			local moveZ = self.mBgRotate.transform:DORotate(Vector3.New(0,0,180),showTime)
-- 			seq:Append(moveZ)
-- 			return seq
-- 		end)
-- 	end
-- 	seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
-- 	seqTween:PlayForward()
-- 	seqTween:OnComplete(function()
-- 		self:TweenSeqKill(self._playKey)
-- 	end)
-- end
------------------------------------------------------------------
return UIActInitPay


