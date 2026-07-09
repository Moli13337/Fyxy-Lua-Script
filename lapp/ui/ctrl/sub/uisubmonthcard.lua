---
--- Created by Administrator.
--- DateTime: 2023/10/9 16:43:05
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubMonthCard:LChildWnd
local UISubMonthCard = LxWndClass("UISubMonthCard", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubMonthCard:UISubMonthCard()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubMonthCard:OnWndClose()
	self:DestroyWndEffectAll()
	LChildWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubMonthCard:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubMonthCard:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitData()
	self:SetPara()
	self:SetTop()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp, function(...) self:OnActivityResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp, function(...) self:OnActivityReceiveGoalResp(...) end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)

	--local pbData = gModelActivity:GetActivityPageBySid(self._sid)
	--if pbData then
	--	self:OnActivityPageResp(pbData)
	--else
	--	gModelActivity:OnActivityPageReq(self._sid)
	--end

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
		if self._sid ~= sid then
			return
		end
		self:RefreshContent()
	end)

	gModelActivity:ReqActivityConfigData(self._sid)
	self:RefreshForeign()
end

function UISubMonthCard:OnClickVip()
	GF.OpenWndBottom("UIHuiYPay", { page = 1 })
end

function UISubMonthCard:OnDrawItem(list, item, itemdata, itempos)
	local bg = self:FindWndTrans(item, "bg")
	local NameTitle =self:FindWndTrans(item, "NameTitle")
	local textBg = self:FindWndTrans(item, "textBg")
	local textBgText_0 = self:FindWndTrans(textBg, "text_0")
	local text_0UIText = self:FindWndTrans(textBgText_0, "UIText")
	local text_0Icon = self:FindWndTrans(textBgText_0, "icon")
	local text_0ItemNum = self:FindWndTrans(textBgText_0, "itemNum")
	local textBgText_1 = self:FindWndTrans(textBg, "text_1")
	local text_1UIText = self:FindWndTrans(textBgText_1, "UIText")
	local text_1Icon = self:FindWndTrans(textBgText_1, "icon")
	local text_1ItemNum = self:FindWndTrans(textBgText_1, "itemNum")
	local backText = self:FindWndTrans(item, "BackText")

	local textBgText_2 = self:FindWndTrans(textBg, "text_2")
	local text_2UIText = self:FindWndTrans(textBgText_2, "UIText")
	local card = self:FindWndTrans(item, "card")
	local title = self:FindWndTrans(item, "title")
	local button = self:FindWndTrans(item, "button")
	local buttonText = self:FindWndTrans(button, "Light/Text")
	local buttonText2 = self:FindWndTrans(item, "buttonText2")
	-- local getTag = self:FindWndTrans(item, "getTag")
	local getInfo = self:FindWndTrans(item, "getInfo")
	local getInfoUIText = self:FindWndTrans(getInfo, "UIText")
	local getInfoItemIcon = self:FindWndTrans(getInfo, "itemIcon")
	local getInfoItemNum = self:FindWndTrans(getInfo, "itemNum")
	--local charIntro = self:FindWndTrans(item,"charIntro")
	--local charIntroNumIcon = self:FindWndTrans(charIntro,"numIcon")
	local countdown = self:FindWndTrans(item, "countdown")

	local proRoot = self:FindWndTrans(item, "proRoot")
	local proRootSlider = self:FindWndTrans(proRoot, "Slider")
	local SliderBackground = self:FindWndTrans(proRootSlider, "Background")
	local SliderFillArea = self:FindWndTrans(proRootSlider, "FillArea")
	local FillAreaFill = self:FindWndTrans(SliderFillArea, "Fill")
	local proRootProgressText = self:FindWndTrans(proRoot, "progressText")
	--local getIntro = self:FindWndTrans(item,"getIntro")

	local InstanceID = item:GetInstanceID()

	local entryId = itemdata.entryId
	local resCfg = self._resConfig[entryId]
	if not resCfg then
		return
	end
	local colorFam = "<color=#a1#>#a2#</color>"
	local color1 = itempos == 1 and "#454e90" or "#905945"
	local color2 = itempos == 1 and "#352c78" or "#b44823"

	if self._isVie then
		self:SetAnchorPos(title,Vector2.New(-20,130))
	end
	if self.jpj then
		self:SetAnchorPos(title,Vector2.New(-70,130))
		self:InitTextSizeWithLanguage(getInfoUIText,-2)
		self:InitTextSizeWithLanguage(getInfoItemNum,-2)
		getInfoItemIcon.localScale = Vector2.New(0.9,0.9,0.9)
	end
	self:SetWndClick(button, function() self:OnClickEntry(itemdata) end)
	--self:SetWndText(buttonText,itemdata.jumpDesc)
	--local itemId = itemdata.item.itemId
	local itemNum = itemdata.item.itemNum
	--for k,v in ipairs(items) do
	--	itemId = v.itemId
	--	itemNum = v.itemNum
	--end

	self:SetWndEasyImage(bg, itemdata.bgPath)

	if itemdata.nameTitle then
		self:SetWndEasyImage(NameTitle, itemdata.nameTitle, function()
			CS.ShowObject(NameTitle, true)
		end, true)
	end

	self:SetWndText(text_0UIText, string.replace(colorFam, color1, self.getText[itempos]))
	self:SetWndText(text_1UIText, string.replace(colorFam, color1, ccClientText(16107)))
	CS.ShowObject(textBgText_1, true)
	self:SetWndText(text_0ItemNum, string.replace(colorFam, color2, itemNum))

	local iconRef = gModelItem:GetRefByRefId(tonumber(itemdata.item.itemId))
	self:SetWndEasyImage(text_1Icon, iconRef.icon)
	self:SetWndEasyImage(text_0Icon, iconRef.icon)


	--self:SetWndEasyImage(textBgIntro,resCfg.introPath,nil,true)
	if not string.isempty(itemdata.cardPath) then
		CS.ShowObject(card, true)
		self:SetWndEasyImage(card, itemdata.cardPath, nil, true)
	else
		CS.ShowObject(card, false)
	end
	self:SetWndEasyImage(title, itemdata.titlePath, nil, true)
	--self:SetWndEasyImage(charIntroNumIcon,resCfg.numIconPath,nil,true)
	--self:SetWndText(charIntro,resCfg.charIntro)

	self:SetWndEasyImage(FillAreaFill, itemdata.barPath)

	local showVip = false
	if not string.isempty(resCfg.vipText) then
		showVip = true
		local uiHyper = UIHyperText:New()
		uiHyper:Create(text_2UIText)
		local str = uiHyper:AddHyper(resCfg.vipText, { func = function() self:OnClickVip() end })
		self:SetWndText(text_2UIText, str)
	end

	CS.ShowObject(textBgText_2, showVip)


	local jumpBtnIndex = self._jumpBtnList[entryId]
	local isShowJumpText = jumpBtnIndex == false

	local isActive = true
	local state = itemdata.state
	local btnStr = nil
	local showGray = false
	local showIntro = false
	local showCd = false
	if state == 0 then
		showIntro = true
		btnStr = itemdata.jumpDesc
		isActive = false
	elseif state == 1 then
		isShowJumpText = false
		btnStr = ccClientText(16100) -- "领  取")
		local key = "cardBtn" .. tostring(InstanceID)
		self:CreateWndEffect(button, "fx_anniu_03", key, 100)
	elseif state == 2 then
		showCd = true
		showGray = true
		btnStr = ccClientText(16001)
	end

	local conditionTips = self._conditionTips[entryId]
	if conditionTips == false then
		--配置控制屏蔽该文本显示
		showIntro = false
	end

	--CS.ShowObject(charIntro,showIntro)
	-- if showIntro then
	-- 	CS.ShowObject(countdown,true)
	-- 	self:SetWndText(countdown, string.replace(resCfg.charIntro, itemdata.condition[3] or 0))
	-- elseif showCd then
	-- 	CS.ShowObject(countdown,true)
	-- 	self:SetWndText(countdown, "")
	-- else
	-- 	CS.ShowObject(countdown,false)
	-- end

	--self:SetWndImageGray(button,showGray)
	-- CS.ShowObject(getTag, showGray)
	CS.ShowObject(button, not showGray and not isShowJumpText)
	CS.ShowObject(buttonText2, not showGray and isShowJumpText)
	--CS.EnableClickListener(button.gameObject,not showGray)

	local progressStr = nil
	local countdownStr = nil
	local totalDay = 1
	local totalGet = 1
	local totalBack = ""
	local value = 0
	local limitKey = "playerLimit_" .. itemdata.entryId
	local totalInfo = string.split(self._receiveData[limitKey], "=")
	if #totalInfo >= 2 then
		totalDay = tonumber(totalInfo[1])
		totalGet = tonumber(totalInfo[2])
		totalBack = totalInfo[3]
	end
	if isActive then
		local key = "receiveCount_" .. itemdata.entryId
		local receiveCnt = tonumber(self._receiveData[key])
		if not receiveCnt then
			receiveCnt = 0
		end
		countdownStr = ccClientText(16110)
		progressStr = string.replace(ccClientText(16102), receiveCnt, totalDay)
		value = 0
		if totalDay > 0 then
			value = receiveCnt / totalDay
		end
	else
		-- local testId = self._progressTextList[entryId] or 16102
		countdownStr = self.progressText[itempos]
		progressStr = string.replace(ccClientText(16102), itemdata.schedule, itemdata.goal) --"当前充值: %s/%s"

		local goal = tonumber(itemdata.goal)
		local schedule = tonumber(itemdata.schedule)
		if goal > 0 then
			value = schedule / goal
		end
	end

	self:SetWndText(getInfoUIText, ccClientText(16108))
	self:SetWndText(getInfoItemNum, totalGet)
	local popData = self.popTb[itempos]
	local backS = popData.type == 1 and popData.str or popData.str .. "\n" .. totalBack
	self:SetWndText(backText, backS)
	self:SetWndText(text_1ItemNum, string.replace(colorFam, color2, totalGet / totalDay))
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(getInfoUIText)
    UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(getInfoItemNum)

	local iconRef = gModelItem:GetRefByRefId(itemdata.item.itemId)
	self:SetWndEasyImage(getInfoItemIcon, iconRef.icon)
	--CS.ShowObject(getInfo,isActive)

	self:SetWndText(buttonText, btnStr)
	self:SetWndText(buttonText2, btnStr)

	progressStr = string.replace(colorFam, color1, progressStr)
	countdownStr = string.replace(colorFam, color2, countdownStr)
	self:SetWndText(proRootProgressText, progressStr)
	self:SetWndText(countdown, countdownStr)
	LxUiHelper.SetProgress(proRootSlider, value)

	self._uiItemDatas[itempos] = { item = item, itemdata = itemdata }
end

function UISubMonthCard:InitItemList(dataList)
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local moreInfo = activityData.moreInfo
	local data = JSON.decode(moreInfo)

	self._receiveData = data
	self:DestroyWndEffectAll()

	local uiList = self:GetUIScroll("itemList")
	uiList:Create(self.mItemList, dataList, function(...) self:OnDrawItem(...) end)

	self:RefreshCountDown()
	self:TimerStop(self._countDownKey)
	self:TimerStart(self._countDownKey, 1, false, -1)
end

function UISubMonthCard:SetPara()
	self._sid = self:GetWndArg("sid")
end

function UISubMonthCard:SetTop()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end

	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then
		return
	end

	local data = activityCfg.config


	if not string.isempty(data.descIcon) then
		self:SetWndEasyImage(self.mTextImg,data.descIcon,function() CS.ShowObject(self.mTextImg,true)  end,true)
	end

	local poTextSTb = string.split(data.popText, "|")
	self.popTb = {}
	for _, v in ipairs(poTextSTb) do
		local sTb = string.split(v, "=")
		table.insert(self.popTb, {
			type = tonumber(sTb[1]),
			str = sTb[2]
		})
	end

	self.getText = string.split(data.getText, "|")

	self.progressText  = string.split(data.progressText , "|")

	local showHelp = data.helpTips == 1
	CS.ShowObject(self.mHelpBtn, showHelp)
	if showHelp then
		local title = gModelActivity:GetLngNameByActivitySid(self._sid)
		local content = data.helpTipsContent
		self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(data.helpTipsPosition))
		self:SetWndClick(self.mHelpBtn, function() self:OnClickHelp(title, content) end, LSoundConst.CLICK_ERROR_COMMON)
	end


	self:SetWndText(self.mIntro, data.bannerTips)


	local cellIconList = string.split(data.cellIcon, ';')
	self._cellIconData = {}
	local curCellData
	local cellKey
	for k, v in ipairs(cellIconList) do
		curCellData                 = string.split(v, '=')
		cellKey                     = tonumber(curCellData[1])
		self._cellIconData[cellKey] = {
			title = curCellData[2],
			icon = curCellData[3],
		}
	end


	self._conditionTips = {}
	local conditionTips = data.conditionTips
	if not string.isempty(conditionTips) then
		local conditionTipsList = string.split(conditionTips, '|')
		local tipsList = {}
		for k, v in ipairs(conditionTipsList) do
			local tipsData = string.split(v, "=")
			local index = tonumber(tipsData[1])
			local condition = tonumber(tipsData[2])
			tipsList[index] = condition == 0
		end
		self._conditionTips = tipsList
	end

	self._jumpBtnList = {}
	local jumpBtn = data.jumpBtn
	if not string.isempty(jumpBtn) then
		local jumpBtnList = string.split(jumpBtn, '|')
		local resultList = {}
		for k, v in ipairs(jumpBtnList) do
			local tipsData = string.split(v, "=")
			local index = tonumber(tipsData[1])
			local condition = tonumber(tipsData[2])
			resultList[index] = condition == 0
		end
		self._jumpBtnList = resultList
	end

	-- self._progressTextList= {}
	-- local progressText = data.progressText
	-- if not string.isempty(progressText) then
	-- 	local progressTextList = string.split(progressText, '|')
	-- 	local resultList = {}
	-- 	for k,v in ipairs(progressTextList) do
	-- 		local tipsData = string.split(v, "=")
	-- 		local index = tonumber(tipsData[1])
	-- 		local strId = tonumber(tipsData[2])
	-- 		resultList[index] = strId
	-- 	end
	-- 	self._progressTextList = resultList
	-- end
end

function UISubMonthCard:InitData()
	local str = ccClientText(16103)
	local vipStr = ccClientText(16104)
	self._resConfig =
	{
		[1] =
		{
			index = 1,
			introPath = "monthlycard_txt_7",
			--cardPath = "monthlycard_icon_2",
			charIntro = str,
			numIconPath = "monthlycard_txt_1"
		},
		[2] =
		{
			index = 2,
			introPath = "monthlycard_txt_8",
			--cardPath = "monthlycard_icon_1",
			vipText = vipStr,
			charIntro = str,
			numIconPath = "monthlycard_txt_2"
		},

	}

	self._uiItemDatas = {}
	self._countDownKey = "_countDownKey"
end

function UISubMonthCard:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end

	local page = pb.pages[1]
	self._pageId = page.pageId

	local structPage = StructActivityPage:New()
	structPage:CreateByPb(page)
	self:RefreshUI(structPage)
end

function UISubMonthCard:RefreshForeign()
	if self._isVie then
		self:SetAnchorPos(self.mTextImg,Vector2.New(415,-258))
	end
end

function UISubMonthCard:RefreshCountDown()
	if not self._uiItemDatas then
		return
	end
	local now = GetTimestamp()
	local date = LUtil.OSDate("*t", now)
	local dayEnd = LUtil.OSTime({ year = date.year, month = date.month, day = date.day + 1, hour = 0, min = 0, sec = 3 })
	local timeDif = os.difftime(dayEnd, now)
	local timeStr = LUtil.FormatTimespanNumber(timeDif)


	for k, v in pairs(self._uiItemDatas) do
		local state = v.itemdata.state
		local charIntro = self:FindWndTrans(v.item, "getText")
		if state == 2 then
			local str = ccClientText(16109)

			str = string.replace(str, timeStr)
			self:SetWndText(charIntro, str)
		else
			self:SetWndText(charIntro, "")
		end
	end
end

function UISubMonthCard:OnTimer(key)
	if key == self._countDownKey then
		self:RefreshCountDown()
	end
end

function UISubMonthCard:RefreshContent()
	self:SetTop()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubMonthCard:OnClickHelp(title, content)
	GF.OpenWnd("UIBzTips", { title = title, text = content })
end

function UISubMonthCard:OnClickEntry(itemdata)
	local state = itemdata.state
	if state == 0 then
		if itemdata.jumpId and itemdata.jumpId > 0 then
			local isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.jumpId, true)
			if isOpen then
				gModelFunctionOpen:Jump(itemdata.jumpId)
			end
		else
			GF.ShowMessage(ccClientText(14303)) --"任务未完成，无法领取"
		end
	elseif state == 1 then
		local sid = self._sid
		local pageId = self._pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid, pageId, entryId)
	elseif state == 2 then
		GF.ShowMessage(ccClientText(12208))
	end
end

function UISubMonthCard:OnActivityResp(pb)
	local sid = pb.sid
	if sid ~= self.sid then
		return
	end


	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local moreInfo = activityData.moreInfo
	local data = JSON.decode(moreInfo)

	self._receiveData = data
	local list = self:GetUIScroll("itemList")
	local uiList = list:GetList()
	if not uiList then
		return
	end
	uiList:DrawAllItems()
end

function UISubMonthCard:RefreshUI(page)
	local pageId = page.pageId
	local pageCfg = gModelActivity:GetWebActivityPageData(self._sid, pageId)
	if not pageCfg then
		return
	end

	local dataList = {}
	for k, v in ipairs(pageCfg.entries) do
		local entryId = v.id
		local entryData = page:GetEntry(entryId)
		if entryData then
			local data     = {}
			data.entryId   = entryId
			data.state     = entryData.goalData.status --(0-不可领取, 1-可领取，2-已领取)
			data.schedule  = entryData.goalData.schedules[1].schedule
			data.goal      = entryData.goalData.schedules[1].goal
			data.jumpId    = v.jumpId
			data.jumpDesc  = v.jumpDesc
			local imgPaths = string.split(v.icon, '=')
			data.titlePath = self._cellIconData[entryId].title
			data.cardPath  = self._cellIconData[entryId].icon
			data.bgPath    = imgPaths[1]
			data.nameTitle = imgPaths[2]
			data.barPath   = imgPaths[3]
			data.item      = LxDataHelper.ParseItem_3(v.reward)
			data.condition = LxDataHelper.ParseNumber_Sign(v.condition, "=")
			table.insert(dataList, data)
		end
	end

	table.sort(dataList, function(a, b)
		return a.entryId < b.entryId
	end)
	self:InitItemList(dataList)
end

function UISubMonthCard:OnActivityReceiveGoalResp(pb)

end

------------------------------------------------------------------
return UISubMonthCard