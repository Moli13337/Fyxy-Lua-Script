---
--- Created by wzz.
--- DateTime: 2024/12/12
--- 三消小游戏


local LMapBase           = LMapBase
---@class LMatchThreeGameMap:LMapBase
local LMatchThreeGameMap = LxClass("LMatchThreeGameMap", LMapBase)
-----------------------------------------------------------------
local typeSpriteRenderer = typeof(UnityEngine.SpriteRenderer)
local typeofYXIMapCamera = typeof(CardEHT.YXIMapCamera)

local YXTouchManager     = CS.YXTouchManager
local Tweening           = DG.Tweening


local Vector3 = Vector3
local Vector2 = Vector2
local table   = table
local pairs   = pairs


-----------------------------------------------------------------
function LMatchThreeGameMap:LMatchThreeGameMap()
    self._mgr = nil

    self:InitEvents()
end

function LMatchThreeGameMap:OnDestroy()
    self._onEnterMap = nil
    if self._mgr then
        self._mgr:ExitMap()
        self._mgr = nil
    end
    
    LMapBase.OnDestroy(self)
end

function LMatchThreeGameMap:OnCreate()
    LMapBase.OnCreate(self)
end

-- 初始事件
function LMatchThreeGameMap:InitEvents()
    self:MapEventRecv(EventNames.MATCH_THREE_GAME_RESTART, function(...)
        if not self._onEnterMap then
            return
        end
        self:RestartGame(...)
    end)
end

function LMatchThreeGameMap:OnExitMap()
    self._onEnterMap = nil
    self._mgr:ExitMap()

    GF.CloseWndByName("WndMatchThreeGame")
    self:ReSetCamera()

    Tweening.DOTween.SetTweensCapacity(200, 125)
end

function LMatchThreeGameMap:OnResetMap()
    local mapName = "MapMatchThreeGame"
    self:SetMapName(mapName)

    GF.OpenWnd("WndMatchThreeGame")

    self:DelayGuideReadyMsg()
end

function LMatchThreeGameMap:OnEnterMap()
    LMapBase.OnEnterMap(self)

    gModelMatchThreeGame:SaveHadPlayGame()
    self:InitCamera()
    self:RefreshBg()

    self._mgr = gLGpManager:GetMatchThreeGameImpl()
    self._mgr:EnterMap(self)

    self._onEnterMap = true

    Tweening.DOTween.SetTweensCapacity(300, 125)
end

-- 根节点
function LMatchThreeGameMap:GetNodeRootTrans()
    if not self._nodeRootTrans then
        local root = self:GetMapTrans()
        self._nodeRootTrans = CS.FindTrans(root, "LayerRoot/LayerNode")
    end
    return self._nodeRootTrans
end

-- 初始化相机设置
function LMatchThreeGameMap:InitCamera()
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()

    self._cameraInitData = {}
    self._cameraInitData.pos = Vector3.New(0, 0, 0)
    self._cameraInitData.orthographicSize = sceneCamera.orthographicSize

    self:ResetCameraPos(0, self._cameraInitData.pos)
end

-- 还原相机设置
function LMatchThreeGameMap:ReSetCamera()
    if self._cameraInitData then
        local sceneCamera = gLGameScene:GetCurrentSceneCamera()
        sceneCamera.orthographicSize = self._cameraInitData.orthographicSize
        sceneCamera.transform.rotation = Quaternion.Euler(0, 0, 0)
        self._cameraInitData = nil
    end
end

-- 获取初始相机设置
function LMatchThreeGameMap:GetCameraInitData()
    return self._cameraInitData
end

-- 刷新背景图
function LMatchThreeGameMap:RefreshBg()
    local ref = gModelMatchThreeGame:GetRef()
    local root = self:GetMapTrans()
    local trans = CS.FindTrans(root, "LayerRoot/LayerBg/bg")
    --- 代码是注释掉的，修改函数
    --self:SetSpriteRenderer(trans,ref.bg)
end

-- 重新开始游戏
function LMatchThreeGameMap:RestartGame()
    self:RefreshBg()
    self._mgr:OnRestartGame()
end

return LMatchThreeGameMap
