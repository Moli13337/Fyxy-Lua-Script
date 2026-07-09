---
--- Created by Administrator.
--- DateTime: 2023/10/29 9:59:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISuSpreadPop:LWnd
local UISuSpreadPop = LxWndClass("UISuSpreadPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISuSpreadPop:UISuSpreadPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISuSpreadPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISuSpreadPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISuSpreadPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()

	self:RefreshUI()

end

function UISuSpreadPop:InitUIEvent()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
end

function UISuSpreadPop:RefreshUI()

	local playerData = self:GetWndArg("playerData")

	local headTran = self.mHeadIcon
	local playerInfo =
	{
		trans = headTran,
		icon = playerData.head,
		headFrame = playerData.headFrame,
		level = playerData.level,
		func = function()
			gModelGeneral:PlayerShowReq(playerData.playerId,LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)


	local s = "<#d27c00>[#a1#]</color>#a2#"
	local nameStr = string.replace(s,playerData.serverName,playerData.name)
	self:SetWndText(self.mName,nameStr)
	local powerStr = string.replace(ccClientText(25193),LUtil.NumberCoversion(playerData.power))
	self:SetWndText(self.mPower,powerStr)
	self:SetWndText(self.mWinFail,ccClientText(25289))

	local achieve = string.replace(ccClientText(25239),playerData.winCnt,playerData.failCnt)
	self:SetTextTile(self.mWinFail,achieve)
	--local str = string.replace(ccClientText(25195),playerData.score)
	self:SetWndText(self.mScore,ccClientText(25290))
	self:SetTextTile(self.mScore,playerData.score)
	--str = string.replace(ccClientText(25196),playerData.rank)
	self:SetWndText(self.mRank,ccClientText(25291))
	self:SetTextTile(self.mRank,playerData.rank)
end

function UISuSpreadPop:SetStaticContent()
	local str = ccClientText(25187)--"我的成绩"
	self:SetWndText(self.mTitle,str)
	str = ccClientText(10103)
	self:SetWndText(self.mCloseTip,str)

	CS.ShowObject(self.mMeReportImage, not gLGameLanguage:IsForeignRegion())
end


------------------------------------------------------------------
return UISuSpreadPop


