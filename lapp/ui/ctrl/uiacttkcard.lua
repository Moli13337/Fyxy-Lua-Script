---
--- Created by BY.
--- DateTime: 2023/10/9 17:05:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActTkCard:LWnd
local UIActTkCard = LxWndClass("UIActTkCard", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActTkCard:UIActTkCard()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActTkCard:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActTkCard:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActTkCard:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIActTkCard:OnClickAward()
	local _daRward = self._daRward
	if not _daRward then return end
	local goalData = _daRward.goalData
	local status = goalData.status
	if status == 1 then
		gModelActivity:OnActivityReceiveGoalReq(self._sid,_daRward.pageId,_daRward.entryId)
	elseif status == 0 then
		local _sid = self._sid
		local entryCfg = gModelActivity:GetWebActivityEntryData(_sid,_daRward.pageId,_daRward.entryId)
		local name 	= entryCfg.name
		local reward 	= LxDataHelper.ParseItem(entryCfg.reward)
		GF.OpenWnd("WndBandThemeTaskGiftPop",{
			sid = _sid,
			title = name,
			desc = entryCfg.description,
			itemList = reward,
			isReceived = status == 2,
		})
	end
end

function UIActTkCard:OnTryTcpReconnect()
	self:WndClose()
end
function UIActTkCard:InitCommand()
	local sid = self:GetWndArg("sid")
	local _page = self:GetWndArg("page") --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	local taskEnumList = self._modelEnum[modelId]
	self._basicsTask,self._specialTask = taskEnumList[1],taskEnumList[2]
	self._modelId = modelId
	self._sid = sid
	gModelActivity:ReqActivityConfigData(sid)
end
function UIActTkCard:RefreshData()
	local pages = self.pages
	if not pages then return end
	local _basicsPage,_specialPage = pages[self._basicsTask],pages[self._specialTask]
	local _basicsList,_specialList = _basicsPage.entry,_specialPage.entry

	local _uiTaskList1 = self._uiTaskList1
	if _uiTaskList1 then
		_uiTaskList1:RefreshList(_basicsList)
	else
		_uiTaskList1 = self:GetUIScroll("_uiTaskList1")
		_uiTaskList1:Create(self.mTask1Scroll,_basicsList,function(...) self:ListItem(...) end)
	end
	local list2,list3 = {},{}
	for i, v in ipairs(_specialList) do
		if i <= 5 then
			table.insert(list2,v)
		elseif 5 < i and i <= 8 then
			table.insert(list3,v)
		end
	end
	local daRward = _specialList[9]
	CS.ShowObject(self.mBtnAward,daRward)
	if daRward then
		local goalData = daRward.goalData
		local status = goalData.status
		self._daRward = daRward

		local goal = #_basicsList
		local schedule = 0
		for i, v in ipairs(_basicsList) do
			local status = v.goalData.status
			if status > 0 then
				schedule = schedule + 1
			end
		end

		self.mAwardBar.maxValue = goal
		self.mAwardBar.value = schedule
		self:SetWndText(self.mBarText,string.format("%s/%s",schedule,goal))
		self:SetWndEasyImage(self.mBtnAward,status == 1 and "activity_candy_icon_on_3" or "activity_candy_icon_off_3")
		CS.ShowObject(self.mAwardEff,status == 1)
		if status == 1 then
			self:CreateWndEffect(self.mAwardEff,"fx_ui_renwuka_01","UIActTkCard_mAwardEff",100)
		end
		CS.ShowObject(self.mAwardMask,status == 2)
	end

	local _uiTaskList2 = self._uiTaskList2
	if _uiTaskList2 then
		_uiTaskList2:RefreshList(list2)
	else
		_uiTaskList2 = self:GetUIScroll("_uiTaskList2")
		_uiTaskList2:Create(self.mTask2Scroll,list2,function(...) self:ListItem(...) end)
	end
	local _uiTaskList3 = self._uiTaskList3
	if _uiTaskList3 then
		_uiTaskList3:RefreshList(list3)
	else
		_uiTaskList3 = self:GetUIScroll("_uiTaskList3")
		_uiTaskList3:Create(self.mTask3Scroll,list3,function(...) self:ListItem(...) end)
	end
end
function UIActTkCard:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
end
function UIActTkCard:InitDate()
	self._modelEnum = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {ModelActivity.SWEET_COUNTRY_14,ModelActivity.SWEET_COUNTRY_15},
	}
	self._modelClose = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = "UIActSweetCountry",
	}
	self:SetWndText(self.mCloseText,ccClientText(15710))
end
function UIActTkCard:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBtnAward,function (...) self:OnClickAward() end)
end
function UIActTkCard:OnActivityConfigData()
	local _sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	local data = activityData.config
	local puzTaskBg,puzTaskHero,puzTaskHeroPos,puzTaskListTitle,puzTaskListTitlePos
	= data.puzTaskBg,data.puzTaskHero,data.puzTaskHeroPos,data.puzTaskListTitle,data.puzTaskListTitlePos
	self._puzTaskHelpTitle,self._puzTaskHelpTxt = data.puzTaskHelpTitle,data.puzTaskHelpTxt

	if LxUiHelper.IsImgPathValid(puzTaskBg) then
		CS.ShowObject(self.mBg,true)
		self:SetWndEasyImage(self.mBg,puzTaskBg)
	end
	if not string.isempty(puzTaskHero) then
		local imgArr = string.split(puzTaskHero,"=")
		local posParent
		if imgArr[1] == "1" then
			posParent = self.mHeroImg
			self:SetWndEasyImage(posParent,imgArr[2],nil,true)
		else
			posParent = self.mHeroSpine
			local spineName = imgArr[2]
			self:CreateWndSpine(posParent,spineName,spineName.."WndNewYear2022Type5",false)
		end
		if imgArr[3] then
			local flip = tonumber(imgArr[3])
			posParent.localScale = Vector2.New(flip,1)
		end
		CS.ShowObject(posParent,true)
		if not string.isempty(puzTaskHeroPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(puzTaskHeroPos)
			self:SetAnchorPos(posParent, pos)
		end
	end
	if LxUiHelper.IsImgPathValid(puzTaskListTitle) then
		local posParent = self.mTitleImg
		CS.ShowObject(posParent,true)
		self:SetWndEasyImage(posParent,puzTaskListTitle)
		if not string.isempty(puzTaskListTitlePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(puzTaskListTitlePos)
			self:SetAnchorPos(posParent, pos)
		end
	end
	local taskEnumList = self._modelEnum[self._modelId]
	gModelActivity:OnActivityPageReq(_sid,taskEnumList)
end
function UIActTkCard:OnClickClose()
	local wndName = self._modelClose[self._modelId]
	GF.OpenWnd(wndName,{sid = self._sid})
	self:WndClose()
end

function UIActTkCard:OnClickHelp()
	local title = self._puzTaskHelpTitle
	local text = self._puzTaskHelpTxt
	GF.OpenWnd("UIBzTips",{title= title,text = text})
end
function UIActTkCard:ResetData(pb)
	local _pages = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local pageId = v.pageId
		if self._basicsTask == pageId or self._specialTask == pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			_pages[pageId] = page
		end
	end
	self.pages = _pages
	self:RefreshData()
end

function UIActTkCard:ListItem(list, item, itemdata, itempos)
	local _sid = self._sid
	local pageId = itemdata.pageId
	local entryId = itemdata.entryId
	local entryCfg = gModelActivity:GetWebActivityEntryData(_sid,pageId,entryId)
	local root = self:FindWndTrans(item,"Root")

	local image = self:FindWndTrans(root,"Image")
	local iconMask = self:FindWndTrans(root,"IconMask")
	local mask = self:FindWndTrans(root,"Mask")

	local indexText = self:FindWndTrans(root,"IndexBg/IndexText")

	local _basicsTask = self._basicsTask			--任务卡-基础任务表
	local description = entryCfg.description
	local goalData = itemdata.goalData
	local status = goalData.status

	if pageId == _basicsTask then
		CS.ShowObject(image,status >= 1)
		CS.ShowObject(mask,status == 0)
		self:SetWndText(indexText,LUtil.FormatHurtNumSpriteText(itempos))
	else
		CS.ShowObject(image,status == 1)
		CS.ShowObject(iconMask,status == 0)
		CS.ShowObject(mask,status == 2)
	end

	self:SetWndClick(root, function()
		if pageId == _basicsTask then
			if status == 0 then
				GF.OpenWnd("UITkTips",{root = root,sid = _sid,itemdata = itemdata})
			else
				GF.ShowMessage(ccClientText(27656))
			end
		else
			if status == 1 then
				gModelActivity:OnActivityReceiveGoalReq(_sid,pageId,entryId)
			else
				local name 	= entryCfg.name
				local reward 	= LxDataHelper.ParseItem(entryCfg.reward)
				GF.OpenWnd("WndBandThemeTaskGiftPop",{
					sid = _sid,
					title = name,
					desc = description,
					itemList = reward,
					isReceived = status == 2,
				})
			end
		end
	end)
end
------------------------------------------------------------------
return UIActTkCard


