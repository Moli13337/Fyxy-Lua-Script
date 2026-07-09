---
--- Created by Administrator.
--- DateTime: 2024/7/8 15:24:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqExtension:LWnd
local UIEqExtension = LxWndClass("UIEqExtension", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqExtension:UIEqExtension()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqExtension:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqExtension:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqExtension:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitPara()
    self:InitTabBtnData()
    self:InitEvent()
    self:InitText()
    self:CreateTabBtn()

    self:SetInfo()
    --调用一次 打开页面
    self._tabListInfo[self._childIndex].btnClickFunc()
    self:SetBtnRedPoint()
    self:SetBtnLock()
end

function UIEqExtension:InitPara()
    local tabIndex = self:GetWndArg("tabIndex")
    self._childIndex = tabIndex or 1

    self._refId = self:GetWndArg("refId")
    self._id = self:GetWndArg("id")
    self._equip = self:GetWndArg("equip")
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIEqExtension:CreateTabBtn()
    local uiList = self._uiList

    if not uiList then
        uiList = self:GetUIScroll("UIEqExtension_tabList")
        uiList:Create(self.mTabScroll, self._tabListInfo, function(...)
            self:CreateListItem(...)
        end)

        self._uiList = uiList
    end
end

function UIEqExtension:InitText()
    self:SetWndText(self.mTxtClose, ccClientText(30205))
end

function UIEqExtension:SetBtnRedPoint()
    for k, v in ipairs(self._tabTran) do
        local CheckRedPointFunc = self._tabListInfo[k].CheckRedPointFunc
        local redpoint = v.redPoint

        local isShow = CheckRedPointFunc(self._equip)
        CS.ShowObject(redpoint, isShow)
    end
end

function UIEqExtension:InitEvent()
    self:WndEventRecv(gModelEquip.EventArgs.StrengthChange, function(data)
        self._equip = data.equip
        self:SetBtnRedPoint()
        self:SetBtnLock()
    end)

    self:WndNetMsgRecv(LProtoIds.PlayerChangeResp, function()
        self:SetInfo()
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:SetInfo()
        self:SetBtnRedPoint()
        self:SetBtnLock()
    end)

    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end)

    self:SetWndClick(self.mGoldDiv, function()
        GF.OpenWnd("UIGBuy")
    end)

    self:SetWndClick(self.mMasonryDiv, function()
        gLxTKData:OnUIBtnClick("UIHuiYPay")
        local wndInst = GF.FindFirstWndByName("UIHuiYPay")
        if wndInst then
            return
        end
        GF.OpenWndBottom("UIHuiYPay", { page = 2 })
    end)

    self:SetWndClick(self.mHelpTipsBtn, function()
        self:OnHelpTipsClick()
    end)
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIEqExtension:InitTabBtnData()
    self._tabListInfo = {
        [1] = {
            tabIndex = 1,
            btnName = ccClientText(44502), -- [44502] [鑄 魂]
            functionId = 0,
            btnClickFunc = function()
                self:CreateChildWnd(self.mChildRoot, "UISubEqUpde", { refId = self._refId, id = self._id, equip = self._equip })
            end,
            img = "equip_tab3",
            CheckRedPointFunc = function(equip)
                local isShow = gModelEquip:GetUpGradeRedPoint(equip)
                return isShow
            end,
            CheckIsLock = function(equip)
                local refId = equip:GetRefId()
                local equipRef = gModelEquip:GetEquipRefByRefId(refId)
                local starCount = tonumber(equipRef.star)
                return starCount < 2
            end,
        },
        [2] = {
            tabIndex = 2,
            btnName = ccClientText(44501), --  [44501] [升 星]
            functionId = 0,
            btnClickFunc = function()
                self:CreateChildWnd(self.mChildRoot, "UISubEqUpStar", { refId = self._refId, id = self._id, equip = self._equip })
            end,
            img = "equip_tab2",
            CheckRedPointFunc = function(equip)
                local isShow = gModelEquip:GetEquipUpStarRedPoint(equip)
                return isShow
            end,
            CheckIsLock = function(equip)
                return false
            end,
        },
        [3] = {
            tabIndex = 3,
            btnName = ccClientText(44500), --[44500] [强 化]
            functionId = 0,
            btnClickFunc = function()
                self:CreateChildWnd(self.mChildRoot, "UISubEqStrength", { refId = self._refId, id = self._id, equip = self._equip })
            end,
            img = "equip_tab1",
            CheckRedPointFunc = function(equip)
                local isShow = gModelEquip:GetEquipStrengthRedPoint(equip)
                return isShow
            end,
            CheckIsLock = function(equip)
                return false
            end,
        },


    }

    self._tabTran = {}
end

--endregion --------------------------------------------------------------------------------------

--region 页面事件 --------------------------------------------------------------------------------
function UIEqExtension:OnHelpTipsClick()
    local ref = GameTable.SupportTipsRef[178]
    --self._helpTipsRef=GameTable.SupportTipsRef[self._refID]
    --self._title = ccLngText(self._helpTipsRef.title)
    --self._text = ccLngText(self._helpTipsRef.text)

    GF.OpenWnd("UIBzTips", { title = ccLngText(ref.title), text = ccLngText(ref.text) })
end

function UIEqExtension:CreateListItem(list, item, itemdata, itempos)
    local redPoint = CS.FindTrans(item, "redPoint")
    local selectTag = CS.FindTrans(item, "OnBg")

    local offImg = CS.FindTrans(item, "Off")
    local offText = CS.FindTrans(offImg, "Text")

    local onImg = CS.FindTrans(item, "On")
    local onText = CS.FindTrans(onImg, "Text")

    local grayImg = CS.FindTrans(item, "Gray")
    local grayText = CS.FindTrans(grayImg, "Text")

    local lock = CS.FindTrans(item, "Lock")

    CS.ShowObject(redPoint, false)
    CS.ShowObject(selectTag, itemdata.tabIndex == self._childIndex)
    CS.ShowObject(lock, false)

    self:SetWndEasyImage(offImg, itemdata.img)
    self:SetWndEasyImage(onImg, itemdata.img)
    self:SetWndEasyImage(grayImg, itemdata.img)

    self:SetWndText(offText, itemdata.btnName)
    self:SetWndText(onText, itemdata.btnName)
    self:SetWndText(grayText, itemdata.btnName)

    self:SetWndClick(item, function()

        if itemdata.CheckIsLock(self._equip) then
            GF.ShowMessage(string.replace(ccClientText(44526), 2))
        else
            self._childIndex = itemdata.tabIndex
            itemdata.btnClickFunc()
            self:ChangeBtn()
        end

    end)

    if not self._tabTran[itemdata.tabIndex] then
        self._tabTran[itemdata.tabIndex] = {}
    end

    self._tabTran[itemdata.tabIndex].redPoint = redPoint
    self._tabTran[itemdata.tabIndex].selectTag = selectTag
    self._tabTran[itemdata.tabIndex].lock = lock


end

function UIEqExtension:SetInfo()
    -- 砖石
    local num = gModelItem:GetNumByRefId(ModelItem.ITEM_DIAMOND)
    num = LUtil.NumberCoversion(num)
    self:SetWndText(self.mMasonryNum, num)
    local iconPath = gModelItem:GetItemImgByRefId(ModelItem.ITEM_DIAMOND)
    self:SetWndEasyImage(self.mMasonryIcon, iconPath)
    -- 金币
    num = gModelItem:GetNumByRefId(ModelItem.ITEM_GOLD)
    num = LUtil.NumberCoversion(num)
    self:SetWndText(self.mGoldNum, num)

end

function UIEqExtension:ChangeBtn()
    for k, v in ipairs(self._tabTran) do
        CS.ShowObject(v.selectTag, k == self._childIndex)
    end
end

function UIEqExtension:SetBtnLock()
    for k, v in ipairs(self._tabTran) do
        local CheckIsLock = self._tabListInfo[k].CheckIsLock
        local lock = v.lock

        local islock = CheckIsLock(self._equip)
        CS.ShowObject(lock, islock)
    end
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIEqExtension