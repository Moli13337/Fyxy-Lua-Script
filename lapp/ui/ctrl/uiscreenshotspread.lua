---
--- Created by LCM.
--- DateTime: 2024/3/21 21:00:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIScreenShotSpread:LWnd
local UIScreenShotSpread = LxWndClass("UIScreenShotSpread", LWnd)
------------------------------------------------------------------
local CS = CS
local PostProcess = CS.PostProcess
local UScreen = UnityEngine.Screen
local UGraphics = UnityEngine.Graphics
local URenderTextureFormat = UnityEngine.RenderTextureFormat
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeofCustomAxis = typeof(CardEHT.YXTileMapCustomAxis)


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIScreenShotSpread:UIScreenShotSpread()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIScreenShotSpread:OnWndClose()
	self:ClearCameraRT()
	self:ClearSceneShot()

	LxTimer.DelayTimeStop(self._delayShowTimer)
	LxTimer.DelayTimeStop(self._delayCloseTimer)
	
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIScreenShotSpread:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIScreenShotSpread:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitData()
	self:InitEvent()
	self:InitView()

	gLxTKData:OnTAClientEventReq(LxTKData.SOCIAL_SHARE_PHOTO,"截图分享弹框")
end
function UIScreenShotSpread:ClearCameraRT()
	if self._sceneCamera then
		self._sceneCamera.targetTexture = nil
	end
	if self._uiCamera then
		self._uiCamera.targetTexture = nil
	end
end

function UIScreenShotSpread:InitText()
	self:SetWndText(self.mShareDesc,ccClientText(10176))
	self:InitTextLineWithLanguage(self.mShareDesc, -30)
	self:SetWndText(self.mWXBtnName,ccClientText(20818))
	self:SetWndText(self.mPYQBtnName,ccClientText(20819))
	self:SetWndText(self.mKKBtnName,ccClientText(20861))
	self:SetWndText(self.mFBBtnName,ccClientText(20862))
end

function UIScreenShotSpread:InitEvent()
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mWXBtn,function()
		self:SaveImg(LShareConst.SCENE_WX_PY)
	end)

	self:SetWndClick(self.mPYQBtn,function()
		self:SaveImg(LShareConst.SCENE_WX_PYQ)
	end)

	self:SetWndClick(self.mKKBtn,function()
		self:SaveImg(LShareConst.SCENE_KOREA_KAKAO)
	end)

	self:SetWndClick(self.mFBBtn,function()
		self:SaveImg(LShareConst.SCENE_FACE_BOOK)
	end)
end

function UIScreenShotSpread:StartCloseWnd()
	local delayTimerClose = gModelPlayer:GetRoleConfigRefByKey("shareAutoClose") or 6
	self._delayCloseTimer = LxTimer.DelayTimeCall(function ()
		self._delayCloseTimer = nil
		self:WndClose()
	end, delayTimerClose)
end
function UIScreenShotSpread:SaveImg(saveType)
	CS.ShowObject(self.mShotDiv, true)
	CS.ShowObject(self.mMaskBg, true)

	local list = {self.mShotDiv,self.mMaskBg}
	local isShare = false
	local shareData
	local str = "保存图片"

	if saveType and saveType > 0 then
		isShare = self._isShowShare
		shareData = {shareScene=saveType,shareLocation="jiepingfenxiang"}
		str = LShareConst.TA_ATTR_MAP[saveType] or ""
	end

	LxTimer.DelayTimeStop(self._delayCloseTimer)

	--CS.ShowObject(self.mCodeImg, true)
	gLGameUI:CaptureUIScreen(self:GetWndTrans(),list,isShare, shareData,function()
		if not self:IsWndValid() then return end
		self:StartCloseWnd()
	end)

	CS.ShowObject(self.mShotDiv, false)
	CS.ShowObject(self.mMaskBg, false)

	gLxTKData:OnTAClientEventReq(LxTKData.SOCIAL_SHARE_PHOTO,"截图分享点击",str)

end
function UIScreenShotSpread:ClearSceneShot()
	if self._srcRT then
		if CS.IsValidObject(self._srcRT) then
			LRTHelper.ReleaseTemporary(self._srcRT)
		end
		self._srcRT = nil
	end

	if self._desRT then
		if CS.IsValidObject(self._desRT) then
			LRTHelper.ReleaseTemporary(self._desRT)
		end
		self._desRT = nil
	end

	if self._postMat then
		CS.PostUtility.DestroyMaterial(self._postMat)
		self._postMat = nil
	end
end
------------------------------------------------------------------
function UIScreenShotSpread:InitPostShader()
	if self._postMat then
		CS.PostUtility.DestroyMaterial(self._postMat)
		self._postMat = nil
	end
	self._postMat = CS.PostUtility.CreateMaterial("Average")
end

function UIScreenShotSpread:InitView()
	CS.ShowObject(self.mShotDiv, false)
	CS.ShowObject(self.mMaskBg, false)
	CS.ShowObject(self.mUIDiv, false)

	self:InitPostShader()
	--self:InitGameLogo()

	-- 延迟显示本UI，以防截屏到自己
	self._delayShowTimer = LxTimer.DelayTimeCall(function()
		self._delayShowTimer = nil
		if CS.IsNullObject(self.mUIDiv) then
			return
		end
		self:InitCameraShot()
		self:ClearCameraRT()
		CS.ShowObject(self.mUIDiv, true)
	end, 0.5)

	self:StartCloseWnd()
end
function UIScreenShotSpread:InitGameLogo()
	local pngPath = LGameSettings.platformLogoPng
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
		pngPath = "etc/logo.png"
	end
	--printInfoNR("====== pngPath = " .. pngPath)
	local uiPngTexture = self.mGameLogo:GetComponent("YXTextureImage")
	uiPngTexture.isNativeSize = true
	uiPngTexture.isColorReset = true
	uiPngTexture:SetImageFromFullPath(CS.StreamingPath() .. pngPath)
end

function UIScreenShotSpread:InitData()
	self._postMat = nil
	self._srcRT = nil
	self._desRT = nil

	self._isShowShare = false
	self._isShowShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.CHANNEL_WX)
	local isShowShare = false
	if gLGameLanguage:IsForeignRegion() then
		local isShowShareKaKao = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.KOREA_KAKAO)
		CS.ShowObject(self.mKKDiv, isShowShareKaKao)

		local isShowShareFB = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.FOREIGN_FACE_BOOK)
		CS.ShowObject(self.mFBDiv, isShowShareFB)

		isShowShare = isShowShareKaKao or isShowShareFB
	else
		isShowShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.CHANNEL_WX)
		CS.ShowObject(self.mWXDiv, isShowShare)
		CS.ShowObject(self.mPYQDiv, isShowShare)
	end

	self._isShowShare = isShowShare
end
function UIScreenShotSpread:InitCameraShot()
	self._uiCamera = gLGameUI.GetUICamera()
	self._uiCanvasScaler = gLGameUI.GetUICanvasScaler()
	self._sceneCamera = gLGameScene:GetCurrentSceneCamera()
	self._curSceneCls = gLGameScene:GetCurrentScene()

	local rectTran = self.mShotRawImage.gameObject:GetComponent(typeOfRectTransform)
	local width = UScreen.width
	local height = UScreen.height

	local designWidth = LGameQuality.SCREEN_WIDTH_DESIGN-- 设计分辨率
	local designHeight = LGameQuality.SCREEN_HEIGHT_DESIGN-- 设计分辨率

	local designRate = designWidth / designHeight
	local nowRate = width / height
	local sW = width
	local sH = height
	if designRate < nowRate then
		sH = designHeight
		sW = math.floor(sH * width / height)
	else
		sW = designWidth
		sH = math.floor( sW * height / width  )
	end

	local size = Vector2.New(sW,sH)
	rectTran.sizeDelta = size
	--width = sW
	--height = sH


	self._srcRT = LRTHelper.GetTemporary("src_shot_"..width.."_"..height,width,height, nil, nil, 0, nil, nil, true)
	self._sceneCamera.targetTexture = nil
	self._sceneCamera.targetTexture = self._srcRT
	self._uiCamera.targetTexture = nil
	self._uiCanvasScaler.enabled = false
	self._uiCamera.targetTexture = self._srcRT
	self._sceneCamera:Render()
	self._uiCamera:Render()
	self._uiCanvasScaler.enabled = true

	self._desRT = LRTHelper.GetTemporary("des_shot_"..width.."_"..height,width,height, nil, nil, 0, nil, nil, true)
	if self._postMat then
		--self._desRT = PostProcess.BlitSimpleTexture("Average", self._srcRT)
		UGraphics.Blit(self._srcRT, self._desRT, self._postMat)
	else
		UGraphics.Blit(self._srcRT, self._desRT)
	end

	self.mShotRawImage.texture = self._desRT
end
------------------------------------------------------------------
return UIScreenShotSpread


