---
--- Created by Administrator.
--- DateTime: 2024/6/7 11:36:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLand:LWnd
local UIPeWishLand = LxWndClass("UIPeWishLand", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLand:UIPeWishLand()
	self._collectTimeKey = "_collectTimeKey"
	self._cdTimeKey = "_cdTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLand:OnWndClose()
	FireEvent(EventNames.REFRESH_PDL_ENTER)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWishLand:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLand:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
	--- 2024/6/28：进入时，检查是否有结算弹窗
	gModelPetDreanLand:OpenPetDreamLandReportResult()

	if gModelPetDreanLand:DreamLandIsOpen() then
		gModelPetDreanLand:OnPetDreamLandRecordReq()
	end
	self._isJapaness  =gLGameLanguage:IsJapanVersion()
	--- 收集
	self._timeTransList = {}

	self:InitBtnList()
	self:RefreshBtnList()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
	self:StartCdTime()

	self:RegisterRedPointFunc(ModelRedPoint.PDT_NEW_REPORT_1,function(isShow)
		if LOG_INFO_ENABLED then
			local str = isShow and "显示 id ：" or "不显示 id ："
			printInfoNR2("红点显示打印 1：",">> " .. str .. " : " .. ModelRedPoint.PDT_NEW_REPORT_1)
		end
		CS.ShowObject(self.mBtnReportRP1,isShow)
	end)
	self:RegisterRedPointFunc(ModelRedPoint.PDT_NEW_REPORT_2,function(isShow)
		if LOG_INFO_ENABLED then
			local str = isShow and "显示 id ：" or "不显示 id ："
			printInfoNR2("红点显示打印 2：",">> " .. str .. ModelRedPoint.PDT_NEW_REPORT_2)
		end
		CS.ShowObject(self.mBtnReportRP2,isShow)
	end)
	self:RegisterRedPointFunc(ModelRedPoint.PDT_FREE_CALL,function(isShow)
		self:RefreshSignRP()
	end)
	self:RegisterRedPointFunc(ModelRedPoint.PDT_HAS_CALLNUM,function(isShow)
		self:RefreshSignRP()
	end)
    self:RefreshForeign()
end

--- 战报
function UIPeWishLand:OnClickBtnReport(data)
	if not self:CheckBtnIsOpen(data) then return end
	gModelPetDreanLand:OpenPetDreamLandReport()
end


function UIPeWishLand:GetDreamLandList()
	local list = {}
	local gameIsOpen = gModelPetDreanLand:DreamLandIsOpen()
	local refList = gModelPetDreanLand:GetInitPetDreamlandRef()
	for i,v in ipairs(refList) do
		table.insert(list,{
			ref = v,
			serData = gModelPetDreanLand:GetPetDreamLandDataByRefId(v.refId),
			gameIsOpen = gameIsOpen,
		})
	end
	return list
end

function UIPeWishLand:StartCdTime()
	self:StartCDTimer()
	self:TimerStop(self._cdTimeKey)
	self:TimerStart(self._cdTimeKey,1,false,-1)
end

--- 签订
function UIPeWishLand:OnClickBtnSign(data)
	if not self:CheckBtnIsOpen(data) then return end
	GF.OpenWnd("UIPeWishLandYell")
end

function UIPeWishLand:RefreshView()
	self:InitDreamLandList()
	self:StartRunCollectTimer()
end

function UIPeWishLand:InitBtnList()
	local btnList = {
		{
			parentRoot = self.mFormationDiv,
			btnRoot = self.mBtnFormation,
			btnName = ccClientText(43307),
			funcId = 0,
			clickFunc = function(data)
				self:OnClickBtnFormation(data)
			end
		},
		{
			parentRoot = self.mReportDiv,
			btnRoot = self.mBtnReport,
			btnName = ccClientText(43308),
			funcId = 0,
			clickFunc = function(data)
				self:OnClickBtnReport(data)
			end
		},
		{
			parentRoot = self.mRankDiv,
			btnRoot = self.mBtnRank,
			btnName = ccClientText(43309),
			funcId = 0,
			clickFunc = function(data)
				self:OnClickBtnRank(data)
			end
		},
		{
			parentRoot = self.mSignDiv,
			btnRoot = self.mBtnSign,
			btnName = ccClientText(43310),
			funcId = ModelFunctionOpen.PET_DLCALL,
			clickFunc = function(data)
				self:OnClickBtnSign(data)
			end
		},
	}
	self._btnList = btnList
end

function UIPeWishLand:InitDreamLandList()
	local list = self:GetDreamLandList()
	local uiList = self:FindUIScroll("mDreamLandList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mDreamLandList")
		uiList:Create(self.mDreamLandList, list, function(...) self:OnDrawDreamLandCell(...) end)
	end
	uiList:EnableScroll(true)
end

function UIPeWishLand:OnDrawDreamLandCell(list, item, itemdata, itempos)
	local CellBg = self:FindWndTrans(item,"CellBg")
	local Name = self:FindWndTrans(item,"NameBg/Name")

	local CollectBg = self:FindWndTrans(item,"CollectBg")
	local CollectTxt = self:FindWndTrans(CollectBg,"CollectTxt")

	local CellBotBg = self:FindWndTrans(item,"CellBotBg")
	local OutputDiv = self:FindWndTrans(CellBotBg,"OutputDiv")
	local OutputTxt = self:FindWndTrans(OutputDiv,"OutputTxt")
	local OutputItemList = self:FindWndTrans(OutputDiv,"OutputItemList")
	local PointInfoDesc = self:FindWndTrans(CellBotBg,"PointInfoDesc")

	local LockDiv = self:FindWndTrans(item,"LockDiv")

	self:SetWndText(OutputTxt,ccClientText(43402))

	local ref = itemdata.ref

	self:SetWndEasyImage(CellBg,ref.cell,function()
		CS.ShowObject(CellBg,true)
	end,true)

	self:SetWndText(Name,ccLngText(ref.name))
	self:InitOutputItemList(OutputItemList,ref.showRewardList)

	---@type StructPetDreamLandData
	local serData = itemdata.serData
	local pointNum = 0
	if serData then
		pointNum = serData:GetPointNum()
	end

	self._timeTransList[ref.refId] = {
		collectBgTrans = CollectBg,
		collectTxtTrans = CollectTxt,
	}

	local infoStr = ""
	local isLimit = ref.isLimit
	if isLimit then
		local loseNum = math.max(ref.num - pointNum,0)
		infoStr = string.replace(ccClientText(43305),loseNum)
	else
		infoStr = ccClientText(43306)
	end
	local pointInfoDesc = string.replace(ccClientText(43304),infoStr)
	self:SetWndText(PointInfoDesc,pointInfoDesc)

	local gameIsOpen = not itemdata.gameIsOpen
	CS.ShowObject(LockDiv,gameIsOpen)

	self:SetWndClick(item,function() self:OnClickDreamLandFunc(itemdata) end)
end

function UIPeWishLand:StartCollectTransTimer()
	for k,v in pairs(self._timeTransList) do
		local showCollectBg = false
		---@type StructPetDreamLandData
		local serData = gModelPetDreanLand:GetPetDreamLandDataByRefId(k)
		if serData and serData:CheckHasCollect() then
			local timeLeft = GetTimestamp() - serData:GetPlayerPointDataTime()
			if timeLeft > 0 then
				--local collectTimeStr = string.replace(ccClientText(43311),LUtil.FormatTimespanNumber(timeLeft))
				timeLeft = math.floor(timeLeft)
				--- 修改为 时分秒 的格式
				local collectTimeStr = string.replace(ccClientText(43311),LUtil.FormatTimeStr1(timeLeft))
				self:SetWndText(v.collectTxtTrans,collectTimeStr)
				showCollectBg = true
			end
		end
		CS.ShowObject(v.collectBgTrans,showCollectBg)
	end
end

function UIPeWishLand:InitMsg()
	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function (...) self:OnRefreshFunctionState() end)
	self:WndEventRecv(EventNames.PET_DL_POINT_REFRESH,function (...) self:OnPetDLPointRefresh() end)
	self:WndEventRecv(EventNames.HIDE_PET_REPORT1,function (...) self:OnEventPetREPORT1(...) end)
	self:WndEventRecv(EventNames.HIDE_PET_REPORT2,function (...) self:OnEventPetREPORT2(...) end)
	self:WndEventRecv(EventNames.REFRESH_PDL_REDPOINT,function (...) self:RefreshSignRP() end)
