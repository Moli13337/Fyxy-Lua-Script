---
--- Created by Administrator.
--- DateTime: 2024/3/20 15:48:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandGameWin:LWnd
local UIBrandGameWin = LxWndClass("UIBrandGameWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandGameWin:UIBrandGameWin()
	self._tabList = {}
	self._curTabIndex = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandGameWin:OnWndClose()
	LWnd.OnWndClose(self)
	
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandGameWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandGameWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDatas()
	self:InitTabList()
	self:OpenChildCtrl()

	self:SetWndClick(self.mCloseBtn,function(...)
		self:WndClose() 
		if not GF.FindFirstWndByName("UIOutts") then
			GF.OpenWnd("UIOutts")
		 end
	end)
	self:SetWndClick(self.mBtnWin, function(...) self:WndClose() end)
	gModelBadgeGame:OnBadgeGameInfoReq()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:WndClose()
    end)
	self:WndEventRecv(EventNames.BADGE_GAME_UPDATE, function()
		local newChapter = self:GetBattleChapterId()
		local checkId = 1

		local chapterType = self:GetWndArg("chapterType") or ModelBadgeGame.CHAPTER_NORMAL
		local isNormal = chapterType == ModelBadgeGame.CHAPTER_NORMAL
		local curChapter = isNormal and gModelBadgeGame:GetNormalChapterId() or gModelBadgeGame:GetNightmareChapterId()
		local barrierRefs = gModelBadgeGame:GetChapterBarrierRef(curChapter)
		if barrierRefs and #barrierRefs > 0 then
			local first = barrierRefs[1]
			checkId = first.chapterId
		end

		if newChapter <= checkId then return end
		local oldChapter = newChapter - 1
		local isShow = gModelBadgeGame.unlockIdList[oldChapter]
		if not isShow then 
			GF.OpenWnd("UIBrandGameWin",{
				chapterType = chapterType,
				chapterId = oldChapter
			})
			GF.OpenWnd("UIBrandNewChapter",{newChapterId = newChapter})
			gModelBadgeGame:BadgeGameUnlockChapterReq(oldChapter)
		end
    end)
end

function UIBrandGameWin:RefreshSelectTable(newIndex,oldIndex)
    self:SetWndTabStatus(self._tabList[oldIndex],1)
	self:SetWndTabStatus(self._tabList[newIndex],0)

    self:CloseChildByName(self._tabDatas[oldIndex].uiName)
    self:OpenChildCtrl()
end

function UIBrandGameWin:OnDrawTab(list, item, itemData, index)
	local btnTab = CS.FindTrans(item,"BtnTab3")
	self:SetWndTabText(btnTab,itemData.name)
	self:SetWndTabStatus(btnTab, 1)
	self._tabList[index] = btnTab
	self:SetWndClick(item, function (...) self:DoChangeTab(index) end)

end

function UIBrandGameWin:InitDatas()
    self._tabDatas = {
        {uiName="UISubBrandGame", name=ccClientText(40222)},
        -- {uiName="UISubBrandChapter", name=ccClientText(40208)},
    }

    local openName = self:GetWndArg("name") or ""
    self._curTabIndex = 1
    for k,v in ipairs(self._tabDatas) do
        if v.uiName == openName then
            self._curTabIndex = k
        end
    end
end

function UIBrandGameWin:DoChangeTab(index)
    if self._curTabIndex == index then return end
    local oldIndex = self._curTabIndex
    self._curTabIndex = index
	self:SetWndTabStatus(self._tabList[oldIndex],1)
	self:SetWndTabStatus(self._tabList[index],0)

    self:CloseChildByName(self._tabDatas[oldIndex].uiName)
    self:OpenChildCtrl()
end

function UIBrandGameWin:OnWndRefresh()
	LWnd.OnWndRefresh(self)
	local oldIndex = self._curTabIndex
	self:InitDatas()
	local newIndex = self._curTabIndex
	self:RefreshSelectTable(newIndex,oldIndex)
end

function UIBrandGameWin:InitTabList()
    local uiList = self:GetUIScroll("badgeTab")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
    self._tabUiList = uiList
end

function UIBrandGameWin:OpenChildCtrl()
	local tabDatas = self._tabDatas[self._curTabIndex]
	if not tabDatas then return end

    local uiName = tabDatas.uiName
    if string.isempty(uiName) then return end

	self:CreateChildWnd(self.mChildRoot,tabDatas.uiName,{
		chapterId = self:GetWndArg("chapterId"),
		chapterType = self:GetWndArg("chapterType"),
		isSel = self:GetWndArg("isSel"),
		isJump = self:GetWndArg("isJump"),
	})
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0)
end

function UIBrandGameWin:GetBattleChapterId()
	local chapterType = self:GetWndArg("chapterType") or ModelBadgeGame.CHAPTER_NORMAL
	local isNormal = chapterType == ModelBadgeGame.CHAPTER_NORMAL
	local curChapter = isNormal and gModelBadgeGame:GetNormalChapterId() or gModelBadgeGame:GetNightmareChapterId()
	local chapterInfo = gModelBadgeGame:GetChapterById(curChapter)
    if not chapterInfo then return 1 end

    local state = chapterInfo:GetChapterState()
    local nextChapter = GameTable.BadgeGameChapRef[curChapter].nextChapter
    if (state == 3 or state == 4) and nextChapter > 0 then--通关
        local nextChapterInfo = gModelBadgeGame:GetChapterById(nextChapter)
        if nextChapterInfo:GetChapterState() == 2 then
            return chapterInfo.chapterId
        else
            return nextChapter
        end
    else
        return chapterInfo.chapterId
    end
end
------------------------------------------------------------------
return UIBrandGameWin