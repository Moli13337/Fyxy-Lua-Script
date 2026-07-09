---
--- Created by Administrator.
--- DateTime: 2023/10/21 15:00:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISpreadActContent:LWnd
local UISpreadActContent = LxWndClass("UISpreadActContent", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISpreadActContent:UISpreadActContent()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISpreadActContent:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISpreadActContent:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISpreadActContent:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:RefreshContent()
end


function UISpreadActContent:OpenTwitterUrl()
	local isShow, link = gModelPlayer:CheckShowTwitterLink()
	if not isShow then
		return
	end

	CS.UApplication.OpenURL(link)
end


function UISpreadActContent:OnClickTwitter()
	local sid = self:GetWndArg("sid")
	gModelActivity:OnActivitySpecialOpReq(sid,nil,nil,nil, nil, ModelActivity.SHARE)
	self:OpenTwitterUrl()

	local list = {self.mBg}
	local shareData =
	{
		shareScene=LShareConst.SCENE_TWITTER,
		shareLocation="GameShareActivity138",
	}

	gLGameUI:CaptureUIScreen(self:GetWndTrans(),list,true,shareData)
end


function UISpreadActContent:OnClickSave()

	local onlySave = self:GetWndArg("onlySave")
	if onlySave == 0  then
		local sid = self:GetWndArg("sid")
		gModelActivity:OnActivitySpecialOpReq(sid,nil,nil,nil, nil, ModelActivity.SHARE)
	end
	local list = {self.mBg}
	gLGameUI:CaptureUIScreen(self:GetWndTrans(),list,false)
end

function UISpreadActContent:RefreshContent()
	local bgPath = self:GetWndArg("bgPath")
	local showTwitter = self:GetWndArg("showTwitter")
	self:SetWndEasyImage(self.mBg,bgPath)

	CS.ShowObject(self.mTwitterBtn,showTwitter)
	self:SetWndText(self.mTwitterBtnName, ccClientText(21180))
	self:SetWndText(self.mSaveBtnName,ccClientText(20820))

	self:SetWndClick(self.mSaveBtn,function ()
		self:OnClickSave()
	end)

	self:SetWndClick(self.mTwitterBtn,function ()
		self:OnClickTwitter()
	end)

	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UISpreadActContent


