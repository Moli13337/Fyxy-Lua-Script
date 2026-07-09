---
--- Created by LCM.
--- DateTime: 2024/3/6 16:07:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellSagaAwardNew:LWnd
local UIYellSagaAwardNew = LxWndClass("UIYellSagaAwardNew", LWnd)

UIYellSagaAwardNew.TYPE_NORMAL = 1
UIYellSagaAwardNew.TYPE_ACTIVITY = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellSagaAwardNew:UIYellSagaAwardNew()
	self._seqList = {}

    self._showListKey = "showListKey"

    ---- 显示圆圈动画
    self._showYuanAniKey = "showYuanAniKey"

    self._curHeroTimerKey = "_curHeroTimerKey"

    self._showAniKey = "showAniKey"
	self._playAni = true
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellSagaAwardNew:OnWndClose()

    self:ClearSeqList()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellSagaAwardNew:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellSagaAwardNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:SetXUITextText(self.mEnterBtnName,ccClientText(10102))
	self:InitCommonData()
	self:InitEvent()
	self:InitMsg()
	self:OnWndRefresh()
end

function UIYellSagaAwardNew:PlayYuanAni()

end

function UIYellSagaAwardNew:OnTimer(key)
    if key == self._curHeroTimerKey then
        self:TimerStop(key)
        self:OnCreateHeroList()
    end
end

function UIYellSagaAwardNew:RunMirrorCallAni()
    self:ShowUpHeroList()
end

function UIYellSagaAwardNew:OnClickFenxiangBtnFunc()
    local data = {
        root = self.mFenxiangBtn,
        shareType = ModelChat.CHATSHARE_CALL,
        shareData = tostring(self._callLogId)
    }
    gModelGeneral:OpenShareTip(data)
end

function UIYellSagaAwardNew:RefreshView()
    CS.ShowObject(self.mBeforeDiv,false)
    CS.ShowObject(self.mContentDiv,true)

    gModelCallHero:AutoSacrificeFunc()
    CS.ShowObject(self.mGongXiHuoDeRoot,true)
    CS.ShowObject(self.mEnterBtn,true)
    self:RefreshShowBtn()
end

function UIYellSagaAwardNew:CreateCommonIcon(item,itemdata)
	local instanceId = item:GetInstanceID()

	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")

	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(IconTrans)

    local onClickFunc
    if self._wndType == UIYellSagaAwardNew.TYPE_ACTIVITY then
        baseClass:SetRewardDetailItem(itemdata)

        onClickFunc = function()
            gModelGeneral:ShowRewardDetailTip(itemdata)
        end
    else
        local refId = itemdata.itemId
        local itype = itemdata.itype
        local count = itemdata.count

        baseClass:SetCommonReward(itype, refId, count)
        baseClass:EnableShowNum(true)

        onClickFunc = function()
            if itype == LItemTypeConst.TYPE_ITEM then
                gModelGeneral:OpenItemInfoTipTop(refId,count)
            elseif itype == LItemTypeConst.TYPE_HERO then
                gModelGeneral:OpenHeroSimpleTip(refId,true)
            elseif itype == LItemTypeConst.TYPE_EQUIP then
                gModelGeneral:OpenEquipInfoTip(refId,nil,count,true, nil, nil, true)
            elseif itype == LItemTypeConst.TYPE_OUTFIT then
                gModelGeneral:ShowCommonItemTipWnd({
                    itemId = refId,
                    itemType = itype,
                    itemNum = count,
                })
            end
        end
    end

    baseClass:EnableShowNum(true)
    baseClass:ShowSacrificeImg()
    baseClass:DoApply()

    self:SetIconClickScale(IconTrans, true)

    self:SetWndClick(IconTrans,function()
        if onClickFunc then onClickFunc() end
    end)
end

function UIYellSagaAwardNew:RunHeartCallAni()
    self:ShowUpHeroList()
end

function UIYellSagaAwardNew:RefreshRefView()
    self:RefreshShow()
    self:RefreshFixedReward()
    self:RefreshPayDiv()
    self:RefreshCallFreeNum()
    self:InitUIShowList()
end

--function UIYellSagaAwardNew:OpenUpStarWnd(refId,func)
--    gModelGeneral:OpenUpHstarHeroShowNewWnd({
--        heroRefId = refId,
--        isNew = true,
--        callBackFunc = func,
--    })
--end

function UIYellSagaAwardNew:ShowReward()
    --self._showListKey
end

function UIYellSagaAwardNew:InitMsg()
    self:WndNetMsgRecv(LProtoIds.MagicResp,function(pb,ret)
        self._net = false
        self:RefreshCallFreeNum()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSacrificeResp,function(pb,ret)
        self._canGo = false
    end)

    self:WndEventRecv(EventNames.On_Item_Change,function ()
        --self:RefreshShowBtn()
        local refData = self._refData
        if refData then
            self:RefreshPayDiv()
            self:RefreshCallFreeNum()
        end
    end)

    self:WndEventRecv(EventNames.ON_REQ_SUC,function()
        self._net = true
    end)
    self:WndNetMsgRecv(LProtoIds.CallHeroResp,function(pb,ret)
        self._net = false
    end)
end

function UIYellSagaAwardNew:RefreshActLimitCallTips(activityData)
    CS.ShowObject(self.mActTipsDiv,false)
    if not activityData then return end
    local moreInfo = JSON.decode(activityData.moreInfo)
    local playerWishData = moreInfo.playerWishData
    if not playerWishData then return end
    local wishes = playerWishData.wishes
    if not wishes then return end
    local dropRecords = playerWishData.dropRecords
    if not dropRecords then return end

    local id_numKeyList = {}
    local tEnrtyId,tPlayerLimitNum
    local id_num = moreInfo.id_num
    for idx,val in ipairs(id_num) do
        val = string.split(val,"_")
        tEnrtyId,tPlayerLimitNum = tonumber(val[1]),tonumber(val[2])
        id_numKeyList[tEnrtyId] = tPlayerLimitNum
    end

    local dropRecordsKeyList = {}
    for tGroupId,count in pairs(dropRecords) do
        dropRecordsKeyList[tonumber(tGroupId)] = count
    end

    local showTips = false
    local dropRecordsNum
    for k,v in pairs(wishes) do
        if showTips then break end
        for idx,entryId in pairs(v) do
            if showTips then break end
            dropRecordsNum = dropRecordsKeyList[entryId]
            if dropRecordsNum then
                tPlayerLimitNum = id_numKeyList[entryId]
                if tPlayerLimitNum and tPlayerLimitNum ~= -1 then
                    showTips = tPlayerLimitNum - dropRecordsNum < 1
                end
            end
        end
    end
    if showTips then
        self:SetWndText(self.mActTipsTxt,ccClientText(32112))
        self:InitTextSizeWithLanguage(self.mActTipsTxt, -2)
    end
    CS.ShowObject(self.mActTipsDiv,showTips)
end
------------------------- List -------------------------
function UIYellSagaAwardNew:GetShowList()
    return self._itemList or {}
end

function UIYellSagaAwardNew:InitCommonData()
    self._heroEffectList = {
        [4] = "fx_ui_ZHJS_yingxiong_zise",
        [5] = "fx_ui_ZHJS_yingxiong_chengse",
    }

    self._gmOpen = self:GetWndArg("gmOpen")

    self._lihuiInitPos = self.mSpPos.localPosition

    self:CreateWndEffect(self.mGongXiHuoDeRoot,"fx_ui_gongxihuode","fx_ui_gongxihuode",100,false,false)
end

function UIYellSagaAwardNew:CreateLiHui(heroRefId,isMin)
    local startTimeFunc = function()
        if isMin then return end
        local callHeroShowResultCd = gModelCallHero:GetCallConfigRefByKey("callHeroShowResultCd") or 5
        self:CreateTimer(self._curHeroTimerKey,callHeroShowResultCd,1)
    end

    if self._curShowHero and self._curShowHero == heroRefId then
        startTimeFunc()
        return
    end

    --- 英雄召唤获得界面Y轴
    local heroShowLH3 = 100

    --- 英雄召唤获得界面倍数
    local heroShowLH2 = 1

    local effRef = gModelHero:GetHeroEffectRef(heroRefId)
    if effRef then
--[[        local tHeroShowLH3 = effRef.heroShowLH3 or 0
        if tHeroShowLH3 > 0 then
            heroShowLH3 = tHeroShowLH3
        end

        local tHeroShowLH4 = effRef.heroShowLH4 or 0
        if tHeroShowLH4 > 0 then
            heroShowLH4 = tHeroShowLH4
        end
        heroShowLH2 = effRef.heroShowLH2
        ]]

    end

    local showNewLHFunc = function()
        local showHeroLiHuiList = self._showHeroLiHuiList
        if not showHeroLiHuiList then
            showHeroLiHuiList = {}
            self._showHeroLiHuiList = showHeroLiHuiList
        end

--[[        local curPos = self.mSpPos.localPosition
        self.mSpPos.localPosition = Vector3(curPos.x,heroShowLH3,curPos.z)]]
        self.mSpPos.localPosition = gModelHeroExtra:GetHeroShowLH1(effRef,self.mSpPos)

        local showHeroLiHui = showHeroLiHuiList[heroRefId]
        if showHeroLiHui then
            showHeroLiHui:SetVisible(true)
        else
            local spine = gModelHero:GetHeroPrefabNameByRefId(heroRefId,nil,true)
            if not spine then
                return
            end

            showHeroLiHui = self:CreateWndSpine(self.mSpPos,spine,heroRefId,false,function(dpSpine)
                --dpSpine:SetAlpha(0.5)
                dpSpine:SetScale(heroShowLH2)
            end)
        end
        showHeroLiHuiList[heroRefId] = showHeroLiHui
        self._curShowSpine = showHeroLiHui
        self._curShowHero = heroRefId
        CS.ShowObject(self.mSpPos,true)
    end

    local tCurPos = self.mSpPos.localPosition
    self.mSpPos.localPosition = Vector3(self._lihuiInitPos.x,tCurPos.y,self._lihuiInitPos.z)

    local curLiHuiPos = self.mSpPos.localPosition
    local curLiHuiPosX = curLiHuiPos.x
    local curLiHuiPosY = curLiHuiPos.y
    local curLiHuiPosZ = curLiHuiPos.z

    local vanishTime = 1
    local showTime = 1
    local moveX = self._lihuiInitPos.x

    if self._curShowSpine and self._curShowHero and self._curShowHero ~= heroRefId then
        self:TweenSeq_MoveFadeAni(self._showAniKey,{
            {
                trans = self.mSpPos,
                aniStarPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
                vanishPos = Vector3(curLiHuiPosX - moveX,curLiHuiPosY,curLiHuiPosZ),
                aniShowPos = Vector3(curLiHuiPosX + moveX,heroShowLH3,curLiHuiPosZ),
                showPos = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ),
            }
        },{
            initAlpha = 1,
            fromAlpha = 1,
            toAlpha = 0,
            vanishTime = vanishTime,
            showTime = showTime,
            nextShowAni = true,
            nextShowFunc = function()
                self._curShowSpine:SetVisible(false)
                showNewLHFunc()
            end,
            endFunc = function()
                self.mSpPos.localPosition = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ)
                showNewLHFunc()
                startTimeFunc()
            end
        })
    else
        self:TweenSeq_MoveFadeAni(self._showAniKey,{
            {
                trans = self.mSpPos,
                aniStarPos = Vector3(curLiHuiPosX + moveX,heroShowLH3,curLiHuiPosZ),
                vanishPos = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ),
            }
        },{
            initAlpha = 0,
            fromAlpha = 0,
            toAlpha = 1,
            vanishTime = vanishTime,
            showTime = showTime,
            startShowFunc = function()
                showNewLHFunc()
            end,
            endFunc = function()
                self.mSpPos.localPosition = Vector3(curLiHuiPosX,heroShowLH3,curLiHuiPosZ)
                startTimeFunc()
            end
        })
    end
end

function UIYellSagaAwardNew:InitUIShowList()
	local list = self:GetShowList()
	local len = #list
	local showMinList = len <= 4
	local trans = showMinList and self.mShowMinList or self.mShowMaxList
	local hideTrans = showMinList and self.mShowMaxList or self.mShowMinList
	CS.ShowObject(trans,true)
	CS.ShowObject(hideTrans,false)

	local key = trans:GetInstanceID()
	local uiShowList = self:FindUIScroll(key)
	if uiShowList then
		uiShowList:RefreshList(list)
        local uiList = uiShowList:GetList()
        uiList:SetItemRootPosition(nil,0)
	else
		uiShowList = self:GetUIScroll(key)
		uiShowList:Create(trans,list,function(...) self:OnDrawShowCell(...) end)
		uiShowList:EnableScroll(true)
	end
end

function UIYellSagaAwardNew:CreateShowHeroLiHui(upHeroList)
    self:TimerStop(self._curHeroTimerKey)
    local len = #upHeroList
    if len < 1 then return end
    self._showUpHeroList = upHeroList
    self._index = 1
    self:OnCreateHeroList()
end

function UIYellSagaAwardNew:CreateTimer(key,time,loopCnt)
    time = time or 1
    loopCnt = loopCnt or -1
    self:TimerStop(key)
    self:TimerStart(key,time,false,loopCnt)
end

function UIYellSagaAwardNew:RunCommonAni()
    self:ShowUpHeroList()
end

function UIYellSagaAwardNew:OnDrawShowCell(list,item,itemdata,itempos)
	self:CreateCommonIcon(item,itemdata)

    local instanceId = item:GetInstanceID()
    self:DestroyWndEffectByKey(instanceId)

    self:PlayAni(item,itemdata,itempos)
end

function UIYellSagaAwardNew:RefreshCallFreeNum()
    local refId = self._refId
    self:SetWndText(self.mFreeNum,"")
    local showPayDiv = true
    if refId then
        local callHeroData = gModelCallHero:GetCallHeroData()
        local callHero = callHeroData[refId]
        local freeNum  = callHero and callHero.freeNum or 0
        if freeNum >= self._playTimes then
            showPayDiv = false
            local freeNumStr = gModelActivity:GetPrivilegeFreeNumStr()
            local time = gModelBackflow:GetResidueTime()
            local isModelOpen = time > 0
            if isModelOpen then
                freeNumStr = ccClientText(23517)
            end
            self:SetWndText(self.mFreeNum,string.replace(freeNumStr,freeNum))
        end
    end
    CS.ShowObject(self.mPropMag,showPayDiv)
end

function UIYellSagaAwardNew:OnClickAgainBtnFunc()
    if self._canGo then return end
    if self._net then return end

    local wndIns = GF.FindFirstWndByName("UIUpStarSagaSowNew")
    if wndIns then return end

    local playTime = self._playTimes

    local enterfunc = function()
        gModelHero:BuyHeroBag(self:GetWndName())
    end
    local leftFunc = function()
        FireEvent(EventNames.ON_MOJING_MAIN)
        GF.OpenWndBottom("UISagaSpirit",{page = 1})
        self:WndClose()
    end
    local isFull = gModelGeneral:IsFullHeroBag(playTime,leftFunc,enterfunc,nil,nil,self:GetWndName())
    if isFull then return end
    local _sid = self._sid
    if _sid then
        local isZS = false
        local callType = self._playTimes == 1 and 1 or 2
        if self._payRefId == 102001 then
            isZS = true
        end
        local func = function()
            local showAgainInfo = self:GetWndArg("showAgainInfo")
            if showAgainInfo then
                local againBtnCallFunc = showAgainInfo.againBtnCallFunc
                if againBtnCallFunc then
                    againBtnCallFunc()
                    return
                end
            end
            if self._extractType == 1 and self._sendSacrifice then
                self._net = true
            end
            gModelActivity:GetCallDataBySid(_sid,self._activePageId,callType,self:GetWndName(),self._playTimes)
        end
        if func then func() end
    else
        local type = 1
        if playTime == 10 then
            type = 2
        end
        local wndName = self:GetWndName()

        local refId = self._refId
        if refId ~= 0 then
            local refData = gModelCallHero:GetCallRefByRefId(refId)
            if not refData then
                printErrorN(string.format("no callRef refId",refId))

                return
            end
            if refData.extractType == 1 or refData.extractType==4 then
                gModelCallHero:SendCallHeroReq(refId,type,wndName,true,function()
                    self._net = true
                end)
            elseif refData.extractType == 2 then
                gModelCallHero:SendHeartCall(refId,type,wndName,true)
            else
                printErrorN(string.format("call type unknown type ",refData.type))
            end
        else
            gModelCallHero:SendIntegralCallHeroReq(refId,type, self._payRefId, wndName,true)
        end
    end
end

function UIYellSagaAwardNew:GetShowUpHeroList()
    local upHeroList = {}
    local showLiHuiHeroKeyList = {}
    local quality
    local maxQuality
    for i,v in ipairs(self._itemList) do
        local itype = v.itype
        if itype == LItemTypeConst.TYPE_HERO then
            local heroRefId = nil
            if self._wndType == UIYellSagaAwardNew.TYPE_ACTIVITY then
                heroRefId = v.refId
            else
                heroRefId = v.itemId
            end
            quality = gModelHero:GetHeroInitQualityByRefId(heroRefId)
            if quality then
                if maxQuality and maxQuality < quality then
                    maxQuality = quality
                elseif not maxQuality then
                    maxQuality = quality
                end
            end
            local initStar = gModelHero:GetHeroInitStarByRefId(heroRefId)
            if self._extractType == 2 then
                if initStar > 4 then
                    table.insert(upHeroList,{refId = heroRefId})
                end
            else
                if initStar >= 4 then
                    table.insert(upHeroList,{refId = heroRefId})
                end
            end
            if initStar >= 4 then
                if not showLiHuiHeroKeyList[heroRefId] then
                    showLiHuiHeroKeyList[heroRefId] = i
                end
            end
        end
    end
    if maxQuality and not self._sid then
        local qualityRef = gModelItem:GetQualityRef(maxQuality)
        if qualityRef then
        end
    end
    local list = {}
    for heroRefId,idx in pairs(showLiHuiHeroKeyList) do
        table.insert(list,{
            heroRefId = heroRefId,
            idx = idx
        })
    end
    table.sort(list,function(a,b)
        return a.idx < b.idx
    end)
    local showLiHuiHeroList = {}
    for i,v in ipairs(list) do
        local ref = gModelHero:GetHeroRef(v.heroRefId)
        if ref then
            table.insert(showLiHuiHeroList,v.heroRefId)
        end
    end
    table.sort(showLiHuiHeroList,function(a,b)
        local refA,refB = gModelHero:GetHeroRef(a),gModelHero:GetHeroRef(b)
        if refA and refB then
            local qualityA,qualityB = refA.quality,refB.quality
            if qualityA ~= qualityB then
                return qualityA > qualityB
            end
            return a < b
        end
        return false
    end)
    return upHeroList,showLiHuiHeroList
