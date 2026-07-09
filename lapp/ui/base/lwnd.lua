---
--- Created by Admin.
--- DateTime: 2023/10/10 10:12
---
------------------------------------------------------------------
local UnityEngine = UnityEngine
local Vector3 = Vector3
local typeof = typeof
local CS = CS
local Tweening = DG.Tweening
local EaseOutQuad = Tweening.Ease.OutQuad
local typeofCanvas = typeof(UnityEngine.Canvas)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeofGridLayoutGroup = typeof(CS.GridLayoutGroup)
local typeUIImage = typeof(UnityEngine.UI.Image)
local typeofUISorting = typeof(CS.YXUISorting)
local typeofGraphicRaycaster = typeof(UnityEngine.UI.GraphicRaycaster)
local typeClickScale = typeof(CS.YXUIClickScale)
local typeofRawImage = typeof(UnityEngine.UI.RawImage)
local typeRectTransform = typeof(UnityEngine.RectTransform)
local typeTransform = typeof(UnityEngine.Transform)
local LayerMask = LayerMask
local LGameUI = LGameUI
local XUIDragMode = CS.YXUIDrag.DragMode
local typeXUIDrag = typeof(CS.YXUIDrag)
local UIProgress = UIProgress
local typeUITextInput = typeof(CS.YXUITextInput)
local typeUIToggle = typeof(UnityEngine.UI.Toggle)
local typeUIText = typeof(CS.YXUIText)
local typeofYXTextureImage = typeof(CS.YXTextureImage)
local typeUISlider = typeof(UnityEngine.UI.Slider)
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)
local TextAnchor = UnityEngine.TextAnchor
local LxBehaviour = LxRequire("LApp.component.LxBehaviour")
local typeofGameObject = typeof(UnityEngine.GameObject)
local typeOfCPrefab = typeof(PJX.CPrefabVar)
local typeofYXUIStateActor = typeof(CS.YXUIStateActor)
local typeOfSpriteRenderer = typeof(UnityEngine.SpriteRenderer)


---@type LxUiHelper
local LxUiHelper = LxUiHelper
------------------------------------------------------------------
---@class LWnd
local LWnd = LxClass("LWnd", nil)
------------------------------------------------------------------
LXImport('.LWnd_Display')
LXImport('.LWnd_Tween')
LXImport('.LWnd_Child')
LXImport('.LWnd_RedPoint')
LXImport('.LWnd_Animation')
LXImport('.LWnd_ThemeShow')
------------------------------------------------------------------
LWnd.WND_MODE_NONE = 0x00000000 --- normal
LWnd.WND_MODE_UNIQUE = 0x00000001 --- unique wnd
------------------------------------------------------------------
LWnd.StartMoveLeft = 1
LWnd.StartMoveTop = 2
LWnd.StartMoveRight = 3
LWnd.StartMoveBottom = 4

------------------------------------------------------------------
----按钮，标签 的状态类型
LWnd.StateGray = -1
LWnd.StateOn = 0
LWnd.StateOff = 1
LWnd.StateLock = 2

------------------------------------------------------------------
LWnd.SWITCH_TYPE_CHANGE_BTN = 1 --切换底下栏关闭界面
------------------------------------------------------------------

------------------------------------------------------------------
LWnd.WND_LAYER = LayerMask.NameToLayer(LGameUI.UI_LAYER_UI)
LWnd.WND_LAYER_EXTEND = LayerMask.NameToLayer(LGameUI.UI_LAYER_UI_EXTEND)
------------------------------------------------------------------

LWnd.MASK_INPUT_STATUS = 1 --0 关闭 1 开启输入
---
--是否开启input组件的玩家可输入， 0 为关闭， 1为开启
LWnd.MASK_INPUT_STATUS = 1

function LWnd:LWnd()

    self._wndName = nil          -- classname
    self._wndKey = nil           -- table size + 1
    self._wndPrefabName = nil    -- prefab name
    self._wndTrans = nil         -- transform
    self._wndCanvas = nil        -- csCanvas of wnd prefab
    self._wndGraphicRaycaster = nil -- csGraphicRaycaster of wnd prefab
    self._wndCanvasGroup = nil   -- csCanvasGroup of wnd prefab
    self._wndParent = nil        -- parent wndclass
    self._wndArgList = nil       -- open wnd arg list
    self._wndMode = 0            -- modes on bit
    self._wndAsync = false       -- load prefab async

    self._isFrozenUIScroll = false

    self._wndTimer = nil                  -- wnd timer
    self._wndCloseCnt = 0                 -- wnd close count
    self._wndSortLayer = 0                -- wnd sortlayer
    self._wndSortOrder = 0                -- wnd sortorder
    self._wndStarted = false              -- wnd on XStart
    self._wndVisible = true               -- wnd visible
    self._wndUIScene = nil                -- wnd UIScene list
    self._wndUISceneKey = nil             -- wnd uiScene key self increasing
    self._wndEffectList = nil             -- wnd effect play once
    self._wndTweenSeqList = nil           -- wnd tween sequence list | k = any, v = Tweening.DOTween.Sequence
    self._wndTweenStartMove = nil         -- wnd tween sequence list | k = i, v = Tweening.DOTween.Sequence
    self._wndUIProgressList = nil         -- wnd UIProgress list | k = path, v = UIProgress
    self._wndAutoAdjustNotch = nil        -- 刘海屏
    self._wndSpriteAtlasList = {}         -- 窗口内加载的图集列表
    self._wndSwitchType = 0               --窗口切换类型
    self._wndRemoveChildBundleDepend = false -- 是否移除子窗口依赖
    self._wndAniSeqMap = {}               --窗口动画集合
    self._wndAniTransScaleMap = {}        --窗口动画集合缩放
    self._wndAniTransPosMap = {}          --窗口动画集合坐标

    self._hasAni = false
    self._wndAniCallbackList = {}

    self._isDestroy = false
    self._history = {}    -- 历史记录列表

    self._isHurdleHide = nil --是否显示侧边栏
    self._isTopHide = nil
    self._isBottomHide = nil
    self._isActScrollHide = nil
    self._isShowGrade = true

    self._isAutoLangFont = true     -- 是否自动根据语言更换字体

    self._textFontSizeMap = {}      -- 保存多语言字体原始大小
    self._textLineSpacingMap = {}   -- 保存多语言字体原始行距大小
    self._textCharacterSpacingMap = {} -- 保存多语言字体原始间距大小

    ---@type LxBehaviour
    self._behaviour = LxBehaviour:New()

    self._isBackOpen = false
    self._isVisibleAllText = true --显示所有text文本
    self._isVisibleAllRed = true --显示所有红点

    ---@type LxResRequester
    self._resRequester = nil

    ---@type table<number,LxSprite>
    self._ui_images = {}
    ---@type table<number,LxStateActor>
    self._ui_state_actors = {}
    ---@type table<number, LxFontText>
    self._ui_fonts = {}
    ---@type table<table, number>
    self._base_instanceIDMap = {}
end

------------------------------------------------------------------
--- wnd close
------------------------------------------------------------------
function LWnd:ForceShutdown()
    self._bForceShutDown = true
    self:WndClose()
end

function LWnd:WndCloseAndBack()
    local wndName = self:GetWndName()
    local isBackWnd = gLGameUI:OpenBackWnd(wndName)

    self:WndClose()

    return isBackWnd
end

function LWnd:WndClose()
    local wndName = self:GetWndName()
    local wndCloseCnt = self._wndCloseCnt
    if (wndCloseCnt and wndCloseCnt > 0) then
        printInfoN(self:GetClassName(), "already destory! please don't call it twice")
        return
    end
    self._wndCloseCnt = wndCloseCnt + 1

    if(self._resRequester ~= nil) then
        self._resRequester:Dispose()
        self._resRequester = nil
    end

    self:ClearComponentCaches()
    self:ClearAllElement()

    if gLGameUI then
        gLGameUI:OnWndClose(self)
    end

    self:OnWndClose()

    if not self._bForceShutDown then
        FireEvent(EventNames.ON_WND_CLOSE, wndName)
        if (not self:DoWndStartMoveBack()) then
            return
        end
        if self:CloseWndAnimation() then
            self:DestroyWndSpinetAll()
            self:DestroyWndPrefabAll()
            self:DestroyWndEffectAll()
            self:DestroyWndChildEffectAll()

            CS.UpdateChildLayer(self:GetWndTrans(), LWnd.WND_LAYER_EXTEND)
            return
        end
    else
        self:ClearWndThemeShow()
        self:ClearAllWndAnimation()
        self:DestroyWndSpinetAll()
        self:DestroyWndPrefabAll()
        self:DestroyWndEffectAll()
        self:DestroyWndChildEffectAll()

        CS.UpdateChildLayer(self:GetWndTrans(), LWnd.WND_LAYER_EXTEND)
    end

    self:WndDestroy()
end

function LWnd:ClearAllElement()
    local wndTimer = self._wndTimer
    if (wndTimer) then
        wndTimer:Destroy()
        self._wndTimer = nil
    end


    self:ClearNotUICallListen()
    self:ClearAllHyperText()
    self:ClearUIHeroRaceList()
    self:ClearReportGetter()
    self:ClearSeqCom()
    self:ReleaseRedPointFunc() --释放红点
    self:ClearWndThemeShow()
    self:ClearAllWndAnimation()
    self:ClearAllUIList()
    self:ClearAllCommonEmptyList()
    self:ClearAllHeadIcons()
    self:ClearAllCommonIcon()
    self:CloseAllChild()
    self:ClearUIStateActors()
    self:ClearImages()
    self:ClearFonts()
    self:RemoveInstanceIDMap()
    self:WndEventRemoveAll()
    self:WndNetMsgRemoveAll()
    self:UIProgressRemoveAll()
    self:DestroyWndEffectAll()
    self:DestroyWndSpinetAll()
    self:TweenSeqDestroyAll()
    self:WndMusicClose()
end

function LWnd:OnWndClose()
end

------------------------------------------------------------------
--- wnd destroy
------------------------------------------------------------------
function LWnd:WndDestroy()
    self:DestroyWndStartMove()

    self:DoWndDestroy()

    local wndTrans = self._wndTrans
    if (CS.IsValidObject(wndTrans)) then
        LxResUtil.DestroyObject(wndTrans.gameObject)
    end
    wndTrans = nil
    self._wndTrans = nil
end

function LWnd:DoWndDestroy()

end

------------------------------------------------------------------
--- cs callback
------------------------------------------------------------------
function LWnd:UnityOnDestroy()
    LXFW.xpcall(self.OnDestroy, self)
end

function LWnd:UnityAwake()
    LXFW.xpcall(self.OnAwake, self)
end

function LWnd:UnityStart()
    local wndCloseCnt = self._wndCloseCnt
    if (wndCloseCnt and wndCloseCnt > 0) then
        printInfoN(self:GetClassName(), "already destory!")
        return
    end

    self._waitWndAniCall = true

    LXFW.xpcall(self.OnStart, self)

    if self._onStartFinish then
        self._onStartFinish()
        self._onStartFinish = nil
    end

    FireEvent(EventNames.AFTER_WND_START, self:GetWndName())
    self:WndMusicPlay()

    if not self.noNeedRegisterRed then
        self:RegisterRedPoint() --注册红点
    end

    if not self:IsHasWndAni() then
        self:GuideEventAfterStart()
    end
end

---need call OnAwake
function LWnd:DelaySendFinish(time)
    local delay = time or 0.2
    self._delayFinishEvent = true
    local timer = "delaySendFinish"
    self._wndTimer:TimerRemoveByKey(timer)
    self._wndTimer:TimerCreate(timer, function(key)
        if key == timer then
            self:DelayGuideReadyCall()
        end
    end, delay, false, 1)
end

function LWnd:SetAutoLangFont(bAuto)
    self._isAutoLangFont = bAuto
end

function LWnd:IsAutoLangFont()
    return self._isAutoLangFont
end

function LWnd:IsGuideReady()
    return self._isGuideReady
end

function LWnd:IsHasWndAni()
    return self._hasAni
end

function LWnd:AddWndAniCallbackList(callBack)
    if not self._waitWndAniCall then
        if callBack then
            callBack()
        end
        return
    end
    table.insert(self._wndAniCallbackList, callBack)
end

function LWnd:SendGuideReadyEvent(wndName)
    self._delayFinishEvent = false
    self:SendGuideReadyEventImpl(wndName)
end

function LWnd:GuideEventAfterStart()
    self._waitWndAniCall = false
    local wndName = self:GetWndName()
    self:SendGuideReadyEventImpl(wndName)
end

function LWnd:DelayGuideReadyCall()
    self._delayFinishEvent = false
    local wndName = self:GetWndName()
    self:SendGuideReadyEventImpl(wndName)
end

function LWnd:SendGuideReadyEventImpl(wndName)
    if self._waitWndAniCall then
        --界面动画未完成
        return
    end

    if self._delayFinishEvent then
        --固定时间延迟
        return
    end

    self._isGuideReady = true
    FireEvent(EventNames.ON_WND_FINISH, wndName)
end

function LWnd:SendWndOpenDetailInfo()
    if gModelHelpPicture then
        local show = gModelHelpPicture:CheckShowHelpPrefabByWndName(self:GetWndName())
        if show then
            FireEvent(EventNames.ON_HELP_PICTURE_WND_SHOW, true)
        end
    end

    if self._delaySendDetail then
        return
    end
    local wndName = self:GetWndName()
    local argList = self._wndArgList
    local wndPara = {
        wndName = wndName,
        para1 = argList and argList["page"],
        para2 = argList and argList["subPage"],
        argList = argList
    }

    FireEvent(EventNames.ON_WND_OPEN_TRIGGER, wndPara) --指引触发条件
end

function LWnd:DelaySendDetail(isDelay)
    self._delaySendDetail = isDelay
end

------------------------------------------------------------------
function LWnd:OnDestroy()
    self:WndMusicClose()
    local sortLayer = self._wndSortLayer
    local sortingOrder = self._wndSortOrder
    local wndLayer = self._wndLayer
    local wndKey = self._wndKey
    local wndName = self._wndName
    local prefabName = self._wndPrefabName
    local atlasList = self._wndSpriteAtlasList
    local wndCloseCnt = self._wndCloseCnt
    if wndCloseCnt and wndCloseCnt <= 0 then
        wndCloseCnt = 1
        self:ClearAllElement()
        self:OnWndClose()
    end
    self:ClearWndThemeShow()
    self:ClearAllWndAnimation()
    table.removeall(self)
    self._wndSortLayer = sortLayer
    self._wndSortOrder = sortingOrder
    self._wndLayer = wndLayer
    self._wndKey = wndKey
    self:SetWndName(wndName)
    self:SetWndPrefabName(prefabName)
    self:SetSpriteAtlasList(atlasList)
    self._wndCloseCnt = wndCloseCnt
    FireEvent(EventNames.WND_DESTROY, self:GetWndName())
    self._isDestroy = true

    gLGameUI:OnWndDestroy(self)
    self:OnDestroyEnd()

