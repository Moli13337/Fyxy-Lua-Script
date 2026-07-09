---
--- Created by Administrator.
--- DateTime: 2024/4/8 22:21:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandGameBox:LWnd
local UIBrandGameBox = LxWndClass("UIBrandGameBox", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandGameBox:UIBrandGameBox()
    self._effectKeyList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandGameBox:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandGameBox:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandGameBox:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mImgMask,function() self:WndClose() end)
	self:SetWndText(self.mTxtBiaoti,ccClientText(40205))
	self:SetWndText(self.mCloseInfo,ccClientText(41037))
    local chapterId = self:GetWndArg("chapterId")
    if chapterId and chapterId > 0 then
        local chapterType = gModelBadgeGame:GetBadgeGameChapRefType(chapterId)
        if chapterType then
            local starInfo = ModelBadgeGame.StarImgMap[chapterType]
            if starInfo then
                self._starImg = starInfo.Act
            end
        end
    end
    self.chapterInfo = gModelBadgeGame:GetChapterById(chapterId)
    self:WndEventRecv(EventNames.BADGE_GAME_UPDATE,function() self:CreateBoxList() end)
    self:CreateBoxList()
end

function UIBrandGameBox:OnDrawRwdItem(list, item, itemData, index)
	local instanceId = item:GetInstanceID()
	local Icon = self:FindWndTrans(item,"Icon")
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(Icon)
	-- itemData.itemId = 100110

	baseClass:SetCommonReward(itemData.itemType, itemData.itemId, itemData.itemNum)
	baseClass:DoApply()
	self:SetWndClick(item,function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)

end

function UIBrandGameBox:SetComponentCache(instanceID,itemCache)
    if not self._cacheComponents then self._cacheComponents = {} end
    self._cacheComponents[instanceID] = itemCache
end

function UIBrandGameBox:CreateBoxList()
    for k,v in ipairs(self._effectKeyList) do
		self:DestroyWndEffectByKey(v)
	end
	self._effectKeyList={}
    local starRef = LxDataHelper.ParseNumber_Sign(GameTable.BadgeGameConfigRef.boxStar)
	self:CreateUIScrollImpl(nil,self.mListBoxRwd,starRef,function(...) self:OnDrawBoxItem(...) end, UIItemList.WRAP)
end
function UIBrandGameBox:ShowRewardList(listView,itemData)
	self:CreateUIScrollImpl(nil,listView,itemData,function(...) self:OnDrawRwdItem(...) end,UIItemList.WRAP)
end
function UIBrandGameBox:OnDrawBoxItem(list,item,itemData,index)
    local instanceID = item:GetInstanceID()
    local itemCache = self._cacheComponents and self._cacheComponents[instanceID]
    if not itemCache then
        local rewardList = self:FindWndTrans(item,"ListRewards")
        local Title = self:FindWndTrans(item,"Title")
        itemCache ={
            rewardList = rewardList,
            txtTitle = self:FindWndTrans(Title,"TxtTitle"),
            btnGet = self:FindWndTrans(item,"BtnGet"),
            txtProgress = self:FindWndTrans(Title,"TxtProgress"),
            txtGeted =self:FindWndTrans(item,"TxtGeted"),
        }
		itemCache.txtBtnName = self:FindWndTrans(itemCache.btnGet,"TxtBtnName")
        if self._starImg then
            self:SetWndEasyImage(self:FindWndTrans(Title,"TxtProgress/Image"),self._starImg)
        end
        self:SetComponentCache(instanceID,itemCache)
    end
    local star = self.chapterInfo and self.chapterInfo.starNum or 0
    local color = star>= itemData and "#02a90b" or "#FF0000"
    self:SetWndText(itemCache.txtTitle,string.replace(ccClientText(40206),index))



    if self._isEnus then
        self:SetWndText(itemCache.txtProgress,string.replace("  (     <color=#a1#>#a2#</color>/#a3#)",color,(star>=itemData and itemData or star),itemData))
    else
        self:SetWndText(itemCache.txtProgress,string.replace("（     <color=#a1#>#a2#</color>/#a3#）",color,(star>=itemData and itemData or star),itemData))
    end


    local imgPath = star < itemData and "activity_turn_txt_16" or "public_txt_13_1" --ComPanel
    self:SetWndEasyImage(itemCache.txtGeted,imgPath)
    self:SetWndText(itemCache.txtBtnName,star < itemData and ccClientText(30003) or ccClientText(30002))
    local isGet = self.chapterInfo:GetBoxState(index)
    CS.ShowObject(itemCache.btnGet,isGet==2)
    CS.ShowObject(itemCache.txtGeted, isGet~=2)
    self:SetWndClick(itemCache.btnGet,function ()
        if star< itemData then
            self:WndClose()
        else
            gModelBadgeGame:BadgeGameStarChestReq(self.chapterInfo.chapterId,index)
        end
    end)
    local key = "task"..tostring(index)
    table.insert(self._effectKeyList,key)
    self:CreateWndEffect(itemCache.btnGet,"fx_anniu_02",key,100,nil,nil,nil,nil,nil,true)

    local chapterId = self:GetWndArg("chapterId")
    local rwds = GameTable.BadgeGameChapRef[chapterId]["boxReward"..index]
    rwds = LxDataHelper.ParseItem(rwds)
    self:ShowRewardList(itemCache.rewardList,rwds)
end
------------------------------------------------------------------
return UIBrandGameBox