end

function UIYellSagaAwardNew:RefreshPayDiv()
    local refData = self._refData
    if not refData then return end

    local showAgainInfo = self:GetWndArg("showAgainInfo")
    if showAgainInfo then
        local showAgainBtn = showAgainInfo.showAgainBtn
        if showAgainBtn then
            self:SetWndEasyImage(self.mPropIcon, showAgainInfo.img)
            self:SetXUITextText(self.mAgainBtnName,showAgainInfo.againBtnName)


            local score = showAgainInfo.score
            local target = showAgainInfo.target
            local color = "#ffffff"
            if score < target then
                color = "#ff5151"
            end
            local scoreStr = LUtil.NumberCoversion(score)
            local targetStr = LUtil.NumberCoversion(target)
            local payNumStr = string.format("<color=%s>%s/%s</color>",color,scoreStr,targetStr)
            self:SetXUITextText(self.mPayNum,payNumStr)
        end
        CS.ShowObject(self.mAgainBtn,showAgainBtn)
        CS.ShowObject(self.mAgainBtn.parent,showAgainBtn)
        return
    end
    CS.ShowObject(self.mAgainBtn,true)

    local playTimes = self._playTimes
    local isMin = playTimes == 1
    local expend
    local callBtnTxt = {}
    local callAgainBtnTxt = refData.callAgainBtnTxt
    if not string.isempty(callAgainBtnTxt) then
        callBtnTxt = string.split(callAgainBtnTxt,"=")
    end
    if isMin then
        self:SetXUITextText(self.mAgainBtnName,callBtnTxt[2] or ccClientText(11617))
        expend = refData.oneExpend
    else
        self:SetXUITextText(self.mAgainBtnName,callBtnTxt[3] or ccClientText(11618))
        expend = refData.tenExpend
    end

    local splitFunc = function(str)
        str = str or ""
        return string.split(str,"=")
    end

    local payRefId,payNum,haveNum
    local expendList = string.split(expend, "|")
    if #expendList == 1 then
        local firstData = splitFunc(expend)
        payRefId, payNum = tonumber(firstData[2]), tonumber(firstData[3])
        haveNum = gModelItem:GetNumByRefId(payRefId)
    else
        for i,v in ipairs(expendList) do
            local expendInfo = splitFunc(v)
            local needRefId,needNum = tonumber(expendInfo[2]), tonumber(expendInfo[3])
            haveNum = gModelItem:GetNumByRefId(needRefId)
            if i == 1 and haveNum >= needNum then
                payRefId,payNum = needRefId,needNum
                break
            else
                payRefId,payNum = needRefId,needNum
            end
        end
    end

    local color = "#ffffff"
    if haveNum < payNum then
        color = "#ff5151"
    end
    local haveNumStr = LUtil.NumberCoversion(haveNum)
    local needNumStr = LUtil.NumberCoversion(payNum)
    local payNumStr = string.format("<color=%s>%s/%s</color>",color,haveNumStr,needNumStr)
    self:SetXUITextText(self.mPayNum,payNumStr)

    local icon = gModelItem:GetItemIconByRefId(payRefId)
    CS.ShowObject(self.mPropIcon,true)
    self:SetWndEasyImage(self.mPropIcon, icon)
end

function UIYellSagaAwardNew:ShowUpHeroList()
    local upHeroList,showLiHuiHeroList = self:GetShowUpHeroList()
    local len = #upHeroList
    local isEmpty = len <= 0
    if self._gmOpen then
        --self:RefreshView()
        --self:CreateShowHeroLiHui(showLiHuiHeroList)
        gModelGeneral:ShowUpHero(upHeroList,function ()
            if self:IsWndValid() then
                self:RefreshView()
            end
        end,0,self._refId)
        return
    end
    if isEmpty then
        self:RefreshView()
    else
        local openCallBack = function()
            if self._isOpenWnd then
                CS.ShowObject(self.mContentDiv,false)
                CS.ShowObject(self.mSpPos,false)
                self._isOpenWnd = false
            end
        end
        gModelGeneral:ShowUpHero(upHeroList,function ()
            if self:IsWndValid() then
                self:RefreshView()
            end
        end,1,self._refId,openCallBack)


        --local func,openWnd
        --func = function()
        --    if not self:IsWndValid() then return end
        --    table.remove(upHeroList,1)
        --    if upHeroList[1] then
        --        openWnd()
        --    else
        --        self:RefreshView()
        --    end
        --end
        --openWnd = function()
        --    if upHeroList[1] then
        --        self:OpenUpStarWnd(upHeroList[1],func)
        --    else
        --        self:RefreshView()
        --    end
        --end
        --openWnd()
    end
    self:CreateShowHeroLiHui(showLiHuiHeroList)
end

function UIYellSagaAwardNew:OnCreateHeroList()
    local showUpHeroList = self._showUpHeroList or {}
    local len = #showUpHeroList
    if len < 1 then
        self:TimerStop(self._curHeroTimerKey)
        return
    end
    local index = self._index
    if index > len then
        index = 1
        self._index = index
    else
        self._index = index + 1
    end
    local heroRefId = showUpHeroList[index]
    if not heroRefId then
        self:TimerStop(self._curHeroTimerKey)
        return
    end
    local isMin = len <= 1
    --self:CreateLiHui(heroRefId,isMin)
end

function UIYellSagaAwardNew:RefreshFixedReward()
    local fixedRewardStr = ""
    local fixedReward = self._fixedReward
    if fixedReward then
        local fixName = gModelItem:GetNameByRefId(fixedReward.itemId)
        fixedRewardStr = string.replace(ccClientText(11619),fixName,fixedReward.itemNum)
    end
    self:SetXUITextText(self.mRewardTitle,fixedRewardStr)
    CS.ShowObject(self.mRewardTitle,true)
end

function UIYellSagaAwardNew:OnClickEnterBtnFunc()
    self:WndClose()
end

function UIYellSagaAwardNew:OnWndRefresh()
    local isOpenWnd = self:GetWndArg("isOpenWnd")
    self._isOpenWnd = isOpenWnd
    CS.ShowObject(self.mBeforeDiv,true)
    if not isOpenWnd then
        CS.ShowObject(self.mContentDiv,false)
        CS.ShowObject(self.mSpPos,false)
    end
    self:ClearSeqList()
    self:InitWnd()
    self:InitData()
    self:RefreshConfigData()
    self:RunAni()
end

function UIYellSagaAwardNew:InitEvent()

    self:SetWndClick(self.mAgainBtn,function() self:OnClickAgainBtnFunc() end)
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
    self:SetWndClick(self.mFenxiangBtn,function() self:OnClickFenxiangBtnFunc() end)
end

function UIYellSagaAwardNew:InitWnd()
    CS.ShowObject(self.mGongXiHuoDeRoot,false)
    CS.ShowObject(self.mAgainBtn,false)
    CS.ShowObject(self.mEnterBtn,false)
end

function UIYellSagaAwardNew:RefreshCanGoStatus()
    local len = gModelCallHero:GetHeroSacrificeNumAndList()
    self._sendSacrifice = len > 0
    if self._extractType == 1 and len > 0 then
        self._canGo = gModelHero:GetAutoSacrificeStatus()
    else
        self._canGo = false
    end
end

function UIYellSagaAwardNew:InitData()
	self._wndType = self:GetWndArg("wndType") or UIYellSagaAwardNew.TYPE_NORMAL
    self._refId = self:GetWndArg("refId")
    self._itemList = self:GetWndArg("itemList")
    self._playTimes = self:GetWndArg("callNum")
    self._rankValue = self:GetWndArg("rankValue")
    self._callLogId = self:GetWndArg("callLogId")
    self._rank = self:GetWndArg("rank") or 0
    self._fixedReward = self:GetWndArg("fixedReward")
    self._extractType = gModelCallHero:GetExtractType(self._refId)
    self._tipRefId = 110008
    self._hideCallDiamond = self:GetWndArg("hideCallDiamond")
    local sid = self:GetWndArg("sid")
    self._sid = sid
    if not sid then return end
    local activityDataS = gModelActivity:GetActivityBySid(sid)
    local activityDataW = gModelActivity:GetWebActivityDataById(sid)
    if not activityDataS or not activityDataW then return end
    local model = activityDataS.model
    local moreInfo = JSON.decode(activityDataS.moreInfo)
    local dataW = activityDataW.config
    local showBg
    -- if model == ModelActivity.LIMIT_CALL then
    --     showBg = dataW.callResultBg
    -- else
        showBg = dataW.showBg
    -- end
    self:SetWndEasyImage(self.mBg,showBg)

    local noEffModelList = {
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_67] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_68] = true
    }

    if noEffModelList[model] then
        self._first = false
    end

    if not self._hideCallDiamond then
        local last
        local diaCallLimitTips
        -- if model == ModelActivity.LIMIT_CALL then
        --     last = moreInfo.goldTimes - moreInfo.callNum
        --     diaCallLimitTips = dataW.callDiamondTips
        -- else
            if moreInfo.remainBuyNum then
                last = moreInfo.remainBuyNum
            else
                local alreadyCallNum = moreInfo.callNum or 0
                local goldTimes = moreInfo.goldTimes or 0
                last = goldTimes - alreadyCallNum
            end
            diaCallLimitTips = dataW.diaCallLimitTips
        -- end

        local desTips = diaCallLimitTips or ccClientText(20809)
        local str = string.replace(desTips,last)
        self:SetWndText(self.mCallDiamondTips,str)
    end


    self:RefreshCanGoStatus()
end

function UIYellSagaAwardNew:RefreshNoRefView()
    CS.ShowObject(self.mPropIcon,false)
    self:SetXUITextText(self.mAgainBtnName,ccClientText(11617))

    local integralNeedItem = GameTable.SummonConfigRef["integralNeedItem"]
    local strList = string.split(integralNeedItem,"=")
    local needItemId = tonumber(strList[2])
    local needItemNum = tonumber(strList[3])
    local haveNum = gModelItem:GetNumByRefId(needItemId)
    local color = "#0fb93f"
    if haveNum < needItemNum then
        color = "#ff5151"
    end
    local haveNumStr = LUtil.NumberCoversion(haveNum)
    local needNumStr = LUtil.NumberCoversion(needItemNum)
    local str = string.format("<color=%s>%s/%s</color>",color,haveNumStr,needNumStr)
    self:SetXUITextText(self.mPayNum,str)

    local itemIcon = gModelItem:GetItemIconByRefId(needItemId)
    if LxUiHelper.IsImgPathValid(itemIcon) then
        self:SetWndEasyImage(self.mPropIcon, itemIcon)
        CS.ShowObject(self.mPropIcon, true)
    else
        CS.ShowObject(self.mPropIcon,false)
    end

    self:InitUIShowList()
end

function UIYellSagaAwardNew:PlayAni(item,itemdata,itempos)
	local instanceId = item:GetInstanceID()
	local seq = self._seqList[instanceId]
	if seq then
		seq:Kill(false)
		self._seqList[instanceId] = nil
	end

	local aniTrans = self:FindWndTrans(item, "CommonUI")
	if not self._playAni or itemdata.isPlayAni then
		aniTrans.localScale = Vector3.one
		return
	end

	itemdata.isPlayAni = true

	aniTrans.localScale = Vector3.zero

	local dtSequence = YXTween.TweenSequenceIns()
	self._seqList[instanceId] = dtSequence

    local effectRootTrans = self:FindWndTrans(item,"CommonUI/effectRoot")

    local playTime = 0.1
	local startT = itempos * playTime
	local ani1 = aniTrans:DOScale(1, playTime)
    dtSequence:AppendInterval(startT)
	dtSequence:Append(ani1)

	dtSequence:OnComplete(function()
        self._seqList[instanceId] = nil
        local itype = itemdata.itype
        if itype == LItemTypeConst.TYPE_HERO then
            local refId
            if self._wndType == UIYellSagaAwardNew.TYPE_ACTIVITY then
                refId = itemdata.refId
            else
                refId = itemdata.itemId
            end
            local effScaleSize = 100
            local eff
--[[            if gModelHero:CheckIsShowHeroQualityForeign() then
            else
                local initStar = gModelHero:GetHeroInitStarByRefId(refId)
                if initStar >= 4 then
                    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
                end
                eff = self._heroEffectList[initStar]
            end]]
            local heroRef  = gModelHero:GetHeroRef(refId)
            if heroRef then
                local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
                if qualityRef then
                    local heroCallFxList = string.split(qualityRef.heroCallFx, '=')
                    eff = heroCallFxList[1]
                    local fxEffSize = heroCallFxList[2]
                    if not string.isempty(fxEffSize) then
                        effScaleSize = tonumber(fxEffSize) * 100
                    end
                end
            end
            local initStar = gModelHero:GetHeroInitStarByRefId(refId)
            if initStar >= 4 then
                LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_NORMAL)
            end
            if not eff then
                eff = self._heroEffectList[initStar]
            end

            if eff then
                self:CreateWndEffect(effectRootTrans,eff,instanceId,effScaleSize,false,false)
            end
        end
	end)
	dtSequence:PlayForward()
end

function UIYellSagaAwardNew:RefreshShowBtn()
    local refData = self._refData
    if refData then
        self:RefreshRefView()
    else
        CS.ShowObject(self.mAgainBtn,true)
        CS.ShowObject(self.mOuQiDiv,false)
        self:RefreshNoRefView()
    end
end

function UIYellSagaAwardNew:RefreshShow()
    local ouqi = self._rankValue and self._rankValue > 0 or false
    CS.ShowObject(self.mOuQiDiv,ouqi)
    if ouqi then
        self:SetWndText(self.mOuQiZhiTxt,self._rankValue)
        self:SetWndText(self.mOuQiZhiImgText, ccClientText(11681))
    end
    CS.ShowObject(self.mSurpassText,self._rank > 0)

    if self._rank > 0 then
        local value = string.format("%.1f",self._rank * 100)
        local txt = ccClientText(11651)
        self:SetWndText(self.mSurpassText,string.replace(txt,value.."%"))
    end
end

function UIYellSagaAwardNew:RunAni()
    local extractType = self._extractType

    if not extractType then
        self:RunCommonAni()
    else
        if extractType == 1 or extractType==4 then
            self:RunMirrorCallAni()
        elseif extractType == 2 then
            self:RunHeartCallAni()
        end
    end
end

function UIYellSagaAwardNew:RefreshConfigData()
    -- 本地表格数据
    local refId = self._refId
    if refId and refId ~= 0 then
        local refData = gModelCallHero:GetCallRefByRefId(refId)
        if refData then
            local extractType = refData.extractType


            self._extractType = extractType
        end
        self._refData = refData
    end

    -- 活动数据
    local _sid = self._sid
    if _sid then
        local activityCfg = gModelActivity:GetWebActivityDataById(_sid)
        local moreInfo = activityCfg.config
        if moreInfo.oneExpend ~= nil then
            --活动召唤
            self._activePageId = 1
            self._refData = {
                oneExpend = moreInfo.oneExpend,
                tenExpend = moreInfo.tenExpend,
                getBackground = moreInfo.getBackground,
                backgroundIcon = "callhero5_bg_2",
            }
        -- elseif moreInfo.eModel == ModelActivity.MODEL_NEWYEAR then
        --     --新春召唤
        --     self._activePageId = 7
        --     self._refData = {
        --         oneExpend = moreInfo.costOne2.."|"..moreInfo.costOne1,
        --         tenExpend = moreInfo.costTen2.."|"..moreInfo.costTen1,
        --         backgroundIcon = "callhero6_bg_big_2",
        --     }
        -- elseif moreInfo.eModel == ModelActivity.MODEL_ACTIVITY_TYPE_67 then
        --     --快乐国
        --     self._activePageId = ModelActivity.HAPPY_COUNTRY_7
        --     self._refData = {
        --         oneExpend = moreInfo.costOne2.."|"..moreInfo.costOne1,
        --         tenExpend = moreInfo.costTen2.."|"..moreInfo.costTen1,
        --         callAgainBtnTxt = moreInfo.callAgainBtnTxt,
        --     }
        elseif moreInfo.eModel == ModelActivity.MODEL_ACTIVITY_TYPE_68 then
            --国王大街
            self._activePageId = ModelActivity.KING_STREET_3
            self._refData = {
                oneExpend = moreInfo.costOne2.."|"..moreInfo.costOne1,
                tenExpend = moreInfo.costTen2.."|"..moreInfo.costTen1,
                callAgainBtnTxt = moreInfo.callAgainBtnTxt,
            }
        -- elseif moreInfo.eModel == ModelActivity.LIMIT_CALL then
        --     -- 限时召唤
        --     self._refData = {
        --         oneExpend = moreInfo.costOne2.."|"..moreInfo.costOne1,
        --         tenExpend = moreInfo.costTen2.."|"..moreInfo.costTen1,
        --         callAgainBtnTxt = moreInfo.callAgainBtnTxt,
        --     }

        --     local activityData = gModelActivity:GetActivityBySid(_sid)
        --     self:RefreshActLimitCallTips(activityData)
        end
    end

    -- if self._extractType == 1 then
    --     LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_MIRROR)
    -- elseif self._extractType == 2 then
    --     LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_MIRROR)
    -- end
end

function UIYellSagaAwardNew:ClearSeqList()
    if self._seqList then
        local seqList = self._seqList
        for k,v in pairs(self._seqList) do
            v:Kill(false)
            seqList[k] = nil
        end
    end
    self._seqList = {}
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIYellSagaAwardNew



