---
--- Created by wzz.
--- DateTime: 2024/6/11
--- 方块小游戏地图

local LMapBase = LMapBase
---@class LBlockMiniGameMap:LMapBase
local LBlockMiniGameMap = LxClass("LBlockMiniGameMap", LMapBase)
-----------------------------------------------------------------
local typeSpriteRenderer = typeof(UnityEngine.SpriteRenderer)
local typeofYXIMapCamera = typeof(CardEHT.YXIMapCamera)

local YXTouchManager = CS.YXTouchManager

local LBlockMiniGameShape = LXImport("..Object.LBlockMiniGameShape")

local TimerKey = 1
local Time = Time
local CS = CS
local math = math
local LGameTouch = LGameTouch
local Tweening = DG.Tweening

local DownLeftOrRightY = 250
local DownLeftOrRightX = 250
local LeftOrRight = 50
local Down = 50


-----------------------------------------------------------------
function LBlockMiniGameMap:LBlockMiniGameMap()
    -- LBlockMiniGameManager
    self._mgr = nil

    -- gModelBlockMiniGame
    self._model = gModelBlockMiniGame

    --游戏是否暂停
    self._isPauseGame = true

    --格子是否暂停
    self._isPauseBlock = false

    -- 方块对象池
    self._shapeObjPool = {}

    -- 方块父节点
    self._shapeParent = nil

    -- 当前方块对象
    self._curShape = nil

    -- 下一个方块对象
    self._nextShape = nil

    -- 最大行数
    self._maxRow = 22

    -- 最大列数
    self._maxCol = 10

    -- 当前等级配置
    self._ref = nil


    -- 所有方块列表
    self._allBlockMap = {}
    self:ClearBlockMap()

    self:InitEvents()
end

function LBlockMiniGameMap:OnDestroy()
    self:ClearMapData()
    self:RemoveTouchEvent()

    self:ClearBlockMap()
    self:ClearBlockMapObj()

    if self._mgr then
        self._mgr:Destroy()
        self._mgr = nil
    end

    LMapBase.OnDestroy(self)
end

function LBlockMiniGameMap:OnCreate()
    LMapBase.OnCreate(self)
end

-- 初始事件
function LBlockMiniGameMap:InitEvents()
    self:MapEventRecv(EventNames.BLOCKMINIGAME_START, function() self:OnStart() end)
    self:MapEventRecv(EventNames.BLOCKMINIGAME_PAUSE, function() self:OnPauseGame() end)
    self:MapEventRecv(EventNames.BLOCKMINIGAME_RESUME, function() self:OnResumeGame() end)
    self:MapEventRecv(EventNames.BLOCKMINIGAME_OVER, function(...) self:OnOver(...) end)
    self:MapEventRecv(EventNames.BLOCKMINIGAME_RESTART, function(...) self:OnReStart(...) end)
    self:MapEventRecv(EventNames.BLOCKMINIGAME_BTN_CTRL, function(...) self:OnBtnCtrl(...) end)
end

-- 加速度
function LBlockMiniGameMap:GetGameTimeScaleBySpeedValue()
    return 1
end

function LBlockMiniGameMap:OnExitMap()
    self:ReSetCamera()

    self:ClearMapData()
    self:RemoveTouchEvent()
    self:ClearBlockMap()
    self:ClearBlockMapObj()

    self._mgr:ExitMap()


    GF.CloseWndByName("UIBlockMiniGame")
    gModelGameHelper:RefreshGameSpeed()
end

function LBlockMiniGameMap:OnResetMap()
    LxUnity.UResources.UnloadUnusedAssets()
    gModelGameHelper:RefreshGameSpeed()

    local mapName = "MapBlockMiniGame"
    self:SetMapName(mapName)

    local refId = self:GetMapArg("refId")
    if refId then
        self._ref = self._model:GetLevRef(refId)
    else
        self._ref = self._model:GetCurLevRef()
    end

    -- 再来一局
    self:RemoveAllTimer()
end

function LBlockMiniGameMap:OnEnterMap()
    LMapBase.OnEnterMap(self)

    self:InitShapes()
    self:InitTouchEvent()
    self:InitCamera()
    self:RefreshBg()
    self._mgr = gLGpManager:FindBlockMiniGameGp()
    self._mgr:EnterMap(self)
    self:TimerStart(TimerKey, 0, false, -1)

    self:ReadyView()
end

-- 关卡配置
function LBlockMiniGameMap:GetRef()
    return self._ref
end

-- 方块列表
function LBlockMiniGameMap:ClearBlockMap()
    self._allBlockMap = {}

    for k, v in pairs(self._allBlockMap) do
        for k1, v1 in pairs(v) do
            if v1.dp then
                v1.dp:Destroy()
                v1.dp = nil
            end
        end
    end

    for col = 0, self._maxCol - 1 do
        self._allBlockMap[col] = {}
        for row = 0, self._maxRow - 1 do
            self._allBlockMap[col][row] = nil
        end
    end
end

-- 清理方块obj
function LBlockMiniGameMap:ClearBlockMapObj()
    if not self._shapeParent then return end

    for i = self._shapeParent.childCount - 1, 0, -1 do
        local child = self._shapeParent:GetChild(i)
        CS.Destroy(child)
    end

    for k, v in pairs(self._lineEffMap or {}) do
        v:Destroy()
    end
    self._lineEffMap = {}
end

-- 清理数据
function LBlockMiniGameMap:ClearMapData()
    if self._curShape then
        self._curShape:Destroy()
        self._curShape = nil
    end

    if self._nextShape then
        self._nextShape:Destroy()
        self._nextShape = nil
    end
    self._isPauseGame = true
end

-- 初始化相机设置
function LBlockMiniGameMap:InitCamera()
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local root = self:GetMapTrans()
    local bgTrans = CS.FindTrans(root, "LayerRoot/LayerBg")
    local bgTrans2 = CS.FindTrans(root, "LayerRoot/LayerBg/bg_MiniGame")
    local pos = bgTrans.position
    local scale = bgTrans2.localScale
    pos.x = pos.x + bgTrans2.localPosition.x * scale.x * 2
    self:ResetCameraPos(0, pos)

    local bgScale = bgTrans.localScale
    local designAspect = LGameQuality.SCREEN_WIDTH_DESIGN / LGameQuality.SCREEN_HEIGHT_DESIGN
    local bgH
    if sceneCamera.aspect < designAspect  then
        bgH = LGameQuality.SCREEN_WIDTH_DESIGN / sceneCamera.aspect * bgScale.y
    else
        bgH = (LGameQuality.SCREEN_HEIGHT_DESIGN + UnityEngine.Screen.safeArea.y * 2) * bgScale.y
    end

    if not self._oldOrthographicSize then
        self._oldOrthographicSize = sceneCamera.orthographicSize
        sceneCamera.orthographicSize = bgH * 0.5 * 0.01
    end
end

-- 还原相机设置
function LBlockMiniGameMap:ReSetCamera()
    if self._oldOrthographicSize then
        local sceneCamera = gLGameScene:GetCurrentSceneCamera()
        sceneCamera.orthographicSize = self._oldOrthographicSize
        self._oldOrthographicSize = nil
    end
end

-- 触摸
function LBlockMiniGameMap:InitTouchEvent()
    local op = LGameTouch.TOUCH_WONDER

    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_START, function(screenPos)
        self._startPos = nil
        if self:IsOverUI(screenPos) then return end

        self._startPos = screenPos
    end)

    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_END, function(screenPos)
        self:OnTouchEnd(screenPos)
    end)
    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_CANCEL, function(screenPos)
        self:OnTouchEnd(screenPos)
    end)
end

-- 触摸结束
function LBlockMiniGameMap:OnTouchEnd(screenPos)
    local startPos = self._startPos
    self._startPos = nil
    if not startPos or self._isPauseGame then return end

    -- 测试用
    if BlockMiniGameDownLeftOrRightY then
        DownLeftOrRightY = BlockMiniGameDownLeftOrRightY
    end
    if BlockMiniGameDownLeftOrRightX then
        DownLeftOrRightY = BlockMiniGameDownLeftOrRightX
    end
    if BlockMiniGameLeftOrRight then
        LeftOrRight = BlockMiniGameLeftOrRight
    end
    if BlockMiniGameDown then
        Down = BlockMiniGameDown
    end

    local offX = screenPos.x - startPos.x
    local offY = startPos.y - screenPos.y
    if offY > DownLeftOrRightY and offX < -DownLeftOrRightX then
        -- down left
        self:OnTouchDown(true)
    elseif offY > DownLeftOrRightY and offX > DownLeftOrRightX then
        -- down right
        self:OnTouchDown(false)
    elseif offX > LeftOrRight then
        -- right
        self:OnTouchRight()
    elseif offX < -LeftOrRight then
        -- left
        self:OnTouchLeft()
    elseif startPos.y - screenPos.y > Down then
        self:OnTouchDown(nil)
    else
        -- clcik
        self:OnTouchClick()
    end
end

-- 清理触摸
function LBlockMiniGameMap:RemoveTouchEvent()
    if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_WONDER) end
end

-- 左划
function LBlockMiniGameMap:OnTouchLeft()
    if self._curShape and not self._curShape:IsLock() then
        self._curShape:StepLeft()
    end
end

-- 右划
function LBlockMiniGameMap:OnTouchRight()
    if self._curShape and not self._curShape:IsLock() then
        self._curShape:StepRight()
    end
end

-- 下划
function LBlockMiniGameMap:OnTouchDown(moveLeft)
    if self._curShape and not self._curShape:IsLock() then
        self._curShape:SpeedUp(moveLeft)
    end
end

-- 点击
function LBlockMiniGameMap:OnTouchClick()
    if self._curShape and not self._curShape:IsLock() then
        self._curShape:RotateShape()
    end
end

-- 按钮控制
function LBlockMiniGameMap:OnBtnCtrl(flag)
    if self._startPos or self._isPauseGame or self._isPauseBlock then
        return
    end

    if flag == "left" then
        self:OnTouchLeft()
    elseif flag == "right" then
        self:OnTouchRight()
    elseif flag == "down" then
        if self._curShape and not self._curShape:IsLock() then
            self._curShape:LimitFall(1)
        end
    elseif flag == "fast" then
        -- if self._curShape and not self._curShape:IsLock() then
        --     self._curShape:LimitFall(3)
        -- end
        self._curShape:SpeedUp(nil)
    elseif flag == "rotate" then
        self:OnTouchClick()
    end
end

-- true:表示点中UI
function LBlockMiniGameMap:IsOverUI(screenPos)
    local touchObject = YXTouchManager.EventSystemRaycastGameObject(screenPos)
    if touchObject and gLGameUI:IsUILayer(touchObject.layer) then
        return true
    end
end

-- 初始化方块
function LBlockMiniGameMap:InitShapes()
    local root = self:GetMapTrans()
    for i = 1, 7 do
        local trans = CS.FindTrans(root, "Shape/Shape_" .. i)
        self._shapeObjPool[i] = trans.gameObject
    end
    self._shapeParent = CS.FindTrans(root, "LayerRoot/LayerBlock")
end

-- 准备界面
function LBlockMiniGameMap:ReadyView()
    gLGameUI:CloseAllButExcept({
        ["UIBlockMiniGame"] = true
    })

    local function openCall()
        if not self._nextShape then
            -- 新一局

            local function ShowReady()
                self._mgr:StartGame()
                GF.OpenWnd("UIBlockMiniGameReady")
            end

            if self._model:NeedPopHelp() then
                GF.OpenWnd("UIBlockMiniGameHelp", { callback = ShowReady })
            else
                ShowReady()
            end
        end
    end

    GF.OpenWnd("UIBlockMiniGame", {
        refId = self._ref.refId,
        openCall = openCall
    })
end

-- 刷新背景图
function LBlockMiniGameMap:RefreshBg()
    local ref = self._ref
    local root = self:GetMapTrans()
    local trans = CS.FindTrans(root, "LayerRoot/LayerBg/role")
    self:SetSpriteRenderer(trans, ref.bg)
end

-- update
function LBlockMiniGameMap:OnTimer(key)
    if key ~= TimerKey then return end

    if self._isPauseGame then return end

    local dt = Time.deltaTime
    if self._curShape and not self._isPauseBlock then
        self._curShape:Update(dt)
    end

    -- todo: 需要优化，暂停时，可能刚好跑到这里（也可能到了self._mgr:Update中子类的update），导致子类在已暂停时update了一次
    if self._isPauseGame then return end

    if self._mgr then
        self._mgr:Update(dt)
    end
end

-- 创建方块
function LBlockMiniGameMap:SpawnShape()
    local shape = LBlockMiniGameShape.New()
    local refId = self._model:GetRandomBlockRefId(self._ref)
    local ref = self._model:GetBlockRef(refId)
    local obj = CS.InstantObject(self._shapeObjPool[ref.type])

    local speed = self._ref.blockSpeed
    shape:Init({ ref = ref, obj = obj, parent = self._shapeParent, speed = speed, map = self })
    return shape
end

-- 生产下一方块
function LBlockMiniGameMap:SpawnNextShape()
    if self._curShape then
        self._curShape:Destroy()
    end

    self._curShape = self._nextShape
    self._nextShape = self:SpawnShape()
    self._nextShape:InitReadyPos()
    self._curShape:InitStartPos()


    if not self:IsShapePosValid(self._curShape) then
        FireEvent(EventNames.BLOCKMINIGAME_OVER, { isWin = false })
        return
    end
end

-- 开始游戏
function LBlockMiniGameMap:StartGame()
    self._curShape = self:SpawnShape()
    self._nextShape = self:SpawnShape()

    self._curShape:InitStartPos()
    self._nextShape:InitReadyPos()

    self:OnResumeBlock()
end

-- 开始游戏
function LBlockMiniGameMap:OnStart()
    self:StartGame()
    self:OnResumeGame()
end

-- 暂停格子
function LBlockMiniGameMap:OnPauseBlock()
    self._isPauseBlock = true
end

-- 恢复格子
function LBlockMiniGameMap:OnResumeBlock()
    self._isPauseBlock = false
end

-- 暂停游戏
function LBlockMiniGameMap:OnPauseGame()
    self._isPauseGame = true
end

-- 恢复游戏
function LBlockMiniGameMap:OnResumeGame()
    self._isPauseGame = false
end

-- true:表示游戏暂停
function LBlockMiniGameMap:IsPauseGame()
    return self._isPauseGame
end

-- 游戏结束
function LBlockMiniGameMap:OnOver(param)
    self._isPauseGame = true

    FireEvent(EventNames.BLOCKMINIGAME_PAUSE)

    param = param or {}
    local isWin = param.isWin

    local curTime = os.clock()
    if self._sendTime then
        if self._sendTime + 1 > curTime then return end

        self._sendTime = curTime
    else
        self._sendTime = curTime
    end


    local wnd = GF.FindFirstWndByName("UIBlockMiniGame")
    local useTime = wnd:GetUseTime()
    self._model:BlockMiniGamePassReq(self._ref.refId, isWin and 1 or 2, useTime)
end

-- 重新开始
function LBlockMiniGameMap:OnReStart(refId)
    if self._curShape then
        self._curShape:Destroy()
        self._curShape = nil
    end

    if self._nextShape then
        self._nextShape:Destroy()
        self._nextShape = nil
    end

    self:ClearBlockMap()
    self:ClearBlockMapObj()
    self:OnResumeBlock()

    if refId then
        self._ref = self._model:GetLevRef(refId)
    end

    --todo:清理地图
    GF.OpenWnd("UIBlockMiniGameReady")
end

-- 保存block数据
function LBlockMiniGameMap:SaveBlock(shape)
    for index, trans in ipairs(shape:GetBlockList()) do
        local pos = self:RoundPos(trans.position)
        local monsterRefId = shape:GetMonsterRefId(index)
        local dp = shape:PopSpine(index)
        self._allBlockMap[pos.x][pos.y] = { trans = trans, monsterRefId = monsterRefId, dp = dp }
    end
end

-- 检测地图block, 返回true表示有消行
function LBlockMiniGameMap:CheckBlockMap()
    local clearLineNum = 0
    local rowList = {}
    for row = 0, self._maxRow - 1 do
        local isFull = self:CheckIsRowFull(row)
        if isFull then
            clearLineNum = clearLineNum + 1
            table.insert(rowList, row)
        end
    end
    if clearLineNum > 0 then
        -- 有消行
        self:ClearLine(rowList, clearLineNum)
        return true
    end
    return false
end

-- 方块下落结束
function LBlockMiniGameMap:FallEnd(shape)
    self:OnPauseBlock()
    self:SaveBlock(shape)
    if not self:CheckBlockMap() then
        if not self:BlockIsOver() then
            self:SpawnNextShape()
            self:OnResumeBlock()
        end
    end
end

-- true:表示方块已满
function LBlockMiniGameMap:BlockIsOver()
    for col = 0, self._maxCol - 1 do
        if self._allBlockMap[col][self._maxRow - 1] then
            FireEvent(EventNames.BLOCKMINIGAME_OVER, { isWin = false })
            return true
        end
    end
    return false
end

-- 消行
function LBlockMiniGameMap:ClearLine(rowList, num)
    local seq = Tweening.DOTween.Sequence()
    self._lineEffMap = self._lineEffMap or {}
    local dpList = {}
    local parent = self:GetObjRootTrans()
    local effTrans = self:GetClearLineEffTrans()
    for _, row in ipairs(rowList) do
        for col = 0, self._maxCol - 1 do
            local tab = self._allBlockMap[col][row]
            if tab then
                seq:Insert(0, tab.trans:DOScale(0, 0.3))
                seq:Insert(0, tab.trans:DOScale(0, 0.7))
                local tempDP = tab.dp
                if tempDP then
                    local trans = tempDP:GetSpineTrans()
                    trans:SetParent(parent, true)
                    table.insert(dpList, { dp = tempDP, monsterRefId = tab.monsterRefId, lineNum = num })
                end
            end
        end

        if not self._lineEffMap[row] then
            local dpEff = LDisplayEffect:New()
            dpEff:CreateEffect(effTrans, "fx_ui_fangkuai_xiaochu")
            self._lineEffMap[row] = dpEff
            dpEff:SetLoadedFunction(function(dp)
                local dpTrans = dp:GetDisplayTrans()
                dpEff:SetEffectScale(2.8)
                dpTrans.localPosition = Vector3(1.48, -21 + row, 0)
            end)
            dpEff:StartLoadEffect()
        end
    end

    seq:OnComplete(function()
        self:ClearLineFinish(rowList, num)
        for k, v in pairs(self._lineEffMap) do
            v:Destroy()
        end
        self._lineEffMap = {}
    end)
    seq:SetAutoKill(true)
    seq:PlayForward()

    FireEvent(EventNames.BLOCKMINIGAME_CLEARLINESTART, { lineNum = num })
    self:PlayClearLineAudio(num)

    if #dpList > 0 then
        self._mgr:SpawnSelfObjs(dpList)
    end
end

-- 消行动画播完
function LBlockMiniGameMap:ClearLineFinish(rowList, num)
    local mosterList = {}
    for _, row in ipairs(rowList) do
        for col = 0, self._maxCol - 1 do
            local tab = self._allBlockMap[col][row]
            if tab then
                CS.Destroy(tab.trans)
            end
            self._allBlockMap[col][row] = nil
        end
    end

    self:MoveLines(rowList, num)
    self:SpawnNextShape()
    self:OnResumeBlock()
end

-- 剩下的方块往下移
function LBlockMiniGameMap:MoveLines(rowList, num)
    for i = #rowList, 1, -1 do
        local rowIndex = rowList[i]
        for row = rowIndex, self._maxRow - 1 do
            for col = 0, self._maxCol - 1 do
                local tab = self._allBlockMap[col][row + 1]
                if tab then
                    self._allBlockMap[col][row] = tab
                    self._allBlockMap[col][row + 1] = nil
                    local pos = tab.trans.position
                    pos.y = pos.y - 1
                    tab.trans.position = pos
                end
            end
        end
    end
end

-- 检测某行是否已满
function LBlockMiniGameMap:CheckIsRowFull(row)
    for col = 0, self._maxCol - 1 do
        if self._allBlockMap[col][row] == nil then
            return false
        end
    end
    return true
end

-- 方块位置是否有效
function LBlockMiniGameMap:IsShapePosValid(shape)
    for _, trans in ipairs(shape:GetBlockList()) do
        local pos = self:RoundPos(trans.position)
        if not self:IsInsideMap(pos) then
            -- 超出地图
            return false
        end

        if self:IsInOtherShape(pos) then
            -- 与其他方块重合
            return false
        end
    end
    return true
end

-- 方块旋转修正
function LBlockMiniGameMap:CanShapeRotate(shape)
    local offtX = 0
    local offtY = 0
    local listPos = {}
    for k, trans in ipairs(shape:GetBlockList()) do
        local pos = self:RoundPos(trans.position)
        listPos[k] = pos
        if self:IsInOtherShape(pos) then
            -- 与其他方块重合
            return false
        end
        if not self:IsInsideMap(pos) then
            -- 超出地图
            return false
        end


        if pos.x < 0 then
            offtX = math.min(offtX, pos.x)
        elseif pos.x >= self._maxCol then
            offtX = math.max(offtX, pos.x - self._maxCol + 1)
        end
        if pos.y >= self._maxRow then
            offtY = pos.y - self._maxRow + 1
        end
    end

    if offtX == 0 and offtY == 0 then
        return true, 0, 0
    end

    for _, pos in ipairs(listPos) do
        pos.x = pos.x - offtX
        pos.y = pos.y - offtY
        if self:IsInOtherShape(pos) then
            -- 与其他方块重合
            return false
        end
    end
    return true, offtX, offtY
end

-- 设置空格子位置
function LBlockMiniGameMap:SetEmptyShapePos(shape)
    local blockList = shape:GetBlockList()
    local blockList2 = shape:GetBlockList2()

    local startY = self._maxRow - 1
    local blockPosMap = {}
    for i, trans in ipairs(blockList) do
        local pos = self:RoundPos(trans.position)
        blockPosMap[i] = pos
        if startY > pos.y then
            startY = pos.y
        end
    end

    local change = false
    for row = startY, 0, -1 do
        local inOther = false
        for i, pos in ipairs(blockPosMap) do
            if self:IsInOtherShape(pos) then
                inOther = true
                break
            end
        end
        if inOther then break end

        for i, pos in ipairs(blockPosMap) do
            pos.y = pos.y - 1
        end
        change = true
    end

    for i, trans in ipairs(blockList2) do
        local pos = blockPosMap[i]
        if change then
            pos.y = pos.y + 1
        end
        trans.position = pos
    end

    shape:ShowEmptyBlock(true)
end

-- 是否在地图内
function LBlockMiniGameMap:IsInsideMap(pos)
    return pos.x >= 0 and pos.x < self._maxCol and pos.y >= 0
end

-- 是否与其他方块重合
function LBlockMiniGameMap:IsInOtherShape(pos)
    return self._allBlockMap[pos.x] and self._allBlockMap[pos.x][pos.y] ~= nil
end

-- 坐标 4舍5入取整
function LBlockMiniGameMap:RoundPos(pos)
    pos.x = math.round2(pos.x)
    pos.y = math.round2(pos.y)
    return pos
end

-- 下落音效
function LBlockMiniGameMap:PlayDropAudio()
end

-- 控制音效（左右旋转）
function LBlockMiniGameMap:PlayControlAudio()
end

-- 消行音效
function LBlockMiniGameMap:PlayClearLineAudio(lineNum)
    local ref = self._model:GetClearLineRef(lineNum)
    if not ref then return end
    
    local audioName = ref.sound
    if gLGameAudio and audioName ~= "" then
        gLGameAudio:PlaySound(audioName)
    end
end

-- 缓存节点
function LBlockMiniGameMap:GetPoolTrans()
    if not self._poolTrans then
        local root = self:GetMapTrans()
        self._poolTrans = CS.FindTrans(root, "LayerRoot/LayerPool")
    end
    return self._poolTrans
end

-- 游戏对象根节点
function LBlockMiniGameMap:GetObjRootTrans()
    if not self._objRootTrans then
        local root = self:GetMapTrans()
        self._objRootTrans = CS.FindTrans(root, "LayerRoot/LayerObj")
    end
    return self._objRootTrans
end

-- 游戏消行特效
function LBlockMiniGameMap:GetClearLineEffTrans()
    if not self._clearLineEffTrans then
        local root = self:GetMapTrans()
        self._clearLineEffTrans = CS.FindTrans(root, "LayerRoot/LayerBlockEff")
    end
    return self._clearLineEffTrans
end

return LBlockMiniGameMap
