---
--- Created by Administrator.
--- DateTime: 2023/10/27 17:12
---
---------------------------------------------------------------------------
local CS = CS
local Time = Time
local LayerMask = LayerMask
local typeof = typeof
local YXSimplePool = CS.YXSimplePool
local YXUITouchEffect = CS.YXUITouchEffect
local typeYXSimplePool = typeof(YXSimplePool)
local typeYXUITouchEffect = typeof(YXUITouchEffect)

---@class LUiClickEffector
local LUiClickEffector = LxClass("LUiClickEffector", nil)
---------------------------------------------------------------------------

---------------------------------------------------------------------------
LUiClickEffector.TOUCH_LAYER = LayerMask.NameToLayer(LGameUI.UI_LAYER_UI_EXTEND)

LUiClickEffector.TOUCH_EFFECT_POOL = "TouchEffectPool"
LUiClickEffector.TOUCH_EFFECT_HOLD_MAX = 4
LUiClickEffector.TOUCH_EFFECT_WAIT_TIME = 1
LUiClickEffector.TOUCH_EFFECT_ROOT = "TouchEffect"
LUiClickEffector.TOUCH_EFFECT_NAME = "fx_ui_dianji"

LUiClickEffector.TOUCH_DRAG_NAME = "fx_huaping"

---------------------------------------------------------------------------
function LUiClickEffector:LUiClickEffector()
	self._clickEffectRoot = nil
	self._effectPool = nil
	self._csSimplePool = nil
	self._csUITouchEffect = nil
	
	self._touchScreenTimeHandle = nil
	self._touchScreenTimeFunc = nil

	self:InitIdleGC()
end

function LUiClickEffector:Destroy()
	LogWarn("Destroy LUiClickEffector")

	if self._clickEffectDp then
		self._clickEffectDp:Destroy()
		self._clickEffectDp = nil
	end

	if self._trailEffDp then
		self._trailEffDp:Destroy()
		self._trailEffDp = nil
	end

	if self._clickEffectRoot then
		LxResUtil.DestroyImmediate(self._clickEffectRoot)
	end
	if self._touchScreenTimeHandle then
		LxTimer.LoopTimeStop(self._touchScreenTimeHandle)
	end
	if self._freeTimeGcHandle then
		LxTimer.LoopTimeStop(self._freeTimeGcHandle)
	end
	table.removeall(self)
end
function LUiClickEffector:Create()
	local rootCanvas = LGameUI.GetUICanvas_Touch()
	if not rootCanvas then return false end

	--- UITouch/TouchEffect
	local clickEffectRoot = CS.FindTrans(rootCanvas, LUiClickEffector.TOUCH_EFFECT_ROOT)
	if clickEffectRoot then
		LxResUtil.DestroyImmediate(clickEffectRoot)
		clickEffectRoot = nil
	end
	clickEffectRoot = CS.NewObject(LUiClickEffector.TOUCH_EFFECT_ROOT, rootCanvas)
	clickEffectRoot:SetAsFirstSibling()
	self._clickEffectRoot = clickEffectRoot

	--- UITouch/TouchEffect/TouchEffectPool
	local effectPool = CS.FindTrans(clickEffectRoot, LUiClickEffector.TOUCH_EFFECT_POOL)
	if not effectPool then
		effectPool = CS.NewObject(LUiClickEffector.TOUCH_EFFECT_POOL, clickEffectRoot)
		effectPool:SetAsFirstSibling()
	end
	self._effectPool = effectPool
	CS.UpdateChildLayer(rootCanvas, LUiClickEffector.TOUCH_LAYER)

	local csSimplePool = effectPool:GetComponent(typeYXSimplePool)
	if not csSimplePool then
		csSimplePool = effectPool.gameObject:AddComponent(typeYXSimplePool)
	end
	self._csSimplePool = csSimplePool

	local csUITouchEffect = clickEffectRoot:GetComponent(typeYXUITouchEffect)
	if not csUITouchEffect then
		csUITouchEffect = clickEffectRoot.gameObject:AddComponent(typeYXUITouchEffect)
	end
	self._csUITouchEffect = csUITouchEffect



	self._effectLoadCount = 0

	local parentRoot = self._clickEffectRoot.transform
	local dpEff = LDisplayEffect:New()
	self._trailEffDp = dpEff
	dpEff:CreateEffect(parentRoot, LUiClickEffector.TOUCH_DRAG_NAME)
	dpEff:SetLoadedFunction(function(dp)
		local dpTrans = dp:GetDisplayTrans()
		self:OnDragEffectLoaded(dpTrans)
	end)
	dpEff:SetLoadFailFunc(function()
		self:OnDragEffectLoaded(nil)
	end)
	dpEff:StartLoadEffect()

	dpEff = LDisplayEffect:New()
	self._clickEffectDp = dpEff
	dpEff:CreateEffect(parentRoot, LUiClickEffector.TOUCH_EFFECT_NAME)
	dpEff:SetLoadedFunction(function(dp)
		local dpTrans = dp:GetDisplayTrans()
		self:OnClickEffectLoaded(dpTrans)
	end)
	dpEff:SetLoadFailFunc(function()
		self:OnClickEffectLoaded(nil)
	end)
	dpEff:StartLoadEffect()
	return true
end

function LUiClickEffector:OnDragEffectLoaded(prefab)
	self._dragPrefab = prefab
	self._effectLoadCount = self._effectLoadCount + 1
	self:CheckEffectLoaded()
end

function LUiClickEffector:OnClickEffectLoaded(prefab)
	self._clickPrefab = prefab
	self._effectLoadCount = self._effectLoadCount + 1
	self:CheckEffectLoaded()
end

function LUiClickEffector:CheckEffectLoaded()
	if self._effectLoadCount >= 2 then
		local huapinPrefab = self._dragPrefab
		local go = self._clickPrefab
		self._dragPrefab = nil
		self._clickPrefab = nil
		self:OnEffectLoaded(go, huapinPrefab)
	end
end

function LUiClickEffector:OnEffectLoaded(modelPrefab, huapinPrefab)
	local effectName = LUiClickEffector.TOUCH_EFFECT_NAME
	--local resPath = CS.ResPath(CS.RES_UI_EFFECT, LUiClickEffector.TOUCH_EFFECT_NAME)
	--local bundleName = CS.FormatBundleNameByPath(resPath)

	if modelPrefab == nil then
		LogError("can't load click effect modelPrefab " .. effectName)
		return
	end

	--modelPrefab = LxResUtil.NewObject(modelPrefab.gameObject)
	--
	--if huapinPrefab then
	--	huapinPrefab = LxResUtil.NewObject(huapinPrefab.gameObject)
	--end

	CS.UpdateChildLayer(modelPrefab.transform, LUiClickEffector.TOUCH_LAYER)

	CS.UpdateChildLayer(huapinPrefab.transform, LUiClickEffector.TOUCH_LAYER)


	local csSimplePool = self._csSimplePool
	local csUITouchEffect = self._csUITouchEffect
	local csUICamera = LGameUI.GetUICamera()

	--modelPrefab.transform:SetParent(self._clickEffectRoot.transform, false)
	--huapinPrefab.transform:SetParent(self._clickEffectRoot.transform, false)

	CS.ShowObject(modelPrefab, false)
	CS.ShowObject(huapinPrefab, false)

	modelPrefab.transform.localScale = Vector3(100,100,100)
	huapinPrefab.transform.localScale = Vector3(100,100,100)

	csSimplePool.itemTemplate = modelPrefab.gameObject
	csSimplePool.poolInitSize = 2
	csSimplePool.poolMaxSize = LUiClickEffector.TOUCH_EFFECT_HOLD_MAX
	csSimplePool:InitPool()
	
	csUITouchEffect.effectWaitTime = LUiClickEffector.TOUCH_EFFECT_WAIT_TIME
	csUITouchEffect.uiCamera = csUICamera
	csUITouchEffect.effectPool = csSimplePool
	csUITouchEffect.dragObject = huapinPrefab.gameObject
	csUITouchEffect.enableDrag = true

	local onTouchDelegate = function()
		self:OnTouchScreen()
	end
	csUITouchEffect.TouchDelegate = onTouchDelegate
end

function LUiClickEffector:OnTouchScreen()
	if not self._touchScreenTimeFunc then
		self._touchScreenTimeFunc = function()
			-- 正在播放战斗就不要降帧了
			if gLFightManager and gLFightManager:HasBattleInFront() then
				return
			end
			
			self._touchScreenTimeHandle:Pause(true)
			gLGameQuality:SetNoTouchFrameRate(true)
		end
	end
	if not self._touchScreenTimeHandle then
		self._touchScreenTimeHandle = LxTimer.LoopTimeCall(self._touchScreenTimeFunc, 15, true, -1)
	end

	gLGameQuality:SetNoTouchFrameRate(false)
	if self._touchScreenTimeHandle then
		self._touchScreenTimeHandle:Reset(self._touchScreenTimeFunc, 15, -1, true)
		self._touchScreenTimeHandle:Pause(false)
	end

	if CS.IsWebGL() then
		self:DealClearGc()
	end
end

function LUiClickEffector:EnableTouchEffect(bEnable)
	bEnable = bEnable and bEnable or false
	local csUITouchEffect = self._csUITouchEffect
	if (csUITouchEffect) then
		csUITouchEffect.enableTouchEffect = bEnable
	end
end

function LUiClickEffector:ShowTouchEffect(bEnable)
	bEnable = bEnable and bEnable or false
	local csUITouchEffect = self._csUITouchEffect
	if (csUITouchEffect) then
		csUITouchEffect:ShowTouchEffect(bEnable)
	end
end

---------------------------------------
---pyaler idle GC

function LUiClickEffector:DealClearGc()
	if LGameSettings.freeTimeGcInterval <= 0 then return end

	if not self._freeTimeFunc then
		self._freeTimeFunc = function()
			-- 正在播放战斗不处理
			if gLFightManager and gLFightManager:HasBattleInFront() then
				return
			end
			self._freeTimeGcHandle:Pause(true)
			--LResRelease.ClearLuaGC()
		end
	end

	if not self._freeTimeGcHandle then
		self._freeTimeGcHandle = LxTimer.LoopTimeCall(self._freeTimeFunc, LGameSettings.freeTimeGcInterval, true, -1)
	end

	if self._freeTimeGcHandle then
		self._freeTimeGcHandle:Reset(self._freeTimeFunc, LGameSettings.freeTimeGcInterval, -1, true)
		self._freeTimeGcHandle:Pause(false)
	end
end

local _idle_sleep_time = 60
function LUiClickEffector:InitIdleGC()
	if not CS.IsWebGL() then return end
	
	self._idleTime = _idle_sleep_time

	if LPlatformUtil.IsInIos() then 
		_idle_sleep_time = 30
		self._idleTime = _idle_sleep_time
		self._isInIos = true
		self._luaGCRunTimer = LxTimer.LoopTimeCall(function ()
			self:_OnLuaGCRun()
		end, 1)
	end
	
	
	self._clearBundleTimer = LxTimer.LoopTimeCall(function ()
		self:_OnClearBundleRun()
	end, 1)
end	


function LUiClickEffector:ResetTouchTime()
	self._idleTime = _idle_sleep_time
end	

function LUiClickEffector:_OnLuaGCRun()
	-- LogWarn("int ios run lua Gc count")
	--LResRelease.LuaGCCount()
	LxResUtil.RunSimpleLuaGC()
end

function LUiClickEffector:_OnClearBundleRun()
	self._idleTime = self._idleTime - 1
	if self._idleTime <= 0 then
		self._idleTime = _idle_sleep_time
		--LResRelease.ClearBundleUnused(self._isInIos and not LResRelease._IsFightShowing())
	end
end	

return LUiClickEffector