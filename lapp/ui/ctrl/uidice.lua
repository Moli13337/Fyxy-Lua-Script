---
--- Created by Administrator.
--- DateTime: 2025/3/20 16:26:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDice:LWnd
local UIDice = LxWndClass("UIDice", LWnd)

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDice:UIDice()
    self._playDiceAniKey = "playDiceAniKey"
    self._chatAniKey = "_chatAniKey"
    self._overResultAniKey = "_overResult"

    self._isPlayDice_1 = false
    self._isPlayDice_2 = false

    self._curTempScale = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDice:OnWndClose()
    --清理下相关的进度数据
    gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 3)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDice:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDice:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitMsg()
    self:InitEvent()
    self:InitStaticText()
    self:InitPara()
end

function UIDice:InitComment()
    local bg = self._entryCfg.bigbg
    self:SetWndEasyImage(self.mBg_2, bg)
    CS.ShowObject(self.mBtnStarGame, true)
    CS.ShowObject(self.mSelectDiv, false)

    local effRef = GameTable.CharacterEffectRef[self._entryCfg.Heroid]
    if not effRef then
        return
    end

    --设置下pos
    local pos = string.split(self._entryCfg.HeroCoord, ",")
    pos = Vector2.New(checknumber(pos[1]), checknumber(pos[2]))
    self:SetAnchorPos(self.mHeroSpine, pos)

    local heroDrawing = effRef.heroDrawing
    self._heroDpSpine = self:CreateWndSpine(self.mHeroSpine, heroDrawing, heroDrawing, false, function(dpSpine)

    end)

    self._interactiveCfg = gModelActivityMiniGame:ParseMiniGameInteractiveCfg(self._entryCfg)

    --获取其他参数
    local moreInfo = gModelActivityMiniGame:ParseDiceMoreInfo(self._entryCfg)
    self._temperatureNum = self._temperatureNum or 0
    self._maxTemperatureValue = moreInfo.maxTemperatureValue
    --温度计的部分
    self:SetTemperature()
    self:SetDiceEffect()
end
--endregion --------------------------------------------------------------------------------------


--region check --------------------------------------------------------------------------------
function UIDice:CheckIsCanClick()
    if self._gameIsOver then
        return false
    end

    if self._isPlayingSound then
        return false
    end

    return true
end

--游戏结束后的结果飘字
function UIDice:PlayResultAni(isWin)
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

function UIDice:SetDiceResult()
    self._isPlayDice_2 = true -- 骰子游戏第二步

    --是否  大
    local isBigResult = self._diceResult[1] >= self._diceResult[2]
    local chatText = isBigResult and self._interactiveCfg.maxResultText or self._interactiveCfg.minResultText
    chatText = string.split(chatText, "|")

    --显示自己的结果和气泡
    local randomIndex = math.random(1, 3)
    local showChatText = chatText[randomIndex]
    local showStr = ccClientText(checknumber(showChatText))
    self:PlayChatDivShow(showStr)

    --设置骰子结果
    local result = self._diceResult[1]
    local AniName = "open_" .. result
    self._selfDiceDp:PlayAnimation(0, AniName, false)
    self._temperatureEff:SetVisible(false)
    CS.ShowObject(self.mBtnStarGame, false)
    CS.ShowObject(self.mSelectDiv, true)
end

--endregion --------------------------------------------------------------------------------------

--region 界面 --------------------------------------------------------------------------------
--初始化文本
function UIDice:InitStaticText()
    self:SetWndText(self.mTxtReturn, ccClientText(20723))
    local UIText = self:FindWndTrans(self.mBtnStarGame, "UIText")
    self:SetWndText(UIText, ccClientText(46906))
end
--endregion --------------------------------------------------------------------------------------

--region 页面动效 --------------------------------------------------------------------------------
function UIDice:PlayDiceAni()
    self._isPlayDice_1 = true --骰子游戏第一步开始
    self._temperatureEff:SetVisible(true)
    if self._selfDiceDp then
        self._selfDiceDp:PlayAnimation(0, "start", false)
    end
    if self._otherDiceDp then
        self._otherDiceDp:PlayAnimation(0, "start", false)
    end

    --动画播放完  发送协议
    local playAniTime = 2
    LxTimer.DelayTimeCall(
            function()
                gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 1)
            end, playAniTime
    )
end

function UIDice:OnGuessClick(selectResult)
    local isWin = false
    -- 0 猜测小     -- 1 猜测大
    if selectResult == 0 then
        isWin = self._diceResult[1] <= self._diceResult[2]
    elseif selectResult == 1 then
        isWin = self._diceResult[1] >= self._diceResult[2]
    end


    --汇报结果
    --0表示猜对,1表示猜错,不传参数表示摇骰子
    local params = isWin and tostring(0) or tostring(1)
    gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 1, params)
end

function UIDice:SetDiceShowOrHide(diceTran, isShow)
    CS.ShowObject(diceTran.DiceBottom, isShow)
    CS.ShowObject(diceTran.Dice, isShow)
    CS.ShowObject(diceTran.DiceTop, isShow)
end

function UIDice:PlayChatDivShow(chatText)
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq(self._chatAniKey)

    -- 初始化状态
    CS.ShowObject(self.mChatDiv, true)

    self:SetWndText(self.mChatText, chatText)
    self._isPlayChatAni = true
    local chatPlayDelayTime = 2
    local chatPlayTime = 0.3

    if self.mChatDiv.localScale.x > 0 then
        seq:Insert(0, self.mChatDiv:DOScale(Vector3.one * 0, chatPlayTime))
        seq:Insert(chatPlayTime * 2, self.mChatDiv:DOScale(Vector3.one, chatPlayTime))
    else
        seq:Insert(0, self.mChatDiv:DOScale(Vector3.one, chatPlayTime))
    end

    seq:InsertCallback(chatPlayDelayTime + 2, function()
        self._isPlayChatAni = false
    end)

    seq:OnComplete(function()
        seqCom:DeleteSeq(self._chatAniKey)
    end)
    seq:PlayForward()
end
--endregion --------------------------------------------------------------------------------------

--region 数据处理 --------------------------------------------------------------------------------
function UIDice:InitPara()
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

    gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 0)
end


--播放时的特效

-- 设置温度
function UIDice:SetTemperature()
    --计算比例 算下结果
    local progress = self._temperatureNum / self._maxTemperatureValue
    progress = progress > 1 and 1 or progress

    local cur = self._curTempScale
    self._curTempScale = progress
    local tweenSeq = YXTween.TweenSequenceIns()
    local scaleFunc = function(value)
        local temperatureScale = Vector3.New(1, value, 1)
        self.mTemperature.localScale = temperatureScale
    end
    local scaleTween = YXTween.TweenFloat(cur, progress, 0.5, scaleFunc):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(scaleTween)
    tweenSeq:PlayForward()
end

function UIDice:GetDicTransList(tran)
    local list = {}
    list.DiceBottom = CS.FindTrans(tran, "DiceBottom")
    list.Dice = CS.FindTrans(tran, "Dice")
    list.DiceTop = CS.FindTrans(tran, "DiceTop")
    list.PlayDiceAniRoot = CS.FindTrans(tran, "PlayDiceAniRoot")
    local DiceTop_EndPos = CS.FindTrans(tran, "DiceTop_EndPos")
    list.endPosY = DiceTop_EndPos .position.y
    local DiceTop_StarPos = CS.FindTrans(tran, "DiceTop_StarPos")
    list.starPosY = DiceTop_StarPos .position.y
    return list
end

--region 事件 --------------------------------------------------------------------------------
function UIDice:InitMsg()
    self:WndEventRecv(EventNames.MINIGAME_OPT_RESULT, function(miniGameData)
        if miniGameData.gameType ~= self._entryCfg.type then
            return
        end
        self._isGotReward = miniGameData.reward
        self._temperatureNum = miniGameData.progress

        if miniGameData.opt == 0 then
            self:InitComment()
            return
        end

        self:OnMiniGameOptResult(miniGameData)
    end)
end
--特效部分
function UIDice:SetDiceEffect()
    self:CreateWndEffect(self.mBgEff, "h159_touzixiaoyouxi_bg", "h159_touzixiaoyouxi_bg", 100)

    self._temperatureEff = self:CreateWndEffect(self.mTemperatureBg, "h159_touzi_xintiao_idle", "h159_touzi_xintiao_idle", 100)
    self._temperatureEff:SetVisible(false)

    self:CreateWndSpine(self.mSelfDice, "h159_touzi_1", "h159_touzi_1", false, function(dp)
        self._selfDiceDp = dp
    end)
    self:CreateWndSpine(self.mOtherDice, "h159_touzi_2", "h159_touzi_2", false, function(dp)
        self._otherDiceDp = dp
    end)
end

function UIDice:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnStarGame, function()
        if self:CheckIsCanClick() then
            --播放动效
            self:PlayDiceAni()
        end
    end)

    self:SetWndClick(self.mSmallTrans, function()
        if not self._diceResult then
            return
        end
        self:OnGuessClick(0)
    end)

    self:SetWndClick(self.mBigTrans, function()
        if not self._diceResult then
            return
        end
        self:OnGuessClick(1)
    end)

    self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
end

function UIDice:SetDiceResult_2(diceTran, result)
    local tranImgResult = "activity_159_icon_" .. result
    local dice = CS.FindTrans(diceTran.Dice, "Dice_1")
    self:SetWndEasyImage(dice, tranImgResult)

    CS.ShowObject(diceTran.DiceTop, false)
end

function UIDice:OnMiniGameOptResult(miniGameData)
    --判断是否有resultStr --无 则是大小 有则 骰子结果
    local resultStr = miniGameData.resultStr

    --有结果则要飘结果
    local isWin = miniGameData.isWin
    if nil == isWin then
    else
        --游戏进程2 才会进行飘字
        if self._isPlayDice_2 then
            self:PlayResultAni(isWin)
        end
    end

    if string.isempty(resultStr) then
        --猜完大小 重置状态位置
        self._isPlayDice_1 = false
        self._isPlayDice_2 = false

        CS.ShowObject(self.mBtnStarGame, true)
        CS.ShowObject(self.mSelectDiv, false)
        --大小  刷新进度
        self:SetTemperature()

        --展示对方的结果         --设置骰子结果
        local result = self._diceResult[2]
        local AniName = "open_" .. result
        self._otherDiceDp:PlayAnimation(0, AniName, false)

        --获取当前轮次是否为空 为空则进行结果显示
        local endStatus = checknumber(miniGameData.endStatus)
        if endStatus > 0 then
            local wndPara = {}
            wndPara.isSuc = endStatus == 1 and true or false
            wndPara.heroEffectId = self._entryCfg.Heroid
            wndPara.titleStr = self._entryCfg.name
            wndPara.desStr = ccClientText(46908)
            wndPara.wndName = "UIDice"
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
            end, 2, false)
        end

    else
        --骰子结果
        local diceResult = string.split(resultStr, "|")
        self._diceResult = {}

        local tempData_self = 0
        local diceResult_self = string.split(diceResult[1], ",")

        for k, v in ipairs(diceResult_self) do
            tempData_self = tempData_self + checknumber(v)
        end

        local tempData_Other = 0
        local diceResult_other = string.split(diceResult[2], ",")
        for k, v in ipairs(diceResult_other) do
            tempData_Other = tempData_Other + checknumber(v)
        end

        self._diceResult[1] = tempData_self
        self._diceResult[2] = tempData_Other

        self:SetDiceResult()
    end

end

function UIDice:OnClickHelp()
    local content = self._signHelpTips or ""
    local title = self._title or ""
    GF.OpenWnd("UIBzTips",{title = title,text = content})
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIDice