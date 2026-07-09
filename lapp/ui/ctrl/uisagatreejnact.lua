---
--- Created by LCM.
--- DateTime: 2024/3/28 11:10:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTreeJNAct:LWnd
local UISagaTreeJNAct = LxWndClass("UISagaTreeJNAct", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTreeJNAct:UISagaTreeJNAct()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTreeJNAct:OnWndClose()
    self:ClearCommonIconList(self._skillIconList)
    if self._callBackFunc then
        self._callBackFunc()
    end
    self._callBackFunc = nil
    gModelHero:ClearUpLvTreeSelHeroList()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTreeJNAct:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTreeJNAct:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UISagaTreeJNAct:GetColorStr(refId,num,itemType,selNum)
    local allNum
    if itemType == LItemTypeConst.TYPE_ITEM then
        allNum = gModelItem:GetNumByRefId(refId)
    else
        allNum = selNum
    end
    local color = "139057FF"
    if num > allNum then color = "c81212ff" end
    allNum = LUtil.NumberCoversion(allNum)
    num = LUtil.NumberCoversion(num)
    local str = string.replace(ccClientText(10065),color,allNum,num)
    return str
end

function UISagaTreeJNAct:OnDrawUpSkillPayNeedCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
    local NumTxtTrans = self:FindWndTrans(item,"NumTxt")
    local redPointTrans = self:FindWndTrans(item,"redPoint")

    local instanceId = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(IconTrans)
    local key = itemdata.key
    local needRefId = itemdata.needRefId
    local needStar = itemdata.needStar
    local needNum = itemdata.needNum
    local index = itemdata.index
    local selNum
    if key == "upItem" then
        selNum = gModelItem:GetNumByRefId(needRefId)
        baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, needRefId, needNum or 1)
        baseClass:ShowNeedNumStatus(true,true)
        self:SetWndClick(IconTrans,function()
            gModelGeneral:OpenGetWayWnd({itemId = needRefId,srcWnd = self:GetWndName()})
        end)
    else
        local awakenHeroTreeInfo = self._awakenHeroTreeInfo
        if key == "upSelf" then
            self._awakenUpSelfRedPointList[index] = redPointTrans
            local upSelfInfo = awakenHeroTreeInfo.upSelfInfo or {}
            local upSelfData = upSelfInfo[index] or {}
            local selHeroMap = upSelfData.selHeroMap or {}
            selNum = table.keysize(selHeroMap)
            baseClass:SetHeroDataSet({id = needRefId,refId = needRefId,star = needStar,level = 1,hideTree = true})
        elseif key == "upRange" then
            self._awakenUpRangeRedPointList[index] = redPointTrans
            local upRangeInfo = awakenHeroTreeInfo.upRangeInfo or {}
            local upRangeData = upRangeInfo[index] or {}
            local selHeroMap = upRangeData.selHeroMap or {}
            selNum = table.keysize(selHeroMap)
            local selItemMap = upRangeData.selItemMap or {}
            for tRefId,tNum in pairs(selItemMap) do
                selNum = selNum + tNum
            end
            baseClass:SetRaceData({id = needRefId,refId = needRefId,star = needStar,race = needRefId, needNum = needNum,num = selNum,hideTree = true})
        end
        local showMask = selNum ~= needNum
        baseClass:SetShowMaskOnly(showMask)
        baseClass:SetNoShowLv(true)

        self:SetWndClick(IconTrans,function()
            self:OnClickAwakenNeedHeroFunc(itemdata,NumTxtTrans,redPointTrans,baseClass)
        end)
    end
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local colorStr = self:GetColorStr(needRefId,needNum,itemdata.itemType,selNum)
    self:SetWndText(NumTxtTrans,colorStr)

    local showRedPoint = false
    if key ~= "upItem" then
        if selNum < needNum then
            local canSelHeroData = itemdata.canSelHeroData
            if canSelHeroData then
                local allSelHeroMap = self:GetAllSelHeroMap()
                local canSelNum = 0
                for k,v in pairs(canSelHeroData) do
                    if not allSelHeroMap[v._id] then
                        canSelNum = canSelNum + 1
                    end
                end
                showRedPoint = canSelNum >= needNum
            end
        end
    end
    CS.ShowObject(redPointTrans,showRedPoint)
end

function UISagaTreeJNAct:InitMsg()
    self:WndEventRecv(EventNames.On_Item_Change,function() self:RefreshView() end)


	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISagaTreeJNAct:CreateSkillIcon(itemdata)
    local skillIconList = self._skillIconList
    if not skillIconList then
        skillIconList = {}
        self._skillIconList = skillIconList
    end
    local skillId = itemdata.skillId
    local trans = self.mSkillRoot
    local skillIconTrans = self:FindWndTrans(trans,"SkillIcon")
    local InstanceID = skillIconTrans:GetInstanceID()
    local baseClass = skillIconList[InstanceID]
    if not baseClass then
        baseClass = SkillIcon:New(self)
        skillIconList[InstanceID] = baseClass
    end
    baseClass:SetSkillInfo(nil,false,nil,1)
    baseClass:ShowLvl(false)
    baseClass:ShowLock(false)
    baseClass:Create(skillIconTrans,skillId,function()
    end)
    baseClass:SetIconAndIconBgGray(false)

    local skillNameStr = ""
    local skillRef = gModelHero:GetSkillByStarId(skillId)
    if skillRef then
        skillNameStr = ccLngText(skillRef.name)
    end
    self:SetWndText(self.mSkillName,skillNameStr)
end

function UISagaTreeJNAct:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mUpSkillBtn,function() self:OnClickUpSkillBtnFunc() end)
end

function UISagaTreeJNAct:InitUpSkillPayNeedList()
    self._awakenUpSelfRedPointList = {}
    self._awakenUpRangeRedPointList = {}
    local list = self:GetUpSkillPayNeedList()
    local uiUpSkillPayNeedList = self._uiUpSkillPayNeedList
    if uiUpSkillPayNeedList then
        uiUpSkillPayNeedList:RefreshList(list)
    else
        uiUpSkillPayNeedList = self:GetUIScroll("uiUpSkillPayNeedList")
        self._uiUpSkillPayNeedList = uiUpSkillPayNeedList
        uiUpSkillPayNeedList:Create(self.mUpSkillPayNeedList,list,function(...) self:OnDrawUpSkillPayNeedCell(...) end)
    end
    local enable = #list > 3
    uiUpSkillPayNeedList:EnableScroll(enable,true)
end

function UISagaTreeJNAct:OnHeroTreeActiveExtraSkillResp()
    self:WndClose()
end

function UISagaTreeJNAct:InitData()
    local heroServerData = self:GetWndArg("heroServerData")
    self._heroServerData = heroServerData
    self._awakenTreePointId = self:GetWndArg("awakenTreePointId")
    self._extraSkillId = self:GetWndArg("extraSkillId")
    self._extraSkillCostId = self:GetWndArg("extraSkillCostId")
    self._extraSkillCostIdIndex = self:GetWndArg("extraSkillCostIdIndex")
    self._callBackFunc = self:GetWndArg("callBackFunc")

    self._heroId = heroServerData and heroServerData.id
    self._skillIconList = {}
    self._awakenHeroTreeInfo = {}

    if self._heroId then
        local heroTreeInfoList = gModelHero:GetServerHeroTreeInfoByHeroId(self._heroId)
        self._heroTreeInfoList = heroTreeInfoList
    end
end

function UISagaTreeJNAct:GetCommonUpAwankenItemInfo()
    local heroId = self._heroId
    if not heroId then return end

    local treePointRefId = self._awakenTreePointId
    if not treePointRefId then
        printInfoNR("self._awakenTreePointId is a nil")
        return
    end

    local awakenHeroTreeInfo = self._awakenHeroTreeInfo
    if table.isempty(awakenHeroTreeInfo) then
        GF.ShowMessage(ccClientText(14425))
        return
    end

    local appointedlist = {}
    local upSelfInfo = awakenHeroTreeInfo.upSelfInfo
    if upSelfInfo then
        local config,selHeroMap,needNum
        for i,v in ipairs(upSelfInfo) do
            config = v.config
            local selNum = 0
            selHeroMap = v.selHeroMap
            local selInfoMap = {}
            for key,val in pairs(selHeroMap) do
                selNum = selNum + 1
                selInfoMap[key] = key
            end
            needNum = config.needNum

            if selNum < needNum then
                GF.ShowMessage(ccClientText(10054))
                return
            end
            appointedlist[i] = selInfoMap
        end
    end

    local rangelist = {}
    local rangItemList = {}
    local upRangeInfo = awakenHeroTreeInfo.upRangeInfo
    if upRangeInfo then
        local selHeroMap,selItemMap
        local config,needNum
        for i,v in ipairs(upRangeInfo) do
            selHeroMap = v.selHeroMap or {}
            local selNum = 0
            local selHeroInfoMap = {}
            for key,val in pairs(selHeroMap) do
                selNum = selNum + 1
                selHeroInfoMap[key] = key
            end
            local selItemInfoMap = {}
            selItemMap = v.selItemMap or {}
            for refId,num in pairs(selItemMap) do
                if num > 0 then
                    selNum = selNum + num
                    selItemInfoMap[refId] = num
                end
            end
            config = v.config
            needNum = config.needNum

            if selNum < needNum then
                GF.ShowMessage(ccClientText(10054))
                return
            end
            rangelist[i] = selHeroInfoMap
            rangItemList[i] = selItemInfoMap
        end
    end

    local upItemInfo = awakenHeroTreeInfo.upItemInfo
    if upItemInfo then
        local config,itemId,itemNum,haveNum
        for i,v in ipairs(upItemInfo) do
            config = v.config
            if not config then return end
            itemId = config.itemId
            itemNum = config.itemNum
            haveNum = gModelItem:GetNumByRefId(itemId)
            if haveNum < itemNum then
                gModelGeneral:OpenGetWayWnd({itemId = itemId})
                return
            end
        end
    end

    return {
        appointedlist = appointedlist,
        rangelist = rangelist,
        rangItemList = rangItemList,
    }
end

function UISagaTreeJNAct:OnClickUpSkillBtnFunc()
    local extraSkillCostId = self._extraSkillCostId
    if not extraSkillCostId then return end

    local heroId = self._heroId
    if not heroId then return end

    local awakenTreePointId = self._awakenTreePointId
    if not awakenTreePointId then
        printInfoNR("self._awakenTreePointId is a nil")
        return
    end

    local info = self:GetCommonUpAwankenItemInfo()
    if not info then return end

    local list = {
        heroId = heroId,
        pointRefId = awakenTreePointId,
        extraSkillCostRefId = extraSkillCostId,
        appointedList = info.appointedlist or {},
        rangeList = info.rangelist or {},
        rangItemList = info.rangItemList or {},
    }
    gModelHeroExtra:OnHeroTreeActiveExtraSkillReq(list)
end
------------------------- List -------------------------


function UISagaTreeJNAct:GetSkillLvList()
    local awakenTreePointId = self._awakenTreePointId
    if not awakenTreePointId then return {} end

    local extraSkillCostIdIndex = self._extraSkillCostIdIndex
    if not extraSkillCostIdIndex then return {} end

    local typeList = gModelHero:GetHeroTreePointLvList(awakenTreePointId)
    if not typeList then return {} end

    local skillLvList = {}
    local refId,ref,skillInfo,extraSkill
    local lvList = typeList.lvList
    for i,v in ipairs(lvList) do
        refId = v.refId
        ref = gModelHero:GetHeroTreePointLvRef(refId)
        if ref then
            skillInfo = gModelHeroExtra:GetHeroTreeSkillList(ref)
            extraSkill = skillInfo.extraSkill or {}
            local skillId = extraSkill[extraSkillCostIdIndex]
            if skillId then
                local skillRef = gModelHero:GetSkillByStarId(skillId)
                if skillRef then
                    table.insert(skillLvList,{
                        skillId = skillId,
                        level = skillRef.level,
                        description = ccLngText(skillRef.description),
                    })
                end
            end
        end
    end
    return skillLvList
end

function UISagaTreeJNAct:GetAllSelHeroMap()
    if not self._awakenHeroTreeInfo then return {} end
    local map = {}
    local upSelfInfo = self._awakenHeroTreeInfo.upSelfInfo or {}
    for idx,val in ipairs(upSelfInfo) do
        for k,v in pairs(val.selHeroMap) do
            map[k] = v
        end
    end
    local upRangeInfo = self._awakenHeroTreeInfo.upRangeInfo or {}
    for idx,val in ipairs(upRangeInfo) do
        for k,v in pairs(val.selHeroMap) do
            map[k] = v
        end
    end
    return map
end

function UISagaTreeJNAct:GetUpSkillPayNeedList()
    self._awakenHeroTreeInfo = {}
    gModelHero:ClearUpLvTreeSelHeroList()

    self._awakenHeroTreeInfo.upSelfInfo = {}
    self._awakenHeroTreeInfo.upRangeInfo = {}
    self._awakenHeroTreeInfo.upRangeItemInfo = {}
    self._awakenHeroTreeInfo.upItemInfo = {}

    local heroServerData = self._heroServerData
    if not heroServerData then return {} end

    local extraSkillCostId = self._extraSkillCostId
    if not extraSkillCostId then return {} end

    local extraSkillCostRef = gModelHeroExtra:GetHeroExtraSkillCostRefByRefId(extraSkillCostId)
    if not extraSkillCostRef then return {} end

    local fuse = false
    local itemDataList = {[1] = {},[2] = {},[3] = {}}
    local fuse1,fuse2,fuse3 = false,false,false
    local upSelf,upRange,upItem = extraSkillCostRef.upSelf,extraSkillCostRef.upRange,extraSkillCostRef.upItem
    local heroTreeActNeedItemInfo = gModelHeroExtra:GetHeroTreeActNeedItemListByConfig(upSelf,upRange,upItem,heroServerData)
    local upSelfInfo = heroTreeActNeedItemInfo.upSelfInfo

    if upSelfInfo then
        local itemDataInfo = {}
        local configList = upSelfInfo.configList
        local selList = upSelfInfo.selList
        local infoList = {}
        local needNum
        for i,v in ipairs(configList) do
            local dataList = selList[i] or {}
            -- 自动填充
            local selHeroMap = {}
            local autoSelId
            local sortSelList = gModelHero:SortFillHeroList(dataList)
            if #sortSelList > 0 then
                needNum = v.needNum
                for selIdx,selHeroData in ipairs(sortSelList) do
                    if selIdx > needNum then break end
                    autoSelId = selHeroData._id
                    selHeroMap[autoSelId] = autoSelId
                    gModelHero:SetUpLvTreeSelHeroId(autoSelId)
                end
            end
            table.insert(infoList,{
                selHeroMap = selHeroMap,
                config = v,
            })

            table.insert(itemDataInfo,{
                key = "upSelf",
                config = v,
                canSelHeroData = dataList,
            })
        end
        itemDataList[1] = itemDataInfo
        self._awakenHeroTreeInfo.upSelfInfo = infoList
        fuse1 = upSelfInfo.fuse
    end

    local upRangeInfo = heroTreeActNeedItemInfo.upRangeInfo
    if upRangeInfo then
        local itemDataInfo = {}
        local configList = upRangeInfo.configList
        local selList = upRangeInfo.selList
        local infoList = {}
        local needNum
        local needStar
        for i,v in ipairs(configList) do
            needStar = v.needStar
            local selHeroMap = {}
            local dataList = selList[i] or {}
            if needStar <= ModelHero.AUTO_FILL_STAR then
                -- 自动填充
                local autoSelId
                local sortSelList = gModelHero:SortFillHeroList(dataList)
                if #sortSelList > 0 then
                    needNum = v.needNum
                    for selIdx,selHeroData in ipairs(sortSelList) do
                        if selIdx > needNum then break end
                        autoSelId = selHeroData._id
                        selHeroMap[autoSelId] = autoSelId
                        gModelHero:SetUpLvTreeSelHeroId(autoSelId)
                    end
                end
            end
            table.insert(infoList,{
                selHeroMap = selHeroMap,
                selItemMap = {},
                config = v,
            })

            table.insert(itemDataInfo,{
                key = "upRange",
                config = v,
                canSelHeroData = dataList,
            })
        end
        itemDataList[2] = itemDataInfo
        self._awakenHeroTreeInfo.upRangeInfo = infoList
        fuse2 = upRangeInfo.fuse
    end

    local upItemInfo = heroTreeActNeedItemInfo.upItemInfo
    if upItemInfo then
        local itemDataInfo = {}
        local configList = upItemInfo.configList
        local selList = upItemInfo.selList
        local infoList = {}
        for i,v in ipairs(configList) do
            table.insert(infoList,{
                selHeroMap = selList[i],
                config = v,
            })

            table.insert(itemDataInfo,{
                key = "upItem",
                config = v,
            })
        end
        itemDataList[3] = itemDataInfo
        self._awakenHeroTreeInfo.upItemInfo = infoList
        fuse3 = upItemInfo.fuse
    end

    fuse = fuse1 and fuse2 and fuse3

    local list = {}
    for i,v in ipairs(itemDataList) do
        for idx,val in ipairs(v) do
            local config = val.config
            table.insert(list,{
                itemType = config.itemType,
                needRefId = config.needRefId,
                needStar = config.needStar,
                needNum = config.needNum,
                canCompound = config.canCompound,
                key = val.key,
                canSelHeroData = val.canSelHeroData,
                index = idx,
            })
        end
    end
    return list
end

function UISagaTreeJNAct:RefreshView()
    self:InitSkillLvList()
    self:InitUpSkillPayNeedList()
end

function UISagaTreeJNAct:InitSkillLvList()
    local list = self:GetSkillLvList()
    local uiSkillLvList = self._uiSkillLvList
    if uiSkillLvList then
        uiSkillLvList:RefreshList(list)
    else
        uiSkillLvList = self:GetUIScroll("uiSkillLvList")
        self._uiSkillLvList = uiSkillLvList
        uiSkillLvList:Create(self.mSkillLvList,list,function(...) self:OnDrawSkillLvCell(...) end)
    end
    if #list > 0 then
        if not self._curSkillLv then
            local first = list[1]
            self:OnClickSkillLvFunc(first)
        end
    end
end

function UISagaTreeJNAct:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(37615))
    self:SetWndText(self.mTitleText,ccClientText(37609))
    self:SetWndButtonText(self.mUpSkillBtn,ccClientText(37607))
    self:SetWndText(self.mIntro,ccClientText(37618))
end

function UISagaTreeJNAct:OnDrawSkillLvCell(list,item,itemdata,itempos)
    local SelImgTrans = self:FindWndTrans(item,"SelImg")
    local SkillLvTxtTrans = self:FindWndTrans(item,"SkillLvTxt")
    local BtnTrans = self:FindWndTrans(item,"Btn")

    local level = itemdata.level
    self:SetWndText(SkillLvTxtTrans,level)

    local isSel = self._curSkillLv and self._curSkillLv == level
    CS.ShowObject(SelImgTrans,isSel)

    self:SetWndClick(BtnTrans,function()
        self:OnClickSkillLvFunc(itemdata)
    end)
end

function UISagaTreeJNAct:OnClickAwakenNeedHeroFunc(itemdata,NumTxtTrans,redPointTrans,baesClass)
    local tab = {}
    local needRefId = itemdata.needRefId
    local needStar = itemdata.needStar
    local needNum = itemdata.needNum
    local index = itemdata.index
    local key = itemdata.key
    local selHeorId = self._heroId
    local itype = LItemTypeConst.TYPE_HERO
    local noHeightQualityTipRefId = 10020
    local heightQualityTipRefId = 10019
    if key == "upSelf" then
        tab = {
            refId = needRefId,num = needNum,star = needStar,race = -1,selHeorId = selHeorId,selHeroList = self._awakenHeroTreeInfo.upSelfInfo[index].selHeroMap or {},
            noHeightQualityTipRefId = noHeightQualityTipRefId,heightQualityTipRefId = heightQualityTipRefId,selectType = 2,showRaceDiv = true,
            func = function(appointList)
                if not self:IsWndValid() then return end
                local selNum = table.keysize(appointList)
                if not table.isempty(appointList) then
                    local tempList = {}
                    self._awakenHeroTreeInfo.upSelfInfo[index].selHeroMap = tempList
                    for _k,_v in pairs(appointList) do tempList[_v] = _v end
                else
                    self._awakenHeroTreeInfo.upSelfInfo[index].selHeroMap = appointList
                end
                if NumTxtTrans then
                    local colorStr = self:GetColorStr(needRefId,needNum,itype,selNum)
                    self:SetWndText(NumTxtTrans,colorStr)
                end
                baesClass:ShowMaskOnly(selNum ~= needNum)
                local awakenUpRangeRedPointList = self._awakenUpRangeRedPointList
                if awakenUpRangeRedPointList then
                    local tConfig,tNeedRefId,tNeedStar,tNeedNum,tSelHeroMap,tSelHeroNum
                    local upRangeInfo = self._awakenHeroTreeInfo.upRangeInfo
                    for i,v in ipairs(upRangeInfo) do
                        tConfig = v.config
                        tNeedStar = tConfig.needStar
                        if tNeedStar == needStar then
                            tNeedNum = tConfig.needNum
                            tSelHeroMap = v.selHeroMap
                            tSelHeroNum = table.keysize(tSelHeroMap)
                            if tSelHeroNum < tNeedNum then
                                tNeedRefId = tConfig.needRefId
                                local dataList = gModelHero:AwakenFilterHero(tNeedRefId,tNeedStar,tNeedRefId,selHeorId,{})
                                local len = table.keysize(dataList)
                                local showRedPoint = len >= tNeedNum
                                local tRedPointTrans = awakenUpRangeRedPointList[i]
                                CS.ShowObject(tRedPointTrans,showRedPoint)
                            end
                        end
                    end
                end
                if redPointTrans then
                    local showRed = selNum < needNum
                    if showRed then
                        local dataList = gModelHero:AwakenFilterHero(needRefId,needStar,nil,selHeorId,{})
                        local tempLen = table.keysize(dataList)
                        local tempNum = needNum - selNum
                        showRed = tempLen >= tempNum
                    end
                    CS.ShowObject(redPointTrans,showRed)
                end
            end
        }
    else
        tab = {
            refId = needRefId,num = needNum,star = needStar,race = needRefId,selHeorId = selHeorId,selHeroList = self._awakenHeroTreeInfo.upRangeInfo[index].selHeroMap or {},
            selItemList = table.clone(self._awakenHeroTreeInfo.upRangeInfo[index].selItemMap or {}),noHeightQualityTipRefId = noHeightQualityTipRefId,heightQualityTipRefId = heightQualityTipRefId,
            selectType = 2,showRaceDiv = true,
            func = function(rangList,rangItemList)
                if not self:IsWndValid() then return end
                self._awakenHeroTreeInfo.upRangeInfo[index].selItemMap = {}
                local selNum = 0
                for k,v in pairs(rangItemList) do
                    if v > 0 then
                        self._awakenHeroTreeInfo.upRangeInfo[index].selItemMap[k] = v
                        selNum = selNum + v
                    end
                end
                local tempList = {}
                local rangeNum = 0
                rangList = rangList or {}
                for _k,_v in pairs(rangList) do
                    tempList[_v] = _v
                    rangeNum = rangeNum + 1
                end
                selNum = selNum + rangeNum
                self._awakenHeroTreeInfo.upRangeInfo[index].selHeroMap = tempList
                if NumTxtTrans then
                    local colorStr = self:GetColorStr(needRefId,needNum,itype,selNum)
                    self:SetWndText(NumTxtTrans,colorStr)
                end
                baesClass:ShowMaskOnly(selNum ~= needNum)
                local awakenUpSelfRedPointList = self._awakenUpSelfRedPointList
                if awakenUpSelfRedPointList then
                    local tConfig,tNeedRefId,tNeedStar,tNeedNum,tSelHeroMap,tSelHeroNum
                    local upSelfInfo = self._awakenHeroTreeInfo.upSelfInfo
                    for i,v in ipairs(upSelfInfo) do
                        tConfig = v.config
                        tNeedStar = tConfig.needStar
                        if tNeedStar == needStar then
                            tNeedNum = tConfig.needNum
                            tSelHeroMap = v.selHeroMap
                            tSelHeroNum = table.keysize(tSelHeroMap)
                            if tSelHeroNum < tNeedNum then
                                tNeedRefId = tConfig.needRefId
                                local dataList = gModelHero:AwakenFilterHero(tNeedRefId,tNeedStar,nil,selHeorId,{})
                                local len = table.keysize(dataList)
                                local showRedPoint = len >= tNeedNum
                                local tRedPointTrans = awakenUpSelfRedPointList[i]
                                CS.ShowObject(tRedPointTrans,showRedPoint)
                            end
                        end
                    end
                end
                if redPointTrans then
                    local redShow = selNum < needNum
                    if redShow then
                        local dataList = gModelHero:AwakenFilterHero(needRefId,needStar,needRefId,selHeorId,{})
                        local len = 0
                        local allSelHeroMap = self:GetAllSelHeroMap()
                        for k,v in pairs(dataList) do
                            if not allSelHeroMap[k] then
                                len = len + 1
                            end
                        end
                        local tempNum = needNum - selNum
                        redShow = len >= tempNum
                    end
                    CS.ShowObject(redPointTrans,redShow)
                end
            end
        }
    end
    GF.OpenWnd("UISagaSelect",tab)
end

function UISagaTreeJNAct:OnClickSkillLvFunc(itemdata)
    local level = itemdata.level
    if self._curSkillLv == level then return end
    self._curSkillLv = level
    local description = itemdata.description
    description = string.gsub(description, "30e005", "139057")
    self:SetWndText(self.mSkillDesc,description)
    self:CreateSkillIcon(itemdata)
    self:InitSkillLvList()
end


------------------------- List -------------------------

------------------------------------------------------------------
return UISagaTreeJNAct



