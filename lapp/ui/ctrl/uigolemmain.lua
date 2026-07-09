---
--- Created by LCM.
--- DateTime: 2022/10/24 14:49:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemMain:LWnd
local UIGolemMain = LxWndClass("UIGolemMain", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemMain:UIGolemMain()
    self._changeHeroOptStatus = false

    self._redIdRecord = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemMain:OnWndClose()
    FireEvent(EventNames.REFRESH_OUTFITOPT_BAG)

    for k,v in pairs(self._redIdRecord) do
        gModelGolem:SaveGolemRedRecord(k)
    end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemMain:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemMain:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEffShow()
	self:InitText()
	self:InitGolemShowDiv()
	self:InitMsg()
	self:InitData()
    self:InitEvent()
    self:OnGolemSlotReq()
end

function UIGolemMain:OnDrawGolemSuitCell(list,item,itemdata,itempos)
    local isAct = itemdata.isAct
    local ActDivTrans = self:FindWndTrans(item,"ActDiv")
    local NotActTrans = self:FindWndTrans(item,"NotAct")
    CS.ShowObject(ActDivTrans,isAct)
    CS.ShowObject(NotActTrans,not isAct)
    if isAct then
        local SuitIconTrans = self:FindWndTrans(ActDivTrans,"SuitIcon")
        local SuitNameTrans = self:FindWndTrans(ActDivTrans,"SuitName")
        local SuitDescTrans = self:FindWndTrans(ActDivTrans,"SuitDescDiv/SuitDesc")
        self:SetWndEasyImage(SuitIconTrans,itemdata.icon,function()
            CS.ShowObject(SuitIconTrans,true)
            SuitIconTrans.localScale = Vector2.New(0.6,0.6)
        end,true)
        self:SetWndText(SuitNameTrans,itemdata.showNumTxt)
        self:SetWndText(SuitDescTrans,itemdata.suitTxt)
    else
        local NotActDecTrans = self:FindWndTrans(NotActTrans,"NotActDec")
        self:SetWndText(NotActDecTrans,itemdata.notAct)
    end
end

function UIGolemMain:InitText()
    self:SetWndButtonText(self.mGolemSplitBtn,ccClientText(33225))
    self:SetWndButtonText(self.mUnLoadGolemBtn,ccClientText(33205))
    self:SetWndButtonText(self.mWearGolemBtn,ccClientText(33223))
    self:SetWndText(self.mTxtReturn,ccClientText(10320))
    self:SetWndText(self.mNotActDec,ccClientText(34808))
    self:SetTextTile(self.mSuitDeactivate,ccClientText(34856))
end

function UIGolemMain:InitGolemShowDiv()
    local golemRootList = {
        {
            trans = self.mGolemRoot1,
            index = 1,
        },
        {
            trans = self.mGolemRoot2,
            index = 2,
        },
        {
            trans = self.mGolemRoot3,
            index = 3,
        },
        {
            trans = self.mGolemRoot4,
            index = 4,
        },
    }
    local golemRootTransList = {}
    for i,v in ipairs(golemRootList) do
        local transInfo = self:GetGolemShowDivTransInfo(v)
        table.insert(golemRootTransList,transInfo)
    end
    self._golemRootTransList = golemRootTransList
end
------------------------- List -------------------------
function UIGolemMain:GetShowAttrList(slotServerDataList)
    local list = {}

    return list
end

function UIGolemMain:OnGolemSlotResp(pb,ret)
    if self._heroId ~= pb.heroId and not self._showMapping then return end
    local slotServerDataList = gModelGolem:GetGolemSlotRespSlotServerDataList(pb)
    self._slotServerDataList = slotServerDataList

    if self._wearStatus then
        --- 仅穿戴时生效
        self._wearStatus = false
        local actSuitIdList = gModelGolem:GetGolemActSuitList(slotServerDataList)
        if #actSuitIdList > 0 then
            local first =  actSuitIdList[1]
            local actType = first.actType
            local soundId = actType == ModelGolem.ACT_SKILL_NUM_TWO and LSoundConst.GOLEM_SUIT_ACT_4 or LSoundConst.GOLEM_SUIT_ACT_2
            LxUiHelper.PlayAudioSoundName(soundId)
        end
    end
    self:RefreshView(slotServerDataList)
end

function UIGolemMain:InitEvent()
    local lastNum = #self._cutHeroList -- gModelHero:GetHeroGolemLastNum()
    if lastNum <= 1 then
        CS.ShowObject(self.mLeftBtnDiv,false)
        CS.ShowObject(self.mRightBtnDiv,false)
    end
    self:SetWndClick(self.mLeftBtn,function() self:OnClickLeftBtnFunc() end)
    self:SetWndClick(self.mRightBtn,function() self:OnClickRightBtnFunc() end)
    self:SetWndClick(self.mShowAllAttrBtn,function() self:OnClickShowAllAttrBtnFunc() end)
    self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mGolemSplitBtn,function() self:OnClickGolemSplitBtnFunc() end)
    self:SetWndClick(self.mUnLoadGolemBtn,function() self:OnClickUnLoadGolemBtnFunc() end)
    self:SetWndClick(self.mWearGolemBtn,function() self:OnClickWearGolemBtnFunc() end)
    self:SetWndClick(self.mBtnHelp,function ()self:OnClickHelp() end)
end

function UIGolemMain:OnClickLeftBtnFunc()
    if self._changeHeroOptStatus then return end
    self:ChangeHeroOpt(-1)
end

function UIGolemMain:RefreshNewSuitLH(slotServerDataList)
    local actSuitList = gModelGolem:GetGolemActSuitList(slotServerDataList)
    self:RefreshShowEff(actSuitList)
    local actSuitLen = #actSuitList
    CS.ShowObject(self.mFourSuitRoot,false)
    CS.ShowObject(self.mLeftSuitRoot,false)
    CS.ShowObject(self.mRightSuitRoot,false)
    CS.ShowObject(self.mSuitDeactivate,false)
    if actSuitLen < 1 then
        CS.ShowObject(self.mSuitDeactivate,true)
        return
    end
    local isFour = false
    ---- 长度为 1 的有 2 种情况，要么是 4 件套，要么是 2 件套
    if actSuitLen == 1 then
        local fisrt = actSuitList[1]
        local actNum = fisrt.actNum
        if actNum == ModelGolem.SUIT_WEAR_2 then
            --- 4 件套逻辑
            --[[
                三、魔偶套装立绘优化
                1、当激活魔偶4件套时
                --#魔偶立绘字段（golemDrawing）若有配置则显示对应立绘
                --#若魔偶立绘字段（golemDrawing）没有配置则左右两边显示2个两件套魔偶
                注：当前激活魔偶4件套时，左右两边不显示2件套魔偶（attrShow）   ----- 注意事项而已，明白就行
            ]]
            -- isFour = true
            -- local suitRefId = fisrt.suitRefId
            -- local golemDrawing = gModelGolem:GetGolemSuitGolemDrawingByRefId(suitRefId)
            -- if not string.isempty(golemDrawing) then
            --     local attrShowType4 = suitRefId and gModelGolem:GetGolemSuitAttrShowType4ByRefId(suitRefId)
            --     if not attrShowType4 then
            --         attrShowType4 = 2
            --         if LOG_INFO_ENABLED then
            --             printInfoNR("四件套的展示类型配置字段 attrShowType4，默认是2")
            --         end
            --     end
            --     local showPos = suitRefId and gModelGolem:GetGolemSuitShowPosByRefId(suitRefId)
            --     self:DisposeShowSuitFunc({
            --         attrShowType = attrShowType4,
            --         showPos = showPos,
            --         attrShow = golemDrawing,
            --         showType = ModelGolem.GOLEMDRAWING_CENTER,
            --         ImgTrans = self.mFourSuitImg,
            --         SpTrans = self.mFourSuitSp,
            --         EffTrans = self.mFourSuitEff,
            --         SuitEffTrans = self.mFourEffSuit,
            --     })
            --     CS.ShowObject(self.mFourSuitRoot,true)
            --     return
            -- end
        end
    end
    self:CreateLeftAndRightSuitShow(actSuitList,isFour)--屏蔽
end

function UIGolemMain:RefreshTop()
    local heroId = self._heroId
    if heroId then
        local refId = gModelHero:GetRefIdById(heroId)
        local star = gModelHero:GetHeroServerStar(heroId)
        if refId and star then
            --local heroName = gModelHero:GetHeroNameByRefId(refId,star)

            local serverData = gModelHero:GetHeroServerDataById(heroId)
            local heroName = gModelHeroExtra:GetHeroSetName(serverData)
            self:SetWndText(self.mHeroName,heroName)

            local raceType = gModelHero:GetHeroType(refId)
            local raceRef = raceType and gModelHero:GetHeroRaceRefByRefId(raceType)
            if raceRef then
                self:SetWndEasyImage(self.mHeroRaceImg,raceRef.icon,function() CS.ShowObject(self.mHeroRaceImg,true) end)
            end

            local quality = gModelHero:GetHeroQualityByRefId(refId)
            local qualityRef = quality and gModelItem:GetQualityRef(quality)
            if qualityRef then
                self:SetWndEasyImage(self.mHeroQuaImg,qualityRef.heroMsgNameBg,function() CS.ShowObject(self.mHeroQuaImg,true) end)
            end
        end
    else
        CS.ShowObject(self.mHeroQuaImg,false)
    end
end

function UIGolemMain:DisposeShowSuitFunc(info)
    local actSuitSpineShowList = self._actSuitSpineShowList
    if not actSuitSpineShowList then
        actSuitSpineShowList = {}
        self._actSuitSpineShowList = actSuitSpineShowList
    end
    local actSuitEffectShowList = self._actSuitEffectShowList
    if not actSuitEffectShowList then
        actSuitEffectShowList = {}
        self._actSuitEffectShowList = actSuitEffectShowList
    end
    local attrShowType = info.attrShowType
    if attrShowType then
        if LOG_INFO_ENABLED then
            printInfoNR("attrShowType（1=icon；2=spine；3=特效） = " .. attrShowType)
        end
    end
    local showIcon = attrShowType == ModelGolem.ATTRSHOWTYPE_ICON
    local showSpine = attrShowType == ModelGolem.ATTRSHOWTYPE_SPINE
    local showEffect = attrShowType == ModelGolem.ATTRSHOWTYPE_EFFECT
    local ImgTrans,SpTrans,EffTrans = info.ImgTrans,info.SpTrans,info.EffTrans
    local SuitEffTrans = info.SuitEffTrans
    local attrShow = info.attrShow
    local showType = info.showType
    local showPos = info.showPos

    local suitSpEffName = "fx_ui_jiemo"
    local leftTrans = ImgTrans.parent
    self:CreateWndEffect(leftTrans,suitSpEffName,leftTrans:GetInstanceID(),100,false,nil,nil,nil,nil,nil,nil,function(effTran)
        if not effTran then return end
        local pos = LxDataHelper.ParseVector2NotEmpty(showPos)
        effTran.localPosition = Vector3.New(pos.x,pos.y,0)
    end)

    if showIcon then
        if string.isempty(attrShow) then
            if LOG_INFO_ENABLED then
                printInfoNR("打印而已，莫慌    没有配置图片，attrShow 字段")
            end
            CS.ShowObject(ImgTrans,false)
            CS.ShowObject(SuitEffTrans,false)
        else
            local spriteAtlasPath = LxResPathUtil.GetSpriteAtlasPath(gLGameLanguage:GetResName(attrShow))
            if spriteAtlasPath then
                self:SetWndEasyImage(ImgTrans,attrShow,function()
                    self:SetAnchorPos(ImgTrans, LxDataHelper.ParseVector2NotEmpty(showPos))
                    CS.ShowObject(ImgTrans,true)
                end,true)
                CS.ShowObject(SuitEffTrans,true)
            else
                if LOG_INFO_ENABLED then
                    printInfoNR("打印而已，莫慌    没有配置图片的图片资源 attrShow = " .. attrShow)
                end
                CS.ShowObject(ImgTrans,false)
                CS.ShowObject(SuitEffTrans,false)
            end
        end
    elseif showSpine then
        local spineKey = actSuitSpineShowList[showType]
        if spineKey and spineKey ~= attrShow then
            local spine = self:FindWndSpineByKey(spineKey)
            if spine then CS.ShowObject(spine:GetDisplayTrans(),false) end
        end
        if spineKey and spineKey == attrShow then
            local spine = self:FindWndSpineByKey(spineKey)
            if spine then
                actSuitSpineShowList[showType] = attrShow
                CS.ShowObject(spine:GetDisplayTrans(),true)
            end
            CS.ShowObject(SpTrans,true)
            CS.ShowObject(SuitEffTrans,true)
        else
            local spine = self:FindWndSpineByKey(attrShow)
            if spine then
                self:SetAnchorPos(SpTrans, LxDataHelper.ParseVector2NotEmpty(showPos))
                actSuitSpineShowList[showType] = attrShow
                CS.ShowObject(spine:GetDisplayTrans(),true)
                CS.ShowObject(SpTrans,true)
            else
                self:CreateWndSpine(SpTrans,attrShow,attrShow,false,function()
                    actSuitSpineShowList[showType] = attrShow
                    self:SetAnchorPos(SpTrans, LxDataHelper.ParseVector2NotEmpty(showPos))
                    CS.ShowObject(SpTrans,true)
                end)
            end
            CS.ShowObject(SuitEffTrans,true)
        end
    elseif showEffect then
        local effectKey = actSuitEffectShowList[showType]
        if effectKey and effectKey ~= attrShow then
            local effect = self:FindWndEffectByKey(attrShow)
            if effect then effect:SetVisible(false) end
            CS.ShowObject(SuitEffTrans,false)
        end
        if effectKey and effectKey == attrShow then
            local effect = self:FindWndEffectByKey(attrShow)
            if effect then
                effect:SetVisible(true)
                actSuitEffectShowList[showType] = attrShow
            end
            CS.ShowObject(SuitEffTrans,true)
        else
            local effect = self:FindWndEffectByKey(attrShow)
            if effect then
                effect:SetVisible(true)
                actSuitEffectShowList[showType] = attrShow
            else
                self:CreateWndEffect(EffTrans,attrShow,attrShow,100,false,false,50,function(dpTrans)
                    actSuitEffectShowList[showType] = attrShow
                    self:SetAnchorPos(EffTrans, LxDataHelper.ParseVector2NotEmpty(showPos))
                    dpTrans.gameObject:SetActive(true)
                end)
            end
            CS.ShowObject(SuitEffTrans,true)
        end
    end
    CS.ShowObject(EffTrans,showEffect)
end

function UIGolemMain:OnGolemRefreshWear()
    self:OnGolemSlotReq()
end

function UIGolemMain:GetGolemShowDivTransInfo(transInfo)
    local trans = transInfo.trans
    local CommonUITrans = self:FindWndTrans(trans,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
    local TargetImgTrans = self:FindWndTrans(trans,"TargetImg")
    local BtnTrans = self:FindWndTrans(trans,"Btn")
    local redPointTrans = self:FindWndTrans(trans,"redPoint")
    return{
        root = trans,
        CommonUITrans = CommonUITrans,
        IconTrans = IconTrans,
        TargetImgTrans = TargetImgTrans,
        BtnTrans = BtnTrans,
        redPointTrans = redPointTrans,
        index = transInfo.index,
    }
end

function UIGolemMain:InitEffShow()

    -- local twoSuitActEffName = "fx_golem_bg_suit_2"
    -- local suit2EffTrans = self.mSuit2EffRoot
    -- self:CreateWndEffect(suit2EffTrans,twoSuitActEffName,suit2EffTrans:GetInstanceID(),100,false)

    -- local fourSuitActEffName = "fx_golem_bg_suit_4"
    -- local suit4EffTrans = self.mSuit4EffRoot
    -- self:CreateWndEffect(suit4EffTrans,fourSuitActEffName,suit4EffTrans:GetInstanceID(),100,false)
end

function UIGolemMain:OnClickGolemIconFunc(data)
    local serverData = data.serverData
    if serverData then
        --- 魔偶属性详情界面
        gModelGolem:OpenGolemInfoTip({
            viewType = 1,
            golemData = serverData,
            wearList = self._slotServerDataList,
            heroServerData = gModelHero:GetHeroServerDataById(self._heroId),
            intensifyType = 1,
            golemList = self._slotServerDataList,
            showRedPoint = data.showRedPoint
        })
    else
        --- 魔偶仓库界面
        gModelGolem:OpenGolemWarehouse({
            viewType = 1,
            optType = ModelGolem.TYPE_OPT_WEAR,
            golemIndex = data.index,
            golemId = serverData and gModelGolem:GetGolemIdByGolemInfo(serverData),
            heroId = self._heroId,
            wearStatus = ModelGolem.OPSTYPE_TYPE_WEAR,
            optStatus = ModelGolem.OPTSTATUS_WAREHOUSE_WEAR,
        })
    end
end

function UIGolemMain:OnGolemStrongResp(pb)
    if not gModelGolem:CheckIsLvUp(pb.before,pb.after) then return end
    self:OnGolemSlotReq()
end

function UIGolemMain:OnClickGolemSplitBtnFunc()
    local heroId = self._heroId
    if not heroId then return end
    gModelGolem:OpenHeroGolemRecommendByHeroI(heroId)
end

function UIGolemMain:OnGolemAttrResp(pb)
    if pb.type ~= ModelGolem.GOLEMATTR_TYPE_HERO then return end
    if pb.id ~= self._heroId and not self._showMapping then return end
    local attrList = LUtil.ConvertCommonAttrStrToList(pb.attr)
    CS.ShowObject(self.mNotActDec,false)
    if #attrList < 1 then
        -- attrList = gModelGolem:GetConfigAttrShowList()
        CS.ShowObject(self.mNotActDec,true)
    end
    table.sort(attrList,function(a,b)
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

    local showAttrMap = {}
    for i,v in ipairs(attrList) do
        showAttrMap[v.attrRefId] = true
    end
    self._showAttrMap = showAttrMap
    self:RefreshShowAttrList(attrList)
end

function UIGolemMain:OnClickRightBtnFunc()
    if self._changeHeroOptStatus then return end
    self:ChangeHeroOpt(1)
end

function UIGolemMain:RefreshSuitList(slotServerDataList)
    self:InitGolemSuitList(slotServerDataList)
end

function UIGolemMain:OnClickWearGolemBtnFunc()
    --- 一键穿戴
    local heroId = self._heroId
    local serverData = heroId and gModelHero:GetHeroServerDataById(heroId)
    if not serverData then return end

    local refId
    local isFull,locationKeyList
    local initGolemSuitRefList = gModelGolem:GetInitGolemSuitRefList()
    local suitLocationNum = 0
    local recordLocationHaveNum = 0
    for k,v in pairs(initGolemSuitRefList) do
        refId = v.refId
        isFull,locationKeyList = gModelGolem:GetGolemListBySuitId(refId)
        if locationKeyList and #locationKeyList > 0 then
            recordLocationHaveNum = recordLocationHaveNum + 1
        end
        suitLocationNum = suitLocationNum + 1
    end

    if recordLocationHaveNum < 0 then
        gModelGeneral:OpenUIOrdinTips({refId = 310010,func = function()
            gModelGolem:JumpDreamKillWnd(self:GetWndName())
        end})
        return
    end

    local slotServerDataList = self._slotServerDataList or {}
    gModelGolem:OpenGolemWear({
        heroServerData = serverData,
        wearList = slotServerDataList,
    })
end

function UIGolemMain:RefreshSpShow(slotServerDataList)
    self:RefreshHeroSp()
    --self:RefreshSuitLH(slotServerDataList)
    self:RefreshNewSuitLH(slotServerDataList)
end

function UIGolemMain:RefreshHeroSp()
    local heroId = self._heroId
    local isHero = heroId ~= nil
    if isHero then
        local sp --= gModelHero:GetHeroPrefabNameById(heroId)
        if sp then
            if self._heroSpKey and self._heroSpKey ~= sp then
                local spine = self:FindWndSpineByKey(self._heroSpKey)
                CS.ShowObject(spine:GetDisplayTrans(),false)
            end
            local curSpine = self:FindWndSpineByKey(sp)
            if curSpine then
                CS.ShowObject(curSpine:GetDisplayTrans(),true)
                self._changeHeroOptStatus = false
            else
                self:CreateWndSpine(self.mHeroSp,sp,sp,false,function(spine)
                    spine:PlayAnimation(0,"idle",true)
                    self._changeHeroOptStatus = false
                end)
            end
            self._heroSpKey = sp
        else
            isHero = false
            self._changeHeroOptStatus = false
        end
    end
    CS.ShowObject(self.mHeroSp,isHero)
end

function UIGolemMain:RefreshShowAttrList(list)
    local uiShowAttrList = self._uiShowAttrList
    if uiShowAttrList then
        uiShowAttrList:RefreshList(list)
    else
        uiShowAttrList = self:GetUIScroll("uiShowAttrList")
        self._uiShowAttrList = uiShowAttrList
        uiShowAttrList:Create(self.mShowAttrList,list,function(...) self:OnDrawShowAttrCell(...) end)
        uiShowAttrList:EnableScroll(true,false)
    end
end

function UIGolemMain:InitMsg()

	self:WndNetMsgRecv(LProtoIds.GolemSlotResp,function(pb) self:OnGolemSlotResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.GolemAttrResp,function(pb) self:OnGolemAttrResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.GolemWearResp,function(pb) self:OnGolemWearResp(pb) end)
    --self:WndNetMsgRecv("GolemStrongResp",function(pb) self:OnGolemStrongResp(pb) end)

    self:WndEventRecv(EventNames.On_Item_Change,function() self:OnItemChange() end)

    self:WndEventRecv(EventNames.ON_GOLEM_REFRESH_WEAR,function() self:OnGolemRefreshWear() end)

    self:WndNetMsgRecv(LProtoIds.GolemBagResp,function ()  self:OnGolemSlotReq() end)

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemMain:OnGolemWearResp(pb)
    self._wearStatus = true
    if pb.opsType == 1 or pb.opsType == 3 then
        for index, id in ipairs(pb.golemId) do
            gModelGolem:SaveGolemRedRecord(id)
        end
    end
    self:OnGolemSlotReq()
end

function UIGolemMain:RefreshSuitLH(slotServerDataList)
    local actSuitList = gModelGolem:GetGolemShowActSuitList(slotServerDataList)
    self:RefreshShowEff(actSuitList)
    CS.ShowObject(self.mFourSuitRoot,false)
    CS.ShowObject(self.mLeftSuitRoot,false)
    CS.ShowObject(self.mRightSuitRoot,false)
    if #actSuitList < 1 then
        return
    end
    self:CreateLeftAndRightSuitShow(actSuitList) -- 屏蔽
end

function UIGolemMain:OnItemChange()
    local slotServerDataList = self._slotServerDataList
    if not slotServerDataList then return end
    self:RefreshView(slotServerDataList)
end

function UIGolemMain:RefreshGolemDiv(serverDataList)
    for i,v in ipairs(self._golemRootTransList) do
        local IconTrans = v.IconTrans
        local serverData = serverDataList[i]
        local showCommonUI = serverData ~= nil
        local instanceID = IconTrans:GetInstanceID()
        local baseClass = self:GetCommonIcon(instanceID)
        baseClass:Create(IconTrans)
        local golemData = {}
        if(self._showMapping)then
            local golemSuitList = gModelHero:GetMappingGolemSuitList()
            local golemSuit = golemSuitList[i]
            if(golemSuit)then
                golemData.refId = golemSuit.refId
                golemData.lvlRefId = golemSuit.lvlRefId
                golemData.lvl = gModelGolem:GetGolemLvByLevelRefId(golemSuit.lvlRefId)
                -- golemData.displayPos = gModelGolem:GetGolemElementGolemDrawingIconByRefId(golemSuit.refId)
            else
                golemData = {showEmpty = true }
            end
        elseif showCommonUI then
            golemData.refId = gModelGolem:GetGolemRefIdByGolemInfo(serverData)
            golemData.lvlRefId = gModelGolem:GetGolemLvlRefIdByGolemInfo(serverData)
            golemData.lvl = gModelGolem:GetGolemLvlByGolemInfo(serverData)
            -- golemData.displayPos = gModelGolem:GetGolemElementGolemDrawingIconByGolemInfo(serverData)
        else
            golemData = {showEmpty = true }
        end
        baseClass:SetGolemData(golemData)
        baseClass:SetPosIconShowStatus(false)
        baseClass:SetGolemDisplayPos(nil)
        baseClass:DoApply()

        local posIndex = v.index
        local TargetImgTrans = v.TargetImgTrans
        local posIcon = gModelGolem:GetGolemLocationIconByRefId(posIndex)
        self:SetWndEasyImage(TargetImgTrans,posIcon,function() CS.ShowObject(TargetImgTrans,true) end)

        local redPointTrans = v.redPointTrans
        local showRedPoint = false
        if showCommonUI then
            showRedPoint = gModelGolem:CheckGolemIsCanUpLvStatus(serverData) and not self._showMapping

            if showRedPoint then
                self._redIdRecord[serverData.id] = true
            end
        else
            showRedPoint = gModelGolem:CheckPosCanWearGolemStatus(posIndex) and not self._showMapping
        end
        CS.ShowObject(redPointTrans,showRedPoint)

        local BtnTrans = v.BtnTrans
        local data = {
            serverData = serverData,
            index = posIndex,
            showRedPoint = showRedPoint
        }
        self:SetWndClick(BtnTrans,function()
            if(self._showMapping)then
                if( not golemData.showEmpty)then
                    local argList = {golemData = {
                        itype = 6,num = 1,refId = golemData.refId
                    },viewType = 4}
                    gModelGolem:OpenGolemInfoTip(argList)
                else
                    GF.ShowMessage(string.replace(ccClientText(38426),ccClientText(38404)))
                end
            else
                self:OnClickGolemIconFunc(data)
            end
        end)

        CS.ShowObject(v.CommonUITrans,true)
    end
end

function UIGolemMain:OnDrawShowAttrCell(list,item,itemdata,itempos)
    local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
    local AttrLineTrans = self:FindWndTrans(item,"AttrLine")
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local AttrValueTrans = self:FindWndTrans(item,"AttrValue")

    local attrRefId,attrType,attrNum = itemdata.attrRefId,itemdata.attrType,itemdata.attrNum
    CS.ShowObject(AttrLineTrans,not (itempos==1 or itempos==2))
    local precision = 10000
    attrNum = math.floor(attrNum * precision + 0.5) / precision

    local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
    self:SetWndEasyImage(AttrIconTrans,attrIcon,function() CS.ShowObject(AttrIconTrans,true) end)

    local attrName = gModelHero:GetAttributeNameById(attrRefId)
    self:SetWndText(AttrNameTrans,attrName)

    local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,attrType,attrNum)
    self:SetWndText(AttrValueTrans,value)
end

function UIGolemMain:InitGolemSuitList(slotServerDataList)
    local list = self:GetGolemSuitList(slotServerDataList)

    local uiGolemSuitList = self._uiGolemSuitList
    if uiGolemSuitList then
        uiGolemSuitList:RefreshList(list)
    else
        uiGolemSuitList = self:GetUIScroll("uiGolemSuitList")
        self._uiGolemSuitList = uiGolemSuitList
        uiGolemSuitList:Create(self.mGolemSuitList,list,function(...) self:OnDrawGolemSuitCell(...) end)
    end
    local isEmpty = #list < 1
    CS.ShowObject(self.mNoActGolemSuitTxt,isEmpty)
end

function UIGolemMain:RefreshShowEff(actSuitList)
    actSuitList = actSuitList or {}
    if #actSuitList < 1 then
        CS.ShowObject(self.mSuit2EffRoot,false)
        CS.ShowObject(self.mSuit4EffRoot,false)
        return
    end
    local first = actSuitList[1]
    local actType = first.actType
    local showTwo = actType == ModelGolem.ACT_SKILL_NUM_ONE
    local showFour = actType == ModelGolem.ACT_SKILL_NUM_TWO
    CS.ShowObject(self.mSuit2EffRoot,showTwo)
    CS.ShowObject(self.mSuit4EffRoot,showFour)
end

function UIGolemMain:GetGolemSuitList(slotServerDataList)
    return gModelGolem:GetGolemActSuitShowList(slotServerDataList)
end
function UIGolemMain:SetMappingGroup()
    local heroId = self._heroId
    local mappingData = gModelResonance:CheckHeroInTargetMappingDict(heroId)
    local showMapping = false
    if(mappingData)then
        local sourceHeroId = mappingData.sourceHeroId
        showMapping = sourceHeroId and sourceHeroId~="0" and sourceHeroId~=0
        if(showMapping)then
            local heroData = gModelHero:GetHeroById(sourceHeroId)
            local heroRefId = heroData:GetRefId()
            local heroEffRef = gModelHero:GetShowEffectById(heroRefId)
            local txtTrans = self:FindWndTrans(self.mMappingGroup,"DescTxt")
            local golemmeStr = ccClientText(38404)
            local descTxtStr = not self._showMapping and string.replace(ccClientText(38412),golemmeStr,golemmeStr) or ccClientText(38423)
            self:SetWndText(txtTrans,descTxtStr)
            local iconTrans = self:FindWndTrans(txtTrans,"Icon")
            self:SetWndEasyImage(iconTrans,heroEffRef.outfitIcon)
            local changeBtnTrans = self:FindWndTrans(txtTrans,"ChangeBtn")
            local changeBtnText = self:FindWndTrans(changeBtnTrans,"Text")
            local changeBtnStrId = not self._showMapping and 38424 or 38425
            self:SetWndText(changeBtnText,ccClientText(changeBtnStrId))
            self:SetWndClick(changeBtnTrans, function()
                if(self.clickMapping)then
                    return
                end
                self._showMapping = not self._showMapping
                self:OnItemChange()
                self:OnGolemSlotReq()
                self.clickMapping = true
                LxTimer.DelayTimeCall(function()
                    self.clickMapping = false
                end,0.1)
            end)
        end
    end
    CS.ShowObject(self.mMappingGroup, showMapping)
    CS.ShowObject(self.mOptBtnList, not showMapping)
end

function UIGolemMain:OnClickUnLoadGolemBtnFunc()
    --- 一键卸下
    local heroId = self._heroId
    if not heroId then return end
    local slotServerDataList = self._slotServerDataList or {}
    local demountList = {}
    for k,v in pairs(slotServerDataList) do
        table.insert(demountList,gModelGolem:GetGolemIdByGolemInfo(v))
    end
    if #demountList < 1 then
--[[        gModelGeneral:OpenUIOrdinTips({refId = 310008,func = function()
            gModelGolem:JumpDreamKillWnd(self:GetWndName())
        end})]]
        --- http://192.168.5.2:3000/issues/10877
        --- 需求详情如下：
        --- 1、魔偶主界面，点击一键卸下按钮
        --- --#当玩家未穿戴魔偶时，点击一键卸下弹出飘字提示“您未穿戴魔偶，快去装备魔偶提升战力吧”
        --- ---#tips：34808
        GF.ShowMessage(ccClientText(34808))
        return
    end
    gModelGolem:OnGolemWearReq(ModelGolem.OPSTYPE_TYPE_DEMOUNT,heroId,demountList)
end

function UIGolemMain:OnClickHelp()
    GF.OpenWnd("UIBzTips",{refId = 501})
end

function UIGolemMain:CreateLeftAndRightSuitShow(actSuitList,isFour)
    local attrShowFunc = function(info)
        self:DisposeShowSuitFunc(info)
    end
    local leftType = ModelGolem.GOLEMDRAWING_LEFT
    local leftData = actSuitList[leftType]
    if leftData then
        local suitRefId = leftData.suitRefId
        local attrShow = suitRefId and gModelGolem:GetGolemSuitAttrShowByRefId(suitRefId)
        local attrShowType = suitRefId and gModelGolem:GetGolemSuitAttrShowTypeByRefId(suitRefId)
        local showPos = suitRefId and gModelGolem:GetGolemSuitShowPosByRefId(suitRefId)
        if attrShow and attrShowType then
            attrShowFunc({
                attrShowType =attrShowType,
                showPos = showPos,
                attrShow = attrShow,
                showType = leftType,
                ImgTrans = self.mLeftSuitImg,
                SpTrans = self.mLeftSuitSp,
                EffTrans = self.mLeftSuitEff,
                SuitEffTrans = self.mLeftEffSuit,
            })
            CS.ShowObject(self.mLeftSuitRoot,true)
        else
            CS.ShowObject(self.mLeftSuitRoot,false)
        end
    else
        CS.ShowObject(self.mLeftSuitRoot,false)
    end

    local rightType = ModelGolem.GOLEMDRAWING_RIGHT
    local rightData = actSuitList[rightType]
    -- if not rightData and isFour then
    --     rightData = leftData
    -- end
    if rightData then
        local suitRefId = rightData.suitRefId
        local attrShow = suitRefId and gModelGolem:GetGolemSuitAttrShowByRefId(suitRefId)
        local attrShowType = suitRefId and gModelGolem:GetGolemSuitAttrShowTypeByRefId(suitRefId)
        local showPos = suitRefId and gModelGolem:GetGolemSuitShowPosByRefId(suitRefId)
        if attrShow and attrShowType then
            attrShowFunc({
                attrShowType =attrShowType,
                showPos = showPos,
                attrShow = attrShow,
                showType = rightType,
                ImgTrans = self.mRightSuitImg,
                SpTrans = self.mRightSuitSp,
                EffTrans = self.mRightSuitEff,
                SuitEffTrans = self.mRightEffSuit,
            })
            CS.ShowObject(self.mRightSuitRoot,true)
        else
            CS.ShowObject(self.mRightSuitRoot,false)
        end
    else
        CS.ShowObject(self.mRightSuitRoot,false)
    end
end

function UIGolemMain:RefreshCutHeroInfo()
    self._cutHeroList = gModelHero:FilterGolemList(self._career,self._race)
    self._index = 1
    for k,v in ipairs(self._cutHeroList) do
        if self._heroId == v.id then
            self._index = k
        end
    end
end

function UIGolemMain:RefreshView(slotServerDataList)
    self:RefreshGolemDiv(slotServerDataList)
    self:RefreshSuitList(slotServerDataList)
    self:RefreshSpShow(slotServerDataList)
    self:RefreshTop()
    self:SetMappingGroup()
end

function UIGolemMain:OnClickShowAllAttrBtnFunc()
    local heroId = self._heroId
    if not heroId then return  end
    local heroAttrList = gModelHero:GetHeroAttrAndEquipInfoById(heroId)
    --local attrMap = gModelGolem:GetGolemConfigRefByKey("attrMap")
    local attrMap = self._showAttrMap
    gModelGolem:OpenGolemHeroAttrShow({
        heroId = heroId,
        attrList = heroAttrList,
        showAttrMap = attrMap
    })
end

function UIGolemMain:OnGolemSlotReq()
    local heroId = self._heroId
    if(self._showMapping)then
        heroId = gModelResonance:GetMappingOtherId(heroId)
        if(not heroId)then
            return
        end
    end
    gModelGolem:OnGolemSlotReq(heroId)
    gModelGolem:OnGolemAttrReq(ModelGolem.GOLEMATTR_TYPE_HERO,heroId)
    local heroAttrList = gModelHero:GetHeroAttrAndEquipInfoById(heroId)
    if heroAttrList then
        local attrNum = 0
        for k,v in pairs(heroAttrList) do
            attrNum = 1
            break
        end
        if attrNum == 1 then return end
    end
    gModelHero:OnHeroAttributeReq(heroId)
end

function UIGolemMain:ChangeHeroOpt(optNum)
    local index = self._index
    if not index then
        return
    end
    self._showMapping = false

    local cnt = #self._cutHeroList

    --local lastNum = gModelHero:GetHeroGolemLastNum()
    local newIndex = index + optNum
    if newIndex <= 0 then
        newIndex = cnt
    elseif newIndex > cnt then
        newIndex = 1
    end
    self._changeHeroOptStatus = false
    --local data = gModelHero:GetHeroGolemBagPos(newIndex)
    --if not data then
    --    return
    --end
    local heroData = self._cutHeroList[newIndex]

    self._heroId = heroData.id
    self._index = newIndex
    self:OnGolemSlotReq()
    self._changeHeroOptStatus = true
end

function UIGolemMain:InitData()
    self._heroId = self:GetWndArg("heroId")
    self._career = self:GetWndArg("career")
    self._race = self:GetWndArg("race")

    self:RefreshCutHeroInfo()

    --self._index = self:GetWndArg("index")
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemMain



