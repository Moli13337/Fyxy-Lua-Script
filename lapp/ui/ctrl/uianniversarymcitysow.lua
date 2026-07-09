---
--- Created by ly.
--- DateTime: 2023/10/9 17:40:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAnniversaryMCitySow:LWnd
local UIAnniversaryMCitySow = LxWndClass("UIAnniversaryMCitySow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAnniversaryMCitySow:UIAnniversaryMCitySow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAnniversaryMCitySow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAnniversaryMCitySow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAnniversaryMCitySow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitStaticContent()
	self._sid = self:GetWndArg("sid")
	self._isShow=false
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIAnniversaryMCitySow:InitStaticContent()
	local isForeign = gLGameLanguage:IsForeignVersion()
	CS.ShowObject(self.mBg, not isForeign)
	CS.ShowObject(self.mBgEn, isForeign)
	if isForeign then
		self:InitLogoEn()
	end
end

function UIAnniversaryMCitySow:InitEvent()

	self:SetWndClick(self.mNoMoreBtn,function()
		local bshow=not self._isShow
		CS.ShowObject(self.mCheckmark,bshow)
		self._isShow=bshow
	end)

	local func=function()
		if self._isShow then gModelActivity:OnActivitySpecialOpReq(self._sid, 1, 1, nil, nil, ModelActivity.MEMOIR_SHOW_CITY) end--发送标记 ， 不再显示
		self:WndClose()
	end
	self:SetWndClick(self.mBtnJoin,function()
		-- GF.OpenWnd("WndAnniversarySummary",{sid = self._sid})		--直接跳转进入活动
		func()
	end)
	self:SetWndClick(self.mBtnClose, function(...) func() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

function UIAnniversaryMCitySow:OnActivityConfigData()

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end
	local data = webData.config
	local checkText = data.checkText
	if not string.isempty(checkText) then
		self:SetWndText(self.mToggleTextEn, checkText)
	end
end

function UIAnniversaryMCitySow:InitLogoEn()
	local pngPath = LGameSettings.platformLogoPng
	if (not LPlatformUtil.IsAssetFileExist(pngPath)) then
		pngPath = "etc/logo.png"
	end
	local logo = self.mLogoEn
	local uiPngTexture = logo:GetComponent("YXTextureImage")
	uiPngTexture.isNativeSize = true
	uiPngTexture.isColorReset = true
	uiPngTexture:SetImageFromFullPath(CS.StreamingPath() .. pngPath)
end

function UIAnniversaryMCitySow:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)

end

------------------------------------------------------------------
return UIAnniversaryMCitySow


