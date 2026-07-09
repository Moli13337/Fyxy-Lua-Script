---
--- Created by Administrator.
--- DateTime: 2024/9/19 16:42:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicUpCandleLv:LWnd
local UIMicUpCandleLv = LxWndClass("UIMicUpCandleLv", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicUpCandleLv:UIMicUpCandleLv()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicUpCandleLv:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicUpCandleLv:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicUpCandleLv:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitText()
    self:InitCommon()
end

function UIMicUpCandleLv:InitCommon()
    self:SetMagicBuff()
end

--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------
--设置技能信息
function UIMicUpCandleLv:SetMagicBuff()
    local circleData = self._circleData

    local buffRefId = self._magicCircleCfg.buff
    local buffCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(buffRefId, circleData:GetLevel() or 0)

    self:SetWndEasyImage(self.mSkillIcon, self._magicCircleCfg.buffIcon)
    self:SetWndText(self.mSkillName,ccLngText(self._magicCircleCfg.buffName))
    self:SetWndText(self.mSkillLv, "Lv." .. buffCfg.lv)

    --判断是否满级
    local isMax = buffCfg.next == -1

    CS.ShowObject(self.mNotFull, not isMax)
    CS.ShowObject(self.mFull, isMax)

    CS.ShowObject(self.mBenefitNotFull, not isMax)
    CS.ShowObject(self.mBenefitFull, isMax)

    self._curBuffRefId = buffCfg.refId



    --设置属性部分
    local curTran
    if isMax then
        curTran = CS.FindTrans(self.mBenefitFull, "Bg/Cur")

        --拿到上一个阶级的消耗道具
        local lv = circleData:GetLevel() - 1
        local lastBuffCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(buffRefId, lv)
        local costItem = lastBuffCfg.upNeed
        costItem = string.split(costItem, "=")
        self:SetCostItem(checknumber(costItem[2]), checknumber(costItem[3]))
    else
        curTran = CS.FindTrans(self.mBenefitNotFull, "Bg/Cur")

        local nextTran = CS.FindTrans(self.mBenefitNotFull, "Bg/Next")
        self:SetNextAttr(nextTran)

        --设置消耗的道具
        local costItem = buffCfg.upNeed
        costItem = string.split(costItem, "=")
        self:SetCostItem(checknumber(costItem[2]), checknumber(costItem[3]))
    end

    self:SetCurAttr(curTran)
end

function UIMicUpCandleLv:SetNextAttr(tran)
    local Title = CS.FindTrans(tran, "Title")
    local Attr = CS.FindTrans(tran, "Attr")
    local circleData = self._circleData

    local buffRefId = self._magicCircleCfg.buff
    local buffCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(buffRefId, circleData:GetLevel() or 0)
    local count, attrList = gModelMagic:ParseAttr(buffCfg.attr)

    local nextLv = circleData:GetLevel() + 1
    self:SetWndText(Title, string.replace(ccClientText(45723), nextLv))

    local nextBuffCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(buffRefId, nextLv)
    local nextCount, nextAttrList = gModelMagic:ParseAttr(nextBuffCfg.attr)

    for i = 1, nextCount do
        local tranKey = "Attr_" .. i
        local Des = CS.FindTrans(Attr, tranKey)

        local itemdata = nextAttrList[i]

        local colorStr = ccClientText(45730)
        local curValue = attrList[i].attrValue
        if itemdata.attrValue > curValue then
            colorStr = ccClientText(45706)
            local Arrow = CS.FindTrans(Des, "Arrow")
            CS.ShowObject(Arrow, true)
        end

        local str = string.replace(colorStr, itemdata.attrName, itemdata.attrStr)  --[45706] [全體少女：#a1#]
        self:SetWndText(Des, str)

    end
end

function UIMicUpCandleLv:OnDrawItem(list, item, itemdata, index)
    local IconRoot = CS.FindTrans(item, "IconRoot")
    local CandleLvTag = CS.FindTrans(item, "CandleLvTag")
    local AddValue_Bg = CS.FindTrans(item, "AddValue_Bg")
    local AddValue = CS.FindTrans(AddValue_Bg, "AddValue")

    local Icon = IconRoot
    local InstanceID = Icon:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(Icon)
    self:SetIconClickScale(Icon, true)
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:DoApply()

    self:SetWndClick(Icon, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)

    --

    if itemdata.itemId == 3210001 then
        local exp = itemdata.itemNum * 1
        self:SetWndText(AddValue, "+" .. exp)
    else
        local expInfo = gModelMagic:GetMagicRef(itemdata.itemId).exp
        expInfo = string.split(expInfo, "=")
        local exp = checknumber(expInfo[3])

        exp = exp * itemdata.itemNum
        exp = LUtil.NumberCoversion(exp)
        self:SetWndText(AddValue, "+" .. exp)
    end
end

function UIMicUpCandleLv:InitPara()
    self._magicRefId = self:GetWndArg("magicRefId")
    self._magicCircleCfg = gModelMagic:GetMagicCircleRef(self._magicRefId)
    self._circleData = gModelMagic:GetCircleData(self._magicCircleCfg.refId)


end

--region 界面初始化 --------------------------------------------------------------------------------
function UIMicUpCandleLv:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mUpLevel, function()
        if gModelMagic:CheckCanUpBuff(self._curBuffRefId) then
            --请求升级
            gModelMagic:SendMagicUpLevelReq(self._magicRefId, 1, self._costItemList)
        else
            --等级未满
            GF.ShowMessage(ccClientText(18342))

        end
    end)
end

function UIMicUpCandleLv:InitText()
    self:SetWndText(self.mTitle, ccClientText(45722))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:SetWndText(self.mSubTitle, ccClientText(45724))

    self:SetWndButtonText(self.mUpLevel, ccClientText(43710))
end

--设置背包中的蜡烛道具
function UIMicUpCandleLv:SetCostItem(itemid, count)
    local expItemId = itemid
    local haveNum = gModelItem:GetNumByRefId(expItemId)
    local showData = gModelMagic:GetCanUpLvCandle()
    self._costItemList = {}

    --消耗的道具
    local icon = gModelItem:GetItemIconByRefId(expItemId)
    self:SetWndEasyImage(self.mCost_Icon, icon)

    local isCan,leftNum =  gModelMagic:CheckCanUpBuff(self._curBuffRefId)

    if isCan then
        self:SetWndText(self.mCost_Value, count)
    else
        if leftNum then

            local countStr  = "#a1##a2#"
            local leftStr = "(#a1#)"
            leftStr = string.replace(leftStr,leftNum)
            local leftStr =  LUtil.FormatColorStr(leftStr,"lightRed" )

            countStr=  string.replace(countStr,count,leftStr)
            local str = countStr
            self:SetWndText(self.mCost_Value, str)

            self:SetAnchorPos(self.mCost_Icon,Vector2.New(-50,42))
            self:SetAnchorPos(self.mCost_Value,Vector2.New(40,42))
        else

            local countStr =  LUtil.FormatColorStr(count,"lightRed" )
            self:SetWndText(self.mCost_Value, countStr)
        end
    end

    if haveNum > 0 then
        local itemdata = {}

        itemdata.itemId = expItemId
        itemdata.itemNum = haveNum
        itemdata.itemType = 1

        table.insert(showData, 1, itemdata)
    end

    if table.isempty(showData) then

        CS.ShowObject(self.mNoRecord2, true)
        CS.ShowObject(self.mCostItemDiv, false)

        local emptyCfg = GameTable.EmptyTipsRef[41003]

        --icon  textbg  text
        self:SetWndEasyImage(self.mEmptyIcon, emptyCfg.icon)
        self:SetWndEasyImage(self.mEmptyTextBg, emptyCfg.textBg)
        self:SetWndText(self.mEmptyText, ccLngText(emptyCfg.text))

        return
    end
    self._costItemList = showData

    CS.ShowObject(self.mNoRecord2, false)
    CS.ShowObject(self.mCostItemDiv, true)

    local uiList = self._costItem
    if not uiList then
        uiList = self:GetUIScroll("UIMicUpCandleLvCostItem")

        uiList:Create(self.mCostItemList, showData or {}, function(...)
            self:OnDrawItem(...)
        end, UIItemList.SUPER_GRID)
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems()
    end

    self._costItem = uiList


end

function UIMicUpCandleLv:SetCurAttr(tran)
    local Title = CS.FindTrans(tran, "Title")
    local Attr = CS.FindTrans(tran, "Attr")
    local circleData = self._circleData

    local buffRefId = self._magicCircleCfg.buff
    local buffCfg = gModelMagic:GetBuffCfgByOriginIdAndLv(buffRefId, circleData:GetLevel() or 0)

    --拿到对应的属性
    local count, attrList = gModelMagic:ParseAttr(buffCfg.attr)

    local lv = circleData:GetLevel()
    self:SetWndText(Title, string.replace(ccClientText(45725), lv))

    for i = 1, count do
        local tranKey = "Attr_" .. i
        local Des = CS.FindTrans(Attr, tranKey)

        local itemdata = attrList[i]

        local str = string.replace(ccClientText(45730), itemdata.attrName, itemdata.attrStr)  --[45706] [全體少女：#a1#]
        self:SetWndText(Des, str)
    end
end

function UIMicUpCandleLv:InitMsg()
    self:WndEventRecv(EventNames.On_Item_Change, function(...)
        self:SetMagicBuff()
    end)

    self:WndEventRecv(gModelMagic.EventArgs.UpLightCandle, function()
        GF.ShowMessage(ccClientText(41057))
        self:SetMagicBuff()
    end)
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMicUpCandleLv