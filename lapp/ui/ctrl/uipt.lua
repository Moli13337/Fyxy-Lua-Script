---
--- Created by Administrator.
--- DateTime: 2023/10/17 15:29:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPt:LWnd
local UIPt = LxWndClass("UIPt", LWnd)



------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPt:UIPt()


end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPt:OnWndClose()
	FireEvent(EventNames.HIDE_WND_BY_PLOT,false)

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPt:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPt:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	
	self:SetStaticContent()

	self:InitData()
	self:OnWndRefresh()
	self:InitUIEvent()


	FireEvent(EventNames.HIDE_WND_BY_PLOT,true)
end

function UIPt:DrawRole(cfg)
	local paint = cfg.paint
	local action = cfg.action
	local direction = cfg.direction


	--local index = self:GetIndexByDirection(direction)

	local isLeft  = direction==0
	local spineKey =isLeft and "leftRole" or "rightRole"

	local spineName = self._spineNameList[spineKey]
	local effRoot = isLeft and self.mLeftEff or self.mRightEff
	local roleRoot = isLeft and self.mLeftRole or self.mRightRole

	if paint == spineName then
		local spine = self:FindWndSpineByKey(spineKey)
		if spine then
			self:ModifySpineColorAndPos(direction)
			if action>0 then
				self:PlayAction(action,spine,effRoot,direction)
			end
		end


	else
		self:ClearEffectTime(direction)
		self:DestroyWndSpineByKey(spineKey)

		self._spineNameList[spineKey] = paint

		self:CreateWndSpine(roleRoot,paint,spineKey,false,function(spine)
			self:ModifySpineColorAndPos(direction)
			spine:SetFlipX(not isLeft)
			if action==0 then
				return
			end
			self:PlayAction(action,spine,effRoot,direction)

		end)

	end





end

function UIPt:ModifySpineColorAndPos(direction)
	local keyList= {
		{key = "leftRole", rootTrans = self.mLeftRoot},
		{key = "rightRole", rootTrans = self.mRightRoot},
	}
	local curIndex = self:GetIndexByDirection(direction)

	for k,v in pairs(keyList) do
		local color = nil
		local pos	= nil
		if curIndex == k then
			color = Color.New(1,1,1,1)
			pos	  = Vector3.New(0, -146, 0)
		else
			color = Color.New(0.4,0.4,0.4,1)
			pos	  = Vector3.New(0, -200, 0)
		end
		local spine = self:FindWndSpineByKey(v.key)
		if spine then
			spine:SetColor(color)
		end
		v.rootTrans.localPosition = pos
	end
end

function UIPt:RefreshUI()
	local cfg = gModelPlot:GetPlotCfg(self._plotId)
	if not cfg then
		LogError("UIPt:RefreshUI()  cfg is nil! plotId = "..tostring(self._plotId or 0))
		return
	end
	local sound = cfg.get_soundP and cfg.soundP or nil
	if not string.isempty(sound) then
		gLGameAudio:PlaySingleSound(sound)
	end
	local selectList = gModelPlot:GetSelectList(self._plotId)
	local showPop = true
	if not selectList then
		showPop = false
	end

	CS.ShowObject(self.mRoot, not showPop)
	CS.ShowObject(self.mCommonBg_4, not showPop)
	CS.ShowObject(self.mTypeThree, not showPop)
	CS.ShowObject(self.mSkipBtn, not showPop)
	CS.ShowObject(self.mPop,showPop)
	if showPop then
		local itemList = self:GetUIScroll("selectList")
		itemList:Create(self.mChooseList,selectList,function (...) self:OnDrawSelect(...)  end)
	end

	self._isPop = showPop

	if showPop then
		return
	end
	table.insert(self._plotList,1,cfg)
	if #self._plotList>4 then
		table.remove(self._plotList)
	end
	self:InitPlotList()
	self:DrawRole(cfg)

	local delayTime =gModelPlot:GetPara("plotJump")
	self:TimerStop(self._delayTimer)
	self:TimerStart(self._delayTimer,delayTime,false,1)


end

function UIPt:SetFadeColor(tran)
	local xuitxt = self:FindWndText(tran)
	local color = xuitxt.color
	local fadeColor = Color.New(color.r,color.g,color.b,0.5)
	self:SetXUITextColor(xuitxt,fadeColor)
end

function UIPt:GetIndexByDirection(dire)
	local isLeft  = dire==0
	return isLeft and 1 or 2
end

function UIPt:OnWndRefresh()
	self:SetPara()
	self:RefreshUI()
end


function UIPt:PlayAction(refId,spine,effRoot,direction)
	self:ClearEffectTime(direction)

	local skillExpRef = GameTable.SnakeSkillExpressionRef[refId]
	if not skillExpRef then
		LogError("no skillexpid "..refId)
		return
	end

	local panelPlayEff = skillExpRef.panelPlayEff
	if string.isempty(panelPlayEff) then
		return
	end
	local arrPlayEffId = string.split(panelPlayEff,"|")
	local playList = {}
	local effectList ={}
	for k,strId in ipairs(arrPlayEffId) do
		local arrPlayRefId = tonumber(strId)
		local skillVfxRef = GameTable.SnakeSkillVfxRef[arrPlayRefId]
		local delayTime = skillVfxRef.delayTime
		local playTime = skillVfxRef.playTime
		local effectType = skillVfxRef.effType
		local effectRes = skillVfxRef.effRes
		local data = {
			refId = arrPlayRefId,
			effType = effectType,
			effRef = effectRes,
			delayTime = delayTime,
			playTime = playTime,
			uiHierarchy = skillVfxRef.UiHierarchy
		}

		if effectType ~=2 then
			table.insert(effectList,effectRes)
		end
		table.insert(playList,data)
	end

	local index = self:GetIndexByDirection(direction)
	self._effectLists[index] = effectList

	local maxTime = 0
	for i,v in ipairs(playList) do
		v.isPlay = false
		maxTime = math.max(maxTime,v.playTime)
	end
	table.sort(playList,function(eff1,eff2)
		return eff1.delayTime < eff2.delayTime
	end)

	local starTime

	local timer = LxTimer.LoopTimeCall(function()
		if starTime == nil then
			starTime = Time.time
		end
		for i,v in ipairs(playList) do
			local time = Time.time
			local tempTime = time - starTime
			if tempTime >= v.delayTime and (not v.isPlay) then
				v.isPlay = true
				--printInfoN("=========== effRef,refId,uiHierarchy = ",v.effRef,v.refId,v.uiHierarchy)
				if v.effType == 2 then
					spine:PlayAnimation(0,v.effRef,false)
				else
					if v.uiHierarchy == 1 then
						self:CreateWndEffect(effRoot,v.effRef,v.effRef,100,false,false,0)
					else
						self:CreateWndEffect(effRoot,v.effRef,v.effRef,100,false,false,3)
					end
				end
			end
			if tempTime > maxTime then
				self:ClearEffectTime(direction)
			end
		end
	end,0,false,-1)

	self._playTimers[index] = timer
end

function UIPt:OnSelect(itemdata,item)
	local select = self:FindWndTrans(item,"select")
	CS.ShowObject(select,false)

	local nextId = itemdata.next
	gModelPlot:NextSelectPlot(nextId)
end

function UIPt:OnDrawSelect(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local select = self:FindWndTrans(item,"select")
	local intro = self:FindWndTrans(item,"intro")

	CS.ShowObject(select,false)
	self:SetWndText(intro,itemdata.buttonStr)
	self:SetWndClick(item,function () self:OnSelect(itemdata,item) end)
end

function UIPt:InitPlotList()
	local list = self:GetUIScroll("plotList")
	list:Create(self.mTextList,self._plotList,function (...) self:OnDrawPlot(...)  end)
end

function UIPt:ClearEffectTime(direction)
	local index = self:GetIndexByDirection(direction)
	local timer = self._playTimers[index]
	if timer then
		LxTimer.LoopTimeStop(timer)
		self._playTimers[index] = nil
	end



	local effectList = self._effectLists[index]
	if effectList then
		for k,v in pairs(effectList) do
			self:DestroyWndEffectByKey(v)
		end
		self._effectLists[index] = nil
	end

	local isLeft  = direction==0
	local spineKey =isLeft and "leftRole" or "rightRole"
	--local spineKey = self._spineKeyList[index]
	if not spineKey then
		return
	end
	local spine = self:FindWndSpineByKey(spineKey)
	if spine then spine:PlayAnimation(0,"idle",true) end

end


function UIPt:OnDestroy()
	if self._playTimers then
		for k,v in pairs(self._playTimers) do
			LxTimer.LoopTimeStop(v)
		end
		self._playTimers = nil
	end


	LWnd.OnDestroy(self)
end

function UIPt:SetStaticContent()
	self:SetWndText(self.mTitle,ccClientText(16764))
end

function UIPt:SetPara()
	self._plotId = self:GetWndArg("plotId")
end

function UIPt:InitUIEvent()
	self:SetWndClick(self.mSkipBtn,function () gModelPlot:OnPlotComplete(true)  end)
	self:SetWndClick(self.mMask,function ()
		if self._isPop then
			return
		end
		gModelPlot:NextPlot()
	end)
end

function UIPt:OnTimer(key)
	if key == self._delayTimer then
		if not self._isPop then
			gModelPlot:NextPlot()
		end
	end
end

function UIPt:InitData()
	self._plotList ={}
	self._spineNameList ={}
	self._delayTimer = "_delayTimer"

	self._playTimers={}

	self._effectLists={}

end

function UIPt:OnDrawPlot(list,item,itemdata,itempos)
	local bg = self:FindWndTrans(item,"bg")
	local leftTitle = self:FindWndTrans(item,"leftTitle")
	local rightTitle = self:FindWndTrans(item,"rightTitle")
	local content = self:FindWndTrans(item,"content")

	local dire = itemdata.direction
	local state = itempos==1 and 1 or 0
	local scale = Vector3.New(1,1,1)
	if dire==0 and state== 1 then
		scale = Vector3.New(-1,1,1)
	elseif dire ==1 and state == 0 then
		scale = Vector3.New(-1,1,1)
	end
	bg.localScale = scale
	self:SetImageActorState(bg,state)



	local showLeft = dire ==0
	CS.ShowObject(leftTitle,showLeft)
	CS.ShowObject(rightTitle,not showLeft)
	local textTran = showLeft and leftTitle or rightTitle
	local str = ccLngText(itemdata.name)
	self:SetWndText(textTran,str)


	local refId = itemdata.refId
	str = gModelPlot:GetRolePlotText(refId) --ccLngText(itemdata.txt)

	local t = {
		["a1"] = gModelPlayer:GetPlayerName()
	}

	str = string.gsub(str,"#(%w+)#",t)
	self:SetWndText(content,str)

	local isFade = itempos~=1
	if isFade then
		self:SetFadeColor(leftTitle)
		self:SetFadeColor(rightTitle)
		self:SetFadeColor(content)
	end
end

------------------------------------------------------------------
return UIPt


