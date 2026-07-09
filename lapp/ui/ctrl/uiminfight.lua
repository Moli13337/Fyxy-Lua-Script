---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMinFight:LWnd
local UIMinFight = LxWndClass("UIMinFight", LWnd)
local typeGridLayoutGroup = typeof(CS.GridLayoutGroup)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeofCanvas = typeof(UnityEngine.Canvas)
local YXTweeningEase = CS.YXTweeningEase
local typeSpineClick = typeof(CS.SpineClick)
local Tweening = DG.Tweening
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMinFight:UIMinFight()
    --引用外部创建的pool， 不需要自己进行销毁
    ---@type LSimplePool
    self._simplePool = nil
    -- self._mTsTweenKey = "mTsDesBg"
    self._mZBTweenKey = "mZBTweenKey"
    self._mMainTweenKey = "mMainDesBg"
    self._dropSpineMap = {}


    self.openWinTime = 0
    self.openWinTimer = "openWinTimer"
    local sInfo = GameTable.MainInstanceConfigRef["ChangeBtnGuiderewardTime"]
    local tipsInfo = string.split(sInfo, ";")
    self.popTipsTime = tonumber(string.split(tipsInfo[1], "=")[2])
    self.showTipsTime = tonumber(string.split(tipsInfo[2], "=")[2])
    self.tipsText = ccClientText(tonumber(string.split(tipsInfo[3], "=")[2]))
    sInfo = GameTable.MainInstanceConfigRef["ChangeBtnInstance"]
    local stageInfo = string.split(sInfo, ";")
    self.minStage = tonumber(stageInfo[1])
    self.maxStage = tonumber(stageInfo[2])


    --self._timerPrivileKey = "_timerPrivileKey"
    self:SetHideActScroll()
    
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMinFight:OnWndClose()
    self:StopChangeMapDelayTimer()
    self:IsShowBarrage(false)
    -- self:TweenSeqKill(self._mTsTweenKey)
    self:TweenSeqKill(self._mMainTweenKey)
    self:TweenSeqKill(self._mZBTweenKey)
    --FireEvent(EventNames.REFRESH_PREPOST)

    if LOG_INFO_ENABLED then
        print("UIMinFight:OnWndClose()")
    end

    if self.delayTimer1 then
        LxTimer.DelayTimeStop(self.delayTimer1)
        self.delayTimer1 = nil
    end

    if self.delayTimer2 then
        LxTimer.DelayTimeStop(self.delayTimer2)
        self.delayTimer2 = nil
    end

    LWnd.OnWndClose(self)

    self.clickChallengeEff = nil
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMinFight:OnCreate()
    LWnd.OnCreate(self)


    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMinFight:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitData()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus then 
        self:SetAnchorPos(self.mLookBtn,Vector2.New(130,0))
        self:InitTextLineWithLanguage(self.mMainDesText, 40)
        self:InitTextLineWithLanguage(self.mMainLineText, 30)
    end 
    
    if self._isVie then
        local imgTran =CS.FindTrans(self.mChallengeTips,"tipsImg")
        LxUiHelper.SetSizeWithCurAnchor(imgTran,1,80)
        self:SetAnchorPos(imgTran,Vector2.New(-13,20))
        self:InitTextLineWithLanguage(self.mMainDesText, 20)

        if PRODUCT_G_VER ~= 0 then
            self:SetWndEasyImage(self.mChallengeBtn,"onhook_icon_btn_battle_ios")
        end
    end 
    self._bChallengeBtnShow = 0

    --CS.ShowObject(self.mChallengeBtn, false)

    self:SetPara()
    self:InitEvent()
    self:InitMsg()

    self:InitWndText()
    --self:InitScrollView()
    self:ShowExploreBtn()
    self:ShowQuickBtn()

    self:CreateModai()
    self:CreateSimplePool()

    --FireEvent(EventNames.REFRESH_PREPOST)

    local cd, effectName = gModelInstance:GetModaiDropEff()
    self:TimerStart(self._dropEffctCdKey, cd, false, -1)
    --self:TimerStart(self._pocketTimerKey,60,false,-1)
    self:CreateDelayPocketTimer()
    self:UpdateActivityShow()

    --self:ShowDreamVehicle()
    --FireEvent(EventNames.Examine_Fight_Wnd)
    --FireEvent(EventNames.CHANGE_MAIN_CITY_ACTIVTYSTATE,2,self:GetWndName())

    self:DelayShowFinger()

    if gModelInstance:IsShowFormationTipsBubble() then
        CS.ShowObject(self.mZhenrongBubble, true)
    end
    CS.ShowObject(self.mHeroTalkBubble, false)



    self:InitCommand()

    self:RefreshFuncBtnShow()
    --self:TimerStart(self._timerPrivileKey,0.5,false,1)

    -- local priviCom = self:GetPrivilegeCom()
    -- priviCom:Create(self.mBtnPrivile, 5, self)

    local list = gModelBackflow:GetPrivilegesTypeListByType(5)
    CS.ShowObject(self.mPrivileMar, list ~= nil)

    --【Z主线推图】屏蔽主线困难及噩梦模式
    -- self:RefreshDifficultyLvlGroup()--推图试炼难度选项
    --

    if gModelInstance:IsImproveTag() then
        -- self:ShowChapterBubble()
        gModelInstance:ShowImproveWnd(self.curDiffLvlIndex)
    else
        CS.ShowObject(self.mBubbleShow, false)
    end

    self:DelaySendFinish(0.2)

    self:RefreshPartShow()

    self.challengeBtnEff = self:CreateWndEffect(self.mChallengeBtn, "fx_ui_maoxiananniu_cz", "fx_ui_maoxiananniu_cz", 100, false, false)

    -- self:UpdateBlockMiniGame()

    self:TimerStart(self.openWinTimer, 1, false, -1)

    local level = GameTable.SnakeRoleConfigRef['strongLvVariety']
    local isShowStrong = gModelPlayer:GetPlayerLv() < level
    local y = isShowStrong and 41 or 105
    self.mOnlineRewards.localPosition = Vector3(self.mOnlineRewards.localPosition.x, y)

    self:UpdateCanvas()
end

function UIMinFight:OnPlayerLvChange()
    self:SetFightBtn()
end

-- 【G公共支持】删掉小游戏功能
-- function UIMinFight:OnClickMinGameBtnFunc()
--     local actData = gModelActivity:GetMiniGameActData()
--     if not actData then
--         return
--     end

--     local moreInfo = JSON.decode(actData.moreInfo)
--     local gameType = moreInfo.quoteMinGame
--     gameType = tonumber(gameType)
--     if gameType == ModelActivity.MINIGAME_1001 then
--         gModelMinGame:EnterGame()
--     elseif gameType == ModelActivity.MINIGAME_2001 then
--         GF.OpenWnd("WndSleepModeSel")
--     end

-- end

function UIMinFight:InitMsg()
    self:WndEventRecv(EventNames.ON_CHAT_BARRAGE_WIN, function() self:OnClickBarrage() end)
    --self:WndEventRecv(EventNames.CLOSE_CURRENT_WND,function () self:WndClose() end)
    self:WndEventRecv(EventNames.PLACE_TIME_REFRESH, function() self:SetPocketTime() end)
    --self:WndEventRecv(EventNames.ON_GET_NEW_HANG_MSG,function () self:DelayUpdateMsg() end)
    --[[
      self:WndEventRecv(EventNames.BTIDLE_MONSTER_DEAD,function (...) self:OnMonsterDie(...) end)
    --]]
    self:WndEventRecv(EventNames.BTIDLE_DROP_FLY, function(...) self:OnDropLittleIconFly(...) end)
    self:WndEventRecv(EventNames.BTIDLE_SEARCH_MON, function(...) self:OnBtIdleSearchMon(...) end)

    --self:WndEventRecv(EventNames.On_REMOVE_HANG_MSG,function (data) self:OnRemoveHangMsg(data) end)
    self:WndEventRecv(EventNames.ON_PLAYER_LEVEL_CHANGE, function()
        self:OnPlayerLvChange()
        self:CheckShowFinger()
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function() self:ShowExploreBtn() end)

    --【Z主线推图】屏蔽主线困难及噩梦模式
    -- self:WndEventRecv(EventNames.MAINFIGHT_CHANGE_DIFF_LVL,function (diffLvl) self:OnChangeDiffLvl(diffLvl) end)
    --

    self:WndNetMsgRecv(LProtoIds.InstanceSwitchResp, function() self:OnPlayerInstanceResp() end)
    self:WndNetMsgRecv(LProtoIds.PlayerInstanceResp, function() self:OnPlayerInstanceResp() end)


    ---屏蔽击杀怪物的界面统计
    --self:WndNetMsgRecv(LProtoIds.InstanceKillTimeResp,function () self:OnInstanceKillTimeResp() end)

    --【Z主线推图】屏蔽主线困难及噩梦模式
    -- self:WndNetMsgRecv(LProtoIds.CombatResultSureResp,function (pb)
    --     if(	gModelInstance:CheckCombatTypeIsDiffMainFight(pb.combatType))then
    --         self:OnChangeDiffLvl()
    --     end
    -- end)
    --

    gModelInstance:OnInstanceExtraContentReq()
    gModelInstance:OnPlayerInstanceReq()

    ---屏蔽击杀怪物的界面统计
    --if not gModelInstance:IsNotReqNotifyKillMon() then gModelInstance:OnInstanceKillTimeReq() end

    --gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_ON_HOOK_DEFEND)
    --gModelPlayer:ReqFigureData(ModelPlayer.PLAY_IMAGE_HANG)

    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function() self:UpdateActivityShow() end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb) self:UpdateOnlineActivityData(pb) end)
    self:WndNetMsgRecv(LProtoIds.InstanceRewardResp, function(...) gModelInstance:InstanceFreeTheGirdReq() end)
    self:WndNetMsgRecv(LProtoIds.InstanceFreeTheGirdResp, function(pb)
		self.theGirdPos = #pb.position
		self:UpdateMainLineAward()
	end)

    --self:WndEventRecv(EventNames.ON_QUEST_CHANGE,function() self:ShowDreamVehicle() end)
    --self:WndEventRecv(EventNames.ON_DREAM_ALL_UNLOCK,function() self:ShowDreamVehicle() end)
    self:WndEventRecv(EventNames.ON_GUIDE_START, function()
        local key = "guideFinger"
        self:DestroyWndEffectByKey(key)
    end)

    self:WndEventRecv(EventNames.ON_OPERATION_TIME_CHANGE, function()
        self:CheckShowFinger()
    end)

    self:WndEventRecv(EventNames.BTIDLE_HERO_BUBBLE, function(...)
        self:OnShowHeroBubble(...)
    end)

    -- self:RegisterRedPointFunc(ModelRedPoint.MAIN_AWARD,function (pb)
    --     local showB = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.MAIN_AWARD)
    --     CS.ShowObject(self.mTsRedPoint,showB)
    -- end)

    self:WndEventRecv(EventNames.HIDE_WND_BY_PLOT, function(value)
        self:SetWndVisible(not value)
    end)

    self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE, function()
        self:RefreshFuncBtnShow()
        self:RefreshPartShow()
    end)
end

function UIMinFight:CreateSimplePool()
    --local simplePool = LSimplePool:New()
    --simplePool:InitPool(self.mDropPool)
    local simplePool = GF.CreateSimplePool(LPoolTagConst.TAG_BTIDLE_DROP, true)
    if simplePool then
        local spineName = "JinbiUI"
        local spinePath = "Spine/Jinbi" .. "/" .. spineName
        local args = simplePool:MakeArgs(spinePath, spineName, nil, LPoolItemConst.TYPE_SPINE_UI)
        simplePool:InitPoolItem(args)
    end
    self._simplePool = simplePool
end

function UIMinFight:ChallengeBtnEvent()
    -- self.challengeBtnEff:SetVisible(false)
    -- if self.clickChallengeEff then
    --     self.clickChallengeEff:SetVisible(false)
    --     self.clickChallengeEff:SetVisible(true)
    -- else
    --     self.clickChallengeEff = self:CreateWndEffect(self.mChallengeBtn, "fx_ui_maoxiananniu_dj", "fx_ui_maoxiananniu_dj", 100, false, false)
    -- end
    gModelInstance:TryGotoChallenge(true)
    -- LxTimer.DelayTimeCall(function()
    --     gModelInstance:TryGotoChallenge(true)
    --     -- if self.clickChallengeEff then
    --     --     self.clickChallengeEff:SetVisible(false)
    --     --     -- self.challengeBtnEff:SetVisible(true)
    --     -- end
    -- end, 0.2)
end

function UIMinFight:DelayShowFinger()
    self:TimerStop(self._delayShowFinger)
    self:TimerStart(self._delayShowFinger, 1, false, -1)
end

function UIMinFight:UpdateActivityShow()
    -- self:RefreshMinGameShow()【G公共支持】删掉小游戏功能
    local online = gModelActivity:GetOnlineActivity()
    if (not online or online.status == 3) then
        CS.ShowObject(self.mOnlineRewards, false)
        if online then
            self._activityItemList[online.sid] = nil
        end
        self:TimerStop(self._dropOnlineKey)
        return
    end
    self._activityItemList[online.sid] = self.mOnlineRewards

    local icon = self:FindWndTrans(self.mOnlineRewards, "OnlineBg/icon")

    if (not self._bReqOnline) then
        CS.ShowObject(self.mOnlineRewards, false)
        gModelActivity:OnActivityPageReq(online.sid)
        self._bReqOnline = true
        self:RegisterRedPointFunc(ModelRedPoint.ACTIVITY_TYPE4, function(pb)
            self:RefreshActivityRed()
        end)
    else
        CS.ShowObject(self.mOnlineRewards, true)
    end
end

function UIMinFight:UpdateOnlineActivityData(pb)
    local online = gModelActivity:GetOnlineActivity()
    if not online then
        self:TimerStop(self._dropOnlineKey)
        return
    end
    local sid = pb.sid
    if not self._activityItemList[sid] then
        return
    end
    if online.sid ~= sid then
        return
    end
    self._onlineSid = sid
    local onlineData = gModelActivity:GetOnlineRewardData(sid)
    local curIndex = onlineData and onlineData.curIndex or 0
    if curIndex > 0 then
        self._onlineData = onlineData
        local goal = onlineData.goal
        local schedule = onlineData.schedule
        local status = onlineData.status
        local curEntry = onlineData.curEntry
        local onlineShowEntryId = self._onlineShowEntryId
        local leftTime = 0
        local passTime = Time.RawUnityEngineTime.realtimeSinceStartup - onlineData.time
        if passTime < 0 then passTime = 0 end
        if status == 0 then
            leftTime = goal - schedule - passTime
        end
        if leftTime <= 0 then
            self:SetWndText(self.mOnlineText, ccClientText(14801))
            self:TimerStop(self._dropOnlineKey)
        else
            self:TimerStart(self._dropOnlineKey, 0.3, false, -1)
            self._onlineLeftTime = goal - schedule
            self:SetOnlineTime()
        end

        if curEntry.entryId ~= onlineShowEntryId then
            self._onlineShowEntryId = onlineShowEntryId
            local items = curEntry.items
            local reward = items[1]
            CS.ShowObject(self.mOnlineRewards, true)
            local icon = self:FindWndTrans(self.mOnlineRewards, "OnlineBg/icon")
            local iconStr = gModelGeneral:GetCommonItemImgRef(reward)
            self:SetWndEasyImage(icon, iconStr)
        end
    end
end

function UIMinFight:CreatePocketTimer()
    self:SetPocketTime()
    --self:ShowPocketSliderEff()
    self:TimerStart(self._pocketTimerKey, 60, false, -1)
end

function UIMinFight:RefreshActivityRed()
    for k, v in pairs(self._activityItemList) do
        local item = v
        local RedPoint = CS.FindTrans(item, "redPoint")
        local showRed = self:CheckShowRed(k)
        CS.ShowObject(RedPoint, showRed)

        gModelRedPoint:ShowPointRed(ModelRedPoint.RISK_ONLINE, showRed)
    end
end

function UIMinFight:CreateModaiEffect()
    local spine = self:FindWndSpineByKey(self._pocketKey)
    if not spine then
        return
    end

    local effectName = gModelInstance:GetModaiEffect()

    if self._modaiEffectKey == effectName then
        return
    end
    if self._modaiEffectKey then
        --print("destroy  "..self._modaiEffectKey)
        self:DestroyWndEffectByKey(self._modaiEffectKey)
        self._modaiEffectKey = nil
    end

    local root = spine:GetSpineTrans()
    if effectName and root then
        --printInfoN("effectname ",effectName)
        self._modaiEffectKey = effectName
        self:CreateWndEffect(self.mJinBiEffect, effectName, self._modaiEffectKey, 100, false, false, 2)
    end
end

--【Z主线推图】删除冒险玩法中的主角形象设置功能
-- function UIMinFight:OpenFormationSetting()
--     --[[    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_ON_HOOK_DEFEND,{})
-- 		self:WndClose()]]
--     GF.OpenWnd("UISelFightSaga")
-- end
--

function UIMinFight:InitWndText()
    local text

    --【Z主线推图】删除冒险玩法中的主角形象设置功能
    -- text = self:FindWndTrans(self.mFormationBtn,"text")
    -- self:SetWndText(text,ccClientText(10133))
    --

    --text = self:FindWndTrans(self.mBianqiangBtn,"text")
    --self:SetWndText(text,ccClientText(10134))

    text = self:FindWndTrans(self.mBarrageInputBtn, "text")
    self:SetWndText(text, ccClientText(10145))

    -- 【G挂机功能】挂机功能界面布局调整（客户端）
    -- text = self:FindWndTrans(self.mZhenrongBtn, "text")
    -- self:SetWndText(text,ccClientText(10147))
    local textTran = self:FindWndTrans(self.mChallengeBtn, 'layout/Text')
    self:SetWndText(textTran, ccClientText(20422))

    text = self:FindWndTrans(self.mSearchNode, "text")
    self:SetWndText(text, ccClientText(10772))
    CS.ShowObject(self.mSearchNode, false)

    text = self:FindWndTrans(self.mZhenrongBubble, "text")
    self:SetWndText(text, ccClientText(10782))
    self:InitTextSizeWithLanguage(text, -2)
    self:InitTextLineWithLanguage(text, -20)
    CS.ShowObject(self.mZhenrongBubble, false)
    self:SetTowee(self.mZhenrongBubble, self._mZBTweenKey)
    local _, limit = gModelInstance:CheckShowTip(self.curDiffLvlIndex)
    local str = string.replace(ccClientText(19911), limit) --"升级攻略"
    self:SetWndText(self.mTipText, str)

    self:SetWndText(self.mBubbleText, ccClientText(10787))

    -- self:SetTextTile(self.mBlockMiniGame, ccClientText(43515))

    self:SetWndText(CS.FindTrans(self.mChallengeTips, "tipsImg/Text"), self.tipsText)
end

--【Z主线推图】屏蔽主线困难及噩梦模式
-- function UIMinFight:SetDiffLvlBtn(index)
--     local diffLvlTrans = self.mDifficultyLvl
--     local lvlTrans = self:FindWndTrans(diffLvlTrans,"LvlList/Lvl"..index)
--     local nameTrans = self:FindWndTrans(lvlTrans,"NameTxt")
--     local lockImgTrans = self:FindWndTrans(lvlTrans,"LockImg")
--     local patternCfg = gModelInstance:GetInstancePattern(index)
--     local showDiffLvlGroup = index == 1 and true or gModelInstance:CheckDiffLvlFuncIsOpen(index)
--     self:SetWndText(nameTrans,ccLngText(patternCfg.name)..ccClientText(16326))
--     self:SetWndClick(lvlTrans, function()
--         if(showDiffLvlGroup)then
--             self:OnClickDiffLvlBtn(diffLvlTrans,index)
--         else
--             gModelInstance:ShowDiffLvlOpenTips(index)
--         end
--         self:OnClicDiffLvlArrow()
--     end)
--     CS.ShowObject(lockImgTrans,not showDiffLvlGroup)
-- end

--【Z主线推图】屏蔽主线困难及噩梦模式
-- function UIMinFight:OnClickDiffLvlBtn(diffLvlTrans,index, isInit)
--     self.diffLvlPatternCfg = gModelInstance:GetInstancePattern(index)
--     local curLvlTrans = self:FindWndTrans(diffLvlTrans,"CurLvl")
--     self:SetWndEasyImage(curLvlTrans,self.diffLvlPatternCfg.icon)
--     for i = 1, 3 do
--         local lvlTrans = self:FindWndTrans(diffLvlTrans,"LvlList/Lvl"..i)
--         local seleImg = self:FindWndTrans(lvlTrans,"SeleImg")
--         CS.ShowObject(seleImg,i == index)
--     end
--     self.curDiffLvlIndex = index
--     gModelInstance:SetMainFightLevelOfDifficulty(index)
--     if(not isInit)then
--         GF.OpenWndWait("UIMinFightOpenEffect")
--     else
--         self:SetCurDiffLvlBtn(self.curDiffLvlIndex)
--         self:SetCurDiffLvlTitle(self.curDiffLvlIndex)
--     end
-- end
--

--【Z主线推图】屏蔽主线困难及噩梦模式
-- function UIMinFight:OnChangeDiffLvl(diffLvl)
--     self.curDiffLvlIndex = (diffLvl and diffLvl[1])and diffLvl[1] or self.curDiffLvlIndex
--     self:SetCurDiffLvlBtn(self.curDiffLvlIndex)
--     self:SetCurDiffLvlTitle(self.curDiffLvlIndex)
--     gModelInstance:ChangeMapState(true)
--     gModelInstance:OnInstanceExtraContentReq()
--     gModelInstance:OnPlayerInstanceReq()
--     GF.ChangeMap("LFightIdleMap")
-- end
--

--【Z主线推图】屏蔽主线困难及噩梦模式
-- function UIMinFight:OnClicDiffLvlArrow()
--     self.diffLvlArrowOpen = not self.diffLvlArrowOpen
--     local diffLvlTrans = self.mDifficultyLvl
--     local arrow = self:FindWndTrans(diffLvlTrans,"arrow")
--     local bgTrans = self:FindWndTrans(diffLvlTrans,"Bg")
--     local scaleX = not self.diffLvlArrowOpen and -1 or 1
--     local posX = not self.diffLvlArrowOpen and 53.3 or 228
--     arrow.localScale = Vector3.New(scaleX,1,1)
--     self:SetAnchorPos(arrow,Vector2.New(posX,-25.3))
--     local bgWidth = not self.diffLvlArrowOpen and 115 or 290
--     bgTrans.sizeDelta = Vector2.New(bgWidth,78)
--     local diffLvlTrans = self.mDifficultyLvl
--     local LvlList = self:FindWndTrans(diffLvlTrans,"LvlList")
--     CS.ShowObject(LvlList,self.diffLvlArrowOpen)
--     CS.ShowObject(self.mDiffLvlHideClickImg, self.diffLvlArrowOpen)
-- end
--【Z主线推图】屏蔽主线困难及噩梦模式
-----------------------------------------------------
---【G公共支持】删掉小游戏功能
-- function UIMinFight:RefreshMinGameShow()
--     local actData = gModelActivity:GetMiniGameActData()
--     local show = actData ~= nil

--     if show then
--         local moreInfo = JSON.decode(actData.moreInfo)
--         local gameType = moreInfo.quoteMinGame
--         if gameType == ModelActivity.GAME_TYPE_DOG then
--             show = false
--         end
--     end

--     if show then
--         self:SetWndText(self.mMinGameBtnName,actData.title)
--     end
--     CS.ShowObject(self.mMinGameMar,show)
--     CS.ShowObject(self.mMinGameBtn,show)
--     local effName = "fx_daomengkongjianrukou"
--     self:DestroyWndSpineByKey(effName)
--     if show then
--         self:CreateWndSpine(self.mMinGameEffRoot,effName,effName,100,function(dp)
--             dp:SetRaycastTarget(false)
--         end,false)
--     end
-- end

function UIMinFight:OnClickBarrageInput()
    local para = { channel = ModelChat.CHANNEL_RISK, isShow = self._isBarrageShow }
    gModelChat:OnClickOpentBarrageWin(para)
end

function UIMinFight:CreateModaiDropEff()
    if self._isDropEffCd then
        return
    end
    local spine = self:FindWndSpineByKey(self._pocketKey)
    if not spine then
        return
    end

    local root = spine:GetSpineTrans()
    self._isDropEffCd = true
    local cd, effectName = gModelInstance:GetModaiDropEff()
    if effectName then
        self:CreateWndEffect(root, effectName, self._dropEffctKey, 100)
    end
end

function UIMinFight:InitEvent()
    -- self:SetWndClick(self.mMinGameBtn,function() self:OnClickMinGameBtnFunc() end)【G公共支持】删掉小游戏功能
    -- 【G挂机功能】挂机功能界面布局调整（客户端）
    -- self:SetWndClick(self.mShaGuaiJinduBtn, function ()
    --     GF.ShowMessage(ccClientText(10773))
    -- end)
    -- CS.ShowObject(self.mShaGuaiJinduBtn, false)

    -- 【G挂机功能】挂机功能界面布局调整（客户端）
    -- self:SetWndClick(self.mZhenrongBtn, function ()
    --     local para = {
    --         setTargetType = LCombatTypeConst.COMBAT_MAIN,
    --         returnFunc = function()
    --             FireEvent(EventNames.CHANGE_MAIN_BTN,3)
    --             GF.ChangeMap("LFightIdleMap")
    --             --GF.OpenWndBottom("UIMinFight")
    --         end
    --     }
    --     CS.ShowObject(self.mZhenrongBubble, false)
    --     gModelFormation:OpenSetFormationWnd(para)
    -- end)

    -- 挑战按钮事件
    self:SetWndClick(self.mChallengeBtn, function()
        self:ChallengeBtnEvent()
    end, LSoundConst.CLICK_FIGHT)
    LxUnity.SetPointerDown(self.mChallengeBtn.gameObject, function()
        self:CreateWndEffect(self.mChallengeBtn, "fx_ui_maoxiananniu_dj", "fx_ui_maoxiananniu_dj", 100, false, false)
	end)
	LxUnity.SetPointerUp(self.mChallengeBtn.gameObject, function()
        self:DestroyWndEffectByKey("fx_ui_maoxiananniu_dj")
	end)

    self:SetWndClick(self.mOnlineRewards, function()
        local sid = self._onlineSid
        if not sid then return end
        local modelId = gModelActivity:GetActivityModeIdBySid(sid)
        if modelId == ModelActivity.MODEL_ACTIVITY_TYPE_74 then
            GF.OpenWnd("UIActOnlineAwards", { sid = sid })
            -- elseif modelId == ModelActivity.MODEL_ONLINEREWARD then
            --     GF.OpenWndBottom("UIActOnlineWin")
        end
    end)
    self:SetWndClick(self.mMainLineRewards, function()
        GF.OpenWnd("UIMinLineAwards2")
    end)
    self:SetWndClick(self.mMainDesBg, function()
        GF.OpenWnd("UIMinLineAwards2")
    end)
    -- self:SetWndClick(self.mMainLineTsRewards,function()
    --     GF.OpenWnd("UIMinLineAwards2")
    -- end)
    -- self:SetWndClick(self.mTsDesBg,function()
    --     GF.OpenWnd("UIMinLineAwards2")
    -- end)
    -- self:SetWndClick(self.mTsDesBgEn,function()
    --     GF.OpenWnd("UIMinLineAwards2")
    -- end)
    self:SetWndClick(self.mTitle, function()
        self:OnClickTitle()
    end)

    --【Z主线推图】删除冒险玩法中的主角形象设置功能
    -- self:SetWndClick(self.mFormationBtn,function ()
    --     self:OpenFormationSetting()
    -- end)
    -- CS.ShowObject(self.mFormationBtn, false)
    --

    --self:SetWndClick(self.mBianqiangBtn,function()
    --    GF.OpenWndBottom("UIGwWin")
    --end)

    self:SetWndClick(self.mExploreBtn, function() self:OnClickExplore() end)

    self:SetWndClick(self.mQuickBtn, function()
        --gModelInstance:SetQuickClicked()
        GF.OpenWnd("UIQuk")
    end)

    --self:SetWndClick(self.mClickArea,function () gModelInstance:OpenUIGjAward() end)
    self:SetWndClick(self.mBarrageInputBtn, function() self:OnClickBarrageInput() end)

    self:SetWndClick(self.mUpLvTip, function() self:ShowUpLvTipWnd() end)


    self:SetWndClick(self.mBlockMiniGame, function()
        GF.OpenWnd("UIBlockMiniGameLevel")
    end)

    self:WndEventRecv("UpdateGradeBigRewardShow", function(isShow)
        self:UpdateTopLeftShow(isShow)
    end)

    self:WndEventRecv(EventNames.SHOW_MAIN_GRADE, function(...)
        self:UpdateMainLineAwardPos()
    end)
    self:WndNetMsgRecv(LProtoIds.QuestReceiveResp, function(...)
        self:UpdateMainLineAwardPos()
    end)
end

function UIMinFight:GenerateFallenTween(dropKey, startPos, endPos)
    local time = 0.5
    local dropDpData = self._dropSpineMap[dropKey]
    local dpSpine = dropDpData.spine
    local curveFun = LCurveUtil.PopAndFallen(startPos, endPos, time)
    local tweener = YXTween.TweenFloat(0, 1, time, function(t)
        local p = curveFun(t)
        if dpSpine and dpSpine:IsDpValid() then
            dpSpine:GetDisplayTrans().position = p
        else
            dropDpData.pos = p
        end
    end)
    tweener:SetEase(YXTweeningEase.InOutQuad)
    return tweener
end

function UIMinFight:CreateModaiAniEff(aniName)
    if not self._modaiAniEffNameMap then
        self._modaiAniEffNameMap = {
            shaking = "fx_modai_shaking",
            spray = "fx_modai_spray",
            spit = "fx_modai_spit",
        }
    end
    local lbl = string.sub(aniName, 1, -2)
    local effName = self._modaiAniEffNameMap[lbl]
    if string.isempty(effName) then
        return
    end
    if self._modaiAniEffKey ~= effName then
        self:DestroyWndEffectByKey(self._modaiAniEffKey)
    end
    self._modaiAniEffKey = effName
    self:CreateWndEffect(self.mJinBiEffect, effName, self._modaiAniEffKey, 100, false, false, 2)
end

function UIMinFight:OnClickTitle()
    local battleNode = gModelInstance:GetRawBattleNode()
    if battleNode == -1 then
        local chapter = gModelInstance:GetNextChapterId()
        local showTip = false
        if chapter > 0 then
            local node = gModelInstance:GetChapterFirstNode(chapter)
            local canEnter, limit = gModelInstance:CanEnterBattleNode(node)
            if canEnter then
                showTip = true
            end
        end

        -- GF.OpenWnd("UIGolbMl", { showTip, self.curDiffLvlIndex })
        GF.OpenWndWait("UIWaitZC", { hideTime = 1 })
        self.delayTimer1 = LxTimer.DelayTimeCall(function()
            GF.OpenWnd("UIGolbMlNew", { showTip, self.curDiffLvlIndex })
            self.delayTimer1 = nil
        end, 0.7)
    else
        -- GF.OpenWnd("UIGolbMl", { nil, self.curDiffLvlIndex })
        GF.OpenWndWait("UIWaitZC", { hideTime = 1 })
        self.delayTimer2 = LxTimer.DelayTimeCall(function()
            GF.OpenWnd("UIGolbMlNew", { showTip, self.curDiffLvlIndex })
            self.delayTimer2 = nil
        end, 0.7)
    end
end

function UIMinFight:InitCommand()
    --local channel = ModelChat.CHANNEL_RISK
    --self._isBarrageShow = gModelChat:GetBarrageIsShow(channel)
    --self._isBarrageShow = not self._isBarrageShow
    self._isBarrageShow = false
    self:OnClickBarrage(true)

    -- local isHideReward = gModelGrade:GetIsHideReward()
    -- self:SetAnchorPos(self.mTopLeft, Vector2.New(14, isHideReward and -134 or -250))
    -- local isShow = gModelGrade:GetIsShow()
    -- self:SetAnchorPos(self.mTopLeft, Vector2.New(14, isShow and -250 or -134))
end

function UIMinFight:SetFightBtnText(str)
    local textTran = self:FindWndTrans(self.mChallengeBtn, 'layout/Text')
    -- self:SetWndText(textTran,str)

    -- self:InitTextSizeWithLanguage(textTran,-2)
end

--function UIMinFight:InitScrollView()
--    local uiList = self._uiList
--    if not uiList then
--        uiList = UIListWrap:New()
--        uiList:Create(self,self.mChallengeList)
--        uiList:SetFuncOnItemDraw(function(...)
--            self:OnDrawMsg(...)
--        end)
--        uiList:SetFuncOnItemReturn(function (...) self:OnMsgItemReturn(...) end)
--        self._uiList = uiList
--    end
--    self:UpdateMsg()
--end

--function UIMinFight:OnDrawMsg(list,item, itemdata, itempos, fromHeadTail)
--    local txtTrans = CS.FindTrans(item,"MessageTxt")
--    if not txtTrans then
--        return
--    end
--
--    local data = itemdata.data
--
--    if data.msgType == 1 then
--        self:SetWndText(txtTrans,data.text)
--    elseif data.msgType==2 then
--
--        local uiHyper =self._uiHyperList[itemdata.index]
--        if not uiHyper then
--            uiHyper= UIHyperText:New()
--            self._uiHyperList[itemdata.index]= uiHyper
--        end
--
--        uiHyper:Create(txtTrans)
--        local isFirst = true
--        local stringBuilder ={}
--        for k,v in ipairs(data.meta) do
--            if isFirst then
--                isFirst = false
--            else
--                table.insert(stringBuilder,",")
--            end
--            local str = ""
--            local name =""
--            local color ="white"
--            if v.type == 1 then
--                name = gModelItem:GetNameByRefId(v.itemId)
--                name = uiHyper:AddHyper(name,{func =function (...) self:OpenTipWnd(...)  end,para =v})
--                color ="#"..gModelItem:GetItemNameColorString(v.itemId)
--            elseif v.type ==2 then
--                name = gModelHero:GetHeroNameByRefId(v.itemId)
--                name = uiHyper:AddHyper(name,{func =function (...) self:OpenTipWnd(...)  end,para =v})
--                color ="#"..gModelHero:GetHeroNameColorByRefId(v.itemId)
--            elseif v.type == 3 then
--                name = gModelEquip:GetNameByRefId(v.itemId)
--                name = uiHyper:AddHyper(name,{func =function (...) self:OpenTipWnd(...)  end,para =v})
--                color ="#"..gModelEquip:GetEquipColorByRefId(v.itemId,true)
--            end
--            --local colorName = LUtil.FormatColorStr(name,color)
--            --local colorCount =  LUtil.FormatColorStr(v.count,color)
--            str = string.format("%s*%s",name,v.count)
--            str = LUtil.FormatColorStr(str,color)
--            table.insert(stringBuilder,str)
--        end
--        local itemStr = table.concat(stringBuilder)
--        local finalStr = string.replace(data.text,itemStr)
--
--        self:SetWndText(txtTrans,finalStr)
--    end
--
--    if not self._curShowMsg then
--        self._curShowMsg ={}
--    end
--    self._curShowMsg[itempos]= itemdata.data
--end


function UIMinFight:OpenTipWnd(para)
    local data =
    {
        itemId = para.itemId,
        itemNum = para.count,
        itemType = para.type
    }
    gModelGeneral:ShowCommonItemTipWnd(data)
end

function UIMinFight:GeneratePopUpTween(item, startPos, endPos, topPos)
    local tweenTime = 0.6
    local fromX = startPos.x
    local toX = endPos.x
    local fromY = startPos.y
    local topY = topPos.y
    local toY = endPos.y
    local tweener = YXTween.TweenFloat(0, 1, tweenTime, function(t)
        local x = Mathf.Lerp(fromX, toX, t)
        local y = 0
        local time = t * 2
        if (time > 1) then
            --quadEaseIn
            time = time - 1
            time = time * time
            y = Mathf.Lerp(topY, toY, time)
        else
            --quadEaseOut
            time = time * (2 - time)
            y = Mathf.Lerp(fromY, topY, time)
        end
        item.transform.position = Vector3(x, y, 0)
    end)
    tweener:SetEase(YXTweeningEase.Linear)
    return tweener
end

function UIMinFight:OnClickBarrage(isOne)
    self._isBarrageShow = not self._isBarrageShow
    local channel = ModelChat.CHANNEL_RISK
    self:IsShowBarrage(self._isBarrageShow)
    CS.ShowObject(self.mBarrageMask, not self._isBarrageShow)
    if (not isOne) then
        gModelChat:SetBarrageSav(channel, self._isBarrageShow)
    end
end

function UIMinFight:OnMonsterDie(pos)
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local uiCamera    = LGameUI.GetUICamera()
    local screenPos   = sceneCamera:WorldToScreenPoint(Vector3(pos.x, pos.y, 0)) --Vector3
    local startPos    = uiCamera:ScreenToWorldPoint(screenPos)
    self:ShowKillMonEff(startPos)
end

function UIMinFight:StopHeroSayBubbleTimer()
    if self._heroSayBubbleTimer then
        LxTimer.DelayTimeStop(self._heroSayBubbleTimer)
        self._heroSayBubbleTimer = nil
    end
end

function UIMinFight:ShowExploreBtn()
    local isShowBtn = gModelFunctionOpen:CheckIsShow(ModelFunctionOpen.EXPLORE_TASK)
    CS.ShowObject(self.mExploreBtn, isShowBtn)
    if not isShowBtn then return end

    local max = gModelExplore:GetMaxExplorePoint() --+ gModelGrade:GetPrivilegeEff(39)
    local cur = gModelExplore:GetCurExplorePoint()
    local porgress = 0
    if max > 0 then
        porgress = cur / max
    end
    local progressTran = self:FindWndTrans(self.mExploreBtn, "progress")
    local numBg = self:FindWndTrans(self.mExploreBtn, "numbg")

    local num = self:FindWndTrans(numBg, "num")
    local text = self:FindWndTrans(self.mExploreBtn, "text")
    self:SetWndText(text, ccClientText(12327))




    local uiProgress = UIProgress:New()
    uiProgress:Create(progressTran, porgress)

    local funcId = ModelFunctionOpen.EXPLORE_TASK
    local isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
    CS.ShowObject(numBg, isOpen)
    local numStr = tostring(cur)
    local imagePath = "public_explore_bar_3"
    if cur >= max then
        numStr = LUtil.FormatColorStr(numStr, "red")
        imagePath = "public_explore_bar_5"
    end
    self:SetWndText(num, numStr)
    self:SetWndEasyImage(progressTran, imagePath)
end

--function UIMinFight:ShowPocketSliderEff()
--    --CS.ShowObject(self.mPocketHandle,true)
--    --self:TimerStart(self._pocketSliderEffKey,1,false,1)
--end
function UIMinFight:SetOnlineActivityTime() --在线奖励
    self:SetOnlineTime()
end

function UIMinFight:OnInstanceKillTimeResp()
    gModelInstance:ShowKillMonWnd()
end

function UIMinFight:SetWndVisible(active)
    LWnd.SetWndVisible(self, active)
    if not self._wndEffectList then
        return
    end
    for k, v in pairs(self._wndEffectList) do
        v:SetVisible(active)
    end
end

function UIMinFight:UpdateMsg()
    -- timer里面接收msg做反馈，可能出问题，加个防止
    if not self._uiList then
        return
    end

    local isDragged = self._uiList:GetIsDragged()
    local isReachEnd = self._uiList:GetIsReachEnd()

    --print("isDragged "..tostring(isDragged))
    --print("isReachEnd "..tostring(isReachEnd))

    if isDragged and not isReachEnd then
        return
    end
    self._uiList:SetIsDragged(false)

    local msgList = gModelInstance:GetMsgList()
    local uiList = self._uiList

    uiList:RemoveAllData()
    for i, v in ipairs(msgList) do
        local data = {
            index = i,
            data = v,
        }
        uiList:AddData(i, data)
    end
    uiList:RefreshSimpleList(UIListWrap.RefreshMode.Bottom)
end

-----------------------------------------------------------------
function UIMinFight:DoWndDestroy()
    self:KillChapterBubbleTween()
    if self._bubbleUIHero then
        self._bubbleUIHero:Destroy()
        self._bubbleUIHero = nil
    end

    self:StopSearchAniTimer()
    self:StopHeroSayBubbleTimer()
    self:StopAllDropTween()
    self:StopAllKillMonEffTween()

    if self._dropSpineMap then
        local spineMap = self._dropSpineMap
        for k, v in pairs(spineMap) do
            local spine = v.spine
            v.spine = nil
            if spine then
                spine:Destroy()
            end
            spineMap[k] = nil
        end
        self._dropSpineMap = nil
    end

    --[[
    --引用外部创建的pool， 不需要自己进行销毁
    if self._simplePool then
        self._simplePool:Destroy()
        self._simplePool = nil
    end
    ]]
    --

    if self._uiHyperList then
        for k, v in pairs(self._uiHyperList) do
            v:Destroy()
        end
        self._uiHyperList = nil
    end


    LWnd.DoWndDestroy(self)
end

function UIMinFight:ShowQuickBtn()
    local isShow = gModelFunctionOpen:CheckIsShow(10200010)
    CS.ShowObject(self.mQuickBtn, isShow)
    if not isShow then return end

    local text = self:FindWndTrans(self.mQuickBtn, "text")
    self:SetWndText(text, ccClientText(10129))
end

function UIMinFight:UpdateTopLeftShow(isShow)
    -- self:SetAnchorPos(self.mTopLeft, Vector2.New(14, isShow and -250 or -134))
end

function UIMinFight:IsShowBarrage(bool)
    if (bool) then
        local channel = ModelChat.CHANNEL_RISK
        gModelGeneral:OpenBarrage({ channel = channel })
    else
        GF.CloseWndByName("UIBulletSay")
    end
end

function UIMinFight:OnModaiAniComplete(aniName)
    if aniName == self._curModaiAni then
        self._curModaiAni = nil
        local spine = self:FindWndSpineByKey(self._pocketKey)
        local aniName, index = gModelInstance:GetModaiAniName(true)
        if spine then
            spine:PlayAnimation(0, aniName, true)
            --spine:MatchRectTransform()
            local width = self._pocketSize[index]
            if width then
                local rectTran = self.mClickArea:GetComponent(typeOfRectTransform)
                local size = Vector2.New(width, rectTran.sizeDelta.y)
                rectTran.sizeDelta = size
            end
        end
    end
end

function UIMinFight:OnModaiLoaded()
    local spine = self:FindWndSpineByKey(self._pocketKey)
    if spine then
        local spineTrans = spine:GetSpineTrans()
        local spineClick = spineTrans:GetComponent(typeSpineClick)
        if not spineClick then
            spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
            spineClick.isUISpine = true
        end
        if spineClick then
            -- spineClick.onClick = function()
            --     gModelInstance:OpenUIGjAward()
            -- end
        end

        spine:SetAnimationCompleteFunc(function(...) self:OnModaiAniComplete(...) end)
        self:PlayerModaiAni()

        self:SetWndClick(self.mPocketArea, function()
            gModelInstance:OpenUIGjAward()
        end)
        --self:SetWndClick(self.mSpineArea,function ()
        --    gModelInstance:OpenUIGjAward()
        --end)
    end
end

function UIMinFight:OnRunChapterTime()
    if self._bubbleUIHero then
        self._bubbleUIHero:OnRun(Time.time)
    end
end

function UIMinFight:UpdateMainLineAwardPos()
    local isShow = gModelGrade:GetIsShow()
    local isHideReward = gModelGrade:GetIsHideReward()
    local b = isShow and isHideReward
    local pos = b and -116 or 12
    self:SetAnchorPos(self.mMainLineRewards, Vector2.New(38, pos))
end

function UIMinFight:ShowChapterBubble()
    self:KillChapterBubbleTween()
    self:TimerStop(self._chapterBubbleTimeKey)

    local battleNum = gModelInstance:GetBattleNum()
    local battleNode = gModelInstance:GetRawBattleNode()

    local missRef
    if (battleNode == -1) then
        local nextChapterId = gModelInstance:GetNextChapterId()
        if nextChapterId > 0 then
            local nextNode = gModelInstance:GetNodeByBattleNum(battleNum + 1)
            missRef = gModelInstance:GetMissionCfg(nextNode)
        end
    else
        missRef = gModelInstance:GetMissionCfg(battleNode)
    end

    if not missRef then
        CS.ShowObject(self.mBubbleShow, false)
        return
    end

    CS.ShowObject(self.mBubbleShow, true)

    local isNext = battleNode == -1
    local str = ""
    if isNext then
        str = ccClientText(10784)
    else
        str = ccClientText(10783)
    end
    local missionMame = missRef.nameWorld
    missionMame = ccLngText(missionMame)
    str = string.replace(str, missionMame)
    local bubbleAniText = CS.FindTrans(self.mBubbleShow, "BubbleAniText/UIText")
    self:SetWndText(bubbleAniText, str)
    self:InitTextLineWithLanguage(bubbleAniText, -30)
    self:InitTextSizeWithLanguage(bubbleAniText, -2)

    local effNode = CS.FindTrans(self.mBubbleShow, "Eff")
    self:CreateWndEffect(effNode, "fx_guajiqipao_liuguang", "mBubbleShow", 100, nil, nil, 2)

    local waitTime = 0

    local roleNode = CS.FindTrans(self.mBubbleShow, "Role")
    local uiHeroObj = self._bubbleUIHero
    if not uiHeroObj then
        uiHeroObj = LUIHeroObject:New(self)
        self._bubbleUIHero = uiHeroObj
        uiHeroObj:Create(roleNode, "mBubbleShow", "Ailisi")
        uiHeroObj:SetScale(1)
        uiHeroObj:ShowHero(true)
        uiHeroObj:SetLoadedFunction(function()
            if self._bubbleUIHero then
                self._bubbleUIHero:PlayAni("start", nil, nil, nil)
            end
        end)
        uiHeroObj:StartLoad()
        waitTime = 0.3
    else
        uiHeroObj:ShowHero(true)
        if self._bubbleUIHero and self._bubbleUIHero:IsDpValid() then
            self._bubbleUIHero:PlayAni("start", nil, nil, nil)
        end
    end
    self:TimerStart(self._chapterBubbleTimeKey, 0, false, -1)

    local appearTime = 0.6
    local stayTime = 2
    local disappearTime = 0.3

    local seq = YXTween.TweenSequenceIns()
    self._chapterBubbleSeqTween = seq


    local aniTextTrans = self.mBubbleAniText
    local aniDiImage = CS.FindTrans(aniTextTrans, "Image")
    local aniDiImageNext = CS.FindTrans(aniTextTrans, "ImageNext")
    CS.ShowObject(aniDiImage, not isNext)
    CS.ShowObject(aniDiImageNext, isNext)

    local canvas = aniTextTrans:GetComponent(typeofCanvasGroup)
    canvas.alpha = 0
    aniTextTrans.anchoredPosition = Vector2(0, 0)
    roleNode.localScale = Vector3.one

    local alphaTweenIn = canvas:DOFade(1, appearTime)

    local moveTween = aniTextTrans:DOLocalMoveY(71, disappearTime)
    local alphaTweenOut = canvas:DOFade(0, disappearTime)
    local roleTween = roleNode:DOScale(0, disappearTime)

    if waitTime > 0 then
        seq:AppendInterval(waitTime)
        CS.ShowObject(effNode, false)
        self._bubbleUIHero:SetAlpha(0)
        seq:AppendCallback(function()
            CS.ShowObject(effNode, true)
            self._bubbleUIHero:SetAlpha(1)
        end)
    end
    seq:Append(alphaTweenIn)
    seq:AppendInterval(stayTime)
    seq:Append(moveTween)

    local insertPos = waitTime + appearTime + stayTime
    seq:Insert(insertPos, alphaTweenOut)
    seq:Insert(insertPos, roleTween)

    seq:OnComplete(function()
        self._chapterBubbleSeqTween = nil
        self:TimerStop(self._chapterBubbleTimeKey)
        CS.ShowObject(self.mBubbleShow, false)
    end)
    seq:PlayForward()
end

function UIMinFight:CreateLittleIcon(dropKey, itemId, startPos)
    local itemRoot = self.mDropContent
    local spineName = "Jinbi"
    local dropScale = gModelInstance:GetLittleDropScale() or 1
    ---@type LDisplaySpine
    local dpSpine = LDisplaySpine:New()
    self._dropSpineMap[dropKey] = { spine = dpSpine, pos = startPos }

    dpSpine:CreateSpine(itemRoot.transform, spineName, LDisplaySpine.TYPE_UI)
    dpSpine:EnableReleaseFreeze(true)
    dpSpine:SetLoadedFunction(function()
        local spineData = self._dropSpineMap[dropKey]
        local spine = spineData.spine
        if spine and spine:IsDpValid() then
            local dpTrans = spine:GetDisplayTrans()
            local pos = spineData.pos
            dpTrans.position = pos
            dpTrans.localScale = Vector3.one
            if dpTrans.gameObject.layer ~= LWnd.WND_LAYER then
                CS.UpdateChildLayer(dpTrans, LWnd.WND_LAYER)
            end
            spine:SetScale(dropScale)
            CS.ShowObject(dpTrans, false)
            spine:PlayAnimation(0, itemId, true, false, 0)

            local trackEntry = spine:GetCurTrackEntry()
            if trackEntry then
                trackEntry.MixTime = 0
                trackEntry.MixDuration = 0
            end
            CS.ShowObject(dpTrans, true)
            --spine:SetToSetupPose()
        end
    end)
    dpSpine:SetUsePool(true)
    dpSpine:SetPool(self._simplePool)
    return dpSpine
end

function UIMinFight:SetTitle()
    local prefix, name = gModelInstance:GetCurBattleNodePrefixAndName()
    self:SetXUITextText(self.mTitleText, name)
    self:SetWndText(self.mChapterText, prefix)
    self:InitTextSizeWithLanguage(self.mTitleText, -4)

    if self._isVie then
        self:InitTextCharacterWithLanguage(self.mTitleText, -7)
        local LL =CS.FindTrans(self.mTitle,"StarImg/StarL")
        local RR =CS.FindTrans(self.mTitle,"StarImg/StarR")
        self:SetAnchorPos(LL,Vector2.New(-38.8,-0.3))
        self:SetAnchorPos(RR,Vector2.New(32,-0.3))
    end

    gModelInstance:InstanceFreeTheGirdReq()
end

function UIMinFight:OnBtIdleSearchMon(bSearchMon)
    local oldSearch = self._bBtIdleSearchMon and self._bBtIdleSearchMon or false
    if oldSearch == bSearchMon then return end
    self._bBtIdleSearchMon = bSearchMon
    CS.ShowObject(self.mSearchNode, bSearchMon)
    if bSearchMon then
        self:StartSearchAniTimer()
    else
        self:StopSearchAniTimer()
    end
end

function UIMinFight:OnTimer(key)
    if key == self._dropOnlineKey then
        self:SetOnlineActivityTime()
    elseif key == self._chapterBubbleTimeKey then
        self:OnRunChapterTime()
    elseif key == self._pocketTimerKey then
        self:SetPocketTime()
    elseif key == self._msgTimerKey then
        self:UpdateMsg()
        self:TimerStop(self._msgTimerKey)
        --elseif key ==self._battleCdTimerKey then
        --    self:SetBattleCd()
    elseif key == self._pocketAniTimerKey then
        self:PlayerModaiAni()
    elseif key == self._dropEffctCdKey then
        self._isDropEffCd = false
    elseif key == self._delayPocketTimerKey then
        self:CreatePocketTimer()
    elseif key == self._delayShowFinger then
        self:CheckShowFinger()
        --elseif key == self._timerPrivileKey then
    elseif key == self.openWinTimer then
        self.openWinTime = self.openWinTime + 1
        if self.openWinTime >= self.popTipsTime then
            if self.openWinTime > self.popTipsTime + self.showTipsTime then
                CS.ShowObject(self.mChallengeTips, false)
                self:TimerStop(self.openWinTimer)
            else
                local curStage = gModelInstance:GetRawBattleNode()
                if self.minStage <= curStage and curStage <= self.maxStage then
                    CS.ShowObject(self.mChallengeTips, true)
                end
            end
        end
    end
end

function UIMinFight:RefreshFuncBtnShow()
    for k, v in pairs(self._funcOpenList) do
        local isShow = gModelFunctionOpen:CheckIsShow(k)
        CS.ShowObject(v, isShow)
    end
end

--
function UIMinFight:UpdateBlockMiniGame()
    local isOpen = gModelFunctionOpen:CheckIsShow(33000002)
    local levelMode = gModelBlockMiniGame:GetGameMode()
    local allPass = gModelBlockMiniGame:IsPassAll()

    CS.ShowObject(self.mBlockMiniGame, isOpen and not allPass)
end

function UIMinFight:SetPara()
    self._isShowPocket = gModelFunctionOpen:CheckIsShow(10210001)
end

function UIMinFight:HideLittleIcon(dropKey)
    local data = self._dropSpineMap[dropKey]
    if not data then
        return
    end
    local spine = data.spine
    data.spine = nil
    if spine then
        spine:Destroy()
    end
    self._dropSpineMap[dropKey] = nil
end

function UIMinFight:UpdateCanvas()
    local trans = CS.FindTrans(self.mMainLineRewards, "Eff")
    local canvas = trans:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 2
    trans = CS.FindTrans(self.mMainLineRewards, "MainLineItemBg")
    canvas = trans:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 1
    trans = self.mMainLineItemIcon
    canvas = trans:GetComponent(typeofCanvas)
    canvas.sortingOrder = self:GetWndSortOrder() + 4
end

function UIMinFight:SetOnlineTime()
    --local m = math.floor(self._onlineLeftTime/60)%60
    --local s = math.floor(self._onlineLeftTime)%60
    --local timeStr= string.format("%02d:%02d",m,s)
    if not self._onlineData then return end
    local passTime = Time.RawUnityEngineTime.realtimeSinceStartup - self._onlineData.time
    local timeLeft = (self._onlineLeftTime or 0) - passTime
    if timeLeft <= 0 then
        self:SetWndText(self.mOnlineText, ccClientText(14801))
    else
        local timeStr = LUtil.FormatTimespanCn(timeLeft, { hTextId = 10371 })
        self:SetWndText(self.mOnlineText, timeStr)
    end
end

-------------------------------------------------------------------
function UIMinFight:StopAllKillMonEffTween()
    local tweenList = self._killMonEffTween
    for k, v in pairs(tweenList or {}) do
        v:Kill(false)
        tweenList[k] = nil
    end
end

function UIMinFight:OnMsgItemReturn(item, itemdata, itempos)
    if not self._curShowMsg then
        self._curShowMsg = {}
    end
    if self._curShowMsg[itempos] then
        self._curShowMsg[itempos] = nil
    end
end

function UIMinFight:CheckShowFinger()
    local showFinger = gModelGuide:CheckShowFinger()

    if showFinger then
        local includeWnd =
        {
            ["UIMinFight"] = true,
            ["UIBulletSay"] = true,
        }

        local isClean = gLGameUI:IsCurMainClean(includeWnd)
        if isClean then
            local combatType = LCombatTypeConst.COMBAT_MAIN
            local infight    = gLFightManager:IsCombatTypeInFight(combatType)
            showFinger       = not infight
        else
            showFinger = false
        end
    end

    CS.ShowObject(self.mFingerPart, showFinger)

    local key = "guideFinger"
    if not showFinger then
        self:DestroyWndEffectByKey(key)
        return
    end


    local effectName = "fx_ui_shou_2"
    local effData =
    {
        trans = self.mFingerEff,
        effName = effectName,
        effKey = key,
        bDefaultSortNum = 10,
    }
    self:CreateWndEffect_Ex(effData)
end

function UIMinFight:StopChangeMapDelayTimer()
    if (self._changeMapDelayTimer) then
        LxTimer.DelayTimeStop(self._changeMapDelayTimer)
    end
    self._changeMapDelayTimer = nil
end

function UIMinFight:KillChapterBubbleTween()
    if self._chapterBubbleSeqTween then
        self._chapterBubbleSeqTween:Kill(false)
        self._chapterBubbleSeqTween = nil
    end
end

function UIMinFight:SetFightBtnGray(isGray)
    local iconPath = nil
    if isGray then
        iconPath = "public_btn_ash_8_1"
    else
        iconPath = "public_btn_3_3"
    end

    local textTran = self:FindWndTrans(self.mChallengeBtn, 'layout/Text')
    -- self:SetBtnImageAndMat(self.mChallengeBtn,iconPath,textTran)
end

function UIMinFight:CreateModai()
    local isShowPocket = self._isShowPocket
    CS.ShowObject(self.mPocketContent, isShowPocket)
    CS.ShowObject(self.mOnHookBgImg, isShowPocket)
    if not isShowPocket then return end
    if PRODUCT_G_VER ~= 0 then
        self:SetWndClick(self.mPocketArea, function()
            gModelInstance:OpenUIGjAward()
        end)
        return
    end

    local root = self.mPocket
    self:CreateWndSpine(root, "Modai", self._pocketKey, true, function() self:OnModaiLoaded() end)
end

function UIMinFight:SetTowee(trans, key)
    local seqTween
    self:TweenSeqKill(key)
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            local time = 1
            local scale = trans.localScale
            local downPos = Vector3.New(0.9, 0.9, 0.9)
            local tweener = trans:DOScale(downPos, time)
            seq:Append(tweener)
            local tweener = trans:DOScale(scale, time)
            seq:Append(tweener)
            seq:SetLoops(-1, Tweening.LoopType.Restart)
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)
    end)
end

function UIMinFight:CheckShowRed(sid)
    local showRed = gModelRedPoint:CheckActivityShowRed(sid)
    return showRed
end

function UIMinFight:StartSearchAniTimer()
    self:StopSearchAniTimer()
    if not self._aniSearchInfo then
        self._curSearchAniIndex = 1
        self._aniSearchInfo = {
            ".",
            "..",
            "...",
        }
        self._aniSearchLen = 3
    end
    self._mLoopSearchAniTimer = LxTimer.LoopTimeCall(function()
        local str = ccClientText(10772)
        local aniStr = self._aniSearchInfo[self._curSearchAniIndex] or ""
        local text = self:FindWndTrans(self.mSearchNode, "text")
        self:SetWndText(text, str .. aniStr)
        self._curSearchAniIndex = self._curSearchAniIndex + 1
        if self._curSearchAniIndex > self._aniSearchLen then
            self._curSearchAniIndex = 1
        end
    end, 1)
end

function UIMinFight:OnPlayerInstanceResp()
    self:SetPocketTime()
    self:SetTitle()

    local canChanllenge = true
    local battleNode = gModelInstance:GetRawBattleNode()
    if battleNode == -1 then
        local chapter = gModelInstance:GetNextChapterId()
        if chapter ~= -1 then
            canChanllenge = false
        end
    end

    self:SetFightBtn()

    if (gModelInstance:ChangeMapState(nil, true)) then
        gModelInstance:ChangeMapState(false)
        GF.ChangeMap("LFightIdleMap")
    end
end

-----------------------------------------------------------------
function UIMinFight:StopSearchAniTimer()
    if self._mLoopSearchAniTimer then
        LxTimer.LoopTimeStop(self._mLoopSearchAniTimer)
        self._mLoopSearchAniTimer = nil
    end
end

--【Z主线推图】屏蔽主线困难及噩梦模式
------------开发需求 #10712 推图扩展----------------------------
-- function UIMinFight:RefreshDifficultyLvlGroup()
--     local showDiffLvlGroup = gModelInstance:CheckDiffLvlFuncIsOpen(2)
--     --local showDiffLvlGroup = true
--     local diffLvlTrans = self.mDifficultyLvl
--     if(showDiffLvlGroup)then
--         local curDiffLvl = gModelInstance:GetMainFightLevelOfDifficulty()
--         if(curDiffLvl == 3 and not gModelInstance:CheckDiffLvlFuncIsOpen(3))then
--             curDiffLvl = 1
--         end
--         self:OnClickDiffLvlBtn(diffLvlTrans,curDiffLvl,true)
--         for i = 1, 3 do
--             self:SetDiffLvlBtn(i)
--         end
--         local arrow = self:FindWndTrans(diffLvlTrans,"arrow")
--         self:SetWndClick(arrow, function()
--             self:OnClicDiffLvlArrow()
--         end)
--         local curLvl = self:FindWndTrans(diffLvlTrans,"CurLvl")
--         self:SetWndClick(curLvl, function()
--             self:OnClicDiffLvlArrow()
--         end)
--     end
--     CS.ShowObject(diffLvlTrans,showDiffLvlGroup)
--     CS.ShowObject(self.mDiffLvlHideClickImg, false)
--     self:SetWndClick(self.mDiffLvlHideClickImg, function()
--         self:OnClicDiffLvlArrow()
--     end)
-- end
--

--【Z主线推图】屏蔽主线困难及噩梦模式
-- function UIMinFight:SetCurDiffLvlBtn(index)
--     local iconPath  = "instance_btn_icon_"..index
--     local diffLvlTrans = self.mDifficultyLvl
--     local curLvlIcon = self:FindWndTrans(diffLvlTrans,"CurLvl/Icon")
--     local nameTxt = self:FindWndTrans(diffLvlTrans,"CurLvl/NameTxt")
--     self.diffLvlPatternCfg = gModelInstance:GetInstancePattern(index)
--     self:SetWndText(nameTxt,ccLngText(self.diffLvlPatternCfg.name)..ccClientText(16326))
--     self:SetWndEasyImage(curLvlIcon,iconPath)
-- end

--【Z主线推图】屏蔽主线困难及噩梦模式
-- function UIMinFight:SetCurDiffLvlTitle(index)
--     local bgPath  = "public_bg_title_"..index
--     self:SetWndEasyImage(self.mTitle,bgPath)
--     local prefix,name = gModelInstance:GetCurBattleNodePrefixAndName()
--     self:SetWndText(self.mChapterText,prefix)
--     local topColor = self:GetChapterTextTopColorByIndex(index)
--     self:SetTextTransColorGradient(self.mChapterText,topColor,"ffffff")
-- end

function UIMinFight:GetChapterTextTopColorByIndex(chapterType)
    if (chapterType == 1) then
        return "c5cced"
    elseif (chapterType == 2) then
        return "fff2b8"
    elseif (chapterType == 3) then
        return "ffb8fc"
    else
        return "c5cced"
    end
end

function UIMinFight:SetPocketTime()
    local timeTotal = GetTimestamp() - gModelInstance:GetPlaceTime()
    --print("timeTotal "..timeTotal)

    if timeTotal < 0 then
        timeTotal = 0
    end
    local timeMax = gModelInstance:GetBoxTimeLimit() * 60
    if timeTotal > timeMax then
        timeTotal = timeMax
    end
    local progresss = timeTotal / timeMax
    local slider = self:UIProgressFind(self.mPocketTime, self._pocketSliderKey, progresss)
    slider:SetUIProgress(progresss)

    local hour = math.floor(timeTotal / 3600)
    local min = math.floor(timeTotal / 60) % 60
    local timeStr = string.format("%02d:%02d", hour, min)
    self:SetXUITextText(self.mTimeTotal, timeStr)


    self:PlayerModaiAni()
end

function UIMinFight:GenerateKillMonEffBezier(from, to, time)
    local xRand = 1 + math.random()
    local yRand = 2 + math.random()

    local face1 = (math.random(1, 10000) > 5000) and 1 or -1
    local face2 = (math.random(1, 10000) > 5000) and 1 or -1

    local top1 = Vector3(from.x + xRand * face1, from.y + yRand * face2, 0)
    local top2 = Vector3(from.x + 3 * face1, to.y, 0)
    local bezier = LCurveUtil.NewBezier(from, to, time, top1, top2)
    return function(t)
        return bezier:NextPos(t)
    end
end

function UIMinFight:StopAllDropTween()
    if not self._dropTweenSeqList then
        return
    end
    for k, v in pairs(self._dropTweenSeqList) do
        v:Kill(false)
    end
    self._dropTweenSeqList = {}
end

function UIMinFight:UpdateMainLineAward()
    local rpTrans = self:FindWndTrans(self.mMainLineText, "redPoint")
    CS.ShowObject(rpTrans, false)

    local isOpen = gModelFunctionOpen:CheckIsOpened(10201000)
    self:UpdateMainLineAwardPos()

    ---------------------------------------------------------------------
    ---解救少女阶段 特殊处理  --by.lkt
	if self.theGirdPos < 5 then
        local battleNode = gModelInstance:GetRawBattleNode(1)
        local battleNum = gModelInstance:GetBattleNum(1)
        CS.ShowObject(self.mMainLineRewards, isOpen and battleNum > 8)
        if not isOpen then
            return
        end
        if not self.handcuffsStage then
            self.handcuffsStage = {}
            local cfg = GameTable.MainInstanceProRewardRef
            for _, v in pairs(cfg) do
                if v.type == 1 then
                    table.insert(self.handcuffsStage, v)
                end
            end
            table.sort(self.handcuffsStage, function(a, b)
                return a.refId < b.refId
            end)
        end

        local showEff = false
        local chapterId = gModelInstance:GetChapterId()
        local isGetBig = true
        local afterStage
        for i = 1, 5 do
            local num = gModelInstance:GetMissionCfg(self.handcuffsStage[i].refId).num
            local isPass = num < battleNum or (num <= battleNum and battleNode == -1)
            if isPass and self.theGirdPos < i then
                showEff = true
            end

            if not isPass and not afterStage then
                afterStage = battleNum - num
            end

            if i == 5 and isPass then
                isGetBig = false
            end
        end
        if showEff then
            local tran = CS.FindTrans(self.mMainLineRewards, "Eff")
            self:CreateWndEffect(tran, "fx_ui_xiannv_rukou", "fx_ui_xiannv_rukou", 100)
        else
            self:DestroyWndEffectByKey("fx_ui_xiannv_rukou")
        end
        local rpTrans = self:FindWndTrans(self.mMainLineText, "redPoint")
        CS.ShowObject(rpTrans, showEff)

        local item = LxDataHelper.ParseItem_4(self.handcuffsStage[#self.handcuffsStage].reward)
        local icon = gModelGeneral:GetCommonItemImgRef(item)
        self:SetWndEasyImage(self.mMainLineItemIcon, icon)

        CS.ShowObject(self.mMainDesBg, true)
        if gLGameLanguage:IsJapanVersion() then
            local bgTran =  CS.FindTrans(self.mMainDesBg,"MainDesBg")
            LxUiHelper.SetSizeWithCurAnchor(bgTran,1,150)
        end
        local str
        if afterStage then
            if afterStage <= 0 then
                str = ccClientText(45016)
            else
                str = string.replace(ccClientText(45014), afterStage)
            end
        end
        if not isGetBig then
            str = ccClientText(45015)
        end
        self:SetWndText(self.mMainDesText, str)
        return
    end


    ---------------------------------------------------------------------
    ---少女馈赠阶段 之前的处理
    local list
    --if gLGameLanguage:IsJapanRegion() then
    --    list = gModelInstance:GetBGetAwardChapterIdJapan()
    --else
    --    list = gModelInstance:GetBGetAwardChapterId(self.curDiffLvlIndex)
    --end
    list = gModelInstance:GetBGetAwardChapterId(self.curDiffLvlIndex)
    local isShow = #list > 0
    CS.ShowObject(self.mMainLineRewards, isShow and isOpen)
    if (not isShow) then
        return
    end
    local chapterId = gModelInstance:GetChapterId()
    local battleNode = gModelInstance:GetRawBattleNode()
    local _battleNum = gModelInstance:GetBattleNum()

    local alist = gModelInstance:GetInstanceProRewardRef(self.curDiffLvlIndex)
    local daAward = nil
    for i, v in ipairs(alist) do
        local refId = v.refId
        local mission = gModelInstance:GetMissionCfg(refId)
        local specialId = v.specialId or 0
        if specialId ~= 0 and (mission.belongChapterId > chapterId or (battleNode ~= -1 and mission.refId >= battleNode and mission.belongChapterId == chapterId)) then
            daAward = mission
            break
        end
    end
    local nodeStr = ""
    local getBoxGet = gModelInstance:GetBoxBGet(self.curDiffLvlIndex)
    local canGetChapterReward = false
    if (getBoxGet) then
        nodeStr = ccClientText(16304)
        local tran = CS.FindTrans(self.mMainLineRewards, "Eff")
        self:CreateWndEffect(tran, "fx_ui_xiannv_rukou", "fx_ui_xiannv_rukou", 100)
    else
        local cnt = gModelInstance:GetNextProgressCnt(self.curDiffLvlIndex)
        if (cnt == -1) then
            CS.ShowObject(self.mMainLineItemBg, false)
        else
            nodeStr = string.replace(ccClientText(16305), cnt)
        end
        self:DestroyWndEffectByKey("fx_ui_xiannv_rukou")
    end
    self:SetWndText(self.mMainLineText, nodeStr)

    local rewardName = ""
    local rewardList = {}
    local rewardRef

    if #list <= 0 then
        local roll = rollAwardList[1]
        rewardList = LxDataHelper.ParseItem(roll.reward)
        CS.ShowObject(self.mMainLineItemBg, true)

        local mapReceiveTime = gModelInstance:GetMapReceiveTime(self.curDiffLvlIndex)
        mapReceiveTime = tonumber(mapReceiveTime) / 1000
        if mapReceiveTime > 0 then
            local dayTime = LUtil.GetNextDayTimes(mapReceiveTime > 0 and mapReceiveTime or nil, roll.intervalTime or 0)
            local curTime = GetTimestamp()
            local isTimeReach = mapReceiveTime <= 0 or curTime >= dayTime
            if isTimeReach then
                canGetChapterReward = true
                rewardName = rewardName .. "\n" .. ccClientText(16324)
            else
                local day = math.ceil((dayTime - curTime) / 86400)
                local str = string.replace(ccClientText(16325), day)
                rewardName = rewardName .. "\n" .. str
            end
        else
            canGetChapterReward = true
            rewardName = rewardName .. "\n" .. ccClientText(16324)
        end
    else
        rewardRef = list[1].ref
        rewardList = LxDataHelper.ParseItem(rewardRef.reward)
    end
    local item = rewardList[1]
    local icon = gModelGeneral:GetCommonItemImgRef(item)
    self:SetWndEasyImage(self.mMainLineItemIcon, icon)
    self:SetWndText(self.mMainLineItemName, rewardName)
    self:InitTextModeWithLanguage(self.mMainLineItemName)

    if gLGameLanguage:IsJapanRegion() then
        daAward = nil
    end

    CS.ShowObject(self.mMainDesBg, daAward)
    local desStr = ccClientText(16309)
    if daAward then
        self:SetTowee(self.mMainDesBg, self._mMainTweenKey)
        if daAward.num - _battleNum > 0 then
            desStr = string.replace(ccClientText(16308), daAward.num - _battleNum)
        end
        self:InitTextSizeWithLanguage(self.mMainDesText, -4)
        if gLGameLanguage:IsJapanRegion() then
            self:InitTextLineWithLanguage(self.mMainDesText, -20)
        end
    end
    desStr = getBoxGet and ccClientText(45015) or desStr
    self:SetWndText(self.mMainDesText, desStr)


    local nodeStr = ""
    if gLGameLanguage:IsJapanRegion() then
        local isShowLineText, canGetBigReward = gModelInstance:GetBoxBGetJapan(rewardRef)
        if isShowLineText then
            if canGetBigReward then
                nodeStr = ccClientText(16304)
            else
                nodeStr = ccClientText(16346)
            end
        else
            nodeStr = ""
        end
        self:SetWndText(self.mMainLineText, nodeStr)
    else
        CS.ShowObject(self.mMainLineText, not canGetChapterReward)
        local rpTrans = self:FindWndTrans(self.mMainLineText, "redPoint")
        CS.ShowObject(rpTrans, getBoxGet)
    end
end

function UIMinFight:SetFightBtn()
    local isGray = false
    self:ShowUpLvTip()

    local showEff = true
    local str = ccClientText(10748)
    local battleNode = gModelInstance:GetRawBattleNode()
    if battleNode == -1 then
        local chapter = gModelInstance:GetNextChapterId()
        if chapter > 0 then
            local node                      = gModelInstance:GetChapterFirstNode(chapter)
            local canEnterBattleNode, limit = gModelInstance:CanEnterBattleNode(node)
            if not canEnterBattleNode then
                str = string.replace(ccClientText(10750), limit)
            else
                str = ccClientText(10749)
            end
            if not canEnterBattleNode then
                showEff = false
            end
        else
            showEff = false
            str = ccClientText(10749)
            isGray = true
        end
    else
        local isBoss = gModelInstance:IsBossShow()
        if isBoss then
            str = ccClientText(10768)
        end

        local canEnterBattleNode, limit = gModelInstance:CanEnterBattleNode(battleNode)
        if not canEnterBattleNode then
            str = string.replace(ccClientText(10750), limit)
        end
    end

    self:SetFightBtnText(str)
    self:SetFightBtnGray(isGray)

    --if string.isempty(str) then
    --    if not self._bChallengeBtnShow or self._bChallengeBtnShow ==1 then
    --        self._bChallengeBtnShow = 0
    --        CS.ShowObject(self.mChallengeBtn, false)
    --        CS.ShowObject(self.mFightEff, false)
    --    end
    --else
    --    if not self._bChallengeBtnShow or self._bChallengeBtnShow == 0 then
    --        self._bChallengeBtnShow = 1
    --        CS.ShowObject(self.mChallengeBtn, true)
    --        CS.ShowObject(self.mFightEff, true)
    --    end
    --end

    if showEff then
        -- self:CreateWndEffect(self.mFightEff,"fx_zhandou_anniu","fightBtnEff",100,nil,nil,6)
    else
        self:DestroyWndEffectByKey("fightBtnEff")
    end
end

function UIMinFight:OnClickExplore()
    GF.OpenWnd("UIExre")
end

function UIMinFight:ShowKillMonEff(pos)
    local effectname = "fx_guaji_guangdian"
    local idx = self._killMonIndex + 1
    if idx > 100000000 then
        idx = 1
    end
    self._killMonIndex = idx

    local key = "guaji_fly_" .. idx
    local effFly = self:CreateWndEffect(self.mGuajiFlyEffect, effectname, key, 100, nil, 3)

    local flyTime = 0.8 + math.random() * 0.4
    local tween = YXTween.TweenSequenceIns()
    local oldTween = self._killMonEffTween[idx]
    if oldTween then
        oldTween:Kill(false)
    end
    self._killMonEffTween[idx] = tween

    local curveFun = self:GenerateKillMonEffBezier(pos, self.mGuajiFlyEffect.position, flyTime)
    local tweener = YXTween.TweenFloat(0, 1, flyTime, function(t)
        local p = curveFun(t)
        if effFly and effFly:IsDpValid() then
            effFly:GetDisplayTrans().position = p
        end
    end):SetEase(DG.Tweening.Ease.InCubic)

    tween:Append(tweener)
    tween:AppendCallback(function()
        self:DestroyWndEffectByKey(key)
        LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_KILL_MON_FLY_EFF)
        self:CreateWndEffect(self.mGuajiHitEffect, "fx_guaji_guangdian_hit", "guaji_hit_" .. idx, 100, nil)
    end)
    tween:AppendInterval(2)
    tween:OnComplete(function()
        self._killMonEffTween[idx] = nil
        self:DestroyWndEffectByKey("guaji_hit_" .. idx)
    end)
    tween:PlayForward()
end

function UIMinFight:CreateDelayPocketTimer()
    local timeTotal = GetTimestamp() - gModelInstance:GetPlaceTime()
    if timeTotal < 0 then
        self:CreatePocketTimer()
    else
        local delay = 60 - math.floor(timeTotal) % 60
        self:TimerStart(self._delayPocketTimerKey, delay, false, 1)
    end
end

function UIMinFight:OnRemoveHangMsg(data)
    for k, v in pairs(self._curShowMsg) do
        if v == data then
            --print("OnRemoveHangMsg")
            self._uiList:SetIsDragged(false)
            break
        end
    end
end

function UIMinFight:OnShowHeroBubble(sayStr, stayTime)
    if not self._isShowPocket then return end

    CS.ShowObject(self.mHeroTalkBubble, true)
    self:SetWndText(CS.FindTrans(self.mHeroTalkBubble, "text"), sayStr)
    self:StopHeroSayBubbleTimer()
    self._heroSayBubbleTimer = LxTimer.DelayTimeCall(function()
        CS.ShowObject(self.mHeroTalkBubble, false)
        self._heroSayBubbleTimer = nil
    end, stayTime)
end

function UIMinFight:InitData()
    self._activityItemList = {}
    self._pocketSliderKey = "_pocketSliderKey"
    self._pocketTimerKey = "_pocketTimerKey"
    self._msgTimerKey = "_msgTimerKey"
    self._dropItemPool = {}
    self._dropTweenSeqList = {}

    self._killMonEffTween = {}
    self._killMonIndex = 0

    self._uiHyperList = {}
    self._battleCdTimerKey = "_battleCdTimerKey"
    self._pocketAniTimerKey = "_pocketAniTimerKey"
    self._pocketKey = "_pocketKey"
    self._dropEffctCdKey = "_dropEffctCdKey"
    self._dropEffctKey = "_dropEffctKey"
    self._dropOnlineKey = "_dropOnlineKey" --在线奖励倒计时
    self._isDropEffCd = false

    self._chapterBubbleTimeKey = "_chapterBubbleTimeKey" -- 冒泡计时循环

    self._delayPocketTimerKey = "_delayPocketTimerKey"
    self._delayShowFinger = "_delayShowFinger"
    --self._msgList = {}                              -- 挂机消息列表

    self._pocketSize =
    {
        [1] = 175,
        [2] = 175,
        [3] = 209,
        [4] = 350,
        [5] = 380,
    }
    self._onlineLeftTime = 0

    self._funcOpenList =
    {
        --【Z主线推图】删除冒险玩法中的主角形象设置功能
        -- [12301000] = self.mFormationBtn,
        --
        -- [12302000] = self.mZhenrongBtn,【G挂机功能】挂机功能界面布局调整（客户端）
        --[11721000] = self.mBarrageInputBtn,
    }

    -- self._tsDesBgTrans = gLGameLanguage:IsJapanRegion() and self.mTsDesBgEn or self.mTsDesBg
end

function UIMinFight:RefreshPartShow()
    local guideType = gModelGuide:GetGuideType()
    local hide = false
    if guideType == 5 then
        hide = not gModelFunctionOpen:CheckIsShow(50400006)
    end

    local isShow = gModelFunctionOpen:CheckIsShow(10200010)

    CS.ShowObject(self.mQuickBtn, not hide and isShow)
    CS.ShowObject(self.mOnHookBgImg, not hide)
    CS.ShowObject(self.mPocketContent, not hide)
    --CS.ShowObject(self.mQuickBtn,not hide)
end

function UIMinFight:ShowUpLvTip()
    if PRODUCT_G_VER == 1 then
        if not gModelFunctionOpen:CheckIsShow(17600011) then --ios写死屏蔽
            return
        end
    end
    if PRODUCT_G_VER == 2 or PRODUCT_G_VER == 3 then
        --hw ios写死屏蔽
        return
    end
    local showTip = gModelInstance:CheckShowTip(self.curDiffLvlIndex)
    CS.ShowObject(self.mUpLvTip, showTip)
end

function UIMinFight:ShowUpLvTipWnd()
    if PRODUCT_G_VER == 1 then
        if not gModelFunctionOpen:CheckIsShow(17600011) then --ios写死屏蔽
            return
        end
    end

    if PRODUCT_G_VER == 2 or PRODUCT_G_VER == 3 then
        --hw ios写死屏蔽
        return
    end

    local showTip = gModelInstance:CheckShowTip(self.curDiffLvlIndex)
    if not showTip then
        return
    end
    GF.OpenWnd("UIUpLvhjgyPop")
end

function UIMinFight:DelayUpdateMsg()
    if self:IsTimerExist(self._msgTimerKey) then
        return
    end
    self:TimerStart(self._msgTimerKey, 0.5, false, 1)
end

function UIMinFight:OnDropLittleIconFly(flyList)
    if not flyList or #flyList == 0 then return end

    --print("drop little item")
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local uiCamera = LGameUI.GetUICamera()
    local endPos = self.mCoinTarget.transform.position

    for k = 1, #flyList do
        if k < 4 then
            -- LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_RECHARGE_LARGE)
            LxUiHelper.PlayAudioSoundName(30)
        end
        local paramData = flyList[k]
        local itemId    = paramData.itemId
        local monPos    = Vector3(paramData.x, paramData.y, 0)
        --坐标轴转换：将角色位置坐标，转化为屏幕坐标。屏幕坐标转化为世界坐标，设置UI坐标。
        local screenPos = sceneCamera:WorldToScreenPoint(monPos) --Vector3

        local startPos  = uiCamera:ScreenToWorldPoint(screenPos)


        local dropKey = (self._dropKey or 0)
        dropKey = dropKey + 1
        self._dropKey = dropKey

        local dpSpine = self:CreateLittleIcon(dropKey, itemId, startPos)
        dpSpine:StartLoad()

        local seq = Tweening.DOTween.Sequence()
        self._dropTweenSeqList[seq] = seq
        local tweener = self:GenerateFallenTween(dropKey, startPos, endPos)
        seq:Append(tweener)
        seq:OnComplete(function()
            self._dropTweenSeqList[seq] = nil
            self:HideLittleIcon(dropKey)
            self:CreateModaiDropEff()
        end)
        seq:PlayForward()
    end
end

function UIMinFight:PlayerModaiAni()
    self:TimerStop(self._pocketAniTimerKey)
    local spine = self:FindWndSpineByKey(self._pocketKey)
    local aniName = gModelInstance:GetModaiAniName(false)
    --print("modai ani "..aniName)
    if spine then
        spine:PlayAnimation(0, aniName, false)
        --spine:MatchRectTransform()
        self:CreateModaiEffect()
        self:CreateModaiAniEff(aniName)
        self._curModaiAni = aniName
    end

    local time = gModelInstance:GetAniInterval()
    self:TimerStart(self._pocketAniTimerKey, time, false, 1)
end

------------------------------------------------------------------
return UIMinFight