---
--- Created by Administrator.
--- DateTime: 2023/10/7 16:15:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIQst:LWnd
local UIQst = LxWndClass("UIQst", LWnd)
--local typeofYXUIStateActor = typeof(CS.YXUIStateActor)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXUIPointUtil = CS.YXUIPointUtil
---@type LUIEffectObject
local LUIEffectObject = LxRequire("LApp.UI.Display.LUIEffectObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIQst:UIQst()
	---@type table<number,UIIconEasyList>
	self._uiListTbl = {}
	self._passEEffectName = "fx_ui_zhanlinglingqu_chuxian"
	self._passEEffect2Name = "fx_ui_zhanlinglingqu_hit"

	---@type table<number,LUIEffectObject>
	self._uiEffectObjList = {}
	self._flayEffIdx = 0

	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIQst:OnWndClose()
	--if self._uiTypeList then
	--	self._uiTypeList:Destroy()
	--	self._uiTypeList=nil
	--end
	if self._boxUIList then
		self._boxUIList:Destroy()
		self._boxUIList=nil
	end
	if self._delayUpdateScrollTimer then
		LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
		self._delayUpdateScrollTimer = nil
	end

	if self._uiListTbl then
		local uiListTbl = self._uiListTbl
		for k,v in pairs(uiListTbl) do
			v:Destroy()
			uiListTbl[k] = v
		end
		self._uiListTbl = nil
	end
	if self._taskList then
		self._taskList:OnWndClose()
	end

	if self._uiEffectObjList then
		local listObj = self._uiEffectObjList
		for k,v in pairs(listObj) do
			listObj[k] = nil
			v:Destroy()
		end
		self._uiEffectObjList = nil
	end

	if self._simplePool then
		self._simplePool:Destroy()
		self._simplePool = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIQst:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIQst:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitList()
	self:SetPara()
	self:InitTypeList()
	self:RefreshUI()
	self:SetWndText(self.mPassAText,ccClientText(12218))
	self:RefreshRed()
	self:RefreshPassE(true)
	self:InitTag()

	--关闭成就界面
	GF.CloseWndByName("UIFeat")

	self:RefreshBottomBtnShow()
end

function UIQst:OnClickPassE()
	if not self._passESid then return end

	gModelActivity:CommonActJump(self._passESid)
end

function UIQst:GetTransScreenPos(targetTrans)
	local canvasRect = self._canvasRect
	return YXUIPointUtil.GetScreenPoint(canvasRect,targetTrans)
end

function UIQst:RefreshPassEEffectItem()
	self._needPassEItemEffect = false
	local effectItem = self._effectItem
	if not effectItem then return end

	local icon = gModelItem:GetItemIconByRefId(effectItem)
	if not LxUiHelper.IsImgPathValid(icon) then
		return
	end

	for i = 1, 5 do
		local isShow = i <= self._effectItemNum
		local itemIcon = self:FindWndTrans(self.mFlyItemList, "ItemIcon"..i)
		CS.ShowObject(itemIcon, isShow)
		if isShow then
			self:SetWndEasyImage(itemIcon, icon)
		end
	end
	self._needPassEItemEffect = true
end

function UIQst:InitTypeList()
	local typeDataList =gModelQuest:GetTaskTypeList()

	local uiTypeList = self:FindUIScroll("uiTypeList")
	if not uiTypeList then
		uiTypeList = self:GetUIScroll("uiTypeList")
		uiTypeList:Create(self.mTypeList,typeDataList,function (...) self:SetTypeItem(...) end)
	else
		uiTypeList:RefreshList(typeDataList)
	end

	--self._uiTypeList =  UIItemList:New(self)
	--self._uiTypeList :Create(self.mTypeList,typeDataList,function (...) self:SetTypeItem(...) end)
end

function UIQst:RefreshContent()
	local selectType = self._curType
	local itemdataList = gModelQuest:GetTaskList(selectType)

	local taskList = self._taskList

	for k,v in ipairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}
	if not taskList then
		taskList = UIListWrap:New()


		taskList:Create(self,self.mTaskContent)
		taskList:SetFuncOnItemDraw(function(...)
			self:SetTaskItem(...)
		end)
		taskList:SetFuncOnItemReturn(function(...)
			self:OnTaskItemReturn(...)
		end)

		taskList:EnableLoadAnimation(true, 0.03, 1, 2)
		taskList:SetLoadAnimationScale(nil, 0.03)
		self._taskList = taskList
	else
		taskList:EnableLoadAnimation(false)
	end
	taskList:RemoveAll()

	for k,v in ipairs(itemdataList) do
        local refId = v:GetRefId()
		taskList:AddData(refId,v)
	end

	taskList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
end

function UIQst:RefreshRed()
	local list = gModelActivity:GetActivityDataByModelId(12)
	local activity = list[1]
	CS.ShowObject(self.mPassABtn,activity)
	if not activity then
		return
	end
	local sid = activity.sid
	local isRed = gModelRedPoint:CheckActivityShowRed(sid)
	CS.ShowObject(self.mRedPoint,isRed)
end

function UIQst:RefreshPassE()
	self._passESid = nil
	local list = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_PASSE)
	local startTime
	local activity
	for k,v in ipairs(list) do
		local curStartTime = v.startTime
		if not startTime or startTime < curStartTime then
			startTime = curStartTime
			activity = v
		end
	end

	local haveAct = activity ~= nil
	if not haveAct then
		CS.ShowObject(self.mPassEBtn,false)
		return
	end

	local sid		= activity.sid

	self._passESid 	= sid
	if not self._initActPassE then
		self._initActPassE = true
		self:InitPassEEffectPlayPool()
		gModelActivity:ReqActivityConfigData(sid)
		return
	end

	CS.ShowObject(self.mPassEBtn,true)
	local config = JSON.decode(activity.moreInfo)
	local mainEntryIcon = config.mainEntryIcon
	self._effectItem = config.effectItem
	self._effectItemNum = config.effectItemNum

	if LxUiHelper.IsImgPathValid(mainEntryIcon) then
		self:SetWndEasyImage(self.mPassEImage, mainEntryIcon)
	end
	local title = config.mainEntryName or gModelActivity:GetLngNameByActivitySid(sid)
	self:SetWndText(self.mPassEText, title)

	local showRed = gModelQuest:CheckShowPassERed(sid)
	CS.ShowObject(self.mPassERedPoint, showRed)

	self:RefreshPassEProgress()
	self:RefreshPassEEffectItem()
end

function UIQst:SetTypeItem(list, item,itemdata)
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
	local bg = self:FindWndTrans(item,"bg")

	local refId = itemdata
	local typeName = self._typeNameList[refId]
	self:SetWndTabText(BtnTab1,typeName, nil, -30)
	self:SetWndClick(bg,function () self:OnClickType(refId) end)
	local state = refId == self._curType and LWnd.StateOn or LWnd.StateOff

	self:SetWndTabStatus(BtnTab1,state)

	self._typeBtnList[refId] = item
	return item
end


function UIQst:OnClickType(refId)
	if self._curType == refId then
		return
	end

	local oldSelect = self._curType
	if oldSelect==-1 then
		for k,v in pairs(self._typeBtnList) do
			local BtnTab1 = self:FindWndTrans(v,"BtnTab1")
			self:SetWndTabStatus(BtnTab1,LWnd.StateOff)
		end
	else
		local oldSelectItem = self._typeBtnList[oldSelect]
		if oldSelectItem then
			local BtnTab1 = self:FindWndTrans(oldSelectItem,"BtnTab1")
			self:SetWndTabStatus(BtnTab1,LWnd.StateOff)
		end
	end
	self._curType = refId
	self:SaveWndArg()
	local newSelectItem = self._typeBtnList[refId]
	if newSelectItem then
		local BtnTab1 = self:FindWndTrans(newSelectItem,"BtnTab1")
		self:SetWndTabStatus(BtnTab1,LWnd.StateOn)
	end

	self:RefreshUI()
end

function UIQst:InitList()


	self._pageToType =
	{
		[3]= ModelQuest.MAIN,
		[1] = ModelQuest.DAILY,
		[2] = ModelQuest.WEEK,
	}

	self._typeNameList=
	{
		[1]= ccClientText(12203),
		[2]= ccClientText(12204),
		[3]= ccClientText(12205),

	}

	self._titleList=
	{
		[1]= ccClientText(12200),
		[2]= ccClientText(12201),
		[3]= ccClientText(12202),
	}

	self._stateStr =
	{
		[0] =ccClientText(12206),
		[1] =ccClientText(12207),
		[2] =ccClientText(12214),
	}

	self._stateImg =
	{
		[0] = "public_btn_1_1",
		[1] = "public_btn_1_2",
		[2] = "public_btn_ash_1",
	}

    --self._boxStateImg=
    --{
    --    [0] = "quest_icon_box_1",
    --    [1] = "quest_icon_box_3",
    --    [2] = "quest_icon_box_2",
    --}

    self._boxSliderKey = "_boxSliderKey"

	self._typeBtnList={}
    self._boxItemList={}

	self._effectKeyList ={}
	self._boxEffectKeyList ={}

	--获取UI节点屏幕坐标。
	self._canvasRect = LGameUI.GetUICanvasRoot()
	self._passEBtnScreenPos = self:GetTransScreenPos(self.mPassEBtn)
	self._passEBtnEffSize = 100
	self._passEBtnStartScale = Vector3.one * self._passEBtnEffSize
	self._passEBtnEndScale = Vector3.one * 35
end

function UIQst:InitItemList(root,itemList)
	local instanceId = root:GetInstanceID()
	local uiList = self._uiListTbl[instanceId]
	if not uiList then
		uiList = UIIconEasyList:New()
		self._uiListTbl[instanceId] = uiList
		uiList:Create(self, root)
		uiList:SetShowNum(false)
		uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
		uiList:SetShowExtraNum(true, "itemNum")
	end
	uiList:RefreshList(itemList)
end

function UIQst:SetTaskItem(list,item,itemdata,itemPos)
	local bg = self:FindWndTrans(item,"bg")
	local bgTitle = self:FindWndTrans(bg,"title")
	local bgSlider = self:FindWndTrans(bg,"Slider")
	--local SliderBackground = self:FindWndTrans(bgSlider,"Background")
	--local SliderFillArea = self:FindWndTrans(bgSlider,"FillArea")
	--local FillAreaFill = self:FindWndTrans(SliderFillArea,"Fill")
	--local FillImage = self:FindWndTrans(FillAreaFill,"Image")
	local bgProgress = self:FindWndTrans(bg,"progress")
	local bgItemList = self:FindWndTrans(bg,"itemList")
	local bgButton = self:FindWndTrans(bg,"button")
	local buttonText = self:FindWndTrans(bgButton,"text")
	local AllGet = self:FindWndTrans(bg,"AllGet")
	local bgUnlockTip = self:FindWndTrans(bg,"unlockTip")
	--local bgMask = self:FindWndTrans(bg,"mask")


	local refId = itemdata:GetRefId()
    local cfg = gModelQuest:GetTaskConfig(refId)

	local rewards = gModelQuest:GetRewardList(refId)
	if rewards then
		self:InitItemList(bgItemList,rewards)
	end

	local schedule =tonumber(itemdata:GetSchedule())
	local goal = tonumber(itemdata:GetGoal())


	local color = "black"
	if schedule>=goal then
		color = "green"
	end

	local scheduleStr = LUtil.NumberCoversion(schedule)
	local goalStr = LUtil.NumberCoversion(goal)

	local str = LUtil.FormatColorStr(string.format("%s/%s",scheduleStr,goalStr),color)
	self:SetWndText(bgProgress,str)


	local state= itemdata:GetState()
    local stateStr =self._stateStr[state]

	local isLock = false

	local isAllGet = false
	local btnState = 0
	if state == ModelQuest.TASK_UNFINISH then
		local originId = cfg.originId
		if originId ~= 0 then
			stateStr = ccClientText(12209)
			btnState = 0
		else
			btnState = 2
		end
	elseif state == ModelQuest.TASK_FINNISH then
		btnState = 1
		local key = "task"..tostring(refId)
		table.insert(self._effectKeyList,key)
		self:CreateWndEffect(bgButton,"fx_shouchong_anniu_zhong",key,100,nil,nil,nil,nil,nil,true)
	elseif state == ModelQuest.TASK_REWARDED then
		btnState = 2
		isAllGet = true
	elseif state == ModelQuest.TASK_LOCK then
		isLock = true
	end

	CS.ShowObject(bgButton,not isLock and not isAllGet)

	CS.ShowObject(AllGet,isAllGet)

	CS.ShowObject(bgProgress,not isLock)
	local color = Color.New(1,1,1,1)
	if isLock then
		color = Color.New(0.5,0.5,0.5,0.5)
	end
	self:SetWndImageColor(bg,color)


	self:SetWndText(bgUnlockTip,ccLngText(cfg.unlockTip))
	CS.ShowObject(bgUnlockTip,isLock)

	if not isAllGet then

		local imgPath = self._stateImg[btnState]
		self:SetBtnImageAndMat(bgButton,imgPath)
	end


	local c = btnState == 1 and "<#ffffff>" or "<#5c6d9a>"
	if stateStr then
		stateStr = c .. stateStr .. "</color>"
	end
	self:SetWndText(buttonText, stateStr)
	self:InitTextSizeWithLanguage(buttonText,-2)


	local value = 0
	if goal > 0 then
		value = schedule/goal
	end
	LxUiHelper.SetProgress(bgSlider,value)


	if cfg then
		local textId = cfg.description
		self:SetWndText(bgTitle, ccLngText(textId))
	end

	self:SetWndClick(bgButton, function () self:OnClickTask(itemdata, bgItemList) end)

	self:SetWndClick(bg,function () self:OnClickTask(itemdata, bgItemList) end)

	self:InitTextSizeWithLanguage(bgTitle,-4)
	self:InitTextLineWithLanguage(bgTitle,-35)

end

function UIQst:ShowPassEEffect(itemTrans)
	if not self._needPassEItemEffect then return end

	if self._curType == ModelQuest.MAIN then return end

	local effName = self._passEEffectName
	local startPos = self:GetTransScreenPos(itemTrans)

	local idx = self._flayEffIdx + 1
	self._flayEffIdx = idx
	local uiEffectObj = LUIEffectObject:New(self)
	self._uiEffectObjList[idx] = uiEffectObj

	local completeFunc = function ()
		self:PlayPassEEffect()
		local tmpObj = self._uiEffectObjList[idx]
		tmpObj:Destroy()
		self._uiEffectObjList[idx] = nil
	end

	uiEffectObj:EnablePool(self._simplePool)
	uiEffectObj:Create(self.mFlyItemRoot, effName, self._passEBtnEffSize, 0, 2, function (obj)
		local dpEff = obj:GetDisplayEffect()
		dpEff:SetVisible(true)
		dpEff:GetDisplayTrans().localPosition = startPos
		dpEff:GetDisplayTrans().localScale = self._passEBtnStartScale
		obj:InitTweenMove(self._passEBtnScreenPos, 1.2,completeFunc)
		obj:InitTweenScale(self._passEBtnEndScale, 1.2)
	end)
	uiEffectObj:StartLoad()
end

function UIQst:OnTryRefreshRedPoint(redPointType)
	if(redPointType == ModelRedPoint.ACTIVITY_ACTIVITY)then
		self:RefreshRed()
		self:RefreshPassE()
	end
end

function UIQst:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.QuestReceiveResp,function (...) self:RefreshTaskItem(...) end)
	self:WndEventRecv(EventNames.ON_QUEST_CHANGE,function (...) self:RefreshTaskItem(...) end)
	--self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)


	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function ()
		self:RefreshBottomBtnShow()
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid == self._passESid then
			gModelActivity:OnActivityPageReqEx(self._passESid, ModelActivity.PASS_E_ELITE)
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetActData(pb)
	end)
end

function UIQst:OnClickTask(itemdata, bgItemList)
   	local refId = itemdata:GetRefId()
    local state = itemdata:GetState()
	local cfg = gModelQuest:GetTaskConfig(refId)
    if state == ModelQuest.TASK_UNFINISH then
		local originId = cfg.originId
		if originId > 0 then
			gModelQuest:TaskGoto(refId,self:GetWndName())
		else
			GF.ShowMessage(ccClientText(12210))
		end
    elseif state== ModelQuest.TASK_FINNISH then
		self:ShowPassEEffect(bgItemList)
        gModelQuest:OnQuestReceiveReq(refId)
	elseif state == ModelQuest.TASK_REWARDED then
        GF.ShowMessage(ccClientText(12211))
	elseif state == ModelQuest.TASK_LOCK then
		local str = string.replace(ccClientText(12219),ccLngText(cfg.unlockTip))
		GF.ShowMessage(str)
    end

end

function UIQst:InitTag()
	self:SetWndTabText(self.mTaskBtn, ccClientText(19500))
	self:SetWndTabText(self.mAchievementBtn, ccClientText(19501))

	self:SetWndTabStatus(self.mTaskBtn,LWnd.StateOn)
	self:SetWndTabStatus(self.mAchievementBtn,LWnd.StateOff)
end

function UIQst:RefreshBoxSlider(type)

    local boxList = gModelQuest:GetTaskList(type)
    local cnt = #boxList
    local last = boxList[cnt]
	if not last then
		return
	end
    local schedule = tonumber(last:GetSchedule())
    local goal = tonumber(last:GetGoal())
    local progress =0
    if goal>0 then
        progress = schedule/goal
    end

    local slider =self:UIProgressFind(self.mSlider,self._boxSliderKey,progress)
    slider:SetUIProgress(progress)

    local str = string.format("%s/%s",schedule,goal)
    self:SetWndText(self.mTotalProgress,str)
end

function UIQst:OnDrawBox(list, item,itemdata)

    local btn = self:FindWndTrans(item,"btn")
    local bg = self:FindWndTrans(item,"bg")
    local bgTimes = self:FindWndTrans(bg,"times")

    local refId = itemdata:GetRefId()
    local state =itemdata:GetState()

	self:SetImageActorState(btn,state)
	--local color = "lightBlue"

	if state == 1 then
		--color = "white"
		local key = "box"..tostring(refId)
		table.insert(self._boxEffectKeyList,key)
		self:CreateWndEffect(btn,"fx_richangbaoxiang",key,100)
	end



    --self:SetWndEasyImage(btn,iconPath,function ()
	--	CS.ShowObject(btn,true)
	--end)
    self:SetWndClick(btn,function ()
        self:OnClickBtn(refId)
    end)

    local goal = tostring(itemdata:GetGoal()) --LUtil.FormatColorStr(itemdata:GetGoal(),color)
    self:SetWndText(bgTimes,goal)

    if not self._boxItemList then
        self._boxItemList ={}
    end
    self._boxItemList[refId]= item
end

function UIQst:InitEvent()
	self:SetWndClick(self.mReturnBtn,function () self:WndCloseAndBack() end)
	self:SetWndClick(self.mPassABtn,function () self:OnClickPassA() end)
	self:SetWndClick(self.mPassEBtn,function () self:OnClickPassE() end)
	self:SetWndClick(self.mAchievementBtn,function ()
		GF.OpenWndBottom("UIFeat")
	end)
end


function UIQst:RefreshTaskItem(pb)

	self:RefreshContent()

	self:RefreshBoxContent()
end

function UIQst:RefreshUI()
	local showBox = false
	if self._curType ==ModelQuest.DAILY or self._curType ==ModelQuest.WEEK then
		showBox = true
        self:RefreshBoxContent()
	end
	local size = Vector2.New(-46,-210)
	if showBox then
		size = Vector2.New(-46,-210)
	end

	CS.ShowObject(self.mPattern,showBox)

	self.mDi.sizeDelta = size

	CS.ShowObject(self.mEmpty,not showBox)
	CS.ShowObject(self.mBoxContent,showBox)

	local title = self._titleList[self._curType]
	self:SetWndText(self.mTitle,title)

    if self._taskList then
        self._taskList:RemoveAll()
    end
	self._delayUpdateScrollTimer=LxTimer.DelayFrameCall(function () self:RefreshContent() end,1)
end

function UIQst:SetPara()
	local page = self:GetWndArg("page")
	if page then
		self._curType =self._pageToType[page]
	end
	if not self._curType then
		self._curType=gModelQuest:GetShowType()
	end
end

function UIQst:RefreshPassEProgress()
	if not self._actPassEPage then
		return
	end

	local eliteList = self._actPassEPage.entry
	local data
	local nextData
	for i, v in ipairs(eliteList) do
		local goalData	  	= v.goalData
		if(goalData.status == 2)then
			data = v
		else
			nextData = v
			break
		end
	end

	if not data then
		data = eliteList[1]
	end

	if not nextData then
		nextData = eliteList[#eliteList]
	end

	local sid = self._passESid
	local cfg 		= gModelActivity:GetWebActivityEntryData(sid,data.pageId,data.entryId)
	local maxCfg 	= gModelActivity:GetWebActivityEntryData(sid,nextData.pageId,nextData.entryId)
	local curValue 	= tonumber(cfg.name)
	local maxValue 	= tonumber(maxCfg.name)
	local schedule = nextData.goalData.schedules[1].schedule
	local startValue = schedule - curValue
	local endValue = maxValue - curValue
	LxUiHelper.SetProgress(self.mPassBarE,startValue/endValue)
end

function UIQst:InitBoxList(type)
    local boxList = gModelQuest:GetTaskList(type)

	local boxUIList = self:FindUIScroll("boxList") --self._boxUIList
	if not boxUIList then
		boxUIList = self:GetUIScroll("boxList") -- UIItemList:New(self)
		boxUIList:Create(self.mBoxList,boxList,function (...) self:OnDrawBox(...) end)
	else
		boxUIList:RefreshList(boxList)
	end

	--boxUIList:Create(self.mBoxList,boxList,function (...) self:OnDrawBox(...) end)

end

function UIQst:SaveWndArg()
	local pageIdex = nil
	for idx,v in pairs(self._pageToType) do
		if v == self._curType then
			pageIdex = idx
			break
		end
	end

	if pageIdex then
		local argList = self:GetWndArgList() or {}
		argList["page"] = pageIdex
		self:SetWndArg(argList)
	end
end

function UIQst:PlayPassEEffect()
	CS.ShowObject(self.mPassEEff, false)
	self:CreateWndEffect(self.mPassEEff, self._passEEffect2Name, self._passEEffect2Name, 100, false, false)
	CS.ShowObject(self.mPassEEff, true)
end

function UIQst:OnTaskItemReturn(list,item,itemdata,itemPos)
	if not itemdata then
		return
	end
	local refId = itemdata:GetRefId()
	local key = "task"..tostring(refId)
	self:DestroyWndEffectByKey(key)
end

function UIQst:RefreshBoxContent()
    local type =nil
	if self._curType == ModelQuest.DAILY then
		type = ModelQuest.DAILY_BOX
		self:SetImageActorState(self.mIcon,0)
    elseif self._curType == ModelQuest.WEEK then
        type = ModelQuest.WEEK_BOX
		self:SetImageActorState(self.mIcon,1)
    else
        return
	end


	for k,v in ipairs(self._boxEffectKeyList) do
		self:DestroyWndEffectByKey(v)
	end

	self._boxEffectKeyList ={}
    self:InitBoxList(type)

    self:RefreshBoxSlider(type)

	local str= ccClientText(12212)
	if type == ModelQuest.WEEK_BOX then
		str=ccClientText(12213)
	end
	self:SetWndText(self.mIntro,str)

end

function UIQst:InitPassEEffectPlayPool()
	local simplePool = LSimplePool:New()
	self._simplePool = simplePool

	simplePool:InitPool(self.mEffectRoot, "PassEPlay")

	local effName = self._passEEffectName
	local assetPath = CS.ResPath(CS.RES_ANY_PREFAB, LxResPathUtil.GetEffectAssetPath(effName))
	local args = simplePool:MakeArgs(assetPath,effName,nil, nil)
	simplePool:InitPoolItem(args)
end

function UIQst:RefreshBottomBtnShow()
	local funcId = 11502001
	local isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
	local state = isOpen and LWnd.StateOff or LWnd.StateGray
	self:SetWndTabStatus(self.mAchievementBtn,state)
end

function UIQst:OnClickPassA()
	local jump = gModelQuest:GetQuestConfigRefByKey("uniqueJump")
	gModelFunctionOpen:Jump(jump,self:GetWndName())
end

function UIQst:OnClickBtn(refId)
    local netData = gModelQuest:GetTaskDataByRefId(refId)
	if not netData then
		return
	end
    local state = 0
    if netData then
        state = netData:GetState()
    end

    if state ==0 or state ==2  then
        --showdetail
        local rewardList = gModelQuest:GetRewardList(refId)
        if rewardList then
            local item = self._boxItemList[refId]
			local root = self:FindWndTrans(item,"btn")
            GF.OpenWnd("UIringBoxDetail",{root,rewardList})
        end
    elseif state == 1 then
        gModelQuest:OnQuestReceiveReq(refId)
    end
end

function UIQst:ResetActData(pb)
	local sid=pb.sid
	if(self._passESid==sid)then
		for i, v in ipairs(pb.pages) do
			local pageData = gModelActivity:GenerateActivePageDataFromPb(v)
			local pageId = pageData.pageId
			if pageId == ModelActivity.PASS_E_ELITE then
				self._actPassEPage = pageData
				self:RefreshPassE()
				break
			end
		end
	end
end

------------------------------------------------------------------
return UIQst


