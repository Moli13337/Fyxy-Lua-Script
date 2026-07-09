---
--- Created by Administrator.
--- DateTime: 2023/10/27 11:29:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEden:LWnd
local UIEden = LxWndClass("UIEden", LWnd)
local Tweening = DG.Tweening
local EaseInExpo = Tweening.Ease.InExpo
local EaseOutExpo = Tweening.Ease.OutExpo
local EaseInQuad = Tweening.Ease.InQuad
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
local typeUIImage = typeof(UnityEngine.UI.Image)



------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEden:UIEden()
	self._redItemList = {}

	self:SetHideHurdle()
	self:SetHideTop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEden:OnWndClose()
	if LOG_INFO_ENABLED then
		print("function UIEden:OnWndClose()")
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEden:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEden:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:SetPara()
	self:InitData()

	self:InitUIEvent()
	self:InitEvent()
	self:InitBtnList()
	self:ShowLittleBox()


	--gModelBackflow:SetPrivileBtn(self.mBtnPrivile,1,self)

	-- local priviCom = self:GetPrivilegeCom()
	-- priviCom:Create(self.mBtnPrivile,1,self,true)

	gModelWonderland:InitFormation()
	CS.ShowObject(self.mLayerList,false)
	CS.ShowObject(self.mUiRoot,true)
	CS.ShowObject(self.mBoxBg,false)

	local isFromBattle = self:GetWndArg("isFromBattle")
	local inMap = gModelWonderland:IsInMap()
	if inMap and not isFromBattle then
		gModelWonderland:WonderlandHeroOpsReq(0) --刷新英雄数据
	end

	gModelWonderland:WonderlandQuestReq(0)


	self:RefreshRed()
	self:SetContent()
	self:ShowBuffList()
	self:RefreshSettingAutoRunStatus()
end


function UIEden:GetPlayModuleBelong()
	return LPlayModuleConst.WONDERLAND
end

function UIEden:WorldSpriteEvent(data)
	if data.canSelect then
		GF.OpenWnd("UIEdenMonsterPop",{data= data,eventType = ModelWonderland.EVENT_SPRITE,wndType = 5})
	else
		local str =ccClientText(16768) --"请先走到这个平台前"
		GF.ShowMessage(str)
	end
end

function UIEden:GetSettingAutoRunStatus()
	return gModelGameHelperAlleviation:CheckWonderlandIsAutoRun()
end

function UIEden:ShowItemGainEff(grid,eventType)

    local map = GF.GetCurMap()
    if not map or not map:IsSameMap("LWonderlandMap") then
        return
    end
    local gridPos = map:GetGridPos(grid.layerIndex,grid.gridIndex)

    local eventInfo = gModelWonderland:GetEventInfoByType(eventType)
    if not eventInfo then
        return
    end

    local offset = LxDataHelper.ParseVector(eventInfo.resSite,';')
    local startPos = gridPos + Vector3.New(offset.x/100,offset.y/100,0)

	local uiCamera = LGameUI.GetUICamera()
	local sceneCamera = gLGameScene:GetCurrentSceneCamera()
	local screenPos  = sceneCamera:WorldToScreenPoint(startPos)
	local effStartPos =  uiCamera:ScreenToWorldPoint(screenPos)

	local endPos = self.mItemIcon.position

    local root = self.mEffRoot
	self:DestroyWndEffectByKey("eventEff")
	self._effOneOk = false
	self._effTwoOk = false
	local data =
	{
		trans = root,
		effName = eventInfo.res,
		effKey = "eventEff",
		endFunc = function()
			self._effOneOk = true
			self:StartFly(root,effStartPos,endPos,eventType)
		end,
	}
	self:CreateWndEffect_Ex(data)

	local data =
	{
		trans = root,
		effName = "ui_fx_tubiaotuowei",
		effKey = "itemEff",
		endFunc = function()
			self._effTwoOk = true
			self:StartFly(root,effStartPos,endPos,eventType)
		end,
	}


	self:CreateWndEffect_Ex(data)


end

function UIEden:ShowOrganNum(tipsId)
	CS.ShowObject(self.mItemInfo,true)
	self:SetWndEasyImage(self.mItemIcon,"wonderland_map1_icon_8",nil,true)
	local num = gModelWonderland:GetOrganNum()
	local str = string.format("%s/%s",num,3)
	self:SetWndText(self.mItemNum,str)
	--self:SetWndClick(self.mItemInfo,function()
	--	self:ShowItemInfoTip(tipsId)
	--end,LSoundConst.CLICK_ERROR_COMMON)

end

function UIEden:ShowSingTween(eventType,root)
	if eventType ~= ModelWonderland.EVENT_SINGING then
		return
	end

	local isTrigger = gModelWonderland:IsBossTrigger(self._themeId)

	if not isTrigger then
		return
	end

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("fullSingTween")
	local tween = root:DOLocalMove(Vector3.zero,1)
	seq:Append(tween)
	tween = root:DOScale(Vector3.New(1.2,1.2,1.2),1)
	seq:Join(tween)
	seq:AppendCallback(function ()
		self:DestroyWndEffectByKey("eventEff")
		self:CreateWndEffect(self.mEffRoot,"ui_fx_shenhaigesheng","shakeSingEff",100)
	end)
	seq:AppendInterval(5)
	seq:OnComplete(function ()
		self:DestroyWndEffectByKey("shakeSingEff")
	end)
	seq:PlayForward()

	return true
end

function UIEden:RefreshTaskContent(pb)
	local questId = pb.questId
	local status =pb.status

	self._questId = questId
	self._schedule = pb.schedule
	self._status =status

	CS.ShowObject(self.mTaskBg,status ~= 2)

	self:DestroyWndEffectByKey("taskBtn")

	local str = ""
	if status == 0 then
		str =ccClientText(11811) --"进行中"
	elseif status == 1 then
		str =ccClientText(18504) --"领取"
	else
		return
	end

	if status == 1 then
		self:CreateWndEffect(self.mBtnTask,"ui_fx_renwuanniu","taskBtn",100)
	end


	local taskCfg = gModelWonderland:GetTaskConfig(questId)

	local state_0 = self:FindWndTrans(self.mBtnTask,"state_0")
	local state_1 = self:FindWndTrans(self.mBtnTask,"state_1")

	self:SetTextTile(state_0,str)
	self:SetTextTile(state_1,str)


	CS.ShowObject(state_0,status == 0)
	CS.ShowObject(state_1,status == 1)

	local text = ccLngText(taskCfg.text)
	local keyTable = {}
	local themeId = gModelWonderland:GetThemeId()
	local themIdList = {themeId}

	local nameList = {}
	for k,v in ipairs(themIdList) do
		local themeCfg = gModelWonderland:GetThemeConfig(v)
		if themeCfg then
			local name = ccLngText(themeCfg.name)
			table.insert(nameList,name)
		end
	end

	keyTable["a1"] = table.concat(nameList,",")

	local str = string.gsub(text,"#(%w+)#",keyTable)
	self:SetTextTile(self.mTaskBg,str)
end

function UIEden:AnswerEvent(data)
	GF.OpenWnd("UIEdenKey",{data= data})

end

function UIEden:SpringEvent(data)
	local para =
	{
		wndType = 2,
		data = data,
		eventType = ModelWonderland.EVENT_SPRING
	}
	GF.OpenWnd("UIEdenSpring",para)
end

function UIEden:ShowSceneInfo()
	CS.ShowObject(self.mTextBg,false)
	CS.ShowObject(self.mItemInfo,false)
	local themeId = gModelWonderland:GetThemeId()
	local themeType = gModelWonderland:GetThemeType()

	local themeCfg = gModelWonderland:GetThemeConfig(themeId)
	local tipId = themeCfg.tips

	local bubbleRoot = nil
	if themeType == 1 then
		bubbleRoot = self.mTextBg
		self:ShowEvilAwake()
	elseif themeType == 2 then
		bubbleRoot = self.mItemInfo
		local itemId = gModelWonderland:GetBossTriggerCondition(themeId)
		self:ShowItemInfo(itemId)
	elseif themeType == 3 then
		bubbleRoot = self.mItemInfo
		self:ShowOrganNum()
	elseif themeType == 4 then
		bubbleRoot = self.mTextBg
		self:ShowWorldTreeInfo()
	elseif themeType == 5 then
		bubbleRoot = self.mItemInfo
		local itemId = gModelWonderland:GetBossTriggerCondition(themeId)
		self:ShowItemInfo(itemId)
	end

	self:ShowSceneBubble(bubbleRoot,tipId)

	self._curBubbleTran = bubbleRoot

	self:TimerStop(self._delayTweenKey)
	self:TimerStart(self._delayTweenKey,0,false,1)

end

function UIEden:QueenEvent(data)

	GF.OpenWnd("UIEdenMonsterPop",{data= data,eventType = ModelWonderland.EVENT_QUEEN,wndType = 4})
end

function UIEden:ShowWorldTreeInfo()
	CS.ShowObject(self.mTextBg,true)
	local str =ccClientText(16767) --"已使用回合"
	self:SetWndText(self.mSceneEvent,str)
	self:InitTextLineWithLanguage(self.mSceneEvent, -30)
	self:InitTextSizeWithLanguage(self.mSceneEvent, -2)
	local bout = gModelWonderland:GetBout()
	self:SetWndText(self.mEventProgress,bout)


	local eff = "ui_fx_mowangjingxing_green"
	if bout> 10 and bout <= 15 then
		eff = "ui_fx_mowangjingxing_red"
	elseif bout > 15 then
		self:DestroyWndEffectByKey("boutEff")
		return
	end
	if self._oldEff ~= eff then
		self:DestroyWndEffectByKey("boutEff")
	end

	self._oldEff = eff
	self:CreateWndEffect(self.mBgIcon,eff,"boutEff",100)

end


function UIEden:OnTimer(key)
	if key == self._countDownKey then
		self:SetCountDown()
	elseif key == self._delayTweenKey then
		self:TweenBubble()
	end
end

function UIEden:ShowSceneBubble(root,tipsId)
	local themeId = gModelWonderland:GetThemeId()
	local themeCfg = gModelWonderland:GetThemeConfig(themeId)
	local textId = themeCfg.themeTips
	local textCfg = gModelWonderland:GetEventTextConfig(textId)
	local str = ccLngText(textCfg.dec)

	local bubbleTran = self:FindWndTrans(root,"bubble")
	self:SetWndClick(bubbleTran,function()
		self:ShowItemInfoTip(tipsId)

		--local tran = self:FindWndTrans(self.mEffRoot,"icon")
		--self:ShowSingTween(ModelWonderland.EVENT_SINGING,tran)

	end,LSoundConst.CLICK_ERROR_COMMON)
	local textTran = self:FindWndTrans(bubbleTran,"Image/UIText")
	self:SetWndText(textTran,str)

end

function UIEden:SingingEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:RefreshSettingAutoRunStatus()
	local isShowMask = self:GetSettingAutoRunStatus()
	CS.ShowObject(self.mSettingAutoRunMask,isShowMask)

	local aniKey = "autoTipsABCDEFGTween"
	local seqCom = self:GetSeqCom()
	local canvasGroup = self:GetCanvasGroup(self.mAutoRunTxtBg)
	if isShowMask then
		local seq = seqCom:CreateSeq(aniKey)
		canvasGroup.alpha = 0.5
		local tween = canvasGroup:DOFade(1,0.5):SetEase(DG.Tweening.Ease.InSine)
		seq:Append(tween)
		tween = canvasGroup:DOFade(0.5,0.5):SetEase(DG.Tweening.Ease.InSine)
		seq:Append(tween)
		seq:SetLoops(-1)
		seq:PlayForward()
	else
		canvasGroup.alpha = 0
		seqCom:DeleteSeq(aniKey)
	end
end

function UIEden:ClipEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:WorldLeavesEvent(data)
	GF.OpenWnd("UIEdenKey",{data= data,wndType = 4})
end

function UIEden:RevivalEvent(data)
	local para =
	{
		wndType = 1,
		data = data,
		eventType = ModelWonderland.EVENT_REVIVAL
	}
	GF.OpenWnd("UIEdenSpring",para)
end


function UIEden:TweenTreasureBtn()
	if self:IsWndClosed() then
		return
	end
	local duration = 0.2
	local scaleUp = 1.2
	local seqCom = self:GetSeqCom()
	local seq =seqCom:CreateSeq("btnTween")
	--self._treaTweenSeq = seq
	seq:SetAutoKill(true)
	local upTween = self._treasureBtn.transform:DOScale(scaleUp, duration / 2):SetEase(EaseInExpo)
	local normalTween = self._treasureBtn.transform:DOScale(1, duration / 2):SetEase(EaseOutExpo)
	seq:Append(upTween)
	seq:Append(normalTween)
	seq:PlayForward()
end

function UIEden:TimeEvent(data)
	GF.OpenWnd("UIEdenPop",{data = data,wndType = 2})
end


function UIEden:ShowEffect(pb)
	local effectFunc = nil
	for k,v in ipairs(pb.infos) do

		local eventType = v.eventType

		local data =
		{
			eventType = eventType,
			effectVal = v.effectVal,
		}

		gModelWonderland:OnReceiveEffect(data)

		effectFunc = self._effectFuncList[eventType]

	end

	if effectFunc then
		local wnd = GF.FindFirstWndByName("UIOrdinResult")
		if wnd then
			self._delayFunc = effectFunc
			return
		end

		effectFunc()
	end


end

function UIEden:ShowBoxEff()

	local showEndBox = gModelWonderland:CheckShowEndBox()
	if not showEndBox then
		return
	end

	CS.ShowObject(self.mBoxBg,true)
	local key = "boxEffKey"
	self:DestroyWndEffectByKey(key)
	self:CreateWndEffect(self.mBoxBg,"fx_qjtx_baoxiang",key,100)

	CS.ShowObject(self.mLittleBox,false)
end

function UIEden:ShowHurtEffect()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("hurt")
	local canvasGroup = self:GetCanvasGroup(self.mHurt)
	local tween = canvasGroup:DOFade(0.4,0.5):SetEase(EaseInQuad)
	seq:Append(tween)
	tween = canvasGroup:DOFade(0,0.5):SetEase(EaseInQuad)
	seq:Append(tween)
	seq:SetLoops(3)
	seq:PlayForward()
end

function UIEden:OnClickShop()
	local isOpen = gModelFunctionOpen:CheckIsOpened(14600011,true)
	if not isOpen then
		return
	end

	gModelFunctionOpen:Jump(14600011)
end

function UIEden:BoxSelectEvent(data)
	GF.OpenWnd("UIEdenSelectPop",{data= data,type = 2})
end

function UIEden:GrandmaEvent(data)
	local state = data.state
	local gridIndex = data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
	end
end


function UIEden:InitData()

	local bubble = self:FindWndTrans(self.mTextBg,"bubble")
	self:GetBubbleDefaultPos(bubble)
	bubble = self:FindWndTrans(self.mItemInfo,"bubble")
	self:GetBubbleDefaultPos(bubble)

	self._wndRecord =
	{
		["UIOrdinResult"] = true,
		["UIEdenTsure"] = true,
		["UIAward"] = true,
        ["UIAutoEdenTsure"] = true,
	}

	self._nameRecord =
	{
		["BtnPrivile"] = true,
		["btnAct"] = true
	}

	self._countDownKey = "_countDownKey"
	--self._delaySetPos = "_delaySetPos"
	--self._roleBeHitKey = "_roleBeHitKey"
	--self._boutEffTimerKey = "_boutEffTimerKey"
	self._delayTweenKey = "_delayTweenKey"


	self._btnDataList=
	{
		[1]= {
			iconPath = "wonderland_icon_btn_1",
			str =ccClientText(16708), --"奇境手册",
			func = function()
				self:OnClickGuideBook() end,
		},
		[2]= {
			iconPath = "wonderland_icon_btn_1",
			str =ccClientText(16772), --"奇境商店",
			func = function()
				self:OnClickShop() end,
		},
		[3]= {
			iconPath = "wonderland_icon_btn_4",
			str =ccClientText(16707), --"奇境魔卡",
			func = function()
				self:OnClickTreasureBag()
			end,
		},
		[4]= {
			iconPath = "timecopy_icon_4",
			str =ccClientText(16766), --"奇境伙伴",
			func = function()
				self:OnClickHeroInfo()
			end,
		},
		[5]= {
			iconPath = "onhook_icon_1",
			str = ccClientText(26207),---"奇境阵容",
			func = function()
				self:OnClickFormation() end,
		},
		[6]= {
			iconPath = "public_btn_icon_17_1",
			str =ccClientText(16770), --"奇境战令",
			activtyType = ModelActivity.MODEL_PASSC,
			func = function()
				self:OnClickPassC()
			end,
		},
	}





	self._evenFuncList =
	{
		[ModelWonderland.EVENT_SPRING] = function(...) self:SpringEvent(...) end, ---泉水
		[ModelWonderland.EVENT_REVIVAL] = function(...) self:RevivalEvent(...) end, ---复活十字架
		[ModelWonderland.EVENT_HIRE] = function(...) self:HireEvent(...)  end, ---雇佣英雄
		[ModelWonderland.EVENT_BOSS] = function(...) self:MonsterEvent(...)  end, ---打怪
		[ModelWonderland.EVENT_TREASURE] = function(...) self:TreasureEvent(...)  end, ---宝物
		[ModelWonderland.EVENT_SHOP] = function(...) self:ShopEvent(...)  end, ---商店
		[ModelWonderland.EVENT_BOX] = function(...) self:BoxEvent(...)  end, ---宝箱

		[ModelWonderland.EVENT_GOLD_HAIR] = function(...) self:GoldenHairEvent(...)  end, ---金发
		[ModelWonderland.EVENT_PROTECTOR] = function(...) self:AnswerEvent(...)  end, ---答题
		[ModelWonderland.EVENT_DEVIL] = function(...) self:DevilEvent(...)  end, ---魔王
		[ModelWonderland.EVENT_GRANDMA] = function(...) self:GrandmaEvent(...)  end, ---老奶奶

		[ModelWonderland.EVENT_QUEEN] = function(...) self:QueenEvent(...)  end, ---冰雪皇后
		[ModelWonderland.EVENT_MIRROR] = function(...) self:MirrorEvent(...)  end, ---冰雪皇后

		[ModelWonderland.EVENT_ORGAN] = function(...) self:OrganEvent(...)  end, ---机关咒语
		[ModelWonderland.EVENT_POISON] = function(...) self:PoisonEvent(...)  end, ---毒气陷阱
		[ModelWonderland.EVENT_ARROW_TOWER] = function(...) self:TowerEvent(...)  end, ---箭塔
		[ModelWonderland.EVENT_CLIP] = function(...) self:ClipEvent(...)  end, ---陷阱
		[ModelWonderland.EVENT_BOX_SELECT] = function(...) self:BoxSelectEvent(...)  end, ---秘宝
		[ModelWonderland.EVENT_BOX_BOSS] = function(...) self:BoxBossEvent(...)  end, ---秘宝boss

		[ModelWonderland.EVENT_BEAN_VINE] = function(...) self:BeanVineEvent(...)  end, ---藤蔓
		[ModelWonderland.EVENT_POD] = function(...) self:WorldPodEvent(...)  end, ---豌豆
		[ModelWonderland.EVENT_WORLD_LEAVES] = function(...) self:WorldLeavesEvent(...)  end, ---世界树叶
		[ModelWonderland.EVENT_WORLD_TREE] = function(...) self:WorldTreeEvent(...)  end, ---世界树枝
		[ModelWonderland.EVENT_SPRITE] = function(...) self:WorldSpriteEvent(...)  end, ---精灵boss

		[ModelWonderland.EVENT_EMPTY] = function(...) self:EmptyEvent(...)  end, ---空格子
		[ModelWonderland.EVENT_OCTOPUS] = function(...) self:OctopusEvent(...) end, ---大章鱼
		[ModelWonderland.EVENT_SINGING] = function(...) self:SingingEvent(...) end,---歌声碎片
		[ModelWonderland.EVENT_FOAM] = function(...) self:FoamEvent(...) end,---泡泡
		[ModelWonderland.EVENT_BEAST_ADD] = function(...) self:BeastAddEvent(...) end,--- 双boss
		[ModelWonderland.EVENT_WITCH] = function(...) self:WitchEvent(...) end, --- 女巫

		[ModelWonderland.EVENT_TREA_HARD] = function(...) self:TreasureEvent(...) end, --- 困难魔卡
		[ModelWonderland.EVENT_TREA_TOUGH] = function(...) self:TreasureEvent(...) end, --- 困难魔卡

		[ModelWonderland.EVENT_LORD] = function(...) self:LordEvent(...) end, --- 梦魇领主
		[ModelWonderland.EVENT_THIEF] = function(...) self:MonsterEvent(...) end, --- 盗宝精灵
		[ModelWonderland.EVENT_TIME] = function(...) self:TimeEvent(...) end, --- 时空裂缝
		[ModelWonderland.EVENT_ABYSS_LORD] = function(...) self:LordEvent(...) end, --- 深渊领主

	}

	self._effectFuncList=
	{
		[ModelWonderland.EVENT_DEVIL] = function(...) self:ShowDevilAwake() end,

	}


	self:ShowActPart()

end

function UIEden:TimeLordEvent(data)
	GF.OpenWnd("UIEdenMonster",{data= data})
end

function UIEden:OnClickTask()
	GF.OpenWnd("UIEdenTk",{wndType = 2})
end


function UIEden:SetStaticContent()
	local str = ccClientText( 16772)
	local text = self:FindWndTrans(self.mShopBtn,"UIText")
	self:SetWndText(text,str)
	str = ccClientText(16771)
	text = self:FindWndTrans(self.mTaskBtn,"UIText")
	self:SetWndText(text,str)

	--self:InitTextSizeWithLanguage(self.mMonsterTip,-2)
	self:InitTextLineWithLanguage(self.mMonsterTip,-40)

	self:SetWndText(self.mAutoRunTxt,ccClientText(36422))
end

function UIEden:MonsterEvent(data)
	GF.OpenWnd("UIEdenMonster",{data= data})
end

function UIEden:ShopEvent(data)
	GF.OpenWnd("UIEdenDian",{data= data})
end

function UIEden:DevilEvent(data)
	if  data.canSelect then
		GF.OpenWnd("UIEdenMonster",{data= data})
	else
		GF.OpenWnd("UIEdenMonsterPop",{data= data,eventType = ModelWonderland.EVENT_DEVIL,wndType = 3})
	end

end

function UIEden:TowerEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:ShowMirror(eventId)
	local cfg = gModelWonderland:GetEventConfig(eventId)
	local para = cfg.parameter
	local tempStrs = string.split(para,"=")
	if #tempStrs < 2 then
		return
	end
	local str =ccClientText(16701)-- "魔镜碎片进度"
	self:SetWndText(self.mSceneEvent,str)
	self:InitTextLineWithLanguage(self.mSceneEvent, -30)
	self:InitTextSizeWithLanguage(self.mSceneEvent, -2)
	local itemId = tonumber(tempStrs[1])
	local totalCnt = gModelWonderland:GetItemNum(itemId)
	local targetCnt = 0
	if #tempStrs >1 then
		targetCnt = tonumber(tempStrs[2])
	end


	str = string.format("%s/%s",totalCnt,targetCnt)
	self:SetWndText(self.mEventProgress,str)


end

function UIEden:ShowDevilAwake()
	local wndData =
	{
		wnd = "UIEdenMonsterPop",
		para = {wndType = 2},
		layer = LGameUI.UI_SORTLAYER_UIWND
	}

	gModelGeneral:OpenUniquePopWnd(wndData)
end

function UIEden:ShowActPart()
	self._showTips = false
	self._actData = 1
	local actData,icon,title = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"wonderLand",true)
	if actData then

		self:EnableClickNotUICall()

		self._actData = actData
		local str = string.replace(ccClientText(16216),actData*100)
		local tipTran = self:FindWndTrans(self.mBtnAct,"tips")
		local text = self:FindWndTrans(tipTran,"UIText")
		self:SetWndText(text,str)
		local textCom = self:FindWndText(text)
		local preferredWidth = textCom.preferredWidth
		preferredWidth = math.min(preferredWidth,400)

		local layoutElement = self:FindCommonComponent(text,typeLayoutElement)
		layoutElement.preferredWidth = preferredWidth

		if icon then
			local iconTran = self:FindWndTrans(self.mBtnAct,"Root/icon")
			self:SetWndEasyImage(iconTran,icon,function() CS.ShowObject(self.mBtnAct,true) end)
		end

		if title then
			local textTran = self:FindWndTrans(self.mBtnAct,"Root/name")
			self:SetWndText(textTran,title)
		end
	else
		CS.ShowObject(self.mBtnAct,false)
	end
	self._actRewardList = {}
	local actReward = gModelActivity:GetActivityListByModelId(ModelActivity.COMMONRANK,"wonderLandReward")
	if actReward then
		actReward = string.split(actReward,",")
		for i,v in ipairs(actReward) do
			local refId = tonumber(v)
			self._actRewardList[refId] = refId
		end
	end

	self._activeRecord = {}
end

function UIEden:OnDrawBuff(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local icon = self:FindWndTrans(item,"icon")
	local level = self:FindWndTrans(item,"level")


	local ref = gModelSkill:GetSkillRef(itemdata)
	if not ref then
		return
	end
	local iconPath = ref.icon
	self:SetWndEasyImage(icon,iconPath)



	local str = string.format("Lv.%s",ref.level)
	self:SetWndText(level,str)

	local isActivate,layer = gModelWonderland:IsBuffActivate(itempos)
	self:SetWndImageGray(icon,not isActivate)
	local str = ""
	if not isActivate then
		str =ccClientText(16790) --"深渊难度中达到%s层时自动激活"
		str= string.replace(str,layer)
	end


	self:SetWndClick(icon,function ()
		--GF.OpenWnd("UINewJNTip",{curSkillId = itemdata,wndType = 2,extraInfo = str})
		gModelGeneral:OpenSkillWnd({curSkillId = itemdata,wndType = 2,extraInfo = str})
	end)

	local key = "activate"..itempos
	self:DestroyWndEffectByKey(key)

	local oldActivate = self._activeRecord[itempos]

	if oldActivate == false and isActivate then
		self:CreateWndEffect(item,"fx_qjtx_jiesuo",key,100)
	end

	self._activeRecord[itempos] = isActivate
end

function UIEden:FrozenEvent(data)
	local wndData =
	{
		eventId = 20021,
		state = data.state,
		gridIndex = data.gridIndex,
	}

	GF.OpenWnd("UIEdenPop",{data= wndData,wndType = 2})

end

--function UIEden:OnOperRet(type,grid)
--	if type == ModelWonderland.EVENT_WORLD_LEAVES then
--		self:OnClickGrid(grid.layerIndex,grid.gridIndex)
--	end
--end

function UIEden:OnTryTcpReconnect()
	gModelWonderland:InitFormation()
	gModelWonderland:WonderlandHeroOpsReq(0) --刷新英雄数据

end

function UIEden:OnClickGuideBook()
	local themeId = gModelWonderland:GetThemeId()
	GF.OpenWnd("UIEdenBook",{themeList = {themeId}})
end

function UIEden:SetCountDown()
	local endTime = gModelWonderland:GetCountDownTime()
	endTime = tonumber(endTime)/1000
	local timeLeft = endTime- GetTimestamp()
	if timeLeft < 0 then
		self:TimerStop(self._countDownKey)
	end

	local timeStr = LUtil.FormatTimespanNumber(timeLeft)
	timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
	local str = ccClientText(26200) --"%s  后重置奇境"
	str = string.replace(str,timeStr)
	self:SetWndText(self.mCountDown,str)
end


function UIEden:ShowDevilAwakeEffect()
	gLGpManager:FindWonderlandCopyGp():ShowDevilAwakeEffect()
end

function UIEden:OnDrawBtn(list,item,itemdata,itempos)
	local icon = self:FindWndTrans(item,"icon")
	local UIText = self:FindWndTrans(item,"UIText")
	self:SetWndText(UIText,itemdata.str)
	self:InitTextSizeWithLanguage(UIText, -2)
	self:InitTextLineWithLanguage(UIText, -30)
	local activtyType = itemdata.activtyType
	if activtyType then
		self._redItemList[activtyType] = item
	end

	self:SetWndEasyImage(icon,itemdata.iconPath)
	self:SetWndClick(item,itemdata.func,LSoundConst.CLICK_BUTTON_COMMON)

	if itempos == 3 then
		self._treasureBtn = item
	end
end

function UIEden:InitEvent()
	self:WndEventRecv(EventNames.ON_WONDERLAND_PAGE_CHANGE,function() self:SetContent() end)

	self:WndNetMsgRecv(LProtoIds.WonderlandEffectResp,function(...) self:ShowEffect(...) end)
	self:WndNetMsgRecv(LProtoIds.WonderlandItemInfoResp,function(...) self:ShowSceneInfo(...) end)
	--self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_DEVIL_AWAKE,function() self:ShowDevilAwakeEffect() end)
	self:WndEventRecv(EventNames.ON_DEST_REWARD_REFRESH,function () self:ShowBoxEff() end)


	--self:WndEventRecv(EventNames.ON_CLICK_BUTTON,function (...) self:CheckOnButtonClick(...) end)

	self:WndEventRecv(EventNames.ON_WONDER_GRID_CLICK,function (...)
		if self:IsWndClosed() then
			return
		end

		---战斗未结算，不允许点击
		if not gModelBattle:IsCombatLifeFinish(LCombatTypeConst.COMBAT_WONDERLAND) then
			return
		end

		self:OnClickGrid(...) end)

	self:WndEventRecv(EventNames.ON_WONDER_ROLE_MOVE_FINISH,function ()
		self:ShowBuffList()
	end)

	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (wndName)


		if not self._wndRecord[wndName] then
			return
		end

		if gModelBattle:IsVideoAlive() then
			return
		end

		printInfoN("____________auto trigger -----2")

		if self._delayFunc then
			self._delayFunc()
			self._delayFunc = nil
		end

		self:AutoTriggerEvent()
	end)

	self:WndEventRecv(EventNames.ON_SEL_GRID_CHANGE,function ()
		printInfoN("____________auto trigger -------1")

		self._autoTrigger = true
		self:AutoTriggerEvent()
	end)

	self:WndNetMsgRecv(LProtoIds.WonderlandQuestResp,function (...)
		self:RefreshTaskContent(...)
	end)

	self:WndEventRecv(EventNames.ON_WONDERLAND_GET_HURT,function ()
		self:ShowHurtEffect()
	end)

	self:WndEventRecv(EventNames.ON_GAIN_ITEM,function (...) self:ShowItemGainEff(...) end)

	self:WndNetMsgRecv(LProtoIds.GameHelperRunningFunctionResp,function(...) self:RefreshSettingAutoRunStatus() end)
	self:WndNetMsgRecv(LProtoIds.WonderlandGameHelperResp,function(...) self:OnWonderlandGameHelperResp(...) end)
end

function UIEden:ScaleBubble()
	local trans = self.mTextBg
	local seqCom = self:GetSeqCom()
	trans.localScale = Vector3.one

	local seq = seqCom:CreateSeq("scaleBubble")
	local tween = trans:DOScale(Vector3.New(1.2,1.2,1.2),0.4):SetEase(EaseInExpo)
	seq:Append(tween)
	seq:SetLoops(2,Tweening.LoopType.Yoyo)
	seq:PlayForward()

end

function UIEden:OnClickTreasureBag()
	GF.OpenWnd("UIEdenTsBag")
end

function UIEden:ShowActTips()
	local tran = self:FindWndTrans(self.mBtnAct,"tips")
	CS.ShowObject(tran,true)
	--CS.ShowObject(self.mActTips,self._showTips)
end

--function UIEden:CheakActTips()
--	if self._showTips then
--		self:ShowActTips()
--	end
--end

function UIEden:OnClickHelp()
	local updateDay = gModelWonderland:GetWonderlandPara("updateDay")
	GF.OpenWnd("UIBzTips",{refId = 10,para ={updateDay}})
end


function UIEden:HireEvent(data)
	GF.OpenWnd("UIEdenHire",{data= data})
end

function UIEden:OctopusEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:TweenBubble()
	local root = self._curBubbleTran
	local trans = self:FindWndTrans(root,"bubble")
	local pos = self:GetBubbleDefaultPos(trans)

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("floatBubble")
	trans.localPosition = pos
	trans.localScale = Vector3.one
	local tween= trans:DOLocalMoveY(-10,0.8):SetRelative():SetEase(EaseInQuad)
	seq:Append(tween)
	seq:SetLoops(-1,Tweening.LoopType.Yoyo)
	seq:PlayForward()
end

function UIEden:SetContent()
	local themeId = gModelWonderland:GetThemeId()

	self._themeId = themeId

	local themeCfg = gModelWonderland:GetThemeConfig(themeId)
	local name = ccLngText(themeCfg.name)
	self:SetWndText(self.mTitle,name)

	self:SetCountDown()
	local endTime = gModelWonderland:GetCountDownTime()
	endTime = tonumber(endTime)/1000
	if endTime> GetTimestamp() then

		self:TimerStop(self._countDownKey)
		self:TimerStart(self._countDownKey,1,false,-1)
	end

	self:ShowSceneInfo()

	self:AutoTriggerEvent()

	gModelWonderland:WonderlandEffectReq() --获取各种效果

	self:ShowMonster()

	gModelWonderland:CheckChangeMap()
end



function UIEden:InitBtnList()
	local _uilist = self:GetUIScroll("btnList")
	local activitylist = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_PASSC)
	local activity = activitylist[1]
	local list = {}
	for k,v in ipairs(self._btnDataList) do
		if v.activtyType then
			if activity then
				table.insert(list,v)
			end
		else
			table.insert(list,v)
		end
	end

	_uilist:Create(self.mBtnList,list,function (...) self:OnDrawBtn(...) end)
end

function UIEden:OnWonderlandGameHelperResp(pb)
	local eventType = pb.eventType
	local bufRefId = pb.bufRefId
	if bufRefId and bufRefId > 0 then
		if eventType == ModelWonderland.EVENT_TREASURE or eventType == ModelWonderland.EVENT_TREA_HARD or eventType == ModelWonderland.EVENT_TREA_TOUGH then
			local wndData = {
				wnd = "UIAutoEdenTsure",
				para  = {bufRefId = bufRefId},
				layer = LGameUI.UI_SORTLAYER_UIWND
			}
			gModelGeneral:OpenUniquePopWnd(wndData)
		end
	end
end

function UIEden:GetTreasureBtnPos()
	if CS.IsValidObject(self._treasureBtn) then
		return self._treasureBtn.transform.position
	end
end

function UIEden:BeanVineEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:GetBubbleDefaultPos(trans)
	local posRecord = self._bubblePosRecord
	if not posRecord then
		posRecord = {}
		self._bubblePosRecord = posRecord
	end

	local instanceId = trans:GetInstanceID()

	local pos = posRecord[instanceId]
	if not pos then
		pos = trans.localPosition
	end

	posRecord[instanceId] = pos

	printInfoN(string.format("pos x %s,y %s,z %s",pos.x,pos.y,pos.z))

	return pos
end

function UIEden:WorldPodEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})
end

function UIEden:BeastEvent()



	local beastEvent = gModelWonderland:GetBeastEvent()
	if not beastEvent then
		return
	end
	local isMeet = beastEvent.isMeet
	if not isMeet then
		return
	end
	beastEvent.beastState = 1

	if self:GetSettingAutoRunStatus() then
		return
	end

	GF.OpenWnd("UIEdenMonsterPop",{data= beastEvent,eventType = ModelWonderland.EVENT_BEAST,wndType = 7})
	return true
end

function UIEden:TreasureEvent(data)
	local isShowMask = self:GetSettingAutoRunStatus()
	if isShowMask then return end

	local wndData =
	{
		wnd = "UIEdenTsure",
		para  = {data= data},
		layer = LGameUI.UI_SORTLAYER_UIWND
	}

	gModelGeneral:OpenUniquePopWnd(wndData)
end

function UIEden:OnClickGetTaskReward()
	local status = self._status
	if status == 0 then
		self:OnClickTask()
	elseif status == 1 then
		gModelWonderland:WonderlandQuestReq(1)
	elseif status == 2 then
		local str =ccClientText(12211)-- "奖励已领取"
		GF.ShowMessage(str)
	end
end

function UIEden:ShowLittleBox()
	local showEndBox = gModelWonderland:CheckShowEndBox()
	CS.ShowObject(self.mLittleBox,showEndBox)
	if not showEndBox then
		return
	end

	local key = "littleBoxEffKey"
	self:DestroyWndEffectByKey(key)
	self:CreateWndEffect(self.mLittleBox,"fx_qjtx_baoxiang",key,30)
end

function UIEden:EmptyEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:ShowItemInfoTip(tipsId)
	GF.OpenWnd("UIBzTips",{refId = tipsId})
end

function UIEden:OrganEvent(data)
	GF.OpenWnd("UIEdenKey",{data= data})
end

function UIEden:WitchEvent(data)
	GF.OpenWnd("UIEdenMonsterPop",{data= data,eventType = ModelWonderland.EVENT_WITCH,wndType = 6})
end


function UIEden:ShowBuffList()

	local curPattern = gModelWonderland:GetCurPattern()
	if curPattern ~= ModelWonderland.TOUGH then
		return
	end
	local themeBuff = gModelWonderland:GetThemeBuff()
	if not themeBuff then
		return
	end
	local cnt = #themeBuff
	if cnt ==0 then
		return
	end

	local needRefresh = false
	if #self._activeRecord >0 then
		for k,v in pairs(self._activeRecord) do
			local isActivate = gModelWonderland:IsBuffActivate(k)
			if isActivate ~= v then
				needRefresh = true
				break
			end
		end
	else
		needRefresh = true
	end

	if not needRefresh then
		return
	end

	local buffList = self._buffList
	if not buffList then
		buffList = self:GetUIScroll("buffList")
		self._buffList = buffList
		buffList:Create(self.mBuffList,themeBuff,function (...) self:OnDrawBuff(...) end)
	else
		buffList:RefreshList(themeBuff)
	end
end


function UIEden:OnClickGrid(layerIndex,gridIndex)

	local themeType = gModelWonderland:GetThemeType()
	if themeType == 5 then
		if self:BeastEvent() then
			return
		end
	end

	local itemdata = gModelWonderland:GetGridData(layerIndex,gridIndex)
	if not itemdata then
		return
	end
	local state = itemdata:GetStatus()

	if state == StructWonderlandGrid.DISAPPEAR then
		return
	end
	if state == StructWonderlandGrid.PASSED or state == StructWonderlandGrid.PLAYER then
		return
	end

	local gridIndex = itemdata:GetGridIndex()
	local layerIndex = itemdata:GetLayerIndex()
	local gridKey = gModelWonderland:FormatGridKey(layerIndex,gridIndex)



	local data = {}
	data.canSelect = state == StructWonderlandGrid.ALLOW or state == StructWonderlandGrid.SELECTED
	data.layerIndex = layerIndex
	data.gridIndex = gridIndex
	data.state = state

	local hasSnow = gModelWonderland:HasAffectEventType(gridKey,ModelWonderland.EVENT_SNOW)
	if hasSnow  then
		if data.canSelect then
			local influence = itemdata:GetInfluenced()
			if influence == 1 then --结冰方块
				if state == StructWonderlandGrid.ALLOW then
					self:FrozenEvent(data)
				end
				return
			end
		else
			local str =ccClientText(16750) --"这里被一片风雪覆盖，完全无法看清"
			GF.ShowMessage(str)
			return
		end
	end



	local eventList = itemdata:GetEventList()
	if #eventList< 0 then
		return
	end

	local event = nil
	local prio = nil
	for k,v in ipairs(eventList) do             --优先触发普通事件
		local eventId = v.eventId
		local eventCfg = gModelWonderland:GetEventConfig(eventId)
		local tempPrio = eventCfg.overlayType
		if not prio then
			prio = tempPrio
			event = v
		else
			if prio > tempPrio then
				event = v
			end
		end

	end

	if not event then
		event = eventList[1]
	end

	local eventType = nil
	if event then
		local eventId = event.eventId
		local eventCfg = gModelWonderland:GetEventConfig(eventId)
		eventType = eventCfg.type
		printInfoN(string.format("event id %s,type %s",eventId,eventType))
		local isShow = gModelWonderland:IsEventShow(layerIndex,gridIndex,eventId)
		if not isShow and not data.canSelect then
			return
		end

		data.eventId = eventId
		data.type = event.type
		data.moreInfo = event.moreInfo
		data.refreshCnt = event.refreshCount
		data.fixedTreasure = event.fixedTreasure
	else
		data.eventId = 30015
		local eventCfg = gModelWonderland:GetEventConfig(30015)
		eventType = eventCfg.type
	end

	local isShowMask = self:GetSettingAutoRunStatus()
	if isShowMask then return end

	data.eventType = eventType
	local eventFunc = self._evenFuncList[eventType]

	if not eventFunc then
		return
	end

	if data.canSelect then
		FireEvent(EventNames.ON_TRIGGER_WONDER_EVENT,{eventType = eventType,endCall = function ()
			eventFunc(data)
		end})
	else
		eventFunc(data)
	end


end

function UIEden:ShowEvilAwake()
	CS.ShowObject(self.mTextBg,true)

	local themeId = gModelWonderland:GetThemeId()
	local themeCfg = gModelWonderland:GetThemeConfig(themeId)
	local eventId = themeCfg.endEvent
	local cfg = gModelWonderland:GetEventConfig(eventId)
	local para = cfg.parameter
	local tempStrs = string.split(para,"=")
	if #tempStrs <2 then
		return
	end
	local str =ccClientText(16700)-- "魔王惊醒值"
	self:SetWndText(self.mSceneEvent,str)
	self:InitTextLineWithLanguage(self.mSceneEvent, -30)
	self:InitTextSizeWithLanguage(self.mSceneEvent, -2)
	local itemId = tonumber(tempStrs[1])
	local totalTimes = gModelWonderland:GetItemNum(itemId)
	local awakeTimes = tonumber(tempStrs[2])
	local timeShow = nil
	if totalTimes == 0 then
		timeShow = 0
	else
		timeShow = totalTimes%awakeTimes
	end
	str = string.format("%s/%s",timeShow,awakeTimes)
	self:SetWndText(self.mEventProgress,str)

	if timeShow >= 6 then
		self:CreateWndEffect(self.mBgIcon,"ui_fx_mowangjingxing_red","evilAwake",100)
	else
		self:DestroyWndEffectByKey("evilAwake")
	end



end


function UIEden:OnClickReborn()
	GF.OpenWnd("UIEdenReborn")
end

function UIEden:LordEvent(data)
	GF.OpenWnd("UIEdenLord",{data= data})
end


function UIEden:StartFly(root,startPos,endPos,eventType)
	if not self._effOneOk or not self._effTwoOk then
		return
	end

	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("itemFly")
    root.position = startPos

	local tween = root:DOMove(endPos,2)
	seq:Append(tween)
	seq:OnComplete(function ()
		self:DestroyWndEffectByKey("itemEff")
		if not self:ShowSingTween(eventType,root) then
			self:DestroyWndEffectByKey("eventEff")
		end
	end)
	seq:PlayForward()

end

function UIEden:PoisonEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2 })


end

function UIEden:OnClickFormation()
	local para = {
		setTargetType = LCombatTypeConst.COMBAT_WONDERLAND ,
		returnFunc = function()
			gModelGeneral:WonderlandEntrance()
		end
	}
	gModelFormation:OpenSetFormationWnd(para)
end

function UIEden:RefreshRed()
	local list = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_PASSC)
	local activity = list[1]
	if not activity then
		return
	end
	local sid = activity.sid
	local isRed = gModelRedPoint:CheckActivityShowRed(sid)
	local trans = self._redItemList[ModelActivity.MODEL_PASSC]
	if not trans then
		return
	end
	local redPoint = CS.FindTrans(trans,"redPoint")
	CS.ShowObject(redPoint,isRed)
end

function UIEden:BoxEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 1})

end


function UIEden:OnClickNotUI(name)
	local nameRecord = self._nameRecord
	if name and nameRecord[name] then
		return
	end

	local tip = self:FindWndTrans(self.mBtnAct,"tips")
	CS.ShowObject(tip,false)
	tip = self:FindWndTrans(self.mBtnPrivile,"tips")
	CS.ShowObject(tip,false)
end

function UIEden:InitUIEvent()
	self:SetWndClick(self.mReturnBtn,function ()
		GF.ChangeMap("LCityMap")
		if not self:WndCloseAndBack() then
			GF.OpenWndBottom("UIDTDNew")
		end
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	--self:SetWndClick(self.mTaskBtn,function () self:OnClickTask() end,LSoundConst.CLICK_BUTTON_COMMON)
	--self:SetWndClick(self.mShopBtn,function () self:OnClickShop() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mHelpBtn,function () self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mTextBg,function () self:OnClickThemeHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mBtnAct,function() self:ShowActTips() end,LSoundConst.CLICK_BUTTON_COMMON)
	--self:SetWndClick(self.mActTips,function() self:CheakActTips() end,LSoundConst.CLICK_BUTTON_COMMON)

	self:SetWndClick(self.mBoxBg,function ()
		GF.OpenWnd("UIEdenDestRwd")
		CS.ShowObject(self.mBoxBg,false)
	end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mLittleBox,function ()
		GF.OpenWnd("UIEdenDestRwd")
		CS.ShowObject(self.mLittleBox,false)
	end,LSoundConst.CLICK_BUTTON_COMMON)


	self:SetWndClick(self.mTaskBg,function ()
		self:OnClickTask()
	end)

	self:SetWndClick(self.mBtnTask,function ()
		self:OnClickGetTaskReward()
	end)
end

function UIEden:FoamEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:GoldenHairEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})


end

function UIEden:OnClickPassC()
	local jump = gModelWonderland:GetWonderlandPara("uniqueJump")
	gModelFunctionOpen:Jump(jump,self:GetWndName())
end

function UIEden:OnClickHeroInfo()
	GF.OpenWnd("UIEdenSagaBag")
end

function UIEden:OnTryRefreshRedPoint(redPointType)
	if(redPointType == ModelRedPoint.ACTIVITY_ACTIVITY)then
		self:RefreshRed()
	end
end

function UIEden:WorldTreeEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})

end

function UIEden:ShowItemInfo(itemId,tipsId)
	local showItem = itemId>0
	CS.ShowObject(self.mItemInfo,showItem)
	if not showItem then
		return
	end

	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(self.mItemIcon,iconPath,nil,true)

	local itemNum = gModelWonderland:GetItemNum(itemId)
	self:SetWndText(self.mItemNum,itemNum)

	--self:SetWndClick(self.mItemInfo,function()
	--	self:ShowItemInfoTip(tipsId)
	--end,LSoundConst.CLICK_ERROR_COMMON)
end


function UIEden:SetPara()
	self._autoTrigger = self:GetWndArg("autoTrigger")


end

function UIEden:MirrorEvent(data)
	GF.OpenWnd("UIEdenPop",{data= data,wndType = 2})



end

function UIEden:OnClickThemeHelp()
	local themeId = gModelWonderland:GetThemeId()
	local themeCfg = gModelWonderland:GetThemeConfig(themeId)
	local tipId = themeCfg.tips

	GF.OpenWnd("UIBzTips",{refId = tipId})
end



function UIEden:AutoTriggerEvent()

	local wndRecord =
	{
		["UIOrdinResult"] = true,
		["UIEdenTsure"] = true,
		["UIEdenSelectPop"] = true,
		["UIEdenPop"] = true,
		["UIEdenMonsterPop"] = true,
		["UIAward"] = true,
        ["UIAutoEdenTsure"] = true,
	}

	if gLGameUI:IsExistOneWnd(wndRecord) then
		return
	end

	local isChange = gModelWonderland:IsEvilAwakeTimeChange()
	if isChange then
		self:ScaleBubble()
	end

	if not self._autoTrigger then
		return
	end
	self._autoTrigger = false

	local selectGrid = nil
	local gridDatas = gModelWonderland:GetGridInfos()
	if gridDatas then
		for k,v in pairs(gridDatas) do
			local state = v:GetStatus()
			if state == StructWonderlandGrid.SELECTED then
				selectGrid = v
				break
			end
		end
	end

	local isInLordMap = false
	local eventData,eventInfo = gModelWonderland:GetTimeEvent()
	if eventInfo and eventInfo.isEnter then
		isInLordMap = true
	end

	if selectGrid and not isInLordMap then
		local layerIndex = selectGrid:GetLayerIndex()
		local gridIndex = selectGrid:GetGridIndex()
		self:OnClickGrid(layerIndex,gridIndex)
	end

	local eventId = self:GetWndArg("eventId")
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	if eventCfg then
		local type = eventCfg.type

		if type == ModelWonderland.EVENT_BEAST  then
			local eventData = gModelWonderland:GetBeastEvent()
			if eventData and eventData.beastState ~= 3 then
				eventData.beastState =3
				if self:GetSettingAutoRunStatus() then return end

				GF.OpenWnd("UIEdenMonsterPop",{data= eventData,eventType = ModelWonderland.EVENT_BEAST,wndType = 7})
			end
		end
	end



	self:ShowBoxEff()



end


function UIEden:ShowMonster()
	local themeType = gModelWonderland:GetThemeType()
	if themeType ~= 5 then
		CS.ShowObject(self.mMonster,false)
		return
	end


	local isEnd = gModelWonderland:IsMapEnd()
	CS.ShowObject(self.mMonster,not isEnd)

	local isGray = false
	local themeId = gModelWonderland:GetThemeId()
	local isTrigger = gModelWonderland:IsBossTrigger(themeId)
	if isTrigger then
		isGray = true
		local str = ccClientText(16763)
		self:SetWndText(self.mMonsterTip,str)
		self:SetWndImageGray(self.mMonsterIcon,isGray)
	else
		local sleepBout = gModelWonderland:GetBeastSleep()

		if sleepBout>0 then
			local str =ccClientText(16761) --"%s回合后苏醒"
			str = string.replace(str,sleepBout)
			self:SetWndText(self.mMonsterTip,str)
			isGray = true
		else
			local curLayer = gModelWonderland:GetCurLayer()
			local eventdata = gModelWonderland:GetBeastEvent()
			local str = nil
			if not eventdata then
				CS.ShowObject(self.mMonster,false)
				local eventCfg = gModelWonderland:GetEventConfig(50008)
				local para = eventCfg.parameter
				local strs = string.split(para,'=')
				local cnt = tonumber(strs[1])
				local dis = cnt - curLayer
				str =ccClientText(16761) --"%s回合后苏醒"
				str = string.replace(str,dis)
				isGray = true
			else
				local monsterLayer =eventdata.layerIndex
				local dis = curLayer - monsterLayer
				str =ccClientText(16762)-- "%s回合后追上")
				str = string.replace(str,dis)
			end

			self:SetWndText(self.mMonsterTip,str)
		end

		self:SetWndImageGray(self.mMonsterIcon,isGray)
	end

	if self._isSleep == isGray then
		return
	end

	self._isSleep = isGray


	self:DestroyWndEffectByKey("monsterEff")
	if isGray then
		self:CreateWndEffect(self.mMonsterEff,"ui_fx_kelakenchenshui","monsterEff",100)
	else
		self:CreateWndEffect(self.mMonsterEff,"ui_fx_kelakensuxing","monsterEff",100)
	end

end

function UIEden:BoxBossEvent(data)
	GF.OpenWnd("UIEdenMonster",{data= data})
end
------------------------------------------------------------------
return UIEden


