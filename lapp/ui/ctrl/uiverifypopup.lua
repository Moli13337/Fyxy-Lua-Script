---
--- Created by Administrator.
--- DateTime: 2024/11/18 19:56:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIVerifyPopUp:LWnd
local UIVerifyPopUp = LxWndClass("UIVerifyPopUp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIVerifyPopUp:UIVerifyPopUp()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIVerifyPopUp:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIVerifyPopUp:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIVerifyPopUp:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isSEA = gLGameLanguage:IsSEALngRegion()

    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitData()
end

function UIVerifyPopUp:DrawRewardList(_, trans, data, pos)
    local Title = CS.FindTrans(trans, "Title")
    local ItemList = CS.FindTrans(trans, "ItemList")
    local Got = CS.FindTrans(trans, "Got")
    local BindBtn = CS.FindTrans(trans, "BindBtn")
    local BindBtnName = CS.FindTrans(BindBtn, "BindBtnName")
    local GetBtn = CS.FindTrans(trans, "GetBtn")
    local GetBtnName = CS.FindTrans(GetBtn, "GetBtnName")

    --文本
    self:SetWndText(Title, ccLngText(data.name))
    self:SetWndText(BindBtnName, ccClientText(15067))
    self:SetWndText(GetBtnName, ccClientText(15068))

    --构建itemlist
    local items = LxDataHelper.ParseItem(data.reward)

    if not self._iconBindList then
        self._iconBindList = {}
    end
    local InstanceID = ItemList:GetInstanceID()
    local uiIconEasyList = self._iconBindList[InstanceID]

    if not uiIconEasyList then
        uiIconEasyList = UIIconEasyList:New()
        uiIconEasyList:Create(self, ItemList)
        uiIconEasyList:SetShowNum(false)
        uiIconEasyList:SetShowExtraNum(true, "itemNum")

        self._iconBindList[InstanceID] = uiIconEasyList
    end
    uiIconEasyList:RefreshList(items)

    CS.ShowObject(Got, false)
    CS.ShowObject(BindBtn, false)
    CS.ShowObject(GetBtn, false)
    --获取绑定情况
    local isBind = gModelActivity:IsAccountBindTarget(self._BindStr[data.refId])
    local isGot = gModelPlayer:InAccoutBindingReward(data.refId)

    CS.ShowObject(Got, isGot)
    CS.ShowObject(BindBtn, not isBind)
    CS.ShowObject(GetBtn, isBind and (not isGot))

    self:SetWndClick(BindBtn, function()
        if not isBind then
            gLSdkImpl:CallMethod(LSdkMethod.OpenBind, self._BindStr[data.refId])
        end
    end)
    self:SetWndClick(GetBtn, function()
        if not isGot then
            gModelPlayer:OnAuthOnetimeStateReq(data.refId)
        end
    end)

end

--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------
function UIVerifyPopUp:RefreshBindRewardEnus()
    CS.ShowObject(self.mBind_Reward_Enus, true)

    --创建列表 --构建下数据先
    local type = { 2, 3, 4 }

    if CS.IsOSIos() then
        table.insert(type, 5)
    end

    local isUseConfigPackType, result = gLGameLanguage:CheckIsUseConfigControlBindAccount()
    if isUseConfigPackType then
        type = result
    end

    local data = {}

    for k, v in ipairs(type) do
        local cfg = gModelActivity:GetVerifyConfig(v)
        if cfg then
            table.insert(data, cfg)
        end
    end

    table.sort(data, function(a, b)
        return a.refId < b.refId
    end)

    if self.uiList then
        self.uiList:RefreshList(data)
        self.uiList:DrawAllItems()
    else
        self.uiList = self:GetUIScroll("uiList")
        self.uiList:Create(self.mBindRewardList, data, function(...)
            self:DrawRewardList(...)
        end, UIItemList.SUPER)
    end

    self.uiList:EnableScroll(false, false)
end

--region 初始化 --------------------------------------------------------------------------------
function UIVerifyPopUp:InitEvent()
    self:SetWndClick(self.mMask_Enus, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mClose_Enus, function()
        self:WndClose()
    end)
end

function UIVerifyPopUp:InitData()
    self._BindStr = {
        [2] = "bindEmail",
        [3] = "bindFacebook",
        [4] = "bindGoogle",
        [5] = "bindApple",
    }

    self:RefreshBindRewardEnus()
end

function UIVerifyPopUp:InitPara()

end

function UIVerifyPopUp:InitMsg()
    self:WndNetMsgRecv(LProtoIds.AuthOnetimeStateResp, function()
        self:RefreshBindRewardEnus()
    end)

    self:WndEventRecv(EventNames.SDK_ACCOUNTBIND_RESULT, function()
        self:RefreshBindRewardEnus()
    end)
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIVerifyPopUp