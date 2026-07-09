---
--- Created by wzz.
--- DateTime: 2024/9/10
--- 爱欲小径地图, 特别注意：格子坐标，y在前，x在后， y表示层数floor（行数）, 从下0到上~， x表示列数，从左0到右~

local LMapBase            = LMapBase
---@class LDesireTrailMap:LMapBase
local LDesireTrailMap     = LxClass("LDesireTrailMap", LMapBase)
-----------------------------------------------------------------
local typeSpriteRenderer  = typeof(UnityEngine.SpriteRenderer)
local typeofYXIMapCamera  = typeof(CardEHT.YXIMapCamera)

local YXTouchManager      = CS.YXTouchManager
local Tweening            = DG.Tweening

local LDesireTrailGridObj = LXImport("..Object.LDesireTrailGridObj")

local Vector3             = Vector3
local Vector2             = Vector2
local table               = table
local pairs               = pairs

local function tableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- 界面存时在，不检测格子状态
local WndExistNoNeedCheckGrid = {
    ["UIDesireTrailMonsterTips"] = true,
    ["UIDesireTrailBoxTips"] = true,
    ["UIAward"] = true,
}

-- 界面关闭时，检测格子状态
local WndCloseNeedCheckGrid = {
    ["UIDesireTrailBoxTips"] = true,
    ["UIAward"] = true,
}

local GridStatus = ModelDesireTrail.GridStatus

-----------------------------------------------------------------
function LDesireTrailMap:LDesireTrailMap()
    -- gModelDesireTrail
    self._model = gModelDesireTrail

    -- 当前主题配置
    self._themeRef = nil

    -- 格子对象
    self._gridObjMap = {}

    -- 第一个格子的偏移高度
    self._firstGridOffy = -4.5

    -- 格子之间的高度
    self._gridSpaceH = 1.5

    self._mapW3 = LGameQuality.SCREEN_WIDTH_DESIGN / 100 + 1.8
    self._mapW2 = LGameQuality.SCREEN_WIDTH_DESIGN / 100

    -- 主角精灵
    self._roleDp = nil

    self:InitEvents()
end

function LDesireTrailMap:OnDestroy()
    self._onEnterMap = nil
    self:ClearDelayTime()
    self:ClearGrid()
    self:RemoveTouchEvent()
    
    if self._dpObj then
        self._dpObj:Destroy()
        self._dpObj = nil
    end

    if self._effSweep then
        self._effSweep:Destroy()
        self._effSweep = nil
    end


    LMapBase.OnDestroy(self)
end

function LDesireTrailMap:OnCreate()
    LMapBase.OnCreate(self)
end

-- 初始事件
function LDesireTrailMap:InitEvents()
    self:MapEventRecv(EventNames.DESIRE_TRAIL_RESET, function()
        if not self._onEnterMap then
            return
        end
        self:OnResetAllGrid()
        self:CheckTarget()
    end)

    self:MapEventRecv(EventNames.DESIRE_TRAIL_GRID_CHANGE, function()
        if not self._onEnterMap then
            return
        end
        self:OnGridChange()
    end)

    self:MapEventRecv(EventNames.ON_WND_CLOSE, function(wndName)
        if not self._onEnterMap then
            return
        end
        self:OnWndClose(wndName)
    end)

    self:MapEventRecv(EventNames.DESIRE_TRAIL_SWEEP, function(...)
        if not self._onEnterMap then
            return
        end
        self:OnSweepReturn(...)
    end)

    self:MapEventRecv(EventNames.DESIRE_TRAIL_CRUSHING, function(...)
        if not self._onEnterMap then
            return
        end
        self:OnCrushingReturn(...)
    end)
end

function LDesireTrailMap:OnExitMap()
    self._onEnterMap = nil
    self._model:SetSweeping(false)

    self:ReSetCamera()

    self:ClearDelayTime()
    self:ClearGrid()
    self:RemoveTouchEvent()
end

-- 清理格子
function LDesireTrailMap:ClearGrid()
    for _, tab in pairs(self._gridObjMap) do
        for _, grid in pairs(tab) do
            grid:Destroy()
        end
    end
    self._gridObjMap = {}

    if self._dpObj then
        self._dpObj:Destroy()
        self._dpObj = nil
    end

    if self._effSweep then
        self._effSweep:Destroy()
        self._effSweep = nil
    end

    self:ClearTargetList()
end

-- 清理target列表
function LDesireTrailMap:ClearTargetList()
    if self._targetList then
        for _, v in pairs(self._targetList) do
            v.seq:Kill()
            LxUnity.Destroy(v.target)
        end
    end
    self._targetList = {}
end

function LDesireTrailMap:OnResetMap()
    local mapName = "MapDesireTrail"
    self:SetMapName(mapName)

    GF.OpenWnd("UIDesireTrail")
end

function LDesireTrailMap:OnEnterMap()
    LMapBase.OnEnterMap(self)
    self._model:SetSweeping(false)

    self:InitTouchEvent()
    self:OnResetAllGrid()

    if self._model:HasChangedGrid() then
        self._playingAni = true
        self._delayTime = LxTimer.DelayTimeCall(function()
            self:ClearDelayTime()
            self:PlayEffAni()
            self:CheckTarget()
        end, 0.5)
    else
        self._playingAni = nil
        self:CheckTarget()
    end
    self._onEnterMap = true
end

-- 清理时间
function LDesireTrailMap:ClearDelayTime()
    if self._delayTime then
        LxTimer.DelayTimeStop(self._delayTime)
        self._delayTime = nil
    end
end

-- 重置所有格子
function LDesireTrailMap:OnResetAllGrid()
    self:ClearGrid()
    self:InitData()
    self:InitGrid()
    self:InitRoleDp()
    self:InitCamera()
    self:InitTarget()
    self:InitMapEff()
    self:RefreshBg()
end

-- 初始化数据
function LDesireTrailMap:InitData()
    self._themeRef = self._model:GetCurThemeRef()
end

-- 格子根节点
function LDesireTrailMap:GetGridRootTrans()
    if not self._gridRootTrans then
        local root = self:GetMapTrans()
        self._gridRootTrans = CS.FindTrans(root, "LayerRoot/GridRoot")
    end
    return self._gridRootTrans
end

-- 格子节点(克隆节点)
function LDesireTrailMap:GetGridPoolObj()
    if not self._gridPoolObj then
        local root = self:GetMapTrans()
        local trans = CS.FindTrans(root, "LayerRoot/GridTemplate")
        self._gridPoolObj = trans.gameObject
        self._gridPoolObj:SetActive(false)
    end
    return self._gridPoolObj
end

-- 初始化相机设置
function LDesireTrailMap:InitCamera()
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local root = self:GetMapTrans()
    local bgTrans = CS.FindTrans(root, "LayerRoot/LayerBg/bg")

    local bgOff = 0
    bgTrans.position = Vector3.New(0, -bgOff * 0.5, 0)
    self:ResetCameraPos(0, Vector3.New(0, 0, 0))

    local range = self:GetCameraRange()
    self:GetMapCameraCom():SetRange(Vector2.New(0, range.x), Vector2.New(0, range.y + bgOff))
    self._curCameraTrans = sceneCamera.transform
end

-- 还原相机设置
function LDesireTrailMap:ReSetCamera()
    if self._oldOrthographicSize then
        local sceneCamera = gLGameScene:GetCurrentSceneCamera()
        sceneCamera.orthographicSize = self._oldOrthographicSize
        self._oldOrthographicSize = nil
    end
end

-- 获取相机范围
function LDesireTrailMap:GetCameraRange()
    local orthgraphicSize, designOrthgraphicSize = LUtil.GetCameraSize()

    local lineNum = tableSize(self._model:GetGridDataMap())
    local offtH = math.max(0, self._gridSpaceH * (lineNum - 6) - 1)

    local min = orthgraphicSize - designOrthgraphicSize
    local max = designOrthgraphicSize - orthgraphicSize + offtH

    if CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
        local topY = ((LNotchUtil.menuButtonY + LNotchUtil.menuButtonH) / 100) or 0
        local bottomY = (((LNotchUtil.NotchAnchorMin.y * LNotchUtil.height) + LNotchUtil.SafeArea.y) / 100) or 0
        max = max + topY
        min = min - bottomY
        --gprint("GetCameraRange", topY, bottomY, max, min, LNotchUtil.NotchAnchorMin.y, LNotchUtil.height, LNotchUtil.SafeArea.y)
    end

    return Vector2.New(min, max)
end

-- 触摸
function LDesireTrailMap:InitTouchEvent()
    local op = LGameTouch.TOUCH_WONDER

    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_START, function(screenPos)
        self._startMousePos = nil
        if self:IsOverUI(screenPos) then return end

        if not self._mapCameraCom then
            return
        end
        self._cameraStartPos = self._curCameraTrans.position
        self._startMousePos = screenPos
        self._mapCameraCom:StartDrag()
    end)
    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_MOVE, function(screenPos)
        if not self._startMousePos then
            return
        end
        if self:IsOverUI(screenPos) then
            return
        end
        self:OnDrag(screenPos)
    end)
    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_END, function(screenPos)
        self._mapCameraCom:EndDrag()
        self._startMousePos = nil
    end)
    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_CANCEL, function(screenPos)
        self._mapCameraCom:EndDrag()
        self._startMousePos = nil
    end)
end

-- 拖拽
function LDesireTrailMap:OnDrag(mousePos)
    local offset = self._startMousePos - mousePos
    local offsetY = offset.y * 0.01 + self._cameraStartPos.y
    self._mapCameraCom:ChangeCameraPos(Vector3.New(0, offsetY, 0))
end

-- 重置相机位置
function LDesireTrailMap:SetCameraPosInRole()
    if not self._mapCameraCom then return end

    if not self._dpObj then return end
    local trans = self._dpObj:GetDisplayTrans()
    if not trans then return end

    if self._lastChangeCame and self._lastChangeCame < os.clock() - 1 then
        return
    end
    self._lastChangeCame = os.clock()
    
    self._mapCameraCom:EndDrag()
    self._startMousePos = nil

    local offsetY = trans.position.y + 2

    self._mapCameraCom:ChangeCameraPos(Vector3.New(0, offsetY, 0))
end

-- 清理触摸
function LDesireTrailMap:RemoveTouchEvent()
    if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_WONDER) end
end

-- true:表示点中UI
function LDesireTrailMap:IsOverUI(screenPos)
    local touchObject = YXTouchManager.EventSystemRaycastGameObject(screenPos)
    if touchObject and gLGameUI:IsUILayer(touchObject.layer) then
        return true
    end
end

-- 刷新背景图
function LDesireTrailMap:RefreshBg()
    local ref = self._themeRef
    local root = self:GetMapTrans()
    local trans = CS.FindTrans(root, "LayerRoot/LayerBg/bg")
    self:SetSpriteRenderer(trans, ref.pic)
end

-- 初始化背景特效
function LDesireTrailMap:InitMapEff()
    self._bgEffObjList = self._bgEffObjList or {}
    for _, eff in pairs(self._bgEffObjList) do
        eff:Destroy()
    end
    self._bgEffObjList = {}

    local root = self:GetMapTrans()
    local downTrans = CS.FindTrans(root, "LayerRoot/LayerDown")
    local upTrans = CS.FindTrans(root, "LayerRoot/LayerUp")

    local effList = {
        {
            parent = upTrans,
            effName = "fx_ui_aiyu_map_up",
        },
        {
            parent = downTrans,
            effName = "fx_ui_aiyu_map_down",
        }
    }

    for _, v in pairs(effList) do
        local eff = LDisplayEffect:New()
        table.insert(self._bgEffObjList, eff)
        eff:CreateEffect(v.parent, v.effName)
        eff:SetResTag(CS.RES_TAG_SCENE)

        eff:SetLoadedFunction(function()
            -- if not self._boxEffObj then
            --     return
            -- end
            -- local trans = self._boxEffObj:GetDisplayTrans()
            -- trans.localScale = Vector3(0.7, 0.7, 0.7)
        end)

        eff:StartLoadEffect()
    end
end

-- 初始化target
function LDesireTrailMap:InitTarget()
    local root = self:GetMapTrans()
    local targetTran = CS.FindTrans(root, "LayerRoot/GridTarget")
    self._targetRootObj = targetTran.gameObject
end

-- 显示
function LDesireTrailMap:ShowTarget(y, x)
    local obj = CS.InstantObject(self._targetRootObj)
    obj:SetActive(true)
    local target = obj.transform
    target:SetParent(self:GetGridRootTrans(), false)


    local gridObj = self:GetGridObj(y, x)

    local pos = gridObj:GetPos()
    pos.y = pos.y + 1
    target.localPosition = pos

    local initY = pos.y
    local seq = Tweening.DOTween.Sequence()
    local tw1 = target:DOLocalMoveY(initY + 0.15, 0.8)
    local tw2 = target:DOLocalMoveY(initY, 0.8)
    seq:Append(tw1)
    seq:Append(tw2)
    seq:SetLoops(-1)
    seq:Play()

    table.insert(self._targetList, { target = target, seq = seq })
end

-- 检查target
function LDesireTrailMap:CheckTarget()
    local dataList = self._model:GetGridDataMap()
    local select = GridStatus.Selected
    local canMove = GridStatus.CanMove
    local targetList = {}

    local _, roleY = self._model:GetRolePos()
    for y, tab in pairs(dataList) do
        if roleY + 1 == y then
            for x, data in pairs(tab) do
                if data.status == select then
                    targetList = {}
                    table.insert(targetList, { y = y, x = x })
                elseif data.status == canMove then
                    table.insert(targetList, { y = y, x = x })
                end
            end
            break
        end
    end

    self:ClearTargetList()
    if #targetList == 0 then
        return
    end

    if self._model:IsSweeping() then
        return
    end

    local canSweep = self._model:IsSweepOpen(false)
    for _, v in pairs(targetList) do
        self:ShowTarget(v.y, v.x)

        if canSweep and not self._model:IsLastGrid(v.y) then
            local gridObj = self:GetGridObj(v.y, v.x)
            if gridObj then
                gridObj:ShowTitle()
            end
        end
    end
end

-- 界面关闭
function LDesireTrailMap:OnWndClose(wndName)
    if not WndCloseNeedCheckGrid[wndName] then
        return
    end
    self:OnGridChange()
end

-- true: 表示需要检测格子状态
function LDesireTrailMap:NeedCheckGridStatus()
    for viewName in pairs(WndExistNoNeedCheckGrid) do
        if GF.FindFirstWndByName(viewName) then
            return false
        end
    end
    return true
end

-- 格子变化
function LDesireTrailMap:OnGridChange()
    if not self:NeedCheckGridStatus() then
        return
    end

    self:PlayEffAni()
    self:CheckTarget()
end

-- 一键碾压
function LDesireTrailMap:OnCrushingReturn()
    -- local x, y = self._model:GetRolePos()
    -- local gridObj = self:GetGridObj(y, x)
    -- if gridObj then
    --     gridObj:ShowEmpty()
    --     local trans = self._dpObj:GetDisplayTrans()
    --     trans.localPosition = gridObj:GetPos()
    -- end
    -- self:CheckTarget()
end

-- 初始化格子
function LDesireTrailMap:InitGrid()
    local parnet = self:GetGridRootTrans()
    local poolObj = self:GetGridPoolObj()
    local dataList = self._model:GetGridDataMap()

    for y, tab in pairs(dataList) do
        local oneLineNum = tableSize(tab)
        for x, data in pairs(tab) do
            local pos = self:GetGridPos(y, x, oneLineNum)

            local obj = CS.InstantObject(poolObj)
            local grid = LDesireTrailGridObj.New()
            grid:Create(self, obj, parnet, y, x)
            grid:SetPos(pos)
            if not self._gridObjMap[y] then
                self._gridObjMap[y] = {}
            end
            self._gridObjMap[y][x] = grid
        end
    end
end

-- 获取格子坐标
function LDesireTrailMap:GetGridPos(y, x, oneLineNum)
    local mapW = self._mapW2
    if oneLineNum == 3 then
        mapW = self._mapW3
    end

    x = (x + 1) * mapW / (oneLineNum + 1) - mapW / 2
    y = y * self._gridSpaceH
    return Vector3.New(x, y + self._firstGridOffy, 0)
end

-- 获取格子对象
function LDesireTrailMap:GetGridObj(y, x)
    if not self._gridObjMap[y] then
        return nil
    end
    return self._gridObjMap[y][x]
end

-- 初始化主角色精灵
function LDesireTrailMap:InitRoleDp()
    local ref = self._themeRef

    local parent = self:GetGridRootTrans()
    local dp = LDisplaySpine:New()
    dp:CreateSpine(parent, ref.roleRes)
    self._dpObj = dp
    dp:SetLoadedFunction(function()
        if self._dpObj == nil then return end
        local x, y = self._model:GetRolePos()
        local gridObj = self:GetGridObj(y, x)
        if gridObj then
            local pos = gridObj:GetPos()
            local trans = self._dpObj:GetDisplayTrans()
            trans.localPosition = pos
            self._roleGridObj = gridObj

            self._dpObj:SetRenderOrder(999)
            self:SetCameraPosInRole()

            local collider = CS.FindTrans(trans, "Collider")
            if collider then
                CS.ShowObject(collider.gameObject, false)
            end

        end
    end)
    dp:StartLoad()
end

-- 主角跳到其它格子
function LDesireTrailMap:JumpToGrid(y, x, endFunc)
    if not self._dpObj then
        if endFunc then
            endFunc()
        end
        return
    end

    local gridObj = self:GetGridObj(y, x)
    local trans = self._dpObj:GetDisplayTrans()
    if not trans then
        if endFunc then
            endFunc()
        end
        return
    end

    self._roleGridObj = gridObj
    gridObj:ShowEmpty()
    local pos = gridObj:GetPos()
    local trans = self._dpObj:GetDisplayTrans()
    local duration = 0.5
    local tw = trans:DOJump(pos, 0.2, 1, duration)
    tw:Play()
    tw:OnComplete(function()
        if endFunc then
            endFunc()
        end

        if self._dpObj == nil then return end
        self._dpObj:PlayAnimation(0, "idle", true)
    end)
    self._dpObj:PlayAnimation(0, "jump2", false)
end

-- 主角跳到最后一关
function LDesireTrailMap:JumpToEndGrid(y, x)
    self._playingAni = true

    local gridObj = self:GetGridObj(y, x)
    local pos = gridObj:GetPos()
    pos.y = pos.y + 0.5

    local trans = self._dpObj:GetDisplayTrans()
    self._dpObj:PlayAnimation(0, "jump2", false)

    local duration = 1
    local tw1 = trans:DOJump(pos, 0.2, 1, duration)
    local tw2 = trans:DOScale(Vector3(0, 0, 0), duration)

    local seq = Tweening.DOTween.Sequence()
    seq:Insert(0, tw1)
    seq:Insert(0, tw2)
    seq:InsertCallback(0.5, function()
        local obj = self:GetGridObj(y, x)
        if obj then
            obj:ShowDoor(false, 0.8, function()
                self._playingAni = nil
                self._model:DesireTrailNextThemeReq()
            end)
        end
    end)
    seq:SetAutoKill(true)
    seq:Play()
