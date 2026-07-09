---
--- Created by Administrator.
--- DateTime: 2024/10/12 16:27:39
---
------------------------------------------------------------------
local LWnd = LWnd
local uICamera = LGameUI.GetUICamera()
---@class UIGdHoFightPkTeam:LWnd
local UIGdHoFightPkTeam = LxWndClass("UIGdHoFightPkTeam", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkTeam:UIGdHoFightPkTeam()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkTeam:OnWndClose()
	LWnd.OnWndClose(self)
	LxTimer.LoopTimeStop(self.timer)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkTeam:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkTeam:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:SetBanchList()

	gModelGuildHolyPeak:GuildPinnacleGuildMemberReq(gModelPlayer:GetGuildId())
end

function UIGdHoFightPkTeam:InitCommon()
	-----------------------------------------------
	---click
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mTeamBtn, function()
		local para = {
			setTargetType = LCombatTypeConst.COMBAT_TYPE_46,
			returnFunc = function()
				FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.CITY)
				GF.ChangeMap("LCityMap")
				GF.OpenWnd("UIGdHoFightPk")
				GF.OpenWnd("UIGdHoFightPkTeam")
			end,
			retAfterSet = true,
		}
		gModelFormation:OpenSetFormationWnd(para)
		-- self:WndClose()
	end)

	gLGameTouch:TouchRegister(LGameTouch.TOUCH_TOP_TIME, LGameTouch.TOUCH_EVT_END, function(screenPos)
		if self.isLongClick then
			self.isLongClick = false
			self.listScrollRect.vertical = true
			self.banchScrollRect.horizontal = true
			LxTimer.LoopTimeStop(self.timer)
			self:clickUpRoleItem()
		end
	end)

	-----------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.GuildPinnacleGuildMemberResp, function(pb)
		if pb.guildId ~= gModelPlayer:GetGuildId() then
			return
		end
		self:SetRoleList(pb.combatMember)
		self:SetBanchList(pb.prepareMember)
	end)
	self:WndNetMsgRecv(LProtoIds.GetFormationShowResp, function(pb)
		self:OnGetFormationShowResp(pb)
	end)

	-----------------------------------------------
	---menber
	self.listScrollRect = self.mRoleList:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	self.banchScrollRect = self.mBanchList:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	self.listPos = self.mAniRoot:InverseTransformPoint(self.mRoleList.position)
	self.listHeight = self.mRoleList.rect.height
	self.listHeight = self.mRoleList.rect.height

	-----------------------------------------------
	---text
    self:SetWndText(self.mTxtClose, ccClientText(30205))
    self:SetWndText(self.mBenchText, ccClientText(46041))
    self:SetWndText(CS.FindTrans(self.mTeamBtn, "Text"), ccClientText(46009))
end

function UIGdHoFightPkTeam:SelectRoleItem(data)
	self:SetRoleItem(self.mRoleTemp, data)
	CS.ShowObject(self.mRoleTemp, true)
end

function UIGdHoFightPkTeam:SetDicIcon(root, data)
	local icon = self:FindWndTrans(root, "DraconicCard")
	local name = self:FindWndTrans(icon, "name")
	local iconImg = self:FindWndTrans(icon, "icon")
	local starRoot = self:FindWndTrans(icon, "starRoot")
	CS.ShowObject(root, true)
	if data.ref then
		local param = {
			refId    = data.ref.refId,
			showType = true,
			starNum  = data.upRef.rankNow,
			showName = true,
		}
		gModelDraconic:DrawCard(self, icon, param)
		CS.ShowObject(name, true)
		CS.ShowObject(iconImg, true)
		CS.ShowObject(starRoot, true)
	else
		local mask = self:FindWndTrans(icon, "mask")
		local typeRoot = self:FindWndTrans(icon, "typeRoot")
		self:SetWndEasyImage(mask, "draconic_frame_1")
		CS.ShowObject(mask, true)
		CS.ShowObject(typeRoot, false)
		CS.ShowObject(name, false)
		CS.ShowObject(iconImg, false)
		CS.ShowObject(starRoot, false)
	end
	self:SetWndClick(icon, function()
		if data.ref then
			GF.OpenWnd("UIDraconicUpStar", { refId = data.ref.refId, starNum = data.upRef.rankNow, tips = true })
		end
	end)
end

function UIGdHoFightPkTeam:SetBanchList(list)
	if self.banchList then
		self.banchList:RefreshList(list)
		self.banchList:DrawAllItems()
	else
		self.banchList = self:GetUIScroll("banchList")
		self.banchList:Create(self.mBanchList, list, function(...) self:DrawBanch(...) end, UIItemList.SUPER_GRID)
	end
end

function UIGdHoFightPkTeam:DrawBanch(_, trans, data, index)
	local t = {
		trans = trans,
		data = data
	}
	self.roleListData[data.playerId] = t
	self:SetRoleItem(trans, data)
	self:SetWndClick(trans, function()
		self.clickItemData = data
		self:ClickRoleItem()
	end)

	local longClickFunc = function()
		if data == nil then
			return
		end
		self.timer = LxTimer.LoopTimeCall(function()
			local mousePos = UnityEngine.Input.mousePosition
			self.mousePos = mousePos
			local pos = uICamera:ScreenToWorldPoint(mousePos)
			pos = self.mAniRoot:InverseTransformPoint(pos)
			if self.listPos.y + (self.listHeight / 2) < pos.y then
				local len = pos.y - (self.listPos.y + (self.listHeight / 2))
				local y = 0.2 * len
				local contentPos = self.mContent.localPosition
				if contentPos.y > 0 then
					y = math.max(0, (contentPos.y - y))
					self:SetAnchorPos(self.mContent, Vector2.New(0, y))
				end
			elseif self.listPos.y - (self.listHeight / 2) > pos.y then
				local len = self.listPos.y - (self.listHeight / 2) - pos.y
				local y = 0.2 * len
				local contentPos = self.mContent.localPosition
				if contentPos.y < self.mContent.rect.height - self.listHeight then
					y = math.min(self.mContent.rect.height - self.listHeight, (contentPos.y + y))
					self:SetAnchorPos(self.mContent, Vector2.New(0, y))
				end
			end
			self.mRoleTemp.localPosition = Vector2.New(pos.x, pos.y)
			if not self.isLongClick then
				self.isLongClick = true
				self.listScrollRect.vertical = false
				self.selectData = {
					trans = trans,
					data = data,
					index = index,
					type = 2
				}
				self:SelectRoleItem(data)
			end
		end, 0.01, true, -1)
	end
	local pos = gModelGuild:GetGuildPosition()
	if pos == 1 or pos == 2 then
		self:SetWndLongClick(trans, longClickFunc, 0.2)
	end
end

function UIGdHoFightPkTeam:ClickRoleItem()
	for playerId, v in pairs(self.roleListData) do
		local select = CS.FindTrans(v.trans, "Select")
		CS.ShowObject(select, playerId == self.clickItemData.playerId)
	end
	local playerId = gModelPlayer:GetPlayerId()
	CS.ShowObject(self.mTeamBtn, playerId == self.clickItemData.playerId)
	gModelPlayer:OnGetFormationShowReq(self.clickItemData.playerId, LCombatTypeConst.COMBAT_TYPE_46)
end

function UIGdHoFightPkTeam:SetRoleItem(trans, data, index)
	local num = CS.FindTrans(trans, "Num")
	local select = CS.FindTrans(trans, "Select")
	local headIcon = CS.FindTrans(trans, "HeadIcon")
	local power = CS.FindTrans(trans, "Power")
	local powerText = CS.FindTrans(trans, "Power/PowerText")
	local name = CS.FindTrans(trans, "Name")
	local me = CS.FindTrans(trans, "Me")

	if num then
		self:SetWndText(num, index)
	end
	if data then
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
		self:SetWndText(powerText, ccClientText(46025) .. LUtil.NumberCoversion(data.playerPower))
		self:SetWndText(name, data.playerName)
	end
	CS.ShowObject(headIcon, data ~= nil)
	CS.ShowObject(power, data ~= nil)
	CS.ShowObject(name, data ~= nil)
	CS.ShowObject(me, data and data.playerId == gModelPlayer:GetPlayerId())
	CS.ShowObject(select, self.clickItemData and data and data.playerId == self.clickItemData.playerId)
end

function UIGdHoFightPkTeam:SetHeroList(heros)
	if self.heroList then
		self.heroList:ResetList(heros)
		self.heroList:DrawAllItems()
	else
		self.heroList = self:GetUIScroll("heroList")
		self.heroList:Create(self.mTeamList, heros, function(...) self:DrawHero(...) end, UIItemList.SUPER_GRID)
	end
end

function UIGdHoFightPkTeam:OnGetFormationShowResp(pb)
	self:SetHeroList(pb.heroData.heros)
	self:SetDicList(pb.heroData.draconicStarRefIds)
end

function UIGdHoFightPkTeam:SetDicList(dicList)
	local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
	local DraconicRef = GameTable.DraconicRef
	for i = 1, 4 do
		local data = { ref = nil, upRef = nil }
		if dicList[i] and dicList[i] > 0 then
			local upRef = DraconicSuitRankRef[dicList[i]]
			local ref = DraconicRef[upRef.type]
			data = { ref = ref, upRef = upRef }
		end

		local root = self["mDraconic" .. i]
		self:SetDicIcon(root, data)
	end
end

function UIGdHoFightPkTeam:SetRoleList(list)
	self.roleListData = {}
	local selfIndex
	for i = 1, #list do
		local itemName = "item" .. i
		local trans = CS.FindTrans(self.mContent, itemName)
		if not trans then
			local gameObj = LxUnity.InstantObject(self.mRoleTemp.gameObject)
			gameObj.name = itemName
			trans = gameObj.transform
			LxUnity.SetParentTrans(trans, self.mContent)
			CS.ShowObject(trans, true)
		end

		local data
		if list[i] and list[i].playerId ~= "0" then
			data = list[i]
			if gModelPlayer:GetPlayerId() == list[i].playerId then
				selfIndex = i
			end
		end
		self:SetRoleItem(trans, data, i)
		if data then
			local t = {
				trans = trans,
				data = data
			}
			self.roleListData[data.playerId] = t
		end
		self:SetWndClick(trans, function()
			if data == nil then
				return
			end
			self.clickItemData = data
			self:ClickRoleItem()
		end)
		local longClickFunc = function()
			if data == nil then
				return
			end
			self.timer = LxTimer.LoopTimeCall(function()
				local mousePos = UnityEngine.Input.mousePosition
				self.mousePos = mousePos
				local pos = uICamera:ScreenToWorldPoint(mousePos)
				pos = self.mAniRoot:InverseTransformPoint(pos)
				if self.listPos.y + (self.listHeight / 2) < pos.y then
					local len = pos.y - (self.listPos.y + (self.listHeight / 2))
					local y = 0.2 * len
					local contentPos = self.mContent.localPosition
					if contentPos.y > 0 then
						y = math.max(0, (contentPos.y - y))
						self:SetAnchorPos(self.mContent, Vector2.New(0, y))
					end
				elseif self.listPos.y - (self.listHeight / 2) > pos.y then
					local len = self.listPos.y - (self.listHeight / 2) - pos.y
					local y = 0.2 * len
					local contentPos = self.mContent.localPosition
					if contentPos.y < self.mContent.rect.height - self.listHeight then
						y = math.min(self.mContent.rect.height - self.listHeight, (contentPos.y + y))
						self:SetAnchorPos(self.mContent, Vector2.New(0, y))
					end
				end
				self.mRoleTemp.localPosition = Vector2.New(pos.x, pos.y)
				if not self.isLongClick then
					self.isLongClick = true
					self.listScrollRect.vertical = false
					self.selectData = {
						trans = trans,
						data = data,
						index = i,
						type = 1
					}
					self:SelectRoleItem(data)
					LxUiHelper.SetCanvasGroupAlpha(trans, 0)
				end
			end, 0.01, true, -1)
		end
		local pos = gModelGuild:GetGuildPosition()
		if pos == 1 or pos == 2 then
			self:SetWndLongClick(trans, longClickFunc, 0.2)
		end
	end

	local index = selfIndex ~= nil and selfIndex or 1
	if list[index] and list[index].playerId ~= "0" and not self.clickItemData then
		self.clickItemData = list[index]
		self:ClickRoleItem()
	end
end

function UIGdHoFightPkTeam:clickUpRoleItem()
	CS.ShowObject(self.mRoleTemp, false)
	LxUiHelper.SetCanvasGroupAlpha(self.selectData.trans, 1)
	local pos = uICamera:ScreenToWorldPoint(self.mousePos)
	pos = self.mAniRoot:InverseTransformPoint(pos)
	local index = 1
	while CS.FindTrans(self.mContent, "item" .. index) ~= nil do
		local trans = CS.FindTrans(self.mContent, "item" .. index)
		local transPos = self.mAniRoot:InverseTransformPoint(trans.position)
		local bX = (pos.x >= transPos.x - 59) and (pos.x <= transPos.x + 59)
		local bY = (pos.y >= transPos.y - 59) and (pos.y <= transPos.y + 59)
		local bList = (self.listPos.y + (self.listHeight / 2) >= pos.y) and (self.listPos.y - (self.listHeight / 2) <= pos.y)
		if bX and bY and bList then
			local oldInfo = {
				index = self.selectData.index,
				type = self.selectData.type
			}
			local newInfo = {
				index = index,
				type = 1
			}
			gModelGuildHolyPeak:GuildPinnacleSwapMemberIndexReq(oldInfo, newInfo)
			return
		end
		index = index + 1
	end
	-- for i = 1, 30 do
	-- 	local trans = self["mRoleTemp" .. i]
	-- 	local transPos = self.mAniRoot:InverseTransformPoint(trans.position)
	-- 	local bX = (pos.x >= transPos.x - 59) and (pos.x <= transPos.x + 59)
	-- 	local bY = (pos.y >= transPos.y - 59) and (pos.y <= transPos.y + 59)
	-- 	local bList = (self.listPos.y + (self.listHeight / 2) >= pos.y) and (self.listPos.y - (self.listHeight / 2) <= pos.y)
	-- 	if bX and bY and bList then
	-- 		local oldInfo = {
	-- 			index = self.selectData.index,
	-- 			type = self.selectData.type
	-- 		}
	-- 		local newInfo = {
	-- 			index = i,
	-- 			type = 1
	-- 		}
	-- 		gModelGuildHolyPeak:GuildPinnacleSwapMemberIndexReq(oldInfo, newInfo)
	-- 		return
	-- 	end
	-- end
	local banchPos = self.mAniRoot:InverseTransformPoint(self.mBanchList.position)
	local bX = (pos.x >= banchPos.x - 311) and (pos.x <= banchPos.x + 311)
	local bY = (pos.y >= banchPos.y - 59) and (pos.y <= banchPos.y + 59)
	if bX and bY then
		local oldInfo = {
			index = self.selectData.index,
			type = self.selectData.type
		}
		local newInfo = {
			index = 1,
			type = 2
		}
		if oldInfo.type == newInfo.type then
			return
		end
		gModelGuildHolyPeak:GuildPinnacleSwapMemberIndexReq(oldInfo, newInfo)
		return
	end
end

function UIGdHoFightPkTeam:DrawHero(_, item, data, pos)
	local root = self:FindWndTrans(item, "Root")
	local data = {
		id = data.id,
		refId = data.refId,
		star = data.star,
		level = data.level,
		skin = data.skin,
		isResonance = data.isResonance,
		grade = data.grade,
		fightPower = data.fightPower,
	}
	local commonIconCls = self:GetCommonIcon(pos)
	commonIconCls:Create(root)
	commonIconCls:SetHeroDataSet(data)
	commonIconCls:DoApply()

	self:SetWndClick(root,function()
		if self.clickItemData and self.clickItemData.playerId ~= "0" then
			gModelHero:ReqShowHeroTip(self.clickItemData.playerId, data)
		end
	end)
end

------------------------------------------------------------------
return UIGdHoFightPkTeam