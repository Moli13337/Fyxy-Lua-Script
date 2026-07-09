---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqCompLog:LWnd
local UIEqCompLog = LxWndClass("UIEqCompLog", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqCompLog:UIEqCompLog()
	---@type table<number,CommonIcon>
	self._equipIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqCompLog:OnWndClose()
	self:ClearCommonIconList(self._equipIconList)
	self._equipIconList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqCompLog:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqCompLog:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetXUITextText(self.mTitle,ccClientText(11319))
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:SetEmptyData()
	gModelEquip:OnEquipLogReq()
end

function UIEqCompLog:SetEmptyData()
	local data = {refId = 101,IntroTran = self.mEmptyText,TextBgTran = self.mEmptyTextBg,IconTran = self.mEmptyIcon}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIEqCompLog:OnDrawEquipCell(list, item, itemdata, itempos, fromHeadTail)
	local equipTrans = CS.FindTrans(item,"IconRoot/Icon")
	local refId = itemdata.refId
	local num = itemdata.num
	local instanceId = item:GetInstanceID()
	local baseClass = self._equipIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._equipIconList[instanceId] = baseClass
		baseClass:Create(equipTrans)
	end
	baseClass:SetCommonReward(LItemTypeConst.TYPE_EQUIP, refId, num)
	baseClass:EnableShowNum(true)
	self:SetIconClickScale(equipTrans, true)
	self:SetWndClick(equipTrans,function()
		GF.OpenWndUp("UIEqInfo",{refId = refId , noShowBtn = true})
	end)
	baseClass:DoApply()

end

function UIEqCompLog:OnDrawLogCell(list, item, itemdata, itempos, fromHeadTail)
	self:SetListItem(item,itemdata)
end

function UIEqCompLog:InitMsg()
	self:WndNetMsgRecv(LProtoIds.EquipLogResp,function()
		self:InitList()
	end)
end

function UIEqCompLog:SetListItem(item,itemdata)
	local equipListTrans = self:FindWndTrans(item,"EquipList")
	local expendTxtTrans = self:FindWndTrans(item,"ExpendTxt")
	local expendNumTrans = self:FindWndTrans(item,"ExpendNum")
	local expendTimeTrans = self:FindWndTrans(item,"ExpendTime")
	local InstanceID = item:GetInstanceID()
	self._logList[InstanceID] = item
	if equipListTrans then
		local equipData = itemdata[2]
		self:CreateEquipList(equipListTrans,equipData,InstanceID)
	end
	if expendTxtTrans then
		self:SetWndText(expendTxtTrans,ccClientText(11320))
	end
	if expendNumTrans then
		local consume = itemdata[1]
		consume = LUtil.NumberCoversion(consume)
		self:SetWndText(expendNumTrans,consume)
	end
	if expendTimeTrans then
		local createTime = tonumber(itemdata[3])
		local str = ccClientText(11321)
		local timeStr = LUtil.FormatTimeStr(createTime,"%Y/%m/%d %H:%M")
		str = string.replace(str,timeStr)
		self:SetWndText(expendTimeTrans,str)
	end
end

function UIEqCompLog:InitList()
	local uiList = self._uiLogList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mEquipLogList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawLogCell(...)
		end)
		self._uiLogList = uiList
	end
	uiList:RemoveAll()

	local list = gModelEquip:GetEquipLogList()

--[[	local list = {
		[1] = {
			[1] = "100",
			[2] = {
				[1] = {
					num = 1,
					refId = 2030107
				},
				[2] = {
					num = 1,
					refId = 2030107
				},
				[3] = {
					num = 1,
					refId = 2030107
				},
				[4] = {
					num = 1,
					refId = 2030107
				},
				[5] = {
					num = 1,
					refId = 2030107
				},
			},
			[3] = "1592628584052",
		},
		[2] = {
			[1] = "100",
			[2] = {
				[1] = {
					num = 1,
					refId = 2030107
				},
				[2] = {
					num = 1,
					refId = 2030107
				},
				[3] = {
					num = 1,
					refId = 2030107
				},
				[4] = {
					num = 1,
					refId = 2030107
				},
			},
			[3] = "1592628584052",
		},
	}]]
	local show = table.isempty(list)
	if not show then
		CS.ShowObject(self.mEquipLogList,true)
		for i,v in ipairs(list) do
			uiList:AddData(i,v)
		end
		uiList:RefreshList()
	end
	CS.ShowObject(self.mNoRecord,show)
end

function UIEqCompLog:InitData()
	self._logList = {}
	self._equipList = {}
end

function UIEqCompLog:InitEvent()
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEqCompLog:CreateEquipList(trans,data,InstanceID)
	local equipList = self._equipList
	local uiList = equipList[InstanceID]
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,trans)
		uiList:EnableScroll(true,true)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawEquipCell(...)
		end)
		equipList[InstanceID] = uiList
	end
	uiList:RemoveAll()
	local function sortFunc(equip1,equip2)
		local refId1,refId2 = equip1.refId,equip2.refId
		local ref1,ref2 = gModelEquip:GetEquipRefByRefId(refId1),gModelEquip:GetEquipRefByRefId(refId2)
		return ref1.order < ref2.order
	end
	table.sort(data,sortFunc)
	for i,v in ipairs(data) do
		uiList:AddData(i,v)
	end
	uiList:RefreshList()
end
------------------------------------------------------------------
return UIEqCompLog


