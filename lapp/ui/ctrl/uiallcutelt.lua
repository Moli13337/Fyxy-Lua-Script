---
--- Created by LCM.
--- DateTime: 2024/3/3 10:27:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAllcutelt:LWnd
local UIAllcutelt = LxWndClass("UIAllcutelt", LWnd)

local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)

UIAllcutelt.TYPE_START_RUN = 1       --- 开始执行
UIAllcutelt.TYPE_SHOW_RES = 2        --- 显示结果
UIAllcutelt.TYPE_SHOW_RUN = 3        --- 执行中

---- 0：显示图片，1：显示特效
UIAllcutelt.BATTLE_SHOW_TYPE = 1

UIAllcutelt.BATTLE_IMG_LIST = {
    [ModelGameHelperAlleviation.BATTLE_WIN] = "settlement_txt_2",
    [ModelGameHelperAlleviation.BATTLE_FAIL] = "settlement_txt_3",
}

-- UIAllcutelt.BATTLE_EFF_LIST = {
--     [ModelGameHelperAlleviation.BATTLE_WIN] = "fx_ui_shengli_01",
--     [ModelGameHelperAlleviation.BATTLE_FAIL] = "fx_ui_shibai_01",
-- }

UIAllcutelt.LIST_STATUS_NOTMOVE = 1             --- 不能拖动列表
UIAllcutelt.LIST_STATUS_CANMOVE = 2             --- 能拖动列表



UIAllcutelt.NOT_DEFAULT = 0         --- 没有定义
UIAllcutelt.NOT_REPORT = 1          --- 没有战报返回的情况


UIAllcutelt.LIMIT_MAX_HEIGHT = 365
UIAllcutelt.REWARD_MIN_LINE = 3

local Tweening = DG.Tweening
local YXTween = YXTween
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAllcutelt:UIAllcutelt()
    self._listMoveStatus = UIAllcutelt.LIST_STATUS_NOTMOVE
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAllcutelt:OnWndClose()
    FireEvent(EventNames.ON_REFRESH_SETTINGINFO)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAllcutelt:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAllcutelt:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:SetWndButtonText(self.mFinishBtn,ccClientText(36413))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    local wndType = self._wndType
    if wndType == UIAllcutelt.TYPE_START_RUN then
        if not self._executeType then return end
        gModelGameHelperAlleviation:OnGameHelperExecuteReq(self._executeType,self._helperRefIdList)
    elseif wndType == UIAllcutelt.TYPE_SHOW_RES then
        self:InitExecuteResultList()
    elseif wndType == UIAllcutelt.TYPE_SHOW_RUN then
        self._executeServerMap = gModelGameHelperAlleviation:GetGameHelperExecuteList()
        self:InitExecuteResultList()
    end
end

function UIAllcutelt:RefreshAllStatus()
    local showFinishImg = self:IsCanTouch()
    if showFinishImg then
        self:StopRunInHandTxtAni(self.mRunTxt)
        CS.ShowObject(self.mRunTxt,false)
    else
        CS.ShowObject(self.mRunTxt,true)
        self:RunInHandTxtAni(self.mRunTxt,true,ccClientText(36405))
    end
    CS.ShowObject(self.mFinishBtn,showFinishImg)
end

function UIAllcutelt:InitExecuteResultList()
    --if self:CheckIsNeedJumpMap() then return end

    local list = self:GetExecuteResultList()
    self:RefreshTitleTxt(list)
    self:RefreshAllStatus()
    local uiExecuteResultList = self._uiExecuteResultList
    if uiExecuteResultList then
        uiExecuteResultList:RefreshList(list)
    else
        uiExecuteResultList = self:GetUIScroll("uiExecuteResultList")
        self._uiExecuteResultList = uiExecuteResultList
        uiExecuteResultList:Create(self.mExecuteResultList,list,function(...) self:OnDrawExecuteResultCell(...) end,UIItemList.SUPER)
    end
    local isEnable = self:IsCanTouch()
    uiExecuteResultList:EnableScroll(isEnable)
    uiExecuteResultList:MoveToPos(#list)
end

function UIAllcutelt:GetShowBattleResultType()
    return self._battleShowType or UIAllcutelt.BATTLE_SHOW_TYPE
end

function UIAllcutelt:InitEvent()
    self:SetWndClick(self.mCloseBtn,function() self:OnClickCloseBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mFinishBtn,function() self:OnClickFinishBtnFunc() end)
end

function UIAllcutelt:GetExecuteResultList()
    local list = {}

    local executeServerList = self:GetExecuteServerList()

    local setSortMap = self._setSortMap or {}

    local recordList = {}
    local recordRefId
    local serverData
    local serverDataRefId
    for i,v in ipairs(executeServerList) do
        serverData = v.serverData
        table.insert(list,serverData)
        serverDataRefId = serverData.refId
        if recordRefId then
            recordList[serverDataRefId] = {
                beforeRefId = recordRefId
            }
        end
        recordRefId = serverDataRefId
    end

    local resultList = {}

    local allNum = 0
    local inHandNum = 0
    local finishNum = 0
    local minInHandNum
    local state,refId
    local beforeRefId
    local nextInfo
    local inhandRecord = false
    local needAddNextStatus = true
    for i,v in ipairs(list) do
        state = v.state
        refId = v.refId
        if state == StructExecuteResult.STATUS_FINISH then
            finishNum = finishNum + 1

            if ModelGameHelperAlleviation.EXECUTERESULT_SPLIT_SHOW_MAP[refId] then
                self:DisposeSplitShowMap(v,resultList)
            else
                table.insert(resultList,v)
            end
            beforeRefId = refId
        elseif state == StructExecuteResult.STATUS_INHAND then
            if minInHandNum and minInHandNum > i then
                minInHandNum = i
            elseif not minInHandNum then
                minInHandNum = i
            end
            inHandNum = inHandNum + 1
            if not inhandRecord then
                if beforeRefId then
                    nextInfo = recordList[refId]
                    if nextInfo then
                        if nextInfo.beforeRefId == beforeRefId then
                            if ModelGameHelperAlleviation.EXECUTERESULT_SPLIT_SHOW_MAP[refId] then
                                local reStatus = self:DisposeSplitShowMap(v,resultList)
                                if reStatus == UIAllcutelt.NOT_REPORT then
                                    needAddNextStatus = false
                                end
                                inhandRecord = true
                            end
                        end
                    end
                end
            end
        end
        allNum = allNum + 1
    end

    if allNum > 0 and needAddNextStatus then
        local data
        if finishNum < 1 then
            data = list[1]
        elseif finishNum < allNum then
            minInHandNum = minInHandNum or finishNum + 1
            data = list[minInHandNum]
        end
        if data then
            local minInHandRefId = data.refId
            if ModelGameHelperAlleviation.EXECUTERESULT_SPLIT_SHOW_MAP[minInHandRefId] then
                if allNum == 1 then
                    local reStatus = self:DisposeSplitShowMap(data,resultList)
                    if ModelGameHelperAlleviation.EXECUTERESULT_BATTLE_OR_TIPS_MAP[minInHandRefId] then
                        if reStatus ~= UIAllcutelt.NOT_REPORT then
                            self:SetSplitData(data,resultList,{
                                refId = minInHandRefId,
                                battleStatus = StructExecuteResult.BATTLE_STATUS_RUN,
                            })
                        end
                    end
                else
                    if minInHandRefId == StructSettingInfo.HELPERSET_118 then
                        self:SetSplitData(data,resultList,{
                            refId = minInHandRefId,
                            splitTxt = ccClientText(36404)
                        })
                    else
                        self:SetSplitData(data,resultList,{
                            refId = minInHandRefId,
                            battleStatus = StructExecuteResult.BATTLE_STATUS_RUN,
                        })
                    end
                end
            else
                table.insert(resultList,data)
            end
        end
    end

    local isAllFinish = finishNum >= allNum
    self._listMoveStatus = isAllFinish and UIAllcutelt.LIST_STATUS_CANMOVE or UIAllcutelt.LIST_STATUS_NOTMOVE

    return resultList
end

function UIAllcutelt:InitSortList()
    local refId
    local funcSortMap = {}
    local funcNameMap = {}

    local functionRef = GameTable.AssistantFunctionRef
    for k,v in pairs(functionRef) do
        refId = v.refId
        funcNameMap[refId] = ccLngText(v.name)
        funcSortMap[refId] = v.sort
    end
    self._funcSortMap = funcSortMap
    self._funcNameMap = funcNameMap

    local setSortMap = {}
    local setFunctionIdMap = {}
    local setNextSortRefIdList = {}

    local beforeRefId
    local setRef = GameTable.AssistantSetRef
    for k,v in pairs(setRef) do
        refId = v.refId
        setFunctionIdMap[refId] = v.functionId
        setSortMap[refId] = v.sort

        if beforeRefId then
            setNextSortRefIdList[beforeRefId] = {
                nextRefId = refId,
                nextSort = v.sort,
            }
        end
        beforeRefId = refId
    end
    self._setSortMap = setSortMap
    self._setFunctionIdMap = setFunctionIdMap
    self._setNextSortRefIdList = setNextSortRefIdList
end

function UIAllcutelt:InitRewardList(trans,list)
    local key = trans:GetInstanceID()
    local uiRewardList = self:FindUIScroll(key)
    if uiRewardList then
        uiRewardList:RefreshList(list)
        uiRewardList:DrawAllItems()
    else
        uiRewardList = self:GetUIScroll(key)
        uiRewardList:Create(trans,list,function(...) self:OnDrawRewardCell(...) end,UIItemList.SUPER_GRID)
    end
    local isEnable = self:IsCanTouch()
    if isEnable then
        local col = self:GetRewardListCol(list)
        isEnable = col > UIAllcutelt.REWARD_MIN_LINE
    end
    uiRewardList:EnableScroll(isEnable)
    uiRewardList:MoveToPos(1)
end

function UIAllcutelt:GetBattleReportList(itemdata)
    local reportList = {}
    local fightReports = itemdata:GetFightReports() or {}
    for i,v in pairs(fightReports) do
        table.insert(reportList,v)
    end
    table.sort(reportList,function(a,b)
        return a.index < b.index
    end)
    return reportList
end

--------------------------------- SetFinishDiv ---------------------------------

function UIAllcutelt:SetFinishDiv(item,itemdata)
    local FinishImgTrans = self:FindWndTrans(item,"FinishImg")
    CS.ShowObject(FinishImgTrans,true)
end

function UIAllcutelt:InitData()
    self._wndType = self:GetWndArg("wndType")

    self._executeType = self:GetWndArg("executeType")
    self._helperRefIdList = self:GetWndArg("helperRefIdList")

    self:InitSortList()

    self._executeServerMap = {}
    local resultExecuteList = self:GetWndArg("resultExecuteList")
    if resultExecuteList then
        self._executeServerMap = resultExecuteList
    end

    local battleShowType = GameTable.AssistantConfig["battleShowType"]
    if not battleShowType then
        battleShowType = UIAllcutelt.BATTLE_SHOW_TYPE
        if LOG_INFO_ENABLED then
            printInfoNR("GameHelperConfig 表可配置 battleShowType 字段，0：显示图片，1：显示特效 ，默认是" .. UIAllcutelt.BATTLE_SHOW_TYPE)
        end
    end
    self._battleShowType = battleShowType




    local battleResultImgList = {}
    local battleWinImgPath = GameTable.AssistantConfig["battleWinImgPath"]
    if LOG_INFO_ENABLED then
        battleWinImgPath = UIAllcutelt.BATTLE_IMG_LIST[ModelGameHelperAlleviation.BATTLE_WIN]
        printInfoNR("GameHelperConfig 表可配置 battleWinImgPath 字段显示胜利图片，为空显示默认图片 " .. battleWinImgPath)
    end
    battleResultImgList[ModelGameHelperAlleviation.BATTLE_WIN] = battleWinImgPath

    local battleFailImgPath = GameTable.AssistantConfig["battleFailImgPath"]
    if LOG_INFO_ENABLED then
        battleFailImgPath = UIAllcutelt.BATTLE_IMG_LIST[ModelGameHelperAlleviation.BATTLE_FAIL]
        printInfoNR("GameHelperConfig 表可配置 battleFailImgPath 字段显示胜利图片，为空显示默认图片 " .. battleFailImgPath)
    end
    battleResultImgList[ModelGameHelperAlleviation.BATTLE_FAIL] = battleFailImgPath
    self._battleResultImgList = battleResultImgList


    local battleResultEffList = {}
    -- local battleWinEffName = GameTable.AssistantConfig["battleWinEffName"]
    -- if not battleWinEffName then
    --     battleWinEffName = UIAllcutelt.BATTLE_EFF_LIST[ModelGameHelperAlleviation.BATTLE_WIN]
    --     if LOG_INFO_ENABLED then
    --         printInfoNR("GameHelperConfig 表可配置 battleWinEffName 字段显示胜利特效，为空显示默认的：" .. battleWinEffName)
    --     end
    -- end
    -- battleResultEffList[ModelGameHelperAlleviation.BATTLE_WIN] = battleWinEffName

    -- local battleFailEffName = GameTable.AssistantConfig["battleFailEffName"]
    -- if not battleFailEffName then
    --     battleFailEffName = UIAllcutelt.BATTLE_EFF_LIST[ModelGameHelperAlleviation.BATTLE_FAIL]
    --     if LOG_INFO_ENABLED then
    --         printInfoNR("GameHelperConfig 表可配置 battleFailEffName 字段显示胜利特效，为空显示默认的：" .. battleFailEffName)
    --     end
    -- end
    -- battleResultEffList[ModelGameHelperAlleviation.BATTLE_FAIL] = battleFailEffName
    self._battleResultEffList = battleResultEffList


    self._playerId = gModelPlayer:GetPlayerId()
    self._playerHead = gModelPlayer:GetPlayerHead()
    self._playerHeadFrame = gModelPlayer:GetPlayerHeadFrame()
    self._playerName = gModelPlayer:GetPlayerName()
    self._playerLevel = gModelPlayer:GetPlayerLv()
    self._curServerId = gModelPlayer:GetServerId()
end

function UIAllcutelt:OnClickFinishBtnFunc()
    self:ClearNotices()
    self:WndClose()
end
--------------------------------- SetRewardItemDiv ---------------------------------
function UIAllcutelt:DisposeRewardItemList(itemdata)
    local refId = itemdata.refId
    local isWish = ModelGameHelperAlleviation.WISH_MAP[refId] or false
    local list = {}
    if isWish then
        local moreInfoIdxMap = gModelGameHelperAlleviation:ExecuteResultDisposeMoreInfoKey(itemdata)
        if moreInfoIdxMap then
            local IdxMap
            local rewardIdxList = self:GetRewardIdxList(itemdata)
            for idx,rewardList in pairs(rewardIdxList) do
                IdxMap = moreInfoIdxMap[idx] or {}
                for i,v in ipairs(rewardList) do
                    local serverData = v.serverData
                    local itemType = serverData.itemType or serverData.itype
                    local itemId = serverData.refId
                    local rateInfo = IdxMap[itemType] or {}
                    local rate = rateInfo[itemId] or 1
                    table.insert(list,{
                        serverData = serverData,
                        setRefId = refId,
                        isWish = isWish,
                        idx = idx,
                        index = v.index,
                        rate = rate,
                    })
                end
            end
            table.sort(list,function(a,b)
                local idxA,idxB = a.idx,b.idx
                if idxA ~= idxB then return idxA < idxB end
                return a.index < b.index
            end)
        else
            local rewardList = self:GetRewardList(itemdata)
            for i,v in ipairs(rewardList) do
                table.insert(list,{
                    serverData = v,
                    setRefId = refId,
                    isWish = isWish,
                })
            end
        end
    else
        local rewardList = self:GetRewardList(itemdata)
        for i,v in ipairs(rewardList) do
            table.insert(list,{
                serverData = v,
                setRefId = refId,
                isWish = isWish,
            })
        end
    end
    return list
end

--------------------------------- SetBattleDiv ---------------------------------

function UIAllcutelt:SetBattleDiv(item,itemdata)
    local InHandTxtTrans = self:FindWndTrans(item,"InHandTxt")
    local ResultDivTrans = self:FindWndTrans(item,"ResultDiv")
    CS.ShowObject(ResultDivTrans,true)
    self:SetBattleResuleDiv(ResultDivTrans,itemdata)
end

function UIAllcutelt:OnDrawRewardCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
    local RateBgTrans = self:FindWndTrans(item,"RateBg")

    local serverData = itemdata.serverData

    local showRate = false
    if itemdata.isWish then
        local rate = itemdata.rate or 1
        showRate = rate > 1
        if showRate then
            self:SetTextTile(RateBgTrans,string.replace(ccClientText(36412),rate))
        end
    end
    CS.ShowObject(RateBgTrans,showRate)

    local instanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetRewardDetailItem(serverData)
    baseClass:DoApply()
    self:SetIconClickScale(IconTrans, true)
    self:SetWndClick(IconTrans,function()
        self:OnClickRewardFunc(itemdata)
    end)
end


function UIAllcutelt:SetRewardItemDiv(item,itemdata)
    --local InHandTxtTrans = self:FindWndTrans(item,"InHandTxt")
    local ResultDivTrans = self:FindWndTrans(item,"ResultDiv")
    local RewardItemListTrans = self:FindWndTrans(ResultDivTrans,"RewardItemList")
    local rewardList = self:DisposeRewardItemList(itemdata)
    self:InitRewardList(RewardItemListTrans,rewardList)
end


function UIAllcutelt:SetFormmatPrinterAni(formatInfo)
    if not formatInfo then return end
    local str = formatInfo.str or ""
    local trans = formatInfo.trans
    local constStr = formatInfo.constStr or ""
    local len,itor = LUtil.FormatPrinterData(str)
    local perTime = 0.3
    local time = len * perTime
    local tween = YXTween.TweenInt(0,len,time,function (value)
        local temp = itor(value) or ""
        temp = constStr .. temp
        self:SetWndText(trans,temp)
    end)
    return tween
end

function UIAllcutelt:GetRewardListCol(rewardList)
    local len = #rewardList
    local col = math.ceil(len / 5)
    return col
end

function UIAllcutelt:IsCanTouch()
    return self._listMoveStatus == UIAllcutelt.LIST_STATUS_CANMOVE
end

function UIAllcutelt:OnClickCloseBtnFunc()
    local finishCheckClearResultKey = "finishCheckClearResult"
    local finishCheckClearResult = GameTable.AssistantConfig[finishCheckClearResultKey]
    if not finishCheckClearResult then
        finishCheckClearResult = 0
        if LOG_INFO_ENABLED then
            printInfoNR("如果关闭按钮事件需要检测当前执行是否全部完成并取消缩小减负助手窗口，可以在 GameHelperConfig 表配置 " ..
                    finishCheckClearResultKey .. " 字段，" .. finishCheckClearResultKey .. " = 1 时会检测是否完成并关闭缩小减负助手窗口，默认0，不检测不关闭")
        end
    end
    local needCheck = finishCheckClearResult == 1
    if needCheck then
        self:ClearNotices()
    end
    --策划需求 #13167
    --【减负助手】优化执行完毕流程（客户端）
    local showFinishImg = self:IsCanTouch()
    if(showFinishImg)then
        self:ClearNotices()
    end
    -----------------
    self:WndClose()
end

function UIAllcutelt:GetRewardList(itemdata)
   return itemdata and itemdata.rewardList or {}
end

function UIAllcutelt:GetRewardIdxList(itemdata)
   return itemdata and itemdata.rewardIdxList or {}
end

function UIAllcutelt:OnClickRewardFunc(itemdata)
    if not self:IsCanTouch() then return end
    gModelGeneral:ShowRewardDetailTip(itemdata.serverData)
end

--------------------------------- SetInHandDiv ---------------------------------

function UIAllcutelt:SetInHandDiv(item,itemdata)
    local InHandTxtTrans = self:FindWndTrans(item,"InHandTxt")
    self:SetWndText(InHandTxtTrans,ccClientText(36404))
end

function UIAllcutelt:SetSplitData(itemdata,resultList,extraData)
    local refId = extraData.refId
    if ModelGameHelperAlleviation.EXECUTERESULT_BATTLE_OR_TIPS_MAP[refId] then
        table.insert(resultList,itemdata:GetBattleTypeData(extraData.battleData,extraData.battleStatus))
    elseif refId == StructSettingInfo.HELPERSET_118 then
        table.insert(resultList,itemdata:GetExecuteResult118Data(extraData.splitTxt))
    end
end

--- 根据类型做界面展示
function UIAllcutelt:GetResultShowType(itemdata)
    local refId = itemdata.refId
    local state = itemdata.state
    if not ModelGameHelperAlleviation.EXECUTERESULT_SPLIT_SHOW_MAP[refId] then
        if state == StructExecuteResult.STATUS_INHAND then
            return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_INHAND
        end
    end
    local winType,failType
    local ref = gModelGameHelperAlleviation:GetLighteningHelperSetRefByRefId(refId)
    if ref then
        winType = ref.winType
        failType = ref.failType
    end
    if refId == StructSettingInfo.HELPERSET_101 then
        --- 收取资源
        local rewardList = self:GetRewardList(itemdata)
        if #rewardList > 0 then
            return winType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_REWARD
        else
            return failType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        end
    elseif refId == StructSettingInfo.HELPERSET_102 then
        --- 一键上阵
        local code = itemdata.code
        if code == StructExecuteResult.CODE_INIT then
            return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_INHAND
        elseif code == StructExecuteResult.CODE_SUC then
            return winType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_FINISH
        else
            return failType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        end
    elseif refId == StructSettingInfo.HELPERSET_103 then
        --- 一键援助
        local rewardList = self:GetRewardList(itemdata)
        if #rewardList > 0 then
            return winType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_REWARD
        else
            return failType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        end
    elseif ModelGameHelperAlleviation.EXECUTERESULT_REWARD_OR_TIPS_MAP[refId] then
        local rewardList = self:GetRewardList(itemdata)
        if #rewardList > 0 then
            return winType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_REWARD
        else
            return failType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        end
    elseif ModelGameHelperAlleviation.WISH_MAP[refId] then
        local rewardList = self:GetRewardList(itemdata)
        if #rewardList > 0 then
            return winType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_REWARD
        else
            return failType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        end
    elseif ModelGameHelperAlleviation.EXECUTERESULT_BATTLE_OR_TIPS_MAP[refId] then
        local battleStatus = itemdata.battleStatus
        if battleStatus == StructExecuteResult.BATTLE_STATUS_END then
            if not itemdata.battleData then
                battleStatus = StructExecuteResult.BATTLE_STATUS_RUN
            end
        end
        if battleStatus == StructExecuteResult.BATTLE_STATUS_RUN then
            return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_INHAND
        elseif battleStatus == StructExecuteResult.BATTLE_STATUS_END then
            return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_BATTLE
        elseif battleStatus == StructExecuteResult.BATTLE_STATUS_ERR then
            return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        else
            return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        end
    elseif refId == StructSettingInfo.HELPERSET_117 then
        return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_FINISH
    elseif refId == StructSettingInfo.HELPERSET_118 then
        return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
    else
        if LOG_INFO_ENABLED then
            printInfoNR("如果可使用已实现的显示，可直接配置 winType 字段（展示成功界面，有奖励优先展示奖励）和 failType 字段（展示失败界面，通用错误码类型）")
        end
        winType = winType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_FINISH
        failType = failType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE
        local code = itemdata.code
        if code == StructExecuteResult.CODE_INIT then
            return ModelGameHelperAlleviation.RESULT_SHOW_TYPE_INHAND
        elseif code == StructExecuteResult.CODE_SUC then
            local rewardList = self:GetRewardList(itemdata)
            if #rewardList > 0 then
                if refId == StructSettingInfo.HELPERSET_122 or refId == StructSettingInfo.HELPERSET_121 then
                    winType = ModelGameHelperAlleviation.RESULT_SHOW_TYPE_REWARD
                else
                    winType = ModelGameHelperAlleviation.RESULT_SHOW_TYPE_FINISH
                end
            end
            return winType or ModelGameHelperAlleviation.RESULT_SHOW_TYPE_FINISH
        else
            return failType
        end
    end
end

function UIAllcutelt:OnDrawExecuteResultCell(list,item,itemdata,itempos)
    local TitleNameTrans = self:FindWndTrans(item,"TopDiv/TitleBg/TitleName")
    local name = gModelGameHelperAlleviation:GetLighteningHelperSetTxtByRefId(itemdata.refId)
    self:SetWndText(TitleNameTrans,name)

    local height = 37 + 8           -- 8 是 标题和内容的间隔

    local RewardItemDivTrans = self:FindWndTrans(item,"RewardItemDiv")
    local FinishDivTrans = self:FindWndTrans(item,"FinishDiv")
    local InHandDivTrans = self:FindWndTrans(item,"InHandDiv")
    local BattleDivTrans = self:FindWndTrans(item,"BattleDiv")
    local CodeDivTrans = self:FindWndTrans(item,"CodeDiv")

    local resultShowType = self:GetResultShowType(itemdata)
    local showRewardItem = resultShowType == ModelGameHelperAlleviation.RESULT_SHOW_TYPE_REWARD
    local showFinish = resultShowType == ModelGameHelperAlleviation.RESULT_SHOW_TYPE_FINISH
    local showInhand = resultShowType == ModelGameHelperAlleviation.RESULT_SHOW_TYPE_INHAND
    local showBattle = resultShowType == ModelGameHelperAlleviation.RESULT_SHOW_TYPE_BATTLE
    local showCode = resultShowType == ModelGameHelperAlleviation.RESULT_SHOW_TYPE_CODE


    local resultDivHeight
    local rewardItemDivHeight
    if showRewardItem then
        local rewardList = self:DisposeRewardItemList(itemdata)
        local col = self:GetRewardListCol(rewardList)
        local rewardHeight = col * 88 + (col - 1) * 11 + 20
        resultDivHeight = rewardHeight

        rewardHeight = rewardHeight + 20
        rewardItemDivHeight = rewardHeight

        if rewardItemDivHeight > UIAllcutelt.LIMIT_MAX_HEIGHT then
            rewardHeight = UIAllcutelt.LIMIT_MAX_HEIGHT
            rewardItemDivHeight = UIAllcutelt.LIMIT_MAX_HEIGHT
            resultDivHeight = rewardItemDivHeight - 20
        end

        height = height + rewardHeight

        self:SetRewardItemDiv(RewardItemDivTrans,itemdata)
    end
    if showFinish then
        height = height + 114
        self:SetFinishDiv(FinishDivTrans,itemdata)
    end
    if showInhand then
        height = height + 114
        self:SetInHandDiv(InHandDivTrans,itemdata)
    end
    if showBattle then
        height = height + 128
        self:SetBattleDiv(BattleDivTrans,itemdata)
    end
    if showCode then
        height = height + 114
        self:SetCodeDiv(CodeDivTrans,itemdata)
    end

    CS.ShowObject(FinishDivTrans,showFinish)
    CS.ShowObject(InHandDivTrans,showInhand)
    CS.ShowObject(BattleDivTrans,showBattle)
    CS.ShowObject(CodeDivTrans,showCode)

    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)

    if showRewardItem then
        local ResultDivTrans = self:FindWndTrans(RewardItemDivTrans,"ResultDiv")
        LxUiHelper.SetSizeWithCurAnchor(ResultDivTrans, 1, resultDivHeight)
    end
    if rewardItemDivHeight then
        LxUiHelper.SetSizeWithCurAnchor(RewardItemDivTrans, 1, rewardItemDivHeight)
    end
    CS.ShowObject(RewardItemDivTrans,showRewardItem)

end

function UIAllcutelt:CheckIsNeedJumpMap()
    --- GameHelperRunningFunctionResp 通知，强制关闭界面，兼容处理
    local executeServerMap = self._executeServerMap
    if not executeServerMap then return false end

    if gModelGameHelperAlleviation:CheckIsNeedJumpMap(executeServerMap) then
        return true
    end

    return false
end


function UIAllcutelt:InitMsg()
	 self:WndNetMsgRecv(LProtoIds.GameHelperExecuteResp,function(pb) self:OnGameHelperExecuteResp(pb) end)
	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end


function UIAllcutelt:RunInHandTxtAni(trans,isLoop,constStr,str)
    local seqKey = trans:GetInstanceID()
    self:TweenSeqKill(seqKey)
    local seqTween = self:TweenSeqCreate(seqKey, function(seq)
        local formatTween = self:SetFormmatPrinterAni({
            trans = trans,
            constStr = constStr or ccClientText(36404),
            str = str or ccClientText(36406),
        })
        seq:Append(formatTween)
        return seq
    end)
    if isLoop then
        seqTween:SetLoops(-1,Tweening.LoopType.Restart)
    end
    seqTween:OnComplete(function()
        self:TweenSeqKill(seqKey)
    end)
    seqTween:PlayForward()
end

function UIAllcutelt:GetBattleLeftAndRightHeadData(itemdata)
    local battleData = itemdata.battleData
    if not battleData then return end
    ------ 左边自己，右边对方
    local leftData = {
        playerId = self._playerId,
        icon = self._playerHead,
        headFrame = self._playerHeadFrame,
        name = self._playerName,
        level = self._playerLevel,
        serverId = self._curServerId,
    }
    local rightData = {
        playerId = battleData.playerId,
        icon = battleData.head,
        headFrame = battleData.headFrame,
        name = battleData.playerName,
        level = battleData.playerLvl,
        serverId = battleData.serverId,
    }
    return leftData,rightData
end

function UIAllcutelt:ClearNotices()
    local isAllFinish = self:CheckIsRunEnd()
    if not isAllFinish then return end
    if LOG_INFO_ENABLED then
        printInfoNR("打印而已，莫慌      清除数据")
    end
    FireEvent(EventNames.ON_CLEAR_EXECUTELIST)
end

------------------------- List -------------------------


---------------------------------- ani ------------------------------
function UIAllcutelt:StopRunInHandTxtAni(trans)
    local seqKey = trans:GetInstanceID()
    self:TweenSeqKill(seqKey)
end

function UIAllcutelt:SetBattleResuleDiv(item,itemdata)
    local EffRootTrans = self:FindWndTrans(item,"EffRoot")
    local ImgRootTrans = self:FindWndTrans(item,"ImgRoot")
    local SuccessImgTrans = self:FindWndTrans(ImgRootTrans,"SuccessImg")
    local FailImgTrans = self:FindWndTrans(ImgRootTrans,"FailImg")
    local battleData = itemdata.battleData
    local win = ModelGameHelperAlleviation.BATTLE_FAIL
    if battleData then
        win = battleData.win
    end
    local showType = self:GetShowBattleResultType()
    local showEffStatus = showType == 1
    local effKey = EffRootTrans:GetInstanceID()
    self:DestroyWndEffectByKey(effKey)

    if showEffStatus then
        local effName = self._battleResultEffList[win]
        self:CreateWndEffect(EffRootTrans,effName,effKey,100,false,false,20,
        nil,false,false,false,function()
                    CS.ShowObject(EffRootTrans,true)
                end)
    else
        local isWnd = win == ModelGameHelperAlleviation.BATTLE_WIN
        local showImgTrans = isWnd and SuccessImgTrans or FailImgTrans
        local HideImgTrans = isWnd and FailImgTrans or SuccessImgTrans
        CS.ShowObject(HideImgTrans,false)
        CS.ShowObject(showImgTrans,true)
