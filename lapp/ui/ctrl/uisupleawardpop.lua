---
--- Created by BY.
--- DateTime: 2023/10/7 15:41:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISupleAwardPop:LWnd
local UISupleAwardPop = LxWndClass("UISupleAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISupleAwardPop:UISupleAwardPop()
    ---@type UIIconEasyList
    self._uiRewardList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISupleAwardPop:OnWndClose()
    if self._uiRewardList then
        self._uiRewardList:Destroy()
        self._uiRewardList = nil
    end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISupleAwardPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISupleAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:InitEvent()
    --self:InitMessage()
    self:InitCommand()
end

function UISupleAwardPop:SetItemList(dataList)
    local uiRewardList = self._uiRewardList
    if not uiRewardList then
        uiRewardList = UIIconEasyList:New()
        self._uiRewardList = uiRewardList
        uiRewardList:Create(self, self.mItemList)
        uiRewardList:EnableLoadAnimation(true, 0.1, 1)
        uiRewardList:SetIconParentPath("Icon")
        uiRewardList:EnableScroll(true,false)
    end
    uiRewardList:RefreshList(dataList, true)
    uiRewardList:EnableScroll(true,false)
end

function UISupleAwardPop:RefreshHeroPaint(gameHero, gameHeroPos)
    if not gameHero then return end

    local posParent

    if type(gameHero) == "number" then
        posParent = self.mHeroPaint
        local ref = gModelHero:GetShowEffectById(gameHero)
        local spineName = ref.heroDrawing
        self:CreateWndSpine(self.mHeroPaint,spineName,spineName.."hero",false,function(dpSpine)
            dpSpine:SetScale(0.8)
        end)
    elseif not string.isempty(gameHero) then
        local imgArr = string.split(gameHero,"=")
        if imgArr[1] == "1" then
            posParent = self.mHeroImage
            self:SetWndEasyImage(posParent,imgArr[2],nil,true)
        else
            posParent = self.mHeroPaint
            local spineName = imgArr[2]
            self:CreateWndSpine(posParent,spineName,spineName.."hero",false)
        end
        CS.ShowObject(posParent,true)
    end

    if not string.isempty(gameHeroPos) then
        local arr = string.split(gameHeroPos,"|")
        posParent.anchoredPosition = Vector2(tonumber(arr[1]),tonumber(arr[2]))
    end
end

function UISupleAwardPop:InitCommand()
    local title = self:GetWndArg("title")
    local desc = self:GetWndArg("desc")
    local hero = self:GetWndArg("hero")
    local pos = self:GetWndArg("pos")
    local awards = self:GetWndArg("awards")

    self:RefreshHeroPaint(hero, pos)
    self:SetWndText(self.mTitleText,title)
    self:SetWndText(self.mDesText,desc)
    self:SetItemList(awards)
end

function UISupleAwardPop:InitEvent()
    self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
    self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end
------------------------------------------------------------------
return UISupleAwardPop


