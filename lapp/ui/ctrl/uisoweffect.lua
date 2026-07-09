---
--- Created by Administrator.
--- DateTime: 2023/10/27 17:20:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISowEffect:LWnd
local UISowEffect = LxWndClass("UISowEffect", LWnd)
------------------------------------------------------------------
---
UISowEffect.COMMON = 0						-- 通用
UISowEffect.WONDERLAND = 1 					-- 奇境探险
UISowEffect.DREAMTRIP = 2						-- 梦境之旅
UISowEffect.FUNCTION_OPEN = 3          		-- 玩法解锁
UISowEffect.FAIRYTALE_TD = 4          		-- 保卫童话镇
UISowEffect.ACTIVIT_DREAMTRIP = 5				-- 活动梦境之旅
-- UISowEffect.ACTIVIT_FAIRCOMPETE = 6			-- 公平竞技
UISowEffect.FastDREAMTRIP = 7						-- fast 梦境之旅




local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISowEffect:UISowEffect()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISowEffect:OnWndClose()
	if self._seqCom then
		self._seqCom:Destroy()
		self._seqCom = nil
	end

	if self._wndType == UISowEffect.FUNCTION_OPEN then
		local isFromGuide = self:GetWndArg("isFromGuide")
		local guideId = self:GetWndArg("guideId")
		if isFromGuide then
			gModelGuide:OnNextGuide(guideId)
		end
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISowEffect:OnCreate()
	LWnd.OnCreate(self)
	self._seqCom = SequenceCom:New()
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISowEffect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local wndType = self:GetWndArg("wndType") or UISowEffect.WONDERLAND
	self._wndType = wndType
	self._isFirst = self:GetWndArg("isFirst") or false
	if wndType == UISowEffect.WONDERLAND then
		self:ShowWonderlandEffect()
	elseif wndType == UISowEffect.DREAMTRIP then
		gModelDreamTrip:OnDreamTripRobberInfoReq()
		self:ShowDreamTripEffect()
	elseif wndType == UISowEffect.FUNCTION_OPEN then
		self:ShowFunctionOpenEff()
	elseif wndType == UISowEffect.FAIRYTALE_TD then
		self:ShowFairyTaleTDEffect()
	elseif wndType == UISowEffect.ACTIVIT_DREAMTRIP then
		self:ShowDreamTripEffect()
	-- elseif wndType == UISowEffect.ACTIVIT_FAIRCOMPETE then
	-- 	self:ShowActivityFairCompete()
	elseif wndType == UISowEffect.FastDREAMTRIP then
		self:ShowFastDreamTripEffect()
	elseif wndType == UISowEffect.COMMON then
		self:ShowCommonEffect()
	end
end

function UISowEffect:ShowFastDreamTripEffect()
	local spineName = "fx_slzt_zhuanchang"
	self._bookSpineKey = "DreamTripSpine"
	self:CreateWndEffect(self.mRoot,spineName,self._bookSpineKey,100,nil,nil
	,nil,function (dpTrans)
		dpTrans.gameObject:SetActive(true)
		self:FastDreamTripShowEnterTween()
	end)
end

function UISowEffect:CheckShowEnterTween()
	self._waitCnt = self._waitCnt -1
	if self._waitCnt>0 then
		return
	end
	local themeId = self:GetWndArg("themeId")
	self._themeId = themeId
	local refreshEff = gModelWonderland:GetRefreshEff(themeId)
	local adAni = refreshEff.adAni
	self:EnterTween(adAni)
end

function UISowEffect:ShowFunctionOpenEff()


	local effList =
	{
		[1] = "fx_wanfajiesuo_1",
		[2] = "fx_wanfajiesuo_2",
		[3] = "fx_wanfajiesuo_3",
	}


	self._waitCnt = 3

	local effKey = "eff_"
	for i = 1 , 3 do
		local effectName = effList[i]
		local effData =
		{
			trans = self.mRoot,
			effName = effectName,
			effKey = effKey..i,
			endFunc = function(effect)
				effect:SetVisible(false)
				-- self:OnFuncEffAllEnd()【G功能预告】删除玩法预告机制（客户端&服务端
			end,
		}

		self:CreateWndEffect_Ex(effData)
	end


end

function UISowEffect:EnterFairyTaleTDTween()
	local key = "FairyTaleTDTween"
	local seq =  self._seqCom:CreateSeq(key)
	seq:AppendCallback(function ()
		local effect = self:FindWndEffectByKey(self._bookSpineKey)
		if effect then
			local effectTrans = effect:GetDisplayTrans()
			if CS.IsValidObject(effectTrans)  then
				effectTrans.gameObject:SetActive(true)
			end
		end
	end)
	seq:AppendInterval(1)
	seq:AppendCallback(function ()
		local effect = self:FindWndEffectByKey(self._bookSpineKey)
		if effect then
			local effectTrans = effect:GetDisplayTrans()
			if CS.IsValidObject(effectTrans)  then
				effectTrans.gameObject:SetActive(true)
			end
		end
		GF.ChangeMap("LFairyTaleTDMap",true, {createId=self:GetWndArg("createId")})
	end)
	seq:AppendInterval(1)
	seq:OnComplete(function()
		self._seqCom:DeleteSeq(key)
		self:WndClose()
	end)
	seq:PlayForward()
end

function UISowEffect:DreamTripShowEnterTween()
	local dreamTripArgList = self:GetWndArg("dreamTripArgList")
	local wndType = self._wndType
	local key = "dreamTripDT"
	local seq =  self._seqCom:CreateSeq(key)
	seq:AppendCallback(function ()
		local effect = self:FindWndEffectByKey(self._bookSpineKey)
		if effect then
			local effectTrans = effect:GetDisplayTrans()
			if CS.IsValidObject(effectTrans)  then
				effectTrans.gameObject:SetActive(true)
			end
		end
		if wndType == UISowEffect.DREAMTRIP then
			GF.ChangeMap("LDreamTripMap",true,{isFirst = self._isFirst,mapType = ModelCommonDreamTrip.MAP_TYPE_NORMAL})
		elseif wndType == UISowEffect.ACTIVIT_DREAMTRIP then
			GF.ChangeMap("LDreamTripMap",true,{isFirst = self._isFirst,dreamTripArgList = dreamTripArgList,mapType = ModelCommonDreamTrip.MAP_TYPE_ACTIVITY})
		end
	end)
	seq:AppendInterval(1)
	seq:AppendCallback(function ()
		if wndType == UISowEffect.DREAMTRIP then
			GF.OpenWndBottom("UIHope",{isFirst = self._isFirst})
		else
			GF.OpenWnd("UIActDreamTrip",dreamTripArgList)
		end
	end)
	seq:AppendInterval(1.1)
	seq:AppendCallback(function ()
		GF.CloseWndByName("UIDTDNew")
	end)
	seq:AppendInterval(0.1)
	seq:AppendCallback(function ()
		if wndType == UISowEffect.DREAMTRIP then
			local dreamTripCallBack = self:GetWndArg("dreamTripCallBack")
			if dreamTripCallBack then
				dreamTripCallBack()
			end
		end
	end)
	seq:AppendInterval(0.5)
	seq:OnComplete(function()
		self._seqCom:DeleteSeq(key)
		self:WndClose()
	end)
	seq:PlayForward()
end

-- 【G功能预告】删除玩法预告机制（客户端&服务端
-- function UISowEffect:OnFuncEffAllEnd()
-- 	self._waitCnt = self._waitCnt -1
-- 	if self._waitCnt>0 then
-- 		return
-- 	end

-- 	local refId = self:GetWndArg("refId")
-- 	local ref = gModelFunctionOpen:GetForeShowRef(refId)
-- 	if not ref then
-- 		self:WndClose()
-- 		return
-- 	end

-- 	local icon = ref.icon
-- 	local path = ref.path

-- 	local s,e = string.find(path,'/')

-- 	local target = nil
-- 	local type = 1
-- 	if s and e then
-- 		local rootName = LUtil.GetRootName(path)
-- 		local relativePath = LUtil.GetRelativePath(path)
-- 		s,e = string.find(rootName,"UI")
-- 		if s and e then
-- 			local wnd = GF.FindFirstWndByName(rootName)
-- 			if not wnd then
-- 				self:WndClose()
-- 				return
-- 			end
-- 			local rootTran  = wnd:GetWndTrans()
-- 			target = self:FindWndTrans(rootTran,relativePath)
-- 			type = 1
-- 			--targetPos = target.position
-- 		else
-- 			local scene = GF.GetNowSceneClass()
-- 			local mapTran = nil
-- 			if scene and scene.GetCurMapTran then
-- 				mapTran = scene:GetCurMapTran()
-- 			end
-- 			if not CS.IsValidObject(mapTran) then
-- 				self:WndClose()
-- 				return
-- 			end
-- 			target = mapTran:Find(relativePath)
-- 			type = 2
-- 			--local uicamera = gLGameUI:GetCSUICamera()
-- 			--local size,center = LUtil.GetBuildingPos(target)
-- 			--targetPos = uicamera:ScreenToWorldPoint(center)
-- 		end
-- 	end

-- 	if not target then
-- 		self:WndClose()
-- 		return
-- 	end

-- 	local cameraPara = ref.coords
-- 	if not string.isempty(cameraPara) then
-- 		local cameraPos = LxDataHelper.ParseVector(cameraPara,';')
-- 		FireEvent(EventNames.SHOW_MAIN_MOVE_POS,cameraPos)
-- 	end

-- 	local name = ccLngText(ref.name)
-- 	local seq = self._seqCom:CreateSeq("delayShowEff")
-- 	seq:AppendInterval(0.1)
-- 	seq:OnComplete(function ()
-- 		self:DelayShowFunEff(icon,target,type,name)
-- 	end)
-- 	seq:PlayForward()


-- end

function UISowEffect:DelayShowFunEff(icon,target,type,name)
	local targetPos = nil
	if type == 2 then
		local uicamera = gLGameUI:GetCSUICamera()
		local size,center = LxUiHelper.GetColliderPosAndSize(target,"GameObject",self._wndTrans)
		targetPos = uicamera:ScreenToWorldPoint(center)
	else
		targetPos = target.position
	end

	self:SetWndText(self.mFuncName,name)


	local seq = self._seqCom:CreateSeq("showFuncEff")

	local effect1 = self:FindWndEffectByKey("eff_1")
	local effect2 = self:FindWndEffectByKey("eff_2")
	local effect3 = self:FindWndEffectByKey("eff_3")

	local tran1 = effect1:GetDisplayTrans()
	tran1.localPosition = Vector3.New(277,120,0)
	local imgTran = self:FindWndTrans(tran1,"tubiao")
	self:SetWndSpriteRenderer(imgTran,icon)

	local tran = effect2:GetDisplayTrans()
	tran.localPosition = Vector3.New(0,-28.7,0)
	local duration1 = 3.4

	local duration2 = 0.5
	local duration3 = 0.5

	local duration4 = 1.9

	seq:AppendCallback(function ()
		effect1:SetVisible(true)
	end)
	seq:AppendInterval(duration1)
	seq:AppendCallback(function ()
		effect2:SetVisible(true)
	end)

	CS.ShowObject(self.mFuncRoot,true)
	local canvasGroup = self.mFuncRoot:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 0
	local alphaTween = canvasGroup:DOFade(1,0.3)
	seq:Insert(duration4,alphaTween)
	alphaTween = canvasGroup:DOFade(0,0.3)
	seq:Append(alphaTween)

	local tween = tran:DOMove(targetPos,duration2)
	seq:Append(tween)
	seq:AppendCallback(function ()
		local tran = effect3:GetDisplayTrans()
		tran.position = targetPos
		effect3:SetVisible(true)
	end)
	seq:AppendInterval(duration3)
	seq:OnComplete(function ()
		self:WndClose()
	end)

	seq:PlayForward()
end

function UISowEffect:ShowFairyTaleTDEffect()
	local spineName = "fx_slzt_zhuanchang"
	self._bookSpineKey = "FairyTaleTDEff"
	self:CreateWndEffect(self.mRoot,spineName,self._bookSpineKey,100,nil,nil,nil,function (dpTrans)
		self:EnterFairyTaleTDTween()
	end)
end

function UISowEffect:EnterCommonEffect()
	local endFunc = self:GetWndArg("endFunc")
	local key = "common"
	local seq =  self._seqCom:CreateSeq(key)
	seq:AppendInterval(0.5)
	seq:AppendCallback(function ()
		if endFunc then
			endFunc()
		end
	end)
	seq:AppendInterval(1.5)
	seq:OnComplete(function()
		self._seqCom:DeleteSeq(key)
		self:WndClose()
	end)
	seq:PlayForward()
end

-- function UISowEffect:ShowActivityFairCompete()
-- 	local fairCompeteEffName = self:GetWndArg("fairCompeteEffName")
-- 	local spineName = fairCompeteEffName or "fx_slzt_zhuanchang"
-- 	self._bookSpineKey = "FairCompeteEff"
-- 	self:CreateWndEffect(self.mRoot,spineName,self._bookSpineKey,100,nil,nil,nil,function (dpTrans)
-- 		self:EnterActivityFairCompete()
-- 	end)
-- end

-- function UISowEffect:EnterActivityFairCompete()
-- 	local key = "activityFairCompete"
-- 	local seq =  self._seqCom:CreateSeq(key)
-- 	seq:AppendInterval(1)
-- 	seq:AppendCallback(function ()
-- 		local fairCompeteFunc = self:GetWndArg("fairCompeteFunc")
-- 		if fairCompeteFunc then
-- 			fairCompeteFunc()
-- 		end
-- 		GF.CloseWndByName("UIActFairCompeteReset")
-- 	end)
-- 	seq:OnComplete(function()
-- 		self._seqCom:DeleteSeq(key)
-- 		self:WndClose()
-- 	end)
-- 	seq:PlayForward()
-- end

-- 显示通用
function UISowEffect:ShowCommonEffect()
	self:CreateWndEffect(self.mRoot, "fx_slzt_zhuanchang", "common", 100,nil,nil,nil, function (dpTrans)

		if CS.IsValidObject(dpTrans)  then
			dpTrans.gameObject:SetActive(true)
		end

		self:EnterCommonEffect()
	end)
end

function UISowEffect:EnterTween(adAni)
	local key = "enterTween"
	local seq =  self._seqCom:CreateSeq(key)

	seq:AppendCallback(function ()
		local effect = self:FindWndEffectByKey("roujie")
		effect:SetVisible(true)
	end)
	seq:AppendInterval(0.1)
	seq:AppendCallback(function ()
		local spine = self:FindWndSpineByKey(self._bookSpineKey)
		if spine then
			spine:SetVisible(true)
			spine:PlayAnimationSolid(adAni)
		end


	end)
	seq:AppendInterval(1.7)
	seq:AppendCallback(function ()
		gModelWonderland:ClearOldRecord()
		GF.OpenWndBottom("UIEden")
		GF.ChangeMap("LWonderlandMap",true,{isFirst = true})
		GF.CloseWndByName("UIEdenFront")
	end)
	seq:AppendInterval(0.3)
	seq:AppendCallback(function ()
		self:DestroyWndSpineByKey(self._bookSpineKey)
	end)
	seq:AppendInterval(2)
	seq:OnComplete(function ()
		self._seqCom:DeleteSeq(key)
		self:WndClose()
		if not gModelGuide:IsInGuide() then

			FireEvent(EventNames.ON_ENTER_WONDER_THEME,{themeId = self._themeId,endCall = function ()
				GF.OpenWnd("UIEdenTk",{wndType = 2})
			end})


		end
	end)
	seq:PlayForward()

end


function UISowEffect:GetPlayModuleBelong()
	local wndType = self:GetWndArg("wndType") or UISowEffect.WONDERLAND
	if wndType == UISowEffect.DREAMTRIP then
		return LPlayModuleConst.TRAVEL
	elseif wndType == UISowEffect.WONDERLAND then
		return LPlayModuleConst.WONDERLAND
	end

	return LPlayModuleConst.NONE
end

function UISowEffect:FastDreamTripShowEnterTween()
	local key = "dreamTripDT"
	local seq =  self._seqCom:CreateSeq(key)
	seq:AppendInterval(0.1)
	seq:AppendCallback(function ()
		gModelFastDreamTrip:EnterNormalDreamTripMap(self:GetWndArg("fastDreamTripInfo"))
	end)
	seq:AppendInterval(1.1)
	seq:AppendCallback(function ()
		GF.CloseWndByName("UIOutts")
		GF.CloseWndByName("UIOuttsList")
	end)
	seq:AppendInterval(0.6)
	seq:OnComplete(function()
		self._seqCom:DeleteSeq(key)
		self:WndClose()
	end)
	seq:PlayForward()
end


function UISowEffect:ShowDreamTripEffect()
	local spineName = "fx_slzt_zhuanchang"
	self._bookSpineKey = "DreamTripSpine"
	self:CreateWndEffect(self.mRoot,spineName,self._bookSpineKey,100,nil,nil
	,nil,function (dpTrans)
		self:DreamTripShowEnterTween()
	end)
end

function UISowEffect:ShowWonderlandEffect()
	self._bookSpineKey = "_bookSpineKey"
	local spineName = "Qijingtanxian_shu"
	self._waitCnt = 2
	self:DestroyWndSpineByKey(self._bookSpineKey)
	self:CreateWndSpine(self.mUpBookRoot,spineName,self._bookSpineKey,true,function (dpSpine)
		dpSpine:SetVisible(false)
		self:CheckShowEnterTween()
	end)
	local effKey = "roujie"
	self:DestroyWndEffectByKey(effKey)
	local effData =
	{
		trans = self.mBookEffRoot,
		effName = "fx_qjtx_rongjie",
		effKey = effKey,
		bDefaultSortNum = 11,
		endFunc = function(effect)
			effect:SetVisible(false)
			self:CheckShowEnterTween()
		end,
	}

	self:CreateWndEffect_Ex(effData)

end

------------------------------------------------------------------
return UISowEffect