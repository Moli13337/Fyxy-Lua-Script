---
--- 皮肤图鉴
--- Created by Ease.
--- DateTime: 2023/10/25 18:04:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISnBook:LWnd
local UISnBook = LxWndClass("UISnBook", LWnd)
UISnBook.HeroBtn = 1
UISnBook.SetsBtn = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISnBook:UISnBook()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISnBook:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISnBook:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISnBook:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
end

function UISnBook:UpdateCurSkinCnt()
	self._curSkinCnt = gModelSkinBook:CalcCurSkinCnt()
end
function UISnBook:SeleBotBtn(btnType)
	local heroIcon = self:FindWndTrans(self.mHeroBtn, "Icon")
	local setsIcon = self:FindWndTrans(self.mSetsBtn, "Icon")
	if (UISnBook.HeroBtn == btnType) then
		--屏蔽掉皮肤图鉴伙伴分页
		self:SetBotBtnState(self.mHeroBtn, false)
		self:SetWndEasyImage(heroIcon,"heroskin_5_1")
		self:SetBotBtnState(self.mSetsBtn, false)
		self:SetWndEasyImage(setsIcon,"heroskin_ui_4")
	elseif (UISnBook.SetsBtn == btnType) then
		self:SetBotBtnState(self.mHeroBtn, false)
		self:SetWndEasyImage(heroIcon,"heroskin_ui_5")
		self:SetBotBtnState(self.mSetsBtn, true)
		self:SetWndEasyImage(setsIcon,"heroskin_ui_4_1")
	end
end

function UISnBook:RefreshMyRedPoint()
	--printInfoNR("-----RefreshRedPoint---")
	local collectRP = self:FindWndTrans(self.mCollectBtn,"RedPoint")
	local showCollectRP = gModelSkinBook:CheckCollectActRedPointStatus()
	CS.ShowObject(collectRP,showCollectRP)
	local heroBtnRP = self:FindWndTrans(self.mHeroBtn,"RedPoint")
	local showHeroRP = gModelSkinBook:CheckItemtRedPointStatus(1)
	CS.ShowObject(heroBtnRP,showHeroRP)-- or showCollectRP
	local setsBtnRP = self:FindWndTrans(self.mSetsBtn,"RedPoint")
	local showSetsRP = gModelSkinBook:CheckItemtRedPointStatus(2)
	CS.ShowObject(setsBtnRP,showSetsRP)-- or showCollectRP
end
--消息事件监听初始化
function UISnBook:InitEvent()
	--self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
	--	self:OnActivityConfigData(...)    --活动配置
	--end)
end
function UISnBook:SetBotBtnState(btnTrans, isSele)
	local seleTrans = self:FindWndTrans(btnTrans, "SelBg")
	local nameTrans = self:FindWndTrans(btnTrans,"NameTxt")
	local nameTxtCmp = nameTrans:GetComponent("YXUIText")
	local nameTxtColorHex = isSele and "FFFFFF" or "BFBDDB"
	nameTxtCmp.color = LUtil.ColorByHex_6(nameTxtColorHex)
	CS.ShowObject(seleTrans, isSele)
end

function UISnBook:SetBotList()
	if (not self._HeroSkinRef) then return end
	local skinBookList = {}
	--skinBookList.hero = gModelSkinBook:GetSkinBookHeroRef()
	skinBookList.sets = gModelSkinBook:GetSkinBookSetsRef()
	self:SetBotBtn(UISnBook.HeroBtn)
	self:SetBotBtn(UISnBook.SetsBtn)
	if(self._seleBtnType == UISnBook.HeroBtn)then
		--self:OnClickBotBtn(UISnBook.HeroBtn, skinBookList.hero)
		self:OnClickBotBtn(UISnBook.SetsBtn, skinBookList.sets)
	elseif(self._seleBtnType == UISnBook.SetsBtn)then
		self:OnClickBotBtn(UISnBook.SetsBtn, skinBookList.sets)
	else
		--self:OnClickBotBtn(UISnBook.HeroBtn, skinBookList.hero)
		self:OnClickBotBtn(UISnBook.SetsBtn, skinBookList.sets)
	end
	self:SetWndClick(self.mHeroBtn, function()
		--self:OnClickBotBtn(UISnBook.HeroBtn, skinBookList.hero)
		self:OnClickBotBtn(UISnBook.SetsBtn, skinBookList.sets)
	end, LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mSetsBtn, function()
		self:OnClickBotBtn(UISnBook.SetsBtn, skinBookList.sets)
	end, LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mItemInfoBtn,function()
		gModelGeneral:OpenItemInfoTip(ModelItem.ITEM_SKIN_DEBRIS)
	end)

	self:UpdateCurSkinCnt()
end
function UISnBook:InitData()
	gModelSkinBook:RaceType(0)
	gModelSkinBook:CareerType(0)
	self._HeroSkinRef = gModelSkinBook:GetHeroSkinRef()
	self._HeroSkinList = gModelHero:GetHeroSkinList()
	self:SetUI()
	gModelSkinBook:OnHeroSkinPropertyListReq()
	self:RefreshSkinPiece()
end
function UISnBook:OnClickBotBtn(btnType, data)
	self:SeleBotBtn(btnType)
	self._seleBtnType = btnType
	--local wndName = btnType == UISnBook.HeroBtn and "UISubSnBookSaga" or "UISubSnBookSets"
	local wndName = btnType == UISnBook.HeroBtn and "UISubSnBookSaga" or "UISubSnBookSets"
	self:CloseAllChild()
	self._wnd = self:CreateChildWnd(self.mChildRoot, wndName, { refDataList = data })
