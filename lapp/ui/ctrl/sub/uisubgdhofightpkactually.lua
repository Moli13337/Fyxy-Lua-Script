---
--- Created by Administrator.
--- DateTime: 2024/10/17 15:59:29
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGdHoFightPkActually:LChildWnd
local UISubGdHoFightPkActually = LxWndClass("UISubGdHoFightPkActually", LChildWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LFightIdleConst = LFightIdleConst
------------------------------------------------------------------

---@type number 连赢最大次数
local WinMaxNum = 3

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGdHoFightPkActually:UISubGdHoFightPkActually()
	---@type table<string,number> 阵容A连赢次数
	self._winACnt = {}
	---@type table<string,number> 阵容B连赢次数
	self._winBCnt = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGdHoFightPkActually:OnWndClose()
	if self.spine1 then
		self.spine1:Destroy()
		self.spine1 = nil
	end
	if self.spine2 then
		self.spine2:Destroy()
		self.spine2 = nil
	end
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGdHoFightPkActually:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGdHoFightPkActually:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitCommon()

	gModelGuildHolyPeak:GuildPinnacleBattlefieldReq(self.id, 1)
end

function UISubGdHoFightPkActually:InitCommon()
	------------------------------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.GuildPinnacleBattlefieldResp, function(pb)
		self:SetData(pb)
		self.curIndex = 1

		self._winACnt = {}
		self._winBCnt = {}
		
		self:PlayFight()
	end)

	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	self.roleList = {}
	self.dieList = {}
	self.fightPlayer = {}
	self.allPlayer = {}
	self.playerShowData = {}
	self.dieNum = {0, 0}
	self.fightNum = {0, 0}

	------------------------------------------------------------------
	---eff
	self:CreateWndEffect(self.mFightEff, "fx_ui_sqzz_zhankuang", "fx_ui_sqzz_zhankuang", 100)
end

function UISubGdHoFightPkActually:SetRoleList(roleList, data, index)
	local list = {}
	for _, v in ipairs(data) do
		local t = {
			playerId = v.playerId,
			playerName = v.playerName,
			avatar = v.avatar,
			avatarFrame = v.avatarFrame,
			lvl = v.lvl,
		}
		if v.playerId ~= "0" then
			table.insert(list, t)
			self.playerShowData[v.playerId] = {
				image = v.image,
				name = v.playerName,
				avatar = v.avatar,
				avatarFrame = v.avatarFrame,
			}
		end
	end
	self.allPlayer[index] = #list
	if self.roleList[index] then
		self.roleList[index]:RefreshList(list)
		self.roleList[index]:DrawAllItems()
	else
		self.roleList[index] = self:GetUIScroll("roleList" .. index)
		self.roleList[index]:Create(roleList, list, function(...) self:DrawRole(...) end, UIItemList.SUPER_GRID)
	end
end

function UISubGdHoFightPkActually:SetData(pb)
	if pb.id ~= self.id then return end

	self.data = {}
	for _, v in ipairs(pb.fightInfo) do
		local t = {
			guild1 = {
				guildId = v.guildA,
				playerId = v.memberA,
				maxHp = v.maxHpA,
				hp = v.hpA
			},
			guild2 = {
				guildId = v.guildB,
				playerId = v.memberB,
				maxHp = v.maxHpB,
				hp = v.hpB
			},
		}
		table.insert(self.data, t)
		if not self.guildA then
			self.guildA = v.guildA
		end
		if not self.guildB then
			self.guildB = v.guildB
		end
	end

	local disposeMembersFunc = function(memberPb)
		local playerId = memberPb.playerId
		if playerId ~= "0" then
			return {
				playerId = playerId,
				playerName = memberPb.playerName,
				playerPower = memberPb.playerPower,
				avatar = memberPb.avatar,
				avatarFrame = memberPb.avatarFrame,
				lvl = checknumber(memberPb.lvl),
				image = memberPb.image,
			}
		end
	end

	local membersA,membersB = {},{}
	for i,v in ipairs(pb.membersA) do
		local data = disposeMembersFunc(v)
		if data then
			table.insert(membersA,data)
		end
	end
	for i,v in ipairs(pb.membersB) do
		local data = disposeMembersFunc(v)
		if data then
			table.insert(membersB,data)
		end
	end
	self._membersA = membersA
	self._membersB = membersB


	self:SetGuildInfo(self.mGuild1, self.guildA)
	self:SetGuildInfo(self.mGuild2, self.guildB)

	self:SetRoleList(CS.FindTrans(self.mGuild1, "RoleList"), pb.membersA, 1)
	self:SetRoleList(CS.FindTrans(self.mGuild2, "RoleList"), pb.membersB, 2)
	self:UpdataNum()
end

function UISubGdHoFightPkActually:SetGuildInfo(trans, id)
	local flag = CS.FindTrans(trans, "Flag")
	local icon = CS.FindTrans(trans, "Icon")
	local lvl = CS.FindTrans(trans, "Lvl")
	local name = CS.FindTrans(trans, "Name")
	local win = CS.FindTrans(trans, "Win")
	local lose = CS.FindTrans(trans, "Lose")

	local data = gModelGuildHolyPeak:GetGuildInfoById(id)
	local flagRes = gModelGuild:GetGuildFlagRefByRefId(data.flagBgId).res
	local iconRes = gModelGuild:GetGuildFlagRefByRefId(data.flagId).res
	self:SetWndEasyImage(flag, flagRes)
	self:SetWndEasyImage(icon, iconRes)
	self:SetWndText(name, data.guildName)
	self:SetWndText(lvl, data.level .. ccClientText(46014))
end

function UISubGdHoFightPkActually:DrawRole(_, trans, data, index)
	local off = CS.FindTrans(trans, "Off")
	local offNum = CS.FindTrans(off, "num")
	local die = CS.FindTrans(trans, "Die")
	local on = CS.FindTrans(trans, "On")
	local headIcon = CS.FindTrans(on, "HeadIcon")
	local select = CS.FindTrans(on, "Select")

	if data.playerId ~= 0 then
		local isDie = self.dieList[data.playerId]
		if isDie then
			CS.ShowObject(die, true)
			CS.ShowObject(on, false)
		else
			local instanceId = trans:GetInstanceID()
			local playerInfo = {
				trans = headIcon,
				playerId = data.playerId,
				icon = data.avatar,
				headFrame = data.avatarFrame,
				level = data.lvl,
			}
			local headIconCls = self:GetHeadIcon(instanceId)
			headIconCls:SetHeadData(playerInfo)

			CS.ShowObject(on, true)
			CS.ShowObject(select, self.fightPlayer[data.playerId])
			if self.fightPlayer[data.playerId] then
				local insId = select:GetInstanceID()
				self:CreateWndEffect(select, "fx_ui_sqzz_xuanzhong", insId, 50)
			end
		end
	else
		self:SetWndText(offNum, index)
		CS.ShowObject(off, true)
		CS.ShowObject(die, false)
		CS.ShowObject(on, false)
	end
end

function UISubGdHoFightPkActually:PlayFight()
	self.time = 0
	local data = self.data[self.curIndex]
	if not self.data then
		return
	end

	if not self.eff then
		self.eff = self:CreateWndEffect(self.mEff, "fx_zhandoujinchangtuzi", "eff", 100)
	end

	local dieIndex = data.guild1.hp < data.guild2.hp and 1 or 2

	local playerA = data.guild1.playerId
	local playerB = data.guild2.playerId
	if dieIndex == 1 then
		local winBCnt = self._winBCnt[playerB] or 0
		self._winBCnt[playerB] = winBCnt + 1
	else
		local winACnt = self._winACnt[playerA] or 0
		self._winACnt[playerA] = winACnt + 1
	end


	self.fightPlayer = {}
	for i = 1, 2 do
		local info = data["guild" .. i]
		self.fightPlayer[info.playerId] = true
		if self.roleList[i] then
			self.roleList[i]:DrawAllItems()
		end
		local seqCom = self:GetSeqCom()
		seqCom:DeleteSeq("spine" .. i)
		local showData = self.playerShowData[info.playerId]
		local ref = gModelPlayer:GetRoleAdventureImage(showData.image)
		local effId = ref.hero
		local heroId = GameTable.CharacterEffectRef[effId].heroType
		local starCfg = gModelHero:GetHeroStarRef(heroId)
		local skillData = LFightIdleConst.CreateSkillData(starCfg.commonSkill, true)
		local effList = skillData:GetPlayEffList()
		local trans = self["mSpine" .. i]
		local root = CS.FindTrans(trans, "Root")
		local nameText = CS.FindTrans( trans, "Name")
		local bar = CS.FindTrans(trans, "BarBg/Bar")
		local bar2 = CS.FindTrans(trans, "BarBg/Bar2")
		local btRoot = CS.FindTrans(trans, "BtRoot")
		if self._isEnus then
			nameText = CS.FindTrans( trans, "Name_Enus")
		end


		for i = 1, 5 do
			local btHurt = CS.FindTrans(btRoot, "BtHurt" .. i)
			btHurt.localPosition = Vector2.New(0, 160)
			self:SetCanvasGroupAlpha(btHurt, 0)
		end


		--位置血条初始化
		local num = i == 1 and -1 or 1
		trans.localPosition = Vector2.New(417 * num, 233.8)
		LxUiHelper.SetProgress(bar, 1)
		LxUiHelper.SetProgress(bar2, 1)
		self:SetWndText(nameText, showData.name)
		local allHp = info.maxHp - info.hp
		local stepHp = tonumber(info.maxHp) > 0 and allHp / info.maxHp / 4 or 0
		self["spine" .. i] = LUIHeroObject:New(self)
		local lUIHeroObject = self["spine" .. i]
		lUIHeroObject:Create(root, "spine" .. i, ref.spine)
		lUIHeroObject:SetScale(1.5)
		lUIHeroObject:SetLoadedFunction(function()
			local seqCom = self:GetSeqCom()
			seqCom:DeleteSeq("spine" .. i)
			local seq = seqCom:CreateSeq("spine" .. i)

			--往中间跑动画
			lUIHeroObject:PlayAni("run", true)
			local downTweener = trans:DOLocalMove(Vector2.New(65 * num,  233.8), 1):SetEase(DG.Tweening.Ease.Linear)
			seq:Insert(0, downTweener)
			seq:InsertCallback(0, function()
				self:CreateWndEffect(root, "effect_mjzl_chongci_1", "chongci_1_" .. i, 100)
				self:CreateWndEffect(root, "effect_mjzl_chongci_2", "chongci_2_" .. i, 100)
				self:CreateWndEffect(root, "effect_mjzl_chongci_3", "chongci_3_" .. i, 100)
				self:CreateWndEffect(root, "effect_mjzl_chongci_4", "chongci_4_" .. i, 100)
			end)

			--走到中间转待机
			seq:InsertCallback(1, function()
				lUIHeroObject:PlayAni("idle", true)

				self:DestroyWndEffectByKey("chongci_1_" .. i)
				self:DestroyWndEffectByKey("chongci_2_" .. i)
				self:DestroyWndEffectByKey("chongci_3_" .. i)
				self:DestroyWndEffectByKey("chongci_4_" .. i)
			end)

			--左边比右边提前1s攻击 播放攻击动画
			local start = i == 1 and 1 or 2
			local count = (dieIndex == 2 and i == 2) and 4 or 6
			for k = start, start + count, 2 do
				seq:InsertCallback(k, function()
					lUIHeroObject:PlayAni("attack1", true)
					self:DestroyWndEffectByKey("atkEff" .. i)
					for _, v in ipairs(effList) do
						local effectName = gLGameLanguage:GetResName(v.effRes)
						local effectPath = GameTable.AutoEffectRef[string.lower(effectName)]
						if effectPath then
							self:CreateWndEffect(root, v.effRes, "atkEff" .. i, 100)
							break
						end
					end
				end)
			end

			--右边比左边提前0.5s进行扣血 飘血
			local start = i == 1 and 2.5 or 1.5
			local count = (dieIndex == 2 and i == 1) and 4 or 6
			for k = start, start + count, 2 do
				local n = (k - start + 2) / 2
				local btHurt = CS.FindTrans(btRoot, "BtHurt" .. n)
				local btText = CS.FindTrans(btHurt, "Text")
				seq:InsertCallback(k, function()
					lUIHeroObject:PlayAni("hit1", true)

					self:SetWndText(btText, LUtil.FormatHurtNumSpriteText(math.abs(allHp / 4), false))
				end)

				local alphaTween = YXTween.TweenFloat(0, 1, 0.1, function(value)
					self:SetCanvasGroupAlpha(btHurt, value)
				end):SetEase(DG.Tweening.Ease.Linear)
				seq:Insert(k, alphaTween)

				local moveTweeb = btHurt:DOLocalMove(Vector2.New(0, 400), 10):SetEase(DG.Tweening.Ease.Linear)
				seq:Insert(k, moveTweeb)

				local alphaTween = YXTween.TweenFloat(1, 0, 0.1, function(value)
					self:SetCanvasGroupAlpha(btHurt, value)
				end):SetEase(DG.Tweening.Ease.Linear)
				seq:Insert(k + 1, alphaTween)
			end

			--右边比左边提前1s进行扣血 播放血条减少动画
			local start = i == 1 and 3 or 2
			for k = start, start + count, 2 do
				local form = 1 - (stepHp * ((k - start) / 2))
				local to = 1 - (stepHp * ((k - start + 2) / 2))
				seq:InsertCallback(k, function()
					LxUiHelper.SetProgress(bar2, to)
				end)
				local barTweener = YXTween.TweenFloat(form, to, 0.3, function(value)
					LxUiHelper.SetProgress(bar, value)
				end):SetEase(DG.Tweening.Ease.OutSine)
				seq:Insert(k, barTweener)
			end

			--播放死亡动画
			local time = i == 1 and 9 or 8
			if i == dieIndex then
				seq:InsertCallback(time, function()
					lUIHeroObject:PlayAni("die", true)

					--常规死亡
					self.dieList[info.playerId] = true
					self.dieNum[i] = self.dieNum[i] + 1

					--连胜死亡
					local win = i == 1 and 2 or 1
					if self.data[self.curIndex + 1] then
						local id = self.data[self.curIndex + 1]["guild" .. win].playerId
						local cur = data["guild" .. win].playerId
						if id ~= cur then
							self.dieList[cur] = true
							self.dieNum[win] = self.dieNum[win] + 1


							local AId = data.guild1.playerId
							local AData = self.playerShowData[AId]
							local BId = data.guild2.playerId
							local BData = self.playerShowData[BId]
							local info = {
								win = win,
								winCount = 3,
								headA =	AData.avatar,
								headFrameA = AData.avatarFrame,
								playerNameA = AData.name,
								headB =	BData.avatar,
								headFrameB = BData.avatarFrame,
								playerNameB = BData.name,
							}
							GF.OpenWnd("UIConoryPop",{StructGuildMeleeReportInfo = info})
						end
					end

					self:UpdataNum()
					if self.roleList[i] then
						self.roleList[i]:DrawAllItems()
					end
				end)

				seq:InsertCallback(time + 0.5, function()
					if i == dieIndex then
						if not self["dieEff" .. i] then
							self["dieEff" .. i] = self:CreateWndEffect(root, "fx_siwangxiaosan", "dieEff" .. i, 100)
						else
							self["dieEff" .. i]:SetVisible(false)
							self["dieEff" .. i]:SetVisible(true)
						end
					end
				end)

				local alphaTween = YXTween.TweenFloat(1, 0, 0.5, function(value)
					lUIHeroObject._displaySpine:SetAlpha(value)
				end):SetEase(DG.Tweening.Ease.InElastic)
				seq:Insert(time + 0.5, alphaTween)
			end

			--结束一轮动画
			if i == 2 then
				seq:InsertCallback(10.5, function()
					--还有战报继续递归执行
					if self.data[self.curIndex + 1] then
						self.spine1:Destroy()
						self.spine2:Destroy()
						self.spine1 = nil
						self.spine2 = nil
						self.curIndex = self.curIndex + 1
						self:PlayFight()
					else
						local win = dieIndex == 1 and 2 or 1

						local hasChangeWin = false
						local winACnt = self._winACnt[playerA]
						local winBCnt = self._winBCnt[playerB]
						--- 已经结束了，如果连赢册数大于等于3，且后续无玩家可以上阵
						if (winACnt and winACnt >= WinMaxNum) or (winBCnt and winBCnt >= WinMaxNum) then
							local nextMemberAIdx,nextMemberA
							local membersA = self._membersA
							for idx,val in ipairs(membersA) do
								if val.playerId == playerA then
									nextMemberAIdx = idx
								else
									if nextMemberAIdx and nextMemberAIdx > 0 then
										nextMemberA = val
										break
									end
								end
							end

							local nextMemberBIdx,nextMemberB
							local membersB = self._membersB
							for idx,val in ipairs(membersB) do
								if val.playerId == playerB then
									nextMemberBIdx = idx
								else
									if nextMemberBIdx and nextMemberBIdx > 0 then
										nextMemberB = val
										break
									end
								end
							end

							if nextMemberA or nextMemberB then
								local isMemberAZero = true
								if nextMemberA then
									isMemberAZero = nextMemberA.playerId == "0"
								end
								local isMemberBZero = true
								if nextMemberB then
									isMemberBZero = nextMemberB.playerId == "0"
								end
								if isMemberAZero or isMemberBZero then
									if isMemberAZero and win == 1 then
										win = 2
										dieIndex = 1
										hasChangeWin = true
									elseif isMemberBZero and win == 2 then
										win = 1
										dieIndex = 2
										hasChangeWin = true
									end
									if hasChangeWin then
										local tempInfo = data["guild" .. dieIndex]
										if tempInfo then
											self.dieList[tempInfo.playerId] = true
										end
									end
								end
							end
						end

						local winIcon = CS.FindTrans(self["mGuild" .. win], "Win")
						CS.ShowObject(winIcon, true)
						local loseIcon = CS.FindTrans(self["mGuild" .. dieIndex], "Lose")
						CS.ShowObject(loseIcon, true)
						
						if hasChangeWin then
							if self.spine1 then
								self.spine1:Destroy()
							end
							self.spine1 = nil
							CS.ShowObject(self.mSpine1,false)

							if self.spine2 then
								self.spine2:Destroy()
							end
							self.spine2 = nil
							CS.ShowObject(self.mSpine2,false)
							if self.roleList[i] then
								self.roleList[i]:DrawAllItems()
							end
						else
							CS.ShowObject(self["mSpine" .. dieIndex], false)
						end
					end
				end)
			end

			seq:PlayForward()
		end)
		lUIHeroObject:StartLoad()
	end
end

function UISubGdHoFightPkActually:UpdataNum()
	local t = {
		self.mGuild1,
		self.mGuild2
	}
	for i, v in ipairs(t) do
		local num = CS.FindTrans(v, "Text")
		local s = ccClientText(46027)
		local color = self.dieNum[i] >= self.allPlayer[i] and "#ff7676" or "#68e6ac"
		self:SetWndText(num, string.replace(s, self.allPlayer[i], color, self.allPlayer[i] - self.dieNum[i]))
	end
end


------------------------------------------------------------------
return UISubGdHoFightPkActually