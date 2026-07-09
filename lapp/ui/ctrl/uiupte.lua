---
--- Created by luofuwen.
--- DateTime: 2023/10/13 10:31:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUpte:LWnd
local UIUpte = LxWndClass("UIUpte", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUpte:UIUpte()
	self._isShowBottomView = false
	self._isShowBarView = false
	-- 0:解压  1:下载文件  2:修复
	self._barType = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUpte:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUpte:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndAsync(false)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUpte:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitUpdateUI()

	self:WndEventRecv(EventNames.SDK_LOGAN_UPLOAD_RESULT, function(...)
		self._lastUploadTime = nil
	end)

	-- get server list
	self:WndEventRecv(EventNames.LOGIN_SERVERLIST_START,function (...)
		self:OnGetServerListStart(...)
	end)
	self:WndEventRecv(EventNames.LOGIN_SERVERLIST_OK,function (...)
		self:OnGetServerListEnd(...)
	end)
	-- progress change
	self:WndEventRecv(EventNames.UPDATE_PROGRESS_CHANGE,function (...)
		self:OnProgressChange(...)
	end)
	-- extract res
	self:WndEventRecv(EventNames.UPDATE_EXTRACT_RES_START,function (...)
		self:OnExtractResStart(...)
	end)
	self:WndEventRecv(EventNames.UPDATE_EXTRACT_RES_OK,function (...)
		self:OnExtractResEnd(...)
	end) 
	-- download file
	self:WndEventRecv(EventNames.UPDATE_DOWNLOAD_RES_START,function (...)
		self:OnDownloadResStart(...)
	end)
	self:WndEventRecv(EventNames.UPDATE_DOWNLOAD_RES_OK,function (...)
		self:OnDownloadResEnd(...)
	end)
	-- repeair file 
	self:WndEventRecv(EventNames.UPDATE_REPAIR_RES_START,function (...)
		self:OnRepairResStart(...)
	end)
	self:WndEventRecv(EventNames.UPDATE_REPAIR_RES_OK,function (...)
		self:OnRepairResEnd(...)
	end)
	
	self:WndEventRecv(EventNames.UPDATE_NEED_INSTALL,function (...)
		self:OnNeedInstall(...)
	end)
	FireEvent(EventNames.UPDATE_UI_READY)
end

function UIUpte:OnRepairResStart()
	self._isShowBottomView = true
	self._isShowBarView = true
	CS.ShowObject(self.mBottomView, self._isShowBottomView)
	CS.ShowObject(self.mBarView, self._isShowBarView)
	-- 文本直接写死，不适用ccClientText(xxxx)，因为配置数据还没有加载
	self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(6))
end
function UIUpte:OnNeedInstall()
	self:SetXUITextText(self.mProgressText, "Need Install Game!")
end
function UIUpte:OnRepairResEnd()
	self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(9))
end

function UIUpte:OnProgressChange(barType, progress, info, isIgnore)
	self._barType = barType
	if not self._isShowBottomView then
		self._isShowBottomView = true
		CS.ShowObject(self.mBottomView, true)
		CS.ShowObject(self.mRepairBtn, false)
		self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(1))
	end
	if not self._isShowBarView then
		self._isShowBarView = true
		CS.ShowObject(self.mBarView, true)
	end

	self._progress = progress
	self._barObj:SetProgress(self._progress)
	self:SetXUITextText(self.mNum, string.format("%.2f%%", progress * 100))

	if  isIgnore then
		self:SetXUITextText(self.mNum, "")
	end

	if PRODUCT_G_VER == 1 or PRODUCT_G_VER == 2 then
		--ios 写死提审屏蔽
		self:SetXUITextText(self.mNum, "")
		CS.ShowObject(self.mBarView, false)
	end

	if barType == 0 then
		self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(1))
	elseif barType == 1 then
		self:SetXUITextText(self.mProgressText, string.replace(gLxPatchCtrl:GetInfoText(2),info))
	elseif barType == 2 then
		self:SetXUITextText(self.mProgressText, string.replace(gLxPatchCtrl:GetInfoText(3),info))
	end
end
function UIUpte:OnExtractResStart()
	self._isShowBottomView = true
	self._isShowBarView = true
	CS.ShowObject(self.mBottomView, self._isShowBottomView)
	CS.ShowObject(self.mBarView, self._isShowBarView)
	CS.ShowObject(self.mRepairBtn, false)
	-- 文本直接写死，不适用ccClientText(xxxx)，因为配置数据还没有加载
	self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(1))
end
function UIUpte:OnDownloadResEnd()
	self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(8))
end
function UIUpte:OnGetServerListEnd()
	self:SetXUITextText(self.mProgressText,gLxPatchCtrl:GetInfoText(4))

	if not PRODUCT_G_VER or PRODUCT_G_VER == 0 then
		CS.ShowObject(self.mBar, true)
		CS.ShowObject(self.mEffRoot, true)
		CS.ShowObject(self.mLightMask, true)
		CS.ShowObject(self.mBarBg, true)
	end
end
function UIUpte:OnDownloadResStart()
	self._isShowBottomView = true
	self._isShowBarView = true
	CS.ShowObject(self.mBottomView, self._isShowBottomView)
	CS.ShowObject(self.mBarView, self._isShowBarView)
	-- 文本直接写死，不适用ccClientText(xxxx)，因为配置数据还没有加载
	self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(5))
end

function UIUpte:OnGetServerListStart()
	self._isShowBottomView = true
	self._isShowBarView = false
	CS.ShowObject(self.mBottomView, self._isShowBottomView)
	CS.ShowObject(self.mBarView, self._isShowBarView)

	self:SetXUITextText(self.mProgressText,gLxPatchCtrl:GetInfoText(4))
end
function UIUpte:OnExtractResEnd()
	CS.ShowObject(self.mRepairBtn, true)
	self:SetXUITextText(self.mProgressText, gLxPatchCtrl:GetInfoText(7))
end

function UIUpte:InitUpdateUI()
	self._progress = 0
	self._barObj = self:UIProgressFind(self.mBar, "barProgress",self._progress)
	self._barObj:SetProgress(self._progress)
	self:SetXUITextText(self.mNum, "")
	self:SetXUITextText(self.mProgressText, "")
	if gLGameLanguage:IsJapanRegion() then
		self:SetXUITextFontSize(self.mProgressText,18)
	end

	CS.ShowObject(self.mBottomView, self._isShowBottomView)
	CS.ShowObject(self.mBarView, self._isShowBarView)

	--self:CreateWndSpine(self.mEffRoot,"Dengyemian_bianfu","handleEffect")

	--if LGameSettings.platformRegion == LRegionConst.HMT then
	--	CS.ShowObject(self.mBar, false)
	--	CS.ShowObject(self.mEffRoot, false)
	--end

	if LGameSettings.showLogUpload then
		self:SetWndText(self.mBtnLogUploadName, ccClientText(15063))
		CS.ShowObject(self.mBtnLogUpload, true)
		self:SetWndClick(self.mBtnLogUpload, function()
			if self._lastUploadTime and self._lastUploadTime > Time.RawUnityEngineTime.realtimeSinceStartup then
				GF.ShowMessage(ccClientText(120))
				return
			end
			self._lastUploadTime = Time.RawUnityEngineTime.realtimeSinceStartup + 10
			gLSdkImpl:CallMethod(LSdkMethod.LoganUpload)
		end)
	else
		CS.ShowObject(self.mBtnLogUpload, false)
	end
end

------------------------------------------------------------------
return UIUpte


