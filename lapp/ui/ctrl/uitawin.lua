---
--- Created by BY.
--- DateTime: 2023/10/13 17:51:22
---
------------------------------------------------------------------
local LWnd = LWnd
local Color = Color
---@class UITaWin:LWnd
local UITaWin = LxWndClass("UITaWin", LWnd)
local typeOfSkeletonGraphic = typeof(Spine.Unity.SkeletonGraphic)
local typeUIImage = typeof(UnityEngine.UI.Image)
local typeofXUIMelt = typeof(CS.YXUIMelt)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaWin:UITaWin()
    ---@type table<number, CommonIcon>
    self._commonIconTbl = {}
    self._uiheadList = {}
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaWin:OnWndClose()
    self:ClearCommonIconList(self._commonIconTbl)
    self:ClearCommonIconList(self._uiheadList)
    self._commonIconTbl = nil

    if self._simplePool then
        self._simplePool:ClearPool()
        self._simplePool:Destroy()
        self._simplePool = nil
    end
    --
    CS.ShowObject(self.mUITraceSR, false)
    CS.ShowObject(self.mUITraceSR2, false)

    print("----------------UITaWin:OnWndClose()")

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaWin:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus then
        self:SetAnchorPos(self.mTipsBtn,Vector2.New(120,0))
    end 
    
    self:SetHideTop(true)
    self:InitEvent()
    self:InitMessage()
    self:CreateSimplePool()
    self:InitData()
    self:InitCommand()
    self:RefreshRed()
    --local newInfo = gModelGeneral:IsNewHeroWnd()
    local wndHeroInfo = "UINewSagaInfo"-- newInfo.wndHeroInfo
    --local wndInst = GF.FindFirstWndByName(wndHeroInfo)
    --if wndInst then
    GF.CloseWndByName(wndHeroInfo)
    --end
    gModelTower:SetNumRed()
--[[    local noOpentPrivile = self:GetWndArg("noOpentPrivile")
    if not noOpentPrivile then
        --gModelBackflow:SetPrivileBtn(self.mBtnPrivile,7,self)

        local priviCom = self:GetPrivilegeCom()
        priviCom:Create(self.mBtnPrivile, 7, self)
    end]]

    self:OnUpdateSweepRed()
    self:SetSecretJumpBtn(self.mBtnSecret, 7)
    self:RefreshForeign()
end

function UITaWin:OnClickLayer(itemdata, tasLayer, bool)
    local _towerType = self._towerType
    -- if(tasLayer >= itemdata.floorNum)then
    -- 	GF.ShowMessage(ccClientText(12154))
    -- 	return
    -- else
    if (tasLayer + 1 < itemdata.floorNum) then
        GF.ShowMessage(ccClientText(12140))
        return
    elseif (bool) then
        gModelTower:OnClickLayerBtn(itemdata.type, itemdata.refId)
        -- gModelTower:OnClickLayerBtn(_towerType,itemdata.refId)
        return
    end
    GF.OpenWnd("UITaMopUpPop", { refId = itemdata.refId, towerType = itemdata.type })
    -- GF.OpenWnd("UITaMopUpPop",{refId = itemdata.refId,towerType = _towerType})
end

function UITaWin:SetLayerPlayer(info, headIcon, refId)
    if info and headIcon then
        CS.ShowObject(headIcon, true)
        local playerData = {
            trans = headIcon,
            icon = info.head,
            headFrame = info.headFrame,
            level = info.level,
            noEff = true
        }
        local uiheadlist = self._uiheadList
        local InstanceID = info.playerId
        local baseClass = uiheadlist[InstanceID]
        if not baseClass then
            baseClass = HeadIcon:New(self)
            uiheadlist[InstanceID] = baseClass
        end
        baseClass:SetHeadData(playerData)
        baseClass:RefreshUI()
        self:SetWndClick(headIcon, function(...)
            GF.OpenWnd("UITaLayePop", { towerType = self._towerType, refId = refId })
        end)
    end
end

function UITaWin:InitCommand()
    self._towerType = self:GetWndArg("towerType") or ModelTower.RACE_COM
    -- local textTask=CS.FindTrans(self.mTaskBtn,"XUIText")
    -- self:SetWndText(textTask,ccClientText(12101))
    -- if not gModelFunctionOpen:CheckIsShow(16400017) then
    -- 	CS.ShowObject(self.mTaskBtn, false)
    -- end
    local textBPass = CS.FindTrans(self.mPassBBtn, "XUIText")
    self:SetWndText(textBPass, ccClientText(12165))
    local textDPass = CS.FindTrans(self.mPassDBtn, "XUIText")
    self:SetWndText(textDPass, ccClientText(12167))
    self:SetWndButtonText(self.mReturnBtn, ccClientText(12108))
    self:SetWndText(self.mTxtSweep, ccClientText(12186))
    CS.ShowObject(self.mSweepBtn, self._towerType == ModelTower.RACE_COM)

    self:SetWndText(self.mRankTileText, ccClientText(11819))
    self:SetWndText(self.mLookRankText, ccClientText(17205))
    self:InitTextLineWithLanguage(self.mLookRankText, -40)
    self.mLookRankText.sizeDelta = Vector2.New(180, 30)
    local ref = gModelTower:GetTowerPatternRefByRefId(self._towerType)
    gModelRank:OnRankReq(2, ref.rankRefId, 1, 3, nil)

    self:ResetTowerType()

