---
--- Created by Administrator.
--- DateTime: 2023/10/22 15:06:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActOneClickSn:LWnd
local UIActOneClickSn = LxWndClass("UIActOneClickSn", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActOneClickSn:UIActOneClickSn()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActOneClickSn:OnWndClose()
	if self._nameList then
		self._nameList = nil
	end

	if self._nameList then
		LUtil.ClearHashTable(self._btnList)
		self._btnList = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActOneClickSn:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActOneClickSn:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActOneClickSn:InitCommand()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._nameList = {}

	--是否全部购买
	self._isBuyAll = nil
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActOneClickSn:OnClickOpenReward()
	GF.OpenWnd("UIActOneClickSnAward",{ sid = self._sid})
end

function UIActOneClickSn:InitSkinNameList()
	if not table.isempty(self._nameList) then return end

	for i = 1, self._skinLen do
		local cloneItem = LxResUtil.NewObject(self.mItemTemplate.gameObject)
		local item = cloneItem.transform
		item:SetParent(self.mItemRoot, false)
		table.insert(self._nameList, item)
	end
end

function UIActOneClickSn:InitData()
	local activityData 		= gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local config  = webData.config
	self._webCfg  = config
	self._isForeign = gLGameLanguage:IsForeignRegion()
	self._isReBuy = config.isReBuy or 0 ---是否可重复购买

	self._namePosList = {}
	local btnPos  = string.split(config.btnPos, '|')
	for k,v in ipairs(btnPos) do
		table.insert(self._namePosList, v)
	end

	self._endTime = tonumber(activityData.endTime)
end

function UIActOneClickSn:OnClickBtn(btnIndex)
	local sid = self._sid
	if btnIndex == 1 then
		local func = function()
			GF.OpenWnd("UIActOneClickSn",{sid = sid})
		end

		GF.OpenWnd("UIActDiscsSn", {sid = sid, func = func})
	else

		local isAllow = self:IsAllowRepeatBuy()
		if not isAllow then
			local str =ccClientText(17426) --"不可重复购买星灵伙伴"
			GF.ShowMessage(str)
			return
		end

		GF.OpenWnd("UIActOneClickSnPop", {sid = sid})
	end

	self:WndClose()
end

function UIActOneClickSn:RefreshBtnList()
	local config = self._webCfg
	if not config then return end

	for k,v in ipairs(self._btnList) do
		local isBuy = k == 2 and self._isBuyAll
		if not isBuy then
			local dataKey = "btnName"..k
			local btnData = string.split(config[dataKey], '=')
			local btnIcon = btnData[1]
			if LxUiHelper.IsImgPathValid(btnIcon) then
				self:SetWndEasyImage(v.btnPay, btnIcon)
			end
			local payStr = btnData[2]

			local isShowOriginalText = false
			if k == 2 then
				local showPrice = config.showPrice
				isShowOriginalText = not string.isempty(showPrice)
				if isShowOriginalText then
					self:SetWndText(v.originalText, showPrice)
				end

				--[[
				local price = config.price
				local welfareStr = gModelPay:GetShowByWelfareId(price)
				payStr = payStr..welfareStr
				]]--
			end
			self:SetWndText(v.payText, payStr)
			self:InitTextSizeWithLanguage(v.payText, -2)

			CS.ShowObject(v.originalText, isShowOriginalText)
			CS.ShowObject(v.originalLine, isShowOriginalText and not self._isForeign)

			self:SetWndClick(v.btnPay, function()
				self:OnClickBtn(k)
			end)
		else
			CS.ShowObject(v.originalText, false)
		end

		CS.ShowObject(v.btnPay, not isBuy)
		CS.ShowObject(v.maskPay, isBuy)
	end

	local showBtnOne = not self._isBuyAll
	local btnOne = self._btnList[1]
	CS.ShowObject(btnOne.btnTrans,showBtnOne)


	local isGray = not self:IsAllowRepeatBuy()

	local img = isGray and "public_btn_ash_1" or "public_btn_1_2"

	local btnTwo = self._btnList[2]
	local btnTran = btnTwo.btnPay
	local textTran = btnTwo.payText

	self:SetBtnImageAndMat(btnTran,img,textTran)
end

function UIActOneClickSn:ResetActivePageData(pb)
	local hasBuyOne = false
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if page then
			if v.pageId == 1 then
				local moreInfo
				self._pageData   = {}
				self._isBuyAll = true
				for p,q in pairs(page.entry) do
					local entryCfg  = gModelActivity:GetWebActivityEntryData(self._sid,q.pageId,q.entryId)
					if entryCfg then
						moreInfo = string.split(entryCfg.moreInfo, '|')
						local marketData 	= q.MarketData
						local personal 		= marketData.personal; -- 已使用个人限购次数
						local personalGoal	= marketData.personalGoal; -- 个人可购买次数
						local haveCount		= personalGoal - personal
						local heroSpineData = string.split(moreInfo[1], '=')
						local showLookBtn   = tonumber(moreInfo[4] or 0)

						local data = {
							entryId = q.entryId,
							pageId = q.pageId,
							sid = self._sid,
							id 		= entryCfg.id,
							name = entryCfg.name,
							heroRefId = tonumber(heroSpineData[1]),
							showLookBtn = showLookBtn == 0,
							sort = entryCfg.sort,
							price = entryCfg.expend2,
							isSoldOut = personal >= personalGoal,
						}
						table.insert(self._pageData, data)

						if haveCount > 0 then
							self._isBuyAll = false
						end

						if personal > 0 then
							hasBuyOne = true
						end
					end
				end

				table.sort(self._pageData, function(a, b)
					return a.sort < b.sort
				end)
			elseif v.pageId == 2 then
				self._pageRewardData = page
			end
		end
	end

	self._hasBuyOne = hasBuyOne
end

function UIActOneClickSn:OnClickLook(heroRefId)
	local sid = self._sid
	local heroSkinCloseFunc = function()
		GF.OpenWnd("UIActOneClickSn",{sid = sid})
	end
	if self._themeType == 1 then
		gModelGeneral:OpenHeroSkin({skinRefId = heroRefId,preview = true, backFunc = heroSkinCloseFunc})
	elseif self._themeType == 2 then
		gModelGeneral:OpenHeroSimpleTip(heroRefId,true)
	end

	self:WndClose()
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActOneClickSn:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()
	self:InitTop()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActOneClickSn:InitBtnList()
	if not table.isempty(self._btnList) then return end

	self._btnList = {}
	for i = 1, 2 do
		local btnTrans = self:FindWndTrans(self.mBtnList, "Btn"..i)
		local data     = {
			btnTrans	 = btnTrans,
			originalText = self:FindWndTrans(btnTrans, "OriginalText"),
			originalLine = self:FindWndTrans(btnTrans, "OriginalText/Image"),
			btnPay		 = self:FindWndTrans(btnTrans, "BtnPay"),
			payText		 = self:FindWndTrans(btnTrans, "BtnPay/PayText"),
			maskPay		 = self:FindWndTrans(btnTrans, "MaskPay"),
		}

		table.insert(self._btnList, data)
	end
end

function UIActOneClickSn:InitTimeBg()
	if self._endTime <= 0 then
		self:SetWndText(self.mTimeText, "")
		return
	end

	local config = self._webCfg
	local timeTxt = config.timeTxt

	local str = LUtil.FormatYearMonthDay(self._endTime)
	str = string.replace(timeTxt, str)
	self:SetWndText(self.mTimeText, str)
end

function UIActOneClickSn:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if self._sid == sid then
			self:InitData()
			self:RefreshUIRoot()
			break
		end
	end
end

function UIActOneClickSn:RefreshSkinNameList()
	for k,v in ipairs(self._pageData) do
		self:SetSkinNameItem(v, k)
	end
end

function UIActOneClickSn:OnClickBuySkin(itemdata)
	gModelPay:GiftPayCtrl(itemdata.entryId,itemdata.price,ModelPay.PAY_TYPE_ACTIVITY,0,itemdata.sid,itemdata.pageId)
end

function UIActOneClickSn:IsAllowRepeatBuy()
	return not (self._hasBuyOne and self._isReBuy == 1)
end

function UIActOneClickSn:RefreshUIRoot()
	local list = self._pageData
	if not list then return end
	self._skinLen = #list

	self:InitSkinNameList()
	self:RefreshSkinNameList()
	self:RefreshBtnList()
	self:RefreshRewardRed()

	CS.ShowObject(self.mAniRoot, true)
end

function UIActOneClickSn:SetSkinNameItem(itemdata, itempos)
	local item = self._nameList[itempos]
	if not item then return end

	local Image = self:FindWndTrans(item,"Image")
	local ImageNameText = self:FindWndTrans(Image,"NameText")
	local ImageBtnLook = self:FindWndTrans(Image,"BtnLook")
	local btnBuy = self:FindWndTrans(item,"btnBuy")
	local btnBuyUIText = self:FindWndTrans(btnBuy,"UIText")


	--local nameText  = self:FindWndTrans(itemTrans, "Image/NameText")
	--local btnLook   = self:FindWndTrans(itemTrans, "Image/BtnLook")

	local name      = itemdata.name
	local heroRefId = itemdata.heroRefId
	local isShowLookBtn = itemdata.showLookBtn

	self:SetWndText(ImageNameText, name)

	CS.ShowObject(ImageBtnLook,isShowLookBtn)
	if isShowLookBtn then
		self:SetWndClick(Image,function ()
			self:OnClickLook(heroRefId)
		end)
	end

	local transPos = self._namePosList[itempos]
	if transPos and transPos ~= "0" then
		self:SetAnchorPos(item, LxDataHelper.ParseVector2NotEmpty(transPos))
	end

	CS.ShowObject(item, true)
	local priceShow = gModelPay:GetShowByWelfareId(itemdata.price)
	local str = string.replace(ccClientText(28900),priceShow)
	self:SetWndText(btnBuyUIText,str)
	self:InitTextSizeWithLanguage(btnBuyUIText, -4)

	CS.ShowObject(btnBuy,not itemdata.isSoldOut)

	self:SetWndClick(btnBuy,function ()
		self:OnClickBuySkin(itemdata)
	end)

end

function UIActOneClickSn:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb) self:OnActivityPageResp(pb) end)
end

function UIActOneClickSn:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	self:ResetActivePageData(pb)
	self:RefreshUIRoot()
end

function UIActOneClickSn:RefreshRewardRed()
	local haveCanGet = false
	local pageRewardData = self._pageRewardData or {}
	local entry = pageRewardData.entry or {}
	for k,v in ipairs(entry) do
		local status  = v.goalData.status
		if status == 1 then
			haveCanGet = true
			break
		end
	end

	CS.ShowObject(self.mOpenRewardRedPoint, haveCanGet)
end

function UIActOneClickSn:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOpenReward, function(...) self:OnClickOpenReward() end)
end
--#####################################################################################################################
--## Root #############################################################################################################
--#####################################################################################################################
function UIActOneClickSn:InitTop()
	local config = self._webCfg
	if not config then
		return
	end

	CS.ShowObject(self.mContent, true)

	local path = config.image
	local size = nil
	if not string.isempty(config.imageScope) then
		size = LxDataHelper.ParseVector2(config.imageScope,'*')
	end
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mBgImg, path, nil,size == nil)
		CS.ShowObject(self.mBgImg, true)
	end

	if size then
		self.mBgImg.sizeDelta = size
	end

	path = config.imageBottom
	local isValid = LxUiHelper.IsImgPathValid(path)
	if isValid then
		self:SetWndEasyImage(self.mImageExtra, path, nil,true)
	end
	CS.ShowObject(self.mImageExtra, isValid)

	path = config.mainTxt
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTitleImg, path, nil, true)
		CS.ShowObject(self.mTitleImg, true)
	end

	if not string.isempty(config.boxCoord) then
		local pos = LxDataHelper.ParseVector2(config.boxCoord,'|')
		self:SetAnchorPos(self.mOpenReward,pos)
	end

	local str = config.tipTxt
	local showTitle = not string.isempty(str)
	CS.ShowObject(self.mTitleBg, showTitle)
	if showTitle then
		self:SetWndText(self.mTitleText, str)
	end

	local str = ccClientText(24000)
	if not string.isempty(config.rewardTxt) then
		str = config.rewardTxt
	end
	self:SetWndText(self.mOpenRewardText, str)

	self._themeType = config.theme or 1

	self:InitBtnList()
	self:InitTimeBg()
end


------------------------------------------------------------------
return UIActOneClickSn


