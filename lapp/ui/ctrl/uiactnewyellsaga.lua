---
--- Created by Administrator.
--- DateTime: 2023/10/20 21:01:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActNewYellSaga:LWnd
local UIActNewYellSaga = LxWndClass("UIActNewYellSaga", LWnd)
local UnityEngine = UnityEngine
local typeof = typeof
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

UIActNewYellSaga.TYPE_STAGEVIEW = 1 			-- 心愿舞台
UIActNewYellSaga.TYPE_GIFTVIEW = 2			-- 心愿礼包
UIActNewYellSaga.TYPE_WALLVIEW = 3			-- 心愿墙
UIActNewYellSaga.TYPE_PAEANVIEW = 4			-- 心愿赞歌


UIActNewYellSaga.TYPE_EXCHANGE = 7
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActNewYellSaga:UIActNewYellSaga()
	self._timerKey = "_timerKey"
	self._playAniKey = "playAniKey"
	self._runAnitimerKey = "_runAnitimerKey"
	self._loopScaleKey = "_loopScaleKey"
	self._changeImg = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActNewYellSaga:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActNewYellSaga:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActNewYellSaga:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mReturnBtnTxt,ccClientText(20812))
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActNewYellSaga:GetConfigData(data)
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end
	local configDataList = self._configDataList
	if not configDataList then
		configDataList = {}
		self._configDataList = configDataList
	end
	local config = webData.config
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local moreInfo = JSON.decode(activityData.moreInfo)
	local freeNum = moreInfo.freeNum
	self._freeNum = freeNum

	self._giftOptional = config.giftOptional

	self._probInfo = {
		desc = config.desc,
		title = activityData.title,
	}

    local jumpId = config.jumpId
    local jumpTxt = config.jumpTxt
    local showActivityShowTip = jumpId ~= nil and not string.isempty(jumpId)
    self:SetWndText(self.mActivityTipTxt,jumpTxt)
    self._showActivityShowTip = showActivityShowTip
    self._jumpId = jumpId

	-- 修改主题界面显示
	if not self._changeImg then
		local activityPartyBgBig1 = config.activityPartyBgBig1
		self:SetWndEasyImage(self.mDiTu,activityPartyBgBig1,function()
			CS.ShowObject(self.mDiTu,true)
		end)
		if self._playAni then
			self:SetWndEasyImage(self.mBg,activityPartyBgBig1,function()
				CS.ShowObject(self.mBg,true)
			end)
		end
		local activityPartyText1 = config.activityPartyText1
		self:SetWndEasyImage(self.mInfoTitleImg,activityPartyText1)

		local btnList = {self.mStageBtnIcon,self.mGiftBtnIcon,self.mWallBtnIcon,self.mPaeanBtnIcon}
		local btnIcon = string.split(config.btnIcon,";")
		for i,v in ipairs(btnIcon) do
			v = string.split(v,"=")
			local sBtnIcon = v[5]
			local btnTrans = btnList[i]
			if sBtnIcon and btnTrans then
				self:SetWndEasyImage(btnTrans,sBtnIcon, nil, true)
			end
		end

		local idHero = config.idHero
		local showP = idHero == 1
		CS.ShowObject(self.mNoSelHeroImg,showP)
		CS.ShowObject(self.mSelHeroSp,showP)
		CS.ShowObject(self.mSpineRoot1,showP)
        CS.ShowObject(self.mGiftEffRoot,showP)
		CS.ShowObject(self.mWallEffRoot,showP)
		CS.ShowObject(self.mPaeanEffRoot,showP)
		self._showP = showP

		self._changeImg = true
		self:Show()
	end

--[[	self._btnDivList = {
		self.mStageDiv,self.mGiftBtn,self.mWallBtn,self.mPaeanBtn
	}]]
    local btnDivList = self._btnDivList
    if btnDivList then
        local btnCoordinate = config.btnCoordinate
        --btnCoordinate = "230,835=125,225=-160,725=85,555"
        if not string.isempty(btnCoordinate) then
            btnCoordinate = string.split(btnCoordinate,"=")
            for i,v in ipairs(btnCoordinate) do
                local btnTrans = btnDivList[i]
                if btnTrans then
                    v = string.split(v,",")
                    local x,y = tonumber(v[1]),tonumber(v[2])
                    btnTrans.anchoredPosition = Vector2.New(x ,y)
                end
            end
        end
    end

	-- 第3页分页标签列表
	local btnIcon3List = {}
	self._page3ChangeBgStatus = {} 				-- 图片替换状态
	local btnIcon3 = string.split(config.btnIcon3,";")
	for i,v in ipairs(btnIcon3) do
		v = string.split(v,"=")
		local pageId = tonumber(v[1])
		table.insert(btnIcon3List,{
			pageId = pageId, 					-- pageId
			btnName = v[2],						-- 按钮名字
			btnImg = v[3],						-- 按钮图标
			pageBg = v[4],						-- 对应的背景图
		})
		self._page3ChangeBgStatus[pageId] = false
	end

	local showRoleShadowSpine = config.showRoleShadowSpine or 1
	CS.ShowObject(self.mSpineRoot1, showRoleShadowSpine == 1)

	local speakBgPos = config.speakBgPos
	if not string.isempty(speakBgPos) then
		self:SetAnchorPos(self.mActivityShowTipDiv, LxDataHelper.ParseVector2NotEmpty(speakBgPos))
	end

	self._page3Info = btnIcon3List

	self._mySelect = moreInfo.mySelect
	self._mySelectHero = moreInfo.mySelectHero

	self._itemId = moreInfo.itemId

	local endTime = activityData.endTime
	if endTime == 0 then
		-- 永久生效
		self:SetWndText(self.mCountDownTxt,"")
	else
		self._endTime = endTime
		self:CreateTime()
	end
	self:RefreshHeroShow()
	self:RefreshMyRedPoint()
end

function UIActNewYellSaga:RunAniFunc(times)
	self:TimerStop(self._runAnitimerKey)
	self:TimerStart(self._runAnitimerKey,times,false,1)
end

function UIActNewYellSaga:StarCountDown()
	local lastTime = self._endTime - GetTimestamp()
	if lastTime < 0 then
		self:SetWndText(self.mCountDownTxt,ccClientText(14301))
		self:TimerStop(self._timerKey)
	else
		local timeStr = LUtil.FormatTimespanCn(lastTime)
		--timeStr = LUtil.FormatColorStr(timeStr,"green")
		timeStr = string.replace(ccClientText(11640),timeStr)
		self:SetWndText(self.mCountDownTxt,timeStr)
	end
end

function UIActNewYellSaga:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.sid = self._sid
	wndArgList.playAni = self._playAni
	return list
end

function UIActNewYellSaga:BtnEvent(index)
	local sid = self._sid
	GF.OpenWnd("UIActNewYellSagaSow",{sid = sid,page = index,func = function()
		--GF.OpenWnd("UIActNewYellSaga",{sid = sid})
	end})
	--self:WndClose()
end

function UIActNewYellSaga:OnClickActivityShowBgFunc()
    if not self._jumpId then return end
    gModelFunctionOpen:Jump(self._jumpId,self:GetWndName())
end

function UIActNewYellSaga:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn,function()
		local probInfo = self._probInfo
		if not probInfo then return end
		local title,desc = probInfo.title,probInfo.desc
		GF.OpenWnd("UIBzTips",{title = title,text = desc,bTransWarp = true})
	end)
	for k,v in pairs(self._btnList) do
		self:SetWndClick(v.btnTrans,function()
			self:BtnEvent(v.index)
		end)
	end
    self:SetWndClick(self.mActivityShowTipBg,function()
        self:OnClickActivityShowBgFunc()
    end)
end

function UIActNewYellSaga:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if self._sid ~= sid then return end
		self:GetConfigData(data)
        if not self._init then
            self._init = true
            gModelActivity:OnActivityPageReq(self._sid)
        end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivitySelectDropGiftResp, function()
		self:GetConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityDropGiftResp, function()
		self:GetConfigData()
	end)
end

function UIActNewYellSaga:InitData()
	self._sid = self:GetWndArg("sid")
	self._playAni = self:GetWndArg("playAni")
	self._btnList = {
		[UIActNewYellSaga.TYPE_STAGEVIEW] = {
			index = UIActNewYellSaga.TYPE_STAGEVIEW,
			btnTrans = self.mStageBtn,
		},
		[UIActNewYellSaga.TYPE_GIFTVIEW] = {
			index = UIActNewYellSaga.TYPE_GIFTVIEW,
			btnTrans = self.mGiftBtn,
		},
		[UIActNewYellSaga.TYPE_WALLVIEW] = {
			index = UIActNewYellSaga.TYPE_WALLVIEW,
			btnTrans = self.mWallBtn,
		},
		[UIActNewYellSaga.TYPE_PAEANVIEW] = {
			index = UIActNewYellSaga.TYPE_PAEANVIEW,
			btnTrans = self.mPaeanBtn,
		},
	}

    self._btnDivList = {
        self.mStageDiv,self.mGiftBtn,self.mWallBtn,self.mPaeanBtn
    }

    self._init = false
end

function UIActNewYellSaga:RunAni()
	local spine1Key = "Xinyuanwutai"

	self:CreateWndSpine(self.mSpineRoot1,spine1Key,spine1Key,false,function (spine) end)
    self:TweenSeq_DefalutScale(self._loopScaleKey,self.mActivityShowTipDiv,{x = 0.9,y = 0.9,z = 0.9,time = 1.5,recover = true})
    --self:TweenSeq_LoopScale(self._loopScaleKey,self.mActivityShowTipBg)
	CS.ShowObject(self.mActivityShowTipDiv,self._showActivityShowTip)
	local list = {
		self.mInfoTitleImg,
		self.mHelpBtn,
		self.mCountDownBg,
		self.mStageDiv,
		self.mWallBtn,
		self.mPaeanBtn,
		self.mGiftBtn,
		self.mReturnBtn,
	}
	self:TweenSeqKill(self._playAniKey)
	local seqTween = self:TweenSeqCreate(self._playAniKey, function(seq)
		local showTime = 0.5
		for i,trans in ipairs(list) do
			local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
			if (not csCanvasGroup) then
				csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
			end
			csCanvasGroup.alpha = 0
			CS.ShowObject(trans,true)
			local tween = csCanvasGroup:DOFade(1,showTime)
			seq:Join(tween)
		end
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._playAniKey)
	end)
end

function UIActNewYellSaga:RefreshHeroShow()
	if self._mySelect == 0 and not self._mySelectHero then return end
	if not self._showP then return end
	local showHeroSp = self._mySelect ~= 0
	if self._mySelectHero then
		if self._prefabKey then
			self:DestroyWndSpineByKey(self._prefabKey)
		end
		local prefab = gModelHero:GetPrefabNameById(self._mySelectHero)
		if prefab then
			self._prefabKey = prefab
			self:CreateWndSpine(self.mSelHeroSp,prefab,prefab,false,function(spine)
				spine:PlayAnimation(0,"idle",true)
			end)
		end
	end
	CS.ShowObject(self.mSelHeroSp,showHeroSp)
	CS.ShowObject(self.mNoSelHeroImg,not showHeroSp)
end

function UIActNewYellSaga:CreateTime()
	self:TimerStop(self._timerKey)
	self:TimerStart(self._timerKey,1,false,-1)
end

function UIActNewYellSaga:OnActivityPageResp(pb,ret)
	self:GetConfigData()
	local sid = pb.sid
	if sid ~= self._sid then return end
	local activityData = self._activityData
	if not activityData then
		activityData = {}
		self._activityData = activityData
	end
	for i,v in ipairs(pb.pages or {}) do
		local pageData = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = pageData.pageId
		activityData[pageId] = {
			sid = pageData.sid,
			pageId = pageId,
		}
		activityData[pageId].entry = {}
		for idx,val in ipairs(pageData.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,val.pageId,val.entryId)
			if not entryCfg then return end
			local moreInfo = entryCfg.moreInfo
			local entryId = val.entryId
			local items = LxDataHelper.ParseItem(entryCfg.reward)
			local goalData = val.goalData
			local data = {
				entryId = entryId,
				pageId = pageId,
				title = entryCfg.name,
				desc = entryCfg.description,
				icon = entryCfg.icon,
				items = items,
				goalData = goalData,
				status  = goalData.status,
				MarketData = val.MarketData,
				moreInfo = moreInfo,
				sort = entryCfg.sort,
				jumpId = entryCfg.jumpId,
			}
			table.insert(activityData[pageId].entry, data)
		end
	end

	self:RefreshMyRedPoint()
	self:RefreshHeroShow()
end

function UIActNewYellSaga:OnTimer(key)
	if key == self._timerKey then
		self:StarCountDown()
	elseif key == self._runAnitimerKey then
		self:RunAni()
	end
end

function UIActNewYellSaga:GetWallRedPointStatusByPageId(pageId)
	local status = false
	local activityData = self._activityData
	if not activityData then return status end
	local pageDataList = activityData[pageId]
	if pageDataList then
		for idx,val in ipairs(pageDataList.entry) do
			if val.status == 1 then
				status = true
				break
			end
		end
	end
	return status
end

function UIActNewYellSaga:Show()
	local func = function(times)
		times = times or 0.8
		self:CreateAllEff()
		self:RunAniFunc(times)
		self._playAni = false
	end
	if self._playAni then
		self:PlayStarAni(func)
	else
		CS.ShowObject(self.mBg,false)
		func(0.1)
	end
end

function UIActNewYellSaga:PlayStarAni(func)
	local spineKey = "Xinyuanzhaohuan_men"
	self:CreateWndSpine(self.mSpineRoot,spineKey,spineKey,false,function (spine)
		self:TweenSeq_DefalutScale("scaleDefalut",self.mBg,{time = 0.5,loopNum = 1})
		spine:PlayAnimation(0,"idle",false)
		if func then func() end
	end)
end

function UIActNewYellSaga:RefreshMyRedPoint()
	local showStageRedPoint = self._freeNum and self._freeNum > 0 or false
	CS.ShowObject(self.mStageRedPoint,showStageRedPoint)

	local activityData = self._activityData
	if activityData then
		local sid = self._sid
		local giftOptional = self._giftOptional or ModelActivity.GIFTOPTIONAL_0
		local pageId = ModelActivity.MODEL_NEWHEROCALL_TYPE_GIFT_SEL
		local pageData,entryList
		local showGiftRedPoint = false
		if gModelActivity:CheckGiftoptionalStatus(sid,giftOptional,pageId) then
			pageData = activityData[pageId] or {}
			entryList = pageData.entry or {}
			for i,v in ipairs(entryList) do
				local MarketData = v.MarketData
				local personal,personalGoal = MarketData.personal,MarketData.personalGoal
				local buyNum = personalGoal - personal
				local expendType = MarketData.expendType
				if buyNum > 0 and expendType == 0 then
					showGiftRedPoint = true
					break
				end
			end
		end
		if not showGiftRedPoint then
			pageId = ModelActivity.MODEL_NEWHEROCALL_TYPE_GIFT_SHOP
			if gModelActivity:CheckGiftoptionalStatus(sid,giftOptional,pageId) then
				local player = gModelPlayer:GetPlayerLv()
				pageData = activityData[pageId] or {}
				entryList = pageData.entry or {}
				for i,v in ipairs(entryList) do
					local moreInfo = string.split(v.moreInfo,";")
					local showLv = moreInfo[2]
					local needShowLv = showLv and tonumber(showLv) or 0 --显示等级
					local ins = player >= needShowLv
					if ins then
						local MarketData = v.MarketData
						local personal,personalGoal = MarketData.personal,MarketData.personalGoal
						local buyNum = personalGoal - personal
						local expend2 = MarketData.expend2
						if buyNum > 0 and expend2 == "-1" then
							showGiftRedPoint = true
							break
						end
					end
				end
			end
		end
		CS.ShowObject(self.mGiftRedPoint,showGiftRedPoint)

		local showTargetRedPoint = false
		local page3Info = self._page3Info or {}
		for i,v in ipairs(page3Info) do
			local _pageId = v.pageId
			local status = self:GetWallRedPointStatusByPageId(_pageId)
			if status then
				showTargetRedPoint = true
				break
			end
		end
		CS.ShowObject(self.mWallRedPoint,showTargetRedPoint)

		pageId = UIActNewYellSaga.TYPE_EXCHANGE
		pageData = activityData[pageId] or {}
		local showExchangeRedPoint = false
		entryList = pageData.entry or {}
		local minPay = 9999
		for i,v in ipairs(entryList) do
			local MarketData = v.MarketData
			local expend2 = string.split(MarketData.expend2,"=")
			local value = tonumber(expend2[3])
			if value < minPay and MarketData.personalGoal > MarketData.personal then
				minPay = value
			end
		end
		local haveNum = gModelItem:GetNumByRefId(self._itemId)
		showExchangeRedPoint = haveNum >= minPay
		CS.ShowObject(self.mPaeanRedPoint,showExchangeRedPoint)
	end
end

function UIActNewYellSaga:CreateAllEff()
	local key1 = "fx_xyzh_xinyuanlibao"
	self:CreateWndEffect(self.mGiftEffRoot,key1,key1,100)
	local key2 = "fx_xyzh_xinyuanqiang"
	self:CreateWndEffect(self.mWallEffRoot,key2,key2,100)
	local key3 = "fx_xyzh_xinyuanzange"
	self:CreateWndEffect(self.mPaeanEffRoot,key3,key3,100)
	if not self._playAni then return end
	local key4 = "fx_xyzh_kaimen"
	self:CreateWndEffect(self.mEffRoot,key4,key4,100)
end

------------------------------------------------------------------
return UIActNewYellSaga


