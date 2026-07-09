---
--- Created by Administrator.
--- DateTime: 2023/10/27 16:35:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenFront:LWnd
local UIEdenFront = LxWndClass("UIEdenFront", LWnd)
--local Tweening = DG.Tweening
--local typeofCanvas = typeof(UnityEngine.Canvas)
--local typeofUISorting = typeof(CS.YXUISorting)
--local typeSpineClick = typeof(CS.SpineClick)


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenFront:UIEdenFront()
    self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenFront:OnWndClose()

    --if not self._isEnter then
    --    gModelGeneral:ExitPlayModule()
    --end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenFront:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    self:SetHideTop()

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenFront:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitData()

    self:SetStaticContent()
    self:InitUIEvent()

    --self:WndNetMsgRecv(LProtoIds.WonderlandQuestResp,function(...) self:OnWonderlandQuestResp(...) end)
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
    self:WndEventRecv(EventNames.ON_WONDERLAND_THEME_REFRESH,function () self:RefreshUI() end)


    self:WndEventRecv(EventNames.PLAY_ENTER_WONDERLAND_EFF,function (...)
        self:PlayEnterEff(...)
    end)

    self:RefreshRed()
    self:RefreshUI()

    self:SetBg()

    self:ShowBook()
    --gModelBackflow:SetPrivileBtn(self.mBtnPrivile,1,self)

    -- local priviCom = self:GetPrivilegeCom()
    -- priviCom:Create(self.mBtnPrivile,1,self)
end

function UIEdenFront:OpenStartTip(themeId)
    GF.OpenWnd("UIEdenStartTip",{themeId = themeId})
end



function UIEdenFront:PlayEnterEff(themeId)
    CS.ShowObject(self.mUiRoot,false)
    self:PreloadImg(themeId)
    GF.OpenWnd("UISowEffect",{themeId = themeId})
end

function UIEdenFront:OnClickSpine(index)
    printInfoN("on click "..index)

    if index == 1 then
        self:MoveSpine(-1)
    elseif index == 2 then
        self:MoveSpine(1)
    elseif index == 3 then
        self:MoveSpine(0)
    end
end


--function UIEdenFront:ShowDifList()
--
--    self:DestroyWndEffectByKey("selectDif")
--
--
--    local unlockWonderDif = tonumber(LPlayerPrefs.wonderlandDif)
--
--    self._lastUnlockDif = unlockWonderDif
--    local maxUnlock = nil
--    for k,v in ipairs(self._difDataList) do
--        local isOpen = gModelFunctionOpen:CheckIsOpened(v.funId)
--        if isOpen then
--            maxUnlock = v.pattern
--        end
--    end
--    self._maxUnlock = maxUnlock
--
--    if maxUnlock == ModelWonderland.NORMAL then
--        CS.ShowObject(self.mDifList,false)
--        return
--    end
--    CS.ShowObject(self.mDifList,true)
--
--
--    local difList = self._difUiList
--    if not difList then
--        difList = self:GetUIScroll("difList")
--        self._difUiList = difList
--        difList:Create(self.mDifList,self._difDataList,function (...) self:OnDrawDif(...) end)
--    else
--        difList:RefreshList(self._difDataList)
--    end
--
--
--
--    if maxUnlock> unlockWonderDif then
--        local item = self._difUIItemList[maxUnlock]
--        if item then
--            self:DestroyWndEffectByKey("jiesuo")
--            self:CreateWndEffect(item,"fx_qjtx_jiesuo","jiesuo",100)
--            LPlayerPrefs.SetWonderlandDif(maxUnlock)
--            self._lastUnlockDif = maxUnlock
--            local seqCom = self:GetSeqCom()
--            local seq = seqCom:CreateSeq("delayRefresh")
--            seq:AppendInterval(2)
--            seq:OnComplete(function ()
--                self._difUiList:DrawAllItems()
--            end)
--            seq:PlayForward()
--        end
--    end
--end

--function UIEdenFront:OnDrawDif(list,item,itemdata,itempos)
--    local root = self:FindWndTrans(item,"root")
--    local rootIcon = self:FindWndTrans(root,"icon")
--    local rootSelect = self:FindWndTrans(root,"select")
--    local rootBg = self:FindWndTrans(root,"bg")
--    local rootUIText = self:FindWndTrans(root,"UIText")
--
--
--    self:SetWndEasyImage(rootIcon,itemdata.icon)
--    local isSelect = self._curPattern == itemdata.pattern
--    CS.ShowObject(rootSelect,isSelect)
--    self:SetWndText(rootUIText,itemdata.name)
--
--    self:SetWndClick(rootIcon,function ()
--        self:OnSelectPattern(itemdata.pattern)
--    end)
--
--    local show = itemdata.pattern<= self._maxUnlock
--    CS.ShowObject(item,show)
--    local showRoot = itemdata.pattern<= self._lastUnlockDif
--    CS.ShowObject(root,showRoot)
--
--    if isSelect then
--        self:CreateWndEffect(root,"fx_qjtx_nandu_xuanzhong","selectDif",100)
--    end
--    if not self._difUIItemList then
--        self._difUIItemList= {}
--    end
--
--    self._difUIItemList[itemdata.pattern] = item
--
--
--end
--
--function UIEdenFront:OnSelectPattern(pattern)
--    if self._curPattern == pattern then
--        return
--    end
--
--    self:DestroyWndEffectByKey("selectDif")
--
--
--    self._curPattern = pattern
--    self._difUiList:DrawAllItems()
--
--    self:SetBg()
--end

function UIEdenFront:SetBg()
    local iconPath = gModelWonderland:GetBgByPattern(self._curPattern)
    self:SetWndEasyImage(self.mBg,iconPath)

end

function UIEdenFront:SetBtnTxt(root,str)
    local text = self:FindWndTrans(root,"UIText")
    self:SetWndText(text,str)

    local addLine = -10
    if gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVietnamVersion() or gLGameLanguage:IsJapanVersion() then
        addLine = -30
    end
    self:InitTextLineWithLanguage(text, addLine)
end

function UIEdenFront:SetStaticContent()
    local str =ccClientText( 16771)
    self:SetBtnTxt(self.mTaskBtn,str)
    str = ccClientText( 16772) --"商城"
    self:SetBtnTxt(self.mShopBtn,str)
    str = ccClientText(16708)
    self:SetBtnTxt(self.mBookBtn,str)

    str = ccClientText(16777)
    self:SetBtnTxt(self.mPassCBtn,str)

    local layoutPos = Vector2.New(118.5, 154)
    if gLGameLanguage:IsThaiVersion() then
        layoutPos = Vector2.New(118.5, 170)
    end
    self:SetAnchorPos(self.mLayout, layoutPos)
end

function UIEdenFront:SetCountDown()
    local endTime = gModelWonderland:GetCountDownTime() or 0
    endTime = tonumber(endTime)/1000
    local timeLeft = endTime- GetTimestamp()
    if timeLeft < 0 then
        self:TimerStop(self._countDownKey)
    end

    local timeStr = LUtil.FormatTimespanNumber(timeLeft)
    timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
    local str = ccClientText(26200)--"%s  后重置奇境"
    str = string.replace(str,timeStr)
    self:SetWndText(self.mCountDown,str)
end

--function UIEdenFront:OnWonderlandQuestResp()
--local questdata = gModelWonderland:GetQuestData()
--if not questdata then
--	return
--end
--local questId = questdata.questId
--
--
--local cfg = gModelWonderland:GetTaskConfig(questId)
--if not cfg then
--	return
--end
--local spineName = cfg.prefabName
--if not self._questRoleKey or self._questRoleKey~= spineName then
--	if self._questRoleKey then
--		self:DestroyWndSpineByKey(self._questRoleKey)
--	end
--
--	self._questRoleKey = spineName
--	self:CreateWndSpine(self.mRole,spineName,self._questRoleKey,false,function (spine)
--		spine:SetScale(2)
--		spine:PlayAnimation(0,"idle",true)
--	end)
--end
--
--
--
--self:SetWndText(self.mPost,ccClientText(16773))
--end

function UIEdenFront:RefreshUI()

    self._curPattern = gModelWonderland:GetCurPattern()
    self._curPattern = self._curPattern == 0 and ModelWonderland.NORMAL or self._curPattern

    local str =ccClientText(16710)  -- "奇境探险"
    self:SetWndText(self.mTitle,str)

    local refreshNeed = gModelWonderland:GetWonderlandPara("refreshExpend")
    local price = LxDataHelper.ParseItem_3(refreshNeed)

    local icon = gModelItem:GetItemImgByRefId(price.itemId)
    if icon then
        self:SetWndEasyImage(self.mIcon,icon)
    end
    self:SetWndText(self.mNum,price.itemNum)
    local str =ccClientText(16711)  -- "刷新"
    self:SetWndText(self.mRefreshText,str)
    str =ccClientText(16712)  -- "出发"
    self:SetWndText(self.mStartText,str)

    local endTime = gModelWonderland:GetCountDownTime() or 0
    endTime = tonumber(endTime)/1000
    self:SetCountDown()
    if endTime> GetTimestamp() then
        self:TimerStop(self._countDownKey)
        self:TimerStart(self._countDownKey,1,false,-1)
    end

    --self._selectIndex = 0

    --self:ShowDifList()

    self:SetSelectIndex(0)

end

function UIEdenFront:OnSpineLoad(spine,index)

    local themeIdList = self:GetThemeIdList() -- gModelWonderland:GetThemeSelections()
    if not themeIdList then
        return
    end

    spine:SetVisible(false)
    spine:SetAnimationCompleteFunc(function (aniname)
        local spineData = self._spineDataMap[index]
        local anikey = self:FormatIdleKey(spineData.state,spineData.pos)
        local idleName = self._aniStateMap[anikey]
        --printInfoN("ani name complete "..aniname)
        if idleName ~= aniname then
            printInfoN("idle name start ----1  "..idleName)
            self._isMoving = false
            spine:PlayAnimationSolid(idleName,true)

        end
    end)

    if not self._spineDataMap then
        self._spineDataMap = {}
    end

    self._spineDataMap[index] = {pos = index,state = 0,spine = spine,index = index}

    local themeId = themeIdList[index]
    local themeCfg = gModelWonderland:GetThemeConfig(themeId)
    printInfoN("奇境探险",string.format("主题id %s",themeId))
    if not themeCfg then
        return
    end
    local textureName = themeCfg.themeTexture
    spine:SetUITextureEx(self._assetpath,textureName,function ()
        self._loadCnt = self._loadCnt -1
        self:CheckShowEnter()
    end)

    local canEnter = gModelWonderland:CheckCanEnterType(themeCfg.type)
    if not canEnter then
        spine:SetUIMaterial("Gray")
    end

end

function UIEdenFront:FormatIdleKey(state,pos)
    return string.format("%s|%s|idle",state,pos)
end

function UIEdenFront:GetThemeIdList()
    local themeIdList = gModelWonderland:GetThemeSelections() or {}
    local maxThemeType = gModelWonderland:GetMaxThemeType()

    local list = {}
    local themeId = nil
    for k,v in ipairs(themeIdList) do
        local themeCfg = gModelWonderland:GetThemeConfig(v)
        if themeCfg.type == maxThemeType then
            themeId = v
        else
            table.insert(list,v)
        end
    end

    if themeId then
        table.insert(list,themeId)
    end

    return list
end

function UIEdenFront:OnTryRefreshRedPoint(redPointType)
    if(redPointType == ModelRedPoint.ACTIVITY_ACTIVITY)then
        self:RefreshRed()
    end
end

function UIEdenFront:FormatStateKey(state,oldPos,newPos)
    return string.format("%s|%s|%s",state,oldPos,newPos)
end

function UIEdenFront:OnClickPassC()
    local jump = gModelWonderland:GetWonderlandPara("uniqueJump")
    gModelFunctionOpen:Jump(jump,self:GetWndName())
end


--function UIEdenFront:OnClickStart()
--
--    if self._selectIndex== 0 then
--        local str =ccClientText(16796)-- "请选择一个主题进入"
--        GF.ShowMessage(str)
--        return
--    end
--
--    local isInMap = gModelWonderland:IsInMap()
--    if not isInMap then
--
--        local themeIdList = gModelWonderland:GetThemeSelections()
--        if not themeIdList then
--            return
--        end
--
--        local themeId = themeIdList[self._selectIndex]
--        if not themeId then
--            return
--        end
--        local themeCfg = gModelWonderland:GetThemeConfig(themeId)
--        if not themeCfg then
--            return
--        end
--        --local name = ccLngText(themeCfg.name)
--
--        local pattern = self._curPattern
--        local patternName = nil
--        if pattern == ModelWonderland.NORMAL then
--            patternName = ccClientText(16793)
--        elseif pattern == ModelWonderland.HARD then
--            patternName = ccClientText(16794)
--        else
--            patternName = ccClientText(16795)
--        end
--        local name = string.format("%s[%s]",ccLngText(themeCfg.name),patternName)
--
--        if self._curPattern == ModelWonderland.TOUGH then
--            GF.OpenWnd("UIEdenEnter",{themeId = themeId,enterFunc = function ()
--                if self:IsWndClosed() then
--                    return
--                end
--
--
--                gModelWonderland:WonderlandRefreshReq(themeId,self._curPattern) --请求进入地图
--                self:PlayEnterEff(themeId)
--            end})
--        else
--            local wndId = 70009
--            local func = function()
--                if self:IsWndClosed() then
--                    return
--                end
--
--
--                gModelWonderland:WonderlandRefreshReq(themeId,self._curPattern) --请求进入地图
--                self:PlayEnterEff(themeId)
--            end
--
--            gModelGeneral:OpenUIOrdinTips({refId = wndId,func= func,para={name}})
--        end
--    else
--        GF.OpenWndBottom("UIEden")
--        self:WndClose()
--    end
--end





function UIEdenFront:OnClickShop()

    local isOpen = gModelFunctionOpen:CheckIsOpened(14600011,true)
    if not isOpen then
        return
    end


    gModelFunctionOpen:Jump(14600011)
end


function UIEdenFront:ShowBook()

    self._loadCnt = 3

    for k,v in ipairs(self._spineCfg) do
        self:CreateWndSpine(self.mBookSpine,v.name,v.key,false,function (spine)
            self:OnSpineLoad(spine,k)
        end)
    end


end

function UIEdenFront:RefreshRed()
    local list = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_PASSC)
    local activity = list[1]
    CS.ShowObject(self.mPassCBtn,activity)
    if not activity then
        return
    end
    local sid = activity.sid
    local isRed = gModelRedPoint:CheckActivityShowRed(sid)
    CS.ShowObject(self.mRedPoint,isRed)
end

function UIEdenFront:OnClickTask()
    GF.OpenWnd("UIEdenTk")
end




function UIEdenFront:OnTimer(key)
    if key == self._countDownKey then
        self:SetCountDown()
    end
end

function UIEdenFront:InitData()
    self._countDownKey = "_countDownKey"

    self._questRoleKey = "_questRoleKey"


    self._spineKeyList =
    {
        [1] = "spine1",
        [2] = "spine2",
        [3] = "spine3",
    }

    self._aniStateMap =
    {
        ["0|1|1"] = "move_xiao5",
        ["0|2|2"] = "move_xiao6",
        ["0|3|3"] = "move_xiao7",

        ["0|3|2"] = "move_xiao1",
        ["0|2|1"] = "move_xiao2",
        ["0|1|3"] = "move_xiao9",

        ["0|1|2"] = "move_xiao3",
        ["0|2|3"] = "move_xiao4",
        ["0|3|1"] = "move_xiao8",


        ["1|1|3"] = "move1",
        ["1|3|2"] = "move2",
        ["1|2|1"] = "move3",

        ["1|3|1"] = "move4",
        ["1|1|2"] = "move5",
        ["1|2|3"] = "move6",

        ["0|1|idle"] = "idle1",
        ["0|2|idle"] = "idle2",
        ["0|3|idle"] = "idle3",
        ["1|1|idle"] = "idle_da1",
        ["1|2|idle"] = "idle_da2",
        ["1|3|idle"] = "idle_da3",
    }



    self._assetpath = "Spine/Qijingtanxian_shu1"

    self._spineCfg =
    {
        [1] = {name = "Qijingtanxian_shu1",key = "spine1"},
        [2] = {name = "Qijingtanxian_shu2",key = "spine2"},
        [3] = {name = "Qijingtanxian_shu3",key = "spine3"},
    }

    local iconPathList = gModelWonderland:GetDifIconList()

    self._difDataList =
    {
        [1] =
        {
            icon = iconPathList[1],
            name =ccClientText(16793), --"普 通",
            pattern = 1,
            funId = 16800020,

        },
        [2] =
        {
            icon = iconPathList[2],
            name = ccClientText(16794), --"困 难",
            pattern = 2,
            funId = 16800030,

        },
        [3] =
        {
            icon = iconPathList[3],
            name = ccClientText(16795), --"深 渊",
            pattern = 3,
            funId = 16800040,

        }
    }


end



function UIEdenFront:InitUIEvent()
    self:SetWndClick(self.mReturnBtn,
		function ()
			if not self:WndCloseAndBack() then
				GF.OpenWndBottom("UIDTDNew")
			end
		end,LSoundConst.CLICK_CLOSE_COMMON)
    --self:SetWndClick(self.mStartBtn,function () self:OnClickStart() end,LSoundConst.CLICK_BUTTON_COMMON)
    --self:SetWndClick(self.mRefreshBtn,function () self:OnClickRefresh() end,LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mShopBtn,function () self:OnClickShop() end,LSoundConst.CLICK_BUTTON_COMMON)
    --self:SetWndClick(self.mTaskBtn,function () self:OnClickTask() end,LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBookBtn,function () self:OnClickGuideBook() end,LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mHelpBtn,function () self:OnClickHelp() end,LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mPassCBtn,function () self:OnClickPassC() end)

end


function UIEdenFront:AniOpenStartTip()
    local themeIdList = self:GetThemeIdList()
    if not themeIdList then
        return
    end

    local themeId = themeIdList[self._selectIndex]
    if not themeId then
        return
    end

    local themeRef = gModelWonderland:GetThemeConfig(themeId)
    local canEnter = gModelWonderland:CheckCanEnterType(themeRef.type,true)
    if not canEnter then
        return
    end

    self:SetWndEasyImage(self.mPageBg,themeRef.themeIcon)

    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("aniOpenStartTip")

    local cg = self:GetCanvasGroup(self.mBookPage)
    cg.alpha = 1
    self.mBookPage.localPosition = Vector3.New(-11,202,0)
    CS.ShowObject(self.mBookPage,true)

    local tween = self.mBookPage:DOLocalMoveX(500,0.3)
    seq:Append(tween)
    tween = cg:DOFade(0,0.5)
    seq:Join(tween)
    seq:OnComplete(function ()
        self:OpenStartTip(themeId)
    end)
    seq:PlayForward()
end

function UIEdenFront:GetPlayModuleBelong()
    return LPlayModuleConst.WONDERLAND
end

function UIEdenFront:OnClickHelp()
    local updateDay = gModelWonderland:GetWonderlandPara("updateDay")
    GF.OpenWnd("UIBzTips",{refId = 10,para ={updateDay}})
end

function UIEdenFront:CheckShowEnter()
    if self._loadCnt > 0 then
        return
    end

    self:SetWndClick(self.mShu_1,function ()
        self:OnClickSpine(1)
    end)

    self:SetWndClick(self.mShu_2,function ()
        self:OnClickSpine(2)
    end)

    self:SetWndClick(self.mShu_3,function ()
        self:OnClickSpine(3)
    end)

    for k,v in ipairs(self._spineCfg) do
        local spine = self:FindWndSpineByKey(v.key)
        if spine then
            spine:SetVisible(true)
            spine:PlayAnimationSolid("ruchang",false)
        end
    end


end

function UIEdenFront:OnClickGuideBook()
    local themeIdList = gModelWonderland:GetThemeSelections()
    GF.OpenWnd("UIEdenBook",{themeList = themeIdList })
end

function UIEdenFront:SetSelectIndex(index)
    self._selectIndex = index

    local themeId = nil
    local themeIdList = self:GetThemeIdList() -- gModelWonderland:GetThemeSelections()
    if themeIdList then
        themeId = themeIdList[self._selectIndex]
    end

    local str =ccClientText(26201)-- "请选择进行探险的奇境世界"
    if themeId then
        local themeCfg = gModelWonderland:GetThemeConfig(themeId)
        str = string.replace(ccClientText(26202),ccLngText(themeCfg.name))
    end

    self:SetTextTile(self.mTipBg,str)
end

---type 0 原地不动放大，1 顺时针 -1 逆时针
function UIEdenFront:MoveSpine(offset)
    if self._isMoving then
        return
    end
    self._isMoving = true

    local oldPos,newPos
    for k,v in pairs(self._spineDataMap) do
        oldPos = v.pos
        newPos = v.pos + offset
        newPos = (newPos-1)%3 + 1
        local aniKey = self:FormatStateKey(v.state,oldPos,newPos)
        local aniName = self._aniStateMap[aniKey]
        if string.isempty(aniName) then
            --printErrorN("no ani key "..aniKey)
            self._isMoving = false
        else
            v.spine:PlayAnimationSolid(aniName,false)
        end
    end
    local oldPos,newPos
    local tran

    self.mBookPage.transform:SetAsLastSibling()

    for k,v in pairs(self._spineDataMap) do
        oldPos = v.pos
        newPos = v.pos + offset
        newPos = (newPos-1)%3 + 1
        v.pos = newPos
        v.state = 1

        if newPos == 3 then
            --self._selectIndex = v.index
            self:SetSelectIndex(v.index)
            tran = v.spine:GetSpineTrans()
            tran:SetAsLastSibling()
        end
    end

    if not self._isMoving then
        self:AniOpenStartTip()
        return
    end

    self:HideWndEffect("fx_qjtx_xuanzhong")

    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("showSelect")
    seq:AppendInterval(0.8)
    seq:AppendCallback(function ()
        self:CreateWndEffect(self.mSelectEff,"fx_qjtx_xuanzhong","fx_qjtx_xuanzhong",100)
    end)
    seq:AppendInterval(0.2)
    seq:OnComplete(function ()
        self:AniOpenStartTip()
    end)

    seq:PlayForward()
end

function UIEdenFront:PreloadImg(themeId)
    --local themeId = gModelWonderland:GetThemeId()
    local themeCfg = gModelWonderland:GetThemeConfig(themeId)
    if not themeCfg then
        return
    end
    --local bgPath= themeCfg.pic
    --local paths = string.split(bgPath,",")
    --local strs =string.split(themeCfg.platform,",")
    --for k,v in ipairs(paths) do
    --    self:PreloadImage(v, function(...)  end)
    --end
    --for k,v in ipairs(strs) do
    --    self:PreloadImage(v, function(...)  end)
    --end

end

------------------------------------------------------------------
return UIEdenFront


