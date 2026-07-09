---
--- Created by Administrator.
--- DateTime: 2024/10/15 10:41:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFarmLog:LWnd
local UIFarmLog = LxWndClass("UIFarmLog", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmLog:UIFarmLog()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmLog:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmLog:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmLog:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:WndEventRecv(EventNames.FARM_RECORD_UPDATE,function() self:UpdateList() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndText(self.mLblBiaoti,ccClientText(45905))
	self:SetWndText(self.mTxtDesc,ccClientText(45906))
	self:SetWndText(self.mCloseTip,ccClientText(41037))
	self.activityData = self:GetWndArg("activityData")
	gModelFarm:OnHappyFarmRecordReq(self.activityData.sid)
	local mainCfg = gModelActivity:GetWebActivityDataById(self.activityData.sid)
	self.scoreId = mainCfg and mainCfg.config.itemId
	self.maxLog = mainCfg and mainCfg.config.logNum
	self:InitEmptyTips()
	self:UpdateList()
end

-- 空列表提示
function UIFarmLog:InitEmptyTips()
	-- local emptyList = self:GetCommonEmptyList("_empty")
	-- local data =
	-- {
	-- 	-- refId = 36006,
	-- 	IntroTran = self.mEmptyText,
	-- }
	-- emptyList:RefreshUI(data)
	self:SetWndText(self.mEmptyText,ccClientText(45962))
end

function UIFarmLog:OnEffectLoaded(itemdata)
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

function UIFarmLog:OnDrawCell(list,item,itemdata,itempos)
	local ItemIcon = self:FindWndTrans(item, "ItemIcon")
	local BtnGoto = self:FindWndTrans(item, "BtnGoto")
	local TxtOffline = self:FindWndTrans(item,"TxtOffline")
	local TxtDesc = self:FindWndTrans(item,"TxtDesc")
	local TxtState = self:FindWndTrans(TxtDesc,"TxtState")
	local Icon = self:FindWndTrans(TxtState,"Icon")
	local TxtNum = self:FindWndTrans(Icon,"TxtNum")

	---@type StructFarmRecord
	local itemdata = itemdata
	CS.ShowObject(BtnGoto,itemdata.type==2)
	self:SetWndButtonText(BtnGoto,ccClientText(20307))
	local InstanceID = item:GetInstanceID()
	local uiheadlist = self._uiheadList
	---@type HeadIcon
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	local roleInfo = itemdata.roleInfo
	-- headIcon
	local playerInfo = {
		trans = ItemIcon,
		playerId = roleInfo.playerId,
		name = roleInfo.name,
		icon = roleInfo.head,
		headFrame = roleInfo.headFrame or 20001,
		level = roleInfo.grade
	}
	baseClass:SetHeadData(playerInfo)

	local str = ""
	local stateStr = 45949--获得了
	local name = roleInfo.name.."("..roleInfo.serverId..")"
	if itemdata.type==2 then --被偷
		if itemdata.cropNum>0 then
			stateStr = 45948
			str = string.replace(ccClientText(45950),name,itemdata.cropNum,gModelItem:GetNameByRefId(itemdata.cropId))
		else
			str = string.replace(ccClientText(45951),name,gModelItem:GetNameByRefId(itemdata.cropId))
		end
	elseif itemdata.type==1 then--偷取
		if itemdata.cropNum>0 then
			str = string.replace(ccClientText(45952),name,itemdata.cropNum,gModelItem:GetNameByRefId(itemdata.cropId))
		else
			stateStr = 45948
			str = string.replace(ccClientText(45953),name,gModelItem:GetNameByRefId(itemdata.cropId))
		end
	else--收割
		str = string.replace(ccClientText(45954),itemdata.cropNum,gModelItem:GetNameByRefId(itemdata.cropId))
		stateStr = 45955
	end

	local iconPath = self.scoreId and gModelItem:GetItemIconByRefId(self.scoreId)
	if iconPath then self:SetWndEasyImage(Icon,iconPath) end
	self:SetWndText(TxtState,ccClientText(stateStr))
	self:SetWndText(TxtNum,itemdata.score)
	self:SetWndText(TxtDesc,str)

	local curTime = GetTimestamp()
	local timeDif = os.difftime(curTime,itemdata.time)
	local timeStr = ""
	if timeDif <= 60 then
		timeStr = ccClientText(43330)
	else
		timeStr = string.replace(ccClientText(12561),LUtil.FormatTimeToMin(timeDif))
	end
	self:SetWndText(TxtOffline,timeStr)

	self:SetWndClick(BtnGoto,function()
		local instanceId = self.mEffectCloud:GetInstanceID()
		self:CreateWndEffect(self.mEffectCloud,"guochangdonghua_2",instanceId,100,nil,nil,nil,nil,nil,nil,nil,function()
			self:OnEffectLoaded(itemdata)
		end)
	end)

end

function UIFarmLog:UpdateList()
	---@type table<StructFarmRecord>
	local curlist = gModelFarm.farmRecordList
	local list = {}
	local count = 0
	for _, recordInfo in ipairs(curlist or {}) do
		for _, crop in pairs(recordInfo.crops or {}) do
			count = count+1
			local num = crop.count or 0
			table.insert(list,{roleInfo = recordInfo.roleInfo,time = recordInfo.time,cropId = crop.crop,
			cropNum = num,score =crop.score ,type = recordInfo.type,result = recordInfo.result,})
		end
		if count>=self.maxLog then break end
	end
	local uiFarmList = self._uiFarmList
	if uiFarmList then
		uiFarmList:RefreshList(list)
	else
		uiFarmList = self:GetUIScroll("FarmLogList")
		---@type UIItemList
		self._uiFarmList = uiFarmList
		uiFarmList:Create(self.mListLog,list,function(...) self:OnDrawCell(...) end)
	end
	uiFarmList:EnableScroll(true)
	CS.ShowObject(self.mEmptyText,#list<=0)
end
------------------------------------------------------------------
return UIFarmLog