---
--- Created by By.
--- DateTime: 2023/10/29 16:38:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISelSer:LWnd
local UISelSer = LxWndClass("UISelSer", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISelSer:UISelSer()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISelSer:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISelSer:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISelSer:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self:SetPara()
    self:InitData()
    self:InitEvent()
    self:OnShowServerList()
end

function UISelSer:InitEvent()
    self:SetWndClick(self.mImgServerListBgObj, function(...)
        if self._isSwitchAccount then
            return
        end
        self:OnHideServerList()
    end)

    self:SetWndClick(self.mBtnClose, function(...)
        if self._isSwitchAccount then
            return
        end
        self:OnHideServerList()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    --切换账号的弹窗不显示关闭
    if self._isSwitchAccount then
        CS.ShowObject(self.mBtnClose, false)
    end
end

function UISelSer:OnServerItemDraw(list, item, itemdata, itempos)
    item = self:FindWndTrans(item, "AniRoot")
    local serverData = itemdata.serverData
    local playerInfo = itemdata.playerInfo
    local id = serverData.id
    self:SetWndClick(item, function(...)
        local imgSel = CS.FindTrans(item, "ImageSel")
        CS.ShowObject(imgSel, true)
        self:OnClickServerItem(serverData)
    end)

    local bSel = self._curServer and self._curServer.id == id

    local state = serverData.state
    local show = self:IsNew(serverData.openTime or 0)
    local serverName = serverData.name
    if show then
        local baseName = ccClientText(1003)
        if state then
            -- 检查服务器列表里的状态是否是1  1：良好，2：维护，3：秘籍
            if state == 1 or state == 2 then
                --良好 还需要根据服务器的状态 拥挤 爆满 顺畅 显示
                local serState = gLGameLogin:GetServerStateById(id)
                if serState and serState == 3 then
                    local img, name = self:GetServerItemStatusImgAndName(serState)
                    if not string.isempty(name) then
                        baseName = string.replace("[#a1#]",name)
                    end
                end
            end
        end
        serverName = baseName .. serverName
    end

    if bSel then
        local text = CS.FindTrans(item, "XUISelText")
        CS.ShowObject(text, true)
        self:SetWndText(text,serverName)
        text = CS.FindTrans(item, "XUIText")
        CS.ShowObject(text, false)
    else
        local text = CS.FindTrans(item, "XUIText")
        CS.ShowObject(text, true)
        self:SetWndText(text,serverName)
        text = CS.FindTrans(item, "XUISelText")
        CS.ShowObject(text, false)
    end

    local statusImgTrans = CS.FindTrans(item, "statusImg")
    if statusImgTrans then
        self:SetStateInfo(state, id, statusImgTrans)
    end

    local recommendImgTrans = CS.FindTrans(item, "recommendImg")
    if recommendImgTrans then
        local setDefault = serverData.setDefault == 1
        CS.ShowObject(recommendImgTrans, setDefault)
    end

    local imgSel = CS.FindTrans(item, "ImageSel")
    CS.ShowObject(imgSel, bSel)

    local img = CS.FindTrans(item, "Image")
    --CS.ShowObject(img,not bSel)

    --local newImgTrans = CS.FindTrans(item,"NewImg")
    --if newImgTrans then
    --	local show = self:IsNew(serverData.openTime or 0)
    --CS.ShowObject(newImgTrans,show)
    --end

    local headIconTrans = CS.FindTrans(item, "HeadIcon")
    if headIconTrans then
        if table.isempty(playerInfo) then
            CS.ShowObject(headIconTrans, false)
        else
            CS.ShowObject(headIconTrans, true)
            local baseClass = HeadIcon:New(self)
            playerInfo.trans = headIconTrans
            baseClass:SetHeadData(playerInfo)
        end
    end
    if self._isEnus then
        if playerInfo then
            local levelTran = CS.FindTrans(item, "HeadIcon/lvBg/level")
            local levelTran_enus = CS.FindTrans(item, "HeadIcon/lvBg/level_enus")
            CS.ShowObject(levelTran, false)
            self:SetWndText(levelTran_enus, playerInfo.level)
        end
    end

end

function UISelSer:SetPara()
    self._curServer = self:GetWndArg("curServer")
    self._selCallFunc = self:GetWndArg("callFunc")
    self._hideFunc = self:GetWndArg("hideFunc")
    self._isServerDataFromDefault = self:GetWndArg("default")
    self._isSwitchAccount = self:GetWndArg("isSwitchAccount")
    self._bSelMaxPlayerLv = self:GetWndArg("bSelMaxPlayerLv")
end

function UISelSer:OnGroupItemDraw(list, item, itemdata, itempos)
    self:SetWndClick(item, function(...)
        self:OnClickGroupItem(itemdata, itempos)
    end)

    self:OnDrawGroupItemCom(item, itemdata)

end

function UISelSer:OnGroupSpecialItemDraw(list, item, itemdata, itempos)
    self:SetWndClick(item, function(...)
        self:OnClickSpecialGroupItem(itemdata, itempos)
    end)

    self:OnDrawGroupItemCom(item, itemdata)

end

function UISelSer:CheckDefaultSelectMyServerGroupId()
    if not gLGameLanguage:IsJapanRegion() then
        return false
    end

    local playerInfoList = gLGameLogin:GetPlayerInfoList() or {}
    local playerServerList = gLGameLogin:GetMyPlayerServerList() or {}
    local isNewPlayer = table.isempty(playerInfoList) and table.isempty(playerServerList)
    return not isNewPlayer
end

-----------------------------------------------------------------
---选服列表
function UISelSer:OnShowServerList()
    local defaultServerList = gLGameLogin:GetDefaultServerList() or {}

    local groupList = gLGameLogin:GetGroupList() or {}

    local selGroupId = self._selGroupId

    local specialTypeMap = {}

    local specialDataList = {}
    local recommendGroupId = -199999
    local serverTypeData = {
        gsGroupId = recommendGroupId,
        gsGroupName = ccClientText(1000),
        isRecommend = true,
        serverList = defaultServerList,
        gsGroupDesc = -2
    }
    table.insert(specialDataList, serverTypeData)
    specialTypeMap[serverTypeData.gsGroupId] = serverTypeData
    local myServerGroupId = -199998
    serverTypeData = {
        gsGroupId = myServerGroupId,
        gsGroupName = ccClientText(1001),
        isMyPlayerServer = true,
        serverList = gLGameLogin:GetMyPlayerServerList(),
        gsGroupDesc = -1
    }

    table.insert(specialDataList, serverTypeData)
    specialTypeMap[serverTypeData.gsGroupId] = serverTypeData

    self._specialTypeMap = specialTypeMap

    local isRecommend = false
    if recommendGroupId == selGroupId then
        isRecommend = true
    end

    local groupListData = {}
    local groupDataMap = {}
    self._groupDataMap = groupDataMap
    local isNormal = nil
    local isExclusiveMode = gLGameLogin:IsExclusiveMode()
    for k, v in ipairs(groupList) do
        local serverList = nil
        if isExclusiveMode then
            serverList = v.serverList
        end
        local groupData = { gsGroupId = v.gsGroupId, gsGroupName = v.gsGroupName, serverList = serverList, gsGroupDesc = v.gsGroupDesc }
        groupDataMap[v.gsGroupId] = groupData
        table.insert(groupListData, groupData)
        if selGroupId == v.gsGroupId then
            isNormal = k
        end
    end

    if not isRecommend and not isNormal then
        if self._curServer then
            if self:CheckDefaultSelectMyServerGroupId() then
                self._selGroupId = myServerGroupId
            else
                self._selGroupId = self._curServer.gsGroupId
            end
            if self._bSelMaxPlayerLv then
                self._selGroupId = myServerGroupId
            else
                --第一次打开服务器了列表选择，默认推荐的服务器选的服 打开默认推荐
                if self._isServerDataFromDefault then
                    self._selGroupId = recommendGroupId
                    isRecommend = true
                end
            end
        else
            if #defaultServerList <= 0 and #groupList > 0 then
                self._selGroupId = groupList[1].gsGroupId
                isNormal = true
            else
                self._selGroupId = recommendGroupId
                isRecommend = true
            end
        end

    end
    self._isServerDataFromDefault = nil

    local uiList = self._uiServerList
    if (not uiList) then
        uiList = self:GetUIScroll("_uiServerList")
        uiList:Create(self.mServerScroll, {}, function(...)
            self:OnServerItemDraw(...)
        end, UIItemList.SUPER_GRID)
        uiList:EnableScroll(true, false)
        self._uiServerList = uiList
    end

    local uiGroupList = self._uiGroupList
    if (not uiGroupList) then
        uiGroupList = self:GetUIScroll("_uiGroupList")
        uiGroupList:Create(self.mGroupScroll, {}, function(...)
            self:OnGroupItemDraw(...)
        end, UIItemList.SUPER_GRID)
        uiGroupList:EnableScroll(true, false)
        self._uiGroupList = uiGroupList
    end
    uiGroupList:RefreshList(groupListData)
    uiGroupList:DrawAllItems(false)

    local specialUIList = self._uiSpecialTypList
    if not specialUIList then
        specialUIList = self:GetUIScroll("specialTypeList")
        specialUIList:Create(self.mSpecialScroll, { }, function(...)
            self:OnGroupSpecialItemDraw(...)
        end, UIItemList.SUPER_GRID)
        specialUIList:EnableScroll(false, false)
        self._uiSpecialTypList = specialUIList
    end
    specialUIList:RefreshList(specialDataList)
    specialUIList:DrawAllItems(false)

    self:UpdateSelGroupServerList()
end

function UISelSer:TryQueryServerGroupServerList(gId)
    LServerUtil.QueryServerGroupShortFromWeb(function(bOk, ret, result, url)
        if self:IsWndClosed() then
            return
        end
        if not bOk then
            return
        end
        local groupData = self._groupDataMap[gId]
        if groupData then
            local retServer = {}
            for k, v in ipairs(result) do
                if gLGameLogin:IsServerValidShow(v) then
                    table.insert(retServer, v)
                end
            end
            groupData.serverList = retServer
            table.sort(retServer, function(sA, sB)
                return sA.orders > sB.orders
            end)
            if self._selGroupId == gId then
                self:UpdateSelGroupServerList()
            end
        end
    end, gId)
end

function UISelSer:SetStateInfo(sState, serverId, trans, stateNameTrans)
    local img, name
    local statesTrans = trans            -- 状态节点

    -- 检查服务器列表里的状态是否是1  1：良好，2：维护，3：秘籍
    if sState ~= 1 then
        img, name = self:GetStateIcon(sState)
    else
        --良好 还需要根据服务器的状态 拥挤 爆满 顺畅 显示
        local serState = gLGameLogin:GetServerStateById(serverId)
        img, name = self:GetServerItemStatusImgAndName(serState)
    end
    self:SetWndEasyImage(statesTrans, img)

    if (stateNameTrans) then
        self:SetXUITextText(stateNameTrans, name)
        self:InitTextSizeWithLanguage(stateNameTrans, -4)
    end
end

function UISelSer:GetStateIcon(state)
    local icon, name
    if state == 2 then
        icon = "login_ui_4"
        name = ccClientText(121)
    else
        icon = "login_ui_3"
        name = ccClientText(122)
    end
    return icon, name
end

function UISelSer:GetServerItemStatusImgAndName(state)
    local icon, name
    local ref = GameTable.GameServerStateRef[state]
    if ref then
        icon = ref.icon
        name = ccLngText(ref.name)
    end
    return icon, name
end

function UISelSer:InitData()
    self._recommendIcon = GameTable.GameServerConfigRef["recommendIcon"]            -- 推荐服图标
    self._newIcon = GameTable.GameServerConfigRef["newIcon"]                        -- 新服图标
    self._newValue = GameTable.GameServerConfigRef["newValue"]                        -- 新服图标


    self:SetXUITextText(self.mLblBiaoti, ccClientText(109))

    self:InitTextSizeAndLineAndStr(self.mShunchangTxt, ccClientText(116))
    self:InitTextSizeAndLineAndStr(self.mYongjiTxt, ccClientText(117))
    self:InitTextSizeAndLineAndStr(self.mBaomanTxt, ccClientText(118))
    self:InitTextSizeAndLineAndStr(self.mWeihuTxt, ccClientText(119))

    self._groupDataMap = {}

    self:InitEmptyList()
end

function UISelSer:IsNew(openTime)
    openTime = openTime / 1000
    --港澳台直接用实际流逝时间判断
    if LGameSettings.platformRegion == LRegionConst.HMT then
        local nowTime = (tonumber(os.time()) or 0)
        local overTime = openTime + self._newValue * 86400
        if nowTime <= overTime then
            return true
        else
            return false
        end
    end
    local openTab = LUtil.OSDate("*t", openTime)
    local overTime = LUtil.OSTime({ hour = 0, day = openTab.day + self._newValue, month = openTab.month, year = openTab.year })
    if tonumber(os.time()) <= tonumber(overTime) then
        return true
    else
        return false
    end
end

function UISelSer:OnDrawGroupItemCom(item, itemdata)
    local aniRoot = CS.FindTrans(item, "AniRoot")
    local btnTrans = CS.FindTrans(aniRoot, "Btn")
    self:SetWndButtonText(btnTrans, itemdata.gsGroupName)
    local bSel = itemdata.gsGroupId == self._selGroupId
    self:SetWndButtonGray(btnTrans, not bSel)
end

function UISelSer:InitEmptyList()
    local data = {
        refId = 1,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISelSer:OnHideServerList()
    if self._bInitCurrentServer and self._selCallFunc then
        self._selCallFunc(self._curServer)
    end

    local func = self._hideFunc
    if func then
        func()
    end

    if self:IsWndClosed() then
        return
    end
    self:WndClose()
end

function UISelSer:OnClickGroupItem(itemdata, index)
    local oldGroupId = self._selGroupId
    local nowGroupId = itemdata.gsGroupId

    if oldGroupId == nowGroupId then
        return
    end

    self._selGroupId = nowGroupId

    self._uiGroupList:DrawAllItems(false)
    self._uiSpecialTypList:DrawAllItems(false)

    self:UpdateSelGroupServerList()
end

function UISelSer:OnClickServerItem(itemData)
    self._curServer = itemData
    local func = self._selCallFunc
    if func then
        func(itemData)
    end
end

function UISelSer:UpdateSelGroupServerList()
    if CS.IsNullObject(self.mServerListObj) or not self.mServerListObj.activeSelf then
        return
    end
    local uiList = self._uiServerList

    local serverDataList = {}

    local bWaitQueryServerList = false
    local selGroupId = self._selGroupId
    local nowServerId = nil
    if self._curServer then
        nowServerId = self._curServer.id
    end
    local nowIndex = nil
    local isEmpty = true
    if selGroupId then
        local palyerInfoList = gLGameLogin:GetPlayerInfoList() or {}
        local gpData = self._specialTypeMap[selGroupId]
        if not gpData then
            gpData = self._groupDataMap[selGroupId]
        end

        local serverList = gpData and gpData.serverList
        if not serverList then
            bWaitQueryServerList = true
        else
            if not self._curServer and #serverList > 0 then
                self._curServer = serverList[#serverList]
                self._bInitCurrentServer = true
            end
            isEmpty = #serverList <= 0
            for k, v in ipairs(serverList) do
                local mergeSvr = tonumber(v.mergeToSvr) or 0
                local fid = v.id
                local data = {
                    serverData = v,
                    playerInfo = palyerInfoList[fid] or palyerInfoList[mergeSvr],
                }
                if nowServerId and nowServerId == fid then
                    nowIndex = k
                end
                table.insert(serverDataList, data)
            end
        end
    end

    uiList:RefreshList(serverDataList)
    uiList:DrawAllItems()

    if bWaitQueryServerList then
        self:TryQueryServerGroupServerList(selGroupId)
    end

    CS.ShowObject(self.mNoRecord2, isEmpty)
end

function UISelSer:OnClickSpecialGroupItem(itemdata)
    local oldGroupId = self._selGroupId
    local nowGroupId = itemdata.gsGroupId

    if oldGroupId == nowGroupId then
        return
    end
    self._selGroupId = nowGroupId

    self._uiGroupList:DrawAllItems(false)
    self._uiSpecialTypList:DrawAllItems(false)

    self:UpdateSelGroupServerList()
end

function UISelSer:InitTextSizeAndLineAndStr(textTrans, str)
    if not (CS.IsValidObject(textTrans) and str) then
        return
    end

    self:SetXUITextText(textTrans, str)
    self:InitTextLineWithLanguage(textTrans, -30)
    self:InitTextSizeWithLanguage(textTrans, -2)
end

------------------------------------------------------------------
return UISelSer


