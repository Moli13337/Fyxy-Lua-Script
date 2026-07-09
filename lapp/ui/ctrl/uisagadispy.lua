---
--- Created by Administrator.
--- DateTime: 2023/10/8 11:21:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaDisPy:LWnd
local UISagaDisPy = LxWndClass("UISagaDisPy", LWnd)
local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeSpineClick = typeof(CS.SpineClick)

local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaDisPy:UISagaDisPy()
    ---@type LUIHeroObject
    self._curUILiHuiObj = nil            -- 当前立绘
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaDisPy:OnWndClose()

    local haveHero = gModelHeroBook:GetHeroIsActByRefId(self._heroRefId)
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "伙伴形象close", self._heroRefId, haveHero)

    if self._curUILiHuiObj then
        self._curUILiHuiObj:Destroy()
        self._curUILiHuiObj = nil
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaDisPy:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaDisPy:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitSlider()
    self:InitText()
    self:InitEvent()
    self:InitData()
    self:SetView()
    self:RefreshView()
    self:RefreshSlider()
    self:InitImgList()
    self:RefreshPersonText()
    
    self:RefreshForeign()
end

function UISagaDisPy:RefreshInDoorDiv()
    self:SetWndText(self.mDoorBtnTxt, ccClientText(19726))
    self:InitTextLineWithLanguage(self.mDoorBtnTxt, -50)

    local refId = self._heroRefId
    local heroRef = gModelHero:GetHeroRef(refId)
    if heroRef then
        local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
        if qualityRef then
        end
    end
end

function UISagaDisPy:TabListItem(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "Icon")
    if IconTrans then
        self:SetWndEasyImage(IconTrans, itemdata.heroBookScreenBg)
    end
    local SelTrans = self:FindWndTrans(item, "Sel")
    if SelTrans then
        local index = itemdata.index
        self._selTransList[index] = SelTrans
        CS.ShowObject(SelTrans, index == self._imgIndex)
    end
end

function UISagaDisPy:OnItemCenter(item, itemdata, itempos)
    self:Refresh(itemdata)
end

function UISagaDisPy:ChangeWndSpineScale(value)
    local spine
    local showOutDoor = self._showOutDoor
    if showOutDoor then
        local showSP = self._outDoorShowSP
        if showSP then
            spine = self._outDoorHeroSP
        else
            spine = self._outDoorHeroLH
        end
    else
        spine = self._inDoorHeroSP
    end
    if spine then
        spine:SetScale(value)
    end
end

function UISagaDisPy:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mPersonBtn, function()
        self:ShowOutDoorSpine(true)
    end)
    self:SetWndClick(self.mDoorBtn, function()
        self:ChangeView()
    end)
    self:SetWndClick(self.mShotBtn, function()
        self:ShotEvent()
    end)
    self:SetWndClick(self.mSubBtn, function()
        self:ChangeBtnEvent(false)
    end)
    self:SetWndClick(self.mAddBtn, function()
        self:ChangeBtnEvent(true)
    end)
    self:SetWndClick(self.mLiHuiClick, function()
        GF.OpenWndUp("UISagaLiHuiSow", { selSkinRefId = self._heroRefId })
    end)

    self:SetWndClick(self.mUnfold_Btn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mPhotograph_Btn, function()
        self:ShotEvent()
    end)
end

function UISagaDisPy:InitImgList()
    --CS.ShowObject(self.mImgList,true)
    --self._selTransList = {}
    --local uiList = self:GetUIScroll("imgList")
    --uiList:InitListData({
    --	root = self.mImgList,
    --	dataList = self._imgList,
    --	setFunc = function (...) self:TabListItem(...) end,
    --	type = UIItemList.CIRCLE,
    --	onCenterFunc = function (...) self:OnItemCenter(...) end,
    --	centerPos = self._imgIndex
    --})
end

