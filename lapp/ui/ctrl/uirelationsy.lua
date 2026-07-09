---
--- Created by Administrator.
--- DateTime: 2023/10/10 20:02:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRelationSy:LWnd
local UIRelationSy = LxWndClass("UIRelationSy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRelationSy:UIRelationSy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRelationSy:OnWndClose()

	local haveHero = gModelHeroBook:GetHeroRelationActNum(self._relationRefId)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"羁绊故事close",self._relationRefId,haveHero)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRelationSy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRelationSy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTitleText,ccClientText(19746))
	self:InitEvent()
	self:InitData()
	self:RefreshView()
end

function UIRelationSy:RefreshView()
	local relationRefId = self._relationRefId
	local ref = gModelHeroBook:GetHeroRelationRefByRefId(relationRefId)
	if not ref then return end
	local relationStory = ccLngText(ref.relationStory)
	self:SetWndText(self.mContentText,relationStory)
	local listPrefabName = ref.listPrefabName
	self:CreateWndPrefab(self.mRoot,listPrefabName,listPrefabName,function(trans)
		local HeroBookName2Trans = self:FindWndTrans(trans,"HeroBookName2")
		if HeroBookName2Trans then
			local NameTxt = self:FindWndTrans(HeroBookName2Trans,"NameTxt")
			self:SetWndText(NameTxt,ccLngText(ref.name))
		end
	end ,CS.RES_UI_HEROBOOK)
end

function UIRelationSy:InitEvent()
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIRelationSy:InitData()
	self._relationRefId = self:GetWndArg("relationRefId")
	self._maxCount = 780
end
------------------------------------------------------------------
return UIRelationSy


