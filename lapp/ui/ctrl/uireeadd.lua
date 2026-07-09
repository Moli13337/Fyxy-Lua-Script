---
--- Created by Administrator.
--- DateTime: 2023/10/28 18:17:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReeAdd:LWnd
local UIReeAdd = LxWndClass("UIReeAdd", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReeAdd:UIReeAdd()
	---@type table<number, CommonIcon>
	self._uiHeroIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReeAdd:OnWndClose()
	self:ClearCommonIconList(self._uiHeroIconClsList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReeAdd:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReeAdd:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:SetWndText(self.mTitle,ccClientText(14720))
	self:SetWndText(self.mTitle2,ccClientText(14720))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mCloseTip2,ccClientText(10103))
	self:InitEvent()
	self:Refresh()
end

function UIReeAdd:Refresh()
	if self._page == 1 then
		CS.ShowObject(self.mView1,true)
		local str = string.replace(ccClientText(14717),self._addLv)
		self:SetWndText(self.mLvlimitTxt,str)
		self:InitHeroList()
	else
		CS.ShowObject(self.mView2,true)
		local data = {
			refId = 2001,
			IntroTran = self.mEmptyTxt,
			IconTran = self.mEmptyIcon,
			TextBgTran = self.mEmptyBg,
			GetBtn = self.mEmptyBtn,
			GetBtnText = self.mEmptyBtnTxt,
		}
		local emptyList = self:GetCommonEmptyList("_empty")
		emptyList:RefreshUI(data)
	end
end

function UIReeAdd:InitData()
	self._selectIdList = self:GetWndArg("selectList") or {}
	self._addLv = self:GetWndArg("addLv")
	self._page = 1
	if table.isempty(self._selectIdList) then self._page = 2 end
end

function UIReeAdd:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn2,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIReeAdd:InitHeroList()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mHeroList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawHeroCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local heroList = {}
	for i,v in ipairs(self._selectIdList) do
		local serverData = gModelHero:GetHeroServerDataById(v)
		if serverData then
			table.insert(heroList,serverData)
		end
	end

	table.sort(heroList,function(hero1,hero2)
		local star1,star2 = hero1.star,hero2.star
		if star1 ~= star2 then
			return star1 > star2
		else
			return hero1.refId < hero2.refId
		end
	end)
	for i,v in ipairs(heroList) do
		uiList:AddData(v.id,v)
	end

	uiList:RefreshList()
end

function UIReeAdd:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
	local heroIconTrans = CS.FindTrans(item,"HeroIcon")
	if heroIconTrans then
		local id = itemdata.id
		local instanceId = item:GetInstanceID()
		local baseClass = self._uiHeroIconClsList[instanceId]
		if not baseClass then
			baseClass = CommonIcon:New()
			self._uiHeroIconClsList[instanceId] = baseClass
			baseClass:Create(heroIconTrans)
		end
		baseClass:SetHeroPlayer(id)
		baseClass:DoApply()
	end
end
------------------------------------------------------------------
return UIReeAdd