function UISagaDisPy:SetOutDoorDiv()
    self._isCanMove = false
    local effRef
    if self._sid then
        effRef = gModelHero:GetHeroEffectRefById(self._sid)
    else
        local refId = self._heroRefId
        if not refId then return end

        effRef = gModelHero:GetHeroShowRefByRefId(refId)
    end
    if not effRef then return end

    local heroDrawing, prefabName = effRef.heroDrawing, effRef.prefabName

--[[    self._outDoorHeroLH = self:CreateWndSpine(self.mOutDoorHeroLHPos, heroDrawing, "mOutDoorHeroLHPos", false, function(spine)
        spine:SetScale(self._heroScaleRangeDefault)
        spine:MatchRectTransform()
        self:OnSpineLoaded(spine)
    end)]]


    ---@type LUIHeroObject
    local curUILiHuiObj = LUIHeroObject:New(self)
    self._curUILiHuiObj = curUILiHuiObj
    curUILiHuiObj:Create(self.mOutDoorHeroLHPos,heroDrawing,heroDrawing)
    curUILiHuiObj:SetHeroBgParams({
        effRef = effRef,
        lihuiBgTrans = self.mOutDoorHeroLHBgPos,
        lihuiHdTrans = self.mOutDoorHeroLHHdPos,
    })
    curUILiHuiObj:SetRectMatch(true)
    curUILiHuiObj:ShowHero(true)

    if curUILiHuiObj:GetShowBgSpineState() then
        --- 带背景：缩放最小1倍，进入界面默认1倍
        self._heroScaleRange.min = 1
    else
        self._isCanMove = true
    end

    ---@param uiLiHuiObj LUIHeroObject
    curUILiHuiObj:SetLoadedFunction(function(uiLiHuiObj)
        if not self._isCanMove then return end
        local spine = uiLiHuiObj:GetDisplaySpine()
        self:OnSpineLoaded(spine,true)
    end)
    curUILiHuiObj:SetBgSpineLoadCb(function()
        local spine = curUILiHuiObj:GetDisplaySpine()
        self:OnSpineLoaded(spine,true)
    end)
    curUILiHuiObj:SetScale(self._heroScaleRangeDefault)
    curUILiHuiObj:StartLoad()



    self._outDoorHeroSP = self:CreateWndSpine(self.mOutDoorHeroSPPos, prefabName, "mOutDoorHeroSPPos", false, function(spine)
        --spine:SetScale(self._heroFightScaleRangeDefault / 100)
        --spine:MatchRectTransform()
        --self:OnSpineLoaded(spine)
    end)
end

function UISagaDisPy:ChangeImg(index)
    for k, v in pairs(self._selTransList) do
        CS.ShowObject(v, k == index)
    end
end

function UISagaDisPy:RefreshSlider()
    local defaultSize, rangeList
    local showOutDoor = self._showOutDoor
    if showOutDoor then
        local showSP = self._outDoorShowSP
        if showSP then
            defaultSize = self._heroFightScaleRangeDefault
            rangeList = self._heroFightScaleRange
        else
            defaultSize = self._heroScaleRangeDefault
            rangeList = self._heroScaleRange
        end
    else
        defaultSize = self._heroFightScaleRangeDefault
        rangeList = self._heroFightScaleRange
    end
    if rangeList then
        local min, max = rangeList.min, rangeList.max
        self._sliderComponent.minValue = min
        self._sliderComponent.maxValue = max
    end
    if defaultSize then
        self._sliderComponent.value = defaultSize
        self:ChangeHeroSpineSize(defaultSize)
    end
end

function UISagaDisPy:ShotEvent()
    local list = {}
    local image, position
    local showOutDoor = self._showOutDoor
    if showOutDoor then
        local showSP = self._outDoorShowSP
        if showSP then
            list = { self.mBg, self.mOutDoorHeroLHBgPos,self.mOutDoorHeroSPPos,self.mOutDoorHeroLHHdPos }
            image = ModelHeroBook.HERO_CAPTURE_PERSON
        else
            list = { self.mBg,self.mOutDoorHeroLHBgPos, self.mOutDoorHeroLHPos,self.mOutDoorHeroLHHdPos }
            image = ModelHeroBook.HERO_CAPTURE_LIHUI
        end
        position = ModelHeroBook.HERO_CAPTURE_OUTDOOR
    else
        list = { self.mBg, self.mInDoorLHPos, self.mInDoorImg, self.mInDoorSPPos }
        image = ModelHeroBook.HERO_CAPTURE_PERSON
        position = ModelHeroBook.HERO_CAPTURE_INDOOR
    end
    local heroRefId = self._heroRefId
    local race = gModelHero:GetHeroRace(heroRefId)
    local value = self._sliderComponent.value
    value = tonumber(value)
    value = math.floor(value + 0.5)
    gModelHeroBook:OnHeroForCaptureReq(image, position, race, heroRefId, value)
    gLGameUI:CaptureUIScreen(self:GetWndTrans(), list)
end

function UISagaDisPy:Refresh(itemdata)
    local heroBg = itemdata.heroBg

    local index = itemdata.index
    self._imgIndex = index

    self:ChangeImg(index)

    self:SetWndEasyImage(self.mBg, heroBg)

    --self:StarShowTimer()
end

function UISagaDisPy:InitSlider()
    self._sliderComponent = self.mSlider:GetComponent(typeUISlider)
    if (not self._sliderComponent) then
        self._sliderComponent = self.mSlider:AddComponent(typeUISlider)
    end
    LxUiHelper.SetProgress_ValueChanged(self.mSlider, function()
        local value = self._sliderComponent.value
        self:ChangeHeroSpineSize(value)
    end)
end

function UISagaDisPy:InitData()
    local showOutDoor = self:GetWndArg("showOutDoor")
    self._showOutDoor = showOutDoor or true                -- 是否是室外，默认是室外

    self._heroRefId = self:GetWndArg("heroRefId")
    self._sid = self:GetWndArg("sid")
    local effRef = gModelHero:GetHeroShowRefByRefId(self._heroRefId)
    if not effRef then
        return
    end

    --self._outDoorShowSP = true

    self._outDoorShowSP = false
    -- 立绘缩放范围
    local heroScaleRange = gModelHero:GeConfigByKey("heroScaleRange")
    heroScaleRange = string.split(heroScaleRange, ",")
    local heroScaleMin, heroScaleMax = tonumber(heroScaleRange[1]) / 100, tonumber(heroScaleRange[2]) / 100
    self._heroScaleRange = {
        min = heroScaleMin,
        max = heroScaleMax,
    }

    -- 立绘默认比例
    --self._heroScaleRangeDefault = effRef.pos1Scale
    self._heroScaleRangeDefault = 1

    -- 战斗小人缩放范围
    --local heroFightScaleRange = gModelHero:GeConfigByKey("heroFightScaleRange")
    local heroFightScaleRange = "1,1"
    heroFightScaleRange = string.split(heroFightScaleRange, ",")
    local heroFightMin, heroFightMax = tonumber(heroFightScaleRange[1]) / 100, tonumber(heroFightScaleRange[2]) / 100
    self._heroFightScaleRange = {
        min = heroFightMin,
        max = heroFightMax,
    }

    -- 战斗小人默认比例
    local heroFightScaleRangeDefault = gModelHero:GeConfigByKey("heroFightScaleRangeDefault")
    self._heroFightScaleRangeDefault = heroFightScaleRangeDefault

    local oneOptBtnNum = gModelHero:GeConfigByKey("oneOptBtnNum")
    if oneOptBtnNum == nil then
        oneOptBtnNum = 0.1
    end
    self._oneOptBtnNum = oneOptBtnNum

    local img = ""
    local raceType = gModelHero:GetHeroType(self._heroRefId)
    self._imgList = {}
    local imgList = {}
    for k, v in pairs(GameTable.CharacterRaceRef) do
        local refId, heroBg, heroBookScreenBg = v.refId, v.heroBg, v.heroBookScreenBg
        if refId == raceType then
            img = heroBg
        end
        table.insert(imgList, { refId = refId, heroBg = heroBg, heroBookScreenBg = heroBookScreenBg })
    end
    table.sort(imgList, function(t1, t2)
        return t1.refId < t2.refId
    end)
    for i, v in ipairs(imgList) do
        local heroBg = v.heroBg
        local heroBookScreenBg = v.heroBookScreenBg
        if heroBg == img then
            self._imgIndex = i
        end
        table.insert(self._imgList, { heroBg = heroBg, index = i, heroBookScreenBg = heroBookScreenBg })
    end

    if self._sid then
        local effRef = gModelHero:GetHeroEffectRefById(self._sid)
        if effRef then
            img = effRef.skinBg
            if string.isempty(effRef.skinBg) then
                img = effRef.heroBg
            end
        end
    end

    self:SetWndEasyImage(self.mBg, img)
end

function UISagaDisPy:RefreshView()
    local showOutDoor = self._showOutDoor
    CS.ShowObject(self.mPersonBtn, showOutDoor)
    CS.ShowObject(self.mInDoorDiv, not showOutDoor)
    CS.ShowObject(self.mOutDoorDiv, showOutDoor)
    if showOutDoor then
        self:RefreshOutDoorDiv()
    else
        self:RefreshInDoorDiv()
    end
end

function UISagaDisPy:ChangeBtnEvent(isAdd)
    local oneOptBtnNum = self._oneOptBtnNum
    local optNum = isAdd and oneOptBtnNum or -oneOptBtnNum
    local curValue = self._sliderComponent.value
    local newValue = curValue + optNum
    if newValue < self._sliderComponent.minValue then
        newValue = self._sliderComponent.minValue
    elseif newValue > self._sliderComponent.maxValue then
        newValue = self._sliderComponent.maxValue
    end
    print("oneOptBtnNum = " .. oneOptBtnNum)
    print("newValue = " .. newValue)
    print("curValue = " .. curValue)
    self._sliderComponent.value = newValue
    self:ChangeHeroSpineSize(newValue)
end

function UISagaDisPy:ChangeHeroSpineSize(value)
    if self._curUILiHuiObj then
        self._curUILiHuiObj:SetObjScale(value)
    else
        self:ChangeWndSpineScale()
    end
end

function UISagaDisPy:InitText()
    self:SetWndText(self.mShotBtnTxt, ccClientText(19727))
    self:InitTextLineWithLanguage(self.mShotBtnTxt, -50)

    self:SetWndText(self.mPhotograph_Txt, ccClientText(20179))
    self:SetWndText(self.mUnfold_Txt, ccClientText(20180))
end

function UISagaDisPy:ShowOutDoorSpine(change)
    local showOutDoor = self._showOutDoor
    if not showOutDoor then
        return
    end
    if change ~= nil then
        self._outDoorShowSP = not self._outDoorShowSP
    end
    self:RefreshPersonText()
    local showSP = self._outDoorShowSP
    CS.ShowObject(self.mOutDoorHeroSPPos, showSP)
    CS.ShowObject(self.mOutDoorHeroLHPos, not showSP)
    --CS.ShowObject(self.mOutDoorHeroLHPos,true)
    self:RefreshSlider()
end

function UISagaDisPy:SetInDoorDiv()
    local refId = self._heroRefId
    if not refId then
        return
    end
    local effRef = gModelHero:GetHeroShowRefByRefId(refId)
    if not effRef then
        return
    end

    local heroDrawing, prefabName = effRef.heroDrawing, effRef.prefabName
    self._inDoorHeroLH = self:CreateWndSpine(self.mInDoorLHPos, heroDrawing, "mInDoorLHPos", false, function(spine)
        spine:SetScale(self._heroScaleRangeDefault)
        spine:MatchRectTransform()
        self:OnSpineLoaded(spine)
    end)
    self._inDoorHeroSP = self:CreateWndSpine(self.mInDoorSPPos, prefabName, "mInDoorSPPos", false, function(spine)
        --spine:SetScale(self._heroFightScaleRangeDefault/100)
        --spine:MatchRectTransform()
        --self:OnSpineLoaded(spine)
    end)
end

function UISagaDisPy:RefreshPersonText()
    local showSP = self._outDoorShowSP
    local textId = showSP and 19752 or 19724
    self:SetWndText(self.mPersonBtnTxt, ccClientText(textId))
    self:InitTextLineWithLanguage(self.mPersonBtnTxt, -50)
end

function UISagaDisPy:RefreshForeign()
    if CS.IsWebGL() and gLGameLanguage:IsJapanRegion() then
        CS.ShowObject(self.mPhotograph_Btn,false)
    end
end

function UISagaDisPy:SetView()
    local refId = self._heroRefId
    if not refId then
        return
    end
    local effRef = gModelHero:GetHeroShowRefByRefId(refId)
    if not effRef then
        return
    end

    local x, y = gModelHeroBook:GetHeroPosByRefIdAndType(effRef.refId, "heroDrawingPos1")
    if x and y then
        self.mInDoorLHPos.anchoredPosition = Vector3.New(x, y, 0)
        self.mInDoorLHEffPos.anchoredPosition = Vector3.New(x, y, 0)
        self.mOutDoorHeroLHPos.anchoredPosition = Vector3.New(x, y, 0)
    end

    self:SetInDoorDiv()
    self:SetOutDoorDiv()
end

function UISagaDisPy:RefreshOutDoorDiv()
    self:SetWndText(self.mDoorBtnTxt, ccClientText(19725))
    self:InitTextLineWithLanguage(self.mDoorBtnTxt, -50)
    self:ShowOutDoorSpine()
end

function UISagaDisPy:ChangeView()
    self._showOutDoor = not self._showOutDoor
    self:RefreshView()
    self:RefreshSlider()
end

function UISagaDisPy:OnSpineLoaded(spine,isOutDoor)
    ---# http://192.168.16.254:3002/issues/630
    --- 由于spine背景要跟着小人一起，所以需优化为：
    --- 1. 缩放最小1倍，进入界面默认1倍
    --- 2. 缩放跟着背景一起缩放
    --- 3. 去掉拖动设定
    local ignoreMove = true
    if ignoreMove then return end
    local spineTrans = spine:GetSpineTrans()
    local spineClick = spineTrans:GetComponent(typeSpineClick)
    if not spineClick then
        spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
        spineClick.isUISpine = true
    end
    local onDragFunc

    local curUILiHuiObj = self._curUILiHuiObj
    if isOutDoor and curUILiHuiObj and curUILiHuiObj:GetShowBgSpineState() then
        --- 带背景的需要进行判断范围
        onDragFunc = function(eventData)
            if not self._isCanMove then return end
            local camera = eventData.pressEventCamera
            local deltaPos = camera:ScreenToWorldPoint(eventData.position) - camera:ScreenToWorldPoint(eventData.position - eventData.delta)

            curUILiHuiObj:SetObjPos(deltaPos)
        end
    end
    if not onDragFunc then
        onDragFunc = function(eventData)
            if not self._isCanMove then return end
            local camera = eventData.pressEventCamera
            local deltaPos = camera:ScreenToWorldPoint(eventData.position) - camera:ScreenToWorldPoint(eventData.position - eventData.delta)
            spineTrans.position = spineTrans.position + deltaPos
        end
    end
    spineClick.onDrag = onDragFunc
end
------------------------------------------------------------------
return UISagaDisPy


