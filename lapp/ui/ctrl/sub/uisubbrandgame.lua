---
--- Created by Administrator.
--- DateTime: 2024/3/20 22:20:43
---
------------------------------------------------------------------
local BadgeGameNode =  LxRequire('LApp.UI.Common.BadgeGameNode')
local LChildWnd = LChildWnd
---@class UISubBrandGame:LChildWnd
local UISubBrandGame = LxWndClass("UISubBrandGame", LChildWnd)
------------------------------------------------------------------

local MODE_NORMAL = ModelBadgeGame.CHAPTER_NORMAL
local MODE_NIGHTMARE = ModelBadgeGame.CHAPTER_NIGHTMARE

local StarImg = ModelBadgeGame.StarImgMap

--支持配置位置信息
local nodePos = {
    {-230.,-137},{-173,5},{-238,156},{-76,174},{67,127},{-50,1},{42,-137},{187,-137},{248,12},{210,163}
}

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubBrandGame:UISubBrandGame()
	self.badgeModule = gModelBadgeGame
    self._curChapter = 1
    self._curBarrier = 1
    ---@type table<string,UIBadgeNode>
    self._badgeNodes = {}
    ---@type UIBadgeNode
    self._curSel = nil
    self._chapterRef = nil

    self._chapterType = MODE_NORMAL
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBrandGame:OnWndClose()
	LChildWnd.OnWndClose(self)
    -- self.badgeModule.chapterAndBarrier[1] = self._curChapter
    -- self.badgeModule.chapterAndBarrier[2] = self._curBarrier
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBrandGame:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBrandGame:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitSliderRect()
	self:InitMsgs()
    self:AddBtnClickFun()

    self:CreateRwdList()

    self:RefreshForeign()

    self:OnWndRefresh()
end

function UISubBrandGame:InitSliderRect()
    local isOpen = gModelBadgeGame:CheckIsOpenNightmare()
    local temp = self.mSliderRectTrans.sizeDelta
    local x = temp.x
    if isOpen then
        x = 398
    end
    self.mSliderRectTrans.sizeDelta = Vector2(x,temp.y)
    CS.ShowObject(self.mModeBtn,isOpen)
end

function UISubBrandGame:OnWndRefresh()
    self:InitDatas()
    self:UpdateChapter()
    self:InitBoxRwd()
end

function UISubBrandGame:CreateRwdList()
    local list = self:CreateUIScrollImpl("rwdScroll",self.mListRwdScroll,nil,function (...)
        self:OnDrawRewardItem(...)
    end)
    self.rwdList = list
end
function UISubBrandGame:InitBoxRwd()
    local boxStar = LxDataHelper.ParseNumber_Sign(GameTable.BadgeGameConfigRef.boxStar)
    local maxStar = boxStar[#boxStar]
    local width = self.mSliderRectTrans.sizeDelta.x
    for indx, value in pairs(boxStar) do
        local itemBox = self["mItemBox"..indx]
        local boxRtTran = self["m"..indx.."RectTrans"]
        local txtStar = self["mTxtStar"..indx]
        local imgBox = self["mImgGeted"..indx]
        if itemBox then
            CS.ShowObject(itemBox,true)
            local pos = boxRtTran.anchoredPosition
            pos.x = width*(value/maxStar)
            boxRtTran.anchoredPosition = pos
            self:SetWndEasyImage(imgBox,"draconic_box_icon_off")
            self:SetWndText(txtStar,tostring(value))
            self:SetWndClick(itemBox,function ()
                GF.OpenWnd("UIBrandGameBox",{chapterId = self._curChapter})
            end)
        end
    end
end

function UISubBrandGame:AddBtnClickFun()
    self:SetWndClick(self.mBtnLeft,function ()
        local frontChapterRef = gModelBadgeGame:GetBadgeGameChapRefByInfo(self._chapterType,self._curChapter-1)
        if not frontChapterRef then return end
        self._curChapter = frontChapterRef.refId
        self:UpdateChapter()
    end)
    self:SetWndClick(self.mBtnRight,function ()
        local chapterType = self._chapterType
        local chapterRef = gModelBadgeGame:GetBadgeGameChapRefByInfo(chapterType,self._curChapter)
        if not chapterRef or chapterRef.nextChapter <=0 then return end

        local nextChapterRef = gModelBadgeGame:GetBadgeGameChapRefByInfo(chapterType,chapterRef.nextChapter)
        local lv = gModelPlayer:GetPlayerLv()
        if nextChapterRef.needLevel>lv then --等级不足
            GF.ShowMessage(string.replace(ccClientText(40214),nextChapterRef.needLevel))
            return
        end
        local chapterInof = self.badgeModule:GetChapterById(chapterRef.refId)
        local state = chapterInof:GetChapterState()
        if state == 1 then--当前章节未通关
            GF.ShowMessage(ccClientText(40215))
            return
        elseif state == 3 or state ==4  then
            local chapterStar = chapterInof.starNum
            if nextChapterRef.needStar> chapterStar then
                GF.ShowMessage(string.replace(ccClientText(40216),nextChapterRef.needStar))
                return
            end
        end
        self._curChapter = chapterRef.nextChapter
        self:UpdateChapter()
    end)
    self:SetWndClick(self.mBtnVideo,function ()
        -- ShowPanel(UiNames.BadgeGameVideo,{
        --     refId = self._curBarrier,
        --     uiDataForExitBattle = {
        --         {name = UiNames.PlayGamesPve},
        --         {name = UiNames.BadgeMain}
        --     }
        -- })
        GF.OpenWnd("UIBrandGameVdo",{
            refId = self._curBarrier,
            uiDataForExitBattle = {
                -- {name = UiNames.PlayGamesPve},
                {
                    name = "UIBrandGameWin",
                    chapterId = self._curChapter,
                }
            },
        })
    end)
    self:SetWndClick(self.mBtnBattle,function ()
        self:GoToFight()
    end)
    self:SetWndClick(self.mBtnWelfare,function ()
        self:OnWelfare()
    end)
    self:SetWndClick(self.mBtnHelp,function ()
        GF.OpenWnd("UIBzTips",{refId = 160})
    end)
    self:SetWndClick(self.mBtnChapter,function ()
        local chapterType = MODE_NORMAL
        local curChapter = self._curChapter
        if curChapter and curChapter > 0 then
            chapterType = gModelBadgeGame:GetBadgeGameChapRefType(curChapter)
        end
        GF.OpenWnd("UIBadgeGameChapter",{
            chapterType = chapterType
        })
    end)
    self:SetWndClick(self.mModeBtn,function()
        GF.OpenWnd("UIBadgeGameSelect")
    end)

end

function UISubBrandGame:RefreshForeign()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isVie then
        self:SetAnchorPos(self.mBtnLeft,Vector2.New(-120,-62))
        self:SetAnchorPos(self.mBtnRight,Vector2.New(120,-20))
        self:SetAnchorPos(self.mTxtPower,Vector2.New(146.1,408.7))
        self:SetAnchorPos(self.mPowerIcon,Vector2.New(110,421.9063))
    end
end

function UISubBrandGame:InitDatas()
    self.badgeModule.starCondRefId = {}
    local curChapter,defaultChapterType = self:DefaultChapterId()
    self._curChapter = curChapter
    self._chapterType = defaultChapterType

    local isNightType = defaultChapterType == MODE_NIGHTMARE
    local isNormal = not isNightType
    CS.ShowObject(self.mBg2,isNightType)
    CS.ShowObject(self.mModeType1,isNormal)
    CS.ShowObject(self.mModeType2,isNightType)
    CS.ShowObject(self.mNodeContentBg1,isNormal)
    CS.ShowObject(self.mNodeContentBg2,isNightType)
    CS.ShowObject(self.mMode1,isNormal)
    CS.ShowObject(self.mMode2,isNightType)
    CS.ShowObject(self.mImgStarBg1,isNormal)
    CS.ShowObject(self.mImgStarBg2,isNightType)
    CS.ShowObject(self.mImgStarBg1,isNormal)
    CS.ShowObject(self.mImgStarBg2,isNightType)
    CS.ShowObject(self.mImgStarIcon1,isNormal)
    CS.ShowObject(self.mImgStarIcon2,isNightType)
    local barImg = isNightType and "badgeGame1_bg_3" or "draconic_bar_1"
    self:SetWndEasyImage(self.mFill,barImg)
end


function UISubBrandGame:DisposeNodeIocn()
    for key, value in pairs(self._badgeNodes or {}) do
        value:Destroy()
        value = nil
    end
end
function UISubBrandGame:DefaultChapterId()
    local chapterType = self:GetWndArg("chapterType") or MODE_NORMAL
    local badgeModule = self.badgeModule
    local isSel = self:GetWndArg("isSel")
    local isJump = self:GetWndArg("isJump")

    --- 界面刷新，重置参数
    local wndArgList = self:GetWndArgList()
    wndArgList["isSel"] = false
    wndArgList["isJump"] = false

    local lastBattleBarrier = badgeModule:GetLastBattleBarrier()
    if not isSel and lastBattleBarrier > 0 then
        local barrierCfg = GameTable.BadgeGameBarrierRef[lastBattleBarrier]
        if barrierCfg then
            return barrierCfg.chapterId,barrierCfg.type
        end
    end
    local chapterId = chapterType == MODE_NORMAL and badgeModule:GetNormalChapterId() or badgeModule:GetNightmareChapterId()
    local arg_chapterId = self:GetWndArg("chapterId")
    if arg_chapterId and arg_chapterId > 0 then
        chapterId = arg_chapterId
        chapterType = gModelBadgeGame:GetBadgeGameChapRefType(chapterId)
    end
    local chapterInfo = badgeModule:GetChapterById(chapterId)
    if not chapterInfo then return 1,chapterType end

    if isJump then
        return chapterId,chapterType
    end

    local state = chapterInfo:GetChapterState()
    local ref = gModelBadgeGame:GetBadgeGameChapRefByInfo(chapterType,chapterId)
    local nextChapter = ref.nextChapter
    if (state == 3 or state == 4) and nextChapter > 0 then--通关
        local nextChapterInfo = badgeModule:GetChapterById(nextChapter)
        if nextChapterInfo:GetChapterState() == 2 then
            return chapterInfo.chapterId,chapterType
        else
            return nextChapter,chapterType
        end
    else
        return chapterInfo.chapterId,chapterType
    end
end

function UISubBrandGame:InitText()
    self:SetWndText (self.mPanelTitle,ccClientText(40200))
    self:SetWndText(self.mTxtStar,ccClientText(40220))
    self:SetWndText(self.mTxtBtnBattle,ccClientText(37234))
    self:SetWndText(self.mTxtBtnWelfare,ccClientText(204))
    self:SetWndText(self.mTxtBtnChapter,ccClientText(40208))
    self:SetWndText(self.mModeDesc,ccClientText(40237))
    self:SetWndText(self.mTxtRwd,ccClientText(40231))
    self:SetWndText(self.mTxtPowerTiltle,ccClientText(40201))
end

function UISubBrandGame:UpdateArrow()
    local chapterType = self._chapterType
    local curChapter = self._curChapter
    local chapterRef = gModelBadgeGame:GetBadgeGameChapRefByInfo(chapterType,curChapter)
    CS.ShowObject(self.mBtnRight.transform,chapterRef.nextChapter>0 and true or false)
    local frontChapterRef = gModelBadgeGame:GetBadgeGameChapRefByInfo(chapterType,curChapter-1)
    CS.ShowObject(self.mBtnLeft.transform,frontChapterRef and true or false)

    -- local redNum = 0
    -- local chapterRight = chapterRef.nextChapter and self.badgeModule:GetChapterById(chapterRef.nextChapter)
    -- redNum = chapterRight and chapterRight:GetChapterRed()
    -- self:SetRedNum(self.mBtnRight.transform,redNum and 1 or 0,false)

    -- local chapterLeft = frontChapterRef and self.badgeModule:GetChapterById(frontChapterRef.refId)
    -- redNum = chapterLeft and chapterLeft:GetChapterRed()
    -- self:SetRedNum(self.mBtnLeft.transform,redNum and 1 or 0,false)


end
function UISubBrandGame:UpdateChapterRed()
    local chapterType = gModelBadgeGame:GetBadgeGameChapRefType(self._curChapter)
    CS.ShowObject(self.mImgChapterRed,gModelBadgeGame:GetBadgeGameRed(chapterType))
end

function UISubBrandGame:UpdateStarCondition()
    local barrierRef = GameTable.BadgeGameBarrierRef[self._curBarrier]
    local monsterRef = GameTable.MonsterFormationRef[barrierRef.monster]
    local power = monsterRef and monsterRef.monsterPower or 0
    local color = tonumber(gModelPlayer:GetPlayerFightPower()) >= power and "#48A646" or "#D92716"
    self:SetWndText(self.mTxtPower,string.replace("<color=#a1#>#a2#</color>",color,LUtil.NumberCoversion(power)))

    local curChapter = self._curChapter
    local chapterType = gModelBadgeGame:GetBadgeGameChapRefType(curChapter)
    local starImgInfo = StarImg[chapterType]
    local Act,NoAct = starImgInfo.Act,starImgInfo.NoAct

    local chapterInfo = self.badgeModule:GetChapterById(curChapter)
    local stars = {0,0,0}
    if chapterInfo then
        stars = chapterInfo:GetBarrierStar(self._curBarrier,true)
    end

    self:OnDrawPassStar({
        star = stars[1],
        txt = ccClientText(40203),
        Act = Act,
        NoAct = NoAct,
    },{
        starTrans = self.mImgPassStar1,
        starBgTrans = self.mStarBg1,
        textStarCond = self.mTxtStarCond1,
    })

    local condRef = GameTable.BadgeGameCondRef[barrierRef.starCond1]
    self:OnDrawPassStar({
        star = stars[2],
        txt = ccLngText(condRef.text),
        Act = Act,
        NoAct = NoAct,
    },{
        starTrans = self.mImgPassStar2,
        starBgTrans = self.mStarBg2,
        textStarCond = self.mTxtStarCond2,
    })

    condRef = GameTable.BadgeGameCondRef[barrierRef.starCond2]
    self:OnDrawPassStar({
        star = stars[3],
        txt = ccLngText(condRef.text),
        Act = Act,
        NoAct = NoAct,
    },{
        starTrans = self.mImgPassStar3,
        starBgTrans = self.mStarBg3,
        textStarCond = self.mTxtStarCond3,
    })
end
function UISubBrandGame:OnWelfare()
    local curTotalStar = self.badgeModule.yesterdayStar
    local rwd = nil
    local refs = GameTable.BadgeGameStarRef
    for _, value in ipairs(refs) do
        local star = string.split(value.star,"|")
        if curTotalStar>= tonumber(star[1]) and curTotalStar<= tonumber(star[2]) then
            rwd = LxDataHelper.ParseItem(value.reward)-- LxDataHelper.ParseItemList(value.reward)
        end
    end
    if not rwd then rwd = LxDataHelper.ParseItem(refs[#refs].reward) end
	local func = function()
        if gModelBadgeGame.dailyRewardState ==1 then
            gModelBadgeGame:BadgeGameDailyRewardReq()
        end
    end
    local tipId = gModelBadgeGame.dailyRewardState ==1 and 400001 or 400002
    gModelGeneral:OpenUIOrdinTips({refId = tipId,func = func,itemList = rwd,para = {curTotalStar},})
end

function UISubBrandGame:OnStarProgress()
    local boxStar = LxDataHelper.ParseNumber_Sign(GameTable.BadgeGameConfigRef.boxStar)
    local chapterInfo = self.badgeModule:GetChapterById(self._curChapter)
    if not chapterInfo then return end
    self:SetWndText(self.mTxtOwnStar,tostring(chapterInfo.starNum))
    self.mSlider.value = chapterInfo.starNum/(boxStar[#boxStar])
    local chapterType = gModelBadgeGame:GetBadgeGameChapRefType(self._curChapter)

    local starImgInfo = StarImg[chapterType]
    local Act = starImgInfo.Act

    local isRed = false
    for indx, value in pairs(boxStar) do
        isRed = chapterInfo:GetBoxState(indx)
        local imgGetd = self["mImgGeted"..indx]
        self:SetWndEasyImage(imgGetd,isRed>2 and "draconic_box_icon_on" or "draconic_box_icon_off")
        local imgRed = self["mImgRed"..indx]
        CS.ShowObject(imgRed,isRed==2)
        self:SetWndEasyImage(self["mImgStar"..indx],Act)
    end
end

function UISubBrandGame:InitMsgs()
    self:WndEventRecv(EventNames.BADGE_GAME_UPDATE,function()
        local curChapter,chapterType = self:DefaultChapterId()
        self._curChapter = curChapter
        self._chapterType = chapterType
        self:UpdateChapter()
    end)
end

function UISubBrandGame:UpdateBarrierInfo()
    local barrierRef = GameTable.BadgeGameBarrierRef[self._curBarrier]
    self:SetWndText(self.mTxtChapterLv,ccLngText(barrierRef.name))

    local rwds = LxDataHelper.ParseItem(barrierRef.reward)
    -- rwds[1].itemId = 100110
    -- rwds[2].itemId = 100130
    self.rwdList:RefreshList(rwds)
    self.rwdList:EnableScroll(#rwds > 2,true)
    self:UpdateStarCondition()
end

function UISubBrandGame:OnDrawPassStar(setInfo,transInfo)
    local star,txt = setInfo.star,setInfo.txt
    local isFinish = star >= 1
    local starTrans = transInfo.starTrans
    self:SetWndEasyImage(starTrans,setInfo.Act)
    CS.ShowObject(starTrans,isFinish)

    self:SetWndEasyImage(transInfo.starBgTrans,setInfo.NoAct)

    local color = isFinish and "48A646ff" or "D92716ff"
    local textStarCond = transInfo.textStarCond
    self:SetWndText(textStarCond,txt)
    self:SetXUITextTransColor(textStarCond,color)
end

--[[function UISubBrandGame:RefreshWhenOpen()
    LChildWnd.RefreshWhenOpen(self)
    self._curChapter = self:DefaultChapterId()
    self:UpdateChapter()
end]]

function UISubBrandGame:DefaultSelBarrier()
    local chapterInfo = self.badgeModule:GetChapterById(self._curChapter)
    if not chapterInfo then return 1 end
    self._curBarrier = chapterInfo:PrioritySelBarrier()
    self.badgeModule:SetLastBattleBarrier(self._curBarrier)
end
function UISubBrandGame:GoToFight()
    local barrierRef = GameTable.BadgeGameBarrierRef[self._curBarrier]
    local chapterData = self.badgeModule:GetChapterById(self._curChapter)
    if chapterData and chapterData:PerfectPassedBarrier(self._curBarrier) then
        GF.ShowMessage(ccClientText(40212))
        return
    end
    local chapterInfo = gModelBadgeGame:GetChapterById(barrierRef.chapterId)
    local chapterRef = gModelBadgeGame:GetBadgeGameChapRefByInfo(self._chapterType,barrierRef.chapterId)
    local needLv = gModelPlayer:GetPlayerLv() < (chapterRef.needLevel or 0)
    local needStar = chapterInfo.starNum < (chapterRef.needStar or 0)
    if needLv or needStar then
        local str = ""
        if needLv then str = string.replace(ccClientText(40228),chapterRef.needLevel) end
        if needStar then str = str..string.replace(ccClientText(40229),chapterRef.needStar) end
        str = str..ccClientText(40230)
        GF.ShowMessage(str)
        return
    end
    -- local videoBtnCB = self.OnVideoCallBack
    -- CtrlCenter.Battle:GotoFormation({
    --     battleType = BattleType.BadgeGame,
    --     index = 1,
    --     mapName = "Battle003",
    --     monsterRefId = barrierRef.monster,
    --     videoBtnCB = videoBtnCB,
    --     videoParam = self._curBarrier,
    --     -- formation2 = formation,
    --     -- roleInfo2 = battleRoleInfo,
    --     showMode = BattleViewMode.Battle,
    --     callBackObj = self,
    --     params =  {refId = self._curBarrier},
    --     uiDataForExitBattle = {{name=UiNames.PlayGamesPve},{name = UiNames.BadgeMain}},
    -- })
    local monsterRef = GameTable.MonsterFormationRef[barrierRef.monster]
    local name = monsterRef and ccLngText(monsterRef.name)
    local power = monsterRef and monsterRef.monsterPower or 0
    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_BADGE_GAME,{refId = self._curBarrier,otherName=name,power = power,monsterRefId = barrierRef.monster})
    self.badgeModule:SetLastBattleBarrier(self._curBarrier)
end
function UISubBrandGame:OnVideoCallBack(barrierId, backFormation)
    -- ShowPanel(UiNames.BadgeGameVideo,{
    --     refId = barrierId,
    --     backFormation = backFormation
    -- })
end


function UISubBrandGame:CreateBadgeNode()
    if self._curSel then self._curSel:OnSelect(false) end
    self._curSel = nil
    self:DisposeNodeIocn()
    local curChapter = self._curChapter
    local chapterType = gModelBadgeGame:GetBadgeGameChapRefType(curChapter)
    local starImgInfo = StarImg[chapterType]
    local Act,NoAct = starImgInfo.Act,starImgInfo.NoAct

    local barrierId = chapterType == MODE_NORMAL and gModelBadgeGame:GetNormalBarrierId() or gModelBadgeGame:GetNightmareBarrierId()

    local childCount = self.mDian.childCount
    local barrierRefs = self.badgeModule:GetChapterBarrierRef(curChapter)
    for indx, barrierCfg in pairs(barrierRefs) do
        local pos = nodePos[indx]
        local NodeIcon = BadgeGameNode:New()
        NodeIcon:SetClickFunc(function()
            if barrierCfg.refId == self._curBarrier then return end

            if barrierCfg.refId > barrierId + 1 then
                GF.ShowMessage(ccClientText(40217))
                return
            end
            local chapterInfo = self.badgeModule:GetChapterById(barrierCfg.chapterId)
            if chapterInfo and chapterInfo:PerfectPassedBarrier(barrierCfg.refId) then
                GF.ShowMessage(ccClientText(40212))
                return
            end
            self._curBarrier = barrierCfg.refId
            self:UpdateBarrierInfo()
            if self._curSel then
                self._curSel:OnSelect(false)
            end
            NodeIcon:OnSelect(true)
            self._curSel =NodeIcon
        end)

        NodeIcon:SetLoadedCallback(function ()
            NodeIcon:SetPostion({x = pos[1],y=pos[2],z=0})
            NodeIcon:SetLineWidth(pos,nodePos[indx+1])
            NodeIcon:setLineRotationZ(pos,nodePos[indx+1])
            if barrierCfg.refId == self._curBarrier then
                self._curSel = NodeIcon
                self._curSel:OnSelect(true)
            end
        end)
        NodeIcon:Create(self.mNodeContent,{
            chapterId= barrierCfg.chapterId,
            barrierId = barrierCfg.refId,
            actStarImg = Act,
            notActStarImg = NoAct,
        })

        local iconKey = "BadgeNode"..barrierCfg.refId
        self._badgeNodes[iconKey] = NodeIcon
        local line = self.mDian.transform:GetChild(math.min(indx - 1,childCount - 1))
        if line then
            CS.ShowObject(line,barrierId>=barrierCfg.refId)
        end
    end
end

function UISubBrandGame:UpdateChapter()
    self._chapterRef = gModelBadgeGame:GetBadgeGameChapRefByInfo(self._chapterType,self._curChapter)
    self:SetWndText(self.mTxtChapter,ccLngText(self._chapterRef.name))
    local isShow = self.badgeModule.yesterdayStar>0
    local isOpen = gModelFunctionOpen:CheckIsOpened(32000002,false)
    CS.ShowObject(self.mBtnWelfare.transform,isShow and isOpen)
    CS.ShowObject(self.mImgRed,self.badgeModule.dailyRewardState==1 and isShow)
    self:UpdateArrow()
    self:OnStarProgress()
    self:DefaultSelBarrier()
    self:UpdateBarrierInfo()
    self:CreateBadgeNode()
    self:UpdateChapterRed()
end
function UISubBrandGame:OnDrawRewardItem(list, item, itemData, index)
	local CommonUIIcon = self:FindWndTrans(item,"CommonUI/Icon")
	local txtGeted = self:FindWndTrans(item,"CommonUI/TxtGeted")
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUIIcon)

	baseClass:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
	baseClass:DoApply()
	self:SetWndClick(CommonUIIcon,function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)

    local chapterInfo = self.badgeModule:GetChapterById(self._curChapter)
    local starNum = 0
    if chapterInfo then  starNum = chapterInfo:GetBarrierStar(self._curBarrier) end
    CS.ShowObject(txtGeted,starNum>0)
end


------------------------------------------------------------------
return UISubBrandGame