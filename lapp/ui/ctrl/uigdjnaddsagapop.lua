---
--- Created by BY.
--- DateTime: 2023/10/25 16:07:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdJNAddSagaPop:LWnd
local UIGdJNAddSagaPop = LxWndClass("UIGdJNAddSagaPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdJNAddSagaPop:UIGdJNAddSagaPop()
	self._tabList = {}
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdJNAddSagaPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdJNAddSagaPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdJNAddSagaPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdJNAddSagaPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(13319))
	self:SetWndText(self.mTipsText,ccClientText(13320))

	local list = gModelHero:GetHeroCareerRefs()
	local _uiList = self:GetUIScroll("heroTab")
	_uiList:Create(self.mTabScroll,list,function (...) self:ListItem(...) end)
	self:OnClickTab(list[1].refId)
end

function UIGdJNAddSagaPop:OnClickTab(tab)
	if self._tab then
		if(self._tab == tab)then
			return
		end
		self:SetWndTabStatus(self._tabList[self._tab], LWnd.StateOff)
	end
	self:SetWndTabStatus(self._tabList[tab], LWnd.StateOn)
	self._tab = tab
	self:RefreshHeroList()
end

function UIGdJNAddSagaPop:RefreshHeroList()
	local _tab = self._tab
	if not _tab then
		return
	end
	local heros = gModelHero:GetHeroList()
	local heroList = {}
	for i, v in pairs(heros) do
		-- local hero = heroList[v._refId]
		local ref = gModelHero:GetHeroRef(v._refId)
		-- if ref.careerType == _tab and (not hero or v._star > hero._star) then
		if ref.careerType == _tab then
			-- heroList[v._refId] = v
			table.insert(heroList, v)
		end
	end
	local list = heroList
	-- for i, v in pairs(heroList) do
	-- 	table.insert(list,v)
	-- end
	table.sort(list,function (a,b)
		if a._star ~= b._star then
			return a._star > b._star
		end
		return a._level > b._level
	end)

	local uilist = self._heroUiList
	if not uilist then
		uilist = self:GetUIScroll("heroList")
		uilist:Create(self.mHeroSuper,list,function (...) self:OnDrawHeroCell(...)  end,UIItemList.SUPER_GRID)
		uilist:EnableScroll(true,false)
		self._heroUiList = uilist
	else
		uilist:RefreshList(list)
		local _uiList = uilist:GetList()
		_uiList:DrawAllItems()
	end
end

function UIGdJNAddSagaPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end

function UIGdJNAddSagaPop:ListItem(list, item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab1")
	self._tabList[itemdata.refId] = btnTab
	self:SetWndTabStatus(btnTab, LWnd.StateOff)
	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndClick(btnTab,function  ()
		self:OnClickTab(itemdata.refId)
	end)
end

function UIGdJNAddSagaPop:InitMessage()

end

function UIGdJNAddSagaPop:CreateIcon(trans,key)
	local uiCommonList = self._uiCommonList
	local baseClass = uiCommonList[key]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		uiCommonList[key] = baseClass
		baseClass:Create(trans)
	end
	return baseClass
end

function UIGdJNAddSagaPop:OnDrawHeroCell(list,item, itemdata, itempos)
	if not itemdata then
		return
	end
	local id = itemdata._id
	local fightPower = itemdata._fightPower
	local instanceID = item:GetInstanceID()

	local CommonUI = self:FindWndTrans(item,"Root")
	if CommonUI then
		local baseClass = self:CreateIcon(CommonUI,instanceID)
		baseClass:SetHeroPlayer(id)
		baseClass:DoApply()

		self:SetWndClick(CommonUI,function()
			local data = {
				id = id,
				refId = itemdata._refId,
				level = itemdata._level,
				star = itemdata._star,
				grade = itemdata._grade,
				fightPower = fightPower,
				isResonance = itemdata._isResonance,
				skin = itemdata._skin,
			}
			gModelHero:ReqShowHeroTip("",data)
		end)
	end
end
------------------------------------------------------------------
return UIGdJNAddSagaPop


