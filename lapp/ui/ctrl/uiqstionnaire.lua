---
--- Created by BY.
--- DateTime: 2023/10/11 14:55:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIQstionnaire:LWnd
local UIQstionnaire = LxWndClass("UIQstionnaire", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIQstionnaire:UIQstionnaire()
	---@type UIIconEasyList
	self._uiIconEasyList = nil

	--url后插入 ?sojumpparm=玩家id|服务器id|活动refId
	self._linkExtra = "sojumpparm="
	self._linkParamFormat = "%s|%s|%s"
	self._sdkKey = "sdkaihelp"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIQstionnaire:OnWndClose()
	if self._uiIconEasyList then
		self._uiIconEasyList:Destroy()
		self._uiIconEasyList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIQstionnaire:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIQstionnaire:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitMsg()
	self:InitData()
	self:InitEvent()

	--self:SetIcon()
end

function UIQstionnaire:SetContent()

	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then
		return
	end

	local data = activityCfg.config

	self._iamge = data.image

	-- 艺术字
	self._descIcon = data.descIcon

	-- 艺术字坐标：string
	self._descIconPosition = data.descIconPosition--"52,103"

	-- 描述
	self._helpDes = data.helpDes

	-- 描述坐标
	self._helpDesPosition = data.helpDesPosition--"40,-3.5"

	-- 描述1
	self._helpDes1 = data.helpDes1

	-- 描述坐标1
	self._helpDesPosition1 = data.helpDesPosition1--"40,-3.5"

	-- 物品
	self._showItmeList = string.split(data.showItme,",")

	-- http
	self._link = data.link or ""

	-- 按钮文字
	self._buttonDesc = data.buttonDesc

	-- 按钮图片
	self._buttonIcon = data.buttonIcon

	-- 调查问卷监视兑换码（海外使用）
	self._rewardId = data.rewardId

	-- 标题描述
	local str = data.title
	if not string.isempty(str) then
		self._titleStr   = str
	end

	self:SetWndEasyImage(self.mMainImage,self._iamge,function () CS.ShowObject(self.mMainImage,true) end,true)
	self:SetWndEasyImage(self.mTxetImage,self._descIcon,function () CS.ShowObject(self.mTxetImage,true) end,true)
	self:SetWndButtonImg(self.mGoTo,self._buttonIcon,nil,true)

	CS.ShowObject(self.mHelpList, true)
	self:SetWndText(self.mHelpText,self._helpDes)
	self:SetWndText(self.mDescText, self._helpDes1)
	self:SetWndButtonText(self.mGoTo,self._buttonDesc)

	self:SetAnchorPos(self.mTxetImage, LxDataHelper.ParseVector2NotEmpty(self._descIconPosition))
	self:SetAnchorPos(self.mHelpList, LxDataHelper.ParseVector2NotEmpty(self._helpDesPosition))
	self:SetAnchorPos(self.mDescText, LxDataHelper.ParseVector2NotEmpty(self._helpDesPosition1))

	self:InitRewardList(self._showItmeList)

end

function UIQstionnaire:InitEvent()

	self:SetWndClick(self.mBg,function ()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	-- 前往答题
	self:SetWndClick(self.mGoTo,function ()
		self:OnClickGoToBtn()
	end,LSoundConst.CLICK_BUTTON_COMMON)

end

function UIQstionnaire:ShowSDKHelp(callTypeStr)
	if string.isempty(callTypeStr) then
		printInfoNR("callTypeStr is a nil, self._link = "..(self._link or "nil"))
		return
	end

	--添加发放奖励监听
	self:AddGiftListenerRewardId()

	local callType = tonumber(callTypeStr)
	gLSdkImpl:CallMethod(LSdkMethod.DoShowAIGMorFAQ,callType)
end

function UIQstionnaire:ShowWindowContent()
	if not self._link then return end

	local playerId = gLGameLogin:GetLoginIdentityId() -- gLGameLogin:GetPlayerId()
	local serverId = gLGameLogin:GetServerId()

	--url后插入 ?sojumpparm=玩家id|服务器id
	local linkStr = string.replace(self._linkParamFormat, playerId, serverId, self._sid)
	local serverLink = string.urlencode(linkStr)

	local extraFont = '?'
	if string.find(self._link, '?', nil, true) then
		extraFont = '&'
	end

	serverLink = extraFont..self._linkExtra..serverLink

	local resultLink = self._link
	if gLGameLanguage:IsHmtRegion() or gLGameLanguage:IsJapanRegion() then --港澳台(和日本)问卷关闭后直接获得奖励
		self:AddGiftListenerRewardId()
	elseif gLGameLanguage:IsKoreaRegion() then
		local linkParam = gLSdkImpl:CallMethod(LSdkMethod.GetSdkLinkParam) or ""
		if not string.isempty(linkParam) then
			resultLink = resultLink..linkParam
		end
	end

	resultLink = resultLink..serverLink
	GF.OpenWndTop("UIQstionnaireContent",{link = resultLink, sid = self._sid, titleStr = self._titleStr})
	--CS.UApplication.OpenURL(self._link)
end

function UIQstionnaire:AddGiftListenerRewardId()
	if not string.isempty(self._rewardId) then
		local rewardId = self._rewardId
		gModelActivity:SetListenerSDKQuestionRewardId(rewardId)
	end
end

function UIQstionnaire:InitData()

	self._sid = self:GetWndArg("sid")

	local page = self:GetWndArg("page")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	gModelActivity:ReqActivityConfigData(self._sid)
	self:SetWndText(self.mCloseTipObj,ccClientText(10103))
end

function UIQstionnaire:OnClickGoToBtn()
	local linkList = string.split(self._link, "=")
	if self._sdkKey == linkList[1] then
		--打开sdk接口
		self:ShowSDKHelp(linkList[2])
	else
		--打开网络连接http
		self:ShowWindowContent()
	end

	self:WndClose()
end

function UIQstionnaire:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid~= self._sid then
			return
		end
		self:SetContent()
	end)


end

--function UIQstionnaire:SetIcon()
--
--end

function UIQstionnaire:InitRewardList(itemsList)
	-- 物品奖励显示
	local dataList = {}
	for k,v in ipairs(itemsList) do
		local data = string.split(v,"=")
		local refId = tonumber(data[2]) or 0
		local num = tonumber(data[3]) or 0
		local type = tonumber(data[1]) or 0
		table.insert(dataList, {
			itemType = type,
			itemId = refId,
			itemNum = num,
		})
	end
	local uiList = self._uiIconEasyList
	if not uiList then
		uiList = UIIconEasyList:New()
		self._uiIconEasyList = uiList
		uiList:Create(self, self.mRewardList)
		uiList:EnableScroll(true,true)
	end
	uiList:RefreshList(dataList)

end
------------------------------------------------------------------
return UIQstionnaire


