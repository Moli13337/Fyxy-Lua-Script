---
--- Created by wzz.
--- DateTime: 2024/7/4 17:13:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFish:LWnd
local UIFish = LxWndClass("UIFish", LWnd)

local TaskState = gModelFish.TaskState
local Tweening = DG.Tweening

local AniPaths = {
    ["shuaigan"] = { nextName = "idle2", effName = "fx_ui_diaoyu_idle2" },
    ["idle2"] = { checkFish = true, effName = "fx_ui_diaoyu_shanggou", name1 = "shanggou1", name2 = "shanggou2", name3 = "shanggou3", sound = "SoundS_352" },
    ["shanggou1"] = { checkHad = true, had = "qigan1", no = "qigan2", hadEff = "fx_ui_diaoyu_qigan_1", noEff = "fx_ui_diaoyu_qigan_2" },
    ["shanggou2"] = { checkHad = true, had = "qigan1", no = "qigan2", hadEff = "fx_ui_diaoyu_qigan_1", noEff = "fx_ui_diaoyu_qigan_2" },
    ["shanggou3"] = { checkHad = true, had = "qigan1", no = "qigan2", hadEff = "fx_ui_diaoyu_qigan_1", noEff = "fx_ui_diaoyu_qigan_2" },
    ["qigan2"] = { nextName = "idle3", isEnd = true },
    ["qigan1"] = { nextName = "idle3", isEnd = true },
}

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFish:UIFish()
    -- 自动钓鱼数据，为nil表示没有在自动调鱼
    self._autoFishData = nil
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFish:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFish:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFish:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mTxtName, -14)
        self:SetAnchorPos(self.mReset,Vector2.New(-20,32.5))
    end
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitView()
    self:InitData()
    self:InitTimer()
    self:InitTexts()
    self:InitEvents()
    self:InitSpine()
    self:Refresh()
end

-- 点击技能
function UIFish:OnBtnSkill()
    GF.OpenWnd("UIFishSkill")
end

-- 播音效
function UIFish:PlaySound(name)
    if not name then
        return
    end

    gLGameAudio:PlaySound(name, self._curFishSpeed)
end

-- 顶部资产
function UIFish:RefreshTopAsset()
    local assetIdList, assetMaxMap = gModelFish:GetTopAssetList()
    self:SetTopAssetList(self.mTopAsset, assetIdList, assetMaxMap)
end

-- 初始界面化文本
function UIFish:InitTexts()
    self:SetWndText(self.mTitle, ccClientText(44207))
    self:SetTextTile(self.mBtnIllustrated, ccClientText(44202))
    self:SetTextTile(self.mBtnShop, ccClientText(44201))
    self:SetTextTile(self.mBtnFishGift, ccClientText(44200))
    self:SetTextTile(self.mBtnAuto, ccClientText(44208))
    self:SetTextTile(self.mBtnSkill, ccClientText(44209))
    self:SetTextTile(self.mBtnMore, ccClientText(44211))
    self:SetTextTile(self.mBtnBackpack, ccClientText(44345))
    self:SetTextTile(self.mBtnProb, ccClientText(21813))

    if self._isEnus then
        self:SetWndButtonText(self.mBtnRod, ccClientText(44205), nil, -6, -20)
        self:SetWndButtonText(self.mBtnBait, ccClientText(44204), nil, -6, -20)
    else
        self:SetWndButtonText(self.mBtnRod, ccClientText(44205))
        self:SetWndButtonText(self.mBtnBait, ccClientText(44204))
    end

    self:SetWndText(self.mTxtTask, ccClientText(44203))
end

-- 自动卖鱼
function UIFish:AutoSellFish(theBait)
    local fishObj = theBait.fish
    gModelFish:SellFishReq(0, fishObj.id)
end

-- 飘资产
function UIFish:FlyAsset(param)
    local refId = param.refId
    local num = math.min(20, param.num)
    local toTrans
    local instanceID = self.mTopAsset:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID) or {}
    for k, v in ipairs(itemCache.itemList or {}) do
        if v.refId == refId then
            toTrans = v.icon
            break
        end
    end

    if not toTrans then
        return
    end

    local rootfromTrans = param.trans
    -- rootfromTrans:SetParent(self.mTopAsset, false)
    -- rootfromTrans.position = param.position

    local rootObj = rootfromTrans.gameObject
    local pos = param.position
    local Vector3 = Vector3
    for i = 1, num do
        local obj = LxUnity.InstantObject(rootObj)
        local fromTrans = obj.transform
        fromTrans:SetParent(self.mTopAsset, false)

        local offx = math.random(-100, 100) * 0.001
        local offy = math.random(-100, 100) * 0.001

        fromTrans.position = Vector3(pos.x + offx, pos.y + offy, pos.z)

        local toPos = toTrans.position
        local toSize = Vector3(0.36, 0.36, 0.36)
        local fromSize = fromTrans.localScale

        local flyTime = 0.5
        local offtSize = 0.4
        local offtSize2 = 0.2
        local seqTween
        seqTween = self:TweenSeqCreate(fromTrans:GetInstanceID(), function(seq)
            local tw1 = fromTrans:DOMove(toPos, flyTime)
            local tw2 = fromTrans:DOScale(Vector3(fromSize.x + offtSize, fromSize.y + offtSize, fromSize.z + offtSize),
                    flyTime * 0.5)
            local tw3 = fromTrans:DOScale(toSize, flyTime * 0.5)
            seq:AppendInterval(i * 0.015)

            local seqMove = Tweening.DOTween.Sequence()
            seqMove:Insert(0, tw1)
            seqMove:Insert(0, tw2)
            seqMove:Insert(flyTime * 0.5, tw3)
            seq:Append(seqMove)

            local seqScale = Tweening.DOTween.Sequence()
            local tw4 = fromTrans:DOScale(Vector3(toSize.x + offtSize2, toSize.y + offtSize2, toSize.z + offtSize2), 0.1)
            local tw5 = fromTrans:DOScale(toSize, 0.1)
            seqScale:Append(tw4)
            seqScale:Append(tw5)
            seq:Append(seqScale)
            return seq
        end)
        seqTween:Play()
        seqTween:OnComplete(function()
            LxUnity.GameObject.Destroy(fromTrans.gameObject)
        end)
    end
end

-- 点击鱼礼包
function UIFish:OnBtnFishGift()
    GF.OpenWnd("UIFishGift")
end

-- 刷新任务
function UIFish:RefreshTask()
    local dataList = gModelFish:GetTaskList(true)
    local list = {}
    for i, v in ipairs(dataList) do
        list[i] = v
    end
    self:SetComList(self.mTaskList, list, function(...)
        return self:OnDrawTaskItem(...)
    end)

    local can = gModelFish:CanReSetAll(false, true)
    CS.ShowObject(self.mReset, can)

    local num = #dataList
    local h = 128 + 35 * (num - 1)
    LxUiHelper.SetSizeWithCurAnchor(self.mTaskRoot, 1, h)
end

-- 播鱼结束动画
function UIFish:PlayFishEndAni(data)
    self:SetSpeedFishing(false)
    self._dpSpine:PlayAnimation(0, data.nextName, true)
    if self._fishSpine then
        self._fishSpine:SetAnimationTimeScale(1)
        self._fishSpine:PlayAnimation(0, "idle", true)
    end

    local theBait = self._theBait
    self._theBait = nil
    if not theBait then
        GF.ShowMessage(ccClientText(44327))
        self._isFishing = false
        if self._autoFishData then
            if not gModelFish:CanFishing(false) then
                self:StopAutoFishing()
            end
            self:PlayEndFishingAnim()
        end
        return
    end
    local fishRefId = theBait.fish.refId
    if not self._autoFishData then
        GF.OpenWnd("UIFishGet", {
            theBait = theBait,
            callback = function()
                self:DestroyWndSpineByKey(fishRefId)
                self._fishSpine = nil
                self._isFishing = false
            end
        })
        return
    end

    -- 自动钓鱼
    local showGet = self:CheckIsShowGet(theBait)
    if showGet then
        GF.OpenWnd("UIFishGet", {
            theBait = theBait,
            callback = function()
                self:DestroyWndSpineByKey(fishRefId)
                self._fishSpine = nil
                self:OnFishingFinish()
            end
        })
        return
    end

    self:DestroyWndSpineByKey(fishRefId)
    self._fishSpine = nil

    self:AutoSellFish(theBait)
    self:PlayEndFishingAnim()
