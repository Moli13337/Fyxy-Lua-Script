---
--- Created by BY.
--- DateTime: 2023/10/7 14:41:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIProlicPop:LWnd
local UIProlicPop = LxWndClass("UIProlicPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIProlicPop:UIProlicPop()
	self._uiIconList = {}
	self._modelEnum = ModelActivity.NEWYEAR2022_ITEM_8
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIProlicPop:OnWndClose()
	self:ClearCommonIconList(self._uiIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIProlicPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIProlicPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIProlicPop:ResetData(pb)
	local pageId = self._modelList[self._modelId]

	for i, v in ipairs(pb.pages) do
		if v.pageId == pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self._page = page
		end
	end
	self:RefreshData()
end

function UIProlicPop:InitCommand()
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(24702))
	local sid = self:GetWndArg("sid")
	local _page = self:GetWndArg("page") --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId

	self._modelList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = ModelActivity.NEWYEAR2022_ITEM_8,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_67] = ModelActivity.HAPPY_COUNTRY_7,
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = ModelActivity.KING_STREET_3,
		-- [ModelActivity.FAIRY_FATHER_DAY] 	   = ModelActivity.FATHER_DAY_BOX,
		[ModelActivity.MODEL_ACTIVITY_TYPE_129] = 2
	}

	local modelEnum = self._modelList[modelId]
	if modelEnum then
		self._modelEnum = modelEnum
	end

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIProlicPop:SetRuleDivText(str)
	local isShow = not string.isempty(str)

	CS.ShowObject(self.mDescContent, isShow)
	if not isShow then return end

	self:SetWndText(self.mDescText,str)
end

function UIProlicPop:RefreshData()
	local _page = self._page
	if not _page then return end
	local list = _page.entry

	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
		_uiCellList:DrawAllItems()
	else
		_uiCellList = self:GetUIScroll("UIProlicPop")
		_uiCellList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER_GRID)
		_uiCellList:EnableScroll(true,false)
		self._uiCellList = _uiCellList
	end
end

function UIProlicPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if(self._sid ~= sid)then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end

function UIProlicPop:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config

	local binWeightShow,bingopolTxt = data.binWeightShow,data.bingopolTxt
	self:SetWndText(self.mTitleText,binWeightShow)
	self:SetRuleDivText(bingopolTxt)

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIProlicPop:ListItem(list, item, itemdata, itempos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local root = self:FindWndTrans(item,"Root")
	local icon 	= self:FindWndTrans(root,"CommonUI/Icon")
	local probText 	= self:FindWndTrans(root,"ProbText")

	local instanceId 	= item:GetInstanceID()
	local moreInfo = entryCfg.moreInfo
	if not string.isempty(moreInfo) then
		local arr = string.split(moreInfo,"|")
		self:SetWndText(probText,arr[2])
	end

	local rewards = LxDataHelper.ParseItem(entryCfg.reward)
	local reward = rewards[1]

	local baseClass = self._uiIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiIconList[instanceId] = baseClass
		baseClass:Create(icon)
	end
	baseClass:SetCommonReward(reward.itemType,reward.itemId,reward.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetWndClick(root,function ()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
end

function UIProlicPop:InitEvent()
	self._modelList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = ModelActivity.NEWYEAR2022_ITEM_8,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_67] = ModelActivity.HAPPY_COUNTRY_7,
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = ModelActivity.KING_STREET_3,
		-- [ModelActivity.FAIRY_FATHER_DAY]	   = ModelActivity.FATHER_DAY_BOX,
		[ModelActivity.MODEL_ACTIVITY_TYPE_129] = 2
	}
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:WndClose() end)
end
------------------------------------------------------------------
return UIProlicPop


