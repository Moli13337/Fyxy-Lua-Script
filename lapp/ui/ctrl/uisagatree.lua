---
--- Created by LCM.
--- DateTime: 2024/3/22 15:52:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaTree:LWnd
local UISagaTree = LxWndClass("UISagaTree", LWnd)

local UIHeroTreeRoot = LXImport('LApp.UI.Common.UIHeroTreeRoot')
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaTree:UISagaTree()
    self._tryHeroTimeKey = "_tryHeroTimeKey"

    ---@type UIHeroTreeRoot
    self._uiHeroTreeRoot = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaTree:OnWndClose()
    gModelHero:ClearUpLvTreeSelHeroList()
    if self._uiHeroTreeRoot then
        self._uiHeroTreeRoot:Destroy()
        self._uiHeroTreeRoot = nil
    end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaTree:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaTree:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:InitStaticData()
    self:RefreshView()

end


function UISagaTree:SetHeroTreePointInfo(treeTrans)
    local heroTreeInfoList	= self._heroTreeInfoList
    if not heroTreeInfoList then return end

    if not self._uiHeroTreeRoot then
        self._uiHeroTreeRoot = UIHeroTreeRoot:New()
    end
    self._uiHeroTreeRoot:SetInfo(self,treeTrans,gModelHero:GetHeroById(self._heroId))
end

function UISagaTree:OnDrawAwakenNeedItemCell(list,item,itemdata,itempos)
    local RootTrans = self:FindWndTrans(item,"CommonUI/Root")
    local NumTxtTrans = self:FindWndTrans(item,"NumTxt")
    local redPointTrans = self:FindWndTrans(item,"redPoint")

    local instanceId = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(RootTrans)
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
        self:SetWndClick(RootTrans,function()
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

        self:SetWndClick(RootTrans,function()
            self:OnClickAwakenNeedHeroFunc(itemdata,NumTxtTrans,redPointTrans,baseClass)
        end)
    end
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local colorStr = self:GetColorStr(needRefId,needNum,itemdata.itemType,selNum)
    self:SetWndText(NumTxtTrans,colorStr)

    local showRedPoint = false
    if not self._isLimitUpLv then
        if key ~= "upItem" then
            if selNum < needNum then
                local canSelHeroData = itemdata.canSelHeroData
                if canSelHeroData then
                    local canSelNum = table.keysize(canSelHeroData)
                    if key == "upRange" then
                        local dataList,yinghunItemList = gModelHero:AwakenFilterHero(needRefId,needStar,needRefId,self._heroId,{})
                        canSelNum = canSelNum + table.keysize(yinghunItemList)
                    end
                    showRedPoint = canSelNum >= needNum
                end
            end
        end
    end
    CS.ShowObject(redPointTrans,showRedPoint)
end

function UISagaTree:ShowPrepositionPointEff(isShow, treePointRefId)
    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then return end

    local isShowEff = isShow
    if isShowEff then
        isShowEff = false
        if not heroTreePointInfo.isActivate then
            if not heroTreePointInfo.canActivate and heroTreePointInfo.needConType == ModelHero.TREE_CON_TYPE_LVL then
                isShowEff = true
            end
        end
    end

    local ref = gModelHero:GetHeroTreePointRef(treePointRefId)
    if not ref then
        printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = "..treePointRefId)
        return
    end

    local front = ref.front
    if not front or front <= 0 then return end

    local treePointTransList = self._awakenTreeTransList[self._treePbName]
    local frontPointInfo = treePointTransList[front]
    if not frontPointInfo then return end

    local frontHeroTreePointInfo = self._heroTreeInfoList[front]
    if not frontHeroTreePointInfo then return end

    local pointTrans = frontPointInfo.pointTrans
    local pointType = frontHeroTreePointInfo.pointType
    local effName = pointType == ModelHero.TREE_POINT_TYPE_ATTR and "ui_yingxiongjuexing_qianzhi" or "ui_yingxiongjuexing_qianzhi_2"
    self:SetAwakenPointEffShow(isShowEff, effName, pointTrans)
end

function UISagaTree:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroTreeResetResp,function(pb) self:OnHeroTreeResetResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.HeroTreePointActiveResp,function(pb) self:OnHeroTreePointUpLvResp(pb) end)
	 self:WndEventRecv(EventNames.On_Item_Change,function() self:OnItemChange() end)
	 self:WndEventRecv(EventNames.ON_HEROTREE_CHANGESEL,function() self:RefreshHeroTreeDataShow() end)
    self:WndNetMsgRecv(LProtoIds.HeroTreePointSelectSkillResp,function(pb) self:OnHeroTreePointSelectSkillResp(pb) end)
end

function UISagaTree:InitStaticData()
    --local actAwakenHeroList = gModelHero:GetActivateHeroList()
    --self._actAwakenHeroList = actAwakenHeroList
    local isShowCutHeroBtn = #self._cutHeroList > 1
    CS.ShowObject(self.mLeftBtn,isShowCutHeroBtn)
    CS.ShowObject(self.mRightBtn,isShowCutHeroBtn)


    self._awakenTreeList = {}
    self._awakenTreeTransList = {}
end

function UISagaTree:OnHeroTreePointSelectSkillResp()
    self._curSelectTreePointId = self._uiHeroTreeRoot:GetCurSelTreeRefId()
    self:InitHeroTreeInfoList()
    self._uiHeroTreeRoot:RefreshHeroSkillShow()
    self:RefreshAwakenDetails()
end

