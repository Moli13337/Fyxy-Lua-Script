---
--- Created by Administrator.
--- DateTime: 2023/10/24 18:09
---
------------------------------------------------------------------
local LxTimer = LXFW.LxTimer
local CS = CS
---@type LWnd
local LWnd = LWnd
---@class UILoadsng:LWnd
local UILoadsng = LxWndClass("UILoadsng", LWnd)
------------------------------------------------------------------
UILoadsng.TIMER_KEY_PROGRESS = 1
---

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILoadsng:UILoadsng()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILoadsng:OnWndClose()
	self:StopDelayTimer()
	self:StopDelayEndTimer()

	if self._waitTimer then
		LxTimer.DelayTimeStop(self._waitTimer)
		self._waitTimer = nil
	end

	if(self._loadEndFunc)then
		self._loadEndFunc()
	end
	local _loadEndFunc = self._loadEndFunc
	if _loadEndFunc ~= nil then
		_loadEndFunc()
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILoadsng:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILoadsng:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitLoadingUI()
	self:InitEvent()

	self:TimerStart(UILoadsng.TIMER_KEY_PROGRESS, 0, false, -1)

	self._delayTimer = LxTimer.DelayFrameCall(function()
		self._delayTimer = nil
		self:StartLoading()
	end,1)
end
function UILoadsng:OnDestroyEnd()
	-- LResRelease.OnSceneChanged()
end

function UILoadsng:OnLoadingProgress(progress)
	local progressRate = self._progressRate
	if not self._loadingFinish then
		if progressRate then
			progress = progressRate * progress
		end
		self._loadingProgress = progress
		self._cacheProgress = progress
	else
		if progressRate then
			self._cacheProgress = self._loadingProgress + progress * (1 - progressRate)
		end
	end
end

function UILoadsng:SetBigBgUsingPackageImage(packagePngPath)
	if string.isempty(packagePngPath) then return end
	if packagePngPath == self._lastPackagePngPath then return end

	self._lastPackagePngPath = packagePngPath
	local bg = self.mBgPkg
	local uiPngTexture = bg:GetComponent("YXTextureImage")
	uiPngTexture.isNativeSize = false
	uiPngTexture.isColorReset = true
	uiPngTexture:SetImageFromFullPath(CS.StreamingPath() .. packagePngPath)
end

function UILoadsng:OnTimer(key)
	if key == 1 then
		if self:IsWndClosed() or not self:IsWndValid() then
			return
		end

		local progress = self._showProgress
		if self._loadingEnd then
			progress = progress + self._progressStep
			if progress > self._cacheProgress then
				progress = self._cacheProgress

				self:TimerStop(UILoadsng.TIMER_KEY_PROGRESS)
				self:StopDelayTimer()
				self:StopDelayEndTimer()
				if self._bBlackEnd then
					local blacktime = 0.5
					GF.OpenWndWait("UIBlockBlack",{blacktime})
					self._delayTimer = LxTimer.DelayTimeCall(function ()
						self:WndClose()
					end,blacktime)
				else
					self._delayTimer = LxTimer.DelayFrameCall(function ()
						self:WndClose()
					end,1)
				end

			end
		else
			progress = progress + 0.02
			local limit = math.max(self._cacheProgress,0.5)
			if progress > limit then
				progress = limit
			end
		end

		self:OnUpdateProgress(progress)
	end
end


-- 场景加载资源完成
function UILoadsng:OnLoadingFinish()
	self._loadingFinish = true
end

function UILoadsng:StopDelayTimer()
	if self._delayTimer then
		LxTimer.DelayTimeStop(self._delayTimer)
		self._delayTimer = nil
	end
end

function UILoadsng:ShowBg()
	self.mImageBlackCanvasGroup.alpha = 0

	--local pngPath = LGameSettings.platformLoadPng
	--if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
	--	pngPath = "etc/bg.png"
	--end
	self._isUsingPackageImage = LGameSettings.usePackageImage
	
	local usePackageIdImg = nil
	local loginPackResBg = GameTable.GameServerConfigRef.loginPackResBg
	if not string.isempty(loginPackResBg) then
		local packageId = tonumber(LGameSettings.platformId)
		loginPackResBg = string.split(loginPackResBg,"|")
		for i,v in ipairs(loginPackResBg) do
			v = string.split(v,"=")
			if checknumber(v[1]) == packageId then
				self._isUsingPackageImage = false
				usePackageIdImg = v[2]
			end
		end
	end
	self._usePackageIdImg = usePackageIdImg
	
	if self._isUsingPackageImage then
		self._packagePngPathForIos = LGameSettings.platformLoadPng_ver
		self._packagePngPathNormal = LGameSettings.platformLoadPng
		if string.isempty(self._packagePngPathForIos) then
			self._packagePngPathForIos = self._packagePngPathNormal
		end

		CS.ShowObject(self.mBg, false)
		CS.ShowObject(self.mBgPkg, true)
	else
		CS.ShowObject(self.mBg, true)
		CS.ShowObject(self.mBgPkg, false)
	end

	if PRODUCT_G_VER and PRODUCT_G_VER > 0 then
		self:SetBgForIos()
	else
		self:SetBgForNormal()
	end

	--if pngPath == "etc/bg.png" then
		--self:InitBgEffect()
		--CS.ShowObject(self.mBg, false)
	--else
	--	local bg = self.mBg
		--[[背景图直接使用Unity资源
		local uiPngTexture = bg:GetComponent("YXTextureImage")
		uiPngTexture.pngPath = CS.AppAssetPath()..pngPath
		uiPngTexture.bImageNativeSize = false
		uiPngTexture.bImageColor = true
		uiPngTexture:LoadFile()
		]]
	--end
end

function UILoadsng:DealStartProgress(startProgress,updateRate)
	self._curProgress =  startProgress
	self._updateRate = updateRate
	self._isHasStartProgress = true
end

function UILoadsng:InitLoadingUI()
	if self._bHideBg then
		CS.ShowObject(self.mBg, false)
		CS.ShowObject(self.mBgPkg, false)
		CS.ShowObject(self.mLogo, false)
	else
		self:ShowBg()
		--TODO logo不显示
		--self:ShowLogo()
	end

	self._rtProgress = self:UIProgressFind(self.mBar, "barProgress",self._showProgress)
	self._rtProgress:SetProgress(self._showProgress)

	--self:CreateWndSpine(self.mEffRoot,"Dengyemian_bianfu","handleEffect")

	if PRODUCT_G_VER and PRODUCT_G_VER == 2 then
		--ios 写死提审屏蔽,港澳台要隐藏进度条
		if LGameSettings.platformRegion == LRegionConst.HMT then
			CS.ShowObject(self.mBar, false)
			CS.ShowObject(self.mBarBg, false)
			CS.ShowObject(self.mLightMask, false)
			CS.ShowObject(self.mEffRoot, false)
			CS.ShowObject(self.mProgress, false)
		end
	end

	--日服提审屏蔽进度条
	if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        if gLGameLanguage:IsJapanRegion() then
			CS.ShowObject(self.mBar, false)
			CS.ShowObject(self.mBarBg, false)
			CS.ShowObject(self.mLightMask, false)
			CS.ShowObject(self.mEffRoot, false)
			CS.ShowObject(self.mProgress, false)
        end
	end
end

function UILoadsng:SetBgForNormal()
	if self._isUsingPackageImage then
		self:SetBigBgUsingPackageImage(self._packagePngPathNormal)
		return
	end
	local loginBgName = GameTable.GameServerConfigRef.loginBg
	if not string.isempty(self._usePackageIdImg) then
		loginBgName = self._usePackageIdImg
	end
	if not string.isempty(loginBgName) then
		local img = self:FindWndImage(self.mBg)
		if img and img.sprite  and img.sprite.name ~= loginBgName then
			self:SetWndEasyImage(self.mBg, loginBgName, function()
			end, nil, true)
		end
	end
end

------------------------------------------------------------------
function UILoadsng:StartLoading()
	local loadingCall = self._loadingCall
	if loadingCall ~= nil then
		loadingCall()
	end
end

function UILoadsng:StopDelayEndTimer()
	if self._delayEndTimer then
		LxTimer.DelayTimeStop(self._delayEndTimer)
		self._delayEndTimer = nil
	end
end

-- 加载场景流程结束
function UILoadsng:OnLoadingEnd()
	if self._loadingEnd then
		return
	end
	self:StopDelayEndTimer()
	self._loadingEnd = true

	local progressStep = (self._cacheProgress - self._showProgress) / 3
	if progressStep <= 0 then
		progressStep = 0.1
	end
	self._progressStep = progressStep


end
-----------------------------------------------------------------

function UILoadsng:InitData()
	self._loadingCall = self:GetWndArg("cb")
	self._sceneName = self:GetWndArg("sceneName")
	self._progressRate = self:GetWndArg("rate")

	self._bWaitVideo = self:GetWndArg("waitVideo")
	self._bBlackEnd = self:GetWndArg("blackEnd")
	self._bHideBg = self:GetWndArg("hideBg")
	self._bClearBgWnd = self:GetWndArg("clearBgWnd")
	self._loadEndFunc = self:GetWndArg("loadEndFunc")

	self._loadingProgress = 0
	self._cacheProgress = 0
	self._showProgress = 0

	local isHasStartProgress
	local startProgress
	local updateRate = 0.02

	if self:GetWndArg("startProgress") then
		isHasStartProgress = true
		startProgress = self:GetWndArg("startProgress")
		if self:GetWndArg("updateRate") then
			updateRate = self:GetWndArg("updateRate")
		end
	end

	if CS.IsWebGL() and self:GetWndArg("isGetLaunchProgress") then
		isHasStartProgress = true
		local duration = LGameSettings.splash_progress_duration or 15
		startProgress = CS.GetCsValue(CsValueType.GetLaunchProgress)
		updateRate = Time.deltaTime / duration
		PJXUI.UnZipUI.Instance:Hide()
	end

	if isHasStartProgress then
		--gprint("updateRate", updateRate)
		self:DealStartProgress(startProgress, updateRate)
	end

	if self._bHideBg then
		self._fmtProgressStr = ccClientText(135)
	else
		self._fmtProgressStr = ccClientText(103)
	end
end

function UILoadsng:InitEvent()
	self:WndEventRecv(EventNames.LOADING_PROGRESS, function(...)
		self:OnLoadingProgress(...)
	end)

	self:WndEventRecv(EventNames.LOADING_FINISHED, function(...)
		self:OnLoadingProgress(...)
		self:OnLoadingFinish()
	end)

	self:WndEventRecv(EventNames.LOADING_END, function(...)
		if self._bClearBgWnd then
			GF.CloseUIBtBackground()
		end
		if self._bWaitVideo then
			self:StartDelayEndTimer()
		else
			self:OnLoadingEnd(...)
		end

	end)

	if self._bWaitVideo then
		self:WndEventRecv(EventNames.LOADING_VIDEO_COMPLETE, function (...)
			self:OnLoadingEnd(...)
		end)
	end
end

function UILoadsng:InitBgEffect()
	--[[
	if not self:CreateSetEffect() then
		local effectName = "effect_denglu_02"
		local key = "effect_denglu_02"
		local effData =
		{
			trans = self.mEffectbg,
			effName = effectName,
			effKey = key,
			bDefaultSortNum = 2,
			scale = Vector3(100,100,100),
			isCheckInit = true,
			endFunc = function(effect)
				self._effectBgLoaded = true
				self:TryHideImageBg()
			end
		}
		self:CreateWndEffect_Ex(effData)
	end

	local firstEndFunc = function()
		LxUiHelper.PlayAudioSoundName(LSoundConst.BATS_FLY)
	end
	self._waitTimer = LxTimer.DelayTimeCall(firstEndFunc, 3)
	--]]

end

function UILoadsng:OnUpdateProgress(progress)
	if progress > 0 and self._showProgress == progress then
		return
	end

	self._showProgress = progress
	local barProgress = progress

	--这里判断是否超过原来的进度条值，超过则拿最新的，否则拿参数传进来的
	if self._isHasStartProgress then
		local _curProgress = self._curProgress
		if progress < _curProgress then
			self._curProgress = _curProgress + self._updateRate
			barProgress = self._curProgress
		else
			self._isHasStartProgress = nil
		end
	end
	self._rtProgress:SetProgress(barProgress)

	--gprint("OnUpdateProgress", progress, self._curProgress)

	--local msgStr = LStringUtil.ReplaceStringCommon(self._fmtProgressStr,nil,tostring(math.floor(progress * 100)))

	local msgStr = self._fmtProgressStr
	self:SetWndText(self.mProgressText,msgStr)
	self:SetWndText(self.mProgress, tostring(math.floor(progress * 100)).."%")
end

function UILoadsng:CreateSetEffect()
	local refId = gLGameLogin:GetLoginFigure()
	if string.isempty(refId) then
		return false
	end

	local itemdata = GameTable.OneNightRoleRef[tonumber(refId)]
	if not itemdata then
		return false
	end

	if itemdata.type == 2 then
	    self:SetWndEasyImage(self.mLoginBg,itemdata.img,function ()
			self._effectBgLoaded = true
			self:TryHideImageBg()
		end)
		return true
	end

	local data =
	{
		trans = self.mEff1,
		effName = itemdata.effectRes,
		effKey = "effect1",
		bDefaultSorting = true,
		sortOrder = 1,
		endFunc =function(effect)
			self._effectBgLoaded = true
			self:TryHideImageBg()
		end
	}

	self:CreateWndEffectImpl(data)

	local data =
	{
		trans = self.mEff2,
		effName = itemdata.uiRes1,
		effKey = "effect2",
		bDefaultSorting = true,
		sortOrder = 30,

	}

	self:CreateWndEffectImpl(data)

	local data =
	{
		trans = self.mEff3,
		effName = itemdata.uiRes2,
		effKey = "effect3",
		bDefaultSorting = true,
		sortOrder = 40,
	}

	self:CreateWndEffectImpl(data)

	local data =
	{
		trans = self.mSpine1,
		spineName = itemdata.spine,
		key = "spine1",
		sortOrder = 20,
	}

	self:CreateWndSpineImpl(data)

	return true
end

function UILoadsng:TryHideImageBg()
	if not self._effectBgLoaded then
		return
	end
	local bg = self.mBg
	CS.ShowObject(bg, false)
	--local uiPngTexture = bg:GetComponent("YXTextureImage")
	--uiPngTexture.image.enabled = false
end

function UILoadsng:StartDelayEndTimer()
	self:StopDelayEndTimer()
	self._delayEndTimer = LxTimer.DelayTimeCall(function()
		self._delayEndTimer = nil
		self:OnLoadingEnd()
	end,5)
end

function UILoadsng:SetBgForIos()
	if self._isUsingPackageImage then
		self:SetBigBgUsingPackageImage(self._packagePngPathForIos)
		return
	end
	local iosBg = GameTable.GameServerConfigRef.loginBgIos
	if string.isempty(iosBg) then
		iosBg = "login_bg_big_ios1"
	end
	self:SetWndEasyImage(self.mBg, iosBg, function()

	end, nil, true)
end

function UILoadsng:ShowLogo()
	local pngPath = LGameSettings.platformLogoPng
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
		pngPath = "etc/logo.png"
	end
	local logo = self.mLogo
	local uiPngTexture = logo:GetComponent("YXTextureImage")
	uiPngTexture.isNativeSize = true
	uiPngTexture.isColorReset = true
	uiPngTexture:SetImageFromFullPath(CS.StreamingPath() .. pngPath)
end
------------------------------------------------------------------
return UILoadsng


