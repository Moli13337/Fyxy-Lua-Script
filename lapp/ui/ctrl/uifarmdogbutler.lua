---
--- Created by Administrator.
--- DateTime: 2024/10/15 11:03:25
---
------------------------------------------------------------------
local LWnd = LWnd
local YXTweeningDoTween = LxUnity.YXTweeningDoTween
local Tweening = DG.Tweening
---@class UIFarmDogButler:LWnd
local UIFarmDogButler = LxWndClass("UIFarmDogButler", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmDogButler:UIFarmDogButler()
	self.timerKeyDog = "timerKeyDog"
	self.endTime = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmDogButler:OnWndClose()
	LWnd.OnWndClose(self)
	local seqCom = self:GetSeqCom()
	seqCom:DeleteSeq("textTween")
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmDogButler:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmDogButler:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mLblBiaoti,ccClientText(45914))
	self:SetWndText(self.mTxtDesc,ccClientText(45915))
	self:SetWndText(self.mTxtState,ccClientText(45916))
	self:SetWndText(self.mCloseTip,ccClientText(41037))
	
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnPrivilege,function() self:OnClickZhanling() end)
	self:SetWndClick(self.mBtnConfirm,function() self:OnConfirmClick() end)
	self:WndEventRecv(EventNames.FARM_DOGTIME_UPDATE,function() self:OnUpdatePanel() end)
	self:WndEventRecv(EventNames.FARM_INFO_UPDATE,function() self:OnUpdatePanel() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) 
		if pb.sid == self.activityData.sid then self:UpdateZhanling() end
	end)
	self.dogStartPos = self.mDogSpine.localPosition
	self.activityData = self:GetWndArg("activityData")
	self._mainCfg = gModelActivity:GetWebActivityDataById(self.activityData.sid).config
	local playerId = gModelPlayer:GetPlayerId()
	self.farmData = gModelFarm:GetFarmDataByPlayerId(playerId)
	self:SetTextTile(self.mBtnPrivilege,self._mainCfg.giftName)
	self:UpdateZhanling()
	self:OnUpdatePanel()
	
end

function UIFarmDogButler:InitSpine()
	self:DogSpine()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("textTween")
	-- self:SetWndEasyImage(self.mImgDog,self.status==1 and "activity_156_ui_1_on" or "activity_156_ui_1_off",nil,true)
	local str = self.status==1 and ccClientText(45941) or ccClientText(45942)
	local tween = YXTween.TweenInt(0,3,2,function (value)
		if value==1 then
			value = str.."."
		elseif value==2 then
			value = str..".."
		else
			value = str.."..."
		end
		self:SetWndText(self.mTxtSpine,value)
	end)
	seq:Append(tween)
	seq:SetLoops(-1)
	seq:PlayForward()

end

function UIFarmDogButler:UpdateZhanling()
	if not self._mainCfg then self._mainCfg = gModelActivity:GetWebActivityDataById(self.activityData.sid).config end
	local param = gModelFunctionOpen:ModifyWndPara(self._mainCfg.jump)
	local isBuy = false
	if param and param.subPage then
		local sid = gModelActivity:GetSidByUniqueJump(param.subPage)
		local activityData = gModelActivity:GetActivityBySid(sid)
		if activityData and not string.isempty(activityData.moreInfo) then
			local moreInfo = JSON.decode(activityData.moreInfo)
			local buyPassNum = string.split(moreInfo.buyPassNum,",")
			for i,v in ipairs(buyPassNum) do
				v = tonumber(v)
				if v>0 then
					isBuy = true
					break
				end
			end
		end
	end
	CS.ShowObject(self.mImgAct,isBuy)
end

function UIFarmDogButler:DogTween()
	self.mDogSpine.localPosition = self.dogStartPos
	if self.dogSequence then
		self.dogSequence:Kill(false)
		self.dogSequence:Destroy()
	end
	if self.status ==1 then
		self.mDogSpine.localPosition = Vector3.New(145,55,0)
		self.dogSequence = YXTween.TweenSequenceIns()
		local dtMoveTo = self.mDogSpine:DOLocalMoveX(-300, 5):SetRelative():SetEase(Tweening.Ease.Linear)
		self.dogSequence:Append(dtMoveTo)
		self.dogSequence:SetLoops(-1,Tweening.LoopType.Yoyo)
		self.dogSequence:OnStepComplete(function()
			if not self.mDogSpine then return end
			local scale = self.mDogSpine.localScale
			scale.x = scale.x>0 and -1 or 1
			self.mDogSpine.localScale = scale
			-- self.mTxtDogState.localScale = scale
			-- if self.dogState==0 and scale.x==1 then --休息状态时--回到狗窝-进入休息状态
			-- 	self:DogSpine()
			-- 	self.dogSequence:Kill(false)
			-- 	self.dogSequence:Destroy()
			-- 	scale.x = 1
			-- 	self.mDogSpine.localScale = scale
			-- 	self.mTxtDogState.localScale = scale
			-- 	self:SetWndText(self.mTxtDogState,ccClientText(45959))
			-- end
		end)
		self.dogSequence:Play()
	end
end

function UIFarmDogButler:OnClickZhanling()
	local functionId = self._mainCfg.jump
	if functionId and not gModelFunctionOpen:CheckIsOpened(functionId, true) then
		return
	end
	gModelFunctionOpen:Jump(functionId, self:GetWndName(),function(isBuy)
		if isBuy then
			gModelFarm:OnFarmInfoReq(self.activityData.sid,gModelPlayer:GetPlayerId())
			self:UpdateZhanling()
		end
	end,self)
end
function UIFarmDogButler:DogSpine()
	local instanceId = self.mDogSpine:GetInstanceID()
	self:DestroyWndSpineByKey(instanceId)
	local action = self.status==1 and "walk" or "sleep"
	local func = function (dpLoaded)
		dpLoaded:PlayAnimationSolid(action,true)
		self:DogTween()
	end
	local dpSpine = self:CreateWndSpine(self.mDogSpine,"Keji_01",instanceId,true,
	func,true)
	dpSpine:StartLoad()
end

function UIFarmDogButler:OnConfirmClick()
	if self.status~=3 then
	else
		gModelFarm:OnPatrolDogReq(self.activityData.sid)
	end
	self:WndClose()
end

function UIFarmDogButler:OnTimer(key)
	if self.timerKeyDog == key  then
		self:SetDogTime()
	end
end
function UIFarmDogButler:SetDogTime()
	local timeDif = os.difftime(self.endTime,GetTimestamp())
	if timeDif<0 then
		if self.status ==1 then
			self.endTime = self._mainCfg.DogRestTimes+self.farmData.patrolDogTime+1
			self.status = 2
			timeDif = os.difftime(self.endTime,GetTimestamp())
		elseif self.status == 2 then
			self:TimerStop(self.timerKeyDog)
			self:SetWndText(self.mTxtStateVal,ccClientText(45938))
			return
		end
	end
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	timeStr = string.replace(ccClientText(self.status==1 and 45964 or 45939), timeStr)
	self:SetWndText(self.mTxtStateVal,timeStr)
end

function UIFarmDogButler:OnUpdatePanel()
	---@type StructFarm
	local farmData = self.farmData
	local canActiveTime = self._mainCfg.DogRestTimes+farmData.patrolDogTime
	local curTime = GetTimestamp()
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(43343))
	self.status = 0
	if curTime < farmData.patrolDogTime then --巡逻
		self.status = 1
		self.endTime = farmData.patrolDogTime
	elseif curTime < canActiveTime then--休息
		self.status = 2
		self.endTime = canActiveTime
	else--可激活
		self.status = 3
		self:SetWndButtonText(self.mBtnConfirm,ccClientText(45917))
		self:SetWndText(self.mTxtStateVal,ccClientText(45938))
	end
	if self.status~=3 then
		self:SetDogTime()
		self:TimerStart(self.timerKeyDog,1,false,-1)
	end

	self:InitSpine()
end
------------------------------------------------------------------
return UIFarmDogButler