end

-- 钓鱼spine
function UIFish:InitSpine()
    self:CreateWndSpine(self.mBtnFishingSpine, "yugan_1", "key", false, function(dpSpine)
        dpSpine:PlayAnimation(0, "idle1", true)
        dpSpine:SetScale(2)
        self._dpSpine = dpSpine
        dpSpine:SetAnimationCompleteFunc(function(...)
            self:OnSpineAnimComplete(...)
        end)
    end)
end

-- 点击自动钓鱼
function UIFish:OnBtnAuto()
    if not gModelFish:OpenAutoFishing(true) then
        return
    end

    if self._autoFishData then
        self:StopAutoFishing()
        return
    end

    if self._isFishing then
        GF.ShowMessage(ccClientText(44335))
        return
    end

    GF.OpenWnd("UIFishAuto")
end

-- 更换鱼场
function UIFish:OnFishChangeFarm()
    self._ref = gModelFish:GetCurRef()

    self:StopAutoFishing()
    self:Refresh()
end

-- 钓鱼返回
function UIFish:OnFishingReturn(param)
    local theBait = param.theBait
    self._theBait = theBait

    self:Refresh()
    self:InitAutoFishingBtn()

    self._isFishing = true
    self:PlayStartFishingAnim()
end

-- update
function UIFish:Update()
    self:RefreshEndTime()
end

-- 点击鱼釭
function UIFish:OnBtnFishTank()
    GF.OpenWnd("UIFishTank")
end

-- 自动钓鱼 按钮动画
function UIFish:InitAutoFishingBtn()
    if not self._autoFishData then
        return
    end
    if self._autoIconPlaying then
        return
    end

    GF.ShowMessage(ccClientText(44311))
    self._autoIconPlaying = true

    self.mAutoIcon.localEulerAngles = Vector3.New(0, 0, 0)
    local tw = self.mAutoIcon:DORotate(Vector3.New(0, 0, 180), 1)
    tw:SetLoops(-1)
    tw:Play()
end

-- 初始化打开界面
function UIFish:InitView()
    local function callback()
        local theBait = gModelFish:PopCurTheBaitObj()
        if theBait then
            GF.OpenWnd("UIFishGet", { theBait = theBait })
        else
            self:CheckNewFarm()
        end
    end

    local itemStr = gModelFish:GetEndThings()
    if itemStr ~= "" then
        local itemList = LUtil.GetRefItemDataList(itemStr)
        gModelGeneral:OpenUIOrdinTips({
            refId = 450001,
            itemList = itemList,
            func = callback,
            closeFunc = callback,
        })
        gModelFish:FishingRemoveEndReq()
        self:CheckNewFarm()
    else
        callback()
    end

    local config = gModelFish:GetConfigRef()
    local flag = config.probabilityOff or 1
    CS.ShowObject(self.mBtnProb, flag == 1)
end

-- 刷新结束时间
function UIFish:RefreshEndTime()
    local isOpen = gModelFish:IsFishingOpen()
    if not isOpen then
        -- self:SetWndText(self.mTxtTime, ccClientText(44292))
        -- self:WndClose()
        gModelFish:PlayOver()
        return
    end

    local curTime = GetTimestamp()
    local leftTime = gModelFish:GetEndTime() - curTime
    if leftTime <= 0 then
        self:SetWndText(self.mTxtTime, ccClientText(44292))
        return
    end

    local str = LUtil.FormatTimespanCn(leftTime)
    self:SetWndText(self.mTxtTime, ccClientText(44206, str))
