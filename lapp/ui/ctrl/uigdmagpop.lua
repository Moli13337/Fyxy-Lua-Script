---
--- Created by BY.
--- DateTime: 2023/10/16 17:54:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdMagPop:LWnd
local UIGdMagPop = LxWndClass("UIGdMagPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdMagPop:UIGdMagPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdMagPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdMagPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdMagPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdMagPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end

function UIGdMagPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(12474))
	local list={
		{type=1,text=ccClientText(12428),redPoint = 1},
		{type=2,text=ccClientText(12481),redPoint = ModelRedPoint.GUILD_APPLYFOR},
		{type=3,text=ccClientText(17914),redPoint = 3},
		{type=6,text=ccClientText(12603),redPoint = 7},
		{type=4,text=ccClientText(12555),redPoint = 4},
		{type=5,text=ccClientText(12427),redPoint = 6},
		-- {type=7,text=ccClientText(12609),redPoint = 7, showFunc = function() return self:CheckShowLanguage() end},【D多语言】删除多语言联盟机制（客户端&服务端）
	}
	local uiList = self:GetUIScroll("btnList")
	uiList:Create(self.mMagScroll,list,function (...) self:ListItem(...) end)
end

function UIGdMagPop:InitMessage()

end

function UIGdMagPop:OnClickMangeBtn(index)
	local callFunc = function()
		GF.OpenWnd("UIGdMagPop")
	end
	if(index == 1)then
		GF.OpenWnd("UIGdRecruitPop",{callFunc = callFunc})
	elseif(index == 2)then
		GF.OpenWnd("UIGdApplyForPop",{callFunc = callFunc})
	elseif(index == 3)then
		GF.OpenWnd("UIGdReNamePop",{callFunc = callFunc})
	elseif(index == 4)then
		GF.OpenWnd("UIGdMilPop",{callFunc = callFunc})
	elseif(index == 5)then
		self:OnClickSendRecruit(callFunc)
	elseif(index == 6)then
		local guildInfo = gModelGuild:GetGuildInfo()
		GF.OpenWnd("UIGdFlagPop",{confirmType = ModelGuild.GUILD_FLAG_TYPE_ALTER,flagId = guildInfo.flagId,flagBgId = guildInfo.flagBgId,callFunc = callFunc})
	-- 【D多语言】删除多语言联盟机制（客户端&服务端）
	-- elseif(index == 7)then
	-- 	GF.OpenWnd("WndGuildLanguage",{callFunc = callFunc})
	end
	if(index ~= 5)then
		self:WndClose()
	end
end

function UIGdMagPop:CheckShowLanguage()
	local isForeign = gLGameLanguage:IsUSARegion()
	return isForeign
end

function UIGdMagPop:OnClickSendRecruit(callFunc)
	local guildInfo=gModelGuild:GetGuildInfo()
	local levelLimit=guildInfo.levelLimit
	local approve=1
	if(guildInfo.approve==1)then
		approve=2
	else
		approve=1
	end
	local approveStr=""
	local list={
		ccClientText(12429),
		ccClientText(12489),
	}
	approveStr=list[approve]
	local num = guildInfo.recruitCount
	local sendNum = gModelGuild:GetGuildConfigRefByKey("recruitMaxNum")
	local freeNum = gModelGuild:GetGuildConfigRefByKey("recruitFreeTimes")
	if(num < freeNum)then
		-- GF.OpenWnd("UIGdRecruitTips",{refId=100002,para2={approveStr,levelLimit},para={sendNum-num},func=function (...)
		-- 	gModelGuild:OnGuildRecruitReq()
		-- end })
		gModelGeneral:OpenUIOrdinTips({
			refId = 100002,
			para = {sendNum-num},
			func = function() gModelGuild:OnGuildRecruitReq() end
		})
		return
	end
	if(num < sendNum)then
		local item=gModelGuild:GetRecruitSpend()
		-- local itemRefId = item.refId
		local itemCount = item.count
		-- GF.OpenWnd("UIGdRecruitTips",{refId=100003,para2={approveStr,levelLimit},para={itemCount,sendNum-num},func=function (...)
		-- 	gModelGuild:OnGuildRecruitReq()
		-- end , consume ={itemCount, itemRefId}})

		gModelGeneral:OpenUIOrdinTips({
			refId = 100003,
			para = {itemCount, sendNum - num},
			func = function() gModelGuild:OnGuildRecruitReq() end
		})
		return
	end
	GF.ShowMessage(ccClientText(12492))
end

function UIGdMagPop:ListItem(list , item, itemdata, itempos)
	local showFunc = itemdata.showFunc
	local isShow  = not showFunc or showFunc()
	CS.ShowObject(item, isShow)
	if not isShow then return end

	local icon = CS.FindTrans(item,"Image/Icon")
	local nameText = CS.FindTrans(item,"Image/Image/NameText")
	local iconStr = ""
	if itemdata.type == 1 then
		iconStr = "guild_icon_9"
	elseif itemdata.type == 2 then
		iconStr = "guild_icon_8"
	elseif itemdata.type == 3 then
		iconStr = "guild_icon_6"
	elseif itemdata.type == 4 then
		iconStr = "guild_icon_7"
	elseif itemdata.type == 5 then
		iconStr = "guild_icon_4"
	elseif itemdata.type == 6 then
		iconStr = "guild_icon_19"
	elseif itemdata.type == 7 then
		iconStr = "guild_icon_20"
	end

	self:SetWndEasyImage(icon,iconStr)
	self:SetWndText(nameText,itemdata.text)
	self:SetWndClick(item, function(...) self:OnClickMangeBtn(itemdata.type) end)
end
------------------------------------------------------------------
return UIGdMagPop


