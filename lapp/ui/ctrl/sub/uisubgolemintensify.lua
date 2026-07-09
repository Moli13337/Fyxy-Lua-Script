---
--- Created by Administrator.
--- DateTime: 2024/12/25 14:16:19
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGolemIntensify:LChildWnd
local UISubGolemIntensify = LxWndClass("UISubGolemIntensify", LChildWnd)
UISubGolemIntensify.TYPE_HERO = 1             -- 英雄
UISubGolemIntensify.TYPE_GOLEM = 2            -- 单个魔偶

UISubGolemIntensify.STATUS_NOTSELGOLEM = -1   --- 没有选择魔偶
UISubGolemIntensify.STATUS_MATERIALS = 1      --- 正常的材料
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGolemIntensify:UISubGolemIntensify()
	self._showBarEffKey = "showBarEffKey"
    self._showBarEffStatus = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGolemIntensify:OnWndClose()
	FireEvent(EventNames.ON_GOLEM_REFRESH_WEAR)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGolemIntensify:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGolemIntensify:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitSortSelGolemDiv()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshGolemShowView()
    self:RefreshHeroGolemData()

    local closeWndFunc = self:GetWndArg("closeWndFunc")
    if closeWndFunc then closeWndFunc() end
end

function UISubGolemIntensify:RefreshByHeroIdChange(selHeroId)
    if not self:IsWndValid() then return end
    if not selHeroId then return end
    if selHeroId ~= self._heroId then
        self._golemId = nil
        self._golemServerData = nil
        --- 刷新流程
        self:InitSelIntensifyMaterials()
    end
    self._heroId = selHeroId
    self:RefreshHeroServerData()
    self:RefreshHeroGolemData()

    local params = self:GetWndArgList()
    params.heroServerData = self:GetHeroServerData()
    params.golemId = self._golemId
    params.viewType = UISubGolemIntensify.TYPE_HERO
end

function UISubGolemIntensify:GetSelIntensifyMaterials()
    return self._selIntensifyMaterials
end

------------------------------------------------------------------
function UISubGolemIntensify:RefreshShowHeroGolemRecastBtn()
--[[    local showRecastBtn = false
    local viewType = self._viewType
    local showHero = viewType == UISubGolemIntensify.TYPE_HERO
    if showHero then
        local golemServerData = self:GetSelGolemServerData()
        if golemServerData then
            local golemStars = gModelGolem:GetGolemStars()
            local golemStar = gModelGolem:GetGolemElementStarByGolemInfo(golemServerData)
            showRecastBtn = golemStar >= golemStars
        end
    end
    CS.ShowObject(self.mShowHeroGolemRecastBtnDiv,showRecastBtn)]]
end

function UISubGolemIntensify:OnDrawShowHeroWearGolemCell(list,item,itemdata,itempos)
    local SelTrans = self:FindWndTrans(item,"Sel")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local EffRootTrans = self:FindWndTrans(item,"EffRoot")
    local LvTxt = self:FindWndTrans(item,"LvTxt")

    local golemInfo = itemdata.golemInfo

    self:CreateShowGolemIcon(item,golemInfo)
    local lv = golemInfo and gModelGolem:GetGolemLvlByGolemInfo(golemInfo) or 0
    self:SetWndText(LvTxt,"+"..lv)
    local isSel = self:CheckIsSelHeroWearGolem(golemInfo)
    CS.ShowObject(SelTrans,isSel)
    CS.ShowObject(LvTxt,not not golemInfo)

    local instanceID = EffRootTrans:GetInstanceID()
    local showEff = false
    if golemInfo then
        local golemId = gModelGolem:GetGolemIdByGolemInfo(golemInfo)
        showEff = self:CheckShowEff(golemId)
        if showEff then
            self:CreateGolemIconEff(EffRootTrans,instanceID,function()
                self:SetShowEffStatus(golemId)
                CS.ShowObject(EffRootTrans,true)
            end)
        else
            local createEffIdList = self._createEffIdList
            if not createEffIdList then
                createEffIdList = {}
                self._createEffIdList = createEffIdList
            end
            showEff = createEffIdList[instanceID] or false
            --CS.ShowObject(EffRootTrans,false)
        end
    --else
        --CS.ShowObject(EffRootTrans,false)
    end
    CS.ShowObject(EffRootTrans,showEff)

    self:SetWndClick(BtnTrans,function()
        self:OnClickShowHeroWearGolemFunc(itemdata)
    end)
end

------------------------- List ------------------------

function UISubGolemIntensify:OnTcpReconnect()
    self._showBarEffStatus = false
end

function UISubGolemIntensify:InitNeedItemList(list)
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

function UISubGolemIntensify:RefreshGolemDemountBtnStatus(slotServerDataList)
    local num = 0
    for k,v in pairs(slotServerDataList) do
        num = num + 1
    end
    local showGolemWear = num < 1
    CS.ShowObject(self.mShowHeroGolemDemountBtn,not showGolemWear)
    CS.ShowObject(self.mShowHeroGolemWearBtn,showGolemWear)
end

function UISubGolemIntensify:CheckGolemMaterialsStatus()
    local list,status = self:GetGolemItemList()
    if status == UISubGolemIntensify.STATUS_NOTSELGOLEM then
        GF.ShowMessage(ccClientText(33268))
    elseif status == UISubGolemIntensify.STATUS_MATERIALS then
        if #list < 1 then
            --GF.ShowMessage(ccClientText(33270))
            self:OnClickCommonWay()
        else
            --- http://192.168.5.2:3000/issues/10877
            --- 需求详情如下：
            --- 2、魔偶强化界面
            --- --#未选中消耗道具时，点击弹出飘字提示“请选择消耗材料，才可强化魔偶哦”
            --- ---#tips：34809
            GF.ShowMessage(ccClientText(34809))
        end
    end
end

function UISubGolemIntensify:RefreshHeroGolemData()
    if self._viewType ~= UISubGolemIntensify.TYPE_HERO then return end
    if not self._heroId then return end
    gModelGolem:OnGolemSlotReq(self._heroId)
    --gModelGolem:OnGolemAttrReq(ModelGolem.GOLEMATTR_TYPE_HERO,self._heroId)
end

function UISubGolemIntensify:GetAllPayMaterialsChangeToPayList()
--[[    local selIdList
    local tempList
    local payKeyList = {}
    local payItemId,recordNum

    local recordFunc = function(tPayList)
        for i,v in ipairs(tPayList) do
            payItemId = v.itemId
            recordNum = payKeyList[payItemId] or 0
            payKeyList[payItemId] = recordNum + v.itemNum
        end
    end

    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    for useType,useTypeInfo in pairs(selIntensifyMaterials) do
        selIdList = useTypeInfo.selIdList
        if useType == ModelGolem.TYPE_MATERIAL_ITEM then
            if useTypeInfo.selNum > 0 then
                for itemId,useNum in pairs(selIdList) do
                    tempList = self:GetMaterialsChangeToPayList(useType,{itemId = itemId,useNum = useNum})
                    recordFunc(tempList)
                end
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            for golemId,golemInfo in pairs(selIdList) do
                tempList = self:GetMaterialsChangeToPayList(useType,{golemInfo = golemInfo})
                recordFunc(tempList)
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
            if useTypeInfo.selNum > 0 then
                for itemId,useInfo in pairs(selIdList) do
                    tempList = self:GetMaterialsChangeToPayList(useType,{itemId = itemId,useNum = useInfo.useNum})
                    recordFunc(tempList)
                end
            end
        end
    end
    local payList = {}
    for k,v in pairs(payKeyList) do
        table.insert(payList,{
            itemType = LItemTypeConst.TYPE_ITEM,
            itemId = k,
            itemNum = v,
        })
    end
    return payList]]

    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    return gModelGolem:GetAllPayMaterialsChangeToPayList(selIntensifyMaterials)
end

function UISubGolemIntensify:OnGolemSlotResp(pb)
    if not self._heroId then return end
    local viewType = self._viewType
    if viewType ~= UISubGolemIntensify.TYPE_HERO then return end
    if self._heroId ~= pb.heroId then return end
    self:RefreshHeroServerData()
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
                self:RefreshSelGolemServerData()
                break
            end
        end
    end
    self:RefreshShowHeroGolemView()
end
function UISubGolemIntensify:RefreshCutHeroInfo()
    self._index = 1
    self._cutHeroList = gModelHero:GetHaveHeroGolemList()
    if not self._heroId then return end
    for k,v in ipairs(self._cutHeroList) do
        if self._heroId == v.id then
            self._index = k
        end
    end
end

function UISubGolemIntensify:GetSelIntensifyMaterialsByUseType(useType)
    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    return selIntensifyMaterials[useType]
end

function UISubGolemIntensify:OnTimer(key)
    if key == self._showBarEffKey then
        self:OnShowBarEffKey()
    end
end

function UISubGolemIntensify:OnClickShowHeroGolemWayBtnFunc()
    self:OnClickCommonWay()
end

function UISubGolemIntensify:GetSelGolemServerData()
    local golemServerData = self._golemServerData
    if not golemServerData then
        self:RefreshSelGolemServerData()
        golemServerData = self._golemServerData
    end
    return golemServerData
end


function UISubGolemIntensify:CheckGolemInfoUseExpIsFull()
    local golemServerData = self:GetSelGolemServerData()
    if not golemServerData then return false end
    local curExp = gModelGolem:GetGolemExpByGolemInfo(golemServerData)
    local useExpNum = self:GetAllPayMaterialsChangeToExp()
    local maxLvInfo = gModelGolem:GetGolemLvGroupMaxInfoByGolemInfo(golemServerData)
    local newExp = curExp + useExpNum
    return newExp >= maxLvInfo.exp
end

--- 将素材转成经验
function UISubGolemIntensify:GetAllPayMaterialsChangeToExp()
--[[    local useExpNum = 0
    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    local selIdList
    for useType,useTypeInfo in pairs(selIntensifyMaterials) do
        selIdList = useTypeInfo.selIdList
        if useType == ModelGolem.TYPE_MATERIAL_ITEM then
            if useTypeInfo.selNum > 0 then
                for itemId,useNum in pairs(selIdList) do
                    useExpNum = useExpNum + self:GetMaterialsChangeToExp(useType,{itemId = itemId,useNum = useNum})
                end
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            for golemId,golemInfo in pairs(selIdList) do
                useExpNum = useExpNum + self:GetMaterialsChangeToExp(useType,{golemInfo = golemInfo})
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
            if useTypeInfo.selNum > 0 then
                for itemId,useInfo in pairs(selIdList) do
                    useExpNum = useExpNum + self:GetMaterialsChangeToExp(useType,{itemId = itemId,useNum = useInfo.useNum})
                end
            end
        end
    end
    return useExpNum]]

    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    return gModelGolem:GetAllPayMaterialsChangeToExp(selIntensifyMaterials)
end

function UISubGolemIntensify:GetSortSelGolemList()
    local list = {}
    table.insert(list,{
        selType = ModelGolem.GOLEM_SORT_GETTIME,
        name = ccClientText(33212),
    })
    table.insert(list,{
        selType = ModelGolem.GOLEM_SORT_LVL,
        name = ccClientText(33211),
    })
    table.insert(list,{
        selType = ModelGolem.GOLEM_SORT_STAR,
        name = ccClientText(33210),
    })
    table.insert(list,{
        selType = ModelGolem.GOLEM_SORT_ATTRTYPE,
        name = ccClientText(33213),
    })
    return list
end

function UISubGolemIntensify:InitHeroServerData()
    local heroServerData = self:GetWndArg("heroServerData")
    self._heroServerData = heroServerData
    self:RefreshHeroId()
end

function UISubGolemIntensify:CheckShowEff(golemId)
    local showEffGolemRefIdList = self._showEffGolemRefIdList
    if not showEffGolemRefIdList then return false end
    local status = showEffGolemRefIdList[golemId]
    return status
end

function UISubGolemIntensify:OnAutoKeyChoiceeFunc()
    local golemServerData = self:GetSelGolemServerData()
    if not golemServerData then return end

    local materialsList = self:GetGolemItemList()
    if #materialsList < 1 then
        self:OnClickCommonWay()
        return
    end

    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    local addExp = self:GetAllPayMaterialsChangeToExp()
    local selMaterialsList = gModelGolem:GetAutoKeyChoiceeItemList(golemServerData,materialsList,selIntensifyMaterials,addExp)
    for useType,useTypeInfo in pairs(selMaterialsList) do
        if useType == ModelGolem.TYPE_MATERIAL_ITEM then
            for itemId,useNum in pairs(useTypeInfo) do
                self:SetSelGolemItemInfo(useType,{
                    itemId = itemId,
                    useNum = useNum,
                })
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
            for itemId,useInfo in pairs(useTypeInfo) do
                self:SetSelGolemItemInfo(useType,{
                    itemId = itemId,
                    useNum = useInfo.useNum,
                })
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            for golemId,serverData in pairs(useTypeInfo) do
                self:SetSelGolemItemInfo(useType,serverData)
            end
        end
    end
    self:InitGolemItemList()
end

function UISubGolemIntensify:InitText()
    self:SetTextTile(self.mShowHeroGolemRecommendBtn,ccClientText(33203), -30)
    self:SetTextTile(self.mShowHeroGolemBagBtn,ccClientText(33274), -30)
    self:SetTextTile(self.mShowHeroGolemDemountBtn,ccClientText(33205), -30)
    self:SetTextTile(self.mShowHeroGolemWearBtn,ccClientText(33223), -30)
    self:SetTextTile(self.mShowHeroGolemWayBtn,ccClientText(33206), -30)
    self:SetTextTile(self.mShowHeroGolemSplitBtn,ccClientText(33207), -30)
    self:SetTextTile(self.mShowGolemBagBtn,ccClientText(33273))
    self:SetTextTile(self.mShowGolemWayBtn,ccClientText(33206))
    self:SetTextTile(self.mShowGolemSplitBtn,ccClientText(33207))
    self:SetWndText(self.mNotAttrTips,ccClientText(34808))

    self:SetWndText(self.mIntensifyDescTxt,ccClientText(33238))

    self:SetWndButtonText(self.mIntensifyBtn,ccClientText(33209))
    self:SetWndButtonText(self.mKeyChoiceeBtn,ccClientText(33208))


    self:SetTextTile(self.mShowHeroGolemRecastBtn,ccClientText(34845))
    --屏蔽按钮
    CS.ShowObject(self.mShowHeroGolemSplitBtnDiv,false)
    CS.ShowObject(self.mShowHeroGolemRecastBtnDiv,false)
    CS.ShowObject(self.mShowGolemSplitBtnDiv,false)
end

function UISubGolemIntensify:CreateBarEff(showEff,pb)
    if not showEff then
        CS.ShowObject(self.mGolemExpBarEff,showEff)
        return
    end
    self._showBarEffStatus = true
    local effBarRoot = self.mGolemExpBarEff
    local beforeGolem = gModelGolem:GetGolemInfoFormPb(pb.before)
    local afterServer = gModelGolem:GetGolemInfoFormPb(pb.after)
    self._showUpLvPopWndFunc = function()
        gModelGolem:OpenGolemUpLv({
            beforeGolem = beforeGolem,
            laterGolem = afterServer,
        })
    end

    self:CreateWndEffect(effBarRoot,"ui_fx_golem_up_01",effBarRoot:GetInstanceID(),100,nil,nil,nil ,nil,
    nil,nil,nil,function()
                self:TimerStart(self._showBarEffKey,1,true,1)
            end)
    CS.ShowObject(effBarRoot,showEff)
end


