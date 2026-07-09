---
--- Created by LCM.
--- DateTime: 2022/10/25 17:16:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemWarehouse:LWnd
local UIGolemWarehouse = LxWndClass("UIGolemWarehouse", LWnd)

---- 类型备注
--- 主界面跳转的显示装备按钮，强化按钮没备注，暂不处理
UIGolemWarehouse.TYPE_MAIN_OPEN = 1                --- 魔偶主界面跳转显示
UIGolemWarehouse.TYPE_INTENSIFY = 2                --- 魔偶强化界面切换
UIGolemWarehouse.TYPE_ONLY_WEAR = 3                --- 仅用于穿戴
UIGolemWarehouse.TYPE_RECAST = 4                   --- 魔偶重铸界面切换

--- 窗口类型显示装备按钮
UIGolemWarehouse.SHOW_FITOUTBTN_TYPE = {
    [ModelGolem.TYPE_OPT_WEAR] = true,
}

UIGolemWarehouse.SUITDESC_USE_LIST = 1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemWarehouse:UIGolemWarehouse()
    self._showDivType = nil
    self._selAttrInfoMap = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemWarehouse:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemWarehouse:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemWarehouse:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitEmptyList()

    self._showDivListTransList = {}

    self._showDivNameTransList = {}

    self._showSelDivInfoList = {
        --- 配置数据，可选择的数据
        config = {
            [ModelGolem.GOLEM_DIV_SORT] = ModelGolem.GOLEM_DIV_SORT_NUM,
            [ModelGolem.GOLEM_DIV_ATTR] = {
                [ModelGolem.GOLEM_DIV_ATTR_PRIME] = ModelGolem.GOLEM_DIV_ATTR_PRIME_NUM,
                [ModelGolem.GOLEM_DIV_ATTR_DEPUTY] = ModelGolem.GOLEM_DIV_ATTR_DEPUTY_NUM,
            },
            [ModelGolem.GOLEM_DIV_STATUS] = ModelGolem.GOLEM_DIV_STATUS_NUM,
        },
        --- 玩家选择的数据
        selInfo = {
            [ModelGolem.GOLEM_DIV_SORT] = {
                selNum = 0,
                keyMap = {},
            },
            [ModelGolem.GOLEM_DIV_ATTR] = {
                [ModelGolem.GOLEM_DIV_ATTR_PRIME] = {
                    selNum = 0,
                    keyMap = {},
                },
                [ModelGolem.GOLEM_DIV_ATTR_DEPUTY] = {
                    selNum = 0,
                    keyMap = {},
                },
            },
            [ModelGolem.GOLEM_DIV_STATUS] = {
                selNum = 0,
                keyMap = {},
            },

        },
    }

    self:InitSortSelGolemDiv()
    self:InitAttrSelGolemDiv()
    self:InitStatusSelGolemDiv()

    CS.ShowObject(self.mIntensifyBtn,true)

    self:InitEvent()
    self:InitMsg()
    self:InitData()

    self:InitText()
    self:RefreshGolemShow()
    self:InitShowGolemList()
end

function UIGolemWarehouse:InitShowGolemList(refreshData)
    local list = self:GetShowGolemList()
    local isEmpty = #list < 1
    local needJump = false
    if not self._golemId and not isEmpty then
        local curSelGolemId = self._curSelGolemId
        if curSelGolemId then
            self._golemId = curSelGolemId
            needJump = true
        else
            self._golemId = gModelGolem:GetGolemIdByGolemInfo(list[1])
        end
        self:RefreshFitOutBtnTxt(true)
        self:RefreshGolemShow()
    else
        if not refreshData then
            needJump = true
        end
    end
    local uiShowGolemList = self._uiShowGolemList
    if uiShowGolemList then
        if refreshData then
            uiShowGolemList:RefreshData(list)
        else
            uiShowGolemList:RefreshList(list)
        end
    else
        uiShowGolemList = self:GetUIScroll("uiShowGolemList")
        self._uiShowGolemList = uiShowGolemList
        uiShowGolemList:Create(self.mShowGolemList,list,function(...) self:OnDrawShowGolemCell(...) end,UIItemList.WRAP)
    end

    if needJump then
        local index
        for i,v in ipairs(list) do
            if gModelGolem:GetGolemIdByGolemInfo(v) == self._golemId then
                index = i
                break
            end
        end
        if index then
            local uiList = uiShowGolemList:GetList()
            uiList:RefreshList(UIListWrap.RefreshMode.Custom,index)
        end
    end

    CS.ShowObject(self.mNoShowGolemEmpty,isEmpty)
end

function UIGolemWarehouse:OnClickAttrEnterBtnFunc()
    local selAttrInfoMap = self._selAttrInfoMap
    --self._showSelDivInfoList = {}
    local showSelDivInfoList = self._showSelDivInfoList
    local selInfo = showSelDivInfoList.selInfo
    local arrSelInfo = selInfo[ModelGolem.GOLEM_DIV_ATTR]
    local selAttrType
    local selAttrTypeNumList = {}
    for i, v in pairs(selAttrInfoMap) do
        selAttrType = i
        selAttrTypeNumList[selAttrType] = 0
        for j, k in pairs(v) do
            if k.status then
                arrSelInfo[i].keyMap[j] = j

                local selAttrTypeNum = selAttrTypeNumList[selAttrType] or 0
                selAttrTypeNumList[selAttrType] = selAttrTypeNum + 1
            else
                arrSelInfo[i].keyMap[j] = nil
            end
        end
    end
    for tSelAttrType,tSelAttrNum in pairs(selAttrTypeNumList) do
        arrSelInfo[tSelAttrType].selNum = tSelAttrNum
    end
    --self:ClearSuitSort()
    self._showSelDivInfoList = showSelDivInfoList
    self:OnClickClickMaskFunc()
end

function UIGolemWarehouse:RefreshGolemShow()
    local golemId = self._golemId
    local isSel = golemId ~= nil

    CS.ShowObject(self.mGolemRoot,isSel)
    CS.ShowObject(self.mGolemInfo,isSel)
    CS.ShowObject(self.mNoSelGolemEmpty,not isSel)

    if not golemId then
        return
    end

    local serverData = self:GetGolemServerData()
    local golemName = gModelGolem:GetGolemElementNameByGolemInfo(serverData)
    self:SetWndText(self.mGolemName,golemName)

    self:RefreshGolemRoot()
    self:RefreshGolemDesc()
    self:InitGolemAttrList()
end

function UIGolemWarehouse:InitAttrSelGolemDiv()
    local showDivType = ModelGolem.GOLEM_DIV_ATTR
    local trans = self.mAttrSelGolemDiv
    local transInfo = self:GetSelGolemDivInfo(trans,showDivType,ccClientText(33250))
    self:SetWndClick(transInfo.DivBgTrans,function()
        self:OnClickAttrSelGolemDivFunc(transInfo,showDivType)
    end)
end

function UIGolemWarehouse:OnGolemWearFunc()
    --- 空位置直接装备
    --- 已有锁定状态先解锁
    local serverData = self:GetGolemServerData()
    if not serverData then return end
    local isLock = gModelGolem:GetGolemIsLockByGolemInfo(serverData)
    if isLock then
        gModelGolem:ChangeGolemLockStatusByGolemInfo(serverData)
    else
        if self._heroId and self._golemId then
            if self._curSelGolemId == self._golemId then return end

            local wearStatus = self:GetWndArg("wearStatus")
            local isReplace = wearStatus ~= nil and self._curSelGolemId ~= nil
            if not wearStatus then
                wearStatus = ModelGolem.OPSTYPE_TYPE_WEAR
            end

            local isWear = wearStatus == ModelGolem.OPSTYPE_TYPE_WEAR

            local sendFunc = function()
                if not self:IsWndValid() then return end
                gModelGolem:OnGolemWearReq(wearStatus,self._heroId,{self._golemId})
            end
            if isReplace then
                local isInBag = gModelGolem:CheckGolemIsNotWearByGolemInfo(serverData)
                if not isInBag then
                    local heroId = serverData.heroId
                    if heroId ~= self._heroId then
                        local wearHeroNamne = gModelHero:GetHeroNameById(heroId)
                        local wearGolemName = gModelGolem:GetGolemElementNameByGolemInfo(serverData)
                        local curHeroName = gModelHero:GetHeroNameById(self._heroId)
                        local curSelGolemServerData = gModelGolem:GetGolemServerDataById(self._curSelGolemId)
                        local selGolemName = gModelGolem:GetGolemElementNameByGolemInfo(curSelGolemServerData)
                        gModelGeneral:OpenUIOrdinTips({refId = 310003,para = {wearHeroNamne,wearGolemName,curHeroName,selGolemName},func = sendFunc})
                        return
                    end
                end
            elseif isWear then
                local isInBag = gModelGolem:CheckGolemIsNotWearByGolemInfo(serverData)
                if not isInBag then
                    local heroId = serverData.heroId
                    if heroId ~= self._heroId then
                        local wearHeroNamne = gModelHero:GetHeroNameById(heroId)
                        local wearGolemName = gModelGolem:GetGolemElementNameByGolemInfo(serverData)
                        local curHeroName = gModelHero:GetHeroNameById(self._heroId)
                        gModelGeneral:OpenUIOrdinTips({refId = 310023,para = {wearHeroNamne,wearGolemName,curHeroName},func = sendFunc})
                        return
                    end
                end
            end
            sendFunc()
        end
    end
end

function UIGolemWarehouse:GetAttrSelGolemList(listKey)
    local list = {}
    local attrList = {}
    local showType = ModelGolem.GOLEM_DIV_ATTR
    local attr = gModelGolem:GetGolemConfigRefByKey("attr")
    for i,v in ipairs(attr) do
        v = tonumber(v)
        table.insert(attrList,{
            attrRefId = v,
            selAttrType = ModelGolem.GOLEM_DIV_ATTR_PRIME,
            showType = showType,
            listKey = listKey,
        })
    end
    table.insert(list,{
        selAttrType = ModelGolem.GOLEM_DIV_ATTR_PRIME,
        showType = showType,
        attrList = attrList,
        str = ccClientText(33218),
        listKey = listKey,
    })

    local attrDeputyList = {}
    local attrDeputy = gModelGolem:GetGolemConfigRefByKey("attrDeputy")
    for i,v in ipairs(attrDeputy) do
        v = tonumber(v)
        table.insert(attrDeputyList,{
            attrRefId = v,
            selAttrType = ModelGolem.GOLEM_DIV_ATTR_DEPUTY,
            showType = showType,
            listKey = listKey,
        })
    end
    table.insert(list,{
        selAttrType = ModelGolem.GOLEM_DIV_ATTR_DEPUTY,
        showType = showType,
        attrList = attrDeputyList,
        str = ccClientText(33219),
        listKey = listKey,
    })


    return list
end

------------------------- List -------------------------

function UIGolemWarehouse:OnWndRefresh()
    self:InitData()
    self:RefreshGolemShow()
    self:InitShowGolemList()
end

function UIGolemWarehouse:RefreshGolemDesc()
    local serverData = self:GetGolemServerData()
    if not serverData then return end
    local showGolemDescList = UIGolemWarehouse.SUITDESC_USE_LIST == 1
    CS.ShowObject(self.mDescType1Div,not showGolemDescList)
    CS.ShowObject(self.mDescType2Div,showGolemDescList)
    if showGolemDescList then
        self:InitGolemDescList()
    else
        local descStr = gModelGolem:GetGolemSuitDescStr(serverData)
        self:SetWndText(self.mGolemDesc1,descStr)
    end
end

------------------------- List -------------------------


function UIGolemWarehouse:GetGolemAttrList()
    local golemId = self._golemId
    if not golemId then return {} end
    local serverData = gModelGolem:GetGolemServerDataById(golemId)
    if not serverData then return {} end
    return gModelGolem:GetGolemAllAttrList(serverData)
end

function UIGolemWarehouse:InitAttrSelGolemList(listTrans,refreshData)
    local BgTrans = self:FindWndTrans(listTrans,"Bg")
    CS.ShowObject(BgTrans,true)

    local BtnDivTrans = self:FindWndTrans(listTrans,"BtnDiv")
    local BtnYellow3Trans = self:FindWndTrans(BtnDivTrans,"BtnYellow3")
    self:SetWndButtonText(BtnYellow3Trans,ccClientText(33240))
    self:SetWndClick(BtnYellow3Trans,function()
        self:OnClickAttrEnterBtnFunc()
    end)
    CS.ShowObject(BtnDivTrans,true)

    local key = listTrans:GetInstanceID()
    local list = self:GetAttrSelGolemList(key)
    self:InitSelAttrInfo(list)

    local uiList = self:FindUIScroll(key)
    if uiList then
        if refreshData then
            uiList:RefreshData(list)
        else
            uiList:RefreshList(list)
        end
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(listTrans,list,function(...) self:OnDrawAttrSelGolemCell(...) end)
    end
end

function UIGolemWarehouse:OnClickCommonDivFunc(transInfo,showType)
    local listTrans = transInfo.SelListTrans
    local btnTrans = transInfo.BtnTrans
    local _showDivType = self._showDivType
    if _showDivType and _showDivType == showType then
        CS.ShowObject(self.mClickMask,false)
        CS.ShowObject(listTrans,false)
        self._showDivType = nil
        btnTrans.localScale = Vector3.New(1,1,1)
        return false
    end
    CS.ShowObject(self.mClickMask,true)
    CS.ShowObject(listTrans,true)
    self._showDivType = showType
    self:RefreshSelGolemDivStatus()
    btnTrans.localScale = Vector3.New(1,-1,1)
    return true
end

function UIGolemWarehouse:OnClickAttrSelGolemDivFunc(transInfo,showType)
    local listTrans = transInfo.SelListTrans
    local bool = self:OnClickCommonDivFunc(transInfo,showType)
    if not bool then
        return
    end

    self:InitAttrSelGolemList(listTrans)
end

function UIGolemWarehouse:OnClickCommonStatusDivFunc(itemdata)
    local showType = itemdata.showType
    local value = itemdata.refId

    local isSel = self:CheckIsSel(showType,{
        refId = value,
    })
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
    if isSel then
        selTypeKeyInfo[value] = nil
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        selTypeInfo.selNum = selTypeNumInfo - 1
        return true
    else
        local configNum = self:GetConfigNumByShowType(showType)
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        if selTypeNumInfo < configNum then
            selTypeKeyInfo[value] = value
            selTypeInfo.selNum = selTypeNumInfo + 1
            return true
        else
            if configNum == 1 then
                --- 如果是只能选择单个的情况
                selTypeInfo.keyMap = {}
                selTypeInfo.keyMap[value] = value
                return true
            else
                --- 多选的情况不管，等策划决定
            end
        end
    end
    return false
end

function UIGolemWarehouse:InitMsg()
    self:WndNetMsgRecv(LProtoIds.GolemWearResp,function(pb) self:OnGolemWearResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemLockResp,function(pb) self:OnGolemLockResp(pb) end)
    -- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemWarehouse:OnClickClickMaskFunc()
    CS.ShowObject(self.mClickMask,false)
    self._showDivType = nil
    self:RefreshSelGolemDivStatus()

    if LOG_INFO_ENABLED then
        local info = self:GetSelInfo()
        for showType,typeInfoList in pairs(info) do
            if showType == ModelGolem.GOLEM_DIV_ATTR then
                for k,v in pairs(typeInfoList) do
                    for key,val in pairs(v.keyMap) do
                        printInfoNR("属性筛选：ModelGolem.GOLEM_DIV_ATTR = val = " .. val)
                    end
                end
            elseif showType == ModelGolem.GOLEM_DIV_SORT then
                for key,val in pairs(typeInfoList.keyMap) do
                    printInfoNR("套装筛选：ModelGolem.GOLEM_DIV_SORT = val = " .. val)
                end
            elseif showType == ModelGolem.GOLEM_DIV_STATUS then
                for key,val in pairs(typeInfoList.keyMap) do
                    printInfoNR("类型筛选：ModelGolem.GOLEM_DIV_STATUS = val = " .. val)
                end
            end
        end
    end

    ----- 逻辑处理
    self:InitShowGolemList()
end

function UIGolemWarehouse:RefreshShowGolemList()
    local uiShowGolemList = self._uiShowGolemList
    if not uiShowGolemList then return end
    local uiList = uiShowGolemList:GetList()
    uiList:RefreshList()
end

function UIGolemWarehouse:OnDrawAttrSelGolemCell(list,item,itemdata,itempos)
    local TitleTrans = self:FindWndTrans(item,"TitleDiv/Title")
    local AttrListTrans = self:FindWndTrans(item,"AttrList")
    local AttrListEnTrans = self:FindWndTrans(item,"AttrListEn")
    self:SetWndText(TitleTrans,itemdata.str)

    local isForeign = gLGameLanguage:IsForeignRegion()
    CS.ShowObject(AttrListTrans, not isForeign)
    CS.ShowObject(AttrListEnTrans,  isForeign)

    local targetAttrTrans = isForeign and AttrListEnTrans or AttrListTrans
    self:InitAttrList(targetAttrTrans,itemdata.attrList)
end

function UIGolemWarehouse:GetGolemServerData()
    local golemId = self._golemId
    if not golemId then return end
    return gModelGolem:GetGolemServerDataById(golemId)
end

function UIGolemWarehouse:GetSelInfoByShowType(showType)
    local selInfo = self:GetSelInfo()
    if not selInfo then return end
    return selInfo[showType]
end

function UIGolemWarehouse:GetKeyMap(info)
    return info.keyMap
end

function UIGolemWarehouse:GetSelInfoSelNumByShowType(showType)
    --- 属性除外 ， 属性有主副之分
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    if not selTypeInfo then return end
    return self:GetSelNum(selTypeInfo)
end

function UIGolemWarehouse:OnClickCommonBtnFunc(itemdata)
    local refreshStatus = false
    local showType = itemdata.showType
    if showType == ModelGolem.GOLEM_DIV_SORT then
        refreshStatus = self:OnClickCommonSortDivFunc(itemdata)
    elseif showType == ModelGolem.GOLEM_DIV_STATUS then
        refreshStatus = self:OnClickCommonStatusDivFunc(itemdata)
        --self:ClearSuitSort()
    end
    if refreshStatus then
        GF.ShowMessage(ccClientText(33298))
    end
    self:OnClickClickMaskFunc()
--[[    if refreshStatus then
        local key = itemdata.listKey
        local listTrans = itemdata.listTrans
        local list
        if showType == ModelGolem.GOLEM_DIV_SORT then
            list = self:GetSortSelGolemList(key,listTrans,showType)
        elseif showType == ModelGolem.GOLEM_DIV_STATUS then
            list = self:GetStatusSelGolemList(key,listTrans,showType)
        end
        if not list then return end
        self:InitCommonSelList(key,listTrans,list,true,showType)
    end]]
end
------------------------------------- 配置数据 --------------------------------------------
function UIGolemWarehouse:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(33215))

    local viewType = self._viewType
    if viewType == UIGolemWarehouse.TYPE_RECAST then
        self:SetWndButtonText(self.mIntensifyBtn,ccClientText(34830))
    else
        self:SetWndButtonText(self.mIntensifyBtn,ccClientText(33209))
    end


    local btnStr
    local wearStatus = self:GetWndArg("wearStatus")
    if wearStatus == ModelGolem.OPSTYPE_TYPE_REPLACE then
        btnStr = ccClientText(34805)
    else
        btnStr = ccClientText(33217)
    end
    self:SetWndButtonText(self.mFitOutBtn,btnStr)
end

function UIGolemWarehouse:OnIntensifyFunc()
    local list = self:GetShowGolemList()
    if #list <= 0 then
        gModelGeneral:OpenUIOrdinTips({refId = 310008,func = function()
            gModelGolem:JumpDreamKillWnd(self:GetWndName())
        end})
        return
    end
    local serverData = self:GetGolemServerData()
    if not serverData then return end
    --- 等级已满飘字，当前魔偶满级无需再次强化
    if gModelGolem:CheckGolemIsMaxLevelByGolemInfo(serverData) then
        GF.ShowMessage(ccClientText(33262))
        return
    end
    --- 打开强化界面
    gModelGolem:OpenGolemIntensify({
        golemInfo = serverData,
        golemId = gModelGolem:GetGolemIdByGolemInfo(serverData),
        heroServerData = self._heroServerData,
        viewType = 2,
        intensifyType = 1,
    })
    self:WndClose()
end

function UIGolemWarehouse:InitGolemDescList()
    local list = self:GetGolemDescList()
    local uiGolemDescList = self._uiGolemDescList
    if uiGolemDescList then
        uiGolemDescList:RefreshList(list)
    else
        uiGolemDescList = self:GetUIScroll("uiGolemDescList")
        self._uiGolemDescList = uiGolemDescList
        uiGolemDescList:Create(self.mGolemDescList,list,function(...) self:OnDrawGolemDescCell(...) end,UIItemList.WRAP)
    end
end

function UIGolemWarehouse:RefreshSelGolemDivStatus()
    local showDivListTransList = self._showDivListTransList
    if not showDivListTransList then return end
    local showDivType = self._showDivType
    local show
    for showType,showDivListTrans in pairs(showDivListTransList) do
        show = showType == showDivType or false
        CS.ShowObject(showDivListTrans,show)
    end
    local info = self:GetSelInfo()
    local showDivNameTransList = self._showDivNameTransList
    for showType,divNameTransInfo in pairs(showDivNameTransList) do
        if showType == ModelGolem.GOLEM_DIV_ATTR then
            self:SetWndText(divNameTransInfo.nameTrans,divNameTransInfo.initTxt)
        else
            local selInfo = info[showType]
            local selNum = selInfo.selNum
            if selNum > 0 then
                local keyMap = selInfo.keyMap
                if showType == ModelGolem.GOLEM_DIV_SORT then
                    local suitTypeSort = gModelGolem:GetWarehouseSuitTypeStatus()
                    for k,v in pairs(keyMap) do
                        local name
                        if suitTypeSort == 0 then
                            name = gModelGolem:GetGolemSuitTypeNameByType(k)
                        elseif suitTypeSort == 1 then
                            name = gModelGolem:GetGolemSuitNameByRefId(k)
                        end
                        self:SetWndText(divNameTransInfo.nameTrans,name)
                    end
                elseif showType == ModelGolem.GOLEM_DIV_STATUS then
                    for k,v in pairs(keyMap) do
                        if k == ModelGolem.GOLEM_SORT_LVL then
                            self:SetWndText(divNameTransInfo.nameTrans,ccClientText(33211))
                        elseif k == ModelGolem.GOLEM_SORT_GETTIME then
                            self:SetWndText(divNameTransInfo.nameTrans,ccClientText(33212))
                        elseif k == ModelGolem.GOLEM_SORT_ATTRTYPE then
                            self:SetWndText(divNameTransInfo.nameTrans,ccClientText(33213))
                        end
                    end
                end
            else
                self:SetWndText(divNameTransInfo.nameTrans,divNameTransInfo.initTxt)
            end
        end
    end
end

function UIGolemWarehouse:CheckAttrSelStatus(selAttrType,attrRefId)
    local selAttrInfoMap = self._selAttrInfoMap
    if not selAttrInfoMap then return false end
    local selInfo = selAttrInfoMap[selAttrType]
    if not selInfo then return false end
    local selAttrInfo = selInfo[attrRefId]
    if not selAttrInfo then
        return false
    else
        return selAttrInfo.status or false
    end
end

function UIGolemWarehouse:GetConfigNumByShowType(showType)
    local config = self:GetConfig()
    if not config then return end
    return config[showType]
end

function UIGolemWarehouse:GetSelInfoKeyMapByShowType(showType)
    --- 属性除外 ， 属性有主副之分
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    if not selTypeInfo then return end
    return self:GetKeyMap(selTypeInfo)
end

function UIGolemWarehouse:OnClickIntensifyBtnFunc()
    local optType = self._optType
    if optType == ModelGolem.TYPE_OPT_RECAST then
        self:OnRecastFunc()
    else
        self:OnIntensifyFunc()
    end
end

function UIGolemWarehouse:CheckGolemIsSel(golem)
    local id = gModelGolem:GetGolemIdByGolemInfo(golem)
    return self._golemId == id
end

function UIGolemWarehouse:GetGolemDescList()
    local serverData = self:GetGolemServerData()
    return gModelGolem:GetGolemDescStrList(serverData)
end

function UIGolemWarehouse:InitSortSelGolemDiv()
    local showDivType = ModelGolem.GOLEM_DIV_SORT
    local trans = self.mSortSelGolemDiv
    local transInfo = self:GetSelGolemDivInfo(trans,showDivType,ccClientText(33249))
    self:SetWndClick(transInfo.DivBgTrans,function()
        self:OnClickSortSelGolemDivFunc(transInfo,showDivType)
    end)
end

function UIGolemWarehouse:OnClickAttrBtnFunc(itemdata)
    local showType = itemdata.showType
    local attrRefId = itemdata.attrRefId
    local selAttrType = itemdata.selAttrType

--[[    local isSel = self:CheckIsSel(itemdata.showType,{
        selAttrType = selAttrType,
        refId = attrRefId,
    })]]

--[[    local status = false
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    if isSel then
        local selTypeKeyTypeInfo = selTypeInfo[selAttrType]
        if not selTypeKeyTypeInfo then return false end

        local keyMap = self:GetKeyMap(selTypeKeyTypeInfo)
        keyMap[attrRefId] = nil

        local selAttrTypeInfo = selTypeInfo[selAttrType]
        selAttrTypeInfo.selNum = selAttrTypeInfo.selNum - 1

        status = true
    else
        local configAttrTypeInfo = self:GetConfigNumByShowType(showType)
        local configNum = configAttrTypeInfo[selAttrType]
        local selAttrTypeInfo = selTypeInfo[selAttrType]
        local curSelNum = selAttrTypeInfo.selNum
        if curSelNum < configNum then
            local selTypeKeyTypeInfo = selTypeInfo[selAttrType]
            local keyMap = self:GetKeyMap(selTypeKeyTypeInfo)
            keyMap[attrRefId] = attrRefId
            selAttrTypeInfo.selNum = curSelNum + 1
            status = true
        else
            if selAttrType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
                if configNum == 1 then
                    local selTypeKeyTypeInfo = selTypeInfo[selAttrType]
                    --- 如果是只能选择单个的情况
                    selTypeKeyTypeInfo.keyMap = {}
                    selTypeKeyTypeInfo.keyMap[attrRefId] = attrRefId
                    status = true
                else
                    --- 多选的情况不管，等策划决定
                end
            end
        end
    end
    if not status then return end]]

    local status = false
    local selAttrInfoMap = self._selAttrInfoMap
    --if not selAttrInfoMap then
    --    selAttrInfoMap = {}
    --    self._selAttrInfoMap = selAttrInfoMap
    --end
    local selAttrInfoNumMap = self._selAttrInfoNumMap
    local selNum = selAttrInfoNumMap[selAttrType] or 0
    local isSel = self:CheckAttrSelStatus(selAttrType,attrRefId)
    if isSel then
        local selAttrTypeInfo = selAttrInfoMap[selAttrType]
        if selAttrTypeInfo[attrRefId] then
            selAttrTypeInfo[attrRefId].status = false
            selAttrInfoNumMap[selAttrType] = selNum - 1
            status = true
        end
    else
        local configAttrTypeInfo = self:GetConfigNumByShowType(showType)
        local configNum = configAttrTypeInfo[selAttrType]
        local selAttrTypeInfo = selAttrInfoMap[selAttrType]
        if not selAttrTypeInfo then
            selAttrTypeInfo = {}
            selAttrInfoMap[selAttrType] = selAttrTypeInfo
        end
        if selNum < configNum then
            selAttrInfoNumMap[selAttrType] = selNum + 1
            selAttrTypeInfo[attrRefId] = {
                status = true,
                showType = showType,
            }
            status = true
        else
            if selAttrType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
                if configNum == 1 then
                    for k,v in pairs(selAttrTypeInfo) do
                        v.status = false
                    end
                    selAttrTypeInfo[attrRefId] = {
                        status = true,
                        showType = showType,
                    }
                    status = true
                else
                    --- 多选的情况不管，等策划决定
                end
            elseif selAttrType == ModelGolem.GOLEM_DIV_ATTR_DEPUTY then
                GF.ShowMessage(ccClientText(33299))
            end
        end
    end
    if not status then return end
    local listKey = itemdata.listKey
    local uiAttrList = self:FindUIScroll(listKey)
    if not uiAttrList then return end
    self._selAttrInfoMap = selAttrInfoMap
    local uiList = uiAttrList:GetList()
    uiList:RefreshList()
end

function UIGolemWarehouse:OnGolemWearResp(pb)
    local optType = self._optType
    if optType ~= ModelGolem.TYPE_OPT_WEAR then return end
    if pb.heroId == self._heroId then
        self:WndClose()
    end
end

function UIGolemWarehouse:OnDrawGolemAttrCell(list,item,itemdata,itempos)
    local BgTrans = self:FindWndTrans(item,"Bg")
    local ZSXBgTrans = self:FindWndTrans(item,"ZSXBg")
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local AttrValueTrans = self:FindWndTrans(item,"AttrValue")

    local showZSXBg = false
    local showType = itemdata.showType
    if showType and showType == ModelGolem.GOLEM_DIV_ATTR_PRIME then
        showZSXBg = true
    end
    CS.ShowObject(BgTrans,not showZSXBg)
    CS.ShowObject(ZSXBgTrans,showZSXBg)

    local attrRefId,attrType,attrNum = itemdata.attrRefId,itemdata.attrType,itemdata.attrNum
    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrNameTrans,attrName)

    local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
    self:SetWndText(AttrValueTrans,value)
end

---- 仓库列表
function UIGolemWarehouse:GetShowGolemList()
    local isReplace = false
    local optStatus = self:GetWndArg("optStatus")
    local wearStatus = self:GetWndArg("wearStatus")
    if wearStatus and wearStatus == ModelGolem.OPSTYPE_TYPE_REPLACE then
        isReplace = true
    end
    local replaceShowWearGolem = gModelGolem:GetGolemConfigRefByKey("replaceShowWearGolem")
    if not replaceShowWearGolem then
        replaceShowWearGolem = 1
        if LOG_INFO_ENABLED then
            printInfoNR("GolemConfigRef 表添加 replaceShowWearGolem 字段，表示是否显示已穿戴的装备，默认是1，显示")
        end
    end
    local curSelGolemId = self._curSelGolemId
    local showWear = replaceShowWearGolem == 1
    if showWear and isReplace then
        curSelGolemId = nil
    end
    local extraData = {
        needGolemDrawing = self._golemIndex,
        optStatus = optStatus,
        curSelGolemId = curSelGolemId,
        upIndexId = self._curSelGolemId,
        needStar = self:GetWndArg("showNeedGolemStar")
    }
    return gModelGolem:GetGolemWarehouseList(self:GetSelInfo(),extraData)
end

function UIGolemWarehouse:GetSelNum(info)
    return info.selNum
end

function UIGolemWarehouse:RefreshBotBtnShow()
    local optType = self._optType
    local showFitOutBtn = UIGolemWarehouse.SHOW_FITOUTBTN_TYPE[optType] or false
    CS.ShowObject(self.mFitOutBtn,showFitOutBtn)
end

function UIGolemWarehouse:InitCommonSelList(key,trans,list,refreshData,showType,index)
    local uiList = self:FindUIScroll(key)
    if uiList then
        if refreshData then
            uiList:RefreshData(list)
        else
            uiList:RefreshList(list)
        end
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans,list,function(...) self:OnDrawCommonSelList(...) end)
        uiList:EnableScroll(#list > 8)
    end
    if index then
        local tList = uiList:GetList()
        tList:RefreshList()
        tList:DelayScrollTo(index - 1,2)
    end
end

function UIGolemWarehouse:InitStatusSelGolemDiv()
    local showDivType = ModelGolem.GOLEM_DIV_STATUS
    local trans = self.mStatusSelGolemDiv
    local transInfo = self:GetSelGolemDivInfo(trans,showDivType,ccClientText(33251))
    self:SetWndClick(transInfo.DivBgTrans,function()
        self:OnClickStatusSelGolemDivFunc(transInfo,showDivType)
    end)
end

function UIGolemWarehouse:InitEmptyList()
    local noSelGolemEmptyData = {
        refId = 29001,
        IntroTran = self.mNoSelGolemEmptyText,
        TextBgTran = self.mNoSelGolemEmptyTextBg,
        IconTran = self.mNoSelGolemEmptyIcon,
    }
    local noSelGolemEmptyList = self:GetCommonEmptyList("NoSelGolemEmpty")
    noSelGolemEmptyList:RefreshUI(noSelGolemEmptyData)


    local noShowGolemEmptyData = {
        refId = 29001,
        IntroTran = self.mNoShowGolemEmptyText,
        TextBgTran = self.mNoShowGolemEmptyTextBg,
        IconTran = self.mNoShowGolemEmptyIcon,
    }
    local noShowGolemEmptyList = self:GetCommonEmptyList("NoShowGolemEmpty")
    noShowGolemEmptyList:RefreshUI(noShowGolemEmptyData)
end

function UIGolemWarehouse:OnDrawGolemDescCell(list,item,itemdata,itempos)
    local TitleTrans = self:FindWndTrans(item,"Title")
    local DescTrans = self:FindWndTrans(item,"Desc")
    local desc = string.gsub(itemdata.desc,"#30e005","#139057")
    self:SetWndText(TitleTrans,itemdata.title)
    self:SetWndText(DescTrans,desc)
end

function UIGolemWarehouse:GetStatusSelGolemList(key,listTrans,showType)
    local list = {}
    table.insert(list,{
        showType = showType,
        refId = ModelGolem.GOLEM_SORT_LVL,
        showStr = ccClientText(33211),
        listKey = key,
        listTrans = listTrans,
    })
    table.insert(list,{
        showType = showType,
        refId = ModelGolem.GOLEM_SORT_GETTIME,
        showStr = ccClientText(33212),
        listKey = key,
        listTrans = listTrans,
    })
    table.insert(list,{
        showType = showType,
        refId = ModelGolem.GOLEM_SORT_ATTRTYPE,
        showStr = ccClientText(33213),
        listKey = key,
        listTrans = listTrans,
    })
    return list
end

------------------------------------- 配置数据 --------------------------------------------
function UIGolemWarehouse:GetConfig()
    local showSelDivInfoList = self._showSelDivInfoList
    if not showSelDivInfoList then return nil end
    return showSelDivInfoList.config
end

function UIGolemWarehouse:InitAttrList(trans,list)
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans,list,function(...) self:OnDrawAttrCell(...) end)
    end
end

function UIGolemWarehouse:OnClickShowGolemFunc(itemdata)
--[[    if gModelGolem:GetGolemIsLockByGolemInfo(itemdata) then
        gModelGolem:ChangeGolemLockStatusByGolemInfo(itemdata)
        return
    end]]
    if self:CheckGolemIsSel(itemdata) then return end
    local id = gModelGolem:GetGolemIdByGolemInfo(itemdata)
    self._golemId = id
    self:InitShowGolemList(true)
    self:RefreshGolemShow()
    self:RefreshFitOutBtnTxt()
end

function UIGolemWarehouse:RefreshFitOutBtnTxt(isInit)
    local wearStatus = self:GetWndArg("wearStatus")
    if not wearStatus then return end
    local btnStr
    if wearStatus == ModelGolem.OPSTYPE_TYPE_WEAR then
        if self._curSelGolemId then
            local serverData = self:GetGolemServerData()
            if serverData then
                local isInBag = gModelGolem:CheckGolemIsNotWearByGolemInfo(serverData)
                if isInBag then
                    btnStr = ccClientText(11301)
                else
                    btnStr = ccClientText(34805)
                end
            else
                btnStr = ccClientText(11301)
            end
        else
            btnStr = ccClientText(11301)
        end
    elseif wearStatus == ModelGolem.OPSTYPE_TYPE_REPLACE then
        btnStr = ccClientText(34805)
    end
    self:SetWndButtonText(self.mFitOutBtn,btnStr)
    self:CheckIsSelWearStatus()
end

function UIGolemWarehouse:GetSelGolemDivInfo(trans,showDivType,initTxt)
    local DivBgTrans = self:FindWndTrans(trans,"DivBg")
    local DivNameTrans = self:FindWndTrans(DivBgTrans,"DivName")
    local BtnTrans = self:FindWndTrans(DivBgTrans,"Btn")
    local SelListTrans = self:FindWndTrans(DivBgTrans,"SelList")

    local showDivListTransList = self._showDivListTransList
    if not showDivListTransList then
        showDivListTransList = {}
        self._showDivListTransList = showDivListTransList
    end
    showDivListTransList[showDivType] = SelListTrans


    local showDivNameTransList = self._showDivNameTransList
    if not showDivNameTransList then
        showDivNameTransList = {}
        self._showDivNameTransList = showDivNameTransList
    end
    showDivNameTransList[showDivType] = {
        nameTrans = DivNameTrans,
        initTxt = initTxt,
    }

    self:SetWndText(DivNameTrans,initTxt)

    return {
        DivBgTrans = DivBgTrans,
        DivNameTrans = DivNameTrans,
        BtnTrans = BtnTrans,
        SelListTrans = SelListTrans,
    }
end

function UIGolemWarehouse:OnRecastFunc()
    self:OnGolemSelFunc()
end

function UIGolemWarehouse:OnClickFitOutBtnFunc()
    local list = self:GetShowGolemList()
    if #list <= 0 then
        gModelGeneral:OpenUIOrdinTips({refId = 310008,func = function()
            gModelGolem:JumpDreamKillWnd(self:GetWndName())
        end})
        return
    end
    local optType = self._optType
    if optType == ModelGolem.TYPE_OPT_WEAR then
        self:OnGolemWearFunc()
    elseif optType == ModelGolem.TYPE_OPT_SEL then
        self:OnGolemSelFunc()
    end
end

function UIGolemWarehouse:OnDrawShowGolemCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
    local PosImgTrans = self:FindWndTrans(item,"PosImg")
    local HeroBgTrans = self:FindWndTrans(item,"HeroBg")
    local HeroIconTrans = self:FindWndTrans(HeroBgTrans,"HeroIcon")
    CS.ShowObject(HeroBgTrans,false)
    CS.ShowObject(PosImgTrans,false)

    ---- 是否选中
    local key = IconTrans:GetInstanceID()
    local baseClass = self:GetCommonIcon(key)
    local isSel = self:CheckGolemIsSel(itemdata)
    baseClass = self:CreateGolemIcon(IconTrans,itemdata,isSel,false,false,true)
    baseClass:DoApply()

    -- local displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(itemdata)
    -- if displayPos then
    --     self:SetWndEasyImage(PosImgTrans,displayPos,function()
    --         CS.ShowObject(PosImgTrans,true)
    --     end)
    -- end

    if gModelGolem:CheckGolemIsWearByGolemInfo(itemdata) then
        local heroId = itemdata.heroId
        local displayHero = gModelHero:GetHeroOutfitIconById(heroId)
        if not string.isempty(displayHero) then
            self:SetWndEasyImage(HeroIconTrans,displayHero)
            CS.ShowObject(HeroBgTrans,true)
        end
        local displayHeroBg
        local quality = gModelHero:GetHeroQualityById(heroId)
        if quality then
            local qualityRef = gModelItem:GetQualityRef(quality)
            displayHeroBg = qualityRef.iconBg
        end
        if not string.isempty(displayHeroBg) then
            self:SetWndEasyImage(HeroBgTrans,displayHeroBg)
            CS.ShowObject(HeroBgTrans,true)
        end
    end

    self:SetWndClick(IconTrans,function()
        self:OnClickShowGolemFunc(itemdata)
    end)
end

function UIGolemWarehouse:InitGolemAttrList()
    local list = self:GetGolemAttrList()

    local uiGolemAttrList = self._uiGolemAttrList

    local golemAttrListTrans = gLGameLanguage:IsForeignRegion() and self.mGolemAttrListEn or self.mGolemAttrList

    CS.ShowObject(golemAttrListTrans, true)

    if uiGolemAttrList then
        uiGolemAttrList:RefreshList(list)
    else
        uiGolemAttrList = self:GetUIScroll("uiGolemAttrList")
        self._uiGolemAttrList = uiGolemAttrList
        uiGolemAttrList:Create(golemAttrListTrans,list,function(...) self:OnDrawGolemAttrCell(...) end)
    end
    uiGolemAttrList:EnableScroll(true)
end

function UIGolemWarehouse:CreateGolemIcon(trans,serverData,isSel,showPos,showDisplay,showLock)
    if showDisplay == nil then
        showDisplay = true
    end
    showLock = showLock and true or false
    local displayHero
    local displayHeroBg
    if showDisplay and serverData and gModelGolem:CheckGolemIsWearByGolemInfo(serverData) then
        local heroId = serverData.heroId
        displayHero = gModelHero:GetHeroOutfitIconById(heroId)
        local quality = gModelHero:GetHeroQualityById(heroId)
        local qualityRef = gModelItem:GetQualityRef(quality)
        if qualityRef then
            displayHeroBg = qualityRef.iconBg
        end
    end

    local displayPos
    if showPos then
        displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(serverData)
    end

    local isShowLock = showLock and gModelGolem:GetGolemIsLockByGolemInfo(serverData) or false

    local key = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(key)
    baseClass:Create(trans)
    ------- icon 表现函数
    baseClass:SetGolemData({
        refId = gModelGolem:GetGolemRefIdByGolemInfo(serverData),
        lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(serverData),
        lvl = gModelGolem:GetGolemLvlByGolemInfo(serverData),
        showGou = isSel,
        displayPos = displayPos,
        displayHero = displayHero,
        displayHeroBg = displayHeroBg,
        showPosIcon = showPos,
        showLock = isShowLock,
    })
    return baseClass
end

function UIGolemWarehouse:OnClickStatusSelGolemDivFunc(transInfo,showType)
    local listTrans = transInfo.SelListTrans
    local bool = self:OnClickCommonDivFunc(transInfo,showType)
    if not bool then
        return
    end

    local key = listTrans:GetInstanceID()
    local list = self:GetStatusSelGolemList(key,listTrans,showType)
    self:InitCommonSelList(key,listTrans,list,nil,showType)
end

function UIGolemWarehouse:InitData()
    self._heroId = self:GetWndArg("heroId")
    self._golemId = self:GetWndArg("golemId")
    self._golemIndex = self:GetWndArg("golemIndex")
    local viewType = self:GetWndArg("viewType")
    if not self:GetGolemServerData() then
        self._golemId = nil
    end
    if not viewType then
        viewType = UIGolemWarehouse.TYPE_MAIN_OPEN
    end
    self._viewType = viewType

    self._optType = self:GetWndArg("optType")

    self._selGolemFunc = self:GetWndArg("selGolemFunc")

    local heroServerData
    if self._heroId then
        heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
    end
    self._heroServerData = heroServerData

    self._curSelGolemId = self:GetWndArg("curSelGolemId")
    self:RefreshBotBtnShow()
end

function UIGolemWarehouse:OnDrawAttrCell(list,item,itemdata,itempos)
    local NoSelBgTrans = self:FindWndTrans(item,"NoSelBg")
    local SelBgTrans = self:FindWndTrans(item,"SelBg")
    local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")

    local BtnTrans = self:FindWndTrans(item,"Btn")

    local attrRefId = itemdata.attrRefId

    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIconTrans,attrIcon)

--[[    local show = self:CheckIsSel(itemdata.showType,{
        selAttrType = itemdata.selAttrType,
        refId = attrRefId,
    })]]

    local show = self:CheckAttrSelStatus(itemdata.selAttrType,attrRefId)

    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetTextTile(NoSelBgTrans,attrName, -40, -2)
    self:SetTextTile(SelBgTrans,attrName, -40, -2)

    CS.ShowObject(NoSelBgTrans,not show)
    CS.ShowObject(SelBgTrans,show)

    self:SetWndClick(BtnTrans,function()
        self:OnClickAttrBtnFunc(itemdata)
    end)
end

function UIGolemWarehouse:OnDrawCommonSelList(list,item,itemdata,itempos)
    local NoSelTxtTrans = self:FindWndTrans(item,"NoSelTxt")
    local SelImgTrans = self:FindWndTrans(item,"SelImg")
    local SelTxtTrans = self:FindWndTrans(SelImgTrans,"SelTxt")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local TuiJianTrans = self:FindWndTrans(item,"TuiJian")

    self:SetWndText(NoSelTxtTrans,itemdata.showStr)

    local value
    local showType = itemdata.showType
    if showType == ModelGolem.GOLEM_DIV_SORT then
        value = gModelGolem:GetWarehouseSuitTypeKey(itemdata)
    elseif showType == ModelGolem.GOLEM_DIV_STATUS then
        value = itemdata.refId
    end
    local show = self:CheckIsSel(showType,{
        refId = value
    })
    if show then
        self:SetWndText(SelTxtTrans,itemdata.showStr)
    end
    CS.ShowObject(SelImgTrans,show)

    if TuiJianTrans then
        local showTuiJian = false
        if self._heroServerData and showType == ModelGolem.GOLEM_DIV_SORT then
            showTuiJian = gModelGolem:CheckSuitIdIsHeroGolemSkillByHeroServerData(itemdata.refId,self._heroServerData)
        end
        CS.ShowObject(TuiJianTrans,showTuiJian)
        self:SetTextTile(TuiJianTrans,ccClientText(26691))
    end

    self:SetWndClick(BtnTrans,function()
        self:OnClickCommonBtnFunc(itemdata)
    end)
end

function UIGolemWarehouse:ClearSuitSort()---清楚套装的排序
    local showSelDivInfoList = self._showSelDivInfoList
    local selInfo = showSelDivInfoList.selInfo
    local sortList = selInfo[ModelGolem.GOLEM_DIV_SORT]
    for i, v in pairs(sortList.keyMap) do
        sortList.keyMap[i] = nil
    end
    sortList.selNum = 0
end

function UIGolemWarehouse:CheckIsSel(showType,info)
    if showType == ModelGolem.GOLEM_DIV_SORT then
        local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
        return selTypeKeyInfo[info.refId] ~= nil or false
    elseif showType == ModelGolem.GOLEM_DIV_ATTR then
        local selAttrType = info.selAttrType
        if not selAttrType then return false end

        local selTypeInfo = self:GetSelInfoByShowType(showType)
        local selTypeKeyTypeInfo = selTypeInfo[selAttrType]
        if not selTypeKeyTypeInfo then return false end

        local keyMap = self:GetKeyMap(selTypeKeyTypeInfo)
        return keyMap[info.refId] ~= nil or false
    elseif showType == ModelGolem.GOLEM_DIV_STATUS then
        local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
        return selTypeKeyInfo[info.refId] ~= nil or false
    end
end

function UIGolemWarehouse:OnGolemLockResp(pb)
    self:InitShowGolemList(true)
end

function UIGolemWarehouse:GetSortSelGolemList(key,listTrans,showType)
    local list = {}
    local suitTypeList = gModelGolem:GetGolemSuitList()
    for i,v in ipairs(suitTypeList) do
        table.insert(list,{
            showType = showType,
            refId = v.refId,
            showStr = v.name,
            type = v.type,
            listKey = key,
            listTrans = listTrans,
        })
    end
    return list
end

function UIGolemWarehouse:GetSelInfo()
    local showSelDivInfoList = self._showSelDivInfoList
    if not showSelDivInfoList then return nil end
    return showSelDivInfoList.selInfo
end

function UIGolemWarehouse:InitSelAttrInfo(list)
    local selAttrInfoMap = self._selAttrInfoMap
    local selAttrInfoNumMap = {}
    self._selAttrInfoNumMap = selAttrInfoNumMap
    list = list or {}
    local showType = ModelGolem.GOLEM_DIV_ATTR
    local attrRefId
    local status,selAttrType
    for i,v in ipairs(list) do
        selAttrType = v.selAttrType
        local selAttrTypeInfo = selAttrInfoMap[selAttrType]
        if not selAttrTypeInfo then
            selAttrTypeInfo = {}
            selAttrInfoMap[selAttrType] = selAttrTypeInfo
        end
        local selNum = 0
        for idx,val in ipairs(v.attrList) do
            attrRefId = val.attrRefId
            status = self:CheckIsSel(showType,{
                selAttrType = selAttrType,
                refId = attrRefId,
            })
            if status then
                selNum = selNum + 1
            end
            selAttrTypeInfo[attrRefId] = {
                status = status,
                showType = showType,
                selAttrType = val.selAttrType
            }
        end
        selAttrInfoNumMap[selAttrType] = selNum
    end
end

function UIGolemWarehouse:CheckIsSelWearStatus()
    local isGray = false
    if self._curSelGolemId and self._curSelGolemId == self._golemId then
        isGray = true
    end
    self:SetWndButtonGray(self.mFitOutBtn,isGray)
end

function UIGolemWarehouse:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mIntensifyBtn,function() self:OnClickIntensifyBtnFunc() end)
    self:SetWndClick(self.mFitOutBtn,function() self:OnClickFitOutBtnFunc() end)
    self:SetWndClick(self.mClickMask,function() self:OnClickClickMaskFunc() end)
end

---- 套装类型选择器
function UIGolemWarehouse:OnClickCommonSortDivFunc(itemdata)
    local showType = itemdata.showType
    local value = gModelGolem:GetWarehouseSuitTypeKey(itemdata)

    local isSel = self:CheckIsSel(showType,{
        refId = value,
    })
    local selTypeInfo = self:GetSelInfoByShowType(showType)
    local selTypeKeyInfo = self:GetSelInfoKeyMapByShowType(showType)
    if isSel then
        selTypeKeyInfo[value] = nil
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        selTypeInfo.selNum = selTypeNumInfo - 1
        return true
    else
        local configNum = self:GetConfigNumByShowType(showType)
        local selTypeNumInfo = self:GetSelInfoSelNumByShowType(showType)
        if selTypeNumInfo < configNum then
            selTypeKeyInfo[value] = value
            selTypeInfo.selNum = selTypeNumInfo + 1
            return true
        else
            if configNum == 1 then
                --- 如果是只能选择单个的情况
                selTypeInfo.keyMap = {}
                selTypeInfo.keyMap[value] = value
                return true
            else
                --- 多选的情况不管，等策划决定
            end
        end
    end
    return false
end

function UIGolemWarehouse:OnGolemSelFunc()
    local selGolemFunc = self._selGolemFunc
    if selGolemFunc then
        selGolemFunc(self._golemId)
    end
    self._selGolemFunc = nil
    self:WndClose()
end

function UIGolemWarehouse:OnClickSortSelGolemDivFunc(transInfo,showType)
    local listTrans = transInfo.SelListTrans
    local bool = self:OnClickCommonDivFunc(transInfo,showType)
    if not bool then
        return
    end

    local key = listTrans:GetInstanceID()
    local list = self:GetSortSelGolemList(key,listTrans,showType)

    local selNum = self:GetSelInfoSelNumByShowType(showType)
    local configNum = self:GetConfigNumByShowType(showType)
    local index
    local heroServerData = self._heroServerData
    if selNum < configNum and heroServerData then
        for i,v in ipairs(list) do
            if gModelGolem:CheckSuitIdIsHeroGolemSkillByHeroServerData(v.refId,heroServerData) then
                index = i + 1
                break
            end
        end
    elseif selNum >= configNum then
        local value
        for i,v in ipairs(list) do
            value = gModelGolem:GetWarehouseSuitTypeKey(v)
            if self:CheckIsSel(showType,{ refId = value }) then
                index = i + 1
                break
            end
        end
    end
    self:InitCommonSelList(key,listTrans,list,nil,showType,index)
end

function UIGolemWarehouse:RefreshGolemRoot()
    local serverData = self:GetGolemServerData()
    if not serverData then return end
    local baseClass = self:CreateGolemIcon(self.mGolemRoot,serverData,nil,true)
    baseClass:DoApply()
end
------------------------------------------------------------------
return UIGolemWarehouse


