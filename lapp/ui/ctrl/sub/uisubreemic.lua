---
--- Created by LCM.
--- DateTime: 2024/3/15 19:52:58
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubReeMic:LChildWnd
local UISubReeMic = LxWndClass("UISubReeMic", LChildWnd)


UISubReeMic.TYPE_RESONANCE_CRYSTAL = 1           --- 共鸣水晶
UISubReeMic.TYPE_RESONANCE_BREAK = 2             --- 共鸣突破

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubReeMic:UISubReeMic()
    self._timeList = {}
    self._sendMsg = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubReeMic:OnWndClose()
    self:ClearAllTimer()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubReeMic:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubReeMic:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:CreateWndEffect_Ex({
        trans = self.mBgEffRoot,
        effName = "fx_yuchi",
        effKey = "fx_yuchi",
        endFunc = function()
        end
    })

	self:InitHeroTransList()

	self:InitEvent()
	self:InitMsg()

	self:InitData()
    self:InitConfigData()
    self:RefreshServerData()

    self:InitText()

    self:InitEff()

    self:InitResonanceOptBtnList()

    self:RefreshView()
    
    self:RefreshForeign()
end

function UISubReeMic:OnDrawCommonLvAttrCell(list,item,itemdata,itempos)
    local attrIconTrans = self:FindWndTrans(item,"attrIcon")
    local attrNameTrans = self:FindWndTrans(item,"attrName")
    local attrValueTrans = self:FindWndTrans(item,"attrValue")

    local attrRefId,attrType,attrNum = itemdata.attrRefId,itemdata.attrType,itemdata.attrNum

    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(attrIconTrans,attrIcon)

    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(attrNameTrans,attrName)

    local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
    self:SetWndText(attrValueTrans,value)

    if self._isVie then
        self:SetAnchorPos(attrValueTrans,Vector2.New(45,-1))
    end
end

function UISubReeMic:RefreshResonanceAdd()
    local addLv = 0
    local maxList = {}
    local heroList = gModelHero:GetHeroList()
    local refId,star,id
    for k,v in pairs(heroList) do
        refId = v:GetRefId()
        if not gModelSpiritHero:CheckIsSpiritHero(refId) then
            if not v:IsTryHero() then
                star = v:GetStar()
                if self._maxStarAddList[star] then
                    id = v:GetId()
                    local maxRefIdInfo = maxList[refId]
                    if maxRefIdInfo and maxRefIdInfo.star < star then
                        maxRefIdInfo.star = star
                        maxRefIdInfo.id = id
                    elseif not maxRefIdInfo then
                        maxRefIdInfo = {
                            star = star,
                            id = id,
                        }
                        maxList[refId] = maxRefIdInfo
                    end
                end
            end
        end
    end

    self._selectMaxStarList = {}
    for k,v in pairs(maxList) do
        addLv = addLv + self._maxStarAddList[v.star]
        table.insert(self._selectMaxStarList,v.id)
    end
    self._addLv = addLv
end
--------------------------------- 未解锁函数 ---------------------------------
function UISubReeMic:OpenUnlockPosWndFunc(itemdata)
    local data = {}
    table.insert(data,itemdata.unlockNeedItem)
    table.insert(data,itemdata.unlockNeedDiamonds)
    self:OpenResonanceOptWnd({view = 1,itype = 1,data = data,func = function(payType)
        gModelResonance:OnResonancePosUnlockReq(itemdata.refId,payType)
    end})
end

function UISubReeMic:InitHeroBreakItemList()
    local list = self:GetHeroBreakItemList()
    local uiHeroBreakItemList = self._uiHeroBreakItemList
    if uiHeroBreakItemList then
        uiHeroBreakItemList:RefreshList(list)
    else
        uiHeroBreakItemList = self:GetUIScroll("uiHeroBreakItemList")
        self._uiHeroBreakItemList = uiHeroBreakItemList
        uiHeroBreakItemList:Create(self.mHeroBreakItemList,list,function(...) self:OnDrawHeroBreakItemCell(...) end)
    end
end

function UISubReeMic:GetNextLvAttrList()
    local list = {}
    local resonanceLevel = self._resonanceLevel
    if resonanceLevel then
        local nextLv = resonanceLevel + 1
        local maxLv = gModelResonance:GetBreakUpMaxLv()
        if maxLv >= nextLv then
            local ref = GameTable.LevelShareBreachRef[nextLv]
            if ref then
                list = LUtil.ConvertCommonAttrStrToList(ref.attr)
            end
        end
    end
    return list
end

function UISubReeMic:ClearAllTimer()
    local timeList = self._timeList
    if not timeList then return end
    for k,timer in pairs(timeList) do
        LxTimer.DelayTimeStop(timer)
        timeList[k] = nil
    end
    self._timeList = nil
end

function UISubReeMic:InitCurLvAttrList()
    local list = self:GetCurLvAttrList()
    local uiCurLvAttrList = self._uiCurLvAttrList
    if uiCurLvAttrList then
        uiCurLvAttrList:RefreshList(list)
    else
        uiCurLvAttrList = self:GetUIScroll("uiCurLvAttrList")
        self._uiCurLvAttrList = uiCurLvAttrList
        uiCurLvAttrList:Create(self.mCurLvAttrList,list,function(...) self:OnDrawCommonLvAttrCell(...) end,UIItemList.WRAP)
    end
    local enable = #list > 2
    uiCurLvAttrList:EnableScroll(enable)

    local isEmpty = #list < 1
    local curLvStr = ""
    if not isEmpty then
        local resonanceLevel = self._resonanceLevel
        curLvStr = string.replace(ccClientText(14734),resonanceLevel)
    end
    self:SetWndText(self.mCurLvTxt,curLvStr)
    CS.ShowObject(self.mNoLvTxt,isEmpty)
end
--------------------------------- 卸载英雄 ---------------------------------
function UISubReeMic:OpenUnloadHeroWndFunc(itemdata)
    local heroId = itemdata.heroId
    self:OpenResonanceOptWnd({view = 2,heroId = heroId,func = function()
        gModelResonance:OnResonanceHeroReq(heroId,itemdata.refId,2)
    end})
end

function UISubReeMic:RefreshBreakView()
    self:ShowHeroTrans(false)
    self:RefreshResonanceAdd()
    self:InitCurLvAttrList()
    self:InitNextLvAttrList()
    self:InitHeroBreakItemList()
    local resonanceLevel = self._resonanceLevel
    local maxLv = gModelResonance:GetResonanceMaxLv()
    local gray = resonanceLevel and resonanceLevel >= maxLv
    self:SetWndButtonGray(self.mHeroBreakBtn,gray)
end
------------------------- 属性列表 -------------------------

------------------------- 突破消耗列表 -------------------------
function UISubReeMic:GetHeroBreakItemList()
    local list = {}
    local resonanceLevel = self._resonanceLevel
    if resonanceLevel then
        local ref = GameTable.LevelShareBreachRef[resonanceLevel]
        if ref then
            local upNeed = ref.upNeed
            local isMax = upNeed == "-1"
            if not isMax then
                list = LUtil.ConvertCommonItemStrToList(upNeed)
            end
        end
    end
    return list
end
function UISubReeMic:RefreshForeign()
    if self._isVie then
        self:SetAnchorPos(self.mHeroBreakAddTxt,Vector2.New(210,18))
    end
end

function UISubReeMic:ClearTimer(refId)
    local timeList = self._timeList
    if not timeList then return end
    local timer = timeList[refId]
    if timer then
        LxTimer.DelayTimeStop(timer)
        timeList[refId] = nil
    end
end

function UISubReeMic:InitData()
    local subPage = self:GetWndArg("subPage")
    if not subPage then
        subPage = UISubReeMic.TYPE_RESONANCE_CRYSTAL
    end
    self._subPage = subPage

    self._btnType = subPage

    self._btnList = {
        {
            btnType = UISubReeMic.TYPE_RESONANCE_CRYSTAL,
            btnName = ccClientText(14703),
            viewTrans = self.mHeroResonanceView,
            funcId=16501000,
        },
        {
            btnType = UISubReeMic.TYPE_RESONANCE_BREAK,
            btnName = ccClientText(14704),
            viewTrans = self.mHeroBreakView,
            funcId=16502000,
        },
    }
    self._btnPageFuncList = {
        [UISubReeMic.TYPE_RESONANCE_CRYSTAL] = function()
            self:RefreshCrystalView()
        end,
        [UISubReeMic.TYPE_RESONANCE_BREAK] = function()
            self:RefreshBreakView()
        end,
    }
end

function UISubReeMic:InitEvent()
    self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
    self:SetWndClick(self.mHeroNumAddBtn,function() self:OnClickHeroNumAddBtnFunc() end)
    self:SetWndClick(self.mPayItemAddBtn,function() self:OnClickPayItemAddBtnFunc() end)
    self:SetWndClick(self.mHeroBreakBtn,function() self:OnClickHeroBreakBtnFunc() end)
end
------------------------- 英雄列表 -------------------------

------------------------- 属性列表 -------------------------
function UISubReeMic:GetCurLvAttrList()
    local list = {}
    local resonanceLevel = self._resonanceLevel
    if resonanceLevel then
        local ref = GameTable.LevelShareBreachRef[resonanceLevel]
        if ref then
            list = LUtil.ConvertCommonAttrStrToList(ref.attr)
        end
    end
    return list
end

function UISubReeMic:CheckIsHaveHeroToPos()
    -- 满足材料后再判断是否有可共鸣的英雄
    local heroList = gModelHero:GetHeroList()
    local resonanceLevel = self._resonanceLevel
    local resonanceList = gModelResonance:SelResonanceHeroList()
    for k,v in pairs(heroList) do
        local id = v:GetId()
        if not resonanceList[id] then
            local lv = v:GetLv()
            if lv < resonanceLevel then
                return true
            end
        end
    end
    return false
end

function UISubReeMic:RefreshBtnFunc()
    local btnType = self._btnType
    local showViewTransStatus = false
    for i,v in ipairs(self._btnList) do
        showViewTransStatus = v.btnType == btnType
        CS.ShowObject(v.viewTrans,showViewTransStatus)
    end

    if btnType == UISubReeMic.TYPE_RESONANCE_CRYSTAL then
        gModelRedPoint:OnClickFunc(ModelRedPoint.HERO_RESONANCE_GONGMING)
    end

    local btnPageFuncList = self._btnPageFuncList
    if not btnPageFuncList then return end
    local func = btnPageFuncList[btnType]
    if func then func() end
end

function UISubReeMic:ShowHeroTrans(show)
    local heroTransInfoList = self._heroTransInfoList
    if not heroTransInfoList then return end
    for i,v in ipairs(heroTransInfoList) do
        CS.ShowObject(v.rootTrans,show)
    end
    if show then
        self:RefreshCrystalHeroShow()
    end
end

function UISubReeMic:OnClickHeroBtnFunc(itemdata)
    local coolTime = itemdata.coolTime
    if coolTime then
        --- 已解锁
        if coolTime > 0 then
            --- 清除冷却
            self:OnClickClearCoolTimeFunc(itemdata)
        else
            --- 放入或者卸载英雄
            local heroId = itemdata.heroId
            if string.isempty(heroId) then
                self:OnLoadHeroFunc(itemdata)
            else
                self:OnClickUnloadHeroFunc(itemdata)
            end
        end
    else
        --- 未解锁，优先解锁最近的一个
        self:OnClickUnLockFirstPosFunc()
    end
end

function UISubReeMic:OnClickPayItemAddBtnFunc()
    local useRefId = self:GetUseRefId()
    if not useRefId then return end
    self:OpenItemGetWayWnd(useRefId)
end

function UISubReeMic:RefreshCrystalHeroShow()
    local heroServerDataList = {}
    local heroResonanceList = self._heroResonanceList or {}
    for i,id in ipairs(heroResonanceList) do
        local serverData = gModelHero:GetHeroServerDataById(id)
        table.insert(heroServerDataList,serverData)
    end
    table.sort(heroServerDataList,function(a,b)
        return a.lv < b.lv
    end)


    local serverData
    local effKey
    local effTrans,heroPbTrans
    local showSp,showMask,showAdd
    local lvStr = ccClientText(14701)
    local effName = "fx_ui_gmsj_guanghuan"
    local heroTransInfoList = self._heroTransInfoList
    for i,v in ipairs(heroTransInfoList) do
        serverData = heroServerDataList[i]
        showSp = serverData ~= nil or false
        effTrans = v.effTrans
        heroPbTrans = v.heroPbTrans
        effKey = effTrans:GetInstanceID()
        if not self:FindWndEffectByKey(effKey) then
            self:CreateWndEffect(effTrans,effName, effKey,100,false,false)
        end
        showMask = showSp
        showAdd = not showSp
        if showSp then
            self:SetWndText(v.heroLvTxtTrans,string.replace(lvStr,serverData.lv))
            self:CreateHeroPb(heroPbTrans,serverData.id,i)
        end
        CS.ShowObject(heroPbTrans,showSp)
        CS.ShowObject(v.maskTrans,showMask)
        CS.ShowObject(v.addTrans,showAdd)
    end
end
------------------------- 突破消耗列表 -------------------------

------------------------- 操作按钮列表 -------------------------
function UISubReeMic:RefreshResonanceOptBtnList()
    local uiResonanceOptBtnList = self._uiResonanceOptBtnList
    if not uiResonanceOptBtnList then return end
    local uiList = uiResonanceOptBtnList:GetList()
    uiList:RefreshList()
end

function UISubReeMic:GetNextUnLockFirstPosData()
    local unlockNum = self._unlockNum
    if not unlockNum then return end
    local resonancePosDataList = self._resonancePosDataList
    if not resonancePosDataList then return end
    local nextUnLockNum = unlockNum + 1
    local itemdata = resonancePosDataList[nextUnLockNum]
    return itemdata
end

function UISubReeMic:OnClickUnloadHeroFunc(itemdata)
    local heroId = itemdata.heroId
    if string.isempty(heroId) then return end
    self:OpenUnloadHeroWndFunc(itemdata)
end

function UISubReeMic:OnResonanceInfoResp()
    self._sendMsg = false
    self:RefreshServerData()
    self:RefreshView()
end

function UISubReeMic:OnClickUnLockFirstPosFunc()
    local itemdata = self:GetNextUnLockFirstPosData()
    if not itemdata then return end
    self:OpenUnlockPosWndFunc(itemdata)
end

function UISubReeMic:InitEff()
    local spineKey = self._resonanceBreachLevel <= self._resonanceLevel and "Gongmingshuijing_liebian" or "Gongmingshuijing_putong"

    if self._spineKey then
        if self._spineKey == spineKey then
            return
        else
            self:DestroyWndSpineByKey(self._spineKey)
        end
    end

    --self:CreateWndSpine(self.mShuijingEff,spineKey,spineKey,false,function(spine)
    --    --spine:SetScale(2)
    --    spine:PlayAnimation(0,"idle",true)
    --    self._spineKey = spineKey
    --end)

    local showEff = gModelResonance:GetTuPoEffStatue()
    if showEff == 1 then
        self:CreateWndEffect(self.mShuijingEff,"fx_gongmingshuijing_tupo","fx_gongmingshuijing_tupo",100,false)
        gModelResonance:SetTuPoEffStatue()
    end
end

function UISubReeMic:InitResonanceOptBtnList()
    local list = self:GetResonanceOptBtnList()
    local uiResonanceOptBtnList = self._uiResonanceOptBtnList
    if uiResonanceOptBtnList then
        uiResonanceOptBtnList:RefreshList(list)
    else
        uiResonanceOptBtnList = self:GetUIScroll("uiResonanceOptBtnList")
        self._uiResonanceOptBtnList = uiResonanceOptBtnList
        uiResonanceOptBtnList:Create(self.mResonanceOptBtnList,list,function(...) self:OnDrawResonanceOptBtnCell(...) end)
    end
end

function UISubReeMic:GetMulTime(itemdata)
    local curTime = tonumber(GetTimestamp())
    local coolTime = itemdata.coolTime or 0
    return coolTime - curTime
end

function UISubReeMic:OnClickHelpBtnFunc()
    local btnType = self._btnType
    local refId
    if btnType == UISubReeMic.TYPE_RESONANCE_CRYSTAL then
        refId = 34
    elseif btnType == UISubReeMic.TYPE_RESONANCE_BREAK then
        refId = 35
    end
    if not refId then return end
    GF.OpenWnd("UIBzTips",{refId = refId})
end

function UISubReeMic:SetTimeTxt(txtTrans,itemdata,refId)
    local mulTime = self:GetMulTime(itemdata)
    if mulTime < 0 then
        self:ClearTimer(refId)
        gModelResonance:OnResonanceInfoReq()
    else
        local mulTimeStr = LUtil.FormatTimespanNumber(mulTime)
        self:SetWndText(txtTrans,mulTimeStr)
    end
end

function UISubReeMic:InitNextLvAttrList()
    local list = self:GetNextLvAttrList()
    local uiNextLvAttrList = self._uiNextLvAttrList
    if uiNextLvAttrList then
        uiNextLvAttrList:RefreshList(list)
    else
        uiNextLvAttrList = self:GetUIScroll("uiNextLvAttrList")
        self._uiNextLvAttrList = uiNextLvAttrList
        uiNextLvAttrList:Create(self.mNextLvAttrList,list,function(...) self:OnDrawCommonLvAttrCell(...) end,UIItemList.WRAP)
    end
    local enable = #list > 2
    uiNextLvAttrList:EnableScroll(enable)

    local isFull = #list < 1
    local nextLvStr = ""
    if not isFull then
        local resonanceLevel = self._resonanceLevel
        if resonanceLevel then
            local nextLv = resonanceLevel + 1
            local maxLv = gModelResonance:GetBreakUpMaxLv()
            if nextLv > maxLv then
                nextLv = maxLv
            end
            nextLvStr = string.replace(ccClientText(14735),nextLv)
        end
    end
    self:SetWndText(self.mNextLvTxt,nextLvStr)
    CS.ShowObject(self.mMaxLvTxt,isFull)
end

function UISubReeMic:CreateTimer(trans,itemdata)
    local timeList = self._timeList
    if not timeList then
        timeList = {}
        self._timeList = timeList
    end
    local refId = itemdata.refId
    self:SetTimeTxt(trans,itemdata,refId)

    self:ClearTimer(refId)

    self._timeList[refId] = LxTimer.LoopTimeCall(function()
        self:SetTimeTxt(trans,itemdata,refId)
    end, 1, false, -1)

end

function UISubReeMic:RefreshCrystalView()
    local noBreak = self._resonanceBreachLevel > self._resonanceLevel
    self:ShowHeroTrans(noBreak)
    self:InitHeroList()
end

function UISubReeMic:InitConfigData()
    --- 共鸣槽位数量
    self._resonanceSlotNum = GameTable.LevelShareConfigRef["resonanceSlotNum"]

    --- 共鸣展示货币
    self._resonanceShowItem = GameTable.LevelShareConfigRef["resonanceShowItem"]

    --- 水晶突破展示货币
    self._resonanceBreachShowItme = GameTable.LevelShareConfigRef["resonanceBreachShowItme"]

    --- 共鸣槽位冷却时间，单位秒
    self._resonanceTime = GameTable.LevelShareConfigRef["resonanceTime"]

    --- 达到多少级后开始突破
    self._resonanceBreachLevel = GameTable.LevelShareConfigRef["resonanceBreachLevel"]

    self._maxStarAddList = {}
    local resonanceStarAddLevel = GameTable.LevelShareConfigRef["resonanceStarAddLevel"]
    resonanceStarAddLevel = string.split(resonanceStarAddLevel,",")
    for i,v in ipairs(resonanceStarAddLevel) do
        v = string.split(v,"=")
        self._maxStarAddList[tonumber(v[1])] = tonumber(v[2])
    end
end

function UISubReeMic:OnDrawHeroBreakItemCell(list,item,itemdata,itempos)
    local CommonIconTrans = self:FindWndTrans(item,"CommonIcon")
    local IconTrans = self:FindWndTrans(CommonIconTrans,"Icon")
    local NumTrans = self:FindWndTrans(item,"Num")

    local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum
    local instanceId = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemType,itemId,itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local haveNum = gModelItem:GetNumByRefId(itemId)
    local color = haveNum >= itemNum and "green" or "red"
    local haveNumStr = LUtil.FormatColorStr(LUtil.NumberCoversion(haveNum),color)
    local numStr = LUtil.NumberCoversion(itemNum)
    local str = string.format("%s/%s",haveNumStr,numStr)
    self:SetWndText(NumTrans,str)


    self:SetWndClick(IconTrans,function()
        self:OpenItemGetWayWnd(itemId)
    end)
end

function UISubReeMic:OnClickResonanceOptBtnFunc(itemdata)
    if not itemdata then return end
    local btnType = itemdata.btnType
    if self._btnType == btnType then return end
    local funcId = itemdata.funcId
    if funcId and funcId > 0 then
        if not gModelFunctionOpen:CheckIsOpened(funcId,true) then return end
    end
    self._btnType = btnType
    self:RefreshView()
end

function UISubReeMic:OnClickHeroNumAddBtnFunc()
    self:OnClickUnLockFirstPosFunc()
end

function UISubReeMic:RefreshView()
    self:RefreshTop()
    self:RefreshResonanceOptBtnList()
    self:RefreshHeroNumDiv()
    self:RefreshPayItemDiv()
    self:RefreshBtnFunc()
end

function UISubReeMic:OnDrawResonanceOptBtnCell(list,item,itemdata,itempos)
    local BtnTab2Trans = self:FindWndTrans(item,"BtnTab2")
    local redPointTrans = self:FindWndTrans(item,"redPoint")

    local btnType = itemdata.btnType
    local isSel = self._btnType == btnType
    local state =isSel and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(BtnTab2Trans,state)

    self:SetWndTabText(BtnTab2Trans,itemdata.btnName, -2, -30)

    local showRedPoint = false
    if btnType == UISubReeMic.TYPE_RESONANCE_BREAK then
        showRedPoint = gModelResonance:CheckBreakRedPoint()
    end
    CS.ShowObject(redPointTrans,showRedPoint)

    self:SetWndClick(BtnTab2Trans,function()
        self:OnClickResonanceOptBtnFunc(itemdata)
    end)
end
--------------------------------- 放入英雄 ---------------------------------
function UISubReeMic:OnLoadHeroFunc(itemdata)
    local resonanceList = gModelResonance:SelResonanceHeroList()
    GF.OpenWnd("UISagaResSel",{resonanceList = resonanceList,resonanceLevel = self._resonanceLevel,pos = itemdata.refId})
end

function UISubReeMic:CreateHeroPb(trans,id,index)
    local pbPosInfoList = self._pbPosInfoList
    if not pbPosInfoList then
        pbPosInfoList = {}
        self._pbPosInfoList = pbPosInfoList
    end

    local idPbPos = pbPosInfoList[index]
    if idPbPos and idPbPos == id then return end

    local pbName = gModelHero:GetHeroPrefabNameById(id)
    self:CreateWndSpine(trans,pbName,id,false)
    pbPosInfoList[index] = id
end

function UISubReeMic:CheckPosIsShowRedPoint(itemdata)
    local heroId = itemdata.heroId
    if heroId then
        --- 有英雄id不需要显示红点
        return false
    end

    if gLGameLanguage:IsJapanRegion() and self._haveCoolTimeGridNum > 15 then
        return false
    end

    local coolTime = itemdata.coolTime
    if coolTime and coolTime == 0 then
        --- 没有冷却时间且有英雄可以放入
        return self:CheckIsHaveHeroToPos()
    end

    local unlockData = self:GetNextUnLockFirstPosData()
    if not unlockData then return false end

    local unlockPosRefId = unlockData.refId
    local curPosRefId = itemdata.refId
    if unlockPosRefId ~= curPosRefId then return false end

    local unlockNeedItem = string.split(itemdata.unlockNeedItem,"=")
    local useRefId = tonumber(unlockNeedItem[2])
    local haveNum = gModelItem:GetNumByRefId(useRefId)
    local needNum = tonumber(unlockNeedItem[3])
    return haveNum >= needNum
end
--------------------------------- 打开界面 ---------------------------------
function UISubReeMic:OpenResonanceOptWnd(argList)
    GF.OpenWnd("UIReeOpt",argList)
end

function UISubReeMic:OnItemChange()
    self:OnResonanceInfoResp()
end

function UISubReeMic:GetResonanceOptBtnList()
    local list = {}
    local btnList = self._btnList
    if btnList then
        for i,v in ipairs(btnList) do
            local ins = true
            if v.btnType == UISubReeMic.TYPE_RESONANCE_BREAK then
                ins = self._resonanceBreachLevel <= self._resonanceLevel
            end

            --顺便判断功能是否开启
            local isOpen=true
            if v.funcId>0 then
                isOpen = gModelFunctionOpen:CheckIsShow(v.funcId)
            end

            if ins and isOpen then
                table.insert(list,v)
            end
        end
    end
    return list
end

function UISubReeMic:OpenItemGetWayWnd(itemId)
    gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = self:GetWndName()})
end

function UISubReeMic:GetUseRefId()
    local useRefId
    local btnType = self._btnType
    if btnType == UISubReeMic.TYPE_RESONANCE_CRYSTAL then
        useRefId = self._resonanceShowItem
    elseif btnType == UISubReeMic.TYPE_RESONANCE_BREAK then
        useRefId = self._resonanceBreachShowItme
    end
    return useRefId
end

function UISubReeMic:RefreshServerData()
    self._heroResonanceList,self._resonanceLevel,self._heroResonancePosList = gModelResonance:GetResonanceData()
end
------------------------- List -------------------------


------------------------- 英雄列表 -------------------------
function UISubReeMic:GetHeroList()
    local heroResonancePosList = self._heroResonancePosList or {}
    local noBreak = self._resonanceBreachLevel <= self._resonanceLevel
    local hide
    local refList = {}
    for k,v in pairs(GameTable.LevelSharePosRef) do
        hide = v.hide
        if not noBreak then
            if hide == 0 then table.insert(refList,v) end
        else
            table.insert(refList,v)
        end
    end
    table.sort(refList,function(ref1,ref2)
        return ref1.sort < ref2.sort
    end)

    local haveCoolTimeGridNum = 0
    local resonancePosDataList = {}
    local list = {}
    local usePosNum = 0
    local unLockNum = 0
    local allNum = 0
    local refId,serverData,heroId,coolTime
    for i,v in ipairs(refList) do
        refId = v.refId
        hide = v.hide
        serverData = heroResonancePosList[refId]
        local data = {
            refId = refId,
            nextId = v.nextId,
            openType = v.openType,
            sort = v.sort,
            hide = hide,
            unlockNeedItem = v.unlockNeedItem,
            unlockNeedDiamonds = v.unlockNeedDiamonds,
        }
        if serverData then
            heroId = nil
            coolTime = tonumber(serverData.coolTime) / 1000
            if not string.isempty(serverData.heroId) then
                --- 放入英雄才有英雄id，空也不算
                heroId = serverData.heroId
                usePosNum = usePosNum + 1
            end
            if hide == 0 then
                unLockNum = unLockNum + 1
            end
            allNum = allNum + 1
            data.heroId = heroId
            data.coolTime = coolTime
            haveCoolTimeGridNum = haveCoolTimeGridNum + 1
        end
        if hide == 0 then
            table.insert(resonancePosDataList,data)
        end
        table.insert(list,data)
    end
    self._unlockNum = unLockNum
    self._resonancePosDataList = resonancePosDataList
    self._haveCoolTimeGridNum = haveCoolTimeGridNum
    return list,usePosNum,allNum
end
------------------------- List -------------------------

--重连
function UISubReeMic:OnTcpReconnect()
    self._sendMsg = false
end

function UISubReeMic:RefreshTop()
    local lvStr = "<color=#a1#>#a2#</color>"
    lvStr = string.replace(lvStr,"#"..LUtil.GetResonanceColor(1),self._resonanceLevel)
    local isBreak = self._resonanceBreachLevel <= self._resonanceLevel
    local textId = isBreak and 14739 or 14738
    self:SetWndText(self.mHeroResonanceDesc,ccClientText(textId))

    if isBreak then
        local maxLv = gModelResonance:GetResonanceMaxLv()
        local upMaxLv = gModelResonance:GetBreakUpMaxLv()
        if upMaxLv < maxLv then
            maxLv = upMaxLv
        end
        lvStr = lvStr .. "/" .. maxLv
    end
    local str = string.replace(ccClientText(14701),lvStr)
    self:SetWndText(self.mLvTxt,str)
end

function UISubReeMic:OnClickHeroBreakBtnFunc()
    if self._sendMsg then return end
    local list = self:GetHeroBreakItemList()
    if #list > 0 then
        local isEnough = gModelGeneral:CheckItemListEnough(list,self:GetWndName())
        if not isEnough then
            return
        end
    end
    self._sendMsg = true
    gModelResonance:OnResonanceBreachReq()
end

function UISubReeMic:InitHeroList()
    local list = self:GetHeroList()
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        uiHeroList:RefreshData(list)
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroList,list,function(...) self:OnDrawHeroCell(...) end,UIItemList.WRAP,false)
        local uiList = uiHeroList:GetList()
        uiList:EnableLoadAnimation(true, 0, 2)
        uiList:RefreshList(UIListWrap.RefreshMode.Solid)
    end
end

function UISubReeMic:OnResonanceHeroResp(pb)
    if pb.opera == 2 then
        GF.ShowMessage(ccClientText(14728))
    end
end

function UISubReeMic:OnDrawHeroCell(list,item,itemdata,itempos)
    local HeroIconTrans = self:FindWndTrans(item,"HeroIcon")
    local BgTrans = self:FindWndTrans(item,"Bg")
    local AddImgTrans = self:FindWndTrans(BgTrans,"AddImg")
    local ClockImgTrans = self:FindWndTrans(BgTrans,"ClockImg")
    local TimeTxtTrans = self:FindWndTrans(BgTrans,"TimeTxt")
    local BtnTrans = self:FindWndTrans(item,"Btn")
    local redPointTrans = self:FindWndTrans(item,"redPoint")

    local heroId = itemdata.heroId
    local showHeroIcon = false
    local showAdd = false
    local showClock = false

    self:SetWndText(TimeTxtTrans,"")

    self:ClearTimer(itemdata.refId)
    if heroId then
        local instanceId = item:GetInstanceID()
        local baseClass = self:GetCommonIcon(instanceId)
        baseClass:Create(HeroIconTrans)
        baseClass:SetHeroPlayer(heroId)
        baseClass:DoApply()

        self:SetIconClickScale(HeroIconTrans, true)
        showHeroIcon = true
    else
        local coolTime = itemdata.coolTime
        if coolTime then
            if coolTime > 0 then
                showClock = true
                self:CreateTimer(TimeTxtTrans,itemdata)
            else
                showAdd = true
                self:ClearTimer(itemdata.refId)
            end
        else
            self:ClearTimer(itemdata.refId)
        end
        local bgImg = coolTime and "public_item_bg_1" or "public_item_bg_lock"
        self:SetWndEasyImage(BgTrans,bgImg)
    end
    CS.ShowObject(ClockImgTrans,showClock)
    CS.ShowObject(TimeTxtTrans,showClock)

    CS.ShowObject(AddImgTrans,showAdd)

    CS.ShowObject(HeroIconTrans,showHeroIcon)
    CS.ShowObject(BgTrans,not showHeroIcon)

    self:SetWndClick(BtnTrans,function()
        self:OnClickHeroBtnFunc(itemdata)
    end)


    local showRedPoint = self:CheckPosIsShowRedPoint(itemdata)
    CS.ShowObject(redPointTrans,showRedPoint)
end
--------------------------------- 清除冷却函数 ---------------------------------
function UISubReeMic:OnClickClearCoolTimeFunc(itemdata)
    local mulTime = self:GetMulTime(itemdata)
    local maxRefId,maxTime = 0,0
    for k,v in pairs(GameTable.LevelShareCoolRef) do
        local time = v.time
        if mulTime >= time then
            if maxTime < time then
                maxRefId,maxTime = v.refId,time
            end
            if maxTime == 0 then
                maxRefId,maxTime = v.refId,time
            end
        end
    end
    if not maxRefId then return end
    local data = {}
    local ref = GameTable.LevelShareCoolRef[maxRefId]
    table.insert(data,ref.NeedItem)
    table.insert(data,ref.NeedDiamonds)
    self:OpenResonanceOptWnd({view = 1,itype = 2,data = data,func = function(payType)
        gModelResonance:OnResonancePosCoolTimeReq(itemdata.refId,payType)
    end})
end

function UISubReeMic:GetHeroTransInfo(trans)
    local heroPbTrans = self:FindWndTrans(trans,"HeroPb")
    local maskTrans = self:FindWndTrans(trans,"Mask")
    local heroLvTxtTrans = self:FindWndTrans(maskTrans,"HeroLvTxt")
    local addTrans = self:FindWndTrans(trans,"Add")
    local effTrans = self:FindWndTrans(trans,"eff")
    return {
        rootTrans = trans,
        heroPbTrans = heroPbTrans,
        maskTrans = maskTrans,
        heroLvTxtTrans = heroLvTxtTrans,
        addTrans = addTrans,
        effTrans = effTrans,
    }
end

function UISubReeMic:RefreshHeroNumDiv()
    local heroList,usePosNum,unLockNum = self:GetHeroList()
    local str = string.format("%s/%s",usePosNum,unLockNum)
    self:SetWndText(self.mHeroNumTxt,str)
end

function UISubReeMic:OnResonancePosUnlockResp()
    GF.ShowMessage(ccClientText(14727))
end

function UISubReeMic:RefreshPayItemDiv()
    local useRefId = self:GetUseRefId()
    if not useRefId then return end
    local icon = gModelItem:GetItemIconByRefId(useRefId)
    self:SetWndEasyImage(self.mPayItemIcon,icon)
    local numStr = gModelItem:GetNumStrByRefId(useRefId)
    self:SetWndText(self.mPayItemNum,numStr)
end

function UISubReeMic:InitMsg()
    self:WndNetMsgRecv(LProtoIds.ResonanceInfoResp, function()
        self:OnResonanceInfoResp()
        self:InitEff()
    end)
    self:WndNetMsgRecv(LProtoIds.ResonancePosUnlockResp, function()
        self:OnResonancePosUnlockResp()
    end)
    self:WndNetMsgRecv(LProtoIds.ResonancePosCoolTimeResp, function()
        self:OnResonancePosCoolTimeResp()
    end)
    self:WndNetMsgRecv(LProtoIds.ResonanceHeroResp, function(pb,ret)
        self:OnResonanceHeroResp(pb)
    end)
    self:WndEventRecv(EventNames.On_Item_Change,function()
        self:OnItemChange()
    end)
end
function UISubReeMic:InitText()
    self:SetWndText(self.mTitle,ccClientText(14705))

    self:SetWndText(self.mNoLvTxt,ccClientText(14736))
    self:SetWndText(self.mMaxLvTxt,ccClientText(14737))

    self:SetWndButtonText(self.mHeroBreakBtn,ccClientText(10000))

    local hyper = self:GetUIHyperText(self.mHeroBreakAddTxt)
    local str = hyper:AddHyper(ccClientText(14716),{func = function ()
        GF.OpenWnd("UIReeAdd",{selectList = self._selectMaxStarList,addLv = self._addLv})
    end})
    self:SetWndText(self.mHeroBreakAddTxt,str)
end

function UISubReeMic:InitHeroTransList()
    local heroTransInfoList = {}
    local heroTransList = { self.mHero1 , self.mHero2 , self.mHero3 , self.mHero4 , self.mHero5 , self.mHero6 }
    local transInfo
    for i,v in ipairs(heroTransList) do
        transInfo = self:GetHeroTransInfo(v)
        table.insert(heroTransInfoList,transInfo)
    end
    self._heroTransInfoList = heroTransInfoList
end

function UISubReeMic:OnResonancePosCoolTimeResp()
    GF.ShowMessage(ccClientText(14726))
end
------------------------------------------------------------------
return UISubReeMic



