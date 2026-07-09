---
--- Created by Administrator.
--- DateTime: 2023/10/26 17:35:00
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UILimitWardrobe:LChildWnd
local UILimitWardrobe = LxWndClass("UILimitWardrobe", LChildWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILimitWardrobe:UILimitWardrobe()
    self._heroImgFrameDefaultPath = "public_frame_4_1"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILimitWardrobe:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILimitWardrobe:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILimitWardrobe:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:InitSkinList()
    self:InitPayItemList()

    self:CreateWndEffect_Ex({
        trans = self.mRewardEffRoot,
        effName="fx_tehuishangdian",
        effKey="fx_tehuishangdian",
    })
end

function UILimitWardrobe:InitPayItemList()
	local list = self:GetPayItemList()
	local uiList = self:FindUIScroll("mPayItemList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mPayItemList")
		uiList:Create(self.mPayItemList, list, function(...) self:OnDrawPayItemCell(...) end)
	end
end

function UILimitWardrobe:InitData()
    self._sortList = {
        [0] = 1,
        [1] = 3,
        [2] = 2,
    }

    self._skinShopList = gModelActivity:GetSkinList()

    self._raceType = 0
    self._raceTransList = {
        self.mRaceBtn1,
        self.mRaceBtn2,
        self.mRaceBtn3,
        self.mRaceBtn4,
        self.mRaceBtn5,
    }
    self._raceSelTransList = {
        self.mRaceBtnSel1,
        self.mRaceBtnSel2,
        self.mRaceBtnSel3,
        self.mRaceBtnSel4,
        self.mRaceBtnSel5,
    }

    local cfg = gModelGeneral:GetEmptyCfg(35001)
    self:SetWndText(self.mEmptyText, ccLngText(cfg.text))

    self:SetWndText(self.mRewardBtnName,ccClientText(30212))
end

function UILimitWardrobe:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroSkinShopResp, function()

        --self._skinShopList = gModelActivity:GetSkinList()
        self:InitSkinList(true)
    end)

    self:WndEventRecv(EventNames.REFRESH_SKIN_INFO, function()
        self:InitSkinList(true)
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:InitSkinList(true)
        self:InitPayItemList()
    end)
end

function UILimitWardrobe:OnDrawSkinCell(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local AniRootSkinImg = self:FindWndTrans(AniRoot, "SkinImg")
    local AniRootLightImg = self:FindWndTrans(AniRoot, "LightImg")
    local AniRootKuangImg = self:FindWndTrans(AniRoot, "kuangImg")
    local AniRootTypeImg = self:FindWndTrans(AniRoot, "TypeImg")
    local AniRootBlackImg = self:FindWndTrans(AniRoot, "blackImg")
    local blackImgRewardList = self:FindWndTrans(AniRootBlackImg, "RewardList")
    local AniRootWearTag = self:FindWndTrans(AniRoot, "wearTag")
    local AniRootBuyBtn = self:FindWndTrans(AniRoot, "BuyBtn")
    local BuyBtnUIText = self:FindWndTrans(AniRootBuyBtn, "UIText")
    local BuyBtnLayout = self:FindWndTrans(AniRootBuyBtn, "layout")
    --local layoutIcon = self:FindWndTrans(BuyBtnLayout,"Icon")
    local layoutUIText = self:FindWndTrans(BuyBtnLayout, "UIText")
    local layoutUIIcon = self:FindWndTrans(BuyBtnLayout, "Icon")
    local heroImgFrameDefault = self:FindWndTrans(AniRoot, "HeroImgFrameDefault")
    local heroImgFrame = self:FindWndTrans(AniRoot, "HeroImgFrame")
    local qualityIcon = self:FindWndTrans(AniRoot, 'QualityIcon')
    local heroImgBg = self:FindWndTrans(AniRoot, 'HeroImgBg')

    local rewardTran= self:FindWndTrans(AniRoot, 'Reward')

    local ref = itemdata.ref
    local refId = ref.refId
    local state = itemdata.state
    local expend = ref.expend
    local skin = ref.skin
    local skinItem = itemdata.rewardList[1]

    local heroSkinData = gModelHero:GetShowEffectById(skin)
    local instanceId = item:GetInstanceID()

    local iconBig = heroSkinData.iconBig
    self:SetWndEasyImage(AniRootSkinImg, iconBig, function()
        CS.ShowObject(AniRootSkinImg, true)
    end,true)

    local isShowQualityIcon = false
    local heroImgFramePath = heroSkinData.skinIcon
    --local quality = heroSkinData.skinQuality
    --if quality and quality > 0 then
    --    local qualityData = gModelItem:GetQualityRef(quality)
    --
    --end
    --
    --CS.ShowObject(qualityIcon, isShowQualityIcon)

    self:SetWndClick(rewardTran,function()
        GF.OpenWnd("UIringBoxDetail",{rewardTran,itemdata.rewardList})
    end)


    local skinQuality = heroSkinData and heroSkinData.skinQuality
    if not string.isempty(skinQuality) then
        self:SetWndEasyImage(qualityIcon,skinQuality,function()
            CS.ShowObject(qualityIcon, true)
        end,true)
    else
        CS.ShowObject(qualityIcon, false)
    end

    local isShowDefaultFrameIcon = heroImgFramePath == self._heroImgFrameDefaultPath
    --CS.ShowObject(heroImgFrameDefault, isShowDefaultFrameIcon)
    --CS.ShowObject(heroImgFrame, not isShowDefaultFrameIcon)


    if LxUiHelper.IsImgPathValid(heroImgFramePath) then
        local frameIconTrans = isShowDefaultFrameIcon and heroImgFrameDefault or heroImgFrame
        self:SetWndEasyImage(frameIconTrans, heroImgFramePath)
    end

    local efficacy = ref.efficacy
    self:SetWndEasyImage(AniRootLightImg, efficacy, function()
        CS.ShowObject(AniRootLightImg, true)
    end)
    local itemList = itemdata.rewardList

    local InstanceID = item:GetInstanceID()
    local uiIconEasyList = self._uiList:GetItemCls(InstanceID)
    if (not uiIconEasyList) then
        uiIconEasyList = UIIconEasyList:New()
        self._uiList:SetItemCls(InstanceID, uiIconEasyList)
        uiIconEasyList:Create(self, blackImgRewardList)
        uiIconEasyList:SetShowNum(false)
        uiIconEasyList:SetShowExtraNum(true, "NumTxt")
    end
    uiIconEasyList:RefreshList(itemList)

    local img = gModelHero:GetRaceImgByRefId(ref.race)
    --self:SetWndEasyImage(AniRootTypeImg, img, function()
    --    CS.ShowObject(AniRootTypeImg, true)
    --end)
    CS.ShowObject(AniRootTypeImg, false)

    local refId = skinItem.itemId
    local ref = gModelItem:GetRefByRefId(refId)
    local typeDate = ref.typeDate
    typeDate = string.split(typeDate, "=")
    local skinRefId, skinTime, heroRefId = tonumber(typeDate[1]), tonumber(typeDate[2]), tonumber(typeDate[3])
    local heroTypeId = math.floor(skinRefId / 100)
    local heroListData = self:CheckWearHeroList(heroTypeId) -- 判断是否有该类型的英雄
    local heroListCnt = heroListData.heroListCnt -- 判断是否有该类型的英雄


    if state == 1 then
        local isRmb = false
        local pay
        expend = string.split(expend, "=")
        local isDiamond = #expend > 1
        if isDiamond then
            pay = expend[3]
            -- 钻石
            local str = pay
            self:SetWndText(layoutUIText, str)
            local iconPath = gModelItem:GetItemIconByRefId(tonumber(expend[2]))
            self:SetWndEasyImage(layoutUIIcon, iconPath)
        else
            isRmb = true
            pay = tonumber(expend[1])
            -- RMB
            local str = gModelPay:GetShowByWelfareId(pay)
            self:SetWndText(BuyBtnUIText, str)
        end

        CS.ShowObject(BuyBtnLayout, isDiamond)
        CS.ShowObject(BuyBtnUIText, not isDiamond)

        local payId  = itemdata.ref.refId
        self:SetWndClick(AniRootBuyBtn, function()
            self:BuySkin(payId, isRmb, pay, skin, ref.hero)
        end)

        self:SetWndClick(AniRootSkinImg, function()

            -- 获取一次对应的id
            --调整为直接打开皮肤预览界面
            if (heroListCnt and heroListCnt > 0) then
                local maxPowerHeroId = heroListData.maxPowerId--最高战力流水ID
                local gotoHeroId = maxPowerHeroId
                gModelGeneral:OpenHeroSkin({ refId = heroTypeId, id = gotoHeroId, gotoSkin = skinRefId })
            else
                gModelItem:GetWndNameByType(skinItem.itemType, skinItem.itemId, 1016)

            end
        end)

    else

        CS.ShowObject(BuyBtnLayout, false)
        CS.ShowObject(BuyBtnUIText, true)
        local str = nil
        if state == 2 then
            str = ccClientText(17422)
        elseif state == 3 then
            str = ccClientText(17421)
        end

        self:SetWndText(BuyBtnUIText, str)
        self:SetWndClick(AniRootBuyBtn, function()
            gModelHero:ActiveOrWearSkin(skin)
        end)

        self:SetWndClick(AniRootSkinImg, function()
            --调整为直接打开皮肤预览界面
            gModelHero:ActiveOrWearSkin(skin)
        end)

    end

    CS.ShowObject(AniRootWearTag, state == 4)
    CS.ShowObject(AniRootBuyBtn, state ~= 4)

    --设置背景框 和背景图
    local qualityData = gModelHero:GetTimeWardrobeQualityBgAndFrame(ref.frame)

    --self:SetWndEasyImage(heroImgBg, heroSkinData.iconBig,function()
    --    CS.ShowObject(heroImgBg,true)
    --end,true)

    if qualityData then
        self:SetWndEasyImage(heroImgBg, qualityData.bg,function()
            CS.ShowObject(heroImgBg,true)
        end)
        self:SetWndEasyImage(heroImgFrame, qualityData.frame)
    end
end

function UILimitWardrobe:OnClickRewardBtnFunc()
    GF.OpenWnd("UITmWardrobeGift")
end

function UILimitWardrobe:InitEvent()
    self:SetWndClick(self.mAllBtn, function()
        self:RaceEvent(0)
    end, LSoundConst.CLICK_PAGE_COMMON)
    for i, v in ipairs(self._raceTransList) do
        self:SetWndClick(v, function()
            self:RaceEvent(i)
        end, LSoundConst.CLICK_PAGE_COMMON)
    end
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 93 })
    end)
    self:SetWndClick(self.mRewardBtn,function()
        self:OnClickRewardBtnFunc()
    end)
end

function UILimitWardrobe:BuySkin(refId, isRmb, pay, skinRefId, heroRefId)

    if heroRefId then
        local heroRefIdList = gModelHero:GetServerHeroListByRefId(heroRefId)        -- 判断是否有该类型的英雄
        if #heroRefIdList <= 0 then
            GF.ShowMessage(ccClientText(17407))
            return
        end
    end

    if isRmb then
        gModelPay:GiftPayCtrl(refId, tonumber(pay), ModelPay.PAY_TYPE_GIFT, ModelPay.PAY_SKIN_BUY)
    else
        gModelActivity:OnHeroSkinBuyReq(refId)
    end
end

function UILimitWardrobe:CheckWearHeroList(heroRefIde)
    local heroRefIdList = gModelHero:GetServerHeroListByRefId(heroRefIde) -- 判断是否有该类型的英雄
    local maxPowerHeroId = gModelHero:GetRefIdTypeList(heroRefIde)--最高战力流水ID
    return { heroListCnt = #heroRefIdList, maxPowerId = maxPowerHeroId }
end

function UILimitWardrobe:InitSkinList(network)
    local list = {}
    local skinList = gModelHero:GetTimeWardrobeSkinList()
    for i, v in ipairs(skinList) do
        if self._raceType == 0 or self._raceType == v.race then
            local rewardList = LxDataHelper.ParseItem(v.reward)

            local isSkinItem, code, skinRefId
            for k1, v1 in ipairs(rewardList) do
                isSkinItem, code, skinRefId = gModelHero:GetSkinStateByItemId(v1)
                if isSkinItem then
                    break
                end
            end

            local data = {
                ref = v,
                state = code,
                rewardList = rewardList
            }
            table.insert(list, data)
        end


    end
    table.sort(list, function(a, b)
        if a.state ~= b.state then
            return a.state < b.state
        end
        return a.ref.sort < b.ref.sort
        --local refId1,refId2 = skinData1.refId,skinData2.refId
        --local state1,state2 = self._skinShopList[refId1].state,self._skinShopList[refId2].state
        --if state1 == state2 then
        --	return skinData1.sort < skinData2.sort
        --else
        --	--self._sortList
        --	return self._sortList[state1] < self._sortList[state2]
        --end
    end)
    if self._uiList then
        if network then
            self._uiList:RefreshData(list)
        else
            self._uiList:RefreshList(list)
        end
    else
        self._uiList = self:GetUIScroll("skinList")
        self._uiList:Create(self.mItemList, list, function(...)
            self:OnDrawSkinCell(...)
        end, UIItemList.WRAP, false)
        local uiList = self._uiList:GetList()
        --uiList:EnableLoadAnimation(true, 0, 3)
        uiList:RefreshList(UIListWrap.RefreshMode.Solid)
    end

    CS.ShowObject(self.mNoRecord2, #list == 0)


end

function UILimitWardrobe:OnClickPayItemFunc(itemdata)
    gModelGeneral:OpenGetWayWnd({ itemId = itemdata.itemId })
end



function UILimitWardrobe:GetPayItemList()
	local list = {
        {itemId = 100218},
    }
	return list
end

function UILimitWardrobe:OnDrawPayItemCell(list, item, itemdata, itempos)
    local icon = self:FindWndTrans(item,"icon")
    local ItemNum = self:FindWndTrans(item,"ItemNum")
    local AddBtn = self:FindWndTrans(item,"AddBtnDiv/AddBtn")

    local itemId = itemdata.itemId
    local iconPath = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(icon,iconPath,function() CS.ShowObject(icon,true) end)

    self:SetWndText(ItemNum,LUtil.NumberCoversion(gModelItem:GetNumByRefId(itemId)))

	self:SetWndClick(AddBtn,function() self:OnClickPayItemFunc(itemdata) end)
	self:SetWndClick(item,function() self:OnClickPayItemFunc(itemdata) end)
end

function UILimitWardrobe:RaceEvent(race)
    if self._raceType == race then
        return
    end
    self._raceType = race
    for i, v in ipairs(self._raceSelTransList) do
        CS.ShowObject(v, race == i)
    end

    CS.ShowObject(self.mAllBtnSel, race == 0)

    self:InitSkinList()
end
------------------------------------------------------------------
return UILimitWardrobe


