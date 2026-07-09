---
--- Created by Administrator.
--- DateTime: 2024/12/25 15:57:31
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGolemRecast:LChildWnd
local UISubGolemRecast = LxWndClass("UISubGolemRecast", LChildWnd)
------------------------------------------------------------------

UISubGolemRecast.TYPE_RECAST_BEFORE = 1           --- 重铸前
UISubGolemRecast.TYPE_RECAST_LATER = 2            --- 重铸后

UISubGolemRecast.TYPE_HERO = 1                    --- 英雄
UISubGolemRecast.TYPE_GOLEM = 2                   --- 单个魔偶

--- 帮助弹窗
UISubGolemRecast.RECAST_TYPE_TIPS = {
    [ModelGolem.RECAST_TYPE_BASE] = 505,
    [ModelGolem.RECAST_TYPE_HIGH] = 505,
}

--- 0：切换不弹框
--- 1：切换弹框
UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS = 0
UISubGolemRecast.TYPE_SWITCH_STATUS_SHOWTIPS = 1

--- 返回按钮事件
UISubGolemRecast.EVENT_SWITCH_RETURNBTN = "returnBtn"

--- 重铸类型按钮事件
UISubGolemRecast.EVENT_SWITCH_RECASTTYPETABBTN = "recastTypeTabBtn"

--- 英雄列表切换魔偶事件
UISubGolemRecast.EVENT_SWITCH_HEROGOLEMLIST = "heroGolemList"

--- 英雄界面切换按钮事件
UISubGolemRecast.EVENT_SWITCH_HEROVIEWHEROCHANGEBTN = "heroViewHeroChangeBtn"

--- 单个魔偶界面切换按钮事件
UISubGolemRecast.EVENT_SWITCH_GOLEMVIEWGOLEMCHANGEBTN = "golemViewGolemChangeBtn"

--- 一键选择按钮事件
UISubGolemRecast.EVENT_SWITCH_KEYCHOICEEBTN = "keyChoiceeBtn"

--- 强化按钮事件
UISubGolemRecast.EVENT_SWITCH_INTENSIFYBTN = "intensifyBtn"

--- 魔偶背包按钮事件
UISubGolemRecast.EVENT_SWITCH_SHOWGOLEMBAGBTN = "showGolemBagBtn"

--- 英雄列表按钮事件
UISubGolemRecast.EVENT_SWITCH_SHOWHEROGOLEMBTN = "showHeroGolemBtn"

---- 事件屏蔽
UISubGolemRecast.EVENT_SWITCH_LIST = {
    [UISubGolemRecast.EVENT_SWITCH_RETURNBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
    [UISubGolemRecast.EVENT_SWITCH_RECASTTYPETABBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_SHOWTIPS,
    [UISubGolemRecast.EVENT_SWITCH_HEROGOLEMLIST] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
    [UISubGolemRecast.EVENT_SWITCH_HEROVIEWHEROCHANGEBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
    [UISubGolemRecast.EVENT_SWITCH_GOLEMVIEWGOLEMCHANGEBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
    [UISubGolemRecast.EVENT_SWITCH_KEYCHOICEEBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
    [UISubGolemRecast.EVENT_SWITCH_INTENSIFYBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
    [UISubGolemRecast.EVENT_SWITCH_SHOWGOLEMBAGBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
    [UISubGolemRecast.EVENT_SWITCH_SHOWHEROGOLEMBTN] = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS,
}

UISubGolemRecast.EVENT_SWITCH_SHOWTIPINFO_LIST = {
    [UISubGolemRecast.EVENT_SWITCH_RECASTTYPETABBTN] = {
        msg = ccClientText(34841),
        showMsg = true,
        showCommonTips = false,
    },
}

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGolemRecast:UISubGolemRecast()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGolemRecast:OnWndClose()
    local recastType = self._recastType or ModelGolem.RECAST_TYPE_BASE
    LPlayerPrefs.SetGolemRecastType(recastType)
    FireEvent(EventNames.ON_GOLEM_REFRESH_WEAR)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGolemRecast:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGolemRecast:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()

    local closeWndFunc = self:GetWndArg("closeWndFunc")
    if closeWndFunc then closeWndFunc() end
end

function UISubGolemRecast:CreateRecastDiv(trans,list)
    local RecastListTrans = self:FindWndTrans(trans,"RecastList")
    self:InitRecastList(RecastListTrans,list)
end

function UISubGolemRecast:OnGolemRecastResp(pb)
    if pb.golemId ~= self._golemId then return end
    self:InitSelGolemIdMap()
    self:InitGolemServerData()
    self:RefreshRecastDiv()
    self:InitGolemItemList()
end

function UISubGolemRecast:InitData()
    self:InitChangeData()
    local recastType =  tonumber(LPlayerPrefs.golemRecastType) or ModelGolem.RECAST_TYPE_BASE
    self._recastType = recastType

    local delimiter = ","
    local eventSwitchMap = {}
    local eventSwitch = gModelGolem:GetGolemConfigRefByKey("eventSwitch")
    if eventSwitch then
        eventSwitch = string.split(eventSwitch,delimiter)
    else
        local typeStr
        local strList = {}
        local str
        for k,v in pairs(UISubGolemRecast.EVENT_SWITCH_LIST) do
            str = k .. "=" .. v
            table.insert(strList,str)

            if typeStr then
                typeStr = typeStr .. delimiter .. k
            else
                typeStr = k
            end
        end
        eventSwitch = strList


        if LOG_INFO_ENABLED then
            local printeventSwitch = table.concat(strList,delimiter)
            printInfoNR("打印而已，莫慌   GolemConfigRef 表的 eventSwitch 可控制是否弹窗提示必须保存或取消上一次重铸结果，默认 eventSwitch（类型=状态） ： " .. printeventSwitch)
            printInfoNR("打印而已，莫慌   状态默认 " .. UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS)
            printInfoNR("打印而已，莫慌   目前定义的类型有 ： " .. typeStr)
        end
    end
    local key,val
    for i,v in ipairs(eventSwitch) do
        v = string.split(v,"=")
        key = v[1]
        val = tonumber(v[2])
        eventSwitchMap[key] = val
    end
    self._eventSwitchMap = eventSwitchMap
end

function UISubGolemRecast:InitText()
    self:SetWndButtonText(self.mRecastBtn,ccClientText(34830))
    self:SetWndButtonText(self.mRecastOptBtn,ccClientText(34831))
    self:SetWndButtonText(self.mKeyChoiceeBtn,ccClientText(34832))
    self:SetWndText(self.mNotAttrTips,ccClientText(34808))


    local BRecastTitleTrans = self:FindWndTrans(self.mBeforeRecastDiv,"RecastTitle")
    self:SetTextTile(BRecastTitleTrans,ccClientText(34834))

    local LRecastTitleTrans = self:FindWndTrans(self.mLaterRecastDiv,"RecastTitle")
    self:SetTextTile(LRecastTitleTrans,ccClientText(34835))

    self:SetTextTile(self.mShowGolemIntensify1Btn,ccClientText(34836))
    self:SetTextTile(self.mShowGolemIntensify2Btn,ccClientText(34836))
    self:SetTextTile(self.mShowHeroGolemBtn,ccClientText(34838))
    self:SetTextTile(self.mShowGolemBagBtn,ccClientText(34837))

    self:SetTextTile(self.mShowHeroGolemDemountBtn,ccClientText(33205))
    self:SetTextTile(self.mShowHeroGolemWearBtn,ccClientText(33223))

    local attrPreViewDescTrans = self:FindWndTrans(self.mAttrPreViewDiv,"Desc")
    self:SetWndText(attrPreViewDescTrans,ccClientText(34842))
    --屏蔽按钮
    CS.ShowObject(self.mShowGolemIntensify1Btn,false)
    CS.ShowObject(self.mShowGolemIntensify2BtnDiv,false)
end

function UISubGolemRecast:GetGolemLockInfoByAttrInfo(attrInfo,index)
    local golemLockInfo = gModelGolem:GetGolemLockInfoFormData({
        attrType = attrInfo.showType,
        index = index,
    })
    return golemLockInfo
end

function UISubGolemRecast:RefreshGolemDemountBtnStatus(slotServerDataList)
    local num = 0
    for k,v in pairs(slotServerDataList) do
        num = num + 1
    end
    local showGolemWear = num < ModelGolem.SHOW_GOLEM_NUM
    CS.ShowObject(self.mShowHeroGolemDemountBtn,not showGolemWear)
    CS.ShowObject(self.mShowHeroGolemWearBtn,showGolemWear)
end

function UISubGolemRecast:OnWndRefresh()
    self:InitChangeData()
    self:RefreshView()
end

function UISubGolemRecast:OnClickReturnBtnFunc()
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_RETURNBTN) then return end

    self:WndClose()
end

function UISubGolemRecast:GetRecastBeforeAttrList(showGouBtn)
    local golemServerData = self:GetGolemServerData()
    if not golemServerData then return {} end

    local attrGroupIdListLen = gModelGolem:GetGolemElementAttrGroupIdListLenByGolemInfo(golemServerData)
    local isSingle = showGouBtn and attrGroupIdListLen == 1
    local primeIndex = ModelGolem.LOCK_INFO_INDEX_START
    local deputyIndex = ModelGolem.LOCK_INFO_INDEX_START
    local showType
    local list = {}
    local attrList = gModelGolem:GetGolemAllAttrList(golemServerData)
    for i,v in ipairs(attrList) do
        local tempIndex
        local showEmptyRoot = false
        showType = v.showType
        if showType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
            tempIndex = primeIndex
            primeIndex = primeIndex + 1
            showEmptyRoot = isSingle
        elseif showType == ModelGolem.GOLEM_DIV_ATTR_DEPUTY then
            tempIndex = deputyIndex
            deputyIndex = deputyIndex + 1
        end
        if tempIndex then
            local golemLockInfo = self:GetGolemLockInfoByAttrInfo(v,tempIndex)
            table.insert(list,{
                attrInfo = v,
                golemLockInfo = golemLockInfo,
                showGouBtn = showGouBtn,
                showEmptyRoot = showEmptyRoot,
                recastType = UISubGolemRecast.TYPE_RECAST_BEFORE,
            })
        end
    end
    return list
end

------------------------- List -------------------------
function UISubGolemRecast:OnWndRefreshPanel()
    self:InitChangeData()
    self:RefreshView()
end

function UISubGolemRecast:CheckIsSelRecastLockInfo(golemLockInfo)
    if not golemLockInfo then return false end
    local golemLockInfoMap = self._golemLockInfoMap
    if not golemLockInfoMap then return false end
    local key = golemLockInfo.key
    return golemLockInfoMap[key] and true or false
end

function UISubGolemRecast:InitSelGolemIdMap()
    self._selGolemIdMap = {}
end

function UISubGolemRecast:OnClickRecastTypeTabFunc(itemdata)
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_RECASTTYPETABBTN) then return end

    local recastType = itemdata.recastType
    local isSel = recastType == self._recastType
    if isSel then return end

    self._recastType = recastType
    self:RefreshRecastTypeView()
end

function UISubGolemRecast:GetEventShowTips(eventType)
    if not eventType then return UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS end

    local eventSwitchMap = self._eventSwitchMap
    if not eventSwitchMap then
        eventSwitchMap = UISubGolemRecast.EVENT_SWITCH_LIST
    end

    local eventShow = eventSwitchMap[eventType]
    if not eventShow then
        eventShow = UISubGolemRecast.EVENT_SWITCH_LIST[eventType]
    end

    if not eventShow then
        eventShow = UISubGolemRecast.TYPE_SWITCH_STATUS_NOTTIPS
    end

    return eventShow
end

--- 刷新魔偶
function UISubGolemRecast:RefreshShowGolemView()
    local golemServerData = self:GetGolemServerData()
    if not golemServerData then
        self:InitGolemItemList()
        self:CreateGolemIcon(self.mShowGolemRoot,golemServerData)
        return
    end
    self:CreateGolemIcon(self.mShowGolemRoot,golemServerData)
    if not self:ChangeGolemUseRecastType() then
        self:RefreshRecastDiv()
        self:InitGolemItemList()
    end
end

function UISubGolemRecast:OnClickRecastCellBtnFunc(itemdata)
    local recastType = itemdata.recastType
    if recastType == UISubGolemRecast.TYPE_RECAST_LATER then return end
end

function UISubGolemRecast:ChangeGolemId(golemId)
    self._golemId = golemId
    self:UpdateGolemId()
    self:InitGolemServerData()
end

function UISubGolemRecast:CreateCommonBaseClass(trans)
    local IconTrans = self:FindWndTrans(trans,"CommonUI/Icon")
    local instanceID = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    return baseClass
end

function UISubGolemRecast:OnDrawGolemItemCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
    local isSel = self:CheckIsSelGolemId(itemdata)
    self:CreateGolemIcon(item,itemdata,{
        showGou = isSel,
        isLock = itemdata.isLock,
    })
    self:SetWndClick(IconTrans,function()
        self:OnClickGolemItemFunc(itemdata)
    end)
    -- 长按
    self:SetWndLongClick(IconTrans,function()
        ----- 魔偶属性详情界面
        gModelGolem:OpenGolemInfoTip({
            viewType = 2,
            golemData = itemdata,
        })
    end,0.8,false)


end

function UISubGolemRecast:InitGolemLockInfoData()
    self:InitGolemLockInfoNum()
    self:InitGolemLockInfoMap()
end

function UISubGolemRecast:RefreshGolemRecastDescTxt()
    local recastType = self._recastType or ModelGolem.RECAST_TYPE_BASE
    local consumeNum = self:GetGolemConsumeNum()
    local selGolemIdNum = self:GetSelGolemIdNum()
    local golemStars = gModelGolem:GetGolemStars()
    local isSelEnough = selGolemIdNum >= consumeNum
    local textStr
    if recastType == ModelGolem.RECAST_TYPE_BASE then
        local textId = isSelEnough and 34820 or 34819
        textStr = string.replace(ccClientText(textId),golemStars,selGolemIdNum,consumeNum)
    else
        local textId = isSelEnough and 34822 or 34821
        textStr = string.replace(ccClientText(textId),golemStars,selGolemIdNum,consumeNum)
    end
    self:SetWndText(self.mRecastDescTxt,textStr)

    local needItemList = {}
    local recasteExpend = gModelGolem:GetGolemConfigRefByKey("recasteExpend")
    for i,v in ipairs(recasteExpend) do
        table.insert(needItemList,{
            itemType = v.itemType,
            itemId = v.itemId,
            itemNum = v.itemNum * selGolemIdNum,
        })
    end
    self:InitNeedItemList(needItemList)
end

function UISubGolemRecast:RefreshBeforeAttrList()
    local showGouBtn = self._recastType == ModelGolem.RECAST_TYPE_HIGH
    local beforeAttrList = self:GetRecastBeforeAttrList(showGouBtn)
    CS.ShowObject(self.mNotAttrTips,#beforeAttrList<=0)
    self:CreateRecastDiv(self.mBeforeRecastDiv,beforeAttrList)
end

function UISubGolemRecast:OnClickGolemItemFunc(itemdata)
    if itemdata.isLock then
        gModelGolem:ChangeGolemLockStatusByGolemInfo(itemdata)
        return
    end
    local isSel = self:CheckIsSelGolemId(itemdata)
    local id = gModelGolem:GetGolemIdByGolemInfo(itemdata)
    if isSel then
        self._selGolemIdMap[id] = nil
    else
        local consumeNum = self:GetGolemConsumeNum()
        local selGolemIdNum = self:GetSelGolemIdNum()
        if selGolemIdNum >= consumeNum then
            GF.ShowMessage(ccClientText(34833))
            return
        end
        self._selGolemIdMap[id] = itemdata
    end
    self:InitGolemItemList()
end

function UISubGolemRecast:GetKeyChoiceGolemItemList()
    local list = self:GetGolemItemList()
    if #list < 1 then return {} end
    local golemItemList = {}
    for i,golemInfo in ipairs(list) do
        if not gModelGolem:GetGolemIsLockByGolemInfo(golemInfo) then
            table.insert(golemItemList,golemInfo)
        end
    end
    return golemItemList
end

function UISubGolemRecast:GetSelGolemIdNum()
    local selGolemIdNum = 0
    local selGolemIdMap = self._selGolemIdMap or {}
    for k,v in pairs(selGolemIdMap) do
        selGolemIdNum = selGolemIdNum + 1
    end
    return selGolemIdNum
end

function UISubGolemRecast:InitGolemServerData()
    if not self._golemId then
        self._golemServerData = nil
        return
    end
    self._golemServerData = gModelGolem:GetGolemServerDataById(self._golemId)
end

function UISubGolemRecast:OnGolemAttrSaveResp(pb)
    if pb.golemId ~= self._golemId then return end
    self:InitSelGolemIdMap()
    self:InitGolemServerData()
    self:RefreshRecastDiv()
    self:InitGolemItemList()
end

function UISubGolemRecast:OnDrawRecastTypeTabCell(list,item,itemdata,itempos)
    local BtnTab2Trans = self:FindWndTrans(item,"BtnTab2")
    self:SetWndTabText(BtnTab2Trans,itemdata.btnName)

    local recastType = itemdata.recastType
    local isSel = recastType == self._recastType
    local status = isSel and self.StateOn or self.StateOff
    self:SetWndTabStatus(BtnTab2Trans,status)

    self:SetWndClick(BtnTab2Trans,function()
        self:OnClickRecastTypeTabFunc(itemdata)
    end)
end

function UISubGolemRecast:UpdateGolemId()
    local params = self:GetWndArgList()
    params.golemId = self._golemId
end

function UISubGolemRecast:InitEvent()
    self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
    self:SetWndClick(self.mRecastTypeHelpBtn,function() self:OnClickHelpBtnFunc() end)
    self:SetWndClick(self.mGolemChangeBtn,function() self:OnClickGolemChangeBtnFunc() end)
    self:SetWndClick(self.mShowGolemIntensify1Btn,function() self:OnClickShowGolemIntensify1BtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemBtn,function() self:OnClickShowHeroGolemBtnFunc() end)
    self:SetWndClick(self.mHeroChangeBtn,function() self:OnClickHeroChangeBtnFunc() end)
    self:SetWndClick(self.mShowGolemIntensify2Btn,function() self:OnClickShowGolemIntensify2BtnFunc() end)
    self:SetWndClick(self.mShowGolemBagBtn,function() self:OnClickShowGolemBagBtnFunc() end)
    self:SetWndClick(self.mReturnBtn,function() self:OnClickReturnBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mRecastBtn,function() self:OnClickRecastBtnFunc() end)
    self:SetWndClick(self.mRecastOptBtn,function() self:OnClickRecastOptBtnFunc() end)
    self:SetWndClick(self.mKeyChoiceeBtn,function() self:OnClickKeyChoiceeBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemDemountBtn,function() self:OnClickShowHeroGolemDemountBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemWearBtn,function() self:OnClickShowHeroGolemWearBtnFunc() end)

    local attrPreViewBtnTrans = self:FindWndTrans(self.mAttrPreViewDiv,"Btn")
    self:SetWndClick(attrPreViewBtnTrans,function() self:OnClickAttrPreViewBtnFunc() end)
end
---------------------------------------------   uiGolemItemList
function UISubGolemRecast:GetGolemItemList()
    local golemServerData = self:GetGolemServerData()
    if not golemServerData then return {} end
    local list = gModelGolem:GetRecastMaterialsList({
        golemServerData = golemServerData,
        recastType = self._recastType or ModelGolem.RECAST_TYPE_BASE,
    })
    return list
end

function UISubGolemRecast:InitGolemLockInfoMap()
    self._golemLockInfoMap = {}
end

------------------------- List -------------------------

---------------------------------------------   uiShowHeroWearGolemList
function UISubGolemRecast:GetShowHeroWearGolemList()
    local list = {}
    local slotServerDataList = self._slotServerDataList or {}
    for i = 1,ModelGolem.SHOW_GOLEM_NUM do
        table.insert(list,{
            golemInfo = slotServerDataList[i],
            golemIndex = i,
        })
    end
    return list
end

function UISubGolemRecast:InitShowHeroGolemData()
    local heroServerData = self:GetWndArg("heroServerData")
    self._heroServerData = heroServerData

    self:RefreshHeroId()
    self:RefreshHeroGolemData()
end

function UISubGolemRecast:RefreshLaterAttrList()
    local showGouBtn = self._recastType == ModelGolem.RECAST_TYPE_HIGH
    local beforeAttrList = self:GetRecastBeforeAttrList(showGouBtn)
    local laterAttrList = self:GetRecastLaterAttrList(beforeAttrList)
    self:CreateRecastDiv(self.mLaterRecastDiv,laterAttrList)
end

function UISubGolemRecast:RefreshHeroId()
    local heroServerData = self._heroServerData
    if not heroServerData then return end
    self._heroId = heroServerData.id
end

function UISubGolemRecast:OnClickRecastOptBtnFunc()
    local golemId = self._golemId
    if not golemId then return end
    gModelGeneral:OpenUIOrdinTips({
        refId = 310022,
        func = function()
            gModelGolem:OnGolemAttrSaveReq(golemId,ModelGolem.RECAST_SAVETYPE_SAVE)
        end,
        leftFunc = function()
            gModelGolem:OnGolemAttrSaveReq(golemId,ModelGolem.RECAST_SAVETYPE_CANCEL)
        end,
    })
end

function UISubGolemRecast:RefreshHeroServerData()
    if not self._heroId then return end
    self._heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
end

function UISubGolemRecast:InitChangeData()
    self._viewType = self:GetWndArg("viewType")
    self._golemId = self:GetWndArg("golemId")
    local golemInfo = self:GetGolemServerData()
    if not self._viewType then
        self._viewType = gModelGolem:CheckGolemIsWearByGolemInfo(golemInfo or {}) and UISubGolemRecast.TYPE_HERO or UISubGolemRecast.TYPE_GOLEM
    end
    self:InitSelGolemIdMap()
    self:InitGolemServerData()
end

function UISubGolemRecast:GetRecastLaterAttrList(beforeAttrList)
    beforeAttrList = beforeAttrList or {}
    local golemServerData = self:GetGolemServerData()
    if not golemServerData then return {} end
    local list = {}
    local attrList = gModelGolem:GetGolemRecastAllAttrList(golemServerData)
    for i,v in ipairs(attrList) do
        local changeFontColor = false
        local laterAttrInfo = v
        local beforeAttrInfo = beforeAttrList[i]
        if beforeAttrInfo then
            if beforeAttrInfo.attrInfo.golemAttrRefId ~= laterAttrInfo.golemAttrRefId then
                changeFontColor = true
            end
        end
        table.insert(list,{
            attrInfo = laterAttrInfo,
            showGouBtn = false,
            changeFontColor = changeFontColor,
            recastType = UISubGolemRecast.TYPE_RECAST_LATER,
        })
    end

    local curLen = #list
    local showeOptBtn = curLen > 0
    CS.ShowObject(self.mRecastOptBtnDiv,showeOptBtn)

    local beforeLen = #beforeAttrList
    local laterLen = #list
    if beforeLen > laterLen then
        local lostNum = beforeLen - laterLen
        for i = 1,lostNum do
            table.insert(list,{
                showGouBtn = false,
                showEmptyRoot = false,
                notTxt = "?",
                recastType = UISubGolemRecast.TYPE_RECAST_LATER,
            })
        end
    end
    return list
end

function UISubGolemRecast:InitMsg()
    self:WndNetMsgRecv(LProtoIds.GolemSlotResp,function(pb) self:OnGolemSlotResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemRecastResp,function(pb) self:OnGolemRecastResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemWearResp,function(pb) self:OnGolemWearResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemAttrSaveResp,function(pb) self:OnGolemAttrSaveResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemLockResp,function(pb) self:OnGolemLockResp(pb) end)

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISubGolemRecast:OnClickShowGolemIntensify2BtnFunc()
    self:OpenGolemIntensify()
end

function UISubGolemRecast:InitGolemItemList()
    local list = self:GetGolemItemList()
    local uiGolemItemList = self._uiGolemItemList
    if uiGolemItemList then
        uiGolemItemList:RefreshList(list)
        uiGolemItemList:DrawAllItems(false)
    else
        uiGolemItemList = self:GetUIScroll("uiGolemItemList")
        self._uiGolemItemList = uiGolemItemList
        uiGolemItemList:Create(self.mGolemItemList,list,function(...) self:OnDrawGolemItemCell(...) end,UIItemList.SUPER_GRID)
    end
    self:RefreshGolemRecastDescTxt()
    local isEmpty = #list < 1
    if isEmpty then
        local wndId
        if self._golemId then
            local recastType = self._recastType or ModelGolem.RECAST_TYPE_BASE
            if recastType == ModelGolem.RECAST_TYPE_BASE then
                --- 未有任意5星魔偶时显示空列表id
                wndId = 29004
            else
                --- 未同名5星魔偶时显示空列表id
                wndId = 29005
            end
        else
            --- 未有可重铸魔偶时显示空列表id
            wndId = 29006
        end
        self:SetEmptyList(wndId)
    end
    CS.ShowObject(self.mNotItemRecord,isEmpty)
end

function UISubGolemRecast:OnDrawShowHeroWearGolemCell(list,item,itemdata,itempos)
    local SelTrans = self:FindWndTrans(item,"Sel")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local EffRootTrans = self:FindWndTrans(item,"EffRoot")

    local golemInfo = itemdata.golemInfo
    self:CreateGolemIcon(item,golemInfo)

    local isSel = self:CheckIsSelHeroWearGolem(golemInfo)
    CS.ShowObject(SelTrans,isSel)

    local showEff = false
    CS.ShowObject(EffRootTrans,showEff)


    self:SetWndClick(BtnTrans,function()
        self:OnClickShowHeroWearGolemFunc(itemdata)
    end)
end

function UISubGolemRecast:InitShowHeroWearGolemList()
    local list = self:GetShowHeroWearGolemList()
    local uiShowHeroWearGolemList = self._uiShowHeroWearGolemList
    if uiShowHeroWearGolemList then
        uiShowHeroWearGolemList:RefreshList(list)
    else
        uiShowHeroWearGolemList = self:GetUIScroll("uiShowHeroWearGolemList")
        self._uiShowHeroWearGolemList = uiShowHeroWearGolemList
        uiShowHeroWearGolemList:Create(self.mShowHeroWearGolemList,list,function(...) self:OnDrawShowHeroWearGolemCell(...) end)
    end
end

--- 刷新英雄魔偶
function UISubGolemRecast:RefreshShowHeroGolemView()
    self:CreateHeroIcon()
    self:InitShowHeroWearGolemList()
    if not self:ChangeGolemUseRecastType() then
        self:RefreshRecastDiv()
        self:InitGolemItemList()
    end
end

function UISubGolemRecast:InitRecastTypeTabList()
    local list = self:GetRecastTypeTabList()
    local uiRecastTypeTabList = self._uiRecastTypeTabList
    if uiRecastTypeTabList then
        uiRecastTypeTabList:RefreshList(list)
    else
        uiRecastTypeTabList = self:GetUIScroll("uiRecastTypeTabList")
        self._uiRecastTypeTabList = uiRecastTypeTabList
        uiRecastTypeTabList:Create(self.mRecastTypeTabList,list,function(...) self:OnDrawRecastTypeTabCell(...) end)
    end
end

function UISubGolemRecast:OnClickKeyChoiceeBtnFunc()
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_KEYCHOICEEBTN) then return end

    local selGolemIdNum = self:GetSelGolemIdNum()
    local consumeNum = self:GetGolemConsumeNum()
    if selGolemIdNum >= consumeNum then
        GF.ShowMessage(ccClientText(34833))
        return
    end
    local list = self:GetKeyChoiceGolemItemList()
    if #list < 1 then
        GF.ShowMessage(ccClientText(34840))
        return
    end
    local golemId
    local selGolemIdMap = self._selGolemIdMap or {}
    for i,golemInfo in ipairs(list) do
        if selGolemIdNum >= consumeNum then
            break
        end
        golemId = gModelGolem:GetGolemIdByGolemInfo(golemInfo)
        if not selGolemIdMap[golemId] then
            selGolemIdMap[golemId] = golemInfo
            selGolemIdNum = selGolemIdNum + 1
        end
    end
    self:InitGolemItemList()
end

function UISubGolemRecast:OnClickGolemChangeBtnFunc()
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_GOLEMVIEWGOLEMCHANGEBTN) then return end

    if not self._golemId then return end

    gModelGolem:OpenGolemWarehouse({
        viewType = 4,
        optType = ModelGolem.TYPE_OPT_RECAST,
        golemId = self._golemId,
        optStatus = ModelGolem.OPTSTATUS_WAREHOUSE_RECAST,
        showNeedGolemStar = gModelGolem:GetGolemStars(),
        selGolemFunc = function(selGolemId)
            if not self:IsWndValid() then return end
            if not selGolemId then return end
            self._golemId = selGolemId
            self._golemServerData = nil
            self:UpdateGolemId()
            self:RefreshShowGolemView()
        end,
    })
end

function UISubGolemRecast:ChangeGolemUseRecastType()
    local isHaveRecastResult = self:CheckGolemIsHaveRecastResult()
    if not isHaveRecastResult then return false end

    local golemServerData = self:GetGolemServerData()
    if not golemServerData then return false end

    local golemCurRecastType = gModelGolem:GetGolemUseRecastTypeByGolemInfo(golemServerData)
    if not golemCurRecastType then return false end

    local curRecastType = self._recastType
    local isSame = curRecastType == golemCurRecastType
    if isSame then return false end

    if LOG_INFO_ENABLED then
        printInfoNR("打印而已，莫慌      当前的重铸类型 ： " .. curRecastType .. "，修改为 ： " .. golemCurRecastType)
    end

    self._recastType = golemCurRecastType
    self:RefreshRecastTypeView()
    return true
end

function UISubGolemRecast:OnClickShowHeroGolemWearBtnFunc()
    local heroServerData = self._heroServerData
    if not heroServerData then return end
    local slotServerDataList = self._slotServerDataList or {}
    gModelGolem:OpenGolemWear({
        heroServerData = heroServerData,
        wearList = slotServerDataList,
    })
end

function UISubGolemRecast:OpenGolemIntensify()
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_INTENSIFYBTN) then return end

    local golemServerData = self:GetGolemServerData()
    if not golemServerData then return end
    local heroServerData = self._heroServerData
    local viewType = heroServerData ~= nil and 1 or 2
    -- gModelGolem:OpenGolemIntensify({
    --     golemInfo = golemServerData,
    --     golemId = gModelGolem:GetGolemIdByGolemInfo(golemServerData),
    --     heroServerData = heroServerData,
    --     viewType = viewType,
    --     closeWndFunc = function()
    --         self:WndClose()
    --     end,
    -- })
	GF.OpenWnd("UIGolemMainWin",{
		    golemInfo = golemServerData,
		    golemId = gModelGolem:GetGolemIdByGolemInfo(golemServerData),
		    heroServerData = heroServerData,
		    viewType = viewType,
			page = 4
		})
end

function UISubGolemRecast:CreateHeroIcon()
    local heroId = self._heroId
    if not heroId then return end
    local baseClass = self:CreateCommonBaseClass(self.mHeroShowRoot)
    baseClass:SetHeroPlayer(heroId)
    baseClass:DoApply()
end

function UISubGolemRecast:OnClickShowHeroGolemBtnFunc()
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_SHOWHEROGOLEMBTN) then return end

    local golemInfo,golemId
    local heroId = self._heroId
    local wearMap,wearList = gModelGolem:GetHeroWearGolemListByHeroId(heroId)
    if #wearList > 0 then
        local needNewGolemId = true
        if ModelGolem.TYPE_GOLEM_USEHEO == 1 then
            local curGolemId = self._golemId
            local curGolemServerData = curGolemId and gModelGolem:GetGolemServerDataById(curGolemId)
            local isHaveData = curGolemServerData ~= nil
            if isHaveData then
                local golemDrawing = gModelGolem:GetGolemElementGolemDrawingByGolemInfo(curGolemServerData)--槽位
                local drawGolem = wearMap[golemDrawing]
                if (not string.isempty(drawGolem)) and drawGolem == curGolemId then
                    needNewGolemId = false
                    golemId = curGolemId
                    golemInfo = curGolemServerData
                end
            end
        end
        if needNewGolemId then
            local first = wearList[1]
            if first then
                golemId = first.golemId
                golemInfo = first.golemInfo
            end
        end
    else
        heroId = nil
    end
    if not heroId then
        local list = gModelHero:GetHaveHeroGolemList()
        --if #list < 1 then
        --    gModelHero:SaveHaveHeroGoleList()
        --    list = gModelHero:GetHaveHeroGolemList()
        --end
        if #list < 1 then
            self:ShowNoHeroWearMsg()
            return
        end
        for i,v in ipairs(list) do
            if v.id then
                wearMap,wearList = gModelGolem:GetHeroWearGolemListByHeroId(v.id)
                if #wearList > 0 then
                    local first = wearList[1]
                    if first then
                        golemId = first.golemId
                        golemInfo = first.golemInfo
                        heroId = v.id
                    end
                    break
                end
            end
        end
    end
    if not golemId or not golemInfo then
        self:ShowNoHeroWearMsg()
        return
    end
    local heroServerData = gModelHero:GetHeroServerDataById(heroId)
    self:SetWndArg({
        golemId = golemId,
        golemInfo = golemInfo,
        heroServerData = heroServerData,
        viewType = UISubGolemRecast.TYPE_HERO,
    })
    self:OnWndRefreshPanel()
end

function UISubGolemRecast:GetGolemServerData()
    if not self._golemServerData then
        self:InitGolemServerData()
    end
    return self._golemServerData
end

function UISubGolemRecast:SetEmptyList(refId)
    local NotItemEmptyData = {
        refId = refId or 29002,
        IntroTran = self.mNotItemEmptyText,
        TextBgTran = self.mNotItemEmptyTextBg,
        IconTran = self.mNotItemEmptyIcon,
    }
    local NotItemEmpty = self:GetCommonEmptyList("NotItemEmpty")
    NotItemEmpty:RefreshUI(NotItemEmptyData)
end

function UISubGolemRecast:OnClickHelpBtnFunc()
    local recastType = self._recastType or ModelGolem.RECAST_TYPE_BASE
    local refId = UISubGolemRecast.RECAST_TYPE_TIPS[recastType]
    GF.OpenWnd("UIBzTips",{refId = refId})
end

function UISubGolemRecast:OnClickAttrPreViewBtnFunc()
    local golemServerData = self:GetGolemServerData()
    if not golemServerData then return end

    local golemTipsArrow = gModelGolem:GetGolemConfigRefByKey("golemTipsArrow")
    if not golemTipsArrow then
        golemTipsArrow = 0
    end
    local showgolemTipsArrow = golemTipsArrow == 1

    local offset = Vector3(0,0,0)
    gModelGolem:OpenGolemPreviewAttr({
        viewType = 2,
        golemInfo = golemServerData,
        followRoot = self.mShowTipsRoot,
        offsetPos = offset,
        showArrow = showgolemTipsArrow,
    })
end

function UISubGolemRecast:RefreshHeroGolemData()
    if self._viewType ~= UISubGolemRecast.TYPE_HERO then return end
    if not self._heroId then return end
    gModelGolem:OnGolemSlotReq(self._heroId)
end

function UISubGolemRecast:CheckGolemIsHaveRecastResult()
    local golemServerData = self:GetGolemServerData()
    if not golemServerData then return false end
    return gModelGolem:CheckGolemIsHaveRecastResultByGolemInfo(golemServerData)
end

function UISubGolemRecast:OnGolemSlotResp(pb)
    if not self._heroId then return end
    if self._heroId ~= pb.heroId then return end
    local viewType = self._viewType
    if viewType ~= UISubGolemRecast.TYPE_HERO then return end
    --self:RefreshHeroServerData()
    local slotServerDataList = gModelGolem:GetGolemSlotRespSlotServerDataList(pb)
    self:RefreshGolemDemountBtnStatus(slotServerDataList)
    self._slotServerDataList = slotServerDataList
    if not self._golemId then
        local slotServerData
        for i = 1,ModelGolem.SHOW_GOLEM_NUM do
            slotServerData = slotServerDataList[i]
            if slotServerData then
                self._golemId = gModelGolem:GetGolemIdByGolemInfo(slotServerData)
                self:UpdateGolemId()
                self:InitGolemServerData()
                break
            end
        end
    end
    self:RefreshShowHeroGolemView()
end

function UISubGolemRecast:SetGolemLockInfoMapData(data)
    if not data then return end
    local golemLockInfo = data.golemLockInfo
    if not golemLockInfo then return end
    local key = golemLockInfo.key
    if not key then return  end
    if not self._golemLockInfoMap then
        self:InitGolemLockInfoMap()
    end
    local golemLockInfoNum = self._golemLockInfoNum
    if not golemLockInfoNum then
        self:InitGolemLockInfoNum()
        golemLockInfoNum = self._golemLockInfoNum
    end
    if golemLockInfoNum == 1 then
        self:InitGolemLockInfoMap()
    end
    self._golemLockInfoMap[key] = golemLockInfo
end

function UISubGolemRecast:GetGolemConsumeNum()
    local recastType = self._recastType or ModelGolem.RECAST_TYPE_BASE
    local consumeNum = 0
    local golemServerData = self:GetGolemServerData()
    if golemServerData then
        consumeNum = gModelGolem:GetGolemRecastConsumeNumByGolemInfo(golemServerData,recastType)
    end
    return consumeNum
end

function UISubGolemRecast:OnClickRecastBtnFunc()
    local golemId = self._golemId
    if not golemId then return end
    if golemId and not gModelGolem:GetGolemServerDataById(golemId) then
        GF.ShowMessage(ccClientText(33301))
        return end

    local func = function()
        if not self:IsWndValid() then return end
        local selGolemIdNum = self:GetSelGolemIdNum()
        local consumeNum = self:GetGolemConsumeNum()
        if selGolemIdNum < consumeNum then
            GF.ShowMessage(ccClientText(34839))
            return
        end

        local selGolemIdMap = self._selGolemIdMap or {}
        local consumeGolemIdList = {}
        for k,v in pairs(selGolemIdMap) do
            table.insert(consumeGolemIdList,k)
        end

        local needItemList = {}
        local recasteExpend = gModelGolem:GetGolemConfigRefByKey("recasteExpend")
        for i,v in ipairs(recasteExpend) do
            table.insert(needItemList,{
                itemType = v.itemType,
                itemId = v.itemId,
                itemNum = v.itemNum * selGolemIdNum,
            })
        end

        local isEnough = gModelGeneral:CheckItemListEnough(needItemList,self:GetWndName())
        if not isEnough then return end

        local recastType = self._recastType or ModelGolem.RECAST_TYPE_BASE
        if recastType == ModelGolem.RECAST_TYPE_BASE then
            gModelGolem:CheckRecastGolemIsHaveIntensifyGolem(golemId,consumeGolemIdList,{})
        else
            local golemLockInfoMap = self._golemLockInfoMap or {}
            local lockInfosList = {}
            for k,v in pairs(golemLockInfoMap) do
                table.insert(lockInfosList,{
                    attrType = v.attrType,
                    index = v.index,
                })
            end
            if #lockInfosList < 1 then
                GF.ShowMessage(ccClientText(34827))
                return
            end
            gModelGolem:CheckRecastGolemIsHaveIntensifyGolem(golemId,consumeGolemIdList,lockInfosList)
        end
    end

    if self:CheckGolemIsHaveRecastResult() then
        self:OpenCommonTips310021(func)
    else
        func()
    end
end

function UISubGolemRecast:ShowNoHeroWearMsg()
    local golemStars = gModelGolem:GetGolemStars()
    local msg = string.replace(ccClientText(34824),golemStars,golemStars)
    GF.ShowMessage(msg)
end

---------------------------------------------   uiRecastTypeTabList
function UISubGolemRecast:GetRecastTypeTabList()
    local list = {}
    table.insert(list,{
        recastType = ModelGolem.RECAST_TYPE_BASE,
        btnName = ccClientText(34817),
    })
    table.insert(list,{
        recastType = ModelGolem.RECAST_TYPE_HIGH,
        btnName = ccClientText(34818),
    })
    return list
end

function UISubGolemRecast:CheckIsSelHeroWearGolem(golemInfo)
    if not golemInfo then return false end
    if not self._golemId then return false end
    local id = gModelGolem:GetGolemIdByGolemInfo(golemInfo)
    return id == self._golemId
end

function UISubGolemRecast:RefreshView()
    self:InitRecastTypeTabList()
    local viewType = self._viewType
    local showHero = viewType == UISubGolemRecast.TYPE_HERO
    local showGolem = viewType == UISubGolemRecast.TYPE_GOLEM
    CS.ShowObject(self.mShowGolemView,showGolem)
    CS.ShowObject(self.mShowHeroGolemView,showHero)
    if showHero then
        self:InitShowHeroGolemData()
    elseif showGolem then
        self:RefreshShowGolemView()
    end
end

function UISubGolemRecast:InitGolemLockInfoNum()
    local golemServerData = self:GetGolemServerData()
    self._golemLockInfoNum = gModelGolem:GetGolemLockInfoNum(golemServerData)
end

function UISubGolemRecast:OnGolemLockResp(pb)
    self:InitGolemItemList()
end

function UISubGolemRecast:InitNeedItemList(list)
    --local list = self:GetNeedItemList()
    local uiNeedItemList = self._uiNeedItemList
    if uiNeedItemList then
        uiNeedItemList:RefreshList(list)
    else
        uiNeedItemList = self:GetUIScroll("uiNeedItemList")
        self._uiNeedItemList = uiNeedItemList
        uiNeedItemList:Create(self.mNeedItemList,list,function(...) self:OnDrawNeedItemCell(...) end)
    end
end

function UISubGolemRecast:CreateGolemIcon(trans,golemInfo,extraData)
    extraData = extraData or {}
    local baseClass = self:CreateCommonBaseClass(trans)
    if golemInfo then
        baseClass:SetGolemData({
            refId = gModelGolem:GetGolemRefIdByGolemInfo(golemInfo),
            lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(golemInfo),
            lvl = gModelGolem:GetGolemLvlByGolemInfo(golemInfo),
            displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(golemInfo),
            showGou = extraData.showGou or false,
            showLock = extraData.isLock or false,
        })
    else
        baseClass:SetGolemData({
            showEmpty = true
        })
    end

    baseClass:DoApply()
end

function UISubGolemRecast:OpenCommonTips310021(func)
    gModelGeneral:OpenUIOrdinTips({refId = 310021, func = func,})
end

function UISubGolemRecast:CheckIsSelGolemId(golemInfo)
    if not self._selGolemIdMap then return false end
    local id = gModelGolem:GetGolemIdByGolemInfo(golemInfo)
    return self._selGolemIdMap[id]
end

function UISubGolemRecast:RefreshRecastDiv()
    self:InitGolemLockInfoData()
    self:RefreshGolemLockInfo()
    self:RefreshBeforeAttrList()
    self:RefreshLaterAttrList()
end

function UISubGolemRecast:CheckIsNotSwitchHero(eventType)
    if not eventType then return false end

    local isHaveRecastResult = self:CheckGolemIsHaveRecastResult()
    if isHaveRecastResult then
        local eventShow = self:GetEventShowTips(eventType)
        if eventShow == UISubGolemRecast.TYPE_SWITCH_STATUS_SHOWTIPS then
            local showTipsInfo = UISubGolemRecast.EVENT_SWITCH_SHOWTIPINFO_LIST[eventType]
            if showTipsInfo then
                local showMsg = showTipsInfo.showMsg
                if showMsg then
                    local msg = showTipsInfo.msg
                    if msg then
                        GF.ShowMessage(msg)
                    end
                end
                local showCommonTips = showTipsInfo.showCommonTips
                if showCommonTips then
                    self:OnClickRecastOptBtnFunc()
                end
            else
                self:OnClickRecastOptBtnFunc()
            end
            return true
        end
    end

    return false
end

function UISubGolemRecast:OnClickShowHeroGolemDemountBtnFunc()
    --- 一键卸下
    local heroId = self._heroId
    if not heroId then return end
    local slotServerDataList = self._slotServerDataList or {}
    local demountList = {}
    for k,v in pairs(slotServerDataList) do
        table.insert(demountList,gModelGolem:GetGolemIdByGolemInfo(v))
    end
    if #demountList < 1 then return end
    gModelGolem:OnGolemWearReq(ModelGolem.OPSTYPE_TYPE_DEMOUNT,heroId,demountList)
end
---------------------------------------------   uiNeedItemList
function UISubGolemRecast:GetNeedItemList()
end

function UISubGolemRecast:OnClickShowGolemIntensify1BtnFunc()
    self:OpenGolemIntensify()
end

function UISubGolemRecast:OnClickShowHeroWearGolemFunc(itemdata)
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_HEROGOLEMLIST) then return end

    local golemInfo = itemdata.golemInfo
    if golemInfo then
        local isSel = self:CheckIsSelHeroWearGolem(golemInfo)
        if isSel then return end
        local golemStar = gModelGolem:GetGolemElementStarByGolemInfo(golemInfo)
        local golemStars = gModelGolem:GetGolemStars()
        if golemStar ~= golemStars then
            GF.ShowMessage(string.replace(ccClientText(34823),golemStars))
            return
        end
        self._golemId = gModelGolem:GetGolemIdByGolemInfo(golemInfo)
        self:UpdateGolemId()
        self:InitGolemServerData()
        self:RefreshShowHeroGolemView()
        self:InitSelGolemIdMap()
        self:InitGolemItemList()
    else
        --- 魔偶仓库界面
        gModelGolem:OpenGolemWarehouse({
            viewType = 2,
            optType = ModelGolem.TYPE_OPT_WEAR,
            golemIndex = itemdata.golemIndex,
            heroId = self._heroId,
            optStatus = ModelGolem.OPTSTATUS_WAREHOUSE_NORMAL,
        })
    end

end

function UISubGolemRecast:OnClickShowGolemBagBtnFunc()
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_SHOWGOLEMBAGBTN) then return end
    local golemData
    if ModelGolem.TYPE_GOLEM_USEHEO == 0 then
        golemData = gModelGolem:GetIntensifyGolemId()
    elseif ModelGolem.TYPE_GOLEM_USEHEO == 1 then
        local golemServerData = self:GetGolemServerData()
        local isHaveData = golemServerData ~= nil
        golemData = {
            status = isHaveData and 1 or -1,
            golemId = isHaveData and gModelGolem:GetGolemIdByGolemInfo(golemServerData),
            golemInfo = golemServerData,
        }
    end
    local status = golemData.status
    if status == -1 then
        gModelGeneral:OpenUIOrdinTips({refId = 310009,func = function()
            gModelGolem:JumpDreamKillWnd(self:GetWndName())
        end})

        return
    end

    local golemId,golemInfo = golemData.golemId , golemData.golemInfo
    local heroServerData = self._heroServerData
    self:SetWndArg({
        golemInfo = golemInfo,
        golemId = golemId,
        heroServerData = heroServerData,
        viewType = UISubGolemRecast.TYPE_GOLEM,
    })
	self:OnWndRefreshPanel()
end

function UISubGolemRecast:RefreshRecastTypeView()
    self:InitSelGolemIdMap()
    self:RefreshRecastDiv()
    self:InitRecastTypeTabList()
    self:InitGolemItemList()
end

function UISubGolemRecast:OnGolemWearResp(pb)
    if pb.opsType == ModelGolem.OPSTYPE_TYPE_DEMOUNT then
        for i,v in ipairs(pb.golemId) do
            if v == self._golemId then
                self._golemId = nil
            end
        end
        self:UpdateGolemId()
        self:InitGolemServerData()
    elseif pb.opsType == ModelGolem.OPSTYPE_TYPE_WEAR then
        if not self._golemId then
            for i,v in ipairs(pb.golemId) do
                self._golemId = v
                break
            end
            self:UpdateGolemId()
            self:InitGolemServerData()
        end
    end
    self:RefreshHeroGolemData()
end

function UISubGolemRecast:OnDrawNeedItemCell(list,item,itemdata,itempos)
    local IconDivTrans = self:FindWndTrans(item,"IconDiv")
    local IconTrans = self:FindWndTrans(IconDivTrans,"Icon")
    local IconNumTrans = self:FindWndTrans(item,"IconNum")

    local itemId = itemdata.itemId
    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(IconTrans,icon,function()
        CS.ShowObject(IconTrans,true)
        CS.ShowObject(IconDivTrans,true)
    end)

    local haveNum = gModelItem:GetNumByRefId(itemId)
    local payNum = itemdata.itemNum
    local color = haveNum >= payNum and "lightGreen" or "lightRed"
    local payStr = LUtil.NumberCoversion(payNum)
    local str = LUtil.FormatColorStr(payStr,color)
    self:SetWndText(IconNumTrans,str)
end

---------------------------------------------   RecastList
function UISubGolemRecast:InitRecastList(trans,list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans,list,function(...) self:OnDrawRecastCell(...) end)
    end
end

function UISubGolemRecast:RefreshGolemLockInfo()
    self:InitGolemLockInfoMap()
    local golemServerData = self:GetGolemServerData()
    if not golemServerData then
        return
    end
    local key
    local lockInfo = gModelGolem:GetGolemLockInfoByGolemInfo(golemServerData)
    for i,v in ipairs(lockInfo) do
        key = v.key
        self._golemLockInfoMap[key] = v
    end
end

function UISubGolemRecast:OnClickHeroChangeBtnFunc()
    if self:CheckIsNotSwitchHero(UISubGolemRecast.EVENT_SWITCH_HEROVIEWHEROCHANGEBTN) then return end

    gModelGolem:OpenGolemSwitchHero({
        wndType = 3,
        curSelHeroId = self._heroId,
        func = function(selHeroId)
            if not self:IsWndValid() then return end
            if not selHeroId then return end
            if selHeroId ~= self._heroId then
                self._golemId = nil
                self._golemServerData = nil
                self:UpdateGolemId()
                self:InitSelGolemIdMap()
            end
            self._heroId = selHeroId
            self:RefreshHeroServerData()
            self:RefreshHeroGolemData()
        end,
    })
end

function UISubGolemRecast:OnClickRecastCellGouBtnFunc(itemdata)
    local recastType = itemdata.recastType
    if recastType == UISubGolemRecast.TYPE_RECAST_LATER then return end
    local showGouBtn = itemdata.showGouBtn
    if not showGouBtn then return end
    local golemLockInfo = itemdata.golemLockInfo
    local isSel = self:CheckIsSelRecastLockInfo(golemLockInfo)
    if isSel then return end
    self:SetGolemLockInfoMapData(itemdata)
    self:RefreshBeforeAttrList()
end

function UISubGolemRecast:OnDrawRecastCell(list,item,itemdata,itempos)
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local ZSXBgTrans = self:FindWndTrans(item,"ZSXBg")
    local AutoRootTrans = self:FindWndTrans(item,"AutoRoot")
    local EmptyRootTrans = self:FindWndTrans(AutoRootTrans,"EmptyRoot")
    local GouBtnTrans = self:FindWndTrans(AutoRootTrans,"GouBtn")
    local GouTrans = self:FindWndTrans(GouBtnTrans,"Gou")
    local AttrNameTrans = self:FindWndTrans(AutoRootTrans,"AttrName")
    local AttrValueTrans = self:FindWndTrans(item,"AttrValue")
    local NotTipsTrans = self:FindWndTrans(item,"NotTips")

    local attrInfo = itemdata.attrInfo
    local showAttrInfo = attrInfo ~= nil
    if showAttrInfo then
        local attrRefId = attrInfo.attrRefId

        local attrName = gModelHero:GetAttributeNameById(attrRefId)
        self:SetWndText(AttrNameTrans,attrName)

        local attrType = attrInfo.attrType
        local attrNum = attrInfo.attrNum
        local attrNumStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)

        local changeFontColor = itemdata.changeFontColor or false
        -- local color = changeFontColor and "lightGreen" or "yellow_2"

        -- attrNumStr = LUtil.FormatColorStr(attrNumStr,color)
        self:SetWndText(AttrValueTrans,attrNumStr)
        local showType = attrInfo.showType or 0
        local showZSXBg = false
        if showType and showType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
            showZSXBg = true
        end
        CS.ShowObject(ZSXBgTrans,showZSXBg)

        local showEmptyRoot = itemdata.showEmptyRoot or false
        local showGouBtn = itemdata.showGouBtn
        if showGouBtn then
            if showEmptyRoot then
                showGouBtn = false
            end
            local golemLockInfo = itemdata.golemLockInfo
            local isSel = self:CheckIsSelRecastLockInfo(golemLockInfo)
            CS.ShowObject(GouTrans,isSel)
        end
        CS.ShowObject(GouBtnTrans,showGouBtn)
        CS.ShowObject(EmptyRootTrans,showEmptyRoot)
    else
        self:SetWndText(NotTipsTrans,itemdata.notTxt)
    end
    CS.ShowObject(AutoRootTrans,showAttrInfo)
    CS.ShowObject(AttrValueTrans,showAttrInfo)

    CS.ShowObject(NotTipsTrans,not showAttrInfo)


    self:SetWndClick(GouBtnTrans,function()
        self:OnClickRecastCellGouBtnFunc(itemdata)
    end)
    self:SetWndClick(BtnTrans,function()
        self:OnClickRecastCellBtnFunc(itemdata)
    end)
end



------------------------------------------------------------------
return UISubGolemRecast