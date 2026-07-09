---
--- Created by Administrator.
--- DateTime: 2023/10/5 14:08:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDoubleValue:LWnd
local UIDoubleValue = LxWndClass("UIDoubleValue", LWnd)

local Tweening = DG.Tweening

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDoubleValue:UIDoubleValue()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDoubleValue:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDoubleValue:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDoubleValue:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:ShowSpine()
	self:InitEvent()
	self:OnWndRefresh()
end

function UIDoubleValue:OnDrawEntry(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootTitle = self:FindWndTrans(AniRoot,"title")
	local AniRootItemList = self:FindWndTrans(AniRoot,"itemList")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootBtnRoot = self:FindWndTrans(AniRoot,"btnRoot")
	local btnRootBtn = self:FindWndTrans(AniRootBtnRoot,"btn")

	local btnRootTag = self:FindWndTrans(AniRootBtnRoot,"tag")



	self:SetWndText(AniRootTitle,itemdata.title)

	local instanceId = item:GetInstanceID()
	local rewardList = itemdata.reward
	local list = self:FindUIScroll(instanceId)
	if list then
		list:RefreshList(rewardList)
	else
		list= self:GetUIScroll(instanceId)
		list:Create(AniRootItemList,rewardList,function (...) self:OnDrawItem(...) end)
	end

	local btnStr = ""
	self:DestroyWndEffectByKey(instanceId)

	if itemdata.status == 0 then
		btnStr =ccClientText(16753) --"前 往"
	elseif itemdata.status == 1 then
		btnStr =ccClientText(18214) --"领 取"
		self:CreateWndEffect(AniRootBtnRoot,"fx_anniu_02",instanceId,100)
	--elseif itemdata.status == 2 then
	--	btnStr = "已领取"
	end

	local completeSchedule = tonumber(itemdata.completeSchedule.schedule)
	local progressStr = ""
	local color;
	if completeSchedule == 0 then
		color = "red"
	else
		color = "green"
	end
	local goal = tonumber(itemdata.completeSchedule.goal)
	local str = string.format("(%s/%s)",completeSchedule,goal)
	progressStr = LUtil.FormatColorStr(str,color)

	self:SetWndText(AniRootUIText,progressStr)

	self:SetWndButtonText(btnRootBtn,btnStr)
	CS.ShowObject(btnRootBtn,itemdata.status ~= 2)
	CS.ShowObject(btnRootTag,itemdata.status == 2)

	self:SetWndClick(AniRootBtnRoot,function ()
		self:OnClickEntry(itemdata)
	end)

end

function UIDoubleValue:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)

		if sid ~= self._sid then
			return
		end

		self._isConfigOk = true
		self:OnActConfigRet()
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:OnActivityPageResp(pb)
	end)

	self:WndNetMsgRecv(LProtoIds.ChargeResp,function ()
		if not self._isConfigOk then
			return
		end
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UIDoubleValue:OnClickHelp()
	local content = self._helpTipsContent
	if not content then return end

	local title = gModelActivity:GetLngNameByActivitySid(self._sid)
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UIDoubleValue:OnClickEntry(itemdata)
	if itemdata.status == 0 then
		gModelFunctionOpen:Jump(itemdata.jumpId,self:GetWndName())
	elseif itemdata.status == 1 then
		local sid = itemdata.sid
		local pageId = itemdata.pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	elseif itemdata.status == 2 then
		GF.ShowMessage(ccClientText(12208))
	end
end

function UIDoubleValue:ShowDailyReward(data)
	local entryData = data.entryData
	local status = entryData.goalData.status
	local seqCom = self:GetSeqCom()
	local iconPath = nil

	local effRes = ""

	if status == 1 then
		local seq = seqCom:CreateSeq("shake")
		self.mBoxicon.localRotation = Quaternion.Euler(0,0,0)
		local tween = self.mBoxicon:DORotate(Vector3.New(0,0,10),0.04):SetEase(Tweening.Ease.OutCubic)
		seq:Append(tween)
		tween = self.mBoxicon:DORotate(Vector3.New(0,0,-10),0.08):SetEase(Tweening.Ease.InOutCubic)
		seq:Append(tween)
		tween = self.mBoxicon:DORotate(Vector3.New(0,0,0),0.04):SetEase(Tweening.Ease.InCubic)
		seq:Append(tween)

		seq:AppendInterval(1)
		seq:SetLoops(-1)
		seq:Play()
		iconPath = "activity_magicSchool_icon_1"
		effRes = "fx_ui_baoxiang_guanbi"
	else
		seqCom:DeleteSeq("shake")
		iconPath = "activity_magicSchool_icon_2"
		if status == 2 then
			effRes = "fx_ui_baoxiang_quankai"
		end
	end

	local effKey = "boxEff"
	if effRes ~= self._oldEffRes then
		self._oldEffRes = effRes
		self:DestroyWndEffectByKey(effKey)
		self:CreateWndEffect(self.mEffRoot,effRes,effKey,100)
	end

	CS.ShowObject(self.mRedPoint,status == 1)
	self:SetWndEasyImage(self.mBoxicon,iconPath)

	self:SetWndClick(self.mBoxicon,function ()
		self:OnClickBox(data)
	end)
end

function UIDoubleValue:OnActivityPageResp(pb)
	if pb.sid ~= self._sid then
		return
	end

	local actConfig = gModelActivity:GetWebActivityDataById(self._sid)
	if not actConfig then
		return
	end

	local actData = gModelActivity:GetActivityBySid(self._sid)
	if not actData then
		return
	end

	self._endtime = actData.endTime
	if self._endtime > 0 then
		self:TimerStart(self._timerKey,1,false,-1)
		self:SetCountdown()
	else
		local str =ccClientText(18404) --"永久活动"
		self:SetWndText(self.mTime,str)
	end

	local config = actConfig.config
	self:SetWndText(self.mIntro,config.txt)

	local pageData = nil
	for i, v in ipairs(pb.pages) do
		if v.pageId == 1 then
			pageData = gModelActivity:GenerateActivePageDataFromPb(v)
			break
		end
	end

	if not pageData then
		return
	end

	self._pageData = pageData

	local dataID = config.dataId

	local pageCfg =gModelActivity:GetWebActivityPageData(self._sid,1)

    local dataList = {}
    for k,v in pairs(pageCfg.entries) do
		local entryId = v.id
		local entryData = pageData:GetEntry(entryId)

		if entryId ~= dataID then
			local data =
			{
				sid = self._sid,
				pageId = 1,
				entryId = entryId,
				title = v.description,
				reward = LxDataHelper.ParseItem(v.reward),
				schedule = entryData.goalData.schedules[1],
				status = entryData.goalData.status,
				jumpId = v.jumpId,
				sort = v.sort,
				completeSchedule = entryData.goalData.completionsInfo,
			}

			table.insert(dataList,data)
		else
			self._boxData =
			{
				entryData = entryData,
				reward = LxDataHelper.ParseItem(v.reward),
			}

		end
    end

	table.sort(dataList,function (a,b)
		local aPrio = a.status == 2 and 1 or 0
		local bPrio = b.status == 2 and 1 or 0
		if aPrio ~= bPrio then
			return aPrio < bPrio
		end

		return a.sort < b.sort
	end)

	self:ShowEntryList(dataList)

	local boxData = self._boxData
	self:ShowDailyReward(boxData)

	local helpTips = config.helpTips or 0
	local isShowHelp = helpTips == 1
	CS.ShowObject(self.mBtnHelp, isShowHelp)
	if isShowHelp then
		local helpTipsPosition = config.helpTipsPosition
		if not string.isempty(helpTipsPosition) then
			self:SetAnchorPos(self.mBtnHelp, LxDataHelper.ParseVector2NotEmpty(helpTipsPosition))
		end
		self._helpTipsContent = config.helpTipsContent
	end

end

function UIDoubleValue:OnActConfigRet()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIDoubleValue:OnClickBox(data)

	local itemdata = data.entryData
	if itemdata.goalData.status == 1 then
		local sid = self._sid
		local pageId = itemdata.pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	else
		GF.OpenWnd("UIringBoxDetail",{self.mBoxicon,data.reward})


		--GF.ShowMessage(ccClientText(12208))
	end
end

function UIDoubleValue:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")
	local itemRoot = self:FindWndTrans(AniRootItem,"root")

	self:CreateCommonIconImpl(itemRoot,itemdata)
end

function UIDoubleValue:ShowSpine()
	CS.ShowObject(self.mIntro,false)
	self:CreateWndSpine(self.mSpineRoot,"Yueduizhuti_b","spine1",false,function (spine)
		spine:SetAnimationCompleteFunc(function(...)
			spine:PlayAnimationSolid("idle", false)
			CS.ShowObject(self.mIntro,true)
		end)
		spine:PlayAnimationSolid("open", false)
	end)
end

function UIDoubleValue:SetStaticContent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndText(self.mCloseTip,ccClientText(10103))

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnHelp, function()
		self:OnClickHelp()
	end)

	self._timerKey = "_timerKey"
end

function UIDoubleValue:OnTimer(key)
	if self._timerKey == key then
		self:SetCountdown()
	end
end

function UIDoubleValue:ShowEntryList(dataList)
	local list = self:FindUIScroll("entryList")
	if list then
		list:RefreshList(dataList)
		list:DrawAllItems(false)
	else
		list= self:GetUIScroll("entryList")
		list:Create(self.mEntryList,dataList,function (...) self:OnDrawEntry(...) end,UIItemList.SUPER)
		list:DrawAllItems(true)
	end

	local pos = 1
	for k,v in ipairs(dataList) do
		if v.status  == 1 then
			pos = k
			break
		end
	end

	list:MoveToPos(pos)

end

function UIDoubleValue:SetCountdown()
	local timeLeft =math.floor(self._endtime - GetTimestamp())
	if timeLeft > 0 then
		local str = string.replace(ccClientText(27500),LUtil.FormatTimespanCn(timeLeft))
		self:SetWndText(self.mTime,str)
	else
		local str =ccClientText(14301) --"活动已结束"
		self:SetWndText(self.mTime,str)
		self:TimerStop(self._timerKey)
	end

end

function UIDoubleValue:OnWndRefresh()
	self._sid = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	local actData = gModelActivity:GetActivityBySid(self._sid)
	if not actData then
		return
	end

	self:SetWndText(self.mTitle,actData.title)

	gModelActivity:ReqActivityConfigData(self._sid)
end

------------------------------------------------------------------
return UIDoubleValue