end

function LWnd:OnDestroyEnd()
end

function LWnd:IsDestroy()
    return self._isDestroy
end

function LWnd:OnCreate()
    self:SetAutoAdjustNotch(0)
    self:SetWndAsync(true)
    self:SetWndMode(LWnd.WND_MODE_UNIQUE)

    self:SendWndOpenDetailInfo()
    ---指引修改
    return true
end

function LWnd:OnAwake()
end

function LWnd:OnStart()
    self:WndEventRecv(EventNames.NET_LOST, function(...)
        self:OnTryTcpLost(...)
    end)
    self:WndEventRecv(EventNames.NET_RECONNECTED, function(...)
        self:OnTryTcpReconnect(...)
    end)

    if not self:IsChildWnd() then
        if (not LGameUI.NO_CLEAN_CLOSE_WND_LIST[self:GetClassName()]) then
            self:WndEventRecv(EventNames.WND_ALPHA_INOUT, function(...)
                self:TweenSeq_AlphaInOut(...)
            end)
        end
    end

    self:WndEventRecv(EventNames.ON_RED_POINT_CHANGE, function(...)
        self:_InnerRefreshRedPoint(...)
        self:OnTryRefreshRedPoint(...)
    end)

    self:SetWndStarted(true)
    self:SetWndVisible(self._wndVisible)

    local wndTheme = gLGameDisplayTheme:GetUITheme()
    self:InitWndThemeShow(wndTheme)
    self:InitWndLanguage()
    self:InitWndLanguageText()
    self:InitSensitiveRes()

    local nodes = nil
    local guideReadyFun = function()
        for _, callBack in ipairs(self._wndAniCallbackList) do
            callBack()
        end
        self._wndAniCallbackList = {}

        self:GuideEventAfterStart()
        gLGameUI:AddOpenAniCount(-1)
        if nodes then
            CS.UpdateNodesLayer(nodes, LWnd.WND_LAYER)
        end
    end
    local hasAni = false
    if self:IsChildWnd() then
        hasAni = self:InitChildWndAnimation(guideReadyFun)
    else
        hasAni = self:InitWndAnimation(guideReadyFun)
    end

    if hasAni then
        if (gLGameUI:AddOpenAniCount(1) > 0) then
            nodes = CS.UpdateChildLayer(self:GetWndTrans(), LWnd.WND_LAYER_EXTEND)
        end
    else
        self:DelaySendFinish(0.2)
    end

    self._hasAni = hasAni
end

function LWnd:OnStartCreate()
end

------------------------------------------------------------------
--- wnd create
------------------------------------------------------------------
function LWnd:Create(wndName, argList)
    self._wndTimer = LxTimer:New()
    self:SetWndName(wndName)
    self:SetWndPrefabName(gLGameLanguage:GetPrefabName(wndName))
    self:SetWndArg(argList)
    self:OnStartCreate()
    local wndTrans = self._wndTrans
    if (CS.IsValidObject(wndTrans)) then
        LogError("wndObject not null when create | " .. self._wndName)
        return false
    end
    if (not self:OnCreate()) then
        return false
    end
    local wndPrefabName = self._wndPrefabName
    if (not wndPrefabName) then
        LogError("empty wndPrefabName " .. self._wndName)
        return false
    end

    self:InitProperties()

    if gLGameUI:OnWndCreate(self) then
        return
    end

    --local isAsync = self:GetWndAsync()
    --if CS.IsWebGL() then isAsync = true end

    local assetPath = string.format("UI/Prefabs/panel/%s.prefab", tostring(wndPrefabName))
    self._resRequester = LxResUtil.GetAssetRequester(assetPath, typeofGameObject, function(obj)
        self:OnWndPrefabLoaded(obj, assetPath)
    end)
    self._resRequester:StartRequester()
    return true
end

------------------------------------------------------------------
--- wnd prefab loaded
------------------------------------------------------------------
function LWnd:OnWndPrefabLoaded(wndPrefab, wndPrefabPath)
    if (self:IsWndClosed()) then
        return
    end
    if not wndPrefab then
        if gLGameUI then
            gLGameUI:OnWndClose(self)
        end
        LogError("can't load wndPrefabName " .. wndPrefabPath)
        return
    end
    local wndObject = LxResUtil.NewObject(wndPrefab)
    wndPrefab = nil
    local wndTrans = wndObject.transform
    self._wndTrans = wndTrans

    local wndCanvas = wndTrans:GetComponent(typeofCanvas)
    if (not wndCanvas) then
        wndCanvas = wndObject:AddComponent(typeofCanvas)
    end
    wndCanvas.overrideSorting = true
    wndCanvas.sortingLayerName = self:GetWndSortLayer()
    self._wndCanvas = wndCanvas

    local wndGraphicRaycaster = wndTrans:GetComponent(typeofGraphicRaycaster)
    if (not wndGraphicRaycaster) then
        wndGraphicRaycaster = wndObject:AddComponent(typeofGraphicRaycaster)
        wndGraphicRaycaster.ignoreReversedGraphics = true
    end
    self._wndGraphicRaycaster = wndGraphicRaycaster

    local csCanvasGroup = wndTrans:GetComponent(typeofCanvasGroup)
    if (not csCanvasGroup) then
        csCanvasGroup = wndObject:AddComponent(typeofCanvasGroup)
    end
    self._wndCanvasGroup = csCanvasGroup
    if csCanvasGroup then
        self._bWndInnerBlockRaycasts = csCanvasGroup.blocksRaycasts
    end

    self:_InternalInitUI()

    wndObject:SetActive(false) -- stop awake
    CS.BindLuaTable(wndObject, self)

    gLGameUI:OnWndLoaded(self)
    wndObject:SetActive(true) -- active awake

    if self._wndName == "UIFightPrepare"
            or self._wndName == "UIFight"
            or self._wndName == "UIMCity" then
        local isFontVisible = gLGameUI:IsVisibleBattleFont()
        self:SetAllUIVisible(isFontVisible)
    end

    if self._isShow ~= nil then
        self:Show(self._isShow)
    end
end

function LWnd:Show(isShow)
    if not self._wndTrans then
        self._isShow = isShow
        return
    end
    self._isShow = nil
    if isShow then
        self._wndTrans.gameObject:SetActive(true)
    else
        self._wndTrans.gameObject:SetActive(false)
    end
end

function LWnd:TrySetWndSortOrder(index)
    local newOrder = (index - 1) * 300 + 1
    local order = self:GetWndSortOrder()
    if order == newOrder then
        return
    end
    self:SetWndSortOrder(newOrder)
    self:UpdateWndSort()

    self:ResetChildsSortOrder()
end

function LWnd:UpdateWndSort()
    local newOrder = self:GetWndSortOrder()
    local sortLayerName = self:GetWndSortLayer()

    local wndCanvas = self:GetWndCanvas()
    local oldOrder = wndCanvas.sortingOrder
    wndCanvas.sortingOrder = newOrder

    local diffOrder = newOrder - oldOrder

    local wndTrans = self:GetWndTrans()

    local dicCanvas = self._dicSoringCanvas or {}

    local childCanvasList = wndTrans:GetComponentsInChildren(typeofCanvas, true)
    for k = 1, childCanvasList.Length do
        local canvasChild = childCanvasList[k - 1]
        if canvasChild ~= wndCanvas then
            --local canvasChildInstanceId = canvasChild:GetInstanceID()
            --local canvasChildOrder = dicCanvas[canvasChildInstanceId]
            --if not canvasChildOrder then
            --	canvasChildOrder = canvasChild.sortingOrder
            --	dicCanvas[canvasChildInstanceId] = canvasChildOrder
            --end
            --canvasChild.sortingOrder = canvasChildOrder + newOrder
            canvasChild.sortingOrder = canvasChild.sortingOrder + diffOrder
            canvasChild.sortingLayerName = sortLayerName
        end
    end
    self._dicSoringCanvas = dicCanvas

    local rendererSortList = wndTrans:GetComponentsInChildren(typeofUISorting, true)
    for k = 1, rendererSortList.Length do
        local rendererSort = rendererSortList[k - 1]
        rendererSort:SetLayerName(sortLayerName)
        rendererSort:SetParentOrder(newOrder)
        rendererSort:UpdateSorting()
    end
end

function LWnd:OnCanvasParaChange()

end

------------------------------------------------------------------
function LWnd:InitUI()

end

function LWnd:_InternalInitUI()
    if not self:IsWndValid() then
        return
    end
    local wndTrans = self:GetWndTrans()
    local prefabVar = wndTrans.gameObject:GetComponent(typeOfCPrefab)
    if not CS.IsNullObject(prefabVar) then
        local varData = prefabVar:GetVarArray()
        local iter = varData:GetEnumerator()
        while iter:MoveNext() do
            local varObj = iter.Current
            if not CS.IsNullObject(varObj) then
                --lua访问C#时候，c#对象会转成实际类型
                --table的key的访问有两种方式，得以实现如此
                self[varObj.name] = varObj.objValue
            end
        end
    end
end

------------------------------------------------------------------
--- wnd attrib
------------------------------------------------------------------
function LWnd:GetWndKey()
    return self._wndKey
end

function LWnd:SetWndKey(v)
    self._wndKey = v
end

function LWnd:SetWndName(v)
    self._wndName = v
end

function LWnd:GetWndName()
    return self._wndName
end

function LWnd:SetWndPrefabName(v)
    self._wndPrefabName = v
end

function LWnd:GetWndPrefabName()
    return self._wndPrefabName
end

function LWnd:GetWndTrans()
    return self._wndTrans
end

function LWnd:SetWndParent(v)
    self._wndParent = v
end

function LWnd:GetWndParent()
    return self._wndParent
end

function LWnd:SetWndAsync(v)
    self._wndAsync = v
end

function LWnd:GetWndAsync()
    return self._wndAsync
end

function LWnd:GetWndCanvas()
    return self._wndCanvas
end

function LWnd:GetWndGraphicRaycaster()
    return self._wndGraphicRaycaster
end

function LWnd:GetWndCanvasGroup()
    return self._wndCanvasGroup
end

function LWnd:GetWndStarted()
    return self._wndStarted
end

function LWnd:SetWndStarted(v)
    self._wndStarted = v
end

function LWnd:SetWndSortLayer(layer)
    self._wndSortLayer = layer
end

function LWnd:GetWndSortLayer()
    return self._wndSortLayer
end

function LWnd:IsWndSortLayer(layer)
    return (self._wndSortLayer == layer)
end

function LWnd:SetWndSortOrder(order)
    self._wndSortOrder = order
    self:OnCanvasParaChange()
end

function LWnd:GetWndSortOrder()
    return self._wndSortOrder
end

function LWnd:SetWndSwitchType(switchType)
    self._wndSwitchType = switchType
end

function LWnd:GetWndSwitchType()
    return self._wndSwitchType
end

function LWnd:IsBackOpen()
    return self._isBackOpen
end

function LWnd:SetBackOpen(bBackOpen)
    self._isBackOpen = bBackOpen
end

function LWnd:SetWndArg(argList)
    self._wndArgList = argList
    self:OnWndArg()
end

function LWnd:GetWndArgList()
    return self._wndArgList
end

function LWnd:GetWndArg(pos)
    local wndArgList = self._wndArgList
    if (pos) then
        if (wndArgList) then
            return wndArgList[pos]
        end
    end
    return nil
end

function LWnd:OnWndArg()
end

function LWnd:SetWndMode(...)
    local wndMode = 0
    for k, v in ipairs({ ... }) do
        wndMode = bit.bor(wndMode, v)
    end
    self._wndMode = wndMode
end

function LWnd:IsWndMode(v)
    return (bit.band(self._wndMode, v) ~= 0)
end

function LWnd:IsChildWnd()
    return false
end

function LWnd:SetAutoAdjustNotch(adjustType)
    self._wndAutoAdjustNotch = adjustType
end

function LWnd:GetAutoAdjustNotch()
    return self._wndAutoAdjustNotch
end

function LWnd:SetSpriteAtlasList(atlasList)
    self._wndSpriteAtlasList = atlasList
end

function LWnd:GetSpriteAtlasList()
    return self._wndSpriteAtlasList
end

function LWnd:SetRemoveChildBundleDepend(bRemove)
    self._wndRemoveChildBundleDepend = bRemove
end

function LWnd:IsRemoveChildBundleDepend()
    return self._wndRemoveChildBundleDepend
end

function LWnd:GetHistory()
    self._history = {
        wndName = self._wndName,
        wndArgList = self._wndArgList or {},
        wndSortOrder = self._wndSortOrder,
        wndSortLayer = self._wndSortLayer, -- 窗口层级
    }
    return self._history
end

------------------------------------------------------------------
--- wnd function
------------------------------------------------------------------
--- 窗口是否设置已关闭
function LWnd:IsWndClosed()
    local wndCloseCnt = self._wndCloseCnt
    if (wndCloseCnt and wndCloseCnt > 0) then
        return true
    end
    return false
end

--- 窗口是否有效
function LWnd:IsWndValid()
    if (self:IsWndClosed()) then
        return false
    end
    return CS.IsValidObject(self._wndTrans)
end

--- 设置窗口alpha
function LWnd:SetWndAlpha(alpha)
    if (self:IsWndValid()) then
        local wndCanvasGroup = self._wndCanvasGroup
        if (not wndCanvasGroup) then
            LogError("can't find CanvasGroup on WndGame " .. self:GetWndName())
            return
        end
        wndCanvasGroup.alpha = alpha
        local isShow = true
        if (alpha < 1) then
            isShow = false
        end
        wndCanvasGroup.interactable = isShow

        local innerBlock = isShow
        if self._bWndInnerBlockRaycasts ~= nil then
            innerBlock = isShow and self._bWndInnerBlockRaycasts
        end
        wndCanvasGroup.blocksRaycasts = innerBlock
    end
end

--- 设置窗口显示/隐藏
function LWnd:IsWndVisible()
    return self._wndVisible
end

function LWnd:SetWndVisible(active)
    if not gLGameUI:IsVisibleAllUI() then
        if self:GetWndName() ~= "UIGMand" then
            active = false
        end
    end

    self._wndVisible = active
    -- hide by alpha
    local alpha = 1
    if (not active) then
        alpha = 0
    end
    self:SetWndAlpha(alpha)
    -- hide by position
    --OOOOOO

    --print("-------------------------wnd alpha "..alpha)
end

--- 已打开的界面刷新
function LWnd:RefreshWhenOpen(args)
    self:SetWndArg(args)
    if self._wndStarted then
        self:OnWndRefresh()
    end
end

function LWnd:OnWndRefresh()

end

function LWnd:SetOnStartFinish(func)
    self._onStartFinish = func
end

------------------------------------------------------------------
--- on tcp lost && reconnect
------------------------------------------------------------------
function LWnd:OnTryTcpLost(...)
    if (self.OnTcpLost) then
        self:OnTcpLost(...)
    end
end

function LWnd:OnTryTcpReconnect(...)
    if (self.OnTcpReconnect) then
        self:OnTcpReconnect(...)
    end
end

------------------------------------------------------------------
--- wnd Drag
--- 拖拽有两种
--- 1 - 窗口对象拖拽 = LWnd:UIDragSetItem , callback = LWnd:UIDragOnBegin(dragKey, event)
--- 2 - 列表子对象拖拽 = UIList:SetDragDrop , callback = LWnd:UIDragOnBegin(dragKey, event, UIList)
--- dragMode
---        XUIDragMode.DragClone
---        XUIDragMode.DragCloneHideOrigin
---        XUIDragMode.DragOrigin
---        XUIDragMode.DragNothing
------------------------------------------------------------------
function LWnd:InternalUIDragSetItem(dragKey, itemObj, dragMode, bActive, isfollow, rootParent)
    local wndTrans = self._wndTrans
    if (not wndTrans) then
        return
    end
    dragKey = dragKey or "uiDragKey"
    if bActive == nil then
        bActive = true
    end
    rootParent = rootParent or wndTrans.gameObject
    dragMode = dragMode or XUIDragMode.DragClone
    if (itemObj) then
        local csUIDrag = itemObj:GetComponent(typeXUIDrag)
        if (not csUIDrag) then
            csUIDrag = itemObj.gameObject:AddComponent(typeXUIDrag)
            csUIDrag.rootParent = rootParent
            csUIDrag.onBeginDrag = function(...)
                self:UIDragTryOnBegin(dragKey, ...)
            end
            csUIDrag.onDrag = function(...)
                self:UIDragTryOnDrag(dragKey, ...)
            end
            csUIDrag.onEndDrag = function(...)
                self:UIDragTryOnEnd(dragKey, ...)
            end
        end
        csUIDrag.dragMode = dragMode
        csUIDrag.enabled = bActive
        if isfollow ~= nil then
            csUIDrag.follow = isfollow
        end
    end
end

function LWnd:UIDragSetItem(dragKey, childPath, dragMode, bActive, isfollow)
    local wndTrans = self._wndTrans
    if (not wndTrans) then
        return
    end
    local itemObj
    if (childPath ~= nil) then
        itemObj = wndTrans:Find(childPath)
    else
        itemObj = wndTrans
    end
    self:InternalUIDragSetItem(dragKey, itemObj, dragMode, bActive, isfollow)
end

function LWnd:UIDragTryOnBegin(...)
    if (self.UIDragOnBegin) then
        self:UIDragOnBegin(...)
    end
end

function LWnd:UIDragTryOnDrag(...)
    if (self.UIDragOnDrag) then
        self:UIDragOnDrag(...)
    end
end

function LWnd:UIDragTryOnEnd(...)
    if (self.UIDragOnEnd) then
        self:UIDragOnEnd(...)
    end
end

-----------------------------------------------------------------------------
--- wnd event
------------------------------------------------------------------------------
function LWnd:WndEventRemoveAll()
    if self._behaviour then
        self._behaviour:RemoveEventHandlerList()
    end
end

function LWnd:WndEventRecv(event, func, target)
    if self._behaviour then
        self._behaviour:AddEventHandler(event, func, target)
    end
end

function LWnd:WndEventRemove(event)
    if self._behaviour then
        self._behaviour:RemoveEventHandler(event)
    end
end

------------------------------------------------------------------------------
--- wnd net msg
------------------------------------------------------------------------------
function LWnd:WndNetMsgRemoveAll()
    if self._behaviour then
        self._behaviour:RemoveMsgHandlerList()
    end
end

function LWnd:WndNetMsgRecv(msg, func, target)
    if self._behaviour then
        self._behaviour:AddMsgHandler(msg, func, target)
    end
end

function LWnd:WndNetMsgRemove(msg)
    if self._behaviour then
        self._behaviour:RemoveMsgHandler(msg)
    end
end
------------------------------------------------------------------------------
--- wnd timer
------------------------------------------------------------------------------
function LWnd:TimerStop(key)
    if self._wndTimer then
        self._wndTimer:TimerRemoveByKey(key)
    end
end

---@param timeScale boolean false:不受加速 影响，true:受加速 影响
function LWnd:TimerStart(key, time, timeScale, loopCnt)
    if not time then
        if LOG_INFO_ENABLED then
            print("time is nil")
        end
        return
    end
    local timeUnscale = not timeScale
    if self._wndTimer then
        self._wndTimer:TimerCreate(key, function(...)
            self:OnTryTimer(...)
        end, time, timeUnscale, loopCnt)
    end
end

function LWnd:OnTryTimer(key)
    if (self.OnTimer) then
        self:OnTimer(key)
    end
    local call = self._timeCallMap and self._timeCallMap[key]
    if call then
        call()
    end
end

function LWnd:IsTimerExist(key)
    if not self._wndTimer then
        return false
    end
    local timer = self._wndTimer:TimerGetByKey(key)
    return timer ~= nil
end

function LWnd:TimePauseAll(bPause)
    if self._wndTimer then
        self._wndTimer:TimePause(bPause)
    end
end

function LWnd:TimerStartImpl(timePara)
    if timePara.callOnStart then
        if timePara.func then
            timePara.func()
        end
    end
    self:TimerStop(timePara.key)
    local timescale = timePara.timescale or false
    local loopcnt = timePara.loopcnt or 1
    self:TimerStart(timePara.key, timePara.interval, timescale, loopcnt)
    if not self._timeCallMap then
        self._timeCallMap = {}
    end
    self._timeCallMap[timePara.key] = timePara.func
end

------------------------------------------------------------------------------
--- wnd start move
------------------------------------------------------------------------------
function LWnd:DoWndStartMove(beginWaitSec, fromDir, inTrans)
    local inTransform = inTrans
    local originPos = inTransform.localPosition
    local toPos = originPos
    local moveRange = 1500
    local moveSec = 0.3
    if (fromDir == LWnd.StartMoveLeft) then
        inTransform.localPosition = originPos + Vector3(-moveRange, 0, 0)
    elseif (fromDir == LWnd.StartMoveTop) then
        inTransform.localPosition = originPos + Vector3(0, moveRange, 0)
    elseif (fromDir == LWnd.StartMoveRight) then
        inTransform.localPosition = originPos + Vector3(moveRange, 0, 0)
    elseif (fromDir == LWnd.StartMoveBottom) then
        inTransform.localPosition = originPos + Vector3(0, -moveRange, 0)
    else
        inTransform.localPosition = originPos
    end
    local dtSequence = Tweening.DOTween.Sequence()
    dtSequence:SetAutoKill(false)
    local dtMoveTo = inTransform:DOLocalMove(toPos, moveSec, false):SetEase(EaseOutQuad)
    dtSequence:AppendInterval(beginWaitSec)
    dtSequence:Append(dtMoveTo)
    dtSequence:PlayForward()
    local dtsWndStartMove = self._wndTweenStartMove
    if (dtsWndStartMove == nil) then
        dtsWndStartMove = {}
        self._wndTweenStartMove = dtsWndStartMove
    end
    table.insert(dtsWndStartMove, dtSequence)
end

function LWnd:DoWndStartMoveBack()
    local dtsWndStartMove = self._wndTweenStartMove
    if (dtsWndStartMove) then
        self._wndTweenStartMove_count = #dtsWndStartMove
        for k, v in ipairs(dtsWndStartMove) do
            local completeFunc = function()
                --v:Kill(false)
                local dtsWaitCnt = self._wndTweenStartMove_count - 1
                self._wndTweenStartMove_count = dtsWaitCnt
                if (dtsWaitCnt <= 0) then
                    self:WndDestroy()
                    self._wndTweenStartMove_count = nil
                end
            end
            v:OnStepComplete(completeFunc)
            v:PlayBackwards()

            --#fix bug which the PlayBackwards is failure because of PlayForward not run any position
            if (v:IsActive()) then
                --print("the PlayBackwards is failure")
                completeFunc()
            end
        end
        return false
    end
    return true
end

function LWnd:DestroyWndStartMove()
    if self._wndTweenStartMove then
        for k, v in ipairs(self._wndTweenStartMove) do
            v:Kill(false)
        end
        self._wndTweenStartMove = nil
        self._wndTweenStartMove_count = nil
    end
end

function LWnd:DoWndStartScale(beginWaitSec, inTrans, callFunc)
    local inTransform = inTrans
    local originPos = inTransform.localScale
    local toPos = originPos
    local moveSec = 0.2
    inTransform.localScale = Vector3(0, 0, 0)
    local dtSequence = Tweening.DOTween.Sequence()
    dtSequence:SetAutoKill(false)
    local dtMoveTo = inTransform:DOScale(toPos, moveSec):SetEase(EaseOutQuad)
    dtSequence:AppendInterval(beginWaitSec)
    dtSequence:Append(dtMoveTo)
    dtSequence:OnComplete(function()
        if callFunc then
            callFunc()
        end
    end)
    dtSequence:PlayForward()
    local dtsWndStartMove = self._wndTweenStartMove
    if (dtsWndStartMove == nil) then
        dtsWndStartMove = {}
        self._wndTweenStartMove = dtsWndStartMove
    end
    table.insert(dtsWndStartMove, dtSequence)
end

function LWnd:RemoveWndStartScale()
    if self._wndTweenStartMove then
        for _, v in ipairs(self._wndTweenStartMove) do
            if v:IsPlaying() then
                v:Kill()
            end
        end
    end

    self._wndTweenStartMove = nil
end

function LWnd:DoWndStartAlpha()
    self:TweenSeq_AlphaInOut(true, 0.1, 0, 1)
end

------------------------------------------------------------------
--- 窗口控件控制
------------------------------------------------------------------
------------------------------------------------------------------
--- wnd transform
------------------------------------------------------------------
function LWnd:FindWndTrans(trans, childPath)
    if (trans) then
        if (childPath) then
            return trans:Find(childPath)
        else
            return trans
        end
    else
        return self:GetWndTrans():Find(childPath)
    end
end

------------------------------------------------------------------
--- wnd click
------------------------------------------------------------------
function LWnd:SetWndClick(theTrans, func, soundRefId, showTips)
    local modifyFun = func
    if gModelFunctionOpen then
        modifyFun = gModelFunctionOpen:ModifyFunc(self:GetWndName(), theTrans, func, showTips)
    end
    LxUiHelper.SetTransClick(theTrans, modifyFun, soundRefId)
end

function LWnd:SetIconClickScale(theTrans, bEnable)
    local trans = theTrans
    if not trans or not CS.IsValidObject(trans) then
        return
    end
    if not bEnable then
        local clickScale = trans:GetComponent(typeClickScale)
        if clickScale then
            clickScale.enabled = false
        end
        return
    else
        local clickScale = trans:GetComponent(typeClickScale)
        if not clickScale then
            clickScale = trans.gameObject:AddComponent(typeClickScale)
        else
            clickScale.enabled = true
        end
        clickScale.clickScaleTime = 0.12
        clickScale.clickScaleDown = 0.95
        clickScale.clickScaleUp = 1.02
    end
end

function LWnd:SetWndLongClick(theTrans, func, thresHold, isRepeat, soundRefId, pointerUpFunc)
    LxUiHelper.SetTransLongClick(theTrans, func, thresHold, isRepeat, soundRefId, pointerUpFunc)
end

------------------------------------------------------------------
--- wnd textmesh
------------------------------------------------------------------
function LWnd:_InternalSetTextMaterial(uiText, matName)
    self:InitTextAutoLangFont(uiText, matName)
end

function LWnd:InitTextAutoLangFont(uiText, forceMatName)
    if not self:IsWndValid() then return end
    if CS.IsNullObject(uiText) then return end

    local forceChange = not string.isempty(forceMatName)

    if not forceChange and not self:IsAutoLangFont() then return end

    local isNeedLoad, sysFontChangeName, materialChangeName, artFontChangeName = LxUiHelper.GetXUITextTextLanguage(uiText,forceMatName)
    if isNeedLoad then
        local id = self:FindInstanceID(uiText)
        local fontText = self._ui_fonts[id]
        if not fontText then
            fontText = require("LApp.component.res.LxFontText"):New(uiText)
            self._ui_fonts[id] = fontText
        end
        fontText:SetSysFontPath(sysFontChangeName)
        fontText:SetMaterialPath(materialChangeName)
        fontText:SetArtFontPath(artFontChangeName)
        fontText:LoadSysFont()
        fontText:LoadArtFont()
    end
end

function LWnd:SetXUITextText(xuitext, msg)
    self:InitTextAutoLangFont(xuitext)
    xuitext.text = msg
end

function LWnd:SetXUITextFontSize(xuitext, size)
    xuitext.fontSize = size
end

function LWnd:SetXUITextColor(xuitext, color)
    if not color then
        return
    end
    xuitext.color = color
end

function LWnd:SetXUITextbSelect(trans, colors, bool)
    local uiText = LxUiHelper.FindXTextCtrl(trans)
    local color = colors[2]
    if (bool) then
        color = colors[1]
    end
    color = LUtil.ColorByHex(color)
    if (uiText) then
        uiText.color = color
    end
end

function LWnd:SetXUITextbSelect2(trans, colors, bool)
    local uiText = LxUiHelper.FindXTextCtrl(trans)
    local color = colors[2]
    if (bool) then
        color = colors[1]
    end
    color = LUtil.ColorByHex_6(color)
    if (uiText) then
        uiText.color = color
    end
end

function LWnd:SetXUITextTransColor(trans, color)
    if type(color) == "string" then
        color = LUtil.ColorByHex(color)
    end
    local uiText = LxUiHelper.FindXTextCtrl(trans)
    if (uiText) then
        uiText.color = color
    end
end

function LWnd:SetTextTransColorGradient(trans, topColor, bottomColor)
    if not string.isempty(topColor) and not string.isempty(bottomColor) then
        local top, bottom
        local topColorLen = string.len(topColor)
        local bottomColorLen = string.len(bottomColor)
        if (topColorLen == 8) then
            top = LUtil.ColorByHex(topColor)
        else
            top = LUtil.ColorByHex_6(topColor)
        end

        if (bottomColorLen == 8) then
            bottom = LUtil.ColorByHex(bottomColor)
        else
            bottom = LUtil.ColorByHex_6(bottomColor)
        end

        LxUiHelper.SetTextColorGradient(trans, top, top, bottom, bottom)
    end
end

function LWnd:FindWndText(trans)
    return self:FindCommonComponent(trans, typeUIText)
end

function LWnd:SetWndText(trans, msg)
    if not trans then return end

    if LOG_INFO_ENABLED then
        if LPlayerPrefs.openClientTextLog == "1" then
            printErrorN("：文本节点名字：" .. trans.name)
        end
    end
    local text = self:FindCommonComponent(trans, typeUIText)
    if not CS.IsValidObject(text) then return end

    self:InitTextAutoLangFont(text)
    text.text = msg
end

function LWnd:SetWndTextMat(trans, matName)
    if not trans then return end

    local uiText = LxUiHelper.FindXTextCtrl(trans)
    self:_InternalSetTextMaterial(uiText, matName)
end

function LWnd:FindWndTextInput(trans)
    return LxUiHelper.FindXTextInputCtrl(trans)
end

function LWnd:SetWndTextInput(trans, sText, sTextHold)
    local uiInput,holdText,showText = LxUiHelper.FindXTextInputCtrl(trans.transform)
    if (holdText and sTextHold) then
        self:InitTextAutoLangFont(holdText)
        holdText.text = sTextHold
        if (string.isempty(sText)) then
            holdText.enabled = true
        else
            holdText.enabled = false
        end
    end
    if (showText) then
        self:InitTextAutoLangFont(showText)
        showText.text = sText or ""
    end
    if (uiInput) then
        uiInput.text = sText or ""
    end
end

function LWnd:SetTextOutLineByColor(trans, color)
    local mat = LUtil.GetOutLineMat(color)
    self:SetWndTextMat(trans, mat)
end

-- 设置窗口文字
function LWnd:SetWndTitleByTextId(trans, textId)
    if not textId then
        return
    end
    local title = ccClientText(textId)
    self:SetWndText(trans, title)
end

-- 设置窗口文字
function LWnd:SetWndTitleByTitle(trans, title)
    self:SetWndText(trans, title)
end

function LWnd:SetWndTabText(buttonTrans, str, addFontSize, addFontLine)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    addFontSize = addFontSize or -2
    local offTrans = CS.FindTrans(buttonTrans, "Off/Text")
    local onTrans = CS.FindTrans(buttonTrans, "On/Text")
    local grayTrans = CS.FindTrans(buttonTrans, "Gray/Text")
    self:SetWndText(offTrans, str)
    self:SetWndText(onTrans, str)
    self:SetWndText(grayTrans, str)

    self:InitTextSizeWithLanguage(offTrans, addFontSize)
    self:InitTextSizeWithLanguage(onTrans, addFontSize)
    self:InitTextSizeWithLanguage(grayTrans, addFontSize)

    if addFontLine then
        self:InitTextLineWithLanguage(offTrans, addFontLine)
        self:InitTextLineWithLanguage(onTrans, addFontLine)
        self:InitTextLineWithLanguage(grayTrans, addFontLine)
    end
end

function LWnd:SetWndTabIcon(buttonTrans, offPath, onPath,bgPath)
    if CS.IsNullObject(buttonTrans) then
        return
    end

    onPath = onPath or offPath

    local onBgTrans = CS.FindTrans(buttonTrans, "OnBg")
    local offTrans = CS.FindTrans(buttonTrans, "Off")
    local onTrans = CS.FindTrans(buttonTrans, "On")
    local grayTrans = CS.FindTrans(buttonTrans, "Gray")

    if offTrans then
        self:SetWndEasyImage(offTrans, offPath)
    end

    if onTrans then
        self:SetWndEasyImage(onTrans, onPath)
    end

    if grayTrans then
        self:SetWndEasyImage(grayTrans, onPath)
    end
    if onBgTrans then
        self:SetWndEasyImage(onBgTrans, bgPath,nil,true)
    end
end

function LWnd:SetWndTabStatus(buttonTrans, status, index)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    local offTrans = CS.FindTrans(buttonTrans, "Off")
    local onBg = CS.FindTrans(buttonTrans, "OnBg")
    local onTrans = CS.FindTrans(buttonTrans, "On")
    local grayTrans = CS.FindTrans(buttonTrans, "Gray")
    local lockTrans = CS.FindTrans(buttonTrans, "Lock")

    status = status and status or LWnd.StateOn
    local bGray = status == LWnd.StateGray
    local bOn = status == LWnd.StateOn
    local bOff = status == LWnd.StateOff
    local bLock = status == LWnd.StateLock

    CS.ShowObject(offTrans, bOff or bLock)
    CS.ShowObject(onBg, bOn)
    CS.ShowObject(onTrans, bOn)
    CS.ShowObject(grayTrans, bGray)
    CS.ShowObject(lockTrans, bLock)

    if onBg then
        onBg.localRotation = Quaternion.Euler(0, (index and index == 1) and 180 or 0, 0)
        local onBgPath = (index and index == 1) and "mainui_btn_tab_on2" or "mainui_btn_tab_on"
        self:SetWndEasyImage(onBg, onBgPath, nil, true)
    end
end

function LWnd:SetWndTabTextLine(buttonTrans, lineValue)
    if CS.IsNullObject(buttonTrans) then
        return
    end

    local offTrans = CS.FindTrans(buttonTrans, "Off/Text")
    local onTrans = CS.FindTrans(buttonTrans, "On/Text")
    local grayTrans = CS.FindTrans(buttonTrans, "Gray/Text")

    self:InitTextLineWithLanguage(offTrans, lineValue)
    self:InitTextLineWithLanguage(onTrans, lineValue)
    self:InitTextLineWithLanguage(grayTrans, lineValue)
end

function LWnd:SetWndButtonText(buttonTrans, str, pos, addFontSize, addLine)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    addFontSize = addFontSize or -2
    local lightText = CS.FindTrans(buttonTrans, "Light/Text")
    local grayText = CS.FindTrans(buttonTrans, "Gray/Text")
    self:SetWndText(lightText, str)
    self:SetWndText(grayText, str)
    self:InitTextSizeWithLanguage(lightText, addFontSize)
    self:InitTextSizeWithLanguage(grayText, addFontSize)
    if pos then
        lightText.transform.localPosition = pos
        grayText.transform.localPosition = pos
    end
    if addLine then
        self:InitTextLineWithLanguage(lightText, addLine)
        self:InitTextLineWithLanguage(grayText, addLine)
    end
end

function LWnd:SetWndButtonTextMat(buttonTrans, matName)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    local lightText = CS.FindTrans(buttonTrans, "Light/Text")
    self:SetWndTextMat(lightText, matName)
end

function LWnd:SetWndButtonTextColor(buttonTrans, color)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    local lightText = CS.FindTrans(buttonTrans, "Light/Text")
    LxUiHelper.SetXTextColor(lightText, color)
end

function LWnd:SetTextColor(Trans, color)
    LxUiHelper.SetXTextColor(Trans, color)
end

function LWnd:SetWndButtonImg(buttonTrans, imgName, func, isNativeSize)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    local lightImg = CS.FindTrans(buttonTrans, "Light")
    self:SetWndEasyImage(lightImg, imgName, func, isNativeSize)
end

function LWnd:SetWndButtonGray(buttonTrans, isGray)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    local lightTrans = CS.FindTrans(buttonTrans, "Light")
    local grayTrans = CS.FindTrans(buttonTrans, "Gray")
    if (isGray) then
        CS.ShowObject(lightTrans, false)
        CS.ShowObject(grayTrans, true)
    else
        CS.ShowObject(lightTrans, true)
        CS.ShowObject(grayTrans, false)
    end
end

function LWnd:SetWndButtonTextLine(buttonTrans, lineValue)
    if CS.IsNullObject(buttonTrans) then
        return
    end
    local lightText = CS.FindTrans(buttonTrans, "Light/Text")
    local grayText = CS.FindTrans(buttonTrans, "Gray/Text")

    self:InitTextLineWithLanguage(lightText, lineValue)
    self:InitTextLineWithLanguage(grayText, lineValue)
end

function LWnd:SetTextTile(trans, str, addLine, addSize)
    local UITextTrans = CS.FindTrans(trans, "UIText")
    self:SetWndText(UITextTrans, str)

    if addLine then
        self:InitTextLineWithLanguage(UITextTrans, addLine)
    end

    if addSize then
        self:InitTextSizeWithLanguage(UITextTrans, addSize)
    end
end

function LWnd:SetRed(trans, isShow)
    local redTrans = CS.FindTrans(trans, "redPoint")
    if redTrans then
        CS.ShowObject(redTrans, not not isShow)
    end
end

function LWnd:SetAnchorPos(rectTran, pos)
    if not pos then
        return
    end
    if not rectTran then
        return
    end
    rectTran.anchoredPosition = pos
end

function LWnd:SetTrAnchors(trans, v2)
    trans.anchorMin = v2
    trans.anchorMax = v2
    trans.pivot = v2
end

function LWnd:SetAllUIVisible(isShow)
    if not self:IsWndValid() then
        return
    end
    if self._isVisibleAllText == isShow then
        return
    end

    self._isVisibleAllText = isShow
    local alpha = isShow and 1 or 0
    local layerRoot = self:GetWndTrans()
    local childs = layerRoot:GetComponentsInChildren(typeUIText, true)
    for i = 0, childs.Length - 1 do
        local text = childs[i]
        if CS.IsValidObject(text) then
            local oldColor = text.color
            text.color = Color.New(oldColor.r, oldColor.g, oldColor.b, alpha)
        end
    end
end

function LWnd:SetAllUIRedVisible(isShow)
    if not self:IsWndValid() then
        return
    end
    if self._isVisibleAllRed == isShow then
        return
    end

    local needCheckSpriteNameList = {
        "public_redpoint",
    }

    self._isVisibleAllRed = isShow
    local alpha = isShow and 1 or 0
    local layerRoot = self:GetWndTrans()
    local childs = layerRoot:GetComponentsInChildren(typeUIImage, true)
    for i = 0, childs.Length - 1 do
        local sp = childs[i]
        if CS.IsValidObject(sp) and sp.sprite then
            local spName = sp.sprite.name
            if not string.isempty(spName) then
                for k, v in ipairs(needCheckSpriteNameList) do
                    if string.find(spName, v) then
                        sp.color = Color.New(1, 1, 1, alpha)
                    end
                end
            end
        end
    end
end

function LWnd:SetAnchorPosStr(tran, pos, sign)
    if not string.isempty(pos) then
        self:SetAnchorPos(tran, LxDataHelper.ParseVector2(pos, sign))
    end
end

------------
--- showStr：活动配置
--- showPos：显示位置
--- parentRoot：父节点，包含 图片节点 和 spine节点
--- imgRoot：图片节点
--- spineRoot：spine节点
------ spineKey：spineKey，没有默认节点的GetInstanceID
--[[
eg:
	showInfo = {
		showStr = config.heroImg,
		showPos = config.heroImgPos,
		parentRoot = self.mShowPos,
		imgRoot = self.mImgPos,
		spineRoot = self.mSpinePos,
		spineKey = self.mSpinePos:GetInstanceID(),
	}
]]
function LWnd:SetActivityShowInfo(showInfo)
    local showStr = showInfo.showStr
    local parentRoot = showInfo.parentRoot
    local showParentRoot = not string.isempty(showStr)
    if showParentRoot then
        local showStrInfo = string.split(showStr, "=")
        local showType = tonumber(showStrInfo[1])
        local res = showStrInfo[2]
        if showType == 1 then
            local imgRoot = showInfo.imgRoot
            self:SetWndEasyImage(imgRoot, res, function()
                CS.ShowObject(imgRoot, true)
            end, true)
        elseif showType == 2 then
            local spineRoot = showInfo.spineRoot
            local spineKey = showInfo.spineKey or spineRoot:GetInstanceID()
            self:CreateWndSpine(spineRoot, res, spineKey, false, function()
                CS.ShowObject(spineRoot, true)
            end)
        end
        self:SetAnchorPos(parentRoot, LxDataHelper.ParseVector2NotEmpty(showInfo.showPos))
    end
    CS.ShowObject(parentRoot, showParentRoot)
end

------------------------------------------------------------------
---Slider
------------------------------------------------------------------
function LWnd:FindWndSlider(trans)
    return self:FindCommonComponent(trans, typeUISlider)
end

function LWnd:SetWndSliderPara(trans, value, minValue, maxValue, wholeNumber)
    local com = self:FindWndSlider(trans)
    if not CS.IsValidObject(com) then
        return
    end

    if minValue then
        com.minValue = minValue
    end

    if maxValue then
        com.maxValue = maxValue
    end

    if wholeNumber ~= nil then
        com.wholeNumbers = wholeNumber
    end

    if value then
        com.value = value
    end
end

function LWnd:SetWndSliderDelegate(trans, func)
    local com = self:FindWndSlider(trans)
    if not CS.IsValidObject(com) then
        return
    end
    local csEvent = com.onValueChanged
    csEvent:RemoveAllListeners()
    csEvent:AddListener(func)
end

------------------------------------------------------------------
--- wnd image
------------------------------------------------------------------

---@param item GameObject
function LWnd:FindInstanceID(item)
    local map = self._base_instanceIDMap
    if not map then
        return item:GetInstanceID()
    end
    local id = map[item]
    if not id then
        id = item:GetInstanceID()
        map[item] = id
        return id
    else
        return id
    end
end

function LWnd:RemoveInstanceIDMap()
    local map = self._base_instanceIDMap
    if not map then return end
    self._base_instanceIDMap = nil
    for k,v in pairs(map) do
        map[k] = nil
        k = nil
    end
end

function LWnd:FindWndImage(trans)
    return LxUiHelper.FindImageCtrl(trans)
end

function LWnd:SetWndImageGray(trans, isGray)
    LxUiHelper.SetImageGray(trans, isGray)
end

function LWnd:SetWndImageColor(trans, color)
    LxUiHelper.SetImageColor(trans, color)
end

function LWnd:SetActivityTitleImage(trans, type, func, isNativeSize, isHideLoad)
    local imgPath = LxUiHelper.GetActivityTitleImg(type)
    self:SetWndEasyImage(trans, imgPath, func, isNativeSize, isHideLoad)
end

function LWnd:SetActivityTextColor(trans, type)
    if not trans then
        return
    end
    LxUiHelper.SetActivityTextColor(trans, type)
end

function LWnd:SetWndEasyImage(trans, imgPath, func, isNativeSize, isHideLoad, rootTrans, defaultImgPath, isCountSize)
    if not self:IsWndValid() then return end
    if not self._ui_images then return end
    if string.isempty(imgPath) then return end

    local path = gLGameLanguage:GetResName(imgPath)
    local spriteAtlasPath = LxResPathUtil.GetSpriteAtlasPath(path)
    if not spriteAtlasPath then return end

    if self._wndSpriteAtlasList then
        self._wndSpriteAtlasList[spriteAtlasPath] = true
    end
    rootTrans = rootTrans or self._wndTrans
    local img = self:FindWndImage(trans)
    if not img then return end

    local id = self:FindInstanceID(img)
    local sprite = self._ui_images[id]
    if not sprite then
        sprite = require("LApp.component.res.LxSprite"):New(img)
        self._ui_images[id] = sprite
    end
    sprite:SetLoadedCallback(func)
    sprite:SetSprite(path, isNativeSize, isHideLoad, isCountSize)
end

function LWnd:ClearImages()
    if self._ui_images then
        for k, v in pairs(self._ui_images) do
            v:Dispose()
        end
        self._ui_images = nil
    end
end

function LWnd:ClearFonts()
    if self._ui_fonts then
        for k, v in pairs(self._ui_fonts) do
            v:Dispose()
        end
        self._ui_fonts = nil
    end
end

--function LWnd:PreloadImage(imgPath, func)
--    imgPath = gLGameLanguage:GetResName(imgPath)
--    local spriteAtlasPath = LxResPathUtil.GetSpriteAtlasPath(imgPath)
--
--    if not spriteAtlasPath then
--        return
--    end
--
--    if self._wndSpriteAtlasList then
--        self._wndSpriteAtlasList[spriteAtlasPath] = true
--    end
--
--    LxResPathUtil.Async_LoadUISprite(imgPath, func)
--end

function LWnd:SetWndSpriteRenderer(trans, imgPath, func)
    if string.isempty(imgPath) then return end

    local path = gLGameLanguage:GetResName(imgPath)
    local spriteAtlasPath = LxResPathUtil.GetSpriteAtlasPath(path)
    if not spriteAtlasPath then return end

    if self._wndSpriteAtlasList then
        self._wndSpriteAtlasList[spriteAtlasPath] = true
    end

    local img = trans:GetComponent(typeOfSpriteRenderer)
    if not img then return end

    local id = self:FindInstanceID(img)
    local sprite = self._ui_images[id]
    if not sprite then
        sprite = require("LApp.component.res.LxSprite"):New(img)
        self._ui_images[id] = sprite
    end
    sprite:SetLoadedCallback(func)
    sprite:SetSprite(path, false, true)
end

function LWnd:SetImageAlpha(trans, alpha)
    LxUiHelper.SetImageAlpha(trans, alpha)
end

function LWnd:ClearUIStateActors()
    if self._ui_state_actors then
        for k,v in pairs(self._ui_state_actors) do
            v:Dispose()
        end
        self._ui_state_actors = nil
    end
end
function LWnd:SetImageActorState(trans, state)
    if not self:IsWndValid() then return end
    local actor = trans:GetComponent(typeofYXUIStateActor)
    if not actor then return end
    local instanceId = self:FindInstanceID(actor)
    local stateactor = self._ui_state_actors[instanceId]
    if not stateactor then
        stateactor = require("LApp.component.res.LxStateActor"):New(actor)
        self._ui_state_actors[instanceId] = stateactor
        stateactor:InitLang()
    end
    stateactor:SetImageActorState(state)
end

------------------------------------------------------------------
--- wnd progress
------------------------------------------------------------------
function LWnd:UIProgressRemoveAll()
    local dicProgress = self._wndUIProgressList
    if dicProgress then
        for k, v in pairs(dicProgress) do
            v:CleanUp()
        end
        self._wndUIProgressList = nil
    end
end

function LWnd:UIProgressFind(obj, key, progress)
    local dicProgress = self._wndUIProgressList
    if not dicProgress then
        dicProgress = {}
        self._wndUIProgressList = dicProgress
    end
    local uiProgress = dicProgress[key]
    if uiProgress then
        return uiProgress
    end

    if not obj then
        return nil
    end

    uiProgress = UIProgress:New()
    dicProgress[key] = uiProgress
    uiProgress:Create(obj, progress)
    return uiProgress
end

------------------------------------------------------------------
--- wnd toggle
------------------------------------------------------------------

function LWnd:SetWndToggleValue(tran, value)
    local toggle = self:FindWndToggle(tran)
    if not CS.IsValidObject(toggle) then
        return
    end
    toggle.isOn = value
end

function LWnd:SetWndToggleDelegate(tran, func)
    local toggle = self:FindWndToggle(tran)
    if not CS.IsValidObject(toggle) then
        return
    end
    local csObj = toggle.onValueChanged
    csObj:RemoveAllListeners()
    csObj:AddListener(func)
end

function LWnd:FindWndToggle(trans)
    local toggle = self:FindCommonComponent(trans, typeUIToggle)
    return toggle
end

------------------------------------------------------------------
--- wnd inputfield
------------------------------------------------------------------
function LWnd:SetInputValueChange(inputField, func)
    if not CS.IsValidObject(inputField) then
        return
    end
    inputField.m_onInputChange = func
end

------------------------------------------------------------------
--- wnd inputfield
------------------------------------------------------------------
function LWnd:SetWndInputDelegate(trans, func)
    local com = self:FindTextInput(trans)
    if not CS.IsValidObject(com) then
        return
    end
    com.m_onInputChange = func
end

function LWnd:SetWndInput(trans, holdText, text)
    local com = self:FindTextInput(trans)
    if not CS.IsValidObject(com) then
        return
    end
    holdText = holdText or ""
    text = text or ""
    local textCom = com.textComponent
    self:SetWndText(textCom, text)
    local holderCom = com.placeholder.transform
    self:SetWndText(holderCom, holdText)
    com.text = text
end

function LWnd:SetWndInputLimit(trans, limit)
    if (not trans) then
        return
    end
    local com = self:FindTextInput(trans)
    if not CS.IsValidObject(com) then
        return
    end
    com.characterLimit = limit
end

function LWnd:FindTextInput(trans)
    return self:FindCommonComponent(trans, typeUITextInput)
end

function LWnd:FindCommonComponent(trans, typeComponent)
    local instanceId = trans:GetInstanceID()
    if not self._cacheComponentsMap then
        self._cacheComponentsMap = {}
    end
    local cacheComponents = self._cacheComponentsMap[typeComponent]
    if not cacheComponents then
        cacheComponents = {}
        self._cacheComponentsMap[typeComponent] = cacheComponents
    end
    local component = cacheComponents[instanceId]
    if CS.IsValidObject(component) then
        return component
    end
    component = trans:GetComponent(typeComponent)
    if CS.IsValidObject(component) then
        cacheComponents[instanceId] = component
    end

    return component
end

function LWnd:GetWndTextPreferHeight(trans)
    local com = self:FindCommonComponent(trans, typeUIText)
    if CS.IsValidObject(com) then
        return com.preferredHeight
    end
    return 0
end

function LWnd:SetCanvasGroupAlpha(trans, alpha)
    local com = self:FindCommonComponent(trans, typeofCanvasGroup)
    if CS.IsValidObject(com) then
        com.alpha = alpha
    end
end

function LWnd:GetCanvasGroup(trans)
    local com = self:FindCommonComponent(trans, typeofCanvasGroup)
    return com
end

------------------------------------------------------------------
--- wnd scroll
------------------------------------------------------------------
---@return UIItemList
function LWnd:FindUIScroll(key)
    local uiKeyList = self._uiKeyList
    if (not uiKeyList) then
        return nil
    end
    return uiKeyList[key]
end

---@return UIItemList
function LWnd:GetUIScroll(key)
    local uiKeyList = self._uiKeyList
    if (not uiKeyList) then
        ---@type table<number, UIItemList>
        self._uiKeyList = {}
        uiKeyList = self._uiKeyList
    end
    local uiList = uiKeyList[key]
    if not uiList then
        uiList = UIItemList:New(self)
        uiKeyList[key] = uiList
    end
    return uiList
end

function LWnd:FreezeUIScroll(bFrozen)
    if not self:IsChildWnd() then
        local childWndList = self:GetChildList()
        for k, v in pairs(childWndList) do
            v:FreezeUIScroll(bFrozen)
        end
    end

    if self._isFrozenUIScroll == bFrozen then
        return
    end
    self._isFrozenUIScroll = bFrozen

    local uiKeyList = self._uiKeyList
    if (not uiKeyList) then
        return
    end
    for k, v in pairs(uiKeyList) do
        v:Freeze(bFrozen)
    end
end

---@return table @ return a cache table
function LWnd:GetComponentCache(instanceId)
    local caches = self._componentCaches
    if not caches then
        caches = {}
        self._componentCaches = caches
    end
    return caches[instanceId]
end

function LWnd:SetComponentCache(instanceId, cache)
    local caches = self._componentCaches
    if not caches then
        caches = {}
        self._componentCaches = caches
    end
    caches[instanceId] = cache
end

function LWnd:ClearComponentCaches()
    local caches = self._componentCaches
    if not caches then
        return
    end
    for k, v in pairs(caches) do
        caches[k] = nil
        if type(v.Dispose) == 'function' then
            v:Dispose()
        end
    end
end

function LWnd:WndRemoveScrllByKey(key)
    if (not self._uiKeyList) then
        return
    end
    local uiList = self._uiKeyList[key]
    self._uiKeyList[key] = nil
    if uiList then
        uiList:Destroy()
    end
end

function LWnd:ClearAllUIList()
    LUtil.ClearHashTable(self._uiKeyList)
    self._uiKeyList = nil
end

---@return UIItemList
function LWnd:CreateUIScrollImpl(key, root, dataList, setFunc, listType)
    key = key or root:GetInstanceID()
    listType = listType or UIItemList.NORMAL
    local list = self:FindUIScroll(key)
    local isFirst = false
    if not list then
        list = self:GetUIScroll(key)
        list:Create(root, dataList, setFunc, listType)
        isFirst = true
    else
        list:RefreshList(dataList)
    end

    if listType == UIItemList.SUPER or listType == UIItemList.SUPER_GRID then
        list:DrawAllItems(isFirst)
    end

    return list
end

------------------------------------------------------------------
--- wnd CommonEmptyList
------------------------------------------------------------------
---@return CommonEmptyList
function LWnd:GetCommonEmptyList(key)
    local _uiCommonEmptyList = self._uiCommonEmptyList
    if (not _uiCommonEmptyList) then
        ---@type table<number, CommonEmptyList>
        _uiCommonEmptyList = {}
        self._uiCommonEmptyList = _uiCommonEmptyList
    end
    local uiList = _uiCommonEmptyList[key]
    if not uiList then
        uiList = CommonEmptyList:New(self)
        _uiCommonEmptyList[key] = uiList
    end
    return uiList
end

function LWnd:ClearAllCommonEmptyList()
    LUtil.ClearHashTable(self._uiCommonEmptyList)
    self._uiCommonEmptyList = nil
end

------------------------------------------------------------------------------


------------------------------------------------------------------
function LWnd:WndMusicPlay()
    local wndName = self:GetWndName()

    local ref = GameTable.SoundEffectSceneRef[wndName]
    local musicName
    if ref then
        musicName = ref.soundName
    end
    if string.isempty(musicName) then
        return
    end
    if gLGameAudio then
        self._musicName = musicName
        gLGameAudio:OnPlayWndMusic(musicName, wndName)
    end
end

function LWnd:WndMusicClose()
    if not string.isempty(self._musicName) then
        if gLGameAudio then
            gLGameAudio:OnCloseWndMusic(self:GetWndName())
        end
    end
end

-----------------------------------------------------------------
function LWnd:ClearCommonIconList(list)
    LUtil.ClearHashTable(list)
end

-----------------------------------------------------------------
function LWnd:SetHideHurdle(bHide)
    --隐藏侧边栏
    if bHide == nil then
        bHide = true
    end
    self._isHurdleHide = bHide
    --FireEvent(EventNames.SHOW_MAIN_HURDLE,false)

    gLGameUI:CheckShowHurdle()
end

function LWnd:IsHideHurdle()
    return self._isHurdleHide or false
end

function LWnd:SetHideTop(bHide)
    --隐藏顶部条
    if bHide == nil then
        bHide = true
    end
    self._isTopHide = bHide
    --FireEvent(EventNames.SHOW_MAIN_TOP,false)

    gLGameUI:CheckShowMainTop()
end

function LWnd:IsHideTop()
    return self._isTopHide or false
end

function LWnd:SetHideBottom(bHide)
    --隐藏底部条
    if bHide == nil then
        bHide = true
    end
    self._isBottomHide = bHide
    --FireEvent(EventNames.SHOW_MAIN_BOTTOM,false)
    gLGameUI:CheckShowMainBottom()
end

function LWnd:IsHideBottom()
    return self._isBottomHide or false
end

function LWnd:SetHideActScroll(isHide)
    self._isActScrollHide = isHide == nil and true or isHide
    --FireEvent(EventNames.SHOW_MAIN_ACTSCROLL,not self._isActScrollHide)

    gLGameUI:CheckShowActScroll()
end

function LWnd:IsActScrollHide()
    return self._isActScrollHide or false
end

function LWnd:IsShowGrade()
    return self._isShowGrade or false
end

function LWnd:GetPlayModuleBelong()
    return LPlayModuleConst.NONE
end

-----------------------------------------------------------------
function LWnd:InitSensitiveRes()
    if not gLGameTable or not gLGameTable:IsSensitive() then
        return
    end
    if CS.IsNullObject(self._wndTrans) or not gLGameLanguage:IsDefaultLangVersion() then
        return
    end
    local imageNode = nil
    local spriteResName = nil
    local langResName = nil
    local imageNodes = self._wndTrans:GetComponentsInChildren(typeUIImage, true)
    local nodeLen = imageNodes.Length
    local isNativeSize
    for k = 1, nodeLen do
        imageNode = imageNodes[k - 1]
        if imageNode and CS.IsValidObject(imageNode.sprite) then
            spriteResName = imageNode.sprite.name
            langResName, isNativeSize = gLGameLanguage:GetResName(spriteResName)
            if spriteResName ~= langResName then
                self:SetWndEasyImage(imageNode.transform, langResName, nil, isNativeSize)
            end
        end
    end
end

----------------------------------------------------------------
-- Mult Language
function LWnd:InitWndLanguage()
    if gLGameLanguage:IsDefaultLangVersion() then
        return
    end

    local wndName = self:GetWndName()
    local langNodes = gLGameLanguage:GetWndLanguageNodes(wndName)
    if not langNodes then
        if gLGameLanguage:IsAutoLanguage(wndName) then
            self:AutoInitWndLanguage()
        end

        return
    end
    local langTag = gLGameLanguage:GetLanguageFlag()
    local langNodeTrans = nil
    local langNodeImage = nil
    local langResName = nil
    local isNativeSize = nil
    for idx, wndNodeItem in ipairs(langNodes) do
        langNodeTrans = self:FindWndTrans(nil, wndNodeItem.uiPath)
        langNodeImage = LxUiHelper.FindImageCtrl(langNodeTrans)
        if langNodeImage and CS.IsValidObject(langNodeImage.sprite) then
            langResName, isNativeSize = gLGameLanguage:GetResName(langNodeImage.sprite.name)
            if not string.isempty(langResName) then
                self:SetWndEasyImage(langNodeTrans, langResName, nil, isNativeSize)
            end
        end
    end
end

function LWnd:InitWndLanguageText()
    if gLGameLanguage:IsChinaRegion() or gLGameLanguage:IsHmtRegion() then
        return
    end
    --国内，港澳台不需要设置多语言文本

    local wndName = self:GetWndName()
    local langRefList = gLGameLanguage:GetTextRefByWndName(wndName)
    if not langRefList then
        return
    end
    local curLanguageFlag = gLGameLanguage:GetLanguageFlag()
    if not curLanguageFlag then
        return
    end
    for idx, ref in ipairs(langRefList) do
        local flagIndex = ref[curLanguageFlag] or 0
        if flagIndex == 1 then
            local textPath = ref.textPath
            if not string.isempty(textPath) then
                local textTrans = self:FindWndTrans(self._wndTrans, textPath)
                if CS.IsValidObject(textTrans) then
                    local uiText = self:FindCommonComponent(textTrans, typeUIText)
                    if CS.IsValidObject(uiText) then
                        local size = ref.size
                        if size and size ~= 0 then
                            uiText.fontSize = size
                        end

                        local spacing = ref.spacing
                        if spacing and spacing ~= 0 then
                            uiText.enableWordWrapping = true
                            uiText.lineSpacing = spacing
                        end

                        local alignment = ref.alignment
                        if alignment and alignment ~= 0 then
                            local alignmentEnum = LxUiHelper.GetTMPAlignment(alignment)
                            if alignmentEnum then
                                uiText.alignment = alignmentEnum
                            end
                        end

                        local character = ref.character
                        if character then
                            uiText.characterSpacing = character
                        end
                    end

                    local textPos = ref.textPos
                    if not string.isempty(textPos) then
                        self:SetAnchorPos(textTrans, LxDataHelper.ParseVector2NotEmpty3(textPos))
                    end
                end
            end
        end
    end
end

-- 策划懒得配置，才加的这个效率低的自动查找
function LWnd:AutoInitWndLanguage()
    if CS.IsNullObject(self._wndTrans) or gLGameLanguage:IsDefaultLangVersion() then
        return
    end
    local imageNode = nil
    local spriteResName = nil
    local langResName = nil
    local imageNodes = self._wndTrans:GetComponentsInChildren(typeUIImage, true)
    local nodeLen = imageNodes.Length
    local isNativeSize
    for k = 1, nodeLen do
        imageNode = imageNodes[k - 1]
        if imageNode and CS.IsValidObject(imageNode.sprite) then
            spriteResName = imageNode.sprite.name
            langResName, isNativeSize = gLGameLanguage:GetResName(spriteResName)
            if spriteResName ~= langResName then
                self:SetWndEasyImage(imageNode.transform, langResName, nil, isNativeSize)
            end
        end
    end
end

function LWnd:InitNodeLanguage(trans)
    ---要频闭处理的 一定要去处理一下图片
    local bSensitive = gLGameTable and gLGameTable:IsSensitive()
    if not bSensitive then
        if CS.IsNullObject(trans) or gLGameLanguage:IsDefaultLangVersion() then
            return
        end
    end
    local imageNode = nil
    local spriteResName = nil
    local langResName = nil
    local imageNodes = trans:GetComponentsInChildren(typeUIImage, true)
    local nodeLen = imageNodes.Length
    local isNativeSize
    for k = 1, nodeLen do
        imageNode = imageNodes[k - 1]
        if imageNode and CS.IsValidObject(imageNode.sprite) then
            spriteResName = imageNode.sprite.name
            langResName, isNativeSize = gLGameLanguage:GetResName(spriteResName)
            if spriteResName ~= langResName then
                self:SetWndEasyImage(imageNode.transform, langResName, nil, isNativeSize)
            end
        end
    end
end

-- 根据语言类型是否要缩小字号
function LWnd:InitTextSizeWithLanguage(trans, addSize)
    if (not trans) then
        return
    end
    trans = trans.transform
    addSize = addSize or 0
    if gLGameLanguage:IsForeignVersion() then
        local uiText = LxUiHelper.FindXTextCtrl(trans)
        if (uiText) then
            self._textFontSizeMap = self._textFontSizeMap or {}
            local instanceId = trans:GetInstanceID()
            local fontSize = self._textFontSizeMap[instanceId]
            if not fontSize then
                fontSize = uiText.fontSize
                self._textFontSizeMap[instanceId] = fontSize
            end
            uiText.fontSize = fontSize + addSize
        end
    end
end

-- 根据语言类型是否要缩略显示文本
function LWnd:InitTextModeWithLanguage(trans, clickFunc, isForce)
    if (not trans) then
        return
    end
    trans = trans.transform
    --后面走配表
    if gLGameLanguage:IsForeignVersion() or isForce then
        LxUiHelper.SetXTextOverflowMode(trans, 1)

        local fontSize
        local uiText = LxUiHelper.FindXTextCtrl(trans)
        if (uiText) then
            if fontSize then
                uiText.fontSize = fontSize
            end
            local content = uiText.text
            local clickNode = CS.NewObject(trans.name .. "_click", trans)
            clickNode:SetAsFirstSibling()
            local clickTrans = clickNode.gameObject:AddComponent(typeRectTransform)
            local rawImage = clickTrans.gameObject:AddComponent(typeofRawImage)
            local parentTrans = trans:GetComponent(typeRectTransform)

            rawImage.color = Color.New(0, 0, 0, 0)
            clickTrans.sizeDelta = parentTrans.sizeDelta
            clickTrans.localPosition = Vector3.zero

            self:SetWndClick(trans, function(...)
                if clickFunc ~= nil then
                    clickFunc()
                else
                    GF.OpenWndUp("UIUITexhjTips", { title = ccClientText(21307), para = {}, text = content })
                end
            end)
        end
    end
end

function LWnd:InitTextShowWithLanguage(trans)
    local isForeign = gLGameLanguage:IsForeignRegion()
    if (not trans) then
        return
    end
    --后面走配表
    if isForeign then
        local uiText = LxUiHelper.FindXTextCtrl(trans)
        if CS.IsValidObject(uiText) then
            uiText.color = Color.New(0, 0, 0, 0)
        end
    end
end

-- 根据语言类型是否要缩小行距
function LWnd:InitTextLineWithLanguage(trans, addLine, notWrap)
    if (not trans) then
        return
    end
    trans = trans.transform
    addLine = addLine or 0
    if gLGameLanguage:IsForeignVersion() then
        local uiText = LxUiHelper.FindXTextCtrl(trans)
        if (uiText) then
            self._textLineSpacingMap = self._textLineSpacingMap or {}
            local instanceId = trans:GetInstanceID()
            local lineSpacing = self._textLineSpacingMap[instanceId]
            if not lineSpacing then
                lineSpacing = uiText.lineSpacing
                self._textLineSpacingMap[instanceId] = lineSpacing
            end
            uiText.enableWordWrapping = notWrap == nil and true or notWrap
            uiText.lineSpacing = lineSpacing + addLine
        end
    end
end

-- 根据语言类型是否要缩小间距
function LWnd:InitTextCharacterWithLanguage(trans, addCharacter)
    if (not trans) then
        return
    end
    trans = trans.transform
    addCharacter = addCharacter or 0
    if gLGameLanguage:IsForeignVersion() then
        local uiText = LxUiHelper.FindXTextCtrl(trans)
        if (uiText) then
            self._textCharacterSpacingMap = self._textCharacterSpacingMap or {}
            local instanceId = trans:GetInstanceID()
            local characterSpacing = self._textCharacterSpacingMap[instanceId]
            if not characterSpacing then
                characterSpacing = uiText.characterSpacing
                self._textCharacterSpacingMap[instanceId] = characterSpacing
            end
            uiText.characterSpacing = characterSpacing + addCharacter
        end
    end
end

-----------------------------------------------------------------
function LWnd:DisableInputText(inputObj)
    if not self:IsInputMask() then
        return
    end
    if CS.IsNullObject(inputObj) then
        return
    end
    inputObj.enabled = false
    self:SetWndClick(inputObj.transform, function()
        GF.ShowMessage(ccClientText(10160))
    end)
end

function LWnd:DisableSensitiveInputText(inputObj, sensitiveType)
    local sensitive = gModelPlayer:GetChatForbid(sensitiveType)
    if sensitive then
        return
    end
    if CS.IsNullObject(inputObj) then
        return
    end
    inputObj.enabled = false
    self:SetWndClick(inputObj.transform, function()
        GF.ShowMessage(ccClientText(30801))
    end)
end

function LWnd:IsInputMask()
    return LWnd.MASK_INPUT_STATUS == 0
end

---@return HeadIcon
function LWnd:GetHeadIcon(instanceId)
    if not self._wndHeadIcons then
        ---@type table<number, HeadIcon>
        self._wndHeadIcons = {}
    end
    local heroIcon = self._wndHeadIcons[instanceId]
    if heroIcon then
        return heroIcon
    end
    heroIcon = HeadIcon:New(self)
    self._wndHeadIcons[instanceId] = heroIcon
    return heroIcon
end

function LWnd:ClearAllHeadIcons()
    LUtil.ClearHashTable(self._wndHeadIcons)
    self._wndHeadIcons = nil
end

--[[
	trans,
	icon,
	headFrame,
	level,
	noLv,
	func,
]]
function LWnd:CreateHeadIconImpl(playerInfo)
    local headTran = playerInfo.trans
    local instanceId = headTran:GetInstanceID()
    local baseClass = self:GetHeadIcon(instanceId)
    baseClass:SetHeadData(playerInfo)
    baseClass:RefreshUI()

    self:SetWndClick(headTran, function()
        if playerInfo.func then
            playerInfo.func()
        end
    end)
end

---@return CommonIcon
function LWnd:GetCommonIcon(instanceId)
    if not self._wndCommonIcons then
        ---@type table<number, CommonIcon>
        self._wndCommonIcons = {}
    end

    local isNew = false
    local commonIcon = self._wndCommonIcons[instanceId]
    if commonIcon then
        return commonIcon, isNew
    end

    isNew = true
    commonIcon = CommonIcon:New(self)
    self._wndCommonIcons[instanceId] = commonIcon
    return commonIcon, isNew
end

function LWnd:DeleteCommonIcon(instanceId)
    if not self._wndCommonIcons then
        return
    end
    local baseClass = self._wndCommonIcons[instanceId]
    if not baseClass then
        return
    end

    baseClass:Destroy()
    self._wndCommonIcons[instanceId] = nil
end

function LWnd:CreateCommonIconImpl(root, itemdata, extraData,paramsData)
    local instanceId = root:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(root)
    baseClass:SetCommonItemdata(itemdata)
    extraData = extraData or {}
    paramsData = paramsData or {}
    local showNum = extraData.showNum
    if showNum == nil then
        showNum = true
    end
    baseClass:EnableShowNum(showNum)

    local showBg = extraData.showBg
    if showBg == nil then
        showBg = true
    end
    baseClass:EnableShowBg(showBg)

    local checkActive = extraData.checkActive
    if checkActive then
        baseClass:RefreshActiveShow()
    end

    if extraData.showOver ~= nil then
        baseClass:EnableShowOver(extraData.showOver)
    end

    local showGou = extraData.showshowGou

    if showGou then
        baseClass:ShowGouImg(true)
    end
    baseClass:DoApply()

    if extraData.noClick then
        return
    end

    local clickFunc = extraData.clickFunc
    if clickFunc == nil then
        clickFunc = function()
            gModelGeneral:ShowCommonItemTipWnd(itemdata,paramsData)
        end
    end

    self:SetWndClick(root, clickFunc)
    local addClickScale = extraData.addClickScale
    if addClickScale == nil then
        addClickScale = true
    end
    if addClickScale then
        self:SetIconClickScale(root, true)
    end


end

function LWnd:CreateHeroIconImpl(root, herodata)
    local instanceId = root:GetInstanceID()
    local heroIcon = self:GetCommonIcon(instanceId)
    heroIcon:Create(root)
    heroIcon:SetHeroDataSet(herodata)
    heroIcon:DoApply()

    if herodata.clickFunc then
        self:SetWndClick(root, herodata.clickFunc)
        self:SetIconClickScale(root, true)
    end

    return instanceId
end

--【C宠物系统】删掉宠物系统相关
-- function LWnd:CreatePetIconImpl(root,petdata,extraData)
-- 	local instanceId = root:GetInstanceID()
-- 	local petIcon = self:GetCommonIcon(instanceId)
-- 	petIcon:Create(root)
-- 	petIcon:SetPetDataSet(petdata)
-- 	petIcon:SetShowSelectImg(false)

-- 	if extraData then
-- 		petIcon:SetShowDissimilation(extraData.showDissi)
-- 	end

-- 	petIcon:DoApply()

-- 	if petdata.clickFunc then
-- 		self:SetWndClick(root,petdata.clickFunc)
-- 		self:SetIconClickScale(root, true)
-- 	end

-- 	return instanceId
-- end

function LWnd:CreateCommonIconInter(root, heroId, extra)
    local heroSeverData = gModelHero:GetHeroServerDataById(heroId)
    if not heroSeverData then
        return
    end
    local refId = heroSeverData.refId
    local isResonance = heroSeverData.isResonance
    local star, lv = heroSeverData.star, heroSeverData.lv
    local skin = heroSeverData.skin
    local treeInfo = heroSeverData.treeInfo
    local endTime = heroSeverData.endTime
    local isTry = heroSeverData.isTry

    local heroPara = {
        id = heroId,
        refId = refId,
        star = star,
        level = lv,
        isResonance = isResonance,
        skin = skin,
        treeInfo = treeInfo,
        endTime = endTime,
        isTry = isTry,
        fightPower = heroSeverData.fightPower,
        showTire = extra and extra.showTire,
        form = heroSeverData.form,
    }

    local playerId = gModelPlayer:GetPlayerId()
    heroPara.clickFunc = function()
        gModelHero:ReqShowHeroTip(playerId, heroPara)
    end

    return self:CreateHeroIconImpl(root, heroPara)
end

function LWnd:FindCommonIcon(instanceId)
    if not self._wndCommonIcons then
        return
    end
    local commonIcon = self._wndCommonIcons[instanceId]
    return commonIcon
end

---@return SequenceCom
function LWnd:GetSeqCom()
    if not self._seqCom then
        self._seqCom = SequenceCom:New()
    end

    return self._seqCom
end

function LWnd:ClearSeqCom()
    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end
end

function LWnd:GetPrivilegeCom()
    if self._privilegeCom then
        return self._privilegeCom
    end

    self._privilegeCom = PrivilegeCom:New()
    return self._privilegeCom
end

function LWnd:GetActivityPrivilegeCom()
    if self._activityPrivilegeCom then
        return self._activityPrivilegeCom
    end
    self._activityPrivilegeCom = ActivityPrivilegeCom:New()
    return self._activityPrivilegeCom
end

function LWnd:ClearAllCommonIcon()
    LUtil.ClearHashTable(self._wndCommonIcons)
    self._wndCommonIcons = nil
end

function LWnd:EnableClickNotUICall()
    if not gLGameTouch then
        return
    end
    if self._isAddClickNotUiCall then
        return
    end
    self._isAddClickNotUiCall = true

    self._clickNoUiFunc = function(screenPos)
        local touchObject = CS.YXTouchManager.EventSystemRaycastGameObject(screenPos)
        local name = touchObject and touchObject.name
        self:OnClickNotUI(name)

        self:OnClickNotObj(touchObject)
    end
    local op = LGameTouch.TOUCH_NOT_UI
    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_START, self._clickNoUiFunc)
end

function LWnd:ClearNotUICallListen()
    if not self._isAddClickNotUiCall then
        return
    end
    if gLGameTouch then
        gLGameTouch:TouchUnRegisterEx(LGameTouch.TOUCH_NOT_UI, LGameTouch.TOUCH_EVT_START, self._clickNoUiFunc)
    end
end

function LWnd:OnClickNotUI(name)

end

function LWnd:OnClickNotObj(obj)

end

---@return UIHyperText
function LWnd:GetUIHyperText(tran)
    local instanceId = tran:GetInstanceID()
    if not self._wndHyperMap then
        self._wndHyperMap = {}
    end

    local hyper = self._wndHyperMap[instanceId]
    if not hyper then
        hyper = UIHyperText:New()
        self._wndHyperMap[instanceId] = hyper
    end
    hyper:Create(tran)
    return hyper
end

function LWnd:FindUIHyperText(tran)
    if not self._wndHyperMap then
        return
    end
    local instanceId = tran:GetInstanceID()
    return self._wndHyperMap[instanceId]
end

function LWnd:ClearAllHyperText()
    if not self._wndHyperMap then
        return
    end

    for k, v in ipairs(self._wndHyperMap) do
        v:Destroy()
    end

    self._wndHyperMap = nil
end

---@return UIHeroRaceList
function LWnd:GetUIHeroRaceList(data)
    local wndHeroRaceMap = self._wndHeroRaceMap
    if not wndHeroRaceMap then
        wndHeroRaceMap = {}
        self._wndHeroRaceMap = wndHeroRaceMap
    end
    local listTrans = data.listTrans
    local instanceId = listTrans:GetInstanceID()
    local heroRaceList = wndHeroRaceMap[instanceId]
    if not heroRaceList then
        heroRaceList = UIHeroRaceList:New()
        wndHeroRaceMap[instanceId] = heroRaceList
    end
    heroRaceList:Create(data)
    return heroRaceList
end

function LWnd:FindUIHeroRaceList(listTrans)
    if not self._wndHeroRaceMap then
        return
    end
    local instanceId = listTrans:GetInstanceID()
    return self._wndHeroRaceMap[instanceId]
end

function LWnd:ClearUIHeroRaceList()
    if not self._wndHeroRaceMap then
        return
    end

    for k, v in pairs(self._wndHeroRaceMap) do
        v:Destroy()
    end

    self._wndHeroRaceMap = nil
end

function LWnd:SetBtnImageAndMat(tran, image, textTran, isNativeSize)
    self:SetWndEasyImage(tran, image, nil, isNativeSize)

    if textTran then
        local matName = LUtil.GetOutlineMatByImg(image)
        if matName then
            self:SetWndTextMat(textTran, matName)
        end
    end
end

function LWnd:ScrollWndList(key, index)
    local itemList = self:GetUIScroll(key)
    if itemList then
        itemList:MoveToPos(index)
    end

    self:DelaySendFinish(0.2)
end

function LWnd:SetColorBtnImg(btnTran, btnType)
    local imagePath = LUtil.GetBtnImg(btnType)
    self:SetWndEasyImage(btnTran, imagePath)
    local textTran = self:FindWndTrans(btnTran, "Text")
    if textTran then
        local matName = LUtil.GetOutlineMatByImg(imagePath)
        if matName then
            self:SetWndTextMat(textTran, matName)
        end
    end
end

function LWnd:IsAutoLangFont()
    return true
end

function LWnd:InitLanguageGridLayout(tran, size)
    local isForeign = gLGameLanguage:IsForeignVersion()
    if not isForeign then
        return
    end
    local typeofLoopGridView = typeof(SuperScrollView.LoopGridView)
    if not typeofLoopGridView then
        return
    end

    local gridView = tran:GetComponent(typeofLoopGridView)
    if not CS.IsValidObject(gridView) then
        return
    end

    local para = SuperScrollView.LoopGridViewSettingParam()
    para.mItemSize = size
    gridView:UpdateFromSettingParam(para)
end

function LWnd:InitULayoutByLanguage(tran, padding)
    if not CS.IsValidObject(tran) then
        return
    end
    local isForeign = gLGameLanguage:IsForeignVersion()
    if not isForeign then
        return
    end
    LxUiHelper.SetLayoutPadding(tran, padding)
end

---点击文本非超链接区域，旧版无效
function LWnd:SetNormalTextClick(tran, func)
    LxUiHelper.SetNormalTextClick(tran, func)
end

---设置网络图片
function LWnd:SetTextureData(tran, data)
    local com = self:FindCommonComponent(tran, typeofYXTextureImage)
    LxUiHelper.SetTextureData(com, data)
end

function LWnd:SetImageBySrc(tran, srcTran)
    local image = self:FindCommonComponent(tran, typeUIImage)
    local srcImage = self:FindCommonComponent(srcTran, typeUIImage)
    if CS.IsValidObject(image) and CS.IsValidObject(srcImage) then
        image.sprite = srcImage.sprite
    end
end

function LWnd:GetUIImage(tran)
    return self:FindCommonComponent(tran, typeUIImage)
end

-----------------------------------------------------------------
-----------------------------------------------------------------
local WNDLAYER_FORCE = {
    ["UITop"] = true,
    ["UIUp"] = true,
    ["UIBottom"] = true,
}

local WND_MAINCITY_NAME = "UIMCity"

function LWnd:GetPropertyOrderInLayer()
    return self._propertyOrderInLayer or 0
end

function LWnd:IsUIMCity()
    return self._isUIMCity
end

function LWnd:IsUnderMainCity()
    return self._isUnderMainCity
end

--- wnd properties setting
function LWnd:InitProperties()
    local propertiesList = GameTable.UIWindowPropertiesRef
    if not propertiesList then
        return
    end

    local wndName = self:GetWndName()
    local properties = propertiesList[wndName]
    self._wndProperties = properties

    local sortLayer = self:GetWndSortLayer()
    local async = true
    local propertyOrderInLayer = 0
    local adjustType = 0
    local underMainCity = false
    local hideHurdle = false
    local hideBottom = false
    local hideTop = false
    local hideActScroll = false

    if properties then
        sortLayer = properties.sortLayer
        async = properties.syncLoad == 0
        propertyOrderInLayer = properties.orderInLayer
        adjustType = properties.adjustType
        underMainCity = (properties.underMainCity == 1)
        --if underMainCity then
        hideHurdle = (properties.hideHurdle == 1)
        hideBottom = (properties.hideBottom == 1)
        hideTop = (properties.hideTop == 1)
        hideActScroll = (properties.hideActScroll == 1)
        --end
    end

    -- 除了特殊作用的层级,其余都改成UIWnd
    if string.isempty(sortLayer) then
        sortLayer = "UIWnd"
    end
    if WNDLAYER_FORCE[sortLayer] then
        sortLayer = "UIWnd"
    end

    self:SetAutoAdjustNotch(adjustType)
    self:SetWndAsync(async)
    self:SetWndSortLayer(sortLayer)

    -- if wndName == "UIBlockMiniGame" then
    -- 	--todo:测试用，后续删除
    -- 	underMainCity = true
    -- 	hideHurdle = true
    -- 	hideBottom = true
    -- 	hideTop = true
    -- 	hideActScroll = true
    -- end

    if underMainCity then
        self:SetHideHurdle(hideHurdle)
        self:SetHideBottom(hideBottom)
        self:SetHideTop(hideTop)
        self:SetHideActScroll(hideActScroll)
    else
        --引导层的界面也会影响主城边栏 顶部栏等设定
        if hideHurdle then
            self:SetHideHurdle(hideHurdle)
        end
        if hideBottom then
            self:SetHideBottom(hideBottom)
        end
        if hideTop then
            self:SetHideTop(hideTop)
        end
        if hideActScroll then
            self:SetHideActScroll(hideActScroll)
        end
    end

    self._isUIMCity = (wndName == WND_MAINCITY_NAME)
    self._isUnderMainCity = underMainCity
    self._propertyOrderInLayer = propertyOrderInLayer
end

---无缓存获取
function LWnd:GetReportTable(reportInfo)
    local reportData = {
        reportId = reportInfo.reportId,
        serverId = reportInfo.serverId or gLGameLogin:GetActualServerId(),
        callback = reportInfo.callback,
        failCall = reportInfo.failCall,
    }

    if not reportData.serverId then
        LogError(string.format("report serverId is nil"))
        return
    end

    local key = string.format("%s/%s", reportData.reportId, reportData.serverId)
    reportData.key = key

    local getterList = self._getterList
    if not getterList then
        getterList = {}
        self._getterList = getterList
    end

    local getter = getterList[key]
    if getter then
        if getter:CanReplace() then
            getter:Destroy()
        else
            return ---防止频繁请求
        end
    end
    getter = LFightReportGetter:New()
    getterList[key] = getter
    getter:Start(reportData)
end

function LWnd:ClearReportGetter()
    if not self._getterList then
        return
    end

    for k, v in pairs(self._getterList) do
        v:Destroy()
    end

    self._getterList = nil
end

---有缓存获取
function LWnd:GetReportTableCache(reportInfo)
    local reportData = {
        reportId = reportInfo.reportId,
        serverId = reportInfo.serverId or gLGameLogin:GetActualServerId(),
        callback = reportInfo.callback,
        failCall = reportInfo.failCall,
    }
    local key = string.format("%s/%s", reportData.reportId, reportData.serverId)
    reportData.key = key

    local getterList = self._getterList
    if not getterList then
        getterList = {}
        self._getterList = getterList
    end

    local getter = getterList[key]
    if not getter then
        getter = LFightReportGetter:New()
        getterList[key] = getter

        self:CheckRemoveReportCache()
    end

    getter:Start(reportData)
end

function LWnd:CheckRemoveReportCache()
    if not self._getterList then
        return
    end

    local list = {}
    for k, v in pairs(self._getterList) do
        table.insert(list, v)
    end

    local cnt = #list
    if cnt <= 30 then
        return
    end

    table.sort(list, function(a, b)
        return a:GetStartTime() > b:GetStartTime()
    end)
    local removeCnt = cnt - 30
    for k = 1, removeCnt do
        local getter = table.remove(list)
        local key = getter:GetKey()
        self._getterList[key] = nil
        getter:Destroy()
    end
end

function LWnd:FindReportTable(reportInfo)
    if not self._getterList then
        return
    end
    local reportData = {
        reportId = reportInfo.reportId,
        serverId = reportInfo.serverId or gLGameLogin:GetActualServerId(),
        callback = reportInfo.callback,
        failCall = reportInfo.failCall,
    }
    local key = string.format("%s/%s", reportData.reportId, reportData.serverId)
    local getter = self._getterList[key]
    if not getter then
        return
    end

    return getter:GetReportTable()
end

---需要高于LGameUI.ABOVE_RESULT_WND_LIST 的弹窗
function LWnd:IsAboveWnd()
    local isAboveWnd = self:GetWndArg("_isAboveWnd")
    return isAboveWnd
end

function LWnd:IsBelowSpecial()
    local isBelow = self:GetWndArg("_isBelowWnd")
    local specialJudge = self:GetWndArg("_specialJudge")
    return isBelow, specialJudge
end

function LWnd:ExecuteBtnFunc(btnName)
    local arg = string.format("m%s", string.gsub(btnName, "^%l", string.upper))
    local com = self[arg]
    if not com then
        return
    end

    local func = LxUiHelper.GetClickDelegate(com.gameObject, 1)
    func()
end

function LWnd:SetSecretJumpBtn(tran, refId)
    local dataMap = gModelActivity:GetSecretJumpBtns()
    local data = dataMap[refId]
    local has = data ~= nil
    CS.ShowObject(tran, has)
    if not has then
        self:SetWndClick(tran, function()
        end)
        return
    end
    local imgTran = self:FindWndTrans(tran, "Image")
    if not string.isempty(data.image) then
        self:SetWndEasyImage(imgTran, data.image)
    end

    self:SetTextTile(tran, ccClientText(data.textId))
    self:SetWndClick(tran, function()
        GF.OpenWnd("UISecop", data)
    end)
end

function LWnd:ShowActivityHero(root, res, pos)
    local strs = string.split(res, '=')
    local imageRoot = self:FindWndTrans(root, "roleImage")
    local spineRoot = self:FindWndTrans(root, "roleSpine")
    CS.ShowObject(imageRoot, false)
    CS.ShowObject(spineRoot, false)

    self:DestroyWndSpineByKey("_act_top_role")
    if #strs >= 2 then
        local roleType = tonumber(strs[1])
        local roleRes = strs[2]
        if roleType == 1 then
            self:SetWndEasyImage(imageRoot, roleRes, function()
                CS.ShowObject(imageRoot, true)
            end, true)
        else
            CS.ShowObject(spineRoot, true)
            self:CreateWndSpine(spineRoot, roleRes, "_act_top_role")
        end
    end

    if not string.isempty(pos) then
        self:SetAnchorPos(root, LxDataHelper.ParseVector2NotEmpty(pos))
    end
end

-- 简单列表
function LWnd:SetComList(root, dataList, drawItemCall)
    local instanceID = root:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        local trans = CS.FindTrans(root, "item")
        if not LxUnity.IsValidObject(trans) then
            trans = CS.FindTrans(root, "content/item")
        end
        if not LxUnity.IsValidObject(trans) then
            LogError(string.format("item 节点找不到"))
            return
        end

        itemCache.parent = trans.parent
        itemCache.obj = trans.gameObject
        itemCache.uiList = {}
        CS.ShowObject(trans, false)
        self:SetComponentCache(instanceID, itemCache)
    end

    if not itemCache.uiList then
        return
    end

    for k, data in ipairs(dataList) do
        local uiList = itemCache.uiList[k]
        if not uiList then
            local obj = CS.InstantObject(itemCache.obj)
            local trans = obj.transform
            trans:SetParent(itemCache.parent, false)
            uiList = drawItemCall(nil, trans, data, k)
            uiList.trans = trans
            itemCache.uiList[k] = uiList
        else
            drawItemCall(uiList, uiList.trans, data, k)
        end
        uiList.trans.name = k
        CS.ShowObject(uiList.trans, true)
    end
    for i = #dataList + 1, #itemCache.uiList do
        CS.ShowObject(itemCache.uiList[i].trans, false)
    end
end

-- 通用星星 -- ComStar
function LWnd:SetComStar(root, startNum, needAlignment, showTxt,bVertical)
    --[[ 不适用
    local instanceID = root:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        local trans = CS.FindTrans(root, "item")
        itemCache.parent = trans.parent
        itemCache.obj = trans.gameObject
        itemCache.uiList = {}
        CS.ShowObject(trans, false)
        self:SetComponentCache(instanceID, itemCache)

        itemCache.Dispose = function()
            for _, uiData in ipairs(itemCache.uiList) do
                CS.DestroyObject(uiData.trans.gameObject)
            end
        end
    end

    for i = 1, #itemCache.uiList do
        CS.ShowObject(itemCache.uiList[i].trans, false)
    end
    --]]

    local FindTrans = CS.FindTrans
    local ShowObject = CS.ShowObject

    local starNode = FindTrans(root, "item")
    if not starNode then
        starNode = FindTrans(root.parent, "item")
    else
        starNode:SetParent(root.parent, false)
    end
    if not starNode then
        return
    end

    ShowObject(starNode, false)

    local parent     = root
    local childCount = parent.childCount
    for i = 0, childCount - 1 do
        local child = parent:GetChild(i)
        ShowObject(child, false)
    end

    local ref = GameTable.StarManagerRef[startNum]
    if not ref then
        -- LogError(string.format("StarRef[%s] 为空", tostring(startNum)))
        return
    end
    local showNum    = ref.num
    local iconPath   = ref.icon
    local strStar    = "star"
    if showNum <= childCount then
        for i = 0, childCount - 1 do
            local child = parent:GetChild(i)
            if i < showNum then
                local star = FindTrans(child, strStar)
                self:SetWndEasyImage(star, iconPath, nil, true)
                ShowObject(child, true)

                if i == showNum - 1 and showTxt then
                    self:SetTextTile(star, "(" .. startNum .. ")")
                else
                    self:SetTextTile(star, "")
                end

            else
                break
            end
        end
    else
        for i = 0, showNum - 1 do
            local child
            if i < childCount then
                child = parent:GetChild(i)
            else
                local obj = CS.InstantObject(starNode.gameObject)
                child = obj.transform
                child:SetParent(root, false)
            end
            local star = FindTrans(child, strStar)
            self:SetWndEasyImage(star, iconPath, nil, true)
            CS.ShowObject(child, true)

            if i == showNum - 1 and showTxt then
                self:SetTextTile(star, "(" .. startNum .. ")")
            else
                self:SetTextTile(star, "")
            end

        end
    end

    if needAlignment then
        if bVertical then
            local layout = root:GetComponent(typeVerticalLayoutGroup)
            if layout then
                -- 居中对齐
                layout.childAlignment = TextAnchor.MiddleCenter
            end
        else
            local layout = root:GetComponent(typeHorizontalLayoutGroup)
            if ref.type == 0 then
                -- 向左对齐
                layout.childAlignment = TextAnchor.MiddleLeft
            else
                -- 居中对齐
                layout.childAlignment = TextAnchor.MiddleCenter
            end
        end
    end
end

-- 顶部资产
function LWnd:SetTopAssetList(transRoot, itemRefIdList, maxMap)
    local instanceID = transRoot:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        itemCache.item = CS.FindTrans(transRoot, "Group/Asset")
        itemCache.itemParent = itemCache.item.parent
        itemCache.itemList = {}
        self:SetComponentCache(instanceID, itemCache)
    end
    maxMap = maxMap or {}
    local itemList = itemCache.itemList
    for k, refId in ipairs(itemRefIdList) do
        local item = itemList[k]
        if not item then
            local obj = CS.InstantObject(itemCache.item.gameObject)
            local trans = obj.transform
            trans:SetParent(itemCache.itemParent, false)
            item = {}
            item.trans = trans
            item.txtNum = CS.FindTrans(trans, "num")
            item.icon = CS.FindTrans(trans, "icon")

            itemList[k] = item
        end
        item.refId = refId
        CS.ShowObject(item.trans, true)

        local num = gModelItem:GetNumByRefId(refId)
        num = LUtil.NumberCoversion(num)
        if maxMap[refId] then
            local maxNum =  LUtil.NumberCoversion(maxMap[refId])
            num = num .. "/" .. maxNum
        end
        self:SetWndText(item.txtNum, num)

        local iconPath = gModelItem:GetItemImgByRefId(refId)
        self:SetWndEasyImage(item.icon, iconPath)

        self:SetWndClick(item.trans, function()
            self:OnClickTopAsset(refId)
        end)
    end

    for i = #itemRefIdList + 1, #itemList do
        CS.ShowObject(itemList[i].trans, false)
    end
end

-- 点击顶部资产
function LWnd:OnClickTopAsset(refId)
    if refId == gModelItem.ITEM_DIAMOND then
        -- 钻石
        gLxTKData:OnUIBtnClick("UIHuiYPay")
        local wndInst = GF.FindFirstWndByName("UIHuiYPay")
        if wndInst then
            return
        end
        GF.OpenWndBottom("UIHuiYPay", { page = 2 })
        return
    end

    if refId == gModelItem.ITEM_GOLD then
        -- 金币
        GF.OpenWnd("UIGBuy")
        return
    end
    gModelGeneral:OpenGetWayWnd({ itemId = refId })
end

function LWnd:SetCommonButtonText(btnTrans,str)
    local btnName = self:FindWndTrans(btnTrans,"BtnName")
    self:SetWndText(btnName,str)
end


function LWnd:SetBtnRedPointStatus(btnTrans,isShow)
    local instanceID = btnTrans:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            redPoint = self:FindWndTrans(btnTrans,"redPoint")
        }
        self:SetComponentCache(instanceID, itemCache)
    end
    local redPoint = itemCache.redPoint
    if CS.IsNullObject(redPoint) then return end
    CS.ShowObject(redPoint,isShow)
end


--微信小游戏版本刷新会有异常，这里手动刷数据显示
function LWnd:RefreshSuperList(superList,dataList,func)
    if CS.IsWebGL() then
        for i,v in ipairs(dataList) do
            superList:DrawItemByIndex(i)
        end
    else
        if func then
            func()
        else
            superList:DrawAllItems()
        end
    end
end

-- 超出文本框，滚动（UI结构：Mask2d/Text, 其中text自适应大小）
function LWnd:SetNameTextScroll(txtTrans)
    if not CS.IsValidObject(txtTrans) then
        return
    end

    local instanceId = txtTrans:GetInstanceID()
    local curSeqTweenKey = instanceId

    local txt = self:FindWndText(txtTrans)
    local txtW = txt.preferredWidth
    local maskW = txtTrans.parent.rect.width
    self:TweenSeqKill(curSeqTweenKey)
    if txtW <= maskW then
        -- 还原
        txtTrans.anchoredPosition = Vector2.New(0, 0)
        return
    end

    local defaultPosX = txtW / 2 - maskW / 2
    local defaultPosY = txtTrans.localPosition.y

    local fromPos = Vector3.New(defaultPosX, defaultPosY, 0)
    local toPos = Vector3.New(-defaultPosX - txtW, defaultPosY, 0)

    if not self._setNameTextScrollRollTime then
        self._setNameTextScrollRollTime = gModelNormalActivity:GetBIActivityConfigRefByKey("rollTime") or 2
        self._setNameTextScrollRollingTime = gModelNormalActivity:GetBIActivityConfigRefByKey("rollingTime") or 2
    end

    self:TweenSeq_MoveAndBack(curSeqTweenKey, txtTrans, fromPos, toPos, self._setNameTextScrollRollingTime,
            self._setNameTextScrollRollTime, self._setNameTextScrollRollTime, nil, nil, true, false)
end



function LWnd:GetWndAdBtnShowStatus(params)
    local bShow = gModelAds:CheckShowADBtn()
    if bShow then
        bShow = gModelAds:CheckHasAdConfigByParam(params)
        if bShow and params.checkHasCount then
            --- 需要做数量判断或者其他的特殊判断
            bShow = gModelAds:CheckNeedShowAdBtn(params)
        end
    end
    return bShow
end

function LWnd:SetWndAdBtnInfo(btnTrans,params)
    local bShow = self:GetWndAdBtnShowStatus(params)
    CS.ShowObject(btnTrans,bShow)
    if not bShow then return end

    local config = gModelAds:GetAdConfigByParam(params)
    --- 取消红点
    gModelRedPoint:SetAdsRedPointClick(config.redPointConfig)

    local adRefId = config.refId
    params = params or {}
    params.adRefId = adRefId
    local wndId = params.wndId
    local openADFunc = function()
        gModelAds:OpenAd({
            refId = adRefId,
        })
    end
    params.openADFunc = openADFunc
    self:SetWndClick(btnTrans,function()
        if wndId and wndId > 0 then
            gModelAds:OpenAdByCommonTips(wndId,params)
        else
            openADFunc()
        end
    end)
end

function LWnd:RefreshAdBtnInfo(transInfo,params)
    local btnTrans,btnTxt = transInfo.btnTrans,transInfo.btnTxt
    local redPoint = transInfo.redPoint
    local bShow = self:GetWndAdBtnShowStatus(params)
    CS.ShowObject(btnTrans,bShow)
    CS.ShowObject(redPoint,bShow)
    if not bShow then return end

    CS.ShowObject(redPoint,gModelAds:CheckNeedShowAdBtn(params))
    params = params or {}

    if not btnTxt then
        btnTxt = self:FindWndTrans(btnTrans,"BtnName")
    end

    self:SetWndText(btnTxt,gModelAds:SetAdBtnName(params))
end


function LWnd:SetWndTabAdBtnInfo(transInfo,params)
    local btnTrans = transInfo.btnTrans
    local redPoint = transInfo.redPoint
    local bShow = self:GetWndAdBtnShowStatus(params)
    CS.ShowObject(btnTrans,bShow)
    CS.ShowObject(redPoint,bShow)
    if not bShow then return end

    CS.ShowObject(redPoint,gModelAds:CheckNeedShowAdBtn(params))
    self:SetAutoTabBtnName(btnTrans,gModelAds:SetAdBtnName(params))

    local config = gModelAds:GetAdConfigByParam(params)
    local refId = config.refId

    --- 取消红点
    gModelRedPoint:SetAdsRedPointClick(config.redPointConfig)

    params = params or {}
    local openADFunc = function()
        gModelAds:OpenAd({
            refId = refId,
        })
    end
    params.openADFunc = openADFunc
    local wndId = params.wndId
    self:SetWndClick(btnTrans,function()
        if wndId and wndId > 0 then
            gModelAds:OpenAdByCommonTips(wndId,params)
        else
            openADFunc()
        end
    end)
end

function LWnd:RefreshTabAdBtnInfo(btnTrans,params)
    local bShow = self:GetWndAdBtnShowStatus(params)
    CS.ShowObject(btnTrans,bShow)
    if not bShow then return end

    params = params or {}

    self:SetAutoTabBtnName(btnTrans,gModelAds:SetAdBtnName(params))
end


function LWnd:SetAutoTabBtnName(btnTrans,btnName,addFontSize, addFontLine)
    local Light = self:FindWndTrans(btnTrans,"Light")
    local Gray = self:FindWndTrans(btnTrans,"Gray")
    local lightText = self:FindWndTrans(Light,"AutoRoot/Text")
    local grayText = self:FindWndTrans(Gray,"AutoRoot/Text")
    self:SetWndText(lightText,btnName)
    self:SetWndText(grayText,btnName)

    self:InitTextSizeWithLanguage(lightText, addFontSize)
    self:InitTextSizeWithLanguage(grayText, addFontSize)

    if addFontLine then
        self:InitTextLineWithLanguage(lightText, addFontLine)
        self:InitTextLineWithLanguage(grayText, addFontLine)
    end
end

---@param spine LDisplaySpine
---@param cloudShows table
function LWnd:CreateHeroSpineCloudShow(cloudShows,spine)
    if not self:IsWndValid() then return end
    if not cloudShows or #cloudShows < 1 then return end
    if not spine or not spine:IsDpValid() then return end

    local finishCnt = 0
    local needLoadCnt = #cloudShows
    local spineTrans = spine:GetDisplayTrans()
    for i,v in ipairs(cloudShows) do
        self:CreateImageComp(v,spineTrans,"HERO_YUNDUO" .. i,function()
            finishCnt = finishCnt + 1
            if finishCnt >= needLoadCnt then
                if spine and spine:IsDpValid() then
                    LogWarn("显示spine")
                    spine:SetInterceptSpine(false)
                    spine:UpdateVisible()
                end
            end
        end)
    end
    return true
end

--- res,pos,scale,isFlip
function LWnd:CreateImageComp(info,spineTrans,key,loadCb)
    if not self:IsWndValid() then return end

    local gameTrans = self:FindWndTrans(spineTrans,key)
    if not gameTrans then
        gameTrans = CS.NewObject(key,spineTrans)
    end
    if not gameTrans then
        if loadCb then loadCb() end
        return
    end

    local gameObj = gameTrans.gameObject

    local imgComp = gameTrans:GetComponent(typeUIImage)
    if not imgComp then
        imgComp = gameObj:AddComponent(typeUIImage)
    end
    if not imgComp then
        if loadCb then loadCb() end
        return
    end

    if CS.IsNullObject(gameTrans) then
        gameTrans = imgComp.transform
    end

    local pos = info.pos
    if pos then
        gameTrans.anchoredPosition = pos
    end
    local scale = info.scale
    if scale and scale > 0 then
        local isFlip = info.isFlip
        gameTrans.localScale = Vector3(isFlip and -scale or scale,scale,scale)
    end
    --- 资源是否存在
    if not LxUiHelper.IsImgPathValid(info.res) then
        if loadCb then loadCb() end
    end
    LogWarn("info.res = " .. info.res)
    self:SetWndEasyImage(gameTrans,info.res,function()
        if loadCb then loadCb() end
        CS.ShowObject(gameTrans,true)
    end,true)
end



function LWnd:CreateHeroJDImgShow(jdInfos,root,bShow)
    if not self:IsWndValid() then return false end
    if CS.IsNullObject(root) then return false end

    local childCount = root.childCount
    for i = childCount,1,-1 do
        local child = root:GetChild(i-1)
        CS.ShowObject(child,false)
    end
    if not bShow then return end
    if not jdInfos or #jdInfos < 1 then return false end
    for i,v in ipairs(jdInfos) do
        self:CreateJDImageComp(v,root,"HERO_JD" .. i)
    end
    return true
end

--- res,pos,scale,rotate
function LWnd:CreateJDImageComp(info,root,key)
    if not self:IsWndValid() then return end

    local gameTrans = self:FindWndTrans(root,key)
    if not gameTrans then
        gameTrans = CS.NewObject(key,root)
    end
    if not gameTrans then return end

    local gameObj = gameTrans.gameObject

    local imgComp = gameTrans:GetComponent(typeUIImage)
    if not imgComp then
        imgComp = gameObj:AddComponent(typeUIImage)
    end
    if not imgComp then return end

    if CS.IsNullObject(gameTrans) then
        gameTrans = imgComp.transform
    end

    local pos = info.pos
    if pos then
        gameTrans.anchoredPosition = pos
    end
    local scale = info.scale
    if scale and scale > 0 then
        gameTrans.localScale = Vector3(scale,scale,scale)
    end
    local rotate = info.rotate
    if rotate then
        gameTrans.localRotation = Quaternion.Euler(0,0, rotate)
    end
    self:SetWndEasyImage(gameTrans,info.res,function()
        if not self:IsWndValid() then return end
        CS.ShowObject(gameTrans,true)
    end,true)
end
-----------------------------------------------------------------
return LWnd
