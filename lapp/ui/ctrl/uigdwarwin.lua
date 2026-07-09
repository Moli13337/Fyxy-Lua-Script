---
--- Created by BY.
--- DateTime: 2023/10/30 17:23:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdWarWin:LWnd
local UIGdWarWin = LxWndClass("UIGdWarWin", LWnd)
local typeof = typeof
local typeof_LayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdWarWin:UIGdWarWin()
    self._meleeTime = "meleeTime"		--倒计时
    self._oneRefreshKey = "oneRefreshKey"
    self._logIndexKey = "logIndexKey"

	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdWarWin:OnWndClose()
	if self._uiIconEasyList then
		self._uiIconEasyList:Destroy()
		self._uiIconEasyList =nil
	end
    self:IsShowBarrage(false)
    self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdWarWin:OnCreate()
	LWnd.OnCreate(self)
    self._tabTranss = {}
    self._applyTranss = {}
    self._applyTabEvList = {}
    self._logTranss = {}
    self._logTabEvList = {}
    self._uiheadList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdWarWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    self._reachTail = true

	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

    local inGuide = gModelGuide:IsInGuide()
    if inGuide then
        return
    end

    local call = gModelGuildMelee:GetEffectWndCall()
    if call then
        call()
    end
end

function UIGdWarWin:IsShowBarrage(bool)
	if(bool)then
        gModelGeneral:OpenBarrage({channel = ModelChat.CHANNEL_WAR})
	else
		GF.CloseWndByName("UIBulletSay")
	end
end
function UIGdWarWin:ChangeTab(trans,bool)
    local state = bool and 0 or 1
    self:SetWndTabStatus(trans, state)
end
--布阵
function UIGdWarWin:OnClickFormation()
    local _meleeInfo = self._meleeInfo
    if _meleeInfo.state == ModelGuildMelee.STATE_PREPARE or _meleeInfo.state == ModelGuildMelee.STATE_Melee then
        GF.ShowMessage(ccClientText(17954))
        return
    end
    --gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_WAR,{guildMeleeState = true})
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_WAR)
end

function UIGdWarWin:OnClickClose()
    GF.OpenWnd("UIGdWin")
    self:WndClose()
end


function UIGdWarWin:InitEvent()
	--self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mHelpBtn, function(...) self:OnClickHelp() end)
	self:SetWndClick(self.mBarrageInputBtn,function () self:OnClickBarrageInput() end)
	self:SetWndClick(self.mFormationBtn,function () self:OnClickFormation() end)
	self:SetWndClick(self.mApplyBtn1,function () self:OnClickApply() end)
    self:SetWndClick(self.mApplyBtn2,function () self:OnClickApply() end)
    self:SetWndClick(self.mRankBtn,function () self:OnClickRank() end)
    self:SetWndClick(self.mAwardBtn,function () self:OnClickRankAward() end)
    self:SetWndClick(self.mShopBtn,function () self:OnClickShop() end)
end
--点击标签
function UIGdWarWin:OnClickTab(tab)
    if(self._tab)then
        local trans = self._tabTranss[self._tab]
        self:ChangeTab(trans,false)
    end
    local trans = self._tabTranss[tab]
    self:ChangeTab(trans,true)
    self._tab = tab
    self:RefreshData()
end

function UIGdWarWin:ReqApplyTypeMsg(maxSeq)
    gModelGuildMelee:OnGuildMeleeSignUpInfoListReq(maxSeq,2)
end

function UIGdWarWin:OnSetPlayerABInfo(trans,info)
    local resultIcon = CS.FindTrans(trans,"ResultIcon")
    local resultText = CS.FindTrans(trans,"ResultText")
    local guildText = CS.FindTrans(trans,"GuildText")
    local nameText = CS.FindTrans(trans,"NameText")
    local headIcon = CS.FindTrans(trans,"HeadIcon")
    local powerText = CS.FindTrans(trans,"PowerText")

    CS.ShowObject(resultIcon,true)
    CS.ShowObject(resultText,false)
    local serverName = gModelFriend:GetSevenName(info.serverId)
    local guildName = ""
    if info.guildId == gModelPlayer:GetGuildId() then
        guildName = string.replace(ccClientText(17956),info.guildName,serverName)
    else
        guildName = string.replace(ccClientText(17957),info.guildName,serverName)
    end
    local playerName = ""
    if info.playerId == gModelPlayer:GetPlayerId() then
        playerName = string.replace(ccClientText(17958),info.name)
    else
        playerName = info.name
    end
    self:SetWndText(guildText,guildName)
    self:SetWndText(nameText,playerName)
    self:SetWndText(powerText,LUtil.PowerNumberCoversion(info.power))

    local winIcon
    if(info.win)then
        winIcon = "kf_ladder_txt_3"
        if info.winCount > 1 then
            CS.ShowObject(resultText,true)
            local winCount = LUtil.FormatHurtNumSpriteText(info.winCount)
            self:SetWndText(resultText,winCount)
            CS.ShowObject(resultIcon,false)
        end
    else
        winIcon = "kf_ladder_txt_4"
    end
    self:SetWndEasyImage(resultIcon,winIcon)

    local InstanceID = trans:GetInstanceID()
    local uiheadlist = self._uiheadList
    local baseClass = uiheadlist[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = baseClass
    end
    info.trans = headIcon
    baseClass:SetHeadData(info)
    self:SetWndClick(headIcon, function (...)
        self:OnClickPlayer(info.playerId)
    end)
end

function UIGdWarWin:OnClickRankAward()
    GF.OpenWndBottom("UIGdWarAward")
end

function UIGdWarWin:RefreshApply()
    if(self._tab == 2)then
        return
    end
    self:RefreshApplyList()
end

function UIGdWarWin:SetTextFontSizeAndStr(textTrans, str)
    if not (CS.IsValidObject(textTrans) and str) then
        return
    end

    self:SetWndText(textTrans,str)
    self:InitTextSizeWithLanguage(textTrans, -2)
    self:InitTextLineWithLanguage(textTrans, -30)
end

function UIGdWarWin:OnClickBarrageInput()
	--if(not self._isBarrageShow)then
	--	GF.ShowMessage(ccClientText(17608))
	--	return
	--end
    local para = {channel = ModelChat.CHANNEL_WAR,isShow = self._isBarrageShow}
    gModelChat:OnClickOpentBarrageWin(para)
end

function UIGdWarWin:OnClickLogTab(logTab)

    local _index = 0
    for i, v in pairs(self._logTabEvList) do
        if(v)then
            _index = i
        end
    end
    if(_index>0)then
        local trans = self._logTranss[_index]
        self:ChangeLogTab(trans,false,_index)
    end
    if(_index == logTab)then
        return
    end
    local trans = self._logTranss[logTab]
    self:ChangeLogTab(trans,true,logTab)
end

function UIGdWarWin:applyTypeListItem(list,item, itemdata, itempos)
    local nameText = CS.FindTrans(item,"NameText")
    local lvText = CS.FindTrans(item,"LvText")
    local numText = CS.FindTrans(item,"NumText")
    local powerText = CS.FindTrans(item,"PowerText")

    local type = itemdata.type
    local name,lv,num,power
    local color = "<color=#30e055>%s</color>"
    if(type == ModelGuildMelee.SIGNUP_GUILD)then
        name,lv,num,power = itemdata.guildName,itemdata.level,itemdata.signUpCount,itemdata.powerCount
        num = string.replace(color,num)
    elseif(type == ModelGuildMelee.SIGNUP_MEMBER)then
        name = itemdata.time
        lv,num,power = itemdata.name,itemdata.level,itemdata.power
        local formatStr = ccClientText(17938)
        name = LUtil.OSDate(formatStr,tonumber(name)/1000)
        lv = string.replace(color,lv)
    end
    self:SetWndText(nameText,name)
    self:SetWndText(lvText,lv)
    self:SetWndText(numText,num)
    self:SetWndText(powerText,LUtil.PowerNumberCoversion(power))
    self:SetWndClick(item,function ()
        if(type == ModelGuildMelee.SIGNUP_GUILD)then
            self:OnClickApplyGuildCell(itemdata.guildId,itemdata.serverId)
        elseif(type == ModelGuildMelee.SIGNUP_MEMBER)then
            self:OnClickPlayer(itemdata.playerId)
        end
    end)
end
--空列表
function UIGdWarWin:CreateEmptyShow(refId,trans)
    local icon = CS.FindTrans(trans,"EmptyIcon")
    local bg = CS.FindTrans(trans,"EmptyTextBg")
    local text = CS.FindTrans(trans,"EmptyText")
    local data = {
        refId = refId,
        IconTran = icon,
        TextBgTran = bg,
        IntroTran = text,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIGdWarWin:RecordReportInfo(reportInfo)
    if not self._recordReportList then
        self._recordReportList = {}
    end

    table.insert(self._recordReportList,reportInfo)

end

function UIGdWarWin:SetTime()
    local info = self._meleeInfo
    if not info then
        return
    end
    local state = info.state
    local startTime = tonumber(info.startTime)/1000
    local sevenTime =  GetTimestamp()
    local timespan = startTime - sevenTime
    if timespan < 0 then
        self:TimerStop(self._meleeTime)
        return
    end
    local desStr,timeStr
    if state == 1 or state == 2 then
        desStr = ccClientText(17901)
        timeStr = string.replace(ccClientText(17965),LUtil.FormatTimespanThreeCn(timespan))
    elseif state == 3 then
        local signUpGuildCount = info.signUpGuildCount
        desStr = string.replace(ccClientText(17937),LUtil.FormatTimespanCn(timespan))
        timeStr = string.replace(ccClientText(17907),signUpGuildCount)
    elseif state == 4 then
        local signUpGuildCount = info.signUpGuildCount
        desStr = string.replace(ccClientText(17906),LUtil.FormatTimespanCn(timespan))
        timeStr = string.replace(ccClientText(17907),signUpGuildCount)
    end
    self:SetWndText(self.mTimeDesText,desStr)
    self:SetWndText(self.mTimeText,timeStr)
end
--报名
function UIGdWarWin:OnClickApply()
    local bool = gModelGuildMelee:GetIsBoolApply()
    if not bool then
        return
    end
    if self._meleeInfo.signUpPlayerState == 1 then
        GF.OpenWnd("UIOrdinTip",{refId = 100102,func = function (...)
            local bool = gModelGuildMelee:GetIsBoolApply()
            if not bool then
                return
            end
            gModelGuildMelee:OnGuildMeleeSignUpReq()
        end })
    else
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_GUILD_WAR,{guildMeleeState = true})
    end
end
--标签cell
function UIGdWarWin:TabListItem(list,item, itemdata, itempos)
    local btnTab = CS.FindTrans(item,"BtnTab1")
    self:SetWndTabText(btnTab,itemdata.name)
    self:SetWndTabStatus(btnTab, 1)
    self:SetWndTabTextLine(btnTab, -50)
    self._tabTranss[itempos] = btnTab

    self:SetWndClick(item,function ()
        if(self._tab and self._tab == itempos)then
            return
        end
        self._subPage = 1
        self._reachTail = true
        self:OnClickTab(itempos)
    end)
end

function UIGdWarWin:OnClickPlayer(_playerId)
    if not _playerId then
        return
    end
    gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIGdWarWin:RefreshData()
    CS.ShowObject(self.mAwardPage,false)
    CS.ShowObject(self.mApplyPage,false)
    CS.ShowObject(self.mLogPage,false)
    --self._meleeInfo = gModelGuildMelee:GetGuildMeleeInfo()
    local _meleeInfo = self._meleeInfo
    if not _meleeInfo then
        return
    end
    local isApply = _meleeInfo.state >= ModelGuildMelee.STATE_APPLY and _meleeInfo.signUpPlayerState == 1
    CS.ShowObject(self.mApplyBtn1,not isApply)
    CS.ShowObject(self.mApplyBtn2,isApply)
    self:SetWndButtonGray(self.mApplyBtn1,_meleeInfo.state ~= 3)
    self:SetWndButtonGray(self.mApplyBtn2,_meleeInfo.state ~= 3)
    self:SetWndButtonGray(self.mFormationBtn,self._meleeInfo.state == 4 or self._meleeInfo.state == 5)
    if(self._tab == 1)then
        self:RefreshApplyList()
    else
        self:RefreshALogList()
    end
end

function UIGdWarWin:LogListItem(list,item, itemdata, itempos)
    self._logTranss[itempos] = item
    local image = CS.FindTrans(item,"Image")
    local text = CS.FindTrans(item,"Image/NameText")
    local root = CS.FindTrans(item,"Root")
    local csLayoutElement = root:GetComponent(typeof_LayoutElement)
    if(csLayoutElement)then
        local height = self.mLogPage.rect.height
        csLayoutElement.minHeight = height - 48 * 3 + 4
    end
    self:SetWndText(text,itemdata.name)
    self:SetWndClick(image,function ()
        --if self._oldLogTab and self._oldLogTab == itempos then
        --    return
        --end
        self._logIsLookMsg = true
        --self._isOneRefresh = false
        self._reachTail = true
        self:OnClickLogTab(itempos)
    end)
end

function UIGdWarWin:applyListItem(list,item, itemdata, itempos)
    self._applyTranss[itempos] = item
    local image = CS.FindTrans(item,"Image")
    local text = CS.FindTrans(item,"Image/NameText")
    local root = CS.FindTrans(item,"Root")
    local csLayoutElement = root:GetComponent(typeof_LayoutElement)
    if(csLayoutElement)then
        local height = self.mApplyPage.rect.height
        height = height - 48 * 2
        csLayoutElement.minHeight = height
        root.sizeDelta = Vector2.New(root.rect.width,height)
    end

    self:SetWndText(text,itemdata.name)
    self:SetWndClick(image,function ()
        if(self._applyTab and self._applyTab == itempos)then
            return
        end
        self:OnClickApplyTab(itempos)
    end)
end

function UIGdWarWin:OnClickApplyGuildCell(guildId,sevenId)
    gModelGuild:OnGuildMemberListReq(guildId,sevenId)
end

function UIGdWarWin:InitCommand()
    local barrageText = CS.FindTrans(self.mBarrageInputBtn,"UIText")
    self:SetWndText(barrageText,ccClientText(10145))
	self:SetWndText(self.mTitleText,ccClientText(17900))
	self:SetWndText(self.mAwardText,ccClientText(17902))
    self:SetWndButtonText(self.mFormationBtn,ccClientText(17903))
    self:SetWndButtonTextLine(self.mFormationBtn, -30)
    self:SetWndText(self.mRankBtnText,ccClientText(17951))
    self:SetWndText(self.mAwardBtnText,ccClientText(17952))
    self:SetWndText(self.mShopBtnText,ccClientText(17953))
    self:SetWndButtonText(self.mApplyBtn1,ccClientText(17904))
    self:SetWndButtonText(self.mApplyBtn2,ccClientText(17945))
    self:SetWndButtonTextLine(self.mApplyBtn1, -30)
    self:SetWndButtonTextLine(self.mApplyBtn2, -30)
    self:RefreshInfo()
    local page = self:GetWndArg("page") or 1
    self._subPage = self:GetWndArg("subPage") or 1

    self._logItemPos = self:GetWndArg("itempos") or 0
    local list = {
        {name = ccClientText(17904)},
        {name = ccClientText(17905)}
    }
    local tabList = self:GetUIScroll("tabCell")
    tabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
    self:OnClickTab(page)
	--弹幕
	self._isBarrageShow = gModelChat:GetBarrageIsShow(ModelChat.CHANNEL_WAR)
	self._isBarrageShow = not self._isBarrageShow
	self:OnClickBarrage(true)
    gModelGuildMelee:OnGuildMeleeOpenEffectsReq()
end

function UIGdWarWin:ReqLogMsg(itemdata)
    if not itemdata.seq or itemdata.seq <= 1 then
        return
    end
    if self._seq and self._seq == itemdata.seq then
        return
    end
    self._seq = itemdata.seq
    gModelGuildMelee:OnGuildMeleeReportInfoListReq(itemdata.seq,1)
end
-----------------------------------------------弹幕---------------------------------------
function UIGdWarWin:OnClickBarrage(isOne)
	self._isBarrageShow = not self._isBarrageShow
	self:IsShowBarrage(self._isBarrageShow)
	CS.ShowObject(self.mBarrageMask,not self._isBarrageShow)
	if(not isOne)then
		gModelChat:SetBarrageSav(ModelChat.CHANNEL_WAR,self._isBarrageShow)
	end
end

function UIGdWarWin:OnClickApplyTab(applyTab)
    local _index = 0
    for i, v in pairs(self._applyTabEvList) do
        if(v)then
            _index = i
        end
    end
    if(_index>0)then
        local trans = self._applyTranss[_index]
        self:ChangeApplyTab(trans,false,_index)
    end
    if(_index == applyTab)then
        return
    end
    local trans = self._applyTranss[applyTab]
    self:ChangeApplyTab(trans,true,applyTab)
end

function UIGdWarWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildMeleeStateResp,function (pb)
        local bool = false
        if self._tab == 1 and (self._oldState and  self._oldState ~= pb.state and pb.state == ModelGuildMelee.STATE_Melee) then
            bool = true
            self._subPage = 1
        end
        self:RefreshInfo()
        if bool then
            self:OnClickTab(2)
        else
            self:RefreshData()
        end
	end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeSignUpInfoListResp,function (...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeMemberSignUpInfoListResp,function (...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeSignUpCancelResp,function (...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeMemberSignUpCancelResp,function (...)
        self:RefreshApply()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMeleeOpenEffectsResp,function (pb)
        local openEffects = pb.openEffects
        if openEffects == 1 then
            local inGuide = gModelGuide:IsInGuide()
            if inGuide then
                local func = nil
                func = function ()
                    GF.OpenWnd("UIGdMeleeEffPop")
                end
                gModelGuildMelee:DelayEffectWnd(func)
            else
                GF.OpenWnd("UIGdMeleeEffPop")
            end

        end
    end)
    self:WndEventRecv(EventNames.ON_GUILD_MELEE_REPORT,function()
        self:RefreshALog()
    end)
    self:WndEventRecv(EventNames.ON_CHAT_BARRAGE_WIN,function () self:OnClickBarrage() end)
end

function UIGdWarWin:ChangeApplyTab(trans,bool,index)
    self._applyTabEvList[index] = bool
    local cutIcon = CS.FindTrans(trans,"Image/CutIcon")
    local root = CS.FindTrans(trans,"Root")
    local cutStr = "achievement_arrow_1"
    if(bool)then
        cutStr = "achievement_arrow_2"
    end
    self:SetWndEasyImage(cutIcon,cutStr)
    CS.ShowObject(root,bool)
    if(not bool or not index)then
        return
    end
    local nameText = CS.FindTrans(root,"BgImage/NameText")
    local lvText = CS.FindTrans(root,"BgImage/LvText")
    local numText = CS.FindTrans(root,"BgImage/NumText")
    local powerText = CS.FindTrans(root,"BgImage/PowerText")
    local cellScroll = CS.FindTrans(root,"BgImage/CellScroll")
    local tipsText = CS.FindTrans(root,"BgImage/TipsText")
    local noRecord = CS.FindTrans(root,"BgImage/NoRecord")
    local nameStr,lvStr,numStr,powerStr,tipsStr,noRecordId
    if(index == 1)then
        nameStr,lvStr,numStr,powerStr,tipsStr =
        ccClientText(17914),ccClientText(17915),ccClientText(17916),ccClientText(17917),ccClientText(17970)
        noRecordId = 4102
        tipsStr = string.replace(tipsStr,gModelGuild:GetGuildConfigRefByKey("battleStartCondition"))
    else
        nameStr,lvStr,numStr,powerStr,tipsStr =
        ccClientText(17910),ccClientText(17911),ccClientText(17912),ccClientText(17913),""
        noRecordId = 4103
    end

    self:SetTextFontSizeAndStr(nameText,nameStr)
    self:SetTextFontSizeAndStr(lvText,lvStr)
    self:SetTextFontSizeAndStr(numText,numStr)
    self:SetTextFontSizeAndStr(powerText,powerStr)
    self:SetTextFontSizeAndStr(tipsText,tipsStr)

    local list = {}
    local maxSeq = 1
    if(index == ModelGuildMelee.SIGNUP_GUILD)then
        list = gModelGuildMelee:GetSignUpListByType(ModelGuildMelee.SIGNUP_GUILD,true)
        maxSeq = list[#list]
        table.sort(list,function (a,b)
            if a.powerCount ~= b.powerCount then
                return a.powerCount > b.powerCount
            end
            if a.level ~= b.level then
                return a.level > b.level
            end
            return a.seq < b.seq
        end)
    else
        list = gModelGuildMelee:GetSignUpListByType(ModelGuildMelee.SIGNUP_MEMBER,true)
        table.sort(list,function (a,b)
            if a.power ~= b.power then
                return a.power > b.power
            end
            return a.seq < b.seq
        end)
    end
    local _applyLen = #list
    local isShowNoRecord = _applyLen < 1
    CS.ShowObject(noRecord,isShowNoRecord)
    CS.ShowObject(cellScroll,not isShowNoRecord)
    if(isShowNoRecord)then
        self:CreateEmptyShow(noRecordId,noRecord)
        return
    end
    local applyType = self:GetUIScroll("applyType"..index)
    local _uilist = applyType:GetList()
    if(_uilist)then
        if(_applyLen > 25)then
            applyType:RefreshData(list)
            _uilist:RefreshSilent()
        else
            applyType:RefreshList(list)
        end
    else
        applyType:Create(cellScroll,list,function (...) self:applyTypeListItem(...) end,UIItemList.WRAP)
        _uilist = applyType:GetList()
    end
    _uilist:SetFuncOnItemReachTail(function (_uilist,bool)
        if bool then
            if index ~= ModelGuildMelee.SIGNUP_GUILD then
                return
            end
            local signUpGuildCount = self._meleeInfo.signUpGuildCount
            if _applyLen == signUpGuildCount then
                return
            end
            self:ReqApplyTypeMsg(maxSeq.seq)
        end
    end)
end
--帮助
function UIGdWarWin:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 56})
end

function UIGdWarWin:RefreshALogList()
    CS.ShowObject(self.mEndImage,false)
    CS.ShowObject(self.mLogPage,true)
    local list = {
        {name = ccClientText(17919)},
        {name = ccClientText(17920)},
        {name = ccClientText(17921)}
    }
    if(self._logCell)then
        self._logCell:RefreshList(list)
    else
        self._logCell = self:GetUIScroll("logCell")
        self._logCell:Create(self.mLogScroll,list,function (...) self:LogListItem(...) end)
    end
    local titleIndex = self._subPage
    local _index = 0
    for i, v in pairs(self._logTabEvList) do
        if(v)then
            _index = i
        end
    end
    if _index > 0 then
        self._logTabEvList[_index] = false
        titleIndex = _index
    end
    self._subPage = 0
    if titleIndex <= 0 then
        return
    end
    self:OnClickLogTab(titleIndex)
end

function UIGdWarWin:logTypeListItem(list,item, itemdata, itempos)
    if not itemdata then
        return
    end
    --if itempos == 1 then
    --    self:ReqLogMsg(itemdata)
    --end
    self._logIsLookMsg = self._LoglistLen == itempos
    local root1 = CS.FindTrans(item,"Root1")
    local root2 = CS.FindTrans(item,"Root2")
    local root3 = CS.FindTrans(item,"Root3")

    CS.ShowObject(root1,false)
    CS.ShowObject(root2,false)
    CS.ShowObject(root3,false)

    local type = itemdata.type
    local height = 50
    if(type == 1)then
        CS.ShowObject(root1,true)
        height = 50
        local tipsText = CS.FindTrans(root1,"TipsText")

        local round = itemdata.round

        self:SetWndText(tipsText,string.replace(ccClientText(17922),round))
    elseif(type == 2)then
        CS.ShowObject(root2,true)
        height = 138
        local playerA = CS.FindTrans(root2,"PlayerA")
        local playerB = CS.FindTrans(root2,"PlayerB")
        local lookBtn = CS.FindTrans(root2,"LookBtn")
        local lookText = CS.FindTrans(root2,"LookBtn/UIText")
        local frameImg = CS.FindTrans(root2,"FrameImg")
        if frameImg then
            CS.ShowObject(frameImg,false)
        end
        local infoA = {
            winCount = itemdata.winCount,
            serverId = itemdata.serverIdA,
            playerId = itemdata.playerIdA,
            name = itemdata.playerNameA,
            icon = itemdata.headA,
            headFrame = itemdata.headFrameA,
            level = itemdata.playerLevelA,
            win = itemdata.win == 1,
            guildId = itemdata.guildIdA,
            guildName = itemdata.guildNameA,
            power = itemdata.powerA
        }
        local infoB = {
            winCount = itemdata.winCount,
            serverId = itemdata.serverIdB,
            playerId = itemdata.playerIdB,
            name = itemdata.playerNameB,
            icon = itemdata.headB,
            headFrame = itemdata.headFrameB,
            level = itemdata.playerLevelB,
            win = itemdata.win == 2,
            guildId = itemdata.guildIdB,
            guildName = itemdata.guildNameB,
            power = itemdata.powerB
        }
        local guild = gModelPlayer:GetGuildId()
        local isMyGuild = itemdata.guildIdA == guild or itemdata.guildIdB == guild
        if isMyGuild and frameImg and self._oldLogTab == 1 then
            CS.ShowObject(frameImg,true)
        end
        self:OnSetPlayerABInfo(playerA,infoA)
        self:OnSetPlayerABInfo(playerB,infoB)
        self:SetWndText(lookText,ccClientText(17930))
        self:SetWndClick(lookBtn,function ()
            self:OnClickLook(itemdata,itempos)
        end)
    elseif type == 3 then
        CS.ShowObject(root3,true)
        height = 116
        local rankText = CS.FindTrans(root3,"RankText")
        local rankIcon = CS.FindTrans(root3,"RankIcon")
        local timeText = CS.FindTrans(root3,"TimeText")
        local desText = CS.FindTrans(root3,"DesText")

        local guildNameB = itemdata.guildNameB
        local serverIdB = itemdata.serverIdB
        local serverNameB = gModelFriend:GetSevenName(serverIdB)
        local guildNameA = itemdata.guildNameA
        local serverIdA = itemdata.serverIdA
        local serverNameA = gModelFriend:GetSevenName(serverIdA)
        local oust = itemdata.oust
        local time = tonumber(itemdata.time)/1000
        local win = itemdata.win
        local name1,seven1,name2,seven2
        if win == 1 then
            name1,seven1,name2,seven2 = guildNameB,serverNameB,guildNameA,serverNameA
        else
            name1,seven1,name2,seven2 = guildNameA,serverNameA,guildNameB,serverNameB
        end
        local str = string.replace(ccClientText(17923),name1,seven1,name2,seven2,oust)
        local formatStr = ccClientText(17939)

        CS.ShowObject(rankText,oust > 3)
        CS.ShowObject(rankIcon,oust <= 3)
        if oust <= 3 then
            local icon = "public_num_"..oust
            self:SetWndEasyImage(rankIcon,icon)
        else
            self:SetWndText(rankText,oust)
        end
        self:SetWndText( timeText,LUtil.OSDate(formatStr,time))
        self:SetWndText(desText,str)
    elseif type == 4 then
        height = 116
        local rankText = CS.FindTrans(root3,"RankText")
        local rankIcon = CS.FindTrans(root3,"RankIcon")
        local timeText = CS.FindTrans(root3,"TimeText")
        local desText = CS.FindTrans(root3,"DesText")
        CS.ShowObject(root3,true)
        local win = itemdata.win
        local time = tonumber(itemdata.time)/1000
        local guildNameB = itemdata.guildNameB
        local guildNameA = itemdata.guildNameA
        local serverIdB = itemdata.serverIdB
        local serverNameB = gModelFriend:GetSevenName(serverIdB)
        local serverIdA = itemdata.serverIdA
        local serverNameA = gModelFriend:GetSevenName(serverIdA)
        local name1,seven1
        if win == 1 then
            name1,seven1 = guildNameA,serverNameA
        else
            name1,seven1 = guildNameB,serverNameB
        end
        CS.ShowObject(rankText,false)
        CS.ShowObject(rankIcon,true)
        self:SetWndEasyImage(rankIcon,"public_num_1")
        self:SetWndText(desText,string.replace(ccClientText(17950),name1,seven1))
        local formatStr = ccClientText(17939)
        self:SetWndText( timeText,LUtil.OSDate(formatStr,time))
    end
    --item.sizeDelta = Vector2.New(item.rect.width,height)
    --local csLayoutElement = item:GetComponent(typeof_LayoutElement)
    --if(csLayoutElement)then
    --    csLayoutElement.preferredHeight = height
    --end

    LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end
--点击战报详情
function UIGdWarWin:OnClickLook(itemdata,itempos)
    local _index = 0
    for i, v in pairs(self._logTabEvList) do
        if(v)then
            _index = i
        end
    end
    local _subPage = 1
    if(_index>0)then
        _subPage = _index
    end
    --gModelGuildMelee:SetLogSubPage(_subPage)

    --local combatType = LCombatTypeConst.COMBAT_GUILD_WAR
    local reportId = itemdata.reportId

    local combatData = itemdata
    --combatData.serverId = itemdata.reportServerId
    --combatData.reportUrl = gModelGuildMelee:GetServerReportUrl(itemdata.reportServerId)
    --combatData.isLook = true
    --combatData.isShare = true
    local reportUrl = gModelGuildMelee:GetServerReportUrl(itemdata.reportServerId)

    local wndPara =
    {
        page = 2,
        subPage = _subPage,
        itempos = itempos,
    }
    local reportInfo =
    {
        reportId = reportId,
        serverId = itemdata.reportServerId,
        reportUrl = reportUrl,
        callback = function(reportTable)
            --GF.CloseWndByName("UIWahjop")
            local reportData = LFightReportData:New()
            reportData:CreateNoRound(reportTable)
            GF.OpenWnd("UIWahjop",{combatData = combatData,reportTable = reportData,wndType = 2,wndPara = wndPara})
        end
    }
    self:GetReportTable(reportInfo)

    --self:RecordReportInfo(reportInfo)

    --gModelBattle:StartFromReportId(reportId,combatType,combatData)
    --gModelGuildMelee:SetLogIndex(itempos)
end

function UIGdWarWin:OnClickRank()
    GF.OpenWndBottom("UIGdWarRk")
end

function UIGdWarWin:ChangeLogTab(trans,bool,index)
    self._logTabEvList[index] = bool
    local cutIcon = CS.FindTrans(trans,"Image/CutIcon")
    local root = CS.FindTrans(trans,"Root")
    local cutStr = "achievement_arrow_1"
    if(bool)then
        cutStr = "achievement_arrow_2"
        self._oldLogTab = index
    end
    self:SetWndEasyImage(cutIcon,cutStr)
    CS.ShowObject(root,bool)
    if(not bool or not index)then
        return
    end
    local cellScroll = CS.FindTrans(root,"BgImage/CellScroll")
    local noRecord = CS.FindTrans(root,"BgImage/NoRecord")

    self._noRecord = noRecord

    CS.ShowObject(cellScroll,true)
    local list = {}
    if(index == ModelGuildMelee.REPORT_WORLD)then
        list = gModelGuildMelee:GetReportListByType(ModelGuildMelee.REPORT_WORLD,true)
    elseif(index == ModelGuildMelee.REPORT_GUILD)then
        list = gModelGuildMelee:GetReportListByType(ModelGuildMelee.REPORT_GUILD,true)
    else
        list = gModelGuildMelee:GetReportListByType(ModelGuildMelee.REPORT_MINE,true)
    end

    if self._LoglistLen and self._LoglistLen == #list and self._oldLogIndex and self._oldLogIndex == index then
        return
    end
    self._LoglistLen = #list
    self._oldLogIndex = index

    local isShowNoRecord = self._LoglistLen < 1
    CS.ShowObject(self._noRecord,isShowNoRecord)
    CS.ShowObject(cellScroll,not isShowNoRecord)
    if(isShowNoRecord)then
        self:CreateEmptyShow(4104,self._noRecord)
        return
    end

    local logType = self:GetUIScroll("logType"..index)
    local _uilist = logType:GetList()
    if(not _uilist)then
        logType:Create(cellScroll,list,function (...) self:logTypeListItem(...) end,UIItemList.SUPER,false)
        _uilist = logType:GetList()

    end
    _uilist:SetFuncOnItemReachHead(function (bool)
        if bool then
            self:ReqLogMsg(list[1])
        end
    end)
    _uilist:SetFuncOnItemReachTail(function (bool)
        self._reachTail = bool
        if bool then
            self._logItemPos = 0
        end
    end)
    local len = #list
    local custon = 0
    for i, v in ipairs(list) do
        if self._seq and v.seq == self._seq then
            custon = i
            self._seq = nil
        end
    end
    local _glogIndex = self._logItemPos --gModelGuildMelee:GetLogIndex()
    if _glogIndex > 0 and _glogIndex <= len then
        custon = _glogIndex
    end

    if self._reachTail and _glogIndex == 0 then
        logType:RefreshList(list)
        _uilist:MoveToBottom()
    else
        logType:RefreshList(list)
        if custon == 0 then
            _uilist:DrawAllItems()
        else
            _uilist:MoveToPos(custon)
        end
    end
end

function UIGdWarWin:RefreshInfo()
    self._meleeInfo = gModelGuildMelee:GetGuildMeleeInfo()
    local info = self._meleeInfo
    self:TimerStop(self._meleeTime)
    if not info then
        return
    end
    local state = info.state
    self._oldState = state
    if state == 5 then
        local remainGuildCount = info.remainGuildCount
        local desStr = ccClientText(17935)
        local timeStr = string.replace(ccClientText(17936),remainGuildCount)
        self:SetWndText(self.mTimeDesText,desStr)
        self:SetWndText(self.mTimeText,timeStr)
    else
        self:TimerStart(self._meleeTime,1,false,-1)
        self:SetTime()
    end
end
----------------------------------------------倒计时--------------------------------------
function UIGdWarWin:OnTimer(key)
    if(self._meleeTime == key)then
        self:SetTime()
    --elseif key == self._oneRefreshKey then

    --elseif key == self._logIndexKey then

        --self._uilist:EnableLoadAnimation(true, 0, 1)
        --elseif self._onCreateApplyKey == key then
        --    self:OnClickApplyTab(self._titleIndex)
    end
end

function UIGdWarWin:RefreshApplyList()
    CS.ShowObject(self.mEndImage,true)
    --self._meleeInfo = gModelGuildMelee:GetGuildMeleeInfo()
    local info = self._meleeInfo
    if not info then
        return
    end
    local state = info.state
    local firstOpen = info.firstOpen
    if(firstOpen == 1 and state <= 2)then
        CS.ShowObject(self.mAwardPage,true)
        local items = gModelGuild:GetGuildConfigRefByKey("battleShowReward")
        local itemList = LxDataHelper.ParseItem(items)
        for i, v in ipairs(itemList) do
            v.itemNum = -1
        end
        local uiIconEasyList = self._uiIconEasyList
        if not uiIconEasyList then
            uiIconEasyList = UIIconEasyList:New()
            self._uiIconEasyList = uiIconEasyList
        end
        uiIconEasyList:Create(self, self.mAwardScroll)
        uiIconEasyList:SetShowNum(false)
        uiIconEasyList:EnableScroll(true,true)
        uiIconEasyList:RefreshList(itemList)
        self:CreateEmptyShow(4101,self.mNoRecord)
    else
        CS.ShowObject(self.mApplyPage,true)
        local list = {
            {name = ccClientText(17908)},
            {name = ccClientText(17909)}
        }
        if(self._applyCell)then
            self._applyCell:RefreshList(list)
        else
            self._applyCell = self:GetUIScroll("applyCell")
            self._applyCell:Create(self.mApplyScroll,list,function (...) self:applyListItem(...) end)
            --self._onCreate = true
        end

        local titleIndex = self._subPage
        local _index = 0
        for i, v in pairs(self._applyTabEvList) do
            if(v)then
                _index = i
            end
        end
        if _index > 0 then
            self._applyTabEvList[_index] = false
            titleIndex = _index
        end
        self._subPage = 0
        if titleIndex <= 0 then
            return
        end
        --if self._onCreate then
        --    self._titleIndex = titleIndex
        --    self:TimerStart(self._onCreateApplyKey,5,false,1)
        --else
            self:OnClickApplyTab(titleIndex)
        --end
    end
end

function UIGdWarWin:RefreshALog()
    if(self._tab == 1)then
        return
    end
    self:RefreshALogList()
end

function UIGdWarWin:OnClickShop()
    local functionId = gModelGuild:GetGuildConfigRefByKey("battleShopJump")
    gModelFunctionOpen:Jump(functionId,self:GetWndName())
end

--function UIGdWarWin:ClearReportCache()
--    if not self._recordReportList then
--        return
--    end
--
--    for k,v  in pairs(self._recordReportList) do
--        gModelBattle:ClearCacheReportByKey(v)
--    end
--
--    self._recordReportList = nil
--end

------------------------------------------------------------------
return UIGdWarWin


