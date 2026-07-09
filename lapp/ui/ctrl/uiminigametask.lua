---
--- Created by Administrator.
--- DateTime: 2025/3/28 16:23:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMiniGameTask:LWnd
local UIMiniGameTask = LxWndClass("UIMiniGameTask", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMiniGameTask:UIMiniGameTask()
    self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMiniGameTask:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMiniGameTask:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMiniGameTask:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitStaticText()
end

--region 事件 --------------------------------------------------------------------------------
function UIMiniGameTask:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end)
end
function UIMiniGameTask:SetTaskDiv()
    self:SetTaskList(self._taskList)
end

function UIMiniGameTask:InitMsg()

end

function UIMiniGameTask:SetTaskList(taskList)
    local uiList = self._uiTaskList
    if not uiList then
        uiList = self:GetUIScroll("mTaskList")
        uiList:Create(self.mTaskExhibition, taskList, function(...)
            self:CreateListItem(...)
        end, UIItemList.SUPER)
    else
        if self._PVEListData then
            uiList:RefreshList(taskList)
        end
    end
    self._uiTaskList = uiList

    uiList:EnableScroll(false, #taskList > 3)
end

--endregion --------------------------------------------------------------------------------------

--region 数据 --------------------------------------------------------------------------------
function UIMiniGameTask:InitPara()
    self._taskList = self:GetWndArg("taskList")
    self:SetTaskDiv()
end

--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
function UIMiniGameTask:InitStaticText()
    self:SetWndText(self.mCloseTip, ccClientText(17003))
end

function UIMiniGameTask:CreateListItem(list, item, itemdata, itempos)
    local Icon = CS.FindTrans(item, "Icon")
    local TaskName = CS.FindTrans(item, "TaskName")
    local TaskDes = CS.FindTrans(item, "TaskDes")
    local Button = CS.FindTrans(item, "Button")
    local ButtonText = CS.FindTrans(Button, "UIText")
    local GotTag = CS.FindTrans(item, "GotTag")
    local taskData = gModelQuest:GetTaskDataByRefId(itemdata)
    local taskRef = gModelQuest:GetTaskConfig(itemdata)
    self:SetWndText(TaskName, ccLngText(taskRef.description))
    --self:SetWndText(TaskDes, ccLngText(taskRef.description))

    local itemDataList = LUtil.GetRefItemDataList(taskRef.reward)
    local itemReward = itemDataList[1]
    local InstanceID = Icon:GetInstanceID()
    local baseClass = self._uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._uiCommonList[InstanceID] = baseClass
        baseClass:Create(Icon)
        self:SetIconClickScale(Icon, true)
    end
    baseClass:SetCommonReward(itemReward.itype, itemReward.itemId, itemReward.itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    local state = taskData:GetState()

    CS.ShowObject(Button, false)
    CS.ShowObject(GotTag, false)
    if state == ModelQuest.TASK_UNFINISH then
        CS.ShowObject(Button, true)
        --[10152]	[前  往]
        --self:SetWndEasyImage(Button,"public_btn_1_2")

        self:SetWndText(ButtonText, ccClientText(10152))
    elseif state == ModelQuest.TASK_FINNISH then
        CS.ShowObject(Button, true)
        --按钮状态 [10151]	[領  取]


        self:SetBtnImageAndMat(Button, "public_btn_1_1", ButtonText)
        self:SetWndText(ButtonText, ccClientText(10151))
    elseif state == ModelQuest.TASK_REWARDED then
        CS.ShowObject(GotTag, true)
    elseif state == ModelQuest.TASK_LOCK then

    end

    self:SetWndClick(Button, function()
        gModelQuest:OnClickTaskBtn(taskData, self:GetWndName())
    end)

end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMiniGameTask