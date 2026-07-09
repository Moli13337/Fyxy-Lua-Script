---
--- Created by Admin.
--- DateTime: 2023/10/7 11:09
---
------------------------------------------------------------------
local CS = CS
local YXTween = YXTween
local typeUIImage = typeof(UnityEngine.UI.Image)
local typeUISlider = typeof(UnityEngine.UI.Slider)
local typeXUISlider = typeof(CardEHT.YXUISlider)

-----------------------------------------------------------------
---@class UIProgress
local UIProgress = LxClass("UIProgress", nil)
------------------------------------------------------------------

--initialize
------------------------------------------------------------------
function UIProgress:UIProgress()
	self._progressObj = nil
	self._slider = nil
	self._image = nil
	self._tween = nil
	self._onValueChange = nil

	self._xuiSlider =nil
end

function UIProgress:Create(object,default)
	self._progressObj = object

	if (object) then
		local slider = object:GetComponent(typeUISlider)
		if slider and slider.enabled then
			self._slider = slider
        else
            local uiImage = object:GetComponent(typeUIImage)
            if uiImage and uiImage.enabled then
                self._image = uiImage
            end
		end

	end

	self:SetUIProgress(default or 0)
end

function UIProgress:IsDpObjectSame(obj)
    if not CS.IsValidObject(self._progressObj) then
        return false
    end

    return obj == self._progressObj
end
------------------------------------------------------------------

--set progress func
------------------------------------------------------------------
function UIProgress:SetUIProgress(value)
    if not CS.IsValidObject(self._progressObj) then return end
	if CS.IsValidObject(self._slider) then
		self._slider.value = value
		return
	end

	if CS.IsValidObject(self._image) then
		self._image.fillAmount = value
		return
	end
end
function UIProgress:GetTrans()
	return self._progressObj
end
function UIProgress:GetUIProgress()
	if self._slider then
		return self._slider.value
	end

	if self._image then
		return self._image.fillAmount
	end
	return 0
end

function UIProgress:DoOnValueChange(value)
	if self._onValueChange ~= nil then
		self._onValueChange(value)
	end
end

function UIProgress:SetOnValueChange(fun)
	self._onValueChange = fun
end

function UIProgress:SetProgress(progress,time)
	self:StopProgressTween()
	if time and time > 0 then
		local nowprogress = self:GetUIProgress()
		self:SetProgressTween(nowprogress,progress,time)
	else
		self:SetUIProgress(progress)
		self:DoOnValueChange(progress)
	end
end

function UIProgress:StopProgressTween()
	if not self._tween then return end
	self._tween:Kill(false)
	self._tween = nil
end

function UIProgress:SetProgressTween(from,to,duration)
	local tween = YXTween.NumberTo(from,to,duration,function(f)
		self:SetUIProgress(f)
		self:DoOnValueChange(f)
	end)
	self._tween = tween
	tween:PlayForward()
end

function UIProgress:SetSliderDelegate(func)
	if self._progressObj then
		if not self._xuiSlider then
			self._xuiSlider = self._progressObj.gameObject:GetComponent(typeXUISlider)
			if not self._xuiSlider then
				self._xuiSlider = self._progressObj.gameObject:AddComponent(typeXUISlider)
			end
		end

		self._xuiSlider.onValueChanged = func
	end
end

function UIProgress:SetInteractable(isInteractable)
	if self._slider then
		self._slider.interactable = isInteractable
	end
end

------------------------------------------------------------------
-- clear Reference
function UIProgress:CleanUp()
	self._progressObj = nil
	self._slider = nil
	self._image = nil
	if self._tween then
		self._tween:Kill(false)
		self._tween = nil
	end
	self._onValueChange = nil
end

return UIProgress
