---
--- Created by Administrator.
--- DateTime: 2023/10/7 20:07:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPggPop:LWnd
local UIPggPop = LxWndClass("UIPggPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPggPop:UIPggPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPggPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPggPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPggPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshUIView()
end

function UIPggPop:RefreshUIView()
	local activityWedData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWedData then
		gModelActivity:ReqActivityConfigData(self._sid)
		return
	end

	self:InitTop()
end

function UIPggPop:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
end

function UIPggPop:InitData()
	self._sid = self:GetWndArg("sid") 				-- 活动的sid
	self._closeFunc = self:GetWndArg("closeFunc")		-- 关闭按钮的回调
end

function UIPggPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickCloseButton() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOkBtn,function () self:OnClickCloseButton() end, LSoundConst.CLICK_BUTTON_COMMON)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIPggPop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitTop()
end

function UIPggPop:OnClickCloseButton()
	local args = string.format("%s_%s", 2, 0)
	gModelActivity:OnActivitySpecialOpReq(self._sid,0,0,nil,args,ModelActivity.EGG_REWARD)

	if self._closeFunc then self._closeFunc() end
	self:WndClose()
end

function UIPggPop:InitTop()
	local activityWedData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityWedData then return end

	local config = activityWedData.config

	self:SetWndButtonText(self.mOkBtn, ccClientText(26700))
	CS.ShowObject(self.mOkBtn, true)

	local path = config.pictureTwo or GameTable.CityMapConfRef["pictureTwo"] --兼容原配置
	if LxUiHelper.IsImgPathValid(path) then
		local pos = config.pictureTwoPos or GameTable.CityMapConfRef["pictureTwoPos"]  --兼容原配置

		self:SetWndEasyImage(self.mPicture, path,function()
			if not string.isempty(pos) then
				self:SetAnchorPos(self.mPicture, LxDataHelper.ParseVector2NotEmpty(pos))
			end

			CS.ShowObject(self.mPicture, true)
		end, true)
	end

	path = config.titleTwo or GameTable.CityMapConfRef["titleTwo"]
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTitleImg, path,function()
			CS.ShowObject(self.mTitleImg, true)
		end, true)
	end
end

------------------------------------------------------------------
return UIPggPop


