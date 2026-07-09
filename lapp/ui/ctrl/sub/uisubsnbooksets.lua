---
--- Created by admin.
--- DateTime: 2023/10/26 20:45:57
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSnBookSets:LChildWnd
local UISubSnBookSets = LxWndClass("UISubSnBookSets", LChildWnd)
local typeUIImage = typeof(UnityEngine.UI.Image)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSnBookSets:UISubSnBookSets()
    self._heroImgFrameDefaultPath = "public_frame_4_1"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSnBookSets:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSnBookSets:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSnBookSets:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:InitMessage()

    gModelSkinBook:GetCollectRewardByRefid(2002)
end
function UISubSnBookSets:OnDrawHeroItemCell(list, item, itemdata, itempos)
    local heroNameTxt = self:FindWndTrans(item, "HeroNameTxt")
    local heroHeadIconGroup = self:FindWndTrans(item, "HeroHeadIcon")
    local heroHeadIcon = self:FindWndTrans(heroHeadIconGroup, "Icon")
    local rewardGroup = self:FindWndTrans(item, "RewardGroup")
    local buyRewardTxt = self:FindWndTrans(rewardGroup, "BuyRewardTxt")
    local rewardItem = self:FindWndTrans(rewardGroup, "RewardItem")
    local rewardMask = self:FindWndTrans(rewardGroup, "OwnMask")
    local progressBar = self:FindWndTrans(rewardGroup, "ProgressBar")
    local progressTxt = self:FindWndTrans(rewardGroup, "ProgressTxt")
    local rewardBox = self:FindWndTrans(rewardGroup, "RewardBox")
    local RewardBoxRedPoint = self:FindWndTrans(rewardBox, "RewardBoxRedPoint")
    local skinScroll = self:FindWndTrans(item, "SkinScroll")
    self:SetWndEasyImage(heroHeadIcon, itemdata.icon)
    self:SetWndText(heroNameTxt, ccLngText(itemdata.name))
    local progressBarImg = progressBar:GetComponent(typeUIImage)
    local skinIdList = gModelSkinBook:GetOpenHeroSkinId(itemdata.skinId)
    local curSkinCnt = 0
    local totalSkinCnt = #skinIdList
    local playerSkinList = gModelHero:GetHeroSkinList()
    for i, skinId in ipairs(skinIdList) do
        if ((playerSkinList[skinId] and playerSkinList[skinId].endTime == "-1")) then
            curSkinCnt = curSkinCnt + 1
        end
    end
    local skinCntStr = string.replace(ccClientText(10249), tostring(curSkinCnt), tostring(totalSkinCnt))
    self:SetWndText(progressTxt, skinCntStr)
    if CS.IsValidObject(progressBarImg) then
        progressBarImg.fillAmount = math.floor(curSkinCnt / totalSkinCnt * 1000) / 1000
    end
    local skinDataList = skinIdList
    local hight = 425 + (302
            * (math.ceil(#skinDataList / 3) - 1))
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
    uiSkinList:DrawAllItems()
    uiSkinList:EnableScroll(false)

    self:SetWndText(buyRewardTxt, ccClientText(30200))--30200收集奖励

    -- 这块奖励部分要修改下
    local skinTaskType = gModelSkinBook:GetHeroSkinTaskTypeBySkinRefId(tonumber(skinDataList[1]))
    CS.ShowObject(RewardBoxRedPoint,gModelSkinBook:CheckShowSkinTaskRewardRedPoint(skinTaskType))


    local reward = {}
    local rewardItemCnt = 0
    local cfgReward = gModelSkinBook:GetCollectRewardByRefid(itemdata.refId)
    for k, v in pairs(cfgReward) do
        table.insert(reward, {
            itemType = tonumber(v.itemType),
            itemId = tonumber(k),
            itemNum = tonumber(v.itemNum),
        })
        rewardItemCnt = rewardItemCnt + v.itemNum
    end


    local isGetAllReward = gModelSkinBook:CheckGetAllRewardBySkinType(skinTaskType)
    local boxImg = isGetAllReward and "quest_icon_box_2" or "quest_icon_box_1"
    self:SetWndEasyImage(rewardBox, boxImg, nil, true)
    self:SetWndClick(rewardBox, function()
        --GF.OpenWnd("UIringBoxDetail", { rewardBox, rewardList ,true})
        GF.OpenWnd("UISagaSkinTask",{skinTaskType = skinTaskType})
    end)
end

function UISubSnBookSets:InitMessage()

    gModelHero:OnHeroSkinListReq()
    self:WndNetMsgRecv(LProtoIds.HeroSkinBookInfoResp, function(pb)
        self.finishSkinRewardInfo = gModelSkinBook:SetFinishRewardInfo(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSkinUseResp, function(...)
        self:OnHeroSkinUseResp(...)
        self:SetUI()
    end)
    self:WndNetMsgRecv(LProtoIds.QuestListResp, function(...)
        self:OnQuestReceiveResp(...)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSkinListResp, function(...)
        self:OnHeroSkinListResp()
    end)
    self:WndEventRecv(EventNames.REFRESH_SKIN_INFO, function()
        self:RefreshHeroList()
    end)
end

function UISubSnBookSets:OnHeroSkinUseResp()
    self:RefreshHeroList()
end

function UISubSnBookSets:OnQuestReceiveResp()
    FireEvent(EventNames.REFRESH_SKIN_INFO)
    --self:RefreshHeroList()

end

function UISubSnBookSets:OnHeroSkinListResp()
    self:RefreshHeroList()
end

function UISubSnBookSets:SetUI()
    self:SetTopGroup()
    self:RefreshHeroList()

    self:SetWndEasyImage(self.mTitleImg, "heroskin_txt_2", function()
        CS.ShowObject(self.mTitleImg, true)
    end, true, true)
end
function UISubSnBookSets:CheckWearHeroList(heroRefIde)
    local heroRefIdList = gModelHero:GetServerHeroListByRefId(heroRefIde) -- 判断是否有该类型的英雄
    local maxPowerHeroId = gModelHero:GetRefIdTypeList(heroRefIde)--最高战力流水ID
    return { heroListCnt = #heroRefIdList, maxPowerId = maxPowerHeroId }
end

function UISubSnBookSets:RefreshHeroList()
    if GF.FindFirstWndByName("UISkinUpOpt") then
        return
    end
    local refList = self._refDataList
    local _skinBookList = self._uiSkinBookList
    if (_skinBookList) then
        _skinBookList:RefreshData(refList)
    else
        _skinBookList = self:GetUIScroll("mSkinBookList")
        self._uiSkinBookList = _skinBookList
        _skinBookList:Create(self.mSkinBookList, refList, function(...)
            self:OnDrawHeroItemCell(...)
        end, UIItemList.SUPER)
        _skinBookList:EnableScroll(true, false)
    end
    _skinBookList:DrawAllItems()
    if not self._notInit then
        self._notInit = true
        local heroListPos = gModelSkinBook:GetSkinListActivityIndex(refList)
        local hasWaitGuide = gModelGuide:HasWaitGuide()
        if hasWaitGuide then
            heroListPos = 1
        end

        _skinBookList:MoveToPos(heroListPos)
    end
end

function UISubSnBookSets:InitData()
    self._skinList = {}
    self._uiCommonList = {}
    self._refDataList = self:GetWndArg("refDataList")
    self._isForeignVersion = gLGameLanguage:IsForeignVersion()
    self:SetUI()
    gModelSkinBook:OnHeroSkinBookInfoReq()
end
function UISubSnBookSets:SetTopGroup()
    local curSkinCnt = 0
    local totalSkinCnt = 0
    local playerSkinList = gModelHero:GetHeroSkinList()
    for i, v in pairs(self._refDataList) do
        local skinList = gModelSkinBook:GetOpenHeroSkinId(v.skinId)
        for idx, skinId in ipairs(skinList) do
            if playerSkinList[skinId] then
                curSkinCnt = curSkinCnt + 1
            end
            totalSkinCnt = totalSkinCnt + 1
        end
    end
    local skinCntStr = "(" .. curSkinCnt .. "/" .. totalSkinCnt .. ")"
    self:SetWndText(self.mSkinCntTxt, skinCntStr)
end
function UISubSnBookSets:OnDrawSkinItemCell(list, item, itemdata, itempos)
    if tonumber(itemdata) == 370503 then
        printInfoN2("UISubSnBookSets---nai niu ", itemdata)

    end

    local nameBg = self:FindWndTrans(item, "NameBg")
    local nameTxt = self:FindWndTrans(nameBg, "NameTxt")
    local nameBgEn = self:FindWndTrans(item, "NameBgEn")
    local nameTxtEn = self:FindWndTrans(nameBgEn, "NameTxtEn")
    local activityBtn = self:FindWndTrans(item, "ActivityBtn")
    local activityTxt = self:FindWndTrans(activityBtn, "ActivityTxt")
    local heroImgMask = self:FindWndTrans(item, "HeroImgMask")
    local heroImgMask2 = self:FindWndTrans(item, "HeroImgMask2")
    local StarGroup = self:FindWndTrans(item, "StarGroup")
    local UpStarIcon = self:FindWndTrans(item, "UpStarIcon")
    local heroImg = self:FindWndTrans(item, "HeroImg")
    local heroImgFrameDefault = self:FindWndTrans(item, "HeroImgFrameDefault")
    local heroImgFrame = self:FindWndTrans(item, "HeroImgFrame")
    local qualityIcon = self:FindWndTrans(item, 'QualityIcon')
    local Button = self:FindWndTrans(item, 'Button')
    local ButtonText = self:FindWndTrans(Button, 'UIText')
    local RewardItem = self:FindWndTrans(item, 'RewardItem')

    local skinRefId = tonumber(itemdata)
    local heroTypeId = math.floor(skinRefId / 100)
    local heroSkinData = gModelHero:GetShowEffectById(skinRefId)
    local isForeignVersion = self._isForeignVersion
    local nameTxtTrans = isForeignVersion and nameTxtEn or nameTxt
    --local quality = nil

    --拿对应的任务信息
    --local quests = gModelSkinBook:GetQuestIdBySkinId(skinRefId)
    --
    --local taskState = gModelSkinBook:GetTaskState(quests.questId)
    --local cfgReward = gModelSkinBook:GetCollectRewardAndQuestByRefidAndIndex(quests.heroSkinRef.refId, quests.index)
    --local reward = {}
    --local rewardItemCnt = 0
    printInfoN2("cjh----------getData", "get--OK")

    self:InitTextLineWithLanguage(nameTxtTrans, -30)
    self:SetWndText(activityTxt, ccClientText(30206)) --30206可激活

    local skinEndTime = gModelHero:CheckHeroHadSkin(skinRefId) --检测已激活
    local hadSkin = skinEndTime and skinEndTime == "-1"
    local hasSkinItemId = gModelHero:GetEffectItemId(skinRefId)
    local heroList = gModelHero:GetServerHeroListByRefId(skinRefId)
    local heroListData = self:CheckWearHeroList(heroTypeId) -- 判断是否有该类型的英雄
    local heroListCnt = heroListData.heroListCnt -- 判断是否有该类型的英雄

    local isShowQualityIcon = false
    local heroImgFramePath = heroSkinData.skinIcon
    local skinInfo = gModelHero:GetHeroSkinInfoByRefId(skinRefId)

    --if quality and quality > 0 then
    --    local qualityData = gModelItem:GetQualityRef(quality)
    --
    --    --添加图片设置
    --end
    --
    --CS.ShowObject(qualityIcon, isShowQualityIcon)

    local skinQuality = heroSkinData and heroSkinData.skinQuality
    if not string.isempty(skinQuality) then
        self:SetWndEasyImage(qualityIcon, skinQuality, function()
            CS.ShowObject(qualityIcon, true)
        end, true)
    else
        CS.ShowObject(qualityIcon, false)
    end

    local isShowDefaultFrameIcon = heroImgFramePath == self._heroImgFrameDefaultPath
    CS.ShowObject(heroImgFrameDefault, isShowDefaultFrameIcon)
    CS.ShowObject(heroImgFrame, not isShowDefaultFrameIcon)

    if LxUiHelper.IsImgPathValid(heroImgFramePath) then
        local frameIconTrans = isShowDefaultFrameIcon and heroImgFrameDefault or heroImgFrame
        self:SetWndEasyImage(frameIconTrans, heroImgFramePath, function()
            CS.ShowObject(frameIconTrans, true)
        end)
    end

    local isShowMask = not hadSkin and (not heroList or #heroList == 0) and not hasSkinItemId

    local showMask = isShowMask and isShowDefaultFrameIcon
    local showMask2 = isShowMask and not isShowDefaultFrameIcon
    CS.ShowObject(heroImgMask, showMask)
    CS.ShowObject(heroImgMask2, showMask2)

    if heroSkinData then
        local showBlack = showMask or showMask2
        self:SetWndText(nameTxtTrans, ccLngText(heroSkinData.skinName))
        local iconBig = heroSkinData.iconBig
        if showBlack then
            iconBig = gModelHeroExtra:GetShieldIconBig(iconBig,heroSkinData)
        end
        self:SetWndEasyImage(heroImg, iconBig, function()
            CS.ShowObject(heroImg, true)
        end, true)
        --quality = heroSkinData.skinQuality
    end

    CS.ShowObject(activityBtn, hasSkinItemId and not hadSkin)
    CS.ShowObject(StarGroup, not isShowMask and hadSkin)
    CS.ShowObject(nameBg, (not hasSkinItemId or hadSkin) and not isForeignVersion)
    CS.ShowObject(nameBgEn, (not hasSkinItemId or hadSkin) and isForeignVersion)
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

    CS.ShowObject(RewardItem, false)
    CS.ShowObject(Button, false)
    CS.ShowObject(UpStarIcon,false)
    if not isShowMask and hadSkin then
        -- 新版皮肤图鉴界面弃用
        CS.ShowObject(heroImgMask2, false)
        CS.ShowObject(RewardItem, false)
        CS.ShowObject(Button, false)
        --self:SetWndText(ButtonText, ccClientText(16207))  --可領取

        --for k, v in pairs(cfgReward) do
        --    table.insert(reward, {
        --        itemType = tonumber(v.itemType),
        --        itemId = tonumber(k),
        --        itemNum = tonumber(v.itemNum),
        --    })
        --    rewardItemCnt = rewardItemCnt + v.itemNum
        --end

        local starLevel = skinInfo.starLevel
        for i = 1, 5 do
            local starTrans = self:FindWndTrans(StarGroup, "Star"..i)
            CS.ShowObject(starTrans, starLevel >= i)
        end
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(StarGroup)

        local isMaxStar = skinInfo.starLevel >= 5
        local canUpStar = false
        local Comsume = gModelSkinBook:GetSkinUpStarComsumeByRefId(skinInfo.starRefId)
        if Comsume then
            local first = Comsume[1]
            local haveNum = gModelItem:GetNumByRefId(ModelItem.ITEM_SKIN_DEBRIS) -- 皮肤碎片
            if haveNum >= first.itemNum then
                canUpStar = true
            end
        end
        CS.ShowObject(UpStarIcon, not isMaxStar and canUpStar)
    else
    end
end
function UISubSnBookSets:PlayEff(trans, eff, key, isDes, scale)
    if (isDes) then
        self:DestroyWndEffectByKey(key)
    end
    self:CreateWndEffect(trans, eff, key, scale or 100,
            false, false, 0, nil, scale or 100)
end
------------------------------------------------------------------
return UISubSnBookSets