end

function UITaWin:OnActivityConfigData(data, sid)
    local _activitySids = self._activitySids
    if not _activitySids or not _activitySids[sid] then
        return
    end
    local webData = gModelActivity:GetWebActivityDataById(sid)
    if not webData then
        return
    end
    local data = webData.config
    if data.towerFreeSweepName then
        self._towerFreeSweepName = data.towerFreeSweepName
        self:RefreshLayer()
    end
end

function UITaWin:RaceListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    --local bg = self:FindWndTrans(root,"Bg")
    local icon = self:FindWndTrans(root, "Icon")
    local raceText = self:FindWndTrans(root, "RaceText")
    local redPoint = self:FindWndTrans(root, "RedPoint")

    self:InitTextLineWithLanguage(raceText, -20)

    local showRed = false
    if itemdata.type == 4 then
        showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.TOWER_RACE_COM_SWEEP)
    end
    CS.ShowObject(redPoint, showRed)

    self:SetWndEasyImage(icon, itemdata.icon)
    self:SetWndText(raceText, itemdata.des)
    local uiText = LxUiHelper.FindXTextCtrl(raceText)
    local height = uiText.preferredHeight
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height + 84)
    self:SetWndClick(root, function()
        local type = itemdata.type
        if type == 1 then
            GF.OpenWnd("UITaAwardPop", { openType = 2 })
        elseif type == 2 then
            GF.ShowMessage(itemdata.des)
        elseif type == 3 then
            GF.OpenWndTop("UITaCutToEff", { cutToEff = "fx_slzt_zhuanchang_02", callfunc1 = function()
                self._towerType = ModelTower.RACE_TYPE_99
                LPlayerPrefs.SetTowerDifficulty("true")

                local ref = gModelTower:GetTowerPatternRefByRefId(ModelTower.RACE_TYPE_99)
                gModelRank:OnRankReq(2, ref.rankRefId, 1, 3, nil)

                self:ResetTowerType()


            end })
        elseif type == 4 then
            GF.OpenWndTop("UITaCutToEff", { callfunc1 = function()
                self._towerType = ModelTower.RACE_COM
                LPlayerPrefs.SetTowerDifficulty("false")

                local ref = gModelTower:GetTowerPatternRefByRefId(ModelTower.RACE_COM)
                gModelRank:OnRankReq(2, ref.rankRefId, 1, 3, nil)

                self:ResetTowerType()
            end })
        end

    end)
end

function UITaWin:OnClickPassD()
    local jump = gModelTower:GetTowerConfigRefByKey("raceJump")
    gModelFunctionOpen:Jump(jump, self:GetWndName())
end

function UITaWin:OnClickLookRank()
    --排行榜
    local ref = gModelTower:GetTowerPatternRefByRefId(self._towerType)
    GF.OpenWndBottom("UIRkPop", { refId = ref.rankRefId })
end

function UITaWin:InitAward()
    local towerType = self._towerType
    local isUnlockRace = gModelTower:GetIsUnlockRaceTower()
    local patternRef = gModelTower:GetTowerPatternRefByRefId(towerType)
    local titleStr = ""
    if isUnlockRace then
        titleStr = string.replace(ccClientText(12157), ccLngText(patternRef.name))
    else
        titleStr = ccClientText(12100)
    end
    self:CreateWndEffect(self.mTitleEff, patternRef.nameEffect, " nameEffect", 100)
    self:SetWndText(self.mTitleText, titleStr)
    local layer = gModelTower:GetTasLayer(towerType)
    local ref = gModelTower:GetCurrPhaseRef(towerType)
    local len = #self._arwardTransList <= 2 and #self._arwardTransList or 2
    local isForeign = gLGameLanguage:IsForeignVersion()
    CS.ShowObject(self.mTowerRewardBg, not isForeign)
    CS.ShowObject(self.mTowerRewardBgEn, isForeign)
    CS.ShowObject(self.mAwardGetText, not isForeign)
    CS.ShowObject(self.mAwardGetTextEn, isForeign)
    if isForeign then
        self:InitTextSizeWithLanguage(self.mAwardGetTextEn, -4)
    end
    self:SetWndText(self.mAwardGetText, ccClientText(12160))
    self:SetWndText(self.mAwardGetTextEn, ccClientText(12160))
    if (not ref or not ref.reward) then
        for i = 1, len do
            CS.ShowObject(self._arwardTransList[i], false)
            self:SetWndText(self.mAwardText, "")
        end
        CS.ShowObject(self.mTowerRewardBg, false)
        CS.ShowObject(self.mAwardText, false)
        CS.ShowObject(self.mAwardGetText, false)
        return
    end
    CS.ShowObject(self.mAwardGetText, false)
    CS.ShowObject(self.mAwardGetTextEn, false)
    CS.ShowObject(self.mTowerRewardBg, true)
    CS.ShowObject(self.mTowerRewardBgEn, false)
    local itemArry = LxDataHelper.ParseItem(ref.reward)
    for i = 1, 2 do
        local trans = self._arwardTransList[i]
        self:SetItemData(trans, itemArry[i])--设置阶级奖励
    end
    self:SetWndText(self.mAwardText, layer .. "/" .. ref.floor)

    CS.ShowObject(self.mSweepBtn, self._towerType == ModelTower.RACE_COM)
    self:RefreshRed()
end

function UITaWin:RefreshRaceList()
    local _towerType = self._towerType
    local layer = gModelTower:GetTasLayer(_towerType)
    if _towerType == ModelTower.RACE_COM or _towerType == ModelTower.RACE_TYPE_99 then
        local list = {}
        if _towerType == ModelTower.RACE_COM then
            local num = gModelTower:GetUnlockRaceTowerNum()
            local unlockForeshowRace = gModelTower:GetTowerConfigRefByKey("unlockForeshowRace")
            if num > 0 and unlockForeshowRace <= layer then
                local data = {
                    type = 1,
                    icon = "trial_btn_icon_5",
                    des = string.replace(ccClientText(12153), num),
                }
                table.insert(list, data)
            end

            local diffcultyNum = gModelTower:GetUnlockDifficultyTowerNum()
            local unlockForeshowDifficulty = gModelTower:GetTowerConfigRefByKey("unlockForeshowDifficulty")
            if diffcultyNum > 0 and unlockForeshowDifficulty <= layer then
                local data = {
                    type = 2,
                    icon = "trial_btn_icon_6",
                    des = string.replace(ccClientText(12177), diffcultyNum),
                }
                table.insert(list, data)
            elseif diffcultyNum <= 0 then
                local data = {
                    type = 3,
                    icon = "trial_btn_icon_7",
                    des = ccClientText(12178),
                }
                table.insert(list, data)
            end
        else
            local data = {
                type = 4,
                icon = "trial_btn_icon_8",
                des = ccClientText(12179),
            }
            table.insert(list, data)
        end

        local uiRaceList = self._uiRaceList
        if uiRaceList then
            uiRaceList:RefreshList(list)
        else
            local uiRaceList = self:GetUIScroll("uiRaceList")
            uiRaceList:Create(self.mRaceList, list, function(...)
                self:RaceListItem(...)
            end)
            self._uiRaceList = uiRaceList
        end
    end
end

function UITaWin:InitEvent()
    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mCloseBtn, function(...)
        GF.ChangeMap("LCityMap")
        self:OnClickCloseWnd()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mTipsBtn, function(...)
        self:OnClickTips()
    end)
    self:SetWndClick(self.mReturnBtn, function(...)
        self:OnClickReturnLayer()
    end)
    self:SetWndClick(self.mSweepBtn, function(...)
        self:OnClickRank()
    end)
    self:SetWndClick(self.mPassBBtn, function(...)
        self:OnClickPassB()
    end)
    self:SetWndClick(self.mPassDBtn, function(...)
        self:OnClickPassD()
    end)
    self:SetWndClick(self.mLookRankBtn, function(...)
        self:OnClickLookRank()
    end)
end

function UITaWin:RefreshBagRed()
    local redType = gModelTower:GetBehindPhaseArwardRedByType(self._towerType)
    CS.ShowObject(self.mBagRedPoint, redType > 0)
end

function UITaWin:ListItem(list, item, itemdata, itempos, fromHeadTail)
    if self:IsWndClosed() then
        return
    end
    local _towerType = self._towerType
    local instanceId = item:GetInstanceID()
    local control = CS.FindTrans(item, "Control")
    local imgBg = CS.FindTrans(control, "ImgBg")
    local bossSpine = CS.FindTrans(control, "BossSpine")
    -- local mopupBtn = CS.FindTrans(control,"MopupBtn")
    -- local mopupBtnText = CS.FindTrans(control,"MopupBtn/XUIText")
    -- local mopupBtnIcon = CS.FindTrans(mopupBtn,"icon")
    local challengeBtn = CS.FindTrans(control, "ChallengeBtn")
    local titleText = CS.FindTrans(control, "TierText")
    local txtTitle = CS.FindTrans(control, "TxtTitle")
    local tipsBtn = CS.FindTrans(control, "TipsBtn")
    local awardBg1 = CS.FindTrans(control, "AwardBg1")
    local awardBg2 = CS.FindTrans(control, "AwardBg2")
    local imgLine1 = CS.FindTrans(control, "ImgLine1")
    local imgLine2 = CS.FindTrans(control, "ImgLine2")
    local numText = CS.FindTrans(control, "NumText")
    local lockImage = CS.FindTrans(control, "LockImage")
    local tasImage = CS.FindTrans(control, "TasImage")
    local tipsVIP = CS.FindTrans(control, "TipsVIP")
    local textVIP = CS.FindTrans(control, "TipsVIP/XUIText")
    local activityImg = CS.FindTrans(control, "ActivityImg")
    local activityText = CS.FindTrans(control, "ActivityImg/ActivityText")
    local redPoint = CS.FindTrans(control, "ChallengeBtn/redPoint")
    local headIcon1 = CS.FindTrans(control, "HeadIcon1/HeadIcon1")
    local headIcon2 = CS.FindTrans(control, "HeadIcon2/HeadIcon2")
    local headIcon3 = CS.FindTrans(control, "HeadIcon3/HeadIcon3")


    local image_text_1 = CS.FindTrans(awardBg1, "Image_text")
    local image_text_2 = CS.FindTrans(awardBg2, "Image_text")


    if self._isEnus then
        --image_text_1.localScale = Vector2(1.5,1.5)
        --image_text_2.localScale = Vector2(1.5,1.5)
        --
        --self:SetAnchorPos(self.mTipsBtn,Vector2.New(120,0))
    end

    if not itemdata then
        return
    end

    local refId = itemdata.refId
    CS.ShowObject(redPoint, false)
    CS.ShowObject(control, refId)
    self:SetWndText(txtTitle, ccClientText(12185))
    local ref = gModelTower:GetTowerPatternRefByRefId(self._towerType)
    self:SetWndEasyImage(imgBg, ref.bg)
    local headIcons = {
        headIcon1,
        headIcon2,
        headIcon3
    }
    for i, v in ipairs(headIcons) do
        CS.ShowObject(v, false)
    end

    if not refId then
        return
    end
    CS.ShowObject(activityImg, false)
    local list = gModelTower:GetTypeTowerLayersByRefId(_towerType, refId)
    local layersPLen = #list
    if layersPLen > 0 then
        if layersPLen == 1 then
            local info = list[1]
            local headIcon = headIcons[1]
            self:SetLayerPlayer(info, headIcon, refId)
        elseif layersPLen == 2 then
            local info1 = list[1]
            local info2 = list[2]
            local headIcon1 = headIcons[2]
            local headIcon2 = headIcons[3]
            self:SetLayerPlayer(info1, headIcon1, refId)
            self:SetLayerPlayer(info2, headIcon2, refId)
        else
            for i = 1, 3 do
                local info = list[i]
                local headIcon = headIcons[i]
                self:SetLayerPlayer(info, headIcon, refId)
            end
        end
    end

    -- local posArr = string.split(itemdata.moveXY,",")
    -- control.localPosition = Vector2.New(tonumber(posArr[1]),tonumber(posArr[2]))

    local pos = (itemdata.floorNum + 1) % 2 == 0 and -45 or 263
    local delta = control.anchoredPosition
    delta.x = pos
    control.anchoredPosition = delta

    local _towerInfo = gModelTower:GetTowerInfoByTowerType(_towerType)
    if not _towerInfo then
        return
    end
    local tasLayer = _towerInfo.floor
    if (itempos < tasLayer - 6 or itempos > tasLayer + 8) then
        CS.ShowObject(self.mReturnBtn, true)
    else
        CS.ShowObject(self.mReturnBtn, false)
    end
    CS.ShowObject(bossSpine, false)
    -- CS.ShowObject(mopupBtn,false)
    CS.ShowObject(challengeBtn, false)
    self:SetWndText(titleText, itemdata.floorNum)

    if itemdata.floorNum>= 1000 then
        self:SetAnchorPos(titleText,Vector2.New(-40,60))
    end

    self:SetWndClick(tipsBtn, function(...)
        self:OnClickLayer(itemdata, tasLayer)
    end)
    CS.ShowObject(awardBg1, false)
    CS.ShowObject(awardBg2, false)
    CS.ShowObject(imgLine1, false)
    CS.ShowObject(imgLine2, false)
    self:SetWndText(numText, "")
    CS.ShowObject(lockImage, false)
    CS.ShowObject(tasImage, false)
    CS.ShowObject(tipsVIP, false)

    local imgLine = nil
    if ((itemdata.floorNum + 1) % 2 == 0) then
        imgLine = imgLine2
    else
        imgLine = imgLine1
    end
    CS.ShowObject(imgLine, true and itemdata.floorNum > 1)

    if itemdata.floorNum <= tasLayer or (_towerType ~= ModelTower.RACE_COM and itemdata.floorNum == tasLayer) then
        --已通关
        CS.ShowObject(tasImage, true)
        CS.ShowObject(bossSpine, true)
        self:SetBossSpine(bossSpine, itemdata.monsterShow, instanceId, 2)
        self:SetWndClick(bossSpine, function(...)
            self:OnClickLayer(itemdata, tasLayer)
        end)
        return
    end
    CS.ShowObject(bossSpine, true)
    self:SetWndClick(bossSpine, function(...)
        self:OnClickLayer(itemdata, tasLayer)
    end)
    local reawrdShowNum = gModelTower:GetTowerConfigRefByKey("reawrdFirstShowNum")
    if (itemdata.floorNum <= tasLayer + reawrdShowNum) then
        local commonTrans
        if ((itemdata.floorNum + 1) % 2 == 0) then
            commonTrans = awardBg2
        else
            commonTrans = awardBg1
        end
        CS.ShowObject(item, true)
        local itemArry = LxDataHelper.ParseItem(itemdata.rewardFirst)
        local itemStrArr = itemArry[1]
        self:SetItemData(commonTrans, itemStrArr)--设置首通奖励
    end
    if itemdata.floorNum > tasLayer + 1 then
        --未开启
        CS.ShowObject(lockImage, true)
        self:SetBossSpine(bossSpine, itemdata.monsterShow, instanceId, 3)
        return
    end
    self:SetBossSpine(bossSpine, itemdata.monsterShow, instanceId, 2)
    self:SetWndClick(challengeBtn, function(...)
        self:OnClickLayer(itemdata, tasLayer, true)
    end)
    if (tasLayer + 1 == itemdata.floorNum) then
        --当前挑战的关卡
        CS.ShowObject(challengeBtn, true)
        self:SetWndButtonText(challengeBtn, ccClientText(12104))
        local isGray = false
        if _towerType ~= ModelTower.RACE_COM then
            --local ref = gModelTower:GetTowerPatternRefByRefId(_towerType)
            isGray = _towerInfo.maxChallengesNum - _towerInfo.battleNum == 0
        end
        self:SetWndButtonGray(challengeBtn, isGray)
        return
    end
    local list = gModelActivity:GetTowerSkipBuff({ "towerFreeSweepName", "towerFreeSweep" })
    local _towerFreeSweep = 0
    if list then
        local towerFreeSweep = list["towerFreeSweep"]
        if self._towerFreeSweepName and towerFreeSweep then
            _towerFreeSweep = towerFreeSweep
            CS.ShowObject(activityImg, true)
            self:SetWndText(activityText, string.replace(self._towerFreeSweepName, towerFreeSweep))
        end
    end
    --当前扫荡关卡
    -- local num = gModelTower:GetCurrNum(_towerType)
    -- local vipNum = gModelTower:GetVipGoBuy()
    -- local guyNum = gModelTower:GetBuySweepNum(_towerType)
    -- if(num <= 0)then
    -- 	local guyStr = gModelTower:GetExpend(guyNum + 1)
    -- 	self:SetWndText(mopupBtnText,guyStr..ccClientText(12106))
    -- 	CS.ShowObject(mopupBtn,true)
    -- 	self:SetWndClick(mopupBtn, function(...)
    -- 		self:OnClickLayer(itemdata,tasLayer,true)
    -- 	end)
    -- 	if(vipNum <= guyNum)then
    -- 		CS.ShowObject(tipsVIP,true)
    -- 		self:SetWndText(textVIP,ccClientText(12142))
    -- 		self:SetWndClick(tipsVIP, function(...)
    -- 			self:OnClickGoVip()
    -- 		end)
    -- 		return
    -- 	end
    -- 	self:SetWndText(numText,string.replace(ccClientText(12168),vipNum - guyNum))--设置免费次数
    -- else
    -- 	CS.ShowObject(challengeBtn,true)
    -- 	self:SetWndButtonText(challengeBtn,ccClientText(12105))
    -- 	CS.ShowObject(redPoint,true)
    -- 	self:SetWndText(numText,string.replace(ccClientText(12141),num))--设置免费次数
    -- end
end

function UITaWin:CreateSimplePool()
    local simplePool = LSimplePool:New()
    simplePool:InitPool(self.mSpinePool)
    self._simplePool = simplePool
end

function UITaWin:InitData()
    self._arwardTransList = {
        self.mAwardCommon1,
        self.mAwardCommon2
    }
    self._uiItems = {}
    self._instanceList = {}
end
function UITaWin:RefreshForeign()
    if self._isVie then
        self:InitTextSizeWithLanguage(self.mTitleText,-2)
    end
end

function UITaWin:SetBossSpine(trans, id, instanceId, bHei)
    local monster = gModelTower:GetShowMonster(id)
    local instanceList = self._instanceList
    local spine = instanceList[instanceId]
    CS.ShowObject(trans, true)
    if (spine) then
        if spine:GetAssetName() == monster .. "UI" then
            if (bHei ~= nil) then
                if (bHei == 1) then
                    spine:SetColor(Color.New(0, 0, 0, 1))
                elseif (bHei == 2) then
                    spine:SetColor(Color.New(1, 1, 1, 1))
                elseif (bHei == 3) then
                    spine:SetColor(Color.New(0.5, 0.5, 0.5, 1))
                end
            end
            return
        end
        spine:Destroy()
    end
    local dpSpine = self:CreateWndSpine(trans, monster, instanceId, true, function(dpLoaded)
        dpLoaded:PlayAnimation(0, "idle", true)
        if (bHei ~= nil) then
            if (bHei == 1) then
                dpLoaded:SetColor(Color.New(0, 0, 0, 1))
            elseif (bHei == 2) then
                dpLoaded:SetColor(Color.New(1, 1, 1, 1))
            elseif (bHei == 3) then
                dpLoaded:SetColor(Color.New(0.5, 0.5, 0.5, 1))
            end
        end
    end, true)
    dpSpine:SetUsePool(true)
    dpSpine:SetPool(self._simplePool)
    dpSpine:StartLoad()

    instanceList[instanceId] = dpSpine
end

function UITaWin:InitTraceScrollList()
    local _towerType = self._towerType
    local uiList
    if _towerType == ModelTower.RACE_TYPE_99 then
        uiList = self._uiTraceList2
    else
        uiList = self._uiTraceList
    end
    --CS.ShowObject(self.mUITraceSR2,_towerType == ModelTower.RACE_TYPE_99)
    --CS.ShowObject(self.mUITraceSR,_towerType ~= ModelTower.RACE_TYPE_99)
    CS.ShowObject(self.mUITraceSR, true)

    --这里默认都使用同一个
    --local mUITraceSR = _towerType == ModelTower.RACE_TYPE_99 and self.mUITraceSR2 or self.mUITraceSR
    local mUITraceSR = self.mUITraceSR

    uiList = UIListTrace:New()
    uiList:Create(self, mUITraceSR)
    uiList:SetFuncOnItemDraw(function(...)
        self:ListItem(...)
    end)
    if _towerType == ModelTower.RACE_TYPE_99 then
        self._uiTraceList2 = uiList
    else
        self._uiTraceList = uiList
    end

    local index = gModelTower:GetCurrLayer(_towerType) - 2
    local list = gModelTower:GetTowerLayerDataList(_towerType)
    table.insert(list, { index = #list + 1 })
    table.insert(list, { index = #list + 1 })
    --table.insert(list,{index = #list+1})
    uiList:RemoveAllData()
    for i = 1, #list do
        local data = list[i]
        data.index = i
        uiList:AddData(i, data)
    end
    uiList:RefreshList(1, index)
    CS.ShowObject(self.mReturnBtn, false)
    self:InitAward()

    self:SendGuideReadyEvent(self:GetWndName())
end
function UITaWin:OnWndRefresh()
    LWnd.OnWndRefresh(self)
    local _towerType = self:GetWndArg("towerType") or ModelTower.RACE_COM
    local ref = gModelTower:GetTowerPatternRefByRefId(_towerType)
    self._towerType = _towerType
    gModelRank:OnRankReq(2, ref.rankRefId, 1, 3, nil)
end

function UITaWin:OnClickTips()
    local value1 = gModelTower:GetTowerConfigRefByKey("freeTimes")
    local value2 = gModelTower:GetTowerConfigRefByKey("quickChallenge")
    GF.OpenWnd("UIBzTips", { refId = 5, para = { value1, value2 } })
end

function UITaWin:OnClickReturnLayer()
    self:GoFloor()
end

function UITaWin:OnTryTcpReconnect()
    gModelTower:OnTowerTypePlayerReq(self._towerType)
end
function UITaWin:OnUpdateRankResp(type, rankType)
    local ref = gModelTower:GetTowerPatternRefByRefId(self._towerType)
    if rankType == ref.rankRefId then
        local ranks = gModelRank:GetRankListInfo(type, rankType)
        local selfRank = gModelRank:GetMeRank()
        local playerId = gModelPlayer:GetPlayerId()
        local isExist = nil
        local value = nil
        for i = 1, 3, 1 do
            value = ranks[i]
            if not value then
                self:SetWndText(self["mRankText" .. i], "<color=#d2efff>" .. ccClientText(17270) .. "</color>")
                self:SetWndText(self["mTxtRankNum" .. i], "")
            else
                local str = value.info._name
                self:SetWndText(self["mRankText" .. i], "<color=#ffffff>" .. str .. "</color>")
                if not isExist and value.info._playerId == playerId then
                    isExist = i
                end
                -- local maxNodeRef = gModelEndles:GetEndlessCheckpointRefByRefId(value.score)
                self:SetWndText(self["mTxtRankNum" .. i], value.score)

            end
        end
        CS.ShowObject(self.mRankTextMe, not isExist and selfRank.rank > 0)
        CS.ShowObject(self.mImgRankMe, selfRank.rank > 0)
        local sizeDelta = self.mRankImage.sizeDelta
        sizeDelta.y = self.mRankTextMe.gameObject.activeSelf and 197 or 172
        self.mRankImage.sizeDelta = sizeDelta
        if selfRank.rank > 0 then
            self:InitTextSizeWithLanguage(self.mTxtRankNumMe, -2)
            self:SetWndText(self.mTxtRankNumMe, selfRank.score)
            self:SetWndText(self.mTxtRankMe, selfRank.rank)
            self:SetWndText(self.mRankTextMe, gModelPlayer:GetPlayerName())
            local anchoredPos = self.mImgRankMe.anchoredPosition
            if isExist then
                anchoredPos.y = self["mRankText" .. isExist].anchoredPosition.y
            end
            self.mImgRankMe.anchoredPosition = anchoredPos
        end
    end
end

function UITaWin:SetItemData(item, itemdata)
    if self:IsWndClosed() then
        return
    end
    if not item then
        return
    end
    CS.ShowObject(item, itemdata ~= nil)
    if not itemdata then
        return
    end
    local root = CS.FindTrans(item, "Root")
    local numText = CS.FindTrans(item, "Root/CommonUI/NumText")
    local iconTrans = CS.FindTrans(root, "CommonUI/Icon")
    local uiCommonList = self._commonIconTbl
    local InstanceID = item:GetInstanceID()
    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(iconTrans)
    end
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()
    self:SetWndText(numText, itemdata.itemNum)
    local formatData = {
        itemId = itemdata.itemId,
        itemType = itemdata.itemType,
        itemNum = itemdata.itemNum,
    }
    self:SetIconClickScale(iconTrans, true)
    self:SetWndClick(iconTrans, function()
        -- gModelGeneral:ShowCommonItemTipWnd(formatData)
        self:OnClickBag()
    end)
end

function UITaWin:OnClickBag()
    --print("点击阶段奖励")
    GF.OpenWnd("UITaAwardPop", { towerType = self._towerType })
end

function UITaWin:OnTryRefreshRedPoint(redPointType)
    if (redPointType == ModelRedPoint.ACTIVITY_ACTIVITY) then
        self:RefreshRed()
    end
end

function UITaWin:OnClickPassB()
    local jump = gModelTower:GetTowerConfigRefByKey("uniqueJump")
    gModelFunctionOpen:Jump(jump, self:GetWndName())
end

function UITaWin:OnClickRace()
    GF.OpenWnd("UITaAwardPop", { openType = 2 })
    --if self._towerType == ModelTower.RACE_COM then
    --	local num = gModelTower:GetUnlockRaceTowerNum()
    --	--CS.ShowObject(self.mRaceBtn,num > 0)
    --	if num > 0 then
    --		GF.ShowMessage(string.replace(ccClientText(12153),num))
    --	end
    --end
end

function UITaWin:GoFloor()
    CS.ShowObject(self.mReturnBtn, false)
    local index = gModelTower:GetCurrLayer(self._towerType) - 2
    index = index >= 0 and index or 0
    local uiList = self._towerType == ModelTower.RACE_TYPE_99 and self._uiTraceList2 or self._uiTraceList
    if (not uiList) then
        return
    end
    uiList:RefreshList(1, index)
end
function UITaWin:OnUpdateSweepRed()
    local typeInfo = gModelTower:GetTowerInfoByTowerType(self._towerType)
    local num = gModelTower:GetCurrNum(self._towerType)
    local redPoint = self:FindWndTrans(self.mSweepBtn, "SweepRedPoint")

    CS.ShowObject(redPoint, num > 0 and (typeInfo and typeInfo.historyMaxFloor > 0))
end

function UITaWin:OnClickGoVip()
    if (not gModelTower:GetVipBoolGoBuy()) then
        GF.ShowMessage(ccClientText(12143))
        return
    end
    GF.OpenWnd("UIOrdinTip", { refId = 80004, func = function(...)
        local wndInst = GF.FindFirstWndByName("UIHuiYPay")
        if not wndInst then
            GF.OpenWndBottom("UIHuiYPay")
        else
            FireEvent(EventNames.ON_VIPLEVEL_CHANGE)
        end
        self:WndClose()
    end })
end
function UITaWin:RefreshRed()
    local isComType = self._towerType == ModelTower.RACE_COM
    local activeRef
    local redTrans
    if isComType then
        activeRef = ModelActivity.MODEL_PASSB
        redTrans = self.mBRedPoint
    else
        activeRef = ModelActivity.MODEL_PASSD
        redTrans = self.mDRedPoint
    end

    local list = gModelActivity:GetActivityDataByModelId(activeRef)
    local activity = list[1]
    CS.ShowObject(self.mPassBBtn, isComType and activity)
    CS.ShowObject(self.mPassDBtn, not isComType and activity)
    if not activity then
        return
    end

    local sid = activity.sid
    local isRed = gModelRedPoint:CheckActivityShowRed(sid)
    CS.ShowObject(redTrans, isRed)
end

function UITaWin:OnClickCloseWnd()
    -- print("点击关闭界面")
    if not self:WndCloseAndBack() then
    end
    GF.OpenWndBottom("UIOutts",{ childIndex = 1 })
    FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
    local isBackWnd = gLGameUI:OpenBackWnd(self:GetWndName())
    if isBackWnd then
        self:WndClose()
        return
    end

    local num = gModelTower:GetUnlockRaceTowerNum()
    if num > 0 then
        self:WndClose()
    else
        GF.OpenWndTop("UITaCutToEff", { callfunc1 = function()
            GF.OpenWndBottom("UITaRacePopNew")
            self:WndClose()
        end })
    end
end

function UITaWin:InitMessage()
    self:WndNetMsgRecv(LProtoIds.TowerSweepResp, function(...)
        self:RefreshLayer()
        self:OnUpdateSweepRed()
    end)
    self:WndNetMsgRecv(LProtoIds.TowerInfoResp, function(...)
        self:RefreshLayer()
    end)
    self:WndNetMsgRecv(LProtoIds.TowerBeforeBattleResp, function(...)
        self:OnClickReturnLayer()
    end)
    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshBagRed() end)
    self:WndNetMsgRecv(LProtoIds.TowerTypePlayerResp, function(...)
        self:RefreshLayer()
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
	self:WndEventRecv(EventNames.ON_TOWER_PASS,function (...)
		self:RefreshRaceList()
	end)

    self:WndEventRecv(EventNames.ON_ACCOUNT_RELA_WND_CLOSE, function(wndName, combatType)
        if wndName and combatType == LCombatTypeConst.COMBAT_TOWER_BATTLE then
            local _towerType = self:GetWndArg("towerType") or ModelTower.RACE_COM
            local ref = gModelTower:GetTowerPatternRefByRefId(_towerType)
            gModelRank:OnRankReq(2, ref.rankRefId, 1, 3, nil)
        end
    end)

    self:WndEventRecv(EventNames.RANK_UPDATE_END, function(...)
        self:OnUpdateRankResp(...)
    end)
end

function UITaWin:OnClickMaxLayer()
    --print("敬请期待")
    GF.ShowMessage(ccClientText(12136))
end

function UITaWin:OnClickRank()
    -- local ref = gModelTower:GetTowerPatternRefByRefId(self._towerType)
    -- GF.OpenWndBottom("UIRkPop",{type = 2,refId = ref.rankRefId})

    GF.OpenWnd("UITaSweepTips", { towerType = self._towerType })
end

function UITaWin:RefreshLayer()
    local uiList = self._towerType == ModelTower.RACE_TYPE_99 and self._uiTraceList2 or self._uiTraceList
    uiList:DrawAllItems()
    self:InitAward()

    local isOpent = gModelTower:GetIsUnlockDifficultyTower()

    if isOpent then
        local _towerInfo = gModelTower:GetTowerInfoByTowerType(ModelTower.RACE_TYPE_99)
        if not _towerInfo then
            gModelTower:OnTowerInfoReq(ModelTower.RACE_TYPE_99)
        end
    end
end

function UITaWin:ResetTowerType()
    local _towerType = self._towerType
    local bg = "badgeGame_bg_big_1"
    if _towerType == ModelTower.RACE_TYPE_99 then
        bg = "badgeGame_bg_big_1"
    end
    local ref = gModelTower:GetTowerPatternRefByRefId(_towerType)
    local showRed = gModelRedPoint:CheckShowIdMapRedByRedId(ModelRedPoint.RANK_SCHEDULE, ref.rankRefId)
    CS.ShowObject(self.mRankRedPoint, showRed)
    self:SetWndEasyImage(self.mBgImage, bg)
    self:InitTraceScrollList()
    self:RefreshBagRed()
    self:RefreshRaceList()
    gModelTower:OnTowerTypePlayerReq(_towerType)

    local activityList = gModelActivity:GetActivityDataByModelId(ModelActivity.COMMONRANK, ModelActivity.STATUS_VALID)
    if #activityList == 0 then
        return
    end
    local list = {}
    for k, v in ipairs(activityList) do
        list[v.sid] = true
    end
    self._activitySids = list
    for i, v in pairs(list) do
        gModelActivity:ReqActivityConfigData(i)
    end


end
------------------------------------------------------------------
return UITaWin


