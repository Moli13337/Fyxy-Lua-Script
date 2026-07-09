---
--- Created by Administrator.
--- DateTime: 2024/7/12 18:05:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqBreakBack:LWnd
local UIEqBreakBack = LxWndClass("UIEqBreakBack", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqBreakBack:UIEqBreakBack()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqBreakBack:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqBreakBack:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqBreakBack:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitText()
    self:InitEvent()
    self:InitPara()
    self:InitData()

    self:SetPanel()
end

function UIEqBreakBack:InitPara()
    self._refId = self:GetWndArg("refId")
    self._id = self:GetWndArg("id")
    self._equip = self:GetWndArg("equip")
    self._wndRefId = self:GetWndArg("wndRefId")

end

function UIEqBreakBack:SetContent()
    local str = ccLngText(self._wndData.title)
    self:SetWndText(self.mTitle1, str)

    local equipName = ModelEquip:GetNameByRefId(self._refId)
    str = string.replace(ccLngText(self._wndData.text), ccLngText(equipName))
    self:SetWndText(self.mContent1, str)

    --左右按钮
    local btnImg = string.split(self._wndData.btnPng, "|")
    local btnTxt = string.split(ccLngText(self._wndData.btnTxt), "|")

    local btnImgTran, btnTextTran = self:GetBtnTran(self.mPublic_btn_Left)
    self:SetWndEasyImage(btnImgTran, btnImg[1])
    self:SetWndText(btnTextTran, btnTxt[1])

    btnImgTran, btnTextTran = self:GetBtnTran(self.mPublic_btn_Right)
    self:SetWndEasyImage(btnImgTran, btnImg[2])
    self:SetWndText(btnTextTran, btnTxt[2])


end

function UIEqBreakBack:InitEvent()
    --ui
    self:SetWndClick(self.mCloseBtn1, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mPublic_btn_Left, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mPublic_btn_Right, function()
        self:OnRightClick()
    end)
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIEqBreakBack:InitText()
    self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UIEqBreakBack:GetBtnTran(root)
    local img = CS.FindTrans(root, "Light")
    local text = CS.FindTrans(img, "Text")
    return img, text
end

function UIEqBreakBack:InitData()
    self._wndData = GameTable.UIWindowAttRef[self._wndRefId]

    self._item = gModelEquip:GetEquipBreakBackItem(self._equip)
end

function UIEqBreakBack:SetReward()
    local uiList = self._uiRewardList

    if not uiList then
        uiList = UIIconEasyList:New()
        self._uiRewardList = uiList
        uiList:Create(self, self.mReward)
        uiList:SetShowNum(false)
        uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
        uiList:SetShowExtraNum(true, "itemNum")
    end

    uiList:RefreshList(self._item)

    local length = #self._item

    if length <5 then
        self.mReward.transform.sizeDelta = Vector2(120*length, 122);
        uiList:EnableScroll( false,true)
    else

        uiList:EnableScroll(true,true)
    end





end

--endregion --------------------------------------------------------------------------------------


--region 页面方法 --------------------------------------------------------------------------------
function UIEqBreakBack:SetPanel()
    self:SetContent()
    self:SetReward()
end

--endregion --------------------------------------------------------------------------------------

--region 页面事件 --------------------------------------------------------------------------------

function UIEqBreakBack:OnRightClick()
    self:WndClose()
    gModelEquip:OnEquipResolveReq(self._refId, self._id)
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIEqBreakBack