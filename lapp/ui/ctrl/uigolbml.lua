---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolbMl:LWnd
local UIGolbMl = LxWndClass("UIGolbMl", LWnd)
local typeOfSkeletonGraphic = typeof(Spine.Unity.SkeletonGraphic)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolbMl:UIGolbMl()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolbMl:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolbMl:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    self._mapEventList = {}                                --初始化点地图击事件
    self._startChapterEff = "_startChapterEff"            --开始播放特效
    self._endChapterEff = "_endChapterEff"                --结束播放特效
    self._effParent = nil                                --特效父对象
    self._iconChapter = nil                                --章节图标 播放特效需要隐藏
    self._newChapterId = nil                            --新章节 需要播放特效
    self._mapEffTransList = {}                                --地图模块
    self._mapTransList = {}                                --地图模块
    self._mapIndex = 0                                    --地图模块索引
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolbMl:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitDragData()
    self:InitCommand()
end

function UIGolbMl:InitMapList(roll)
    --初始化地图块
    local worldMapRef = gModelInstance:GetWorldMapRef()
    -- local iconArr = string.split(gModelInstance:GetInstancePara("ChapterPic"), ";")
    -- local mapBgArr = string.split(gModelInstance:GetInstancePara("mapBg"), ";")
    -- local txtColorArr = string.split(gModelInstance:GetInstancePara("txtColor"), ";")
    local colorIndex, iconStr, mapStr, mapColor
    for i = 1, 6 do
        local mapRefData = self:GetMapRefDataByNum(worldMapRef, i)
        local trans = CS.FindTrans(self.mItemList, "MapItem" .. i)
        local btn = CS.FindTrans(trans, "MapBtn")
        local mask = CS.FindTrans(trans, "Mask")
        CS.ShowObject(btn, mapRefData)
        CS.ShowObject(mask, true)
        if (mapRefData) then
            local mapNum = mapRefData.num
            local effTrans = CS.FindTrans(self.mItemBgEffList, "MapItem" .. mapNum)
            self._mapEffTransList[mapNum] = effTrans
            self._mapTransList[mapNum] = trans
            local nameText = CS.FindTrans(btn, "NameText")
            local iconMap = CS.FindTrans(btn, "Icon")
            local eff = CS.FindTrans(btn, "Eff")
            CS.ShowObject(mask, mapNum > roll)

            -- self:SetXUITextTransColor(nameText, "734f22")
            if mapNum > roll then
                -- colorIndex = 3
                iconStr = "public_lock_7"
                -- mapStr = mapBgArr[1]
                -- mapColor = txtColorArr[1]
                --self:SetXUITextTransColor(nameText, "82878b")
            elseif mapNum == roll then
                -- colorIndex = 1
                iconStr = "instance_icon_attack"
                -- mapStr = mapBgArr[2]
                -- mapColor = txtColorArr[2]
                -- self:SetSpine(eff, "map", "jian", 1)
                self:CreateWndEffect(eff, "jian", "MapItem" .. mapNum, 100, false, false, nil, nil, nil, nil, nil, nil, 10)
            else
                -- colorIndex = 2
                iconStr = "public_icon_yes_1"
                -- mapStr = mapBgArr[3]
                -- mapColor = txtColorArr[3]
            end
            self:SetWndEasyImage(iconMap, iconStr, nil, true)
            -- self:SetWndEasyImage(btn, mapStr)
            CS.ShowObject(eff, mapNum == roll)
            CS.ShowObject(iconMap, mapNum ~= roll)
            local _mapName = nil
            if gLGameLanguage:IsForeignRegion() then
                _mapName = ccLngText(mapRefData.name)
            else
                _mapName = string.replace(ccClientText(10614), mapRefData.num, ccLngText(mapRefData.name))
            end
            -- self:SetWndText(nameText, string.replace(mapColor, _mapName))
            self:SetWndText(nameText, _mapName)
        end
        self:SetWndClick(trans, function()
            self:OnClickMapBtn(i)
        end)
    end
end

function UIGolbMl:PlayChapterEffEnd()
    --章节开锁特效结束
    local battleNum = self._newChapterId
    local chapterRef = gModelInstance:GetInstanceChapterRefByRefId(battleNum)
    local storyId = chapterRef.storyId or 0
    if storyId > 0 then
        gModelPlot:StartPlotAndCallback(storyId, function(a, b)
            GF.OpenWndUp("UIMlTipsUI", { battleNum })
        end)
    else
        GF.OpenWndUp("UIMlTipsUI", { battleNum })
    end
end

--点击宝箱
function UIGolbMl:OnClickBox(id, state, item)
    local rewards = gModelInstance:GetProReward(id)
    local rewardList = gModelGeneral:GetParseItem(rewards)
    if (state == 2) then
        gModelInstance:OnInstanceRewardReq(id)
        return
    end
    GF.OpenWnd("UIBoxDel", { root = item, reward = rewardList, state = state })
end
function UIGolbMl:SetDiffLvlSeleBtn(index, btnTrans)
    self._curDiffLvl = index == 1 and self._curDiffLvl - 1 or self._curDiffLvl + 1
    local tmpLvl = self._curDiffLvl
    self:SetWndClick(btnTrans, function()
        local limitCnt = 1
        if (gModelInstance:CheckDiffLvlFuncIsOpen(2)) then
            if (gModelInstance:CheckDiffLvlFuncIsOpen(3)) then
                limitCnt = 3
            else
                limitCnt = 2
            end
        end
        if (index == 1) then
            tmpLvl = self._curDiffLvl - 1 <= 0 and limitCnt or self._curDiffLvl - 1
        else
            tmpLvl = self._curDiffLvl + 1 > limitCnt and 1 or self._curDiffLvl + 1
        end
        self._curDiffLvl = tmpLvl
        gModelInstance:SetMainFightLevelOfDifficulty(self._curDiffLvl)
        GF.OpenWndWait("UIMinFightOpenEffect", { diffLvl = self._curDiffLvl })
    end)
end

function UIGolbMl:InitMessage()
    self:WndNetMsgRecv(LProtoIds.InstanceRewardResp, function(...)
        self:OnRefreshList(...)
    end)
    self:WndNetMsgRecv(LProtoIds.InstanceSwitchResp, function(...)
        if (self._isNew) then
            self._isNew = false
        end
        self._mapEventList = {}
        self:InitCommand()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerInstanceResp, function(...)
        self._isNew = nil
        self:InitCommand(self._curDiffLvl)
    end)

    self:WndEventRecv(EventNames.MAINFIGHT_CHANGE_DIFF_LVL, function()
        self:OnChangeDiffLvl()
    end)
end
-----------------------------------------延迟------------------------------------------------
function UIGolbMl:OnTimer(key)
    if key == self._startChapterEff then
        self:PlayChapterEffStart()
    elseif key == self._endChapterEff then
        self:PlayChapterEffEnd()
    end
end

function UIGolbMl:ChangeMap(trans, bool, b, index)
    local btn = CS.FindTrans(trans, "MapBtn")
    local chapter = CS.FindTrans(trans, "ChapterParent")
    local pick = CS.FindTrans(trans, "Pick")
    local mask = CS.FindTrans(trans, "Mask")
    local worldMapRef = gModelInstance:GetWorldMapRef()
    local mapRefData = self:GetMapRefDataByNum(worldMapRef, index)

    CS.ShowObject(btn, not bool and mapRefData)
    CS.ShowObject(chapter, bool)
    CS.ShowObject(pick, bool)
    if (bool) then
        CS.ShowObject(mask, false)
    else
        CS.ShowObject(mask, not b)
    end
end

