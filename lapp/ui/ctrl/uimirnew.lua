---
--- Created by LCM.
--- DateTime: 2024/3/9 21:03:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMirNew:LWnd
local UIMirNew = LxWndClass("UIMirNew", LWnd)
------------------------------------------------------------------

local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

local _ChildWndDefine = {}
_ChildWndDefine.MirrorCall = 1
_ChildWndDefine.HeartCall = 2
_ChildWndDefine.TimeTreasure = 3
_ChildWndDefine.TreaFindNew = 4

--- 圣物
_ChildWndDefine.HalidomCall = 5

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMirNew:UIMirNew()
	---@type UIBtnTabList
	self._uiBtnTabList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMirNew:OnWndClose()
	-- FireEvent(EventNames.ON_HOROSCOPE_JOIN)
	if self._uiBtnTabList then
		self._uiBtnTabList:Destroy()
		self._uiBtnTabList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMirNew:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMirNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	self._isVie = gLGameLanguage:IsForeignVersion()
	self:InitCommonData()
	self:InitEvent()
	self:InitMsg()

	self:SetTextTile(self.mReturnBtn,ccClientText(30205))
	self:SetWndText(self.mTxtClose,ccClientText(30205))

	self:OnWndRefresh()
	
	self:RefreshForeign()
end

function UIMirNew:InitCallBtnTransInfo()
	local dataList = {
		{
			btnType = _ChildWndDefine.MirrorCall,
			btnTrans = self.mBtnMirrorCall,
			btnName = ccClientText(11668),
			functionId = 0,
			offIcon = "callhero_tab1",
			onIcon = "callhero_tab1",
			index = 1,
			clickFunc = function()
				self:ChangePage(_ChildWndDefine.MirrorCall)
			end,
			specialReduceSize = -4,
		},
		{
			btnType = _ChildWndDefine.HeartCall,
			btnTrans = self.mBtnHeartCall,
			btnName = ccClientText(11669),
			functionId = 15600001,
			offIcon = "callhero_tab2",
			onIcon = "callhero_tab2",
			index = 2,
			clickFunc = function()
				self:ChangePage(_ChildWndDefine.HeartCall)
			end,
			specialReduceSize = -4,
		},
		{
			btnType = _ChildWndDefine.TimeTreasure,
			btnTrans = self.mBtnTimeTreasure,
			btnName = ccClientText(11670),
			functionId = 15700001,
			offIcon = "callhero_tab3",
			onIcon = "callhero_tab3",
			index = 3,
			clickFunc = function()
				self:ChangePage(_ChildWndDefine.TimeTreasure)
			end,
			specialReduceSize = -4,
		},
		{
			btnType = _ChildWndDefine.HalidomCall,
			btnTrans = self.mBtnHalidom,
			btnName = ccClientText(41537),
			functionId = ModelFunctionOpen.HalidomDraw,
			offIcon = "callhero_tab4",
			onIcon = "callhero_tab4",
			index = 4,
			clickFunc = function()
				self:ChangePage(_ChildWndDefine.HalidomCall)
			end,
			checkRPFunc = function()
				local showRP = gModelRedPoint:CheckSingle(ModelRedPoint.RP_HALIDOM_34000001)
				if not showRP then
					showRP = gModelRedPoint:CheckSingle(ModelRedPoint.RP_HALIDOM_34000002)
					if not showRP then
						showRP = gModelRedPoint:CheckSingle(ModelRedPoint.RP_HALIDOM_34000003)
						if not showRP then
							showRP = gModelRedPoint:CheckSingle(ModelRedPoint.RP_HALIDOM_34000004)
						end
					end
				end
				return showRP
			end,
			specialReduceSize = -4,
		},
		--{
		--	btnType = _ChildWndDefine.TreaFindNew,
		--	btnName = ccClientText(11671),
		--	functionId = 15800001,
		--	clickFunc = function()
		--		self:ChangePage(_ChildWndDefine.TreaFindNew)
		--	end,
		--},
	}

	--table.sort(dataList,function(a,b)
	--	return a.index < b.index
	--end)
	--table.sort(dataList,function(a,b)
	--	return a.btnType > b.btnType
	--end)

	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
	--self._uiBtnTabList:SetData(self,self.mTabScroll,dataList,self._page,true)
	self._uiBtnTabList:SetBtnInfoData(self,self.mBtnList,dataList,self._page,true)
end

function UIMirNew:GetCallBtnTransInfo(transInfo,page)
	local trans = transInfo.btnTrans

	local NoSelIconTrans = self:FindWndTrans(trans,"NoSelIcon")
	local NoSelTxtTrans = self:FindWndTrans(NoSelIconTrans,"NoSelTxt")

	local SelBgTrans = self:FindWndTrans(trans,"SelBg")
	local SelIconTrans = self:FindWndTrans(SelBgTrans,"SelIcon")
	local SelTxtTrans = self:FindWndTrans(SelBgTrans,"SelTxt")

	local LockTrans = self:FindWndTrans(trans,"Lock")
	local LockTxtTrans = self:FindWndTrans(LockTrans,"LockTxt")

	local btnName = transInfo.btnName
	self:SetWndText(NoSelTxtTrans,btnName)
	self:InitTextLineWithLanguage(NoSelTxtTrans,-30)
	self:SetWndText(SelTxtTrans,btnName)
	self:InitTextLineWithLanguage(SelTxtTrans,-30)
	self:SetWndText(LockTxtTrans,btnName)
	self:InitTextLineWithLanguage(LockTxtTrans,-30)



	CS.ShowObject(SelIconTrans,true)
	CS.ShowObject(SelTxtTrans,true)

	self:SetWndClick(trans,function()
		self:ChangePage(page)
	end)

	return {
		btnTrans = trans,
		selBgTrans = SelBgTrans,
		noSelIconTrans = NoSelIconTrans,
		selIconTrans = SelIconTrans,
		noSelTxtTrans = NoSelTxtTrans,
		selTxtTrans = SelTxtTrans,
		lockTrans = LockTrans,
		page = page,
		functionId = transInfo.functionId,
	}
end

function UIMirNew:ShowContent()
	local page = self._page
	if not page then
		page = _ChildWndDefine.MirrorCall
	end
	self:RefreshBottomBtnShow()
	local btnFunc = self._btnFuncList[page]
	if btnFunc then
		btnFunc()
	end
end

function UIMirNew:RefreshForeign()
	if self._isVie then
		self:SetBtnTextWidthWithLanguage(self.mBtnMirrorCall,80)
		self:SetBtnTextWidthWithLanguage(self.mBtnHeartCall,80)
		self:SetBtnTextWidthWithLanguage(self.mBtnTimeTreasure,120)
		self:SetBtnTextWidthWithLanguage(self.mBtnHalidom,90)
	end
end

function UIMirNew:SetBtnTextWidthWithLanguage(tran,size)
	local offText = CS.FindTrans(tran,"Off/Text")
	local onText = CS.FindTrans(tran,"On/Text")
	local grayText = CS.FindTrans(tran,"Gray/Text")

	LxUiHelper.SetSizeWithCurAnchor(offText,0,size)
	LxUiHelper.SetSizeWithCurAnchor(onText,0,size)
	LxUiHelper.SetSizeWithCurAnchor(grayText,0,size)

	LxUiHelper.SetTextFontSize(trans,30)
	local uiText =LxUiHelper.FindXTextCtrl(offText)
	uiText.characterSpacing =3
	uiText =LxUiHelper.FindXTextCtrl(onText)
	uiText.characterSpacing =3
	uiText =LxUiHelper.FindXTextCtrl(grayText)
	uiText.characterSpacing =3
end

function UIMirNew:OnClickTimeCallBtnFunc()
end

function UIMirNew:OnClickTreasureCallBtnFunc()
end

function UIMirNew:OnClickMirrorCallBtnFunc()
end

function UIMirNew:CheckIsClickCity()
	-- if self._isCityClick and self._page == 1 then
	-- 	local callRefId = ModelActivity.LIMIT_CALL
	-- 	local activityDataList = gModelActivity:GetActivityDataByModelId(callRefId,ModelActivity.STATUS_VALID)
	-- 	if #activityDataList > 0 then
	-- 		self._activityCallRefId = callRefId
	-- 	end
	-- end
	self._isCityClick = false
end

function UIMirNew:InitData()
	self._page = self:GetWndArg("page") or _ChildWndDefine.MirrorCall
	self._subPage = self:GetWndArg("subPage") or 1
	self._sid = self:GetWndArg("sid")
	self._functionId = self:GetWndArg("functionId")
	self._isCityClick = self:GetWndArg("isCityClick")
	self._uiBtnTabList:SetCurSel(self._page)
end

--跳转需要特殊表现
function UIMirNew:SetWndShowByJump()
	if self._functionId and self._functionId == 50000020 then
		CS.ShowObject(self.mCallList,false)
	end
end

function UIMirNew:OnClickHeartCallBtnFunc()
end

function UIMirNew:InitCommonData()
	self._btnFuncList = {
		[_ChildWndDefine.MirrorCall] = function()
			-- 打开魔镜召唤
			self:CreateChildWnd(self.mChildRoot,"UISubMirrorYell",{page = self._page,subPage = self._subPage,sid = self._sid,functionId = self._functionId,activityCallRefId = self._activityCallRefId})
		end,
		[_ChildWndDefine.HeartCall] = function()
			-- 打开心灵召唤
			self:CreateChildWnd(self.mChildRoot,"UISubHeartYell",{page = self._page,subPage = self._subPage})
		end,
		[_ChildWndDefine.TimeTreasure] = function()
			-- 打开幸运魔轮
			--self:CreateChildWnd(self.mChildRoot,"UIFortuneMic",{page = self._page,subPage = self._subPage})
			self:CreateChildWnd(self.mChildRoot,"UISubLimitedTrea",{page = self._page,subPage = self._subPage})

		end,
		[_ChildWndDefine.TreaFindNew] = function()
			self:CreateChildWnd(self.mChildRoot,"UISubTreadNew")
		end,
		[_ChildWndDefine.HalidomCall] = function()
			self:CreateChildWnd(self.mChildRoot,"UISubSdYell")
		end,
	}
	self:InitCallBtnTransInfo()
end

function UIMirNew:InitEvent()
	self:SetWndClick(self.mReturnBtn,function() self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
--[[    self:SetWndClick(self.mMirrorCallBtn,function() self:OnClickMirrorCallBtnFunc() end)
    self:SetWndClick(self.mHeartCallBtn,function() self:OnClickHeartCallBtnFunc() end)
    self:SetWndClick(self.mTimeCallBtn,function() self:OnClickTimeCallBtnFunc() end)
    self:SetWndClick(self.mTreasureCallBtn,function() self:OnClickTreasureCallBtnFunc() end)]]
end

function UIMirNew:RefreshBottomBtnShow()
	if not self._uiBtnTabList then return end
	self._uiBtnTabList:RefreshTabScroll()
end

function UIMirNew:OnEventCloseBookView()
	if not self._uiBtnTabList then return end
	self._uiBtnTabList:RefreshTabRPState()
end

function UIMirNew:RefreshShow()
	self:CloseAllChild()
	self:ShowContent()
end

function UIMirNew:ChangePage(page)
	if page == self._page then return end
	self._page = page
	self:RefreshShow()
end

function UIMirNew:OnWndRefresh()
	self:InitData()
	self:CheckIsClickCity()
	self:SetWndShowByJump()
	self:RefreshBottomBtnShow()
	self:RefreshShow()
end

function UIMirNew:InitMsg()
	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function()
		self:RefreshBottomBtnShow()
	end)
	self:WndEventRecv(EventNames.ON_MOJING_MAIN,function()
		self:WndClose()
	end)
	self:WndEventRecv(EventNames.CLOSE_BOOK_VIEW,function (...) self:OnEventCloseBookView() end)

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end
------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIMirNew



