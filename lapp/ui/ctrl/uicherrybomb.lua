---
--- Created by Administrator.
--- DateTime: 2025/3/11 17:06:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICherryBomb:LWnd
local UICherryBomb = LxWndClass("UICherryBomb", LWnd)

local UITigerDraw = LXImport('LApp.UI.Common.UITigerDraw')
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeUIImage = typeof(UnityEngine.UI.Image)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
UICherryBomb.IDLE_MOVE_SPEED = 100
UICherryBomb.LIST_REWARD_ITEMNUM = 5
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICherryBomb:UICherryBomb()

    self._uiTigerDraw = nil
    self._drawAniKey = "_drawAniKey"
    self._chatAniKey = "_chatAniKey"
    self._overResultAniKey = "_overResult"
    ---@type boolean 播放动画中
    self._playAni = false
    self._isPlayChatAni = false
    self._isShouldPlayChatAni = false
    self._playDisappearMaskAniIndexList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICherryBomb:OnWndClose()
    if self._uiTigerDraw then
        self._uiTigerDraw:Destroy()
        self._uiTigerDraw = nil
    end
    --清理下相关的进度数据
    gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 3)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICherryBomb:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICherryBomb:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitMsg()
    self:InitEvent()
    self:InitStaticText()

    self:InitPara()
end

--endregion --------------------------------------------------------------------------------------

--region 数据处理 --------------------------------------------------------------------------------
function UICherryBomb:InitPara()
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

--初始化界面
function UICherryBomb:InitComment()
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
    self._heroDpSpine = self:CreateWndSpine(self.mHeroSpine, heroDrawing, heroDrawing, false, function(dpSpine)
        --dpSpine:PlayAnimation(0,"click",true)
    end)

    self._interactiveCfg = gModelActivityMiniGame:ParseMiniGameInteractiveCfg(self._entryCfg)

    --获取当前的温度档位
    self._temperature = gModelActivityMiniGame:GetCherryBombTemperature(self._entryCfg)
    self._temperatureNum = self._temperatureNum or 0
    self._temperatureIndex = gModelActivityMiniGame:GetCherryBombTemperatureIndex(self._temperature, self._temperatureNum)


    --
    self._interactive = {}

    for k, v in ipairs(self._interactiveCfg.changeManifestation) do
        table.insert(self._interactive, gModelActivityMiniGame:ParseInteractiveCfgType_3(v))
    end

    --获取其他参数
    local moreInfo = gModelActivityMiniGame:ParseCherryBombMoreInfo(self._entryCfg)
    self._maxTemperatureValue = moreInfo.maxTemperatureValue
    self._cherryImg = moreInfo.cherryImg

    --设置遮罩部分
    self:CreateHeroMask()

    --温度计的部分
    self:SetTemperature()

    --老虎机部分
    self:InitAniTrans()
    self:InitUITigerDraw()

    self:SetCherryBombEffect()

end

function UICherryBomb:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnStarGame, function()
        if self:CheckIsCanClick() then
            gModelActivityMiniGame:SendActivityMiniGameOptReq(self._entryCfg.type, self._sid, 1, 1)
        end
    end)

    self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
end

--region 事件 --------------------------------------------------------------------------------
function UICherryBomb:InitMsg()
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

        --设置结果
        self:SetGameResultTran(checknumber(miniGameData.resultStr))
        local isWin = miniGameData.isWin
        local _temperatureIndex = gModelActivityMiniGame:GetCherryBombTemperatureIndex(self._temperature, self._temperatureNum)

        if _temperatureIndex > self._temperatureIndex then
            self._temperatureIndex = _temperatureIndex
            self._isShouldPlayChatAni = true
        end
        --展示结果
        local func = function()
            self._playAni = false
        end

        local isHaveBigReward = false
        if not table.isempty(miniGameData.items) then
            isHaveBigReward = true
            local itemList = {  }
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
        end

        local endStatus = checknumber(miniGameData.endStatus)
        self:DoTurnAni(func, isHaveBigReward, isWin, endStatus)
    end)
end

function UICherryBomb:OnClickHelp()
    local content = self._signHelpTips or ""
    local title = self._title or ""
    GF.OpenWnd("UIBzTips",{title = title,text = content})
end

--游戏结束后的结果飘字
function UICherryBomb:PlayResultAni(isWin)
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


--加速移动
function UICherryBomb:DoTurnAni(func, hasBigReward, isWin, endStatus)
    self._playAni = true
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq(self._drawAniKey)

    if self._uiTigerDraw then
        LxUiHelper.PlayAudioSoundName(LSoundConst.HALIDOM_TURN)

        local speed = 2000
        self._uiTigerDraw:SetAllUIScrollSpeed(speed)

        local moveTimes = 0.3
        seq:InsertCallback(2, function()
        end)

        local endSpeed = 0
        local doAlpha = 0.1
        local doAlphaTime = moveTimes - doAlpha
        local list1StartTime = 2.1
        --- 加速
        seq:Insert(list1StartTime, YXTween.TweenFloat(speed, endSpeed, moveTimes, function(val)
            self._uiTigerDraw:SetUIScrollSpeedByTrans(self.mList1, val)
        end))
        --- 先设置节点显示
        seq:InsertCallback(list1StartTime + doAlphaTime, function()
            CS.ShowObject(self.mListRewardMove1, true)
        end)
        --- list 渐隐，listRewardMove 渐现
        seq:Insert(list1StartTime + doAlphaTime, YXTween.TweenFloat(1, 0, doAlpha, function(val)
            self.mListCG1.alpha = val
            self.mListRewardMoveCG1.alpha = 1 - val
        end))
        --- 移动
        seq:Insert(list1StartTime, self.mListRewardMove1:DOMove(self.mStartPos1.position, moveTimes))

        local list2StartTime = 2.4
        --- 加速
        seq:Insert(list2StartTime, YXTween.TweenFloat(speed, endSpeed, moveTimes, function(val)
            self._uiTigerDraw:SetUIScrollSpeedByTrans(self.mList2, val)
        end))
        --- 先设置节点显示
        seq:InsertCallback(list2StartTime + doAlphaTime, function()
            CS.ShowObject(self.mListRewardMove2, true)
        end)
        --- list 渐隐，listRewardMove 渐现
        seq:Insert(list2StartTime + doAlphaTime, YXTween.TweenFloat(1, 0, doAlpha, function(val)
            self.mListCG2.alpha = val
            self.mListRewardMoveCG2.alpha = 1 - val
        end))
        --- 移动
        seq:Insert(list2StartTime, self.mListRewardMove2:DOMove(self.mStartPos2.position, moveTimes))

        local list3StartTime = 2.7
        --- 加速
        seq:Insert(list3StartTime, YXTween.TweenFloat(speed, endSpeed, moveTimes, function(val)
            self._uiTigerDraw:SetUIScrollSpeedByTrans(self.mList3, val)
        end))
        --- 先设置节点显示
        seq:InsertCallback(list3StartTime + doAlphaTime, function()
            CS.ShowObject(self.mListRewardMove3, true)
        end)
        --- list 渐隐，listRewardMove 渐现
        seq:Insert(list3StartTime + doAlphaTime, YXTween.TweenFloat(1, 0, doAlpha, function(val)
            self.mListCG3.alpha = val
            self.mListRewardMoveCG3.alpha = 1 - val
        end))
        --- 移动
        seq:Insert(list3StartTime, self.mListRewardMove3:DOMove(self.mStartPos3.position, moveTimes))
    end

    seq:InsertCallback(3.5, function()
        --温度部分
        self:SetTemperature()

        --气泡部分
        if self._isShouldPlayChatAni then
            self._isShouldPlayChatAni = false
            self:PlayChatDivShow()
        end

        --老虎机显示完结果的事情
        self:PlayDisappearMaskAni()

    end)


    local bigRewardAddTime = 0
    if nil == isWin then
    else
        seq:InsertCallback(3.5, function()
            bigRewardAddTime = self:PlayResultAni(isWin)
        end)
        bigRewardAddTime = 4
    end

    if endStatus > 0 then
        seq:InsertCallback(3 + bigRewardAddTime, function()
            local wndPara = {}
            wndPara.isSuc = endStatus == 1 and true or false
            wndPara.heroEffectId = self._entryCfg.Heroid
            wndPara.titleStr = self._entryCfg.name
            wndPara.desStr = ccClientText(46908)
            wndPara.wndName = "UICherryBomb"
            if hasBigReward then
                wndPara.itemList = self._showRewardItemPara.itemList
            end
            --插入新的显示
            GF.OpenWnd("UIMiniGameResult",wndPara)

        end)
    end



    seq:AppendInterval(2)
    seq:OnComplete(function()
        seqCom:DeleteSeq(self._drawAniKey)
        --if info then
        --	CS.ShowObject(info.turnEffTrans,false)
        --	CS.ShowObject(info.idleEffTrans,true)
        --end
        if func then
            func()
        end

        self:InitAniTrans()

        self._uiTigerDraw:SetAllUIScrollSpeed(UICherryBomb.IDLE_MOVE_SPEED)
    end)
    seq:PlayForward()
end

--聊天气泡部分
function UICherryBomb:PlayChatDivShow()
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq(self._chatAniKey)

    -- 初始化状态
    CS.ShowObject(self.mChatDiv, true)

    self:SetWndText(self.mChatText, ccClientText(self._interactive[self._temperatureIndex].textId))
    self._isPlayChatAni = true
    local chatPlayDelayTime = 2
    local chatPlayTime = 0.3

    if self.mChatDiv.localScale.x > 0 then
        seq:Insert(0, self.mChatDiv:DOScale(Vector3.one * 0, chatPlayTime))
        seq:Insert(chatPlayTime * 2, self.mChatDiv:DOScale(Vector3.one, chatPlayTime))
    else
        seq:Insert(0, self.mChatDiv:DOScale(Vector3.one, chatPlayTime))
    end

    seq:Insert(chatPlayDelayTime + 1, self.mChatDiv:DOScale(Vector3.one * 0, chatPlayTime))

    seq:InsertCallback(chatPlayDelayTime + 2, function()
        self._isPlayChatAni = false
    end)

    seq:OnComplete(function()
        seqCom:DeleteSeq(self._chatAniKey)
    end)
    seq:PlayForward()
end

function UICherryBomb:SetTemperature()
    local temperatureNumStr = string.replace(ccClientText(46901), self._temperatureNum)

    self:SetWndText(self.mBubbleText, temperatureNumStr)
    local uiImage = self.mTemperature:GetComponent(typeUIImage)
    if uiImage and uiImage.enabled then
        local progress = self._temperatureNum / self._maxTemperatureValue
        progress = progress > 1 and 1 or progress
        uiImage.fillAmount = progress
    end
end


--endregion --------------------------------------------------------------------------------------

--region  界面 --------------------------------------------------------------------------------
--初始化文本
function UICherryBomb:InitStaticText()
    self:SetWndText(self.mTxtReturn, ccClientText(20723))
end

function UICherryBomb:CheckIsCanRefreshChatDiv()
    if self._isPlayChatAni then
        return false
    end
    return true
end

--endregion --------------------------------------------------------------------------------------

--region 数据请求 --------------------------------------------------------------------------------
function UICherryBomb:DoReq()

end

function UICherryBomb:SetRewardData(trans, list)
    if not self._recordListRewardTransMap then
        self._recordListRewardTransMap = {}
    end
    local key = trans:GetInstanceID()
    local transMap = self._recordListRewardTransMap[key]
    if not transMap then
        transMap = {}
        self._recordListRewardTransMap[key] = transMap
    end
    for i = 1, UICherryBomb.LIST_REWARD_ITEMNUM do
        local data = list[i]
        local iconTrans = transMap[i]
        if not iconTrans then
            local rewardTrans = self:FindWndTrans(trans, "ListReward" .. i)
            if rewardTrans then
                iconTrans = self:FindWndTrans(rewardTrans, "Icon")
                transMap[i] = iconTrans
            end
        end
        if data and iconTrans then
            local iconPath = gModelItem:GetItemIconByRefId(data.reward.itemId)
            self:SetWndEasyImage(iconTrans, iconPath, function()
                CS.ShowObject(iconTrans, true)
            end, true)
        end
    end
end

--特效部分
function UICherryBomb:SetCherryBombEffect()
    self:CreateWndEffect(self.mBgEff, "h159_laohuji_bg", "h159_laohuji_bg", 100)
end

function UICherryBomb:SetGameResultImg(result, listTran)
    local img_1 = CS.FindTrans(listTran, "ListReward2/Icon")
    local img_2 = CS.FindTrans(listTran, "ListReward3/Icon")
    local img_3 = CS.FindTrans(listTran, "ListReward4/Icon")
    local tempResult = result
    self:SetWndEasyImage(img_2, self._cherryImg[tempResult])
    tempResult = tempResult + 1
    tempResult = tempResult > 3 and 1 or tempResult
    self:SetWndEasyImage(img_3, self._cherryImg[tempResult])
    tempResult = tempResult + 1
    tempResult = tempResult > 3 and 1 or tempResult
    self:SetWndEasyImage(img_1, self._cherryImg[tempResult])
end

--设置奖励的部分
function UICherryBomb:SetGameResultTran(result)
    local result_1 = math.floor(result / 100)
    local result_2 = (math.floor(result / 10)) % 10
    local result_3 = result % 10

    self:SetGameResultImg(result_1, self.mListRewardMove1)
    self:SetGameResultImg(result_2, self.mListRewardMove2)
    self:SetGameResultImg(result_3, self.mListRewardMove3)
end

function UICherryBomb:GetUITigerDatas()

    local results_1 = {}
    local results_2 = {}
    local results_3 = {}

    for i = 1, 4 do
        if i == 4 then
            table.insert(results_1, {
                imgPath = self._cherryImg[1] }
            )
            table.insert(results_2, {
                imgPath = self._cherryImg[2] }
            )
            table.insert(results_3, {
                imgPath = self._cherryImg[3] }
            )
        else
            table.insert(results_1, {
                imgPath = self._cherryImg[i] }
            )
            table.insert(results_2, {
                imgPath = self._cherryImg[i] }
            )
            table.insert(results_3, {
                imgPath = self._cherryImg[i] }
            )
        end
    end

    local isStopState = false
    return {
        {
            trans = self.mList1,
            dataList = results_1,
            autoMove = true,
            isMoveState = isStopState,
            speed = UICherryBomb.IDLE_MOVE_SPEED,
        },
        {
            trans = self.mList2,
            dataList = results_2,
            autoMove = true,
            isMoveState = isStopState,
            speed = UICherryBomb.IDLE_MOVE_SPEED,
        },
        {
            trans = self.mList3,
            dataList = results_3,
            autoMove = true,
            isMoveState = isStopState,
            speed = UICherryBomb.IDLE_MOVE_SPEED,
        },
    }
end
--endregion --------------------------------------------------------------------------------------

--region checK function  --------------------------------------------------------------------------------
function UICherryBomb:CheckIsCanClick()
    if self._playAni then
        return false
    end

    return true
end

function UICherryBomb:CreateHeroMask()
    --创建云
    if not self._maskList then
        self._maskList = {}
    end

    for k, v in ipairs(self._interactive) do
        if not self._maskList[k] then
            local itemNew = LxResUtil.NewObject(self.mHeroMask.gameObject)
            itemNew.transform:SetParent(self.mHeroMaskDiv, false)
            itemNew.transform.localPosition = Vector3.zero
            local rectTrans = itemNew:GetComponent(typeOfRectTransform)

            self:SetWndEasyImage(rectTrans, v.maskBg)
            local maskPos = string.split(v.maskPos, "-")

            maskPos = Vector2.New(checknumber(maskPos[1]), checknumber(maskPos[2]) )
            self:SetAnchorPos(rectTrans, maskPos)
            CS.ShowObject(rectTrans, k > self._temperatureIndex)

            if k > self._temperatureIndex then
                local instanceId = rectTrans:GetInstanceID()
                self:CreateWndEffect(rectTrans, "h159_laohuji_wu", "h159_laohuji_wu" .. instanceId, 100, false, false,
                        10)
            end

            self._maskList[k] = rectTrans
        end
    end
end

--初始化节点
function UICherryBomb:InitAniTrans()
    CS.ShowObject(self.mListRewardMove1, false)
    CS.ShowObject(self.mListRewardMove2, false)
    CS.ShowObject(self.mListRewardMove3, false)
    self.mListRewardMove1.position = self.mEndPos1.position
    self.mListRewardMove2.position = self.mEndPos2.position
    self.mListRewardMove3.position = self.mEndPos3.position
    self.mListRewardMoveCG1.alpha = 0
    self.mListRewardMoveCG2.alpha = 0
    self.mListRewardMoveCG3.alpha = 0
    self.mListCG1.alpha = 1
    self.mListCG2.alpha = 1
    self.mListCG3.alpha = 1
    CS.ShowObject(self.mList1, true)
    CS.ShowObject(self.mList2, true)
    CS.ShowObject(self.mList3, true)
end

--雾散去的动画
function UICherryBomb:PlayDisappearMaskAni()
    self._temperatureIndex = gModelActivityMiniGame:GetCherryBombTemperatureIndex(self._temperature, self._temperatureNum)
    if not self._maskList[self._temperatureIndex].gameObject.activeSelf then
        return
    end
    local rectTrans = self._maskList[self._temperatureIndex]
    local instanceId = rectTrans:GetInstanceID()
    local effKey = "h159_laohuji_wu_2" .. instanceId

    if not self._playDisappearMaskAniIndexList[self._temperatureIndex] then
        self._playDisappearMaskAniIndexList[self._temperatureIndex]  = true
        self:CreateWndEffect(self._maskList[self._temperatureIndex], "h159_laohuji_wu_2", effKey, 100)
        self:DestroyWndEffectByKey("h159_laohuji_wu" .. instanceId)
    end
end

--使用trigger运动
function UICherryBomb:InitUITigerDraw()
    local datas = self:GetUITigerDatas()
    ---@type UITigerDraw
    local uiTigerDraw = UITigerDraw:New()
    self._uiTigerDraw = uiTigerDraw
    uiTigerDraw:SetTigerListInfos(self, datas)
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UICherryBomb