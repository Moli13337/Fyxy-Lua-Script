---
--- Created by Administrator.
--- DateTime: 2023/10/26 20:03:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBookSyPop:LWnd
local UISagaBookSyPop = LxWndClass("UISagaBookSyPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBookSyPop:UISagaBookSyPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBookSyPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBookSyPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBookSyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommon()
end

function UISagaBookSyPop:OnDrawStarCell(list, item, itemdata, itempos)
	local Star = self:FindWndTrans(item, "Star")
	if Star then
		local actStar = not itemdata.actStar
		self:SetWndImageGray(Star, actStar)
	end
end


function UISagaBookSyPop:InitStoryData(heroRefId)
	local  heroRef = gModelHero:GetHeroRef(heroRefId)
	local heroStory = heroRef.heroStory
	if type(heroStory) == "string" then
		heroStory = tonumber(ccLngText(heroStory))
	end
	local storyRefList = gModelHeroBook._initHeroStoryRefList[heroStory] or {}
	local storyData = {}
	for k,v in pairs(storyRefList) do
		table.insert(storyData,v)
	end
	table.sort(storyData,function (a,b)
		return a.needLevel < b.needLevel
	end)
	self._storyData = storyData
end

function UISagaBookSyPop:UpdateStory(toIndex)
	local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(self._heroRefId)
	if not serverData then return end
	local storyIndex = self._storyIndex

	local data = self._storyData[storyIndex]
	local lock = tonumber(serverData.heroMaxStar) >= tonumber(data.needLevel)
	local storyText = self.mStoryText
	CS.ShowObject(self.mLockG, not lock)
	CS.ShowObject(storyText, lock)

	self:SetWndText(self.mStoryTitle,ccLngText(data.decName))
	if lock then
		self:SetWndText(storyText,ccLngText(data.dec))
	else
		self:CreateLockQMDJList(data.needLevel)
	end

	CS.ShowObject(self.mStoryLeftBtn,storyIndex > 1)
	CS.ShowObject(self.mStoryRightBtn,storyIndex < #self._storyData)

	self:CreateStoryIndexList()

end


function UISagaBookSyPop:UIDragOnBegin(dragKey, eventData)

	if dragKey ~= "drag" then
		return
	end

	self._dragBeginPos = eventData.position

	--local camera = eventData.pressEventCamera
	--local pos = camera:ScreenToWorldPoint(eventData.position)
	--pos = item.parent:InverseTransformPoint(pos)
	--self._dragOffsetPosX = item.localPosition.x - pos.x
end


function UISagaBookSyPop:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end )

	self:SetWndClick(self.mStoryRightBtn,function ()
		self:RightFun()
	end)

	self:SetWndClick(self.mStoryLeftBtn,function ()

		self:LeftFun()
	end)


	self:InternalUIDragSetItem("drag",self.mContentScroll,CS.YXUIDrag.DragMode.DragNothing)

end

function UISagaBookSyPop:CreateLockQMDJList(dj)
	local list = {}
	for i = 1,dj do
		table.insert(list, { actStar = true })
	end
	local uiQMDJList = self._uiLockQMDJList
	if uiQMDJList then
		uiQMDJList:RefreshList(list)
	else
		uiQMDJList = self:GetUIScroll("uiLockQMDJList")
		self._uiLockQMDJList = uiQMDJList
		uiQMDJList:Create(self.mLockQmDJList, list, function(...)
			self:OnDrawStarCell(...)
		end)
	end
end

function UISagaBookSyPop:CreateStoryIndexList()
	local list = self._storyData
	local uiQMDJList = self._uiStoryList
	if uiQMDJList then
		uiQMDJList:RefreshList(list)
	else
		uiQMDJList = self:GetUIScroll("_uiStoryList")
		self._uiStoryList = uiQMDJList
		uiQMDJList:Create(self.mStoryList, list, function(...)
			self:OnDrawListCell(...)
		end)
	end
end

function UISagaBookSyPop:RightFun()
	if self._storyIndex < #self._storyData then
		self._storyIndex = self._storyIndex + 1
		self:UpdateStory()
	end
end

function UISagaBookSyPop:RefreshHeroBookView(refId,netWork)
	local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
	if not serverData then return end
	self._heroRefId = refId
	local closeGrade = serverData.heroMaxStar
	local heroRef = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local closeLv = heroRef.closeLv
	local heroCloseRef = gModelHeroBook:GetHeroCloseLvRefByCloseTypeAndCloseGrade(closeLv, closeGrade)
	if not heroCloseRef then return end


	self:InitStoryData(refId)

	self:UpdateStory()

end


function UISagaBookSyPop:OnDrawListCell(list, item, itemdata, itempos)
	local Star = self:FindWndTrans(item, "Star")
	local UpImg = self:FindWndTrans(item, "UpImg")
	CS.ShowObject(UpImg,itempos == self._storyIndex)
end

function UISagaBookSyPop:LeftFun()
	if self._storyIndex > 1 then
		self._storyIndex = self._storyIndex - 1
		self:UpdateStory()
	end
end

function UISagaBookSyPop:InitCommon()

	self:SetWndText(self.mLockTxt1,ccClientText(19730))
	self:SetWndText(self.mLockTxt2,ccClientText(19731))

	self._heroRefId = self:GetWndArg("heroRefId")
	self._storyIndex = self:GetWndArg("index") or 1
	local only = not self._heroList or #self._heroList < 2
	CS.ShowObject(self.mCurLeftBtn,not only);
	CS.ShowObject(self.mCurRightBtn,not only);

	self:RefreshHeroBookView(self._heroRefId)


end


function UISagaBookSyPop:UIDragOnDrag(dragKey,eventData)

	if dragKey ~=  "drag" then
		return
	end

	if self._dragBeginPos == nil then
		return
	end

	local gap = eventData.position.x - self._dragBeginPos.x
	local gap1 = math.abs(gap)


	if gap1 > 50 then
		if gap > 0 then
			self:LeftFun()
		else
			self:RightFun()
		end
		self._dragBeginPos = nil
	end

end

------------------------------------------------------------------
return UISagaBookSyPop


