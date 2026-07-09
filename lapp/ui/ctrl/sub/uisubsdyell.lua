---
--- Created by Administrator.
--- DateTime: 2024/5/9 11:46:02
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSdYell:LChildWnd
local UISubSdYell = LxWndClass("UISubSdYell", LChildWnd)
------------------------------------------------------------------

local UITigerDraw = LXImport('LApp.UI.Common.UITigerDraw')

--- 0:直接切换到下一等级的奖励
--- 1:领取完再切（举例：显示的内容全是1级的，暂时不显示2级的，玩家把奖励领完之后刷2级的内容）
UISubSdYell.DRAW_REWARD_STATE = 1


local number_imgs = {
	[0] = "halidom_num_0",
	[1] = "halidom_num_1",
	[2] = "halidom_num_2",
	[3] = "halidom_num_3",
	[4] = "halidom_num_4",
	[5] = "halidom_num_5",
	[6] = "halidom_num_6",
	[7] = "halidom_num_7",
	[8] = "halidom_num_8",
	[9] = "halidom_num_9",
}

UISubSdYell.SLIDER_N = 0
UISubSdYell.SLIDER_H = 1
UISubSdYell.SLIDER_C = 2
UISubSdYell.SLIDER_L = 3


UISubSdYell.TYPE_REWARD_NORMAL = 0
UISubSdYell.TYPE_REWARD_CANGET = 1
UISubSdYell.TYPE_REWARD_ALREADY = 2

UISubSdYell.IDLE_MOVE_SPEED =  100

UISubSdYell.LIST_REWARD_ITEMNUM = 5

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSdYell:UISubSdYell()
	---@type StructHalidomInfo
	self._info = nil

	---@type UITigerDraw
	self._uiTigerDraw = nil

	self._idleEffectKey = "_idleEffectKey"
	self._turnEffectKey = "_turnEffectKey"

	self._drawAniKey = "_drawAniKey"
	self._upLvAniKey = "_upLvAniKey"

	---@type boolean 播放动画中
	self._playAni = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSdYell:OnWndClose()

	if self._uiTigerDraw then
		self._uiTigerDraw:Destroy()
		self._uiTigerDraw = nil
	end

	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSdYell:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSdYell:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	gModelHalidom:EnterHalidomCall()
	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self._isJapaness  =gLGameLanguage:IsJapanVersion()
	self._idleShowList = {}
	self:InitAniTrans()
	self:InitBtnTrans()

	self:InitTrans()
	self:InitCommonReward()
	self:InitEffect()
	self:InitUITigerDraw()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	gModelHalidom:CheckIsReqInfo()
	self:InitData()
	self:RefreshJumpAniState()
	self:RefreshView()
	self:RefreshForeign()
end

function UISubSdYell:GetUseType()
	local useType = gModelHalidom:GetHalidomJackpotLv()
	if useType < ModelHalidom.CALL_SHOW_MAXNUM then
		--- 不是最高级，默认都是1级的显示
		useType = 1
	end
	return useType
end

function UISubSdYell:DoTurnAni(func,hasBigReward)
	self._playAni = true

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq(self._drawAniKey)

	local info = self:GetCurJackpotInfo(self._recordJackpotLv)
	if info then
		CS.ShowObject(info.idleEffTrans,false)
		CS.ShowObject(info.turnEffTrans,true)
	end

	self:InitAniTrans()

	if self._uiTigerDraw then
		LxUiHelper.PlayAudioSoundName(LSoundConst.HALIDOM_TURN)

		local speed = 2000
		self._uiTigerDraw:SetAllUIScrollSpeed(speed)

		local moveTimes = 0.3
		seq:InsertCallback(2,function()
		end)

		local endSpeed = 0
		local doAlpha = 0.1
		local doAlphaTime = moveTimes - doAlpha
		local list1StartTime = 2.1
		--- 加速
		seq:Insert(list1StartTime,YXTween.TweenFloat(speed,endSpeed, moveTimes, function(val)
			self._uiTigerDraw:SetUIScrollSpeedByTrans(self.mList1,val)
		end))
		--- 先设置节点显示
		seq:InsertCallback(list1StartTime + doAlphaTime,function()
			CS.ShowObject(self.mListRewardMove1,true)
		end)
		--- list 渐隐，listRewardMove 渐现
		seq:Insert(list1StartTime + doAlphaTime,YXTween.TweenFloat(1,0, doAlpha, function(val)
			self.mListCG1.alpha = val
			self.mListRewardMoveCG1.alpha = 1 - val
		end))
		--- 移动
		seq:Insert(list1StartTime,self.mListRewardMove1:DOMove(self.mStartPos1.position,moveTimes))


		local list2StartTime = 2.4
		--- 加速
		seq:Insert(list2StartTime,YXTween.TweenFloat(speed,endSpeed, moveTimes, function(val)
			self._uiTigerDraw:SetUIScrollSpeedByTrans(self.mList2,val)
		end))
		--- 先设置节点显示
		seq:InsertCallback(list2StartTime + doAlphaTime,function()
			CS.ShowObject(self.mListRewardMove2,true)
		end)
		--- list 渐隐，listRewardMove 渐现
		seq:Insert(list2StartTime + doAlphaTime,YXTween.TweenFloat(1,0, doAlpha, function(val)
			self.mListCG2.alpha = val
			self.mListRewardMoveCG2.alpha = 1 - val
		end))
		--- 移动
		seq:Insert(list2StartTime,self.mListRewardMove2:DOMove(self.mStartPos2.position,moveTimes))


		local list3StartTime = 2.7
		--- 加速
		seq:Insert(list3StartTime,YXTween.TweenFloat(speed,endSpeed, moveTimes, function(val)
			self._uiTigerDraw:SetUIScrollSpeedByTrans(self.mList3,val)
		end))
		--- 先设置节点显示
		seq:InsertCallback(list3StartTime + doAlphaTime,function()
			CS.ShowObject(self.mListRewardMove3,true)
		end)
		--- list 渐隐，listRewardMove 渐现
		seq:Insert(list3StartTime + doAlphaTime,YXTween.TweenFloat(1,0, doAlpha, function(val)
			self.mListCG3.alpha = val
			self.mListRewardMoveCG3.alpha = 1 - val
		end))
		--- 移动
		seq:Insert(list3StartTime,self.mListRewardMove3:DOMove(self.mStartPos3.position,moveTimes))
	end
	if hasBigReward then
		seq:InsertCallback(3,function()
			--- 2024/6/3： 大奖特效修改为 UI 界面显示
			--CS.ShowObject(self.mBigRewardEffect,true)
			GF.OpenWnd("UISdBigAward",{
				rewardType = 1
			})
		end)
	end
	seq:AppendInterval(2)
	seq:OnComplete(function()
		seqCom:DeleteSeq(self._drawAniKey)
		if info then
			CS.ShowObject(info.turnEffTrans,false)
			CS.ShowObject(info.idleEffTrans,true)
		end
		if func then func() end

		self:InitAniTrans()

		self._uiTigerDraw:SetAllUIScrollSpeed(UISubSdYell.IDLE_MOVE_SPEED)
	end)
	seq:PlayForward()
end

function UISubSdYell:DisposeRewardShow(pb,list,bigRewardId)
	local rewardIds = pb.rewardIds
	local isMore = #rewardIds > 1
	local itemNum = UISubSdYell.LIST_REWARD_ITEMNUM
	local centerPos = math.floor(itemNum / 2 + 1)
	local list1,list2,list3 = {},{},{}
	if isMore then
		--list1,list2,list3 = self:GetMoreReward(list,centerPos,itemNum,rewardIds)
		bigRewardId = bigRewardId or rewardIds[1]
		list1,list2,list3 = self:GetSimpleReward(list,centerPos,itemNum,{bigRewardId})
	else
		list1,list2,list3 = self:GetSimpleReward(list,centerPos,itemNum,rewardIds)
	end
	return list1,list2,list3
end

function UISubSdYell:RefreshBtnShow()
	local useType = self:GetUseType()
	local btnTransInfos = self._btnTransInfos
	local callOneInfo = btnTransInfos[ModelHalidom.TYPE_DRAW_ONCE]
	if callOneInfo then
		self:SetBtnShow(callOneInfo,useType)
	end

	local callTenInfo = btnTransInfos[ModelHalidom.TYPE_DRAW_MORE]
	if callTenInfo then
		self:SetBtnShow(callTenInfo,useType)
	end

end

function UISubSdYell:InitEvent()
	 self:SetWndClick(self.mBtnHelp,function() self:OnClickBtnHelpFunc() end)

	 --self:SetWndClick(self.mBtnCallOne,function() self:OnClickBtnCallOneFunc() end)
	local btnCallOneGameObj = self.mBtnCallOne.gameObject
	CS.SetPointerUp(btnCallOneGameObj,function()
		self:DisposeClickCallBtnState(ModelHalidom.TYPE_DRAW_ONCE)
		self:OnClickBtnCallOneFunc()
	end)
	CS.SetPointerDown(btnCallOneGameObj,function()
		self:DisposeClickCallBtnState(ModelHalidom.TYPE_DRAW_ONCE,1)
	end)


	 --self:SetWndClick(self.mBtnCallTen,function() self:OnClickBtnCallTenFunc() end)
	local btnCallTenGameObj = self.mBtnCallTen.gameObject
	CS.SetPointerUp(btnCallTenGameObj,function()
		self:DisposeClickCallBtnState(ModelHalidom.TYPE_DRAW_MORE)
		self:OnClickBtnCallTenFunc()
	end)
	CS.SetPointerDown(btnCallTenGameObj,function()
		self:DisposeClickCallBtnState(ModelHalidom.TYPE_DRAW_MORE,1)
	end)



	 self:SetWndClick(self.mBtnHalidomBook,function() self:OnClickBtnHalidomBookFunc() end)
	 self:SetWndClick(self.mBtnLook,function() self:OnClickBtnLookFunc() end)
	 self:SetWndClick(self.mJumpAniBtn,function() self:OnClickJumpAniBtnFunc() end)
	self:SetWndClick(self.mBtnLucky,function() self:OnClickBtnLuckyFunc() end)
end

--------------------------- self.mLuckList end


--------------------------- self.mNumImgList start

function UISubSdYell:GetNumImgList()
	local list = {}
	local numStr = gModelHalidom:GetHalidomRewardImageNums()
	if numStr then
		for i,v in ipairs(numStr) do
			v = tonumber(v)
			table.insert(list,{
				img = number_imgs[v]
			})
		end
	end
	return list
end

function UISubSdYell:GetUITigerDatas()
	local list = gModelHalidom:GetHalidomRewardLvIdleShowList(self._recordJackpotLv)
	self._idleShowList = list

	local results = {}
	for i,v in ipairs(list) do
		table.insert(results,{
			imgPath = gModelItem:GetItemIconByRefId(v.reward.itemId)
		})
	end
	local isStopState = false
	return {
		{
			trans = self.mList1,
			dataList = results,
			autoMove = true,
			isMoveState = isStopState,
			speed = UISubSdYell.IDLE_MOVE_SPEED,
		},
		{
			trans = self.mList2,
			dataList = results,
			autoMove = true,
			isMoveState = isStopState,
			speed = UISubSdYell.IDLE_MOVE_SPEED,
		},
		{
			trans = self.mList3,
			dataList = results,
			autoMove = true,
			isMoveState = isStopState,
			speed = UISubSdYell.IDLE_MOVE_SPEED,
		},
	}
end

function UISubSdYell:RefreshCallPayInfo()
	local hasFree = gModelHalidom:CheckRPHasFreeNum()
	local freeDrawCnt = gModelHalidom:GetHalidomFreeDrawCnt()
	local halidomExpend = gModelHalidom:GetHalidomExpend()
	self:SetCallPayInfo(halidomExpend,{
		payIconTrans = self.mCallOnePayIcon,
		payTxtTrans = self.mCallOnePayNum,
		hasFree = hasFree,
		freeDrawCnt = freeDrawCnt
	})

	local halidomMoreExpend = gModelHalidom:GetHalidomMoreExpend()
	self:SetCallPayInfo(halidomMoreExpend,{
		payIconTrans = self.mCallTenPayIcon,
		payTxtTrans = self.mCallTenPayNum,
		hasFree = false,
		freeDrawCnt = -1
	})
end

function UISubSdYell:SetJackpotShow(jackpotLv)
	if jackpotLv < 1 then jackpotLv = 1 end
	local transInfo = self:GetTransInfo(jackpotLv)
	for k,v in pairs(transInfo.baseTrans) do
		CS.ShowObject(v,true)
	end
	local idleEff = gModelHalidom:GetCallAniIdleAni(jackpotLv)
	self:CreateWndEffect_Ex({
		trans = transInfo.idleEffTrans,
		effName = idleEff,
		effKey = self._idleEffectKey,
		upSortOrder = 8,
		endFunc = function()
			CS.ShowObject(transInfo.idleEffTrans,true)
		end
	})
	local turnEff = gModelHalidom:GetCallAniTurnAni(jackpotLv)
	self:CreateWndEffect_Ex({
		trans = transInfo.turnEffTrans,
		effName = turnEff,
		effKey = self._turnEffectKey,
		upSortOrder = 8,
	})
end

function UISubSdYell:OnClickBtnLookFunc()
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()
	GF.OpenWnd("UISdAwardPre",{
		jackpotLv = jackpotLv,
	})
end

function UISubSdYell:InitMsg()
	self:WndEventRecv(EventNames.CLOSE_HALIDOM_REWARD,function (...) self:OnEventCloseHalidomReward() end)
	self:WndEventRecv(EventNames.CLOSE_BOOK_VIEW,function (...) self:OnEventCloseBookView() end)
	self:WndEventRecv(EventNames.On_Item_Change,function (...) self:OnItemChange() end)
	self:WndNetMsgRecv(LProtoIds.HalidomDrawResp,function(...) self:OnHalidomDrawResp(...) end)
	self:WndNetMsgRecv(LProtoIds.HalidomInfoResp,function(...) self:OnHalidomInfoResp(...) end)
	self:WndNetMsgRecv(LProtoIds.HalidomProgressRewardResp,function(...) self:OnHalidomProgressRewardResp(...) end)
end

function UISubSdYell:OnClickBtnHalidomBookFunc()
	GF.OpenWnd("UISd")
--[[	print("self._recordJackpotLv = " .. self._recordJackpotLv)
	self._recordJackpotLv = 2
	self:DoUpLvJackpotLvAni(self._recordJackpotLv)]]
end

function UISubSdYell:InitUITigerDraw()
	local datas = self:GetUITigerDatas()
	---@type UITigerDraw
	local uiTigerDraw = UITigerDraw:New()
	self._uiTigerDraw = uiTigerDraw
	uiTigerDraw:SetTigerListInfos(self,datas)
end

function UISubSdYell:_GetRewardState0()
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()
	return self:_GetCommonRewardList(jackpotLv)
end

function UISubSdYell:SetBtnShow(data,useType,clickType)
	if not data then return end
	clickType = clickType or  0
	local isClick = clickType == 1 and true or false
	for k,v in pairs(data) do
		local show = useType == k
		if show then
			CS.ShowObject(v.UpImgTrans,not isClick)
			CS.ShowObject(v.DownImgTrans,isClick)
		end
		CS.ShowObject(v.root,show)
	end
end

function UISubSdYell:GetCurJackpotInfo(jackpotLv)
	if not jackpotLv then return end
	return self:GetTransInfo(jackpotLv)
end

--------------------------- self.mLuckList start

function UISubSdYell:_GetCommonRewardList(jackpotLv)
	local datas = gModelHalidom:GetHalidomLuckyRewardsByJackpotLv(jackpotLv) or {}
	local list = {}
	for i,v in ipairs(datas) do
		local sliderType = UISubSdYell.SLIDER_N
		--if i == 1 then
		--	sliderType = UISubSdYell.SLIDER_H
		--elseif i == len then
		--	sliderType = UISubSdYell.SLIDER_L
		--else
		--	sliderType = UISubSdYell.SLIDER_C
		--end
		table.insert(list,{
			refId = v.refId,
			type = v.type,
			grad = v.grad,
			gradReward = v.gradReward,
			beforeGrad = v.beforeGrad,
			sliderType = sliderType,
		})
	end
	return list
end

function UISubSdYell:RefreshView()
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()
	local lvStr = string.replace(ccClientText(41503),jackpotLv)
	self:SetWndText(self.mJackpotLvTxt,lvStr)

	local canDrawCnt = gModelHalidom:GetHalidomCanDrawCnt()
	local halidomMaxNum = gModelHalidom:GetHalidomMaxNum()
	local loseDrawCnt = halidomMaxNum - canDrawCnt
	self:SetWndText(self.mJackpotCallNumTxt,string.replace(ccClientText(41504),loseDrawCnt,halidomMaxNum))

	self:SetWndText(self.mLuckNumTxt,gModelHalidom:GetCurJackpotItemNum())

	CS.ShowObject(self.mFullTarget,gModelHalidom:CheckIsMaxJackpotLv())

	if gModelHalidom:CheckIsMaxJackpotLv() then
		if self._isEnus then
			self:SetAnchorPos(self.mJackpotLvTxt,Vector2.New(-50,0))
		end
	end

	self:RefreshBtnShow()
	self:RefreshCallPayInfo()
	self:InitNumImgList()
	self:InitNeedAddItemList()
	self:InitLuckList()

	local hasFree = gModelHalidom:CheckRPHasFreeNum()
	--CS.ShowObject(self.mCallOneInfo,not hasFree)
	local btnOneName = hasFree and ccClientText(41547) or ccClientText(41507)
	self:SetWndButtonText(self.mBtnCallOne,btnOneName)

	CS.ShowObject(self.mBtnCallTenRP,gModelHalidom:CheckRPHasMoreDraw())

	self:RefreshHalidomBookRP()
end

function UISubSdYell:DisposeClickCallBtnState(drawType,clickType)
	local useType = self:GetUseType()
	local btnTransInfos = self._btnTransInfos
	local callInfo = btnTransInfos[drawType]
	if not callInfo then return end
	self:SetBtnShow(callInfo,useType,clickType)
end

function UISubSdYell:SetRewardData(trans,list)
	if not self._recordListRewardTransMap then
		self._recordListRewardTransMap = {}
	end
	local key = trans:GetInstanceID()
	local transMap = self._recordListRewardTransMap[key]
	if not transMap then
		transMap = {}
		self._recordListRewardTransMap[key] = transMap
	end
	for i = 1,UISubSdYell.LIST_REWARD_ITEMNUM do
		local data = list[i]
		local iconTrans = transMap[i]
		if not iconTrans then
			local rewardTrans = self:FindWndTrans(trans,"ListReward" .. i)
			if rewardTrans then
				iconTrans = self:FindWndTrans(rewardTrans,"Icon")
				transMap[i] = iconTrans
			end
		end
		if data and iconTrans then
			local iconPath = gModelItem:GetItemIconByRefId(data.reward.itemId)
			self:SetWndEasyImage(iconTrans,iconPath,function()
				CS.ShowObject(iconTrans,true)
			end,true)
		end
	end
end

function UISubSdYell:OnClickAddBtnFunc(itemdata)
	gModelGeneral:OpenGetWayWnd({itemId = itemdata.itemId,srcWnd = self:GetWndName()})
end

function UISubSdYell:OnClickBtnCallTenFunc()
	if not self:CheckIsCanDraw() then return end
	gModelHalidom:DisposeHalidomDrawReq(ModelHalidom.TYPE_DRAW_MORE)
end

function UISubSdYell:InitData()
	self._halidomDrawJumpAni = gModelHalidom:CheckIsHalidomDrawJumpAni()
end

function UISubSdYell:RefreshJumpAniState()
	CS.ShowObject(self.mJumpAniBgGou,self._halidomDrawJumpAni)
end

function UISubSdYell:OnDrawNumImgCell(list, item, itemdata, itempos)
	local NumImg = self:FindWndTrans(item,"NumImg")
	self:SetWndEasyImage(NumImg,itemdata.img,function()
		CS.ShowObject(NumImg,true)
	end,true)
end

function UISubSdYell:GetLuckList()
--[[	if UISubSdYell.DRAW_REWARD_STATE == 0 then
		return self:_GetRewardState0()
	elseif UISubSdYell.DRAW_REWARD_STATE == 1 then
		return self:_GetRewardState1()
	end]]
	local progressRewardLv = gModelHalidom:GetHalidomProgressRewardLv()
	return self:_GetCommonRewardList(progressRewardLv)
end

function UISubSdYell:OnItemChange()
	self:RefreshView()
end


function UISubSdYell:InitText()
	self:SetWndButtonText(self.mBtnCallTen,ccClientText(41508))
	self:SetWndText(self.mJumpAniBgTxt,ccClientText(41505))
	self:SetTextTile(self.mBtnLucky,ccClientText(41501))
	self:SetTextTile(self.mBtnHalidomBook,ccClientText(41502))
	self:SetWndText(self.mFullTargetTxt,ccClientText(41551))
end

function UISubSdYell:InitNumImgList()
	local list = self:GetNumImgList()
	local uiList = self:FindUIScroll("mNumImgList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mNumImgList")
		uiList:Create(self.mNumImgList, list, function(...) self:OnDrawNumImgCell(...) end)
	end
	local hasImgs = #list > 0
	CS.ShowObject(self.mUpLvJackpotDiv,hasImgs)
end

function UISubSdYell:OnHalidomInfoResp(pb)
	self:RefreshView()
end

---- 配套使用图片节点
function UISubSdYell:InitTrans()
	self._transInfos = {
		[1] = {
			baseTrans = {
				topBg = self.mJQTopBg1,
				jqImg = self.mJQImg1,
				wzImg = self.mWenzidi1,
			},
			idleEffTrans = self.mIdelEffect1,
			turnEffTrans = self.mTurnEffect1,
		},
		[2] = {
			baseTrans = {
				topBg = self.mJQTopBg2,
				jqImg = self.mJQImg2,
				wzImg = self.mWenzidi2,
			},
			idleEffTrans = self.mIdelEffect2,
			turnEffTrans = self.mTurnEffect2,
		},
		[3] = {
			baseTrans = {
				topBg = self.mJQTopBg3,
				jqImg = self.mJQImg3,
				wzImg = self.mWenzidi3,
			},
			idleEffTrans = self.mIdelEffect3,
			turnEffTrans = self.mTurnEffect3,
		},
	}
end

function UISubSdYell:OnDrawNeedAddItemCell(list, item, itemdata, itempos)
	local IconTrans = self:FindWndTrans(item,"IconDiv/Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local AddBtnTrans = self:FindWndTrans(item,"BtnDiv/AddBtn")

	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans,icon)

	local haveNum = gModelItem:GetNumStrByRefId(itemId)
	self:SetWndText(NumTrans,haveNum)

	self:SetWndClick(AddBtnTrans,function()
		self:OnClickAddBtnFunc(itemdata)
	end)
end

function UISubSdYell:RefreshHalidomBookRP()
	CS.ShowObject(self.mBtnHalidomBookRP,gModelHalidom:CheckRPHasBook())
end

function UISubSdYell:OnEventCloseHalidomReward()
	--CS.ShowObject(self.mBigRewardEffect,false)
	if not self._recordJackpotLv then return end
	local curJackpotLv = gModelHalidom:GetHalidomJackpotLv()
	if curJackpotLv > self._recordJackpotLv then
		self._recordJackpotLv = curJackpotLv
		self:DoUpLvJackpotLvAni(self._recordJackpotLv)
	end
end

function UISubSdYell:DoUpLvJackpotLvAni(jackpotLv)
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq(self._upLvAniKey)
	CS.ShowObject(self.mUpLvBEffect,true)
	CS.ShowObject(self.mUpLvLEffect,true)
	seq:InsertCallback(4,function()
		self:ReSetJackpotShow()
		self:SetJackpotShow(jackpotLv)
		if self._uiTigerDraw then
			local datas = self:GetUITigerDatas()
			self._uiTigerDraw:RefreshAllUIScrollList(datas)
		end
	end)
	seq:AppendInterval(5)
	seq:OnComplete(function()
		CS.ShowObject(self.mUpLvBEffect,false)
		CS.ShowObject(self.mUpLvLEffect,false)
	end)
	seq:PlayForward()
end

function UISubSdYell:OnClickBtnCallOneFunc()
	if not self:CheckIsCanDraw() then return end
	gModelHalidom:DisposeHalidomDrawReq(ModelHalidom.TYPE_DRAW_ONCE)
end

function UISubSdYell:CheckIsCanDraw()
	if self._playAni then return false end
	return true
end

function UISubSdYell:RandomList(list,index)
	local results = {}
	local isDown = index % 2 == 0
	for i,v in ipairs(list) do
		table.insert(results,v)
	end
	local sortFunc
	if isDown then
		sortFunc = function(a,b)
			return a.refId > b.refId
		end
	else
		sortFunc = function(a,b)
			return a.refId < b.refId
		end
	end
	table.sort(results,sortFunc)
	return results
end

function UISubSdYell:ReSetJackpotShow()
	for k,v in pairs(self._transInfos) do
		for key,val in pairs(v.baseTrans) do
			CS.ShowObject(val,false)
		end
		CS.ShowObject(v.idleEffTrans,false)
		CS.ShowObject(v.turnEffTrans,false)
	end
end

function UISubSdYell:_GetRewardState1()
	local jackpotLv = self:GetShowRewardLv()
	printInfoNR2("领取完再切：","当前领取的等级："..jackpotLv)
	return self:_GetCommonRewardList(jackpotLv)
end

function UISubSdYell:InitLuckList()
	local list = self:GetLuckList()
	if not self._uiLuckListWidth then
		self._uiLuckListWidth = self.mLuckList.sizeDelta.x
	end
	local len = #list
	self._itemHorLen = self._uiLuckListWidth / len
	local uiList = self:FindUIScroll("mLuckList")
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems(false)
	else
		uiList = self:GetUIScroll("mLuckList")
		uiList:Create(self.mLuckList, list, function(...)
			self:OnDrawLuckCell(...)
		end,UIItemList.SUPER)
	end
	uiList:EnableScroll(false)

	local curNum = gModelHalidom:GetCurJackpotItemNum()
	local dataList = {}
	for i,v in ipairs(list) do
		table.insert(dataList,v.grad)
	end
	local percent = LUtil.GetCurPercent(dataList,curNum)
	LxUiHelper.SetProgress(self.mLuckySlider, percent)
	CS.ShowObject(self.mLuckySlider,true)
end

function UISubSdYell:GetTransInfo(index)
	return self._transInfos[index]
end

function UISubSdYell:OnDrawLuckCell(list, item, itemdata, itempos)
	local Root = self:FindWndTrans(item,"Root")
	local CommonUI = self:FindWndTrans(Root,"CommonUI")
	local Icon = self:FindWndTrans(CommonUI,"Icon")
	local AlreadyRec = self:FindWndTrans(CommonUI,"AlreadyRec")
	local CanGet = self:FindWndTrans(CommonUI,"CanGet")

	local NumTxt = self:FindWndTrans(Root,"NumTxt")

	local HSlider = self:FindWndTrans(item,"HSlider")
	local CSlider = self:FindWndTrans(item,"CSlider")
	local LSlider = self:FindWndTrans(item,"LSlider")

	local gradReward = itemdata.gradReward
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(gradReward.itemType, gradReward.itemId, gradReward.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	self:SetIconClickScale(Icon, true)

	local grad = itemdata.grad
	self:SetWndText(NumTxt,grad)

	local state = self:IsLuckState(itemdata)
	local showCanGet = state == UISubSdYell.TYPE_REWARD_CANGET
	CS.ShowObject(AlreadyRec,state == UISubSdYell.TYPE_REWARD_ALREADY)
	CS.ShowObject(CanGet,showCanGet)

	self:SetWndClick(Icon,function()
		if showCanGet then
			gModelHalidom:OnHalidomProgressRewardReq()
		else
			gModelGeneral:ShowCommonItemTipWnd(gradReward)
		end
	end)

	local sliderType = itemdata.sliderType
	local showHSlider = sliderType == UISubSdYell.SLIDER_H
	local showCSlider = sliderType == UISubSdYell.SLIDER_C
	local showLSlider = sliderType == UISubSdYell.SLIDER_L

	local sliderTrans = nil
	if showHSlider then
		sliderTrans = HSlider
	elseif showLSlider then
		sliderTrans = LSlider
	else
		sliderTrans = CSlider
	end

	local progress = 0
	local curNum = gModelHalidom:GetCurJackpotItemNum()
	if curNum >= grad then
		progress = 1
	else
		local beforeGrad = itemdata.beforeGrad
		local enoughNum = curNum - beforeGrad
		local progressNum = grad - beforeGrad
		progress = enoughNum / progressNum
	end
	LxUiHelper.SetProgress(sliderTrans, progress)


	CS.ShowObject(HSlider,showHSlider)
	CS.ShowObject(CSlider,showCSlider)
	CS.ShowObject(LSlider,showLSlider)


	LxUiHelper.SetSizeWithCurAnchor(item,0,self._itemHorLen)
end

function UISubSdYell:InitEffect()
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()
	if jackpotLv > ModelHalidom.CALL_SHOW_MAXNUM then
		jackpotLv = ModelHalidom.CALL_SHOW_MAXNUM
	end
	if jackpotLv < 1 then jackpotLv = 1 end
	self._recordJackpotLv = jackpotLv
	self:ReSetJackpotShow()
	self:SetJackpotShow(jackpotLv)
end

function UISubSdYell:OnClickBtnHelpFunc()
	---# 2024/5/22 都打开概率公示界面
	--GF.OpenWnd("UIBzTips",{refId = 162})

	self:OnClickBtnLookFunc()
end

function UISubSdYell:GetSimpleReward(list,centerPos,itemNum,rewardIds)
	local list1,list2,list3 = {},{},{}
	local tempList1 = self:RandomList(list,1)
	local tempList2 = self:RandomList(list,2)
	local tempList3 = self:RandomList(list,3)
	for i = 1,itemNum do
		local data1,data2,data3
		if i == centerPos then
			local sameReward = gModelHalidom:GetHalidomRewardByRefId(rewardIds[1])
			printInfoNR2("奖励：","rewardIds[1] = " .. rewardIds[1] .. "，奖励：" .. sameReward.reward.itemId)
			data1 = sameReward
			data2 = sameReward
			data3 = sameReward
		else
			data1 = tempList1[i]
			if not data1 then
				data1 = tempList1[math.random(1,#tempList1)]
			end
			data2 = tempList2[i]
			if not data2 then
				data2 = tempList2[math.random(1,#tempList2)]
			end
			data3 = tempList3[i]
			if not data3 then
				data3 = tempList3[math.random(1,#tempList3)]
			end
		end
		if data1 then
			table.insert(list1,data1)
		end
		if data2 then
			table.insert(list2,data2)
		end
		if data3 then
			table.insert(list3,data3)
		end
	end
	return list1,list2,list3
end

function UISubSdYell:InitNeedAddItemList()
	local list = self:GetNeedAddItemList()
	local uiList = self:FindUIScroll("mNeedAddItemList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mNeedAddItemList")
		uiList:Create(self.mNeedAddItemList, list, function(...) self:OnDrawNeedAddItemCell(...) end)
	end
end

function UISubSdYell:SetCallPayInfo(payInfo,data)
	local hasFree = data.hasFree
	local freeDrawCnt = data.freeDrawCnt

	local payIconTrans = data.payIconTrans
	local numStr = ""
	local showIconParent = false
	if hasFree and freeDrawCnt > 0 then
		CS.ShowObject(payIconTrans,false)
		numStr = string.replace(ccClientText(41548),freeDrawCnt)
	else
		showIconParent = true
		local itemId = payInfo.itemId
		local iconPath = gModelItem:GetItemIconByRefId(itemId)
		self:SetWndEasyImage(payIconTrans,iconPath,function()
			CS.ShowObject(payIconTrans,true)
		end,true)

		local hasNum = gModelItem:GetNumByRefId(itemId)
		local itemNum = payInfo.itemNum
		local isEnough = hasNum >= itemNum
		local showStr = isEnough and ccClientText(41509) or ccClientText(41510)
		numStr = string.replace(showStr,LUtil.NumberCoversion(hasNum),LUtil.NumberCoversion(itemNum))
	end
	CS.ShowObject(payIconTrans.parent,showIconParent)
	self:SetWndText(data.payTxtTrans,numStr)
end

function UISubSdYell:OnEventCloseBookView()
	self:RefreshHalidomBookRP()
end

function UISubSdYell:GetShowRewardLv()
	local jackpotLv = gModelHalidom:GetHalidomJackpotLv()
	local progressRewardLv = gModelHalidom:GetHalidomProgressRewardLv()
	local initHalidomLuckyRefList = gModelHalidom:GetHalidomLuckyRefDatas()
	for i,v in ipairs(initHalidomLuckyRefList) do
		if jackpotLv > v.type then
			for idx,val in ipairs(v.list) do
				if progressRewardLv < val.refId then
					return v.type
				end
			end
		end
	end
	return jackpotLv
end

--------------------------- self.mNumImgList end




function UISubSdYell:GetNeedAddItemList()
	local list = {}
	---# 2024/6/6：屏蔽砖石
	--table.insert(list,{
	--	itemType = LItemTypeConst.TYPE_ITEM,
	--	itemId = ModelItem.ITEM_DIAMOND,
	--})
	local halidomExpend = gModelHalidom:GetHalidomExpend()
	if halidomExpend then
		table.insert(list,halidomExpend)
	end
	return list
end

function UISubSdYell:InitAniTrans()
	CS.ShowObject(self.mListRewardMove1,false)
	CS.ShowObject(self.mListRewardMove2,false)
	CS.ShowObject(self.mListRewardMove3,false)
	self.mListRewardMove1.position = self.mEndPos1.position
	self.mListRewardMove2.position = self.mEndPos2.position
	self.mListRewardMove3.position = self.mEndPos3.position
	self.mListRewardMoveCG1.alpha = 0
	self.mListRewardMoveCG2.alpha = 0
	self.mListRewardMoveCG3.alpha = 0

	self.mListCG1.alpha = 1
	self.mListCG2.alpha = 1
	self.mListCG3.alpha = 1
	CS.ShowObject(self.mList1,true)
	CS.ShowObject(self.mList2,true)
	CS.ShowObject(self.mList3,true)
end

function UISubSdYell:InitBtnTrans()
	local maxLv = ModelHalidom.CALL_SHOW_MAXNUM
	local btnCallOne = self.mBtnCallOne
	local btnCallOneN = self:FindWndTrans(btnCallOne,"Normal")
	local btnCallOneH = self:FindWndTrans(btnCallOne,"High")
	local dataOne = {
		[1] = {
			root = btnCallOneN,
			UpImgTrans = self:FindWndTrans(btnCallOneN,"UpImg"),
			DownImgTrans = self:FindWndTrans(btnCallOneN,"DownImg"),
		},
		[maxLv] = {
			root = btnCallOneH,
			UpImgTrans = self:FindWndTrans(btnCallOneH,"UpImg"),
			DownImgTrans = self:FindWndTrans(btnCallOneH,"DownImg"),
		}
	}

	local btnCallTen = self.mBtnCallTen
	local btnCallTenN = self:FindWndTrans(btnCallTen,"Normal")
	local btnCallTenH = self:FindWndTrans(btnCallTen,"High")
	local dataTen = {
		[1] = {
			root = btnCallTenN,
			UpImgTrans = self:FindWndTrans(btnCallTenN,"UpImg"),
			DownImgTrans = self:FindWndTrans(btnCallTenN,"DownImg"),
		},
		[maxLv] = {
			root = btnCallTenH,
			UpImgTrans = self:FindWndTrans(btnCallTenH,"UpImg"),
			DownImgTrans = self:FindWndTrans(btnCallTenH,"DownImg"),
		}
	}

	self._btnTransInfos = {
		[ModelHalidom.TYPE_DRAW_ONCE] = dataOne,
		[ModelHalidom.TYPE_DRAW_MORE] = dataTen,
	}
end

function UISubSdYell:InitCommonReward()
	self:CreateWndEffect_Ex({
		trans = self.mUpLvLEffect,
		effName = ModelHalidom.CALL_UPLV_BG,
		effKey = ModelHalidom.CALL_UPLV_BG,
		upSortOrder = 2,
		endFunc = function()
			CS.ShowObject(self.mUpLvLEffect,false)
		end
	})

	self:CreateWndEffect_Ex({
		trans = self.mUpLvBEffect,
		effName = ModelHalidom.CALL_UPLV_QIAN,
		effKey = ModelHalidom.CALL_UPLV_QIAN,
		upSortOrder = 6,
		endFunc = function()
			CS.ShowObject(self.mUpLvBEffect,false)
		end
	})

	--- 2024/6/3： 大奖特效修改为 UI 界面显示
--[[	self:CreateWndEffect_Ex({
		trans = self.mBigRewardEffect,
		effName = ModelHalidom.CALL_DAJIANG,
		effKey = ModelHalidom.CALL_DAJIANG,
		upSortOrder = 6,
		endFunc = function()
			CS.ShowObject(self.mUpLvEffect,false)
		end
	})]]
end

function UISubSdYell:OnClickJumpAniBtnFunc()
	self._halidomDrawJumpAni = not self._halidomDrawJumpAni
	gModelHalidom:SetHalidomDrawJumpAni(self._halidomDrawJumpAni)
	self:RefreshJumpAniState()
end

function UISubSdYell:OnHalidomProgressRewardResp(pb)
	self:RefreshView()
end

function UISubSdYell:RefreshForeign()
	if self._isJapaness then
		self:InitTextSizeWithLanguage(self.mJackpotCallNumTxt,-4)
		self:InitTextSizeWithLanguage(self.mJumpAniBgTxt,-4)
		self:SetAnchorPos(self.mJumpAniBtn,Vector2.New(130,0))
	end
end

function UISubSdYell:OnClickBtnLuckyFunc()
	GF.OpenWnd("UISdIntegralPre")
end

function UISubSdYell:OnHalidomDrawResp(pb)
	local func = function()
		gModelHalidom:DisposeRewardIds(pb,ModelHalidom.WAY_REWARD_DRAW)
		self._playAni = false
		self:RefreshView()
		gModelGameHelper:RefreshGameSpeed()
	end

	if gModelHalidom:CheckHasRewardUI() then
		func()
		return
	end

	if gModelHalidom:CheckIsHalidomDrawJumpAni() then
		func()
	else
		local bigRewardId = nil
		local hasBigReward = false
		for i,v in ipairs(pb.rewardIds) do
			if gModelHalidom:CheckHalidomRewardIsShowBig(v) then
				hasBigReward = true
				bigRewardId = v
				break
			end
		end

		local list = gModelHalidom:GetHalidomRewardLvShowList(self._recordJackpotLv)
		local list1,list2,list3 = self:DisposeRewardShow(pb,list,bigRewardId)

		self:SetRewardData(self.mListRewardMove1,list1)
		self:SetRewardData(self.mListRewardMove2,list2)
		self:SetRewardData(self.mListRewardMove3,list3)
		self:DoTurnAni(func,hasBigReward)
		gModelGameHelper:TemporaryCloseSpeed()
	end
end

function UISubSdYell:IsLuckState(itemdata)
	local grad = itemdata.grad
	local refId = itemdata.refId
	local progressRewardId = gModelHalidom:GetHalidomProgressRewardId()
	local curItemNum = gModelHalidom:GetCurJackpotItemNum()
	if curItemNum >= grad and progressRewardId < refId then
		return UISubSdYell.TYPE_REWARD_CANGET
	end
	if curItemNum >= grad and progressRewardId >= refId then
		return UISubSdYell.TYPE_REWARD_ALREADY
	end
	return UISubSdYell.TYPE_REWARD_NORMAL
end

--- 多连抽奖励显示
function UISubSdYell:GetMoreReward(list,centerPos,itemNum,rewardIds)
	local list1,list2,list3 = {},{},{}
	local tempList1 = self:RandomList(list,1)
	local tempList2 = self:RandomList(list,2)
	local tempList3 = self:RandomList(list,3)
	for i = 1,itemNum do

	end
end

------------------------------------------------------------------
return UISubSdYell