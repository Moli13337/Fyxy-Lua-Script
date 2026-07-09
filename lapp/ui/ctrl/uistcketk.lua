---
--- Created by Administrator.
--- DateTime: 2024/9/11 20:21:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIStCkeTk:LWnd
local UIStCkeTk = LxWndClass("UIStCkeTk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIStCkeTk:UIStCkeTk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIStCkeTk:OnWndClose()
    self:ClearCommonIconList(self.rewardIconUIList)
    self:ClearCommonIconList(self.commonUIList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIStCkeTk:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIStCkeTk:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitCommon()

    gModelActivity:OnActivityPageReq(self.sid)
end

function UIStCkeTk:DrawRewardIcon(_, item, data)
    local root = self:FindWndTrans(item, "Root")
    local instanceId = root:GetInstanceID()
    if not self.commonUIList[instanceId] then
        self.commonUIList[instanceId] = CommonIcon:New()
        self.commonUIList[instanceId]:Create(root)
    end
    self.commonUIList[instanceId]:SetCommonReward(data.type, data.itemId, data.count)
    self.commonUIList[instanceId]:DoApply()

    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(data)
    end)
end

function UIStCkeTk:DrawTask(_, item, data)
    local title = CS.FindTrans(item, "Title")
    local proText = CS.FindTrans(item, "ProText")
    local proImg = CS.FindTrans(item, "ProBg/ProImg")
    local itemList = CS.FindTrans(item, "ItemList")
    local btn = CS.FindTrans(item, "Btn")
    local isGet = CS.FindTrans(item, "IsGet")
    local unFinish = CS.FindTrans(item, "UnFinish")

    --self:SetWndText(title, data.desc)
    local para = data.goalData.schedules[1]
    local id = data.sort
    local showData =self._entryPageData[id]
    local description = gModelActivity:GetLngNameById(showData.description)
    self:SetWndText(title, description)
    local str = "<color=#a1#>#a2#/#a3#</color>"
    local color = data.goalData.status == 0 and "#9f835c" or "#139057"
    self:SetWndText(proText, string.replace(str, color, para.schedule, para.goal))
    local len = 520 * para.schedule / para.goal
    proImg.sizeDelta = Vector2.New(len, 14)

    self:SetWndButtonText(btn, ccClientText(12207))
    local instanceID = item:GetInstanceID()
    if data.goalData.status == 1 then
        self:CreateWndEffect(btn, "fx_anniu_03", instanceID, 100)
    else
        self:DestroyWndEffectByKey(instanceID)
    end

    CS.ShowObject(unFinish, data.goalData.status == 0)
    CS.ShowObject(btn, data.goalData.status == 1)
    CS.ShowObject(isGet, data.goalData.status == 2)

    local InstanceID = item:GetInstanceID()
    local x = math.min(#data.items * 65 + (#data.items - 1) * 4, 272)
    itemList.sizeDelta = Vector2.New(x, 65)
    if self.rewardIconUIList[InstanceID] then
        self.rewardIconUIList[InstanceID]:RefreshList(data.items)
        self.rewardIconUIList[InstanceID]:DrawAllItems()
    else
        self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
        self.rewardIconUIList[InstanceID]:Create(itemList, data.items, function(...)
            self:DrawRewardIcon(...)
        end, UIItemList.SUPER_GRID)
    end

    self:SetWndClick(btn, function()
        if data.goalData.status == 1 then
            gModelActivity:OnActivityReceiveGoalReq(self.sid, self.pageId, data.entryId)
        end
    end)
end

function UIStCkeTk:OnActivityPageResp(pb)
    local activityData = gModelActivity:GetWebActivityDataById(self.sid)

    local pages = pb.pages
    local fList, mList, lList, list = {}, {}, {}, {}
    for _, v in ipairs(pages) do
        if v.data == "手动领取奖励" then
            list = v.entry
            self.pageId = v.pageId
            if activityData.chunk[self.pageId] then
                local entryPageData = activityData.chunk[self.pageId].entries
                if not self._entryPageData then
                    self._entryPageData = {}
                end
                for _, entryData in ipairs(entryPageData) do
                    self._entryPageData[entryData.sort] =entryData
                end
            end
        end
    end
    for _, v in ipairs(list) do
        if v.goalData.status == 1 then
            table.insert(fList, v)
        end
        if v.goalData.status == 0 then
            table.insert(mList, v)
        end
        if v.goalData.status == 2 then
            table.insert(lList, v)
        end
    end
    list = {}
    for _, v in ipairs(fList) do
        table.insert(list, v)
    end
    for _, v in ipairs(mList) do
        table.insert(list, v)
    end
    for _, v in ipairs(lList) do
        table.insert(list, v)
    end

    if self.taskList then
        self.taskList:RefreshList(list)
        self.taskList:DrawAllItems()
    else
        self.taskList = self:GetUIScroll("mTaskList")
        self.taskList:Create(self.mTaskList, list, function(...)
            self:DrawTask(...)
        end, UIItemList.SUPER)
    end
end

function UIStCkeTk:InitCommon()
    -----------------------------------------------
    ---Text
    self:SetWndText(self.mLblBiaoti, ccClientText(29713))
    self:SetWndText(self.mCloseTip, ccClientText(10103))

    -----------------------------------------------
    ---Click
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    -----------------------------------------------
    ---Recv
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        if pb.sid ~= self.sid then
            return
        end
        self:OnActivityPageResp(pb)
    end)

    -----------------------------------------------
    ---Member
    self.sid = self:GetWndArg("sid")
    self.rewardIconUIList = {}
    self.commonUIList = {}
end

------------------------------------------------------------------
return UIStCkeTk