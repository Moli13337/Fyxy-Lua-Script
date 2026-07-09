---
--- Created by Administrator.
--- DateTime: 2023/10/12 11:22:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDTDNew:LWnd
local UIDTDNew = LxWndClass("UIDTDNew", LWnd)

local typeScrollRect = typeof(CS.ScrollRect)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDTDNew:UIDTDNew()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDTDNew:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDTDNew:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDTDNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitEvent()
	self:InitUIEvent()
	self:RefreshContent()
	self:RefreshReq()
end

function UIDTDNew:RefreshReq()
	local refList = gModelDungeonDaily:GetGameTypes()
	local list = {}
	for i, v in pairs(refList) do
		table.insert(list,v.refId)
	end
	gModelGeneral:OnDailyGameInfoReq(list)
end

function UIDTDNew:MoveContent(para)
	local scrollRect = self.mViewPort:GetComponent(typeScrollRect)
	if scrollRect then
		scrollRect.normalizedPosition = para
	end
	self:DelaySendFinish(0)
end

function UIDTDNew:OnTimer(key)
	if self._timerKey == key then
		self:SetTime()
	end
end

function UIDTDNew:SetStaticContent()
	self:CreateWndSpine(self.mSpine,"Shiguangxianjing","bgspine")
end

function UIDTDNew:InitEvent()
	self:WndNetMsgRecv(LProtoIds.DailyGameInfoResp,function (pb)
		self:OnDailyGameInfoResp(pb)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		self:RefreshReq()
	end)

	self:WndEventRecv(EventNames.ON_BATTLE_END,function()
		self:RefreshContent()
	end)

	self:WndEventRecv(EventNames.ON_ENDLESS_FIGHT_STATE,function ()
		self:RefreshContent()
	end)

	self:WndEventRecv(EventNames.DARK_SEASON_INFO_CHANGE,function ()
		self:RefreshContent()
	end)
end

function UIDTDNew:SetPlayItem(data)
	local item = data.item
	local root = self._tranMap[data.itempos]
	CS.SetParentTrans(item,root)

	local name = self:FindWndTrans(item,"name")
	local Image = self:FindWndTrans(item,"Image")
	local ImageText_1 = self:FindWndTrans(Image,"text_1")
	local lock = self:FindWndTrans(item,"lock")
	local fight = self:FindWndTrans(item,"fight")
	--local fightFight = self:FindWndTrans(fight,"fight")
	local introbg = self:FindWndTrans(item,"introbg")
	local introbgText2 = self:FindWndTrans(introbg,"text2")
	local text_3 = self:FindWndTrans(item,"text_3")
	--local tar = self:FindWndTrans(item,"tar")
	local ing = self:FindWndTrans(item,"ing")
	local ingIcon = self:FindWndTrans(ing,"icon")
	local ingText = self:FindWndTrans(ing,"text")



	local itemdata = data.itemdata
	local functionId = itemdata.functionId
	local isOpen = gModelFunctionOpen:CheckIsOpened(functionId,false)
	local iconPath = isOpen and itemdata.nameOn or itemdata.nameOff
	self:SetWndEasyImage(name,iconPath,nil,true)
	if not string.isempty(itemdata.titlePos) then
		local pos = LxDataHelper.ParseVector2NotEmpty(itemdata.titlePos)
		self:SetAnchorPos(name, pos)
	end
	local namePos = self._namePosList.common
	if gLGameLanguage:IsVietnamVersion() and data.itempos == 3 then
		namePos = self._namePosList.vie
	end
	self:SetAnchorPos(name, namePos)

	CS.ShowObject(Image,isOpen)
	CS.ShowObject(introbg,isOpen)
	CS.ShowObject(lock,not isOpen)

	local isFighting = gModelDungeonDaily:CheckIsInBattle(itemdata.refId)
	CS.ShowObject(fight,isFighting)

	if isOpen then
		local info =self._infoList and self._infoList[itemdata.refId]
		local timeStr = gModelDungeonDaily:GetResidueTimeByRefId(itemdata,info)
		local showTime = not string.isempty(timeStr)
		self:SetWndText(ImageText_1,timeStr)
		CS.ShowObject(Image,showTime)
		local text1Str = gModelDungeonDaily:GetText1ByRefId(itemdata,info)
		local text2Str = gModelDungeonDaily:GetText2ByRefId(itemdata,info)
		local showIntro =not string.isempty(text1Str)
		CS.ShowObject(introbg,showIntro)
		self:SetWndText(introbgText2,text1Str)
		self:SetWndText(text_3,text2Str)
		self:InitTextLineWithLanguage(text_3, -30)
	end

	self:SetWndClick(item,function ()
		self:OnClickPlay(itemdata)
	end)
	local showIng = false
	--if itemdata.refId == 105 then
	--	local selHero = gModelDreamTrip:IsSelHero()
	--	if selHero then
	--		local isEnd = gModelDreamTrip:IsEndMapIdx()
	--		if not isEnd and not isFighting then
	--			showIng = true
	--		end
	--	end
	--
	--	local seqCom = self:GetSeqCom()
	--	if showIng then
	--		self:SetWndText(ingText,ccClientText(13419) .. "...")
	--		local seq = seqCom:CreateSeq("ingTween")
	--		local defaultPos = ingIcon.localPosition
	--		local moveTween = ingIcon:DOLocalMove(defaultPos + Vector3.New(0,10,0),0.6)
	--		seq:Append(moveTween)
	--		local moveTween = ingIcon:DOLocalMove(defaultPos,0.6)
	--		seq:Append(moveTween)
	--		seq:SetLoops(-1)
	--		seq:OnKill(function ()
	--			ingIcon.localPosition = defaultPos
	--		end)
	--		seq:PlayForward()
	--	else
	--		seqCom:DeleteSeq("ingTween")
	--	end
	--end


	CS.ShowObject(ing,showIng)
end


function UIDTDNew:RefreshContent()
    local refList = gModelDungeonDaily:GetGameTypes()
    self._itemRecord = self._itemRecord or {}

    for k,v in ipairs(refList) do
        local data = self._itemRecord[k]
        if not data then
            local obj = self._playPool:GetObj()
            local timeText = self:FindWndTrans(obj.transform,"Image/text_1")
            data = {item= obj.transform,itemdata = v,itempos = k,timeText = timeText}
        end

        local itemdata = data.itemdata
        local functionId = itemdata.functionId
        local ref = gModelFunctionOpen:GetFunctionOpenCfg(functionId)
        local isOpen = gModelFunctionOpen:CheckIsOpened(functionId)
        local show = ref.show == 1
        if show and isOpen then
            self._itemRecord[k] = data
            self:SetPlayItem(data)
        end
    end

    self:TimerStop(self._timerKey)
    self:TimerStart(self._timerKey,1,false,-1)
end

function UIDTDNew:OnDailyGameInfoResp(pb)
	self._infoList = gModelGeneral:GetDailyGameInfoResp(pb)
	self:RefreshContent()
end

function UIDTDNew:InitUIEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndCloseAndBack() end)

end

function UIDTDNew:OnClickPlay(itemdata)
	--if true then
	--	GF.OpenWnd("UIDreamKillWin")
	--	self:WndClose()
	--	return
	--end
	-- if itemdata.refId == 107 then
	-- 	gModelRedPoint:SetRedPointClicked(ModelRedPoint.INVASION_EVENT)
	-- end

	local functionId = itemdata.functionId
	if not gModelFunctionOpen:CheckIsOpened(functionId,true) then
		return
	end

	local isFighting,combatType = gModelDungeonDaily:CheckIsInBattle(itemdata.refId)

	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_PLAY,itemdata.refId)

	if combatType and combatType > 0 then
		gLFightManager:PrepareGoToBattle(combatType,{})
	else
		if itemdata.refId == 104 then -- 奇境探险
			gModelGeneral:WonderlandEntrance()
			self:WndClose()
		elseif itemdata.refId == 105 then --梦境之旅
			gModelDreamTrip:GoToMap(function()
				GF.CloseWndByName("UIDTDNew")
			end)
		else
			gModelFunctionOpen:Jump(functionId,self:GetWndName())
		end
	end
end

function UIDTDNew:InitData()
	self._playPool = UIObjPool:New()
	self._playPool:Create(self.mUnuse,self.mTemplate)
	self._timerKey = "timerKey"

	self._tranMap =
	{
		[1] = self.mPos_1,
		[2] = self.mPos_2,
		[3] = self.mPos_3,
		[4] = self.mPos_4,
		[5] = self.mPos_5,
		[6] = self.mPos_6,
		[7] = self.mPos_7,
		[8] = self.mPos_8,
		[9] = self.mPos_9,
	}

	self._namePosList = {
		common = Vector2.New(0, -18),
		vie    = Vector2.New(40, -18),
	}
end

function UIDTDNew:SetTime()
	for i, v in pairs(self._itemRecord) do
		local isOpen = gModelFunctionOpen:CheckIsOpened(v.itemdata.functionId,false)
		if isOpen then
			local info = self._infoList and self._infoList[v.itemdata.refId]
			local timeStr =gModelDungeonDaily:GetResidueTimeByRefId(v.itemdata,info)
			self:SetWndText(v.timeText,timeStr)
		end
	end
end

------------------------------------------------------------------
return UIDTDNew