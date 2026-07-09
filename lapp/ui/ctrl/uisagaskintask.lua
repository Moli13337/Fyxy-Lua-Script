---
--- Created by Administrator.
--- DateTime: 2026/6/1 16:55:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSkinTask:LWnd
local UISagaSkinTask = LxClass("UISagaSkinTask", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSkinTask:UISagaSkinTask()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSkinTask:OnWndClose()
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
	
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSkinTask:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSkinTask:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitMsg()
	self:InitEvent()
	self:InitData()
	self:InitText()
	self:RefreshUI()
end


function UISagaSkinTask:InitMsg()
	self:WndNetMsgRecv(LProtoIds.QuestListResp, function(...) self:OnQuestReceiveResp(...) end)
end

function UISagaSkinTask:InitData()
	local skinTaskType = self:GetWndArg("skinTaskType")
	self._skinTaskType = skinTaskType
	self._skinTaskList = {}
	self._uiListTbl = {}
	self._effectKeyList ={}
	self._passEEffectName = "fx_ui_zhanlinglingqu_chuxian"
end

function UISagaSkinTask:InitEvent()

	self:SetWndClick(self.mMaskBg,function()
		--if self._refID then
		--	if not self._jumpTAClient then
		--		gLGameThinkingData:OnTAClientEventReq(LGameThinkingData.CLIENT_TIP,"close",self._refID)
		--	end
		--end
		FireEvent(EventNames.REFRESH_SKIN_INFO)
		self:WndClose()
	end)
end

function UISagaSkinTask:InitText()
	self:SetWndText(self.mTittleText,ccClientText(47301))
	self:SetWndText(self.mCloseInfo,ccClientText(10103))
end

function UISagaSkinTask:OnQuestReceiveResp(...)
	self:RefreshUI()
end

function UISagaSkinTask:RefreshUI()
	self._canvasRect = LGameUI.GetUICanvasRoot()
	if self._taskList then
		self._taskList:RemoveAll()
	end
	self._delayUpdateScrollTimer = LxTimer.DelayFrameCall(function () self:RefreshSkinTaskList() end,1)
end

function UISagaSkinTask:RefreshSkinTaskList()
	if  self._skinTaskType ~= nil then
		self._skinTaskList = gModelSkinBook:GetSkinTaskLsitBySkinType(self._skinTaskType)
	end

	for k,v in ipairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}

	local UiSkinTaskList = self._UiSkinTaskList
	if not UiSkinTaskList then
		UiSkinTaskList = UIListWrap:New()
		UiSkinTaskList:Create(self, self.mUISuperList)
		UiSkinTaskList:SetFuncOnItemDraw(function(...)
			self:OnDrawSkinTaskItem(...)
		end)
		UiSkinTaskList:SetFuncOnItemReturn(function(...)
			self:OnSkinTaskItemReturn(...)
		end)

		UiSkinTaskList:EnableLoadAnimation(true, 0.03, 1, 2)
		UiSkinTaskList:SetLoadAnimationScale(nil, 0.03)
		self._UiSkinTaskList = UiSkinTaskList
	else
		UiSkinTaskList:EnableLoadAnimation(false)
	end
	UiSkinTaskList:RemoveAll()

	for k, v in ipairs(self._skinTaskList) do
		local refId = v:GetRefId()
		UiSkinTaskList:AddData(refId, v)
	end

	UiSkinTaskList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
end
function UISagaSkinTask:OnDrawSkinTaskItem(list, item, itemdata, itemPos)
	local bg = self:FindWndTrans(item, "bg")
	local Title = self:FindWndTrans(bg, "titleBg/title")
	local ItemList = self:FindWndTrans(bg, "itemList")
	local getBtn = self:FindWndTrans(bg, "GetBtn")
	local GetText = self:FindWndTrans(getBtn, "GetText")
	local FinishTip = self:FindWndTrans(bg, "FinishTip")
	local UnFinishTip = self:FindWndTrans(bg, "UnFinishTip")
	local instance = item:GetInstanceID()
	local refId = itemdata:GetRefId()
	local cfg = gModelQuest:GetTaskConfig(refId)
	local state = itemdata:GetState()
	local rewards = gModelQuest:GetRewardList(refId)
	if rewards then
		self:InitItemList(ItemList,rewards)
	end

	local isAllGet = false
	local isFnish = false

	if state == ModelQuest.TASK_UNFINISH then
		isFnish = false
	elseif state == ModelQuest.TASK_FINNISH then
		isFnish = true
		local key = "task"..tostring(refId)
		table.insert(self._effectKeyList,key)
		self:CreateWndEffect(getBtn,"fx_shouchong_anniu_zhong",key,100,nil,nil,nil,nil,nil,true)
	elseif state == ModelQuest.TASK_REWARDED then
		isAllGet = true
		isFnish = true
	end

	if cfg then
		local textId = cfg.description
		self:SetWndText(Title, ccLngText(textId))
		self:SetWndText(GetText, ccClientText(46913))
	end

	CS.ShowObject(getBtn,isFnish and  not isAllGet)
	CS.ShowObject(FinishTip,isAllGet)
	CS.ShowObject(UnFinishTip,not isFnish)

	self:SetWndClick(getBtn, function () self:OnClickSkinTask(itemdata, ItemList) end)

end

function UISagaSkinTask:OnSkinTaskItemReturn(list,item,itemdata,itemPos)
	if not itemdata then
		return
	end
	local refId = itemdata:GetRefId()
	local key = "task"..tostring(refId)
	self:DestroyWndEffectByKey(key)
end

function UISagaSkinTask:InitItemList(root,itemList)
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

function UISagaSkinTask:OnClickSkinTask(itemdata, ItemList)
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
		gModelQuest:OnQuestReceiveReq(refId)
	elseif state == ModelQuest.TASK_REWARDED then
		GF.ShowMessage(ccClientText(12211))
	end
end
------------------------------------------------------------------
return UISagaSkinTask