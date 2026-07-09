---
--- Created by Administrator.
--- DateTime: 2024/6/11 10:35:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLandReport:LWnd
local UIPeWishLandReport = LxWndClass("UIPeWishLandReport", LWnd)
------------------------------------------------------------------


local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLandReport:UIPeWishLandReport()
	---@type StructPetDreamLandData
	self._landData = nil

	---@type UIBtnTabList
	self._uiBtnTabList = nil

	--- 点击战报数据
	self._clickReportInfo = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLandReport:OnWndClose()
	if self._uiBtnTabList then
		self._uiBtnTabList:Destroy()
		self._uiBtnTabList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWishLandReport:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLandReport:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitTabBtnList()
	gModelPetDreanLand:OnPetDreamLandRecordReq()
end

function UIPeWishLandReport:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
end

function UIPeWishLandReport:OnPetDreamLandRecordResp()
	self._reportMap = gModelPetDreanLand:GetReportMap()

	self:InitReportList()
end

---@param itemdata StructPetDreamLandRankReport
function UIPeWishLandReport:OnClickBtnVideo(itemdata)
	local serverId
	if itemdata.serverId and itemdata.serverId > 0 then
		serverId = itemdata.serverId or 0
	end
	local combatExtraDatas = {
		videoType = LVideoTypeConst.NORMAL,
		canSkip = true,
		serverId = serverId,
		battleEndfun = function()
			gModelGeneral:RecoverGameState()
		end,
	}
	gModelGeneral:RecordGameState()
	gLFightManager:OnPlayBattleVideo(itemdata.reportId,combatExtraDatas,LCombatTypeConst.COMBAT_BATTLE_VIDEO)
end

function UIPeWishLandReport:GoToFormation(pb,clickReportInfo)
	---@type StructPetDreamLandRankReport
	local reportData = clickReportInfo and clickReportInfo.reportData
	local otherName = reportData and reportData:GetPlayerName()
	gModelPetDreanLand:GoToPetDLFormation({
		combatType = LCombatTypeConst.COMBAT_TYPE_41,
		skipBattle = gModelPetDreanLand:CheckIsCanJumpPetDLBattle(),
		fightType = pb.type,
		dreamLandId = pb.refId,
		targetId = pb.pointId,
		otherName = otherName
	})
end

---@param itemdata StructPetDreamLandRankReport
function UIPeWishLandReport:OnClickBtnRevenge(itemdata)
	if self._clickReportInfo then return end
	local result = itemdata.result
	local type = result == 1 and ModelPetDreanLand.TYPE_FIGHT_0 or ModelPetDreanLand.TYPE_FIGHT_1
	local data = {
		playerId = itemdata:GetPlayerId(),
		type = type,
		reportData = itemdata,
	}
	self._clickReportInfo = data
	gModelPetDreanLand:OnPetDreamLandRevengeReq(data.playerId,data.type)
end


function UIPeWishLandReport:InitData()
	self._landData = self:GetWndArg("landData")

	---@type table<number,StructPetDreamLandRankReport> 战报类型数据 Map
	self._reportMap = gModelPetDreanLand:GetReportMap()
end

function UIPeWishLandReport:InitReportList()
	local list = self:GetReportList()
	local uiList = self:FindUIScroll("mReportList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mReportList")
		uiList:Create(self.mReportList, list, function(...) self:OnDrawReportCell(...) end)
	end
	uiList:EnableScroll(true)
	local isEmpty = #list < 1
	if isEmpty then
		local refId = self._reportType == ModelPetDreanLand.TYPE_REPORT_ATTACK and 39002 or 39001
		self:InitEmptyList(refId)
	end
	CS.ShowObject(self.mNoRecord2,isEmpty)
end

function UIPeWishLandReport:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandRecordResp,function(...) self:OnPetDreamLandRecordResp(...) end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandRevengeResp,function(...) self:OnPetDreamLandRevengeResp(...) end)
end

function UIPeWishLandReport:OnClickBtnTab(itemdata)
	if self._reportType == itemdata.btnType then return false end
	self._reportType = itemdata.btnType
	self:OnClickRedPoint(itemdata)
	self:InitReportList()
end

function UIPeWishLandReport:GoToBattle(pb,clickReportInfo)
	local combatType = LCombatTypeConst.COMBAT_TYPE_41
	if gModelFormation:IsFormationEmpty(combatType) then
		self:GoToFormation(pb,clickReportInfo)
		return
	end
	gModelBattle:OnCombatReq({
		combatType = combatType,
		skipBattle = gModelPetDreanLand:CheckIsCanJumpPetDLBattle(),
		targetId = pb.pointId,
		dreamLandId = pb.refId,
		fightType = pb.type,
	})
end

---@param itemdata StructPetDreamLandRankReport
function UIPeWishLandReport:OnDrawReportCell(list, item, itemdata, itempos)
	local Title = self:FindWndTrans(item,"TitleBg/Title")
	local NoLoseTxt = self:FindWndTrans(item,"NoLoseTxt")
	local ReportTime = self:FindWndTrans(item,"ReportTime")
	local ShowRewardList = self:FindWndTrans(item,"ShowRewardList")
	local HeadIcon = self:FindWndTrans(item,"CommonUI/Icon/HeadIcon")
	local PowerTxt = self:FindWndTrans(item,"PowerDiv/PowerTxt")
	local ReportDesc = self:FindWndTrans(item,"ReportDesc")
	local BtnList = self:FindWndTrans(item,"BtnList")
	local BtnRevenge = self:FindWndTrans(BtnList,"BtnRevenge")
	local BtnVideo = self:FindWndTrans(BtnList,"BtnVideo")

	self:SetWndText(Title,itemdata:GetReportTitle())

	self:SetWndText(ReportTime,LUtil.FormatTimeStr2(itemdata.startTime))

	self:SetTextTile(BtnRevenge,ccClientText(43335))
	self:SetTextTile(BtnVideo,ccClientText(43336))

	self:SetWndText(ReportDesc,itemdata:GetReportDesc())
	self:SetWndText(PowerTxt,LUtil.PowerNumberCoversion(itemdata:GetPlayerPower()))

	local showRewardList = itemdata.showRewardList or {}
	local noLoseTxt = itemdata:GetNoLoseTxt()
	self:SetWndText(NoLoseTxt,noLoseTxt)

	self:InitShowRewardList(ShowRewardList,showRewardList)

	local playerInfo = {
		trans = HeadIcon,
		icon = itemdata:GetPlayerHead(),
		headFrame = itemdata:GetPlayerHeadFrame(),
		level = itemdata:GetPlayerGrade(),
		func = function()
			gModelGeneral:PlayerShowReq(itemdata:GetPlayerId(),LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end,
	}
	self:CreateHeadIconImpl(playerInfo)

	CS.ShowObject(BtnRevenge,itemdata:CheckIsCanRevenge())

	self:SetWndClick(BtnRevenge,function()
		self:OnClickBtnRevenge(itemdata)
	end)
	self:SetWndClick(BtnVideo,function()
		self:OnClickBtnVideo(itemdata)
	end)
end

function UIPeWishLandReport:InitTabBtnList()
	local list = {}
	table.insert(list,{
		btnType = ModelPetDreanLand.TYPE_REPORT_ATTACK,
		btnName = ccClientText(43354),
		redPointId = ModelRedPoint.PDT_NEW_REPORT_1,
		clickFunc = function(itemdata)
			return self:OnClickBtnTab(itemdata)
		end,
		checkRPFunc = function(itemdata)
			return gModelRedPoint:CheckSingle(itemdata.redPointId)
		end,
	})
	table.insert(list,{
		btnType = ModelPetDreanLand.TYPE_REPORT_DEFEND,
		btnName = ccClientText(43353),
		redPointId = ModelRedPoint.PDT_NEW_REPORT_2,
		clickFunc = function(itemdata)
			return self:OnClickBtnTab(itemdata)
		end,
		checkRPFunc = function(itemdata)
			return gModelRedPoint:CheckSingle(itemdata.redPointId)
		end,
	})

	local page = self:GetWndArg("page") or 1
	local data = list[page]
	self._reportType = data.btnType
	self:OnClickRedPoint(data)

	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
	self._uiBtnTabList:SetData(self,self.mTabBtnList,list,self._reportType)
end


function UIPeWishLandReport:GetReportList()
	local list = self._reportMap[self._reportType] or {}
	table.sort(list,function(a,b)
		return a.startTime > b.startTime
	end)
	return list
end

function UIPeWishLandReport:OnClickRedPoint(itemdata)
	local redPointId = itemdata.redPointId
	gModelRedPoint:SetRedPointClicked(redPointId)
	gModelRedPoint:RedPointClickReq(redPointId)
	if redPointId == ModelRedPoint.PDT_NEW_REPORT_1 then
		FireEvent(EventNames.HIDE_PET_REPORT1,{showRP = false})
	elseif redPointId == ModelRedPoint.PDT_NEW_REPORT_2 then
		FireEvent(EventNames.HIDE_PET_REPORT2,{showRP = false})
	end
end

function UIPeWishLandReport:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(43308))
end

function UIPeWishLandReport:OnPetDreamLandRevengeResp(pb)
	if not self._clickReportInfo then return end

	local clickReportInfo = self._clickReportInfo
	local playerId = clickReportInfo.playerId
	if playerId ~= pb.playerInd then return end

	local type = clickReportInfo.type
	if type ~= pb.type then return end

	--- 0-可以战斗，1-没有据点，无法复仇，2-所有据点处于保护期，无法进攻，3-据点处于安全区，无法复仇
	local state = pb.state
	if state == 0 then
		--- 修改为打开信息弹窗
		--self:GoToBattle(pb,clickReportInfo)
		gModelPetDreanLand:OpenPetDreamLandPassByPointId(pb.refId,pb.pointId,true,pb.playerInd)
	elseif state == 1 then
		GF.ShowMessage(ccClientText(43370))
	elseif state == 2 then
		GF.ShowMessage(ccClientText(43371))
	elseif state == 3 then
		GF.ShowMessage(ccClientText(43372))
	end
	self._clickReportInfo = nil
end

function UIPeWishLandReport:InitEmptyList(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIPeWishLandReport:OnDrawShowRewardCell(list, item, itemdata, itempos)
	local IconDiv = self:FindWndTrans(item,"IconDiv")
	local Icon = self:FindWndTrans(IconDiv,"Icon")
	local Num = self:FindWndTrans(item,"Num")

	---@type StructRewardItem
	local reward = itemdata.reward
	local itemId = reward.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(Icon,icon,function() CS.ShowObject(Icon,true) end,true)

	local numStr = LUtil.NumberCoversion(reward.count)
	local isSub = not itemdata.isAdd
	local color = itemdata.color
	if color then
		numStr = LUtil.FormatColorStr(numStr,color)
	end
	if isSub then
		numStr = "-" .. numStr
	end
	self:SetWndText(Num,numStr)

end

function UIPeWishLandReport:OnEventXXXXX()
end

function UIPeWishLandReport:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.page = self._reportType
	return list
end




function UIPeWishLandReport:InitShowRewardList(listTrans,list)
	list = list or {}
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans, list, function(...) self:OnDrawShowRewardCell(...) end)
	end
end

------------------------------------------------------------------
return UIPeWishLandReport