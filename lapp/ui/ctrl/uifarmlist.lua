---
--- Created by Administrator.
--- DateTime: 2024/10/15 10:36:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFarmList:LWnd
local UIFarmList = LxWndClass("UIFarmList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmList:UIFarmList()
	self._uiheadList = {}
	self._uiItemList = {}
	self._farmListTime = "farmListTime"
	self._timerKey = "farmList"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmList:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmList:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.activityData = self:GetWndArg("activityData")
	self:OnEventClicks()
	self:SetWndButtonText(self.mBtnRefresh,ccClientText(45946))
	self:SetWndText(self.mLblBiaoti,ccClientText(45903))
	self:SetWndText(self.mCloseTip,ccClientText(41037))

	if not self.activityData then return end
	local playerId = gModelPlayer:GetPlayerId()
	local myFarmData = gModelFarm:GetFarmDataByPlayerId(playerId)
	local activCfg = gModelActivity:GetWebActivityDataById(self.activityData.sid).config
	self.remainCount = activCfg and activCfg.stealingNum-myFarmData.stealingNum or 0
	self.scoreId = activCfg and activCfg.itemId
	self:SetWndText(self.mTxtStealNum,string.replace(ccClientText(45904),math.max(self.remainCount,0)))
	self:OnRefresh(false)
	self:InitEmptyTips()
	self:OnUpdateList()
end

function UIFarmList:SetGrowTime()
	local list = gModelFarm.nearbyFarmList
	local itemList = self._uiItemList
	local curTime = GetTimestamp()
	local isTime = false
	for indx, txtTime in pairs(itemList) do
		if list[indx] then
			local timeDif = os.difftime(list[indx].predictTime, curTime)
			if timeDif>=0 then
				local timeStr = LUtil.FormatTimespanCn(timeDif)
				timeStr = string.replace(ccClientText(39002), timeStr)
				self:SetWndText(txtTime, timeStr)
				isTime = true
			else
				table.remove(itemList,indx)
			end
		end
	end
	if not isTime then self:TimerStop(self._farmListTime) end
end

function UIFarmList:InitEmptyTips()
	-- local emptyList = self:GetCommonEmptyList("_empty")
	-- local data =
	-- {
	-- 	-- refId = 36006,
	-- 	IntroTran = self.mEmptyText,
	-- }
	-- emptyList:RefreshUI(data)
	self:SetWndText(self.mEmptyText,ccClientText(45962))
end

function UIFarmList:OnDrawCell(list,item,itemdata,itempos)
	local ItemIcon = self:FindWndTrans(item, "ItemIcon")
	local IconSteal = self:FindWndTrans(item, "IconSteal")
	local TxtHarvest = self:FindWndTrans(item, "TxtHarvest")
	local Icon = self:FindWndTrans(TxtHarvest, "Icon")
	local IconNum = self:FindWndTrans(Icon, "UIText")
	local TxtName = self:FindWndTrans(item, "TxtName")
	local TxtGrowTime = self:FindWndTrans(item, "TxtGrowTime")
	local TxtSteal = self:FindWndTrans(item, "TxtSteal")
	local BtnGoto = self:FindWndTrans(item, "BtnGoto")
	---@type StructNearbyFarm
	local itemdata = itemdata
	local InstanceID = item:GetInstanceID()

	local uiheadlist = self._uiheadList
	---@type HeadIcon
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	-- headIcon
	local playerInfo = {
		trans = ItemIcon,
		playerId = itemdata.roleInfo.playerId,
		name = itemdata.roleInfo.name,
		icon = itemdata.roleInfo.head,
		headFrame = itemdata.roleInfo.headFrame or 20001,
		level = itemdata.roleInfo.grade
	}
	baseClass:SetHeadData(playerInfo)

	local iconPath = self.scoreId and gModelItem:GetItemIconByRefId(self.scoreId)
	if iconPath then self:SetWndEasyImage(Icon,iconPath) end
	self:SetWndText(TxtName,itemdata.roleInfo.name.."(S"..itemdata.roleInfo.serverId..")")
	self:SetWndText(TxtHarvest,ccClientText(45902))
	self:SetWndText(IconNum,itemdata.outputCount)
	local isShow = not (itemdata.status==0 and itemdata.outputCount==0 and (itemdata.predictTime==0 or itemdata.predictTime<=GetTimestamp()))
	CS.ShowObject(TxtHarvest,isShow)
	CS.ShowObject(Icon,isShow)
	if itemdata.status==1 and self.remainCount>0  then --可偷取
		CS.ShowObject(IconSteal,true)
		CS.ShowObject(TxtSteal,true)
		CS.ShowObject(TxtGrowTime,false)
		self:SetWndText(TxtSteal,ccClientText(45947))
	else
		CS.ShowObject(IconSteal,false)
		CS.ShowObject(TxtSteal,false)
		local curTime = GetTimestamp()
		local timeDif = os.difftime(itemdata.predictTime, curTime)
		CS.ShowObject(TxtGrowTime,timeDif>0)
		if timeDif>0 then
			self._uiItemList[itempos] = TxtGrowTime
		end
	end
	if itempos==1 then
		self:TimerStart(self._farmListTime,1,false,-1)
		self:SetGrowTime()
	end
	self:SetWndButtonText(BtnGoto,ccClientText(21036))
	self:SetWndClick(BtnGoto,function()
		local instanceId = self.mEffectCloud:GetInstanceID()
		self:CreateWndEffect(self.mEffectCloud,"guochangdonghua_2",instanceId,100,nil,nil,nil,nil,nil,nil,nil,function()
			self:OnEffectLoaded(itemdata)
		end)
	end)
end

function UIFarmList:OnEventClicks()
	self:WndEventRecv(EventNames.FARM_NEARBY_UPDATE,function()
		self:OnUpdateList()
	end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnRefresh,function()
		if gModelFarm.nextTime<=GetTimestamp() then
			self:OnRefresh(true)
		end
	end)
end

function UIFarmList:SetRefreshTime()
	local timeDif = os.difftime(gModelFarm.nextTime, GetTimestamp())
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	self:SetWndButtonText(self.mBtnRefresh, timeStr)
	if timeDif<=-1 then
		self:SetWndButtonText(self.mBtnRefresh, ccClientText(45946))
		self:SetWndButtonGray(self.mBtnRefresh,false)
		self:TimerStop(self._timerKey)
	end
end
function UIFarmList:OnEffectLoaded(itemdata)
	local seq = self:GetSeqCom()
	local instanceId = self.mEffectCloud:GetInstanceID()
	local sequence = seq:CreateSeq(instanceId)
	sequence:AppendInterval(0.8)
	sequence:OnComplete(function()
		seq:DeleteSeq(instanceId)
		self:ClearSeqCom()
		GF.OpenWnd("UIFarmHappy",{activityData = self.activityData,playerId = itemdata.roleInfo.playerId})
		self:WndClose()
	end)
	sequence:PlayForward()
end
function UIFarmList:OnUpdateList()
	local curTime = GetTimestamp()
	self:SetWndButtonGray(self.mBtnRefresh,not (curTime>=gModelFarm.nextTime))
	if curTime < gModelFarm.nextTime then
		self:SetRefreshTime()
		self:TimerStart(self._timerKey,1,false,-1)
	end

	local curlist = gModelFarm.nearbyFarmList
	local uiAttrList = self._uiFarmList
	if uiAttrList then
		uiAttrList:RefreshData(curlist)
		uiAttrList:DrawAllItems()
		uiAttrList:MoveToPos(1)
	else
		self._uiFarmList = self:GetUIScroll("nearFarmList")
		self._uiFarmList:Create(self.mListFarm,curlist,function (...) self:OnDrawCell(...) end,UIItemList.SUPER_GRID)
	end
	CS.ShowObject(self.mEmptyText,#curlist<=0)
end

function UIFarmList:OnRefresh(isAuto)
	gModelFarm:OnHappyFarmLandListReq(self.activityData.sid,isAuto)
end
function UIFarmList:OnTimer(key)
	if self._farmListTime == key then
		self:SetGrowTime()
	end
	if self._timerKey == key then
		self:SetRefreshTime()
	end
end
------------------------------------------------------------------
return UIFarmList