---
--- Created by BY.
--- DateTime: 2023/10/5 22:22:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdMeleeResult:LWnd
local UIGdMeleeResult = LxWndClass("UIGdMeleeResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdMeleeResult:UIGdMeleeResult()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdMeleeResult:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdMeleeResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdMeleeResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdMeleeResult:OnClickApplyGuildCell(guildId,sevenId)
	gModelGuild:OnGuildMemberListReq(guildId,sevenId)
end

function UIGdMeleeResult:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnOk,function (...) self:WndClose() end)
end

function UIGdMeleeResult:InitMessage()
	self:WndEventRecv(EventNames.ON_GUILD_MELEE_RESULT,function (isShow)
		if not self:IsWndClosed() then
			CS.ShowObject(self.mPopMag,isShow)
		end
	end)
end

--设置形象
function UIGdMeleeResult:SetSpine(paintTans,ref,key)
	local paintFlip = ref.paintFlip2 == 1
	local paintMultiple = ref.paintMultiple2
	self:CreateWndSpine(paintTans,ref.spine,key,false,function(dpSpine)
		dpSpine:SetScale(paintMultiple)
		dpSpine:SetFlipX(paintFlip)
		local dpTrans =dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
	end)
end

function UIGdMeleeResult:OnTryTcpReconnect()
	self:WndClose()
end

function UIGdMeleeResult:SetRankInfo(trans,info)
	if not info then
		return
	end
	local root = CS.FindTrans(trans,"Root")
	-- local playIcon = CS.FindTrans(root,"Mask/PlayIcon")
	local serverNameText = CS.FindTrans(root,"ServeText")
	local guildNameText = CS.FindTrans(root,"GuildNameText")
	local nameText = CS.FindTrans(root,"NameText")
	local powerText = CS.FindTrans(root,"Bg/PowerText")
	local flagBg = CS.FindTrans(root,"FlagBg")
	local flagIcon = CS.FindTrans(root,"FlagBg/FlagIcon")
	local lvText = CS.FindTrans(root,"FlagBg/LvBg/LvText")

	local serverName = gModelFriend:GetSevenName(info.serverId)
	--local guildName = string.replace(ccClientText(17957),info.guildName,serverName)
	self:SetWndText(serverNameText,serverName)
	self:SetWndText(guildNameText,info.guildName)
	self:SetWndText(nameText,string.replace(ccClientText(17966),info.signUpCount))
	self:SetWndText(powerText,LUtil.NumberCoversion(info.powerCount))
	-- local ref = gModelPlayer:GetRoleAdventureImage(info.chairmanFigure)
	-- local key = info.chairmanId
	-- if(not ref)then
	-- 	return
	-- end
	-- self:SetSpine(playIcon,ref,key)
	local bgRef = gModelGuild:GetGuildFlagRefByRefId(info.flagBgId)
	local iconRef = gModelGuild:GetGuildFlagRefByRefId(info.flagId)
	if bgRef then
		self:SetWndEasyImage(flagBg,bgRef.res)
		CS.ShowObject(flagBg,true)
	end
	if iconRef then
		self:SetWndEasyImage(flagIcon,iconRef.res)
	end
	self:SetWndText(lvText,string.replace(ccClientText(17992),info.level))
	self:SetWndClick(trans,function ()
		self:OnClickApplyGuildCell(info.guildId,info.serverId)
	end)
end

function UIGdMeleeResult:InitCommand()
	local transList = {
		self.mRank1,
		self.mRank2,
		self.mRank3,
	}
	self:SetWndText(self.mLblBiaoti,ccClientText(17968))
	self:InitTextLineWithLanguage(self.mLblBiaoti,-40)
	self:SetWndText(self.mMyTitle,ccClientText(17985))
	self:SetWndText(self.mFightInfoTitle, ccClientText(17986))
	self:SetWndText(self.mRankInfoTitle, ccClientText(17987))
	self:SetWndText(self.mHistoryInfoTitle, ccClientText(17988))
	self:SetWndText(self.mGuessInfoTitle, ccClientText(17989))
	self:SetWndButtonText(self.mBtnOk,ccClientText(17991))

	local list = self:GetWndArg("resultList")

	for i, v in ipairs(transList) do
		self:SetRankInfo(v,list[i])
	end

	local figure = gModelPlayer:GetPlayerFigure()
	local figureRef = gModelPlayer:GetRoleAdventureImage(figure)
	if figureRef then
		self:SetSpine(self.mMySpineNode,figureRef,"mySpine")
	end

	local data = self:GetWndArg("data")
	if not data then
		return
	end
	self:SetWndText(self.mFightInfoValue, string.replace(ccClientText(17990),data.winCount,data.loseCount))
	self:SetWndText(self.mRankInfoValue, data.integralRank)
	local bestIntegralRank = data.bestIntegralRank
	if bestIntegralRank == 0 then
		bestIntegralRank = ccClientText(17216)
	end
	self:SetWndText(self.mHistoryInfoValue, bestIntegralRank)
	self:SetWndText(self.mGuessInfoValue, data.integral)
end
------------------------------------------------------------------
return UIGdMeleeResult


