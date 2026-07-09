---
--- Created by luofuwen.
--- DateTime: 2023/10/26 16:08:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISysShot:LWnd
local UISysShot = LxWndClass("UISysShot", LWnd)
------------------------------------------------------------------
local CS = CS
local UScreen = UnityEngine.Screen
local UGraphics = UnityEngine.Graphics
local URenderTextureFormat = UnityEngine.RenderTextureFormat
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeofCustomAxis = typeof(CardEHT.YXTileMapCustomAxis)

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISysShot:UISysShot()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISysShot:OnWndClose()
	self:ClearCameraRT()
	self:ClearSceneShot()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISysShot:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISysShot:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	
	self:InitData()
	self:InitCtrl()
	self:InitView()
end

function UISysShot:ClearCameraRT()
	if self._sceneCamera then
		self._sceneCamera.targetTexture = nil
	end
	if self._uiCamera then
		self._uiCamera.targetTexture = nil
	end
end
function UISysShot:InitCtrl()
	self:SetWndClick(self.mWeChatBtn,function() self:SaveImg(LShareConst.SCENE_WX_PY) end)
	self:SetWndClick(self.mPYQBtn,function() self:SaveImg(LShareConst.SCENE_WX_PYQ) end)
	self:SetWndClick(self.mSaveBtn,function() self:SaveImg() end)
end
function UISysShot:InitShareNode()
	self._isShowShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.CHANNEL_WX)

	CS.ShowObject(self.mWeChatBtn, self._isShowShare)
	CS.ShowObject(self.mPYQBtn, self._isShowShare)

	self:SetWndText(self.mWeChatBtnName,ccClientText(20818))
	self:SetWndText(self.mPYQBtnName,ccClientText(20819))
	self:SetWndText(self.mSaveBtnName,ccClientText(20820))
	self:SetWndText(self.mCopyBtnName,ccClientText(20856))
end

function UISysShot:ClearSceneShot()
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
function UISysShot:SaveImg(saveType)
	CS.ShowObject(self.mShotDiv, true)
	CS.ShowObject(self.mMaskBg, true)

	local list = {self.mShotDiv,self.mMaskBg}
	local isShare = false
	local shareData
	local str = "保存图片"
	local showImg = self._showImg

	if saveType and saveType > 0 then
		isShare = self._isShowShare
		shareData = {shareScene=saveType,  shareLocation="GameShareActivity40"}
		str = LShareConst.TA_ATTR_MAP[saveType] or ""
	end

	--CS.ShowObject(self.mCodeImg, true)
	gLGameUI:CaptureUIScreen(self:GetWndTrans(),list,isShare, shareData,function()
		if not self:IsWndValid() then return end
		self:WndClose()
	end)

end
function UISysShot:InitView()
	CS.ShowObject(self.mShotDiv, false)
	CS.ShowObject(self.mMaskBg, false)
	CS.ShowObject(self.mBottomDiv, false)


	self:InitCameraShot()
	self:InitGameLogo()
	self:InitShareNode()

	self:ClearCameraRT()

	LxTimer.DelayTimeCall(function()
		if CS.IsNullObject(self.mBottomDiv) then
			return
		end
		local toPos = self.mBottomDiv.localPosition
		local fromPos = toPos:Clone()
		fromPos.y = fromPos.y - 150
		CS.ShowObject(self.mBottomDiv, true)
		self:TweenSeq_LocalMoveTrans("ShowBottom", self.mBottomDiv, fromPos, toPos, 0.3)
	end, 0.3)

	LxTimer.DelayTimeCall(function()
		if CS.IsNullObject(self.mBottomDiv) then
			return
		end
		local fromPos = self.mBottomDiv.localPosition
		local toPos = fromPos:Clone()
		toPos.y = toPos.y - 150
		self:TweenSeq_LocalMoveTrans("HideBottom", self.mBottomDiv, fromPos, toPos, 0.3, function()
			self:WndClose()
		end)
	end, 5)
end
function UISysShot:InitGameLogo()
	local logo = self._logoImg
	local pngPath = LGameSettings.platformLogoPng
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
		pngPath = "etc/" .. logo .. ".png"
	end
	printInfoNR("====== pngPath = " .. pngPath)
	local uiPngTexture = self.mGameLogo:GetComponent("YXTextureImage")
	uiPngTexture.isNativeSize = true
	uiPngTexture.isColorReset = true
	uiPngTexture:SetImageFromFullPath(CS.StreamingPath() .. pngPath)
end
function UISysShot:InitCameraShot()
	self._uiCamera = gLGameUI.GetUICamera()
	self._sceneCamera = gLGameScene:GetCurrentSceneCamera()
	self._curSceneCls = gLGameScene:GetCurrentScene()

	local rectTran = self.mShotRawImage.gameObject:GetComponent(typeOfRectTransform)
	local width = UScreen.width
	local height = UScreen.height
	local size = Vector2.New(width,height)
	rectTran.sizeDelta = size


	self._srcRT = LRTHelper.GetTemporary("src_shot_"..width.."_"..height,width,height, nil, nil, nil, nil, nil, true)
	self._sceneCamera.targetTexture = nil
	self._sceneCamera.targetTexture = self._srcRT
	self._uiCamera.targetTexture = nil
	self._uiCamera.targetTexture = self._srcRT
	self._sceneCamera:Render()
	self._uiCamera:Render()

	self._desRT = LRTHelper.GetTemporary("des_shot_"..width.."_"..height,width,height, nil, nil, nil, nil, nil, true)
	local postMat = CS.PostUtility.CreateMaterial("Average")
	UGraphics.Blit(self._srcRT, self._desRT, postMat)
	self.mShotRawImage.texture = self._desRT
end

function UISysShot:InitData()
	self._isShowShare = false
	self._postMat = nil
	self._srcRT = nil
	self._desRT = nil
end
------------------------------------------------------------------
return UISysShot


