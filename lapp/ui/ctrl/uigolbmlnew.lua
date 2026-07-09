---
--- Created by Administrator.
--- DateTime: 2024/7/30 20:51:42
---
------------------------------------------------------------------
local LWnd = LWnd
local typeofCanvas = typeof(UnityEngine.Canvas)
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
---@class UIGolbMlNew:LWnd
local UIGolbMlNew = LxWndClass("UIGolbMlNew", LWnd)

local typeContentSizeFitter = typeof(CS.ContentSizeFitter)
local enumPreferredSize = CS.ContentSizeFitter.FitMode.PreferredSize
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolbMlNew:UIGolbMlNew()
    GF.OpenWndWait("UIWaitZC", { hideTime = 1 })
    self.lineRenderCtrlList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolbMlNew:OnWndClose()
    if self.timer1 then
        LxTimer.DelayTimeStop(self.timer1)
        self.timer1 = nil
    end
    if self.timer2 then
        LxTimer.DelayTimeStop(self.timer2)
        self.timer2 = nil
    end
    if self.timer3 then
        LxTimer.DelayTimeStop(self.timer3)
        self.timer3 = nil
    end
    if self.timer4 then
        LxTimer.DelayTimeStop(self.timer4)
        self.timer4 = nil
    end
    if self.lineRenderCtrlList then
        for _, v in pairs(self.lineRenderCtrlList) do
            v:Destroy()
        end
        self.lineRenderCtrlList = nil
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolbMlNew:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolbMlNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitText()
    self:InitSlider()
    self:UpdateCanvas()
    self:InitEff()
    self:InitChapter()
end

function UIGolbMlNew:InitChapter()
    local curDiffLvl = self:GetWndArg(2) or 1
    self.curChapter = gModelInstance:GetChapterId(curDiffLvl)
    self:SetAllChatper()
    self:SetMePos()
    self:SetChatperInCenter()

    local isNew = self:GetWndArg(1)
    if isNew then
        self.canClose = false
        local newChapterId = gModelInstance:GetNextChapterId(curDiffLvl)
        if newChapterId ~= -1 then
            self.newChapterId = newChapterId
            gModelInstance:OnInstanceSwitchReq(curDiffLvl)
        end
    else
        self.canClose = true
    end
end

function UIGolbMlNew:InitSlider()
    self.scaleSlider = self:UIProgressFind(self.mScaleBar, "mScaleBar", 0)
    local slider = self.mScaleBar:GetComponent(typeof(UnityEngine.UI.Slider))
    slider.maxValue = GameTable.MainInstanceConfigRef["mapInitialScaleMax"]
    slider.minValue = GameTable.MainInstanceConfigRef["mapInitialScaleMin"]
    self.scaleSlider:SetSliderDelegate(function(value)
        self.curScale = value
        self.mMapContent.localScale = Vector3.New(value, value, value)
        self.mNullObj.localScale = Vector2.New(value, value)
    end)
    self.scaleSlider:SetUIProgress(GameTable.MainInstanceConfigRef["mapInitialScale"])
end

function UIGolbMlNew:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        if self.canClose then
            GF.OpenWndWait("UIWaitZC", { hideTime = 1 })
            self.timer1 = LxTimer.DelayTimeCall(function()
                self.timer1 = nil
                self:WndClose()
            end, 0.7)
        end
    end)
    self:SetWndClick(self.mAdd, function()
        self.scaleSlider:SetUIProgress(self.curScale + 0.1)
    end)
    self:SetWndClick(self.mSub, function()
        self.scaleSlider:SetUIProgress(self.curScale - 0.1)
    end)
    self:SetWndClick(self.mMe, function()
        GF.OpenWndUp("UIMlTipsUI", { self.curChapter })
    end)

    self:WndNetMsgRecv(LProtoIds.InstanceSwitchResp, function()
        self:PlayNewChatperAni()
    end)
end

function UIGolbMlNew:PlayNewChatperAni()
    local nextChatperTran = CS.FindTrans(self.mChapterObj, "Chapter" .. self.curChapter + 2)
    local newChatperTran = CS.FindTrans(self.mChapterObj, "Chapter" .. self.curChapter + 1)

    local fog = CS.FindTrans(nextChatperTran, "FogImg")
    local fogCom = fog:GetComponent(typeof(UnityEngine.UI.Image))
    self:CreateWndEffect(fog, "fx_ui_map_world_yun", "yun", 100)
    self.timer2 = LxTimer.DelayTimeCall(function()
        fogCom.color = Color.New(1, 1, 1, 0)
        self.timer2 = nil
    end, 1)
    self.timer3 = LxTimer.DelayTimeCall(function()
        local oldChatper = self.curChapter
        self.curChapter = self.newChapterId
        self:CreateWndEffect(newChatperTran, "fx_ui_map_world_jiesuo", "jiesuo", 100)
        self.timer3 = LxTimer.DelayTimeCall(function()
            self:SetAllChatper()
            self:PlayRoleMove(oldChatper)
            self.timer3 = nil
        end, 1.4)
        self.timer2 = nil
    end, 2)
    -- local fogCom = fog:GetComponent(typeof(UnityEngine.UI.Image))
    -- local a = 1
    -- self.fogTimer = LxTimer.LoopTimeCall(function()
    -- 	a = a - 0.05
    -- 	fogCom.color = Color.New(1, 1, 1, a)
    -- 	if a <= 0 then
    -- 		LxTimer.DelayTimeStop(self.fogTimer)
    -- 		local oldChatper = self.curChapter
    -- 		self.curChapter = self.newChapterId
    -- 		self:SetAllChatper()
    -- 		self:PlayRoleMove(oldChatper)
    -- 	end
    -- end, 0.01, false, -1)
end

function UIGolbMlNew:InitEff()
    for i = 1, 9 do
        local tran = CS.FindTrans(self.mMapObj, "Map" .. i)
        self:CreateWndEffect(tran, "fx_ui_map_world_" .. i, tran.gameObject.name, 100)
    end
    self:CreateWndEffect(CS.FindTrans(self.mTop, "Title"), "fx_ui_map_world_biaoti", "biaoti", 100)
    self:CreateWndEffect(CS.FindTrans(self.mHeadObj, "Bg"), "fx_ui_map_world_touxiang", "touxiang", 100, nil, nil, nil, nil, nil, nil, nil, nil, 3)
    self:CreateWndEffect(CS.FindTrans(self.mTop, "Compass"), "fx_ui_map_world_zhinanzhen", "zhinanzhen", 100)

end

function UIGolbMlNew:SetAllChatper()
    local chapterList = gModelInstance:GetInstanceChapterRef()
    for i, v in ipairs(chapterList) do
        local trans = CS.FindTrans(self.mChapterObj, "Chapter" .. i)
        local lineTrans = CS.FindTrans(self.mLineObj, "Line" .. i - 1)
        self:SetChapter(trans, v, lineTrans)
    end

    local prefix, name = gModelInstance:GetCurBattleNodePrefixAndName()
    self:SetWndText(self.mStageText, prefix .. " " .. name)

    if self._isVie then
        local text = self:FindWndText(self.mStageText)
        local width = text.preferredWidth
        LxUiHelper.SetSizeWithCurAnchor(self.mStage, 0, 316 + width / 2)
    end
end

function UIGolbMlNew:SetChapter(trans, data, lineTrans)
    if not trans then
        return
    end
    local unOpen = CS.FindTrans(trans, "UnOpen")
    local unOpenImg = CS.FindTrans(unOpen, "UnOpenImg")
    local open = CS.FindTrans(trans, "Open")
    local cur = CS.FindTrans(trans, "Cur")
    local fog = CS.FindTrans(trans, "FogImg")
    local unOpenText = CS.FindTrans(unOpen, "Text")
    local openText = CS.FindTrans(open, "Text")
    local curText = CS.FindTrans(cur, "Text")
    self:SetWndText(unOpenText, ccLngText(data.name))
    self:SetWndText(openText, ccLngText(data.name))
    self:SetWndText(curText, ccLngText(data.name))

    local curChapter = self.curChapter
    if lineTrans then
        CS.ShowObject(CS.FindTrans(lineTrans, "OnLine"), true)
        CS.ShowObject(CS.FindTrans(lineTrans, "OffLine"), false)
    end
    if data.refId < curChapter then
        CS.ShowObject(open, true)
        CS.ShowObject(unOpen, false)
        CS.ShowObject(cur, false)
        CS.ShowObject(fog, false)
    elseif data.refId == curChapter then
        CS.ShowObject(cur, true)
        CS.ShowObject(unOpen, false)
        CS.ShowObject(open, false)
        CS.ShowObject(fog, false)
        if self._isVie then
            self:CreateWndEffect(trans, "fx_ui_map_world_dangqianzhangjie", "dangqianzhangjie", 200, nil, nil, nil, nil, 110, nil, nil, nil, 3)
        else
            self:CreateWndEffect(trans, "fx_ui_map_world_dangqianzhangjie", "dangqianzhangjie", 100, nil, nil, nil, nil, nil, nil, nil, nil, 3)
        end
    elseif data.refId == curChapter + 1 then
        CS.ShowObject(unOpen, true)
        CS.ShowObject(cur, false)
        CS.ShowObject(open, false)
        CS.ShowObject(fog, false)
        if lineTrans then
            CS.ShowObject(CS.FindTrans(lineTrans, "OnLine"), false)
            CS.ShowObject(CS.FindTrans(lineTrans, "OffLine"), true)
        end
    else
        CS.ShowObject(unOpen, true)
        CS.ShowObject(cur, false)
        CS.ShowObject(open, false)
        CS.ShowObject(fog, true)
        if lineTrans then
            CS.ShowObject(CS.FindTrans(lineTrans, "OnLine"), false)
            CS.ShowObject(CS.FindTrans(lineTrans, "OffLine"), true)
        end
    end

    self:SetWndClick(trans, function()
        if data.refId <= curChapter then
            GF.OpenWndUp("UIMlTipsUI", { data.refId })
        else
            GF.ShowMessage(ccClientText(45006))
        end
    end)

    if self._isEnus then
        LxUiHelper.SetLayoutPadding(unOpen, Vector4.New(0, 24, 0, 0))

        local csSizeFitter = unOpen:GetComponent(typeContentSizeFitter)
        if (not csSizeFitter) then
            csSizeFitter = unOpen.gameObject:AddComponent(typeContentSizeFitter)
            csSizeFitter.horizontalFit = enumPreferredSize
        end

    end

    if self._isVie then
        local changeWidth = 280
        LxUiHelper.SetSizeWithCurAnchor(unOpenImg, 0, changeWidth)
        LxUiHelper.SetSizeWithCurAnchor(open, 0, changeWidth)
        LxUiHelper.SetSizeWithCurAnchor(cur, 0, changeWidth)
    end

    LayoutRebuilder.ForceRebuildLayoutImmediate(unOpenText)
end

function UIGolbMlNew:InitText()
    self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
end

function UIGolbMlNew:GetPath(chapter)
    local curChapter = CS.FindTrans(self.mChapterObj, "Chapter" .. chapter)
    local nextChapter = CS.FindTrans(self.mChapterObj, "Chapter" .. chapter + 1)
    local lineTrans = CS.FindTrans(self.mLineObj, "Line" .. chapter)
    local rotPoint = CS.FindTrans(lineTrans, "RotPonit")

    local quardaticBezier = function(t)
        local a = curChapter.localPosition
        local b = rotPoint.localPosition
        local c = nextChapter.localPosition
        local aa = a + (b - a) * t
        local bb = b + (c - b) * t
        return aa + (bb - aa) * t
    end
    local pathList = {}
    for i = 0, 20 do
        local to = quardaticBezier(i / 20)
        table.insert(pathList, to)
    end
    return pathList
end

function UIGolbMlNew:SetMePos()
    local curChatperTran = CS.FindTrans(self.mChapterObj, "Chapter" .. self.curChapter)
    if curChatperTran then
        self.mMe.localPosition = Vector2.New(curChatperTran.localPosition.x, curChatperTran.localPosition.y + 48)
        local res = gModelPlayer:GetPlayerIconByType(ModelPlayer.PERSONALITY_HEAD_IMAGE)
        self:SetWndEasyImage(CS.FindTrans(self.mHeadObj, "Mask/Head"), res)
    end
end

function UIGolbMlNew:UpdateCanvas()
    local wndSortOrder = self:GetWndSortOrder()
    local canvas = self.mBg:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 4
    canvas = self.mScaleBar:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 3
    canvas = self.mBot:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 3
    canvas = self.mTop:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 3
    canvas = self.mMapObj:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder
    canvas = self.mChapterObj:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 2
    canvas = self.mFogObj:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 3

    local i = 1
    while true do
        local trans = CS.FindTrans(self.mLineObj, "Line" .. i)
        if trans then
            local offLine = CS.FindTrans(trans, "OffLine")
            local onLine = CS.FindTrans(trans, "OnLine")
            local offCtrl = LineRenderCtrl:New(offLine)
            self.lineRenderCtrlList["OffLine" .. i] = offCtrl
            offCtrl:SetSortingOrder(wndSortOrder + 1)
            local onCtrl = LineRenderCtrl:New(onLine)
            self.lineRenderCtrlList["OnLine" .. i] = onCtrl
            onCtrl:SetSortingOrder(wndSortOrder + 1)
            i = i + 1
        else
            break
        end
    end
end

function UIGolbMlNew:SetChatperInCenter()
    local curChatperTran = CS.FindTrans(self.mChapterObj, "Chapter" .. self.curChapter)
    self.mMapContent.position = Vector2.New(-curChatperTran.position.x, -curChatperTran.position.y)
end

function UIGolbMlNew:PlayRoleMove(chatper)
    local pathList = self:GetPath(chatper)
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("delayFreeze")
    local Tweening = DG.Tweening
    local time = 0.1

    local curChatperTran = CS.FindTrans(self.mChapterObj, "Chapter" .. self.curChapter)
    local oldPos = self.mMapContent.localPosition
    self.mMapContent.position = Vector2.New(0, 0)
    self.mNullObj.position = Vector2.New(0, 0)
    local pos = curChatperTran.position
    self.mNullObj.position = Vector2.New(-pos.x, -pos.y)
    self.mMapContent.localPosition = oldPos
    local downTweener = self.mMapContent:DOLocalMove(Vector2.New(self.mNullObj.localPosition.x, self.mNullObj.localPosition.y), 1):SetEase(Tweening.Ease.Linear)
    seq:Insert(0, downTweener)

    CS.ShowObject(self.mHeadObj, false)
    for i, v in ipairs(pathList) do
        local pos = v + Vector3.New(0, 48)
        local downTweener = self.mMe:DOLocalMove(pos, time):SetEase(Tweening.Ease.Linear)
        seq:Insert(1 + time * (i - 1), downTweener)
    end
    seq:InsertCallback(time * (#pathList - 1) + 1.5, function()
        CS.ShowObject(self.mHeadObj, true)
        self.timer4 = LxTimer.DelayTimeCall(function()
            GF.OpenWndUp("UIMlTipsUI", { self.curChapter, true })
            self:UpdateCanvas()
            self.canClose = true
            self.timer4 = nil
        end, 0.5)
    end)
    seq:PlayForward()
end

------------------------------------------------------------------
return UIGolbMlNew