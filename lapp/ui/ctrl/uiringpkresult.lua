---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIringPkResult:LWnd
local UIringPkResult = LxWndClass("UIringPkResult", LWnd)
------------------------------------------------------------------
---@type LUIHeroObject
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

UIringPkResult.CHAMPION = 1
UIringPkResult.PEAK = 2



--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIringPkResult:UIringPkResult()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIringPkResult:OnWndClose()
	LUtil.ClearHashTable(self._playerHeroMap)
	self._playerHeroMap = {}
	
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIringPkResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIringPkResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitEvent()
	self:InitView()
	--self:DoWndStartScale(0, self.mView, function() self:RemoveWndStartScale() end )
end
function UIringPkResult:InitData()
	self._pbData = self:GetWndArg(1)

	self._wndType = self:GetWndArg("wndType") or UIringPkResult.CHAMPION


	self._playerHeroMap = {}

	self._rankThree =
	{
		self.mRank1,
		self.mRank2,
		self.mRank3,
	}

end

function UIringPkResult:InitEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnOk,function () self:WndClose() end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIringPkResult:RefreshThreeRank(playerInfos)
	for i = 1, #playerInfos do
		if self._rankThree[i] then
			local root = CS.FindTrans(self._rankThree[i], "Root2")
			CS.ShowObject(root,true)
			self:InitRankItem(root,playerInfos[i])
		end
	end
end

function UIringPkResult:InitView()
	local infos = self._pbData.infos
	self:RefreshThreeRank(infos)

	local figure = gModelPlayer:GetPlayerFigure()
	local figureRef = gModelPlayer:GetRoleAdventureImage(figure)
	if figureRef then
		local instanceID = self.mMySpineNode:GetInstanceID()
		local newHeroObj = LUIHeroObject:New(self)
		newHeroObj:Create(self.mMySpineNode, figureRef.spine, figureRef.spine)
		newHeroObj:SetScale(2)
		self._playerHeroMap[instanceID] = newHeroObj
		newHeroObj:StartLoad()
	end
	self:SetWndButtonText(self.mBtnOk, ccClientText(17583))
	self:SetWndText(self.mTitleText, ccClientText(11852))
	self:SetWndText(self.mMyTitle, ccClientText(17572))
	self:SetWndText(self.mFightInfoTitle, ccClientText(17572))
	self:InitTextLineWithLanguage(self.mFightInfoTitle, -30)
	self:InitTextSizeWithLanguage(self.mFightInfoTitle, -2)
	self:SetWndText(self.mRankInfoTitle, ccClientText(17573))
	self:InitTextLineWithLanguage(self.mRankInfoTitle, -30)
	self:InitTextSizeWithLanguage(self.mRankInfoTitle, -2)
	self:SetWndText(self.mHistoryInfoTitle, ccClientText(17574))
	self:InitTextLineWithLanguage(self.mHistoryInfoTitle, -30)
	self:InitTextSizeWithLanguage(self.mHistoryInfoTitle, -2)
	self:SetWndText(self.mGuessInfoTitle, ccClientText(17575))
	self:InitTextLineWithLanguage(self.mGuessInfoTitle, -30)
	self:InitTextSizeWithLanguage(self.mGuessInfoTitle, -2)
	local winCount = self._pbData.winCount
	local loseCount = self._pbData.battleCount - winCount
	self:SetWndText(self.mFightInfoValue, string.replace(ccClientText(17576), winCount, loseCount))
	local rank = self._pbData.rank
	local rankMax = self._pbData.rankMax
	if rank < 0 then
		rank = ccClientText(17512)
	end
	if rankMax < 0 then
		rankMax = ccClientText(17512)
	end
	self:SetWndText(self.mRankInfoValue, rank)
	self:SetWndText(self.mHistoryInfoValue, rankMax)
	self:SetWndText(self.mGuessInfoValue, self._pbData.guessCoin)
end
function UIringPkResult:InitRankItem(item,playerInfo)
	local instanceID = item:GetInstanceID()

	local nameText = CS.FindTrans(item,"NameText")
	local guildNameText = CS.FindTrans(item,"GuildNameText")
	local serverNameText = CS.FindTrans(item,"ServerNameText")

	local name =  playerInfo.name
	--local serverName = playerInfo.serverName

	local serverName = gLGameLogin:GetServerShotNameById(playerInfo.serverId)
	--if self._wndType == UIringPkResult.PEAK then
	--	serverName = gLGameLogin:GetServerName()
	--else
	--	serverName = gLGameLogin:GetServerShotNameById(playerInfo.serverId) --gModelCrossServer:GetServerName(playerInfo.serverId)
	--end
	--local serverName = string.replace(ccClientText(138), tostring(playerInfo.serverId))
	serverName = string.replace(ccClientText(138), serverName)

	self:SetWndText(serverNameText, serverName)
	if string.isempty(playerInfo.guildName) then
		self:SetWndText(guildNameText,ccClientText(11526))
	else
		self:SetWndText(guildNameText,playerInfo.guildName)
	end
	self:SetWndText(nameText, name)

	local powerText = CS.FindTrans(item,"Bg/PowerText")
	self:SetWndText(powerText, LUtil.PowerNumberCoversion(playerInfo.score))

	local playIcon = CS.FindTrans(item, "Mask/PlayIcon")
	local figure = playerInfo.figure
	local figureRef = gModelPlayer:GetRoleAdventureImage(figure)
	if figureRef then
		local newHeroObj = LUIHeroObject:New(self)
		newHeroObj:Create(playIcon, figureRef.spine, figureRef.spine)
		newHeroObj:SetLoadedFunction(function(heroObj)
			heroObj:SetScale(2)
		end)
		newHeroObj:SetClickFunc(function()
			local playerId = playerInfo.playerId
			if playerId == 0 or playerId == gModelPlayer:GetPlayerId() then
				GF.ShowMessage(ccClientText(11522))
				return
			end
			local combatType = LCombatTypeConst.COMBAT_MAIN

			gModelGeneral:PlayerShowReq(playerInfo.playerId,combatType,LPlayerShowConst.OTHER_SYSTEM)
		end)

		self._playerHeroMap[instanceID] = newHeroObj
		newHeroObj:StartLoad()
	end

end

------------------------------------------------------------------
return UIringPkResult


