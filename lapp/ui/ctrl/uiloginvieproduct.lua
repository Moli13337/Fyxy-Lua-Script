---
--- Created by Administrator.
--- DateTime: 2025/4/7 15:11:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILoginVieProduct:LWnd
local UILoginVieProduct = LxWndClass("UILoginVieProduct", LWnd)
local typeUITextInput = typeof(CS.YXUITextInput)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILoginVieProduct:UILoginVieProduct()
    self._staticText = {
        [1] = 169,
        [2] = 170,
        [3] = 171,
        [4] = 172,
        [5] = 173,
        [6] = 174,
        [7] = 175,
        [8] = 176,
    }

    self._oldStr=""
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILoginVieProduct:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILoginVieProduct:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILoginVieProduct:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitMsg()
    self:InitStaticText()
end

--endregion --------------------------------------------------------------------------------------

--region 界面设置 --------------------------------------------------------------------------------
function UILoginVieProduct:InitStaticText()
    for i = 1, 8 do
        local tranName = "Div_" .. i
        local inputTranDiv = CS.FindTrans(self.mInPutDiv, tranName)
        local Title = CS.FindTrans(inputTranDiv, "Title")
        local index = self._staticText[i]
        self:SetWndText(Title, ccClientText(index))
    end

    self:SetWndText(CS.FindTrans(self.mSendBtn, "UIText"), ccClientText(177))
    self:SetWndText(CS.FindTrans(self.mSureBtn, "UIText"), ccClientText(178))
end

function UILoginVieProduct:InitMsg()

end

function UILoginVieProduct:OnInput(tran, str, index)
    if index == 8 then
        if type(str) == "number" then
        else
            local text =CS.FindTrans(tran,"TextArea/Text")
            self:SetWndText(text, self._oldStr)
            return
        end



    end

    self._oldStr = str
    self:SetWndTextInput(tran,  self._oldStr)
end

--region 事件 --------------------------------------------------------------------------------

function UILoginVieProduct:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mSendBtn, function()
        GF.ShowMessage(ccClientText(179))
    end)

    self:SetWndClick(self.mSureBtn, function()
        self:WndClose()
    end)

    for i = 1, 8 do
        local tranName = "Div_" .. i
        local inputTranDiv = CS.FindTrans(self.mInPutDiv, tranName)
        local inputTran = CS.FindTrans(inputTranDiv, "UIInputText")
        local inputComponent = inputTran:GetComponent(typeUITextInput)
        inputComponent.onValueChanged:AddListener(function(str)
            self:OnInput(inputTran, str, i)
        end)
    end
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UILoginVieProduct