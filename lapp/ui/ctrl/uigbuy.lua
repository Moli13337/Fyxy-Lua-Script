---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
local CS = CS

---@type UIGoldHud
local UIGoldHud = LXImport('LApp.UI.Common.UIGoldHud')

---@class UIGBuy:LWnd
local UIGBuy = LxWndClass("UIGBuy", LWnd)

local adMethodId = ModelAds.TYPE_ADS_301

UIGBuy.TREASURE_ACT = 1403
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGBuy:UIGBuy()
    self._upAddTransList = {}
    self._clickEffList = {}
    self._timerPrivileKey = "_timerPrivileKey"
    self._clickGoldEffRes = { "fx_xuyuanchi_01_1", "fx_xuyuanchi_02_3", "fx_xuyuanchi_03_5" }
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGBuy:OnWndClose()
    if self._timerList then
        for i, v in pairs(self._timerList) do
            if v then
                LxTimer.DelayTimeStop(v)
            end
        end
    end

    self:ClearAllGoldHUD()

    self:TimerStop(self._goldCheckKey)

	if self._feedOpen then
		FireEvent(EventNames.ON_CHECK_SUBSCRIBE_FEED_CLEANTAR)
	end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGBuy:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGBuy:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

	local feedOpen = self:GetWndArg("feedOpen")
	self._feedOpen = feedOpen
	if feedOpen then
		LogWarn("正在直流")
	else
		LogWarn("bu 在直流")
	end

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitMsg()
    self:InitEvent()

    -- local isAct = gModelTreasure:CheckTreasureIsAct(UIGBuy.TREASURE_ACT)
    -- --local str = isAct and ccClientText(19090) or ccClientText(19089)
    -- --self:SetWndText(self.mPrivilegeBtnName,str)

    -- if isAct then
    -- 	local spineName = "Xuyuanjinyu_tequan"
    -- 	self:CreateWndSpine(self.mSpineRoot,spineName,spineName,false,function(dpSpine)
    -- 		dpSpine:PlayAnimation(0,"idle",true)
    -- 	end)
    -- end

    self._goldHUDList = {}

    self._timerList = {}

    self:CreateWndEffect(self.mEffPoint, "fx_xuyuanchi", "fx_xuyuanchi", 100, false, false)

    gModelGoldBuy:GoldBuyDetailReq()
    ----------------------------------------- 金币特效动画 --------------------------------------
    -- 特效管理列表
    self._goldEffDataList = {}

    self._hitEffDataList = {}

    -- 金币飞行顶点高度偏移值
    self._offectX = 0

    -- 金币飞行时间
    self._moveTime = 1

    -- 特效Key值
    self._effKeyCount = 0

    -- 水花落点位置列表
    self._hitPosList = {}
    for i = 1, 10 do
        local trans = self:FindWndTrans(self.mHitPosList, i)
        if trans then
            table.insert(self._hitPosList, trans)
        end
    end

    self:StartPlayEff()

    if self._isEnus or self._isJapaness or self._isVie then
        self.mTime.sizeDelta = Vector2(self.mTime.rect.width + 35, self.mTime.rect.height)
    end

    ----------------------------------------- 金币特效动画 --------------------------------------
    self._goldCheckKey = "UIGoldCheck"
    self:TimerStart(self._goldCheckKey, 1, false, -1)
    self:InitCommand()
    self:TimerStart(self._timerPrivileKey, 0.5, false, 1)
end

function UIGBuy:ListItem(list, item, itemdata, itempos)

    local IconBg = self:FindWndTrans(item, "IconBg")
    local IconBgIcon = self:FindWndTrans(IconBg, "Icon")
    local IconBgNum = self:FindWndTrans(IconBg, "Num")
    local IconBgUPAddBg = self:FindWndTrans(IconBg, "UPAddBg")
    local UPAddBgAddNum = self:FindWndTrans(IconBgUPAddBg, "AddNum")
    local IconBgRateBg = self:FindWndTrans(IconBg, "RateBg")
    local RateBgUIText = self:FindWndTrans(IconBgRateBg, "UIText")
    local IconBgEff = self:FindWndTrans(IconBg, "Eff")
    local BuyBtn = self:FindWndTrans(item, "BuyBtn")
    local NoBuyBtn = self:FindWndTrans(item, "NoBuyBtn")
    local BuyBtnRedPoint = self:FindWndTrans(BuyBtn, "redPoint")
    local SurplusText = self:FindWndTrans(item, "SurplusText")

    if self._isEnus then
        IconBgRateBg.sizeDelta = Vector2.New(90, 66)
    end

    self._upAddTransList[itempos] = IconBgUPAddBg
    self._clickEffList[itemdata.refId] = IconBgEff

    local refId = itemdata.refId

    local basicsRef = gModelGoldBuy:GetGoldBuyBasicsRefById(refId)

    self:SetWndEasyImage(IconBgIcon, basicsRef.icon)
    local value = LUtil.NumberCoversion(itemdata.baseGold)
    self:SetWndText(IconBgNum, value)
    local isCrit = basicsRef.crit == 1
    CS.ShowObject(IconBgRateBg, isCrit)
    if isCrit then
        local critRef = gModelGoldBuy:GetGoldBuyCritRefById(itemdata.criteRefId)
        local critSectionArr = string.split(critRef.critSection, ",")

        local str = ccClientText(13015)
        str = string.replace(str, critSectionArr[1], critSectionArr[2])
        self:SetWndText(RateBgUIText, str)
    end
    local buyNeed = basicsRef.buyNeed
    local itemId = 0
    local consume = 0
    local num = 0
    local isRemain = itemdata.maxTime ~= -1
    local remain = itemdata.remainTime
    local color1 = "red"
    local color2 = "green"
    local surplusStr = ""
    local showText = false
    local isShowGray = true
    local haveNum = true

    local isShowBuyObjBuyIcon = false
    local icon, butTextStr
    if (buyNeed ~= "") then
        isShowBuyObjBuyIcon = true
        local buyNeedArr = string.split(buyNeed, "=")
        itemId = tonumber(buyNeedArr[1])
        consume = tonumber(buyNeedArr[2])
        num = gModelItem:GetNumByRefId(itemId)
        icon = gModelItem:GetItemImgByRefId(itemId)
        butTextStr = consume

        if num >= consume then
            isShowGray = false
        end
    else
        butTextStr = ccClientText(13011)
    end

    if not gLGameLanguage:IsJapanRegion() then
        isShowGray = false
    end

    if isRemain then
        local remainValue = LUtil.FormatColorStr(remain, color1)
        if remain > 0 then
            remainValue = LUtil.FormatColorStr(remain, color2)
            isShowGray = false
        else
            isShowGray = true
        end
        surplusStr = string.replace(ccClientText(13012), remainValue)
        showText = true
    elseif itemId > 0 then
        local value = LUtil.FormatColorStr(num, color1)
        if num >= consume then
            value = LUtil.FormatColorStr(num, color2)
            isShowGray = false
        else
            isShowGray = true
        end
        surplusStr = string.replace(ccClientText(13014), value)
        showText = true
    end

    local showRedPoint = itemdata.refId == 1 and remain > 0
    local showAd = false


    local config = gModelAds:GetAdConfigByParam({
        adMethodId = adMethodId,
        refId = refId,
    })
    if config then
        --- 取消红点
        gModelRedPoint:SetAdsRedPointClick(config.redPointConfig)
    end
    if self:GetWndAdBtnShowStatus({
        adMethodId = adMethodId,
        refId = refId,
        checkHasCount = true,
    }) then
        showAd = true
        icon = "adShop_btn_1"
        showRedPoint = true
        if config then
            isShowBuyObjBuyIcon = true
            local adRefId = config.refId
            local configTimes = gModelAds:GetConfigTimes(adRefId)
            local viewCount = gModelAds:GetAdViewCount(adRefId)
            surplusStr = string.replace(ccClientText(13012), configTimes - viewCount)
        end
        butTextStr = ccClientText(13011)
        showText = true
    end
    if showAd then
        isShowGray = false
    end
    CS.ShowObject(BuyBtnRedPoint, showRedPoint)

    CS.ShowObject(SurplusText, showText)
    self:SetWndText(SurplusText, surplusStr)

    CS.ShowObject(BuyBtn, not isShowGray)
    CS.ShowObject(NoBuyBtn, isShowGray)
    local buyBtnTrans = BuyBtn
    if isShowGray then
        buyBtnTrans = NoBuyBtn
    end
    local BuyBtnBuyObj = self:FindWndTrans(buyBtnTrans, "BuyObj")
    local BuyObjBuyIcon = self:FindWndTrans(BuyBtnBuyObj, "BuyIcon")
    local BuyObjBuyText = self:FindWndTrans(BuyBtnBuyObj, "BuyText")

    CS.ShowObject(BuyObjBuyIcon, isShowBuyObjBuyIcon)
    if isShowBuyObjBuyIcon then
        self:SetWndEasyImage(BuyObjBuyIcon, icon)
    end

    self:SetWndText(BuyObjBuyText, butTextStr)

    self:SetWndClick(buyBtnTrans, function()
        if showAd then
            if not config then return end
            gModelAds:OpenAdByCommonTips(490004,{
                adMethodId = adMethodId,
                refId = refId,
                openADFunc = function()
                    gModelAds:OpenAd({
                        refId = config.refId,
                    })
                end,
                jumpCB = function()
                    self:WndClose()
                end,
            })
        else
            if itemId > 0 and num < consume then
                gModelGeneral:OpenGetWayWnd({ itemId = itemId })
            elseif (isRemain and remain <= 0) then
                GF.ShowMessage(ccClientText(13013))
            else
                gModelGoldBuy:GoldBuyReq(itemdata.refId)
            end
        end
    end)
end
----------------------------------------- 金币特效动画 --------------------------------------
function UIGBuy:ChangeTime(key)
    local curTime = GetTimestamp()
    local time = self._nextResetTime - curTime
    local timer = self._timerList[key]

    if time > 0 then
        if not timer then
            self:SetTime(key)
            self._timerList[key] = LxTimer.LoopTimeCall(function()
                self:SetTime(key)
            end, 1, false, -1)
        end
        CS.ShowObject(self.mTime, true)


    else
        CS.ShowObject(self.mTime, false)
    end
end

function UIGBuy:SetUPAddNum()
    local isOpen = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK, "goldBuy")
    if not isOpen then
        self.mCommonBg_3.sizeDelta = Vector2.New(596, 805)
        self.mBg2.sizeDelta = Vector2.New(596, 805)
        return
    end
    local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.COMMONRANK)
    if not dataList or #dataList == 0 then
        return
    end
    local isEnd = false
    for i, v in ipairs(dataList) do
        if isEnd then
            break
        end
        local moreInfo = JSON.decode(v.moreInfo)
        local needTask = moreInfo["goldBuy"]
        if needTask then
            isEnd = v.status ~= 1 and v.endTime - GetTimestamp() < 0
        end
    end
    if isEnd then
        return
    end

    local goldBuyUPAddList = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }
    for i, data in ipairs(dataList) do
        local dataTable = JSON.decode(data.moreInfo)
        local goldBuyUPAddStr = dataTable.goldBuy
        if goldBuyUPAddStr then
            local upAddList = string.split(goldBuyUPAddStr, ",") or {}
            goldBuyUPAddList[1] = goldBuyUPAddList[1] + tonumber(upAddList[1])
            goldBuyUPAddList[2] = goldBuyUPAddList[2] + tonumber(upAddList[2])
            goldBuyUPAddList[3] = goldBuyUPAddList[3] + tonumber(upAddList[3])
        end
    end

    for i, trans in ipairs(self._upAddTransList) do
        local index = #goldBuyUPAddList
        local num = tonumber(goldBuyUPAddList[i] or 0)
        if i <= index and num > 0 then
            local AddNum = CS.FindTrans(trans, "AddNum")
            self:SetWndText(AddNum, string.replace(ccClientText(13009), num))
            CS.ShowObject(trans, true)
        else
            CS.ShowObject(trans, false)
        end
    end
    self.mCommonBg_3.sizeDelta = Vector2.New(596, 852)
    self.mBg2.sizeDelta = Vector2.New(596, 852)
end

UIGBuy.EFF_PATCH_CLICK = "fx_xuyuanchi_xuyuanjinbi_attack"
UIGBuy.EFF_PATCH_BULLET = "fx_xuyuanchi_xuyuanjinbi_bullet"
UIGBuy.EFF_PATCH_HIT = "fx_xuyuanchi_xuyuanjinbi_hit"

function UIGBuy:Reset(pb)
    self:InitDate(pb)
end

function UIGBuy:ClearAllGoldHUD()
    if self._goldHUDList then
        for i, v in ipairs(self._goldHUDList) do
            v:Destroy()
        end
        self._goldHUDList = {}
    end
end

function UIGBuy:OnTimer(key)
    if key == self._goldCheckKey then
        self:CheckUIGoldClear()
    elseif key == self._timerPrivileKey then
        --gModelBackflow:SetPrivileBtn(self.mBtnPrivile,10,self)
        -- local priviCom = self:GetPrivilegeCom()
        -- priviCom:Create(self.mBtnPrivile, 10, self)
    end
end

function UIGBuy:OnClickPrivilege()
    -- GF.OpenWnd("WndTreasureSkillEffectShowPop", {
    --     refId = ModelTreasure.TREASURE_SKILL_1403,
    -- })
    --local isAct = gModelTreasure:CheckTreasureIsAct(UIGBuy.TREASURE_ACT)
    --if isAct then
    --	GF.OpenWnd("UIGdItemSow")
    --else
    --	local jump = gModelTreasure:GetTreasureConfigRefByKey("jump")
    --	local isOpen = gModelFunctionOpen:CheckIsOpened(jump,true)
    --	if isOpen then
    --		gModelFunctionOpen:Jump(jump)
    --	end
    --end
end

-- 获取水池落点
function UIGBuy:GetPoint(t, startPoint, targetPoint, mTopPos)
    local a = 1 - t
    local target = nil

    startPoint.z = 0
    targetPoint.z = 0
    target = (startPoint * Mathf.Pow(a, 2)) + (mTopPos * 2 * t * a) + (targetPoint * Mathf.Pow(t, 2))
    return target
end

function UIGBuy:CheckUIGoldClear()
    if self._goldHUDList then
        local list = self._goldHUDList
        local len = #list
        for i = len, 1, -1 do
            local gold = list[i]
            if gold:IsPlayEnd() then
                gold:Destroy()
            end
            if gold:IsDelete() then
                table.remove(list, i)
            end
        end
    end
end

function UIGBuy:InitMsg()
    self:WndNetMsgRecv(LProtoIds.GoldBuyDetailResp, function(pb)
        self:Reset(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.GoldBuyResp, function(pb)
        self:CreateGoldClickEff(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.TreasureSkillResp, function(pb)
        self:RefreshAureole()
    end)

    self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function(...)
        --购买了特权后刷新
        gModelGoldBuy:GoldBuyDetailReq()
    end)

    --self:WndEventRecv(EventNames.PLAYER_VIP_LEVEL_CHANGE,function ()
    --	gModelGoldBuy:GoldBuyDetailReq()
    --end)

    --self:WndEventRecv(EventNames.On_Item_Change,function()
    --	gModelGoldBuy:GoldBuyDetailReq()
    --end)

    self:WndEventRecv(EventNames.REFRESH_ADS, function()
        local uiList = self._uiList
        if not uiList then return end
        local _uiList = uiList:GetList()
        if _uiList then
            _uiList:RefreshList()
        end
    end)
end

-- 金币移动
function UIGBuy:GoldMove()
    local destoryList = {}

    if not self._goldEffDataList then
        return
    end
    local curTime = Time.time
    for i, data in ipairs(self._goldEffDataList) do

        local calcTime = data.playTime - curTime
        local isMove = calcTime > 0 and true or false
        if isMove then
            local rate = calcTime / self._moveTime
            local point = self:GetPoint(rate, data.tarTrans.position, data.startTrans.position, data.mTopPos)
            local size = rate * 100
            if point then
                data.effect.position = point
                data.effect.localScale = Vector3(size, size, 0)
            end
        else
            table.insert(destoryList, i)
        end
    end

    for i, index in ipairs(destoryList) do
        local data = table.remove(self._goldEffDataList, index)
        if data then
            data.effect.localScale = Vector3(0, 0, 0)
            -- self:DestroyWndEffectByKey(UIGBuy.EFF_PATCH_BULLET..data.effKey)
            local key = UIGBuy.EFF_PATCH_HIT .. data.effKey
            -- self:CreateWndEffect(data.tarTrans,UIGBuy.EFF_PATCH_HIT,key,100,false,false)
            local effData = {
                effKey = key,
                time = Time.time + 0.5,
            }

            table.insert(self._hitEffDataList, effData)
            self:GetGold(data.pb)
        end
    end

    local cnt = #self._hitEffDataList
    for k = cnt, 1, -1 do
        local data = self._hitEffDataList[k]
        if data.time <= curTime then
            self:DestroyWndEffectByKey(data.effKey)
            table.remove(self._hitEffDataList, k)
        end
    end

end

function UIGBuy:ClearTimer(index)
    local timerList = self._timerList
    local timer = timerList[index]
    if timer then
        LxTimer.DelayTimeStop(timer)
        timerList[index] = nil
    end
end

function UIGBuy:InitCommand()
    self:RefreshAureole()
    self:SetWndText(self.mLogText, ccClientText(13026))
end

function UIGBuy:OnClickLog()
    GF.OpenWnd("UIGBuyLog")
end

function UIGBuy:GetGold(pb)
    local uiGoldHud = UIGoldHud:New()
    uiGoldHud:Create(self.mGoldList, pb)
    table.insert(self._goldHUDList, uiGoldHud)
end

function UIGBuy:SetTime(key)
    local curTime = GetTimestamp()
    local time = (self._nextResetTime - curTime)

    local str = string.replace(ccClientText(13008), LUtil.FormatTimespanNumber(time))
    self:SetWndText(self.mTimeText, str)
    CS.ShowObject(self.mTime, true)

    if time <= 0 then
        CS.ShowObject(self.mTime, false)
        self:ClearTimer(key)
    end
end

function UIGBuy:InitEvent()
    --self:SetWndClick(self.mGoldBuyLog,function()
    --	GF.OpenWnd("UIGBuyLog")
    --end)
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 24 })
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBG, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mCloseTip, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mPrivilegeBtn, function()
        self:OnClickPrivilege()
    end)
    self:SetWndClick(self.mBtnLog, function()
        self:OnClickLog()
    end)
end

function UIGBuy:KeyValueChange()
    self._effKeyCount = self._effKeyCount + 1
end

-- 添加金币特效数据
function UIGBuy:AddGoldEffData(data)
    if not data then
        return
    end

    table.insert(self._goldEffDataList, data)
end

function UIGBuy:OnAwake()
    LWnd.OnAwake(self)
end

-- 创建金币点击特效(全套)
function UIGBuy:CreateGoldClickEff(pb)
    if not pb then
        return
    end
    local effRes = self._clickGoldEffRes[pb.refId]
    self:CreateWndEffect(self.mGoldEff, effRes, effRes, 100, false, false)

    for i, v in pairs(self._clickEffList) do
        CS.ShowObject(v, false)
    end
    local trans = self._clickEffList[pb.refId]
    local refId = pb.refId
    CS.ShowObject(trans, true)
    self:CreateWndEffect(trans, UIGBuy.EFF_PATCH_CLICK, UIGBuy.EFF_PATCH_CLICK .. refId, 100, false, false)

    self:KeyValueChange()
    local curKey = self._effKeyCount
    local startTrans = trans
    local bulletFunc = function(effect)
        CS.ShowObject(effect, true)
        local tarTrans = self._hitPosList[math.random(1, 10)]
        local topPosX = Mathf.Lerp(startTrans.position.x, tarTrans.position.x, 0.5)
        local mTopPos = Vector3(topPosX + self._offectX, 0, 0)

        local data = {
            playTime = Time.time + self._moveTime,
            startTrans = startTrans,
            tarTrans = tarTrans,
            effect = effect,
            pb = pb,
            mTopPos = mTopPos,
            effKey = curKey,
        }
        self:AddGoldEffData(data)
    end

    local key = UIGBuy.EFF_PATCH_BULLET .. curKey
    self:CreateWndEffect(trans, UIGBuy.EFF_PATCH_BULLET, key, 100, false, false, 0, bulletFunc)
end

function UIGBuy:RefreshAureole()
    -- local refId = ModelTreasure.TREASURE_SKILL_1403
    -- local treasureData = gModelTreasure:GetTreasureServerDataByRefId(refId)
    -- local status,a2,a3,a4 = gModelTreasure:JudgeTreasureStatusNoAboutItem(treasureData)
    -- local tImg = ""
    -- local isActvite = status >= ModelTreasure.ARTICLE_STATUS_ACTIVITY
    -- CS.ShowObject(self.mSkillEff,isActvite)
    -- CS.ShowObject(self.mStatueImg,isActvite)
    -- if isActvite then
    -- 	--已经激活		等特效
    -- 	tImg = "goldbuy_txt_7"
    -- 	self:CreateWndEffect(self.mSkillEff,"fx_xuyuanguanghuan","fx_xuyuanguanghuan",100)
    -- else
    -- 	--未激活		等特效
    -- 	tImg = "goldbuy_txt_6"
    -- end
    -- self:SetWndEasyImage(self.mAureoleImg,tImg,function ()
    -- 	CS.ShowObject(self.mAureoleImg,true)
    -- end,true)
end

function UIGBuy:InitDate(pb)
    self._goldBuyDates = gModelGoldBuy:GetGoldItemList()
    -- 曾超要求三个档位刷新时间会同步配置，只需要读取第一个档位的倒计时即可
    self._nextResetTime = pb.items[1].nextResetTime
    self:ChangeTime("gold")

    self:SetWndText(self.mLblBiaoti, ccClientText(13000))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    --VIP加成
    self.goldBuyBonus = (gModelVip:GetGoldBuyBonusInVipEff() or 0) * 100 .. "%"

    --挂机收益
    local timeCount = GameTable.MainInstanceConfigRef["TimeCount"]
    local isVipEff, addPercent = gModelVip:GetIsHookInVipEff()
    addPercent = addPercent or 0
    local cfg = gModelInstance:GetCurMissionCfg(1)
    if cfg and self.goldBuyBonus then
        local itemList = gModelInstance:GetMissionTimeRewardFix(cfg.refId)
        for i, v in ipairs(itemList) do
            if v.itemId == 101001 then
                local value = v.itemNum * (1 + addPercent) * 3600 / timeCount
                value = LUtil.NumberCoversion(value)
                local text = ccClientText(13007)
                text = string.replace(ccClientText(13007), value, gModelPlayer:GetVipLevel(), self.goldBuyBonus)
                self:SetWndText(self.mAdditionText, text)
                break
            end
        end
    end
    local list = {}
    for i, v in pairs(self._goldBuyDates) do
        table.insert(list, v)
    end
    if (self._uiList) then
        self._uiList:RefreshList(list)
    else
        self._uiList = self:GetUIScroll("cell")
        self._uiList:Create(self.mCellScroll, list, function(...)
            self:ListItem(...)
        end)

    end

    self:SetUPAddNum()
end

----------------------------------------- 金币特效动画 --------------------------------------
-- 开启动画播放
function UIGBuy:StartPlayEff()
    local key = "playGoldEffect"
    self._timerList[key] = LxTimer.LoopTimeCall(function()
        self:GoldMove()
    end, 0.000001, false, -1)
end
------------------------------------------------------------------
return UIGBuy


