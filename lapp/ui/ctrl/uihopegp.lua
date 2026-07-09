---
--- Created by Administrator.
--- DateTime: 2023/10/4 17:34:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeGP:LWnd
local UIHopeGP = LxWndClass("UIHopeGP", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeGP:UIHopeGP()
	self._commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeGP:OnWndClose()
	self:ClearCommonIconList(self._commonUIList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeGP:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeGP:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitPlayerList()
end

function UIHopeGP:GetPlayerList()
	local list = {}
	local indexFriendList = gModelDreamTrip:GetIndexFriendList(self._index)
	if indexFriendList then
		local playStarList = gModelDreamTrip:GetConfigByKey("playStarList")
		local playStarRefId = playStarList.itemId
		local info = indexFriendList.info or {}
		for i,v in ipairs(info) do
			table.insert(list,{
				serverData = v,
				itemId = playStarRefId,
			})
		end
	end
	return list
end

function UIHopeGP:InitPlayerList()
	local list = self:GetPlayerList()

	local uiPlayerList = self._uiPlayerList
	if uiPlayerList then
		uiPlayerList:RefreshData(list)
	else
		uiPlayerList = self:GetUIScroll("uiPlayerList")
		self._uiPlayerList = uiPlayerList
		uiPlayerList:Create(self.mPlayerList,list,function(...) self:OnDrawPlayerCell(...) end,UIItemList.WRAP)
	end
end

function UIHopeGP:InitMsg()

end

function UIHopeGP:InitData()
	self._index = self:GetWndArg("index")
end

function UIHopeGP:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeGP:OnDrawPlayerCell(list,item,itemdata,itempos)
	local HeadIconTrans = self:FindWndTrans(item,"HeadIcon")
	local PlayerText = self:FindWndTrans(item,"PlayerText")
	local PowerTxt = self:FindWndTrans(item,"AutoPowerDiv/GameObject/PowerTxt")
	local ItemIcon = self:FindWndTrans(item,"AutoItemDiv/ItemIcon")
	local ItemNumTxt = self:FindWndTrans(item,"AutoItemDiv/GameObject/ItemNumTxt")
	local itemId = itemdata.itemId
	local serverData = itemdata.serverData
	local playerInfo,rankItem = serverData.playerInfo,serverData.rankItem
	local InstanceID = item:GetInstanceID()

	if HeadIconTrans then
		local playerId = playerInfo.playerId
		local commonUIList = self._commonUIList
		if not commonUIList then
			commonUIList = {}
			self._commonUIList = commonUIList
		end
		local baseClass = commonUIList[InstanceID]
		if not baseClass then
			baseClass = HeadIcon:New(self)
			commonUIList[InstanceID] = baseClass
		end
		local tPlayerInfo = {
			trans = HeadIconTrans,
			playerId = playerId,
			icon = playerInfo.head,
			headFrame = playerInfo.headFrame,
		}
		baseClass:SetHeadData(tPlayerInfo)
		self:SetWndClick(HeadIconTrans,function()
			gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end)
	end

	if PlayerText then
		self:SetWndText(PlayerText,playerInfo.name)
	end

	if PowerTxt then
		self:SetWndText(PowerTxt,LUtil.ToInteger(playerInfo.power))
	end

	if ItemIcon then
		local icon = gModelItem:GetItemIconByRefId(itemId)
		self:SetWndEasyImage(ItemIcon,icon)
	end

	if ItemNumTxt then
		self:SetWndText(ItemNumTxt,rankItem)
	end
end
------------------------------------------------------------------
return UIHopeGP