end
--按钮事件监听初始化
function UISnBook:InitBtnEvent()
	--返回按钮
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	--帮助按钮
	self:SetWndClick(self.mHelpBtn, function()
		GF.OpenWnd("UIBzTips", { refId = 370 })
	end, LSoundConst.CLICK_BUTTON_COMMON)
	--时光衣柜按钮
	self:SetWndClick(self.mTimeClosetBtn, function()
		self._heroSkinJump = gModelHero:GeConfigByKey("heroSkinJump")  or 10402101
		local isOpen = gModelFunctionOpen:CheckIsOpened(self._heroSkinJump)
		if isOpen then
			gModelFunctionOpen:Jump(self._heroSkinJump)
		end
	end, LSoundConst.CLICK_BUTTON_COMMON)
	--收集加成按钮
	self:SetWndClick(self.mCollectBtn, function()
		GF.OpenWndTop("UISnBookCollectPop", { collectDataList = self._collectDataList, curSkinCnt = self._curSkinCnt })--
	end)
	--皮肤商店按钮
	self:SetWndClick(self.mSkinShopBtn, function()
		local shopId = gModelShop:GetShopShow(1,1)
		--GF.OpenWndBottom("UIDian",{page = ModelShop.NORMAL,subPage = 1006})--,subPage = 1006
		gModelFunctionOpen:Jump(14500061, self:GetWndName())
	end)
end
function UISnBook:SetUI()

	local isTimecloseOpen = gModelFunctionOpen:CheckIsOpened(10402101)
	CS.ShowObject(self.mTimeClosetBtn,isTimecloseOpen)
	self:SetBotList()
	self:SetWndText(self.mTimeClosetTxt, ccClientText(30208))--时光衣柜
	if not gLGameLanguage:IsJapanRegion() then
		self:InitTextLineWithLanguage(self.mTimeClosetTxt, -30)
	end
	self:InitTextSizeWithLanguage(self.mTimeClosetTxt, -2)
	self:SetWndText(self.mCollectTxt, ccClientText(30209))--收集加成
	self:InitTextLineWithLanguage(self.mCollectTxt, -30)
	self:InitTextSizeWithLanguage(self.mCollectTxt, -2)
	self:SetWndText(self.mSkinShopTxt, ccClientText(30210))--皮肤商店
	self:InitTextSizeWithLanguage(self.mSkinShopTxt, -2)
	self:SetWndText(self.mReturnTxt, ccClientText(30205)) --返回
	CS.ShowObject(self.mMask, true)

	self:SetWndText(self.mTxtClose,ccClientText(30205))
end
function UISnBook:OnHeroSkinUseResp(pb, ret)
	--self:SetUI()
	gModelSkinBook:OnHeroSkinPropertyListReq()
end
function UISnBook:OnHeroSkinPropertyListResp(pb, ret)
	--收集加成数据返回
	self._collectDataList = {}
	for i, v in pairs(pb.refId) do
		if(type(v) and type(v) == "number")then
			--table.insert(self._collectDataList,v)
			self._collectDataList[v] = v
		end
	end
	gModelSkinBook:SetCollectDataList(self._collectDataList)
	self:UpdateCurSkinCnt()
	self:RefreshMyRedPoint()
end
function UISnBook:OnQuestReceiveResp(pb, ret)
	--self:SetUI()
end

function UISnBook:SetBotBtn(btnType)
	local btnTrans = btnType == UISnBook.HeroBtn and self.mHeroBtn or self.mSetsBtn
	local nameTxt = self:FindWndTrans(btnTrans, "NameTxt")
	local nameTxtId = btnType == UISnBook.HeroBtn and 30203 or 30204
	self:SetWndText(nameTxt, ccClientText(nameTxtId))
end
--协议监听初始化
function UISnBook:InitMessage()
	self:WndNetMsgRecv(LProtoIds.HeroSkinPropertyListResp, function(...)
		--printInfoNR("-------------HeroSkinPropertyListResp----------")
		self:OnHeroSkinPropertyListResp(...)    --激活皮肤加成列表数据返回
	end)
	self:WndNetMsgRecv(LProtoIds.HeroSkinUseResp, function(...)
		--printInfoNR("-------------HeroSkinUseResp----------")
		self:OnHeroSkinUseResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.QuestListResp, function(...)
		--printInfoNR("-------------QuestListResp----------")
		self:OnQuestReceiveResp(...)
	end)
	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:RefreshSkinPiece()
	end)

	self:WndNetMsgRecv(LProtoIds.ItemListResp, function()
		self:RefreshSkinPiece()
	end)
end

function UISnBook:RefreshSkinPiece()
	local haveNum = gModelItem:GetNumByRefId(ModelItem.ITEM_SKIN_DEBRIS)
	CS.ShowObject(self.mSkinPieceDiv, true)
	local iconPath = gModelItem:GetItemIconByRefId(ModelItem.ITEM_SKIN_DEBRIS)
	self:SetWndEasyImage(self.mSkinPieceIcon, iconPath)
	self:SetWndText(self.mSkinPieceNum, haveNum)
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mSkinPieceDiv)
end
------------------------------------------------------------------
return UISnBook


