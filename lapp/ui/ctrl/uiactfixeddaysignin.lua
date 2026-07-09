---
--- Created by BY.
--- DateTime: 2023/10/11 11:08:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActFixedDaySignIn:LWnd
local UIActFixedDaySignIn = LxWndClass("UIActFixedDaySignIn", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActFixedDaySignIn:UIActFixedDaySignIn()
	self._uiIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActFixedDaySignIn:OnWndClose()
	self:ClearCommonIconList(self._uiIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActFixedDaySignIn:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActFixedDaySignIn:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActFixedDaySignIn:OnClickGet()
	local pages = self.pages
	if not pages then
		return
	end
	local entryList = pages.entry
	local list = {}
	for k,v in ipairs(entryList) do
		local status = v.goalData.status
		if status == 1 then
			local data = { sid = self._sid,pageId = v.pageId,entryId = v.entryId}
			table.insert(list, data)
		end
	end
	gModelActivity:OnActivityReceiveGoalListReq(list)
end

function UIActFixedDaySignIn:OnClickBigGift()
	local status = self._bigGiftStatus
	local msgStr
	if status == 1 then
		local _signInEnum = self._modelSignInEnum[self._modelId]
		gModelActivity:OnActivitySpecialOpReq(self._sid, 0, 0, 0, nil, _signInEnum)
		return
	elseif status == 0 then
		msgStr = self._signEndRewardTxt
	else
		msgStr = ccClientText(24710)
	end
	GF.ShowMessage(msgStr)
	local rewardList = LxDataHelper.ParseItem(self._signEndReward)
	GF.OpenWnd("UIBandThemeSignPop",{
		sid = self._sid,
		bigGiftStatus = status,
		itemList = rewardList,
		signBoxState = self._signBoxState
	})
end
function UIActFixedDaySignIn:OnClickClose()
	local wndName = self._modelClose[self._modelId]
	GF.OpenWnd(wndName,{sid = self._sid})
	self:WndClose()
end

function UIActFixedDaySignIn:ListItem(list, item, itemdata, itempos)
	local entryId = itemdata.entryId
	local pageId  = itemdata.pageId
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,entryId)
	if not entryCfg then return end
	local root = self:FindWndTrans(item,"Root")
	local comRoot = self:FindWndTrans(root,"ComRoot")
	local iconBg   = self:FindWndTrans(comRoot, "IconBg")
	local iconBg1   = self:FindWndTrans(comRoot, "IconBg1")
	local icon   = self:FindWndTrans(comRoot, "Icon")
	local mask 		= self:FindWndTrans(comRoot,"Mask")
	local eff 		= self:FindWndTrans(comRoot,"Eff")
	local dayText 	= self:FindWndTrans(root,"Image/DayText")
	local numText 	= self:FindWndTrans(root,"NumText")

	local instanceId 	= item:GetInstanceID()
	local goalData = itemdata.goalData
	local status = tonumber(goalData.status)
	local rewardList  = LxDataHelper.ParseItem(entryCfg.reward)
	local reward 		= rewardList[1]
	local iconStr = gModelItem:GetItemIconByRefId(reward.itemId)

	CS.ShowObject(iconBg,status ~= 1)
	CS.ShowObject(iconBg1,status == 1)
	CS.ShowObject(mask,status == 2)
	CS.ShowObject(eff,status == 1)
	self:SetWndText(dayText,entryCfg.name)
	self:SetWndEasyImage(icon,iconStr)
	self:SetWndText(numText,reward.itemNum)
	local circleBg1,circleBg2 = gModelGeneral:GetCommonItemCircleBgRef(reward)
	if LxUiHelper.IsImgPathValid(circleBg1) then
		self:SetWndEasyImage(iconBg, circleBg1)
		self:SetWndEasyImage(iconBg1, circleBg2)
	end

	if status == 1 then
		self:CreateWndEffect(eff,"ui_fx_mengjingxueyuan_01",instanceId,70, false, false)
	end
	local clickFunc = function()
		if(status == 1)then --可领取
			self:OnClickGet()
		else
			gModelGeneral:ShowCommonItemTipWnd(reward)
		end
	end
	self:SetWndClick(root,  clickFunc)
end

function UIActFixedDaySignIn:RefreshData()
	local pages = self.pages
	local _pageType = self._pageType
	local _pageMoreInfo = self._pageMoreInfo
	if not pages then return end
	if not _pageType then return end
	if not _pageMoreInfo then return end

	local list = pages.entry
	local len = #list
	local dayIndex = 1
	local dayInfo = nil
	for i, v in ipairs(list) do
		local goalData = v.goalData
		local status = tonumber(goalData.status)
		if status > 0 then
			dayIndex = i
			dayInfo = v
		else
			break
		end
	end
	local giftStatus = 0
	local _pageId = self._modelPageId[self._modelId]
	local bigGiftStatusKey = string.format("%s-%s-%s", self._sid, _pageId, _pageType)
	local isBigGiftGet     = _pageMoreInfo[bigGiftStatusKey]
	if isBigGiftGet == 1 then
		giftStatus = 2
	else
		local isGet = dayIndex >= len
		giftStatus = isGet and 1 or 0
	end

	local progressStr = ""
	local dayStr = dayIndex
	if dayIndex < len then
		dayStr = LUtil.FormatColorStr(dayIndex,"#f64438")
	end
	progressStr = string.format("%s/%s", dayStr, len)
	self.mGiftBar.maxValue = len
	self.mGiftBar.value = dayIndex
	self:SetWndText(self.mGiftProgressText, progressStr)
	local _signBoxState = self._signBoxState or {}
	local _signBoxEff = self._signBoxEff or {}
	local giftIconStr = _signBoxState[giftStatus + 1] or ""
	local giftEffStr = _signBoxEff[giftStatus + 1] or "0"
	self:SetWndEasyImage(self.mGiftBtn,giftIconStr,nil,true)
	self:SetWndEasyImage(self.mGiftIcon,giftIconStr)
	local _oldGiftEffStr = self._oldGiftEffStr
	if _oldGiftEffStr and _oldGiftEffStr ~= giftEffStr then
		self:DestroyWndEffectByKey("BoxEff")
	end
	if giftEffStr ~= "0" then
		if _oldGiftEffStr and _oldGiftEffStr ~= giftEffStr then
			self:DestroyWndEffectByKey("BoxEff")
		end
		self:CreateWndEffect(self.mGiftEff,giftEffStr,"BoxEff",100)
		self._oldGiftEffStr = giftEffStr
	end
	self._bigGiftStatus = giftStatus

	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshData(list)
	else
		_uiCellList = self:GetUIScroll("WndNewYear2022Type1")
		_uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
		_uiCellList:EnableScroll(len > 14,false)
		self._uiCellList = _uiCellList
	end
end
function UIActFixedDaySignIn:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mGiftBtn, function() self:OnClickBigGift() end)
end
function UIActFixedDaySignIn:InitDate()
	self._modelPageId = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = ModelActivity.NEWYEAR2022_ITEM_1,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = ModelActivity.MAGIC_ACADEMY1,
	}
	self._modelSignInEnum = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = ModelActivity.SPRING_FESTIVAL_SIGN_IN,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = ModelActivity.MAGIC_ACADEMY_SIGN_IN,
	}
	self._modelClose = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = "UIActNewYear2022",
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = "UIActMagicShcool",
	}
end
function UIActFixedDaySignIn:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end
function UIActFixedDaySignIn:InitCommand()
	--self:SetWndText(self.mCloseText,ccClientText(24700))
	self._sid = self:GetWndArg("sid")
	local _page = self:GetWndArg("page") --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		self._sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(self._sid)
	self._modelId = modelId
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActFixedDaySignIn:OnTryTcpReconnect()
	self:WndClose()
end
function UIActFixedDaySignIn:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	local signImg,boxTipTxt = data.signImg,data.boxTipTxt
	local signBoxState,signBoxEff = data.signBoxState,data.signBoxEff
	self._signEndReward,self._signEndRewardTxt = data.signEndReward,data.signEndRewardTxt

	if LxUiHelper.IsImgPathValid(signImg) then
		self:SetWndEasyImage(self.mBg,signImg)
	end
	if not string.isempty(signBoxState) then
		self._signBoxState = string.split(signBoxState,"|")
	end
	if not string.isempty(signBoxEff) then
		self._signBoxEff = string.split(signBoxEff,"|")
	end
	if not string.isempty(boxTipTxt) then
		self:SetWndText(self.mGiftTipsText,boxTipTxt)
	end

	gModelActivity:OnActivityPageReq(self._sid)
end
function UIActFixedDaySignIn:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	local _pageId = self._modelPageId[self._modelId]
	for i, v in ipairs(pb.pages) do
		if v.pageId == _pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self.pages = page
			self._pageType     = v.pageType
			self._pageMoreInfo = JSON.decode(page.moreInfo)
		end
	end
	self:RefreshData()
end
------------------------------------------------------------------
return UIActFixedDaySignIn


