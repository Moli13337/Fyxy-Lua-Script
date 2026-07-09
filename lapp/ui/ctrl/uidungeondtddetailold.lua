---
--- Created by Administrator.
--- DateTime: 2023/10/20 19:36:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDungeonDTDDetailOld:LWnd
local UIDungeonDTDDetailOld = LxWndClass("UIDungeonDTDDetailOld", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDungeonDTDDetailOld:UIDungeonDTDDetailOld()
    ---@type UIItemList
    self._dungeonList = nil -- 仅仅是一个引用，不需要自己销毁，从基类里获得的引用

    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDungeonDTDDetailOld:OnWndClose()
    gModelDungeonDaily:SetCurSelect(nil)
    FireEvent(EventNames.ON_BRAVE_MSG_RET)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDungeonDTDDetailOld:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDungeonDTDDetailOld:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:InitData()
    self:SetPara()
    self:InitUIEvent()
    self:ShowTypeList()
    self:ShowTop()
    self:ShowContent()

    self:WndEventRecv(EventNames.ON_BRAVE_MSG_RET, function(pb)
        self:Refresh(pb)
    end)
    self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE, function()
        gModelDungeonDaily:RecordCurChallenge(nil)
    end)

    self:WndEventRecv(EventNames.ON_BRAVE_SWEEP_RET, function(...)
        self:OnSweepResp(...)
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        gModelDungeonDaily:DailyBraveMessageReq(self._curSelect)
    end)
    self:WndEventRecv(EventNames.PLAYER_VIP_LEVEL_CHANGE, function()
        gModelDungeonDaily:DailyBraveMessageReq(self._curSelect)
    end)

    gModelDungeonDaily:DailyBraveMessageReq(self._curSelect)
    gModelDungeonDaily:SetCurSelect(self._curSelect)

    self:RefreshTypeListRedPoint()

    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshTypeListRedPoint() end)
end

function UIDungeonDTDDetailOld:InitUIEvent()
    self:SetWndClick(self.mCloseBtn, function()

        local isFromJump = self:GetWndArg("isFromJump")
        if not isFromJump then
            FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
            GF.OpenWnd("UIOutts")
            gModelDungeonDaily:RecordCurChallenge(nil)
        else
            GF.OpenWndBottom("UIOutts",{ childIndex = 1 })
            FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
        end

        self:WndClose()
    end)

    self:SetWndClick(self.mOneKey, function()
        self:OneKeySweep()
    end)

    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 4 })
    end)
end

function UIDungeonDTDDetailOld:ShowTypeList()
    local typeList = gModelDungeonDaily:GetTypeConfig()
    local list = self:GetUIScroll("typeList")
    list:Create(self.mTypeList, typeList, function(...)
        self:OnDrawType(...)
    end)
end

function UIDungeonDTDDetailOld:ShowDungeonList()
    local dungeonList = gModelDungeonDaily:GetDungeonListByType(self._curSelect)
    self._netData = gModelDungeonDaily:GetDungeonDataByType(self._curSelect)

    local dungeonList = self:SortDungeonList(dungeonList)

    local list = self._dungeonList
    if list then
        list:RefreshList(dungeonList)
        list:DrawAllItems(true)
    else
        list = self:GetUIScroll("dungeonList")
        list:Create(self.mDungeonList, dungeonList, function(...)
            self:OnDrawDungeon(...)
        end, UIItemList.SUPER)
        list:EnableScroll(true, false)
        self._dungeonList = list
    end
    self._curIndex = 1

    --list:Create(self.mDungeonList,dungeonList,function (...) self:OnDrawDungeon(...) end)


    --local uiList = list:GetList()
    --local curIndex = self._curIndex or 1
    --uiList:DelayScrollTo(curIndex,UIListEasy.SCROLL_TOP)

    --uiList:SetContentPosition(0,1)
    --+ self._netData.freeSweepCount
    local leftTimes = self._netData.sweepCount - self._netData.beSweepCount
    leftTimes = leftTimes < 0 and 0 or leftTimes
    local str = tostring(leftTimes)
    if leftTimes == 0 then
        str = LUtil.FormatColorStr(str, "red")
    end
    str = ccClientText(12801, str) --今日剩余挑战次数：%s

    self:SetWndText(self.mLeftTimes, str)

    local wndName = self:GetWndName()
    self:SendGuideReadyEvent(wndName)
end

function UIDungeonDTDDetailOld:SetPara()
    local page = self:GetWndArg("page")
    if page then
        local type = self._pageToType[page]
        self._curSelect = type
    end

    if not self._curSelect then
        self._curSelect = gModelDungeonDaily:GetCurChallenge()
    end

    if not self._curSelect then
        self._curSelect = ModelDungeonDaily.GOLD
    end


end

function UIDungeonDTDDetailOld:OnDrawDungeon(list, item, itemdata_new, itempos)

    local itemdata = itemdata_new.itemdata

    local bg = self:FindWndTrans(item, "bg")
    local titleBg = self:FindWndTrans(item, "titleBg")
    local titleBgLevel = self:FindWndTrans(titleBg, "level")
    local itemList = self:FindWndTrans(item, "itemList")
    local passTag = self:FindWndTrans(item, "passTag")
    local challengeBtn = self:FindWndTrans(item, "challengeBtn")
    local challengeBtnLayout = self:FindWndTrans(challengeBtn, "layout")
    local layoutIcon = self:FindWndTrans(challengeBtnLayout, "icon")
    local layoutText = self:FindWndTrans(challengeBtnLayout, "text")
    local tip = self:FindWndTrans(item, "tip")

    local challengeBtn_En = self:FindWndTrans(challengeBtn, "layoutEn")
    local challengeBtn_text_En = self:FindWndTrans(challengeBtn_En, "text")
    local challengeBtnLayout_En = self:FindWndTrans(challengeBtn_En, "layout")
    local layoutIcon_En = self:FindWndTrans(challengeBtnLayout_En, "icon")
    local layoutText_En = self:FindWndTrans(challengeBtnLayout_En, "text")

    --这里做一个设置 多语言 layoutIcon
    layoutIcon = self._isEnus and layoutIcon_En or layoutIcon
    layoutText = self._isEnus and layoutText_En or layoutText

    local challengeBtnRedPoint = self:FindWndTrans(challengeBtn, "redPoint")

    if self._isEnus then
        CS.ShowObject(challengeBtn_En,true)
        else
        CS.ShowObject(challengeBtn_En,false)
    end

    CS.ShowObject(challengeBtnRedPoint, false)

    self:SetWndEasyImage(challengeBtn, "public_btn_2_2")

    local refId = itemdata
    local cfg = gModelDungeonDaily:GetDungeonCfgByRefId(itemdata)
    if not cfg then
        return
    end

    local str = ccLngText(cfg.titleName)
    self:SetWndText(titleBgLevel, str)

    local bgPath = cfg.titleBg
    self:SetWndEasyImage(titleBg, bgPath)

    local reward = gModelDungeonDaily:GetDungeonReward(itemdata)
    local instanceId = item:GetInstanceID()
    local uiIconEasyList = self._dungeonList:GetItemCls(instanceId)
    if not uiIconEasyList then
        uiIconEasyList = UIIconEasyList:New()
        self._dungeonList:SetItemCls(instanceId, uiIconEasyList)
        uiIconEasyList:Create(self, itemList)
        uiIconEasyList:SetIconParentPath("root")
    end
    uiIconEasyList:RefreshList(reward)

    --local refId = cfg:get_refId()
    local curNode = self._netData.sweepNode

    local showPass = false
    local showTip = false
    local showBtn = false
    local showIcon = false

    local tipStr = nil
    local btnStr = nil
    local iconId = nil
    local btnStr_2 = nil
    local freeGet = self._netData.beSweepCount < self._netData.freeSweepCount   --当前拥有的免费的次数

    --判断是否为第一关
    local isFirst = gModelDungeonDaily:IsFirstNode(refId)

    if curNode <= 0 then
        local isPass, info = gModelDungeonDaily:IsLimited(refId)
        if not isPass then
            tipStr = info
            showTip = true
        else
            if isFirst then
                btnStr = ccClientText(12802)---"挑战"
                showBtn = true

                --判断下 是否打开过
                local isRed = gModelDungeonDaily:CheckShowDungeonRed_New_2(self._curSelect)
                CS.ShowObject(challengeBtnRedPoint, isRed)
            else
                tipStr = ccClientText(12803) --"请先通关上一关"
                showTip = true
            end
        end
    else
        local nextNode = gModelDungeonDaily:GetNextId(curNode)
        if refId < curNode then
            showPass = true
        elseif refId == curNode then
            self._curIndex = itempos
            local cost = gModelDungeonDaily:GetSweepCost(self._netData)
            if cost.itemNum == 0 or freeGet then
                btnStr = ccClientText(12804) --"免费扫荡"
                CS.ShowObject(challengeBtnRedPoint, true)
            else
                iconId = cost.itemId
                btnStr = ccClientText(12805, cost.itemNum) --%s 扫荡
                showIcon = true

                if self._netData.beSweepCount >= self._netData.sweepCount then
                    --public_btn_2_2  public_btn_ash_2
                    self:SetWndEasyImage(challengeBtn, "public_btn_ash_2")
                end

                if self._isEnus then
                    btnStr = cost.itemNum
                    btnStr_2 = ccClientText(44067)
                end
            end
            showBtn = true
        elseif refId == nextNode then
            local isPass, info = gModelDungeonDaily:IsLimited(refId)
            if not isPass then
                tipStr = info
                showTip = true
            else
                btnStr = ccClientText(12802) -- "挑战"
                showBtn = true

                local isRed = gModelDungeonDaily:CheckShowDungeonRed_New_2(self._curSelect)
                CS.ShowObject(challengeBtnRedPoint, isRed)
            end
        elseif refId > nextNode then
            local isPass, info = gModelDungeonDaily:IsLimited(refId)
            if not isPass then
                tipStr = info
                showTip = true
            else
                tipStr = ccClientText(12803) --"请先通关上一关"
                showTip = true
            end
        end
    end

    CS.ShowObject(passTag, showPass)
    CS.ShowObject(challengeBtn, showBtn)
    CS.ShowObject(tip, showTip)
    self:SetWndText(tip, tipStr)

    if iconId then
        local iconPath, iconBgPath = gModelItem:GetItemImgByRefId(iconId)
        if iconPath then
            self:SetWndEasyImage(layoutIcon, iconPath)
        end
    end
    CS.ShowObject(layoutIcon, showIcon)

    if showIcon and self._isEnus then
        CS.ShowObject(layoutText,true)
        self:SetWndText(layoutText, btnStr)
        self:SetWndText(challengeBtn_text_En, btnStr_2)

    elseif self._isEnus then
        CS.ShowObject(layoutText,false)
        self:SetWndText(challengeBtn_text_En, btnStr)

    else
        self:SetWndText(layoutText, btnStr)
    end

    self:SetWndClick(challengeBtn, function()
        self:OnClickDungeon(itemdata)
    end)
end

function UIDungeonDTDDetailOld:OnDrawType(list, item, itemdata)
    local bg = self:FindWndTrans(item, "bg")
    local bgIcon = self:FindWndTrans(bg, "icon")
    local bgName = self:FindWndTrans(bg, "name")
    local bgLock = self:FindWndTrans(bg, "lock")
    local redPoint = self:FindWndTrans(bg, "redPoint")
    local select = self:FindWndTrans(bg, "select")
    local isSelect = itemdata == self._curSelect

    CS.ShowObject(select, isSelect)
    local cfg = ModelDungeonDaily:GetTypeConfigByType(itemdata)

    local negativeName = cfg.negativeName

    local namePath = negativeName
    self:SetWndEasyImage(bgName, namePath)

    local funcOpenId = gModelDungeonDaily:GetTypeFunctionOpen(itemdata)

    local isOpen, msg = gModelFunctionOpen:CheckIsOpened(funcOpenId)
    CS.ShowObject(bgLock, not isOpen)
    local color = Color.New(1, 1, 1, 1)
    if not isOpen then
        color = Color.New(1, 1, 1, 0.5)
    end

    self:SetWndImageColor(bg, color)

    self._typeUIList[itemdata] = item

    --printInfoN2("cjh------","wnddungeondailydetailold ,this check  function id is ".. tostring(funcOpenId))

    self:SetWndClick(bg, function()
        if isOpen then
            self:OnSelectChange(itemdata)
        else
            GF.ShowMessage(msg)
        end
    end)

    if not self._typeRedpointTrans then
        self._typeRedpointTrans = {}
    end

    self._typeRedpointTrans[itemdata] = redPoint
end

function UIDungeonDTDDetailOld:InitData()
    self._typeUIList = {}

    self._pageToType = {
        [1] = ModelDungeonDaily.GOLD,
        [2] = ModelDungeonDaily.EXP,
        [3] = ModelDungeonDaily.HERO,
        --[4] = ModelDungeonDaily.WEAPON,
        [4] = ModelDungeonDaily.RUNE,

    }
end

function UIDungeonDTDDetailOld:Refresh(pb)
    local type = pb.braveType
    if type ~= self._curSelect then
        return
    end

    self:ShowDungeonList()

    self:RefreshOneKeyRedPoingt()
    self:RefreshTypeListRedPoint()
end

function UIDungeonDTDDetailOld:RefreshTypeListRedPoint()
    if nil == self._typeRedpointTrans or #self._typeRedpointTrans == 0 then
        return
    end

    for k, v in ipairs(self._typeRedpointTrans) do
        local isShow = false

        local isFreeGetRedpoint = gModelDungeonDaily:CheckShowDungeonRed_New_1(k)
        local isNewChallenge = gModelDungeonDaily:CheckShowDungeonRed_New_2(k)

        isShow = isFreeGetRedpoint

        if not isShow then
            isShow = isNewChallenge
        end

        CS.ShowObject(v, isShow)

    end
end

function UIDungeonDTDDetailOld:OnSweepResp(pb)
    local type = pb.braveType
    if type == self._curSelect then
        self:ShowDungeonList()
        self:RefreshOneKeyRedPoingt()
    end
end

function UIDungeonDTDDetailOld:RefreshOneKeyRedPoingt()
    local isRed = gModelDungeonDaily:CheckShowDungeonRed_New_1(self._curSelect)

    CS.ShowObject(self.mOneKeyRedPoint, isRed)

    --

    if self._netData.beSweepCount >= self._netData.sweepCount then
        --public_btn_ash_1
        self:SetWndEasyImage(self.mOneKey, "public_btn_ash_1")
    else
        self:SetWndEasyImage(self.mOneKey, "public_btn_1_2")
        --public_btn_1_2
    end
end

function UIDungeonDTDDetailOld:ShowContent()


    local funcCfg = gModelFunctionOpen:GetFunctionOpenCfg(12400000)
    local str
    if funcCfg then
        str = ccLngText(funcCfg.name)
    else
        str = ccClientText(12806) -- "日常副本"  -- 更改为读funcname的名字
    end
    self:SetWndText(self.mTitleText, str)
    str = ccClientText(12807) --"挑战不消耗次数"
    self:SetWndText(self.mChallengeTip, str)
    str = ccClientText(12822) --"一键扫荡"
    self:SetWndText(self.mOneKeyTxt, str)

    if self._isEnus then
        self:InitTextSizeWithLanguage(self.mOneKeyTxt, -6)
        self:InitTextLineWithLanguage(self.mOneKeyTxt, -30)
    end
end

function UIDungeonDTDDetailOld:OnSelectChange(type)
    if self._curSelect == type then
        return
    end
    local oldType = self._curSelect
    local oldItem = self._typeUIList[oldType]

    self._curSelect = type
    if oldItem then
        self:OnDrawType(nil, oldItem, oldType)
    end
    local newItem = self._typeUIList[type]
    if newItem then
        self:OnDrawType(nil, newItem, type)
    end

    self:ShowTop()

    gModelDungeonDaily:DailyBraveMessageReq(self._curSelect)
    gModelDungeonDaily:SetCurSelect(self._curSelect)
end

function UIDungeonDTDDetailOld:Challenge(refId)
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_DUNGEON_DAILY, { dungeonId = refId })
    gModelDungeonDaily:RecordCurChallenge(self._curSelect)

    --gModelDungeonDaily:OpenChallengTypeCache(self._curSelect)
    --记录refId
    gModelDungeonDaily:OpenChallengTypeCache(refId)
    self:WndClose()
end

function UIDungeonDTDDetailOld:ShowTop()
    local cfg = gModelDungeonDaily:GetTypeConfigByType(self._curSelect)
    local bgpath = cfg.titlePic
    if bgpath then
        self:SetWndEasyImage(self.mTopBg, bgpath)
    end
    local str = ccLngText(cfg.name)
    self:SetWndText(self.mName, str)
end

function UIDungeonDTDDetailOld:OneKeySweep()
    if not self._netData then
        return
    end
    local cost = gModelDungeonDaily:GetSweepCost(self._netData)
    local curNode = self._netData.sweepNode
    if curNode <= 0 then
        GF.ShowMessage(ccClientText(12809))--无关卡可扫荡
        return
    end
    local type = self._curSelect
    if cost.itemNum == 0 or self._netData.beSweepCount < self._netData.freeSweepCount then
        local wndId = 90003
        local func = function()
            gModelDungeonDaily:DailyBraveSweepReq(type, 3, curNode)
        end
        local func1 = function()
            gModelDungeonDaily:DailyBraveSweepReq(type, 2, curNode)
        end
        local timesCnt, totalCost = gModelDungeonDaily:GetOneKeyCost(self._netData, false)
        local para = { timesCnt, totalCost }
        local timesCnt1, totalCost1 = gModelDungeonDaily:GetOneKeyCost(self._netData, true)
        local para1 = { timesCnt1, totalCost1 }
        local args = {
            refId = wndId,
            func = func,
            para = para,
            extraChoice = {
                func = func1,
                para = para1,
            }
        }
        gModelGeneral:OpenUIOrdinTips(args)

    else
        if self._netData.beSweepCount >= self._netData.sweepCount then

            return   --扫荡不可以购买
            --local canUpgrade = gModelVip:CanUpgrade()
            --if canUpgrade then
            --    local wndId = 90002
            --    local func = function()
            --        GF.OpenWndBottom("UIHuiYPay", { page = 2 })
            --    end
            --    local args = {
            --        refId = wndId,
            --        func = func,
            --    }
            --    gModelGeneral:OpenUIOrdinTips(args)
            --
            --else
            --    GF.ShowMessage(ccClientText(12808))
            --end
        else
            local wndId = 90004
            local timesCnt, totalCost = gModelDungeonDaily:GetOneKeyCost(self._netData, false)
            local func = function()
                gModelDungeonDaily:DailyBraveSweepReq(type, 3, curNode)
            end
            local args = {
                refId = wndId,
                func = func,
                para = { timesCnt, totalCost }
            }
            gModelGeneral:OpenUIOrdinTips(args)

        end
    end
end

function UIDungeonDTDDetailOld:SortDungeonList(list)
    local showlist = {}
    local curIndex = 1

    local curNode = self._netData.sweepNode
    local nextNode = curNode + 1
    for k, v in ipairs(list) do
        local data = {}
        data.itemdata = v
        data.sort = v

        if v == curNode then
            --免费扫荡 + 10
            curIndex = k
            data.sort = data.sort + 10
        elseif v < curNode then
            --已经通关 + 10000
            data.sort = data.sort + 10000
        elseif v == nextNode then
            --可以挑战 + 100
            data.sort = data.sort + 100

        elseif v > nextNode then
            --要先挑战上一关  + 1000
            data.sort = data.sort + 1000
        end

        table.insert(showlist, data)
    end
    table.sort(showlist, function(a, b)
        return a.sort < b.sort
    end)

    return showlist, curIndex
end

function UIDungeonDTDDetailOld:SweepSingle()
    if not self._netData then
        return
    end
    local cost = gModelDungeonDaily:GetSweepCost(self._netData)
    local curNode = self._netData.sweepNode
    local type = self._curSelect
    local sweepType = 1
    if cost.itemNum == 0 or self._netData.beSweepCount < self._netData.freeSweepCount then
        gModelDungeonDaily:DailyBraveSweepReq(type, sweepType, curNode)
    else
        if self._netData.beSweepCount >= self._netData.sweepCount then
            --local canUpgrade = gModelVip:CanUpgrade()
            --if canUpgrade then
            --    local wndId = 90002
            --    local func = function()
            --        GF.OpenWndBottom("UIHuiYPay", { page = 2 })
            --    end
            --    local args = {
            --        refId = wndId,
            --        func = func,
            --    }
            --    gModelGeneral:OpenUIOrdinTips(args)
            --
            --else
            --    GF.ShowMessage(ccClientText(12808)) --"已经没有次数啦~"
            --end
        else
            local wndId = 90001
            local func = function()
                gModelDungeonDaily:DailyBraveSweepReq(type, sweepType, curNode)
            end
            local args = {
                refId = wndId,
                func = func,
                para = { cost.itemNum }
            }
            gModelGeneral:OpenUIOrdinTips(args)

        end
    end
end

function UIDungeonDTDDetailOld:OnDrawItem(list, item, itemdata)
    local root = self:FindWndTrans(item, "root")
    local baseClass = CommonIcon:New()
    baseClass:ShowItemData({
        root = root,
        itemType = itemdata.itemType,
        itemId = itemdata.itemId,
        itemNum = itemdata.itemNum,
    })
    self:SetIconClickScale(root, true)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
end

function UIDungeonDTDDetailOld:OnClickDungeon(refId)
    local curNode = self._netData.sweepNode
    if curNode <= 0 then
        local isPass, info = gModelDungeonDaily:IsLimited(refId)
        if isPass then
            local isFirst = gModelDungeonDaily:IsFirstNode(refId)
            if isFirst then
                self:Challenge(refId)
            end
        end
    else
        local nextNode = gModelDungeonDaily:GetNextId(curNode)
        if refId == curNode then
            self:SweepSingle()
        elseif refId == nextNode then
            local isPass, info = gModelDungeonDaily:IsLimited(refId)
            if isPass then
                self:Challenge(refId)
            end
        end

        --self:Challenge(refId)
    end

end

------------------------------------------------------------------
return UIDungeonDTDDetailOld


