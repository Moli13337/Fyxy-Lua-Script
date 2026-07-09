---
--- Created by Administrator.
--- DateTime: 2023/10/18 19:25:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAdvPhotoPop:LWnd
local UIAdvPhotoPop = LxWndClass("UIAdvPhotoPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAdvPhotoPop:UIAdvPhotoPop()
	--url后插入 ?sojumpparm=玩家id|服务器id|活动refId
	self._linkExtra = "?sojumpparm="
	self._linkParamFormat = "%s|%s|%s"
	self._inLocalFormat = "%s-%s-%s-%s"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAdvPhotoPop:OnWndClose()
	self._activityCfg = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAdvPhotoPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAdvPhotoPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitParam()
end

function UIAdvPhotoPop:InitTop()
	if not self._activityCfg then return end

	local config = self._activityCfg
	local path   = config.image
	if LxUiHelper.IsImgPathValid(path) then
		local imgPos 	= config.imagePos
		local imgSize 	= config.imageSize
		self:SetWndEasyImage(self.mBgImg, path, function()
			if not CS.IsValidObject(self.mBgImg) then return end
			if not string.isempty(imgSize) then
				local imgSizeNum = tonumber(imgSize)
				self.mBgImg.localScale = Vector3.New(imgSizeNum, imgSizeNum, imgSizeNum)
			end

			if not string.isempty(imgPos) then
				self:SetAnchorPos(self.mBgImg, LxDataHelper.ParseVector2NotEmpty(imgPos))
			end

			CS.ShowObject(self.mBgImg, true)
		end, true)
	end

	path = config.title
	if LxUiHelper.IsImgPathValid(path) then
		local titleImgPos 	= config.titlePos
		local titleImgSize 	= config.titleSize
		self:SetWndEasyImage(self.mTitleImg, path, function()
			if not CS.IsValidObject(self.mTitleImg) then return end
			if not string.isempty(titleImgSize) then
				local sizeNum = tonumber(titleImgSize)
				self.mTitleImg.localScale = Vector3.New(sizeNum,sizeNum,sizeNum)
			end

			if not string.isempty(titleImgPos) then
				self:SetAnchorPos(self.mTitleImg, LxDataHelper.ParseVector2NotEmpty(titleImgPos))
			end

			CS.ShowObject(self.mTitleImg, true)
		end, true)
	end

	path = config.jumpBtnIcon
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mGoImage, path, function()
			if not CS.IsValidObject(self.mGoImage) then return end
			CS.ShowObject(self.mGoImage, true)
		end,true)

		local text = config.jumpBtnText
		if not string.isempty(text) then
			self:SetWndText(self.mGoText, text)
			CS.ShowObject(self.mGoText, true)
		end
	end

	local pos = config.jumpBtnPos
	if not string.isempty(pos) then
		self:SetAnchorPos(self.mBtnGo, LxDataHelper.ParseVector2NotEmpty(pos))
	end

	local eff = config.jumpBtnFx
	if not string.isempty(eff) then
		self:CreateWndEffect(self.mEffRoot, eff, eff, 100, false, false)
		CS.ShowObject(self.mEffRoot, true)
	end
	CS.ShowObject(self.mBtnGo, true)


	if self:CheckTipToggleShow() then
		local str = config.tipDesc
		if not string.isempty(str) then
			self:SetWndText(self.mToggleText, str)
			pos 	= config.tipPos
			if not string.isempty(pos) then
				self:SetAnchorPos(self.mToggle, LxDataHelper.ParseVector2NotEmpty(pos))
			end
		end

		--打开默认是否勾选
		local tipInitial = config.tipInitial
		self:SetWndToggleValue(self.mToggle, tipInitial == 1)
		CS.ShowObject(self.mToggle, true)
	end
end

function UIAdvPhotoPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)

	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			if(v.sid == self._sid)then
				self:InitView()
				return
			end
		end
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		local activity = pb.activity
		if(activity.sid == self._sid)then
			self:InitView()
		end
	end)
end
--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIAdvPhotoPop:InitView()
	self:InitData()
	self:InitTop()
end

function UIAdvPhotoPop:ReSetInLocalPlayerValue()
	local actDataList = string.split(LPlayerPrefs.advertisingPhoto, '|')

	local time 		  = GetTimestamp()
	local resultListValue
	local curSid      = tostring(self._sid)
	for k,v in ipairs(actDataList) do
		local curActData = string.split(v, '-')
		local actSid     = curActData[1]
		local actEndTime = tonumber(curActData[2]) or 0
		local lastRecordTime = tonumber(curActData[4]) or 0
		local destroyDayTime = LUtil.GetNextDayTimes(tonumber(lastRecordTime),7) --记录最大保持7天，超过7天的记录，删除记录
		local isDestroy = destroyDayTime < GetTimestamp()
		if not isDestroy and (actEndTime == 0 or time < actEndTime) and actSid ~= curSid then
			if not resultListValue then
				resultListValue = v
			else
				resultListValue = resultListValue.."|"..v
			end
		end
	end

	local jumpIndex = self._needNextJumpOpen and 1 or 0
	local curValue = string.replace(self._inLocalFormat, curSid, self._endTime or 0, jumpIndex, GetTimestamp())
	if not resultListValue then
		resultListValue = curValue
	else
		resultListValue = curValue.."|"..resultListValue
	end

	LPlayerPrefs.SetAdvertisingPhoto(resultListValue)
end

function UIAdvPhotoPop:InitParam()
	self._sid = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	local _sid = self._sid

	self._needNextJumpOpen = false

	self:SetWndText(self.mCloseTip, ccClientText(10103))

	gModelActivity:ReqActivityConfigData(_sid)
end

function UIAdvPhotoPop:OnClickToggle(value)
	if value then
		self._needNextJumpOpen  = true
	else
		self._needNextJumpOpen = false
	end
end
--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIAdvPhotoPop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitView()
end

function UIAdvPhotoPop:InitData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	self._activityData = gModelActivity:GetActivityBySid(self._sid)
	self._endTime      = self._activityData.endTime
	local data = webData.config
	self._activityCfg = data
	local closeTipPos = data.closeTipPos
	if not string.isempty(closeTipPos) then
		local pos = LxDataHelper.ParseVector2NotEmpty2(closeTipPos)
		self:SetAnchorPos(self.mCloseTip, pos)
	end
end

function UIAdvPhotoPop:ShowWindowContent(jumpLink)
	local playerId = gLGameLogin:GetLoginIdentityId() -- gLGameLogin:GetPlayerId()
	local serverId = gLGameLogin:GetServerId()

	--url后插入 ?sojumpparm=玩家id|服务器id
	local linkStr = string.replace(self._linkParamFormat, playerId, serverId, self._sid)
	local link = string.urlencode(linkStr)
	link = jumpLink..self._linkExtra..link

	--local desc = self._activityCfg.desc or ""
	--GF.OpenWndTop("UIQstionnaireContent",{link = link, sid = self._sid, titleStr = desc})
	CS.UApplication.OpenURL(link)
end

function UIAdvPhotoPop:InitEvent()
	self:SetWndClick(self.mCloseBtn, function(...) self:ClickCloseFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage, function(...) self:ClickCloseFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnGo, function() self:OnClickGoBtn() end)
	self:SetWndToggleValue(self.mToggle, false)
	self:SetWndToggleDelegate(self.mToggle, function(value) self:OnClickToggle(value) end)
end

function UIAdvPhotoPop:ClickCloseFunc()
	self:ReSetInLocalPlayerValue()
	self:WndClose()
end

function UIAdvPhotoPop:CheckTipToggleShow()
	if not (self._activityData and self._activityCfg) then
		return false
	end

	local tip = self._activityCfg.tip
	if string.isempty(tip) then
		return false
	end

	return tip == 1
end

function UIAdvPhotoPop:OnClickGoBtn()
	self._isClickGo = true
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_TEMP51,"点击跳转")

	local activityCfg = self._activityCfg
	if not activityCfg then
		self:ClickCloseFunc()
		return
	end

	local jump = activityCfg.jump
	local jumpLink = activityCfg.jumpLink
	local jumpActivity = activityCfg.jumpActivity

	if jump == 0 and not string.isempty(jumpLink) then
		--跳转网页
		self:ShowWindowContent(jumpLink)
	else
		if jumpActivity and jumpActivity > 0 then
			local gotoSid = gModelActivity:GetSidByUniqueJump(jumpActivity)
			if gotoSid then
				gModelActivity:CommonActJump(gotoSid)
				self:ClickCloseFunc()
				return
			end
		end
		if gModelFunctionOpen:CheckIsOpened(jump,true) then
			gModelFunctionOpen:Jump(jump,self:GetWndName())
		end
		self:ClickCloseFunc()
	end
end


------------------------------------------------------------------
return UIAdvPhotoPop


