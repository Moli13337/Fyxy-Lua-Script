---
--- Created by Administrator.
--- DateTime: 2024/6/11 15:08:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLandYell:LWnd
local UIPeWishLandYell = LxWndClass("UIPeWishLandYell", LWnd)
------------------------------------------------------------------


local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLandYell:UIPeWishLandYell()
	---@type UIBtnTabList
	self._uiBtnTabList = nil

	self._btnType = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLandYell:OnWndClose()
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
function UIPeWishLandYell:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLandYell:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitCommonData()
	self:InitBtnTabList()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIPeWishLandYell:OnClickBtnTab(itemdata)
	if itemdata.btnType == self._btnType then return end
	self._btnType = itemdata.btnType
	self:RefreshShow()
end

function UIPeWishLandYell:InitBtnTabList()
	local dataList = {
		{
			btnType = ModelPetDreanLand.TYPE_LOTTERY_1,
			btnName = ccClientText(43366),
			clickFunc = function(itemdata)
				gModelPetDreanLand:SetLotteryItemLookState(itemdata.btnType)
				self:OnClickBtnTab(itemdata)
			end,
			checkRPFunc = function(itemdata)
				local lotteryType = itemdata.btnType
				if gModelPetDreanLand:CheckHasFreeByLotteryType(lotteryType) then return true end
				if gModelPetDreanLand:CheckLuckHasGet(lotteryType) then return true end
				return gModelPetDreanLand:CheckLotteryItemEnoughByLotteryType(lotteryType)
			end,
			offIcon = "petDreamland_btn_icon_2",
			onIcon = "petDreamland_btn_icon_2",
		},
		{
			btnType = ModelPetDreanLand.TYPE_LOTTERY_0,
			btnName = ccClientText(43348),
			clickFunc = function(itemdata)
				gModelPetDreanLand:SetLotteryItemLookState(itemdata.btnType)
				self:OnClickBtnTab(itemdata)
			end,
			checkRPFunc = function(itemdata)
				local lotteryType = itemdata.btnType
				if gModelPetDreanLand:CheckHasFreeByLotteryType(lotteryType) then return true end
				if gModelPetDreanLand:CheckLuckHasGet(lotteryType) then return true end
				return gModelPetDreanLand:CheckLotteryItemEnoughByLotteryType(lotteryType)
			end,
			offIcon = "petDreamland_btn_icon_1",
			onIcon = "petDreamland_btn_icon_1",
		},
	}

	--- 默认打开 特级签订
	self._btnType = ModelPetDreanLand.TYPE_LOTTERY_1
	gModelPetDreanLand:SetLotteryItemLookState(self._btnType)

	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
	self._uiBtnTabList:SetData(self,self.mTabScroll,dataList,self._btnType,nil,function(textTran)
		self:InitTextLineWithLanguage(textTran, 0)
		local typeofRectTransform = typeof(CS.RectTransform)
		local rectTrans = textTran.gameObject:GetComponent(typeofRectTransform)
		rectTrans.offsetMax  = Vector2.New(0, rectTrans.offsetMax.y)
		rectTrans.offsetMin = Vector2.New(0, rectTrans.offsetMin.y)
		if gLGameLanguage:IsVieVersion() then
			rectTrans.offsetMax  = Vector2.New(0, -16)
			rectTrans.offsetMin = Vector2.New(0, -16)
			self:InitTextSizeWithLanguage(textTran,-4)
		end

	end)
end

function UIPeWishLandYell:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end


function UIPeWishLandYell:RefreshView()
	self:RefreshShow()
end

function UIPeWishLandYell:InitText()
	self:SetWndText(self.mTxtClose, ccClientText(42010))
end

function UIPeWishLandYell:InitData()
end

function UIPeWishLandYell:OnEventRefreshCallState(data)
	data = data or {}
	local show = data.show and true or false
	CS.ShowObject(self.mBotDiv,show)
end

function UIPeWishLandYell:OnPetDreamLandLotterytResp()
	if self._uiBtnTabList then
		self._uiBtnTabList:RefreshTabScroll()
	end
end

function UIPeWishLandYell:OnPetDreamLandLotterytReceiveResp()
	if self._uiBtnTabList then
		self._uiBtnTabList:RefreshTabScroll()
	end
end

function UIPeWishLandYell:ShowContent()
	local btnType = self._btnType
	local btnFunc = self._btnFuncList[btnType]
	if btnFunc then
		btnFunc()
	end
end

function UIPeWishLandYell:RefreshShow()
	if not self._init or not self._notClearWndMap[self._btnType] then
		self._init = true
		self:CloseAllChild()
	end
	self:ShowContent()
end


function UIPeWishLandYell:InitMsg()
	 self:WndEventRecv(EventNames.REFRESH_CALL_STATE,function (...) self:OnEventRefreshCallState(...) end)
	 self:WndNetMsgRecv(LProtoIds.PetDreamLandLotterytResp,function(...) self:OnPetDreamLandLotterytResp(...) end)
	 self:WndNetMsgRecv(LProtoIds.PetDreamLandLotterytReceiveResp,function(...) self:OnPetDreamLandLotterytReceiveResp(...) end)
end

function UIPeWishLandYell:InitCommonData()
	self._notClearWndMap = {
		[ModelPetDreanLand.TYPE_LOTTERY_0] = true,
		[ModelPetDreanLand.TYPE_LOTTERY_1] = true,
	}
	self._btnFuncList = {
		[ModelPetDreanLand.TYPE_LOTTERY_0] = function()
			self:CreateChildWnd(self.mChildRoot,"UISubPeWishLandYell",{
				lotteryType = ModelPetDreanLand.TYPE_LOTTERY_0,
				BgName = "petDreamland_bg_big_6"
			})
		end,
		[ModelPetDreanLand.TYPE_LOTTERY_1] = function()
			self:CreateChildWnd(self.mChildRoot,"UISubPeWishLandYell",{
				lotteryType = ModelPetDreanLand.TYPE_LOTTERY_1,
				BgName = "petDreamland_bg_big_7"
			})
		end,
	}
end



------------------------------------------------------------------
return UIPeWishLandYell