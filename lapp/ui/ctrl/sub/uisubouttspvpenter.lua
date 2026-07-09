---
--- Created by admin-pc.
--- DateTime: 2024/5/11 18:19:37
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubOuttsPvpEnter:LChildWnd
local UISubOuttsPvpEnter = LxWndClass("UISubOuttsPvpEnter", LChildWnd)

local UnityEngine = UnityEngine
local typeUIImage = typeof(UnityEngine.UI.Image)

---定义常量
UISubOuttsPvpEnter.ARENA_RANK = 201     --勇者杯-排位赛
UISubOuttsPvpEnter.ARENA_PEAK = 202     --神裔爵位赛-巅峰赛
UISubOuttsPvpEnter.CROSS_GRADING = 203     --王国爵位赛-段位赛
UISubOuttsPvpEnter.CROSS_LADDER = 204
UISubOuttsPvpEnter.CROSS_CHAMPION = 205 --女神宫殿-武神殿
UISubOuttsPvpEnter.SIMULATE = 206         --龙裔圣杯-奥兹模拟
UISubOuttsPvpEnter.NV_SHEN_GUIGUAN = 207     --女神桂冠
UISubOuttsPvpEnter.PET_COPY = 208     --萌宠幻境
UISubOuttsPvpEnter.CARE_SCHOOL = 209     --骑士教学
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubOuttsPvpEnter:UISubOuttsPvpEnter()
    self._cdPetTimerKey = "_cdPetTimerKey"
    --- 萌宠倒计时时间
    self._petTimerInfo = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubOuttsPvpEnter:OnWndClose()
    LChildWnd.OnWndClose(self)

    self:TimerStop(self._timeKey)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubOuttsPvpEnter:OnCreate()
    LChildWnd.OnCreate(self)
    self:SetWndSwitchType(LChildWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubOuttsPvpEnter:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    -------------------
    self:InitEntranceConstValue()

    self:InitData()

    self:InitEntranceConstValue()

    self:DoInitReq()

    self:InitBtnEvent()
    self:InitMsgEvent()
    self:InitView()
    self:StartLoadEffect()

    self:TimerStop(self._timeKey)
    self:TimerStart(self._timeKey, 1, false, -1)

    self:RefreshChildRedPoints()

    printInfoN2("----------cjh ---------redpoint--19100000", gModelRedPoint:CheckShowRedPoint(19100000))
end

function UISubOuttsPvpEnter:ShowPetCopy(type, parentRoot, itemContentTrans)
    local otherData = self._otherShowDatas[type]
    if not otherData then
        return
    end

    local otherRoot = CS.FindTrans(parentRoot, "otherRoot")
    local showOther = otherData.showOther
    local modelRef = self._moduleDataList[type]
    if not modelRef then
        showOther = false
    end
    --CS.ShowObject(otherRoot,showOther)
    if not showOther then
        return
    end

    local effRoot = CS.FindTrans(otherRoot, "effRoot")

    --local showOtherEff = gModelPetDreanLand:DreamLandIsOpen()
    --- 2024/6/24：特效要加一下 常驻的
    local showOtherEff = false
    if not string.isempty(otherData.showEffName) then
        showOtherEff = true
        self:CreateWndEffect_Ex({
            trans = effRoot,
            effKey = otherData.effectKey,
            effName = otherData.showEffName,
        })
    end
    CS.ShowObject(effRoot, showOtherEff)

    local imgRoot = CS.FindTrans(otherRoot, "imgRoot")
    if not string.isempty(otherData.showImgName) then
        self:SetWndEasyImage(imgRoot, otherData.showImgName, function()
            CS.ShowObject(imgRoot, true)
        end, true)
    else
        CS.ShowObject(imgRoot, false)
    end

    local openid = modelRef.functionId
    local isOpen = true
    if openid and openid > 0 then
        isOpen = gModelFunctionOpen:CheckIsOpened(openid)
    end

    local showTimeDiv = isOpen
    local TimeDiv = CS.FindTrans(otherRoot, "TimeDiv")
    local TimeTxt = CS.FindTrans(TimeDiv, "TimeTxt")
    --if showTimeDiv then
    --    local timeStr = self:GetPetDreamLandTimer()
    --    self:SetWndText(TimeTxt,timeStr)
    --
    --    showTimeDiv = timeStr ~= nil or timeStr ~= ""
    --end
    --CS.ShowObject(TimeDiv,showTimeDiv)

    local extraInfo = itemContentTrans.extraInfo
    local extraTxt = itemContentTrans.extraTxt

    local showNameBg = isOpen

    --[[
        --- 修改成默认样式
        local NameBg = CS.FindTrans(otherRoot,"NameBg")
        local Name = CS.FindTrans(NameBg,"Name")]]

    local NameBg = extraInfo
    local Name = extraTxt
    --if showNameBg then
    --    local showName = self:GetPetDreamLandName()
    --    self:SetWndText(Name,showName)
    --
    --    showNameBg = showName ~= nil or showName ~= ""
    --end

    local timeStr_temp, isOpen = gModelPetDreanLand:GetShowDreamLandTimerStr()
    local timeStr = isOpen and ccClientText(40302) or ccClientText(40303)
    timeStr = string.replace(timeStr, timeStr_temp)

    self:SetWndText(Name, timeStr)
    CS.ShowObject(NameBg, true)

    self._petTimerInfo = {
        TimeDiv = TimeDiv,
        TimeTxt = TimeTxt,
        NameBg = NameBg,
        Name = Name, -- 改为显示时间
    }
    --CS.ShowObject(otherRoot,showOther)

    self:TimerStop(self._cdPetTimerKey)
    self:TimerStart(self._cdPetTimerKey, 1, false, -1)

end

function UISubOuttsPvpEnter:GetPetDreamLandName()
    if not gModelPetDreanLand:CheckIsOpenGame() then
        return
    end
    local longestPointData = gModelPetDreanLand:GetPlayerOccupyLongestTimeData()
    if longestPointData then
        local name = gModelPetDreanLand:GetPetDreamlandName(longestPointData.refId)
        ---@type V_DailyGameRef
        local ref = gModelDungeonDaily:GetDailyGameConfig(UISubOuttsPvpEnter.PET_COPY)
        local str = ref and ccLngText(ref.text1) or ccClientText(43387)
        --local str = ccClientText(43402)
        return string.replace(str, name)
    else
        return string.replace(ccClientText(43387), ccClientText(43388))
    end
end

function UISubOuttsPvpEnter:OnTryRefreshRedPoint(...)
    self:RefreshItemRedPoint(...)
end

function UISubOuttsPvpEnter:RefreshChildRedPointByRefId(refId)
    local childRedPoints = self._childRedPointsMap[refId]
    if not childRedPoints or #childRedPoints < 1 then
        return
    end

    local itemContent = self._itemContentList[refId]
    if not itemContent then
        return
    end

    local redPointTrans = itemContent.redPoint
    if not CS.IsValidObject(redPointTrans) then
        return
    end

    local isShow = false
    for i, redpointId in ipairs(childRedPoints) do
        isShow = gModelRedPoint:CheckShowRedPoint(redpointId)
        if isShow then
            if LOG_INFO_ENABLED then
                printInfoNR2("子红点检查：", ">> 可显示红点id：" .. redpointId)
            end
            break
        end
    end

    CS.ShowObject(redPointTrans, isShow)
end

function UISubOuttsPvpEnter:UpdateView()
    self:UpdateAllItems()
end


function UISubOuttsPvpEnter:InitView()
    self:InitItems()
    self:UpdateView()
end

function UISubOuttsPvpEnter:InitEntranceConstValue()
    local pvpEntranceConstant = GameTable.DailyGamePlayConfigRef["pvpEntranceConstant"]

    pvpEntranceConstant = string.split(pvpEntranceConstant, "=")

    UISubOuttsPvpEnter.ARENA_RANK = checknumber(pvpEntranceConstant[1])     --勇者杯-排位赛
    UISubOuttsPvpEnter.ARENA_PEAK = checknumber(pvpEntranceConstant[2])        --神裔爵位赛-巅峰赛
    UISubOuttsPvpEnter.CROSS_GRADING = checknumber(pvpEntranceConstant[3])        --王国爵位赛-段位赛
    UISubOuttsPvpEnter.CROSS_LADDER = checknumber(pvpEntranceConstant[4])
    UISubOuttsPvpEnter.CROSS_CHAMPION = checknumber(pvpEntranceConstant[5])    --女神宫殿-武神殿
    UISubOuttsPvpEnter.SIMULATE = checknumber(pvpEntranceConstant[6])            --龙裔圣杯-奥兹模拟
    UISubOuttsPvpEnter.NV_SHEN_GUIGUAN = checknumber(pvpEntranceConstant[7])        --女神桂冠
    UISubOuttsPvpEnter.PET_COPY = checknumber(pvpEntranceConstant[8])        --萌宠幻境
    UISubOuttsPvpEnter.CARE_SCHOOL = checknumber(pvpEntranceConstant[9])        --骑士教学

end

function UISubOuttsPvpEnter:InitData()

    --条目的文本说明
    self._peakStageStr = {
        ccClientText(11800),
        ccClientText(11801),
        ccClientText(11802),
        ccClientText(11803),
        ccClientText(11804),
        ccClientText(11805),
    }
    --红点的获取对应的功能ID  常量和功能id的对应
    self._itemRedList = {
        [UISubOuttsPvpEnter.CROSS_LADDER] = 13300000,
        [UISubOuttsPvpEnter.CROSS_CHAMPION] = 13800000,
        [UISubOuttsPvpEnter.ARENA_RANK] = 13100000,
        [UISubOuttsPvpEnter.ARENA_PEAK] = 13200000,
        [UISubOuttsPvpEnter.CROSS_GRADING] = 13600000,
        [UISubOuttsPvpEnter.PET_COPY] = ModelFunctionOpen.PET_DREAMLAND,
        [UISubOuttsPvpEnter.CARE_SCHOOL] = 19100000,
        [UISubOuttsPvpEnter.SIMULATE] = 13900000,
    }

    --功能id和常量的对应 _itemRedList 的k 和 v 反过来
    self._redIdToItemList = {}
    for k, v in pairs(self._itemRedList) do
        self._redIdToItemList[v] = k
    end

    -- self._itemRedList 不能满足的话，或 红点表不配置 功能id 或者 父节点 ，由程序定位的红点
    self._childRedPointsMap = {
        [UISubOuttsPvpEnter.PET_COPY] = {
            ModelRedPoint.PDT_NOT_OCCUPY, ModelRedPoint.PDT_NEW_REPORT_1, ModelRedPoint.PDT_NEW_REPORT_2,
            ModelRedPoint.PDT_FREE_CALL, ModelRedPoint.PDT_HAS_CALLNUM,
        }
    }

    --定义定时器的key
    self._rankTimerKey = "rankTimerKey"
    self._peakTimerKey = "peakTimerKey"
    self._crossChampionTimerKey = "_crossChampionTimerKey"
    self._timeKey = "UISubOuttsPvpEnter_TimeKey" -- 每隔1S刷新一次
    self._timeTransInfo = {}   -- 倒计时的控件 和对应的timeSpain

    self._timerTransMap = {}

    local itemList = {
        [UISubOuttsPvpEnter.ARENA_RANK] = self.mYongZheBei,
        [UISubOuttsPvpEnter.CROSS_GRADING] = self.mWangGuoJueWei,
        [UISubOuttsPvpEnter.ARENA_PEAK] = self.mShenYiJueWei,
        [UISubOuttsPvpEnter.NV_SHEN_GUIGUAN] = self.mNvShenGuiGuan,
        [UISubOuttsPvpEnter.CROSS_CHAMPION] = self.mNvShenGongDian,
        [UISubOuttsPvpEnter.PET_COPY] = self.mMengChongHuanJing,
        [UISubOuttsPvpEnter.SIMULATE] = self.mLongYiShenBei,
        [UISubOuttsPvpEnter.CARE_SCHOOL] = self.mCareSchool,
    }

    self._itemTransList = itemList

    --特效节点的缓存
    self._enterEffect = {}

    --特效是否开启的方法
    self._enterEffectShowFunc = {
        [UISubOuttsPvpEnter.ARENA_RANK] = function()
            return false
        end,
        [UISubOuttsPvpEnter.CROSS_GRADING] = function()
            return false
        end,
        [UISubOuttsPvpEnter.ARENA_PEAK] = function()
            local state = gModelArena:GetPeakState()
            return state == 2
        end,
        [UISubOuttsPvpEnter.NV_SHEN_GUIGUAN] = function()
            return false
        end,
        [UISubOuttsPvpEnter.CROSS_CHAMPION] = function()
            return false
        end,
        [UISubOuttsPvpEnter.PET_COPY] = function()
            return gModelPetDreanLand:DreamLandIsOpen()
        end,
        [UISubOuttsPvpEnter.SIMULATE] = function()
            return false
        end,
        [UISubOuttsPvpEnter.CARE_SCHOOL] = function()
            return false
        end,
    }

    self._otherShowDatas = {
        [UISubOuttsPvpEnter.PET_COPY] = {
            --showImgName = "worldcopy_pvp_ad_1",
            --showEffName = "fx_ui_mchj_men",
            --effectKey = "otherEffect_" .. UISubOuttsPvpEnter.PET_COPY,
            checkShowEffFunc = function()
                return gModelPetDreanLand:DreamLandIsOpen()
            end,
            showNameStrFunc = function()

            end,
            showTimeStrFunc = function()

            end,
            timeCdFunc = function()

            end,
            showOther = true,
        }
    }

    --排行榜的数据
    self._rankList = {}
    self._rankGameType = {
        [1] = UISubOuttsPvpEnter.CROSS_LADDER,
        [2] = UISubOuttsPvpEnter.CROSS_CHAMPION,
    }

    self._moduleDataList = {}
    for k, v in ipairs(gModelDailyGameEnter:GetEnterList(UISubOuttsPvpEnter.PageType)) do
        self._moduleDataList[v.refId] = v
    end
end


--endregion --------------------------------------------------------------------------------------



--region timer  --------------------------------------------------------------------------------
function UISubOuttsPvpEnter:OnTimer(key)
    local timerItem = self._timerTransMap[key]
    if timerItem then
        local refId = timerItem.refId
        local timeInfoTrans

        local moduleData = self._moduleDataList[refId]
        if moduleData then
            timeInfoTrans = self._itemContentList[refId]
            if timeInfoTrans then
                local seasonEndTime = timerItem.time
                local nowTime = GetTimestamp()
                local timespan = seasonEndTime - nowTime

                local timeStr = nil
                if timerItem.formatFun then
                    timeStr = timerItem.formatFun(timespan)
                else
                    timeStr = LUtil.FormatTimespanCn(timespan)
                end
                timeStr = LUtil.FormatColorStr(timeStr, "lightGreen")
                timeStr = timerItem.title .. timeStr

                self:SetWndText(timeInfoTrans, timeStr)
                if timespan <= 0 then
                    self:TimerStop(key)
                end
            end
        end
    end

    if key == self._timeKey then
        self:CutDownTime()
    elseif key == self._cdPetTimerKey then
        self:OnTimerPetOther()
    end
end

function UISubOuttsPvpEnter:DoInitReq()
    --请求子类节点的信息
    gModelArena:ShowPersonalPeakAccount()
    gModelArena:OnPlayerArenaReq(true)
    gModelArena:PinnaclePaceStateReq()
    if gModelFunctionOpen:CheckIsOpened(13900000) then
        gModelCrossWar:CrossWarTempleStateReq()
    end

    for k, v in ipairs(self._rankGameType) do
        gModelRank:OnGameRankReq(k)
    end

    local formation = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_ARENA_DEFEND)
    if not formation then
        gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_ARENA_DEFEND)
    end
end

--刷新Item的特效
function UISubOuttsPvpEnter:RefreshEnterEffect(refId)
    local showEffect = self._enterEffectShowFunc[refId]()
    self._enterEffect[refId]:SetVisible(showEffect)
end

--endregion ----------------------------------------------------    ----------------------------------

--region 红点控制 --------------------------------------------------------------------------------
function UISubOuttsPvpEnter:RefreshItemRedPoint(redPointType)
    local refId = self._redIdToItemList[redPointType]
    if not refId then
        return
    end
    local itemContent = self._itemContentList[refId]
    if not itemContent then
        return
    end
    local redPointTrans = itemContent.redPoint
    if CS.IsValidObject(redPointTrans) then
        local isShow = gModelRedPoint:CheckShowRedPoint(redPointType)
        CS.ShowObject(redPointTrans, isShow)
    end
    self:RefreshChildRedPointByRefId(redPointType)
end

function UISubOuttsPvpEnter:OnTimerPetOther()
    if not self._petTimerInfo then
        return
    end

    if not gModelFunctionOpen:CheckIsOpened(self._itemRedList[UISubOuttsPvpEnter.PET_COPY]) then
        return
    end

    local timeStr_temp, isOpen = gModelPetDreanLand:GetShowDreamLandTimerStr()
    local timeStr = isOpen and ccClientText(40302) or ccClientText(40303)
    timeStr = string.replace(timeStr, timeStr_temp)
    local petTimerInfo = self._petTimerInfo
    self:SetWndText(petTimerInfo.Name, timeStr)
    CS.ShowObject(petTimerInfo.NameBg, true)
    --local moduleRef = self._moduleDataList[UISubOuttsPvpEnter.PET_COPY]
    --local openid = moduleRef.functionId
    --local isOpen = true
    --if openid and openid > 0 then
    --    isOpen = gModelFunctionOpen:CheckIsOpened(openid)
    --end
    --
    --local petTimerInfo = self._petTimerInfo
    --
    --local showTimeDiv = isOpen
    --if showTimeDiv then
    --    local timeStr = self:GetPetDreamLandTimer()
    --    self:SetWndText(petTimerInfo.TimeTxt,timeStr)
    --
    --    showTimeDiv = timeStr ~= nil or timeStr ~= ""
    --end
    --CS.ShowObject(petTimerInfo.TimeDiv,showTimeDiv)
    --
    --local showNameBg = isOpen
    --if showNameBg then
    --    local showName = self:GetPetDreamLandName()
    --    self:SetWndText(petTimerInfo.Name,showName)
    --
    --    showNameBg = showName ~= nil or showName ~= ""
    --end
    --CS.ShowObject(petTimerInfo.NameBg,showNameBg)
