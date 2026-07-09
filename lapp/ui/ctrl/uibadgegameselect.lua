---
--- Created by Administrator.
--- DateTime: 2025/9/15 14:43:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBadgeGameSelect:LWnd
local UIBadgeGameSelect = LxWndClass("UIBadgeGameSelect", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBadgeGameSelect:UIBadgeGameSelect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBadgeGameSelect:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBadgeGameSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBadgeGameSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIBadgeGameSelect:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
	self:WndNetMsgRecv(LProtoIds.BadgeGameBarrierStarResp,function(...) self:OnBadgeGameBarrierStarResp(...) end)
end

function UIBadgeGameSelect:OnClickChangeMode(mode)
	GF.OpenWnd("UIBrandGameWin",{
		chapterType = mode,
		isSel = true,
	})
	self:WndClose()
end

function UIBadgeGameSelect:OnEventXXXXX()
end

function UIBadgeGameSelect:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnNormal,function() self:OnClickChangeMode(ModelBadgeGame.CHAPTER_NORMAL) end)
	self:SetWndClick(self.mBtnNightmare,function() self:OnClickChangeMode(ModelBadgeGame.CHAPTER_NIGHTMARE) end)
end

function UIBadgeGameSelect:RefreshView()
	self:SetRed(self.mBtnNormal,gModelBadgeGame:GetBadgeGameRed(ModelBadgeGame.CHAPTER_NORMAL))
	self:SetRed(self.mBtnNightmare,gModelBadgeGame:GetBadgeGameRed(ModelBadgeGame.CHAPTER_NIGHTMARE))
end

function UIBadgeGameSelect:OnBadgeGameBarrierStarResp(pb)
	local ref = GameTable.BadgeGameBarrierRef[pb.barrierId]
	self:SetWndText(self.mNormalInfoTxt,string.replace(ccClientText(40238),pb.star,ref and ref.nameMap or 0))

	ref = GameTable.BadgeGameBarrierRef[pb.nightmareBarrierId]
	self:SetWndText(self.mNightmareInfoTxt,string.replace(ccClientText(40238),pb.nightmareStar,ref and ref.nameMap or 0))
	CS.ShowObject(self.mNormalInfoBg,true)
	CS.ShowObject(self.mNightmareInfoBg,true)
end

function UIBadgeGameSelect:InitText()
	self:SetXUITextText(self.mLblBiaoti,ccClientText(40200))
end

function UIBadgeGameSelect:InitData()

	gModelBadgeGame:OnBadgeGameBarrierStarReq()
end



------------------------------------------------------------------
return UIBadgeGameSelect