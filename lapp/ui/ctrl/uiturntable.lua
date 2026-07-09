---
--- Created by Administrator.
--- DateTime: 2025/3/19 16:15:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITurntable:LWnd
local UITurntable = LxWndClass("UITurntable", LWnd)

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITurntable:UITurntable()
    --标志位
    self._starRotation = false
    self._gameIsOver = false
    self._isGetReward = false
    self._isFirstStarGame = true
    self._isPlayingSound = false

    --转盘部分
    self._turnTableCfg = string.split("1:2:3:2:1:3:2:3", ":")
    self._turnTextSize = {
        [1] = 42,
        [2] = 36,
        [3] = 26,
    }
    self._turnTextId = {
        [1] = 46902,
        [2] = 46903,
        [3] = 46904,
    }
    self._turnTextMat = {
        [1] = "OPPOSansRMixB_f480ae_3",
        [2] = "OPPOSansRMixB_c65de1_3",
        [3] = "OPPOSansRMixB_9893f4_3",
    }

    --计时器
    self._timeKey = "UITurntable_timeKey"

    self._overResultAniKey = "_overResult"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITurntable:OnWndClose()
    if self._loopTimer then
        LxTimer.LoopTimeStop(self._loopTimer)
        self._loopTimer = nil
    end

    self:TimerStop(self._timeKey)
    --清理下相关的进度数据
    gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 3)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITurntable:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITurntable:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitMsg()
    self:InitEvent()
    self:InitStaticText()
    self:InitPara()
end

function UITurntable:PlayOverGameAni(miniGameData)
    --当前状态是否为结束
    local endStatus = checknumber(miniGameData.endStatus)
    --其他的表现  奖励弹窗 已经
    local bigRewardAddTime = 2
    local isWin = miniGameData.isWin

    if nil == isWin then
    else
        self:PlayResultAni(isWin)
        bigRewardAddTime = bigRewardAddTime + 2
    end

    if endStatus > 0 then
        local wndPara = {}
        wndPara.isSuc = endStatus == 1 and true or false
        wndPara.heroEffectId = self._entryCfg.Heroid
        wndPara.titleStr = self._entryCfg.name
        wndPara.desStr = ccClientText(46908)
        wndPara.wndName = "UITurntable"
        if miniGameData.items then
            local itemList = {}
            for k, v in ipairs(miniGameData.items) do
                local tab = {
                    itemType = tonumber(v.type),
                    itemId = tonumber(v.itemId),
                    count = tonumber(v.count),
                }
                table.insert(itemList, tab)
            end

            self._showRewardItemPara = {
                itemList = itemList,
                callBackFunc = function()
                end,
            }

            wndPara.itemList = self._showRewardItemPara.itemList
        end

        LxTimer.DelayTimeCall(function()
            GF.OpenWnd("UIMiniGameResult", wndPara)
        end, bigRewardAddTime, false)
    end
end

function UITurntable:InitComment()
    local bg = self._entryCfg.bigbg
    self:SetWndEasyImage(self.mBg, bg)

    local effRef = GameTable.CharacterEffectRef[self._entryCfg.Heroid]
    if not effRef then
        return
    end

    --设置下pos
    local pos = string.split(self._entryCfg.HeroCoord, ",")
    pos = Vector2.New(checknumber(pos[1]), checknumber(pos[2]))
    self:SetAnchorPos(self.mHeroSpine, pos)

    local heroDrawing = effRef.heroDrawing
    self._heroDpSpine = self:CreateWndSpine(self.mHeroSpine, heroDrawing, heroDrawing .. "_index_0", false, function(dpSpine)
        --dpSpine:PlayAnimation(0,"click",true)
    end)

    self._interactiveCfg = gModelActivityMiniGame:ParseMiniGameInteractiveCfg(self._entryCfg)

    --spine的切换
    local changeSpine = string.split(self._interactiveCfg.winSpinName, "|")
    self._winSpinName = changeSpine

    self._soundName = string.split(self._interactiveCfg.winSoundName, "|")

    --设置装盘
    local moreInfo = gModelActivityMiniGame:ParseTurntableMoreInfo(self._entryCfg)
    self._turntableTotalTime = moreInfo.totalTime
    self._turntableRotateSpeed = moreInfo.rotateSpeed
    self._turntableTotalCloth = moreInfo.totalCloth
    self:SetTurntable()
    self:SetTime()

    self:SetTurntableEffect()
end

function UITurntable:SetTime()
    if self._turntableTotalTime < 0 then
        self._turntableTotalTime = 0
    end

    self:SetTextTile(self.mTimeDownDiv, string.replace(ccClientText(46905), self._turntableTotalTime))
end

function UITurntable:SetTurntable()
    for k, v in ipairs(self._turnTableCfg) do
        local textIndex = checknumber(v)
        local textTran = CS.FindTrans(self.mTextDiv, "UIText_" .. k)
        local uiText = LxUiHelper.FindXTextCtrl(textTran)
        uiText.fontSize = self._turnTextSize[textIndex]
        self:SetWndTextMat(textTran, self._turnTextMat[textIndex])
        local text = ccClientText(checknumber(self._turnTextId[textIndex]))
        self:SetWndText(textTran,text )
    end
end

--endregion --------------------------------------------------------------------------------------

--计时器
function UITurntable:OnTimer(key)
    if (key == self._timeKey) then
        self._turntableTotalTime = self._turntableTotalTime - 1
        if self._turntableTotalTime <= 0 then
            self:TimerStop(self._timeKey)
            --倒计时结束 结束动画
            if self._loopTimer then
                LxTimer.LoopTimeStop(self._loopTimer)
                self._loopTimer = nil
            end

            self:OverTurntable()
        end
        self:SetTime()
    end
end

function UITurntable:OverTurntable()
    --停止计时器
    self:TimerStop(self._timeKey)
    self:DestroyWndEffectByKey("h159_zhuanpan_turn")
    --标志位重置
    self._gameIsOver = true
    self._starRotation = false
    --控件初始化
    local btnStarStr = self._starRotation and ccClientText(46907) or ccClientText(46906)
    self:SetTextTile(self.mBtnStarGame, btnStarStr)
    --上报结果
    local params = tostring(self._layoffNum)
    gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 1, params)
end

--游戏结束后的结果飘字
function UITurntable:PlayResultAni(isWin)
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq(self._overResultAniKey)
    local initPos = Vector2.New(0, -200)
    local endPosY = 200
    --初始化状态
    local csCanvasGroup = self.mOverResultImg:GetComponent(typeofCanvasGroup)
    csCanvasGroup.alpha = 0
    local imgPath = gModelActivityMiniGame:GetFloatImgName(isWin)
    self:SetWndEasyImage(self.mOverResultImg, imgPath)
    self:SetAnchorPos(self.mOverResultImg, initPos)

    local alphaAniTime = 1
    local moveTime = 2 * alphaAniTime
    seq:Insert(0, YXTween.TweenFloat(0, 1, alphaAniTime, function(val)
        csCanvasGroup.alpha = val
    end))

    seq:Insert(0, YXTween.TweenFloat(0, 1, alphaAniTime, function(val)
        csCanvasGroup.alpha = val
    end))

    seq:Insert(alphaAniTime, YXTween.TweenFloat(1, 0, alphaAniTime, function(val)
        csCanvasGroup.alpha = val
    end))
    seq:Insert(0, self.mOverResultImg:DOLocalMoveY(endPosY, moveTime))

    seq:OnComplete(function()
        seqCom:DeleteSeq(self._overResultAniKey)
    end)

    seq:PlayForward()
end

function UITurntable:CheckIsCanClickStarGame()
    if self._gameIsOver then
        return false
    end

    if self._isPlayingSound then
        return false
    end

    return true
end


--region 事件 --------------------------------------------------------------------------------
function UITurntable:InitMsg()
    self:WndEventRecv(EventNames.MINIGAME_OPT_RESULT, function(miniGameData)
        if miniGameData.gameType ~= self._entryCfg.type then
            return
        end
        self._isGotReward = miniGameData.reward

        if miniGameData.opt == 0 then
            self:InitComment()
            return
        end

        self:PlayOverGameAni(miniGameData)
    end)
end

function UITurntable:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnStarGame, function()
        if self:CheckIsCanClickStarGame() then
            self:StarArrowRotate()
        end
    end)

    self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
end

--endregion --------------------------------------------------------------------------------------

--region CheckFunction Get DoReq--------------------------------------------------------------------------------
function UITurntable:GetStopResult(angle)
    if angle <= 45 and angle > 0 then
        return 2
    elseif angle <= 90 and angle > 45 then
        return 1
    elseif angle <= 135 and angle > 90 then
        return 8
    elseif angle <= 180 and angle > 135 then
        return 7
    elseif angle <= 225 and angle > 180 then
        return 6
    elseif angle <= 270 and angle > 225 then
        return 5
    elseif angle <= 315 and angle > 270 then
        return 4
    elseif angle <= 360 and angle > 315 then
        return 3
    end
end

--endregion --------------------------------------------------------------------------------------

--region 数据处理 --------------------------------------------------------------------------------
function UITurntable:InitPara()
    self._entryId = self:GetWndArg("entryId")
    self._sid = self:GetWndArg("sid")
    --获取到对应的cfg
    self._entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, 1, self._entryId)
    if not self._entryCfg then
        printInfoNR2("UICherryBomb", "not entryCfg wnd close")
        self:WndClose()
    end

    local helpTips = self._entryCfg.text
    if not string.isempty(helpTips) then
        self._title = gModelActivity:GetLngNameById(self._entryCfg.name)
        self._signHelpTips = gModelActivity:GetLngNameById(self._entryCfg.text)
        local trans = self.mBtnHelp
        CS.ShowObject(trans,true)
    end

    --设置下气泡的位置  dialoguePos
    local dialoguePos  = self._entryCfg.dialoguePos
    if not string.isempty(dialoguePos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(dialoguePos)
        self:SetAnchorPos(self.mChatDiv, pos)
    end

    self._rotateSpeed = 1
    self._layoffNum = 0
    gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 0)


end

function UITurntable:OnClickHelp()
    local content = self._signHelpTips or ""
    local title = self._title or ""
    GF.OpenWnd("UIBzTips",{title = title,text = content})
end


--endregion --------------------------------------------------------------------------------------

--region 界面 --------------------------------------------------------------------------------
--初始化文本
function UITurntable:InitStaticText()
    self:SetWndText(self.mTxtReturn, ccClientText(20723))

    self:SetTextTile(self.mBtnStarGame, ccClientText(46906))
end

--特效部分
function UITurntable:SetTurntableEffect()
    self:CreateWndEffect(self.mBgEff, "h159_zhuanpan_bg", "h159_zhuanpan_bg", 100)

    self:CreateWndEffect(self.mTurntableArrow_2, "h159_aixin_idle", "h159_aixin_idle", 100)

    self:CreateWndSpine(self.mTimeDownIcon, "h159_naozhong", "h159_naozhong", false, function(dpSpine)
        dpSpine:SetIgnoreTimeScale(true)
    end)


end

function UITurntable:StarArrowRotate()
    --是否需要开启计时器
    if self._isFirstStarGame then
        self._isFirstStarGame = false
        self:TimerStop(self._timeKey)
        self:TimerStart(self._timeKey, 1, false, -1)
    end

    self._starRotation = not self._starRotation
    local btnStarStr = self._starRotation and ccClientText(46907) or ccClientText(46906)
    self:SetTextTile(self.mBtnStarGame, btnStarStr)
    --当前已经脱掉的+1
    local speedIndex = self._layoffNum + 1
    speedIndex = speedIndex > #self._turntableRotateSpeed and #self._turntableRotateSpeed or speedIndex
    self._rotateSpeed = checknumber(self._turntableRotateSpeed[speedIndex])

    if self._starRotation then
        self._loopTimer = LxTimer.LoopTimeCall(function()
            local z = self.mTurntableArrow.transform.eulerAngles.z
            self.mTurntableArrow.localRotation = Quaternion.Euler(0, 0, z - self._rotateSpeed)

        end, 0, false, -1)

        self:CreateWndEffect(self.mTurntableArrow_2, "h159_zhuanpan_turn", "h159_zhuanpan_turn", 100)
    else
        self:DestroyWndEffectByKey("h159_zhuanpan_turn")

        if self._loopTimer then
            LxTimer.LoopTimeStop(self._loopTimer)
            self._loopTimer = nil
        end

        --
        local z = self.mTurntableArrow.transform.eulerAngles.z
        if z > 360 then
            z = z % 360
        end

        local textIndex = self:GetStopResult(z)
        local result = checknumber(self._turnTableCfg[textIndex])
        local isChange = false
        if result == 1 then
            isChange = true
        end

        if isChange then
            self._isPlayingSound = true
            self:CreateWndEffect(self.mHeroSwitchover, "huiyizhuanchang", "huiyizhuanchang", 100)

            self._layoffNum = self._layoffNum + 1

            local spineName = self._winSpinName[self._layoffNum]
            LxTimer.DelayTimeCall(function()
                if self._heroDpSpine then
                    self._heroDpSpine:Destroy()
                end

                self._heroDpSpine = self:CreateWndSpine(self.mHeroSpine, spineName, spineName .. "_index_" .. self._layoffNum, false, function(dpSpine)
                    --dpSpine:PlayAnimation(0,"click",true)
                end)
            end, 1, false)

            --播放声音
            local soundName = self._soundName[self._layoffNum]
            soundName = string.split(soundName, "-")
            local delayTime = checknumber(soundName[2])
            gLGameAudio:PlaySingleSound(soundName[1], function()
                LxTimer.DelayTimeCall(function()
                    self._isPlayingSound = false

                    --全部结束在进行请求结束
                    local checkConditionNum = self._layoffNum
                    if checkConditionNum >= self._turntableTotalCloth then
                        --结束
                        self:OverTurntable()
                    end

                end, delayTime, false)
            end)


        end
    end
end

------------------------------------------------------------------
return UITurntable