function UIGolbMl:ListItem(list, item, itemdata, itempos)
    --关卡点列表显示
    local wireTrans = CS.FindTrans(item, "WireImage")
    local wireRTrans = CS.FindTrans(item, "WireImageR")
    local standTrans = CS.FindTrans(item, "StandImage")
    local textTrans = CS.FindTrans(item, "XUIText")
    local selTrans = CS.FindTrans(item, "SelImage")
    local statusTrans = CS.FindTrans(item, "StatusImage")
    local heroSpine = CS.FindTrans(item, "HeroSpine")

    local bShowWire = false
    local bShowSpine = false
    local bShowAttack = false
    local bShowWireR = false
    local bShowStatus = true
    --local statusName = "instance_icon_1_2"
    local statusName = "instance_icon_4_off"

    local numStr, standStr, bBox, boxStr, state
    if (itemdata.refId <= self._currMission) then
        bShowWire = true
        bShowWireR = true
        --statusName = "instance_icon_1_1"
        statusName = "instance_icon_4"
    end

    numStr = itemdata.num

    if itemdata.refId == self._currMission then
        --显示展示英雄
        bShowSpine = true
        bShowWireR = false
        bShowAttack = true
        bShowStatus = false
    end

    CS.ShowObject(heroSpine, bShowSpine)
    CS.ShowObject(wireRTrans, bShowWireR)
    CS.ShowObject(wireTrans, bShowWire)
    CS.ShowObject(selTrans, bShowAttack)
    --CS.ShowObject(statusTrans, bShowStatus)

    self:SetWndText(textTrans, numStr)
    self:SetWndClick(standTrans, function()
        self:OnClickStand(itemdata.refId)
    end)

    --if bShowStatus then
    --	self:SetWndEasyImage(statusTrans, statusName)
    --end

    self:SetWndEasyImage(standTrans, statusName)

    if bShowSpine then
        local preName = gModelPlayer:GetCurPlayFigure(ModelPlayer.PLAY_IMAGE_HANG) or "Jianshi"
        self:CreateHeroSpine(heroSpine, preName, 1011, false)
    end
end

function UIGolbMl:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mReturnBtn, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mRankBtn, function(...)
        self:OnClickRank()
    end)
    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
    self:SetWndClick(self.mBtnTips, function(...)
        self:OnClickTips()
    end)
end

function UIGolbMl:CreateHeroSpine(HeroSpine, spineName, spineKey, bDefaultLayer)
    --创建展示英雄
    local modelSpine = self:FindWndSpineByKey(spineKey)
    if modelSpine then
        modelSpine = modelSpine:GetDisplayTrans()
        if modelSpine then
            local spine = modelSpine:GetComponent(typeOfSkeletonGraphic)
            spine.raycastTarget = false
            CS.SetParentTrans(modelSpine, HeroSpine)
            modelSpine.anchorMin = Vector2.New(0.5, 0.5)
            modelSpine.anchorMax = Vector2.New(0.5, 0.5)
            modelSpine.localPosition = Vector2.New(0, 0)
        end
    end
    if (not modelSpine) then
        self:CreateWndSpine(HeroSpine, spineName, spineKey, bDefaultLayer, function()
            local spine = self:FindWndSpineByKey(spineKey)
            if spine then
                spine:PlayAnimation(0, "run", true)
                local modelSpine = spine:GetDisplayTrans()
                if (modelSpine) then

                    local spine = modelSpine:GetComponent(typeOfSkeletonGraphic)
                    spine.raycastTarget = false
                    modelSpine.anchorMin = Vector2.New(0.5, 0.5)
                    modelSpine.anchorMax = Vector2.New(0.5, 0.5)
                    modelSpine.localPosition = Vector2.New(0, 0)
                end
            end
        end)
    end
end

function UIGolbMl:OnClickTips()
    GF.OpenWnd("UIBzTips", { refId = 84 })
end
function UIGolbMl:OnChangeDiffLvl()
    self:ChangeDiffLvlShow()
end

function UIGolbMl:SetCurrRollMapPoint(currRoll)
    --地块滑动到当前地图
    local ref = gModelInstance:GetWorldMapRefByRefId(currRoll)
    local move = ref.posY
    if (move < self._minY) then
        move = self._minY
    elseif (move > self._maxY) then
        move = self._maxY
    end
    self.mMapImage.localPosition = Vector2.New(self.mMapImage.localPosition.x, move)
end

function UIGolbMl:UIDragOnDrag(dragKey, eventData)
    if dragKey ~= "Map" then
        return
    end
    local trans = self.mMapImage
    local moveY = self._minY
    local pos = trans.localPosition
    if (pos.y <= self._minY) then
        moveY = self._minY
    elseif (pos.y >= self._maxY) then
        moveY = self._maxY
    else
        moveY = pos.y
    end
    trans.localPosition = Vector3.New(self._initX, moveY, pos.z)
end

function UIGolbMl:SetSpine(paintTans, key, name, scale)
    --设置Spine
    local spine = self:FindWndSpineByKey(key)
    if (spine) then
        self:DestroyWndSpineByKey(key)
    end
    self:CreateWndSpine(paintTans, name, key, false, function(dpSpine)
        dpSpine:SetScale(scale)
    end)
end
function UIGolbMl:SetMapBgImg()
    local cfg = gModelInstance:GetInstancePattern(self._curDiffLvl)
    if (not cfg or not cfg.map) then
        return
    end
    local mapArr = string.split(cfg.map, ",")
    for i = 1, #mapArr do
        local mapPath = mapArr[i]
        local mapImgTrans = self:FindWndTrans(self.mMapImage, "Image" .. i)
        self:SetWndEasyImage(mapImgTrans, mapPath)
    end
end
-----------------------------------------显示------------------------------------------------
function UIGolbMl:SetPlayChapterEff(chapterBtn, chapterEffBtn)
    --设置特效
    --self._iconChapter = CS.FindTrans(chapterBtn,"Image")
    -- self._effParent = CS.FindTrans(chapterBtn, "Eff")
    self._effParent2 = CS.FindTrans(chapterEffBtn, "Eff")
    CS.ShowObject(self._effParent, true)
    self:TimerStart(self._startChapterEff, 0.2, false, 1)
end

function UIGolbMl:InitChapterEvent(index)
    --初始化章节 点击事件
    if self._mapEventList[index] then
        return
    end
    self._mapEventList[index] = index
    local mapRef = gModelInstance:GetWorldMapRefByRefId(index, self._curDiffLvl)
    --local mapRef = gModelInstance:GetWorldMapRefByRefId(self._currChapter)
    -- local iconArr = string.split(gModelInstance:GetInstancePara("ChapterPic"), ";")
    -- local bgArr = string.split(gModelInstance:GetInstancePara("ChapterBgType"), ";")
    -- local txtColorArr = string.split(gModelInstance:GetInstancePara("txtColor"), ";")
    local trans = self._mapTransList[index]
    local parent = CS.FindTrans(trans, "ChapterParent")
    local effTrans = self._mapEffTransList[index]
    local effParent = CS.FindTrans(effTrans, "ChapterParent")
    local chapterArr = string.split(mapRef.ChapterId, ";")
    local _newChapterId = self._newChapterId
    local _currChapter = _newChapterId and _newChapterId or self._currChapter
    for j = 1, #chapterArr do
        local refKey = tonumber(chapterArr[j])
        local chapterRef = gModelInstance:GetInstanceChapterRefByRefId(refKey)
        --local chapterBtn = CS.FindTrans(parent,"ChapterItem"..refKey)
        local chapterBtn = CS.FindTrans(parent, "ChapterItem" .. chapterRef.chapteNum1)
        --local  chapterEffBtn = CS.FindTrans(effParent,"ChapterItem"..refKey)
        local chapterEffBtn = CS.FindTrans(effParent, "ChapterItem" .. chapterRef.chapteNum1)
        local textChapter = CS.FindTrans(chapterBtn, "NameText")
        local iconChapter = CS.FindTrans(chapterBtn, "Icon")
        local numBg = CS.FindTrans(chapterBtn, "NumBg")
        local numText = CS.FindTrans(numBg, "NumText")
        local mEffParent = CS.FindTrans(chapterBtn, "DuiZhan")
        local isNewBattle = _newChapterId and _newChapterId == refKey
        local isBattle = refKey == _currChapter
        CS.ShowObject(iconChapter, not isBattle and not isNewBattle)
        CS.ShowObject(mEffParent, isBattle or isNewBattle)
        CS.ShowObject(numBg, true)
        mEffParent.localPosition = Vector3.New(3.5, 3.5, 0)
        local numStr, iconStr, chapterStr, colorIndex
        local currMission = gModelInstance:GetFinallyMissionIndex(refKey)--关卡数
        if refKey < _currChapter then
            -- iconStr = iconArr[3]
            iconStr = "public_icon_yes_1"
            local go = gModelInstance:GetFinallyMissionIndex(refKey - 1)
            numStr = string.replace(ccClientText(10616), currMission - go, currMission - go)
            -- chapterStr = bgArr[3]
            -- colorIndex = txtColorArr[3]
        elseif isBattle or isNewBattle then
            -- iconStr = iconArr[2]
            iconStr = "instance_icon_attack"
            local go = gModelInstance:GetFinallyMissionIndex(refKey - 1)
            local at = gModelInstance:GetBattleNum(self._curDiffLvl)
            numStr = string.replace(ccClientText(10616), at - go, currMission - go)
            -- chapterStr = bgArr[2]
            -- colorIndex = txtColorArr[2]
            -- self:SetSpine(mEffParent, "chapter" .. refKey, "jian", 1)
            self:CreateWndEffect(mEffParent, "jian", "chapter" .. refKey, 100, false, false, nil, nil, nil, nil, nil, nil, 10)
        else
            -- iconStr = iconArr[1]
            iconStr = "public_lock_7"
            numStr = ""
            -- chapterStr = bgArr[1]
            CS.ShowObject(numBg, false)
            -- colorIndex = txtColorArr[1]
        end
        --self:SetWndText(numText, string.replace(colorIndex, numStr))
        self:SetWndText(numText, numStr)
        local chapterName = nil
        if gLGameLanguage:IsForeignRegion() then
            chapterName = ccLngText(chapterRef.name)
        else
            local cfg = gModelInstance:GetInstanceChapterRefByRefId(refKey)
            chapterName = string.replace(ccClientText(10615), cfg.chapteNum1, ccLngText(chapterRef.name))
            chapterName = string.replace(ccClientText(10615), cfg.chapteNum1, ccLngText(chapterRef.name))
        end
        --self:SetWndText(textChapter,string.replace(colorIndex,chapterRef.chapteNum1))
        -- self:SetWndText(textChapter, string.replace(colorIndex, chapterName))
        self:SetWndText(textChapter, chapterName)
        self:InitTextSizeWithLanguage(textChapter, -2)
        self:SetWndEasyImage(iconChapter, iconStr, nil, true)
        --local img = CS.FindTrans(chapterBtn,"Image")
        -- self:SetWndEasyImage(chapterBtn, chapterStr)
        self:SetWndClick(chapterBtn, function()
            self:OnClickChapterBtn(refKey)
        end)
        if (isNewBattle) then
            --新章节 需要播放特效
            self:SetPlayChapterEff(chapterBtn, chapterEffBtn)
        end
    end
end

function UIGolbMl:OnClickRank()
    --点击排行榜
    GF.OpenWndBottom("UIRkPop", {
        type = 1,
        refId = gModelRank:GetInstanceRankRefId(),
        func = function()
            GF.OpenWnd("UIGolbMl")
        end
    })
    self:WndClose()
end

function UIGolbMl:InitDrag()
    --拖动
    self:UIDragSetItem("Map", "Viewport/MapImage", CS.YXUIDrag.DragMode.DragOrigin)
end
function UIGolbMl:SetTitleBg()
    local titleBgTrans = self.mTitleBg
    local diffLvlSeleBtnGroup = self:FindWndTrans(titleBgTrans, "DiffLvlSeleBtnGroup")
    local isFuncOpen = gModelInstance:CheckDiffLvlFuncIsOpen(2)
    if (isFuncOpen) then
        local patternCfg = gModelInstance:GetInstancePattern(self._curDiffLvl)
        self:SetWndEasyImage(titleBgTrans, patternCfg.nameIcon)
        for i = 1, 2 do
            local btnTrans = diffLvlSeleBtnGroup:GetChild(i - 1)
            self:SetDiffLvlSeleBtn(i, btnTrans)
        end
        self:SetWndText(self.mBotDiffLvlTxt, ccLngText(patternCfg.name))
    end
    CS.ShowObject(diffLvlSeleBtnGroup, isFuncOpen)
end

function UIGolbMl:InitRank()
    --初始化超越百分比
    local rank = gModelInstance:GetRank()
    local rankStr = ""
    if not rank or rank == -1 then
        rankStr = ccClientText(10603)
    else
        local str = string.format("%.1f", rank * 100) .. "%"
        rankStr = string.replace(ccClientText(10602), str)
    end
    self:SetWndText(self.mRankText, rankStr)
end
-----------------------------------------拖动------------------------------------------------
function UIGolbMl:InitDragData()
    local _MapImage = self.mMapImage
    local mapHeight = _MapImage.rect.height
    local viewHeight = self.mViewport.rect.height
    local minY = -(mapHeight - viewHeight) * 0.5
    self._initX = _MapImage.localPosition.x
    self._minY = minY
    self._maxY = self._minY + (mapHeight - viewHeight)
    self:InitDrag()
end
-----------------------------------------点击------------------------------------------------
function UIGolbMl:OnClickMapBtn(index)
    --点击地图块
    local mapRef = gModelInstance:GetMapRefByMapIndexAndDiffLvl(index, self._curDiffLvl)
    if (not mapRef) then
        GF.ShowMessage(ccClientText(16345))
        return
    end

    if (self._mapIndex > 0) then
        local trans = self._mapTransList[self._mapIndex]
        local trEff = self._mapEffTransList[self._mapIndex]
        CS.ShowObject(trEff, false)
        self:ChangeMap(trans, false, self._mapIndex <= self._currRoll, self._mapIndex)
    end
    local trans = self._mapTransList[index]
    self:ChangeMap(trans, true, index <= self._currRoll, self._mapIndex)
    local trEff = self._mapEffTransList[index]
    CS.ShowObject(trEff, true)
    self:InitChapterEvent(index)
    self._mapIndex = index
end
function UIGolbMl:GetMapRefDataByNum(worldMapRef, num)
    for i, v in pairs(worldMapRef) do
        if (v.type == self._curDiffLvl and v.num == num) then
            return v
        end
    end
end

