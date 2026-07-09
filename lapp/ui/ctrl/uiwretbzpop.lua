---
--- Created by Administrator.
--- DateTime: 2023/10/24 19:47:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWretBzPop:LWnd
local UIWretBzPop = LxWndClass("UIWretBzPop", LWnd)

UIWretBzPop.TYPE_HELP = 1
UIWretBzPop.TYPE_CONGRATULATION = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWretBzPop:UIWretBzPop()
    --0~9数字卡牌艺术字
    self._secretNumTextFormat = "<sprite index=%s>"

    --每个密码的遮挡数量
    self._coverMaxNum = 6
    self._secretMaxNum = 4
    self._numInputTransList = {}
    self._numSelectTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWretBzPop:OnWndClose()
    self._numInputTransList = {}
    self._numSelectTransList = {}
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWretBzPop:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWretBzPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitData()
    self:RefreshUI()
    self:InitStaticInfo()
end

function UIWretBzPop:OnClickSend()
    if self._popType == self.TYPE_HELP then
        self:SendTypeHelpFunc()
    elseif self._popType == self.TYPE_CONGRATULATION then
        self:SendTypeCongratulationFunc()
    end
    self:WndClose()
end

function UIWretBzPop:RefreshNumInputList()
    if table.isempty(self._numInputTransList) then
        return
    end

    local playInputNumList = self._playInputNumList
    local curSelectIndex = 0
    for k, v in ipairs(self._numInputTransList) do
        local curNum = playInputNumList[k]
        local numStr = ""
        if curNum > -1 then
            numStr = curNum
            curSelectIndex = k + 1
        end
        local numStr_2 = ""
        if (not string.isempty(numStr)) and checknumber(numStr) >= 0 then
            numStr_2 = string.format(self._secretNumTextFormat, numStr)
            self:SetWndText(v, numStr_2)
        end


    end

    curSelectIndex = math.range(curSelectIndex, 1, #self._numSelectTransList)
    for k, v in ipairs(self._numSelectTransList) do
        CS.ShowObject(v, self._isOpenNumInput and curSelectIndex == k)
    end
end

function UIWretBzPop:RefreshCardItemList()
    local coverUpCard = self._coverUpCard
    local passNumDataList = {}
    for k, v in ipairs(self._password) do
        local curCoverUpCars = {}
        local coverUpCardList = coverUpCard[k]
        if coverUpCardList then
            for q, p in ipairs(coverUpCardList) do
                curCoverUpCars[tonumber(p)] = true
            end
        end

        local data = {
            password = v,
            coverUpCars = curCoverUpCars,
        }

        table.insert(passNumDataList, data)
    end

    local uiList = self._cardItemList
    if (uiList) then
        uiList:RefreshList(passNumDataList)
    else
        uiList = self:GetUIScroll("cardItemList")
        self._cardItemList = uiList
        uiList:Create(self.mCardItemList, passNumDataList, function(...)
            self:OnDrawCardItemFunc(...)
        end)
    end
end

function UIWretBzPop:InitEvent()
    self:SetWndClick(self.mBgImage, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mBuyBtn, function()
        self:OnClickSend()
    end)


end

function UIWretBzPop:OnDrawCardItemFunc(list, item, itemdata, itempos)
    local numText = self:FindWndTrans(item, "NumText")
    local coverList = self:FindWndTrans(item, "CoverList")

    local coverUpCars = itemdata.coverUpCars
    local isShow = false
    local needCheckCoverUp = self._popType == self.TYPE_HELP
    for i = 1, self._coverMaxNum do
        local curCover = self:FindWndTrans(coverList, "Cover" .. i)
        if needCheckCoverUp then
            isShow = not coverUpCars[i]
        end
        CS.ShowObject(curCover, isShow)
    end

    local password = itemdata.password
    local numStr = string.format(self._secretNumTextFormat, password)
    self:SetWndText(numText, numStr)
end

function UIWretBzPop:SendTypeHelpFunc()
    local inputNums = self._playInputNumList
    for k, v in ipairs(inputNums) do
        if tonumber(v) < 0 then
            GF.ShowMessage(ccClientText(21908))
            return
        end
    end

    local playerInfo = self._playerInfo
    local isForeign = gLGameLanguage:IsForeignVersion()
    local sepStr = isForeign and "><" or "]["
    local numStr = table.concat(inputNums, sepStr)
    local playerId = playerInfo.playerId
    local isSelf = playerId == gModelPlayer:GetPlayerId()
    local type = ModelChat.MSGTYPE_NORMAL
    local playerName = playerInfo.name
    local taStr = ""
    if not isSelf then
        taStr = "@" .. playerName .. "  "
        type = ModelChat.MSGTYPE_AT
    end

    local sendStr = taStr .. string.replace(ccClientText(21917), numStr)
    local _currChannel = playerInfo.channel
    local serverId = playerInfo.serverId

    gModelChat:OnChatMsgReq(_currChannel, type, sendStr, playerId, playerName, nil, serverId)
end

function UIWretBzPop:OnDrawNumItemFunc(list, item, itemdata, itempos)
    local nameText = self:FindWndTrans(item, "Text")
    local selectImg = self:FindWndTrans(item, "SelectImg")

    self:SetWndClick(item, function()
        self:OnClickNumText(itempos)
    end)
    self._numInputTransList[itempos] = nameText
    self._numSelectTransList[itempos] = selectImg

    if itempos >= #self._playInputNumList then
        self:RefreshNumInputList()
    end
end

function UIWretBzPop:OnClickNumText()
    local min, max = 0, self._secretMaxNum
    local default = ""
    for k, v in ipairs(self._playInputNumList) do
        if v >= 0 then
            default = default .. v
        end
    end

    local func = function(input, cmd)
        if cmd == "D" then
            --关闭键盘
            self._isOpenNumInput = false
            self:RefreshNumInputList()
            return
        end

        local inputLen = string.len(input)
        for k, v in ipairs(self._playInputNumList) do
            if k <= inputLen then
                self._playInputNumList[k] = tonumber(string.sub(input, k, k))
            else
                self._playInputNumList[k] = -1
            end
        end

        self:RefreshNumInputList()
    end

    self._isOpenNumInput = true
    self:RefreshNumInputList()
    GF.OpenWndUp("UINuoardUI",
            { minNum = min, maxNum = max, defaultNum = default, inputFunc = func,
              inputTran = self.mKeyRoot, inputType = 1 })
end

function UIWretBzPop:InitStaticInfo()
    local titleStr
    local descStr
    local btnStr
    if self._popType == self.TYPE_HELP then
        titleStr = ccClientText(21913)
        descStr = ccClientText(21914)
        btnStr = ccClientText(21915)
    elseif self._popType == self.TYPE_CONGRATULATION then
        titleStr = string.replace(ccClientText(21922), self._useConsumeNum, self._curDay)
        descStr = ""
        btnStr = ccClientText(21931)
    end

    self:SetWndText(self.mTitleText, titleStr)
    self:SetWndText(self.mDecodeNumText, descStr)
    self:InitTextLineWithLanguage(self.mDecodeNumText, -30)
    self:SetWndButtonText(self.mBuyBtn, btnStr)

    self:SetWndText(self.mTitle, ccClientText(45017))

    self:SetWndText(self.mCloseTip, ccClientText(10103))
end

function UIWretBzPop:InitNumList()
    local isShow = self._popType == self.TYPE_HELP
    CS.ShowObject(self.mNumList, isShow)
    if not isShow then
        return
    end

    local itemsList = self._playInputNumList
    local uiList = self._numInputList
    if (uiList) then
        uiList:RefreshList(itemsList)
    else
        uiList = self:GetUIScroll("numList")
        self._numInputList = uiList
        uiList:Create(self.mNumList, itemsList, function(...)
            self:OnDrawNumItemFunc(...)
        end)
    end

end

function UIWretBzPop:InitData()
    self._popType = self:GetWndArg("popType")
    local passwordStr = self:GetWndArg("passwordStr")
    local coverUpCardStr = self:GetWndArg("coverUpCardStr")
    self._useConsumeNum = self:GetWndArg("useConsumeNum") or 0
    self._curDay = self:GetWndArg("curDay") or 1
    self._playerInfo = self:GetWndArg("playerInfo")

    --玩家输入的解密数字列表, 默认显示上为空
    self._playInputNumList = {
        -1, -1, -1, -1,
    }

    self._password = string.split(passwordStr, '|')
    self._coverUpCard = {}
    if self._popType == self.TYPE_HELP then
        local coverUpCards = string.split(coverUpCardStr, ';')
        local numIndex, cardIndexList
        for j, g in ipairs(coverUpCards) do
            local cardData = string.split(g, '=')
            numIndex = tonumber(cardData[1])
            cardIndexList = cardData[2]
            self._coverUpCard[numIndex] = string.split(cardIndexList, '|')
        end
    end
end

function UIWretBzPop:SendTypeCongratulationFunc()
    local playerInfo = self._playerInfo
    local playerId = playerInfo.playerId
    local playerName = playerInfo.name
    local isSelf = playerId == gModelPlayer:GetPlayerId()
    local type = ModelChat.MSGTYPE_NORMAL
    local taStr = ""
    if not isSelf then
        taStr = "@" .. playerName .. "  "
        type = ModelChat.MSGTYPE_AT
    else
        playerName = ccClientText(21929)
    end

    local sendStr = taStr .. string.replace(ccClientText(21928), playerName, self._curDay)
    local _currChannel = playerInfo.channel
    local serverId = playerInfo.serverId

    gModelChat:OnChatMsgReq(_currChannel, type, sendStr, playerId, playerName, nil, serverId)
end

function UIWretBzPop:RefreshUI()

    self:RefreshCardItemList()
    self:InitNumList()
end

------------------------------------------------------------------
return UIWretBzPop



