---
--- Created by LCM.
--- DateTime: 2023/2/15 16:09:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemItemUseAuto:LWnd
local UIGolemItemUseAuto = LxWndClass("UIGolemItemUseAuto", LWnd)

local CS = CS
local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)


UIGolemItemUseAuto.TYPE_SEL_0 = 0              --- 没有修改
UIGolemItemUseAuto.TYPE_SEL_1 = 1              --- 有修改

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemItemUseAuto:UIGolemItemUseAuto()
    self._selType = UIGolemItemUseAuto.TYPE_SEL_0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemItemUseAuto:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemItemUseAuto:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemItemUseAuto:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitSlider()
    self:RefreshView()
    self:RefreshGolemRoot()
end

function UIGolemItemUseAuto:GetSortGolemList()
    return self._sortGolemList or {}
end

function UIGolemItemUseAuto:GetMaxLvNeedExp()
    if not self._golemMaxLvInfo then return end
    return self._golemMaxLvInfo.exp
end

function UIGolemItemUseAuto:UpdateSlider()
    self._sliderComponent.value = self._useNum
end

function UIGolemItemUseAuto:OnClickAddBtnFunc()
    local addNum = self._useNum + 1
    if addNum > self._haveNum then return end
    self:ChangeNum(addNum,true)
end

function UIGolemItemUseAuto:GetPayItemListByNum(num)
    local needNum = num
    local itemList = {}
    local useType,info
    local haveNum,useNum
    local recordUseNum = 0
    local sortItemList = self:GetSortItemList()
    for i,v in ipairs(sortItemList) do
        if needNum < 1 then break end
        useType = v.useType
        info = v.info
        haveNum = info.haveNum
        if haveNum > 0 then
            if haveNum >= needNum then
                useNum = needNum
            else
                useNum = haveNum
            end
            table.insert(itemList,{
                useType = v.useType,
                info = {
                    itemId = info.itemId,
                    useNum = useNum,
                }
            })
            recordUseNum = recordUseNum + useNum
            needNum = needNum - useNum
        end
    end
    if needNum > 0 then
        local golemInfo
        local sortGolemList = self:GetSortGolemList()
        for i,v in ipairs(sortGolemList) do
            if needNum < 1 then break end
            useType = v.useType
            info = v.info
            golemInfo = info.serverData
            table.insert(itemList,{
                useType = useType,
                info = {
                    golemInfo = golemInfo,
                }
            })
            recordUseNum = recordUseNum + 1
            needNum = needNum - 1
        end
    end

    local isEnough = recordUseNum == needNum

    return {
        useItemExp = self:GetAllExp(itemList),
        isEnough = isEnough,
        expList = itemList,
        recordUseNum = recordUseNum,
    }
end

function UIGolemItemUseAuto:ChangeSlider()
    self:RefreshUseNumTxt()
    self:UpdateSlider()
end


function UIGolemItemUseAuto:InitMsg()

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemItemUseAuto:GetAllExp(itemList)
    local allExp = 0
    local addExp
    local useType,info
    for i,v in ipairs(itemList) do
        useType = v.useType
        info = v.info
        if useType == ModelGolem.TYPE_MATERIAL_ITEM or useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
            addExp = gModelGolem:GetMaterialsChangeToExp(useType,{
                itemId = info.itemId,
                useNum = info.useNum,
            })
        elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            addExp = gModelGolem:GetMaterialsChangeToExp(useType,{
                golemInfo = info.golemInfo
            })
        end
        allExp = allExp + addExp
    end
    return allExp
end

function UIGolemItemUseAuto:OnDrawGolemActStatusCell(list,item,itemdata,itempos)
    local NoSelImgTrans = self:FindWndTrans(item,"NoSelImg")
    local SelImgTrans = self:FindWndTrans(item,"SelImg")
    local BtnTrans = self:FindWndTrans(item,"Btn")

    local showSelStatus = false
    local intensifyLv = itemdata.intensifyLv
    local lvRef = itemdata.lvRef
    local isLvHaveUp = lvRef ~= nil
    if isLvHaveUp then
        local needExp = lvRef.needExp
        local nowGolemExp = itemdata.nowGolemExp
        if nowGolemExp >= needExp then
            showSelStatus = true
        end
    end
    self:SetTextTile(NoSelImgTrans,intensifyLv)
    CS.ShowObject(NoSelImgTrans,not showSelStatus)

    self:SetTextTile(SelImgTrans,intensifyLv)
    CS.ShowObject(SelImgTrans,showSelStatus)

    self:SetWndClick(BtnTrans,function()
        self:OnClickGolemActStatusFunc(itemdata)
    end)
end

function UIGolemItemUseAuto:GetSortItemList()
    return self._sortItemList or {}
end

function UIGolemItemUseAuto:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCancelBtn,function() self:OnClickCancelBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mSubBtn,function() self:OnClickSubBtnFunc() end)
    self:SetWndClick(self.mAddBtn,function() self:OnClickAddBtnFunc() end)
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)

    self:SetWndClick(self.mValueBg,function() self:OnClickValueBgFunc() end)
end

function UIGolemItemUseAuto:OnClickValueBgFunc()
    local tab = {}
    tab.inputTran = self.mInputBg
    tab.minNum = 0
    tab.maxNum = self._haveNum
    tab.defaultNum = tonumber(self.mValue.text)
    tab.inputFunc = function(numStr,cmd)
        if self:IsWndClosed() then return end
        local num = tonumber(numStr)
        if num then
            if cmd == "C" then
                self:RefreshUseNumTxt(0)
            elseif cmd == "D" then
                local useItemInfo = self:GetPayItemListByNum(num)
                local useItemExp = useItemInfo.useItemExp
                if self:CheckIsMax(useItemExp) then
                    if not self:CheckGolemIsMaxLv() then
                        local maxLvNeedExp = self:GetMaxLvNeedExp()
                        local exp = gModelGolem:GetGolemExpByGolemInfo(self._golemInfo)
                        if maxLvNeedExp and exp then
                            local lostExp = maxLvNeedExp - exp
                            useItemInfo = self:GetPayItemListByExp(lostExp)
                        else
                            useItemInfo = self:GetPayItemListByNum(0)
                        end
                    else
                        useItemInfo = self:GetPayItemListByNum(0)
                    end
                end
                self:CommonDisposeChange(useItemInfo)
            else
                self:RefreshUseNumTxt(num)
            end
        end
    end
    GF.OpenWndUp("UINuoardUI",tab)
end

function UIGolemItemUseAuto:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(34810))
    self:SetWndText(self.mDesc,ccClientText(34811))
    self:SetWndText(self.mUseDesc,ccClientText(34812))
    self:SetTextTile(self.mUseTitle,ccClientText(33237))
    self:SetTextTile(self.mIntensifyTitle,ccClientText(33238))
    self:SetWndButtonText(self.mEnterBtn,ccClientText(34815))
    self:SetWndButtonText(self.mCancelBtn,ccClientText(34814))
end

function UIGolemItemUseAuto:CommonDisposeChange(useItemInfo)
    local expList = useItemInfo.expList
    self:PackageSelMaterialsList(expList)
    self._useItemExp = useItemInfo.useItemExp
    self._useNum = useItemInfo.recordUseNum

    self:RefreshIntensifyDiv()
end

function UIGolemItemUseAuto:OnClickSubBtnFunc()
    local subNum = self._useNum - 1
    if subNum < 0 then return end
    self:ChangeNum(subNum)
end

function UIGolemItemUseAuto:OnClickCancelBtnFunc()
    self:WndClose()
end

function UIGolemItemUseAuto:RefreshView()
    self:RefreshIntensifyDiv()
end

function UIGolemItemUseAuto:InitData()
    self._selMaterialsList = {}

    local golemInfo = self:GetWndArg("golemInfo")
    if golemInfo then
        local maxLvInfo = gModelGolem:GetGolemLvGroupMaxInfoByGolemInfo(golemInfo)
        if maxLvInfo then
            self._golemMaxLvInfo = maxLvInfo
        end
    end
    self._golemInfo = golemInfo

    self._func = self:GetWndArg("func")

    local recordItemNum = self:DisposeGolemItemList()
    local recordGolemNum = self:DisposeGolemList()

    self._haveNum = recordItemNum + recordGolemNum

    self:DisposeSelGolemAndItemList()
end

function UIGolemItemUseAuto:OnClickEnterBtnFunc()
    local func = self._func
    self._func = nil
    if func then
        if self._selType == UIGolemItemUseAuto.TYPE_SEL_1 then
            ---- 更新选择后的数据
            func(self._selMaterialsList)
        end
    end
    self:WndClose()
end

function UIGolemItemUseAuto:GetCurCanUpExp(expValue)
    local golemInfo = self._golemInfo
    if not golemInfo then return end
    local golemExp = gModelGolem:GetGolemExpByGolemInfo(golemInfo)
    return golemExp + expValue
end

function UIGolemItemUseAuto:DisposeGolemItemList()
    local sortItemList = {}
    local recordItemNum = 0
    local refId,haveNum,useType
    local golemItemList = gModelItem:GetGolemExpItemList()
    for i,v in ipairs(golemItemList) do
        refId = v.refId
        haveNum = gModelItem:GetNumByRefId(refId)
        if haveNum > 0 then
            if gModelItem:CheckIsGolemExpRefId(refId) then
                useType = ModelGolem.TYPE_MATERIAL_ITEM
            else
                useType = ModelGolem.TYPE_MATERIAL_ITEMGOLEM
            end
            table.insert(sortItemList,{
                useType = useType,
                info = {
                    itemType = LItemTypeConst.TYPE_ITEM,
                    itemId = refId,
                    haveNum = haveNum,
                    conversionExp = v.conversionExp,
                    order = v.order,
                }
            })
            recordItemNum = recordItemNum + haveNum
        end
    end
    table.sort(sortItemList,function(a,b)
        return a.info.order < b.info.order
    end)
    self._sortItemList = sortItemList

    return recordItemNum
end

function UIGolemItemUseAuto:RefreshUseNumTxt(showNum)
    local useNum = self._useNum or 0
    showNum = showNum or useNum
    self:SetWndText(self.mValue,showNum)
end

function UIGolemItemUseAuto:OnClickGolemActStatusFunc(itemdata)
    local lvRef = itemdata.lvRef
    if not lvRef then
        GF.ShowMessage(ccClientText(34801))
        --- 找不到这个经验值了
        return
    end
    local needExp = lvRef.needExp
    local curGolemExp = itemdata.curGolemExp
    if curGolemExp > needExp then
        --- 当前魔偶已经超过这个经验了
        return
    end

    local lostExp = needExp - curGolemExp
    local useItemInfo = self:GetPayItemListByExp(lostExp)
    local isEnough = useItemInfo.isEnough
    if not isEnough then
        --- 道具不足
        GF.ShowMessage(ccClientText(34816))
        return
    end

    local useItemExp = useItemInfo.useItemExp
    if self:CheckIsMax(useItemExp,true) then return end

    self:CommonDisposeChange(useItemInfo)
end

function UIGolemItemUseAuto:CheckIsMax(expValue,toLvStatus)
    toLvStatus = toLvStatus or false
    if not self._golemMaxLvInfo then return false end

    local golemInfo = self._golemInfo
    if not golemInfo then return true end

    if self:CheckGolemIsMaxLv() then
        GF.ShowMessage(ccClientText(33262))
        return true
    end

    local newExp = self:GetCurCanUpExp(expValue)
    local maxLvNeedExp = self:GetMaxLvNeedExp()

    if not newExp or not maxLvNeedExp then return false end

    if newExp > maxLvNeedExp and not toLvStatus then return true end

    return false
end

function UIGolemItemUseAuto:ChangeNum(addNum,isAddBtn)
    self:ChangeSelType()
    local useItemInfo = self:GetPayItemListByNum(addNum)
    local useItemExp = useItemInfo.useItemExp
    if self:CheckIsMax(useItemExp,isAddBtn) then
        self:UpdateSlider()
        return false
    end
    self:CommonDisposeChange(useItemInfo)
    self:UpdateSlider()
    return true
end

function UIGolemItemUseAuto:InitGolemActStatusList()
    local list = self:GetGolemActStatusList()
    local uiGolemActStatusList = self._uiGolemActStatusList
    if uiGolemActStatusList then
        uiGolemActStatusList:RefreshList(list)
    else
        uiGolemActStatusList = self:GetUIScroll("uiGolemActStatusList")
        self._uiGolemActStatusList = uiGolemActStatusList
        uiGolemActStatusList:Create(self.mGolemActStatusList,list,function(...) self:OnDrawGolemActStatusCell(...) end)
    end
end

function UIGolemItemUseAuto:CheckGolemIsMaxLv()
    if not self._golemMaxLvInfo then return false end

    local golemInfo = self._golemInfo
    if not golemInfo then return true end

    local level = self._golemMaxLvInfo.level
    local golemLvl = gModelGolem:GetGolemLvlByGolemInfo(golemInfo)
    return level == golemLvl
end

function UIGolemItemUseAuto:RefreshIntensifyDiv()
    self:ChangeSlider()
    self:InitGolemActStatusList()
end

function UIGolemItemUseAuto:ChangeSelType()
    if self._selType == UIGolemItemUseAuto.TYPE_SEL_0 then
        self._selType = UIGolemItemUseAuto.TYPE_SEL_1
    end
end

function UIGolemItemUseAuto:DisposeGolemList()
    local sortGolemList = {}
    local useType
    local recordGolemNum = 0
    local serverData
    --- 这个传进来时已经排序好了，不需要再次排序
    local materialsList = self:GetWndArg("materialsList") or {}
    for i,v in ipairs(materialsList) do
        useType = v.useType
        if useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            serverData = v.info.serverData
            if not serverData.isLock then
                table.insert(sortGolemList,{
                    useType = useType,
                    info = {
                        serverData = serverData,
                    },
                })
                recordGolemNum = recordGolemNum + 1
            end
        end
    end
    self._sortGolemList = sortGolemList
    return recordGolemNum
end

function UIGolemItemUseAuto:RefreshSlider()
    self._sliderComponent.minValue = 0
    self._sliderComponent.maxValue = self._haveNum
end

function UIGolemItemUseAuto:InitSlider()
    self._sliderComponent = self.mSlider:GetComponent(typeUISlider)
    if (not self._sliderComponent) then
        self._sliderComponent = self.mSlider:AddComponent(typeUISlider)
    end

    LxUiHelper.SetProgress_ValueChanged(self.mSlider, function()
        self:ChangeSelType()
        if self:CheckGolemIsMaxLv() then
            self:UpdateSlider()
            GF.ShowMessage(ccClientText(33262))
        else
            local value = self._sliderComponent.value
            value = math.floor(value)
            if not self:ChangeNum(value) then
                local maxLvNeedExp = self:GetMaxLvNeedExp()
                local exp = gModelGolem:GetGolemExpByGolemInfo(self._golemInfo)
                if maxLvNeedExp and exp then
                    local lostExp = maxLvNeedExp - exp
                    local useItemInfo = self:GetPayItemListByExp(lostExp)
                    self:CommonDisposeChange(useItemInfo)
                    self:UpdateSlider()
                end
            end
        end
    end)

    self:RefreshSlider()
end

function UIGolemItemUseAuto:PackageSelMaterialsList(expList)
    expList = expList or {}
    local useType,info
    local selMaterialsList = {}
    for i,v in ipairs(expList) do
        useType = v.useType
        info = v.info
        if useType == ModelGolem.TYPE_MATERIAL_ITEM then
            if info.useNum and info.useNum > 0 then
                table.insert(selMaterialsList,{
                    useType = useType,
                    info = {
                        itemId = info.itemId,
                        useNum = info.useNum,
                    }
                })
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_ITEMGOLEM then
            if info.useNum and info.useNum > 0 then
                table.insert(selMaterialsList,{
                    useType = useType,
                    info = {
                        itemId = info.itemId,
                        useNum = info.useNum,
                    }
                })
            end
        elseif useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            table.insert(selMaterialsList,{
                useType = useType,
                info = info
            })
        end
    end
    self._selMaterialsList = selMaterialsList
end

------------------------- List -------------------------

function UIGolemItemUseAuto:GetGolemActStatusList()
    local golemInfo = self._golemInfo
    if not golemInfo then return {} end
    local list = {}
    local intensifyLv,faceLv
    local configList = gModelGolem:GetGolemActItemUseList(golemInfo)
    local exp = gModelGolem:GetGolemExpByGolemInfo(golemInfo)
    local lvrGroupId = gModelGolem:GetGolemElementLvrGroupIdByGolemInfo(golemInfo)

    local itemUpExp =  self._useItemExp

    for i,v in ipairs(configList) do
        intensifyLv = v.intensifyLv
        faceLv = intensifyLv - 1
        table.insert(list,{
            intensifyLv = intensifyLv,
            lvRef = gModelGolem:GetGolemLvInfoByLvrGroupIdAndLv(lvrGroupId,faceLv),
            curGolemExp = exp,
            itemUpExp = itemUpExp,
            nowGolemExp = itemUpExp + exp,
        })
    end
    return list
end

function UIGolemItemUseAuto:RefreshGolemRoot()
    local serverData = self._golemInfo
    if not serverData then return end
    local displayHero
    if  serverData and gModelGolem:CheckGolemIsWearByGolemInfo(serverData) then
        local heroId = serverData.heroId
        displayHero = gModelHero:GetHeroOutfitIconById(heroId)
    end
    local displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(serverData)
    local key = self.mGolemRoot:GetInstanceID()
    local baseClass = self:GetCommonIcon(key)
    baseClass:Create(self.mGolemRoot)
    ------- icon 表现函数
    baseClass:SetGolemData({
        refId = gModelGolem:GetGolemRefIdByGolemInfo(serverData),
        lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(serverData),
        lvl = gModelGolem:GetGolemLvlByGolemInfo(serverData),
        displayPos = displayPos,
        showGou = false,
        displayHero = displayHero,
        -- showPosIcon = showPos,
        -- showLock = isShowLock,
    })
    baseClass:DoApply()

    local golemName = gModelGolem:GetGolemElementNameByGolemInfo(serverData)
    self:SetWndText(self.mGolemName,golemName)
    self:SetWndText(self.mGolemNum,string.replace(ccClientText(33236),gModelItem:GetNumByRefId(serverData.refId)))
end

function UIGolemItemUseAuto:DisposeSelGolemAndItemList()
    local selMaterialsList = self:GetWndArg("selMaterialsList")

    local selNum = 0
    local useItemExp = 0
    local itemList = {}
    local selGolemNum,recordSelMaterials = gModelGolem:GetRecordSelMaterials(selMaterialsList)
    for useType,useInfoMap in pairs(recordSelMaterials) do
        if useType == ModelGolem.TYPE_MATERIAL_GOLEM then
            for golemId,golemInfo in pairs(useInfoMap) do
                table.insert(itemList,{
                    useType = useType,
                    info = {
                        golemInfo = golemInfo,
                    }
                })
                selNum = selNum + 1

                useItemExp = useItemExp + gModelGolem:GetMaterialsChangeToExp(useType,{
                    golemInfo = golemInfo,
                })
            end
        else
            for refId,useNum in pairs(useInfoMap) do
                if useNum > 0 then
                    table.insert(itemList,{
                        useType = useType,
                        info = {
                            itemId = refId,
                            useNum = useNum,
                        }
                    })
                    selNum = selNum + useNum

                    useItemExp = useItemExp + gModelGolem:GetMaterialsChangeToExp(useType,{
                        itemId = refId,
                        useNum = useNum,
                    })
                end
            end
        end
    end
    self._useItemExp = useItemExp
    self._useNum = selNum
    self:RefreshUseNumTxt(selNum)
end

function UIGolemItemUseAuto:GetPayItemListByExp(lostExp)
    local expValue = lostExp

    local expList = {}
    local recordUseNum = 0

    local useType
    local haveNum
    local loseNum,useNum,newAddExp
    local info,conversionExp,itemId
    local sortItemList = self:GetSortItemList()
    for i,v in ipairs(sortItemList) do
        if expValue < 1 then break end
        info = v.info
        haveNum = info.haveNum
        if haveNum > 0 then
            itemId = info.itemId
            conversionExp = info.conversionExp

            loseNum = math.floor(expValue / conversionExp)
            if loseNum > haveNum then
                useNum = haveNum
            else
                newAddExp = loseNum * conversionExp
                if expValue - newAddExp > 0 then
                    if loseNum + 1 <= haveNum then
                        loseNum = loseNum + 1
                    end
                end
                useNum = loseNum
            end
            recordUseNum = recordUseNum + useNum
            expValue = expValue - conversionExp * useNum
            table.insert(expList,{
                useType = v.useType,
                info = {
                    itemId = itemId,
                    useNum = useNum,
                }
            })
        end
    end

    if expValue > 0 then
        local golemInfo
        local sortGolemList = self:GetSortGolemList()
        for i,v in ipairs(sortGolemList) do
            if expValue < 1 then break end
            useType = v.useType
            info = v.info
            golemInfo = info.serverData
            conversionExp = gModelGolem:GetMaterialsChangeToExp(useType,{golemInfo = golemInfo})

            recordUseNum = recordUseNum + 1
            expValue = expValue - conversionExp
            table.insert(expList,{
                useType = useType,
                info = {
                    golemInfo = golemInfo,
                }
            })
        end
    end

    local isEnough = true
    if expValue > 0 then
        isEnough = false
    end

    return {
        useItemExp = self:GetAllExp(expList),
        isEnough = isEnough,
        expList = expList,
        recordUseNum = recordUseNum,
    }
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemItemUseAuto



