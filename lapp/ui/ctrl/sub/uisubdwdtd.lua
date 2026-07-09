---
--- Created by Administrator.
--- DateTime: 2023/10/21 18:19:35
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDWDTD:LChildWnd
local UISubDWDTD = LxWndClass("UISubDWDTD", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDWDTD:UISubDWDTD()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDWDTD:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDWDTD:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDWDTD:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:ShowTaskList()
	self:InitEvent()
end

function UISubDWDTD:InitData()
	self._stateImg =
	{
		[0] = "public_btn_2_1",
		[1] = "public_btn_2_2",
		[2] = "public_btn_ash_2",
	}

	self._stateStr =
	{
		[0] =ccClientText(12206),
		[1] =ccClientText(12207),
		[2] =ccClientText(12214),
	}
end

function UISubDWDTD:InitEvent()
	self:WndEventRecv(EventNames.ON_QUEST_CHANGE,function ()
		self:ShowTaskList()
	end)
end

function UISubDWDTD:SetStaticContent()
	local str = ccClientText(30675)--"任务每天0点重置,请及时完成和领取奖励")
	self:SetWndText(self.mDesc,str)
	self:InitTextLineWithLanguage(self.mDesc, -30)
	self:InitTextSizeWithLanguage(self.mDesc, -2)
end

function UISubDWDTD:OnDrawItem(list,item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemRootIcon = self:FindWndTrans(itemRoot,"Icon")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local Eff = self:FindWndTrans(item,"Eff")

	self:SetWndText(itemNum,itemdata.itemNum)
	self:CreateCommonIconImpl(itemRootIcon,itemdata,{showNum = false})
end

function UISubDWDTD:ShowTaskList()
	local dataList = gModelQuest:GetTaskList(ModelQuest.TYPE_141)
	self:CreateUIScrollImpl("taskList",self.mTaskList,dataList,function (...) self:OnDrawTask(...) end,UIItemList.SUPER)
end


function UISubDWDTD:OnDrawTask(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	--local AniRootBgImage = self:FindWndTrans(AniRoot,"BgImage")
	local AniRootRewardList = self:FindWndTrans(AniRoot,"rewardList")
	local AniRootBtn = self:FindWndTrans(AniRoot,"btn")
	local btnText = self:FindWndTrans(AniRootBtn,"text")
	local AniRootTitle = self:FindWndTrans(AniRoot,"title")
	local AniRootDescTxt = self:FindWndTrans(AniRoot,"DescTxt")
	local AniRootMask = self:FindWndTrans(AniRoot,"mask")
	--local maskShow = self:FindWndTrans(AniRootMask,"Show")



	local refId = itemdata:GetRefId()
	local ref = gModelQuest:GetTaskConfig(refId)

	self:SetWndText(AniRootTitle,ccLngText(ref.description))
	local goal = itemdata:GetGoal()
	local schedule = itemdata:GetSchedule()
	local color = "red"
	if tonumber(schedule) >= tonumber(goal) then
		color = "green"
	end
	local str = string.format("(%s/%s)",LUtil.FormatColorStr(schedule,color),goal)
	self:SetWndText(AniRootDescTxt,str)

	local state = itemdata:GetState()
	local btnState = 0
	local stateStr = self._stateStr[state]
	if state == ModelQuest.TASK_UNFINISH then
		local originId = ref.originId
		if originId ~= 0 then
			stateStr = ccClientText(12209)
			btnState = 0
		else
			btnState = 2
		end
	elseif state == ModelQuest.TASK_FINNISH then
		btnState = 1
	elseif state == ModelQuest.TASK_REWARDED then
		btnState = 2
	end

	local imgPath = self._stateImg[btnState]
	self:SetBtnImageAndMat(AniRootBtn,imgPath,btnText)
	self:SetWndText(btnText, stateStr)
	self:InitTextSizeWithLanguage(btnText,-2)

	CS.ShowObject(AniRootBtn,state ~= ModelQuest.TASK_REWARDED)
	self:SetWndClick(AniRootBtn,function ()
		self:OnClickTask(itemdata)
	end)

	local rewards = gModelQuest:GetRewardList(refId)
	self:CreateUIScrollImpl(nil,AniRootRewardList,rewards,function (...)
		self:OnDrawItem(...)
	end)

	CS.ShowObject(AniRootMask,state == ModelQuest.TASK_REWARDED)
end

function UISubDWDTD:OnClickTask(itemdata)
	local wndName = self:GetParentWndName()
	gModelQuest:OnClickTaskBtn(itemdata,wndName)

	--GF.CloseWndByName(wndName)
end


------------------------------------------------------------------
return UISubDWDTD


