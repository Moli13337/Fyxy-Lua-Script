---
--- Created by BY.
--- DateTime: 2023/10/7 11:16:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICareColleChapter:LWnd
local UICareColleChapter = LxWndClass("UICareColleChapter", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICareColleChapter:UICareColleChapter()
    self:SetHideHurdle()
    self._tabChapterList = {}
    self._uiItemScroll = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICareColleChapter:OnWndClose()
    if self._uiItemScroll then
        self._uiItemScroll:Destroy()
        self._uiItemScroll = nil
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICareColleChapter:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICareColleChapter:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isEnus then
        self.mItemScroll.localPosition = self.mItemScroll.localPosition + Vector3.New(70, 0, 0)
    end

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UICareColleChapter:InitMessage()
    self:WndNetMsgRecv(LProtoIds.CollegeInfoResp, function(...)
        self:InitTabList()
    end)
end
function UICareColleChapter:OnClickGet()
    local dolist = gModelCareSchool:GetLibraryDoList()
    local refIds = gModelCareSchool:GetReceiveRefIds()
    local refId = self._refId
    local ref = gModelCareSchool:GetCollegeLibraryRefByRefId(refId)
    local list = gModelCareSchool:GetCollegeLibraryCheckpointRefListByRefId(refId)
    local isYesGet = true
    for i, v in ipairs(list) do
        if not dolist[v.refId] then
            isYesGet = false
            break
        end
    end
    if refIds[refId] then
        GF.ShowMessage(ccClientText(20925))
        return
    end
    if not isYesGet then
        GF.ShowMessage(string.replace(ccClientText(20924), ccLngText(ref.name)))
        return
    end
    gModelCareSchool:OnCollegeLibraryRewardReq(refId)
end

function UICareColleChapter:RefreshData()
    local ref = gModelCareSchool:GetCollegeLibraryRefByRefId(self._refId)
    self:SetWndText(self.mRwardText, string.replace(ccClientText(20923), ccLngText(ref.name)))
    self:SetWndText(self.mTitleText, ccLngText(ref.name))
    self:SetWndText(self.mBubbleText, ccLngText(ref.desc))
    if self._isVie then
        self:InitTextLineWithLanguage(self.mBubbleText, 15)
    else
        self:InitTextLineWithLanguage(self.mBubbleText, -30)
    end
    self:SetWndEasyImage(self.mImg, ref.bg)

    local list = gModelCareSchool:GetCollegeLibraryCheckpointRefListByRefId(ref.refId)

    local index = 1
    local isRed = true
    for i, v in ipairs(list) do
        local dolist = gModelCareSchool:GetLibraryDoList()
        if not dolist[v.refId] then
            index = i
            isRed = false
            break
        end
    end

    if not self._uiCellList then
        self._uiCellList = self:GetUIScroll("cell")
        self._uiCellList:Create(self.mCellSuper, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        self._uiCellList:EnableScroll(true, false)
    else
        self._uiCellList:RefreshList(list)
    end
    self._uiCellList:MoveToPos(index)

    self:DelaySendFinish(0.1)

    local reward1List = LxDataHelper.ParseItem(ref.extraReward)
    local uiList1 = self._uiItemScroll
    if not uiList1 then
        uiList1 = UIIconEasyList:New(self)
        self._uiItemScroll = uiList1
        uiList1:Create(self, self.mItemScroll)
        uiList1:SetIconParentPath("Root/CommonUI/Icon")
        uiList1:EnableScroll(true, true)
    end
    uiList1:RefreshList(reward1List)

    local refIds = gModelCareSchool:GetReceiveRefIds()
    --self:SetWndButtonGray(self.mBtnGet,refIds[ref.refId])
    self:SetWndButtonGray(self.mBtnGet, refIds[ref.refId] or not isRed)
    CS.ShowObject(self.mRedPoint, not refIds[ref.refId] and isRed)
end

function UICareColleChapter:OnClickClose()
    GF.OpenWndBottom("UICareColleWin")
    self:WndClose()
end

function UICareColleChapter:ListItem(list, item, itemdata, itempos)
    local titleText = CS.FindTrans(item, "TitleImg/TitleText")
    local desText = CS.FindTrans(item, "DesText")
    local rewardList = CS.FindTrans(item, "RewardList")
    local btnText = CS.FindTrans(item, "BtnText")
    local btnYellow3 = CS.FindTrans(item, "BtnYellow3")
    local redPoint = CS.FindTrans(item, "BtnYellow3/redPoint")

    local list = gModelCareSchool:GetLibraryDoList()
    local isLock = itemdata.open == 0 or list[itemdata.open]

    self:SetWndText(titleText, ccLngText(itemdata.name))
    self:InitTextSizeWithLanguage(titleText, -2)
    self:SetWndText(desText, ccLngText(itemdata.desc))
    self:InitTextSizeWithLanguage(desText, -2)

    if self._isVie then
        self:InitTextLineWithLanguage(desText, 0)
    else
        self:InitTextLineWithLanguage(desText, -30)
    end
    CS.ShowObject(btnText, not isLock)
    CS.ShowObject(btnYellow3, isLock)
    CS.ShowObject(redPoint, false)
    if not isLock then
        local opentRef = gModelCareSchool:GetCollegeLibraryCheckpointRefByRefId(itemdata.open)
        self:SetWndText(btnText, string.replace(ccClientText(20903), ccLngText(opentRef.name)))
    else
        local btnStr = ccClientText(20904)
        if list[itemdata.refId] then
            btnStr = ccClientText(20905)
        else
            CS.ShowObject(redPoint, true)
        end

        local addSize = -2
        local addLine = -30
        if gLGameLanguage:IsThaiVersion() then
            addSize = -4
            addLine = -50
        end

        self:SetWndButtonText(btnYellow3, btnStr, nil, addSize, addLine)
        self:SetWndClick(btnYellow3, function()
            self:OnClickCellBtn(itemdata.refId)
        end)
    end

    local InstanceID = item:GetInstanceID()
    local itemList = LxDataHelper.ParseItem(itemdata.reward)
    local uiIconEasyList = self._uiCellList:GetItemCls(InstanceID)
    if (not uiIconEasyList) then
        uiIconEasyList = UIIconEasyList:New()
        self._uiCellList:SetItemCls(InstanceID, uiIconEasyList)
        uiIconEasyList:Create(self, rewardList)
        uiIconEasyList:SetIconClickPath("CommonUI")
        uiIconEasyList:SetIconParentPath("CommonUI/Icon")
    end
    local isShowMask = list[itemdata.refId] ~= nil
    uiIconEasyList:SetShowMask(isShowMask, "CommonUI/Mask")
    uiIconEasyList:RefreshList(itemList)
end

function UICareColleChapter:InitTabList()
    local list = gModelCareSchool:GetCollegeLibraryRef()
    if not self._uiList then
        self._uiList = self:GetUIScroll("tab")
        self._uiList:Create(self.mTabSuper, list, function(...)
            self:TabListItem(...)
        end, UIItemList.SUPER)
        self._uiList:EnableScroll(true, true)
    end
    self._uiList:MoveToPos()
    local tabIndex = self._refId or list[1].refId
    self:OnClickTab(tabIndex)
end

function UICareColleChapter:TabListItem(list, item, itemdata, itempos)
    local bg = CS.FindTrans(item, "Image")
    local titleText = CS.FindTrans(item, "TitleBg/TitleText")
    local barTrans = CS.FindTrans(item, "Bar_1")
    local bar_1 = self:FindWndSlider(barTrans)
    local barText = CS.FindTrans(item, "BarText")
    local mask = CS.FindTrans(item, "Mask")
    local lockText = CS.FindTrans(item, "Mask/LockText")
    local statusImg = CS.FindTrans(item, "StatusImg")
    local redPoint = CS.FindTrans(item, "redPoint")

    local refId = itemdata.refId
    self._tabChapterList[refId] = item
    local refIds = gModelCareSchool:GetReceiveRefIds()
    local len, num = gModelCareSchool:GetLibraryChapterNum(refId)
    local isOpened = gModelFunctionOpen:CheckIsOpened(itemdata.functionOpen)
    self:SetWndEasyImage(bg, itemdata.tabIcon)
    self:SetWndText(titleText, ccLngText(itemdata.name))
    CS.ShowObject(barTrans, isOpened)
    CS.ShowObject(barText, isOpened)
    CS.ShowObject(mask, not isOpened)
    CS.ShowObject(statusImg, num > 0 and len == num and refIds[refId])

    if isOpened then
        bar_1.maxValue = len
        bar_1.value = num
        self:SetWndText(barText, string.replace(ccClientText(20902), num, len))
    else
        self:SetWndText(lockText, ccLngText(itemdata.openText))
    end
    self:SetWndClick(item, function()
        self:OnClickTab(refId)
    end)
    local list = gModelCareSchool:GetCollegeLibraryCheckpointRefListByRefId(refId)
    local wclist = gModelCareSchool:GetLibraryDoList()
    local isShowRed = false

    --这里进行约束 能否进行挑战
    for i, v in ipairs(list) do
        if not wclist[v.refId] then
            isShowRed = true
            break
        end
    end

    --local haveChallenge = false
    --
    --for i, v in ipairs(list) do
    --    if v.open == 1008 then
    --        printInfoN2("--", "--")
    --    end
    --    local isUnLock = v.open == 0 or wclist[v.open]
    --    if isUnLock then
    --        haveChallenge = true
    --        break
    --    end
    --end

    CS.ShowObject(redPoint, (isShowRed or not refIds[refId]) and isOpened)
    --CS.ShowObject(redPoint, (isShowRed or not refIds[refId]) and isOpened and haveChallenge)
    --CS.ShowObject(mask, not haveChallenge)

    self:InitTextSizeWithLanguage(titleText, -4)
end

function UICareColleChapter:ChangeTab(refId, bool)
    local trans = self._tabChapterList[refId]
    local selImg = CS.FindTrans(trans, "SelImg")
    CS.ShowObject(selImg, bool)
end

function UICareColleChapter:InitEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBtnGet, function()
        self:OnClickGet()
    end)
end

function UICareColleChapter:OnClickCellBtn(refId)
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TACTICAL_TRAINING, { targetId = refId })
    gModelCareSchool:SetOpentTabIndex(self._refId)
end

function UICareColleChapter:OnClickTab(refId)
    if self._refId then
        self:ChangeTab(self._refId, false)
    end
    self._refId = refId
    self:ChangeTab(refId, true)
    self:RefreshData()
end

function UICareColleChapter:InitCommand()
    self:SetWndButtonText(self.mBtnGet, ccClientText(18214))
    self._refId = self:GetWndArg("tabRefId") or self:GetWndArg("page")
    CS.ShowObject(self.mBubbleText, true)

    local dolist = gModelCareSchool:GetLibraryDoList()
    if table.isempty(dolist) then
        --没有数据时，进入界面请求一次
        gModelCareSchool:OnCollegeInfoReq()
        return
    end

    self:InitTabList()
end
------------------------------------------------------------------
return UICareColleChapter


