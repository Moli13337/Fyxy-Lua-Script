---
--- Created by admin.
--- DateTime: 2023/10/26 18:24:18
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSnBookSaga:LChildWnd
local UISubSnBookSaga = LxWndClass("UISubSnBookSaga", LChildWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeUIImage = typeof(UnityEngine.UI.Image)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSnBookSaga:UISubSnBookSaga()
    self._heroImgFrameDefaultPath = "public_frame_4_1"

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSnBookSaga:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSnBookSaga:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSnBookSaga:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:InitBtnEvent()
    self:InitMessage()
end
function UISubSnBookSaga:RefreshHeroList()
    self:RaceBtnEvent(self._raceType, self._raceBtnList[self._raceType])
    self:CareerBtnEvent(self._careerType, self._careerBtnList[self._careerType])
    local refList = self._refDataList
    local tmp = {}
    for i, v in pairs(refList) do
        local heroRef = gModelHero:GetHeroRef(v.heroId)
        local condition1 = heroRef.raceType == self._raceType and heroRef.careerType == self._careerType
        local condition2 = heroRef.raceType == self._raceType and self._careerType == 0
        local condition3 = heroRef.careerType == self._careerType and self._raceType == 0
        local condition4 = self._raceType == 0 and self._careerType == 0
        if (condition1 or condition2 or condition3 or condition4) then
            table.insert(tmp, v)
        end
    end
    table.sort(tmp, function(a, b)
        return a.heroId < b.heroId
    end)

    local _skinBookList = self._uiSkinBookList
    if (_skinBookList) then
        _skinBookList:RefreshList(tmp)
    else
        _skinBookList = self:GetUIScroll("mSkinBookList")
        self._uiSkinBookList = _skinBookList
        _skinBookList:Create(self.mSkinBookList, tmp, function(...)
            self:OnDrawHeroItemCell(...)
        end, UIItemList.SUPER)
    end
    _skinBookList:DrawAllItems()
    local heroListPos = gModelSkinBook:GetSkinListActivityIndex(tmp)

    local hasWaitGuide = gModelGuide:HasWaitGuide()
    if hasWaitGuide then
        heroListPos = 1
    end

    _skinBookList:MoveToPos(heroListPos)
end
function UISubSnBookSaga:OnDrawSkinItemCell(list, item, itemdata, itempos)
    local nameBg = self:FindWndTrans(item, "NameBg")
    local nameBgEn = self:FindWndTrans(item, "NameBgEn")
    local nameTxt = self:FindWndTrans(nameBg, "NameTxt")
    local nameTxtEn = self:FindWndTrans(nameBgEn, "NameTxt")
    local activityBtn = self:FindWndTrans(item, "ActivityBtn")
    local activityTxt = self:FindWndTrans(activityBtn, "ActivityTxt")
    local heroImgMask = self:FindWndTrans(item, "HeroImgMask")
    local heroImgMask2 = self:FindWndTrans(item, "HeroImgMask2")
    local heroImg = self:FindWndTrans(item, "HeroImg")
    local heroImgFrameDefault = self:FindWndTrans(item, "HeroImgFrameDefault")
    local heroImgFrame = self:FindWndTrans(item, "HeroImgFrame")
    local qualityIcon = self:FindWndTrans(item, 'QualityIcon')


    --local heroSkinRef = gModelSkinBook:GetHeroSkinRef()
    local skinRefId = tonumber(itemdata)
    local heroTypeId = math.floor(skinRefId / 100)
    local heroSkinData = gModelHero:GetShowEffectById(skinRefId)
    local skinNameStr = ccLngText(heroSkinData.skinName)
    self:SetWndText(activityTxt, ccClientText(30206)) --30206可激活
    self:SetWndEasyImage(heroImg, heroSkinData.skinIcon)
    local skinEndTime = gModelHero:CheckHeroHadSkin(skinRefId) --检测已激活
    local hadSkin = skinEndTime and skinEndTime == "-1"
    local hasSkinItemId = gModelHero:GetEffectItemId(skinRefId)
    local heroList = gModelHero:GetServerHeroListByRefId(skinRefId)
    local heroListData = self:CheckWearHeroList(heroTypeId) -- 判断是否有该类型的英雄
    local heroListCnt = heroListData.heroListCnt -- 判断是否有该类型的英雄
    local isShowMask = not hadSkin and (not heroList or #heroList == 0) and not hasSkinItemId
    CS.ShowObject(activityBtn, hasSkinItemId and not hadSkin)

    local heroImgFramePath = self._heroImgFrameDefaultPath
    --local isShowQualityIcon = false
    --local quality = heroSkinData.skinQuality
    --if quality and quality > 0 then
    --    local qualityData = gModelItem:GetQualityRef(quality)
    --
    --    --添加图片设置
    --end
    --
    --CS.ShowObject(qualityIcon, isShowQualityIcon)

    local skinQuality = heroSkinData.skinQuality
    if not string.isempty(skinQuality) then
        self:SetWndEasyImage(qualityIcon,skinQuality,function()
            CS.ShowObject(qualityIcon, true)
        end,true)
    else
        CS.ShowObject(qualityIcon, false)
    end

    local isShowDefaultFrameIcon = heroImgFramePath == self._heroImgFrameDefaultPath
    CS.ShowObject(heroImgFrameDefault, isShowDefaultFrameIcon)
    CS.ShowObject(heroImgFrame, not isShowDefaultFrameIcon)

    if LxUiHelper.IsImgPathValid(heroImgFramePath) then
        local frameIconTrans = isShowDefaultFrameIcon and heroImgFrameDefault or heroImgFrame
        self:SetWndEasyImage(frameIconTrans, heroImgFramePath)
    end

    CS.ShowObject(heroImgMask, isShowMask and isShowDefaultFrameIcon)
    CS.ShowObject(heroImgMask2, isShowMask and not isShowDefaultFrameIcon)

    local showBg = not hasSkinItemId or hadSkin
    if gLGameLanguage:IsForeignRegion() then
        CS.ShowObject(nameBg, false)
        CS.ShowObject(nameBgEn, showBg)
        self:SetWndText(nameTxtEn, skinNameStr)
        self:InitTextLineWithLanguage(nameTxtEn, -30)
    else
        CS.ShowObject(nameBg, showBg)
        CS.ShowObject(nameBgEn, false)
        self:SetWndText(nameTxt, skinNameStr)
    end

    self:SetWndClick(item, function()
        if (heroListCnt and heroListCnt > 0) then
            local maxPowerHeroId = heroListData.maxPowerId--最高战力流水ID
            local gotoHeroId = maxPowerHeroId
            gModelGeneral:OpenHeroSkin({ refId = heroTypeId, id = gotoHeroId, gotoSkin = skinRefId })
        else
            gModelGeneral:OpenHeroSkin({ refId = heroTypeId, skinRefId = skinRefId, preview = true })
        end
    end)
    if (hasSkinItemId) then
        self:SetWndClick(activityBtn, function()
            if heroListCnt <= 0 then
                gModelGeneral:OpenHeroSkin({ refId = heroTypeId, skinRefId = skinRefId, preview = true })
                GF.ShowMessage(ccClientText(17420))--17420 您暂未获得该英雄无法激活使用皮肤
            else
                local maxPowerHeroId = heroListData.maxPowerId--最高战力流水ID
                if maxPowerHeroId then
                    local code = 1015 --皮肤激活
                    local itemType = gModelItem:GetType(hasSkinItemId)
                    if (not hadSkin) then
                        gModelItem:GetWndNameByType(itemType, hasSkinItemId, code)
                    else
                        local gotoHeroId = maxPowerHeroId
                        gModelGeneral:OpenHeroSkin({ refId = heroTypeId, id = gotoHeroId, gotoSkin = skinRefId })
                    end
                end
            end
        end)
    end
end

function UISubSnBookSaga:PlayEff(trans, eff, key, isDes, scale)
    if (isDes) then
        self:DestroyWndEffectByKey(key)
    end
    self:CreateWndEffect(trans, eff, key, scale or 100,
            false, false, 0, nil, scale or 100)
end
-- 职业按钮事件 mCareerSelImg
function UISubSnBookSaga:CareerBtnEvent(index, btnTrans)
    self._careerType = index
    gModelSkinBook:CareerType(index)
    self:ChangeSelImgParent(self.mCareerSelImg, btnTrans)
end
function UISubSnBookSaga:ChangeSelImgParent(imgTrans, btnTrans)
    CS.SetParentTrans(imgTrans, btnTrans)
end
-- 种族按钮事件 mRaceSelImg
function UISubSnBookSaga:RaceBtnEvent(index, btnTrans)
    self._raceType = index
    gModelSkinBook:RaceType(index)
    self:ChangeSelImgParent(self.mRaceSelImg, btnTrans)
end
function UISubSnBookSaga:InitMessage()
    self:WndNetMsgRecv(LProtoIds.HeroSkinBookInfoResp, function(pb)
        self.finishSkinRewardInfo = gModelSkinBook:SetFinishRewardInfo(pb)
    end)
end
function UISubSnBookSaga:PlayRaceBtnAni()
    if self.isPlayEffect then
        return
    end
    self.isPlayEffect = not self.isPlayEffect
    local isShow = self._showRaceBtnList
    local moveTrans = self.mRaceTypeBg
    self:TweenSeqKill(self._moveRaceKey)
    local seqTween = self:TweenSeqCreate(self._moveRaceKey, function(seq)
        local showTime = 0.1
        local pos, fromAlpha, toAlpha
        -- 展开
        if isShow then
            pos = 72.2
            fromAlpha, toAlpha = 0, 1
        else
            pos = 0
            fromAlpha, toAlpha = 1, 0
        end
        CS.ShowObject(self.mLine1, not isShow)
        CS.ShowObject(self.mLine2, isShow)
        CS.ShowObject(self.mUnfoldBtn, not isShow)
        local trans = self.mCareerTypeBg
        local Ease = DG.Tweening.Ease.OutCubic
        local vec = Vector2.New(moveTrans.localPosition.x, moveTrans.localPosition.y + pos)
        local tweener = trans:DOLocalMove(vec, showTime)
        seq:Join(tweener)
        local canvasGroup = trans:GetComponent(typeofCanvasGroup)
        if canvasGroup then
            CS.ShowObject(trans, isShow)
            local _temp = YXTween.TweenFloat(fromAlpha, toAlpha, showTime, function(ival)
                canvasGroup.alpha = ival
            end)                 :SetEase(Ease)
            seq:Join(_temp)
        end
        return seq
    end)
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self.isPlayEffect = not self.isPlayEffect
        self:TweenSeqKill(self._moveRaceKey)
    end)
end
function UISubSnBookSaga:SetUI()
    --printInfoNR("-------------UISubSnBookSaga:SetUI()----------------")
    self:SetTopGroup()
    self:RefreshHeroList()

    self:SetWndEasyImage(self.mTitleImg, "heroskin_txt_1", function()
        CS.ShowObject(self.mTitleImg, true)
    end, true, true)
end
function UISubSnBookSaga:InitBtnEvent()
    self:SetWndClick(self.mUnfoldBtn, function()
        -- 展开按钮
        if not self._showRaceBtnList then
            self._showRaceBtnList = true
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mPackBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mShowAllBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    -- 所有种族
    self:SetWndClick(self.mAllRaceBtn, function()
        self._raceType = 0
        gModelSkinBook:RaceType(0)
        self:ChangeSelImgParent(self.mRaceSelImg, self.mAllRaceBtn)
        self:RefreshHeroList()
    end, LSoundConst.CLICK_PAGE_COMMON)
    -- 所有职业
    self:SetWndClick(self.mAllCareerBtn, function()
        self._careerType = 0
        gModelSkinBook:CareerType(0)
        self:ChangeSelImgParent(self.mCareerSelImg, self.mAllCareerBtn)
        self:RefreshHeroList()
    end, LSoundConst.CLICK_PAGE_COMMON)

    local raceBtnList = self._raceBtnList
    for k, v in pairs(raceBtnList) do
        self:SetWndClick(v, function()
            self:RaceBtnEvent(k, v)
            self:RefreshHeroList()
        end, LSoundConst.CLICK_PAGE_COMMON)
    end
    local careerBtnList = self._careerBtnList
    for k, v in pairs(careerBtnList) do
        self:SetWndClick(v, function()
            self:CareerBtnEvent(k, v)
            self:RefreshHeroList()
        end, LSoundConst.CLICK_PAGE_COMMON)
    end
end
function UISubSnBookSaga:CheckWearHeroList(heroRefIde)
    local heroRefIdList = gModelHero:GetServerHeroListByRefId(heroRefIde) -- 判断是否有该类型的英雄
    local maxPowerHeroId = gModelHero:GetRefIdTypeList(heroRefIde)--最高战力流水ID
    return { heroListCnt = #heroRefIdList, maxPowerId = maxPowerHeroId }
end
function UISubSnBookSaga:OnDrawHeroItemCell(list, item, itemdata, itempos)
    local heroNameTxt = self:FindWndTrans(item, "HeroNameTxt")
    local heroHeadIconGroup = self:FindWndTrans(item, "HeroHeadIcon")
    local raceIcon = self:FindWndTrans(heroHeadIconGroup, "Race")
    local heroHeadIcon = self:FindWndTrans(heroHeadIconGroup, "Icon")
    local rewardGroup = self:FindWndTrans(item, "RewardGroup")
    local buyRewardTxt = self:FindWndTrans(rewardGroup, "BuyRewardTxt")
    local rewardItem = self:FindWndTrans(rewardGroup, "RewardItem")
    local rewardMask = self:FindWndTrans(rewardGroup, "OwnMask")
    local progressBar = self:FindWndTrans(rewardGroup, "ProgressBar")
    local progressTxt = self:FindWndTrans(rewardGroup, "ProgressTxt")
    local skinScroll = self:FindWndTrans(item, "SkinScroll")
    local heroRef = gModelHero:GetHeroRef(itemdata.heroId)
    local raceType = heroRef.raceType
    local racePath = gModelHero:GetRaceImgByRefId(raceType)
    self:SetWndEasyImage(raceIcon, racePath)
    local iconPath, iconBgPath = gModelHero:GetHeroIcon(itemdata.heroId, 1, itemdata.heroId)
    self:SetWndEasyImage(heroHeadIcon, iconPath)
    self:SetWndClick(heroHeadIcon, function()
        local heroListData = self:CheckWearHeroList(itemdata.heroId) -- 判断是否有该类型的英雄
        gModelGeneral:OpenHeroSkin({ refId = itemdata.heroId, id = heroListData.maxPowerId })
    end)
    local heroName = gModelHero:GetHeroNameByRefId(itemdata.heroId)
    self:SetWndText(heroNameTxt, heroName)
    local progressBarImg = progressBar:GetComponent(typeUIImage)
    local skinIdList = string.split(itemdata.skinId, ",")
    local curSkinCnt = 0
    local totalSkinCnt = #skinIdList
    local playerSkinList = gModelHero:GetHeroSkinList()
    for i, v in pairs(skinIdList) do
        local skinId = tonumber(v)
        local heroList = gModelHero:GetServerHeroListByRefId(tonumber(v))
        if ((playerSkinList[skinId] and playerSkinList[skinId].endTime == "-1") or (heroList and #heroList > 0)) then
            curSkinCnt = curSkinCnt + 1
        end
    end
    local skinCntStr = string.replace(ccClientText(10249), tostring(curSkinCnt), tostring(totalSkinCnt))
    self:SetWndText(progressTxt, skinCntStr)
    if CS.IsValidObject(progressBarImg) then
        progressBarImg.fillAmount = math.floor(curSkinCnt / totalSkinCnt * 1000) / 1000
    end
    local skinDataList = skinIdList
    --根据子项数量高度适应高度
    local hight = 425 + (302 * (math.ceil(#skinDataList / 3) - 1))
    local v2 = Vector2.New(634, 292 + (302 * (math.ceil(#skinDataList / 3) - 1)))
    skinScroll.sizeDelta = v2
    LxUiHelper.SetSizeWithCurAnchor(item, 1, hight)
    local key = item:GetInstanceID()
    local uiSkinList = self:FindUIScroll(key)
    if uiSkinList then
        uiSkinList:RefreshList(skinDataList)
    else
        uiSkinList = self:GetUIScroll(key)
        uiSkinList:Create(skinScroll, skinDataList, function(...)
            self:OnDrawSkinItemCell(...)
        end)
    end
    uiSkinList:EnableScroll(false)
    self:SetWndText(buyRewardTxt, ccClientText(30200))--30200收集奖励
    local itemRoot = self:FindWndTrans(rewardItem, "itemRoot")
    local root = self:FindWndTrans(itemRoot, "Icon")
    local itemNum = self:FindWndTrans(rewardItem, "itemNum")
    local eff = self:FindWndTrans(rewardItem, "eff")
    local taskData = gModelQuest:GetTaskDataByRefId(itemdata.finishCond)
    local isTaskFinish = gModelQuest:IsTaskFinish(itemdata.finishCond)
    isTaskFinish = isTaskFinish and 2 or 0
    local taskState = taskData and taskData:GetState() or isTaskFinish
    CS.ShowObject(rewardMask, taskState == 2)
    CS.ShowObject(eff, taskState == 1)
    if (taskState == 1) then
        self:PlayEff(eff, "fx_ui_qiandao_lingqutishi", "box" .. key, nil, 65)
    end
    local heroSkinRef = gModelSkinBook:GetHeroSkinRef()
    local cfgReward = heroSkinRef[itemdata.refId].reward
    local reward = {}--gModelQuest:GetRewardList(itemdata.finishCond)
    local rArr = string.split(cfgReward, "|")
    local rewardItemCnt = 0
    for i, v in pairs(rArr) do
        local rData = string.split(rArr[i], "=")
        local vRData = {
            itemType = tonumber(rData[1]),
            itemId = tonumber(rData[2]),
            itemNum = tonumber(rData[3]),
        }
        table.insert(reward, vRData)
        rewardItemCnt = rewardItemCnt + tonumber(rData[3])
    end
    --待后端确定数据下发形式
    local curReward = table.clone(reward[1])
    curReward.itemNum = rewardItemCnt
    if reward and curReward then
        local InstanceID = rewardItem:GetInstanceID()
        local baseClass = self._uiCommonList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New()
            self._uiCommonList[InstanceID] = baseClass
            baseClass:Create(root)
            self:SetIconClickScale(root, true)
        end
        baseClass:SetCommonReward(curReward.itemType, curReward.itemId, curReward.itemNum)
        baseClass:EnableShowNum(false)
        baseClass:DoApply()
        self:SetWndText(itemNum, curReward.itemNum)
        self:SetWndClick(rewardMask, function()
            gModelGeneral:ShowCommonItemTipWnd(curReward)
        end)
        self:SetWndClick(root, function()
            if taskState == 0 then
                gModelGeneral:ShowCommonItemTipWnd(curReward)
            elseif taskState == 1 then
                gModelSkinBook:OpenRewardWnd(reward, self.finishSkinRewardInfo, itemdata)
            end
        end)
    end
end
function UISubSnBookSaga:SetTopGroup()
    local curSkinCnt = 0
    local totalSkinCnt = 0
    local playerSkinList = gModelHero:GetHeroSkinList()
    if self._refDataList then
        for i, v in pairs(self._refDataList) do
            local skinList = string.split(v.skinId, ",")--v.skinId
            for i, v in pairs(skinList) do
                local skinId = tonumber(v)
                local heroList = gModelHero:GetServerHeroListByRefId(tonumber(v))
                if ((playerSkinList[skinId] and playerSkinList[skinId].endTime == "-1") or (heroList and #heroList > 0)) then
                    curSkinCnt = curSkinCnt + 1
                end
                totalSkinCnt = totalSkinCnt + 1
            end
        end
    end

    local skinCntStr = "(" .. curSkinCnt .. "/" .. totalSkinCnt .. ")"
    self:SetWndText(self.mSkinCntTxt, skinCntStr)
end

function UISubSnBookSaga:InitData()
    self._showRaceBtnList = false
    self.isPlayEffect = false
    self._moveRaceKey = "moveRace"
    self._raceType = gModelSkinBook:RaceType() -- 种族
    self._careerType = gModelSkinBook:CareerType()  -- 职业
    self._raceBtnList = {
        self.mRaceBtn1,
        self.mRaceBtn2,
        self.mRaceBtn3,
        self.mRaceBtn4,
        self.mRaceBtn5,
        self.mRaceBtn6,
    }
    for i, v in pairs(self._raceBtnList) do
        local raceRef = GameTable.CharacterRaceRef[i]
        if raceRef then
            local showBtn = raceRef.treasureRaceShow ~= 1
            CS.ShowObject(v, showBtn)
        else
            CS.ShowObject(v, false)
        end
    end
    self._careerBtnList = {
        self.mCareerBtn1,
        self.mCareerBtn2,
        self.mCareerBtn3,
        self.mCareerBtn4,
    }
    self._skinList = {}
    self._uiCommonList = {}
    self._refDataList = self:GetWndArg("refDataList")
    gModelSkinBook:SetHeroBtnRPStatus(false)
    self:SetUI()
    gModelSkinBook:OnHeroSkinBookInfoReq()
end
------------------------------------------------------------------
return UISubSnBookSaga


