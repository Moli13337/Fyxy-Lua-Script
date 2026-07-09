---
--- Created by BY.
--- DateTime: 2023/10/16 17:05:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBtnLPop:LWnd
local UIBtnLPop = LxWndClass("UIBtnLPop", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBtnLPop:UIBtnLPop()
    self._delayTimer = "_delayTimer"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBtnLPop:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBtnLPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBtnLPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()

    self:InitEvent()
    --self:InitMessage()
    self:InitCommand()
end

function UIBtnLPop:ListItem(list, item, itemdata, itemPos)
    local btn = CS.FindTrans(item, "Btn")
    local text = CS.FindTrans(btn, "Light/Text")
    local openId = itemdata.openId
    local bool = true
    if openId then
        if type(openId) == "number" then
            bool = gModelFunctionOpen:CheckIsOpened(openId, false)
        elseif type(openId) == "string" then
            local openIdArr = string.split(openId, "|")
            for i, v in ipairs(openIdArr) do
                bool = gModelFunctionOpen:CheckIsOpened(tonumber(v), false)
                if bool then
                    break
                end
            end
        end
    end
    self:SetWndButtonGray(btn, not bool)

    if self._isEnus then
        self:SetWndButtonText(btn, itemdata.title,nil,-7)
    else
        self:SetWndButtonText(btn, itemdata.title)
    end

    local edgeColor = itemdata.edgeColor
    if edgeColor then
        self:SetTextOutLineByColor(text, edgeColor)
    end
    local img = itemdata.img
    if LxUiHelper.IsImgPathValid(img) then
        self:SetWndButtonImg(btn, img)
    end
    local func = itemdata.func
    self:SetWndClick(btn, function()
        if func then
            func()
            self:WndClose()
        end
    end)
end

function UIBtnLPop:InitCommand()
    self._root = self:GetWndArg("root")
    self._showRight = self:GetWndArg("showRight") or false
    local list = self:GetWndArg("list")
    local other = self:GetWndArg("other")
    self._posType = self:GetWndArg('posType') or 1
    CS.ShowObject(self.mTitleText, other)
    if other then
        self:SetWndText(self.mTitleText, other)
    end
    local btnUIList = self:GetUIScroll("btnList")
    btnUIList:Create(self.mBtnScroll, list, function(...)
        self:ListItem(...)
    end)

    self._screenHeight = self.mBgImage.rect.height / 2

    self:TimerStart(self._delayTimer, 0.1, false, 1)
end

function UIBtnLPop:SetPos()
    local follow = self._root
    if CS.IsNullObject(follow) then
        return
    end

    local target = self.mPosMag:GetComponent(typeofRectTransform)

    local canvasRect = LGameUI.GetUICanvasRoot()
    local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect, follow)

    local tarY = targetPos.y
    local _screenHeight = self._screenHeight
    local magHeight = self.mBtnMag.rect.height
    local height = _screenHeight + tarY - magHeight
    if height <= 0 then
        local followHeight = follow.rect.height
        tarY = tarY + magHeight + followHeight - 10
    end

    local tarX = targetPos.x
    if self._showRight then
        tarX = tarX + 240
    end
    local pos = Vector3.New(tarX, tarY, 0)
    target.localPosition = pos
end

function UIBtnLPop:OnTimer(key)

    if self._posType == 1 then
        self:SetPos()
    else
        self:SetPosTwo()
    end
end

function UIBtnLPop:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
end

function UIBtnLPop:SetPosTwo()
    local follow = self._root
    if CS.IsNullObject(follow) then
        return
    end

    local target = self.mPosMag:GetComponent(typeofRectTransform)
    local canvasRect = LGameUI.GetUICanvasRoot()
    local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect, follow)
    local magHeight = self.mBtnMag.rect.height

    local pos = Vector3.New(targetPos.x + 125, targetPos.y + magHeight + 50, 0)
    target.localPosition = pos
end
------------------------------------------------------------------
return UIBtnLPop