function UIGolbMl:InitCommand(curDiffLvl)
    if (curDiffLvl) then
        self._curDiffLvl = curDiffLvl
    else
        self._curDiffLvl = self:GetWndArg(2) or 1 --地图难度等级
    end
    self._currRoll = gModelInstance:GetCurrRoll(self._curDiffLvl)
    self._currChapter = gModelInstance:GetChapterId(self._curDiffLvl)--章节
    self._currMission = gModelInstance:GetBattleNode(self._curDiffLvl)--关卡
    if (not self._isNew and self._isNew ~= false) then
        self._isNew = self:GetWndArg(1)--是否切换章节进入
    end
    if (self._isNew) then
        local _newChapterId = gModelInstance:GetNextChapterId(self._curDiffLvl)
        if (_newChapterId ~= -1) then
            self._newChapterId = _newChapterId
            local NewMapRoll = gModelInstance:IsMapOneChapterId(self._curDiffLvl)
            if NewMapRoll ~= 0 then
                self._currRoll = NewMapRoll
            end
        end
    end
    local mapRef = gModelInstance:GetWorldMapRefByRefId(self._currRoll, self._curDiffLvl)
    --local strRoll=string.replace(ccClientText(10604),mapRef.num)
    --local strChapter=string.replace(ccClientText(10605),self._currChapter)
    local strMission = ""
    if (gModelInstance:GetMissionCfg(self._currMission)) then
        --strMission=string.replace(ccClientText(10617),strRoll,strChapter)
        local cfg = gModelInstance:GetInstanceChapterRefByRefId(self._currChapter)
        strMission = string.replace(ccClientText(10618), mapRef.num, cfg.chapteNum1)
    else
        strMission = ccClientText(10611)
    end
    self:SetWndText(self.mSectionText, strMission)
    self:SetWndText(self.mRankBtnText, ccClientText(10612))
    self:SetWndText(self.mTitleText, ccClientText(10600))
    self:InitRank()
    self:OnRefreshList()
    self:InitMapList(self._currRoll)
    self:OnClickMapBtn(self._currRoll)
    --if(not self._isNew or self._isNew==false)then
    self:SetCurrRollMapPoint(self._currRoll)
    --end
    self:SetTitleBg()
    self:SetMapBgImg()
end

function UIGolbMl:PlayChapterEffStart()
    --章节开锁特效开始
    --CS.ShowObject(self._iconChapter,false)
    -- self:CreateWndEffect(self._effParent, "fx_zhangjie_jiesuo02", "fx_zhangjie_jiesuo02", 100, false, false, 20)
    self:CreateWndEffect(self._effParent2, "fx_zhangjie_jiesuo", "fx_zhangjie_jiesuo", 100, false, false, nil, nil, nil, nil, nil, nil, 10)

    gModelInstance:OnInstanceSwitchReq(self._curDiffLvl)
    self:TimerStart(self._endChapterEff, 3, false, 1)
end

function UIGolbMl:OnClickChapterBtn(index)
    --点击章节
    GF.OpenWndUp("UIMlTipsUI", { index })
end

function UIGolbMl:OnClickStand(id)
    --点击关卡
    GF.OpenWndUp("UIMlAward", { id })
end

function UIGolbMl:ChangeDiffLvlShow()
    local patternCfg = gModelInstance:GetInstancePattern(self._curDiffLvl)
    local titleBgTrans = self.mTitleBg
    self._mapEventList = {}
    self:SetWndEasyImage(titleBgTrans, patternCfg.nameIcon)
    gModelInstance:SetMainFightLevelOfDifficulty(self._curDiffLvl)
    --gModelInstance:ChangeMapState(true)
    --gModelInstance:OnInstanceExtraContentReq()
    --gModelInstance:OnPlayerInstanceReq()
end

function UIGolbMl:OnRefreshList()
    --刷新关卡点列表
    local chapterId = gModelInstance:GetChapterId()
    local refList = gModelInstance:GetChapterIdMission(chapterId)
    local list = {}
    for i, v in pairs(refList) do
        table.insert(list, v)
    end
    table.sort(list, function(a, b)
        return a.num < b.num
    end)
    local refreshCustom = 0
    if (self._currChapter == chapterId) then
        --获取当前位置的点
        for i, v in ipairs(list) do
            if (self._currMission == v.refId) then
                refreshCustom = i - 1
            end
        end
    else
        refreshCustom = #list
    end

    if (self._uiList) then
        self._uiList:RefreshList(list, true)
    else
        self._uiList = self:GetUIScroll("_uiList")
        self._uiList:Create(self.mSectionList, list, function(...)
            self:ListItem(...)
        end, UIItemList.WRAP, false)
    end
    local _uiList = self._uiList:GetList()
    _uiList:RefreshList(UIListWrap.RefreshMode.Custom, refreshCustom)
end
------------------------------------------------------------------
return UIGolbMl