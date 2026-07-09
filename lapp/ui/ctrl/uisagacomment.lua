---
--- Created by Administrator.
--- DateTime: 2023/10/4 17:19:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaComment:LWnd
local UISagaComment = LxWndClass("UISagaComment", LWnd)
local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
---@type LUIDrawingCtrl
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXUIPointUtil = CS.YXUIPointUtil

UISagaComment.NO_HAVE_HEAD_REFID = 10050 							-- 没有头像使用默认
UISagaComment.NO_HAVE_HEADFRAME_REFID = 20050 						-- 没有头像框使用默认
UISagaComment.CREATETIME_FORMAT = "%Y-%m-%d %H:%M" 				-- 时间格式化

UISagaComment.REFRESH_LIST_TYPE_1 = 1 								-- 正常刷新
UISagaComment.REFRESH_LIST_TYPE_2 = 2 								-- 评论点赞刷新
UISagaComment.REFRESH_LIST_TYPE_3 = 3 								-- 发送评论刷新

UISagaComment.TALENT_PROFILE = 1									-- 达人简评
UISagaComment.PLAYER_COMMENT = 2									-- 玩家评论
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaComment:UISagaComment()
	self._commonUIList = {}
	self._oldStr = ""
	---@type LUIHeroObject
	self._curUIHeroObj = nil 			-- 当前spine
	self._curUILiHuiObj = nil			-- 当前立绘
	---@type LUISkillCtrl
	self._uiSkillCtrl = nil

	---@type LUIDrawingCtrl
	self._uiDrawingCtrl = nil

	self._loopHeroObjTimerKey = 1119

	self._effectKey = "_effectKey"
	self._playerAni = false

	self._countDownTime = 0

    local wndInst = GF.FindFirstWndByName("UIOrdinBulletSay")
    if not wndInst then
        local cd = gModelChat:GetChatConfigRefByKey("textShowSpeed")
        local colorList = gModelHero:GetBarrageColorList()
        gModelHeroBook:OpenCommonBarrage({
            cd = cd,
            colorList = colorList,
            barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT,
            heroRefId = self._refId,
            autoRun = false,
        })
    end
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaComment:OnWndClose()
	self:ClearCommonIconList(self._commonUIList)
	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end
	if self._uiDrawingCtrl then
		self._uiDrawingCtrl:Destroy()
		self._uiDrawingCtrl = nil
	end
	if self._curUIHeroObj then
		self._curUIHeroObj:Destroy()
		self._curUIHeroObj = nil
	end
	if self._curUILiHuiObj then
		self._curUILiHuiObj:Destroy()
		self._curUILiHuiObj = nil
	end

	local haveHero = gModelHeroBook:GetHeroIsActByRefId(self._refId)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"伙伴评论close",self._refId,haveHero)

	FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS,false)
	gModelHeroBook:SetBarrageStatus(self._showBarrage)

    local UISagaBook = GF.FindFirstWndByName("UIOrdinBulletSay")
    if not UISagaBook then
        GF.CloseWndByName("UIOrdinBulletSay")
    end

	LxTimer.LoopTimeStop(self._timer)
	self._timer = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaComment:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaComment:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitText()
	self:InitEmptyList()
	self:InitInputEvent()
	self:InitEvent()
	self:InitData()
	self:InitMsg()
	self:RefreshHeroShow()
	if self._refId then gModelHeroBook:OnHeroLoveInfoReq(self._refId) end

	--self:DisableInputText(self.mCommentText)
	self:SetWndText(self.mReturnTxt, ccClientText(30205)) --返回
	self:RefrehFuncBtnShow()
	self:InitFaceBtnShow()
	self:RefreshView()
	self:RefreshVersionShow()
end

function UISagaComment:RefreshView()
	self:RefreshBtnStatus()
	self:DestroyWndEffectAll()
	self._onClickSysRefId = nil
	local commentTapType = self._commentTapType
	if commentTapType == UISagaComment.TALENT_PROFILE then
		self:RefreshProfileView()
	elseif commentTapType == UISagaComment.PLAYER_COMMENT then
		self:RefreshCommentView()
	end
end

--选择表情
function UISagaComment:OnClickFace(faceinstead)
	--self.mCommentText.text = self.mCommentText.text..faceinstead
	self:SetWndTextInput(self.mCommentText, self.mCommentText.text..faceinstead)
end

function UISagaComment:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroCommentListResp,function (pb) self:OnHeroCommentListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.HeroLoveInfoResp,function (pb) self:OnHeroLoveInfoResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.HeroForCommentResp,function (pb) self:OnHeroForCommentResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.HeroCommentForLoveResp,function (pb) self:OnHeroCommentForLoveResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.CommentNumResp,function(pb) self:OnCommentNumResp(pb) end)
	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function () self:RefrehFuncBtnShow() end)
	self:WndNetMsgRecv(LProtoIds.HeroSysCommentInfoResp,function (pb) self:OnHeroSysCommentInfoResp(pb) end)
end

function UISagaComment:OnHeroLoveInfoResp(pb)
	-- 喜欢英雄
	local heroLoveInfo = gModelHeroBook:GetGeneralHeroLoveInfoFromPb(pb.heroLoveInfo)
	local heroRefId = heroLoveInfo.heroRefId
	if self._refId ~= heroRefId then return end
	self:RefreshLoveInfoView(heroLoveInfo)
end

function UISagaComment:InitInputEvent()
	self.mCommentText.onValueChanged:AddListener(function (str)
		self:OnInputComment(str)
	end)
end

function UISagaComment:OnInputComment(str)
	local msg = LUtil.FilterEmoji(str,"?")

	local func = function(isMatch,newText)
		if self:IsWndClosed() then
			return
		end
		local finalText = LUtil.ChatInfoFaceBinToDec(newText)
		self:OnInputDes(finalText)
	end

	LWordMaskUtil.ClearShieldWordEx(msg,false,true,LGameWordMask.SCENE_TYPE_PUBLIC_DATA,func)
	--msg = LWordMaskUtil.ClearShieldWord(msg,false,nil,true)
	--msg = LUtil.ChatInfoFaceBinToDec(msg)
	--self:OnInputDes(msg)
end

function UISagaComment:CreateLiHui(effectId,heroDrawing,pos1Scale)
	pos1Scale = pos1Scale or 1
	---@type LUIHeroObject
	local uiLiHuiObj = LUIHeroObject:New(self)
	self._curUILiHuiObj = uiLiHuiObj
	uiLiHuiObj:Create(self.mHeroLiHuiPos,heroDrawing,heroDrawing)
	uiLiHuiObj:SetHeroBgParams({
		effRef = gModelHero:GetShowEffectById(effectId),
		lihuiBgTrans = self.mHeroLiHuiBgPos,
		lihuiHdTrans = self.mHeroLiHuiHdPos,
	})
	uiLiHuiObj:SetLoadedFunction(function()
--[[
		--- 2024/7/4：不按照是否拥有英雄判断，改为图鉴是否激活
		local hasHeros = gModelHero:GetRefIdTypeList(self._refId)
		if hasHeros then
			uiLiHuiObj:PlayIdleAni()
		else
			uiLiHuiObj:PlayCalmAni()
		end]]

		local isActive = gModelHeroBook:FindHeroInfoStatusByHeroRefId(self._refId)
		if isActive then
			uiLiHuiObj:PlayIdleAni()
		else
			uiLiHuiObj:PlayCalmAni()
		end
	end)
	uiLiHuiObj:SetRectMatch(true)
	uiLiHuiObj:ShowHero(true)
	uiLiHuiObj:SetScale(pos1Scale)
	uiLiHuiObj:StartLoad()

	local uiDrawCtrl = LUIDrawingCtrl:New()
	self._uiDrawingCtrl = uiDrawCtrl
	uiDrawCtrl:SetHeroObject(uiLiHuiObj)
	uiDrawCtrl:SetEffectInfo(self.mHeroLiHuiEffPos, 1, 6, 100)
	uiDrawCtrl:InitHeroEffectInfo(effectId)
	uiDrawCtrl:StartPlay()
end

function UISagaComment:CreateCommentList(list)
	self:ShowCommentTap(self._commentTapType)

	list = list or {}
	local uiCommentList = self._uiCommentList
	if uiCommentList then
		local refreshType = self._refreshType
		local uiList = uiCommentList:GetList()
		if refreshType == UISagaComment.REFRESH_LIST_TYPE_1 then
			-- 正常刷新
			uiCommentList:RefreshData(list)
			uiList:RefreshSilent()
		elseif refreshType == UISagaComment.REFRESH_LIST_TYPE_2 then
			-- 评论点赞刷新
			--uiCommentList:RefreshList(list,false)
			--uiList:RefreshList(UIListWrap.RefreshMode.Solid)
			uiCommentList:RefreshData(list)
		elseif refreshType == UISagaComment.REFRESH_LIST_TYPE_3 then
			-- 发送评论刷新
			uiCommentList:RefreshList(list,false)
			uiList:RefreshList(UIListWrap.RefreshMode.Solid)
		end
		self._refreshType = UISagaComment.REFRESH_LIST_TYPE_1
	else
		uiCommentList = self:GetUIScroll("uiCommentList")
		self._uiCommentList = uiCommentList
		uiCommentList:Create(self.mCommontList,list,function(...) self:OnDrawCommentCell(...) end,UIItemList.WRAP)
	end
	local showEmpty = #list <= 0 or false
	CS.ShowObject(self.mNoRecord,showEmpty)
end

function UISagaComment:OnHeroCommentForLoveResp(pb)
	if self._commentTapType ~= UISagaComment.PLAYER_COMMENT then return end

	local heroRefId = pb.heroRefId
	if self._refId ~= heroRefId then return end
	local commentId = pb.commentId
	local dataList = self._dataList
	if not dataList then
		dataList = {}
		self._dataList = dataList
	end
	for i,v in ipairs(dataList) do
		if v.id == commentId then
			dataList[i].like = v.like + 1
			dataList[i].isLike = true
			dataList[i].createEff = true
		end
	end
	local uiCommentList = self._uiCommentList
	if uiCommentList then
		uiCommentList:RefreshData(dataList)
	end
end

function UISagaComment:RefreshBtnStatus()
	local commentTapType = self._commentTapType
	local isProfile = commentTapType == UISagaComment.TALENT_PROFILE
	local profileStatus = isProfile and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnCommend1,profileStatus)
	local isComment = commentTapType == UISagaComment.PLAYER_COMMENT
	local commentStatus = isComment and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(self.mBtnCommend2,commentStatus)
end

function UISagaComment:PlayEffShow()

	if true then return end
	if self._playerAni then return end
	self._playerAni = true
	local seqTween
	self:TweenSeqKill(self._effectKey)
	local canvasRect = LGameUI.GetUICanvasRoot()
	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mLoveNumTxt)
	self.mUpTxt.localPosition = targetPos - Vector3.New(0,0,0)
	local pos = self.mUpTxt.localPosition
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
			local alphaTime = 0.8
			local Ease = DG.Tweening.Ease.OutCubic

			CS.ShowObject(self.mUpTxt,true)

			local newCanvasGroup = self.mUpTxt:GetComponent(typeofCanvasGroup)
			if newCanvasGroup then
				local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
					newCanvasGroup.alpha = ival
				end):SetEase(Ease)

				local tween = self.mUpTxt:DOLocalMoveY(pos.y + 40, alphaTime)
				seq:Append(_temp)
				seq:Join(tween)
			end

			seq:AppendInterval(0.1)

			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self._playerAni = false
		self.mUpTxt.localPosition = pos
		self:TweenSeqKill(self._effectKey)
		CS.ShowObject(self.mUpTxt,false)
	end)
end

function UISagaComment:InitData()
	self._refId = self:GetWndArg("refId")
	self._dataList = {}
	self._dataKeyList = {}

	local commentTapType = self:GetWndArg("commentTapType") or UISagaComment.TALENT_PROFILE

	local isOpen = gModelFunctionOpen:CheckIsOpened(10303004)
	CS.ShowObject(self.mBtnCommend1,isOpen)
	if not isOpen then
		commentTapType = UISagaComment.PLAYER_COMMENT
	end
	self._commentTapType = commentTapType

	self:InitCommentData()
end

function UISagaComment:OnInputDes(str)
	local len = LxUtf8.cnLen(str)
	local maxLen = gModelHero:GeConfigByKey("heroBookMesLong")
	maxLen = maxLen * 2
	if(len > maxLen)then
		str = self._oldStr
		--self.mCommentText.text = str
		self:SetWndTextInput(self.mCommentText, str)
		len = LxUtf8.cnLen(str)
		GF.ShowMessage(ccClientText(17603))
	else
		self._oldStr = str
	end
	--激活聊天框不选中所有内容
	self.mCommentText.onFocusSelectAll = false
end

function UISagaComment:OnDrawCommentCell(list,item,itemdata,itempos)
	local HeroTrans = self:FindWndTrans(item,"HeroTrans")
	local HeadIconTrans = self:FindWndTrans(HeroTrans,"HeadIcon")
	local Div = self:FindWndTrans(item,"Div")
	local Div2 = self:FindWndTrans(Div,"Div2")
	local Name = self:FindWndTrans(Div,"NameAndTime/Name")
	local Msg = self:FindWndTrans(Div2,"Msg")
	local TimeTrans = self:FindWndTrans(Div,"NameAndTime/Time")
	local DZBtn = self:FindWndTrans(Div2,"DZDiv/DZBtn")
	local Huo = self:FindWndTrans(HeroTrans,"Huo")
	local InstanceID = item:GetInstanceID()

	local createEff = itemdata.createEff
	if not createEff then
		self:DestroyWndEffectByKey(InstanceID)
	end

	local id = itemdata.id
	local lookPlayer = true

	local serverName = itemdata.serverName
	if string.isempty(serverName) then
		serverName = gModelFriend:GetSevenName(itemdata.serverId)
	end
	if string.isempty(serverName) then
		lookPlayer = false
		serverName = ccClientText(19764)
	end
	local str = string.replace(ccClientText(19729),serverName,itemdata.playerName)
	self:SetWndText(Name,str)

	local playerId = itemdata.playerId
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
	local playerInfo = {
		trans = HeadIconTrans,
		playerId = playerId,
		icon = itemdata.playerHead,
		headFrame = itemdata.hearFrame,
		bDefaultSortNum = 30
	}
	baseClass:SetHeadData(playerInfo)
	self:SetWndClick(HeadIconTrans,function()
		if lookPlayer then
			gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.HERO_DISCUSS)
		end
	end)

	local msg = LUtil.FilterEmoji(itemdata.text,"?")
	msg = LWordMaskUtil.ClearShieldWord(msg,false,nil,true)
	msg = LUtil.ChatInfoFaceBinToDec(msg)
	--local msg = gModelHeroBook:DisposeText(itemdata.text)
	msg= LUtil.GetFaceStr(msg,46)
	self:SetWndText(Msg,msg)

	local timeStr = LUtil.FormatTimeStr(itemdata.createTime,UISagaComment.CREATETIME_FORMAT)
	self:SetWndText(TimeTrans,timeStr)

	local isLike = itemdata.isLike
	local NoHand = self:FindWndTrans(DZBtn,"NoHand")
	local Hand = self:FindWndTrans(DZBtn,"Hand")
	local DZNum = self:FindWndTrans(DZBtn,"DZNum")
	CS.ShowObject(NoHand,isLike)
	CS.ShowObject(Hand,not isLike)

	local likeStr = itemdata.like
	self:SetWndText(DZNum,likeStr)

	self:SetWndClick(DZBtn,function()
		self:OnClickHeroCommentDZBtnFunc(InstanceID,itemdata,DZBtn)
	end)

	local show = itemdata.index <= self._heroBookHotNum and itemdata.like ~= 0
	CS.ShowObject(Huo,show)

	if itemdata.isNet and itemdata.index == self._oldIndex then
		self:NewPage()
	end
end

function UISagaComment:SendLove()
	--self:PlayEffShow()
	self:CreateWndEffect(self.mLoveBtn,"fx_ui_xihuan","fx_ui_xihuan",100,nil,nil,30)
	local heroRefId = self._refId
	if not heroRefId then return end
	gModelHeroBook:OnHeroForLoveReq(heroRefId)
	self._sendLoveEvent = true
end
function UISagaComment:RefreshVersionShow()
	if self._isVie then
		self:SetAnchorPos(self.mBtnCommend1,Vector2.New(-140,-21.7))
		self:SetAnchorPos(self.mBtnCommend2,Vector2.New(140,-21.7))

		local imgTran = CS.FindTrans(self.mBtnCommend1,"Off")
		LxUiHelper.SetSizeWithCurAnchor(imgTran,0,300)
		imgTran = CS.FindTrans(self.mBtnCommend1,"On")
		LxUiHelper.SetSizeWithCurAnchor(imgTran,0,300)
		imgTran = CS.FindTrans(self.mBtnCommend1,"Gray")
		LxUiHelper.SetSizeWithCurAnchor(imgTran,0,300)

		imgTran = CS.FindTrans(self.mBtnCommend2,"Off")
		LxUiHelper.SetSizeWithCurAnchor(imgTran,0,300)
		imgTran = CS.FindTrans(self.mBtnCommend2,"On")
		LxUiHelper.SetSizeWithCurAnchor(imgTran,0,300)
		imgTran = CS.FindTrans(self.mBtnCommend2,"Gray")
		LxUiHelper.SetSizeWithCurAnchor(imgTran,0,300)
	end

	CS.ShowObject(self.mBarrageBtn,gModelHeroBook:CheckIsCanGetBarrageStatus())