end

-- 获取当前主角格子位置
function LDesireTrailMap:GetCurRoleGridPos()
    local y, x = 0, 0
    if self._roleGridObj then
        y, x = self._roleGridObj:GetGridPos()
    end
    return y, x
end

-- 点击格子
function LDesireTrailMap:OnClickGrid(y, x)
    local isPlayingAni = self._playingAni
    if isPlayingAni then
        -- 正在动画中
        return
    end
    local roleY, roleX = self:GetCurRoleGridPos()
    if roleY >= y then
        -- 点击同行以下的格子
        return
    end

    local data = self._model:GetGridData(y, x)
    if not data then
        return
    end

    if self._model:IsLastGrid(y) and data.status == ModelDesireTrail.GridStatus.HasMove then
        -- 点击下一关
        if self._model:IsMaxTheme() then
            GF.ShowMessage(ccClientText(45436))
            return
        end

        local gridObj = self:GetGridObj(y, x)
        if gridObj then
            self:JumpToEndGrid(y, x)
        end
        return
    end

    if self._model:IsSweeping(true) then
        return
    end

    self._model:OnClickGrid(y, x)
end

-- 点击标题(扫荡)
function LDesireTrailMap:OnClickTitle(y, x)
    if not self._model:IsSweepOpen(true) then
        return
    end

    if self._model:IsSweeping(true) then
        return
    end


    local isLeft = x == 0
    local oneLineNum = self._model:GetOneLineGridCount(y)
    if oneLineNum == 3 and x == 1 then
        local data = self._model:GetGridData(y, 0)
        isLeft = data.status == GridStatus.Disappear
    end

    self._model:DesireTrailSweepReq(y, x, isLeft)
end

-- 扫荡返回
function LDesireTrailMap:OnSweepReturn(data)
    self._model:SetSweeping(true)
    self._playingAni = true

    self._sweepData = data

    local y, x = data.y, data.x
    local endFunc = function()
        self:PlaySweepAni(y, x)
        self:ShowRole(false)
        self:ClearTargetList()
        self:SetCameraPosInRole()
    end

    self:JumpToGrid(y, x, endFunc)
end

-- 播放扫荡动画
function LDesireTrailMap:PlaySweepAni(y, x)
    if self._effSweep then
        self._effSweep:Destroy()
        self._effSweep = nil
    end

    local eff = LDisplayEffect:New()
    eff:CreateEffect(self:GetGridRootTrans(), "fx_ui_aiyu_saodang")
    eff:SetResTag(CS.RES_TAG_SCENE)
    self._effSweep = eff
    eff:SetLoadedFunction(function()
        if eff:IsDestroy() then return end

        local gridObj = self:GetGridObj(y, x)
        local dpTrans = eff:GetDisplayTrans()
        if gridObj and dpTrans then
            local pos = gridObj:GetPos()
            dpTrans.localPosition = pos
        end
        LxTimer.DelayTimeCall(function() self:PlaySweepAniEnd() end, 2.2)
    end)


    eff:StartLoadEffect()
end

-- 显示/隐藏 主角
function LDesireTrailMap:ShowRole(show)
    if not self._dpObj then
        return
    end

    local trans = self._dpObj:GetDisplayTrans()
    if not trans then
        return
    end
    trans.gameObject:SetActive(show)
end

-- 播放扫荡动画结束
function LDesireTrailMap:PlaySweepAniEnd()
    if not self._onEnterMap then
        return
    end

    if self._effSweep then
        self._effSweep:Destroy()
        self._effSweep = nil
    end

    local data = self._sweepData

    if data.isWin then
        self:PlaySweepAniEndToWin()
    else
        self:PlaySweepAniEndToFail()
    end
end

-- 扫荡失败
function LDesireTrailMap:PlaySweepAniEndToFail()
    self:ShowRole(true)

    local data = self._sweepData

    local gridObj = self:GetGridObj(data.y, data.x)
    if gridObj then
        gridObj:ShowEmpty(true)
    end

    local y, x = data.y - 1, data.x
    if data.isLeft then
        x = math.max(x - 1, 0)
    else
        x = math.min(x + 1, self._model:GetOneLineGridCount(y) - 1)
    end

    self:JumpToGrid(y, x, function()
        self._model:SetSweeping(false)
        self._playingAni = nil
        self._model:ShowSweepResult()
        self:CheckTarget()
    end)
end

-- 扫荡成功
function LDesireTrailMap:PlaySweepAniEndToWin()
    self:ShowRole(true)

    -- 奖励弹窗
    self:ShowSweepAward()

    local x, y = self._model:GetRolePos()
    if self._model:IsLastGrid(y + 1) then
        -- 最后一关
        self._model:SetSweeping(false)
        self._playingAni = nil
        local gridObj = self:GetGridObj(y + 1, 0)
        if gridObj then
            gridObj:Refresh()
        end
        return
    end

    if self._model:GetChallengeCount() == 0 then
        GF.ShowMessage(ccClientText(45441))
        self._model:SetSweeping(false)
        self._playingAni = nil
        self:CheckTarget()
        return
    end

    local data = self._sweepData
    local y, x = data.y + 1, data.x
    if data.isLeft then
        x = math.max(x - 1, 0)
    else
        x = math.min(x + 1, self._model:GetOneLineGridCount(y) - 1)
    end

    if self._model:IsLastGrid(y) then
        self._model:SetSweeping(false)
        self._playingAni = nil
        local gridObj = self:GetGridObj(y, 0)
        if gridObj then
            gridObj:Refresh()
        end
        return
    end

    LxTimer.DelayTimeCall(function() self._model:DesireTrailSweepReq(y, x, data.isLeft) end, 0.5)
 
end

-- 显示扫荡奖励
function LDesireTrailMap:ShowSweepAward()
    local data = self._sweepData
    local gainStrs = {}
    for k, v in ipairs(data.itemList) do
        local str = v.itemType .. "=" .. v.itemId .. "=" .. v.itemNum .. "=" .. 0 .. "#path=3#"
        table.insert(gainStrs, str)
    end
    for k, v in ipairs(gainStrs) do
        local str = v
        GF.ShowMessage(str)
    end
end

-- 检查宝箱状态
function LDesireTrailMap:CheckBoxStatus(y)
    for _, obj in pairs(self._gridObjMap[y] or {}) do
        obj:CheckBoxStatus()
    end
end

-- 播放动画
function LDesireTrailMap:PlayEffAni()
    local effData = self._model:PopEffect()

    local endFunc = function() self._playingAni = nil end

    if effData then
        if effData.effectType == ModelDesireTrail.EffectType.Move then
            self:JumpToGrid(effData.newY, effData.newX, endFunc)
            self:SetCameraPosInRole()
            self:CheckBoxStatus(effData.newY + 1)
            endFunc = nil
        end
    end

    local changedGridMap = self._model:GetChangedGridMap()
    self._model:ClearChangedGridMap()

    for _, lines in pairs(changedGridMap) do
        for _, eventInfo in pairs(lines) do -- 为协议的： message EventInfo
            local gridObj = self:GetGridObj(eventInfo.y, eventInfo.x)
            if gridObj then
                if eventInfo.status == GridStatus.Disappear then
                    gridObj:FadeOut(nil, endFunc)
                    endFunc = nil
                elseif eventInfo.status == GridStatus.HasMove then
                    local isLastGrid = self._model:IsLastGrid(eventInfo.y)
                    if isLastGrid then
                        if self._model:IsMaxTheme() then
                            gridObj:ShowBoxEffect(true)
                        else
                            gridObj:ShowDoor(true, nil, endFunc)
                        end
                        endFunc = nil
                    end
                end
            end
        end
    end

    if endFunc then
        endFunc()
    end
end

return LDesireTrailMap
