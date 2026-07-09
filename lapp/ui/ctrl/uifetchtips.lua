---
--- Created by luofuwen.
--- DateTime: 2023/10/25 17:02:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFetchTips:LWnd
local UIFetchTips = LxWndClass("UIFetchTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFetchTips:UIFetchTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFetchTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFetchTips:OnCreate()
	LWnd.OnCreate(self)

	self._configList = {}
	self._okList = {}

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFetchTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:WndEventRecv(EventNames.DOWNLOAD_RES_UPDATE, function(...)  self:OnDownloadResUpdate(...) end)
	self:WndEventRecv(EventNames.DOWNLOAD_RES_OK, function(...)  self:OnDownloadResOK(...) end)

	self:InitView()
end

function UIFetchTips:OnBtnEnterClick()
	for i, v in ipairs(self._configList) do
		-- type = 1是打开界面
		if v.type == 1 then
			LGameUI:OpenWndWithLayer(v.param.sortLayer, v.resName, v.param.argList)
		end
	end
end

function UIFetchTips:OnDownloadResUpdate(config)
	self:RefreshView(config)
end

function UIFetchTips:RefreshView(config)
	if config.bundleName then
		CS.ShowObject(self.mDownloadText,true)
		if config.totalCnt and config.workCnt then
			local downloadCnt = config.totalCnt - config.workCnt
			self:SetWndText(self.mDownloadText,downloadCnt.."/"..config.totalCnt)
		end

		if config.ok then
			self:CheckResOk()
		end
	else
		CS.ShowObject(self.mDownloadText,false)
	end
end

function UIFetchTips:OnDownloadResOK(config)
	self:RefreshView(config)
end

function UIFetchTips:CheckResOk()
	self._okList = {}
	local bundleName = nil
	for i, v in ipairs(self._configList) do
		bundleName = v.bundleName
		if LResDownload:CheckRes(bundleName) then
			table.insert(self._okList, v)
		end
	end

	if #self._configList == #self._okList then
		CS.ShowObject(self.mBtnEnter,true)
		CS.ShowObject(self.mDownloadText,false)
		self:SetWndText(self.mInfoText, ccClientText(167))
	end
end

function UIFetchTips:InitView()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn1,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnEnter,function() self:OnBtnEnterClick() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndButtonText(self.mBtnEnter,ccClientText(38510))
	self:SetWndText(self.mLblBiaoti, ccClientText(146))
	self:SetWndText(self.mInfoText, ccClientText(147))
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	CS.ShowObject(self.mBtnEnter,false)
	CS.ShowObject(self.mDownloadText,false)

	local config = self:GetWndArgList()
	table.insert(self._configList, config)

	self:CheckResOk()
end

function UIFetchTips:AddConfig(config)
	table.insert(self._configList, config)
	self:CheckResOk()
end

------------------------------------------------------------------
return UIFetchTips


