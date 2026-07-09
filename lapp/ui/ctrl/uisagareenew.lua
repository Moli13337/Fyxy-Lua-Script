---
--- Created by LCM.
--- DateTime: 2024/3/16 16:03:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaReeNew:LWnd
local UISagaReeNew = LxWndClass("UISagaReeNew", LWnd)

UISagaReeNew.BTN_TYPE_CULTIVATE = 1            --- 共鸣养成
UISagaReeNew.BTN_TYPE_CONTRACT = 2            --- 星灵契约
UISagaReeNew.BTN_TYPE_MAGIC = 3                --- 共鸣魔晶
-- UISagaReeNew.BTN_TYPE_MAPPING = 4			--- 养成映射【G公共支持】删除伙伴链接功能

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaReeNew:UISagaReeNew()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaReeNew:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaReeNew:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaReeNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitTabData()
    self:InitTabList()

    self:InitBtnTransInfoList()
    self:InitBotInfoList()
    self:InitEvent()
    self:InitMsg()
    self:OnWndRefresh()

    self:SetWndText(self.mTxtClose, ccClientText(30205))
end

function UISagaReeNew:InitBtnTransInfoList()
    local btnList = {
        {
            btnRoot = self.mCultivateBtn,
            btnName = ccClientText(31202),
            functionId = 0,
            btnType = UISagaReeNew.BTN_TYPE_CULTIVATE,
        },
        {
            btnRoot = self.mContractBtn,
            btnName = ccClientText(31201),
            functionId = 16503000,
            btnType = UISagaReeNew.BTN_TYPE_CONTRACT,
        },
        {
            btnRoot = self.mMagicBtn,
            btnName = ccClientText(31200),
            functionId = 0,
            btnType = UISagaReeNew.BTN_TYPE_MAGIC,
        },

    }
    -- 【G公共支持】删除伙伴链接功能
    -- local isShowMappingBtn = gModelFunctionOpen:CheckIsShow(16504000)
    -- if(isShowMappingBtn)then
    -- 	local mappingBtnData = {
    -- 		btnRoot = self.mMappingBtn,
    -- 		btnName = ccClientText(38400),
    -- 		functionId = 16504000,
    -- 		btnType = UISagaReeNew.BTN_TYPE_MAPPING,
    -- 	}
    -- 	table.insert(btnList,mappingBtnData)
    -- end
    local initBtnTransInfoList = {}
    for i, v in ipairs(btnList) do
        local btnTransInfo = self:GetBtnTransInfo(v)
        table.insert(initBtnTransInfoList, btnTransInfo)
    end
    self._initBtnTransInfoList = initBtnTransInfoList
end

function UISagaReeNew:RefreshAllRedPoint()
    local initBtnTransInfoList = self._initBtnTransInfoList
    if not initBtnTransInfoList then
        return
    end
    local redPointBtnFuncList = self._redPointBtnFuncList
    if not redPointBtnFuncList then
        return
    end

    local btnType, redPointFunc
    for i, v in ipairs(initBtnTransInfoList) do
        btnType = v.btnType
        redPointFunc = redPointBtnFuncList[btnType]
        local showRedPoint = redPointFunc and redPointFunc() or false
        CS.ShowObject(v.redPointTrans, showRedPoint)
    end
end

function UISagaReeNew:InitTabList()
    self._tabList = {}

    local uiList = self:GetUIScroll("UISagaReeNewTab")

    if #self._tabData > 1 then
        uiList:Create(self.mTabScroll, self._tabData, function(...)
            self:OnDrawTab(...)
        end)
        self._tabUiList = uiList

        self._curTabIndex = UISagaReeNew.BTN_TYPE_MAGIC

    end
end

function UISagaReeNew:InitEvent()
    --返回按钮
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaReeNew:InitMsg()
    self:WndNetMsgRecv(LProtoIds.ResonanceInfoResp, function()
        self:RefreshAllRedPoint()
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:InitBtnTransInfoList()
        self:RefreshBotBtn()
        self:RefreshAllRedPoint()
    end)
end

function UISagaReeNew:GetBtnTransInfo(btnInfo)
    local btnRoot = btnInfo.btnRoot
    local selBgTrans = self:FindWndTrans(btnRoot, "SelBg")
    local noSelIconTrans = self:FindWndTrans(btnRoot, "NoSelIcon")
    local noSelTxtTrans = self:FindWndTrans(noSelIconTrans, "NoSelTxt")
    local selIconTrans = self:FindWndTrans(btnRoot, "SelIcon")
    local selTxtTrans = self:FindWndTrans(selIconTrans, "SelTxt")
    local lockTrans = self:FindWndTrans(btnRoot, "Lock")
    local redPointTrans = self:FindWndTrans(btnRoot, "redPoint")

    local btnName = btnInfo.btnName
    self:SetWndText(noSelTxtTrans, btnName)
    self:InitTextLineWithLanguage(noSelTxtTrans, -30)

    self:SetWndText(selTxtTrans, btnName)
    self:InitTextLineWithLanguage(selTxtTrans, -30)

    local btnType = btnInfo.btnType
    self:SetWndClick(btnRoot, function()
        self:OnClickBotBtnFunc(btnType)
    end)

    local functionId = btnInfo.functionId
    local isOpen, isShow = true, true
    if functionId ~= 0 then
        isOpen = gModelFunctionOpen:CheckIsOpened(functionId)
        isShow = isOpen or gModelFunctionOpen:CheckIsShow(functionId)
        CS.ShowObject(btnRoot, isShow)
    end
    CS.ShowObject(lockTrans, not isOpen)

    return {
        btnRoot = btnRoot,
        selBgTrans = selBgTrans,
        noSelIconTrans = noSelIconTrans,
        selIconTrans = selIconTrans,
        lockTrans = lockTrans,
        redPointTrans = redPointTrans,
        functionId = btnInfo.functionId,
        btnType = btnType,
    }
end

function UISagaReeNew:ShowContent()
    local page = self._page
    if not page then
        page = UISagaReeNew.BTN_TYPE_MAGIC
    end

    local initBtnTransInfoList = self._initBtnTransInfoList or {}
    for i, v in ipairs(initBtnTransInfoList) do
        local isSel = v.btnType == page
        CS.ShowObject(v.noSelIconTrans, not isSel)
        CS.ShowObject(v.selIconTrans, isSel)
        CS.ShowObject(v.selBgTrans, isSel)
    end

    local btnFunc = self._btnFuncList[page]
    if btnFunc then
        btnFunc()

        if self._tabList then
            self:SetWndTabStatus(self._tabList[page], 0, page)

        end
    end
end

function UISagaReeNew:OnClickBotBtnFunc(btnType)
    if btnType == self._page then
        return
    end
    -- 【G公共支持】删除伙伴链接功能
    -- if(btnType == UISagaReeNew.BTN_TYPE_MAPPING)then
    -- 	local isOpen = gModelFunctionOpen:CheckIsOpened(16504000,true)
    -- 	if(not isOpen)then
    -- 		return
    -- 	end
    -- end
    self._page = btnType
    self:RefreshView()
end

function UISagaReeNew:RefreshBotBtn()
    local page = self._page
    if not page then
        page = UISagaReeNew.BTN_TYPE_MAGIC
    end

    local initBtnTransInfoList = self._initBtnTransInfoList or {}
    for i, v in ipairs(initBtnTransInfoList) do
        local isSel = v.btnType == page
        CS.ShowObject(v.noSelIconTrans, not isSel)
        CS.ShowObject(v.selIconTrans, isSel)
        CS.ShowObject(v.selBgTrans, isSel)
    end
end

function UISagaReeNew:OnDrawTab(list, item, itemData, index)
    self:SetWndTabText(item, itemData.name, nil, true)
    self:SetWndTabStatus(item, 1)
    self._tabList[itemData.btnType] = item
    self:SetWndClick(item, function(...)
        self:CloseAllChild()
        itemData.clickFunc()
        self:DoChangeTab(itemData.btnType)
    end)

    --local funcRed =function (isShow)
    --    local RedPoint=self:FindWndTrans(item,"redPoint")
    --    CS.ShowObject(RedPoint,isShow)
    --end
    --self:RegisterRedPointFunc(itemData.redId,funcRed)

    local offTrans = CS.FindTrans(item, "Off")
    local onTrans = CS.FindTrans(item, "On")
    self:SetWndEasyImage(offTrans, itemData.offIcon)
    self:SetWndEasyImage(onTrans, itemData.onIcon)
end

function UISagaReeNew:InitBotInfoList()
    self._btnFuncList = {
        [UISagaReeNew.BTN_TYPE_CULTIVATE] = function()

        end,
        [UISagaReeNew.BTN_TYPE_CONTRACT] = function()
            --- 星灵契约
            self:CreateChildWnd(self.mChildRoot, "UISubReeContract", { subPage = self._subPage })
        end,
        [UISagaReeNew.BTN_TYPE_MAGIC] = function()
            --- 共鸣水晶
            self:CreateChildWnd(self.mChildRoot, "UISubReeMic", { subPage = self._subPage })
        end,
        -- 【G公共支持】删除伙伴链接功能
        -- [UISagaReeNew.BTN_TYPE_MAPPING] = function()
        -- 	--- 养成映射
        -- 	self:CreateChildWnd(self.mChildRoot,"WndChildResonanceMapping",{subPage = self._subPage})
        -- end,
    }
    self._redPointBtnFuncList = {
        [UISagaReeNew.BTN_TYPE_CULTIVATE] = function()
            return false
        end,
        [UISagaReeNew.BTN_TYPE_CONTRACT] = function()
            return false
        end,
        [UISagaReeNew.BTN_TYPE_MAGIC] = function()
            return gModelResonance:CheckBreakRedPoint()
        end,
        -- 【G公共支持】删除伙伴链接功能
        -- [UISagaReeNew.BTN_TYPE_MAPPING] = function()
        -- 	return gModelResonance:CheckMappingRedPoint()
        -- end,
    }
end

function UISagaReeNew:OnWndRefresh()
    self:InitData()
    self:RefreshView()
    self:RefreshAllRedPoint()
end

function UISagaReeNew:RefreshView()
    self:CloseAllChild()
    self:ShowContent()
end

function UISagaReeNew:DoChangeTab(btnType)
    --if self._curTabIndex == index then
    --    return
    --end
    local oldIndex = self._curTabIndex
    self._curTabIndex = btnType
    self:SetWndTabStatus(self._tabList[oldIndex], 1, oldIndex)
    self:SetWndTabStatus(self._tabList[btnType], 0, btnType)

    --self:CloseChildByName(self._tabDatas[oldIndex].uiName)
    --self:CreateChildWnd(self.mChildRoot, self._tabDatas[index].uiName)
end

--region tabBtn --------------------------------------------------------------------------------
function UISagaReeNew:InitTabData()
    local tempData = {
        { name = ccClientText(31201), functionId = 16503000, onIcon = "resonance__tab2", offIcon = "resonance__tab2", clickFunc = function()
            --- 星灵契约
            self:CreateChildWnd(self.mChildRoot, "UISubReeContract", { subPage = self._subPage })
         end, btnType = UISagaReeNew.BTN_TYPE_CONTRACT },
        { name = ccClientText(31200), functionId = 0, onIcon = "mainui_btn_5", offIcon = "mainui_btn_5", clickFunc = function()
            --- 共鸣水晶
            self:CreateChildWnd(self.mChildRoot, "UISubReeMic", { subPage = self._subPage })
        end, btnType = UISagaReeNew.BTN_TYPE_MAGIC },
    }

    self._tabData = {}
    for k, v in ipairs(tempData) do
        if v.functionId > 0 then
            local isOpen = gModelFunctionOpen:CheckIsOpened(v.functionId)
            local isShow = isOpen or gModelFunctionOpen:CheckIsShow(v.functionId)

            if isShow then
                table.insert(self._tabData, v)
            end
        else
            table.insert(self._tabData, v)
        end
    end
end

function UISagaReeNew:InitData()
    local page = self:GetWndArg("page")
    if not page then
        page = UISagaReeNew.BTN_TYPE_MAGIC
    end
    self._page = page

    local subPage = self:GetWndArg("subPage")
    self._subPage = subPage
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISagaReeNew


