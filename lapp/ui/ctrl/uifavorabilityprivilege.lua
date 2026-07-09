---
--- Created by Administrator.
--- DateTime: 2024/4/24 16:53:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFavorabilityPrivilege:LWnd
local UIFavorabilityPrivilege = LxWndClass("UIFavorabilityPrivilege", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFavorabilityPrivilege:UIFavorabilityPrivilege()
    self.loveLevel = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFavorabilityPrivilege:OnWndClose()
    LWnd.OnWndClose(self)
    if self._cacheComponents then
        self._cacheComponents = nil
    end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFavorabilityPrivilege:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFavorabilityPrivilege:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:SetWndText(self.mLblBiaoti, ccClientText(41316))
    self:SetWndText(self.mTxtDesc, ccClientText(41317))
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mImgMask, function()
        self:WndClose()
    end)
    self:CrestChapterList()
end

function UIFavorabilityPrivilege:SetComponentCache(instanceID, itemCache)
    if not self._cacheComponents then
        self._cacheComponents = {}
    end
    self._cacheComponents[instanceID] = itemCache
end
function UIFavorabilityPrivilege:OnDrawChapterItem(list, item, itemData, index)
    local instanceID = item:GetInstanceID()
    local itemCache = self._cacheComponents and self._cacheComponents[instanceID]
    if not itemCache then
        itemCache = {
            ImgActive = self:FindWndTrans(item, "ImgActive"),
            ImgLock = self:FindWndTrans(item, "ImgLock"),
            TxtLv = self:FindWndTrans(item, "TxtLv"),
            TxtPrivilege = self:FindWndTrans(item, "GameObject/TxtPrivilege"),
            TxtPrivilege2 = self:FindWndTrans(item, "GameObject/TxtPrivilege2"),
            TxtLock = self:FindWndTrans(item, "TxtLock"),
            TxtLock_en = self:FindWndTrans(item, "TxtLock_en")
        }
        self:SetComponentCache(instanceID, itemCache)

        if self._isEnus then
            itemCache.TxtLock = itemCache.TxtLock_en
        end
    end
    local loveLv = self.loveLevel
    self:SetWndText(itemCache.TxtLv, itemData.refId)
    CS.ShowObject(itemCache.ImgActive, itemData.refId <= loveLv)
    CS.ShowObject(itemCache.ImgLock, itemData.refId > loveLv)
    CS.ShowObject(itemCache.TxtLock, itemData.refId > loveLv)
    self:SetWndText(itemCache.TxtLock, string.replace(ccClientText(41323), itemData.refId))
    CS.ShowObject(itemCache.TxtPrivilege, itemData.text1 ~= "")
    CS.ShowObject(itemCache.TxtPrivilege2, itemData.text2 ~= "")
    self:SetWndText(itemCache.TxtPrivilege, ccLngText(itemData.text1))
    self:SetWndText(itemCache.TxtPrivilege2, ccLngText(itemData.text2))

    if self._isVie then
        if itemData.text1 ~= "" and itemData.text2 ~= "" then
            self:SetAnchorPos(itemCache.ImgActive, Vector2.New(171, 25))
        else
            self:SetAnchorPos(itemCache.ImgActive, Vector2.New(171, 0))
        end
    end
end

function UIFavorabilityPrivilege:CrestChapterList()
    local heroRefId = self:GetWndArg("heroRefId")
    self.loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId) or 0
    self.listData = {}
    local ref = GameTable.CharacterFavorabilityRef
    for _, value in pairs(ref) do
        if value and (value.text1 ~= "" or value.text2 ~= "") then
            table.insert(self.listData, value)
        end
    end
    table.sort(self.listData, function(a, b)
        return a.refId < b.refId
    end)
    local openIndex = -1
    for _, value in ipairs(self.listData) do
        if self.loveLevel >= value.refId then
            openIndex = openIndex + 1
        end
    end

    -- local list = self:CreateUIScrollImpl(nil,self.mListPrivilege,self.listData,function(...) self:OnDrawChapterItem(...) end,UIItemList.NORMAL)
    -- local uiList = list:GetList()
    -- -- uiList:SetContentPosition(0,200)
    -- uiList:ScrollTo(8)
    local itemList = self:GetUIScroll("privilegeList")
    itemList:Create(self.mListPrivilege, self.listData, function(...)
        self:OnDrawChapterItem(...)
    end)
    local uiList = itemList:GetList()
    itemList:EnableScroll(true, false)
    uiList:DelayScrollTo(openIndex, UIListEasy.SCROLL_TOP)


end
------------------------------------------------------------------
return UIFavorabilityPrivilege