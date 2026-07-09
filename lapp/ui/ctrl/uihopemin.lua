---
--- Created by LCM.
--- DateTime: 2024/3/24 11:56:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeMin:LWnd
local UIHopeMin = LxWndClass("UIHopeMin", LWnd)

UIHopeMin.BTN_SHOP = 1
UIHopeMin.BTN_PH = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeMin:UIHopeMin()
	self._countDownKey = "_countDownKey"
	self:SetHideHurdle()
	self:SetHideTop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeMin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeMin:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeMin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitBtnList()
	self:InitTopRightBtnList()
	self:RefreshView()

	self:SetSecretJumpBtn(self.mBtnSecret,2)
end

function UIHopeMin:OpenDreamHelpWnd()
	GF.OpenWnd("UIBzTips",{refId = 77})
end

function UIHopeMin:OpenDreamTripRank()
	GF.OpenWndBottom("UIRkPop",{refId = 1400,showRankType = 1})
end
------------------------- List -------------------------
function UIHopeMin:GetTopRightBtnList()
	return self._btnInfoList
end

function UIHopeMin:OnTimer(key)
	if key == self._countDownKey then
		self:OnRunCountDownTimer()
	end
end

function UIHopeMin:InitBtnList()
	local mapRef = GameTable.SailingMapRef
	local btnInfoList = {
		{
			root = self.mBtn1,
			extraData = {
				configRef = mapRef[2],
			}
		},
		{
			root = self.mBtn2,
			extraData = {
				configRef = mapRef[1],
			}
		},
		{
			root = self.mBtn3,
			extraData = {
				configRef = mapRef[3],
			}
		},
	}


	local refIdNextList = {}
	local extraData,configRef
	local initBtnTransList = {}
	for i,v in ipairs(btnInfoList) do
		extraData = v.extraData
		configRef = extraData.configRef

		if configRef then
			local themeRefId = configRef.themeRefId
			local refId = configRef.refId
			refIdNextList[themeRefId] = refId
		end

		local btnTransInfo = self:InitBtnInfo(v)
		table.insert(initBtnTransList,btnTransInfo)
	end
	self._refIdNextList = refIdNextList
	self._initBtnTransList = initBtnTransList
end

function UIHopeMin:RefreshView()
	self:CreateCoundDown()

	local initBtnTransList = self._initBtnTransList
	if not initBtnTransList then return end

	local mapRefId = self._mapRefId or {}
	local mapRefIdKey = self._mapRefIdKey or {}
	local len = #mapRefId
	local isNotOpen = len < 1
	for i,v in ipairs(initBtnTransList) do
		local extraData = v.extraData
		local configRef = extraData.configRef
		local showIntoBtn = configRef ~= nil
		if showIntoBtn then
			local showBtn = false
			local showLock = false
			if configRef then
				local refId = configRef.refId
				local open = configRef.open
				local isOpenTheme = open == 1
				if isOpenTheme then
					if isNotOpen then
						local themeRefId = configRef.themeRefId
						if themeRefId == -1 then
							showBtn = true
						else
							showLock = true
						end
					else
						local isOpen = mapRefIdKey[refId]
						if not isOpen then
							--- 当前关卡没通过，判断上一关卡是否通过
							local themeRefId = configRef.themeRefId
							local beforeIsOpen = mapRefIdKey[themeRefId]
							if beforeIsOpen then
								isOpen = true
							end
						end
						if isOpen then
							local functionOpen = gModelFunctionOpen:CheckIsOpened(configRef.themeOpen)
							if functionOpen then
								showBtn = true
							else
								showLock = true
							end
						else
							showLock = true
						end
					end
				else
					showLock = true
				end
			else
				showLock = true
			end
			CS.ShowObject(v.BtnTrans,showBtn)
			CS.ShowObject(v.GoBtnTrans,showBtn)
			CS.ShowObject(v.LockImgTrans,showLock)
			CS.ShowObject(v.LockBtnTrans,showLock)
		end
		CS.ShowObject(v.RootTrans,showIntoBtn)
	end
end

function UIHopeMin:OnRunCountDownTimer()
	local endTime = gModelDreamTrip:GetCountDownTime()
	if not endTime then
		self:SetWndText(self.mCountDown,"")
		self:TimerStop(self._countDownKey)
		return
	end
	endTime = tonumber(endTime)/1000
	local timeLeft = endTime - GetTimestamp()
	if timeLeft < 0 then
		self:TimerStop(self._countDownKey)
		return
	end
	local timeStr = LUtil.FormatTimespanNumber(timeLeft)
	timeStr = LUtil.FormatColorStr(timeStr,"lightGreen")
	local str = ccClientText(16702) --"%s  后重置奇境"
	str = string.replace(str,timeStr)
	self:SetWndText(self.mCountDown,str)
end

function UIHopeMin:InitTopRightBtnList()
	local list = self:GetTopRightBtnList()
	local uiBtnList = self._uiBtnList
	if uiBtnList then
		uiBtnList:RefreshList(list)
	else
		uiBtnList = self:GetUIScroll("uiBtnList")
		self._uiBtnList = uiBtnList
		uiBtnList:Create(self.mBtnList,list,function(...) self:OnDrawBtnCell(...) end)
	end
end

function UIHopeMin:InitMsg()
	 self:WndNetMsgRecv(LProtoIds.DreamTripSelectMapResp,function(pb) self:OnDreamTripSelectMapResp(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIHopeMin:InitBtnInfo(transInfo)
	local root = transInfo.root
	local TitleImgTrans = self:FindWndTrans(root,"TitleImg")
	local LockImgTrans = self:FindWndTrans(root,"LockImg")
	local LockBtnTrans = self:FindWndTrans(root,"LockBtn")
	local BtnTrans = self:FindWndTrans(root,"Btn")
	local GoBtnTrans = self:FindWndTrans(root,"GoBtn")

	local extraData = transInfo.extraData
	self:SetWndClick(LockImgTrans,function()
		self:OnClickLockBtnFunc(extraData)
	end)
	self:SetWndClick(LockBtnTrans,function()
		self:OnClickLockBtnFunc(extraData)
	end)


	self:SetWndButtonText(BtnTrans,ccClientText(20498))
	self:SetWndClick(BtnTrans,function()
		self:OnClickBtnFunc(extraData)
	end)
	self:SetWndClick(GoBtnTrans,function()
		self:OnClickBtnFunc(extraData)
	end)

	return {
		RootTrans = root,
		TitleImgTrans = TitleImgTrans,
		LockImgTrans = LockImgTrans,
		LockBtnTrans = LockBtnTrans,
		BtnTrans = BtnTrans,
		GoBtnTrans = GoBtnTrans,
		extraData = extraData,
	}
end

function UIHopeMin:CreateCoundDown()
	self:OnRunCountDownTimer()
	local endTime = gModelDreamTrip:GetCountDownTime()
	if endTime then
		endTime = tonumber(endTime)/1000
		if endTime > GetTimestamp() then
			self:TimerStop(self._countDownKey)
			self:TimerStart(self._countDownKey,1,false,-1)
		end
	end
end

function UIHopeMin:InitEvent()
	self:SetWndClick(self.mHelpBtn,function() self:OpenDreamHelpWnd() end)
    self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeMin:GetNextMapRefId(mapId)
	--- 没有传参数的默认是未解锁地图
	mapId = mapId or -1
	return self._refIdNextList[mapId]
end

function UIHopeMin:OnDreamTripSelectMapResp(pb)
	gModelDreamTrip:GoToMap(self._func)
	self:WndClose()
end

function UIHopeMin:InitData()
	self._func = self:GetWndArg("func")
	local mapRefId = gModelDreamTrip:GetMapRefIdList()
	local mapRefIdKey = gModelDreamTrip:GetMapRefIdKeyList()
	self._mapRefId = mapRefId or {}
	self._mapRefIdKey = mapRefIdKey or {}


	self._btnInfoList = {
		{
			btnImg = "wonderland_icon_btn_1",
			btnName = ccClientText(20487),
			index = UIHopeMin.BTN_SHOP,
			func = function() self:OpenDreamTripShop() end,
		},
	}

--[[	if gModelFunctionOpen:CheckIsShow(17100100) then
		local randBtnInfo =
		{
			btnImg = "timecopy_icon_4",
			btnName = ccClientText(20404),
			index = UIHopeMin.BTN_PH,
			func = function() self:OpenDreamTripRank() end,
		}
		table.insert(self._btnInfoList, randBtnInfo)
	end]]


end

function UIHopeMin:OnClickLockBtnFunc(extraData)
	if not extraData then return end
	local configRef = extraData.configRef
	if not configRef then return end

	local open = configRef.open
	local isOpenTheme = open == 1
	if isOpenTheme then
		local isOpen = self:IsOpen(configRef)
		if not isOpen then
			local functionOpen = gModelFunctionOpen:CheckIsOpened(configRef.themeOpen,true)
			if not functionOpen then
				return
			end
			local themeRefId = configRef.themeRefId
			if themeRefId then
				local ref = gModelDreamTrip:GetMapRefByMapId(themeRefId)
				if ref then
					--local str = string.format("通关%s后解锁主题",ccLngText(ref.name))
					local str = string.replace(ccClientText(20497),ccLngText(ref.name))
					GF.ShowMessage(str)
				end
			end
			return
		end
	else
		GF.ShowMessage(ccClientText(10131))
	end
end

function UIHopeMin:OnDrawBtnCell(list,item,itemdata,itempos)
	local Image = self:FindWndTrans(item,"Image")
	local icon = self:FindWndTrans(item,"icon")
	local UIText = self:FindWndTrans(item,"UIText")
	--local redPoint = self:FindWndTrans(item,"redPoint")
	if Image then
		self:SetWndClick(Image,function()
			local func = itemdata.func
			if func then func() end
		end)
	end
	if icon then
		self:SetWndEasyImage(icon,itemdata.btnImg)
	end
	if UIText then
		self:SetWndText(UIText,itemdata.btnName)
	end
--[[	if redPoint then
		local show = false
		CS.ShowObject(redPoint,show)
	end]]
end

function UIHopeMin:IsOpen(configRef)
	local mapRefIdKey = self._mapRefIdKey
	local refId = configRef.refId
	return mapRefIdKey[refId] ~= nil
end

function UIHopeMin:OnClickBtnFunc(extraData)
	if not extraData then return end
	local configRef = extraData.configRef
	local refId = configRef.refId
	if ModelDreamTrip.SELMAP_STATUS == 0 then
		gModelDreamTrip:OnDreamTripSelectMapReq(refId)
	elseif ModelDreamTrip.SELMAP_STATUS == 1 then
		GF.OpenWnd("UIHopeSelSaga",{
			mapRefId = refId
		})
	end
end

function UIHopeMin:OpenDreamTripShop()
	GF.OpenWnd("UIDian",{shopId = 2013})
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeMin



