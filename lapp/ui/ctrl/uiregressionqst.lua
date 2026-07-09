---
--- Created by Administrator.
--- DateTime: 2024/8/8 11:48:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRegressionQst:LWnd
local UIRegressionQst = LxWndClass("UIRegressionQst", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRegressionQst:UIRegressionQst()
	self._uiListTbl = {}
	self._typeBtnList = {}
	self._effectKeyList= {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRegressionQst:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRegressionQst:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRegressionQst:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:OnAddClick()
	local typeList = self:InitData()
	self:InitTypeList(typeList)
	self:OnUpdateList()
end

function UIRegressionQst:InitTypeList(typeList)

	local uiTypeList = self:FindUIScroll("uiTypeList")
	if not uiTypeList then
		uiTypeList = self:GetUIScroll("uiTypeList")
		uiTypeList:Create(self.mTypeList,typeList,function (...) self:SetTypeItem(...) end)
	else
		uiTypeList:DrawAllItems()
	end
end

function UIRegressionQst:OnClickTask(itemdata, bgItemList)
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
function UIRegressionQst:GetTransScreenPos(targetTrans)
	local canvasRect = self._canvasRect
	return YXUIPointUtil.GetScreenPoint(canvasRect,targetTrans)
end


function UIRegressionQst:OnClickType(refId,index,item)
	if self._curType == refId then
		return
	end
	local BtnTab1 = self:FindWndTrans(self.selTypeItem,"BtnTab1")
	self:SetWndTabStatus(BtnTab1,LWnd.StateOff)
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
	self.selTypeItem = item
	self:SetWndTabStatus(BtnTab1,LWnd.StateOn)
	self._curType = refId

	if self.uiList then
		 local uiList = self.uiList:GetList()
		 uiList:RemoveAll()
    end
	self._delayUpdateScrollTimer=LxTimer.DelayFrameCall(function () self:OnUpdateList() end,1)

	-- self:OnUpdateList()
end

function UIRegressionQst:InitData()
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
	self.tabName = {
		[gModelQuest.QUEST_TYPE_91] = ccClientText(45120),
		[gModelQuest.QUEST_TYPE_93] = ccClientText(45121)
	}
	local regressionTask =  gModelRegression:GetRegressionQuestRef()
	local typeDataList = {}
	for key, _ in pairs(regressionTask) do
		table.insert(typeDataList,tonumber(key))
	end
	table.sort(typeDataList,function(a, b) return a<b end)
	self._curType = self:GetWndArg("taskType")
	if not self._curType then self._curType = typeDataList[1] end
	return typeDataList
end
function UIRegressionQst:SetTaskItem(list,item,itemdata,itemPos)
	local bg = self:FindWndTrans(item,"bg")
	local bgTitle = self:FindWndTrans(bg,"GameObject/title")
	local bgSlider = self:FindWndTrans(bg,"Slider")
	local bgProgress = self:FindWndTrans(bg,"progress")
	local bgItemList = self:FindWndTrans(bg,"itemList")
	local bgButton = self:FindWndTrans(bg,"button")
	local buttonText = self:FindWndTrans(bgButton,"text")
	local AllGet = self:FindWndTrans(bg,"AllGet")
	local bgUnlockTip = self:FindWndTrans(bg,"unlockTip")

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
	-- local color = Color.New(1,1,1,1)
	-- if isLock then
	-- 	color = Color.New(0.5,0.5,0.5,0.5)
	-- end
	-- self:SetWndImageColor(bg,color)


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

function UIRegressionQst:OnAddClick()
	self:SetWndText(self.mLblBiaoti,ccClientText(45103))
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:WndEventRecv(EventNames.ON_QUEST_CHANGE,function ()
		self:OnUpdateList()
	end)

end
function UIRegressionQst:ShowPassEEffect(itemTrans)
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

function UIRegressionQst:InitItemList(root,itemList)
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
function UIRegressionQst:OnUpdateList()
	for k,v in ipairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}
	local regressionTask =  gModelQuest:GetTaskList(self._curType)
	if self.uiList then
		self.uiList:RefreshList(regressionTask)
	else
		self.uiList = self:CreateUIScrollImpl(nil,self.mTaskContent,regressionTask,function(...) self:SetTaskItem(...) end,UIItemList.WRAP)
	end
end

function UIRegressionQst:SetTypeItem(list, item,itemdata,index)
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
	local bg = self:FindWndTrans(item,"bg")

	local refId = itemdata
	local typeCfg = GameTable.MissionClassifyRef[refId]
	local name = self.tabName[refId]
	self:SetWndTabText(BtnTab1,name, nil, -30)
	self:SetWndClick(bg,function () self:OnClickType(refId,index,item) end)
	local state = refId == self._curType and LWnd.StateOn or LWnd.StateOff
	if refId == self._curType then self.selTypeItem = item end
	self:SetWndTabStatus(BtnTab1,state)

	self._typeBtnList[index] = item
end
------------------------------------------------------------------
return UIRegressionQst