--[[        local img = self._battleResultImgList[win]
        if img then
            self:SetWndEasyImage(showImgTrans,img,function()
                CS.ShowObject(showImgTrans,true)
            end,true)
        end]]
    end
    CS.ShowObject(EffRootTrans,showEffStatus)
    CS.ShowObject(ImgRootTrans,not showEffStatus)

    local LeftHeadRootTrans = self:FindWndTrans(item,"LeftHeadRoot")
    local RightHeadRootTrans = self:FindWndTrans(item,"RightHeadRoot")
    local leftData,rightData = self:GetBattleLeftAndRightHeadData(itemdata)
    if leftData then
        self:CreateHeadIcon(LeftHeadRootTrans,leftData)
    else
        CS.ShowObject(LeftHeadRootTrans,false)
    end
    if rightData then
        self:CreateHeadIcon(RightHeadRootTrans,rightData)
    else
        CS.ShowObject(RightHeadRootTrans,false)
    end
end

function UIAllcutelt:CheckIsRunEnd()
    local showNoticesItem = false
    local executeServerMap = self._executeServerMap
    if executeServerMap then
        local finishNum = 0
        local allNum = 0
        for k,v in pairs(executeServerMap) do
            allNum = allNum + 1
            if v.state == StructExecuteResult.STATUS_FINISH then
                finishNum = finishNum + 1
            end
        end
        if allNum > 0 then
            if finishNum < allNum then
                showNoticesItem = true
            end
        end
    end
    gModelGameHelperAlleviation:ShowNoticesItem(showNoticesItem)
    return true
end

function UIAllcutelt:OnGameHelperExecuteResp(pb)
--[[    local executeServerMap = self._executeServerMap
    if not executeServerMap then
        executeServerMap = {}
        self._executeServerMap = executeServerMap
    end

    local serverData,refId
    local results = pb.results
    for i,v in ipairs(results) do
        serverData = gModelGameHelperAlleviation:GetExecuteResultServerData(v)
        refId = serverData.refId
        executeServerMap[refId] = serverData
    end]]

    self._executeServerMap = gModelGameHelperAlleviation:GetGameHelperExecuteList()
    self:InitExecuteResultList()
end

function UIAllcutelt:OnClickHeadIconFunc(itemdata)
    --gModelGeneral:PlayerShowReq(playerInfo:GetPlayerId(), LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIAllcutelt:DisposeSplitShowMap(itemdata,resultList)
    local status = UIAllcutelt.NOT_DEFAULT
    local refId = itemdata.refId
    if ModelGameHelperAlleviation.EXECUTERESULT_SPLIT_SHOW_MAP[refId] then
        if ModelGameHelperAlleviation.EXECUTERESULT_BATTLE_OR_TIPS_MAP[refId] then
            local codeStr = gModelGameHelperAlleviation:ShowCodeInfoLighteningHelperTextByServerData(itemdata)
            if codeStr then
                local reportList = self:GetBattleReportList(itemdata)
                for i,v in ipairs(reportList) do
                    self:SetSplitData(itemdata,resultList,{
                        refId = refId,
                        battleData = v,
                        battleStatus = StructExecuteResult.BATTLE_STATUS_END,
                    })
                end
                self:SetSplitData(itemdata,resultList,{
                    refId = refId,
                    battleStatus = StructExecuteResult.BATTLE_STATUS_ERR,
                })
            else
                local reportList = self:GetBattleReportList(itemdata)
                if #reportList > 0 then
                    for i,v in ipairs(reportList) do
                        self:SetSplitData(itemdata,resultList,{
                            refId = refId,
                            battleData = v,
                            battleStatus = StructExecuteResult.BATTLE_STATUS_END,
                        })
                    end
                else
                    self:SetSplitData(itemdata,resultList,{
                        refId = refId,
                        battleStatus = StructExecuteResult.BATTLE_STATUS_RUN,
                    })
                    status = UIAllcutelt.NOT_REPORT
                end
            end
        elseif refId == StructSettingInfo.HELPERSET_118 then
            local code = itemdata.code
            if code <= StructExecuteResult.CODE_SUC then
                ---- 显示全部的结果
                local codeInfoSplitList = gModelGameHelperAlleviation:DisposeCodeInfoList(itemdata)
                if #codeInfoSplitList > 0 then
                    for i,v in ipairs(codeInfoSplitList) do
                        self:SetSplitData(itemdata,resultList,{
                            refId = refId,
                            splitTxt = v
                        })
                    end
                else
                    local state = itemdata.state
                    if state == StructExecuteResult.STATUS_FINISH then
                        local text = gModelGameHelperAlleviation:ShowCodeInfoLighteningHelperTextByServerData(itemdata)
                        self:SetSplitData(itemdata,resultList,{
                            refId = refId,
                            splitTxt = text
                        })
                    else
                        self:SetSplitData(itemdata,resultList,{
                            refId = refId,
                            splitTxt = ccClientText(36404)
                        })
                    end
                    status = UIAllcutelt.NOT_REPORT
                end
            else
                local codeInfoSplitList = gModelGameHelperAlleviation:DisposeCodeInfoList(itemdata)
                for i,v in ipairs(codeInfoSplitList) do
                    self:SetSplitData(itemdata,resultList,{
                        refId = refId,
                        splitTxt = v
                    })
                end
            end
            if code > StructExecuteResult.CODE_SUC then
                local codeInfo = itemdata.codeInfo
                if string.isempty(codeInfo) then
                    local codeStr = gModelGameHelperAlleviation:DisposeCodeTxt(itemdata)
                    if not string.isempty(codeStr) then
                        self:SetSplitData(itemdata,resultList,{
                            refId = refId,
                            splitTxt = codeStr
                        })
                    end
                end
            end
--[[            local codeStr = gModelGameHelperAlleviation:ShowCodeInfoLighteningHelperTextByServerData(itemdata)
            if not string.isempty(codeStr) then
                self:SetSplitData(itemdata,resultList,{
                    refId = refId,
                    splitTxt = codeStr
                })
            end]]
        else
            table.insert(resultList,itemdata)
        end
    else
        table.insert(resultList,itemdata)
    end
    return status
end

--------------------------------- SetCodeDiv ---------------------------------


function UIAllcutelt:SetCodeDiv(item,itemdata)
    local CodeTxtTrans = self:FindWndTrans(item,"CodeTxt")
    local refId = itemdata.refId
    local str
    if refId == StructSettingInfo.HELPERSET_118 then
        str = itemdata.splitTxt
--[[    elseif refId == StructSettingInfo.HELPERSET_113 then
        local code = itemdata.code
        if code <= StructExecuteResult.CODE_SUC then
        else
            str = gModelGameHelperAlleviation:ShowCodeInfoLighteningHelperTextByServerData(itemdata)
        end]]
    else
        str = gModelGameHelperAlleviation:ShowCodeInfoLighteningHelperTextByServerData(itemdata)
    end
    self:SetWndText(CodeTxtTrans,str)
end

function UIAllcutelt:RefreshTitleTxt(list)
    list = list or {}
    local str = ""
    local len = #list
    if len > 0 then
        local endData = list[len]
        if endData.state == StructExecuteResult.STATUS_FINISH then
            str = ccClientText(36409)
        else
            local setRefId = endData.refId
            local setFunctionIdMap = self._setFunctionIdMap or {}
            local functionId = setFunctionIdMap[setRefId]
            if functionId then
                local funcNameMap = self._funcNameMap or {}
                str = funcNameMap[functionId] or ""
            end
        end
    end
    self:SetWndText(self.mTitleTxt,str)
end

function UIAllcutelt:CreateHeadIcon(item,itemdata)
    local HeadIconTrans = self:FindWndTrans(item,"CommonUI/Icon/HeadIcon")
    local PlayerNameTrans = self:FindWndTrans(item,"PlayerName")
    self:SetWndText(PlayerNameTrans,itemdata.name)


    local instanceID = item:GetInstanceID()
    local headData = {
        trans = HeadIconTrans,
        icon = itemdata.icon,
        headFrame = itemdata.headFrame,
        name = itemdata.name,
        level = itemdata.level,
    }
    local baseClass = self:GetHeadIcon(instanceID)
    baseClass:SetHeadData(headData)

    self:SetWndClick(HeadIconTrans,function ()
        self:OnClickHeadIconFunc(itemdata)
    end)
    CS.ShowObject(item,true)
end

------------------------- List -------------------------
function UIAllcutelt:GetExecuteServerList()
    local executeServerMap = self._executeServerMap
    if not executeServerMap then
        return {}
    end
    local executeServerList = {}
    for k,v in pairs(executeServerMap) do
        table.insert(executeServerList,{
            serverData = v,
            refId = k,
            functionId = gModelGameHelperAlleviation:GetLighteningHelperSetFunctionIdByRefId(k)
        })
    end
    local funcSortMap = self._funcSortMap or {}
    local setSortMap = self._setSortMap or {}
    table.sort(executeServerList,function(a,b)
--[[        local funcSortA = funcSortMap[a.functionId] or 0
        local funcSortB = funcSortMap[b.functionId] or 0
        if funcSortA ~= funcSortB then
            return funcSortA < funcSortB
        end]]
        local setSortA = setSortMap[a.refId] or 0
        local setSortB = setSortMap[b.refId] or 0
        return setSortA < setSortB
    end)
    return executeServerList
end

------------------------------------------------------------------
return UIAllcutelt