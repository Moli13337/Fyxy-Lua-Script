---
--- Created by admin.
--- DateTime: 2023/10/9 22:56:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDiffLvlFightRecordPop:LWnd
local UIDiffLvlFightRecordPop = LxWndClass("UIDiffLvlFightRecordPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDiffLvlFightRecordPop:UIDiffLvlFightRecordPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDiffLvlFightRecordPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDiffLvlFightRecordPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDiffLvlFightRecordPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
end
function UIDiffLvlFightRecordPop:GetReportId(pbReportId)
	for i, v in pairs(pbReportId) do
		if(type(v) == "string")then
			return v
		end
	end
end
function UIDiffLvlFightRecordPop:OnInstanceFloorInfoResp(pb)
	local minLog = self:GetInstanceFloorPlayerInfo(pb.minLog)
	local maxLog = self:GetInstanceFloorPlayerInfo(pb.maxLog)
	local refId = pb.refId
	self:SetRecordList({ minLog, maxLog })
end
function UIDiffLvlFightRecordPop:InitEvent()

end
function UIDiffLvlFightRecordPop:InitBtnEvent()
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end
function UIDiffLvlFightRecordPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.InstanceFloorInfoResp, function(...)
		self:OnInstanceFloorInfoResp(...)
	end)
end
function UIDiffLvlFightRecordPop:DefultUI()
	local titleTxt = self.mTitle
	self:SetWndText(titleTxt, ccClientText(16338))
end
function UIDiffLvlFightRecordPop:GetInstanceFloorPlayerInfo(logData)
	local data = {
		playerId = logData.playerId,
		playerName = logData.playerName,
		level = logData.level,
		power = logData.power,
		reportId = logData.reportId,
		head = logData.head,
		createTime = logData.createTime,
		refId = logData.refId,
		headFrame = logData.headFrame,
	}
	return data
end
function UIDiffLvlFightRecordPop:InitData()
	self._dataList = {}
	self._combatType = self:GetWndArg("combatType")
	self:DefultUI()
	local curDiffLvl = gModelInstance:GetMainFightLevelOfDifficulty()
	local curMissionCfg = gModelInstance:GetCurMissionCfg(curDiffLvl)
	gModelInstance:OnInstanceFloorInfoReq(curMissionCfg.refId)
end
function UIDiffLvlFightRecordPop:SetRecordList(recordList)
	local recordListTrans = self.mRecordList
	for i = 1, 2 do
		local index = i
		local recordData = recordList[index]
		local itemTrans = recordListTrans:GetChild(index - 1)
		local displayGroup = self:FindWndTrans(itemTrans, "DisplayGroup")
		local emtyDescTxt = self:FindWndTrans(itemTrans, "EmtyDescTxt")
		self:SetWndText(emtyDescTxt, ccClientText(16343))
		local titleIndex = index == 1 and 16342 or 16341
		local titleTrans = self:FindWndTrans(itemTrans, "TitleImg/TitleText")
		self:SetWndText(titleTrans, ccClientText(titleIndex))
		if (recordData) then
			local lookBtnTrans = self:FindWndTrans(displayGroup, "LookBtn")
			local lookBtnTxtTrans = self:FindWndTrans(displayGroup, "LookBtn/Text")
			local headIcon = self:FindWndTrans(displayGroup, "HeadIcon")
			self:CreateHeadIcon(headIcon,recordData.head,recordData.headFrame,recordData.level)
			local prowerText = self:FindWndTrans(displayGroup, "ProwerBg/ProwerText")
			local playerText = self:FindWndTrans(displayGroup, "PlayerText")
			self:SetWndText(lookBtnTxtTrans, ccClientText(16340))
			local powerStr = LUtil.PowerNumberCoversion(recordData.power)
			self:SetWndText(prowerText, powerStr)
			local playerNameStr = recordData.playerName
			self:SetWndText(playerText, playerNameStr)

			self:SetWndClick(lookBtnTrans, function()
				local battleData = {
					reportId = recordData.reportId,
					combatType = self._combatType ,
					dungeonId = recordData.refId,
					battleEndfun = function()
						--gModelBattle:ShowAccountByCombatResult(combatResult)
						GF.ChangeMap("LFightIdleMap")
						GF.OpenWnd("UIMultiTeamFightPop")
						GF.OpenWnd("UIDiffLvlFightRecordPop",{combatType = self._combatType})
					end,
				}
				gModelBattle:MultiBattlePlayBack(battleData,false)
			end)
			self:SetWndClick(headIcon, function()
				gModelGeneral:PlayerShowReq(recordData.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
			end)
		end
		CS.ShowObject(displayGroup, recordData and recordData.playerId and recordData.playerId~=0)
		CS.ShowObject(emtyDescTxt, not recordData or not recordData.playerId or recordData.playerId==0)
	end
end
function UIDiffLvlFightRecordPop:CreateHeadIcon(headIcon,icon,headFrame,lvl)
	local baseClass = self._headBaseClass
	local playerInfo = {
		trans = headIcon,
		icon = icon,
		headFrame = headFrame,
		level = lvl,
	}
	if baseClass then
		baseClass:SetHeadData(playerInfo)
		baseClass:RefreshUI()
	else
		baseClass = HeadIcon:New(self)
		baseClass:SetHeadData(playerInfo)
		baseClass:RefreshUI()
		self._headBaseClass = baseClass
	end
end
------------------------------------------------------------------
return UIDiffLvlFightRecordPop


