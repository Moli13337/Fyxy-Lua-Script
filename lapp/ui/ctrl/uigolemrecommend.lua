---
--- Created by LCM.
--- DateTime: 2022/11/8 15:55:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemRecommend:LWnd
local UIGolemRecommend = LxWndClass("UIGolemRecommend", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemRecommend:UIGolemRecommend()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemRecommend:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemRecommend:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemRecommend:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:RefreshView()
end

function UIGolemRecommend:InitEvent()

    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------- List -------------------------


function UIGolemRecommend:GetGolemShowList()
    if not self._suitId then return {} end

    ---- 暂时这么处理，等策划下方案决定
    local suitList = gModelGolem:GetGolemElementSuitListBySuit(self._suitId)
    local suitPosList = {}
    local golemDrawing
    for i,v in ipairs(suitList) do
        golemDrawing = v.golemDrawing
        local suitPosInfo = suitPosList[golemDrawing]
        if not suitPosInfo then
            suitPosInfo = {}
            suitPosList[golemDrawing] = suitPosInfo
        end
        table.insert(suitPosInfo,v)
    end
    local posSortFunc = function(a,b)
        return a.refId > b.refId
    end
    for pos,posList in pairs(suitPosList) do
        table.sort(posList,posSortFunc)
    end

    local list = {}
    for pos,posList in pairs(suitPosList) do
        table.insert(list,posList[1])
    end
    table.sort(list,function(a,b)
        return a.golemDrawing < b.golemDrawing
    end)
    return list
end

function UIGolemRecommend:RefreshView()
    if not self._suitId then return end
    local ref = gModelGolem:GetGolemSuitRefByRefId(self._suitId)
    if not ref then return end
    -- self:SetWndEasyImage(self.mGolemIcon,ref.icon,function()
    --     CS.ShowObject(self.mGolemIcon,true)
    --     self.mGolemIcon.localScale = Vector2.New(0.8,0.8)
    -- end,true)
    self:DisposeShowSuitFunc()
    self:SetWndText(self.mName,ref.name)

    local conStr = ccClientText(33227)
    local twoSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_1)
    local showTwoSuitStr = string.replace(ccClientText(33266),twoSuit,ref.suitText)
    local fourSuit = string.replace(conStr,ModelGolem.SUIT_WEAR_2)
    local showFourSuitStr = string.replace(ccClientText(33266),fourSuit,ref.suitText1)
    showTwoSuitStr = string.gsub(showTwoSuitStr,"#30e005","#139057")
    showFourSuitStr = string.gsub(showFourSuitStr,"#30e005","#139057")
    local suitDesc = string.replace(ccClientText(33253),showTwoSuitStr,showFourSuitStr)
    self:SetWndText(self.mGolemDesc,suitDesc)

    self:InitGolemShowList()
end

function UIGolemRecommend:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(33297))
end


function UIGolemRecommend:InitMsg()

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemRecommend:InitData()
    self._suitId = self:GetWndArg("suitId")
end

function UIGolemRecommend:DisposeShowSuitFunc()
    local attrShow = self._suitId and gModelGolem:GetGolemSuitAttrShowByRefId(self._suitId)
    local attrShowType = self._suitId and gModelGolem:GetGolemSuitAttrShowTypeByRefId(self._suitId)
    local showIcon = attrShowType == ModelGolem.ATTRSHOWTYPE_ICON
    local showSpine = attrShowType == ModelGolem.ATTRSHOWTYPE_SPINE
    local showEffect = attrShowType == ModelGolem.ATTRSHOWTYPE_EFFECT
    CS.ShowObject(self.mGolemIcon,showIcon)
    if showIcon then
        if string.isempty(attrShow) then
            if LOG_INFO_ENABLED then
                printInfoNR("打印而已，莫慌    没有配置图片，attrShow 字段")
            end
        else
            local spriteAtlasPath = LxResPathUtil.GetSpriteAtlasPath(gLGameLanguage:GetResName(attrShow))
            if spriteAtlasPath then
                self:SetWndEasyImage(self.mGolemIcon,attrShow,function()
                    -- self:SetAnchorPos(self.mGolemIcon, LxDataHelper.ParseVector2NotEmpty(showPos))
                end,true)
            else
                CS.ShowObject(self.mGolemIcon,false)
            end
        end
    elseif showSpine then
        self:CreateWndSpine(self.mShowIconRoot,attrShow,attrShow,false)
    elseif showEffect then
        self:CreateWndEffect(self.mShowIconRoot,attrShow,attrShow,100,false,false,50)
    end
end

function UIGolemRecommend:InitGolemShowList()
    local list = self:GetGolemShowList()
    local uiGolemShowList = self._uiGolemShowList
    if uiGolemShowList then
        uiGolemShowList:RefreshList(list)
    else
        uiGolemShowList = self:GetUIScroll("uiGolemShowList")
        self._uiGolemShowList = uiGolemShowList
        uiGolemShowList:Create(self.mGolemShowList,list,function(...) self:OnDrawGolemShowCell(...) end)
    end
    uiGolemShowList:EnableScroll(#list > 4)
end

function UIGolemRecommend:OnDrawGolemShowCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"GolemBg/Icon")
    local posImgTrans = self:FindWndTrans(item,"posImg")
    local PosNameTrans = self:FindWndTrans(item,"PosName")
    local GolemNameTrans = self:FindWndTrans(item,"GolemName")
    local GoToBtnTrans = self:FindWndTrans(item,"GoToBtn")

    self:SetWndEasyImage(IconTrans,itemdata.icon,function()
        CS.ShowObject(IconTrans,true)
    end,true)

    local golemDrawing = itemdata.golemDrawing

    local icon = gModelGolem:GetGolemLocationIconByRefId(golemDrawing)
    self:SetWndEasyImage(posImgTrans,icon,function()
        CS.ShowObject(posImgTrans,true)
    end,true)

    local posStr = string.replace(ccClientText(33228),golemDrawing)
    self:SetWndText(PosNameTrans,posStr)

    self:SetWndText(GolemNameTrans,itemdata.name)

    local showBtn = false
    local jump = itemdata.jump
    if type(jump) == "string" then
        showBtn = not string.isempty(jump)
    else
        showBtn = jump and jump > 0
    end
    CS.ShowObject(GoToBtnTrans,showBtn)
    if showBtn then
        self:SetWndButtonText(GoToBtnTrans,ccClientText(33226))
    end
    self:SetWndClick(GoToBtnTrans,function()
        if gModelFunctionOpen:CheckIsOpened(jump) then
            gModelFunctionOpen:Jump(jump, self:GetWndName())
        end
    end)
end
------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemRecommend



