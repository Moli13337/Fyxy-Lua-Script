---
--- Created by BY.
--- DateTime: 2023/10/21 14:48:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILuckDianDisc:LWnd
local UILuckDianDisc = LxWndClass("UILuckDianDisc", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
local Time = Time
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILuckDianDisc:UILuckDianDisc()
	self._uiHeroObjList = {}
	self._effKey = "effKey"
	self._showKey = "showKey"
	self._randomList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILuckDianDisc:OnWndClose()
	if self._uiSkillCtrl then
		self._uiSkillCtrl:Destroy()
		self._uiSkillCtrl = nil
	end
	self._curUIHeroObj = nil
	self:ClearCommonIconList(self._uiHeroObjList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILuckDianDisc:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILuckDianDisc:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UILuckDianDisc:OnClickHelp()--点击帮助
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local title = activityData.title
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	local dataWeb = webData.config
	local content = dataWeb.shopHeroHelpTxt
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UILuckDianDisc:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self._sid = self:GetWndArg("sid")
	self._pageId = self:GetWndArg("pageId")
	local bargainAnim = self:GetWndArg("bargainAnim") or "zhuanshuzhekou"
	self._bargainAnim = bargainAnim
	self._noChinese = gLGameLanguage:IsForeignVersion()

	self:RefreshData()

	self:CreateSpine(bargainAnim,"idle",true)
end
---------------------------------------------------------------------------------------------------
function UILuckDianDisc:CreateSpine(key,ani,loop)
	local _dpSpine = self._dpSpine
	if not _dpSpine then
		self:CreateWndSpine(self.mDiscountEff,self._bargainAnim,key,false,function(dpSpine)
			dpSpine:PlayAnimation(0,ani,loop)
			self._dpSpine = dpSpine
		end)
	else
		_dpSpine:PlayAnimation(0,ani,loop)
	end
end

function UILuckDianDisc:InitEvent()
	self:SetWndClick(self.mDiscountBtn,function () self:OnClickDiscount() end)
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mTipsBtn,function () self:OnClickHelp() end)
end

function UILuckDianDisc:SetTransTween(seq,discount,pos,time,moveH)
	seq:AppendCallback(function ()
		self:SetDiscountValue()
		CS.ShowObject(discount,true)
		discount.localPosition = Vector3.New(pos.x,pos.y,0)
	end)
	local downPos = discount.localPosition + Vector3.New(pos.x,pos.y + moveH,0)
	local tweener = discount:DOLocalMove(downPos,time)
	seq:Append(tweener)
	seq:AppendCallback(function ()
		CS.ShowObject(discount,false)
	end)
end

function UILuckDianDisc:SetTowee(key)
	local seqTween
	self:TweenSeqKill(key)
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local discount = self.mDiscountBg
			CS.ShowObject(discount,false)
			local initPos = discount.localPosition
			local posList = self._bargainPoslist or {
				{x = 0,y = -80},
				{x = 80,y = -80},
				{x = 80,y = -80},
				{x = 80,y = -80},
			}
			local moveHs = self._bargainMove or {100,100,100,180}
			local timeList = self._bargaintimeList or {0.2,0.2,0.2,0.2}
			local waitList = self._bargainwaitList or {1.5,0.1,0.1,0.2,0.7}
			discount.localPosition = Vector3.New(posList[1].x,posList[1].y,0)
			for i = 1, 4 do
				seq:AppendInterval(waitList[i])
				self:SetTransTween(seq,discount,posList[i],timeList[i],moveHs[i])
			end
			seq:AppendInterval(waitList[5])
			seq:AppendCallback(function ()
				self:SetDiscountValue()
				discount.localPosition = initPos
				CS.ShowObject(discount,true)
			end)
			local toPos = Vector3.New(1.3,1.3,1.3)
			local dtMoveTo = discount:DOScale(toPos,0.1)
			seq:Append(dtMoveTo)
			local toPos = Vector3.New(0.9,0.9,0.9)
			local dtMoveTo = discount:DOScale(toPos,0.1)
			seq:Append(dtMoveTo)
			local toPos = Vector3.New(1,1,1)
			local dtMoveTo = discount:DOScale(toPos,0.1)
			seq:Append(dtMoveTo)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)
	end)
end

function UILuckDianDisc:OnRandom()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local data = JSON.decode(activityData.moreInfo)
	local shopDiscount = data.shopDiscount_lsp or 0			--折扣
	if shopDiscount < 0 then
		self:RefreshData()
		return
	end
	local WebData = gModelActivity:GetWebActivityDataById(self._sid)
	local dataWeb = WebData.config
	local shopHeroSale = dataWeb.shopHeroSale
	local shopHeroSaleArr = string.split(shopHeroSale,"|")
	local maxValue = tonumber(shopHeroSaleArr[2])
	local minValue = shopDiscount + 1 <= maxValue and shopDiscount + 1 or shopDiscount
	local list  = {shopDiscount}
	for i = 1, 4 do
		local random = math.random(minValue,maxValue)
		table.insert(list,random)
	end
	table.sort(list,function (a,b)
		return a > b
	end)
	self._randomList = list
	self._randomIndex = 1
	CS.ShowObject(self.mShowMag,false)
	self:TimerStop(self._showKey)
	self:TimerStart(self._showKey,4.3, false, 1)
	self:SetTowee("key")
	self:CreateSpine(self._bargainAnim,"skill3",false)
end

function UILuckDianDisc:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		if self._isPayEff then
			self:OnRandom()
		else
			self:RefreshData()
		end
	end)
end

function UILuckDianDisc:SetDiscountValue(value)
	local value = value
	if not value then
		local index = self._randomIndex
		if not index then
			index = 1
		end

		value = self._randomList[index]
		self._randomIndex = index + 1
	end
	if not value then
		return
	end


	local discount1,discount2, sizeRate, showText2, showImg1,discount1Str, discount2Str
	if self._noChinese then
		sizeRate = 150
		discount1 = 100 - value
		discount1Str = LUtil.FormatCoversionHurtNumSpriteText(discount1,false,sizeRate, 24)
	else
		if value < 10 then
			discount1 = 0
			discount2 = value
		else
			discount1 =  math.floor(value / 10)
			discount2 = value % 10
		end
		discount1Str = LUtil.FormatHurtNumSpriteText(discount1, false, sizeRate)
		discount2Str = LUtil.FormatHurtNumSpriteText(discount2, false, sizeRate)
		showText2 = true
		showImg1  = true
	end


	self:SetWndText(self.mDiscountText1,discount1Str)

	CS.ShowObject(self.mDiscountText2, showText2)
	if showText2 and discount2Str then
		self:SetWndText(self.mDiscountText2,discount2Str)
	end

	CS.ShowObject(self.mDiscountImg1, showImg1)
end

function UILuckDianDisc:OnTryTcpReconnect()
	self:WndClose()
end

function UILuckDianDisc:OnClickDiscount()
	local WebData = gModelActivity:GetWebActivityDataById(self._sid)
	local dataWeb = WebData.config
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local data = JSON.decode(activityData.moreInfo)
	local resetCount = data.resetCount_lsp or 0			--重置次数
	local shopSaleNum = dataWeb.shopSaleNum	 or 0				--免费重置次数
	if resetCount >= shopSaleNum then
		local resetCount = resetCount - shopSaleNum
		local isGuy = false
		local shopResetNum = dataWeb.shopResetNum
		local shopResetNumArr = string.split(shopResetNum,"|")
		local resetLen = #shopResetNumArr
		local vipIndex = 0
		local vip = gModelPlayer:GetVipLevel()
		for i, v in ipairs(shopResetNumArr) do
			local shopReset = string.split(v,"=")
			if vip >= tonumber(shopReset[1]) then
				local num = tonumber(shopReset[2])
				if num > resetCount then
					isGuy = true
					break
				end
			else
				local num = tonumber(shopReset[2])
				if num > resetCount then
					break
				end
			end
			vipIndex = i
		end
		if not isGuy then
			if vipIndex < resetLen then
				local vip = shopResetNumArr[vipIndex+1]
				local vipArr = string.split(vip,"=")
				GF.ShowMessage(string.replace(ccClientText(19230),vipArr[1]))
			else
				GF.ShowMessage(ccClientText(19229))
			end
			return
		end
		local shopResetUse = dataWeb.shopResetUse
		local item = LxDataHelper.ParseItem_3(shopResetUse)
		local isEnough = gModelGeneral:CheckItemEnough(item.itemId,item.itemNum,true,self:GetWndName())
		if not isEnough then
			return
		end
	end

	if resetCount >= shopSaleNum then
		local shopResetUse = dataWeb.shopResetUse
		local item = LxDataHelper.ParseItem_3(shopResetUse)
		local itemNum = item.itemNum
		local itemId  = item.itemId
		local name = gModelItem:GetNameByRefId(itemId)
		gModelGeneral:OpenUIOrdinTips({refId = 110017,para = {itemNum..name},func = function()
			self._isPayEff = true
			gModelActivity:OnActivitySpecialOpReq(self._sid,self._pageId,0,4)
		end, consume={itemNum,itemId} })
	else
		self._isPayEff = true
		gModelActivity:OnActivitySpecialOpReq(self._sid,self._pageId,0,4)
	end
end

function UILuckDianDisc:OnTimer(key)
	if self._showKey == key then
		self:RefreshData()
		self:CreateSpine(self._bargainAnim,"idle",true)
	end
end

function UILuckDianDisc:RefreshData()
	local _sid = self._sid
	CS.ShowObject(self.mShowMag,true)
	local activityData = gModelActivity:GetActivityBySid(_sid)
	if not activityData then
		return
	end
	local data = JSON.decode(activityData.moreInfo)
	local WebData = gModelActivity:GetWebActivityDataById(_sid)
	local dataWeb = WebData.config

	local bargainPoslist,bargainMove,bargaintimeList,bargainwaitList
	= dataWeb.bargainPoslist,dataWeb.bargainMove,dataWeb.bargaintimeList,dataWeb.bargainwaitList
	if not string.isempty(bargainPoslist)then
		local arr = string.split(bargainPoslist,"|")
		local list = {}
		for i, v in ipairs(arr) do
			local ar = string.split(v,",")
			table.insert(list,{x = tonumber(ar[1]),y = tonumber(ar[2])})
		end
		self._bargainPoslist = list
	end
	if not string.isempty(bargainMove)then
		local arr = string.split(bargainMove,"|")
		local list = {}
		for i, v in ipairs(arr) do
			table.insert(list,tonumber(v))
		end
		self._bargainMove = list
	end
	if not string.isempty(bargaintimeList)then
		local arr = string.split(bargaintimeList,"|")
		local list = {}
		for i, v in ipairs(arr) do
			table.insert(list,tonumber(v))
		end
		self._bargaintimeList = list
	end
	if not string.isempty(bargainwaitList)then
		local arr = string.split(bargainwaitList,"|")
		local list = {}
		for i, v in ipairs(arr) do
			table.insert(list,tonumber(v))
		end
		self._bargainwaitList = list
	end

	local shopDiscount = data.shopDiscount_lsp or 0		--折扣
	local resetCount = data.resetCount_lsp or 0			--重置次数
	local shopSaleNum = dataWeb.shopSaleNum or 	0				--免费重置次数
	local isFree = resetCount < shopSaleNum
	local isDiscount = shopDiscount > 0
	local shopHero = dataWeb.bargainHero
	local bargainTxt = dataWeb.bargainTxt
	local mTipsStr = ""
	if not string.isempty(bargainTxt)then
		mTipsStr = bargainTxt
	elseif not string.isempty(shopHero) then
		local ref = gModelHero:GetShowEffectById(tonumber(shopHero))
		if ref and not isDiscount then
			mTipsStr = string.replace(ccClientText(19212),ccLngText(ref.name))
		end
	end
	self:SetWndText(self.mTipsText,mTipsStr)

	local discountBtnStr = ""
	if not isFree then
		local shopResetUse = dataWeb.shopResetUse
		local shopResetUseArr = string.split(shopResetUse,"=")
		local icon = gModelItem:GetItemIconByRefId(shopResetUseArr[2])
		self:SetWndEasyImage(self.mConsumeIcon,icon)
		self:SetWndText(self.mConsumeText,shopResetUseArr[3])

		discountBtnStr = ccClientText(19214)
		local heroDescDiscount = shopDiscount/10
		if self._noChinese then
			heroDescDiscount = 100 - shopDiscount
			heroDescDiscount = heroDescDiscount.."%"
		end

		self:SetWndText(self.mHeroDesText,string.replace(ccClientText(19228),heroDescDiscount))
		self:InitTextLineWithLanguage(self.mHeroDesText, -30)
		self:InitTextSizeWithLanguage(self.mHeroDesText, -2)
		self:SetDiscountValue(shopDiscount)
	else
		discountBtnStr = ccClientText(19235)
	end
	CS.ShowObject(self.mTipsBg,isFree)
	CS.ShowObject(self.mConsumeText,not isFree)
	CS.ShowObject(self.mHeroDesBg,isDiscount)
	CS.ShowObject(self.mDiscountBg,isDiscount)
	self:SetWndButtonText(self.mDiscountBtn,discountBtnStr, false, -4)
	self:SetWndButtonTextLine(self.mDiscountBtn, -30)
    if resetCount < shopSaleNum then
        self:SetWndText(self.mResidueNumText,"")
        return
    end
	local _resetCount,allCount = gModelActivity:GetDisShopResidueNum(_sid)
	local num = allCount - _resetCount
	local color = "lightGreen"
	if num <= 0 then
		color = "white"
		num = 0
	end
	local numStr = LUtil.FormatColorStr(num,color)
	self:SetWndText(self.mResidueNumText,string.replace(ccClientText(19244),numStr))
end
------------------------------------------------------------------
return UILuckDianDisc


