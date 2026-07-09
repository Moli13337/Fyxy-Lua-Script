---
--- Created by Administrator.
--- DateTime: 2023/10/23 11:34:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWretLanguage:LWnd
local UIWretLanguage = LxWndClass("UIWretLanguage", LWnd)
local UnityEngine = UnityEngine
local typeof = typeof
local typeofImage = typeof(UnityEngine.UI.Image)
local typeofCanvas = typeof(UnityEngine.Canvas)
local typeofUISorting = typeof(CS.YXUISorting)
local YXUIPointUtil = CS.YXUIPointUtil
---@type LUIEffectObject
local LUIEffectObject = LxRequire("LApp.UI.Display.LUIEffectObject")

---@type LUIHeroObject
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

UIWretLanguage.STATUS_COMMON_SECRET = 1    --解密状态（后端控制）
UIWretLanguage.STATUS_COMMON_COMPLETE = 2    --完成解密状态（后端控制）
UIWretLanguage.STATUS_FAKE_SECRET = 3        --假解密状态（前端控制）
UIWretLanguage.STATUS_FAKE_COMPLETE = 4    --假完成解密状态（前端控制）
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWretLanguage:UIWretLanguage()

    --每个密码的遮挡数量
    self._coverMaxNum = 6
    self._secretMaxNum = 4
    self._canGetEffName = "fx_myxj_lingqutishi"
    self._cardRefreshEffName = "fx_ui_monvwuyu_kapai"
    self._coverClearEffName = "fx_ui_monvwuyu_kapai_suilie"

    self._coverTransList = {}
    self._cardEffsList = {}
    self._numInputTransList = {}
    self._numSelectTransList = {}

    self._coverClearEffIdx = 0
    ---@type table<number,LUIEffectObject>
    self._uiEffectObjList = {}
    self._curUIHeroObj = {}

    self._delayTimeList = {}

    self._secretFakeTimerKey = "_secretFakeTimerKey"
    self._secretBuyTimerKey = "_secretBuyTimerKey"
    self._rewardNameFormat = "<color=#%s>%s</color>"

    self._doTweenShakeKey = "_doTweenShakeKey"

    self._successSecretMsgStr = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWretLanguage:OnWndClose()
    self:ClearTimerClose()

    if self._uiEffectObjList then
        local listObj = self._uiEffectObjList
        for k, v in pairs(listObj) do
            listObj[k] = nil
            v:Destroy()
        end
        self._uiEffectObjList = nil
    end

    if self._simplePool then
        self._simplePool:Destroy()
        self._simplePool = nil
    end

    self._curUIHeroObj = {}

    self:ResetLocalRandomSecretNum()
    self:DestroyWndEffectAll()

    self._coverTransList = {}
    self._cardEffsList = {}
    self._numInputTransList = {}
    self._numSelectTransList = {}
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWretLanguage:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWretLanguage:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    if self._isEnus then 
        self:SetAnchorPos(self.mHelpTxt,Vector2.New(-65,-7))
    end 
    
    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitStaticInfo()
    self:InitCoverEffectPlayPool()
end

function UIWretLanguage:BuyClickFakeCompleteFunc()
    --假重置密码
    self._isSecretSuccess = false
    self:ClearRandomSecretNum(self._nowDay)
    self:RefreshCurDayRewardGetStatus()
    self:RefreshContent()
end

function UIWretLanguage:BuyClickFakeSecretFunc()
    if self._isResetCards then
        self:PlayResidueCardCoverClearEff()
        self:RefreshCarsRefreshEff()
        self:TimerStop(self._secretFakeTimerKey)
        self:TimerStart(self._secretFakeTimerKey, 1.5, false, 1)
    else
        self:SecretFake()
    end
end

-------------------------------------------------设置天数----------------------------------------------------------
-- 七天图标
function UIWretLanguage:InitSevenDaysTrans()
    if (not self._sevenDaysTrans) then
        self._sevenDaysTrans = {}
        for i = 1, 7 do
            local item = CS.FindTrans(self.mDayList, "Day" .. i)
            local dayEffTrans = CS.FindTrans(item, "Eff/SelectEff")
            local canGetEffTrans = self:FindWndTrans(item, "Eff/CanGetEff")
            local redpoint = self:FindWndTrans(item, "redPoint")
            local selectTran = CS.FindTrans(item, "Select")
            local bg = CS.FindTrans(item, "Bg")
            local bgImg = bg.gameObject:GetComponent(typeofImage)
            self._sevenDaysTrans[i] = item
            self._dayCanGetEffTransList[i] = canGetEffTrans
            self._dayCanGetRedPointTransList[i] = redpoint
            self._dayEffTransList[i] = dayEffTrans
            self._dayBgList[i] = bg
            self._dayBgImgList[i] = bgImg
            self._selectTrans[i] = selectTran
            self:SetWndClick(item, function()
                self:OnClickDay(i)
            end, LSoundConst.CLICK_PAGE_COMMON)
        end
    end
end

function UIWretLanguage:BuyClickCommonSecretFunc()
    local curData = self._curPageData
    local inputNums = self._playInputNumList
    local args = string.replace(self._clearDreamFormat, inputNums[1], inputNums[2], inputNums[3], inputNums[4])
    self._buyArgs = args

    self._successSecretMsgStr = nil
    if self._isSecretSuccess then
        self._successSecretMsgStr = self:GetSuccessSecretMsgStr()
    end

    local func = function()
        self._playInputNumList = { -1, -1, -1, -1 }
        CS.ShowObject(self.mClickCover, true)
        if self._isResetCards then
            self:PlayResidueCardCoverClearEff()
            self:RefreshCarsRefreshEff()
            self:TimerStop(self._secretBuyTimerKey)
            self:TimerStart(self._secretBuyTimerKey, 1, false, 1)
        else
            self:SecretBuyFunc()
        end
    end

    local curNum = curData.guessingConsumeCount or 0
    local expends = self._expends
    local curExpend = expends[curNum + 1]
    if not curExpend then
        curExpend = expends[#expends]
    end

    local expendItem = string.split(curExpend, '=')
    local itemType = tonumber(expendItem[1])
    local isFree = itemType == 0
    if not isFree then
        local itemId = tonumber(expendItem[2])
        local haveNum = gModelItem:GetNumByRefId(itemId)
        local itemNum = tonumber(expendItem[3])
        if haveNum < itemNum then
            gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = self:GetWndName() })
            return
        end

        local tipPara = { refId = 110015, func = func, para = { itemNum }, sid = self._sid, consume = { itemNum, itemId } }
        gModelGeneral:OpenUIOrdinTips(tipPara, true)
    else
        func()
    end
end

function UIWretLanguage:SecretBuyFunc()
    if not self._isSecretSuccess then
        self:TweenSeq_ShakeTrans(self._doTweenShakeKey, self.mCardItemList, 10, 1)
    else
        if string.isempty(self._successSecretMsgStr) then
            GF.ShowMessage(ccClientText(21919))
        else
            GF.ShowMessage(self._successSecretMsgStr)
        end
    end
    self._successSecretMsgStr = nil

    gModelActivity:OnActivitySpecialOpReq(self._sid, self._buyPageId, self._buyEntryId, 6, self._buyArgs)
    CS.ShowObject(self.mClickCover, false)
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIWretLanguage:RefreshContent()
    self:RefreshRandomSecretNum()
    self:RefreshCurDayWndStatus()
    self:RefreshHelpText()
    self:RefreshConsumeItemNum()
    self:RefreshCardItemList()
    self:RefreshRewardReceived()
    self:RefreshNumInputList()
    self:RefreshBuyBtn()
end

function UIWretLanguage:OnClickDay(day)
    if not day then
        return
    end
    if (day > self._currDay) then
        GF.ShowMessage(ccClientText(21930))
        return
    end

    if table.isempty(self._sevenDaysTrans) then
        --防止断线重连报错，加个保护
        self:InitSevenDaysTrans()
    end

    if (self._nowDay > 0 and self._nowDay ~= day) then
        local trans = self._sevenDaysTrans[self._nowDay]
        self:ChangeDayImage(trans, false, self._nowDay)
        self:ChangeDayTransTop(trans, false)
        self:ChangeDayEffect(false, self._nowDay)
        self:ChangeDayOrderLayer(self._nowDay, false)
        self._dayBgImgList[self._nowDay].raycastTarget = true
        self._playInputNumList = { -1, -1, -1, -1 }
    end
    local trans = self._sevenDaysTrans[day]
    self:ChangeDayImage(trans, true, day)
    self:ChangeDayTransTop(trans, true)
    self:ChangeDayEffect(true, day)
    self:ChangeDayOrderLayer(day, true)
    self._dayBgImgList[day].raycastTarget = false
    self._nowDay = day
    self._curPageData = self._pages[day]

    self:RefreshCurDayRewardGetStatus()
    local guessingSuccess = self._curPageData.guessingSuccess or 0
    self._isSecretSuccess = guessingSuccess == 1

    self:RefreshContent()

    gModelActivity:SetIsActWitchSecretDayClick(day, true)
    --gModelActivity:OnActivitySpecialOpReq(self._sid,day,nil,ModelActivity.CANCEL_RED_POINT, "1")
    self:ShowRedPoint()
end

function UIWretLanguage:InitRoleSpine()
    local config = self._config
    local heroRefId = config.image
    local effectRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
    if not effectRef then
        return
    end
    local prefabName = effectRef.heroDrawing
    local prefabKey = prefabName

    if self._curUIHeroObj[prefabKey] then
        return
    end

    local newUIHeroObj = LUIHeroObject:New(self)
    newUIHeroObj:Create(self.mHeroCGEffRoot, prefabKey, prefabName)
    newUIHeroObj:SetScale(1)
    --newUIHeroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
    newUIHeroObj:ShowHero(true)
    newUIHeroObj:StartLoad()

    local pos = config.pos
    if not string.isempty(pos) then
        self:SetAnchorPos(self.mHeroCGEffRoot, LxDataHelper.ParseVector2NotEmpty(pos))
    end

    self._curUIHeroObj[prefabKey] = newUIHeroObj
end

function UIWretLanguage:OnClickNumText()
    local curStatus = self._curSecretStatus
    if curStatus == self.STATUS_FAKE_COMPLETE or curStatus == self.STATUS_COMMON_COMPLETE then
        return
    end

    local min, max = 0, self._secretMaxNum
    local default = ""
    for k, v in ipairs(self._playInputNumList) do
        if v >= 0 then
            default = default .. v
        end
    end

    local func = function(input, cmd)
        if cmd == "D" then
            --关闭键盘
            self._isOpenNumInput = false
            self:RefreshNumInputList()
            return
        end

        local inputLen = string.len(input)
        for k, v in ipairs(self._playInputNumList) do
            if k <= inputLen then
                self._playInputNumList[k] = tonumber(string.sub(input, k, k))
            else
                self._playInputNumList[k] = -1
            end
        end

        self:RefreshNumInputList()
    end

    self._isOpenNumInput = true
    self:RefreshNumInputList()
    GF.OpenWndUp("UINuoardUI",
            { minNum = min, maxNum = max, defaultNum = default,
              inputFunc = func, inputTran = self.mNumList, inputType = 1, cancelType = 1 })
end

function UIWretLanguage:OnActivityPageResp(pb)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end

    self:ResetActivePageData(pb)
    self:ResetUIData()
    self:OnClickDay(self._nowDay)
end


--#####################################################################################################################
--## Spine ############################################################################################################
--#####################################################################################################################
function UIWretLanguage:PlayBookPageStartSpine()
    self._isPlayOpenSpine = true
    CS.ShowObject(self.mCoverBg, false)
    CS.ShowObject(self.mChangePageEffRoot, true)
    self._bookPageSp:PlayAnimationSolid("idle1", false)
    self._bookPageSp:SetAnimationCompleteFunc(function()
        self:PlayBookPageCardDrawSpine()
    end)
end

function UIWretLanguage:OnTimer(key)
    if (key == self._secretLanguageTime) then
        self:SetTimeStr()
    elseif key == self._secretFakeTimerKey then
        self:SecretFake()
    elseif key == self._secretBuyTimerKey then
        self:SecretBuyFunc()
    end
end

function UIWretLanguage:RefreshSevenDayImg()
    for i, v in ipairs(self._sevenDaysTrans) do
        local bg = self._dayBgList[i]
        local icon = self._currDay < i and self._sevenDayNoOpenIcon or self._sevenDaysIconList[i]
        self:SetWndEasyImage(bg, icon, function()
            CS.ShowObject(bg, true)
        end)
    end
end

function UIWretLanguage:CheckShowDayRedPoint(dayIndex)
    if not self:CheckHaveNoGetByDayIndex(dayIndex) then
        return false
    end

    if gModelActivity:GetIsActWitchSecretDayClick(dayIndex) then
        return false
    end

    return true
end

function UIWretLanguage:InitData()
    local webData = gModelActivity:GetWebActivityDataById(self._sid)
    if not webData then
        return
    end

    self._activity = gModelActivity:GetActivityBySid(self._sid)
    local activityData = JSON.decode(self._activity.moreInfo)
    self._activityMoreInfo = activityData
    local config = webData.config
    self._config = config


    --创建角色spine动画
    self:InitRoleSpine()

    -- 七天图标
    self._sevenDaysIconList = string.split(config.tabIcon, ",")
    -- 额外参数
    self._moreInfo = self._activity.moreInfo
    -- 活动剩余时间
    self._endTime = tonumber(self._activity.endTime)

    self:SetSecretLanguageTime()

    --设置标题图片
    local path = config.titleIcon
    local pos
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mTitleImg, path, function()
            CS.ShowObject(self.mTitleImg, true)
        end, true)

        pos = config.titleIconPos
        if not string.isempty(pos) then
            self:SetAnchorPos(self.mTitleImg, LxDataHelper.ParseVector2NotEmpty(pos))
        end
    end

    path = config.passwordItemIcon
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(self.mConsumeImage, path, nil, false)
    end

    --3个宝箱的框图，道具图，名字
    local boxName = string.split(config.boxName, '|')
    for k, v in ipairs(boxName) do
        local curBoxName = string.split(v, '=')
        local quality = tonumber(curBoxName[2])
        self._rewardData[k].icon = curBoxName[1]
        self._rewardData[k].quality = quality
        self._rewardData[k].name = curBoxName[3]

        local qualityRef = gModelItem:GetQualityRef(quality)
        if qualityRef then
            self._rewardData[k].nameColor = qualityRef.nameColor
            self._rewardData[k].iconBg = qualityRef.iconBg
        end
    end
    --宝箱已领取图标
    self._rewardReceivedIcons = {}
    self:InitRewardList()
    self:InitNumList()

    -- 活动分页数据
    self._curPageData = nil

    self._decodeNum = config.decodeNum

    --解码消耗
    self._expends = string.split(config.expend, '|')

    self._curInputNumIndex = 1

    self:InitSevenDaysTrans()
end

function UIWretLanguage:BuyClickSecretFunc()
    if table.isempty(self._pages) then
        return
    end

    local curData = self._curPageData
    if not curData then
        printInfoNR("self._pages[self._nowDay] is not find, self._nowDay = " .. self._nowDay)
        return
    end

    local inputNums = self._playInputNumList
    for k, v in ipairs(inputNums) do
        if tonumber(v) < 0 then
            GF.ShowMessage(ccClientText(21908))
            return
        end
    end

    local curStatus = self._curSecretStatus

    local password
    if curStatus == self.STATUS_COMMON_SECRET then
        password = curData.password
    elseif curStatus == self.STATUS_FAKE_SECRET then
        local randomData = self._randomNumList[self._nowDay]
        password = randomData.password
    else
        printInfoNR("Error， no find status, curStatus = " .. curStatus)
        return
    end

    local isResetCards = true
    self._isSecretSuccess = true
    for k, v in pairs(password) do
        if tonumber(inputNums[k]) ~= tonumber(v) then
            isResetCards = false
            self._isSecretSuccess = false
            break
        end
    end

    if not isResetCards and self._residueNum == 1 then
        isResetCards = true
    end
    self._isResetCards = isResetCards

    if curStatus == self.STATUS_COMMON_SECRET then
        self:BuyClickCommonSecretFunc()
    elseif curStatus == self.STATUS_FAKE_SECRET then
        --完全解密后，不再请求后端，由前端控制玩法逻辑
        self:BuyClickFakeSecretFunc()
    else
        printInfoNR("Error， no find status, curStatus = " .. curStatus)
        return
    end
end

function UIWretLanguage:RefreshCurDayWndStatus()
    local curData = self._curPageData
    local isSecretSuccess = self._isSecretSuccess
    local guessingSuccess = curData.guessingSuccess or 0

    local curNum
    local residueNum
    local isFake = self._isRewardAllGet and guessingSuccess == 0
    if not isFake then
        curNum = curData.guessingCount or 0
        residueNum = math.max(self._decodeNum - curNum, 0)
        if isSecretSuccess or residueNum == 0 then
            self._curSecretStatus = self.STATUS_COMMON_COMPLETE
        else
            self._curSecretStatus = self.STATUS_COMMON_SECRET
        end
    else
        local randomData = self._randomNumList[self._nowDay]
        local secretStatus = randomData.secretStatus
        curNum = randomData.guessingCount or 0
        residueNum = math.max(self._decodeNum - curNum, 0)
        if isSecretSuccess or residueNum == 0 or secretStatus == 1 or secretStatus == 2 then
            if secretStatus == 1 then
                self._isSecretSuccess = true
            elseif secretStatus == 2 then
                self._isSecretSuccess = false
            end

            self._curSecretStatus = self.STATUS_FAKE_COMPLETE
        else
            self._curSecretStatus = self.STATUS_FAKE_SECRET
        end
    end

    self._residueNum = residueNum
end

function UIWretLanguage:RefreshHelpText()
    local str = ""
    local curStatus = self._curSecretStatus
    if curStatus == self.STATUS_COMMON_SECRET
            or curStatus == self.STATUS_FAKE_SECRET then
        str = ccClientText(21900)
    else
        if self._isSecretSuccess then
            str = ccClientText(21921)
        end
    end

    self:SetWndText(self.mHelpTxt, str)
end

function UIWretLanguage:ClearRandomSecretNum(curDay)
    if not curDay then
        curDay = self._nowDay
    end

    self._randomNumList[curDay] = nil
end

function UIWretLanguage:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        self:OnActivityListResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)
    end)
    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(wndName)
        if wndName == "UIHuiYPay" then
            gModelActivity:OnActivityPageReq(self._sid)
        end
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:InitData()
        gModelActivity:OnActivityPageReq(self._sid)
    end)
    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:ShowRedPoint() end)
end

function UIWretLanguage:InitPara()
    self._sid = self:GetWndArg("sid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        self._sid = gModelActivity:GetSidByUniqueJump(subpage)
    end

    --self._bookPageSp = self:CreateWndSpine(self.mChangePageEffRoot, "Mengyouxianjing", "MengyouxianjingPage", false,
    --		function(dpSpine)
    --			self._bookPageSp = dpSpine
    --			self:BookPageSpineLoadFunc() end)

    --7天卡牌翻转动作名字
    self._sevenDaysSpineNameList = {
        [1] = "idle4",
        [2] = "idle5",
        [3] = "idle6",
        [4] = "idle7",
        [5] = "idle8",
        [6] = "idle9",
        [7] = "idle10",
    }

    --0~9数字卡牌艺术字
    self._secretNumTextFormat = "<sprite index=%s>"

    --未开放时图标
    --self._sevenDayNoOpenIcon = "activity_dream_btn_0";
    self._sevenDayNoOpenIcon = "activity_43card8";
    self._secretLanguageTime = "secretLanguageTime"

    --3个宝箱的框图
    self._rewardData = {
        { iconBg = "public_item_bg_5", },
        { iconBg = "public_item_bg_6", },
        { iconBg = "public_item_bg_4", },
    }

    self._dayEffectName = "fx_mengyouxianjing_kapai"

    self._isPlayOpenSpine = false
    self._isFirstIn = true

    --玩家输入的解密数字列表, 默认显示上为空
    self._playInputNumList = {
        -1, -1, -1, -1,
    }
    --前端生成的随机数密码
    self:InitRandomSecretNum()

    --活动分页数据
    self._pages = {}
    -- 天数红点列表
    self._dayRedPointList = {}
    -- 天数提示可领取特效列表
    self._dayCanGetEffTransList = {}
    -- 天数的可领取红点
    self._dayCanGetRedPointTransList = {}
    -- 天数选择特效列表
    self._dayEffTransList = {}
    -- 天数选择的图片
    self._selectTrans = {}
    -- 天数点击检测的背景图
    self._dayBgImgList = {}
    -- 天数背景图
    self._dayBgList = {}

    --活动操作构建参数格式
    --1=p1|p2|...	1=解梦操作、p=输入的密码
    --self._clearDreamFormat = "1=%s|%s|%s|%s"
    self._clearDreamFormat = "1=#a1#|#a2#|#a3#|#a4#"
    --2=消除噩梦卡: 2=pIndex|cIndex	pIndex=密码所在下标（1-N）、cIndex=掀开的噩梦卡下标（1=6）
    self._drawCardFormat = "2=#a1#|#a2#"

    --设置面板当前状态
    self._curSecretStatus = self.STATUS_COMMON_SECRET
    --解密成功或失败
    self._isSecretSuccess = false

    self._isResetCards = false
    self._canvasRect = LGameUI.GetUICanvasRoot()
    self._hadClearRed = false

    self._isHideAni = true  -- 屏蔽动画

    gModelActivity:ReqActivityConfigData(self._sid)
end

function UIWretLanguage:ChangeDayImage(trans, bool, dayIndex)
    local bg = CS.FindTrans(trans, "Bg")
    local icon = self._sevenDaysIconList[dayIndex]
    if icon then
        if bool then
            icon = icon .. "_1"
        end

        self:SetWndEasyImage(bg, icon)
    end
end

function UIWretLanguage:OnClickRewardItem()
    local curData = self._curPageData
    if not curData then
        printInfoNR("self._pages[self._nowDay] is not find, self._nowDay = " .. (self._nowDay or "nil"))
        return
    end

    local config = self._config
    local txtReward = config.txtReward
    local boxName = config.boxName
    GF.OpenWnd("UIWretAwards", { txtReward = txtReward, boxName = boxName, page = curData,title=config.rewardName })
end

function UIWretLanguage:InitStaticInfo()
    self:SetWndText(self.mButtomDesc, ccClientText(10103))
    self:SetWndText(self.mTitleTxt, ccClientText(21901))
end

function UIWretLanguage:OnClickConsumeItemBtn()
    if not self._config then
        return
    end

    local str = self._config.itemTxt or ""
    GF.OpenWndUp("UIBzTips", {
        title = ccClientText(21903),
        text = str })
end

function UIWretLanguage:OnClickCardPart(itempos, cardPartIndex)
    local coverTransData = self._coverTransList[itempos]
    if not coverTransData then
        printInfoNR("self._coverTransList[itempos] is a nil, itempos = " .. itempos)
        return
    end

    local curCoverTransData = coverTransData[cardPartIndex]
    if not coverTransData then
        printInfoNR("self._coverTransList[itempos][cardPartIndex] is a nil, itempos = " .. itempos .. "; cardPartIndex = " .. cardPartIndex)
        return
    end

    local coverTrans = curCoverTransData.trans
    if coverTrans then
        CS.ShowObject(coverTrans, false)
        self:PlayTargetCardPosCoverClearEff(coverTrans)
    end

    curCoverTransData.isShow = false

    --完全解密后，不再请求后端，由前端控制玩法逻辑
    local curStatus = self._curSecretStatus
    if curStatus == self.STATUS_FAKE_SECRET then
        local randomData = self._randomNumList[self._nowDay]
        if not randomData.coverUpCard[itempos] then
            randomData.coverUpCard[itempos] = {}
        end
        table.insert(randomData.coverUpCard[itempos], cardPartIndex)
        self:RefreshConsumeItemNum()
        return
    end

    local pageId = self._curPageData.pageId
    local entryId = self._curPageData.entryId
    local args = string.replace(self._drawCardFormat, itempos, cardPartIndex)
    gModelActivity:OnActivitySpecialOpReq(self._sid, pageId, entryId, 6, args)
end

--#####################################################################################################################
--## Random ###########################################################################################################
--#####################################################################################################################
function UIWretLanguage:InitRandomSecretNum()
    self._randomNumList = {}
    local witchSecretLocal = string.split(LPlayerPrefs.witchSecretLocal, ',')
    local curSecret
    for k, v in ipairs(witchSecretLocal) do
        local curData = string.split(v, '-')
        local curSidId = tonumber(curData[1])
        if curSidId == self._sid then
            curSecret = curData
            break
        end
    end

    if not curSecret then
        return
    end

    --构建前端密码
    for i = 3, #curSecret do
        local curDayLocalData = string.split(curSecret[i], '=')
        local dayIndex = tonumber(curDayLocalData[1])
        local guessingCount = tonumber(curDayLocalData[2])
        local secretStatus = tonumber(curDayLocalData[3])
        local passwordData = string.split(curDayLocalData[4], '|')

        local passwordStr
        local password = {}
        local coverUpCard = {}
        for q, p in ipairs(passwordData) do
            local curPasswordData = string.split(p, '+')
            local passwordNum = curPasswordData[1]
            if not passwordStr then
                passwordStr = passwordNum
            else
                passwordStr = passwordStr .. "|" .. passwordNum
            end
            table.insert(password, passwordNum)

            local curCoverUPCard
            for j = 2, #curPasswordData do
                local coverUpCardPos = curPasswordData[j]
                if not curCoverUPCard then
                    curCoverUPCard = {}
                end
                table.insert(curCoverUPCard, coverUpCardPos)
            end

            if curCoverUPCard then
                coverUpCard[q] = curCoverUPCard
            end
        end

        self._randomNumList[dayIndex] = {
            guessingCount = guessingCount,
            passwordStr = passwordStr,
            password = password,
            coverUpCard = coverUpCard,
            secretStatus = secretStatus, -- 0解密中，1解密成功，2次数耗尽
        }
    end
end

function UIWretLanguage:RefreshCardItemList()
    local curData = self._curPageData
    if not curData then
        printInfoNR("self._pages[self._nowDay] is not find, self._nowDay = " .. self._nowDay)
        return
    end

    local password
    local coverUpCard
    local curStatus = self._curSecretStatus
    if curStatus == self.STATUS_COMMON_SECRET or curStatus == self.STATUS_COMMON_COMPLETE then
        password = curData.password
        if not (password) then
            printInfoNR("self._pages[self._nowDay].password is not find, self._nowDay = " .. self._nowDay)
            return
        end

        coverUpCard = curData.coverUpCard
    elseif curStatus == self.STATUS_FAKE_SECRET or curStatus == self.STATUS_FAKE_COMPLETE then
        local randomData = self._randomNumList[self._nowDay]
        password = randomData.password
        coverUpCard = randomData.coverUpCard
    else
        printInfoNR("Error， no find status, curStatus = " .. curStatus)
        return
    end

    local passNumDataList = {}
    for k, v in ipairs(password) do
        local curCoverUpCars = {}
        local coverUpCardList = coverUpCard[k]
        if coverUpCardList then
            for q, p in ipairs(coverUpCardList) do
                curCoverUpCars[tonumber(p)] = true
            end
        end

        local data = {
            password = v,
            coverUpCars = curCoverUpCars,
        }

        table.insert(passNumDataList, data)
    end

    local uiList = self._cardItemList
    if (uiList) then
        uiList:RefreshList(passNumDataList)
    else
        uiList = self:GetUIScroll("cardItemList")
        self._cardItemList = uiList
        uiList:Create(self.mCardItemList, passNumDataList, function(...)
            self:OnDrawCardItemFunc(...)
        end)
    end
end

function UIWretLanguage:RefreshNumInputList()
    if table.isempty(self._numInputTransList) then
        return
    end

    local playInputNumList = self._playInputNumList
    local curSelectIndex = 0
    for k, v in ipairs(self._numInputTransList) do
        local curNum = playInputNumList[k]
        local numStr = ""
        if curNum > -1 then
            numStr = curNum
            curSelectIndex = k + 1
        end
        local numStr_2 = ""
        if (not string.isempty(numStr)) and checknumber(numStr) >= 0 then
            numStr_2 = string.format(self._secretNumTextFormat, numStr)
        end

        self:SetWndText(v, numStr_2)
    end

    curSelectIndex = math.range(curSelectIndex, 1, #self._numSelectTransList)
    for k, v in ipairs(self._numSelectTransList) do
        CS.ShowObject(v, self._isOpenNumInput and curSelectIndex == k)
    end
end

function UIWretLanguage:GetLocalRandomCoverUpCardStr()
    local randomData = self._randomNumList[self._nowDay]
    if not randomData then
        return ""
    end

    -- 格式 a1=c1|c2|..;a2=c1|c5;  a 表示所在密码下标， c表示所在噩梦卡下标
    local coverUpCardStr
    local coverUPCard = randomData.coverUpCard
    for k, v in pairs(coverUPCard) do
        local coverUpCardPos = k .. "=" .. table.concat(v, '|')
        if not coverUpCardStr then
            coverUpCardStr = coverUpCardPos
        else
            coverUpCardStr = coverUpCardStr .. ";" .. coverUpCardPos
        end
    end

    return coverUpCardStr or ""
end

function UIWretLanguage:GetLocalRandomSecretNumStr()
    if table.isempty(self._randomNumList) then
        return nil
    end

    local curTime = GetTimestamp()
    --活动id-记录时间-天数index=已解密次数=解密状态=密码1+掀开位置1+掀开位置2|密码2|..-天数index=已解密次数=密码1..
    local curActData = self._sid .. "-" .. curTime
    for k, v in pairs(self._randomNumList) do
        local guessingCount = v.guessingCount
        local password = v.password
        local coverUpCard = v.coverUpCard
        local secretStatus = v.secretStatus
        local nextStr

        for q, p in ipairs(password) do
            local coverUpCardStr = ""
            if coverUpCard[q] then
                coverUpCardStr = "+" .. table.concat(coverUpCard[q], "+")
            end

            if not nextStr then
                nextStr = p .. coverUpCardStr
            else
                nextStr = nextStr .. "|" .. p .. coverUpCardStr
            end
        end

        curActData = curActData .. "-" .. k .. "=" .. guessingCount .. "=" .. secretStatus .. "=" .. nextStr
    end
    return curActData
end

function UIWretLanguage:CheckHaveNoGetByDayIndex(dayIndex)
    local pageData = self._pages[dayIndex]
    local receiveRewardIndex = pageData.receiveRewardIndex
    return receiveRewardIndex < #self._rewardData - 1
end

function UIWretLanguage:BuyClickCommonCompleteFunc()
    --重置密码
    self._isSecretSuccess = false
    gModelActivity:OnActivitySpecialOpReq(self._sid, self._buyPageId, self._buyEntryId, 6, "3")
end

function UIWretLanguage:OnDrawNumItemFunc(list, item, itemdata, itempos)
    local nameText = self:FindWndTrans(item, "Text")
    local selectImg = self:FindWndTrans(item, "SelectImg")

    self:SetWndClick(item, function()
        self:OnClickNumText(itempos)
    end)
    self._numInputTransList[itempos] = nameText
    self._numSelectTransList[itempos] = selectImg

    if itempos >= #self._playInputNumList then
        self:RefreshNumInputList()
    end
end

function UIWretLanguage:ChangeDayEffectOrderLayer(effTrans, dayIndex)
    if dayIndex < 4 then
        return
    end

    if not CS.IsValidObject(effTrans) then
        return
    end

    local dpParentTrans = effTrans.parent.transform
    if dpParentTrans and CS.IsValidObject(dpParentTrans) then
        local rendererSort = dpParentTrans:GetComponent(typeofUISorting)
        if not rendererSort then
            rendererSort = dpParentTrans.gameObject:AddComponent(typeofUISorting)
        end
        rendererSort:SetParentOrder(self:GetWndSortOrder() + 1)
        rendererSort:UpdateSorting()
    end
end

function UIWretLanguage:InitRewardList()
    local uiList = self._rewardList
    local itemsList = self._rewardData
    if (uiList) then
        uiList:RefreshList(itemsList)
    else
        uiList = self:GetUIScroll("rewardList")
        self._rewardList = uiList
        uiList:Create(self.mRewardList, itemsList, function(...)
            self:OnDrawRewardItemFunc(...)
        end)
    end
end

function UIWretLanguage:GetTransScreenPos(targetTrans)
    local canvasRect = self._canvasRect
    return YXUIPointUtil.GetScreenPoint(canvasRect, targetTrans)
end

function UIWretLanguage:SetTimeStr()
    local curTime = GetTimestamp()
    local time = self._endTime - curTime
    if time > 0 then
        local strText = ccClientText(15506)
        local str = LUtil.FormatTimespanCn(time)
        self:SetWndText(self.mTimeText, strText .. str)
    else
        self:TimerStop(self._secretLanguageTime)
        self:WndClose()
    end
end

function UIWretLanguage:RefreshRewardReceived()
    if table.isempty(self._pages) then
        return
    end

    local curData = self._curPageData
    if not curData then
        printInfoNR("self._pages[self._nowDay] is not find, self._nowDay = " .. self._nowDay)
        return
    end

    local receiveRewardIndex = curData.receiveRewardIndex or -1
    local isGetReward
    for k, v in ipairs(self._rewardReceivedIcons) do
        isGetReward = receiveRewardIndex >= k - 1
        CS.ShowObject(v, isGetReward)
    end
end

function UIWretLanguage:OnClickHelpTxt()

    if self:IsInputMask() then
        --GF.ShowMessage(ccClientText(10160))
        return
    end

    local curData = self._curPageData
    local nowDay = self._nowDay

    local secretData
    local useNum
    local curStatus = self._curSecretStatus
    if curStatus == self.STATUS_COMMON_SECRET or curStatus == self.STATUS_COMMON_COMPLETE then
        secretData = {
            passwordStr = curData.passwordStr,
            coverUpCardStr = curData.coverUpCardStr,
        }
        useNum = curData.decode or 0
    elseif curStatus == self.STATUS_FAKE_SECRET or curStatus == self.STATUS_FAKE_COMPLETE then
        local randomData = self._randomNumList[nowDay]
        secretData = {
            passwordStr = randomData.passwordStr,
            coverUpCardStr = self:GetLocalRandomCoverUpCardStr(),
        }

        useNum = 0
        for k, v in pairs(randomData.coverUpCard) do
            useNum = useNum + #v
        end
    else
        printInfoNR("Error， no find status, curStatus = " .. curStatus)
        return
    end

    local chatType
    if self._isSecretSuccess then
        chatType = ModelChat.CHATSHARE_SECRET_CONGRATULATION
        secretData.curDay = nowDay
        secretData.useConsumeNum = useNum
    else
        chatType = ModelChat.CHATSHARE_SECRET_LANGUAGE
    end

    local jsonStr = JSON.encode(secretData)
    local data = {
        root = self.mHelpTxt,
        shareType = chatType,
        shareData = jsonStr
    }
    gModelGeneral:OpenShareTip(data)
end

function UIWretLanguage:ChangeDayOrderLayer(dayIndex, isTop)
    --只有顶部的3个要调整层级
    if dayIndex > 3 then
        return
    end

    local trans = self._sevenDaysTrans[dayIndex]

    local changeOrder
    if isTop then
        changeOrder = 3
    else
        changeOrder = 1
    end

    local instCanvas = trans:GetComponent(typeofCanvas)
    if instCanvas then
        instCanvas.sortingOrder = self:GetWndSortOrder() + changeOrder
    end

    --修改特效层级
    if isTop then
        changeOrder = 2
    else
        changeOrder = 0
    end
    local selectEffTrans = self._dayEffTransList[dayIndex]
    if selectEffTrans and CS.IsValidObject(selectEffTrans) then
        local rendererSort = selectEffTrans:GetComponent(typeofUISorting)
        if rendererSort then
            rendererSort:SetParentOrder(self:GetWndSortOrder() + changeOrder)
            rendererSort:UpdateSorting()
        end
    end

    local canGetEffTrans = self._dayCanGetEffTransList[dayIndex]
    if canGetEffTrans and CS.IsValidObject(canGetEffTrans) then
        local rendererSort = selectEffTrans:GetComponent(typeofUISorting)
        if rendererSort then
            rendererSort:SetParentOrder(self:GetWndSortOrder() + changeOrder)
            rendererSort:UpdateSorting()
        end
    end
end
--#####################################################################################################################
--## RedPoint #########################################################################################################
--#####################################################################################################################
-- 显示红点
function UIWretLanguage:ShowRedPoint()
    if table.isempty(self._pages) then
        return
    end

    --for i, obj in pairs(self._dayCanGetEffTransList) do
    --	CS.ShowObject(obj,false)
    --end

    for i, obj in pairs(self._dayCanGetRedPointTransList) do
        CS.ShowObject(obj, false)
    end

    local haveShowRed = false
    for i = 1, 7 do
        if (i > self._currDay) then
            break
        end
        if (self._nowDay ~= i) then
            local bool = self:CheckShowDayRedPoint(i)
            --local obj = self._dayCanGetEffTransList[i]

            local obj = self._dayCanGetRedPointTransList[i]
            if bool then
                haveShowRed = true
                local effKey = self._canGetEffName .. i
                local endFunc = function(effNode)
                    self:ChangeDayEffectOrderLayer(effNode, i)
                end

                --self:CreateWndEffect(obj,self._canGetEffName,effKey,100,false,
                --		false, nil,nil,nil,nil,
                --		nil, endFunc)
            end

            CS.ShowObject(obj, bool)
        end
    end

    if not haveShowRed and not self._hadClearRed then
        gModelRedPoint:SetActivityRedClicked(self._sid)
    end
end

function UIWretLanguage:BookPageSpineLoadFunc()
    self._bookPageSpIsLoaded = true
    if self._bookPageSpIsLoaded and self._activityCfgDataLoad then
        self:PlayBookPageStartSpine()
    end
end

function UIWretLanguage:OnActivityListResp(pb)
    local activities = pb.activities
    for i, v in ipairs(activities) do
        local sid = v.sid
        if self._sid == sid then
            self._activity = gModelActivity:GetActivityBySid(self._sid)
            self._activityMoreInfo = JSON.decode(self._activity.moreInfo)
            self:InitData()

            if not table.isempty(self._pages) then
                self:ResetUIData()
                self:OnClickDay(self._nowDay)
            end
            break
        end
    end
end

function UIWretLanguage:ChangeDayEffect(bool, dayIndex)
    local eff = self._dayEffTransList[dayIndex]
    if not eff then
        return
    end

    local effectName = self._dayEffectName
    local effKey = effectName .. dayIndex

    CS.ShowObject(self._selectTrans[dayIndex], bool)

    --CS.ShowObject(self._dayEffTransList[dayIndex], bool)
    --if bool and not self:FindWndEffectByKey(effKey) then
    --	self:CreateWndEffect(eff,effectName,effKey,100,false,false,
    --			nil, nil, nil, nil, nil, nil, 2)
    --end
end

function UIWretLanguage:RefreshCurDayRewardGetStatus()
    local curData = self._curPageData
    if not curData then
        return
    end
    local receiveRewardIndex = curData.receiveRewardIndex
    self._isRewardAllGet = receiveRewardIndex and receiveRewardIndex >= #self._rewardData - 1 or false
end

--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UIWretLanguage:SetSecretLanguageTime()
    self:TimerStop(self._secretLanguageTime)
    if self._endTime > 0 then
        --非永久活动
        local curTime = GetTimestamp()
        local time = self._endTime - curTime
        if time <= 0 then
            self:WndClose()
            return
        else
            self:TimerStart(self._secretLanguageTime, 1, false, -1)
        end

        self:SetTimeStr()
    else
        local strText = ccClientText(16800)
        self:SetWndText(self.mTimeText, strText .. ccClientText(10170))
    end
end

function UIWretLanguage:OnClickHelpBtn()
    if not self._config then
        return
    end

    local str = self._config.txt or ""
    GF.OpenWndUp("UIBzTips", {
        title =  gModelActivity:GetLngNameById(self._config.name) ,
        para = { },
        text = str })
end

function UIWretLanguage:PlayBookPageCardDrawSpine()
    local curDay = self._currDay
    if not curDay then
        return
    end

    local animName = self._sevenDaysSpineNameList[curDay]
    self._bookPageSp:PlayAnimationSolid(animName, false)
    self._bookPageSp:SetAnimationCompleteFunc(function()
        CS.ShowObject(self.mChangePageEffRoot, false)
        CS.ShowObject(self.mDayList, true)
    end)


end

function UIWretLanguage:PlayTargetCardPosCoverClearEff(coverItemTrans)
    local effName = self._coverClearEffName
    local targetPos = self:GetTransScreenPos(coverItemTrans)
    local idx = self._coverClearEffIdx
    self._coverClearEffIdx = idx + 1
    local uiEffectObj = LUIEffectObject:New(self)
    self._uiEffectObjList[idx] = uiEffectObj

    local completeFunc = function()
        if table.isempty(self._uiEffectObjList) then
            return
        end
        local tmpObj = self._uiEffectObjList[idx]
        tmpObj:Destroy()
        self._uiEffectObjList[idx] = nil
        LxTimer.DelayTimeStop(self._delayTimeList[idx])
        self._delayTimeList[idx] = nil
    end

    uiEffectObj:EnablePool(self._simplePool)
    uiEffectObj:Create(self.mCoverEff, effName, 100, 0, 2, function(obj)
        local dpEff = obj:GetDisplayEffect()
        dpEff:SetVisible(true)
        dpEff:GetDisplayTrans().localPosition = targetPos
        if not self._delayTimeList then
            return
        end
        self._delayTimeList[idx] = LxTimer.DelayTimeCall(completeFunc, 1)
    end)
    uiEffectObj:StartLoad()
end

function UIWretLanguage:GetSuccessSecretMsgStr()
    local curData = self._curPageData
    local receiveRewardIndex = curData.receiveRewardIndex or -1
    local maxIndex = #self._rewardData - 1
    if receiveRewardIndex == maxIndex then
        --奖励已全部领取
        return nil
    end

    local decodeConditions = curData.decodeConditions
    local useNum = curData.decode or 0
    local useIndex = 0
    for k, v in ipairs(decodeConditions) do
        if useNum <= tonumber(v) then
            useIndex = k
        end
    end

    local str
    local startIndex = math.max(receiveRewardIndex + 1, 0) + 1
    for i = startIndex, useIndex do
        local curRewardData = self._rewardData[i]
        local nameStr = curRewardData.name
        local nameStrColor = curRewardData.nameColor
        if nameStrColor then
            nameStr = string.format(self._rewardNameFormat, nameStrColor, nameStr)
        end

        if not str then
            str = nameStr
        else
            str = str .. '，' .. nameStr
        end
    end

    if not str then
        --没有奖励可领取
        return nil
    end

    return string.replace(ccClientText(21932), str)
end

function UIWretLanguage:InitNumList()
    local itemsList = self._playInputNumList
    local uiList = self._numInputList
    if (uiList) then
        uiList:RefreshList(itemsList)
    else
        uiList = self:GetUIScroll("numList")
        self._numInputList = uiList
        uiList:Create(self.mNumList, itemsList, function(...)
            self:OnDrawNumItemFunc(...)
        end)
    end

end

--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIWretLanguage:ResetActivePageData(pb)
    -- 活动分页数据解析
    for i, b in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(b)
        if page then
            self._pages = {}
            for p, q in pairs(page.entry) do
                local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, q.entryId)
                if not entryCfg then
                    return
                end

                local data = {
                    pageId = q.pageId,
                    entryId = q.entryId,
                    day = entryCfg.day,
                    items = string.split(entryCfg.reward, '|'),
                    passwordItem = tonumber(entryCfg.passwordItem),
                    decodeConditions = string.split(entryCfg.decode, '|'),
                    cfgPassword = entryCfg.password,
                    coverUpCard = {},
                    moreInfo = entryCfg.moreInfo,
                    --MarketData = q.MarketData,
                    --goalData = q.goalData,
                }

                local moreInfo = JSON.decode(q.moreInfo)
                local moreInfoStr
                for k, v in pairs(moreInfo) do
                    moreInfoStr = string.split(k, '_')
                    local key = moreInfoStr[1]
                    if key == "guessingCount" then
                        --当前解密次数（密码重置后归零）
                        data.guessingCount = tonumber(v)
                    elseif key == "guessingConsumeCount" then
                        --消耗次数（用来读取 钻石消耗）
                        data.guessingConsumeCount = tonumber(v)
                    elseif key == "receiveRewardIndex" then
                        --当前已领取的奖励档次下标
                        data.receiveRewardIndex = tonumber(v)
                    elseif key == "password" then
                        --当前密码
                        data.passwordStr = v
                        data.password = string.split(v, '|')
                    elseif key == "decode" then
                        --密码本次使用次数
                        data.decode = tonumber(v)
                    elseif key == "coverUpCard" then
                        --噩梦卡掀开信息 格式 a1=c1|c2|..;a2=c1|c5;  a 表示所在密码下标， c表示所在噩梦卡下标
                        data.coverUpCardStr = v
                        local coverUpCards = string.split(v, ';')
                        local numIndex, cardIndexList
                        for j, g in ipairs(coverUpCards) do
                            local cardData = string.split(g, '=')
                            numIndex = tonumber(cardData[1])
                            cardIndexList = cardData[2]
                            data.coverUpCard[numIndex] = string.split(cardIndexList, '|')
                        end
                    elseif key == "guessingSuccess" then
                        --解密成功还未重置标记 0不需要重置，1需要重置
                        data.guessingSuccess = tonumber(v)
                    end
                end

                table.insert(self._pages, data)
            end
        end
    end

    table.sort(self._pages, function(a, b)
        return a.day < b.day
    end)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIWretLanguage:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end

    self:InitData()
    gModelActivity:OnActivityPageReq(self._sid)
end

function UIWretLanguage:OnDrawCardItemFunc(list, item, itemdata, itempos)
    local numText = self:FindWndTrans(item, "NumText")
    local coverList = self:FindWndTrans(item, "CoverList")
    local effTrans = self:FindWndTrans(item, "Eff")
    local coverTransList = {}

    local coverUpCars = itemdata.coverUpCars
    local isShow = false
    local curStatus = self._curSecretStatus
    for i = 1, self._coverMaxNum do
        local curCover = self:FindWndTrans(coverList, "Cover" .. i)
        if curStatus == self.STATUS_COMMON_SECRET or curStatus == self.STATUS_FAKE_SECRET then
            isShow = not coverUpCars[i]
        end
        coverTransList[i] = {
            trans = curCover,
            isShow = isShow,
        }
        CS.ShowObject(curCover, isShow)
        if isShow then
            self:SetWndClick(curCover, function()
                self:OnClickCardPart(itempos, i)
            end)
        end
    end

    self._coverTransList[itempos] = coverTransList
    self._cardEffsList[itempos] = effTrans
    CS.ShowObject(effTrans, false)

    local password = itemdata.password
    local numStr = string.format(self._secretNumTextFormat, password)
    self:SetWndText(numText, numStr)
end

function UIWretLanguage:InitEvent()
    self:SetWndClick(self.mBgImage, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mHelpTxt, function()
        self:OnClickHelpTxt()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mHelpImg, function()
        self:OnClickHelpBtn()
    end, LSoundConst.CLICK_ERROR_COMMON)
    self:SetWndClick(self.mTitleImg, function()
        self:OnClickHelpBtn()
    end, LSoundConst.CLICK_ERROR_COMMON)
    self:SetWndClick(self.mConsumeItemBg, function()
        self:OnClickConsumeItemBtn()
    end, LSoundConst.CLICK_ERROR_COMMON)
    self:SetWndClick(self.mBuyBtn, function()
        self:OnClickBuyBtn()
    end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIWretLanguage:PlayResidueCardCoverClearEff()
    if table.isempty(self._coverTransList) then
        return
    end

    for k, v in pairs(self._coverTransList) do
        for p, q in pairs(v) do
            if q.isShow then
                q.isShow = false
                CS.ShowObject(q.trans, false)
                self:PlayTargetCardPosCoverClearEff(q.trans)
            end
        end
    end
end

function UIWretLanguage:ClearTimerClose()
    for k, v in pairs(self._delayTimeList) do
        LxTimer.DelayTimeStop(v)
    end

    self._delayTimeList = {}
end

function UIWretLanguage:RefreshBuyBtn()
    if table.isempty(self._pages) then
        return
    end

    local curData = self._curPageData
    if not curData then
        printInfoNR("self._pages[self._nowDay] is not find, self._nowDay = " .. self._nowDay)
        return
    end

    local str
    local buttonStr
    local isComplete = false
    local isSuccess = self._isSecretSuccess
    local isShowItem
    local isShowNoItem
    local buyNumStr = ""
    local itemImg

    local curStatus = self._curSecretStatus
    if curStatus == self.STATUS_COMMON_SECRET then
        buttonStr = ccClientText(21902)
        isShowItem = true
        isShowNoItem = false

        local consumeTime = curData.guessingConsumeCount or 0
        local expends = self._expends
        local curExpend = expends[consumeTime + 1]
        if not curExpend then
            curExpend = expends[#expends]
        end
        local expendItem = string.split(curExpend, '=')
        local itemType = tonumber(expendItem[1])
        local isFree = itemType == 0
        local itemId = tonumber(expendItem[2])
        local itemNum = tonumber(expendItem[3])
        buyNumStr = isFree and ccClientText(21907) or itemNum

        itemImg = gModelItem:GetItemImgByRefId(itemId)
    elseif curStatus == self.STATUS_COMMON_COMPLETE then
        isComplete = true
        str = ccClientText(21924)
        buttonStr = ccClientText(21926)
        isShowItem = false
        isShowNoItem = false
    elseif curStatus == self.STATUS_FAKE_SECRET then
        --完全解密后，不再请求后端，由前端控制玩法逻辑
        buttonStr = ccClientText(21902)
        isShowItem = false
        isShowNoItem = true
        buyNumStr = ccClientText(21918)
    elseif curStatus == self.STATUS_FAKE_COMPLETE then
        isComplete = true
        str = ccClientText(21927)
        buttonStr = ccClientText(21926)
        isShowItem = false
        isShowNoItem = false
    else
        printInfoNR("Error， no find status, curStatus = " .. curStatus)
        return
    end

    --设置提示
    local residueNum = self._residueNum
    if not isComplete then
        local colorStr = residueNum > 1 and "green" or "red"
        colorStr = LUtil.FormatColorStr(residueNum, colorStr)
        str = string.replace(ccClientText(21906), colorStr)
    elseif isSuccess then
        str = ccClientText(21923) .. str
    else
        str = string.replace(ccClientText(21925), self._decodeNum)
    end
    self:SetWndText(self.mDecodeNumText, str)

    --设置道具消耗
    CS.ShowObject(self.mBuyItemIcon, isShowItem)
    CS.ShowObject(self.mBuyNumText, isShowItem)
    CS.ShowObject(self.mBuyNumText2, isShowNoItem)
    if isShowItem then
        self:SetWndText(self.mBuyNumText, buyNumStr)
        if itemImg then
            self:SetWndEasyImage(self.mBuyItemIcon, itemImg)
        end
    elseif isShowNoItem then
        self:SetWndText(self.mBuyNumText2, buyNumStr)
    end

    --设置按钮描述
    self:SetWndButtonText(self.mBuyBtn, buttonStr)
end

function UIWretLanguage:ResetLocalRandomSecretNum()
    local curTime = GetTimestamp()
    local witchSecretLocal = string.split(LPlayerPrefs.witchSecretLocal, ',')
    local witchSecretLocalList = {}
    for k, v in ipairs(witchSecretLocal) do
        local curSecret = string.split(v, '-')
        local recordTime = tonumber(curSecret[2])
        local sid = tonumber(curSecret[1])
        if curTime < recordTime + 2592000 and sid ~= self._sid then
            table.insert(witchSecretLocalList, v)
        end
    end

    local curActData = self:GetLocalRandomSecretNumStr()
    if curActData then
        table.insert(witchSecretLocalList, curActData)
    end

    --活动id-记录时间-天数index=已解密次数=密码1+掀开位置1+掀开位置2|密码2|..-天数index=已解密次数=密码1..,活动id-记录时间-..
    local res = table.concat(witchSecretLocalList, ',')
    LPlayerPrefs.SetWitchSecretLocal(res)
end

function UIWretLanguage:OnClickBuyBtn()
    local curStatus = self._curSecretStatus
    local curData = self._curPageData
    local pageId = curData.pageId
    self._buyPageId = pageId
    local entryId = curData.entryId
    self._buyEntryId = entryId

    if curStatus == self.STATUS_COMMON_SECRET
            or curStatus == self.STATUS_FAKE_SECRET then
        self:BuyClickSecretFunc()
    elseif curStatus == self.STATUS_COMMON_COMPLETE then
        self:BuyClickCommonCompleteFunc()
    elseif curStatus == self.STATUS_FAKE_COMPLETE then
        self:BuyClickFakeCompleteFunc()
    else
        printInfoNR("Error， no find status, curStatus = " .. curStatus)
        return
    end
end

function UIWretLanguage:OnDrawRewardItemFunc(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local icon = self:FindWndTrans(root, "Icon")
    local received = self:FindWndTrans(root, "Received")
    local nameTxt = self:FindWndTrans(item, "Name")

    self._rewardReceivedIcons[itempos] = received

    local path = itemdata.iconBg
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(root, path)
    end

    path = itemdata.icon
    if LxUiHelper.IsImgPathValid(path) then
        self:SetWndEasyImage(icon, path,function()
            CS.ShowObject(icon,true)
        end)
    end

    local nameStr = itemdata.name
    local nameStrColor = itemdata.nameColor
    if nameStrColor then
        nameStr = string.format(self._rewardNameFormat, nameStrColor, nameStr)
    end

    self:SetWndText(nameTxt, nameStr)

    self:SetWndClick(root, function()
        self:OnClickRewardItem()
    end)

    if itempos >= #self._rewardData then
        self:RefreshRewardReceived()
    end
end

function UIWretLanguage:RefreshConsumeItemNum()
    local curData = self._curPageData
    if not curData then
        printInfoNR("self._pages[self._nowDay] is not find, self._nowDay = " .. self._nowDay)
        return
    end

    local curStatus = self._curSecretStatus
    local consumeMax = curData.passwordItem
    local useNum

    if curStatus == self.STATUS_COMMON_SECRET or curStatus == self.STATUS_COMMON_COMPLETE then
        useNum = curData.decode or 0
    elseif curStatus == self.STATUS_FAKE_SECRET or curStatus == self.STATUS_FAKE_COMPLETE then
        local randomData = self._randomNumList[self._nowDay]
        useNum = 0
        for k, v in pairs(randomData.coverUpCard) do
            useNum = useNum + #v
        end
    else
        printInfoNR("Error， no find status, curStatus = " .. curStatus)
        return
    end

    local consumeNum = math.range(consumeMax - useNum, 0, consumeMax)
    local consumeColor = "lightGreen"
    if consumeNum == 0 then
        consumeColor = "red"
    end

    consumeNum = LUtil.FormatColorStr(consumeNum, consumeColor)

    local str = string.replace(ccClientText(21905), consumeNum, consumeMax)
    self:SetWndText(self.mConsumeNumTxt, str)
end

function UIWretLanguage:RefreshCarsRefreshEff()
    if table.isempty(self._cardEffsList) then
        return
    end

    local effName = self._cardRefreshEffName
    local effKey
    for k, v in ipairs(self._cardEffsList) do
        effKey = effName .. k
        if not self:FindWndEffectByKey(effKey) then
            self:CreateWndEffect(v, effName, effKey, 95, false, false)
        else
            CS.ShowObject(v, false)
        end
        CS.ShowObject(v, true)
    end
end



--#####################################################################################################################
--## Effect ###########################################################################################################
--#####################################################################################################################
function UIWretLanguage:InitCoverEffectPlayPool()
    local simplePool = LSimplePool:New()
    self._simplePool = simplePool

    simplePool:InitPool(self.mContentEffRoot, "cardsCoverEffPlay")

    local effName = self._coverClearEffName
    local assetPath = CS.ResPath(CS.RES_ANY_PREFAB, LxResPathUtil.GetEffectAssetPath(effName))
    local args = simplePool:MakeArgs(assetPath, effName, nil, nil)
    simplePool:InitPoolItem(args)
end

function UIWretLanguage:RefreshRandomSecretNum()
    if not self._isRewardAllGet then
        return
    end

    local curDay = self._nowDay
    if not table.isempty(self._randomNumList[curDay]) then
        return
    end

    local pageData = self._curPageData
    local cfgPassword = string.split(pageData.cfgPassword, '|')
    local resPassWords = {}

    math.randomseed(tostring(os.time()):reverse():sub(1, 7))
    for k, v in ipairs(cfgPassword) do
        local password = tonumber(v)
        if password ~= -1 then
            table.insert(resPassWords, password)
        else
            table.insert(resPassWords, math.random(0, 9))
        end
    end

    local passwordStr = table.concat(resPassWords, '|')
    self._randomNumList[curDay] = {
        guessingCount = 0,
        passwordStr = passwordStr,
        password = resPassWords,
        coverUpCard = {},
        secretStatus = 0,
    }
end

function UIWretLanguage:ResetUIData()
    if table.isempty(self._pages) then
        return
    end

    -- 天数
    local curDay = 1
    for k, v in ipairs(self._pages) do
        if table.isempty(v.password) then
            break
        else
            curDay = k
        end
    end

    self._currDay = math.range(curDay, 1, 7)-- 最大七天
    if not self._nowDay then
        self._nowDay = self._currDay    --默认当前天数index
    end

    self:RefreshSevenDayImg()

    --首次打开时，播放动画
    if not self._isPlayOpenSpine and (not self._isHideAni) then
        self._activityCfgDataLoad = true
        if self._bookPageSpIsLoaded and self._activityCfgDataLoad then
            self:PlayBookPageStartSpine()
        end
    end
end

function UIWretLanguage:ChangeDayTransTop(trans, isTop)
    local layerIndex
    if isTop then
        layerIndex = 6
    else
        layerIndex = self._nowDay - 1
    end

    trans:SetSiblingIndex(layerIndex)
end

function UIWretLanguage:SecretFake()
    local nowDay = self._nowDay
    local randomData = self._randomNumList[nowDay]
    local password = randomData.password
    local isError = false
    for k, v in ipairs(self._playInputNumList) do
        if v ~= tonumber(password[k]) then
            isError = true
            break
        end
    end

    self._playInputNumList = { -1, -1, -1, -1 }
    if isError then
        GF.ShowMessage(ccClientText(21920))
        local guessingCount = randomData.guessingCount
        randomData.guessingCount = guessingCount + 1
        if self._decodeNum <= randomData.guessingCount then
            --次数耗尽,失败
            randomData.secretStatus = 2
        end
    else
        GF.ShowMessage(ccClientText(21919))
        --密码正确，成功
        randomData.secretStatus = 1
    end

    self:RefreshCurDayRewardGetStatus()
    self:RefreshContent()
end

------------------------------------------------------------------
return UIWretLanguage




