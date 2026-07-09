---
--- Created by LCM.
--- DateTime: 2024/3/1 19:50:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellHRew:LWnd
local UIYellHRew = LxWndClass("UIYellHRew", LWnd)

UIYellHRew.VIEW_CALL_EXTRACTTYPE = 1  -- 通过召唤类型打开
UIYellHRew.VIEW_CALL_REFID = 2        -- 通过召唤RefId打开
UIYellHRew.VIEW_TIME_TREASURE = 3     -- 幸运魔轮
UIYellHRew.VIEW_FIND_TREASURE = 4     -- 灵物遗迹
UIYellHRew.VIEW_ACTIVITY_CALL = 5     -- 活动召唤
UIYellHRew.VIEW_PETDREAMLAND_CALL = 6 -- 萌宠幻境
UIYellHRew.VIEW_HERO_TRANSFORM = 7    -- 英雄转换
UIYellHRew.VIEW_SHOP = 8                             -- 商店

UIYellHRew.SHOWSPECIALBTNLIST = {
    [UIYellHRew.VIEW_TIME_TREASURE] = true
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellHRew:UIYellHRew()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellHRew:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellHRew:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellHRew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isJapaness = gLGameLanguage:IsJapanVersion()

    if self._isJapaness then
        self:InitTextSizeWithLanguage(self.mRuleTxt, -2)
        self:InitTextLineWithLanguage(self.mRuleTxt, -50)
    end

    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshView()
end

function UIYellHRew:InitActivityCallData()
    self._sid = self:GetWndArg("sid")
    self._jackpotId = self:GetWndArg("jackpotId")
    self._policyTxt = self:GetWndArg("policyTxt")
    self._specialTxt = self:GetWndArg("specialTxt")

    if self._sid and self._jackpotId then
        gModelActivity:OnActivityPageReq(self._sid)
    end
end

function UIYellHRew:InitLandCall()
    self._lotteryType = self:GetWndArg("lotteryType")
end

function UIYellHRew:RefreshView()
    self:RefreshShowSpecialHelpBtn()
    local viewType = self._viewType
    if viewType== UIYellHRew.VIEW_SHOP then
        CS.ShowObject(self.mPrivate2,true)
    else
        CS.ShowObject(self.mPrivate2,false)
    end
    if viewType == UIYellHRew.VIEW_CALL_EXTRACTTYPE then
        self:RefreshExtractView()
    elseif viewType == UIYellHRew.VIEW_HERO_TRANSFORM then
        self:RefreshHeroTransformView()
    elseif viewType == UIYellHRew.VIEW_CALL_REFID then
        self:RefreshRefIdView()
    elseif viewType == UIYellHRew.VIEW_TIME_TREASURE then
        self:RefreshTimeTreasureView()
    elseif viewType == UIYellHRew.VIEW_FIND_TREASURE then
        self:RefreshFindTreasureView()
    elseif viewType == UIYellHRew.VIEW_ACTIVITY_CALL then
        self:RefreshActivityCallView()
    elseif viewType == UIYellHRew.VIEW_PETDREAMLAND_CALL then
        self:RefreshPetDreamLandCallView()
    elseif viewType == UIYellHRew.VIEW_SHOP then
        self:RefreshShopView()
    end
end

function UIYellHRew:InitFindTreasureData()

end

function UIYellHRew:InitFindTreasureRuleText()
    local ruleStr = ccClientText(19422)
    local textList = {}
    local refId = 3010
    local ref = GameTable.SummonTextRef[refId]
    if ref then
        ruleStr = ccClientText(ref.text)
        local specialExplain = string.split(ref.specialExplain, ",")
        for idx, val in ipairs(specialExplain) do
            table.insert(textList, {
                str = ccClientText(tonumber(val)),
            })
        end
    end

    self:SetRuleDivText(ruleStr)
    self:InitExplainList(textList)
end

function UIYellHRew:OnDrawRuleMoreNewCell(list, item, itemdata, itempos)
    local StarDesc = self:FindWndTrans(item, "TopDiv/StarDesc")
    local InRuleList = self:FindWndTrans(item, "InRuleList")
    self:SetWndText(StarDesc, itemdata.showKindStr)
    self:CreateInRuleList(InRuleList, itemdata.jackpotList)
end

function UIYellHRew:GetHeroList(itemdata)
    local list = self:GetCommonHeroList(itemdata)
    return list
end

function UIYellHRew:GetPetDreamLandCall()
    local refs = gModelPetDreanLand:GetPetDreamLandRuleList(self._lotteryType)
    if not refs or #refs < 1 then return {} end
    local list = {}
    for i, v in ipairs(refs) do
        table.insert(list, {
            refId = v.refId,
            rewardList = v.showReward,
            probabilityStr = v.num,
            show = not string.isempty(v.num),
        })
    end
    return list
end
function UIYellHRew:InitShopList()
    CS.ShowObject(self.mRuleMoreListShop,true)
    local list = self:GetRuleNormalList()

    local mRuleMoreListShop = self._mRuleMoreListShop
    if mRuleMoreListShop then
        mRuleMoreListShop:RefreshList(list)
    else
        mRuleMoreListShop = self:GetUIScroll("uiRuleNormalList")
        self._mRuleMoreListShop = mRuleMoreListShop
        mRuleMoreListShop:Create(self.mRuleMoreListShop,list,function(...) self:OnDrawShopCell(...) end)
    end
    mRuleMoreListShop:EnableScroll(true)
end

function UIYellHRew:RefreshHeroTransformView()
    self:InitRuleTxt()
    self:InitRuleList()
end

function UIYellHRew:RefreshPetDreamLandCallView()
    local ruleStr = ccClientText(27823)
    self:SetRuleDivText(ruleStr)
    local textList = {}
    --[[
    --- 2024/7/31:改为 27862~27865
    --- 修改为帮助文本 176
    local ref = GameTable.SupportTipsRef[176]
    table.insert(textList,{
        str = ccLngText(ref.text),
    })]]

    for i = 27872, 27875 do
        table.insert(textList, {
            str = ccClientText(i)
        })
    end
    self:InitExplainList(textList)
    self:InitRuleNormalList()
end

function UIYellHRew:GetTimeTreasureViewRuleList()
    local list = {}
    if self._curMagicWheelType then
        local itemList = gModelCallHero:GetMagicWheelExplainRefByType(self._curMagicWheelType)
        if itemList then
            local rewardList
            for k, v in pairs(itemList) do
                if v.reward then
                    rewardList = self:GetCommonRewardList(v.reward)
                    table.insert(list, {
                        refId = v.refId,
                        rewardList = rewardList,
                        probability = v.num / 10000,
                        show = v.show == 1
                    })
                end
            end
        end
        if #list > 0 then
            table.sort(list, function(a, b)
                return a.refId < b.refId
            end)
        end
    end
    return list
end

function UIYellHRew:OnDrawRuleCell(list, item, itemdata, itempos)
    local UITextTrans = self:FindWndTrans(item, "Top/UIText")
    local HeroListTrans = self:FindWndTrans(item, "HeroList")

    local list = {}
    local strTitle = ""
    if self._viewType == UIYellHRew.VIEW_HERO_TRANSFORM then
        local ref = GameTable.CharacterRaceRef[itemdata.type]
        strTitle = ccLngText(ref.name)
        list = itemdata.list
    else
        strTitle = ccLngText(itemdata.title)
        list = itemdata
    end
    self:SetWndText(UITextTrans, strTitle)
    self:InitHeroList(HeroListTrans, list)
end

function UIYellHRew:OnDrawShopCell(list,item,itemdata,itempos)
    local TopDiv = self:FindWndTrans(item,"TopDiv")
    local StarDesc = self:FindWndTrans(item,"TopDiv/StarDesc")
    local InRuleList = self:FindWndTrans(item,"InRuleList")

    local ref = itemdata[1]

    self:SetWndText(StarDesc,ccLngText(ref.listName))
    self:CreateInRuleList(InRuleList,itemdata)
end

function UIYellHRew:InitExtractData()
    self._extractType = self:GetWndArg("extractType")
end

function UIYellHRew:CreateCommonHero(item, itemdata)
    local IconTrans = self:FindWndTrans(item, "CommonUI/Icon")
    local ProbabilityTxtTrans = self:FindWndTrans(item, "ProbabilityTxt")
    local ProbabilityTxtTrans2 = self:FindWndTrans(item, "ProbabilityTxt2")
    local DiscountImg = self:FindWndTrans(item,"DiscountImg")
    local text1 = self:FindWndTrans(DiscountImg,"text")

    local itemType, itemId, itemNum
    local show = false
    local str = ""
    local reward = itemdata.rewardList or itemdata
    if self._viewType == UIYellHRew.VIEW_HERO_TRANSFORM then
        itemType = 2
        itemId = itemdata.ref.getHero
        itemNum = 0
        show = true
        str =  math.round(itemdata.ref.rate / itemdata.totalRate * 100, 2 ) .. "%"
    elseif self._viewType == UIYellHRew.VIEW_SHOP and self._curShopId == 1007 then
        reward = LUtil.GetRefItemData(itemdata.reward)
        itemType, itemId, itemNum = reward.itemType, reward.itemId, reward.itemNum

        local WeightShopNum = 0
        local num = 0
        for k,v in pairs(GameTable.StoreRandomRef) do
            if v.type == itemdata.type then
                WeightShopNum = WeightShopNum + v.weightShow
            end
        end
        num = itemdata.weightShow / WeightShopNum
        str = (math.floor(num * 10000000) /10000000) * 100 .. "%"
        local discountCfg = itemdata.fixDiscount
        local text = ccLngText(discountCfg)
        if text ~= "" then
            CS.ShowObject(DiscountImg,true)
            self:SetWndText(text1,text)

        else
            CS.ShowObject(DiscountImg,false)
        end
        CS.ShowObject(ProbabilityTxtTrans2,true)
        self:SetWndText(ProbabilityTxtTrans2, str)
    else
        --local reward = itemdata.rewardList or itemdata
        itemType, itemId, itemNum = reward.itemType, reward.itemId, reward.itemNum
        show = itemdata.show or true
        if show then
            local probability = itemdata.probability
            if probability then
                --保留5位小数
                str = (math.floor(probability * 10000000) / 10000000) * 100 .. "%"
            else
                str = itemdata.probabilityStr
            end
            if probability==nil then
                local WeightShopNum = 0
                local num = 0
                for k,v in pairs(GameTable.StoreRandomRef) do
                    if v.type == itemdata.type then
                        WeightShopNum = WeightShopNum + v.weightShow
                    end
                end

                local weightShow = itemdata.weightShow
                if weightShow and weightShow > 0 then
                    num = weightShow / WeightShopNum
                    str =  math.round(num * 100, 5 ) .. "%"
                end

                if itemdata.fixDiscount then
                    CS.ShowObject(DiscountImg,true)
                    self:SetWndText(text1,ccLngText(itemdata.fixDiscount))
                else
                    CS.ShowObject(DiscountImg,false)
                end
            end
        end
    end

    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemType, itemId, itemNum)
    baseClass:EnableShowNum(itemNum > 0)
    baseClass:SetNoShowLv(true)
    baseClass:DoApply()

    self:SetIconClickScale(IconTrans, true)

    self:SetWndClick(IconTrans, function()
        if self._callRefId == ModelCallHero.CALL_TYPE_PREPARE then
            -- local heroRef = gModelHero:GetHeroRef(itemId)
            -- local heroStar = heroRef.initStar
            -- GF.OpenWndTop("UINewSagaStarPre", {
            --     refId = itemId,
            --     nextStar = heroStar,
            --     showType = 2,
            --     hideAwaken = true
            -- })
            -- return
        end

        if itemType == 2 then
            gModelGeneral:OpenHeroSimpleTip(itemId, true)
        elseif itemType == 3 then
            gModelGeneral:OpenEquipInfoTip(itemId, nil, nil, true)
        else
            gModelGeneral:ShowCommonItemTipWnd(reward)
        end
    end)
    self:SetWndText(ProbabilityTxtTrans, str)
    CS.ShowObject(ProbabilityTxtTrans, show)
end

function UIYellHRew:GetIntegralGetList()
    local list = {}
    local curMagicWheelType = self._curMagicWheelType
    if curMagicWheelType == ModelCallHero.LUCKY then       -- 幸运魔轮
        list = gModelCallHero:GetLuckMagicWheelLuckyRef()
    elseif curMagicWheelType == ModelCallHero.MIRACLE then -- 奇迹魔轮
        list = gModelCallHero:GetMiracleMagicWheelLuckyRef()
    end
    return list
end

function UIYellHRew:OnClickSpecialHelpBtnFunc()
    local viewType = self._viewType
    if viewType == UIYellHRew.VIEW_TIME_TREASURE then
        self:DisposeFindTreasureHelpBtnFunc()
    end
end

function UIYellHRew:OnActivityPageResp(pb)
    if self._sid ~= pb.sid then return end
    local model = gModelActivity:GetActivityModeIdBySid(self._sid)
    if not model then return end
    -- if model == ModelActivity.LIMIT_CALL then
    --     self:DisposeLimitCallActivityPage(pb)
    -- end
end

function UIYellHRew:InitExplainList(list)
    local isEmpty = list == nil or #list == 0
    CS.ShowObject(self.mExplain, not isEmpty)

    local height = isEmpty and 690 or 850
    local width = self.mBg.rect.width
    self.mBg.sizeDelta = Vector2.New(width, height)
    if isEmpty then return end

    list = list or {}
    local uiExplainList = self._uiExplainList
    if uiExplainList then
        uiExplainList:RefreshList(list)
    else
        uiExplainList = self:GetUIScroll("uiExplainList")
        self._uiExplainList = uiExplainList
        uiExplainList:Create(self.mExplainList, list, function(...) self:OnDrawExplainCell(...) end, UIItemList.WRAP)
    end

    local isShow = not table.isempty(list)
    CS.ShowObject(self.mExplain, isShow)
end

function UIYellHRew:GetRuleMoreList()
    local list = {}
    local viewType = self._viewType
    if viewType == UIYellHRew.VIEW_CALL_REFID then
        list = self:GetCallRefidRuleList()
        --[[
    ---- 后续重新开发，可用 ItemTemplate11
    elseif viewType == UIYellHRew.VIEW_TIME_TREASURE then
        list = self:GetTimeTreasureViewRuleList()
    elseif viewType == UIYellHRew.VIEW_FIND_TREASURE then
        list = self:GetFindTreasureViewRuleList()
        ]]
    end
    return list
end

function UIYellHRew:InitTimeTreasureRuleText()
    local ruleStr = ccClientText(14618)

    local textList = {}
    local curMagicWheelType = self._curMagicWheelType
    if curMagicWheelType then
        local refId = curMagicWheelType == ModelCallHero.LUCKY and 2010 or 2020
        local ref = GameTable.SummonTextRef[refId]
        if ref then
            ruleStr = ccClientText(ref.text)
            local specialExplain = string.split(ref.specialExplain, ",")
            for idx, val in ipairs(specialExplain) do
                table.insert(textList, {
                    str = ccClientText(tonumber(val)),
                })
            end
        end
    end

    self:SetRuleDivText(ruleStr)
    self:InitExplainList(textList)
end

function UIYellHRew:GetHeroTransformRuleList()
    local map = {}
    for _, v in pairs(GameTable.CharacterChangePondRef) do
        local strList = string.split(v.condition, "=")
        local _type = tonumber(strList[1])
        local star = tonumber(strList[2])
        if not map[_type] then
            map[_type] = {}
        end
        if not map[_type][star] then
            map[_type][star] = {}
            map[_type][star].rate = 0
            map[_type][star].star = star
            map[_type][star].list = {}
        end
        map[_type][star].rate = map[_type][star].rate + v.rate
        table.insert(map[_type][star].list, v)
        table.sort(map[_type][star].list, function(a, b)
            return a.refId < b.refId
        end)
    end
    local list = {}

    local function Sort(a, b)
        return a.sort < b.sort
    end

    for type, tab in pairs(map) do
        local list2 = {}
        for _, v in pairs(tab) do
            table.insert(list2, v)
            table.sort(v, Sort)
        end
        table.insert(list, { type = type, list = list2 })
    end
    table.sort(list, function(a, b)
        return a.type < b.type
    end)

    return list
end

function UIYellHRew:GetCommonRewardList(str)
    return LxDataHelper.ParseItem_3(str)
end

function UIYellHRew:InitRuleList()
    CS.ShowObject(self.mRuleList, true)
    local list = self:GetRuleList()
    local uiRuleList = self._uiRuleList
    if uiRuleList then
        uiRuleList:RefreshList(list)
    else
        uiRuleList = self:GetUIScroll("uiRuleList")
        self._uiRuleList = uiRuleList
        uiRuleList:Create(self.mRuleList, list, function(...) self:OnDrawRuleCell(...) end)
    end
    uiRuleList:EnableScroll(true)
end

function UIYellHRew:GetRuleNormalList()
    local viewType = self._viewType
    if viewType == UIYellHRew.VIEW_TIME_TREASURE then
        return self:GetTimeTreasureViewRuleList()
    elseif viewType == UIYellHRew.VIEW_FIND_TREASURE then
        return self:GetFindTreasureViewRuleList()
    elseif viewType == UIYellHRew.VIEW_PETDREAMLAND_CALL then
        return self:GetPetDreamLandCall()
    elseif viewType == UIYellHRew.VIEW_CALL_REFID and
        self._callRefId == ModelCallHero.CALL_TYPE_REGRESSION then
        return self:GetRegressionCallRuleList()
    elseif viewType == UIYellHRew.VIEW_SHOP then
        return self:GetShopList()
    end
    return {}
end

function UIYellHRew:InitData()
    local viewType = self:GetWndArg("viewType")
    if not viewType then
        viewType = UIYellHRew.VIEW_CALL_EXTRACTTYPE
    end
    self._viewType = viewType

    if viewType == UIYellHRew.VIEW_CALL_EXTRACTTYPE then
        self:InitExtractData()
    elseif viewType == UIYellHRew.VIEW_HERO_TRANSFORM then
        self:InitExtractData()
    elseif viewType == UIYellHRew.VIEW_CALL_REFID then
        self:InitRefIdData()
    elseif viewType == UIYellHRew.VIEW_TIME_TREASURE then
        self:InitTimeTreasureData()
    elseif viewType == UIYellHRew.VIEW_FIND_TREASURE then
        self:InitFindTreasureData()
    elseif viewType == UIYellHRew.VIEW_ACTIVITY_CALL then
        self:InitActivityCallData()
    elseif viewType == UIYellHRew.VIEW_PETDREAMLAND_CALL then
        self:InitPetDreamLandCall()
    elseif viewType == UIYellHRew.VIEW_SHOP then
        self:InitShopData()
    end
end

function UIYellHRew:RefreshShopView()
    local ruleStr = ccClientText(27823)
    self:SetRuleDivText(ruleStr)
    local ref = 1001
    if self._curShopId==1001 then
        ref = GameTable.SupportTipsRef[901]
        self:InitRuleNormalList()
    elseif self._curShopId==1007 then
        ref = GameTable.SupportTipsRef[903]
        self:InitShopList()
    elseif self._curShopId==1005 then
        ref = GameTable.SupportTipsRef[902]
        self:InitRuleNormalList()
    end
    self:SetWndText(self.mRuleTxt2,ccLngText(ref.text))
    --self:InitRuleNormalList()
    --self:InitShopList()
end

function UIYellHRew:InitPetDreamLandCall()
    self._lotteryType = self:GetWndArg("lotteryType")
end

function UIYellHRew:InitEvent()
    self:SetWndClick(self.mMask, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mSpecialHelpBtn, function() self:OnClickSpecialHelpBtnFunc() end)
end

function UIYellHRew:OnDrawRuleMoreCell(list, item, itemdata, itempos)
    self:CreateCommonHero(item, itemdata)
end

function UIYellHRew:RefreshExtractView()
    self:InitRuleTxt()
    self:InitRuleList()
end

function UIYellHRew:GetRuleList()
    local list = {}
    local viewType = self._viewType
    if viewType == UIYellHRew.VIEW_CALL_EXTRACTTYPE then
        list = self:GetCallExtractTypeRuleList()
    elseif viewType == UIYellHRew.VIEW_HERO_TRANSFORM then
        list = self:GetHeroTransformRuleList()
    end
    return list
end

function UIYellHRew:OnDrawExplainCell(list, item, itemdata, itempos)
    local UITextTrans = self:FindWndTrans(item, "DescDiv/UIText")
    self:SetWndText(UITextTrans, itemdata.str)
end

function UIYellHRew:InitHeroList(trans, itemdata)
    local list = {}
    if self._viewType == UIYellHRew.VIEW_HERO_TRANSFORM then
        for k, v in ipairs(itemdata) do
            local showKindStr = ccClientText(27802, v.star)
            local jackpotList = {}
            for _, j in ipairs(v.list) do
                table.insert(jackpotList, {ref = j, totalRate = v.rate})
            end

            table.insert(list, {showKindStr = showKindStr, jackpotList = jackpotList})
        end
    else
        list = self:GetHeroList(itemdata)
    end
    if gLGameLanguage:IsKoreaRegion() then
        local allProbability = 0
        for k, v in ipairs(list) do
            allProbability = allProbability + v.probability
        end

        if not self._allProbabilityList then
            self._allProbabilityList = {}
        end

        local callRefId = itemdata.callRefId
        self._allProbabilityList[callRefId] = allProbability
    end

    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...) self:OnDrawHeroCell(...) end)
    end
    uiList:EnableScroll(false)
end

function UIYellHRew:GetRegressionCallRuleList()
    local list = {}
    local callRef = GameTable.SummonRef[self._callRefId]
    if not callRef then return list end
    for k, v in pairs(GameTable.SummonJackpotRef) do
        if v.jackpotId == callRef.jackpotId then
            table.insert(list, {
                -- callRefId = self._callRefId,
                sort = v.sort,
                refId = v.refId,
                rewardList = self:GetCommonRewardList(v.reward),
                probability = v.probabilityShow,
                show = v.show == 1,
            })
        end
    end

    table.sort(list, function(a, b) return a.refId < b.refId end)
    return list
end

function UIYellHRew:CreateInRuleList(listTrans, list)
    local key = listTrans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(listTrans, list, function(...) self:OnDrawRuleMoreCell(...) end)
    end
end

function UIYellHRew:InitText()
    self:SetTextTile(self.mRuleTitle, ccClientText(27803))

    local isShowExplain = not gLGameLanguage:IsKoreaRegion()
    CS.ShowObject(self.mExplainTxt, isShowExplain)
    if isShowExplain then
        self:SetWndText(self.mExplainTxt, ccClientText(27804))
    end
end

function UIYellHRew:DisposeLimitCallActivityPage(pb)
    if not pb then return end
    if not self._jackpotId then return end
    local sid = self._sid
    local ruleMoreList = {}
    local entryCfg
    local pages = pb.pages or {}
    for i, v in ipairs(pages) do
        if self._jackpotId == v.pageId then
            local page = gModelActivity:GenerateActivePageDataFromPb(v)
            for idx, val in ipairs(page.entry) do
                entryCfg = gModelActivity:GetWebActivityEntryData(sid, val.pageId, val.entryId)
                if entryCfg then
                    local reward = LxDataHelper.ParseItem(entryCfg.reward)
                    local moreInfo = string.split(entryCfg.moreInfo, '|')
                    local twoMoreInfo = string.split(moreInfo[2], "=")
                    if tonumber(twoMoreInfo[1]) == 1 then
                        table.insert(ruleMoreList, {
                            rewardList = reward[1],
                            probabilityStr = twoMoreInfo[2],
                            sort = val.entryId,
                        })
                    end
                end
            end
        end
    end
    self:InitRuleMoreList(ruleMoreList)
end

function UIYellHRew:RefreshActivityCallView()
    self:SetRuleDivText(self._policyTxt)
    local explainList = {}
    local specialTxt = self._specialTxt or ""
    local specialTxtList = string.split(specialTxt, "|")
    for i, v in ipairs(specialTxtList) do
        table.insert(explainList, {
            str = v,
        })
    end
    self:InitExplainList(explainList)
end

function UIYellHRew:OnDrawHeroCell(list, item, itemdata, itempos)
    self:OnDrawRuleMoreNewCell(list, item, itemdata, itempos)
    --
    --local StarDesc = self:FindWndTrans(item,"TopDiv/StarDesc")
    --self:SetWndText(StarDesc,itemdata.showKindStr)
    --
    --local InRuleList = self:FindWndTrans(item,"InRuleList")
    --self:CreateInRuleList(InRuleList,itemdata.jackpotList)
    --self:CreateCommonHero(item,itemdata, true)
end

function UIYellHRew:InitTimeTreasureData()
    self._curMagicWheelType = self:GetWndArg("curMagicWheelType")
end

function UIYellHRew:GetCommonHeroList(itemdata)
    if not itemdata then return {} end

    local callRefId = itemdata.callRefId
    local callRef = gModelCallHero:GetCallRefByRefId(callRefId)
    if not callRef then return {} end

    local list = {}
    local qualityList = {}
    local tQ
    local quality = string.split(callRef.quality, ",") or {}
    for i, v in ipairs(quality) do
        v = string.split(v, "=")
        tQ = tonumber(v[1])
        qualityList[tQ] = tQ
    end
    local keyDataMap = {}
    local showKind
    local jackpotId = itemdata.jackpotId
    for k, v in pairs(GameTable.SummonJackpotRef) do
        --- 2024/5/16 : show字段仅控制概率是否展示
        --if v.jackpotId == jackpotId and v.show == 1 and qualityList[v.smallJackpot] ~= nil then

        --- 2024/5/22 : 不和品质挂钩，如果 showKind > 0 就显示（有分类就显示出来），无单号
        --if v.jackpotId == jackpotId and qualityList[v.smallJackpot] ~= nil then

        showKind = v.showKind
        if v.jackpotId == jackpotId and showKind and showKind > 0 then
            local keyDatas = keyDataMap[showKind]
            if not keyDatas then
                keyDatas = {}
                keyDataMap[showKind] = keyDatas
            end
            table.insert(keyDatas, {
                callRefId = callRefId,
                sort = v.sort,
                refId = k,
                rewardList = self:GetCommonRewardList(v.reward),
                probability = v.probabilityShow,
                show = v.show == 1,
            })
        end
    end
    for k, v in pairs(keyDataMap) do
        table.sort(v, function(a, b)
            local sortA, sortB = a.sort, b.sort
            if sortA ~= sortB then
                return sortA > sortB
            end
            return a.refId > b.refId
        end)
        table.insert(list, {
            showKind = k,
            showKindStr = ccClientText(k),
            jackpotList = v
        })
    end
    table.sort(list, function(a, b) return a.showKind < b.showKind end)
    return list
end

function UIYellHRew:GetShopList()

    if self._curShopId==1007 then
        local list = {}
        local map = {}
        for k,v in pairs(GameTable.StoreRandomRef) do
            if v.type == 16 then
                if not map[v.list] then
                    map[v.list] = {}
                end
                table.insert(map[v.list], v)
                table.sort(map[v.list],function(a, b)
                    return a.refId < b.refId
                end)
            end
        end
        for _, v in pairs(map) do
            table.insert(list, v)
        end
        return list
    end

    local list = {}
    for k,v in pairs(GameTable.StoreRandomRef) do
        local reward = string.split(v.reward,"=")
        local rewardList = {
            itemType = tonumber(reward[1]),
            itemId = tonumber(reward[2]),
            itemNum = tonumber(reward[3]),
            weightShow = v.weightShow,
            list = v.list,
            type = v.type,
            refId = v.refId,
            fixDiscount = v.fixDiscount,
            listName = v.listName,
        }
        if self._curShopId==1001 and v.type==1 then
            table.insert(list,rewardList)
        elseif self._curShopId==1005 and v.type==5 then
            table.insert(list,rewardList)
        end
    end
    table.sort(list,function(a,b)
        return a.refId < b.refId
    end)

    return list
end

function UIYellHRew:InitRuleNormalList()
    CS.ShowObject(self.mRuleNormalList, true)
    local list = self:GetRuleNormalList()

    local uiRuleNormalList = self._uiRuleNormalList
    if uiRuleNormalList then
        uiRuleNormalList:RefreshList(list)
    else
        uiRuleNormalList = self:GetUIScroll("uiRuleNormalList")
        self._uiRuleNormalList = uiRuleNormalList
        uiRuleNormalList:Create(self.mRuleNormalList, list, function(...) self:OnDrawRuleMoreCell(...) end,
            UIItemList.WRAP)
    end
end

function UIYellHRew:RefreshRefIdView()
    self:InitRuleTxt()
    if self._callRefId == ModelCallHero.CALL_TYPE_REGRESSION then
        self:InitRuleNormalList()
    else
        self:InitRuleMoreList()
    end
end

function UIYellHRew:InitRuleTxt()
    local textList = {}
    local text = ""

    if self._viewType == UIYellHRew.VIEW_HERO_TRANSFORM then
        text = ccClientText(27813)
        local ref = GameTable.SupportTipsRef[31]
        local str = ccLngText(ref.text)
        local specialExplain = string.split(str, "<br>")
        for idx, val in ipairs(specialExplain) do
            table.insert(textList, { str = val })
        end
    else
        local extractType = self._extractType
        local callRefId = self._callRefId
        for k, v in pairs(GameTable.SummonTextRef) do
            local isFull = false
            if extractType and v.extractType == extractType and v.callRefId == 0 then
                isFull = true
            elseif callRefId and callRefId == v.callRefId then
                isFull = true
            end
            if isFull then
                text = ccClientText(v.text)

                local specialExplain = string.split(v.specialExplain, ",")
                for idx, val in ipairs(specialExplain) do
                    table.insert(textList, {
                        str = ccClientText(tonumber(val)),
                    })
                end
            end
        end
    end


    self:SetRuleDivText(text)
    self:InitExplainList(textList)
end

function UIYellHRew:SetRuleDivText(str)
    local isShow = not string.isempty(str)

    if gLGameLanguage:IsKoreaRegion() then
        isShow = false
    end

    CS.ShowObject(self.mPrivate, isShow)
    if not isShow then return end

    self:SetWndText(self.mRuleTxt, str)
end

function UIYellHRew:GetCallRefidRuleList()
    local list = {}
    local callRefId = self._callRefId
    if callRefId then
        for k, v in pairs(GameTable.SummonTextRef) do
            if callRefId == v.callRefId then
                list = self:GetCommonHeroList(v)
                break
            end
        end
    end
    return list
end

function UIYellHRew:GetFindTreasureViewRuleList()
    local list = {}
    local rewardList
    -- local dropList = gModelTreasure:GetTreasureDropByType(1)
    -- for i,v in ipairs(dropList) do
    --     rewardList = self:GetCommonRewardList(v.reward)
    --     table.insert(list,{
    --         sort = v.sort,
    --         refId = v.refId,
    --         rewardList = rewardList,
    --         probability = v.probabilityShow,
    --     })
    -- end
    return list
end

function UIYellHRew:RefreshShowSpecialHelpBtn()
    local viewType = self._viewType
    local showSpecialBtn = UIYellHRew.SHOWSPECIALBTNLIST[viewType] or false
    CS.ShowObject(self.mSpecialHelpBtn, showSpecialBtn)
end

function UIYellHRew:RefreshTimeTreasureView()
    self:InitTimeTreasureRuleText()
    self:InitRuleNormalList()
end

function UIYellHRew:InitMsg()
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb) self:OnActivityPageResp(pb) end)

    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIYellHRew:RefreshFindTreasureView()
    self:InitFindTreasureRuleText()
    self:InitRuleNormalList()
end

function UIYellHRew:DisposeFindTreasureHelpBtnFunc()
    if not self._curMagicWheelType then return end
    local isLucky = self._curMagicWheelType == ModelCallHero.LUCKY
    local id = isLucky and 17 or 18
    local luckyNum
    if isLucky then
        local t = string.split(gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum"), "=")
        luckyNum = tonumber(t[3])
    else
        local t = string.split(gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum"), "=")
        luckyNum = tonumber(t[3])
    end
    local luckCountNum = 0
    local list = self:GetIntegralGetList()
    local len = #list
    if len > 0 then
        luckCountNum = list[len].grad
    end
    luckyNum = luckyNum or 10
    luckCountNum = luckCountNum or 1000
    GF.OpenWnd("UIBzTips", { refId = id, para = { luckyNum, luckCountNum } })
end

function UIYellHRew:InitShopData()
    self._ShopGl = self:GetWndArg("ShopGl")
    self._curShopId = self:GetWndArg("curShopId")
end

function UIYellHRew:InitRefIdData()
    self._callRefId = self:GetWndArg("callRefId")
end

--- 如果是 actList 重新开发
function UIYellHRew:InitRuleMoreList(actList)
    CS.ShowObject(self.mRuleMoreList, true)

    --- 如果存在list，为活动
    local list = self:GetRuleMoreList()

    if gLGameLanguage:IsKoreaRegion() then
        local allProbability = 0
        for k, v in ipairs(list) do
            allProbability = allProbability + v.probability
        end
        self._allProbability = allProbability
    end

    local uiRuleMoreList = self._uiRuleMoreList
    if uiRuleMoreList then
        uiRuleMoreList:RefreshList(list)
    else
        uiRuleMoreList = self:GetUIScroll("uiRuleMoreList")
        self._uiRuleMoreList = uiRuleMoreList
        --- ItemTemplate11
        --uiRuleMoreList:Create(self.mRuleMoreList,list,function(...) self:OnDrawRuleMoreCell(...) end,UIItemList.WRAP)
        uiRuleMoreList:Create(self.mRuleMoreList, list, function(...) self:OnDrawRuleMoreNewCell(...) end)
    end
    uiRuleMoreList:EnableScroll(true)
end

------------------------- List -------------------------
function UIYellHRew:GetCallExtractTypeRuleList()
    local list = {}
    local extractType = self._extractType
    if extractType then
        for k, v in pairs(GameTable.SummonTextRef) do
            if v.extractType == extractType and v.callRefId ~= 0 then
                table.insert(list, v)
            end
        end
    end
    if #list > 0 then
        table.sort(list, function(a, b)
            return a.sort < b.sort
        end)
    end
    return list
end
------------------------- List -------------------------

------------------------------------------------------------------
return UIYellHRew