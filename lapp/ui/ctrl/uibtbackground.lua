---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
-----------------------------------------------------------------
local LxTimer = LXFW.LxTimer
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
-----------------------------------------------------------------
local LWnd = LWnd
---@class UIBtBackground:LWnd
local UIBtBackground = LxWndClass("UIBtBackground", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBtBackground:UIBtBackground()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBtBackground:OnWndClose()
	if self._transitionTween then
		self._transitionTween:Kill(false)
		self._transitionTween = nil
	end
	self:StopAniTimer()

	if self._waitTimer then
		LxTimer.DelayTimeStop(self._waitTimer)
		self._waitTimer = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBtBackground:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndAsync(false)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBtBackground:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitBg()
	self:InitTransition()
	self:InitInfo()

	if CS.IsWebGL() then
		if self:GetWndArg("isInitGame") then
			FireEvent(EventNames.LOGIN_UI_READY)
		end
	end

end

function UIBtBackground:FinishedInfo()
	CS.ShowObject(self.mInfo, false)
	self:SetWndText(self.mInfoAni,"")
	self:StopAniTimer()
end

function UIBtBackground:StartInfo()
	CS.ShowObject(self.mInfo, true)
	self:SetWndText(self.mInfoAni,"")
	self:StartAniTimer()
end

function UIBtBackground:CreateSetEffect()
	local refId = gLGameLogin:GetLoginFigure()
	if string.isempty(refId) then
		return false
	end

	local itemdata = GameTable.OneNightRoleRef[tonumber(refId)]
	if not itemdata then
		printErrorN2("配置缺失", string.format("配置表GameConf.OneNightRoleRef[%s] 为空", refId))
		return false
	end

	if itemdata.type == 2 then
		self:SetWndEasyImage(self.mLoginBg,itemdata.img,function()
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

function UIBtBackground:UpdateBigBg()
	self:ShowBigBg(true)
	if PRODUCT_G_VER and PRODUCT_G_VER > 0 then
		self:SetBigBgAsIos()
	else
		self:SetBigBgAsNormal()
	end
end

function UIBtBackground:SetBigBgUsingPackageImage(packagePngPath)
	if string.isempty(packagePngPath) then return end
	if packagePngPath == self._lastPackagePngPath then return end

	self._lastPackagePngPath = packagePngPath
	local bg = self.mBg
	local uiPngTexture = bg:GetComponent("YXTextureImage")
	uiPngTexture.isNativeSize = false
	uiPngTexture.isColorReset = true
	uiPngTexture:SetImageFromFullPath(CS.StreamingPath() .. packagePngPath)
end
------------------------------------------------------------------
function UIBtBackground:TryHideImageBg()
	if not self._transitionFinished then
		return
	end
	if not self._effectBgLoaded then
		return
	end
	CS.ShowObject(self.mBgBig, false)
	CS.ShowObject(self.mBg, false)
end

function UIBtBackground:InitBgEffect()
	if not self._waitInitBgEffect then
		return
	end
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
                endFunc = function()
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
        ]]

	local loginBgName = GameTable.GameServerConfigRef.loginBg
	if not string.isempty(self._usePackageIdImg) then
		loginBgName = self._usePackageIdImg
	end
	if not string.isempty(loginBgName) then
		self:SetWndEasyImage(self.mLoginBg,loginBgName,function()
			self:SetWndImageColor(self.mLoginBg,Color.New(1, 1, 1, 1))
		end)
	end

	local order = 2
	local max = #self._spineList
	if max > 3 then
		max = 3
	end
	self._effectLoadingMax = max
	self._effectLoadingCnt = 0
	local spineParentList = {self.mSpine1, self.mSpine2, self.mSpine3}
	local isMinGame = CS.IsWebGL() and LWxHelper.IsMiniGamePlatform()
	for k, v in ipairs(self._spineList) do
		if k > max then
			break
		end
		local data = {
			replaceStatus = isMinGame and 2 or 1,
			trans = spineParentList[k],
			spineName = v,
			key = "spine"..k,
			sortOrder = order,
			endFunc = function()
				self._effectLoadingCnt = self._effectLoadingCnt + 1
				if self._effectLoadingCnt >= self._effectLoadingMax then
					self._effectBgLoaded = true
					self:TryHideImageBg()
				end
			end
		}

		self:CreateWndSpineImpl(data)
		order = order + 1
	end
end

function UIBtBackground:ShowBigBg(bShow)
	if self._isUsingPackageImage then
		--local bg = self.mBg
		--local uiPngTexture = bg:GetComponent("YXTextureImage")
		--uiPngTexture.image.enabled = bShow
		CS.ShowObject(self.mBg,bShow)
	else
		if bShow then
			if self.mBg.gameObject.activeSelf then
				LogWarn("b小打印 self.mBg xianshi")
				CS.ShowObject(self.mBg,false)
			end
		end
		CS.ShowObject(self.mBgBig, bShow)
	end
end

function UIBtBackground:InitBg()
	--[[
	local pngPath = LGameSettings.platformLoginPng
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
		pngPath = "etc/bg.png"
	end

	if pngPath == "etc/bg.png" then
		self._waitInitBgEffect = true
	end
	]]

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
	
	CS.ShowObject(self.mBgBig, not self._isUsingPackageImage)
	CS.ShowObject(self.mBg, self._isUsingPackageImage)

	if self._isUsingPackageImage then
		--从包内读图片不需要有张默认图
		self:HideUpdateBg()

		self._packagePngPathForIos = LGameSettings.platformLoginPng_ver
		self._packagePngPathNormal = LGameSettings.platformLoginPng
		if string.isempty(self._packagePngPathForIos) then
			self._packagePngPathForIos = self._packagePngPathNormal
		end
	end

	--使用静态图20240829
	self._waitInitBgEffect = false

	---支持动态配置20241126
	self._waitInitBgEffect = self._isUseSpineBg

	--[[ 背景图直接用Unity资源
	local bg = self.mBg
	local uiPngTexture = bg:GetComponent("YXTextureImage")
	uiPngTexture.pngPath = CS.AppAssetPath() .. pngPath
	uiPngTexture.bImageNativeSize = false
	uiPngTexture.bImageColor = true
	uiPngTexture:LoadFile()
	]]

	--[[ Logo不显示
	pngPath = LGameSettings.platformLogoPng
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
		pngPath = "etc/logo.png"
	end
	local logo = self.mLogo
	local uiPngTexture = logo:GetComponent("YXTextureImage")
	uiPngTexture.pngPath = CS.AppAssetPath() .. pngPath
	uiPngTexture.bImageNativeSize = true
	uiPngTexture.bImageColor = true
	uiPngTexture:LoadFile()
	]]

	if CS.IsWebGL() then
		if self.mFirstScreenLogo then
			CS.ShowObject(self.mFirstScreenLogo, LGameSettings.isShowBootBackgroundFirstLogo)
		end
	end

end

function UIBtBackground:HideUpdateBg()
	CS.ShowObject(self.mBgUpdate, false)
end

function UIBtBackground:OnLoginPlaySpineAni(aniName, timescale)
	local spine = self:FindWndSpineByKey("spine2")
	if not spine then return end
	if not spine:IsDpValid() then return end
	local ani = spine:GetAnimation(aniName)
	if ani then
		if timescale and timescale > 0 then
			spine:SetAnimationTimeScale(timescale)
		end
		local bLoop = aniName == "idle"
		spine:PlayAnimation(0, aniName, bLoop)
	end
end

function UIBtBackground:InitData()
	local spineListStr = ""
	local usePackSpine = false
	local loginPackSpineList = GameTable.GameServerConfigRef.loginPackSpineList or ""
	if not string.isempty(loginPackSpineList) then
		local packageId = tonumber(LGameSettings.platformId)
		loginPackSpineList = string.split(loginPackSpineList,"|")
		for i,v in ipairs(loginPackSpineList) do
			v = string.split(v,"=")
			if checknumber(v[1]) == packageId then
				spineListStr = v[2]
				usePackSpine = true
				break
			end
		end
	end
	if not usePackSpine then
		spineListStr = GameTable.GameServerConfigRef.loginSpineList or ""
	end
	local arrList = string.split(spineListStr, ",") or {}
	local list = {}
	for k,v in ipairs(arrList) do
		if not string.isempty(v) then
			table.insert(list, v)
		end
	end

	self._spineList = list
	self._isUseSpineBg = #list > 0

end

function UIBtBackground:StopAniTimer()
	if self._mLoopAniTimer then
		LxTimer.LoopTimeStop(self._mLoopAniTimer)
		self._mLoopAniTimer = nil
	end
end

function UIBtBackground:InitInfo()
	self._aniInfo = {
		".",
		"..",
		"...",
		"....",
		".....",
		"......",
		".......",
		"........",
	}
	self._aniLen = #self._aniInfo
	self._curAni = 1

	if GF.IsInScene("LUpdateScene") then
		self:FinishedInfo()
	else
		self:StartInfo()
	end

	if LGameSettings.isIosBgInit then
		local isServerInit = self:GetWndArg("isServerInit")
		if isServerInit or PRODUCT_G_VER then
			self:UpdateBigBg()
		else
			self:SetBigBgAsIos()
		end
	else
		self:UpdateBigBg()
	end

	self:WndEventRecv(EventNames.LOGIN_SERVERLIST_OK, function(...)
		LogWarn("b小打印 current lua for product = " ..tostring(PRODUCT_G_VER))
		self:UpdateBigBg()
	end)

	self:WndEventRecv(EventNames.ON_REFRESH_RETURN_PRODUCT, function(...)
		LogWarn("b小打印 current lua for product = " ..tostring(PRODUCT_G_VER))
		self:UpdateBigBg()
	end)

	self:WndEventRecv(EventNames.LOGIN_SCENE_START_LOAD,function (...)
		self:StartInfo()
	end)

	self:WndEventRecv(EventNames.LOGIN_SCENE_FINISH_LOAD,function (...)
		self:FinishedInfo()
		if not PRODUCT_G_VER or PRODUCT_G_VER == 0 then
			self:InitBgEffect()
		end
		self:HideUpdateBg()
	end)
	self:WndEventRecv(EventNames.LOGIN_SPINE_PLAY_ANI, function(...)
		self:OnLoginPlaySpineAni(...)
	end)

	self:WndEventRecv(EventNames.LOGIN_SPINE_HIDE, function(bHide)
		if bHide then
			self:ShowBigBg(true)
		else
			self:ShowBigBg(false)
		end
	end)


end

function UIBtBackground:SetBigBgAsIos()
	if self._isUsingPackageImage then
		LogWarn("b小打印 self._isUsingPackageImage")
		self:SetBigBgUsingPackageImage(self._packagePngPathForIos)
	else
		local iosBg = GameTable.GameServerConfigRef.loginBgIos
		LogWarn("b小打印 GameTable.GameServerConfigRef.loginBgIos " .. GameTable.GameServerConfigRef.loginBgIos)
		if string.isempty(iosBg) then
			iosBg = "login_bg_big_ios1"
		end
		LogWarn("b小打印 loginBgIos " .. iosBg)
		self:SetWndEasyImage(self.mBgBig, iosBg, function()
		end, nil, true)
	end

end

function UIBtBackground:SetBigBgAsNormal()
	if self._isUsingPackageImage then
		LogWarn("b小打印 self._packagePngPathNormal " .. self._packagePngPathNormal)
		self:SetBigBgUsingPackageImage(self._packagePngPathNormal)
	else
		local loginBgName = GameTable.GameServerConfigRef.loginBg
		LogWarn("b小打印 loginBgName " .. loginBgName)
		if not string.isempty(self._usePackageIdImg) then
			loginBgName = self._usePackageIdImg
			LogWarn("b小打印 self._usePackageIdImg " .. self._usePackageIdImg)
		end
		if not string.isempty(loginBgName) then
			local img = self:FindWndImage(self.mBgBig)
			if img and img.sprite  and img.sprite.name ~= loginBgName then
				self:SetWndEasyImage(self.mBgBig, loginBgName, function()
				end, nil, true)
			end
		end
	end
end

function UIBtBackground:InitTransition()
	local canvasGroup = self.mContent:GetComponent(typeofCanvasGroup)
	if self:GetWndArg("ignoreAlpha") then
		canvasGroup.alpha = 1
		self._transitionFinished = true
		--self:TryHideImageBg()

		--使用静态图20240829
		--CS.ShowObject(self.mBgUpdate, true)
		--CS.ShowObject(self.mBgBig, false)

		CS.ShowObject(self.mBgUpdate, false)
		return
	end


	if CS.IsWebGL() then
		canvasGroup.alpha = 1
	else
		canvasGroup.alpha = 0
	end

	local time = 0.5

	local tweener = canvasGroup:DOFade(1,time)
	--self.mContent.localScale = Vector3(0,0,0)
	--local scaleTweener = self.mContent:DOScale(Vector3(1,1,1),time)

	local seqTween = YXTween.TweenSequenceIns()
	self._transitionTween = seqTween
	seqTween:Append(tweener)
	--seqTween:Insert(0,scaleTweener)

	seqTween:OnComplete(function()
		self._transitionTween = nil
		self._transitionFinished = true
		self:TryHideImageBg()
	end)

	seqTween:PlayForward()
end

function UIBtBackground:StartAniTimer()
	self:StopAniTimer()
	self._mLoopAniTimer = LxTimer.LoopTimeCall(function ()
		local str = self._aniInfo[self._curAni] or ""
		self:SetWndText(self.mInfoAni,str)
		self._curAni = self._curAni + 1
		if self._curAni > self._aniLen then
			self._curAni = 1
		end
	end,0.3)
end


------------------------------------------------------------------
return UIBtBackground


