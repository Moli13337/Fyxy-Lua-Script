---
--- Created by Admin.
--- DateTime: 2023/10/10 10:12
---
------------------------------------------------------------------
--- wnd display control
------------------------------------------------------------------
local CS = CS
local Vector3 = Vector3
local Vector2 = Vector2
local UIScene = UIScene
local typeofUISorting = typeof(CS.YXUISorting)
------------------------------------------------------------------
---@type LWnd
local LWnd = LWnd

------------------------------------------------------------------
--- wnd effect play
------------------------------------------------------------------

function LWnd:ShowBtnEff(trans, key, isShow, effName)
	effName = effName or "fx_shouchong_anniu_zhong"

	if isShow then
		if self._wndEffectList and self._wndEffectList[key] then
			return
		end
		self:CreateWndEffect(trans,effName,key,100,nil,nil,nil,nil,nil,true)
	else
		self:DestroyWndEffectByKey(key)
	end
end

function LWnd:DestroyWndEffectAll()
	local effectList = self._wndEffectList
	if effectList then
		for k, v in pairs(effectList) do
			v:Destroy()
		end
		self._wndEffectList = nil
	end

	self._effLoadList = nil
end
function LWnd:DestroyWndEffectByKey(key)
	if not self._wndEffectList then
		return
	end
	--print("destroy  "..key)
	local effectList = self._wndEffectList
	if effectList[key] then
		effectList[key]:Destroy()
		effectList[key] = nil
	end
end

function LWnd:FindWndEffectByKey(key)
	if not self._wndEffectList then
		return
	end
	return self._wndEffectList[key]
end

function LWnd:CreateWndEffect(trans, effName, effKey, scaleSize, bDefaultLayer, bDefaultSorting, bDefaultSortNum, preloadCallback,scaleSizeY,addMask,sortLayer,endFunc, upSortOrder)
	if self:IsDestroy() then
		return
	end
	if not trans then
		--print("trans is nil")
		return
	end
	bDefaultSortNum = bDefaultSortNum or 1
	if bDefaultSortNum <= 0 then
		bDefaultSortNum = 1
	end
	local key = effKey or trans.gameObject.name
	local effectList = self._wndEffectList
	if (not effectList) then
		effectList = {}
		self._wndEffectList = effectList
	end
	local oldEff = effectList[key]
	if oldEff then
		local dpTrans = oldEff:GetDisplayTrans()
		if CS.IsValidObject(dpTrans)  then

			-- false 到 true 重新播特效
			--dpTrans.gameObject:SetActive(false)
			oldEff:SetVisible(false)

			if not self._wndVisible then
				return
			end

			if self._isHideAllEff then
				return
			end
			oldEff:SetVisible(true)
			--dpTrans.gameObject:SetActive(true)
		end
		if endFunc then
			endFunc(dpTrans)
		end
		return
	end
	--print("load "..effName)
	local scale
	if type(scaleSize) == "table" then
		scale = scaleSize
		if scaleSizeY then
			scale.y = scaleSizeY
		end
	elseif scaleSizeY then
		scale = scaleSize and Vector3(scaleSize, scaleSizeY, scaleSize) or Vector3(640,640,640)
	end
	local dpEff = LDisplayEffect:New()
	effectList[key] = dpEff
	dpEff:CreateEffect(trans, effName)
	dpEff:SetLoadedFunction(
			function()
				--print("loaded "..effName)
				local dpTrans = dpEff:GetDisplayTrans()
				dpTrans.localPosition = Vector3.zero
				--dpTrans.localScale = scale
				dpTrans.name = effName
				dpEff:SetEffectScale(scaleSize, scale)

				local dpGo = dpTrans.gameObject
				if not bDefaultLayer and dpGo.layer ~= LWnd.WND_LAYER then
					CS.UpdateChildLayer(dpTrans, LWnd.WND_LAYER)
				end

				if not bDefaultSorting then
					local dpParentTrans = dpEff:GetParentTrans()
					if dpParentTrans and CS.IsValidObject(dpParentTrans) then
						local rendererSort = dpParentTrans:GetComponent(typeofUISorting)
						if not rendererSort then
							rendererSort = dpParentTrans.gameObject:AddComponent(typeofUISorting)
						end
						local sortLayer = sortLayer or self:GetWndSortLayer()
						upSortOrder = upSortOrder or 0
						rendererSort:SetCheckInitValue(true)
						rendererSort:SetLayerName(sortLayer)
						rendererSort:SetParentOrder(self:GetWndSortOrder() + upSortOrder)
						rendererSort:SetInitOrder(bDefaultSortNum)
						rendererSort:UpdateSorting()
					end
				end

				if addMask then
					CS.AddUIParticleMask(dpGo)
				end
				if preloadCallback then
					dpTrans.gameObject:SetActive(false)
					preloadCallback(dpTrans)
				end

				if endFunc then
					endFunc(dpTrans)
				end

				if not self._wndVisible or self._isHideAllEff then
					CS.ShowObject(dpGo,false)
				end
			end
	)
	dpEff:SetLoadFailFunc(function(dpObj, bundleName)
		if endFunc then
			endFunc()
		end
	end)
	--dpEff:StartLoadEffect()
	self:_InsertIntoLoadList(dpEff)

	return dpEff
end

function LWnd:ChangeEffMaskRect()
	if not self._wndEffectList then
		return
	end
	for k,v in pairs(self._wndEffectList) do
		local tran = v:GetDisplayTrans()
		if CS.IsValidObject(tran) then
			CS.ChangeAllMaskRect(tran.gameObject)
		end
	end
end

function LWnd:CreateWndEffect_Ex(effData)
	if self:IsDestroy() then
		return
	end
	local trans = effData.trans

	if not trans then
		--print("trans is nil")
		return
	end

	local bDefaultSortNum =  effData.bDefaultSortNum or 1
	bDefaultSortNum = bDefaultSortNum or 1
	if bDefaultSortNum <= 0 then
		bDefaultSortNum = 1
	end
	local key = effData.effKey or trans.gameObject.name
	local effectList = self._wndEffectList
	if (not effectList) then
		effectList = {}
		self._wndEffectList = effectList
	end
	local effect = effectList[key]
	if effect then
		if not self._wndVisible or self._isHideAllEff then
			return
		end

		effect:SetVisible(false)
		effect:SetVisible(true)
		return
	end
	local scale = effData.scale or Vector3.New(100,100,100)
	local effName = effData.effName
	local bDefaultLayer = effData.bDefaultLayer
	local bDefaultSorting = effData.bDefaultSorting
	local sortLayer = effData.sortLayer
	local addMask = effData.addMask
	local endFunc = effData.endFunc
	local onVisibleCall = effData.onVisibleCall
	local upSortOrder = effData.upSortOrder or 0
	local preloadCallback = effData.preloadCallback

	---@type LDisplayEffect
	local dpEff = LDisplayEffect:New()
	effectList[key] = dpEff
	dpEff:CreateEffect(trans, effName)
	dpEff:SetOnVisibleCall(onVisibleCall)
	dpEff:SetLoadedFunction(function()
		local dpTrans = dpEff:GetDisplayTrans()
		dpTrans.localPosition = Vector3.zero
		dpTrans.name = effName
		dpEff:SetEffectScale(nil, scale)

		local dpGo = dpTrans.gameObject
		if not bDefaultLayer and dpGo.layer ~= LWnd.WND_LAYER then
			CS.UpdateChildLayer(dpTrans, LWnd.WND_LAYER)
		end

		if not bDefaultSorting then
			local dpParentTrans = dpEff:GetParentTrans()
			if dpParentTrans and CS.IsValidObject(dpParentTrans) then
				local rendererSort = dpParentTrans:GetComponent(typeofUISorting)
				if not rendererSort then
					rendererSort = dpParentTrans.gameObject:AddComponent(typeofUISorting)
				end
				local sortLayer = sortLayer or self:GetWndSortLayer()
				rendererSort:SetLayerName(sortLayer)
				rendererSort:SetParentOrder(self:GetWndSortOrder() + upSortOrder)
				rendererSort:SetInitOrder(bDefaultSortNum)
				if(effData.isCheckInit) then
					rendererSort:SetCheckInitValue(true)
				end
				rendererSort:UpdateSorting()
			end
		end

		if addMask then
			CS.AddUIParticleMask(dpGo)
		end
		if not self._wndVisible or self._isHideAllEff then
			dpEff:SetVisible(false)
		end

		if preloadCallback then
			dpEff:SetVisible(false)
			preloadCallback(dpTrans)
		end

		if endFunc then
			endFunc(dpEff)
		end
	end)
	dpEff:SetLoadFailFunc(function(dpObj, bundleName)
		if endFunc then
			endFunc(dpEff)
		end
	end)
	--dpEff:StartLoadEffect()

	self:_InsertIntoLoadList(dpEff)

	return dpEff
end

function LWnd:SetAllEffectShow(isShow)
	if  self._wndEffectList then
		for k,v in pairs(self._wndEffectList) do
			if isShow then
				v:UpdateVisible()
			else
				local tran = v:GetDisplayTrans()
				if CS.IsValidObject(tran) then
					CS.ShowObject(tran,isShow)
				end
			end
		end
	end


	self._isHideAllEff = not isShow
end

function LWnd:HideWndEffect(key)
	if not self._wndEffectList then
		return
	end
	local eff = self._wndEffectList[key]
	if not eff then
		return
	end
	eff:SetVisible(false)
end

---使用特效预制本身的层级关系
function LWnd:CreateWndEffectImpl(effPara)
	if self:IsDestroy() then
		return
	end
	local trans = effPara.trans
	if not CS.IsValidObject(trans) then
		printErrorN("LWnd:CreateWndEffectImpl(effePara) root is invalid")
		return
	end

	local key = effPara.effKey
	if string.isempty(key) then
		printErrorN("LWnd:CreateWndEffectImpl(effePara) effKey is empty")
		return
	end
	local effectList = self._wndEffectList
	if (not effectList) then
		effectList = {}
		self._wndEffectList = effectList
	end
	local effect = effectList[key]
	if effect then
		if not self._wndVisible or self._isHideAllEff then
			return
		end

		if effPara.callBefore then
			effPara.callBefore(effect)
		end

		effect:SetVisible(false)
		effect:SetVisible(true)
		return
	end

	local scale = effPara.scale or Vector3.New(100,100,100)
	local effName = effPara.effName
	local bDefaultLayer = effPara.bDefaultLayer
	local bDefaultSorting = effPara.bDefaultSorting or false
	local sortOrder =  effPara.sortOrder or 1
	local sortLayer = effPara.sortLayer or self:GetWndSortLayer()
	local addMask = effPara.addMask
	local endFunc = effPara.endFunc
	local onVisibleCall = effPara.onVisibleCall
	local parentOrder = self:GetWndSortOrder()

	local dpEff = LDisplayEffect:New()
	effectList[key] = dpEff
	dpEff:CreateEffect(trans, effName)
	dpEff:SetOnVisibleCall(onVisibleCall)
	dpEff:SetLoadedFunction(
			function()
				local dpTrans = dpEff:GetDisplayTrans()
				dpTrans.localPosition = Vector3.zero
				dpTrans.name = effName
				dpEff:SetEffectScale(nil, scale)

				local dpGo = dpTrans.gameObject
				if not bDefaultLayer and dpGo.layer ~= LWnd.WND_LAYER then
					CS.UpdateChildLayer(dpTrans, LWnd.WND_LAYER)
				end
				local dpParentTrans = dpEff:GetParentTrans()
				if CS.IsValidObject(dpParentTrans) then
					local rendererSort = dpParentTrans:GetComponent(typeofUISorting)
					if not rendererSort then
						rendererSort = dpParentTrans.gameObject:AddComponent(typeofUISorting)
					end
					rendererSort:SetLayerName(sortLayer)
					rendererSort:SetParentOrder(parentOrder)
					rendererSort:SetCheckInitValue(bDefaultSorting)
					rendererSort:SetInitOrder(sortOrder)
					rendererSort:UpdateSorting()
				end

				if addMask then
					CS.AddUIParticleMask(dpGo)
				end
				if not self._wndVisible or self._isHideAllEff then
					dpEff:SetVisible(false)
				end

				if endFunc then
					endFunc(dpEff)
				end
			end
	)
	--dpEff:StartLoadEffect()

	self:_InsertIntoLoadList(dpEff)
	return dpEff

end

-- line render effect
function LWnd:CreateWndLineRenderEffect(trans, effName, effKey, scaleSize, bDefaultLayer, bDefaultSorting, bDefaultSortNum, preloadCallback,scaleSizeY)
end

------------------------------------------------------------------
--- wnd spine
------------------------------------------------------------------
function LWnd:DestroyWndSpinetAll()
	local spineList = self._wndSpineList
	if spineList then
		for k, v in pairs(spineList) do
			v:Destroy()
		end
		self._wndSpineList = nil
	end
end

---@return LDisplaySpine
function LWnd:FindWndSpineByKey(key)
	local spineList = self._wndSpineList
	if not spineList then
		return
	end
	return spineList[key]
end
function LWnd:DestroyWndSpineByKey(key)
	local spineList = self._wndSpineList
	if not spineList then return end
	if spineList[key] then
		spineList[key]:Destroy()
		spineList[key] = nil
	end
end

---@return LDisplaySpine
function LWnd:CreateWndSpine(trans, spineName, spineKey, bDefaultLayer,func,bNotLoaded,isCenter,isFlipX)
	local key = spineKey or trans.gameObject.name
	local spineList = self._wndSpineList
	if (not spineList) then
		spineList = {}
		self._wndSpineList = spineList
	end

	local dpSpine = spineList[key]
	if dpSpine then
		local dpTrans = dpSpine:GetDisplayTrans()
		if CS.IsValidObject(dpTrans)  then
			if func then
				func(dpSpine)
			end
			return dpSpine
		end
		dpSpine:Destroy()
	end
	dpSpine = LDisplaySpine:New()
	spineList[key] = dpSpine
	dpSpine:CreateSpine(trans, spineName,LDisplaySpine.TYPE_UI,self)
	if isFlipX then
		dpSpine:SetFlipX(isFlipX)
	end
	dpSpine:SetLoadedFunction(function()
		local dpTrans = dpSpine:GetDisplayTrans()
		if isCenter then
			dpTrans.anchorMin = Vector2(0.5, 0.5)
			dpTrans.anchorMax = Vector2(0.5, 0.5)
			dpTrans.pivot = Vector2(0.5, 0.5)
		end
		dpTrans.anchoredPosition = Vector2.zero
		dpTrans.localScale = Vector3.one

		if not bDefaultLayer and dpTrans.gameObject.layer ~= LWnd.WND_LAYER then
			CS.UpdateChildLayer(dpTrans, LWnd.WND_LAYER)
		end
		if func then
			func(dpSpine)
		end
	end)
	dpSpine:SetLoadFailFunc(function(dpObj, bundleName)
		if func then
			func(dpSpine)
		end
	end)
	if not bNotLoaded then dpSpine:StartLoad() end
	return dpSpine
end

---非ui 模式
function LWnd:CreateWndSpineImpl(spinePara)
	if not CS.IsValidObject(spinePara.trans) then
		printErrorN("LWnd:CreateWndSpineImpl(spinePara) root is invalid")
		return
	end

	if string.isempty(spinePara.key) then
		printErrorN("LWnd:CreateWndSpineImpl(spinePara) key is empty")
		return
	end

	local key = spinePara.key
	local spineList = self._wndSpineList
	if (not spineList) then
		spineList = {}
		self._wndSpineList = spineList
	end
	---@type LDisplaySpine
	local dpSpine = spineList[key]
	if dpSpine then
		local dpTrans = dpSpine:GetDisplayTrans()
		if CS.IsValidObject(dpTrans)  then
			return
		end
		dpSpine:Destroy()
	end
	dpSpine = LDisplaySpine:New()
	spineList[key] = dpSpine

	local scale = spinePara.scale or 100
	local bDefaultLayer = spinePara.bDefaultLayer
	local func = spinePara.endFunc
	local bNotLoaded = spinePara.bNotLoaded
	local sortOrder = spinePara.sortOrder or 1
	local sortLayer = spinePara.sortLayer or self:GetWndSortLayer()
	local parentOrder = self:GetWndSortOrder()


	dpSpine:CreateSpine(spinePara.trans, spinePara.spineName,LDisplaySpine.TYPE_MODEL,self,spinePara.replaceStatus)
	dpSpine:SetLoadedFunction(function(spine)
		local dpTrans = spine:GetDisplayTrans()
		spine:SetScale(scale)

		if not bDefaultLayer and dpTrans.gameObject.layer ~= LWnd.WND_LAYER then
			CS.UpdateChildLayer(dpTrans, LWnd.WND_LAYER)
		end

		local dpParentTrans = spine:GetParentTrans()
		if CS.IsValidObject(dpParentTrans) then
			local rendererSort = dpParentTrans:GetComponent(typeofUISorting)
			if not rendererSort then
				rendererSort = dpParentTrans.gameObject:AddComponent(typeofUISorting)
			end
			rendererSort:SetLayerName(sortLayer)
			rendererSort:SetParentOrder(parentOrder)
			rendererSort:SetCheckInitValue(false) ---spine 一般是单独存在
			rendererSort:SetInitOrder(sortOrder)
			rendererSort:UpdateSorting()
		end

		if func then
			func(spine)
		end
	end)
	if not bNotLoaded then
		dpSpine:StartLoad()
	end
	return dpSpine
end

------------------------------------------------------------------
--- wnd spine
------------------------------------------------------------------
function LWnd:DestroyWndPrefabAll()
	local uiPrefabList = self._uiPrefabList
	if not uiPrefabList then return end
	for k,v in pairs(uiPrefabList) do
		v:Destroy()
	end
	self._uiPrefabList = nil
end

function LWnd:DestroyWndPrefabByKey(key)
	local uiPrefabList = self._uiPrefabList
	if not uiPrefabList then return end
	local prefabInfo = uiPrefabList[key]
	if prefabInfo then
		local parentTrans = prefabInfo.parentTrans
		if (CS.IsValidObject(parentTrans)) then
			LxResUtil.DestroyObject(parentTrans)
		end
		uiPrefabList[key] = nil
	end
end

function LWnd:CreateWndPrefab(trans,prefabName,prefabKey,func,resType)
	if self:IsDestroy() then return end
	if not trans or not CS.IsValidObject(trans) then return end

	resType = resType or CS.RES_UI_WND
	local resPath = CS.ResPath(resType, prefabName)
	local first, last = string.match(resPath,"(.*)/(.+)")

	local instanceId = self:FindInstanceID(trans)
	if not self._uiPrefabList then
		self._uiPrefabList = {}
	end
	local old = self._uiPrefabList[instanceId]
	if old then
		old:Destroy()
	end

	local disObj = LDisplayPrefab:New()
	self._uiPrefabList[instanceId] = disObj
	disObj:CreatePrefab(trans,first,prefabName)
	disObj:SetLoadedFunction(function (dp)
		if func then
			func(dp:GetDisplayTrans())
		end
	end)
	disObj:StartLoad()
end

function LWnd:_InsertIntoLoadList(effectObj)
	if not self._effLoadList then
		self._effLoadList = {}
	end

	table.insert(self._effLoadList,effectObj)


	if self:IsTimerExist("_wnd_display_eff_load") then
		return
	else
		local para = {
			key = "_wnd_display_eff_load",
			loopcnt = -1,
			interval = 0,
			func = function() self:_LoadEffectImpl() end
		}
		self:TimerStartImpl(para)
	end

end

function LWnd:_LoadEffectImpl()
	if self._effLoadList then
		local obj = table.remove(self._effLoadList,1)
		if obj then
			if not obj:IsDestroy() then
				obj:StartLoadEffect()
			end

			return
		end
	end

	self:TimerStop("_wnd_display_eff_load")
end