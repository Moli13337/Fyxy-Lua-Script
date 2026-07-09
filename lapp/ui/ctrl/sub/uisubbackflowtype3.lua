---
--- Created by BY.
--- DateTime: 2023/10/12 16:09:33
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubBackflowType3:LChildWnd
local UISubBackflowType3 = LxWndClass("UISubBackflowType3", LChildWnd)

local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubBackflowType3:UISubBackflowType3()
	self._boxItemList = {}
	self._timeKey = "_timeKey_3"
	self._delayUpdateScrollTimer = "_delayUpdateScrollTimer"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBackflowType3:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBackflowType3:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBackflowType3:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubBackflowType3:InitEvent()
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBtnJump, function(...) self:OnClickJump() end)
end

function UISubBackflowType3:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local activeNumText = self:FindWndTrans(root,"TitleBg1/ActiveNumText")
	local activeNameText = self:FindWndTrans(root,"TitleBg1/ActiveNameText")
	local title2Text = self:FindWndTrans(root,"Title2Text")
	local planText = self:FindWndTrans(root,"PlanText")
	local barTr = self:FindWndTrans(root,"Bar_1_1")
	local bar = self:FindWndSlider(barTr)
	local barText = self:FindWndTrans(barTr,"BarText")
	local awardRoot = self:FindWndTrans(root,"AwardRoot")
	local btnGet = self:FindWndTrans(root,"BtnMar/BtnGet")
	local btnGoTo = self:FindWndTrans(root,"BtnMar/BtnGoTo")
	local status_On = self:FindWndTrans(root,"BtnMar/Status_On")

	local InstanceID = item:GetInstanceID()
	local refId = itemdata:GetRefId()
	local state =itemdata:GetState()
	local schedule = tonumber(itemdata:GetSchedule())
	local goal = tonumber(itemdata:GetGoal())
	local _taskItemShow = self._taskItemShow
	local _taskItemShowNum = 0

	local ref = gModelQuest:GetTaskConfig(refId)
	local tabStr = ref.resetType == 1 and ccClientText(23511) or ccClientText(23512)
	local rewards = LxDataHelper.ParseItem(ref.reward)
	local extraReward = LxDataHelper.ParseItem(ref.extraReward)
	if extraReward then
		for i, v in ipairs(extraReward) do
			_taskItemShowNum = _taskItemShowNum + v.itemNum
		end
	end
	self:SetWndText(activeNumText,_taskItemShowNum)
	self:SetWndText(activeNameText,ccClientText(23504))
	self:SetWndText(planText,ccClientText(23516))
	self:SetWndText(title2Text,string.replace(tabStr,ccLngText(ref.description)))
	self:SetWndText(barText,string.replace(ccClientText(23513),schedule,goal))
	self:SetWndButtonText(btnGet,ccClientText(23501))
	self:SetWndButtonText(btnGoTo,ccClientText(23503))
	bar.maxValue = goal
	bar.value = schedule
	local _rewardAddition = gModelBackflow:GetRewardAddition()
	for i, v in ipairs(rewards) do
		local itemNum = math.floor(v.itemNum * _rewardAddition)
        v.itemNum = itemNum
	end
	self:InitItemList(InstanceID,awardRoot,rewards)
	CS.ShowObject(btnGoTo,state == 0)
	CS.ShowObject(btnGet,state == 1)
	CS.ShowObject(status_On,state == 2)
	self:SetWndClick(btnGet,function ()
		self:OnClickTask(itemdata._refId)
	end)
	self:SetWndClick(btnGoTo,function ()
		self:OnClickTask(itemdata._refId)
	end)

	self:InitTextLineWithLanguage(planText,-30)
end
------------------------------------------------time--------------------------------------------------------------------
function UISubBackflowType3:OnTimer(key)
	if(self._timeKey == key)then
		self:SetTime()
	elseif(key == self._delayUpdateScrollTimer)then
		self:ScrollBoxCenter()
	end
end

function UISubBackflowType3:BoxListItem(item, itemdata, itempos)
	local btn = self:FindWndTrans(item,"Btn")
	local btnEff = self:FindWndTrans(item,"BtnEff")
	local bg = self:FindWndTrans(item,"Bg")
	local bgTimes = self:FindWndTrans(bg,"Num")

	local refId = itemdata:GetRefId()
	local state =itemdata:GetState()
	local goal = tostring(itemdata:GetGoal())
	self._boxItemList[refId]= item
	self:SetWndText(bgTimes,goal)
	local btnStr = self._boxImgs[state]
	self:SetWndEasyImage(btn,btnStr)
	CS.ShowObject(btnEff,state == 1)
	if state == 1 then
		local key = "box"..tostring(refId)
		self:CreateWndEffect(btnEff,"fx_richangbaoxiang",key,100)
	end
	self:SetWndClick(btn,function ()
		self:OnClickBox(refId)
	end)
end
function UISubBackflowType3:OnClickTask(refId)
	local netData = gModelQuest:GetTaskDataByRefId(refId)
	if not netData then
		return
	end
	local state = netData:GetState()
	if state ==0 then
		local cfg = gModelQuest:GetTaskConfig(refId)
		local originId = cfg.originId
		if originId > 0 then
			gModelQuest:TaskGoto(refId,self:GetParentWndName())
		else
			GF.ShowMessage(ccClientText(12210))
		end
	elseif state== 1 then
		gModelQuest:OnQuestReceiveReq(refId)
	elseif state == 2 then
		GF.ShowMessage(ccClientText(12211))
	end
end

function UISubBackflowType3:InitBoxList()
	local boxList = gModelQuest:GetTaskList(ModelBackflow.TASK_TYPE_93)
	local list = {}
	for i, v in ipairs(boxList) do
		local bool = gModelBackflow:RegressionActiveTaskRefByQuest(v._refId)
		if bool then
			table.insert(list,v)
		end
	end

	local giftNum = #list
	local last = boxList[giftNum]
	if last then
		local schedule = tonumber(last:GetSchedule())
		local goal = tonumber(last:GetGoal())
		--self.mActiveBar.maxValue = goal
		--self.mActiveBar.value = schedule
		--local str = string.format("%s/%s",schedule,goal)
		self:SetWndText(self.mActiveNumText,schedule)
		self:SetWndText(self.mActiveNameText,ccClientText(23504))
	end


	local maxSchedule = 0
	local dataList = {}
	for k,v in ipairs(list) do
		local schedule = v:GetSchedule()
		maxSchedule = math.max(maxSchedule,schedule)
		local goal = v:GetGoal()
		table.insert(dataList,goal)
	end

	local percent = LUtil.GetCurPercent(dataList,maxSchedule)
	--progress = Mathf.Clamp(progress,0,1)
	LxUiHelper.SetProgress(self.mActiveBar,percent)

	local scrollContent  = self.mBoxList:Find("content")
	local itemTemp = self.mBoxList:Find("ItemTemplate")
	local itemRoot = scrollContent:Find("ItemRoot")
	CS.ShowObject(itemTemp.gameObject,false)
	if not self._boxItemList then
		self._boxItemList ={}
	end

	local boxItemNum = #self._boxItemList
	if giftNum > boxItemNum then
		for i=boxItemNum + 1,giftNum do
			if not self._boxItemList[i] then
				local itemNew = LxResUtil.NewObject(itemTemp.gameObject)
				table.insert(self._boxItemList,itemNew.transform)
				itemNew.transform:SetParent(itemRoot.transform, false)
				itemNew.name =string.format("item{%d}",i)
				CS.ShowObject(itemNew, true)
			end
		end
	else
		for i=giftNum + 1,boxItemNum do
			local itemNew = self._boxItemList[i]
			if itemNew then
				CS.ShowObject(itemNew, false)
			end
		end
	end

	local jumpIndex = nil
	for i=1,giftNum do
		local giftData = list[i]
		local status =giftData:GetState()
		local canGet = status == 1

		if canGet then
			jumpIndex = i - 1
		end

		self:BoxListItem(self._boxItemList[i],giftData)
	end

	if not jumpIndex then
		jumpIndex = giftNum
	end
	self._jumpBoxIndex = jumpIndex
	self._allBoxNum = giftNum

	self:TimerStop(self._delayUpdateScrollTimer)
	self:TimerStart(self._delayUpdateScrollTimer, 0.3, false, 1)

	CS.ShowObject(self.mBoxList, true)
end
function UISubBackflowType3:OnClickJump()
	local shopJumpId = gModelBackflow:RegressionConfigRefByKey("shopJumpId")
	gModelFunctionOpen:Jump(shopJumpId)
end

function UISubBackflowType3:ScrollBoxCenter()
	local index = self._jumpBoxIndex
	if not index then return end
	local total		= self._allBoxNum
	if not total then return end

	local viewLength = self.mBoxList:GetComponent(typeOfRectTransform).rect.width
	local scrollContent  = self.mBoxList:Find("content")
	local contentLength = scrollContent:GetComponent(typeOfRectTransform).rect.width
	if contentLength<viewLength then
		return
	end
	local factor = ((index/total)*contentLength -viewLength/2)/(contentLength-viewLength)

	factor = math.range(factor, 0, 1)
	local scrollRect = self.mBoxList:GetComponent(typeOfScrollRect)
	if scrollRect then
		scrollRect.normalizedPosition = Vector2(factor,0)
	end
end

function UISubBackflowType3:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = self._ref.helpId})
end

function UISubBackflowType3:InitItemList(InstanceID,awardRoot,itemList)
	local uiIconEasyList = self._uiCellSuper:GetItemCls(InstanceID)
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiCellSuper:SetItemCls(InstanceID, uiIconEasyList)
		uiIconEasyList:Create(self, awardRoot)
		--uiIconEasyList:SetIconParentPath("itemRoot")
	end
	uiIconEasyList:RefreshList(itemList)
end

function UISubBackflowType3:RefreshData()
	local taskList = gModelQuest:GetTaskListByTypeList({ModelBackflow.TASK_TYPE_91,ModelBackflow.TASK_TYPE_92})
	local list = {}
	for i, v in ipairs(taskList) do
		local bool = gModelBackflow:RegressionActiveTaskRefByQuest(v._refId)
		if bool then
			table.insert(list,v)
		end
	end

	local _cellSuper = self._uiCellSuper
	if _cellSuper then
		_cellSuper:RefreshList(list)
	else
		_cellSuper = self:GetUIScroll("mCellSuper3")
		_cellSuper:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_cellSuper:EnableScroll(true,false)
		self._uiCellSuper = _cellSuper
	end
	_cellSuper:DrawAllItems()
	self:InitBoxList()
end

function UISubBackflowType3:InitData()
	local taskBox = gModelBackflow:RegressionConfigRefByKey("taskBox")
	local taskBoxArr = string.split(taskBox,"=")
	local boxImgs = {}
	boxImgs[0] = taskBoxArr[1]
	boxImgs[1] = taskBoxArr[2]
	boxImgs[2] = taskBoxArr[3]
	self._boxImgs = boxImgs
end
function UISubBackflowType3:InitMessage()
	self:WndNetMsgRecv(LProtoIds.QuestListResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.QuestReceiveResp,function (...)
		self:RefreshData()
	end)
end
function UISubBackflowType3:OnClickBox(refId)
	local netData = gModelQuest:GetTaskDataByRefId(refId)
	if not netData then
		return
	end
	local state = netData:GetState()
	if state == 1 then
		gModelQuest:OnQuestReceiveReq(refId)
		return
	end
	local rewardList = gModelQuest:GetRewardList(refId)
	if rewardList then
		local item = self._boxItemList[refId]
		local root = self:FindWndTrans(item,"Btn")
        local _rewardAddition = gModelBackflow:GetRewardAddition()
        for i, v in ipairs(rewardList) do
            v.itemNum = math.floor(v.itemNum * _rewardAddition)
        end
		GF.OpenWnd("UIringBoxDetail",{root,rewardList})
	end
end
function UISubBackflowType3:SetTime()--设置时间
	local time = gModelBackflow:GetResidueTime()
	if(time <= 0)then
		self:TimerStop(self._timeKey)
		CS.ShowObject(self.mTimeText,false)
		return
	end
	local timeStr = LUtil.FormatTimespanCn(time)
	self:SetWndText(self.mTimeText,string.replace(ccClientText(23500),timeStr))
end
function UISubBackflowType3:InitCommand()
	self:SetWndButtonText(self.mBtnJump,ccClientText(23509),nil,nil,-30)
	local refId = self:GetWndArg("refId")
	local ref = gModelBackflow:RegressionBackflowRefByRefId(refId)
	self._ref = ref

	CS.ShowObject(self.mBtnHelp,ref.helpId > 0)
	local showIcon,showIconPos,showTitle,showTitlePos = ref.showIcon,ref.showIconPos,ref.showTitle,ref.showTitlePos
	if LxUiHelper.IsImgPathValid(showIcon) then
		CS.ShowObject(self.mIconImg,true)
		self:SetWndEasyImage(self.mIconImg,showIcon,nil,true)
		local showIconPosArr = string.split(showIconPos,"|")
		self.mIconImg.anchoredPosition = Vector2(tonumber(showIconPosArr[1]),tonumber(showIconPosArr[2]))
	end
	if LxUiHelper.IsImgPathValid(showTitle) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,showTitle,nil,true)
		local showTitlePosArr = string.split(showTitlePos,"|")
		self.mTextImg.anchoredPosition = Vector2(tonumber(showTitlePosArr[1]),tonumber(showTitlePosArr[2]))
	end

	local time = gModelBackflow:GetResidueTime()
	CS.ShowObject(self.mTimeText,time > 0)
	if(time > 0)then
		self:SetTime()
		self:TimerStop(self._timeKey)
		self:TimerStart(self._timeKey,1,false,-1)
	end

	local taskShowBg = gModelBackflow:RegressionConfigRefByKey("taskShowBg")
	if LxUiHelper.IsImgPathValid(taskShowBg) then
		self:SetWndEasyImage(self.mBgImg,taskShowBg,nil,true)
	end
	self._taskItemShow = gModelBackflow:RegressionConfigRefByKey("taskItemShow")
	self:RefreshData()
end
------------------------------------------------------------------
return UISubBackflowType3


