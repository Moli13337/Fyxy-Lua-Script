---
--- Created by Administrator.
--- DateTime: 2024/7/24 17:30:16
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubOuttsPvEEnter:LChildWnd
local UISubOuttsPvEEnter = LxWndClass("UISubOuttsPvEEnter", LChildWnd)

---定义常量
UISubOuttsPvEEnter.Enter_1 = 101     --無盡誘惑
UISubOuttsPvEEnter.Enter_2 = 104      --駕馭龍姬
UISubOuttsPvEEnter.Enter_3 = 106      --攻略芳心
UISubOuttsPvEEnter.Enter_4 = 107      --少女密室
UISubOuttsPvEEnter.Enter_5 = 109     --少女神跡
UISubOuttsPvEEnter.Enter_6 = 10101     --暧昧游戏



UISubOuttsPvEEnter.pageDailyGameEnterType = 1
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubOuttsPvEEnter:UISubOuttsPvEEnter()
    self._timeList = {}
    self._timeKey = "dungeonDailyTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubOuttsPvEEnter:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubOuttsPvEEnter:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubOuttsPvEEnter:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        self:SetWndEasyImage(self.mBg, "fish_bg_big_4", nil, false, true)
    end

    self:InitEntranceConstValue()

    self:InitData()

    self:InitItems()

    self:InitEvent()
    self:DoReq()

    self:UpdateAllItems()
    self:DoChildReq()
    self:StartLoadEffect()
    --printInfoN2("----------cjh ---------redpoint--10100001", gModelRedPoint:CheckShowRedPoint(10100001))
    --printInfoN2("----------cjh ---------redpoint--17100000", gModelRedPoint:CheckShowRedPoint(17100000))  -- 钻石秘境
    --printInfoN2("----------cjh ---------redpoint--33000001", gModelRedPoint:CheckShowRedPoint(33000001))  -- 方块大师
    --
    --printInfoN2("----------cjh ---------redpoint--33000002", gModelRedPoint:CheckShowRedPoint(33000002))  -- 方块大师
    
    self:SetWndEasyImage(self.mBg,"suburb_pve_big_bg",function() 
        CS.ShowObject(self.mBg,true)
    end)
end

function UISubOuttsPvEEnter:DoChildReq()
    local isOpen = gModelFunctionOpen:CheckIsOpened(12400000, false)
    if isOpen then
        for i = 1, 4 do
            gModelDungeonDaily:DailyBraveMessageReq(i)
        end
    end
end

function UISubOuttsPvEEnter:InitEvent()
    self:WndNetMsgRecv(LProtoIds.DailyGameInfoResp, function(pb)
        local refId = pb.infos[1].refId
        if not self._moduleDataList[refId] then
            return
        end

        self:OnDailyGameInfoResp(pb)
    end)

    self:WndNetMsgRecv(LProtoIds.TowerInfoResp, function(pb)
        --爬塔数据变化请求更新一下入口
        gModelGeneral:OnDailyGameInfoReq({ UISubOuttsPvEEnter.Enter_4 })
    end)

    for k, v in pairs(self._itemTransList) do
        self:SetWndClick(v, function()
            self:OnClickItem(k)
        end)
    end

    self:WndEventRecv(EventNames.ON_BRAVE_MSG_RET, function(pb)
        self:RefreshSpecialRedPoint()
    end)

    self:WndEventRecv(EventNames.FISH_BASE_INFO, function(pb)
        --self:UpdateAllItems()
        self:RefreshSpecialRedPoint()
    end)

    self:WndEventRecv(EventNames.ON_BATTLE_FINISHED, function(combatType, winner)
        --self:UpdateAllItems()
        self:UpdateAllItems()
    end)
    self:WndEventRecv(EventNames.START_BATTLE_State, function(combatType, winner)
        --self:UpdateAllItems()
        self:UpdateAllItems()
    end)
end

