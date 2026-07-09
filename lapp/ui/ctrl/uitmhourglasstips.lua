---
--- Created by LCM.
--- DateTime: 2024/3/17 21:05:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITmHourGlassTips:LWnd
local UITmHourGlassTips = LxWndClass("UITmHourGlassTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITmHourGlassTips:UITmHourGlassTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITmHourGlassTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITmHourGlassTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITmHourGlassTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:RefreshView()
	self:RefreshReturnItemList()
end


function UITmHourGlassTips:InitMsg()
	 self:WndNetMsgRecv(LProtoIds.HeroReturn2Resp,function() self:WndClose() end)
end

function UITmHourGlassTips:InitEvent()
    self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCancelBtn,function() self:OnClickCancelBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)
end

function UITmHourGlassTips:RefreshView()
    local itemId = self._itemId
    if not itemId then return end
    local selHeroId = self._selHeroId
    if not selHeroId then return end
    local serverData = gModelHero:GetHeroServerDataById(selHeroId)
    if not serverData then return end
    local heroRefId = serverData.refId
    local needRefId,needNum = gModelHeroSpirit:GetReturnItemInfo(itemId,selHeroId)
    if not needRefId or not needNum then return end
    local itemName = gModelItem:GetNameByRefId(needRefId)
    local heroName = gModelHero:GetHeroNameByRefId(heroRefId,serverData.star)
    local itemInfo = gModelItem:GetTimeHourGlassInfoByRefId(itemId)
    local returnToStar = itemInfo and itemInfo.returnToStar or 5
    local str = string.replace(ccClientText(26308),itemName,needNum,heroName,returnToStar)
    self:SetWndText(self.mDescTxt,str)
end

function UITmHourGlassTips:InitItemList(list)
    local uiItemList = self._uiItemList
    if uiItemList then
        uiItemList:RefreshList(list)
    else
        uiItemList = self:GetUIScroll("uiItemList")
        self._uiItemList = uiItemList
        uiItemList:Create(self.mItemList,list,function(...) self:OnDrawItemCell(...) end,UIItemList.WRAP)
    end
end

function UITmHourGlassTips:OnClickCancelBtnFunc()
    self:WndClose()
end

function UITmHourGlassTips:InitData()
    self._itemId = self:GetWndArg("itemId")
    self._returnRewardList = self:GetWndArg("returnRewardList") or {}
    self._selHeroId = self:GetWndArg("selHeroId")
end

function UITmHourGlassTips:InitMinItemList(list)
    local uiMinItemList = self._uiMinItemList
    if uiMinItemList then
        uiMinItemList:RefreshList(list)
    else
        uiMinItemList = self:GetUIScroll("uiMinItemList")
        self._uiMinItemList = uiMinItemList
        uiMinItemList:Create(self.mMinItemList,list,function(...) self:OnDrawItemCell(...) end)
    end
end

function UITmHourGlassTips:InitText()
    self:SetWndText(self.mLblBiaoti,ccClientText(26310))
    self:SetWndText(self.mTitleText,ccClientText(26309))
    self:SetWndButtonText(self.mCancelBtn,ccClientText(26311))
    self:SetWndButtonText(self.mEnterBtn,ccClientText(26312))
end

function UITmHourGlassTips:OnClickItemFunc(itemdata)

    gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

function UITmHourGlassTips:OnClickEnterBtnFunc()
    if not self._selHeroId then return end
    gModelHeroSpirit:OnHeroReturn2Req(self._selHeroId)
end

function UITmHourGlassTips:OnDrawItemCell(list,item,itemdata,itempos)
    local CommonIconTrans = self:FindWndTrans(item,"CommonIcon")
    local IconTrans = self:FindWndTrans(CommonIconTrans,"Icon")

    local itemType = itemdata.itemType
    local itemId = itemdata.itemId or itemdata.refId
    local itemNum = itemdata.itemNum

    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(IconTrans)
    if itemType == LItemTypeConst.TYPE_ITEM then
        baseClass:SetCommonReward(itemType, itemId, itemNum)
    elseif itemType == LItemTypeConst.TYPE_HERO then
        local id = itemdata.id
        if id then
            local heroData = {
                id = id,
                refId = itemdata.refId,
                star = itemdata.star,
                level = itemdata.level,
                skin = itemdata.skin,
                isResonance = itemdata.isResonance,
            }
            baseClass:SetHeroDataSet(heroData)
            baseClass:ShowStatusImg(true,true)
        else
            baseClass:SetCommonReward(itemType, itemId, itemNum)
        end
    end
    baseClass:DoApply()

    self:SetWndClick(IconTrans,function()
        self:OnClickItemFunc(itemdata)
    end)
end
------------------------- List -------------------------
function UITmHourGlassTips:RefreshReturnItemList()
    local list = self._returnRewardList
    local len = #list
    local showMin = len < 5
    local showMore = not showMin
    local isEmpty = len < 1
    if isEmpty then return end
    CS.ShowObject(self.mMinItemList,showMin)
    CS.ShowObject(self.mItemList,showMore)
    if showMin then
        self:InitMinItemList(list)
    elseif showMore then
        self:InitItemList(list)
    end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UITmHourGlassTips



