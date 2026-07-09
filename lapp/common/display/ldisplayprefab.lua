---@type LDisplayBase
local LDisplayBase = LDisplayBase

------------------------------------------------------------------
---@class LDisplayPrefab:LDisplayBase
local LDisplayPrefab = LxClass("LDisplayPrefab",LDisplayBase)
------------------------------------------------------------------
local typeofRenderer = typeof(UnityEngine.Renderer)
local typeSpriteRenderer = typeof(UnityEngine.SpriteRenderer)

local CS = CS
------------------------------------------------------------------
function LDisplayPrefab:LDisplayPrefab()
    self._bVisible = true
end

function LDisplayPrefab:CreatePrefab(parentTrans,folderName,prefabName)
	prefabName = gLGameLanguage:GetPrefabName(prefabName)
	
    local assetPath = folderName .. "/" .. prefabName
    assetPath = CS.ResPath(CS.RES_ANY_PREFAB, assetPath)
    self:Create(parentTrans,assetPath,prefabName)
    return true
end

function LDisplayPrefab:SetRenderPara(sortingLayer,sortingOrder)
    if sortingLayer and self._sortingLayer ~= sortingLayer then
        self._sortingLayer = sortingLayer
        self:UpdateSortingLayer()
    end

    if sortingOrder and self._sortingOrder~= sortingOrder then
        self._sortingOrder = sortingOrder
        self:UpdateSortingOrder()
    end
end

function LDisplayPrefab:SetVisible(bVisible)
    bVisible = bVisible and true or false
    if self._bVisible == bVisible then return end
    self._bVisible = bVisible
    if not self:IsDpValid() then return end
    self:UpdateVisible()
end

function LDisplayPrefab:SetScale(scale)
    self._scale = scale
    self:UpdateScale()
end

function LDisplayPrefab:OnDpReady()
    LDisplayBase.OnDpReady(self)
    self:UpdateVisible()
    self:UpdateScale()
    self:UpdateSortingOrder()
    self:UpdateSortingLayer()
end

function LDisplayPrefab:UpdateVisible()
    if not self:IsDpValid() then return end
    CS.ShowObject(self:GetDisplayTrans(), self._bVisible)
end

function LDisplayPrefab:UpdateScale()
    if not self._scale then
        return
    end
    if not self:IsDpValid() then
        return
    end
    local tran = self:GetDisplayTrans()
    tran.localScale = self._scale
end

function LDisplayPrefab:UpdateSortingLayer()
    if not self._sortingLayer then
        return
    end
    if not self:IsDpValid() then
        return
    end
    local dpTrans = self:GetDisplayTrans()
    if not self._rendererList then
        self._rendererList = dpTrans:GetComponentsInChildren(typeofRenderer, true)
    end

    local rendererLen = self._rendererList.Length
    for k = 1, rendererLen do
        local renderer = self._rendererList[k-1]
        renderer.sortingLayerName = self._sortingLayer
    end
end


function LDisplayPrefab:UpdateSortingOrder()
    if not self._sortingOrder then
        return
    end
    if not self:IsDpValid() then
        return
    end
    local dpTrans = self:GetDisplayTrans()
    if not self._rendererList then
        self._rendererList = dpTrans:GetComponentsInChildren(typeofRenderer, true)
    end

    local rendererLen = self._rendererList.Length
    for k = 1, rendererLen do
        local renderer = self._rendererList[k-1]
        renderer.sortingOrder = self._sortingOrder
    end
end

function LDisplayPrefab:IsVisible()
    return self._bVisible
end

function LDisplayPrefab:SetAlpha(alpha)
    local spRender = self._spriteRender

    if not spRender then
        local dpTrans = self:GetDisplayTrans()
        spRender = dpTrans:GetComponent(typeSpriteRenderer)
        self._spriteRender = spRender
    end

    spRender.color = Color.New(1, 1, 1, alpha)
end

return LDisplayPrefab