-- 魔偶背包切换到英雄背包界面
function UISubGolemIntensify:OnClickShowGolemBagBtnFunc()
    local heroId = self._heroId
    if not heroId then
        self._index = 1
        heroId = self._cutHeroList[self._index] and self._cutHeroList[self._index].id
        self._heroId = heroId
        self._golemServerData = nil
    end
    local heroServerData = self:GetHeroServerData()
    local golemInfo,golemId
    if heroId then
        local wearMap,wearList = gModelGolem:GetHeroWearGolemListByHeroId(heroId)
        if #wearList > 1 then
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
        end
    end
    --- 打开强化界面
    -- gModelGolem:OpenGolemIntensify({
    --     golemInfo = golemInfo,
    --     golemId = golemId,
    --     heroServerData = heroServerData,
    --     viewType = UISubGolemIntensify.TYPE_HERO,
    -- })
    self:SetWndArg({
        golemInfo = golemInfo,
        golemId = golemId,
        heroServerData = heroServerData,
        viewType = UISubGolemIntensify.TYPE_HERO,
    })
    self:OnWndRefreshPanel()
end

function UISubGolemIntensify:CreateGolemIconEff(EffRootTrans,instanceID,endCall)
    local createEffIdList = self._createEffIdList
    if not createEffIdList then
        createEffIdList = {}
        self._createEffIdList = createEffIdList
    end
    createEffIdList[instanceID] = true
    local effName = "ui_fx_golem_icon_up_01"
    self:CreateWndEffect(EffRootTrans,effName,instanceID,100,nil,nil,nil,nil,nil,
    nil,nil,function()
                if endCall then endCall() end
                createEffIdList[instanceID] = false
            end)
end

function UISubGolemIntensify:OnGolemWearResp(pb)
    if pb.opsType == ModelGolem.OPSTYPE_TYPE_DEMOUNT then
        for i,v in ipairs(pb.golemId) do
            if v == self._golemId then
                self._golemId = nil
            end
        end
        self:UpdateGolemId()
        self:RefreshSelGolemServerData()
    elseif pb.opsType == ModelGolem.OPSTYPE_TYPE_WEAR then
        if not self._golemId then
            for i,v in ipairs(pb.golemId) do
                self._golemId = v
                break
            end
            self:UpdateGolemId()
            self:RefreshSelGolemServerData()
        end
    end
    self:RefreshHeroGolemData()
end

function UISubGolemIntensify:GetNeedItemList()
end

function UISubGolemIntensify:InitSelIntensifyMaterials()
    self._selIntensifyMaterials = {
        [ModelGolem.TYPE_MATERIAL_ITEM] = {
            selNum = 0,
            selIdList = {},
        },
        [ModelGolem.TYPE_MATERIAL_GOLEM] = {
            selNum = 0,
            selIdList = {},
        },
        [ModelGolem.TYPE_MATERIAL_ITEMGOLEM] = {
            selNum = 0,
            selIdList = {},
        },
    }
end
--------------------------------------------------------------------------------------------------
function UISubGolemIntensify:GetMaterialsChangeToExp(useType,info)
--[[    if useType == ModelGolem.TYPE_MATERIAL_ITEM or useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        return gModelGolem:GetUseItemToExp({itemId = info.itemId,useNum = info.useNum})
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        return gModelGolem:GetGolemInfoChangeToExp(info.golemInfo)
    end
    return 0]]

    return gModelGolem:GetMaterialsChangeToExp(useType,info)
end

function UISubGolemIntensify:OnGolemLockResp()
    self:InitGolemItemList()
end

--- 仅显示一个魔偶界面
function UISubGolemIntensify:RefreshShowGolemView()
    local golemServerData = self:GetSelGolemServerData()
    if not golemServerData then
        self:InitGolemItemList()
        self:CreateShowGolemIcon(self.mShowGolemRoot,golemServerData)
        return
    end
    self:CreateShowGolemIcon(self.mShowGolemRoot,golemServerData)
    local golemId = gModelGolem:GetGolemIdByGolemInfo(golemServerData)
    local showEff = self:CheckShowEff(golemId)
    if showEff then

        local instanceID = self.mGolemEffRoot:GetInstanceID()
        self:CreateGolemIconEff(self.mGolemEffRoot,instanceID,function()
            self:SetShowEffStatus(golemId)
        end)
    end
    CS.ShowObject(self.mGolemEffRoot,showEff)
    self:InitGolemItemList()
end

function UISubGolemIntensify:OpenItemUseWnd(info)
    local itemId = info.itemId
    local itemdata = info.itemdata
    local golemServerData = info.golemServerData
    local refreshFunc = info.refreshFunc
    local useType = info.useType
    gModelGolem:OpenGolemItemUse({
        itemId = itemId,
        useNum = self:GetSelGolemItemNum(itemdata),
        golemInfo = golemServerData,
        func = function(data)
            if not self:IsWndValid() then return end
            self:SetSelGolemItemInfo(useType,data)
            if refreshFunc then refreshFunc() end
        end,
    })
end
function UISubGolemIntensify:OpenGolemResolve()
    local heroServerData = self:GetHeroServerData()
    if not heroServerData then return end

    local golemServerData = self:GetSelGolemServerData()
    if not golemServerData then return end

    local golemStars = gModelGolem:GetGolemStars()
    local golemStar = gModelGolem:GetGolemElementStarByGolemInfo(golemServerData)
    if golemStar < golemStars then
        GF.ShowMessage(string.replace(ccClientText(34823),golemStars))
        return
    end
    GF.OpenWnd("UIGolemMainWin",{
        golemId = gModelGolem:GetGolemIdByGolemInfo(golemServerData),
        golemInfo = golemServerData,
        heroServerData = heroServerData,
        page = 1
    })
end

function UISubGolemIntensify:OnClickHeroChangeBtnFunc()
    gModelGolem:OpenGolemSwitchHero({
        curSelHeroId = self._heroId,
        func = function(selHeroId)
            self:RefreshByHeroIdChange(selHeroId)
        end,
    })
end
function UISubGolemIntensify:OnWndRefreshPanel()
    self._showBarEffStatus = false
    self:InitData()
    self:RefreshGolemShowView()
    self:RefreshHeroGolemData()
end

function UISubGolemIntensify:OnClickShowGolemWayBtnFunc()
    self:OnClickCommonWay()
end

function UISubGolemIntensify:InitShowHeroWearGolemList()
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

function UISubGolemIntensify:OnClickShowHeroGolemWearBtnFunc()
    local heroServerData = self:GetHeroServerData()
    if not heroServerData then return end
    local slotServerDataList = self._slotServerDataList or {}
    gModelGolem:OpenGolemWear({
        heroServerData = heroServerData,
        wearList = slotServerDataList,
    })
end

function UISubGolemIntensify:GetSelAutoKeyChoiceeItemList(materialsList)
    materialsList = materialsList or {}
    if #materialsList < 1 then return {} end

    local autoIntensifyIgnoreStar = gModelGolem:GetGolemConfigRefByKey("autoIntensifyIgnoreStar")
    if not autoIntensifyIgnoreStar then
        autoIntensifyIgnoreStar = 5
    end
    local golemStar
    local useType
    local list = {}
    for i,v in ipairs(materialsList) do
        useType = v.useType
        if useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            golemStar = gModelGolem:GetGolemElementStarByGolemInfo(v.info.serverData)
            if golemStar < autoIntensifyIgnoreStar then
                table.insert(list,v)
            end
        else
            table.insert(list,v)
        end
    end
    return list
end

function UISubGolemIntensify:OnClickIntensifyBtnFunc()
    if self._showBarEffStatus then return end
    local golemId = self._golemId
    if not golemId then return end
    local expItem
    local consumeGolem = {}
    local payNum
    local itemStr
    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    for useType,useTypeInfo in pairs(selIntensifyMaterials) do
        for k,v in pairs(useTypeInfo.selIdList) do
            if useType == ModelGolem.TYPE_MATERIAL_ITEM or useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
                if useType == ModelGolem.TYPE_MATERIAL_ITEM then
                    payNum = v
                elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
                    payNum = v.useNum
                end
                if payNum then
                    payNum = tonumber(payNum)
                    if payNum > 0 then
                        itemStr = LItemTypeConst.TYPE_ITEM .. "=" ..  k .. "=" ..  payNum
                        if expItem then
                            expItem = expItem .. "," .. itemStr
                        else
                            expItem = itemStr
                        end
                    end
                end
            elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
                table.insert(consumeGolem,gModelGolem:GetGolemIdByGolemInfo(v))
            end
        end
    end
    if not itemStr and #consumeGolem < 1 then
        self:CheckGolemMaterialsStatus()
        return
    end
    local payList = self:GetAllPayMaterialsChangeToPayList()
    if not gModelGeneral:CheckItemListEnough(payList, self:GetWndName()) then
        return
    end
    local resolveExpFunc = function()
        local func = function()
            gModelGolem:OnGolemStrongReq(golemId,expItem,consumeGolem)
        end
        gModelGolem:CheckIntensifyResolveExp(consumeGolem,func)
    end
    gModelGolem:CheckIntensifyHaveHeightGolem(consumeGolem,resolveExpFunc)
end

function UISubGolemIntensify:RefreshGolemShowView()
    local viewType = self._viewType
    local showHero = viewType == UISubGolemIntensify.TYPE_HERO
    local showGolem = viewType == UISubGolemIntensify.TYPE_GOLEM

    if showGolem then
        self:RefreshShowGolemView()
    end
    CS.ShowObject(self.mShowGolemView,showGolem)
    CS.ShowObject(self.mShowHeroGolemView,showHero)
    CS.ShowObject(self.mLeftBtn,showHero)
    CS.ShowObject(self.mRightBtn,showHero)
    self:RefreshShowHeroGolemRecastBtn()
end

function UISubGolemIntensify:InitMsg()
    self:WndNetMsgRecv(LProtoIds.GolemStrongResp,function(pb) self:OnGolemStrongResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemSlotResp,function(pb) self:OnGolemSlotResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemWearResp,function(pb) self:OnGolemWearResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemBagResp,function(pb) self:OnGolemBagResp(pb) end)
    self:WndEventRecv(EventNames.On_Item_Change,function() self:OnItemChange() end)
    self:WndNetMsgRecv(LProtoIds.GolemLockResp,function(pb) self:OnGolemLockResp(pb) end)
    -- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISubGolemIntensify:OnClickKeyChoiceeBtnFunc()
    if self._showBarEffStatus then return end

    local golemServerData = self:GetSelGolemServerData()
    if not golemServerData then
        GF.ShowMessage(ccClientText(33302))
        return end

    if gModelGolem:CheckGolemIsLevelFullByGolemInfo(golemServerData) then
        GF.ShowMessage(ccClientText(33262))
        return
    end

    local materialsList = self:GetGolemItemList()
    if #materialsList < 1 then
        self:OnClickCommonWay()
        return
    end

    local useQuickSelWnd = gModelGolem:GetGolemConfigRefByKey("useQuickSelWnd")
    if not useQuickSelWnd then
        useQuickSelWnd = 1
    end
    local isUseQuickSelWnd = useQuickSelWnd == 1
    if isUseQuickSelWnd then
        self:OnAutoKeyChoiceeWndFunc()
    else
        self:OnAutoKeyChoiceeFunc()
    end
end

function UISubGolemIntensify:GetGolemItemList()
    if not self._golemId then
        return {},UISubGolemIntensify.STATUS_NOTSELGOLEM
    end
    local golemSplitStatus = gModelGolem:CheckIsGolemItemSplit()
    local selIntensifyMaterialsType = self:GetSelIntensifyMaterialsByUseType(ModelGolem.TYPE_MATERIAL_ITEMGOLEM)
    local selIdList = selIntensifyMaterialsType.selIdList
    local list = {}
    local golemItemList = gModelItem:GetGolemExpItemList()
    local refId,haveNum
    for i,v in ipairs(golemItemList) do
        refId = v.refId
        haveNum = gModelItem:GetNumByRefId(refId)
        if haveNum > 0 then
            if gModelItem:CheckIsGolemExpRefId(refId) then
                table.insert(list,{
                    useType = ModelGolem.TYPE_MATERIAL_ITEM,
                    info = {
                        itemType = LItemTypeConst.TYPE_ITEM,
                        itemId = refId,
                        haveNum = haveNum,
                        conversionExp = v.conversionExp,
                        order = v.order,
                        selStatus = false,
                    },
                })
            else
                if golemSplitStatus then
                    local selInfo = selIdList[refId]
                    if not selInfo then
                        table.insert(list,{
                            useType = ModelGolem.TYPE_MATERIAL_ITEMGOLEM,
                            info = {
                                itemType = LItemTypeConst.TYPE_ITEM,
                                itemId = refId,
                                haveNum = haveNum,
                                conversionExp = v.conversionExp,
                                order = v.order,
                                selStatus = false,
                            },
                        })
                    else
                        local selNum = selInfo.useNum
                        local loseNum = haveNum - selNum
                        if loseNum > 0 then
                            --- 未选中的道具
                            table.insert(list,{
                                useType = ModelGolem.TYPE_MATERIAL_ITEMGOLEM,
                                info = {
                                    itemType = LItemTypeConst.TYPE_ITEM,
                                    itemId = refId,
                                    haveNum = loseNum,
                                    conversionExp = v.conversionExp,
                                    order = v.order,
                                    selStatus = false,
                                },
                            })
                        end
                        --- 分离出选中道具
                        for idx = 1,selNum do
                            table.insert(list,{
                                useType = ModelGolem.TYPE_MATERIAL_ITEMGOLEM,
                                info = {
                                    itemType = LItemTypeConst.TYPE_ITEM,
                                    itemId = refId,
                                    haveNum = 1,
                                    conversionExp = v.conversionExp,
                                    order = v.order,
                                    selStatus = true,
                                },
                            })
                        end
                    end
                else
                    table.insert(list,{
                        useType = ModelGolem.TYPE_MATERIAL_ITEMGOLEM,
                        info = {
                            itemType = LItemTypeConst.TYPE_ITEM,
                            itemId = refId,
                            haveNum = haveNum,
                            conversionExp = v.conversionExp,
                            order = v.order,
                            selStatus = false,
                        },
                    })
                end
            end
        end
    end
    if golemSplitStatus then
        table.sort(list,function(a,b)
            local infoA,infoB = a.info,b.info
            local orderA,orderB = infoA.order,infoB.order
            if orderA ~= orderB then
                return orderA < orderB
            end
            local selStatusA,selStatusB = infoA.selStatus,infoB.selStatus
            local selStatusANum,selStatusBNum = selStatusA and 1 or 0,selStatusB and 1 or 0
            return selStatusANum < selStatusBNum
        end)
    end

    local extraList = {
        [self._golemId] = true,
    }
    local golemList = gModelGolem:GetGolemIntensifyList(self._srotSelType,extraList)
--[[    table.sort(golemList,function (a,b)
        return a.star < b.star
    end)]]
    for i,v in ipairs(golemList) do
        table.insert(list,{
            useType = ModelGolem.TYPE_MATERIAL_GOLEM,
            info = {
                serverData = v,
            },
        })
    end
    return list,UISubGolemIntensify.STATUS_MATERIALS
end

function UISubGolemIntensify:SetShowEffStatus(golemId)

    local showEffGolemRefIdList = self._showEffGolemRefIdList
    if not showEffGolemRefIdList then return end
    showEffGolemRefIdList[golemId] = false
end

function UISubGolemIntensify:OnClickShowHeroWearGolemFunc(itemdata)
    local golemInfo = itemdata.golemInfo
    if golemInfo then
        local isSel = self:CheckIsSelHeroWearGolem(golemInfo)
        if isSel then return end
        self._golemId = gModelGolem:GetGolemIdByGolemInfo(golemInfo)
        self:UpdateGolemId()
        self:RefreshSelGolemServerData()
        self:InitSelIntensifyMaterials()
        self:RefreshShowHeroGolemView()
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

function UISubGolemIntensify:GetMaterialsChangeToPayList(useType,info)
--[[    if useType == ModelGolem.TYPE_MATERIAL_ITEM or useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        return gModelGolem:GetUseItemToPayItemList({itemId = info.itemId,useNum = info.useNum})
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        return gModelGolem:GetGolemInfoChangeToPayItemList(info.golemInfo)
    end
    return {}]]

    return gModelGolem:GetMaterialsChangeToPayList(useType,info)
end
function UISubGolemIntensify:UpdateGolemId()
    local params = self:GetWndArgList()
    params.golemId = self._golemId
end
function UISubGolemIntensify:OnWndRefresh()
    LChildWnd.OnWndRefresh(self)
    self:OnWndRefreshPanel()
end

function UISubGolemIntensify:OnClickShowHeroGolemBagBtnFunc()
    local golemData
    if ModelGolem.TYPE_GOLEM_USEHEO == 0 then
        golemData = gModelGolem:GetIntensifyGolemId()
    elseif ModelGolem.TYPE_GOLEM_USEHEO == 1 then
        local golemServerData = self:GetSelGolemServerData()
        local isHaveData = golemServerData ~= nil
        golemData = {
            status = isHaveData and 1 or -1,
            golemId = isHaveData and golemServerData.id,
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
    local heroServerData = self:GetHeroServerData()
    --- 打开强化界面
    -- gModelGolem:OpenGolemIntensify({
    --     golemInfo = golemInfo,
    --     golemId = golemId,
    --     heroServerData = heroServerData,
    --     viewType = UISubGolemIntensify.TYPE_GOLEM,
    -- })
    self:SetWndArg({
        golemInfo = golemInfo,
        golemId = golemId,
        heroServerData = heroServerData,
        viewType = UISubGolemIntensify.TYPE_GOLEM,
    })
    self:OnWndRefreshPanel()
end

function UISubGolemIntensify:OnItemChange()
    self:InitGolemItemList()
end

function UISubGolemIntensify:CreateShowHeroIcon()
    local heroId = self._heroId
    if not heroId then return end
    local baseClass = self:CreateCommonBaseClass(self.mHeroShowRoot)
    baseClass:SetHeroPlayer(heroId)
    baseClass:DoApply()
end

function UISubGolemIntensify:GetHeroServerData()
    if not self._heroServerData then
        self:RefreshHeroServerData()
    end
    return self._heroServerData
end

function UISubGolemIntensify:RefreshSelGolemItemNum(useType)
    local selIntensifyMaterialsType = self:GetSelIntensifyMaterialsByUseType(useType)
    local selIdList = selIntensifyMaterialsType.selIdList

    local allUseNum = 0
    if useType == ModelGolem.TYPE_MATERIAL_ITEM then
        for k,v in pairs(selIdList) do
            allUseNum = allUseNum + v
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        for k,v in pairs(selIdList) do
            allUseNum = allUseNum + v.useNum
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        for k,v in pairs(selIdList) do
            allUseNum = allUseNum + 1
        end
    end
    selIntensifyMaterialsType.selNum = allUseNum
end

function UISubGolemIntensify:OnClickShowHeroGolemRecommendBtnFunc()
    local heroId = self._heroId
    if not heroId then return end
    gModelGolem:OpenHeroGolemRecommendByHeroI(heroId)
end

function UISubGolemIntensify:InitSortSelGolemDiv()
    local trans = self.mSortSelGolemDiv
    local DivBgTrans = self:FindWndTrans(trans,"DivBg")
    local DivNameTrans = self:FindWndTrans(DivBgTrans,"DivName")
    local BtnTrans = self:FindWndTrans(DivBgTrans,"Btn")
    self:SetWndText(DivNameTrans,ccClientText(33214))
    self._sortSelDivNameTrans = DivNameTrans
    self:SetWndClick(DivBgTrans,function()
        self:OnClickSortSelGolemDivFunc()
    end)
    self:SetWndClick(BtnTrans,function()
        self:OnClickSortSelGolemDivFunc()
    end)
end

function UISubGolemIntensify:RefreshSelGolemServerData()
    if not self._golemId then
        self._golemServerData = nil
        return
    end
    self._golemServerData = gModelGolem:GetGolemServerDataById(self._golemId)
end

function UISubGolemIntensify:OnClickCommonWay()
    -- 策划默认是这个道具跳转
    --gModelGeneral:OpenGetWayWnd({itemId = ModelItem.GOLEM_EXP_270111,srcWnd = self:GetWndName()})
    gModelGeneral:OpenUIOrdinTips({ refId = 310009, func = function()
        gModelFunctionOpen:Jump(31000001,self:GetWndName())
    end})
end

function UISubGolemIntensify:InitData()
    self._viewType = self:GetWndArg("viewType")
    self._golemId = self:GetWndArg("golemId")
    self:InitHeroServerData()
    self:RefreshCutHeroInfo()
    if not self._viewType then
        self._viewType = self._heroId and UISubGolemIntensify.TYPE_HERO or UISubGolemIntensify.TYPE_GOLEM
    end
    self:RefreshSelGolemServerData()
    self:InitSelIntensifyMaterials()
end

function UISubGolemIntensify:OnClickShowHeroGolemSplitBtnFunc()

end

function UISubGolemIntensify:OnClickSortSelGolemFunc(itemdata)
    local isSel = self:CheckIsSortSelGolem(itemdata)
    if isSel then
        self._srotSelType = nil
        self:SetWndText(self._sortSelDivNameTrans,ccClientText(33214))
    else
        self._srotSelType = itemdata.selType
        self:SetWndText(self._sortSelDivNameTrans,itemdata.name)
    end
    self:OnClickShowSelGolemMaskFunc()
    --self:InitSortSelGolemList()
end

function UISubGolemIntensify:OnClickGolemItemFunc(itemdata)
    local refreshFunc = function()
        if not self:IsWndValid() then return end
        self:InitGolemItemList()
    end
    local info = itemdata.info
    if not info then return end
    local useType = itemdata.useType
    if useType == ModelGolem.TYPE_MATERIAL_ITEM then
        local itemId = info.itemId
        local haveNum = info.haveNum
        if haveNum < 1 then
            gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
        else
            --- 限制做在窗口里
            local golemServerData = self:GetSelGolemServerData()
            if not golemServerData then
                GF.ShowMessage(ccClientText(33302))
                return end
            self:OpenItemUseWnd({
                itemId = itemId,
                itemdata = itemdata,
                golemServerData = golemServerData,
                refreshFunc = refreshFunc,
                useType = useType,
            })
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        local itemId = info.itemId
        if gModelGolem:CheckIsGolemItemSplit() then
            local curSelNum = self:GetSelGolemItemNum(itemdata)
            if self:CheckIsSelGolemItem(itemdata) then
                local newSelNum = curSelNum - 1
                if newSelNum > 0 then
                    self:SetSelGolemItemInfo(useType,{
                        itemId = itemId,
                        useNum = newSelNum
                    })
                else
                    self:SetSelGolemItemInfo(useType,{
                        itemId = itemId,
                        useNum = nil
                    })
                end
            else
                self:SetSelGolemItemInfo(useType,{
                    itemId = itemId,
                    useNum = curSelNum + 1
                })
            end
            refreshFunc()
        else
            local golemServerData = self:GetSelGolemServerData()
            if not golemServerData then return end
            self:OpenItemUseWnd({
                itemId = itemId,
                itemdata = itemdata,
                golemServerData = golemServerData,
                refreshFunc = refreshFunc,
                useType = useType,
            })
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        local serverData = info.serverData
        if serverData then
            if serverData.isLock then
                gModelGolem:ChangeGolemLockStatusByGolemInfo(serverData)
                return
            end
            if LOG_INFO_ENABLED then
                local mainAttrList = serverData.mainAttrList
                for i,v in ipairs(mainAttrList) do
                    printInfoNR("打印而已，莫慌      属性打印：attrRefId = " .. v.attrRefId .. ",attrNum = " .. v.attrNum)
                end
            end
            local isSel = self:CheckIsSelGolemItem(itemdata)
            if isSel then
                self:PutSelGolemItemInfo(useType,serverData)
            else
                if self:CheckGolemInfoUseExpIsFull() then
                    GF.ShowMessage(ccClientText(34801))
                    return
                end
                local selectUpper = gModelGolem:GetGolemConfigRefByKey("selectUpper")
                local selGolemNum = self:GetSelGolemItemNum(itemdata)
                if selGolemNum >= selectUpper then return end
                self:SetSelGolemItemInfo(useType,serverData)
            end
            refreshFunc()
        end
    end
end

------------------------------------------------------------------
function UISubGolemIntensify:OnShowBarEffKey()
    self:TimerStop(self._showBarEffKey)
    self._showBarEffStatus = false
    local showUpLvPopWndFunc = self._showUpLvPopWndFunc
    self._showUpLvPopWndFunc = nil
    if showUpLvPopWndFunc then
        showUpLvPopWndFunc()
    end
end

function UISubGolemIntensify:OnDrawSortSelGolemCell(list,item,itemdata,itempos)
    local NoSelTxtTrans = self:FindWndTrans(item,"NoSelTxt")
    local SelImgTrans = self:FindWndTrans(item,"SelImg")
    local SelTxtTrans = self:FindWndTrans(SelImgTrans,"SelTxt")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local name = itemdata.name
    self:SetWndText(NoSelTxtTrans,name)
    self:SetWndText(SelTxtTrans,name)

    local isSel = self:CheckIsSortSelGolem(itemdata)
    CS.ShowObject(NoSelTxtTrans,not isSel)
    CS.ShowObject(SelImgTrans,isSel)

    self:SetWndClick(BtnTrans,function()
        self:OnClickSortSelGolemFunc(itemdata)
    end)
end

function UISubGolemIntensify:OnDrawGolemItemCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
    local NumTxtTrans = self:FindWndTrans(item,"NumTxt")
    local useType = itemdata.useType
    local info = itemdata.info
    local baseClass = self:CreateCommonBaseClass(item)
    local numStr = ""
    if useType == ModelGolem.TYPE_MATERIAL_ITEM then
        baseClass:SetCommonReward(info.itemType,info.itemId,-1)
        baseClass:EnableShowNum(false)

        local haveNum = info.haveNum
        if haveNum < 1 then
            baseClass:ShowMaskOnly(true)
        else
            baseClass:ShowMaskOnly(false)
            local selNum = self:GetSelGolemItemNum(itemdata)
            numStr = string.replace("#a1#/#a2#",LUtil.NumberCoversion(selNum),LUtil.NumberCoversion(haveNum))
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        baseClass:SetCommonReward(info.itemType,info.itemId,-1)
        if gModelGolem:CheckIsGolemItemSplit() then
            local isSel = self:CheckIsSelGolemItem(itemdata)
            baseClass:ShowMaskOnly(isSel)
            baseClass:SetShowGouImg(isSel)
            if not isSel then
                numStr = LUtil.NumberCoversion(info.haveNum)
            end
        else
            baseClass:ShowMaskOnly(false)
            baseClass:SetShowGouImg(false)
            local selNum = self:GetSelGolemItemNum(itemdata)
            numStr = string.replace("#a1#/#a2#",LUtil.NumberCoversion(selNum),LUtil.NumberCoversion(info.haveNum))
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        local serverData = info.serverData
        baseClass:SetGolemData({
            refId = gModelGolem:GetGolemRefIdByGolemInfo(serverData),
            lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(serverData),
            lvl = gModelGolem:GetGolemLvlByGolemInfo(serverData),
            showGou = self:CheckIsSelGolemItem(itemdata),
            displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(serverData),
            showLock = serverData.isLock,
        })
    end
    baseClass:DoApply()

    self:SetWndText(NumTxtTrans,numStr)
    self:SetWndClick(IconTrans,function()
        self:OnClickGolemItemFunc(itemdata)
    end)
    -- 长按
    self:SetWndLongClick(IconTrans,function()
        if useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            ----- 魔偶属性详情界面
            gModelGolem:OpenGolemInfoTip({
                viewType = 2,
                golemData = info.serverData,
            })
        else
            gModelGeneral:OpenItemInfoTip(info.itemId,info.haveNum)
        end
    end,0.8,false)
end

function UISubGolemIntensify:OnDrawNeedItemCell(list,item,itemdata,itempos)
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
    local color = haveNum >= payNum and "white" or "lightRed"
    local payStr = LUtil.NumberCoversion(payNum)
    local str = LUtil.FormatColorStr(payStr,color)
    self:SetWndText(IconNumTrans,str)
end

function UISubGolemIntensify:OnClickHelpBtnFunc()
    GF.OpenWnd("UIBzTips",{refId = 504})
end

function UISubGolemIntensify:CheckIsSelGolemItem(itemdata)
    if not itemdata then return false end
    local useType = itemdata.useType
    local info = itemdata.info
    local selIntensifyMaterialsType = self:GetSelIntensifyMaterialsByUseType(useType)
    if useType == ModelGolem.TYPE_MATERIAL_ITEM then
    elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        return info.selStatus
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        local selIdList = selIntensifyMaterialsType.selIdList
        local id = gModelGolem:GetGolemIdByGolemInfo(info.serverData)
        return selIdList[id] ~= nil
    end
    return false
end

function UISubGolemIntensify:CreateShowGolemIcon(trans,golemInfo)
    local baseClass = self:CreateCommonBaseClass(trans)
    local lv = golemInfo and gModelGolem:GetGolemLvlByGolemInfo(golemInfo) or 0
    self:SetWndText(self.mLvTxt,"+"..lv)
    if golemInfo then
        baseClass:SetGolemData({
            refId = gModelGolem:GetGolemRefIdByGolemInfo(golemInfo),
            lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(golemInfo),
            -- lvl = gModelGolem:GetGolemLvlByGolemInfo(golemInfo),
            displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(golemInfo),
        })
    else
        baseClass:SetGolemData({
            showEmpty = true
        })
    end
    baseClass:DoApply()
end

function UISubGolemIntensify:OnClickShowSelGolemMaskFunc()
    CS.ShowObject(self.mShowSelGolemMask,false)
    self:InitGolemItemList()
end

function UISubGolemIntensify:GetSelGolemItemNum(itemdata)
    if not itemdata then return 0 end
    local useType = itemdata.useType
    local info = itemdata.info
    local selIntensifyMaterialsType = self:GetSelIntensifyMaterialsByUseType(useType)
    if useType == ModelGolem.TYPE_MATERIAL_ITEM then
        local selIdList = selIntensifyMaterialsType.selIdList
        return selIdList[info.itemId] or 0
    elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        local selIdList = selIntensifyMaterialsType.selIdList
        local selInfo = selIdList[info.itemId]
        if selInfo then
            return selInfo.useNum
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        return selIntensifyMaterialsType.selNum
    end
    return 0
end

function UISubGolemIntensify:InitShowChangeAttrList(list)
    list = list or {}
    local uiShowChangeAttrList = self._uiShowChangeAttrList
    if uiShowChangeAttrList then
        uiShowChangeAttrList:RefreshList(list)
    else
        uiShowChangeAttrList = self:GetUIScroll("uiShowChangeAttrList")
        self._uiShowChangeAttrList = uiShowChangeAttrList
        uiShowChangeAttrList:Create(self.mShowChangeAttrList,list,function(...) self:OnDrawShowChangeAttrCell(...) end)
        uiShowChangeAttrList:EnableScroll(true)
    end
end
--------------------------------------------------------------------------------------------------
function UISubGolemIntensify:CreateCommonBaseClass(trans)
    local IconTrans = self:FindWndTrans(trans,"CommonUI/Icon")
    local instanceID = trans:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    return baseClass
end

function UISubGolemIntensify:OnAutoKeyChoiceeWndFunc()
    local golemServerData = self:GetSelGolemServerData()
    if not golemServerData then return end

    local materialsList = self:GetGolemItemList()
    materialsList = self:GetSelAutoKeyChoiceeItemList(materialsList)
    if #materialsList < 1 then
        self:OnClickCommonWay()
        return
    end

    local selIntensifyMaterials = self:GetSelIntensifyMaterials()
    gModelGolem:OpenGolemItemUseAuto({
        golemInfo = golemServerData,
        materialsList = materialsList,
        selMaterialsList = selIntensifyMaterials,
        func = function(list)
            if not self:IsWndValid() then return end
            list = list or {}
            --- 刷新流程
            self:InitSelIntensifyMaterials()
            local useType
            for i,v in ipairs(list) do
                useType = v.useType
                if useType == ModelGolem.TYPE_MATERIAL_GOLEM then
                    self:SetSelGolemItemInfo(useType,v.info.golemInfo)
                else
                    self:SetSelGolemItemInfo(useType,v.info)
                end
            end
            self:InitGolemItemList()
        end,
    })
end

function UISubGolemIntensify:CheckIsSortSelGolem(itemdata)
    if not self._srotSelType then return false end
    return itemdata.selType == self._srotSelType
end

function UISubGolemIntensify:OnClickGolemChangeBtnFunc()
--[[    local wndIns = GF.FindFirstWndByName("UIGolemWarehouse")
    if wndIns then
        GF.CloseWndByName("UIGolemWarehouse")
    end]]
    gModelGolem:OpenGolemWarehouse({
        viewType = 2,
        optType = ModelGolem.TYPE_OPT_CHANGE,
        golemId = self._golemId,
        optStatus = ModelGolem.OPTSTATUS_WAREHOUSE_CHANGE,
    })
end

function UISubGolemIntensify:InitEvent()
    self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
    self:SetWndClick(self.mGolemChangeBtn,function() self:OnClickGolemChangeBtnFunc() end)
    self:SetWndClick(self.mShowGolemBagBtn,function() self:OnClickShowGolemBagBtnFunc() end)
    self:SetWndClick(self.mShowGolemWayBtn,function() self:OnClickShowGolemWayBtnFunc() end)
    self:SetWndClick(self.mShowGolemSplitBtn,function() self:OpenGolemResolve() end)
    self:SetWndClick(self.mHeroChangeBtn,function() self:OnClickHeroChangeBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemRecommendBtn,function() self:OnClickShowHeroGolemRecommendBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemBagBtn,function() self:OnClickShowHeroGolemBagBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemDemountBtn,function() self:OnClickShowHeroGolemDemountBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemWearBtn,function() self:OnClickShowHeroGolemWearBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemWayBtn,function() self:OnClickShowHeroGolemWayBtnFunc() end)
    self:SetWndClick(self.mShowHeroGolemSplitBtn,function() self:OpenGolemResolve() end)
    self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mIntensifyBtn,function() self:OnClickIntensifyBtnFunc() end)
    self:SetWndClick(self.mKeyChoiceeBtn,function() self:OnClickKeyChoiceeBtnFunc() end)
    self:SetWndClick(self.mShowSelGolemMask,function() self:OnClickShowSelGolemMaskFunc() end)
    self:SetWndClick(self.mShowHeroGolemRecastBtn,function() self:OnClickShowHeroGolemRecastBtnFunc() end)
    self:SetWndClick(self.mLeftBtn,function() self:ChangeHeroOpt(-1) end)
    self:SetWndClick(self.mRightBtn,function() self:ChangeHeroOpt(1) end)
end

function UISubGolemIntensify:InitGolemItemList()
    self:GetUpLvlShow()
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
    local isEmpty = #list < 1
    if isEmpty then
        local wndId = self._golemId and 29002 or 29003
        self:SetEmptyList(wndId)
    end
    CS.ShowObject(self.mNotItemRecord,isEmpty)
end

function UISubGolemIntensify:RefreshHeroServerData()
    if not self._heroId then
        self._heroServerData = nil
        return
    end
    self._heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
end

function UISubGolemIntensify:RefreshHeroId()
    local heroServerData = self._heroServerData
    if not heroServerData then
        self._heroId = nil
        return
    end
    self._heroId = heroServerData.id
end

function UISubGolemIntensify:OnGolemStrongResp(pb)
    local before = pb.before
    local golemId = gModelGolem:GetGolemIdByGolemInfo(before)
    if golemId ~= self._golemId then return end
    local isUpLv = gModelGolem:CheckIsLvUp(before,pb.after)
    if isUpLv then
        self._showEffGolemRefIdList = {}
        local id = gModelGolem:GetGolemIdByGolemInfo(before)
        self._showEffGolemRefIdList[id] = true

        LxUiHelper.PlayAudioSoundName(LSoundConst.GOLEM_UP_LV)
    end
    --- 刷新流程
    self:InitSelIntensifyMaterials()
    local viewType = self._viewType
    if viewType == UISubGolemIntensify.TYPE_HERO then
        self:RefreshHeroGolemData()
        self:InitGolemItemList()
    else
        self:RefreshShowGolemView()
    end
    self._showBarEffStatus = false
    self:CreateBarEff(isUpLv,pb)
end

function UISubGolemIntensify:OnClickShowHeroGolemDemountBtnFunc()
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

function UISubGolemIntensify:UpdateSelGolemMaterials(pb)
    local syncType = pb.syncType
    if syncType ~= 2 then return end
    local golem = pb.golem
    for i,v in ipairs(golem) do
        if self:CheckIsSelGolemItem({
            useType = ModelGolem.TYPE_MATERIAL_GOLEM,
            info = {
                serverData = v,
            }
        }) then
            self:PutSelGolemItemInfo(ModelGolem.TYPE_MATERIAL_GOLEM,v)
        end
    end
end

function UISubGolemIntensify:CheckIsSelHeroWearGolem(golemInfo)
    if not golemInfo then return false end
    if not self._golemId then return false end
    local id = gModelGolem:GetGolemIdByGolemInfo(golemInfo)
    return id == self._golemId
end

function UISubGolemIntensify:OnClickShowHeroGolemRecastBtnFunc()
    if not gModelFunctionOpen:CheckIsOpened(31000004,true) then--32000002
        return
    end

    local heroServerData = self:GetHeroServerData()
    if not heroServerData then return end

    local golemServerData = self:GetSelGolemServerData()
    if not golemServerData then return end

    local golemStars = gModelGolem:GetGolemStars()
    local golemStar = gModelGolem:GetGolemElementStarByGolemInfo(golemServerData)
    if golemStar < golemStars then
        GF.ShowMessage(string.replace(ccClientText(34823),golemStars))
        return
    end
    -- gModelGolem:OpenGolemRecast({
    --     golemId = gModelGolem:GetGolemIdByGolemInfo(golemServerData),
    --     golemInfo = golemServerData,
    --     heroServerData = heroServerData,
    --     viewType = 1,
    --     closeWndFunc = function()
    --         self:WndClose()
    --     end,
    -- })
    GF.OpenWnd("UIGolemMainWin",{
        golemId = gModelGolem:GetGolemIdByGolemInfo(golemServerData),
        golemInfo = golemServerData,
        heroServerData = heroServerData,
        viewType = 1,
        page = 3
    })
end

function UISubGolemIntensify:RefreshTopLvAndBar(curLvl,nextLvl,curExp,nextExp,add,changeBarStatus,barCurExp,barNextExp,showFull)
    self:SetWndText(self.mCurLvTxt,string.replace(ccClientText(33243),curLvl))
    local showNext = nextLvl ~= nil
    if showNext then
        self:SetWndText(self.mNewLvTxt,string.replace(ccClientText(33244),nextLvl))
    end
    CS.ShowObject(self.mNewLvTxt,showNext)
    CS.ShowObject(self.mIntensifyArrowDiv,showNext)

    local addExp = curExp + add
--[[    local curPercent = addExp/nextExp
    LxUiHelper.SetProgress(self.mGolemCurExpBar,curExp/nextExp)
    LxUiHelper.SetProgress(self.mGolemAddExpBar,curPercent)]]

    LxUiHelper.SetProgress(self.mGolemCurExpBar,curExp/nextExp)
    if changeBarStatus then
        LxUiHelper.SetProgress(self.mGolemAddExpBar,1)
    else
        local curPercent = addExp/nextExp
        LxUiHelper.SetProgress(self.mGolemCurExpBar,curExp/nextExp)
        LxUiHelper.SetProgress(self.mGolemAddExpBar,curPercent)
    end

    local expStr
    if showFull then
        expStr = ccClientText(34803)
        expStr = "MAX"
    else
        expStr = string.replace("#a1#/#a2#",addExp,nextExp)
    end
    self:SetWndText(self.mGolemExpTxt,expStr)
end
function UISubGolemIntensify:SetEmptyList(refId)
    local NotItemEmptyData = {
        refId = refId or 29002,
        IntroTran = self.mNotItemEmptyText,
        TextBgTran = self.mNotItemEmptyTextBg,
        IconTran = self.mNotItemEmptyIcon,
    }
    local NotItemEmpty = self:GetCommonEmptyList("NotItemEmpty")
    NotItemEmpty:RefreshUI(NotItemEmptyData)
end

------------------------- List -------------------------

function UISubGolemIntensify:GetShowHeroWearGolemList()
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

--- 显示英雄的魔偶数据
function UISubGolemIntensify:RefreshShowHeroGolemView()
    self:CreateShowHeroIcon()
    self:InitShowHeroWearGolemList()
    self:InitGolemItemList()
    self:RefreshShowHeroGolemRecastBtn()
end

function UISubGolemIntensify:OnDrawShowChangeAttrCell(list,item,itemdata,itempos)
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local BeforeAttrValueTrans = self:FindWndTrans(item,"BeforeAttrValue")
    local ArrowTrans = self:FindWndTrans(item,"Arrow")
    local LastAttrValueTrans = self:FindWndTrans(item,"LastAttrValue")

    local attrRefId = itemdata.attrRefId
    local attrType = itemdata.attrType
    local before = itemdata.before
    local last = itemdata.last

    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrNameTrans,attrName)

    local beforeValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,before)
    self:SetWndText(BeforeAttrValueTrans,beforeValue)

    local showNext = last > 0
    if showNext then
        local lastValue = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,last)
        self:SetWndText(LastAttrValueTrans,lastValue)
    end
    CS.ShowObject(ArrowTrans,showNext)
    CS.ShowObject(LastAttrValueTrans,showNext)
end

function UISubGolemIntensify:GetUpLvlShow()
    local curServerData = self:GetSelGolemServerData()
    local upLvChangeAttrList,curLvl,nextLvl,curExp,nextExp
    local showUpView = false
    local payList = {}
    CS.ShowObject(self.mNotAttrTips,not curServerData)
    if curServerData then
        local addExp = self:GetAllPayMaterialsChangeToExp()
        --- 返回当前的经验和下一级的经验，属性变化列表
        local upLvInfo = gModelGolem:GetAddExpShowInfo(curServerData,addExp)
        upLvChangeAttrList = upLvInfo.upLvChangeAttrList or {}
        curLvl = upLvInfo.curLvl or gModelGolem:GetGolemLvlByGolemInfo(curServerData)
        nextLvl = upLvInfo.nextLv
        curExp = upLvInfo.exp or gModelGolem:GetGolemExpByGolemInfo(curServerData)
        nextExp = upLvInfo.nextNeedExp or gModelGolem:GetGolemNeedExpByLevelRefId(gModelGolem:GetGolemLvlRefIdByGolemInfo(curServerData))

        local barCurExp,barNextExp
        local changeBarStatus = upLvInfo.changeBarStatus
        if changeBarStatus then
            barCurExp,barNextExp = 1,1
        else
            barCurExp,barNextExp = curExp,nextExp
        end

        local showFull = upLvInfo.showFull or false

        self:RefreshTopLvAndBar(curLvl,nextLvl,curExp,nextExp,addExp,changeBarStatus,barCurExp,barNextExp,showFull)
        showUpView = true

        payList = self:GetAllPayMaterialsChangeToPayList()
    else
        upLvChangeAttrList = {}
        -- local attrList = gModelGolem:GetConfigAttrShowList()
        -- for i,v in ipairs(attrList) do
        --     table.insert(upLvChangeAttrList,{
        --         attrRefId = v.attrRefId,
        --         attrType = v.attrType,
        --         before = v.attrNum,
        --         last = ModelGolem.UP_LV_STATUS_NOTEXP,
        --     })
        -- end
        table.sort(upLvChangeAttrList,function(a,b)
            local attrRefIdA,attrRefIdB = a.attrRefId,b.attrRefId
            local attrTypeA,attrTypeB = a.attrType,b.attrType
            local sortA
            if attrTypeA == 1 then
                sortA = gModelHero:GetAttributeSortById(attrRefIdA)
            elseif attrTypeA == 2 then
                sortA = gModelHero:GetAttributeSort2ById(attrRefIdA)
            end
            local sortB
            if attrTypeB == 1 then
                sortB = gModelHero:GetAttributeSortById(attrRefIdB)
            elseif attrTypeB == 2 then
                sortB = gModelHero:GetAttributeSort2ById(attrRefIdB)
            end
            return  sortA < sortB
        end)
    end

    self:InitNeedItemList(payList)

    CS.ShowObject(self.mGolemExpDiv,showUpView)
    CS.ShowObject(self.mIntensifyDiv,showUpView)
    self:InitShowChangeAttrList(upLvChangeAttrList)
    CS.ShowObject(self.mShowChangeAttrListBg,true)
end

function UISubGolemIntensify:PutSelGolemItemInfo(useType,selInfo)
    local selIntensifyMaterialsType = self:GetSelIntensifyMaterialsByUseType(useType)
    local selIdList = selIntensifyMaterialsType.selIdList
    local refreshNum = false
    if useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        local id = gModelGolem:GetGolemIdByGolemInfo(selInfo)
        if selIdList[id] then
            selIdList[id] = nil
            refreshNum = true
        end
    end
    if refreshNum then
        self:RefreshSelGolemItemNum(useType)
    end
end

function UISubGolemIntensify:SetSelGolemItemInfo(useType,selInfo)
    local selIntensifyMaterialsType = self:GetSelIntensifyMaterialsByUseType(useType)
    local selIdList = selIntensifyMaterialsType.selIdList
    if useType == ModelGolem.TYPE_MATERIAL_ITEM then
        selIdList[selInfo.itemId] = selInfo.useNum
    elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
        if selInfo.useNum then
            selIdList[selInfo.itemId] = {
                useNum = selInfo.useNum
            }
        else
            selIdList[selInfo.itemId] = nil
        end
    elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
        local id = gModelGolem:GetGolemIdByGolemInfo(selInfo)
        selIdList[id] = selInfo
    end
    self:RefreshSelGolemItemNum(useType)
end

function UISubGolemIntensify:OnGolemBagResp(pb)
    self:UpdateSelGolemMaterials(pb)
    self:InitGolemItemList()
end

function UISubGolemIntensify:InitSortSelGolemList()
    local list = self:GetSortSelGolemList()
    local uiSortSelGolemList = self._uiSortSelGolemList
    if uiSortSelGolemList then
        uiSortSelGolemList:RefreshList(list)
    else
        uiSortSelGolemList = self:GetUIScroll("uiSortSelGolemList")
        self._uiSortSelGolemList = uiSortSelGolemList
        uiSortSelGolemList:Create(self.mSortSelGolemList,list,function(...) self:OnDrawSortSelGolemCell(...) end)
    end
end

function UISubGolemIntensify:ChangeHeroOpt(optNum)
    local index = self._index
    if not index then
        return
    end
    local cnt = #self._cutHeroList
    local newIndex = index + optNum
    if newIndex <= 0 then
        newIndex = cnt
    elseif newIndex > cnt then
        newIndex = 1
    end
    local heroData = self._cutHeroList[newIndex]

    -- self._heroId = heroData.id
    self._index = newIndex
    self:RefreshByHeroIdChange(heroData.id)
end

function UISubGolemIntensify:OnClickSortSelGolemDivFunc()
    CS.ShowObject(self.mShowSelGolemMask,true)
    self:InitSortSelGolemList()
end



------------------------------------------------------------------
return UISubGolemIntensify