end

-- 鱼竿动画
function UIFish:OnSpineAnimComplete(name)
    local data = AniPaths[name]
    if not data then
        return
    end

    self:ShowFishingEff(data.effName)

    if data.checkFish then
        self:PlayFishReadyAni(data)
        return
    end

    if data.checkHad then
        self:PlayFishFleeAni(data)
        return
    end

    if data.isEnd then
        self:PlayFishEndAni(data)
        return
    end

    self._dpSpine:PlayAnimation(0, data.nextName, false)
end

-- 初始数据
function UIFish:InitData()
    local refId = self:GetWndArg("refId")
    local ref = nil
    if refId then
        ref = gModelFish:GetRef(refId)
    end
    if not ref then
        ref = gModelFish:GetCurRef()
    end
    self._ref = ref
end

-- 点击主界面按钮
function UIFish:OnClickMainBtn(index)
    self:WndClose()
end

-- 播上钓动画
function UIFish:PlayFishReadyAni(data)
    local fishRef
    if self._theBait then
        local fishObj = self._theBait.fish
        fishRef = gModelFish:GetFishRef(fishObj.refId)
    else
        local ref = gModelFish:GetCurRef()
        local dataList = gModelFish:GetAllFishByRefId(ref.refId)
        local list = {}
        for k, v in ipairs(dataList) do
            if v.type <= 4 then
                table.insert(list, v)
            end
        end
        local index = math.random(1, #list)
        fishRef = gModelFish:GetFishRef(list[index].refId)
    end
    local fishType = fishRef.type
    local aniName = ""
    if fishType == 3 then
        -- 大鱼
        aniName = data.name3
    elseif fishType == 2 or fishType == 4 then
        -- 中鱼和水中生物
        aniName = data.name2
    else
        -- 小鱼、其它
        aniName = data.name1
    end

    self:PlaySound(data.sound)
    self._dpSpine:PlayAnimation(0, aniName, false)
end

-- 刷新界面红点
function UIFish:RefreshRed()
    local canUp, costItem, isMax = gModelFish:CanLvUpFishTank(false)
    self:SetRed(self.mBtnFishTank, canUp)

    local showRed = false
    if gModelFish:HadRedIllustratedFish() then
        showRed = true
    end
    if not showRed and gModelFish:HadRedIllustrated() then
        showRed = true
    end
    self:SetRed(self.mBtnIllustrated, showRed)

    showRed = gModelFish:CanFishing(false)
    self:SetRed(self.mBtnFishing, showRed)

    showRed = gModelFish:HadRedSkill()
    self:SetRed(self.mBtnSkill, showRed)

    showRed = gModelFish:HadShopGiftRed()
    self:SetRed(self.mBtnFishGift, showRed)

    showRed = gModelFish:HadShopRed()
    self:SetRed(self.mBtnShop, showRed)

    showRed = gModelFish:HadRedFishFarm()
    self:SetRed(self.mBtnShowFishList, showRed)

    showRed = gModelFish:HadRedTask()
    self:SetRed(self.mBtnMore, showRed)

    showRed = gModelFish:HadRedFishFast()
    self:SetRed(self.mBtnAuto, showRed)

    showRed = gModelFish:HadRedBackpack()
    self:SetRed(self.mBtnBackpack, showRed)
end

-- 初始事件
function UIFish:InitEvents()
    self:SetWndClick(self.mBtnClose, function()
        self:OnBtnReturn()
    end)
    self:SetWndClick(self.mBtnReturn, function()
        self:OnBtnReturn()
    end)
    self:SetWndClick(self.mBtnProb, function()
        self:OnBtnProb()
    end)
    self:SetWndClick(self.mBtnIllustrated, function()
        self:OnBtnIllustrated()
    end)
    self:SetWndClick(self.mBtnShop, function()
        self:OnBtnShop()
    end)
    self:SetWndClick(self.mBtnFishGift, function()
        self:OnBtnFishGift()
    end)
    self:SetWndClick(self.mBtnAuto, function()
        self:OnBtnAuto()
    end)
    self:SetWndClick(self.mBtnSkill, function()
        self:OnBtnSkill()
    end)
    self:SetWndClick(self.mBtnMore, function()
        self:OnBtnMore()
    end)
    self:SetWndClick(self.mBtnShowFishList, function()
        self:OnBtnShowFishList()
    end)
    self:SetWndClick(self.mBtnHelp, function()
        self:OnBtnHelp()
    end)
    self:SetWndClick(self.mBtnFishTank, function()
        self:OnBtnFishTank()
    end)
    self:SetWndClick(self.mBtnFishing, function()
        self:OnBtnFishing()
    end)
    self:SetWndClick(self.mBtnBackpack, function()
        self:OnBtnBackpack()
    end)

    self:SetWndClick(self.mBtnRod, function()
        self:OnBtnRod()
    end)
    self:SetWndClick(self.mBtnBait, function()
        self:OnBtnBait()
    end)

    self:WndEventRecv(EventNames.FISH_START_AUTO, function(...)
        self:OnStartAutoFinshing(...)
    end)
    self:WndEventRecv(EventNames.FISH_RETURN, function(...)
        self:OnFishingReturn(...)
    end)
    self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...)
        self:Refresh(...)
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function(...)
        self:Refresh(...)
    end)
    self:WndEventRecv(EventNames.FISH_TASK_RETURN, function(...)
        self:RefreshTask(...)
    end)
    self:WndEventRecv(EventNames.FISH_REFRESH_TASK, function(...)
        self:RefreshTask(...)
    end)

    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function(...)
        self:OnClickMainBtn(...)
    end)
    self:WndEventRecv(EventNames.FISH_CHANGE_FARM, function(...)
        self:OnFishChangeFarm(...)
    end)
    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:CheckNewFarm(...)
    end)
end

-- 点击鱼竿
function UIFish:OnBtnRod()
    GF.OpenWnd("UIFishBag", { tabIndex = 2 })
end

-- true:表示需要显示获得
function UIFish:CheckIsShowGet(theBait)
    local autoFishData = self._autoFishData
    local fishObj = theBait.fish
    local fishRef = gModelFish:GetFishRef(fishObj.refId)
    local needStop = false
    if theBait.type == CommonIcon.ICON_TYPE_FISH then
        local data = gModelFish:GetFishHandbookObjObj(fishRef.refId)
        if autoFishData.selectedQuality then
            -- 品质需求
            needStop = fishRef.quality >= autoFishData.quality
        end

        if not needStop and autoFishData.selectedIllustrated and fishRef.bookShow == 1 then
            -- 可激活图鉴
            needStop = data == nil
        end

        if not needStop and autoFishData.selectedPowerUp and gModelFish:InFishTankTypeList(fishRef.refId) then
            -- 评分提升
            needStop = fishObj.estimatePower > 0
        end
    else
        -- 宝箱
        needStop = true
    end

    return needStop
end

-- 刷新界面
function UIFish:Refresh()
    local ref = self._ref

    -- 鱼虹等级
    local lev = gModelFish:GetFishTankLev()
    self:SetTextTile(self.mBtnFishTank, ccClientText(44210, lev))

    self:SetWndText(self.mTxtName, ccLngText(ref.name))
    self:SetWndEasyImage(self.mBg, ref.bg)

    local curRodRefId = gModelFish:GetCurUseFishRod()
    self._curRodRefId = curRodRefId
    local curBaitRefId = gModelFish:GetCurUseFishBait()
    local iconType = CommonIcon.ICON_TYPE_ITEM
    self:CreateCommonIconImpl(self.mItemRod, { itemType = iconType, itemId = curRodRefId }, { showNum = false })

    local num = 0
    if curBaitRefId == gModelFish:GetInitBaitRefId() then
        num = -2
        self:CreateCommonIconImpl(self.mItemBait, { itemType = iconType, itemId = curBaitRefId, itemNum = num,isShowUnlimited=true })
    else
        num = gModelItem:GetNumByRefId(curBaitRefId)
        self:CreateCommonIconImpl(self.mItemBait, { itemType = iconType, itemId = curBaitRefId, itemNum = num,isShowUnlimited=false })
    end


    self:RefreshTopAsset()
    self:RefreshRed()
    self:RefreshTask()

    local open = gModelFunctionOpen:CheckIsOpened(gModelFish.FastFishId, false)
    if open then
        open = gModelFish:OpenAutoFishing(false)
    end
    CS.ShowObject(self.mBtnBackpack, open)
end

-- 点击商店
function UIFish:OnBtnShop()
    local ref = gModelFish:GetConfigRef()
    GF.OpenWndBottom("UIDian", { shopId = ref.fishingShop, isFish = true })
end

-- 点击更多
function UIFish:OnBtnMore()
    GF.OpenWnd("UIFishTask")
end

-- 加速钓鱼
function UIFish:SetSpeedFishing(isSpeed)
    local speed = 1
    if isSpeed then
        speed = self:GetCurFishSpeed()
    end
    self._curFishSpeed = speed
    self._dpSpine:SetAnimationTimeScale(self._curFishSpeed)
end

-- 播放结束钓鱼动画
function UIFish:PlayEndFishingAnim()
    self._isFishing = false
    gModelFish:FishingReq(0)
end

-- 点击返回
function UIFish:OnBtnReturn()
    GF.OpenWndBottom("UIOutts",{ childIndex = 1 })
    FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
    self:WndClose()
end

-- 点击显示鱼场列表
function UIFish:OnBtnShowFishList()
    GF.OpenWnd("UIFishList")
end

-- 处理鱼完毕
function UIFish:OnFishingFinish()
    if not self._autoFishData then
        return
    end

    if not gModelFish:CanFishing(false) then
        self:StopAutoFishing()
        return
    end

    self:PlayStartFishingAnim()
end

-- 点击帮助
function UIFish:OnBtnHelp()
    GF.OpenWnd("UIBzTips", { refId = 177 })
end

-- 点击钓鱼
function UIFish:OnBtnFishing()
    if self._autoFishData then
        GF.ShowMessage(ccClientText(44313))
        return
    end

    if not gModelFish:CanFishing(true) then
        return
    end

    if self._isFishing then
        GF.ShowMessage(ccClientText(44335))
        return
    end

    gModelFish:FishingReq(0)
end

-- 点击鱼饵
function UIFish:OnBtnBait()
    GF.OpenWnd("UIFishBag", { tabIndex = 1 })
end

-- 播鱼逃跑/上钓
function UIFish:PlayFishFleeAni(data)
    if self._theBait then
        local fishRefId = self._theBait.fish.refId
        self:DestroyWndSpineByKey(fishRefId)
        self._fishSpine = nil
        local fishRef = gModelFish:GetFishRef(self._theBait.fish.refId)

        self:CreateWndSpine(self.mFishObj, fishRef.spine, fishRefId, false, function(dpSpine)
            dpSpine:SetScale(2)
            dpSpine:SetAnimationTimeScale(self._curFishSpeed)
            self._fishSpine = dpSpine
            dpSpine:PlayAnimation(0, "qigan", false)
        end)

        self._dpSpine:PlayAnimation(0, data.had, false)
        self:ShowFishingEff(data.hadEff)
        return
    end
    self._dpSpine:PlayAnimation(0, data.no, false)
    self:ShowFishingEff(data.noEff)
end

-- 点击图鉴
function UIFish:OnBtnIllustrated()
    GF.OpenWnd("UIFishIllustrated")
end

-- 点击概率
function UIFish:OnBtnProb()
    GF.OpenWnd("UIFishProb")
end

-- 开始自动钓鱼
function UIFish:OnStartAutoFinshing(autoFishData)
    if not gModelFish:CanFishing(true, 44353) then
        return
    end

    self._autoFishData = autoFishData

    gModelFish:FishingReq(0)
end

-- 初始时间
function UIFish:InitTimer()
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

-- 播放开始钓鱼动画
function UIFish:PlayStartFishingAnim()
    -- self._delayFishingFinishTime = os.clock() + 5

    self:SetSpeedFishing(true)
    self:PlaySound("SoundS_351")
    self._dpSpine:PlayAnimation(0, "shuaigan", false)

    local effName = "fx_ui_diaoyu_shuaiguan"
    self:ShowFishingEff(effName)
end

-- 绘制任务项
function UIFish:OnDrawTaskItem(uiList, item, data)
    if not uiList then
        uiList = {}
        uiList.name = CS.FindTrans(item, "name")
        uiList.val = CS.FindTrans(item, "val")
    end

    local refId = data.refId
    local taskRef = gModelFish:GetFishTaskRef(refId)
    local desc = ccLngText(taskRef.text)
    self:SetWndText(uiList.name, desc)

    local num = tonumber(data.schedule)
    local maxNum = tonumber(data.goal)

    local strValue = ""
    if num >= maxNum then
        strValue = ccClientText(44357)
    else
        if num == 0 then
            strValue = ccClientText(44359, num, maxNum)
        else
            strValue = ccClientText(44358, num, maxNum)
        end
    end
    self:SetWndText(uiList.val, strValue)
    if self._isVie then
        self:InitTextSizeWithLanguage(uiList.name,-5)
        self:InitTextSizeWithLanguage(uiList.val,-5)
        self:InitTextCharacterWithLanguage(uiList.name,-5)
        self:InitTextCharacterWithLanguage(uiList.val,-5)
    end
    return uiList
end

-- 获取当前钓鱼速为度
function UIFish:GetCurFishSpeed()
    local curRodRefId = self._curRodRefId or gModelFish:GetCurUseFishRod()
    local data = gModelFish:GetFishItemAttr(curRodRefId)
    local speed = 1
    for i, v in ipairs(data.attrList) do
        if v.refId == 1 then
            -- 钓鱼加速
            speed = speed + v.value
        end
    end
    return speed
end

-- 点击暂存鱼
function UIFish:OnBtnBackpack()
    GF.OpenWnd("UIFishBackpack")
end

-- 播放鱼特效
function UIFish:ShowFishingEff(effName)
    self._lastEffName = self._lastEffName or ""
    self:DestroyWndEffectByKey(self._lastEffName)
    self._lastEffName = ""

    if effName and effName ~= "" then
        self._lastEffName = effName
        self:DestroyWndEffectByKey(effName)
        local eff = self:CreateWndEffect(self.mFishEff, effName, effName, 100, nil, nil, nil, nil, nil, nil, nil, nil, 30)
        if eff then
            eff:SetSpeed(self._curFishSpeed)
        end
    end
end

-- 停止自动钓鱼
function UIFish:StopAutoFishing()
    self._autoFishData = nil
    self._autoIconPlaying = nil
    self.mAutoIcon:DOKill()
end

-- 检查新鱼场
function UIFish:CheckNewFarm(wndName)
    if wndName == "UIFishNewFarm" then
        return
    end

    local list = gModelFish:GetFishViewList()
    local UIFishAutoFast = "UIFishAutoFast"
    for k, name in ipairs(list) do
        if name ~= UIFishAutoFast and GF.FindFirstWndByName(name) then
            return
        end
    end

    if GF.FindFirstWndByName("UIDian") then
        return
    end

    local refId = gModelFish:CheckNewFarm()
    if not refId then
        return
    end

    GF.CloseWndByName("UIFishAutoFast")
    self:StopAutoFishing()
    GF.OpenWnd("UIFishNewFarm", { refId = refId })
end

------------------------------------------------------------------
return UIFish