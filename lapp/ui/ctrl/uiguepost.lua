---
--- Created by Administrator.
--- DateTime: 2023/10/11 10:58:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGuePost:LWnd
local UIGuePost = LxWndClass("UIGuePost", LWnd)

UIGuePost.NORMAL = 1
UIGuePost.MULTI = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGuePost:UIGuePost()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGuePost:OnWndClose()

    local notTrigger = self:GetWndArg("notTriggerGuide")
    if not notTrigger then
        FireEvent(EventNames.ON_GUIDE_POST_CLOSE, self._refId)
    end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGuePost:OnCreate()
    LWnd.OnCreate(self)

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGuePost:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitUIEvent()
    self:InitData()
    self:InitWndPara()
    self:SetStaticContent()
    self:RefreshUI()
end

function UIGuePost:InitText()
    self:SetWndText(self.mRaceType6, ccClientText(1010401))
    self:SetWndText(self.mRaceType6Desc, ccClientText(1010402))
end

function UIGuePost:ShowType(item)
    CS.ShowObject(item, true)
    local textRoot = self:FindWndTrans(item, "textRoot")
    local key, text, str

    local addSize = -2
    local addLine = -30
    if gLGameLanguage:IsEnglishVersion() then
        addSize = -4
        addLine = -20
    elseif gLGameLanguage:IsKoreaVersion() then
        addSize = -4
        addLine = -30
    elseif gLGameLanguage:IsJapanRegion() then
        addSize = -4
        addLine = -30
    elseif gLGameLanguage:IsVieVersion() then
        addLine =5
    end

    for k = 2, 11 do
        key = "text_" .. k
        text = self:FindWndTrans(textRoot, key)
        key = "text" .. k
        if text and self._ref[key] then
            str = ccLngText(self._ref[key])
            self:SetWndText(text, str)
            self:InitTextSizeWithLanguage(text, addSize)
            self:InitTextLineWithLanguage(text, addLine)

        end

        if gLGameLanguage:IsJapanVersion() then
            if k == 5 then
                LxUiHelper.SetSizeWithCurAnchor(text,0,300)
            end
        end
    end
    local refText1 = self._ref["text1"]
    if not refText1 then
        printInfoNR("HelpTeachingRef, text1 is not find, refId = " .. (self._refId or "nil"))
        return
    end

    self:SetWndText(self.mTitle, ccLngText(refText1))


end

function UIGuePost:OnClickCut(index)
    local offset = index == 1 and -1 or 1

    local newIndex = self._index + offset
    if newIndex <= 0 then
        newIndex = self._listLen
    elseif newIndex > self._listLen then
        newIndex = 1
    end

    self._index = newIndex
    --if index == 1 and self._index > 1 then
    --	self._index = self._index - 1
    --elseif index == 2 and self._listLen > self._index then
    --	self._index = self._index + 1
    --end
    self._refId = self._refIdList[self._index]
    self._ref = gModelPlot:GetTeachingRef(self._refId)

    self:RefreshUI()

end

function UIGuePost:InitWndPara()

    local wndType = self:GetWndArg("wndType") or 1
    if wndType == 1 then
        self._refId = self:GetWndArg("refId")
        self._refIdList = self:GetWndArg("refIdList") or {}
    else
        self._refIdList = {}
        local dataList = gModelPlot:GetTeachingRefList()
        for k, v in ipairs(dataList) do
            table.insert(self._refIdList, v.refId)
        end

        self._refId = self._refIdList[1]
    end

    self._length = #self._refIdList
    self._index = 1
    self._listLen = #self._refIdList
    if self._listLen > 1 then
        for i, v in ipairs(self._refIdList) do
            if v == self._refId then
                self._index = i
            end
        end
        CS.ShowObject(self.mLeftBtn, true)
        CS.ShowObject(self.mRightBtn, true)

    end
    self._ref = gModelPlot:GetTeachingRef(self._refId)
    if not self._ref then
        printInfoNR("HelpTeachingRef, ref is not find, refId = " .. (self._refId or "nil"))
    end
end

function UIGuePost:InitData()
    self._typeSetList = {
        [1001] = self.mContent_1,
        [1002] = self.mContent_2,
        [1003] = self.mContent_3,
        [1004] = self.mContent_4,
        [1005] = self.mContent_5,
        [1006] = self.mContent_6,
        [1007] = self.mContent_7,
        [1008] = self.mContent_8

    }
end

function UIGuePost:RefreshUI()
    for i, v in pairs(self._typeSetList) do
        CS.ShowObject(v, false)
    end
    self:ShowType(self._typeSetList[self._refId])

    if self._index == 1 then
        CS.ShowObject(self.mLeftBtn, false)

    else
        CS.ShowObject(self.mLeftBtn, self._length > 1)
    end

    if self._index == #self._refIdList then
        CS.ShowObject(self.mRightBtn, false)
    else
        CS.ShowObject(self.mRightBtn, self._length > 1)
    end


end

function UIGuePost:SetStaticContent()
    self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UIGuePost:InitUIEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mLeftBtn, function()
        self:OnClickCut(1)
    end)
    self:SetWndClick(self.mRightBtn, function()
        self:OnClickCut(2)
    end)
    self:SetWndClick(self.mCloseTip, function(...)
        self:WndClose()
    end)
end

------------------------------------------------------------------
return UIGuePost