end

function UISagaComment:InitCommentData()
	local oneRepCommentNum = gModelHero:GeConfigByKey("OneRepCommentNum")
	if not oneRepCommentNum then
		printInfoNR("请在HeroConfigRef里配置每次请求的评论条数，字段名OneRepCommentNum，若无配置，默认"..ModelHeroBook.SEND_REP_NUM)
		oneRepCommentNum = ModelHeroBook.SEND_REP_NUM
	end
	self._oneRepCommentNum = oneRepCommentNum
	local heroBookHotNum = gModelHero:GeConfigByKey("heroBookHotNum")
	self._heroBookHotNum = heroBookHotNum or 1
	self._oldIndex = 0
	self._refreshType = UISagaComment.REFRESH_LIST_TYPE_1

	local heroBookSendCd = gModelHero:GeConfigByKey("heroBookSendCd")
	self._heroBookSendCd = heroBookSendCd

	self._showBarrage = gModelHeroBook:GetBarrageStatus()
	CS.ShowObject(self.mBarrageMask,not self._showBarrage)
	if self._showBarrage then
		FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
			heroRefId = self._refId,
			barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
		})
	else
		FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
	end
	self._heroCommentSelfMax = gModelHero:GeConfigByKey("heroCommentSelfMax")
	local haveCommentNum = gModelHeroBook:GetCommentNumByHTypeAndHeroRefId(ModelHeroBook.HEROTJ_IDX,self._refId)
	if haveCommentNum then
		self._isMax = self._heroCommentSelfMax <= haveCommentNum
	end
end

function UISagaComment:SetCommentBtnTxt(times)
	local timeStr = string.replace(ccClientText(20119),times)
	self:SetWndButtonText(self.mSendMsgBtn,timeStr)
end

function UISagaComment:CreateTimer()
	LxTimer.LoopTimeStop(self._timer)
	self._timer = nil
	local heroBookSendCd = self._heroBookSendCd
	self:SetCommentBtnTxt(heroBookSendCd)
	self:SetWndButtonGray(self.mSendMsgBtn,true)
	self._timer = LxTimer.LoopTimeCall(function()
		if heroBookSendCd <= 0 then
			self._countDownTime = 0
			self:SetWndButtonText(self.mSendMsgBtn,ccClientText(19737))
			LxTimer.LoopTimeStop(self._timer)
			self:SetWndButtonGray(self.mSendMsgBtn,false)
			return
		else
			heroBookSendCd = heroBookSendCd - 1
			self:SetCommentBtnTxt(heroBookSendCd)
		end
		self._countDownTime = heroBookSendCd
	end, 1, false, -1)
end

--- 刷新达人简评
function UISagaComment:RefreshProfileView()
	local heroRefId = self._refId
	if not heroRefId then return end
	gModelHeroBook:OnHeroSysCommentInfoReq(heroRefId)
end

function UISagaComment:OnHeroCommentListResp(pb)
	if self._commentTapType ~= UISagaComment.PLAYER_COMMENT then return end

	local openType = pb.openType
	if openType == ModelHeroBook.TYPE_BARRAGE then return end
	local heroRefId = pb.heroRefId
	if heroRefId ~= self._refId then return end
	-- 获取评论数据
	self:DisposeCommentPbList(pb)
end

function UISagaComment:ShowCommentTap(tapType)
	local isRobot = tapType == UISagaComment.TALENT_PROFILE

	CS.ShowObject(self.mCommentText, not isRobot)
	CS.ShowObject(self.mFaceBtn, not isRobot)
	CS.ShowObject(self.mSendMsgBtn, not isRobot)

	CS.ShowObject(self.mCommontList, not isRobot)
	CS.ShowObject(self.mCommontList2, isRobot)
end

function UISagaComment:SendMsg()
	local openRefId = gModelHero:GeConfigByKey("heroCommentNeedLv")
	local isCommon = gModelHeroBook:GetCommontFuncOpenStatus(openRefId)
	if not isCommon then return end
	if self._countDownTime and self._countDownTime > 0 then
		local str = string.replace(ccClientText(20118),self._countDownTime)
		GF.ShowMessage(str)
		return
	end
	local msg = self.mCommentText.text
	local len = LxUtf8.cnLen(msg)
	printInfoNR("====== len = "..len)
	local maxLen = gModelHero:GeConfigByKey("heroBookMesLong")
	maxLen = maxLen * 2
	if(len > maxLen)then
		GF.ShowMessage(ccClientText(17603))
		--self.mCommentText.text = LxUtf8.sub(msg,1,len)
		self:SetWndTextInput(self.mCommentText, LxUtf8.sub(msg,1,len))
		return
	elseif(msg == "")then
		GF.ShowMessage(ccClientText(19760))
		return
	end
	local refId = self._refId
	if not refId then return end
	local func = function()
		gModelHeroBook:OnHeroForCommentReq(refId,msg)
	end
	if self._isMax then
		local name = gModelHero:GetHeroNameByRefId(refId)
		local heroCommentSelfMax = gModelHero:GeConfigByKey("heroCommentSelfMax")
		gModelGeneral:OpenUIOrdinTips({refId = 10013,func = func,para = {name,heroCommentSelfMax}},true)
	else
		if func then func() end
	end
end

function UISagaComment:NewPage()
	local refId = self._refId
	if not refId then return end
	local oldIndex = self._oldIndex or 0
	if oldIndex ~= 0 then
		oldIndex = oldIndex + 1
	end
	local repNum = self._oneRepCommentNum - 1
	local newIndex = oldIndex + repNum
	printInfoNR("oldIndex = " .. oldIndex ..", newIndex = " .. newIndex)
	gModelHeroBook:OnHeroCommentListReq(refId,oldIndex,newIndex)
end

function UISagaComment:OnDrawFaceCell(list,item,itemdata,itempos)
	local imageTran = CS.FindTrans(item,"Image")
	self:SetWndEasyImage(imageTran,itemdata.faceIcon)
	self:SetWndClick(item, function(...) self:OnClickFace(itemdata.faceinstead) end)
end

function UISagaComment:CreateStarList(star)
	local list = {}
	for i = 1,star do
		table.insert(list,{show = true})
	end
	local uiStarList = self._uiStarList
	if uiStarList then
		uiStarList:RefreshList(list)
	else
		uiStarList = self:GetUIScroll("uiStarList")
		self._uiStarList = uiStarList
		uiStarList:Create(self.mStarList,list,function(...) self:OnDrawStarCell(...) end)
	end
end

function UISagaComment:OnClickHeroSpine(heroObj)
	if self._curUIHeroObj == nil then return end
	if self._curUIHeroObj ~= heroObj then return end
	local spine = self._curUIHeroObj:GetDpObject()
	if not spine then return end
	local nowPlayAniName = spine:GetCurTrackEntryName()
	if nowPlayAniName == nil or nowPlayAniName == "idle" then
		local panelPlayEff = heroObj:RandomOneSkill()
		if not panelPlayEff then
			heroObj:PlayAttackAni()
			return
		end
		local skillCtr = self._uiSkillCtrl
		if skillCtr then
			skillCtr:Destroy()
			skillCtr = nil
		end
		skillCtr = LUISkillCtrl:New(self)
		self._uiSkillCtrl = skillCtr
		--skillCtr:InitData(heroObj, panelPlayEff, self.mHeroEffPos, 0, 6, 100)
		--skillCtr:PreLoadPlaySkill()
	end
end

function UISagaComment:OnHeroSysCommentInfoResp(pb)
	if self._commentTapType ~= UISagaComment.TALENT_PROFILE then return end

	local isEmpty = false
	local oldSysCommentInfoList = self._oldSysCommentInfoList
	if not oldSysCommentInfoList then
		isEmpty = true
		oldSysCommentInfoList = {}
		self._oldSysCommentInfoList = oldSysCommentInfoList
	end

	local refId,myLike
	local list = {}
	local sysCommentInfo = pb.sysCommentInfo
	for i,v in ipairs(sysCommentInfo) do
		local showEff = false
		local heroSysCommentInfo = gModelHeroBook:GetGeneralHeroSysCommentInfoFromPb(v)
		refId = heroSysCommentInfo.refId
		myLike = heroSysCommentInfo.myLike
		if isEmpty then
			oldSysCommentInfoList[refId] = myLike
		else
			if oldSysCommentInfoList[refId] ~= myLike then
				showEff = true
			end
			oldSysCommentInfoList[refId] = myLike
		end
		table.insert(list,{
			serverData = heroSysCommentInfo,
			showEff = showEff
		})
	end
	self:CreateRobotCommentList(list)
end

function UISagaComment:ShowRaecKeZhiInfo()
	local canvasRect = LGameUI.GetUICanvasRoot()
	if not self._changePos then
		local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,self.mTypeImgBg)
		self.mTypeImgBg.localPosition = targetPos - Vector3.New(0,50,0)
		self._changePos = true
	end
	local refId = self._refId
	local raceType = gModelHero:GetHeroType(refId)
	if raceType then
		local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
		if raceRef then
			local restrainDetailsEff = raceRef.restrainDetailsEff
			local isEmpty = string.isempty(restrainDetailsEff)
			local str = ""
			if not isEmpty then
				local heroRaceImage = raceRef.heroRaceImage
				self:SetWndEasyImage(self.mTypeKeZhiImg,heroRaceImage,function()
					CS.ShowObject(self.mTypeKeZhiImg,true)
				end,true)
			else
				CS.ShowObject(self.mTypeKeZhiImg,not isEmpty)
				str = ccClientText(31233)
			end
			CS.ShowObject(self.mTypeKZImgDiv,not isEmpty)
			CS.ShowObject(self.mNoHaveKeZhiTxtDiv,isEmpty)

			local name = string.replace(ccClientText(10079),ccLngText(raceRef.name))
			self:SetWndText(self.mRaceTypeName,name)

			self:SetWndText(self.mNoHaveKeZhiTxt,str)
		end
	end
end

function UISagaComment:RefreshHeroShow()
	local refId = self._refId
	if not refId then return end
	local heroRef = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local raceType = heroRef.raceType
	local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
	if not raceRef then return end
	local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
	if qualityRef then
	end
	local qualityIcon = heroRef.qualityIcon
	self:SetWndEasyImage(self.mHeroZZImg,qualityIcon,function() CS.ShowObject(self.mHeroZZImg,true) end)
	local heroBg = raceRef.heroBg
	self:SetWndEasyImage(self.mHeroBg,heroBg,function() CS.ShowObject(self.mHeroBg,true) end)
	local icon = raceRef.icon
	self:SetWndEasyImage(self.mHeroRaceImg,icon,function() CS.ShowObject(self.mHeroRaceImg,true) end)
	local initStar = heroRef.initStar
	self:CreateStarList(initStar)
	local heroName = gModelHero:GetHeroNameByRefId(refId,initStar)
	self:SetWndText(self.mHeroName,heroName)

	local effRef = gModelHero:GetHeroEffectRef(refId)
	local nickName = ccLngText(effRef.nickName)
	self:SetWndText(self.mNickName, nickName)
	self:SetXUITextTransColor(self.mNickName, qualityRef.nameColor)


	local quality = gModelHero:GetHeroQualityByRefId(refId,initStar)
	qualityRef = gModelItem:GetQualityRef(quality)
	if not qualityRef then return end
	local heroMsgNameBg = qualityRef.heroMsgNameBg
	--self:SetWndEasyImage(self.mHeroQuaImg,heroMsgNameBg,function() CS.ShowObject(self.mHeroQuaImg,true) end)
	self:CreateSpineAndLiHui()
