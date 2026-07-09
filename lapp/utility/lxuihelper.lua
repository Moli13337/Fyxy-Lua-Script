---
--- Created by Administrator.
--- DateTime: 2023/10/10 10:12
---
------------------------------------------------------------------
--- 窗口内部接口 界面不可直接调用本类
------------------------------------------------------------------
local CS = CS
local UnityEngine = UnityEngine
local typeof = typeof
local typeUIText = typeof(CS.YXUIText)
local typeUITextInput = typeof(CS.YXUITextInput)
local typeUIToggle = typeof(UnityEngine.UI.Toggle)
local typeUIImage = typeof(UnityEngine.UI.Image)
local typeUISlider = typeof(UnityEngine.UI.Slider)
local YXUIClickListener = CS.YXUIClickListener
local BuildingClick = CS.BuildingClick
local SpineClick = CS.SpineClick
local typeofYXUIStateActor = typeof(CS.YXUIStateActor)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local VertexGradient = TMPro.VertexGradient
local TextAlignmentOptions = TMPro.TextAlignmentOptions
local RectTransformAxisHorizontal = UnityEngine.RectTransform.Axis.Horizontal
local RectTransformAxisVertical = UnityEngine.RectTransform.Axis.Vertical
local typeOfDragFilter = typeof(CS.YXUIDragFilter)
local typeOfSpriteRenderer = typeof(UnityEngine.SpriteRenderer)
local typeCollider2D = typeof(UnityEngine.Collider2D)
local typeTextMeshPro = typeof(CS.TextMeshPro)

local typeGridLayoutGroup = typeof(CS.GridLayoutGroup)
local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)

local typeSpriteRenderer = typeof(UnityEngine.SpriteRenderer)

local YXTween = YXTween
------------------------------------------------------------------
---@class LxUiHelper
local LxUiHelper = {}

------------------------------------------------------------------
--- textmesh text && input
------------------------------------------------------------------
function LxUiHelper.FindXTextCtrl(trans)
    if not trans then return end

    return trans:GetComponent(typeUIText)
end

function LxUiHelper.GetXTextMeshProCtrl(trans)
    if not trans then return end

    return trans:GetComponent(typeTextMeshPro)
end

function LxUiHelper.SetXTextMeshProLineWithLanguage(trans, addLine,notWrap)
    if not trans then return end

    local uiText = LxUiHelper.GetXTextMeshProCtrl(trans)
    if not uiText then return end

    trans = trans.transform
    addLine = addLine or 0
    local lineSpacing = uiText.lineSpacing
    uiText.enableWordWrapping = notWrap == nil and true or notWrap
    uiText.lineSpacing = lineSpacing + addLine
end

function LxUiHelper.SetXTextMeshProSizeWithLanguage(trans, addLine)
    if not trans then return end

    local uiText = LxUiHelper.GetXTextMeshProCtrl(trans)
    if not uiText then return end

    trans = trans.transform
    addLine = addLine or 0
    local fontSize = uiText.fontSize
    uiText.fontSize = fontSize + addLine
end

function LxUiHelper.GetFontMaterialPath(fontName, matPathName)
    local assetPath = "default"
    if not string.isempty(fontName) then
        local fontPath = gLGameLanguage:GetFontPathByFontName(fontName)
        if not string.isempty(fontPath) then
            assetPath = fontPath
        end
    end
    return string.format("Font/SysFont/%s/%s.mat", assetPath, matPathName)
end

function LxUiHelper.GetXUITextTextLanguage(uiText, forceMatName)
    local isChangeFont = true
    if LGameData.isUseWxFont then
        isChangeFont = false -- 微信平台使用微信字体不切换字体
    end
    local sysFontChangeName = nil
    local materialChangeName = nil
    local artFontChangeName = nil
    local isNeedLoad = false
    if uiText.font then
        local fontName = uiText.font.name
        local matName = nil
        local langFontName = gLGameLanguage:GetFontName(fontName)
        local fileName = string.lastselection(langFontName)
        if fileName ~= fontName and isChangeFont then
            isNeedLoad = true
            sysFontChangeName = string.format("Font/SysFont/%s.asset", langFontName)
            if uiText.fontSharedMaterial then
                matName = uiText.fontSharedMaterial.name
            end
        end
        if not string.isempty(forceMatName) then
            matName = forceMatName
        end
        if matName then
            isNeedLoad = true
            local markPos = string.find(matName, '_')
            if markPos then
                local newMatName = fileName
                newMatName = newMatName..string.sub(matName, markPos)
                materialChangeName = LxUiHelper.GetFontMaterialPath(fontName, newMatName)
            end
        end
    end
    if uiText.spriteAsset then
        local fontName =  uiText.spriteAsset.name
        local langFontName = gLGameLanguage:GetFontName(fontName)
        local fileName = string.lastselection(langFontName)
        if fileName ~= fontName then
            isNeedLoad = true
            artFontChangeName = string.format("Font/ArtFont/%s.asset", langFontName)
        end
    end
    return isNeedLoad, sysFontChangeName, materialChangeName, artFontChangeName
end


function LxUiHelper.SetXTextOverflowMode(trans, mode)
    local uiText = LxUiHelper.FindXTextCtrl(trans)
    if not uiText then return end

    uiText:SetOverflowMode(mode)
end

function LxUiHelper.SetXTextColor(trans, color)
    local uiText = LxUiHelper.FindXTextCtrl(trans)
    if not uiText then return end

    uiText.color = color
end
function LxUiHelper.SetXTextSelect(trans, func)
    if not trans then return end

    CS.SetSelect(trans.gameObject, func)
end
function LxUiHelper.SetXTextSubmit(trans, func)
    if not trans then return end

    CS.SetSubmit(trans.gameObject, func)
end
function LxUiHelper.FindXTextInputCtrl(trans)
    if not trans then return end

    local uiInput,holdText,showText
    uiInput = trans:GetComponent(typeUITextInput)
    local objHolder = trans:Find("Placeholder")
    if not objHolder then
        objHolder = uiInput.placeholder
    end
    if (objHolder) then
        holdText = objHolder:GetComponent(typeUIText)
    end

    local objText = trans:Find("Text")
    if not objText then
        objText = uiInput.textComponent
    end
    if (objText) then
        showText = objText:GetComponent(typeUIText)
    end
    return uiInput,holdText,showText
end

--- func(string)
function LxUiHelper.SetXTextInput_ValueChanged(trans, func)
    if not trans then return end

    local csInputField = trans:GetComponent(typeUITextInput)
    if not csInputField then return end

    local csObj = csInputField.onValueChanged
    csObj:RemoveListener(func)
    csObj:AddListener(func)
end

--- func(string)
function LxUiHelper.SetXTextInput_EndEdit(trans, func)
    if not trans then return end

    local csInputField = trans:GetComponent(typeUITextInput)
    if not csInputField then return end

    local csObj = csInputField.onEndEdit
    csObj:RemoveListener(func)
    csObj:AddListener(func)
end

--- func(sText, iCharIndex, cAddedChar) return cAddedChar
function LxUiHelper.SetXTextInput_ValidateInput(trans, func)
    if not trans then return end
    local csInputField = trans:GetComponent(typeUITextInput)
    if not csInputField then return end

    csInputField.onValidateInput = func
end

local activityTitleImgs = {
    [1] = "activity5_itembg1",
    [2] = "activity5_itembg2",
    [3] = "activity5_itembg3",
    [4] = "activity5_itembg3"
}

local activityTxtColor = {
    [1] = "734F22FF",
    [2] = "734F22FF",
    [3] = "734F22FF",
    [4] = "734F22FF"
}

function LxUiHelper.GetActivityTitleImg(type)
    return activityTitleImgs[type]
end

function LxUiHelper.SetActivityTextColor(trans,type)
    local uiText = LxUiHelper.FindXTextCtrl(trans)
    if not uiText then return end

    local color = activityTxtColor[type]
    uiText.color = LUtil.ColorByHex(color)
end

function LxUiHelper.SetTextFontSize(trans,size)
    local uiText = LxUiHelper.FindXTextCtrl(trans)
    if not uiText then return end

    uiText.fontSize = size
end
---------------------------------------------------------------------
--- Slider
---------------------------------------------------------------------
function LxUiHelper.FindSliderCtrl(trans)
    if not trans then return end

    return trans:GetComponent(typeUISlider)
end
---------------------------------------------------------------------
--- Image
---------------------------------------------------------------------
function LxUiHelper.FindImageCtrl(trans)
    if not trans then return end

    return trans:GetComponent(typeUIImage)
end

function LxUiHelper.SetImageGray(trans,enabled)
    if not trans then return end
    local uiImage = trans:GetComponent(typeUIImage)
    if not uiImage then return end

    if not enabled then
        uiImage.material = nil
        return
    end

    local matName = "ui_gray"
    if not uiImage.material or uiImage.material.name ~= matName then
        uiImage.material = LxResUtil.GetUiGrayMaterial()
    end
end
function LxUiHelper.SetImageColor(trans,color)
    if not trans then return end

    local uiImage = trans:GetComponent(typeUIImage)
    if not uiImage then return end

    uiImage.color = color
end

function LxUiHelper.SetImageAlpha(trans,value)
    if not CS.IsValidObject(trans) then return end

    local uiImage = trans:GetComponent(typeUIImage)
    if not uiImage then return end

    local color = uiImage.color
    local newColor = Color.New(color.r,color.g,color.b,value)
    uiImage.color = newColor
end

function LxUiHelper.SetSpriteRendererSortingOrder(trans,sorting)
    if CS.IsNullObject(trans) then return end

    local spriteRenderer = trans:GetComponent(typeOfSpriteRenderer)
    if not CS.IsValidObject(spriteRenderer) then return end

    spriteRenderer.sortingOrder = sorting
end
---------------------------------------------------------------------
--- Toggle
---------------------------------------------------------------------
--- toggle监听方法
function LxUiHelper.SetToggle_ValueChanged(trans, func)
    if not trans then return end

    local csToggle = trans:GetComponent(typeUIToggle)
    if not csToggle then return end

    local csObj = csToggle.onValueChanged
    csObj:RemoveListener(func)
    csObj:AddListener(func)
end

function LxUiHelper.SetToggle_IsOn(trans, value)
    if not trans then return end

    local csToggle = trans:GetComponent(typeUIToggle)
    if not csToggle then return end

    csToggle.isOn = value
end

---------------------------------------------------------------------
--- Progress / Slider
---------------------------------------------------------------------
--- func(float)
function LxUiHelper.SetProgress_ValueChanged(trans, func)
    if not trans then return end
    local csObj = trans:GetComponent(typeUISlider)
    if not csObj then return end
    local csEvent = csObj.onValueChanged
    csEvent:RemoveListener(func)
    csEvent:AddListener(func)
end
function LxUiHelper.SetProgress(trans, progress)
    if not trans then return end
    local slider = trans:GetComponent(typeUISlider)
    if slider and slider.enabled then
        slider.value = progress
        return
    end
    local uiImage = trans:GetComponent(typeUIImage)
    if uiImage and uiImage.enabled then
        uiImage.fillAmount = progress
        return
    end
end

---------------------------------------------------------------------
---
---------------------------------------------------------------------
LxUiHelper.__progressTween = nil
function LxUiHelper.ProgressAnimation(progressData,funcs,time)
	if LxUiHelper.__progressTween ~= nil then
		LxUiHelper.__progressTween:Kill(false)
		LxUiHelper.__progressTween = nil
	end

	local data = LxUiHelper.SetProgressData(progressData)
	local func = LxUiHelper.SetProgressFunc(funcs)
	local round = 1
	local form,limit,to = data.form,data.limitList,data.to
	local singleTime = time / #progressData[3]
	local singleForm,singleTo

	func.backFunc = function(isNotLastTween)
		round = round + 1
		func.endFunc(isNotLastTween)
		if round <=  #limit then
			singleTo = round == #limit and to or limit[round]
			singleForm = 0
			LxUiHelper.SingleProgressTwn({form = singleForm,to = singleTo,time = singleTime,limit = limit[round], isNotLastTween = round + 1 <=  #limit },func)
		else
			LxUiHelper.ProgressTwnKill()
		end
	end
	singleForm = form
	singleTo = #limit == 1 and to or limit[round]
	LxUiHelper.SingleProgressTwn({form = singleForm,to = singleTo,time = singleTime,limit = limit[round], isNotLastTween = #limit ~= 1},func)
end

function LxUiHelper.SingleProgressTwn(tween,funcs)
	local progress = LxUiHelper.__progressTween
	if not progress then
		progress = YXTween.TweenSequenceIns()
		LxUiHelper.__progressTween = progress
		local tweennum = YXTween.TweenInt(tween.form, tween.to, tween.time,function(ival)
			funcs.func(ival,tween.limit)
		end)
		progress:Insert(0,tweennum)
		progress:OnComplete(function()
            LxUiHelper.ProgressTwnKill()
            funcs.backFunc(tween.isNotLastTween)
        end)
		progress:PlayForward()
	end
end

function LxUiHelper.ProgressTwnKill()
	local progress = LxUiHelper.__progressTween
	if not progress then return end

	progress:Kill()
	progress = nil
	LxUiHelper.__progressTween = nil
end

function LxUiHelper.SetProgressData(data)
	return {form = data[1],to = data[2],limitList = data[3]}
end

function LxUiHelper.SetProgressFunc(data)
	return {func = data[1],endFunc = data[2]}
end
------------------------------------------------------------------
---
---
function LxUiHelper.GetRelativePath(rootName,tran)
    if not tran then return end
    if not CS.IsValidObject(tran) then return end

    local transform = tran.transform
    local stringBuilder = {}
    local name = transform.name
    table.insert(stringBuilder,name)
    local temp = transform.parent
    while CS.IsValidObject(temp) do
        name = temp.name
        table.insert(stringBuilder,name)
		if name == rootName then
			break
		end
        temp = temp.parent
    end
    local  t =table.reverse(stringBuilder)
    local path = table.concat(t,"/")
    return path
end

function LxUiHelper.GetClickDelegate(target,type)
    local func = function()
        if not CS.IsValidObject(target) then return end

        local clickHandle
        if type == 1 then
            clickHandle = YXUIClickListener.Get(target.gameObject)
        elseif type ==2 then
            clickHandle = BuildingClick.Get(target.gameObject)
        end
        if not clickHandle then return end

        clickHandle:excuteClick()
    end
    return func
end

function LxUiHelper.IsImgPathValid(path)
    if not path then return false end
    if string.isempty(path) then return false end

	path = gLGameLanguage:GetResName(path)
    local atlas = LxResPathUtil.GetSpriteAtlasPath(path)
    if string.isempty(atlas) then return false end

    return true
end

function LxUiHelper.SetImageNativeSize(trans)
    if not CS.IsValidObject(trans) then return end
    local uiImage = trans:GetComponent(typeUIImage)
    if not  CS.IsValidObject(uiImage) then return end
    uiImage:SetNativeSize()
end

-----------------------------------------------------------------
---soundRefId == nil, 通用点击LSoundConst.CLICK_BUTTON_COMMON
---soundRefId == 0,  不播声音
---soundRefId > 0, 参考LSoundConst
function LxUiHelper.SetTransLongClick(trans, func, longThresHold, isRepeat, soundRefId,pointerUpFunc)
    if not trans then return end
    local audioName = LxResPathUtil.GetAudioSoundName(trans.name, soundRefId)
    CS.SetLongClick(trans.gameObject, function()
        if not string.isempty(audioName) then
            if gLGameAudio then
                gLGameAudio:PlaySound(audioName)
            end
        end
        if func then
            func()
        end
    end, longThresHold, isRepeat)
    CS.SetPointerUp(trans.gameObject,function ()
        if pointerUpFunc then
            pointerUpFunc()
        end
    end)
end

---soundRefId == nil, 通用点击LSoundConst.CLICK_BUTTON_COMMON
---soundRefId == 0,  不播声音
---soundRefId > 0, 参考LSoundConst
function LxUiHelper.SetTransClick(trans, func, soundRefId)
    if not trans then return end

    local audioName = LxResPathUtil.GetAudioSoundName(trans.name, soundRefId)
    CS.SetClick(trans.gameObject, function()
        if not string.isempty(audioName) then
            if gLGameAudio then
                gLGameAudio:PlaySound(audioName)
            end
        end
        if LOG_INFO_ENABLED then
            local path = LxUiHelper.GetRelativePath("UICanvas",trans)
            if path then
                printInfoN("click path "..path)
            end
        end
        if func then
            func()
        end
        FireEvent(EventNames.ON_CLICK_BUTTON,trans)
    end)
end

function LxUiHelper.PlayAudioSoundName(soundRefId)
    local soundName = LxResPathUtil.GetAudioSoundNameByRefId(soundRefId)
    gLGameAudio:PlaySound(soundName)
end

function LxUiHelper.SetAnchoredPosition(trans,x,y)
    if not CS.IsValidObject(trans) then return end

    local rectTran = trans:GetComponent(typeOfRectTransform)
    local posX = x or 0
    local posY = y or 0
    local pos = Vector2.New(posX,posY)
    rectTran.anchoredPosition = pos
end

function LxUiHelper.SetCanvasGroupAlpha(tran,alpha)
    if not CS.IsValidObject(tran) then return end
    local canvasGroup = tran:GetComponent(typeofCanvasGroup)
    if not canvasGroup then return end

    canvasGroup.alpha = alpha
end

--设置颜色渐变
function LxUiHelper.SetTextColorGradientStr(trans,colorStr)
    if string.isempty(colorStr)then return end

    local arr = string.split(colorStr,"|")
    if not arr[2] then return end

    local topColor = LUtil.ColorByHex_6(arr[1])
    local bottomColor = LUtil.ColorByHex_6(arr[2])
    LxUiHelper.SetTextColorGradient(trans,topColor,topColor,bottomColor,bottomColor)
end

function LxUiHelper.SetTextColorGradient(trans,topleft,topRight,bottomLeft,bottomRight)
    if not VertexGradient then return end
    local xuitext = LxUiHelper.FindXTextCtrl(trans)
    if not xuitext then return end

    xuitext.enableVertexGradient = true
    local vg = VertexGradient()
    vg.topLeft = topleft
    vg.topRight = topRight
    vg.bottomLeft = bottomLeft
    vg.bottomRight = bottomRight
    xuitext.colorGradient = vg
end

function LxUiHelper.SetSizeWithCurAnchor(tran,axis,value)
    if not CS.IsValidObject(tran) then return end

    local rectAxis = RectTransformAxisHorizontal
    if axis == 1 then
        rectAxis = RectTransformAxisVertical
    end
    tran:SetSizeWithCurrentAnchors(rectAxis,value)
end

function LxUiHelper.FilterScrollItem(tran,index)
    if not CS.IsValidObject(tran) then return end
    local dragFilter = tran:GetComponent(typeOfDragFilter)
    if not dragFilter then return end

    index = index or 0
    dragFilter:FilterIndex(index)
end

function LxUiHelper.StopFilterMove(tran)
    if not CS.IsValidObject(tran) then return end
    local dragFilter = tran:GetComponent(typeOfDragFilter)
    if not dragFilter then return end

    dragFilter:StopMove()
end

function LxUiHelper.GetColliderPosAndSize(tran,path,wndTran)
    local size = Vector2.New(0,0)
    local center = Vector2.New(0,0)
    if not CS.IsValidObject(tran) or not CS.IsValidObject(wndTran) then
        return size,center
    end

    local target =CS.FindTrans(tran,path)
    if not CS.IsValidObject(target) then
        return size,center
    end

    local cam  = gLGameScene:GetCurrentSceneCamera()
    local uiCam = LGameUI:GetUICamera()

    local collider = target:GetComponent(typeCollider2D)
    local bounds = collider.bounds
    center = cam:WorldToScreenPoint(bounds.center)

    local point1 =  Vector3.New(bounds.min.x, bounds.min.y, bounds.min.z)
    local point2 =  Vector3.New(bounds.max.x, bounds.max.y, bounds.max.z)

    local uiPos1 = cam:WorldToScreenPoint(point1)
    local uiPos2 = cam:WorldToScreenPoint(point2)

    local localPos1 = CS.YXUIPointUtil.InverseScreenPoint(wndTran,uiPos1,uiCam)
    local localPos2 = CS.YXUIPointUtil.InverseScreenPoint(wndTran,uiPos2,uiCam)

    size = Vector2.New(localPos2.x - localPos1.x,localPos2.y - localPos1.y)
    return size,center
end

function LxUiHelper.GetRectPosAndSize(rectTran,wndTran)
    local size,center = Vector2.zero,Vector2.zero
    if not CS.IsValidObject(rectTran) then
        return size,center
    end
    local worldCorners = rectTran:GetWorldCorners()

    local left = worldCorners[0]
    local right = worldCorners[2]

    local uiCam = LGameUI:GetUICamera()

    local uiPos1 = uiCam:WorldToScreenPoint(left)
    local uiPos2 = uiCam:WorldToScreenPoint(right)

    center = (uiPos1 + uiPos2)/2

    local localPos1 = CS.YXUIPointUtil.InverseScreenPoint(wndTran,uiPos1,uiCam)
    local localPos2 = CS.YXUIPointUtil.InverseScreenPoint(wndTran,uiPos2,uiCam)

    size = Vector2.New(math.abs(localPos2.x - localPos1.x),math.abs(localPos2.y - localPos1.y))

    return size,center
end

function LxUiHelper.SetLayoutPadding(tran,padding)
    local layout = tran:GetComponent(typeGridLayoutGroup)
    if not layout then
        layout = tran:GetComponent(typeVerticalLayoutGroup)
        if not layout then
            layout = tran:GetComponent(typeHorizontalLayoutGroup)
        end
    end
    if not layout then return false end

    layout.padding.left = padding.x
    layout.padding.right = padding.y
    layout.padding.top = padding.z
    layout.padding.bottom = padding.w
end

function LxUiHelper.GetTMPAlignment(index)
    --参考TextAlignmentOptions.cs 文件内的枚举
    local textAlignmentOptions = TextAlignmentOptions
    if not TextAlignmentOptions then return end

    if index == 1 then
        --左上
        return textAlignmentOptions.TopLeft
    elseif index == 2 then
        --上
        return textAlignmentOptions.Top
    elseif index == 3 then
        --右上
        return textAlignmentOptions.TopRight
    elseif index == 4 then
        --左
        return textAlignmentOptions.Left
    elseif index == 5 then
        --中
        return textAlignmentOptions.Center
    elseif index == 6 then
        --右
        return textAlignmentOptions.Right
    elseif index == 7 then
        --左下
        return textAlignmentOptions.BottomLeft
    elseif index == 8 then
        --下
        return textAlignmentOptions.Bottom
    elseif index == 9 then
        --右下
        return textAlignmentOptions.BottomRight
    else
        --默认居中
        return textAlignmentOptions.Center
    end
end

--- isH:1为横向，2为纵向
function LxUiHelper.SetLayoutConstraintCount(tran,count,isH)
    if not count then return end
    local layout = tran:GetComponent(typeGridLayoutGroup)
    if not layout then return end

    if isH then
        layout.constraint = isH
    end
    layout.constraintCount = count
end

function LxUiHelper.SetNormalTextClick(tran,func)
    if not CS.YXUITextClick then return end

    local typeName = typeof(CS.YXUITextClick)
    local com = tran:GetComponent(typeName)
    if not CS.IsValidObject(com) then
        com = tran.gameObject:AddComponent(typeName)
    end
    local uiCamera = LGameUI.GetUICamera()
    com:SetCamera(uiCamera)
    com:SetCallBack(func)
end

local interfaceRecord = {}

function LxUiHelper.CheckInterfaceValid(typeName,methodName)
    local record =  interfaceRecord[typeName]
    if not record then
        record = {}
        interfaceRecord[typeName] = record
    end

    local isExist = record[methodName]

    if isExist == nil then
        isExist = tolua.getmethod(typeName,methodName) ~= nil
        record[methodName] = isExist
    end

    return isExist
end

function LxUiHelper.SetTextureData(com,data)
    if not CS.IsValidObject(com) then return end

    com:FillImageStr(data)
end

function LxUiHelper.SetTextOverflow(textComponent)
    textComponent.enableWordWrapping = true;
    textComponent.overflowMode = TMPro.TextOverflowModes.Overflow;
end

function LxUiHelper.SetTextOverflowList(textComponents)
    for i = 1, #textComponents do
        LxUiHelper.SetTextOverflow(textComponents[i])
    end
end

function LxUiHelper.FindSceneSprite(trans)
    if CS.IsNullObject(trans) then
        return nil
    end
    return trans:GetComponent(typeSpriteRenderer)
end
function LxUiHelper.SetSceneSpriteGray(trans,enabled)
    if (trans) then
        local obj = trans.gameObject
        local sprite = trans:GetComponent(typeSpriteRenderer)
        if (sprite) then

            local mat = nil
            if not enabled then
                mat = LxResUtil.GetSpriteDefaultMaterial()
            else
                mat = LxResUtil.GetSpriteGrayMaterial()
            end

            if mat then
                sprite.material = mat
            end

        end
    end
end

return LxUiHelper