function UISagaTree:InitText()
    self:SetWndButtonText(self.mUpAwakenBtn,ccClientText(37606))
    self:SetWndButtonText(self.mActAwakenBtn,ccClientText(37600))
    self:SetTextTile(self.mAwakenSkillPreBtn,ccClientText(37604))
    self:SetTextTile(self.mAwakenResetBtn,ccClientText(37605))
    self:SetWndText(self.mReturnBtnTxt,ccClientText(30205))
    self:SetTextTile(self.mNewItemIcon,ccClientText(20182))
    self:SetWndText(self.mAwakenTitle,ccClientText(20138))
end

function UISagaTree:OnClickHeroAwakenSkillBtnFunc(itemdata)
    local isPointAct = itemdata.isPointAct
    if not isPointAct then
        GF.ShowMessage(ccClientText(37601))
        return
    end
    local heroServerData = self._heroServerData
    if not heroServerData then return end

    gModelHero:ClearUpLvTreeSelHeroList()
    gModelHeroExtra:OpenHeroTreeSkillActWnd({
        heroServerData = heroServerData,
        awakenTreePointId = itemdata.curSelTreePointId,
        extraSkillId = itemdata.skillId,
        extraSkillCostId = itemdata.extraSkillCostId,
        extraSkillCostIdIndex = itemdata.extraSkillCostIdIndex,
        callBackFunc = function()
            self:RefreshAwakenDetails()
        end,
    })
end

function UISagaTree:OnClickAwakenNeedHeroFunc(itemdata,NumTxtTrans,redPointTrans,baesClass)
    local tab = {}
    --- 是否限制点击
    tab.isLimitClick = self._isLimitClick
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
                if redPointTrans then
                    local redShow = selNum ~= needNum
                    if redShow then
                        local dataList,yinghunItemList = gModelHero:AwakenFilterHero(needRefId,needStar,needRefId,selHeorId,{})
                        local len = table.keysize(dataList) + table.keysize(yinghunItemList)
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

function UISagaTree:SetAwakenPointEffShow(isShow, effName, pointTrans)
    local InstanceID = pointTrans:GetInstanceID()
    local effKey = effName..InstanceID
    if isShow then
        self:CreateWndEffect(pointTrans,effName,effKey,100,false,false, 26)
    else
        self:DestroyWndEffectByKey(effKey)
    end
end

function UISagaTree:OnHeroTreeResetResp(pb)
    self:RefreshServerData()
end

function UISagaTree:InitHeroServerData()
    self._heroServerData = nil
    self._isTryHero = false
    if not self._heroId then return end

    local heroServerData = gModelHero:GetHeroServerDataById(self._heroId)
    self._heroServerData = heroServerData
    self._isTryHero = heroServerData.isTry
    self._heroEndTime = heroServerData.endTime
end

function UISagaTree:GetCommonUpAwankenItemInfo()
    local heroId = self._heroId
    if not heroId then return end

    local treePointRefId = self._curSelectTreePointId
    if not treePointRefId then
        printInfoNR("self._curSelectTreePointId is a nil")
        return
    end

    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        printInfoNR("self._heroTreeInfoList[treePointRefId] is a nil, treePointRefId = "..treePointRefId)
        return
    end

    local canLvlUp = heroTreePointInfo.canLvlUp
    local needCon = heroTreePointInfo.needCon
    if not canLvlUp and needCon then
        local limitStar = ""
        local upLvlConType	= heroTreePointInfo.upLvlNeedConType
        local upLvlCondition= heroTreePointInfo.upLvlNeedActivateCon
        if upLvlConType == ModelHero.TREE_LV_CON_TYPE_LVL then
            limitStar = string.replace(ccClientText(20143), upLvlCondition)
        elseif upLvlConType == ModelHero.TREE_LV_CON_TYPE_STAR then
            limitStar = string.replace(ccClientText(20146), upLvlCondition)
        elseif upLvlConType == ModelHero.TREE_LV_CON_TYPE_RESONANCE then
            limitStar = string.replace(ccClientText(20153), upLvlCondition)
        end
        GF.ShowMessage(limitStar)
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


function UISagaTree:OnHeroTreePointUpLvResp(pb)
    if pb.heroId ~= self._heroId then return end

    self:RefreshServerData()

    if not self._heroTreeInfoList then return end

    local pointRefId = pb.pointRefId
    local heroTreePointInfo = self._heroTreeInfoList[pointRefId]
    if not heroTreePointInfo then return end

    local pointType = heroTreePointInfo.pointType
    if pointType ~= ModelHero.TREE_POINT_TYPE_SKILL then return end

    local lvRefId = heroTreePointInfo.lvRefId
    if lvRefId and lvRefId > 0 then
        gModelHeroExtra:OpenHeroTreeSkillLvUpWnd({
            heroId = self._heroId,
            actLvRefId = lvRefId,
            pointRefId = pointRefId,
        })
    end

end

function UISagaTree:RefreshHeroTreeTransShow()
    local awakenTreeList = self._awakenTreeList
    if not awakenTreeList then return end
    local treePbName = self._treePbName
    for k,v in pairs(awakenTreeList) do
        CS.ShowObject(v,k == treePbName)
    end
end
------------------------- List -------------------------

------------------- 属性
function UISagaTree:InitAwakenAttrList(list)
    --local isChinese = gLGameLanguage:IsChineseVersion()
    local isChinese = true
    local attrListTrans = isChinese and self.mAwakenAttrList or self.mAwakenEnAttrList
    local hideAttrListTrans = isChinese and self.mAwakenEnAttrList or self.mAwakenAttrList
    --调整成为使用同一个list
    CS.ShowObject(attrListTrans,true)
    CS.ShowObject(hideAttrListTrans,false)
    local uiAwakenAttrList = self._uiAwakenAttrList
    if uiAwakenAttrList then
        uiAwakenAttrList:RefreshList(list)
    else
        uiAwakenAttrList = self:GetUIScroll("uiAwakenAttrList")
        self._uiAwakenAttrList = uiAwakenAttrList
        uiAwakenAttrList:Create(attrListTrans,list,function(...) self:OnDrawAwakenAttrCell(...) end)
    end
end

function UISagaTree:InitEvent()
    self:SetWndClick(self.mLeftBtn,function() self:OnClickLeftBtnFunc() end)
    self:SetWndClick(self.mRightBtn,function() self:OnClickRightBtnFunc() end)
    self:SetWndClick(self.mAwakenHelpBtn,function() self:OnClickAwakenHelpBtnFunc() end)
    self:SetWndClick(self.mAwakenSkillPreBtn,function() self:OnClickAwakenSkillPreBtnFunc() end)
    self:SetWndClick(self.mAwakenPandectBtn,function() self:OnClickAwakenPandectBtnFunc() end)
    self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mUpAwakenBtn,function() self:OnClickUpAwakenBtnFunc() end)
    self:SetWndClick(self.mActAwakenBtn,function() self:OnClickActAwakenBtnFunc() end)
    self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
    self:SetWndClick(self.mAwakenResetBtn,function() self:OnClickAwakenResetBtnFunc() end)
end

function UISagaTree:InitTreeData()
    --- 激活选择消耗
    self._awakenHeroTreeInfo = {}

    ---@type StructHeroTreeInfo 英雄觉醒技能树
    self._heroTreeServerData = nil

    --- 英雄觉醒技能树 refId
    self._heroTreeRefId = nil

    local heroServerData = self._heroServerData
    if not heroServerData then
        self:InitHeroServerData()
        heroServerData = self._heroServerData
    end
    if not heroServerData then return end

    local treeInfo = heroServerData.treeInfo
    self._heroTreeServerData = treeInfo
    self._heroTreeRefId = treeInfo.treeRefId
end

function UISagaTree:RefreshHeroName()
    local heroServerData = self._heroServerData
    if not heroServerData then
        self:SetWndText(self.mHeroName,"")
        return
    end
    local heroName = gModelHeroExtra:GetHeroSetName(heroServerData)
    self:SetWndText(self.mHeroName,heroName)
end

function UISagaTree:OnClickLeftBtnFunc()
    self:OnCutHeroFunc(-1)
end

function UISagaTree:OnClickRightBtnFunc()
    self:OnCutHeroFunc(1)
end

function UISagaTree:RefreshTopDivTop()
    local heroServerData = self._heroServerData
    if not heroServerData then return end

    local heroName = gModelHeroExtra:GetHeroSetName(heroServerData)
    self:SetWndText(self.mShowHeroName,heroName)
end

function UISagaTree:RefreshView()
    self:InitHeroServerData()
    --self:RefreshTopDiv()
    self:RefreshTopDivTop()
    self:CreateHeroTree()
    self:RefreshFormTag()
end

function UISagaTree:OnClickActAwakenBtnFunc()
    local heroId = self._heroId
    if not heroId then return end

    if not self._uiHeroTreeRoot then return end

    local curActTreeRefId = self._uiHeroTreeRoot:GetCurActTreeRefId()
    if not curActTreeRefId then return end


    local info = self:GetCommonUpAwankenItemInfo()
    if not info then return end

    local list = {
        id = heroId,
        pointRefId = curActTreeRefId,
        appointedlist = info.appointedlist or {},
        rangelist = info.rangelist or {},
        rangItemList = info.rangItemList or {},
    }
    gModelHero:OnHeroTreePointActiveReq(list)
end

function UISagaTree:InitData()
    self._heroId = self:GetWndArg("heroId")
    --self._heroIndex = self:GetWndArg("heroIndex")

    self:RefreshCutHeroInfo()
end

------------------- 升级需要道具
function UISagaTree:GetAwakenNeedItemList(itemDataList)
    self._awakenAppHeroList = {}
    if not itemDataList then return {} end
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

function UISagaTree:RefreshFormTag()
    CS.ShowObject(self.mFormTag,false)
    ---@type StructHero
    local herodata = gModelHero:GetHeroById(self._heroId)
    if not herodata then
        return
    end

    local refId = herodata:GetRefId()
    local heroRef = gModelHero:GetHeroRef(refId)
    if not heroRef then
        return
    end

    CS.ShowObject(self.mFormTag,false)
end

function UISagaTree:OnTimer(key)
    if key == self._tryHeroTimeKey then
        self:RefreshTryHeroDesc()
    end
end

function UISagaTree:RefreshHeroTreeDataShow()
    self._curSelectTreePointId = self._uiHeroTreeRoot:GetCurSelTreeRefId()

    self:RefreshAwakenDetails()

    local curAllLv,maxLv = gModelHero:GetTreePointsLvlData(self._heroId)
    local pandectProgressStr = string.replace(ccClientText(20150),curAllLv, maxLv)
    self:SetWndText(self.mAwakenPandectProgressText, pandectProgressStr)
end

function UISagaTree:OnClickHeroAwakenSkillSelectFunc(itemdata)
    local treePointRefId = self._curSelectTreePointId
    if not treePointRefId then
        if LOG_INFO_ENABLED then
            printInfoNR("self._curSelectTreePointId is a nil")
        end
        return
    end

    local heroTreeInfoList = self._heroTreeInfoList
    if not heroTreeInfoList then return end

    local heroTreePointInfo = heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        if LOG_INFO_ENABLED then
            printInfoNR("self._heroTreeInfoList[treePointRefId] is a nil, treePointRefId = "..treePointRefId)
        end
        return
    end

    local isPointAct = itemdata.isPointAct
    if not isPointAct then
        GF.ShowMessage(ccClientText(37601))
        return
    end

    local skillId = itemdata.skillId
    if self._curSelectTreePointSkillId == skillId then return end

    local heroId = self._heroId
    gModelHero:OnHeroTreePointSelectSkillReq(heroId,treePointRefId,skillId)
end

function UISagaTree:OnDrawAwakenSkillCell(list,item,itemdata,itempos)
    local ExtraImgTrans = self:FindWndTrans(item,"ExtraImg")
    local SkillIconTrans = self:FindWndTrans(item,"CommonUI/Root/SkillIcon")
    local SelectBgTrans = self:FindWndTrans(item,"SelectBg")
    local ActBgTrans = self:FindWndTrans(item,"ActBg")

    local isPointAct = itemdata.isPointAct
    local skillId = itemdata.skillId
    local baseClass = SkillIcon:New(self)
    if skillId then
        local curSelTreePointId = itemdata.curSelTreePointId
        baseClass:SetSkillInfo(nil,false,nil,1)
        baseClass:Create(SkillIconTrans,skillId,function()
            local skillList = gModelHero:GetTreePointSkillIdList(curSelTreePointId, itempos)
            if not table.isempty(skillList) then
                local firstSkillId = skillList[1]
                gModelGeneral:OpenSkillWnd({
                    skill = firstSkillId,
                    curSkillId = skillId,
                    wndType = 5,
                    pointActivate = isPointAct,
                })
            end
        end)
        ---2025/1/3： 技能图标高亮，不置灰
        --baseClass:SetIconAndIconBgGray(not isPointAct)
        baseClass:SetIconAndIconBgGray(false)
    else
        baseClass:SetShowIcon(false,false)
        baseClass:SetSkillInfo(nil,nil,nil,1)
        baseClass:Create(SkillIconTrans,0,function() end)
        baseClass:SetIconAndIconBgGray(false)
    end
    local isShowExtraSkillAct = false
    local isExtraSkillGrayBtn = false
    local skillType = itemdata.skillType
    local isExtra = skillType == ModelHero.TYPE_AWAKEN_SKILL_EXTRA
    if isExtra then
        if isPointAct then
            local isExtraSkillAct = itemdata.isExtraSkillAct
            if not isExtraSkillAct then
                isShowExtraSkillAct = true
            end
        else
            isShowExtraSkillAct = true
            isExtraSkillGrayBtn = true
        end
    end

    CS.ShowObject(ExtraImgTrans,isExtra)

    local isShowSelectBg = not isShowExtraSkillAct
    if isShowSelectBg then
        local isSel = itemdata.isSel
        local BgTrans = self:FindWndTrans(SelectBgTrans,"Bg")
        CS.ShowObject(BgTrans,isPointAct)
        local SelectYesIconTrans = self:FindWndTrans(SelectBgTrans,"SelectYesIcon")
        CS.ShowObject(SelectYesIconTrans,isSel)

        local LockImgTrans = self:FindWndTrans(SelectBgTrans,"LockImg")
        CS.ShowObject(LockImgTrans,not isPointAct)


        self:SetWndClick(SelectBgTrans,function()
            self:OnClickHeroAwakenSkillSelectFunc(itemdata)
        end)
    end
    if isShowExtraSkillAct then
        local BtnYellow3Trans = self:FindWndTrans(ActBgTrans,"ActBtnRoot/BtnYellow3")
        local redPointTrans = self:FindWndTrans(ActBgTrans,"redPoint")

        self:SetWndButtonText(BtnYellow3Trans,ccClientText(37600))
        local areaOpen = gModelFunctionOpen:CheckAreaOpen(10306003)
        local isFuncOpen = gModelFunctionOpen:CheckIsOpened(10306003)
        local extraSkillIsOpen = not areaOpen and true or isFuncOpen

        self:SetWndButtonGray(BtnYellow3Trans,not extraSkillIsOpen or isExtraSkillGrayBtn)

        local showRedPoint = false
        local extraSkillCostId = itemdata.extraSkillCostId
        if extraSkillCostId and isPointAct and isFuncOpen then
            local heroExtraSkillCost = gModelHeroExtra:GetHeroTreeExtraSkillCostByConfigAndHeroServerData(extraSkillCostId,self._heroServerData)
            if heroExtraSkillCost and gModelHeroExtra:CheckHeroTreeExtraSkillPayEnough(heroExtraSkillCost) then
                showRedPoint = true
            end
        end
        CS.ShowObject(redPointTrans,showRedPoint)

        self:SetWndClick(BtnYellow3Trans,function()
            if(not extraSkillIsOpen)then
                local extraOpenDesc = gModelFunctionOpen:GetOpenTips(10306003)
                GF.ShowMessage(extraOpenDesc)
            else
                self:OnClickHeroAwakenSkillBtnFunc(itemdata)
            end
        end)
    end
    CS.ShowObject(SelectBgTrans,isShowSelectBg)
    CS.ShowObject(ActBgTrans,isShowExtraSkillAct)
end

function UISagaTree:InitHeroTreeInfoList()
    local heroTreeInfoList
    if self._heroId then
        heroTreeInfoList = gModelHero:GetServerHeroTreeInfoByHeroId(self._heroId)
    end
    self._heroTreeInfoList = heroTreeInfoList
end

function UISagaTree:OnClickAwakenPandectBtnFunc()
    local heroId = self._heroId
    GF.OpenWnd("UISagaAwakenAttr",{
        heroId = heroId,
    })
end

function UISagaTree:StartTryHeroDescTimer()
    self:StopTryHeroDescTimer()
    self:TimerStart(self._tryHeroTimeKey,1,false,-1)
end

function UISagaTree:RefreshTopDiv()
    local heroServerData = self._heroServerData
    if not heroServerData then return end

    local refId = heroServerData.refId
    local heroRef  = gModelHero:GetHeroRef(refId)
    if not heroRef then return end

    local raceRef = gModelHero:GetHeroRaceRefByRefId(heroRef.raceType)
    if raceRef then
        self:SetWndEasyImage(self.mHeroRaceImg,raceRef.icon,function()
            CS.ShowObject(self.mHeroRaceImg,true)
        end)
    end

    local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
    if qualityRef then
        self:SetWndEasyImage(self.mHeroQuaImg,qualityRef.heroMsgNameBg,function()
            CS.ShowObject(self.mHeroQuaImg,true)
        end)
    end
end

function UISagaTree:RefreshHeroTree(treeTrans)
    self:InitHeroTreeInfoList()
    self:RefreshHeroTreeTransShow()
    self:SetHeroTreePointInfo(treeTrans)
    self:RefreshHeroTreeDataShow()
end

function UISagaTree:OnClickAwakenResetBtnFunc()
    if not self._heroId then return end

    local isZeroLv = true
    local points = gModelHero:GetHeroServerTreePoints(self._heroId, true)
    for k,v in ipairs(points) do
        local lvRefId = v.lvRefId
        local ref = gModelHero:GetHeroTreePointLvRef(lvRefId)
        if ref.lv > 0 then
            isZeroLv = false
            break
        end
    end

    if isZeroLv then
        GF.ShowMessage(ccClientText(20159))
        return
    end

    local heroAwakenReset = gModelHero:GeConfigByKey("heroAwakenReset")
    local itemData 			= LxDataHelper.ParseItem(heroAwakenReset)
    local itemNum 			= itemData[1].itemNum
    local itemId 			= itemData[1].itemId

    gModelGeneral:OpenUIOrdinTips({
        refId = 10021,
        func = function()
            local own = gModelItem:GetNumByRefId(itemId)
            if own < itemNum then
                gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
                return
            end
            local heroId = self._heroId
            gModelHero:OnHeroTreeResetReq(heroId)
        end,
        para = {gModelItem:GetNameByRefId(itemId),itemNum}, consume = {itemNum, itemId}
    })
end
------------------------- List -------------------------

function UISagaTree:RefreshTryHeroDesc()
    local heroEndTime = self._heroEndTime
    if not heroEndTime then
        self:StopTryHeroDescTimer()
        self:SetWndText(self.mAwakenPageDesc,"")
        return
    end

    local timeValue = heroEndTime - GetTimestamp()
    if timeValue < 0 then
        self:StopTryHeroDescTimer()
        self:SetWndText(self.mAwakenPageDesc,"")
        return
    end

    local timeStr = LUtil.FormatTimespanToMin2(timeValue)
    timeStr = string.replace(ccClientText(10085),timeStr)
    self:SetWndText(self.mAwakenPageDesc,timeStr)
end

function UISagaTree:OnItemChange()
    self:RefreshView()
end

function UISagaTree:GetDefaultSelectTreePoint()
    local heroTreeInfoList = self._heroTreeInfoList
    if not heroTreeInfoList then return end

    local bigRefId,bigSort,isActivate
    for k,v in pairs(heroTreeInfoList) do
        isActivate = v.isActivate
        if ((not isActivate and v.canActivate) or isActivate) and v.canLvlUp then
            local refId = k
            local ref   = gModelHero:GetHeroTreePointRef(refId)
            if not ref then
                if LOG_INFO_ENABLED then
                    printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = "..refId)
                end
                break
            end

            local sort  = ref.sort
            if not bigSort or sort > bigSort then
                -- 默认选最大id的节点
                bigRefId = refId
                bigSort = sort
            end
        end
    end

    if bigRefId then return bigRefId, bigSort end

    local heroTreeServerData = self._heroTreeServerData
    if not heroTreeServerData then return end

    local refId,ref
    local points = heroTreeServerData.points
    for k,v in ipairs(points) do
        refId = v.pointRefId
        ref = gModelHero:GetHeroTreePointRef(refId)
        if not ref then
            if LOG_INFO_ENABLED then
                printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = "..refId)
            end
            break
        end

        local sort = ref.sort
        if not bigSort or sort > bigSort then --默认选最大id的节点
            bigRefId = refId
            bigSort = sort
        end
    end

    if not bigRefId then
        local heroTreeRefId = self._heroTreeRefId
        local treeRef = gModelHero:GetHeroTreeRef(heroTreeRefId)
        bigRefId = treeRef.initPoint
        bigSort = 1
    end
    return bigRefId, bigSort
end

function UISagaTree:RefreshCutHeroInfo()
    local career = self:GetWndArg("career")
    local race = self:GetWndArg("race")
    if not career or not race then
        return
    end
    self._cutHeroList = gModelHero:FilterAwakenHeroList(career,race)
    self._heroIndex = 1
    for k,v in ipairs(self._cutHeroList) do
        if self._heroId == v.id then
            self._heroIndex = k
        end
    end
end

function UISagaTree:OnClickAwakenSkillPreBtnFunc()
    gModelHeroExtra:OpenHeroTreeSkillWnd({
        viewType = 2,
        heroServerData = self._heroServerData,
    })
end

function UISagaTree:OnCutHeroFunc(optNum)
    --local actAwakenHeroList = self._actAwakenHeroList
    --if #actAwakenHeroList < 1 then return end

    local curHeroIndex = self._heroIndex
    if not curHeroIndex then
        return
    end

    curHeroIndex = curHeroIndex + optNum


    local cnt = #self._cutHeroList

    if curHeroIndex >cnt then
        curHeroIndex = 1
    elseif curHeroIndex <1 then
        curHeroIndex = cnt
    end

    local heroData = self._cutHeroList[curHeroIndex]

    self._heroId = heroData.id
    self._heroIndex = curHeroIndex
    self._curSelectTreePointId = nil
    self:RefreshView()
end

function UISagaTree:OnDrawAwakenAttrCell(list,item,itemdata,itempos)
    local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local AttrValueTrans = self:FindWndTrans(item,"AttrValue")
    local ArrowTrans = self:FindWndTrans(item, "Arrow")
    local NextAttrValueTrans = self:FindWndTrans(item, "NextAttrValue")
    local UpArrowTrans = self:FindWndTrans(NextAttrValueTrans, "UpArrow")
    local AttrValueTarTrans = self:FindWndTrans(item,"AttrValueTar")
    local CenterAttrTar = self:FindWndTrans(item,"CenterAttrTar")
    local refId,type,value,nextValue = itemdata.refId,itemdata.type,itemdata.value,itemdata.nextValue
    if AttrIconTrans then
        local icon = gModelHero:GetAttributeIconById(refId)
        self:SetWndEasyImage(AttrIconTrans,icon,function()
            CS.ShowObject(AttrIconTrans,true)
        end)
    end
    local name = gModelHero:GetAttributeNameById(refId)
    self:SetWndText(AttrNameTrans,name)

    local isMaxLv = itemdata.isMaxLv
    local valuePos = isMaxLv and CenterAttrTar.localPosition or AttrValueTarTrans.localPosition
    local val = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,type,value)
    if not isMaxLv then
        local haveNextValue = nextValue and nextValue > 0
        local addVal = ""
        if haveNextValue then
            addVal = gModelHero:GetAttributeValueNoNameByIdAndVal(refId,type,nextValue)
        else
            addVal = val
        end
        self:SetWndText(NextAttrValueTrans,addVal)
        CS.ShowObject(UpArrowTrans,itemdata.isUp)
    end
    self:SetWndText(AttrValueTrans,val)
    AttrValueTrans.localPosition = valuePos
    CS.ShowObject(ArrowTrans,not isMaxLv)
    CS.ShowObject(NextAttrValueTrans,not isMaxLv)
end

function UISagaTree:RefreshAwakenDetails()
    self:StopTryHeroDescTimer()

    local isMaxLv = self._uiHeroTreeRoot:CheckTreeIsMax()
    local treePointRefId = self._curSelectTreePointId
    if not treePointRefId and not isMaxLv then return end

    local heroTreeServerData = self._heroTreeServerData
    if not heroTreeServerData then  return end

    if isMaxLv then
        local treePointList = gModelHero:GetHeroTreePointList(heroTreeServerData.treeRefId)
        if not treePointList or #treePointList < 1 then return end

        treePointRefId = treePointList[#treePointList].refId
    end

    if not treePointRefId then return end

    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        if LOG_INFO_ENABLED then
            printInfoNR("self._heroTreeInfoList[treePointRefId] is a nil, treePointRefId = "..treePointRefId)
        end
        return
    end

    local heroServerData = self._heroServerData
    local isTryHero	 = self._isTryHero
    local lvRefId = heroTreePointInfo.lvRefId
    local pointType = heroTreePointInfo.pointType
    local lvList = heroTreePointInfo.lvList
    local isActivate = heroTreePointInfo.isActivate
    self._awakenPointActivate = isActivate
    local maxLvListNum = #lvList
    local maxPointLvData = lvList[maxLvListNum]
    local curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvRefId)
    local points = heroTreeServerData.points or {}
    local curAttr = ""
    if #points > 0 then
        local lastPoint = points[#points]
        local lastLvRefId = lastPoint.lvRefId
        if lastLvRefId and lastLvRefId > 0 then
            local lastLvRef = gModelHero:GetHeroTreePointLvRef(lastLvRefId)
            if lastLvRef then
                curAttr = lastLvRef.attr
            end
        end
    end

    -- 显示属性/技能
    local isShowAttrDiv = pointType == ModelHero.TREE_POINT_TYPE_ATTR
    local isShowSkillDiv = pointType == ModelHero.TREE_POINT_TYPE_SKILL
    --- 默认显示属性
    --- 2025/1/2：修改为按照类型显示，无默认
    --isShowAttrDiv = true

    local showAwakenSkillList = false
    local showSkillInfo = false
    if isShowSkillDiv then
        local skillId = heroTreePointInfo.skillId
        local usePointSkillRef = curPointLvRef
        local isSel
        local list = {}
        local skillInfo = gModelHeroExtra:GetHeroTreeSkillList(usePointSkillRef)
        --- 当前等级技能id
        for i,v in ipairs(skillInfo.skill) do
            isSel = isActivate and skillId == v
            table.insert(list,{
                skillId = v,
                skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
                isPointAct = isActivate,
                curSelTreePointId = treePointRefId,
                isSel = isSel,
            })
        end
        local isMoreSkill = gModelHeroExtra:IsTreeSkillMore()
        if isMoreSkill and #list > 1 then
            showAwakenSkillList = true
            self:InitAwakenSkillList(list)
        else
            isShowAttrDiv = true
            showSkillInfo = true
            if #list > 0 then
                local tempSkillId = list[1].skillId
                local skillRef = GameTable.SnakeSkillRef[tempSkillId]
                if skillRef then
                    local str = string.replace(ccClientText(20183),ccLngText(skillRef.name),ccLngText(skillRef.description))
                    self:SetWndText(self.mSkillShowInfoDivTxt,str)
                end
            end
        end
    end


    if isShowAttrDiv then
        local nextPointAttr = curPointLvRef and curPointLvRef.attr or ""
        local attrList = gModelHero:GetAwakenTreePointAttrList(curAttr, nextPointAttr,isMaxLv)
        self:InitAwakenAttrList(attrList)
    end

    CS.ShowObject(self.mAwakenAttrDiv, isShowAttrDiv)
    CS.ShowObject(self.mAwakenSkillDiv, showAwakenSkillList)
    CS.ShowObject(self.mAwakenTitle, showAwakenSkillList)
    CS.ShowObject(self.mSkillShowInfoDiv,showSkillInfo)
    local isNextUpLv = self._uiHeroTreeRoot:CheckIsNextUpLv()
    local isLimitClick = false
    local isLimitUpLv = false
    local showDesc = true
    local descStr = ""
    local limitStr = ""
    local showLimitStr = false
    local showUpLvBtn = false
    local showActBtn = true
    local canLvlUp = heroTreePointInfo.canLvlUp
    if isTryHero then
        showDesc = true
        self:RefreshTryHeroDesc()
        self:StartTryHeroDescTimer()
    elseif not isActivate and not isNextUpLv then
        if heroTreePointInfo.needConType and heroTreePointInfo.needActivateCon then
            local needConType = heroTreePointInfo.needConType
            local needActivateCon = heroTreePointInfo.needActivateCon
            showDesc = true
            if needConType == ModelHero.TREE_CON_TYPE_LVL then
                local needActivateConData = string.split(needActivateCon, '=')
                descStr = string.replace(ccClientText(20140), needActivateConData[2])
                isLimitUpLv = true
            elseif needConType == ModelHero.TREE_CON_TYPE_STAR then
                descStr = string.replace(ccClientText(20141), needActivateCon)
                isLimitUpLv = true
            elseif needConType == ModelHero.TREE_CON_TYPE_RESONANCE then
                descStr = string.replace(ccClientText(20152), needActivateCon)
                isLimitUpLv = true
            end
            showUpLvBtn = false
            showActBtn = true
        elseif heroTreePointInfo.firstConType and heroTreePointInfo.firstActivateCon then
            --- 条件满足时，不会存在 needConType 和 needActivateCon
            isLimitClick = true
            local firstConType = heroTreePointInfo.firstConType
            local firstActivateCon = heroTreePointInfo.firstActivateCon
            showDesc = true
            if firstConType == ModelHero.TREE_CON_TYPE_LVL then
                local needActivateConData = string.split(firstActivateCon, '=')
                descStr = string.replace(ccClientText(20140), needActivateConData[2])
                isLimitUpLv = true
            elseif firstConType == ModelHero.TREE_CON_TYPE_STAR then
                descStr = string.replace(ccClientText(20141), firstActivateCon)
                isLimitUpLv = true
            elseif firstConType == ModelHero.TREE_CON_TYPE_RESONANCE then
                descStr = string.replace(ccClientText(20152), firstActivateCon)
                isLimitUpLv = true
            end
            isLimitUpLv = true
        end
    elseif isActivate then
        limitStr = ccClientText(20139)
        showLimitStr = true
        showDesc = false
        isLimitUpLv = true
    elseif not canLvlUp then
        local needCon = heroTreePointInfo.needCon
        if isMaxLv then
            showDesc = true
            descStr = ccClientText(20142)
            isLimitUpLv = true
        elseif needCon then
            showDesc = true
            local upLvlConType	= heroTreePointInfo.upLvlNeedConType
            local upLvlCondition= heroTreePointInfo.upLvlNeedActivateCon
            if upLvlConType == ModelHero.TREE_LV_CON_TYPE_LVL then
                descStr = string.replace(ccClientText(20143), upLvlCondition)
                isLimitUpLv = true
            elseif upLvlConType == ModelHero.TREE_LV_CON_TYPE_STAR then
                descStr = string.replace(ccClientText(20146), upLvlCondition)
                isLimitUpLv = true
            elseif upLvlConType == ModelHero.TREE_LV_CON_TYPE_RESONANCE then
                descStr = string.replace(ccClientText(20153), upLvlCondition)
                isLimitUpLv = true
            end
        elseif not isActivate and not heroTreePointInfo.canActivate then
            if heroTreePointInfo.firstConType and heroTreePointInfo.firstActivateCon then
                --- 条件满足时，不会存在 needConType 和 needActivateCon
                isLimitClick = true
                local firstConType = heroTreePointInfo.firstConType
                local firstActivateCon = heroTreePointInfo.firstActivateCon
                showDesc = true
                if firstConType == ModelHero.TREE_CON_TYPE_LVL then
                    local needActivateConData = string.split(firstActivateCon, '=')
                    descStr = string.replace(ccClientText(20140), needActivateConData[2])
                    isLimitUpLv = true
                elseif firstConType == ModelHero.TREE_CON_TYPE_STAR then
                    descStr = string.replace(ccClientText(20141), firstActivateCon)
                    isLimitUpLv = true
                elseif firstConType == ModelHero.TREE_CON_TYPE_RESONANCE then
                    descStr = string.replace(ccClientText(20152), firstActivateCon)
                    isLimitUpLv = true
                end
                isLimitUpLv = true
            end
        end
    end
    self._isLimitClick = isLimitClick

    self._isLimitUpLv = isLimitUpLv
    self:SetWndText(self.mAwakenPageDesc,descStr)
    CS.ShowObject(self.mAwakenPageDesc,showDesc)

    self:SetWndText(self.mLimitStr,limitStr)
    CS.ShowObject(self.mLimitStr,showLimitStr)

    if isLimitUpLv then
        showUpLvBtn = false
        showActBtn = false
    end
    CS.ShowObject(self.mUpAwakenBtn,showUpLvBtn)
    CS.ShowObject(self.mActAwakenBtn,showActBtn)


    -- 显示消耗区域
    self._awakenHeroTreeInfo = {}
    local fuse = false
    gModelHero:ClearUpLvTreeSelHeroList()
    local showItemList = not (isTryHero or isMaxLv)
    CS.ShowObject(self.mAwakenNeedItemList ,showItemList)

    local itemDataList = {}
    if showItemList and not isActivate then
        self._awakenHeroTreeInfo.upSelfInfo = {}
        self._awakenHeroTreeInfo.upRangeInfo = {}
        self._awakenHeroTreeInfo.upRangeItemInfo = {}
        self._awakenHeroTreeInfo.upItemInfo = {}

        itemDataList = {[1] = {},[2] = {},[3] = {},}
        local fuse1,fuse2,fuse3 = false,false,false
        local heroTreeActNeedItemInfo = gModelHeroExtra:GetHeroTreeActNeedItemListByConfig(curPointLvRef.upSelf,curPointLvRef.upRange,curPointLvRef.upItem,heroServerData)
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
    end

    if itemDataList then
        self:InitAwakenNeedItemList(itemDataList)
    end
end

function UISagaTree:StopTryHeroDescTimer()
    self:TimerStop(self._tryHeroTimeKey)
end

function UISagaTree:OnClickAwakenHelpBtnFunc()
    GF.OpenWnd("UIBzTips",{refId = 120})
end

function UISagaTree:CreateHeroTree()
    self:InitTreeData()

    local heroTreeServerData = self._heroTreeServerData
    if not heroTreeServerData then return end

    local treeRefId	 = heroTreeServerData.treeRefId
    if treeRefId == 0 then return end

    local treeRef = gModelHero:GetHeroTreeRef(treeRefId)
    if not treeRef then
        if LOG_INFO_ENABLED then
            printInfoNR("GameTable.CharacterTreeRef[refId] is a nil, refId = "..treeRefId)
        end
        return
    end

    local treePbName = treeRef.treePb
    self._treePbName = treePbName

    local awakenTreeList = self._awakenTreeList
    if not awakenTreeList then
        awakenTreeList = {}
        self._awakenTreeList = awakenTreeList
    end
    local awakenTreeTrans = awakenTreeList[treePbName]
    if awakenTreeTrans then
        self:RefreshHeroTree(awakenTreeTrans)
    else
        self:CreateWndPrefab(self.mAwakenTree, treePbName, treePbName, function(prefabTrans)
            self._awakenTreeList[treePbName] = prefabTrans
            self:RefreshHeroTree(prefabTrans)
            --self:SendGuideReadyEvent(self:GetWndName())
        end, CS.RES_UI_HERO_AWAKEN_TREE)
    end
end

function UISagaTree:GetColorStr(refId,num,itemType,selNum)
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

------------------------------------------------------------------

function UISagaTree:InitAwakenSkillList(list)
    local uiAwakenSkillList = self._uiAwakenSkillList
    if uiAwakenSkillList then
        uiAwakenSkillList:RefreshList(list)
    else
        uiAwakenSkillList = self:GetUIScroll("uiAwakenSkillList")
        self._uiAwakenSkillList = uiAwakenSkillList
        uiAwakenSkillList:Create(self.mAwakenSkillList,list,function(...) self:OnDrawAwakenSkillCell(...) end)
    end
end

function UISagaTree:OnClickUpAwakenBtnFunc()
    local heroId = self._heroId
    if not heroId then return end

    local treePointRefId = self._curSelectTreePointId
    if not treePointRefId then
        printInfoNR("self._curSelectTreePointId is a nil")
        return
    end

    local info = self:GetCommonUpAwankenItemInfo()
    if not info then return end

    local list = {
        id = heroId,
        pointRefId = treePointRefId,
        appointedlist = info.appointedlist or {},
        rangelist = info.rangelist or {},
        rangItemList = info.rangItemList or {},
    }
    gModelHero:OnHeroTreePointUpLvReq(list)
end

function UISagaTree:OnClickHelpBtnFunc()
    GF.OpenWnd("UIBzTips",{refId = 120})
end

function UISagaTree:RefreshServerData()
    gModelHero:ClearUpLvTreeSelHeroList()
    self:InitHeroServerData()
    self:CreateHeroTree()
end

function UISagaTree:InitAwakenNeedItemList(itemDataList)
    self._awakenUpSelfRedPointList = {}
    local list = self:GetAwakenNeedItemList(itemDataList)
    local uiAwakenNeedItemList = self._uiAwakenNeedItemList
    if uiAwakenNeedItemList then
        uiAwakenNeedItemList:RefreshList(list)
    else
        uiAwakenNeedItemList = self:GetUIScroll("uiAwakenNeedItemList")
        self._uiAwakenNeedItemList = uiAwakenNeedItemList
        uiAwakenNeedItemList:Create(self.mAwakenNeedItemList,list,function(...) self:OnDrawAwakenNeedItemCell(...) end)
    end
end


return UISagaTree