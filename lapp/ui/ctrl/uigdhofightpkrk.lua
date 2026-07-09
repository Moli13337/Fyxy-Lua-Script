---
--- Created by Administrator.
--- DateTime: 2024/10/22 20:20:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkRk:LWnd
local UIGdHoFightPkRk = LxWndClass("UIGdHoFightPkRk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkRk:UIGdHoFightPkRk()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkRk:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkRk:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkRk:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self.jpj = gLGameLanguage:IsJapanVersion()
	gModelGuildHolyPeak:GuildPinnacleGuildInfoReq()
end

function UIGdHoFightPkRk:SetRankTrans(orther, trans, data, rank, isSelf)
	local FlagBg = CS.FindTrans(trans, "FlagBg")
	local FlagIcon = CS.FindTrans(FlagBg, "FlagIcon")
	local GuildLvText = CS.FindTrans(FlagBg, "GuildLvBg/GuildLvText")
	local ServerText = CS.FindTrans(trans, "ServerText")
	local NameText = CS.FindTrans(trans, "NameText")
	local powerBg = CS.FindTrans(trans, "PowerBg")
	local powerText = CS.FindTrans(trans, "PowerBg/PowerText")
	local MeTitleText = CS.FindTrans(trans, "Image/MeTitleText")
	local rankText = CS.FindTrans(trans, "RankText")
	local rankImg = CS.FindTrans(trans, "RankImg")
	local noText = CS.FindTrans(trans, "NoText")
	local guildNameText = CS.FindTrans(trans, "GuildNameText")

	self:SetWndText(MeTitleText, ccClientText(10339))
	if data == 1 or not data then
		if noText then
			self:SetWndText(noText, ccClientText(11736))
			CS.ShowObject(noText, true)
		end
		if guildNameText then
			self:SetWndText(guildNameText, ccClientText(11736))
			CS.ShowObject(guildNameText, true)
		end
		self:SetWndText(ServerText, "")
		self:SetWndText(NameText, "")
		self:SetWndText(GuildLvText, "")
		self:SetWndText(powerText, "")
		if not orther and not isSelf then
			self:SetWndText(NameText, ccClientText(11736))
		end
		CS.ShowObject(rankText, false)
		CS.ShowObject(rankImg, false)
		CS.ShowObject(FlagBg, false)
		CS.ShowObject(powerBg, false)
		if self.jpj then
			local textTran = LxUiHelper.FindXTextCtrl(NameText)

			textTran.enableWordWrapping = true
		end
	else
		CS.ShowObject(FlagBg, true)
		if noText then
			CS.ShowObject(noText, false)
		end
		if guildNameText then
			CS.ShowObject(guildNameText, false)
		end

		local flagRes = gModelGuild:GetGuildFlagRefByRefId(data.flagBgId).res
		local iconRes = gModelGuild:GetGuildFlagRefByRefId(data.flagId).res
		self:SetWndEasyImage(FlagBg, flagRes)
		self:SetWndEasyImage(FlagIcon, iconRes)
		self:SetWndText(ServerText, "【" .. gLGameLogin:GetServerShotNameById(data.serverId) .. "】")
		self:SetWndText(NameText, data.guildName)
		self:SetWndText(GuildLvText, data.level)
		self:SetWndText(powerText, LUtil.NumberCoversion(data.guildPower))

		CS.ShowObject(powerBg, true)
	end

	if orther then
		if rank == 1 then
			self:SetWndText(rankText, 4)
		elseif rank > 1 and rank <= 5 then
			self:SetWndText(rankText, 8)
		elseif rank > 5 then
			self:SetWndText(rankText, 16)
		end
		CS.ShowObject(rankText, true)
	end

	if isSelf == true and data then
		local trueRank = rank
		if rank > 4 and rank <=8 then
			trueRank = 8
		elseif rank > 8 then
			trueRank = 16
		end
		if trueRank > 3 then
			self:SetWndText(rankText, trueRank)
		else
			local res = "public_num_" .. trueRank
			self:SetWndEasyImage(rankImg, res)
		end
		CS.ShowObject(rankText, trueRank > 3)
		CS.ShowObject(rankImg, trueRank <= 3)
	end

	self:SetWndClick(trans, function()
		if data and data ~= 1 then
			gModelGuild:OnGuildMemberListReq(data.guildId, data.serverId)
		end
	end)
end

function UIGdHoFightPkRk:UpdateRank()
	local list = gModelGuildHolyPeak:GetGuildInfoList()
	local topThree = {nil, nil, nil}
	local list2 = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 }
	local selfData
	local selfRank
	for i = 1, 16 do
		local v = list[i]
		if v and v.rank <= 3 and v.rank ~= 0 then
			topThree[v.rank] = v
		elseif v and v.rank == 4 then
			list2[1] = v
		elseif v and v.rank == 8 then
			for i = 2, 5 do
				if list2[i] == 1 then
					list2[i] = v
					break
				end
			end
		elseif v and v.rank == 16 then
			for i = 6, 13 do
				if list2[i] == 1 then
					list2[i] = v
					break
				end
			end
		end

		local guildId = gModelPlayer:GetGuildId()
		if v and guildId == v.guildId and v.rank ~= 0 then
			selfData = v
			selfRank = v.rank
		end
	end
	for i = 1, 3 do
		local trans = CS.FindTrans(self.mGuildRank, "Rank" .. i)
		self:SetRankTrans(nil, trans, topThree[i], i)
	end
	self:SetRankTrans(nil, self.mMeGuildRankItem, selfData, selfRank, true)

	if not self.uiList then
        self.uiList = self:GetUIScroll("list")
        self.uiList:Create(self.mGuildCellScroll, list2, function(...)
            self:SetRankTrans(...)
        end, UIItemList.WRAP)
    else
        self.uiList:RefreshData(list2)
    end
end

function UIGdHoFightPkRk:InitCommon()
	------------------------------------------------------------------
	---text
    self:SetWndText(self.mTitle, ccClientText(44052))
    self:SetWndText(self.mCloseTip, ccClientText(10103))

	------------------------------------------------------------------
	---event
	self:WndEventRecv("GuildPinnacleGuildInfoResp", function()
		self:UpdateRank()
	end)

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end



------------------------------------------------------------------
return UIGdHoFightPkRk