end

function UISagaComment:ShowBarrageMask()
	self._showBarrage = not self._showBarrage
	--self:SendBarrageEventFunc(true)
	gModelHeroBook:SetBarrageStatus(self._showBarrage)
	if self._showBarrage then
		FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
			heroRefId = self._refId,
			barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT
		})
	else
		FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS,false)
	end
	CS.ShowObject(self.mBarrageMask,not self._showBarrage)
	CS.ShowObject(self.mBarrage, self._showBarrage)
end

function UISagaComment:StartHeroObjRunTimer()
	if self:IsTimerExist(self._loopHeroObjTimerKey) then return end
	self:TimerStart(self._loopHeroObjTimerKey,0, false, -1)
end

function UISagaComment:CreateRobotCommentBtn(profileType,itemdata,btnTrans)
	local DZBtnTrans = self:FindWndTrans(btnTrans,"DZBtn")
	local HandTrans = self:FindWndTrans(DZBtnTrans,"Hand")
	local NoHandTrans = self:FindWndTrans(DZBtnTrans,"NoHand")
	local DZNumTrans = self:FindWndTrans(DZBtnTrans,"DZNum")

	local myLike = itemdata.myLike
	local isLike = profileType == ModelHeroBook.PROFILE_LIKE

	local showHand = true
	local showNoHand = false
	if myLike ~= ModelHeroBook.PROFILE_NORNAL and myLike == profileType then
		showNoHand = myLike == profileType
		showHand = not showHand
	end
	CS.ShowObject(HandTrans,showHand)
	CS.ShowObject(NoHandTrans,showNoHand)

	local showNum = isLike and itemdata.allLike or itemdata.allNoLike
	self:SetWndText(DZNumTrans,showNum)

	self:SetWndClick(DZBtnTrans,function()
		self._onClickSysRefId = itemdata.refId
--[[		if EffRootTrans and InstanceID then
			local effectTrans = self:FindWndEffectByKey(InstanceID)
			if effectTrans then
				local dpTrans = effectTrans:GetDisplayTrans()
				dpTrans.gameObject:SetActive(false)
				dpTrans.gameObject:SetActive(true)
			else
				self:CreateWndEffect(EffRootTrans, "fx_ui_dianzan", InstanceID, 100, false, false, 30,
						nil, nil, nil, nil,function(dpTrans)
							if dpTrans then
								LogError("============")
								dpTrans.gameObject:SetActive(true)
								local numTxt = self:FindWndTrans(dpTrans,"zan/1")
								CS.ShowObject(numTxt,true)
								CS.ShowObject(EffRootTrans,true)
							end
						end)
			end
		end]]
		gModelHeroBook:OnHeroSysCommentLikeReq(itemdata.refId,profileType)
		if showNoHand then
			GF.ShowMessage(ccClientText(19766))
		else

			GF.ShowMessage(ccClientText(19765))
		end
	end)
end

function UISagaComment:ShowFaceDiv(show)
	CS.ShowObject(self.mFaceMask,show)
	if show then
		self:InitFaceList()
	end
end

function UISagaComment:InitFaceBtnShow()
	CS.ShowObject(self.mFaceBtn, not gLGameLanguage:IsUSARegion())
end

function UISagaComment:RefrehFuncBtnShow()
	local funcId = 10303001
	local isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
	self:SetWndButtonGray(self.mSendMsgBtn,not isOpen)
end

function UISagaComment:InitText()
	self:SetWndText(self.mBarrageBtnTxt,ccClientText(19736))
	self:SetWndButtonText(self.mSendMsgBtn,ccClientText(19737))
	--self:SetWndText(self.mCommentText.placeholder,ccClientText(19749))
	self:SetWndTextInput(self.mCommentText, nil, ccClientText(19749))
	self:SetWndText(self.mKeZhiGuanXiTxt,ccClientText(10080))
	self:SetWndTabText(self.mBtnCommend1,ccClientText(17424))
	self:SetWndTabText(self.mBtnCommend2,ccClientText(17425))

	self:SetWndText(self.mTxtClose,ccClientText(30205))
end

function UISagaComment:CreateSpineAndLiHui()
	local refId = self._refId
	if not refId then return end

	local needCheck = true
	local heroEffRef = gModelHero:GetHeroShowRefByRefId(refId)
	local id = self:GetWndArg("id")
	if id then
		local tempEffRef = gModelHero:GetHeroEffectRefById(id)
		if tempEffRef then
			heroEffRef = tempEffRef
			needCheck = false
		end
	end

	if not heroEffRef then return end

	local effectId = heroEffRef.refId
	--if needCheck then
	--	local serList = gModelHero:GetServerHeroListByRefId(refId)
	--	if serList and #serList > 0 then
	--		local recordSkinList = {}
	--		local recordSkinMap = {}
	--		for i,v in ipairs(serList) do
	--			local skin = v.skin
	--			if skin and skin > 0 and not recordSkinMap[skin] then
	--				recordSkinMap[skin] = true
	--				table.insert(recordSkinList,skin)
	--			end
	--		end
	--		if #recordSkinList > 0 then
	--			table.sort(recordSkinList,function(a, b) return a > b end)
	--			effectId = recordSkinList[1]
	--			heroEffRef = gModelHero:GetShowEffectById(effectId)
	--		end
	--	end
	--end

	local prefabName = heroEffRef.prefabName
	local heroDrawing = heroEffRef.heroDrawing

	local x,y = gModelHeroBook:GetHeroPosByRefIdAndType(effectId,"heroDrawingPos1")
	if x and y then
		self.mHeroLiHuiPos.anchoredPosition = Vector3.New(x,y,0)
		self.mHeroLiHuiEffPos.anchoredPosition = Vector3.New(x,y,0)
	end

	self:CreateSpine(prefabName)
	self:CreateLiHui(effectId,heroDrawing)
end

function UISagaComment:InitFaceList()
	--弹幕只有小表情
	local list = gModelChat:GetEmojiByType(1)
	local uiFaceList = self._uiFaceList
	if uiFaceList then
		uiFaceList:RefreshData(list)
	else
		uiFaceList = self:GetUIScroll("uiFaceList")
		self._uiFaceList = uiFaceList
		uiFaceList:Create(self.mFaceScroll,list,function(...) self:OnDrawFaceCell(...) end,UIItemList.WRAP)
	end
end
function UISagaComment:InitEmptyList()
	local data = {
		refId = 10002,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UISagaComment:GetNewPage(refreshType)
	self._dataList = {}
	self._dataKeyList = {}
	self._oldIndex = 0
	refreshType = refreshType or UISagaComment.REFRESH_LIST_TYPE_1
	self._refreshType = refreshType
	self:NewPage()
end

function UISagaComment:CreateRobotCommentList(list)
	self:ShowCommentTap(self._commentTapType)

	local uiRobotCommentList = self._uiRobotCommentList
	if uiRobotCommentList then
		uiRobotCommentList:RefreshList(list)
		uiRobotCommentList:DrawAllItems(false)
	else
		uiRobotCommentList = self:GetUIScroll("_uiRobotCommentList")
		self._uiRobotCommentList = uiRobotCommentList
		uiRobotCommentList:Create(self.mCommontList2,list,function(...) self:OnDrawRobotCommentCell(...) end,UIItemList.SUPER)
	end
	local showEmpty = #list <= 0 or false
	CS.ShowObject(self.mNoRecord,showEmpty)
end

function UISagaComment:OnTimer(key)
	if key == self._loopHeroObjTimerKey then
		local time = Time.unscaledTime
		if self._curUIHeroObj then
			self._curUIHeroObj:OnRun(time)
		end
		if self._uiSkillCtrl then
			self._uiSkillCtrl:OnRun(time)
		end
	end
end

function UISagaComment:OnHeroForCommentResp(pb)
	if self._commentTapType ~= UISagaComment.PLAYER_COMMENT then return end

	self:CreateTimer()
	--self.mCommentText.text = ""
	self:SetWndTextInput(self.mCommentText, "")
	-- 英雄评论
	self:GetNewPage(UISagaComment.REFRESH_LIST_TYPE_3)
end

function UISagaComment:CreateSpine(prefabName)
	local refId = self._refId
	if not refId then return end
	local heroRef = gModelHero:GetHeroRef(refId)
	if not heroRef then return end
	local initStar = heroRef.initStar
	local uiSpineObj = LUIHeroObject:New(self)
	self._curUIHeroObj = uiSpineObj
	--uiSpineObj:Create(self.mHeroSpinePos,prefabName,prefabName)
	--uiSpineObj:SetScale(1)
	--uiSpineObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
	--uiSpineObj:SetHeroData(nil,refId,initStar,nil,true)
	--uiSpineObj:ShowHero(true)
	--uiSpineObj:StartLoad()
	--self:StartHeroObjRunTimer()
end

function UISagaComment:SendBarrageEventFunc(sendStatus)
	if self._showBarrage then
		FireEvent(EventNames.SEND_COMMON_BARRAGE_LIST,self._dataList,false)
	end
	if sendStatus then
		FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS,self._showBarrage)
	end
end

function UISagaComment:DisposeCommentPbList(pb)
	local dataList = self._dataList
	if not dataList then
		dataList = {}
		self._dataList = dataList
	end
	local dataKeyList = self._dataKeyList
	if not dataKeyList then
		dataKeyList = {}
		self._dataKeyList = dataKeyList
	end
	local comments = pb.comments
	for i,v in ipairs(comments) do
		local commentData = gModelHeroBook:GetGeneralHeroCommentInfoFromPb(v)
		local id = commentData.id
		if not dataKeyList[id] then
			dataKeyList[id] = id
			table.insert(dataList,commentData)
		end
	end
	local len = #dataList
	local oldIndex = self._oldIndex
	for i,v in ipairs(dataList) do
		local isNet = len == i and oldIndex ~= len
		v.isNet = isNet
		v.index = i
		v.createEff = false
	end
--[[	local oneRepCommentNum = self._oneRepCommentNum - 1
	local num = len % oneRepCommentNum
	if num == 0 then
		self._oldIndex = len
	else
		self._oldIndex = len - num
	end]]
	local numEnd = pb.numEnd
	self._oldIndex = numEnd

	--self:SendBarrageEventFunc()

	self:CreateCommentList(dataList)
end

function UISagaComment:OnDrawRobotCommentCell(list,item,itemdata,itempos)
	local Div2Trans = self:FindWndTrans(item,"Div2")
	local DivTrans = self:FindWndTrans(Div2Trans,"Div")
	local NameAndTimeTrans = self:FindWndTrans(DivTrans,"NameAndTime")
	local NameTrans = self:FindWndTrans(NameAndTimeTrans,"Name")
	local TimeTrans = self:FindWndTrans(NameAndTimeTrans,"Time")
	local MsgTrans = self:FindWndTrans(DivTrans,"Msg")

	local DZDivTrans = self:FindWndTrans(Div2Trans,"DZDiv")
	local CAIDivTrans = self:FindWndTrans(Div2Trans,"CAIDiv")

	local serverData = itemdata.serverData

	local refId = serverData.refId
	local ref = gModelHeroBook:GetHeroCommentRefByRefId(refId)

	local name = ref and ccLngText(ref.criticName)
	if string.isempty(name) then
		name = serverData.name
	end
	self:SetWndText(NameTrans,name)

	local commentTxt = ref and ccLngText(ref.commentTxt)
	local msg = LUtil.FilterEmoji(commentTxt,"?")
	msg = LWordMaskUtil.ClearShieldWord(msg,false,nil,true)
	msg = LUtil.ChatInfoFaceBinToDec(msg)
	msg = LUtil.GetFaceStr(msg,46)
	self:SetWndText(MsgTrans,msg)

	local EffRootTrans = self:FindWndTrans(DZDivTrans,"DZBtn/NoHand/EffRoot")
	if EffRootTrans then
		local InstanceID = EffRootTrans:GetInstanceID()
		if self._onClickSysRefId then
			if self._onClickSysRefId == serverData.refId then
				local showEff = itemdata.showEff
				local effectTrans = self:FindWndEffectByKey(InstanceID)
				if effectTrans then
					local dpTrans = effectTrans:GetDisplayTrans()
					dpTrans.gameObject:SetActive(false)
					local numTxt = self:FindWndTrans(dpTrans,"zan/1")
					CS.ShowObject(numTxt,showEff)
					dpTrans.gameObject:SetActive(true)
					CS.ShowObject(EffRootTrans,true)
				else
					self:CreateWndEffect(EffRootTrans, "fx_ui_dianzan", InstanceID, 100, false, false, 30,
							function(dpTrans)
								if dpTrans then
									dpTrans.gameObject:SetActive(true)
									local numTxt = self:FindWndTrans(dpTrans,"zan/1")
									CS.ShowObject(numTxt,showEff)
									CS.ShowObject(EffRootTrans,true)
								end
							end)
				end
			else
				CS.ShowObject(EffRootTrans,false)
			end
		else
			CS.ShowObject(EffRootTrans,false)
		end
	end


	self:CreateRobotCommentBtn(ModelHeroBook.PROFILE_LIKE,serverData,DZDivTrans)
	self:CreateRobotCommentBtn(ModelHeroBook.PROFILE_TREAD,serverData,CAIDivTrans)
end

function UISagaComment:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	--返回按钮
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSendMsgBtn,function() self:SendMsg() end)
	self:SetWndClick(self.mFaceBtn,function() self:ShowFaceDiv(true) end)
	self:SetWndClick(self.mFaceMask,function() self:ShowFaceDiv(false) end)
	self:SetWndClick(self.mLoveBtn,function() self:SendLove() end)
	self:SetWndClick(self.mBarrageBtn,function() self:ShowBarrageMask() end)
	--self:SetWndClick(self.mLiHuiClick,function()
	--	GF.OpenWndUp("UISagaLiHuiSow",{selSkinRefId = self._refId})
	--end)
	self:SetWndClick(self.mHeroRaceImg,function()
		CS.ShowObject(self.mTypeImgMask,true)
		self:ShowRaecKeZhiInfo()
	end)
	self:SetWndClick(self.mTypeImgMask,function() CS.ShowObject(self.mTypeImgMask,false) end)
	self:SetWndClick(self.mHeroZZImg,function() GF.OpenWndTop("UISagaQualitySow") end)


	self:SetWndClick(self.mBtnCommend1,function()
		self._commentTapType = UISagaComment.TALENT_PROFILE
		self:RefreshView()
	end)
	self:SetWndClick(self.mBtnCommend2,function()
		self._commentTapType = UISagaComment.PLAYER_COMMENT
		self:RefreshView()
	end)
end

function UISagaComment:OnClickHeroCommentDZBtnFunc(InstanceID,itemdata,DZBtn)
	local isLike = itemdata.isLike
	local createEff = itemdata.createEff
	local id = itemdata.id
	local effectTrans = self:FindWndEffectByKey(InstanceID)
	if effectTrans then
		local dpTrans = effectTrans:GetDisplayTrans()
		dpTrans.gameObject:SetActive(false)
		local numTxt = self:FindWndTrans(dpTrans,"zan/1")
		if not createEff then
			CS.ShowObject(numTxt,not isLike)
		else
			CS.ShowObject(numTxt,false)
		end
		dpTrans.gameObject:SetActive(true)
	else
		self:CreateWndEffect(DZBtn, "fx_ui_dianzan", InstanceID, 100, false, false, 30,
				nil, nil, nil, nil,function(dpTrans)
					local numTxt = self:FindWndTrans(dpTrans,"zan/1")
					if not createEff then
						CS.ShowObject(numTxt,not isLike)
					else
						CS.ShowObject(numTxt,false)
					end
				end)
	end
	gModelHeroBook:OnHeroCommentForLoveReq(self._refId,id)
end

function UISagaComment:OnCommentNumResp(pb)
	local haveCommentNum = gModelHeroBook:GetCommentNumByHTypeAndHeroRefId(ModelHeroBook.HEROTJ_IDX,self._refId)
	if haveCommentNum then
		self._isMax = self._heroCommentSelfMax <= haveCommentNum
	end
end

function UISagaComment:RefreshLoveInfoView(serverData)
	local love = serverData.love
	local allLoveNum = LUtil.NumberCoversion(serverData.allLoveNum)
	self:SetWndText(self.mLoveNumTxt,allLoveNum)
	CS.ShowObject(self.mLoveImg, love)
	CS.ShowObject(self.mNoLoveImg,not love)
	local textId = love and 19732 or 19734
	self:SetWndText(self.mLoveBtnTxt,ccClientText(textId))
	if self._sendLoveEvent then self:PlayEffShow() end
end

--- 刷新玩家评论
function UISagaComment:RefreshCommentView()
	self:NewPage()
end

function UISagaComment:OnDrawStarCell(list,item,itemdata,itempos)
end

------------------------------------------------------------------
return UISagaComment


