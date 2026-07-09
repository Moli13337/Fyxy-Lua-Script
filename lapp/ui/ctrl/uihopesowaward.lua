---
--- Created by Administrator.
--- DateTime: 2024/7/1 10:49:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeSowAward:LWnd
local UIHopeSowAward = LxWndClass("UIHopeSowAward", LWnd)
------------------------------------------------------------------


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeSowAward:UIHopeSowAward()
	self._iconPlayTime = 0.3
	self._cancelItemTween = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeSowAward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeSowAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeSowAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	
	self:CreateWndEffect_Ex({
		trans = self.mTitleEff,
		effName = "fx_ui_mengjingzhilv_tanchuang",
		effKey = "fx_ui_mengjingzhilv_tanchuang",
	})

	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()

--[[	--- 测试代码
	local rewardList = {}
	local rewardStr = "1=102001=10,1=102001=50,1=102001=100,1=102001=1080,1=102001=1080,1=102001=1080,1=102001=1080,1=102001=1080,1=102001=1080"
	local rewardItems = LUtil.ConvertCommonItemStrToList(rewardStr)
	for i = 1,1 do
		for _i,v in ipairs(rewardItems) do
			table.insert(rewardList,v)
		end
	end
	self:InitRewardList(rewardList)]]

	gModelFastDreamTrip:OnDreamTripRewardTotalReq()
end


function UIHopeSowAward:OnDrawRewardCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")

	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:DoApply()

	self:TweenItemScale(Icon,itempos)

	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIHopeSowAward:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end


function UIHopeSowAward:MoveContent()
	if self._cancelItemTween then return end

	local uiRewardList = self._uiRewardList
	if not uiRewardList then return end

	local uiList = uiRewardList:GetList()
	if not uiList then return end

	local viewSize = self.mRewardList.rect.size
	local contentSize = uiList:GetContentSize()
	local itemSize = Vector2.New(140, 100)

	local moveLen = contentSize.y - viewSize.y
	if moveLen <= 0 then return end

	local disY = -itemSize.y / moveLen
	local dis = Vector2.New(0, disY)
	local duration = 0.5
	local seq = self._seqCom:CreateSeq("moveContent")
	local curPos = uiList:GetContentPosition()
	local endPos = curPos + dis
	endPos.y = math.max(0, endPos.y)
	local tween = YXTween.TweenFloat(0, 1, duration, function(t)
		local pos = Vector2.Lerp(curPos, endPos, t)
		uiList:SetContentPosition(pos)
	end)
	seq:Append(tween)
	seq:PlayForward()
end

function UIHopeSowAward:OnStartDrag()
	self._cancelItemTween = true

	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	seqCom:DeleteAllSeq()
end

function UIHopeSowAward:OnRewardItemReturn(list, item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	seqCom:DeleteSeq(instanceId)
end

function UIHopeSowAward:InitSuperRewardList(list)
	CS.ShowObject(self.mRewardList,true)
	CS.ShowObject(self.mRewardMinList,false)

	local uiList = self._uiRewardList
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems(true)
	else
		uiList = self:GetUIScroll("mRewardList")
		self._uiRewardList = uiList
		uiList:Create(self.mRewardList, list, function(...)
			self:OnDrawRewardCell(...)
		end, UIItemList.SUPER_GRID, false)

		local uiScrollList = uiList:GetList()
		uiScrollList:SetFuncOnItemReturn(function(...)
			self:OnRewardItemReturn(...)
		end)
		uiScrollList:SetOnStartDrag(function()
			self:OnStartDrag()
		end)
	end
	local tList = uiList:GetList()
	tList:RefreshList()
end

function UIHopeSowAward:TweenItemScale(item,itempos)
	local nowTime = Time.time
	local timePast = nowTime - self._startTime
	local delay = itempos * 0.1
	if timePast > delay or self._cancelItemTween then
		item.transform.localScale = Vector3.one
		return
	end

	local curDelay = delay - timePast
	local instanceId = item:GetInstanceID()
	item.transform.localScale = Vector3.zero

	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	if seqCom:FindSeq(instanceId) then
		seqCom:DeleteSeq(instanceId)
	end
	local seq = seqCom:CreateSeq(instanceId)
	seq:AppendInterval(curDelay)
	seq:Append(item:DOScale(Vector3.one, self._iconPlayTime):SetEase(DG.Tweening.Ease.OutQuad))

	if itempos > 10 and itempos % 5 == 1 then
		seq:AppendCallback(function()
			self:MoveContent()
		end)
	end

	seq:OnKill(function()
		item.transform.localScale = Vector3.one
	end)
	seq:OnComplete(function()
		seqCom:DeleteSeq(instanceId)
	end)
	seq:PlayForward()
end

function UIHopeSowAward:InitText()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mDesc,ccClientText(41419))
	self:SetWndText(self.mDesc1,ccClientText(41420))
end


function UIHopeSowAward:InitMiniRewardList(list)
	CS.ShowObject(self.mRewardMinList,true)
	CS.ShowObject(self.mRewardList,false)

	local uiList = self._uiRewardList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mRewardList")
		self._uiRewardList = uiList

		uiList:Create(self.mRewardMinList, list, function(...)
			self:OnDrawRewardCell(...)
		end,UIItemList.NORMAL,false)
	end
	uiList:EnableScroll(true)
	local tUIList = uiList:GetList()
	tUIList:RefreshList()
end

function UIHopeSowAward:OnDreamTripRewardTotalResp(pb)
	local dreamTripRewardList = {}
	for i,v in ipairs(pb.info) do
		table.insert(dreamTripRewardList,{
			itemType = v.type,
			itemId = v.itemId,
			itemNum = v.count
		})
	end
	self:InitRewardList(dreamTripRewardList)
end

function UIHopeSowAward:RefreshView()
end



function UIHopeSowAward:InitRewardList(list)
	self._cancelItemTween = false
	self._startTime = Time.time


	local isLimit = #list <= 5
	if isLimit then
		self:InitMiniRewardList(list)
	else
		self:InitSuperRewardList(list)
	end
end

function UIHopeSowAward:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripRewardTotalResp, function(pb,ret)
		self:OnDreamTripRewardTotalResp(pb)
	end)
end


function UIHopeSowAward:InitData()
end



------------------------------------------------------------------
return UIHopeSowAward