function UISubOuttsPvEEnter:SetExtraTxt(tranRoot, tranTxt, dataInfo)
    --是否为时间
    if dataInfo.isTime then
        -- 把时间解析出来 然后记录到一个timelist部分
        local data = { tranTxt = tranTxt, dataInfo = dataInfo }
        self._timeList[dataInfo.refId] = data
    else
        --先解析
        local textStr
        if dataInfo.isSpecial then
            textStr = dataInfo.text
        else
            local dataValue = string.split(dataInfo.textValue, "=")

            textStr = string.replace(dataInfo.text, dataValue[1], dataValue[2])
        end

        self:SetWndText(tranTxt, textStr)
    end

    CS.ShowObject(tranRoot, true)
end

function UISubOuttsPvEEnter:RefreshSpecialRedPoint()
    if self._specialRedTran then
        for k, v in pairs(self._specialRedTran) do
            CS.ShowObject(v.redtran, v.func())
        end

    end
end

function UISubOuttsPvEEnter:InitData()
    local itemList = {
        [UISubOuttsPvEEnter.Enter_1] = self.mEnter_1,
        [UISubOuttsPvEEnter.Enter_2] = self.mEnter_2,
        [UISubOuttsPvEEnter.Enter_3] = self.mEnter_3,
        [UISubOuttsPvEEnter.Enter_4] = self.mEnter_4,
        [UISubOuttsPvEEnter.Enter_5] = self.mEnter_5,
        [UISubOuttsPvEEnter.Enter_6] = self.mEnter_6,
    }

    self._itemTransList = itemList

    self._moduleDataList = {}
    for k, v in ipairs(gModelDailyGameEnter:GetEnterList(UISubOuttsPvEEnter.pageDailyGameEnterType)) do
        self._moduleDataList[v.refId] = v
    end

    --特效节点的缓存
    self._enterEffect = {}

    self._enterEffectShowFunc = {
        [UISubOuttsPvEEnter.Enter_1] = function()
            return false
        end,
        [UISubOuttsPvEEnter.Enter_2] = function()
            return false
        end,
        [UISubOuttsPvEEnter.Enter_3] = function()
            return false
        end,
        [UISubOuttsPvEEnter.Enter_4] = function()
            return false
        end,
        [UISubOuttsPvEEnter.Enter_5] = function()
            return false
        end,
        [UISubOuttsPvEEnter.Enter_6] = function()
            return false
        end,
    }
end

function UISubOuttsPvEEnter:IsInFight(combatCfg)
    local inFight = false
    local combatTypeArr = string.split(combatCfg, ",")
    local combatType = nil
    for i, v in ipairs(combatTypeArr) do
        combatType = tonumber(v)
        inFight = gLFightManager:IsCombatTypeInFight(combatType)
        if inFight then
            break
        end
    end
    return inFight, combatType
end

function UISubOuttsPvEEnter:OnTryRefreshRedPoint(redPointType)
    self:RefreshSpecialRedPoint()
end

function UISubOuttsPvEEnter:OnEffectLoaded()

    local seq = self:GetSeqCom()
    local key = "guochangdonghua_2"
    local sequence = seq:CreateSeq(key)
    sequence:AppendInterval(0.8)
    sequence:AppendCallback(function()
        local func = self._hidEndFunc
        if func then
            func()
        end
    end)
    sequence:AppendInterval(0.76)
    sequence:OnComplete(function()
        seq:DeleteSeq(key)
        --self:WndClose()

        CS.ShowObject(self.mEnterDiv, true)
    end)
    sequence:PlayForward()
end

--region 初始化 --------------------------------------------------------------------------------
function UISubOuttsPvEEnter:InitEntranceConstValue()
    local pveEnterConstValue = GameTable.DailyGamePlayConfigRef["pveEntranceConstant"]

    pveEnterConstValue = string.split(pveEnterConstValue, "=")

    UISubOuttsPvEEnter.Enter_1 = checknumber(pveEnterConstValue[1])--無盡誘惑
    UISubOuttsPvEEnter.Enter_2 = checknumber(pveEnterConstValue[2])      --駕馭龍姬
    UISubOuttsPvEEnter.Enter_3 = checknumber(pveEnterConstValue[3])      --攻略芳心
    UISubOuttsPvEEnter.Enter_4 = checknumber(pveEnterConstValue[4])      --少女密室
    UISubOuttsPvEEnter.Enter_5 = checknumber(pveEnterConstValue[5])     --無限絕色
    UISubOuttsPvEEnter.Enter_6 = checknumber(pveEnterConstValue[6])     --暧昧游戏

end

--region 界面的过场动效 --------------------------------------------------------------------------------
function UISubOuttsPvEEnter:StartLoadEffect()
    --波光特效 常驻
    self:CreateWndEffect(self.mShuiguangEffRoot, "fx_ui_PVE_map", "fx_ui_PVE_map", 100)

    --一次性过程特效
    local isFirst = gModelDailyGameEnter:GetIsFirstOpenPvp()

    if not isFirst then
        CS.ShowObject(self.mEnterDiv, true)
        return
    end
    CS.ShowObject(self.mEnterDiv, false)
    gModelDailyGameEnter:SetIsFirstOpenPvp(false)

    self:CreateWndEffect_Ex({
        trans = self.mGuochangdonghuaRoot,
        effName = "guochangdonghua_2",
        effKey = "guochangdonghua_2",
        bDefaultSortNum = 3,
        endFunc = function()
            self:OnEffectLoaded()
        end,
    })
end

function UISubOuttsPvEEnter:SetEnterInfo_2()
    -- key 还是 refId
    for k, v in pairs(self._itemContentList) do

        --check是否开启
        local isOpen = true
        local openid = v.functionId
        if openid and openid > 0 then
            isOpen = gModelFunctionOpen:CheckIsOpened(openid)
        end

        if isOpen then

            local data = self._enterInfo[k]
            if not data then
                return
            end
            for i = 1, data.count do
                --

                local tranRoot = i == 1 and v.extraInfo or v.extraInfo_2
                local tranTxt = i == 1 and v.extraTxt or v.extraTxt_2
                local dataInfo = i == 1 and data.text1Data or data.text2Data

                self:SetExtraTxt(tranRoot, tranTxt, dataInfo)

            end

        end

    end
end

function UISubOuttsPvEEnter:InitItems()
    local template = self.mEnterTemplate
    local itemContentList = {}

    for k, v in pairs(self._itemTransList) do

        local item = LxResUtil.NewObject(template, nil, true)
        item.name = template.name
        CS.SetParentTrans(item, v)
        CS.ShowObject(item, true)

        local bg = CS.FindTrans(item, "bg")
        local text = CS.FindTrans(item, "text")
        local redPoint = CS.FindTrans(item, "redPoint")

        local lock_bg = CS.FindTrans(item, "lock_bg")
        local lock = CS.FindTrans(item, "LockDiv/lock")
        local lock_Text = CS.FindTrans(item, "LockDiv/lock_Text")

        local extraInfo = CS.FindTrans(item, "extraInfo_1")
        local extraTxt = CS.FindTrans(extraInfo, "extraTxt")

        local extraInfo_2 = CS.FindTrans(item, "extraInfo_2")
        local extraTxt_2 = CS.FindTrans(extraInfo_2, "extraTxt")

        local fightEffect = CS.FindTrans(item, "FightEffect")

        local itemContentTrans = { parent = v, item = item, bg = bg, text = text, redPoint = redPoint,
                                   lock_bg = lock_bg, lock_Text = lock_Text, lock = lock, extraInfo = extraInfo,
                                   extraTxt = extraTxt, extraInfo_2 = extraInfo_2, extraTxt_2 = extraTxt_2, fightEffect = fightEffect,
                                   isGray = false }

        itemContentList[k] = itemContentTrans

        --创建effect 顺便key的值为type
        local effectRoot = CS.FindTrans(item, "openEffect")

        self._enterEffect[k] = self:CreateWndEffect(effectRoot, "fx_jianzhurukou", item.name .. k, 100, nil, nil, 1, nil, nil, true)
        local showEffect = self._enterEffectShowFunc[k]()
        self._enterEffect[k]:SetVisible(showEffect)
    end

    self._itemContentList = itemContentList

    --开个计时器
    local _timeKey = self._timeKey
    if not self:IsTimerExist(_timeKey) then
        self:TimerStart(_timeKey, 1, false, -1)
    end
end
--endregion --------------------------------------------------------------------------------------

--region 事件部分 --------------------------------------------------------------------------------
--event
function UISubOuttsPvEEnter:OnDailyGameInfoResp(pb)
    --data type --StructDailyGameInfo
    self._infoList = gModelGeneral:GetDailyGameInfoResp(pb, self._infoList)

    self:SetEnterInfo()
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UISubOuttsPvEEnter:UpdateAllItems()
    for k, v in pairs(self._itemContentList) do
        self:OnDrawItem(v, self._moduleDataList[k])
    end
end

--信息请求
function UISubOuttsPvEEnter:DoReq()
    local refList = gModelDailyGameEnter:GetEnterList(UISubOuttsPvEEnter.pageDailyGameEnterType)
    local list = {}
    for i, v in pairs(refList) do
        if v.style == 1 then
            --这里只做1  样式的信息请求
            table.insert(list, v.refId)
        end
    end
    gModelGeneral:OnDailyGameInfoReq(list)
end

function UISubOuttsPvEEnter:SetEnterInfo()
    self._enterInfo = {}
    --遍历列表
    for k, v in pairs(self._moduleDataList) do

        if not self._infoList[k] then
            --空数据为组合数据不做处理
        else
            local funcList = gModelDailyGameEnter:GetItemInfoFunc(k)
            local text1Data = {}
            local text2Data = {}
            local count = 0
            if not string.isempty(v.timeText) then
                --先从特殊部分去拿    没有的话就从infoList 去取信息 还没有就不做显示
                if funcList then
                    --时间部分 不进行特殊处理
                else
                    --  v.timeText
                    text1Data.refId = self._infoList[k].refId
                    text1Data.text = ccLngText(v.timeText)
                    text1Data.isTime = true
                    text1Data.textValue = self._infoList[k].timeText
                end
                if not string.isempty(text1Data.textValue) then
                    --如果时间没有，则用第一条消息进行填充
                    count = count + 1
                end
            end

            if not string.isempty(v.text1) then
                --填充到1 位置还是2位置
                local data = count == 0 and text1Data or text2Data

                if funcList and funcList.text1 then
                    --特殊处理
                    data.refId = self._infoList[k].refId
                    data.text = funcList.text1(self._infoList[k].text1, ccLngText(v.text1))
                    data.isSpecial = true  --特殊处理标识
                else
                    --
                    data.refId = self._infoList[k].refId
                    data.text = ccLngText(v.text1)
                    data.isTime = false
                    data.textValue = self._infoList[k].text1

                    if string.isempty(data.textValue) then
                        data.textValue = 0
                    end
                end
                count = count + 1
            end

            if count == 2 then
                --不填充这个信息
            else
                if not string.isempty(v.text2) then
                    local data = count == 0 and text1Data or text2Data

                    if funcList and funcList.text2 then
                        --特殊处理
                        data.refId = self._infoList[k].refId
                        data.text = funcList.text2(self._infoList[k].text2, ccLngText(v.text2))
                        data.isSpecial = true  --特殊处理标识
                    else
                        --
                        data.refId = self._infoList[k].refId
                        data.text = ccLngText(v.text2)
                        data.isTime = false
                        data.textValue = self._infoList[k].text2

                        if string.isempty(data.textValue) then
                            data.textValue = 0
                        end
                    end
                    count = count + 1
                end
            end

            self._enterInfo[k] = {
                count = count,
                text1Data = text1Data,
                text2Data = text2Data,
            }
        end

        --printInfoN2("----解析完", "-----------------开始设置")
        self:SetEnterInfo_2()
    end
end

function UISubOuttsPvEEnter:SetGray(refId, isGray)
    local item = self._itemContentList[refId]
    if not item then
        return
    end
    if item.isGray == isGray then
        return
    end
    item.isGray = isGray
    CS.ShowObject(item.lock, isGray)
    CS.ShowObject(item.lock_Text, isGray)
    CS.ShowObject(item.lock_bg, isGray)
    CS.ShowObject(item.text, not isGray)
    CS.ShowObject(item.bg, not isGray)
end
--endregion --------------------------------------------------------------------------------------

--开计时器
function UISubOuttsPvEEnter:OnTimer(key)
    if (self._timeKey == key) then
        self:SetTime()
    end
end

--ui
function UISubOuttsPvEEnter:OnClickItem(refId)
    if not self._moduleDataList or not self._moduleDataList[refId] then
        return
    end

    local moduleData = self._moduleDataList[refId]
    local openId = moduleData.functionId
    local bOpen = gModelFunctionOpen:CheckIsOpened(openId, true)
    if not bOpen then
        return
    end

    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_PLAY, refId)

    local combatTypeCfg = moduleData.combatType
    local inFight, combatType = self:IsInFight(combatTypeCfg)
    if inFight then
        gLFightManager:PrepareGoToBattle(combatType, {})
        return
    end

    if moduleData.style == 3 then
        --这里打开列表部分
        GF.OpenWnd("UIOuttsList", { listRefId = refId })
    else
        if UISubOuttsPvEEnter.Enter_4 == refId then
            local combatList = gModelFunctionOpen:GetFuncRelaCombat(openId)
            for k, v in pairs(combatList) do
                if gLFightManager:IsCombatTypeInFight(k) then
                    gLFightManager:PrepareGoToBattle(k, {})
                    return
                end
            end
            local isOpent = gModelTower:GetIsUnlockRaceTower()
            if not isOpent then
                GF.OpenWndBottom("UITaWin")
            else
                GF.OpenWndBottom("UITaRacePopNew")
            end
        else
            if refId == UISubOuttsPvEEnter.Enter_3 then
                if gModelBadgeGame:CheckIsOpenNightmare() then
                    GF.OpenWnd("UIBadgeGameSelect")
                    return
                end
            end
            gModelFunctionOpen:Jump(openId, "UIOutts")
        end
    end
end

function UISubOuttsPvEEnter:SetTime()
    -- self._timeList 遍历数据 然后设置
    for k, v in pairs(self._timeList) do
        --取到时间
        local timeValue = v.dataInfo.textValue

        if not string.isempty(timeValue) then
            local timespan = (tonumber(timeValue) or 0) / 1000 - GetTimestamp()
            if timespan < 0 then
                --空 则显示已经结束  28502
                self:SetWndText(v.tranTxt, ccClientText(28502))  --[28502]	[已結束]
            else

                local timeStr = LUtil.FormatTimespanCn(timespan)

                local str = string.replace(v.dataInfo.text, timeStr)
                self:SetWndText(v.tranTxt, str)  --[28502]	[已結束]
            end

        else
            --空 则显示已经结束  28502
            self:SetWndText(v.tranTxt, ccClientText(28502))  --[28502]	[已結束]
        end
    end
end

function UISubOuttsPvEEnter:OnDrawItem(item, itemdata)
    if not itemdata then
        CS.ShowObject(item.parent, false)
        return
    end

    local moduleRef = itemdata
    local refId = itemdata.refId
    local name = ccLngText(moduleRef.name)
    self:SetWndText(item.text, name)
    self:SetWndText(item.lock_Text, name)

    local openid = moduleRef.functionId
    local isOpen = true
    if openid and openid > 0 then
        isOpen = gModelFunctionOpen:CheckIsOpened(openid)
    end
    self:SetGray(refId, not isOpen)

    if itemdata.redPoint == 1 then
        if not self._specialRedTran then
            self._specialRedTran = {}
        end
        local data = {}
        data.redtran = item.redPoint
        data.func = gModelDailyGameEnter:GetItemCheckSpecialRedpointFunc(refId)
        self._specialRedTran[refId] = data
    else
        self:RegisterFuncItemRed(openid, item.redPoint)
    end

    --local redPointId = self._itemRedList[refId]
    --local showRed = false
    --if redPointId and isOpen then
    --    showRed = gModelRedPoint:CheckShowRedPoint(redPointId)
    --end
    --CS.ShowObject(item.redPoint, showRed)
    local combatType = itemdata.combatType
    local inFight = false
    if combatType ~= "" then

        local combatTypeArr = string.split(combatType, ",")
        for i, v in ipairs(combatTypeArr) do
            inFight = gLFightManager:IsCombatTypeInFight(tonumber(v))
            if inFight then
                break
            end
        end
        if inFight then
            self:CreateWndEffect(item.fightEffect, "jian", "chapter" .. refId, 100, false, false, nil, nil, nil, nil, nil, nil, 10)
        end
    end

    CS.ShowObject(item.fightEffect, inFight)

end


--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UISubOuttsPvEEnter