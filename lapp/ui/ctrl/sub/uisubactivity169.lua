---
--- Created by Administrator.
--- DateTime: 2025/12/3 17:45:14
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubActivity169:LChildWnd
local UISubActivity169 = LxWndClass("UISubActivity169", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubActivity169:UISubActivity169()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubActivity169:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubActivity169:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubActivity169:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UISubActivity169:RefreshView()
end

function UISubActivity169:InitEvent()
	--- 返回按钮必备
	-- self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
end

function UISubActivity169:OnActivityConfigData(data,sid)
	if sid ~= self._sid then return end

	local actWebData = gModelActivity:GetWebActivityDataById(sid)
	if not actWebData then return end

	local config = actWebData.config

	local image = config.image
	if LxUiHelper.IsImgPathValid(image) then
		self:SetWndEasyImage(self.mBg,image,function()
			CS.ShowObject(self.mBg,true)
		end)
	end

	local LHOverturn = config.LHOverturn or 0
	local LHSize = config.LHSize or 1
	local LHPos = config.LHPos
	---@param dpSpine LDisplaySpine
	self:CreateWndSpine(self.mLHPos,config.LH,"showLH",false,function(dpSpine)
		if not self:IsWndValid() then return end
		if not dpSpine or not dpSpine:IsDpValid() then return end
		if LHOverturn > 0 then
			dpSpine:SetFlipX(true)
		end
		dpSpine:SetScale(LHSize)
		if not string.isempty(LHPos) then
			self:SetAnchorPos(self.mLHPos,LxDataHelper.ParseVector2NotEmpty2(LHPos))
		end
		CS.ShowObject(self.mLHPos,true)
	end)

	local codeImage = config.codeImage
	if LxUiHelper.IsImgPathValid(codeImage) then
		local codeImageSize = config.codeImageSize or 1
		local codeImagePos = config.codeImagePos
		self:SetWndEasyImage(self.mCodeImg,codeImage,function()
			self.mCodeImg.localScale = Vector3(codeImageSize,codeImageSize,codeImageSize)
			if not string.isempty(codeImagePos) then
				self:SetAnchorPos(self.mCodeImg,LxDataHelper.ParseVector2NotEmpty2(codeImagePos))
			end
			CS.ShowObject(self.mCodeImg,true)
		end)
	end

	local popImage = config.popImage
	if LxUiHelper.IsImgPathValid(popImage) then
		local popImageSize = config.popImageSize or 1
		local popImagePos = config.popImagePos
		self:SetWndEasyImage(self.mPopImg,popImage,function()
			self.mPopImg.localScale = Vector3(popImageSize,popImageSize,popImageSize)
			if not string.isempty(popImagePos) then
				self:SetAnchorPos(self.mPopImg,LxDataHelper.ParseVector2NotEmpty2(popImagePos))
			end
			CS.ShowObject(self.mPopImg,true)
		end)
	end

	local showPopTxt = false
	local Text = config.Text
	if not string.isempty(Text) then
		showPopTxt = true
		self:SetWndText(self.mPopText,Text)
	end
	CS.ShowObject(self.mPopText,showPopTxt)
end

function UISubActivity169:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid) self:OnActivityConfigData(data, sid) end)
end

function UISubActivity169:OnClickXXXBtnFunc()
end


function UISubActivity169:InitData()
	local sid = self:GetWndArg("sid")
	local subpage = self:GetWndArg("subPage") --支持跳转
	if subpage then
		sid = gModelActivity:GetSidByUniqueJump(subpage)
	end
	self._sid = sid
	if not sid then return end
	gModelActivity:ReqActivityConfigData(sid)
end

function UISubActivity169:InitText()
end



------------------------------------------------------------------
return UISubActivity169