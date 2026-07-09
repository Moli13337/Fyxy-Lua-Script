---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkCastWin:LWnd
local UIPkCastWin = LxWndClass("UIPkCastWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkCastWin:UIPkCastWin()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkCastWin:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkCastWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkCastWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitScrollRect()
	self:InitMessage()
	local battleNum=self:GetWndArg("battleNode")
	self._extraData = self:GetWndArg("extraData")
	gModelInstance:OnInstanceHistoryReq(battleNum)--请求关卡通关历史
	self:InitCommand()
end

--刷新排行榜列表
function UIPkCastWin:RefreshRank()
	local _itemList={}
	_itemList=gModelInstance:GetContent() or {}
	if(#_itemList<=0) then
		CS.ShowObject(self.mCastScrollRectObj,false)
		CS.ShowObject(self.mNoRecord2,true)
		self:SetWndText(self.mEmptyText, ccClientText(11001))
		return
	else
		CS.ShowObject(self.mNoRecord2,false)
		CS.ShowObject(self.mCastScrollRectObj,true)
	end

	self._uiList:RemoveAll()
	local list = _itemList or {}
	for i = 1, #list do
		local data = list[i]
		data.index = i
		self._uiList:AddData(i, data)
	end
	self._uiList:RefreshList()
end

function UIPkCastWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.InstanceHistoryResp,function (...)
		self:RefreshRank()
	end)
end

function UIPkCastWin:OnClickLook(itemdata)
	--print("点击观看",itemdata.reportId)
	GF.OpenWnd("UIOrdinTip",{refId=80001,func=function (...)
		local extraData = self._extraData
		local combatExtraDatas = {
			meName = itemdata.player.name,
			otherName = extraData.otherName,
			mePlayerHead = itemdata.player.head,
			battleMapName = gModelBattle:GetBattleMapRes({combatType = LCombatTypeConst.COMBAT_MAIN}),
			battleEndfun = function()
				gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_MAIN,{})
			end,
			canSkip = true}
		gLFightManager:OnPlayBattleVideo(itemdata.reportId,combatExtraDatas)
		self:WndClose()
	end })
end

function UIPkCastWin:OnClickPlayer(_playerId)
	if(_playerId==gModelPlayer:GetPlayerId() )then
		GF.ShowMessage(ccClientText(11522))
		return
	end
	gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIPkCastWin:InitCommand()
	self:SetWndText(self.mTitleXUITextObj,ccClientText(11000))
end

function UIPkCastWin:ListItem(list, item, itemdata, itempos, fromHeadTail)
	local info=itemdata.player

	local titleText=CS.FindTrans(item,"TitleImg/TitleText")
	local playerText=CS.FindTrans(item,"PlayerText")
	local desText = CS.FindTrans(item,"DesText")
	local prowerIcon=CS.FindTrans(item,"ProwerBg")
	local prowerText=CS.FindTrans(item,"ProwerBg/ProwerText")

	local shareBtn=CS.FindTrans(item,"ShareBtn")
	local shareText=CS.FindTrans(shareBtn,"XUIText")
	local reportBtn=CS.FindTrans(item,"ReportBtn")
	local reportText=CS.FindTrans(reportBtn,"XUIText")
	local lookBtn=CS.FindTrans(item,"LookBtn")
	local lookText=CS.FindTrans(lookBtn,"XUIText")

	CS.ShowObject(shareBtn,false)

	self:SetWndText(shareText,ccClientText(12116))
	self:SetWndText(reportText,ccClientText(12117))
	self:SetWndText(lookText,ccClientText(12118))

	self:SetHeadIcon(item,info)

	local textId = 0
	if itemdata.relationType == 1 then
		textId = 11002
	elseif itemdata.relationType == 2 then
		textId = 11003
	end
	if(textId > 0)then
		CS.ShowObject(desText,true)
		self:SetWndText(desText,ccClientText(textId))
	else
		CS.ShowObject(desText,false)
	end

	self:SetWndClick(reportBtn,function () self:OnClickBattle(itemdata) end)
	self:SetWndClick(lookBtn,function () self:OnClickLook(itemdata) end)

	if(info.playerId ~= 0)then
		self:SetWndText(prowerText,LUtil.ToInteger(info.power))
		CS.ShowObject(prowerIcon,true)
		local playerStr = info.name
		self:SetWndText(playerText,playerStr)
	else
		CS.ShowObject(prowerIcon,false)
		self:SetWndText(playerText,"")
	end

end

function UIPkCastWin:InitEvent()
	self:SetWndClick(self.mBgMaskObj,function (...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function (...) self:WndClose() end)
end

function UIPkCastWin:SetHeadIcon(item,info)
	local headIcon = CS.FindTrans(item, "HeadIcon")
	CS.ShowObject(headIcon,false)
	if(info.playerId == 0)then
		return
	end
	CS.ShowObject(headIcon,true)
	local InstanceID = item:GetInstanceID()

	local playerInfo={
		trans = headIcon,
		playerId = info.playerId,
		icon = info.head,
		headFrame = info.headFrame,
		level = info.level,
	}
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	self:SetWndClick(headIcon, function (...)
		self:OnClickPlayer(info._playerId)
	end)
end

--初始化排行榜列表
function UIPkCastWin:InitScrollRect()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self, self.mCastScrollRectObj)
		uiList:SetFuncOnItemDraw(function(...)
			self:ListItem(...)
		end)
		self._uiList = uiList
	end
end

function UIPkCastWin:OnClickBattle(itemdata)
	--print("点击战报",itemdata.reportId)
	local extraData = self._extraData
	local combatExtraDatas = {
		meName = itemdata.player.name,
		otherName = extraData.otherName,
		meLevel=itemdata.player.grade,
		mePlayerHead = itemdata.player.head,
		closeAfterVideo = function()
			gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_MAIN,{})
		end
	}
	gLFightManager:OnOpenBattleDetails(itemdata.reportId,combatExtraDatas)
end

------------------------------------------------------------------
return UIPkCastWin


