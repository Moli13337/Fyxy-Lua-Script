---
--- Created by y.
--- DateTime: 2025/2/13 17:20:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWGLDebug:LWnd
local UIWGLDebug = LxWndClass("UIWGLDebug", LWnd)
local typeof = typeof

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWGLDebug:UIWGLDebug()
    self._resultList = {}
    self._typeToNameMap = {}

    self._delayUpdateScrollTimer = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWGLDebug:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWGLDebug:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWGLDebug:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:InitEvent()
    self:InitGroupList()
    self:InitShowCmd()
end

function UIWGLDebug:InitData()
    local groupKeys = { "common" }
    self._groupKeys = groupKeys
    self._groupMaps = {}

    local commons = {
        { type = 1, showname = "游戏渲染数据", command = "GetGameData" },
        --{ type = 2, showname = "ab包当前内存", command = "abMemory" },
        { type = 3, showname = "上报测试", command = "report" },
        { type = 4, showname = "打印开关", command = "logSet" },
        { type = 5, showname = "游戏配置", command = "gameSettingConfig" },
        { type = 6, showname = "打开界面", command = "openView" },
    }
    self._groupMaps["common"] = { key = "common", name = "常用", datas = commons }

    local cmdDataFinder = {}
    local typeData = {}
    for k, v in pairs(self._groupMaps) do
        local isFinder = not v.excludeFinder
        if v.datas then
            for m, data in ipairs(v.datas) do
                if isFinder then
                    table.insert(cmdDataFinder, data)
                end
                typeData[data.type] = data
            end
        end
    end

    self._cmdDataFinder = cmdDataFinder
    self._cmdTypeToData = typeData

    local nameToType = {}
    self._nameToType = nameToType

end

function UIWGLDebug:ShowMessage(str)
    self:SetWndText(self.mMsgTxt, str)
end

function UIWGLDebug:OnSelectGroup(groupKey)
    self._curGroup = groupKey
    if self._uiGroupList then
        self._uiGroupList:DrawAllItems()
    end
    local gpData = self._groupMaps[groupKey]
    local cmdList
    local dataExecute = gpData.dataExecute
    if dataExecute then
        local func = self[dataExecute]
        if func then
            cmdList = func(self)
        end
    else
        cmdList = gpData.datas
    end

    self:ShowCmdList(cmdList or {})
end

function UIWGLDebug:InitShowCmd()
    local gpKey = "common"
    self:OnSelectGroup(gpKey)
end

function UIWGLDebug:InitEvent()
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end)
end

function UIWGLDebug:OnClickGroup(groupKey)
    local data = self._groupMaps[groupKey]
    if not string.isempty(data.execute) then
        local func = self[data.execute]
        if func ~= nil then
            func(self)
        end
        return
    end
    self:OnSelectGroup(groupKey)
end

function UIWGLDebug:ShowMessage(str)
    self:SetWndText(self.mMsgTxt, str)
end

function UIWGLDebug:OnDrawGroup(list, item, itemdata, itempos)
    local btnTrans = self:FindWndTrans(item, "Btn")
    local data = self._groupMaps[itemdata]
    if not data then
        return
    end
    self:SetWndButtonText(btnTrans, data.name)
    self:SetWndClick(item, function()
        self:OnClickGroup(itemdata)
    end)
    local isOn = self._curGroup == itemdata
    self:SetWndButtonGray(btnTrans, not isOn)
end

function UIWGLDebug:InitGroupList()
    ---@type UIItemList
    local groupList = self._uiGroupList
    if not groupList then
        groupList = self:GetUIScroll("_uiGroupList")
        self._uiGroupList = groupList
        groupList:Create(self.mCmdGroupList, {}, function(...)
            self:OnDrawGroup(...)
        end, UIItemList.SUPER)
    end
    local uiList = groupList:GetList()
    uiList:RemoveAllData()
    for k, v in ipairs(self._groupKeys) do
        uiList:AddData(k, v)
    end
    uiList:RefreshList()
    groupList:DrawAllItems()
end

function UIWGLDebug:OnDrawCommandTextItem(list, item, itemdata, itempos, fromHeadTail)
    local textTrans = CS.FindTrans(item, "UIText")
    self:SetWndText(textTrans, itemdata.showname)
end

function UIWGLDebug:OnDrawCommandItem(list, item, itemdata, itempos, fromHeadTail)
    self:OnDrawCommandTextItem(list, item, itemdata, itempos, fromHeadTail)
    self:SetWndClick(item, function(...)
        self:OnClickCommand(itemdata)
    end)
end

function UIWGLDebug:IsAutoLangFont()
    return false
end

function UIWGLDebug:OnClickCommand(cmdData)
    self._selCmdData = cmdData
    local cmd = string.split(cmdData.command, " ")[1]
    local args = string.gsub(cmdData.command, cmd, "")
    args = string.split(string.trim(args), " ")
    self._selCmdStr = cmd
    self._selArgs = args
    self._selId = cmdData.sel
    --gprint("OnClickCommand", cmd)

    local msg
    local value
    local inputStr = self.mSearchCmdInput.text
    if cmd == "GetGameData" then
        local gameData = CS.GameUtil.GetCsValue(CsValueType.GetGameData)
        msg = "游戏渲染数据："
        local descList = { "wasm内存", "纹理内存", "纹理数量", "ab包内存", "ab包数量" }
        local descLen = #descList
        for i = 0, gameData.Length - 1 do
            local value = gameData[i]
            msg = msg .. "\n"
            if i < descLen then
                msg = msg .. descList[i + 1] .. "："
            end
            msg = msg .. value
        end
        --elseif cmd == "abMemory" then
        --    if gLGameMemory then
        --        value = gLGameMemory.assetBundleTotalMemory
        --        msg = "ab包当前内存值：" .. value
        --    end
        gprint("gameData", msg)
    elseif cmd == "report" then
        value = inputStr or "report"
        local time = LUtil.OSDate("%Y-%m-%d %H:%M:%S", GetTimestamp())
        msg = "上报数据：" .. value .. " " .. time
        LxUnity.CallCsFun(CsFunType.Report, { value, time })
    elseif cmd == "logSet" then
        value = inputStr or ""
        local open
        local str = "关闭"
        if value ~= "" then
            open = true
            str = "开启"
        end
        ccLog.logEnabled = open
        msg = "打印开关数据：" .. str
    elseif cmd == "gameSettingConfig" then
        local gameSettings = PJXCenter.GameMgr.GameSettings
        local settingVars = gameSettings.gameSettingVars
        local str = "settingVars :"
        if settingVars then
            local iter = settingVars:GetEnumerator()
            while iter:MoveNext() do
                local varObj = iter.Current
                if varObj ~= nil then
                    str = str .. varObj.varName .. " = " .. varObj.varVal .. "\n"
                end
            end
        end
        msg = "游戏配置" .. str
        LogWarn(str)
    elseif cmd == "openView" then
        if string.isempty(inputStr) then
            LogWarn("打开界面,界面名称为空：" .. inputStr)
            return
        end
        GF.OpenWnd(inputStr)
        msg = "打开界面" .. inputStr
    end

    if msg then
        gprint("OnClickCommand click", value)
        self:ShowMessage(msg)
    end
end

function UIWGLDebug:ShowCmdList(cmdList)

    local list = self._uicmdList
    if not list then
        list = self:GetUIScroll("_uiCmdList")
        self._uicmdList = list
        list:Create(self.mListCommander, cmdList, function(...)
            self:OnDrawCommandItem(...)
        end, UIItemList.SUPER_GRID)
    else
        list:RefreshList(cmdList)
    end
    list:DrawAllItems()
end

------------------------------------------------------------------
return UIWGLDebug