end

function UIPeWishLand:RefreshSignRP()
	local isShow = gModelRedPoint:CheckSingle(ModelRedPoint.PDT_FREE_CALL)
	if not isShow then
		isShow = gModelRedPoint:CheckSingle(ModelRedPoint.PDT_HAS_CALLNUM)
	end
	CS.ShowObject(self.mBtnSignRP,isShow)
end

--- 布阵
function UIPeWishLand:OnClickBtnFormation(data)
	if not self:CheckBtnIsOpen(data) then return end
	gModelGeneral:RecordGameState()
	gModelFormation:OpenPetDreamLandOnlySet({
		combatType = LCombatTypeConst.COMBAT_TYPE_41,
		setTargetType = LCombatTypeConst.COMBAT_TYPE_41,
		returnFunc = function()
			gModelGeneral:RecoverGameState()
		end,
	})
end

function UIPeWishLand:OnPetDLPointRefresh()
	self:RefreshSignRP()
	self._timeTransList = {}
	self:StartCdTime()
	self:RefreshView()
end

function UIPeWishLand:OnEventPetREPORT1(data)
	local showRP = data.showRP
	CS.ShowObject(self.mBtnReportRP1,showRP)
end

function UIPeWishLand:OnRefreshFunctionState()
	self:RefreshBtnList()
end

function UIPeWishLand:OnTimer(key)
	if key == self._collectTimeKey then
		self:StartCollectTransTimer()
	elseif key == self._cdTimeKey then
		self:StartCDTimer()
	end
end

function UIPeWishLand:CheckBtnIsOpen(data)
	if data.funcId and data.funcId > 0 then
		return gModelFunctionOpen:CheckIsOpened(data.funcId,true)
	end
	return true
end
function UIPeWishLand:RefreshForeign()
    if self._isVie then
        for i, v in ipairs(self._btnList) do
            local textTran = CS.FindTrans(v.btnRoot,"UIText")
            self:InitTextLineWithLanguage(textTran,0)
            LxUiHelper.SetSizeWithCurAnchor(textTran,0,80)
        end
    end


	if self._isJapaness then
		LxUiHelper.SetSizeWithCurAnchor(self.mCDBg,0,400)
		for i, v in ipairs(self._btnList) do
			local textTran = CS.FindTrans(v.btnRoot,"UIText")
			self:InitTextLineWithLanguage(textTran,-50)
			LxUiHelper.SetSizeWithCurAnchor(textTran,0,50)

			self:SetAnchorPos(v.btnRoot,Vector2.New(0,20))
		end
	end

end

function UIPeWishLand:OnClickDreamLandFunc(itemdata)
	if not itemdata.gameIsOpen then
		GF.ShowMessage(ccClientText(43403))
		return
	end
	local ref = itemdata.ref
	gModelPetDreanLand:OpenPetDreamLandMain(itemdata.serData,ref.refId)
end

function UIPeWishLand:InitData()
end

function UIPeWishLand:OnDrawOutputItemCell(list, item, itemdata, itempos)
	local IconDiv = self:FindWndTrans(item,"IconDiv")
	local Icon = self:FindWndTrans(IconDiv,"Icon")
	local Num = self:FindWndTrans(item,"Num")

	local icon = gModelItem:GetItemIconByRefId(itemdata.itemId)
	self:SetWndEasyImage(Icon,icon,function() CS.ShowObject(Icon,true) end,true)

	local numTxt = string.replace(ccClientText(43303),LUtil.NumberCoversion(itemdata.itemNum))
	self:SetWndText(Num,numTxt)
end

function UIPeWishLand:StartCDTimer()
	local timerStr = gModelPetDreanLand:GetDreamLandTimeStr()
	if gModelPetDreanLand:DreamLandIsOpen() then
		timerStr = string.replace(ccClientText(43301),timerStr)
	end
	self:SetWndText(self.mCDTxt,timerStr)
end

function UIPeWishLand:StartRunCollectTimer()
	self:TimerStop(self._collectTimeKey)
	self:TimerStart(self._collectTimeKey,1,false,-1)
end

function UIPeWishLand:InitText()
	self:SetWndText(self.mTitle,ccClientText(43300))
end

function UIPeWishLand:InitOutputItemList(listTrans,list)
	list = gModelPetDreanLand:AddBigFightIdAddRewardList(list)
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans,list,function(...) self:OnDrawOutputItemCell(...) end)
	end
end

function UIPeWishLand:OnEventPetREPORT2(data)
	local showRP = data.showRP
	CS.ShowObject(self.mBtnReportRP2,showRP)
end

--- 排行奖励
function UIPeWishLand:OnClickBtnRank(data)
	if not self:CheckBtnIsOpen(data) then return end

	--- 2024/9/29：那后端那边有做排行榜的数据，前端也可以让点开一下排行榜吧，没数据都是暂无上榜骑士也不影响
	--- 2024/10/11：萌宠的排行榜23点结算后，回滚点不开吧 服务端不好改
--[[	if not gModelPetDreanLand:DreamLandIsOpen() then
		GF.ShowMessage(ccClientText(43403))
		return
	end]]

	GF.OpenWndBottom("UIRkPop", { refIds = {
		ModelRank.RANK_511,ModelRank.RANK_512
	}})
end

function UIPeWishLand:RefreshBtnList()
	for i,v in ipairs(self._btnList) do
		local isOpen = true
		if v.funcId and v.funcId > 0 then
			isOpen = gModelFunctionOpen:CheckIsShow(v.funcId)
		end
		if isOpen and v.clickFunc then
			self:SetTextTile(v.btnRoot,v.btnName)
			self:SetWndClick(v.btnRoot,function()
				v.clickFunc(v)
			end)
		end
		CS.ShowObject(v.parentRoot,isOpen)
	end
end

function UIPeWishLand:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mBtnReturn,function()
		GF.OpenWndBottom("UIOutts",{ childIndex = 2 })
		FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnHelp,function() GF.OpenWnd("UIBzTips",{refId = 175}) end)
end

------------------------------------------------------------------
return UIPeWishLand