end

function UISubOuttsPvpEnter:IsInFight(combatCfg)
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

function UISubOuttsPvpEnter:UpdateLockState(refId)
    local data = self._moduleDataList[refId]
    if not data then
        return
    end

    local openid = data.functionId
    local isOpen = true
    if openid and openid > 0 then
        isOpen = gModelFunctionOpen:CheckIsOpened(openid)
    end
    self:SetGray(refId, not isOpen)
end

--刷新按钮
function UISubOuttsPvpEnter:UpdateAllItems()
    for k, v in pairs(self._itemContentList) do

        self:OnDrawItem(v, self._moduleDataList[k])

    end
end

--region 页面的处理 --------------------------------------------------------------------------------
function UISubOuttsPvpEnter:UpdateAllItemLock()
    for k, v in pairs(self._moduleDataList) do
        self:UpdateLockState(v.refId)
    end
end

--endregion --------------------------------------------------------------------------------------

--region 界面的过场动效 --------------------------------------------------------------------------------
function UISubOuttsPvpEnter:StartLoadEffect()
    --波光特效 常驻
    self:CreateWndEffect(self.mShuiguangEffRoot, "fx_PVPchangjing", "fx_PVPchangjing", 100)

    --一次性过程特效
    local isFirst = gModelDailyGameEnter:GetIsFirstOpenPvp()

    if not isFirst then
        return
    end

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

function UISubOuttsPvpEnter:RefreshChildRedPoints()
    for refId, childRedPoints in pairs(self._childRedPointsMap) do
        self:RefreshChildRedPointByRefId(refId)
    end
end
function UISubOuttsPvpEnter:SetGray(refId, isGray)
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

    --这里统一判断是否显示吧

    if isGray then

        local moduleData  = self._moduleDataList[refId]
        local openId = moduleData.functionId
        if gModelFunctionOpen:CheckIsShow(openId) then
            --
            CS.ShowObject(item.parent,true)
        else
            --不显示就隐藏

            CS.ShowObject(item.parent,false)
        end
    end
end
--item元素的点击方法
function UISubOuttsPvpEnter:OnClickItem(refId)
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

    if refId == UISubOuttsPvpEnter.SIMULATE then
        local state = gModelCrossWar:GetState()
        if state == 0 then
            GF.ShowMessage(ccClientText(43830))
            return
        elseif state == 3 then
            GF.ShowMessage(ccClientText(11812))
            return
        end
    end

    if moduleData.subset == 1 then

    else
        gModelFunctionOpen:Jump(openId, "UIOutts")
    end

    if refId == UISubOuttsPvpEnter.PET_COPY then
        gModelRedPoint:SetRedPointClicked(ModelRedPoint.PDT_NOT_OCCUPY)
    end
end

function UISubOuttsPvpEnter:InitBtnEvent()
    for k, v in pairs(self._itemTransList) do
        self:SetWndClick(v, function()
            self:OnClickItem(k)
        end)
    end
end

function UISubOuttsPvpEnter:InitItems()
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
        local lock_div =CS.FindTrans(item,"LockDiv")
        local lock = CS.FindTrans(lock_div, "lock")
        local lock_Text = CS.FindTrans(lock_div, "lock_Text")

        local extraInfo = CS.FindTrans(item, "extraInfo")
        local extraTxt = CS.FindTrans(extraInfo, "extraTxt")

        local fightEffect = CS.FindTrans(item, "FightEffect")
        local itemContentTrans = { parent = v, item = item, bg = bg, text = text, redPoint = redPoint,
                                   lock_bg = lock_bg, lock_Text = lock_Text, lock = lock, extraInfo = extraInfo,
                                   extraTxt = extraTxt, fightEffect = fightEffect,
                                   isGray = false }

        itemContentList[k] = itemContentTrans

        --创建effect 顺便key的值为type
        local effectRoot = CS.FindTrans(item, "openEffect")

        if k == UISubOuttsPvpEnter.PET_COPY then
            self:ShowPetCopy(k, v, itemContentTrans)
        end

        self._enterEffect[k] = self:CreateWndEffect(effectRoot, "fx_jianzhurukou", item.name .. k, 100, nil, nil, 1, nil, nil, true)
        local showEffect = self._enterEffectShowFunc[k]()
        self._enterEffect[k]:SetVisible(showEffect)
    end
    self._itemContentList = itemContentList
end

function UISubOuttsPvpEnter:CutDownTime()
    for k, v in pairs(self._timeTransInfo) do
        local timeStr = nil
        timeStr = LUtil.FormatTimespanCn(v.timespan)
        timeStr = string.replace(v.timeDes, timeStr)

        self:SetWndText(v.timeTran, timeStr)
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(v.timeTran)
        if v.timespan <= 0 then
            CS.ShowObject(v.timeRoot,false)
            --self._timeTransInfo[k] = nil
        end
    end
end

--  每一个Item的绘制处理
function UISubOuttsPvpEnter:OnDrawItem(item, itemdata)
    if not itemdata then
        CS.ShowObject(item.parent, false)
        return
    end
    local moduleRef = itemdata
    local refId = itemdata.refId
    local titleIcon = moduleRef.titleIcon
    local name = ccLngText(moduleRef.name)
    self:SetWndText(item.text, name)
    self:SetWndText(item.lock_Text, name)

    local openid = moduleRef.functionId
    local isOpen = true
    if openid and openid > 0 then
        isOpen = gModelFunctionOpen:CheckIsOpened(openid)
    end
    self:SetGray(refId, not isOpen)
    local redPointId = self._itemRedList[refId]
    local showRed = false
    if redPointId and isOpen then
        showRed = gModelRedPoint:CheckShowRedPoint(redPointId)
    end
    CS.ShowObject(item.redPoint, showRed)

    local infoFunc = gModelDailyGameEnter:GetItemInfoFunc(refId)
    local infoStr
    local time
    if infoFunc and infoFunc.getInfo then
        infoStr, time = infoFunc.getInfo()
    end

    local timeSpanIsCanShow = true

    if not string.isempty(infoStr) then
        if time then
            --如果是时间的倒计时  i
            local timeData = {}
            timeData.timeRoot = item.extraInfo
            timeData.timeTran = item.extraTxt
            timeData.timeDes = infoStr
            timeData.timespan = time
            self._timeTransInfo[refId] = timeData


            --
            if timeData.timespan <= 0 then
                timeSpanIsCanShow = false
            end
        else
            self:SetWndText(item.extraTxt, infoStr)
            UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(item.extraTxt)
            self._timeTransInfo[refId] = nil
        end

        CS.ShowObject(item.extraInfo, true and isOpen and timeSpanIsCanShow)
        local len = string.len(infoStr) > 40 and 240 or 150
        item.extraInfo.sizeDelta = Vector2.New(len, item.extraInfo.sizeDelta.y)
    else
        CS.ShowObject(item.extraInfo, false)
    end

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

function UISubOuttsPvpEnter:OnEffectLoaded()

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
    end)
    sequence:PlayForward()
end

--- 当前为战斗期则显示本赛季的结束倒计时，当前占领时长最久的幻境模式名称
function UISubOuttsPvpEnter:GetPetDreamLandTimer()
    if not gModelPetDreanLand:CheckIsOpenGame() then
        return
    end
    return gModelPetDreanLand:GetDreamLandDailyGameStr()
end

function UISubOuttsPvpEnter:InitMsgEvent()
    self:WndEventRecv(EventNames.ON_PEAK_STATE_CHANGE, function()
        self:RefreshItemByRefId(UISubOuttsPvpEnter.ARENA_PEAK)
        self:RefreshEnterEffect(UISubOuttsPvpEnter.ARENA_PEAK)

    end)
    self:WndEventRecv(EventNames.ON_CROSS_SERVER_CHAMPION_STATE, function()
        self:RefreshItemByRefId(UISubOuttsPvpEnter.CROSS_CHAMPION)
    end)

    self:WndEventRecv(EventNames.REFRESH_PDL_REDPOINT, function()
        self:RefreshChildRedPointByRefId(UISubOuttsPvpEnter.PET_COPY)
    end)

    self:WndEventRecv(EventNames.ON_CROSS_SERVER_LADDER_INFO, function()
        self:RefreshItemByRefId(UISubOuttsPvpEnter.CROSS_LADDER)
    end)


    self:WndNetMsgRecv(LProtoIds.PlayerArenaResp, function(...)
        self:RefreshItemByRefId(UISubOuttsPvpEnter.ARENA_RANK)
    end)
    self:WndNetMsgRecv(LProtoIds.GetFormationResp, function(pb)
        if pb.type == LCombatTypeConst.COMBAT_ARENA_DEFEND then
            self:RefreshItemByRefId(UISubOuttsPvpEnter.ARENA_RANK)
        end
    end)
    self:WndNetMsgRecv(LProtoIds.GameRankResp, function(...)
        self:OnGameRankResp(...)
    end)

    self:WndNetMsgRecv(EventNames.REFRESH_FUNCTION_STATE, function()
        self:UpdateAllItemLock()
    end)

    self:WndNetMsgRecv(LProtoIds.PinnaclePaceStateResp, function(...)
        self:RefreshItemByRefId(UISubOuttsPvpEnter.ARENA_PEAK)
    end)

    self:WndEventRecv("CrossWarTempleInfoResp", function(...)
        self:RefreshItemByRefId(UISubOuttsPvpEnter.SIMULATE)
    end)

    self:WndEventRecv("CrossWarTempleChallengeListResp", function(...)
        self:RefreshItemByRefId(UISubOuttsPvpEnter.SIMULATE)
    end)

    self:WndEventRecv("CrossWarTempleStateResp", function(...)
        if gModelCrossWar:GetState() == 1 then
            gModelCrossWar:CrossWarTempleInfoReq()
            gModelCrossWar:CrossWarTempleChallengeListReq()
            return
        end
        self:RefreshItemByRefId(UISubOuttsPvpEnter.SIMULATE)
    end)

    self:WndEventRecv(EventNames.REFRESH_PDL_ENTER, function()
        --- 刷新 萌宠幻境
        local type = UISubOuttsPvpEnter.PET_COPY
        local item = self._itemTransList and self._itemTransList[type]
        if not item then
            return
        end
        self:ShowPetCopy(type, item, self._itemContentList[type])
    end)
    self:WndEventRecv(EventNames.WARTEMPLE_INFO_RETURN, function()
        self:RefreshItemByRefId(UISubOuttsPvpEnter.CROSS_CHAMPION)
    end)
end

--刷新item部分
function UISubOuttsPvpEnter:RefreshItemByRefId(refId)
    local moduleData = self._moduleDataList[refId]
    if not moduleData then
        return
    end
    local itemTemplate = self._itemContentList[refId]
    if not itemTemplate then
        return
    end
    self:OnDrawItem(itemTemplate, moduleData)
end

--endregion --------------------------------------------------------------------------------------

--region Server的回调 --------------------------------------------------------------------------------
function UISubOuttsPvpEnter:OnGameRankResp(pb)
    local gameType = pb.GameType
    local data = {
        currentRank = pb.currentRank,
        historyRank = pb.historyRank,
    }

    local rankGameType = self._rankGameType[gameType]
    if not rankGameType then
        if LOG_INFO_ENABLED then
            LogError("self._rankGameType[gameType] is not find, gameType = " .. (gameType or "nil"))
        end
        return
    end

    self._rankList[rankGameType] = data
    self:RefreshItemByRefId(rankGameType)
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISubOuttsPvpEnter