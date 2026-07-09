---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGjAwardReceive:LWnd
local UIGjAwardReceive = LxWndClass("UIGjAwardReceive", LWnd)
local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGjAwardReceive:UIGjAwardReceive()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGjAwardReceive:OnWndClose()
	if self._wndType ==1 then
		if self._netData and self._netData.flushTime then
			gModelInstance:SetPlaceTime(self._netData.flushTime)
		end
	end

	--FireEvent(EventNames.ON_ACCOUNT_RELA_WND_CLOSE,self:GetWndName())

	--self:StopPlayerTween()

	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end

	if gModelInstance.isShowOnHookRewardEff then
		GF.OpenWnd("UIOnHookAwardEff")
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGjAwardReceive:OnCreate()
	LWnd.OnCreate(self)

	self._seqCom  = SequenceCom:New()


	self._curItemTweenList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGjAwardReceive:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_RECHARGE_LARGE)
	self:InitData()
	self:SetPara()
	self._expSliderKey ="_expSliderKey"
	self:SetStaticContent()
	--local timeTotal = nil
	--local itemList = self._netData.items
	if self._wndType ==1 then
		--timeTotal = self._netData.receiveTime
		self:WndNetMsgRecv(LProtoIds.InstancePlaceRewardResp,function (pb)
			self._netData = pb
			self._timeTotal = pb.receiveTime
			self._curLv= gModelPlayer:GetPlayerLv()
			self._curExp = gModelPlayer:GetPlayerExp()
			self:RefreshUI()
		end)
		gModelInstance:OnInstancePlaceRewardReq()
	elseif self._wndType == 2 then
		self._timeTotal = gModelInstance:GetQuickTotalTime()

		self._curLv = self:GetWndArg("curLv")
		self._curExp = self:GetWndArg("curExp")

		self:RefreshUI()
	elseif self._wndType == 3 then
		local items = self:GetWndArg("itemList")
		self:RefreshGetReward(items)

	end
	--self:SetTimeContent(timeTotal)
	--self:RefreshGetReward(itemList)
	--self:ShowPlayer()
	self:SetWndClick(self.mMaskBtn,function ()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mCloseTip,function ()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	local effectName = "fx_ui_gongxihuode"
	self:CreateWndEffect(self.mTitle,effectName,effectName,100)
end

function UIGjAwardReceive:StartTween()
	local totalExp = 0
	for k,v in pairs(self._netData.items) do
		if v.itemId ==103001 then           --角色经验
			totalExp =tonumber(v.count)
			break
		end
	end

	local tweenDataList={}

	local curLv = self._curLv
	local curExp = self._curExp
	local curLvExpNeed = gModelPlayer:GetLevelExpNeed(curLv)

	local level = curLv
	local exp =0

	while totalExp>0 do
		local startProgress =0
		local endProgress = 0
		if level == curLv then
			startProgress = curExp/curLvExpNeed
			exp = curExp
		else
			exp=0
		end
		local data ={}
		data.lv = level

		local curLevelExpNeed = gModelPlayer:GetLevelExpNeed(level)
		if curLevelExpNeed == -1 then
			break
		end
		local consume = curLevelExpNeed-exp

		local fullExp = false
		if totalExp>consume then
			totalExp = totalExp-consume
			level = level+1
			endProgress = 1
		else
			if totalExp == consume then
				level = level+1
				fullExp = true
			end

			exp = exp+ totalExp
			totalExp=0
			endProgress = exp/curLevelExpNeed
		end

		data.startP = startProgress
		data.endP = endProgress

		table.insert(tweenDataList,data)
		if fullExp then
			local full =
			{
				lv = level,
				startP = 0,
				endP = 0.01,
			}
			table.insert(tweenDataList,full)
		end
		if consume<=0 then
			LogError(string.format("wrong data lv: %s exp: %s",self._curLv,self._curExp))
		    break
		end
	end

	local duration = 2

	local totalLen= 0
	for k,v in ipairs(tweenDataList) do
		totalLen = totalLen + v.endP-v.startP
	end
	if totalLen <=0 then
		return false
	end
	local perLenTime = duration/totalLen

	local first = tweenDataList[1]
	if first then
		self:ShowPlayerLvAndExp(first.lv,first.startP)
	end



	self._playerSeq =self._seqCom:CreateSeq("playerTween")
	for k,v in ipairs(tweenDataList) do
		local time = (v.endP-v.startP)*perLenTime
		local lv = v.lv
		local tweener = YXTween.TweenFloat(v.startP,v.endP,time, function(t)
			self:ShowPlayerLvAndExp(lv,t)
		end)
		self._playerSeq:Append(tweener)
	end

	self._playerSeq:SetAutoKill(true)
	self._playerSeq:PlayForward()

	return true

end



function UIGjAwardReceive:SetPara()
	self._wndType = self:GetWndArg("wndType")
	if self._wndType== 2 then
		self._netData = self:GetWndArg("wndData")
	end

end

function UIGjAwardReceive:OnRewardItemReturn(list,item,itemdata,itempos)
	local instanceId = item:GetInstanceID()
	self._seqCom:DeleteSeq(instanceId)

	self._curItemTweenList[instanceId] = nil
end


function UIGjAwardReceive:OnDrawItem(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item,"CommonUI")
	local CommonUIIcon = self:FindWndTrans(item,"CommonUI/Icon")
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUIIcon)


	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:DoApply()

	self:SetWndClick(CommonUIIcon,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)

	self:TweenItemScale(CommonUI,itempos)
end

function UIGjAwardReceive:ShowPlayer()
	local trans = self:FindWndTrans(self.mPlayer,"HeadIcon")

	local playerData={
		trans=trans,
		icon=gModelPlayer:GetPlayerHead(),
		headFrame=gModelPlayer:GetPlayerHeadFrame(),
	}

	local instanceId = trans:GetInstanceID()
	local baseClass = self:GetHeadIcon(instanceId)
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()

	if not self:StartTween() then
		local level = gModelPlayer:GetPlayerLv()
		local totalExp=gModelPlayer:GetCurLevelTotalExp()
		local curExp= gModelPlayer:GetPlayerExp()
		local progress = curExp/totalExp
		self:ShowPlayerLvAndExp(level,progress)
		if totalExp<0 then
			--- 2024/6/3： 反馈表处理，直接显示已满级
--[[			local str = ccClientText(17011)
			str = string.replace(str,curExp)
			self:SetWndText(self.mLevelInfo,str)]]
			self:SetWndText(self.mLevelInfo,ccClientText(17011))
		end
	end

end

function UIGjAwardReceive:SetTimeContent(timeTotal)
	local timeMax = gModelInstance:GetBoxTimeLimit()
	if timeTotal > timeMax then
		timeTotal = timeMax
	end
	local hour =math.floor(timeTotal/60)
	local min =math.floor(timeTotal)%60
	local timeStr= string.format("%02d:%02d:00",hour,min)
	timeStr = LUtil.FormatColorStr(timeStr,"green")
	timeStr = ccClientText(10724)..timeStr

	if self._wndType ==1 then
		local isVipEff = gModelVip:GetIsHookInVipEff()
		-- local isNewYear = gModelActivity:GetIsActivityByModelId(ModelActivity.MODEL_NEWYEAR,1)
		local isNewYear = false
		-- local isCHN = gModelActivity:GetIsActivityByModelId(ModelActivity.MODEL_CHN_CELEBRATE,1)
		local isCHN = false
		local tipsStr = ""
		if isVipEff and (not isNewYear and not isCHN) then
			tipsStr = ccClientText(10747)
		elseif (isNewYear or isCHN) and not isVipEff then
			tipsStr = ccClientText(19231)
		elseif (isNewYear or isCHN) and isVipEff then
			tipsStr = ccClientText(19232)
		end
		timeStr= timeStr..LUtil.FormatColorStr(tipsStr,"darkYellow")
	end

	self:SetWndText(self.mHangTime,timeStr)
end

function UIGjAwardReceive:OnStartDrag()
	if table.isempty(self._curItemTweenList) then
		return
	end

	self._cancelItemTween = true

	self._seqCom:DeleteSeq("moveContent")
	for k,v in pairs(self._curItemTweenList) do
		self._seqCom:DeleteSeq(k)
	end
	self._curItemTweenList = {}


	local uiList =self._itemSuperList
	local list = uiList:GetList()
	local seq = self._seqCom:CreateSeq("moveContent")
	local duration = 0.2
	local curPos = list:GetContentPosition()
	local endPos = Vector2.zero
	local tween = YXTween.TweenFloat(0,1,duration,function (t)
		local pos = Vector2.Lerp(curPos,endPos,t)
		list:SetContentPosition(pos)
	end)

	seq:Append(tween)
	seq:PlayForward()
end

function UIGjAwardReceive:MoveContent()
	if self._cancelItemTween then
		return
	end

	local list = self._itemSuperList:GetList()
	if not list then
		return
	end
	local viewSize = self.mItemGetList.rect.size
	local contentSize = list:GetContentSize()
	local itemSize = Vector2.New(140,140)

	local moveLen = contentSize.y - viewSize.y
	if moveLen<= 0 then
		return
	end
	local disY = -itemSize.y/moveLen
	local dis =Vector2.New(0,disY)
	local duration = 0.5
	local seq = self._seqCom:CreateSeq("moveContent")

	local curPos = list:GetContentPosition()
	local endPos = curPos + dis
	endPos.y = math.max(0,endPos.y)
	local tween = YXTween.TweenFloat(0,1,duration,function (t)
		local pos = Vector2.Lerp(curPos,endPos,t)
		list:SetContentPosition(pos)
	end)

	seq:Append(tween)

	seq:PlayForward()
end



function UIGjAwardReceive:RefreshUI()
	self:SetTimeContent(self._timeTotal)
	self:RefreshGetReward(self._netData.items)
	self:ShowPlayer()
end

function UIGjAwardReceive:RefreshGetReward(itemList)
	self._startTime = Time.time

	local dataList = {}
	for k,v in ipairs(itemList) do
		local item =
		{
			itemType = v.type,
			itemId = v.itemId,
			itemNum = v.count,
		}

		table.insert(dataList,item)
	end

	local uiList = self._itemSuperList
	if not uiList then
		uiList = self:GetUIScroll("rewardList")
		self._itemSuperList = uiList
		uiList:Create(self.mItemGetList,dataList,function(...) self:OnDrawItem(...)  end,UIItemList.SUPER_GRID,false)
		local list = uiList:GetList()
		list:SetFuncOnItemReturn(function (...)
			self:OnRewardItemReturn(...)
		end)
		list:SetOnStartDrag(function ()
			self:OnStartDrag()
		end)
	else
		uiList:RefreshData(dataList,true)
	end

	local list = uiList:GetList()
	list:RefreshList()
end

function UIGjAwardReceive:SetStaticContent()
	--self:SetXUITextText(self.mTitleText,ccClientText(10720))
	--local text = self:FindWndTrans(self.mTextTitle,"UIText")
	self:SetWndText(self.mAwardText,ccClientText(10721))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mLevel,ccClientText(10722))
	self:InitTextLineWithLanguage(self.mLevel, -30)
end

function UIGjAwardReceive:TweenItemScale(item,itempos)
	local nowTime = Time.time
	local timePast =nowTime - self._startTime
	local delay = itempos*self._iconPlayTime

	if timePast>delay or self._cancelItemTween then
		item.transform.localScale= Vector3.one
		return
	end
	local curDelay = delay - timePast
	local instanceId = item:GetInstanceID()
	item.transform.localScale= Vector3.zero
	--printInfoN(string.format("create item pos %s instanceId %s delay %s",itempos,instanceId,curDelay))
	local seq = self._seqCom:CreateSeq(instanceId)

	local tween = item:DOScale(Vector3.one,self._iconPlayTime)
	seq:AppendInterval(curDelay)
	if itempos>15 and  itempos%5 ==1 then
		seq:AppendCallback(function ()
			self:MoveContent()
		end)
	end

	seq:Append(tween)
	seq:OnComplete(function ()
		self._seqCom:DeleteSeq(instanceId)
		self._curItemTweenList[instanceId] = nil
	end)
	seq:OnKill(function()
		item.transform.localScale= Vector3.one
	end)
	seq:PlayForward()

	self._curItemTweenList[instanceId] = true

end

function UIGjAwardReceive:ShowPlayerLvAndExp(level,progress)
	local lvlStr = LUtil.FormatColorStr(level, "green")
	self:SetWndText(self.mLevel,ccClientText(10722)..lvlStr)
	--self:InitTextSizeWithLanguage(self.mLevel, 8)
	self:InitTextLineWithLanguage(self.mLevel, -30)
	local expSlider = self:UIProgressFind(self.mExp,self._expSliderKey,progress)
	expSlider:SetUIProgress(progress)
end


function UIGjAwardReceive:InitData()
	self._iconPlayTime =0.1
end
--
--function UIGjAwardReceive:StopPlayerTween()
--	if self._playerSeq then
--		self._playerSeq:Kill(false)
--		self._playerSeq = nil
--	end
--
--end




------------------------------------------------------------------
return UIGjAwardReceive


