---
--- Created by Administrator.
--- DateTime: 2024/9/20 16:55:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicPot:LWnd
local UIMicPot = LxWndClass("UIMicPot", LWnd)
local potRes = {
    [0] = "magicGet_icon_1",
    [1] = "magicGet_icon_2",
    [2] = "magicGet_icon_3",
    [3] = "magicGet_icon_4"
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicPot:UIMicPot()
    self.onePotNum = GameTable.MagicGetConfigRef.magicGetOnePot
    self.aniSpeed = GameTable.MagicGetConfigRef.magicGetFxSpeed
    self.temp = 1 / self.onePotNum
    self.canClick = true
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicPot:OnWndClose()
    LxTimer.LoopTimeStop(self.aniTimer)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicPot:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicPot:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
	self._isJapaness  =gLGameLanguage:IsJapanVersion()
    self:InitCommon()
    self:InitEvent()
    self:InitTopShowItem()
    self:UpdateRedPoint()

    gModelMagicPot:MagicPotInfoReq()
end

function UIMicPot:UpdatePotImg()
    local res = gModelMagicPot:GetPotRes()
    if self.potRes == res then
        return
    end
    self:SetWndEasyImage(self.mPotImg, res)
    self.potRes = res
end

function UIMicPot:InitTopShowItem()
    local data = gModelMagicPot:GetTopShowItem()
    self.topShowItem = {}
    for i, v in ipairs(data) do
        local trans = CS.FindTrans(self.mNeedItem, "Item" .. i)
        if trans then
            local icon = CS.FindTrans(trans, "Icon")
            local add = CS.FindTrans(trans, "Add")
            local text = CS.FindTrans(trans, "Text")

            local res = gModelGeneral:GetCommonItemImgRef(v)
            self:SetWndEasyImage(icon, res)
            self:SetWndClick(add, function()
                gModelGeneral:OpenGetWayWnd({ itemId = v.itemId, srcWnd = self:GetWndName() })
            end)

            table.insert(self.topShowItem, { text = text, data = v })
        end
    end
    self:UpdateTopShowItem()
end

function UIMicPot:UpdateReward()
    local cfg, stage = gModelMagicPot:GetNextLvlReward()
    local showBtn = gModelMagicPot:GetShowRewardBtn()
    local isRed, cfg2 = gModelMagicPot:GetRewardRedpoint()
    if not showBtn then
        CS.ShowObject(self.mRewardBtn, false)
        return
    end
    local trans = CS.FindTrans(self.mRewardBtn, "Text")
    local str = ""
    if isRed then
        str = ccClientText(45807)
        cfg = cfg2
    elseif stage > 0 then
        str = string.replace(ccClientText(45808), stage)
    end
    self:SetWndText(trans, str)

    if self._isEnus then
        self:InitTextLineWithLanguage(trans, 30)
    end

    local reward = LxDataHelper.ParseItem_4(cfg.reward)
    local res = ModelGeneral:GetCommonItemImgRef(reward)
    self:SetWndEasyImage(self.rewardBtnIcon, res)
end

function UIMicPot:SetRank(pb)
    if pb.rankType ~= 1900 then
        return
    end
    if pb.infos then
        for i = 1, 3 do
            local trans = self["mRank" .. i]
            local data = pb.infos and pb.infos[i] or nil
            self:SetRankTrans(trans, data)
        end

        if pb.selfRank and pb.selfRank.rank > 0 then
            self:SetRankTrans(self.mSelfRank, pb.selfRank)
        end
        CS.ShowObject(self.mSelfRank, pb.selfRank and pb.selfRank.rank > 3)
    end
end

function UIMicPot:OnMagicPotInfoResp()
    self:UpdateReward()
    self:UpdateBar()
    self:UpdatePotImg()
end

function UIMicPot:SetPotDoEff(index)
    self:DestroyWndEffectByKey("doEff")
    self:CreateWndEffect(self.mDo, "fx_moyaoguo_yansebianhua_" .. index, "doEff", 100, false, false)
end

function UIMicPot:UpdateBar()
    local potNum = gModelMagicPot:GetPotNum()
    local pot = math.floor(potNum / self.onePotNum)
    local temp = potNum - pot * self.onePotNum
    self.mBarImg.fillAmount = temp / self.onePotNum
    self:SetWndText(self.mBarText, string.replace(ccClientText(45809), pot))
    local index = potNum % 16
    index = index == 0 and 16 or index
    self:SetPotColorEff(index)
    CS.ShowObject(self.mColor, true)
end

function UIMicPot:InitEvent()
    -----------------------------------------------
    ---click
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mRewardBtn, function()
        GF.OpenWnd("UIMicPotAward")
    end)
    self:SetWndClick(self.mLookBtn, function()
        local potNum = gModelMagicPot:GetPotNum()
        local pot = math.floor(potNum / self.onePotNum)
        GF.OpenWnd("UIMicPotLook",{ TextNum = pot })
    end)
    self:SetWndClick(self.mTaskBtn, function()
        GF.OpenWnd("UIMicPotTk")
    end)
    self:SetWndClick(self.mShopBtn, function()
        GF.OpenWnd("UIDian", { shopId = 2014 })
    end)
    self:SetWndClick(self.mGiftBtn, function()
        GF.OpenWnd("UIMicPotGift")
    end)
    self:SetWndClick(self.mOneBtn, function()
        self:ClickOneBtn()
    end)
    self:SetWndClick(self.mTenBtn, function()
        self:ClickTenBtn()
    end)
    self:SetWndClick(self.mRank, function()
        GF.OpenWnd("UIRkPop", { refId = 1900 })
    end)
    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 180 })
    end)

    -----------------------------------------------
    ---event
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:UpdateTopShowItem()
    end)
    self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function()
        self:UpdateRedPoint()
    end)

    self:WndEventRecv(EventNames.ON_SHOP_DATA_RETURN, function()
        self:UpdateRedPoint()
    end)
    self:WndEventRecv("MagicPotInfoResp", function()
        gModelRank:OnRankReq(2, 1900, 1, 3)
        gModelShop:ShopListReq(1010)
        self:OnMagicPotInfoResp()
        self:UpdateRedPoint()
    end)
    self:WndEventRecv("MagicPotLotteryResp", function()
        gModelMagicPot:MagicPotInfoReq()
    end)

    -----------------------------------------------
    ---resp
    self:WndNetMsgRecv(LProtoIds.RankResp, function(pb)
        self:SetRank(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.RankChangeResp, function(pb)
        gModelRank:OnRankReq(2, 1900, 1, 3)
    end)
end

function UIMicPot:UpdateRedPoint()
    for _, v in ipairs(self.redPointList) do
        CS.ShowObject(v.trans, v.func())
    end
end

function UIMicPot:OnTryRefreshRedPoint(...)
    self:UpdateRedPoint()
end

function UIMicPot:PlayBarAni(num, func)
    self.canClick = false
    self.curNum = 0
    local index = 17
    local potNum = gModelMagicPot:GetPotNum()
    if num == 1 then
        index = potNum % 16
        index = index == 0 and 16 or index
    end
    self:SetPotDoEff(index)
    CS.ShowObject(self.mDo, true)
    LxTimer.DelayTimeCall(function()
        CS.ShowObject(self.mColor, false)
    end, 0.15)

    local startNum = potNum - math.floor(potNum / self.onePotNum) * self.onePotNum
    local startPos = startNum / self.onePotNum
    local i = 1
    local time = 0
    local allTime = num == 1 and 40 or 30
    local temp = self.temp / allTime * num
    self.aniTimer = LxTimer.LoopTimeCall(function()
        local pos = startPos + (temp * i)
        if pos > 1 then
            startPos = 0
            pos = temp
            i = 1

            local pot = math.floor((potNum + num) / self.onePotNum)
            local index = pot % 4
            self:SetWndEasyImage(self.mPotImg, potRes[index])
        end
        self.mBarImg.fillAmount = pos
        i = i + 1
        time = time + 1
        if time >= allTime then
            func()
            self.canClick = true
        elseif (time == 29 and num ~= 1) or (time == 39 and num == 1) then
            local index = (potNum + num) % 16
            index = index == 0 and 16 or index
            self:SetPotColorEff(index)
            CS.ShowObject(self.mColor, true)
        end
    end, 0.1, false, allTime)
end

function UIMicPot:SetRankTrans(trans, data)
    local num = CS.FindTrans(trans, "Num")
    local icon = CS.FindTrans(trans, "Icon")
    local name = CS.FindTrans(trans, "Name")
    local score = CS.FindTrans(trans, "Score")
    local me = CS.FindTrans(trans, "Me")

    if data and data.rank > 0 then
        if data.rank > 3 then
            self:SetWndText(num, data.rank)
        else
            local res = "public_num_" .. data.rank
            self:SetWndEasyImage(icon, res)
        end
        self:SetWndText(name, data.info.name)
        self:SetWndText(score, data.score)
        CS.ShowObject(num, data.rank > 3)
        CS.ShowObject(icon, data.rank <= 3)
    else
        self:SetWndText(name, ccClientText(11707))
        self:SetWndText(score, "")
    end
    CS.ShowObject(me, data and data.info.playerId == gModelPlayer:GetPlayerId())
end

function UIMicPot:ClickTenBtn()
    if not self.canClick then
        return
    end
    local item = LxDataHelper.ParseItem_4(GameTable.MagicGetConfigRef.magicGetMoreExpend)
    if gModelGeneral:CheckItemEnough(item.itemId, item.itemNum, true) then
        self:PlayBarAni(10, function()
            gModelMagicPot:MagicPotLotteryReq(1)
        end)
    end
end

function UIMicPot:SetPotColorEff(index)
    self:DestroyWndEffectByKey("colorEff")
    self:CreateWndEffect(self.mColor, "fx_moyaoguo_yanse_" .. index, "colorEff", 100, false, false)
end

function UIMicPot:ClickOneBtn()
    if not self.canClick then
        return
    end
    local item = LxDataHelper.ParseItem_4(GameTable.MagicGetConfigRef.magicGetExpend)
    if gModelGeneral:CheckItemEnough(item.itemId, item.itemNum, true) then
        self:PlayBarAni(1, function()
            gModelMagicPot:MagicPotLotteryReq(0)
        end)
    end
end

function UIMicPot:InitCommon()
    -----------------------------------------------
    ---text
    self:SetWndText(self.mTitleText, ccClientText(45801))
    self:SetWndText(self.mTxtReturn, ccClientText(10320))
    self:SetWndText(self.mRankTitleText, ccClientText(11700))
    self:SetWndText(self.mLookText, ccClientText(42004))
    self:SetWndText(CS.FindTrans(self.mLookBtn, "Text"), ccClientText(45802))
    self:SetWndText(CS.FindTrans(self.mTaskBtn, "Text"), ccClientText(45803))
    self:SetWndText(CS.FindTrans(self.mShopBtn, "Text"), ccClientText(45804))
    self:SetWndText(CS.FindTrans(self.mGiftBtn, "Text"), ccClientText(45805))
    self:SetWndButtonText(self.mOneBtn, string.replace(ccClientText(45806), 1))
    self:SetWndButtonText(self.mTenBtn, string.replace(ccClientText(45806), GameTable.MagicGetConfigRef.magicGetMoreNum))

    if self._isEnus then
        self:InitTextLineWithLanguage(CS.FindTrans(self.mLookBtn, "Text"),30)
        self:InitTextLineWithLanguage(CS.FindTrans(self.mTaskBtn, "Text"),30)
    end
    if self._isJapaness then
		local addLine = -45
		self:InitTextLineWithLanguage(CS.FindTrans(self.mLookBtn, "Text"),addLine)
		self:InitTextLineWithLanguage(CS.FindTrans(self.mTaskBtn, "Text"),addLine)
		self:InitTextLineWithLanguage(CS.FindTrans(self.mShopBtn, "Text"),addLine)
		self:InitTextLineWithLanguage(CS.FindTrans(self.mGiftBtn, "Text"),addLine)

		self:InitTextSizeWithLanguage(CS.FindTrans(self.mLookBtn, "Text"),-2)
		self:InitTextSizeWithLanguage(CS.FindTrans(self.mTaskBtn, "Text"),-2)
		self:InitTextSizeWithLanguage(CS.FindTrans(self.mShopBtn, "Text"),-2)
		self:InitTextSizeWithLanguage(CS.FindTrans(self.mGiftBtn, "Text"),-2)

		local addWidth = 80
		LxUiHelper.SetSizeWithCurAnchor(CS.FindTrans(self.mLookBtn, "Text"),0,addWidth)
		LxUiHelper.SetSizeWithCurAnchor(CS.FindTrans(self.mTaskBtn, "Text"),0,addWidth)
		LxUiHelper.SetSizeWithCurAnchor(CS.FindTrans(self.mShopBtn, "Text"),0,addWidth)
		LxUiHelper.SetSizeWithCurAnchor(CS.FindTrans(self.mGiftBtn, "Text"),0,addWidth)
	end
    -----------------------------------------------
    ---btnText
    local oneBtnItem = LxDataHelper.ParseItem_4(GameTable.MagicGetConfigRef.magicGetExpend)
    local res = gModelGeneral:GetCommonItemImgRef(oneBtnItem)
    self:SetWndEasyImage(CS.FindTrans(self.mOneCost, "Icon"), res)
    self:SetWndText(CS.FindTrans(self.mOneCost, "Text"), oneBtnItem.itemNum)
    local tenBtnItem = LxDataHelper.ParseItem_4(GameTable.MagicGetConfigRef.magicGetMoreExpend)
    local res = gModelGeneral:GetCommonItemImgRef(tenBtnItem)
    self:SetWndEasyImage(CS.FindTrans(self.mTenCost, "Icon"), res)
    self:SetWndText(CS.FindTrans(self.mTenCost, "Text"), tenBtnItem.itemNum)

    -----------------------------------------------
    ---member
    local taskRedpoint = CS.FindTrans(self.mTaskBtn, "redPoint")
    local rewardRedpoint = CS.FindTrans(self.mRewardBtn, "redPoint")
    local shopRedpoint = CS.FindTrans(self.mShopBtn, "redPoint")
    local giftRedpoint = CS.FindTrans(self.mGiftBtn, "redPoint")
    self.redPointList = {
        {
            trans = taskRedpoint,
            func = function()
                return gModelQuest:IsHaveFinishTaskByType(182)
            end
        },
        {
            trans = rewardRedpoint,
            func = function()
                return gModelMagicPot:GetRewardRedpoint()
            end
        },
        {
            trans = shopRedpoint,
            func = function()
                return gModelRedPoint:CheckSingleShopRedPoint(2014)
            end
        },
        {
            trans = giftRedpoint,
            func = function()
                return gModelMagicPot:GetGiftRedPoint()
            end
        },
    }
    self.rewardBtnIcon = CS.FindTrans(self.mRewardBtn, "Icon")

    -----------------------------------------------
    ---eff
    self:CreateWndEffect(self.mFire, "fx_moyaoguo_huoyan", "fx_moyaoguo_huoyan", 100, false, false)

    -----------------------------------------------
    ---canvas
    local canvas = self.mFire:GetComponent(typeof(UnityEngine.Canvas))
    canvas.sortingOrder = self:GetWndSortOrder() + 1
    local canvas = self.mBarObj:GetComponent(typeof(UnityEngine.Canvas))
    canvas.sortingOrder = self:GetWndSortOrder() + 5
end

function UIMicPot:UpdateTopShowItem()
    for _, v in ipairs(self.topShowItem) do
        local num = gModelItem:GetNumByRefId(v.data.itemId)
        self:SetWndText(v.text, LUtil.NumberCoversion(num))
    end
end

------------------------------------------------------------------
return UIMicPot