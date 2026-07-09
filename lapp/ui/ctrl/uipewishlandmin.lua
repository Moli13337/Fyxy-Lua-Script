---
--- Created by Administrator.
--- DateTime: 2024/6/11 18:02:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLandMin:LWnd
local UIPeWishLandMin = LxWndClass("UIPeWishLandMin", LWnd)
------------------------------------------------------------------

local UnityEngine = UnityEngine
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXTween = YXTween


---@type number 显示左右切换按钮的数量
UIPeWishLandMin.SHOW_CHANGEBTN_NUM = 5

---@type number 若玩家停留在界面上，每隔3分钟，继续给随机1~2个小人冒泡文本
UIPeWishLandMin.SHOW_BUBBLE_TIME = 60 * 3

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLandMin:UIPeWishLandMin()
	---@type StructPetDreamLandData
	self._landData = nil

	---@type boolean 是否显示 ClickMask
	self._showClickMask = false

	---@type number 页数
	self._page = 1

	---@type number 总页数
	self._allPage = 1

	self._pageDatas = {}

	---@type number 限制页面数量
	self.limitPageNum = 0

	---@type number 无限制页面数量
	self.notLimitPageNum = 0

	self._timeDatasKey = {}

	self._timerKey = "_timerKey"
	self._cdTimeKey = "_cdTimeKey"
	self._cdNoTimeKey = "_cdNoTimeKey"
	self._updateOutputTimeKey = "_updateOutputTimeKey"
	self._showBubbleTimerKey = "_showBubbleTimerKey"

	--- 检查是否有加成
	self._showAdditionTimerKey = "_showAdditionTimerKey"

	---@type table 记录自己的数据，用于更新当前传出
	self._recordMySelfOutputInfo = nil
	---@type table<StructRewardItem> PetDreamLandPointData 的 itemList
	self._mySelfOutputList = nil

	self._showBubbleInfoMap = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLandMin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWishLandMin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLandMin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._petDreamlandTime = gModelPetDreanLand:GetConfigPetDreamlandTime() or 60
	self._showBubbleInfoMap = {}

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	if self._isEnus then
		LxUiHelper.SetSizeWithCurAnchor(self.mFightDiv,0,300)
	end 
	
	
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshClickMask()
	self:RefreshVip()
	self:RefreshView()
	self:CheckHasType4SettlementUI()

	self:TimerStop(self._cdTimeKey)
	self:TimerStart(self._cdTimeKey,1,false,-1)

	self:TimerStop(self._showAdditionTimerKey)
	self:TimerStart(self._showAdditionTimerKey,1,false,-1)

	self:RegisterRedPointFunc(ModelRedPoint.PDT_NEW_REPORT_1,function(isShow)
		CS.ShowObject(self.mBtnReportRP1,isShow)
	end)
	self:RegisterRedPointFunc(ModelRedPoint.PDT_NEW_REPORT_2,function(isShow)
		CS.ShowObject(self.mBtnReportRP2,isShow)
	end)
end

function UIPeWishLandMin:GetShowList()
	local list = {}
	local sortItemMap = {}
	--- 产出效率
	local refData = gModelPetDreanLand:GetSplitPetDreamlandRefByRefId(self._refId)
	if refData then
		local isVipPrivilege = gModelPetDreanLand:CheckHasVIPPrivilege()

		local weekenBuffNum = 0
		if gModelPetDreanLand:CheckIsOpenWeeken() then
			if self:CheckIsWeek() then
				weekenBuffNum = gModelPetDreanLand:GetpetDreamlandWeekenBuff() / 100
			end
		end

		--- 新增战区产出
		local value = gModelPetDreanLand:GetCurBigFightIdPetDreamlandRewardValue() or {}
		local rewardList = {}
		local reward = refData.reward
		local rewardLen = #reward
		local petDreamlandBuff = gModelPetDreanLand:GetVIPPetDreamlandBuff()
		for i,v in ipairs(reward) do
			--- （1+VIP额外加成比例+周末狂欢）
			local itemNum = (1 + petDreamlandBuff + weekenBuffNum) * v.itemNum
			local rate = value[i] or 1
			itemNum = itemNum * rate
			itemNum = math.floor(itemNum)
			local numStr = string.replace(ccClientText(43303),LUtil.NumberCoversion(itemNum))
			if isVipPrivilege and rewardLen == i then
				--- 追加在文字后面
				local vipPrivilege = gModelPetDreanLand:GetVIPPetDreamlandBuffStr(true)
				local vipPrivilegeStr = string.replace(ccClientText(43315),vipPrivilege)
				numStr = numStr .. vipPrivilegeStr
			end
			table.insert(rewardList,{
				itemId = v.itemId,
				numStr = numStr
			})

			sortItemMap[v.itemId] = i
		end
		table.insert(list,{
			txt = ccClientText(43302),
			list = rewardList,
		})
	end

	--- 玩家在当前模式有占领的据点的，则仍需额外显示当前的已占领收益
	if self._mySelfOutputList then
		local outputRewardList = {}
		local showIcon = false
		---@param v StructRewardItem
		for i,v in ipairs(self._mySelfOutputList) do
			local itemId = v.itemId
			local formatNumStr = LUtil.NumberCoversion(v.count)
			local numStr = ""
			if showIcon then
				numStr = "+" .. formatNumStr
			else
				numStr = string.replace(ccClientText(43396),gModelItem:GetNameByRefId(itemId),formatNumStr)
				itemId = nil
			end
			table.insert(outputRewardList,{
				itemId = itemId,
				sortItemId = v.itemId,
				numStr = numStr,
			})
		end
		table.sort(outputRewardList,function(a, b)
			local sortA = sortItemMap[a.sortItemId] or 0
			local sortB = sortItemMap[b.sortItemId] or 0
			return sortA < sortB
		end)
		table.insert(list,{
			txt = ccClientText(43395),
			list = outputRewardList,
		})
	end

	return list
end

function UIPeWishLandMin:OnClickPlayer(data,isLimit)
	if self._openTips then return end

	local isHasData = data ~= nil
	if not isHasData then return end

	local cancleFunc = function()
		self._openTips = false
	end

	self._openTips = true

	local refId = data.refId
	local func = function()
		gModelPetDreanLand:OnPetDreamLandOccupiedReq(refId)
	end

	---@type boolean 是否可以占领
	local isCanOccupy = gModelPetDreanLand:CheckIsCanOccupy()
	local isEmpty = data.isEmpty
	if isEmpty then

		--[[
                --- 不做额外判断，不用处理当前幻境是否已有占领
                ---@type StructPetDreamLandPointData
                local myPointData = gModelPetDreanLand:GetPointDatasByRefId(self._refId)
                local curLandHasMyData = myPointData ~= nil
                if curLandHasMyData then
                    if LOG_INFO_ENABLED then
                        printInfoNR("当前幻境已经有占领了，不能继续占领")
                    end
                    return
                end]]

		if isCanOccupy then
			func()
		else
			local longestPointData = gModelPetDreanLand:GetPlayerOccupyLongestTimeData()
			if longestPointData then
				if self._getRewardState then return end

				self:SaveWndTips440004(longestPointData,func)
			else
				func()
			end
		end
	else
		---@type StructPetDreamLandPointData
		local serData = data.serData
		if serData:CheckIsMyPoint() then

			-- 点击自己的小人无反应
			if not isLimit then
				cancleFunc()
				return
			end

			--- 自己的据点，离开据点操作

			local targetPointData = {
				refId = refId,
				pointData = serData
			}
			self:SaveWndTips440005(targetPointData,function()
				gModelPetDreanLand:OnPetDreamLandLeftPointReq(refId,serData.id)
			end)
--[[
			local petDreamlandLoss = gModelPetDreanLand:GetConfigPetDreamlandLoss()
			self:OpenCommonTips(440005,{serData:GetHasOccupyTimeStr(),petDreamlandLoss},function()
				gModelPetDreanLand:OnPetDreamLandLeftPointReq(refId,serData.id)
			end)]]
			return
		end

		if serData:CheckHasInitProtect() and (isLimit or self:GetNoLimitShowEffState()) then
			cancleFunc()
			--- 保护状态中
			GF.ShowMessage(ccClientText(43378))
			return
		end

		if isLimit then
			gModelPetDreanLand:OpenPetDreamLandPass(refId,serData)
		else
			gModelPetDreanLand:OpenPetDreamLandNoFightPoint(refId,serData)
		end
		cancleFunc()
	end
end

function UIPeWishLandMin:ShowAdditionTimer()
	local showWeekHappy = self:CheckIsWeek()
	if not showWeekHappy then return end
	self:InitShowList()
end

function UIPeWishLandMin:RefreshClickMask()
	CS.ShowObject(self.mClickMask,self._showClickMask)
end

function UIPeWishLandMin:OnClickBtnRight()
	self:ChangePage()
end

function UIPeWishLandMin:ChecksIsSel(itemdata)
	return itemdata.index == self._page
end

function UIPeWishLandMin:SaveWndTips440004(data,func)
	self._wndTipsId = 440004
	self._atkFunc = func
	self._getRewardState = true
	self._targetPointData = data
	gModelPetDreanLand:OnPetDreamLandPointRewardReq(data.refId)
end

function UIPeWishLandMin:ChangePage(isLeft)
	local optNum = isLeft and -1 or 1
	local newPage = optNum + self._page
	if newPage < 1 then return end
	if newPage > self._allPage then return end
	self._page = newPage

	self:RefreshPointList()
	self:RereshBtnReturnMySelf()
end

function UIPeWishLandMin:RefreshView()

	self._pageDatas = {}

	---@type StructPetDreamLandData
	local landData = self._landData
	local refId = landData and landData.refId or self._refId

	local ref = gModelPetDreanLand:GetPetDreamlandRef(refId)
	if ref then
		self:SetWndEasyImage(self.mBg,ref.bg)
	end
	self:SetWndText(self.mTitle,gModelPetDreanLand:GetPetDreamlandName(refId))


	local num = gModelPetDreanLand:GetPetDreamlandNum(refId)
	local isLimit = gModelPetDreanLand:CheckPetDreamlandIsLimit(refId)
	local isNotLimit = not isLimit

	---@type boolean 玩家是否已占领
	local isOccupy = gModelPetDreanLand:CheckPointRefIdIsOccupy(refId)

	local pageNum = isLimit and self.limitPageNum or self.notLimitPageNum

	---@type table<StructPetDreamLandPointData>
	local pointDatas = landData and landData:GetPointDatas() or {}
	local occupyNum = #pointDatas

	---@type boolean 是否有空位
	local isHasPoint = num > occupyNum

	local pageDatas = {}
	local emptyNum = 0
	if isLimit then
		emptyNum = num - occupyNum
	else
		emptyNum = self.notLimitPageNum - occupyNum
	end
	local showNum = isLimit and num or self.notLimitPageNum
	local index = 1
	local pages = math.ceil(showNum / pageNum)
	--- 已占领或者无空位
	if isOccupy or emptyNum < 1 then
		for i = 1,pages do
			local datas = {}
			for idx = 1,pageNum do
				---@type StructPetDreamLandPointData
				local serData = pointDatas[index]
				table.insert(datas,{
					index = index,
					serData = serData,
					isEmpty = serData == nil,
					refId = refId,
				})
				index = index + 1
			end
			pageDatas[i] = datas
		end
	else
		--- 2024/8/6：玩家未占领时，只显示一个空位
		local userIndex = 1

		--- 已经显示空
		local alreadyShowEmpty = false
		for i = 1,pages do
			local datas = {}
			for idx = 1,pageNum do
				---@type StructPetDreamLandPointData
				local serData = nil
				if alreadyShowEmpty then
					if pointDatas[userIndex] then
						serData = pointDatas[userIndex]
						userIndex = userIndex + 1
					end
				else
					alreadyShowEmpty = true
				end
				table.insert(datas,{
					index = index,
					serData = serData,
					isEmpty = serData == nil,
					refId = refId,
				})
				index = index + 1
			end
			pageDatas[i] = datas
		end


--[[		for i = 1,pages do
			local datas = {}
			for idx = 1,pageNum do
				---@type StructPetDreamLandPointData
				local serData = nil
				if index > emptyNum then
					serData = pointDatas[userIndex]
					userIndex = userIndex + 1
				end
				table.insert(datas,{
					index = index,
					serData = serData,
					isEmpty = serData == nil,
					refId = refId,
				})
				index = index + 1
			end
			pageDatas[i] = datas
		end]]
	end

	if self._page > pages then
		self._page = pages
	end

	self._pageDatas = pageDatas

	if isLimit then
		local showLimitNum = pages
		self._allPage = showLimitNum

		local showChangeBtn = showLimitNum > UIPeWishLandMin.SHOW_CHANGEBTN_NUM
		CS.ShowObject(self.mBtnLeft,showChangeBtn)
		CS.ShowObject(self.mBtnRight,showChangeBtn)
	end

	self:RefreshViewShow()

	self:InitNeedAddItemList()

	CS.ShowObject(self.mLimitedDiv,isLimit)
	CS.ShowObject(self.mNoLimitedDiv,isNotLimit)

	CS.ShowObject(self.mLimitedBotDiv,isLimit)
	CS.ShowObject(self.mNoLimitedBotDiv,isNotLimit)

	if self:CheckHasMySelfPoint() then
		if LOG_INFO_ENABLED then
			printInfoNR2("萌宠幻境：",">> 该模式下有自己的据点，开启倒计时")
		end
	else
		if LOG_INFO_ENABLED then
			printInfoNR2("萌宠幻境：",">> 该模式下没有自己的据点，关闭倒计时")
		end
	end

	self:InitShowList()
	self:RereshBtnReturnMySelf()
end

function UIPeWishLandMin:RefreshLimitedBotDiv()
	self:RefreshFightNumTxt()
	self:InitPointList()
end

function UIPeWishLandMin:UpdateChangeBtnState()
	local showLeft = self._page ~= 1
	local showRight = self._page ~= self._allPage
	CS.ShowObject(self.mBtnLeft,showLeft)
	CS.ShowObject(self.mBtnRight,showRight)
end

function UIPeWishLandMin:OnClickVipImg()
	local vip = gModelPlayer:GetVipLevel()
	if vip < 1 then
		GF.OpenWndBottom("UIHuiYPay",{page = 2})
		return
	end
	self:ShowVipDesc()
end

function UIPeWishLandMin:OpenWndTips440005(loseItemList)
	local targetPointData = self._targetPointData
	if not targetPointData then return end

	---@type StructPetDreamLandPointData
	local pointData = targetPointData.pointData
	local petDreamlandLoss = gModelPetDreanLand:GetConfigPetDreamlandLoss()
	--local params = {pointData:GetHasOccupyTimeStr(),petDreamlandLoss}
	local params = {pointData:GetHasOccupyDetailTimeStr(),petDreamlandLoss}
	self:OpenCommonTips(self._wndTipsId,params,self._atkFunc,loseItemList)
end

function UIPeWishLandMin:OnClickBtnReturnMySelf()
	if not self._pageDatas then return end
	local myPage
	for page,v in pairs(self._pageDatas) do
		if myPage then break end
		for key,val in pairs(v) do
			---@type StructPetDreamLandPointData
			local serData = val.serData
			if serData and serData:CheckIsMyPoint() then
				myPage = page
				break
			end
		end
	end
	if not myPage then return end

	self._page = myPage
	self:RefreshPointList()
	self:RereshBtnReturnMySelf()
end

function UIPeWishLandMin:OnClickBtnEnd()
	local refId = self._refId
	if gModelPetDreanLand:CheckPointRefIdIsOccupy(refId) then
		---@type StructPetDreamLandPointData
		local data = gModelPetDreanLand:GetPointDatasByRefId(refId)
--[[		local petDreamlandLoss = gModelPetDreanLand:GetConfigPetDreamlandLoss()
		gModelGeneral:OpenUIOrdinTips({
			refId = 440005,
			para = {data:GetHasOccupyTimeStr(),petDreamlandLoss},
			func = function()
				gModelPetDreanLand:OnPetDreamLandLeftPointReq(refId,data.id)
			end
		})]]
		local targetPointData = {
			refId = refId,
			pointData = data
		}
		local func = function()
			gModelPetDreanLand:OnPetDreamLandLeftPointReq(refId,data.id)
		end
		self:SaveWndTips440005(targetPointData,func)

	else
		local func = function()
			gModelPetDreanLand:OnPetDreamLandOccupiedReq(refId)
		end
		local isCanOccupy = gModelPetDreanLand:CheckIsCanOccupy()
		if isCanOccupy then
			func()
		else
			local longestPointData = gModelPetDreanLand:GetPlayerOccupyLongestTimeData()
			if longestPointData then
				if self._getRewardState then return end

				self:SaveWndTips440004(longestPointData,func)
			end
		end
	end
end

function UIPeWishLandMin:ShowVipDesc()
	self._showClickMask = not self._showClickMask
	self:RefreshClickMask()
end

function UIPeWishLandMin:RefreshFightNumTxt()
	local fightNumTxtId = 43382
	local fightNum = gModelPetDreanLand:GetHasFreeGrabNum()
	if fightNum < 1 then
		fightNumTxtId = 43404
		fightNum = gModelPetDreanLand:GetHasPayGrabNum()
	end
	self:SetWndText(self.mFightNumTxt,string.replace(ccClientText(fightNumTxtId),fightNum))
end


function UIPeWishLandMin:GetNeedAddItemList()
	local list = {}
	local splitRef = gModelPetDreanLand:GetSplitPetDreamlandRefByRefId(self._refId)
	if splitRef then
		list = splitRef.showRewardList
	end
	return list
end

function UIPeWishLandMin:GetPageData()
	local pageData = self._pageDatas[self._page]
	return pageData
end

function UIPeWishLandMin:OnDrawShowCell(list, item, itemdata, itempos)
	local OutputDiv = self:FindWndTrans(item,"OutputDiv")
	local OutputTxt = self:FindWndTrans(OutputDiv,"OutputTxt")
	local OutputItemList = self:FindWndTrans(OutputDiv,"OutputItemList")

	self:SetWndText(OutputTxt,itemdata.txt)
	self:InitOutputItemList(OutputItemList,itemdata.list)
end

function UIPeWishLandMin:SetItemAlphaTween(root)
	CS.ShowObject(root,true)
	local seqKey = root:GetInstanceID()
	self:TweenSeqKill(seqKey)
	local csCanvasGroup = root:GetComponent(typeofCanvasGroup)
	csCanvasGroup.alpha = 1
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		seq:AppendInterval(3)
		local tween1 = YXTween.TweenFloat(1, 0, 0.5, function(ival)
			csCanvasGroup.alpha = ival
		end)
		seq:Append(tween1)
		return seq
	end)
	seqTween:OnStepComplete(function()
		self:TweenSeqKill(seqKey)
		if (isVisible) then
			csCanvasGroup.interactable = true
			csCanvasGroup.blocksRaycasts = true
		end
		local wndVisibleWait = self._TweenSeq_AlphaInOut
		if (wndVisibleWait ~= nil) then
			self:TweenSeq_AlphaInOut(wndVisibleWait)
		end
		self._TweenSeq_AlphaInOut = nil
	end)
	seqTween:PlayForward()
end

function UIPeWishLandMin:OnClickBtnReport()
	gModelPetDreanLand:OpenPetDreamLandReport()
end

function UIPeWishLandMin:On_Item_Change()
	self:InitNeedAddItemList()
end

function UIPeWishLandMin:OnPDLReportResultStatus(data)
	if not data then return end
	if data.type == 4 or data.type == 0 then
		self:CheckHasType4SettlementUI()
		self._mySelfOutputList = nil
		self:InitShowList()
	end
end

function UIPeWishLandMin:InitOutputItemList(listTrans,list)
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans, list, function(...) self:OnDrawOutputItemCell(...) end)
	end
end

--- 有数量限制
function UIPeWishLandMin:RefreshLimitedDiv()
	local pageData = self:GetPageData()

	--- 隐藏的节点
	local maskNumMap = {}
	local num = gModelPetDreanLand:GetPetDreamlandNum(self._refId)
	local childCount = self.limitPageNum
	local showNum = childCount * self._page
	if showNum > num then
		local hideNum = showNum - num
		for i = 0,hideNum-1 do
			maskNumMap[childCount-i] = true
		end
	end

	for i = 1,childCount do
		local playerTrans = self:FindWndTrans(self.mLimitedDiv,"Player" .. i)
		local showRoot = not maskNumMap[i]
		if showRoot then
			self:SetPlayer(playerTrans,pageData[i],i,true)
		end
		CS.ShowObject(playerTrans,showRoot)
	end
	self:RefreshTimer()

	self:TimerStop(self._timerKey)
	self:TimerStart(self._timerKey,1,false,-1)
end

function UIPeWishLandMin:StartUpdateOutputTimer()
--[[	if not self._recordMySelfOutputInfo then
		self:TimerStop(self._updateOutputTimeKey)
		return
	end
	if not gModelPetDreanLand:DreamLandIsOpen() then
		--- 赛季结束了，取消掉获得显示
		self._mySelfOutputList = nil
		self:InitShowList()
		return
	end
	local outputInfo = self._recordMySelfOutputInfo
	--gModelPetDreanLand:OnPetDreamLandPointCheckReq(outputInfo.refId,outputInfo.pointId)
	gModelPetDreanLand:OnPetDreamLandPointRewardReq(outputInfo.refId)]]

	if not gModelPetDreanLand:CheckPointRefIdIsOccupy(self._refId) then
		self:TimerStop(self._updateOutputTimeKey)
		return
	end

	---@type StructPetDreamLandPointData
	local data = gModelPetDreanLand:GetPointDatasByRefId(self._refId)
	if not data then
		self:TimerStop(self._updateOutputTimeKey)
		return
	end

	local starOccupyTime = data.starOccupyTime
	local timeLeft = math.floor(GetTimestamp() - starOccupyTime)
	if timeLeft % self._petDreamlandTime == 0 then
		gModelPetDreanLand:OnPetDreamLandPointRewardReq(self._refId)
	end
end

function UIPeWishLandMin:GetPlayerTransInfo(item)
	if not self._playerTransInfos then
		self._playerTransInfos = {}
	end
	local key = item:GetInstanceID()
	local playerTransInfo = self._playerTransInfos[key]
	if not playerTransInfo then
		local NoHasDiv = self:FindWndTrans(item,"NoHasDiv")
		local ZhenImg = self:FindWndTrans(NoHasDiv,"ZhenImg")

		local HasDiv = self:FindWndTrans(item,"HasDiv")
		local Common = self:FindWndTrans(HasDiv,"Common")
		local TimeDiv = self:FindWndTrans(Common,"TimeDiv")
		local PowerDiv = self:FindWndTrans(HasDiv,"PowerDiv")

		local BubbleBg = self:FindWndTrans(item,"BubbleBg")

		playerTransInfo = {
			NoHasDiv = NoHasDiv,
			ZhenImg = ZhenImg,
			AddImg = self:FindWndTrans(ZhenImg,"AddImg"),
			NoHasEffRoot = self:FindWndTrans(ZhenImg,"NoHasEffRoot"),

			HasDiv = HasDiv,
			QualityZhen = self:FindWndTrans(HasDiv,"QualityZhen"),
			Name = self:FindWndTrans(HasDiv,"NameBg/Name"),
			SpineRoot = self:FindWndTrans(HasDiv,"SpineRoot"),
			MyDiv = self:FindWndTrans(Common,"MyDiv"),
			OtherDiv = self:FindWndTrans(Common,"OtherDiv"),
			TimeDiv = TimeDiv,
			TimeTxt = self:FindWndTrans(TimeDiv,"TimeTxt"),
			PowerDiv = PowerDiv,
			PowerTxt = self:FindWndTrans(PowerDiv,"PowerTxt"),
			ShieldEff = self:FindWndTrans(HasDiv,"ShieldEff"),

			BubbleBg = BubbleBg,
			BubbleTxt = self:FindWndTrans(BubbleBg,"BubbleTxt"),
		}
		self._playerTransInfos[key] = playerTransInfo
	end
	return playerTransInfo
end

function UIPeWishLandMin:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.page = self._page
	wndArgList.landData = gModelPetDreanLand:GetPetDreamLandDataByRefId(self._refId)
	wndArgList.refId = self._refId
	wndArgList.isHistory = true
	return list
end

function UIPeWishLandMin:StartShowBubbleTimer()
	local showBubbleInfos = {}
	for k,v in pairs(self._showBubbleInfoMap) do
		table.insert(showBubbleInfos,v)
	end
	if #showBubbleInfos < 1 then
		if LOG_INFO_ENABLED then
			printInfoNR2("萌宠幻境：",">> 没有节点信息，不展示")
		end
		--self:TimerStop(self._showBubbleTimerKey)
		return
	end
	local initPetDreamlandTextRefs = gModelPetDreanLand:GetInitPetDreamlandTextRef()
	local refNum = #initPetDreamlandTextRefs
	---@type number 随机给 1~2 个小人冒泡文本 ，每隔3分钟，继续给随机 1~2 个小人冒泡文本
	local showNum = math.random(1,2)
	if LOG_INFO_ENABLED then
		printInfoNR2("萌宠幻境：",">> 随机展示 " .. showNum .. " 个 小人")
	end
	for i = 1,showNum do
		local itemRandom = math.random(1,#showBubbleInfos)
		local item = table.remove(showBubbleInfos,itemRandom)
		if item then
			local randomRefNum = math.random(1,refNum)
			---@type V_PetDreamlandTextRef
			local ref = initPetDreamlandTextRefs[randomRefNum]
			if ref then
				if LOG_INFO_ENABLED then
					printInfoNR2("萌宠幻境：",">> 随机到文本id " .. ref.refId)
				end
				self:_SetBubbleShow(item,ref)
			end
		end
	end
end

function UIPeWishLandMin:OnPetDreamLandOccupiedResp()
	self._openTips = false
	if LOG_INFO_ENABLED then
		printInfoNR2("PetDreamLandOccupiedResp",">> GetTimestamp()：" .. GetTimestamp())
		---@type StructPetDreamLandPointData
		local data = gModelPetDreanLand:GetPointDatasByRefId(self._refId)
		if data then
			printInfoNR2("PetDreamLandOccupiedResp",">> data.starOccupyTime：" .. data.starOccupyTime)
		end
	end
end

function UIPeWishLandMin:CheckIsWeek()
	return LUtil.CheckIsWeekend(GetTimestamp())
end

function UIPeWishLandMin:RefreshTimer()
	--- 刷新玩家的倒计时
	for k,v in pairs(self._timeDatasKey) do
		---@type StructPetDreamLandPointData
		local serData = v.serData
		local starOccupyTime = serData.starOccupyTime
		local timeLeft = math.floor(GetTimestamp() - starOccupyTime)
		--self:SetWndText(v.TimeTxt,LUtil.FormatTimespanNumber(timeLeft))

		--- 修改为 时分秒 的格式
		self:SetWndText(v.TimeTxt,LUtil.FormatTimeStr1(timeLeft))

		CS.ShowObject(v.TimeDiv,true)

		local ShieldEff = v.ShieldEff
		local effectName
		if v.isLimit or self:GetNoLimitShowEffState() then
			effectName = serData:GetProtectEff()
		end
		local showEff = effectName
		if showEff then
			if v.effectName ~= effectName then
				local effectKey = v.effectKey

				self:DestroyWndEffectByKey(effectKey)

				self:CreateWndEffect_Ex({
					trans = ShieldEff,
					effName = effectName,
					effKey = effectKey,
				})
			end
		end
		CS.ShowObject(ShieldEff,showEff)
	end
end

---@param isLimit boolean 是否有限人数
function UIPeWishLandMin:SetPlayer(item,data,index,isLimit)
	local playerTransInfo = self:GetPlayerTransInfo(item)

	local BubbleBg = playerTransInfo.BubbleBg

	local seqKey = BubbleBg:GetInstanceID()
	local tween = self:TweenSeqFind(seqKey)
	if tween then
		self:TweenSeqKill(seqKey)
	end

	CS.ShowObject(BubbleBg,false)

	local isHasData = data ~= nil
	if isHasData then
		local TimeDiv = playerTransInfo.TimeDiv
		CS.ShowObject(TimeDiv,false)

		local TimeTxt = playerTransInfo.TimeTxt
		self:SetWndText(TimeTxt,"")

		local isEmpty = data.isEmpty
		if isEmpty then
			local effKey = "effect_" .. index
			self:CreateWndEffect_Ex({
				trans = playerTransInfo.NoHasEffRoot,
				effName = "fx_ui_mchj_zhen",
				effKey = effKey,
				endFunc = function()
				end,
			})


			self._timeDatasKey[index] = nil

			self._showBubbleInfoMap[index] = nil
		else
			---@type StructPetDreamLandPointData
			local serData = data.serData

			self:SetWndText(playerTransInfo.Name,serData:GetPlayerShowName())

			local key = "Spine" .. index
			local spine = self:FindWndSpineByKey(key)
			if spine then
				self:DestroyWndSpineByKey(key)
			end

			local spineName = serData:GetShowPlayerInfoFigureSpine(serData:GetPlayerId())
			if spineName then
				---@param dpSpine LDisplaySpine
				self:CreateWndSpine(playerTransInfo.SpineRoot,spineName,key,false,function(dpSpine)

				end)
			end

			local isMyPoint = serData:CheckIsMyPoint()
			local MyDiv = playerTransInfo.MyDiv
			if isMyPoint then
				self:SetTextTile(MyDiv,ccClientText(43377))
			end
			CS.ShowObject(MyDiv,isMyPoint)

			--- 根据战报判断是否是敌人，即 防守失败
			local isEnemy = gModelPetDreanLand:CheckIsEnemy(serData:GetPlayerId())
			local OtherDiv = playerTransInfo.OtherDiv
			if isEnemy then
				self:SetTextTile(OtherDiv,ccClientText(43314))
			end
			CS.ShowObject(OtherDiv,isEnemy)

			self:SetWndText(playerTransInfo.PowerTxt,LUtil.PowerNumberCoversion(serData:GetMainShowPlayerPower()))

			local ShieldEff = playerTransInfo.ShieldEff
			local effectKey = "effect" .. index
			local effectName
			if isLimit or self:GetNoLimitShowEffState() then
				effectName = serData:GetProtectEff()
			end
			local showEff = effectName
			if showEff then
				self:CreateWndEffect_Ex({
					trans = ShieldEff,
					effName = effectName,
					effKey = effectKey,
				})
			else
				self:DestroyWndEffectByKey(effectKey)
			end
			CS.ShowObject(ShieldEff,showEff)

			self._timeDatasKey[index] = {
				serData = serData,
				TimeTxt = TimeTxt,
				TimeDiv = TimeDiv,
				ShieldEff = ShieldEff,
				effectKey = effectKey,
				effectName = effectName,
				isLimit = isLimit,
			}

			self._showBubbleInfoMap[index] = {
				BubbleBg = BubbleBg,
				BubbleTxt = playerTransInfo.BubbleTxt,
			}
		end

		CS.ShowObject(playerTransInfo.NoHasDiv,isEmpty)
		CS.ShowObject(playerTransInfo.HasDiv,not isEmpty)
	end
	self:SetWndClick(item,function()
		self:OnClickPlayer(data,isLimit)
	end)
	CS.ShowObject(item,isHasData)
end

function UIPeWishLandMin:OnPetDreamLandLeftPointResp()
	gModelPetDreanLand:OpenPetDreamLandReportResult()
	self._mySelfOutputList = nil
	self._recordMySelfOutputInfo = nil
	self._landData = gModelPetDreanLand:GetPetDreamLandDataByRefId(self._refId)
	self:RefreshView()
end

function UIPeWishLandMin:InitText()
	self:SetWndText(self.mTxtClose, ccClientText(42010))
	self:SetWndText(self.mFightDesc,ccClientText(43381))
	self:SetTextTile(self.mBtnReport,ccClientText(43308))
	self:SetWndButtonText(self.mBtnReturnMySelf,ccClientText(43394))
	local weekStr = gModelPetDreanLand:GetpetDreamlandWeekenBuff(true)
	self:SetWndText(self.mWeekTxt,string.replace(ccClientText(43397),weekStr))
	self:SetTextTile(self.mVipImg,ccClientText(11903))
end

function UIPeWishLandMin:OnClickPoint(itemdata)
	if self:ChecksIsSel(itemdata) then return end
	self._page = itemdata.index
	self:RereshBtnReturnMySelf()
	self:RefreshPointList(false)
end

function UIPeWishLandMin:OnTimer(key)
	if key == self._timerKey then
		self:RefreshTimer()
	elseif key == self._cdTimeKey then
		self:StartCDTimer()
		self:CheckIsShowWeekHappy()
	elseif key == self._cdNoTimeKey then
		self:StartNoCDTimer()
	elseif key == self._updateOutputTimeKey then
		self:StartUpdateOutputTimer()
	elseif key == self._showBubbleTimerKey then
		self:StartShowBubbleTimer()
	elseif key == self._showAdditionTimerKey then
		self:ShowAdditionTimer()
	end
end

function UIPeWishLandMin:RereshBtnReturnMySelf()
	---@type boolean 玩家是否已占领
	local isOccupy = gModelPetDreanLand:CheckPointRefIdIsOccupy(self._refId)
	local isShowReturnMySelf = isOccupy
	if isShowReturnMySelf then
		isShowReturnMySelf = self._page ~= 1
	end
	CS.ShowObject(self.mBtnReturnMySelf,isShowReturnMySelf)
	self:UpdateChangeBtnState()
end

function UIPeWishLandMin:OnPetDreamLandPlayerDataChangeResp(pb)
	self:RefreshFightNumTxt()
end

---@return boolean 是否显示保护罩，无限制的把保护盾去掉
function UIPeWishLandMin:GetNoLimitShowEffState()
	return false
end

function UIPeWishLandMin:InitShowList()
	local list = self:GetShowList()
	local uiList = self:FindUIScroll("mShowList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mShowList")
		uiList:Create(self.mShowList, list, function(...) self:OnDrawShowCell(...) end)
	end
end

function UIPeWishLandMin:InitPointList()
	local list = self:GetPointList()
	local uiList = self:FindUIScroll("mPointList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mPointList")
		uiList:Create(self.mPointList, list, function(...) self:OnDrawPointCell(...) end)
	end
	uiList:EnableScroll(#list > 5,true)
end

function UIPeWishLandMin:OpenWndTips440004(loseItemList)
	local targetPointData = self._targetPointData
	if not targetPointData then return end

	local name = gModelPetDreanLand:GetPetDreamlandName(targetPointData.refId)
	---@type StructPetDreamLandPointData
	local pointData = targetPointData.pointData
	local petDreamlandLoss = gModelPetDreanLand:GetConfigPetDreamlandLoss()
	--local params = {name,pointData:GetHasOccupyTimeStr(),petDreamlandLoss}
	local params = {name,pointData:GetHasOccupyDetailTimeStr(),petDreamlandLoss}
	self:OpenCommonTips(self._wndTipsId,params,self._atkFunc,loseItemList)
end

---@param ref V_PetDreamlandTextRef
function UIPeWishLandMin:_SetBubbleShow(item,ref)
	local BubbleTxt = item.BubbleTxt
	self:SetWndText(BubbleTxt,ccLngText(ref.desc))
	self:SetItemAlphaTween(item.BubbleBg)
end

function UIPeWishLandMin:RefreshVip()
	local vipLv = gModelPlayer:GetVipLevel()
	local vipRef = gModelVip:GetRefByVipLv(vipLv)
	if not vipRef then return end

	--- 2024/6/25：这里不用显示玩家的VIP等级数字，就显示VIP就好了，不管他V几都不用显示数字，，美术效果图如右
--[[	local icon = vipRef.icon
	self:SetWndEasyImage(self.mVipImg,icon,function()
		CS.ShowObject(self.mVipImg,true)
	end,true)]]

	local desc = gModelVip:GetVipPowerDesByTypeAndLv(ModelVip.TYPE_DES_PETDREAMLAND,vipLv)
	self:SetWndText(self.mVipDesc,desc)
end

function UIPeWishLandMin:OnDrawNeedAddItemCell(list, item, itemdata, itempos)
	local IconTrans = self:FindWndTrans(item,"IconDiv/Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local AddBtnTrans = self:FindWndTrans(item,"BtnDiv/AddBtn")

	local itemId = itemdata.itemId
	local itemNum = LUtil.NumberCoversion(gModelItem:GetNumByRefId(itemId))

	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans,icon,function()
		CS.ShowObject(IconTrans,true)
	end,true)

	self:SetWndText(NumTrans,itemNum)

	local showAddBtn = false
	---@type V_ItemRef
	local itemRef = gModelItem:GetRefByRefId(itemId)
	if itemRef and not string.isempty(itemRef.jump) then
		showAddBtn = true
	end
	if showAddBtn then
		self:SetWndClick(AddBtnTrans,function()
			self:OnClickAddBtnFunc(itemdata)
		end)
	end
	CS.ShowObject(AddBtnTrans,showAddBtn)
end

function UIPeWishLandMin:OnPetDreamLandPointCheckResp(pb)
--[[	self._mySelfOutputList = nil
	local showMySelfOutput = false
	local outputInfo = self._recordMySelfOutputInfo
	if outputInfo then
		---@type StructPetDreamLandPointData
		local pointData = gModelPetDreanLand:GetPetDreamLandPointData(pb.pointData)
		local refId = outputInfo.refId
		if refId == pb.refId and pointData.id == outputInfo.pointId then
			self._mySelfOutputList = pointData.itemList

			showMySelfOutput = true
		end
	end
	if showMySelfOutput then
		self:InitShowList()
	end]]

	local pointData = pb.pointData
	if pointData then
		local spointData = gModelPetDreanLand:GetPetDreamLandPointData(pb.pointData)
		local id = pointData.id
		for i,v in ipairs(self._pageDatas) do
			for idx,val in ipairs(v) do
				if val.serData and val.serData.id == id then
					val.serData = spointData
				end
			end
		end
	end
	self:RefreshLimitedDiv()
end

function UIPeWishLandMin:SaveWndTips440005(data,func)
	self._wndTipsId = 440005
	self._atkFunc = func
	self._getRewardState = true
	self._targetPointData = data
	gModelPetDreanLand:OnPetDreamLandPointRewardReq(data.refId)
end

function UIPeWishLandMin:InitNeedAddItemList()
	local list = self:GetNeedAddItemList()
	local uiList = self:FindUIScroll("mNeedAddItemList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mNeedAddItemList")
		uiList:Create(self.mNeedAddItemList, list, function(...) self:OnDrawNeedAddItemCell(...) end)
	end
end

function UIPeWishLandMin:OpenCommonTips(refId,para,func,itemList)
	local resetOpenTipsFunc = function()
		self._openTips = false
	end
	gModelGeneral:OpenUIOrdinTips({
		refId = refId,
		para = para,
		func = function()
			func()
			resetOpenTipsFunc()
		end,
		leftFunc = resetOpenTipsFunc,
		closeFunc = resetOpenTipsFunc,
		itemList = itemList,
		emptyId = 39004,
	})
end


function UIPeWishLandMin:CheckHasMySelfPoint()
	self._recordMySelfOutputInfo = nil
	self:TimerStop(self._updateOutputTimeKey)
	if not gModelPetDreanLand:CheckPointRefIdIsOccupy(self._refId) then return end

	local longestPointData = gModelPetDreanLand:GetPlayerOccupyLongestTimeData()
	if not longestPointData then return end

	---@type StructPetDreamLandPointData
	local pointData = longestPointData.pointData
	if not pointData then return end

	self._recordMySelfOutputInfo = {
		refId = self._refId,
		pointId = pointData.id
	}
	--self:StartUpdateOutputTimer()
	gModelPetDreanLand:OnPetDreamLandPointRewardReq(self._refId)
	self:TimerStart(self._updateOutputTimeKey,1,false,-1)
	return true
end

--- 无数量限制
function UIPeWishLandMin:RefreshNoLimitedDiv()
	local pageData = self:GetPageData()
	local childCount = self.notLimitPageNum
	for i = 1,childCount do
		local playerTrans = self:FindWndTrans(self.mNoLimitedDiv,"Player" .. i)
		self:SetPlayer(playerTrans,pageData[i],i)
	end
	if not self._init then
		self._init = true
		self:StartShowBubbleTimer()
		self:TimerStop(self._showBubbleTimerKey)
		self:TimerStart(self._showBubbleTimerKey,UIPeWishLandMin.SHOW_BUBBLE_TIME,false,-1)
	end
end

function UIPeWishLandMin:RefreshPointList(movePos)
	self:RefreshViewShow()

	local uiPointList = self:FindUIScroll("mPointList")
	if not uiPointList then return end

	if movePos == nil then
		movePos = true
	end
	if movePos then
		uiPointList:MoveToPos(self._page)
	end

	local uiList = uiPointList:GetList()
	uiList:RefreshList()
end

function UIPeWishLandMin:OnDrawOutputItemCell(list, item, itemdata, itempos)
	local IconDiv = self:FindWndTrans(item,"IconDiv")
	local Icon = self:FindWndTrans(IconDiv,"Icon")
	local Num = self:FindWndTrans(item,"Num")

	local itemId = itemdata.itemId
	local showIcon = itemId and itemId > 0
	if showIcon then
		local icon = gModelItem:GetItemIconByRefId(itemId)
		self:SetWndEasyImage(Icon,icon,function()
			CS.ShowObject(Icon,true)
		end,true)
	end
	CS.ShowObject(IconDiv,showIcon)

	self:SetWndText(Num,itemdata.numStr)
end

--- 是否显示周末狂欢
function UIPeWishLandMin:CheckIsShowWeekHappy()
	local showWeekHappy = self:CheckIsWeek()
	CS.ShowObject(self.mWeekDiv,showWeekHappy)
end

function UIPeWishLandMin:InitData()
	---@type StructPetDreamLandData
	self._landData = self:GetWndArg("landData")

	self._refId = self:GetWndArg("refId")

	if self._refId and self._refId > 0 then
		self._landData = gModelPetDreanLand:GetPetDreamLandDataByRefId(self._refId)
	end

	self._page = self:GetWndArg("page") or 1

	self:SetWndText(self.mTitle,gModelPetDreanLand:GetPetDreamlandName(self._refId))

	self.limitPageNum = self.mLimitedDiv.childCount
	self.notLimitPageNum = self.mNoLimitedDiv.childCount
end

function UIPeWishLandMin:OnDrawPointCell(list, item, itemdata, itempos)
	local Sel = self:FindWndTrans(item,"Sel")
	local UIText = self:FindWndTrans(item,"UIText")
	local index = itemdata.index
	local isSel = self:ChecksIsSel(itemdata)
	CS.ShowObject(Sel,isSel)
	self:SetWndText(UIText,index)
	self:SetWndClick(item,function()
		self:OnClickPoint(itemdata)
	end)
end

function UIPeWishLandMin:OnPetDLPointRefresh()
	self._landData = gModelPetDreanLand:GetPetDreamLandDataByRefId(self._refId)
	if self._landData then
		for k,v in pairs(self._landData.pointDataMap) do
			printInfoNR("玩家时间：" .. v.starOccupyTime)
		end
	end
	self:RefreshView()
end

function UIPeWishLandMin:GetPointList()
	local list = {}
	if self._allPage and self._allPage > 1 then
		for i = 1,self._allPage do
			table.insert(list,{
				index = i,
			})
		end
	end
	return list
end

function UIPeWishLandMin:InitMsg()
	self:WndEventRecv(EventNames.On_Item_Change,function (...) self:On_Item_Change() end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandLeftPointResp,function(...) self:OnPetDreamLandLeftPointResp(...) end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandPointCheckResp,function(...) self:OnPetDreamLandPointCheckResp(...) end)
	self:WndNetMsgRecv(LProtoIds.petDreamLandPointRewardResp,function(...) self:OnPetDreamLandPointRewardResp(...) end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandOccupiedResp,function(...) self:OnPetDreamLandOccupiedResp(...) end)
	self:WndEventRecv(EventNames.PET_DL_POINT_REFRESH,function (...) self:OnPetDLPointRefresh() end)
	self:WndEventRecv(EventNames.PLAYER_VIP_LEVEL_CHANGE,function (...) self:InitShowList() end)
	self:WndNetMsgRecv(LProtoIds.PetDreamLandPlayerDataChangeResp,function(...) self:OnPetDreamLandPlayerDataChangeResp(...) end)
	self:WndEventRecv(EventNames.PDL_REPORTRESULT_STATUS,function (...) self:OnPDLReportResultStatus(...) end)
end

function UIPeWishLandMin:OnClickAddBtnFunc(itemdata)
	gModelGeneral:OpenGetWayWnd({itemId = itemdata.itemId,srcWnd = self:GetWndName()})
end

function UIPeWishLandMin:RefreshNoLimitedBotDiv()
	local btnName = ""
	if gModelPetDreanLand:CheckPointRefIdIsOccupy(self._refId) then
		btnName = ccClientText(43389)
	else
		btnName = ccClientText(43390)
	end
	self:SetWndButtonText(self.mBtnEnd,btnName)


	self:TimerStop(self._cdNoTimeKey)
	self:TimerStart(self._cdNoTimeKey,1,false,-1)
end

function UIPeWishLandMin:StartCDTimer()
	local timerStr = gModelPetDreanLand:GetDreamLandTimeStr()
	if gModelPetDreanLand:DreamLandIsOpen() then
		timerStr = string.replace(ccClientText(43301),timerStr)
	end
	self:SetWndText(self.mCDTxt,timerStr)
end

function UIPeWishLandMin:RefreshViewShow()
	local landData = self._landData
	local refId = landData and landData.refId or self._refId

	local isLimit = gModelPetDreanLand:CheckPetDreamlandIsLimit(refId)
	if isLimit then
		--- 有数量显示
		self:RefreshLimitedDiv()
		self:RefreshLimitedBotDiv()
	else
		--- 无数量显示
		self:RefreshNoLimitedDiv()
		self:RefreshNoLimitedBotDiv()
	end
end

function UIPeWishLandMin:CheckHasType4SettlementUI()
	gModelPetDreanLand:CheckHasType4SettlementUI()
end

function UIPeWishLandMin:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnReport,function() self:OnClickBtnReport() end)
	self:SetWndClick(self.mVipImg,function() self:OnClickVipImg() end)
	self:SetWndClick(self.mBtnLeft,function() self:OnClickBtnLeft() end)
	self:SetWndClick(self.mBtnRight,function() self:OnClickBtnRight() end)
	self:SetWndClick(self.mBtnReturnMySelf,function() self:OnClickBtnReturnMySelf() end)
	self:SetWndClick(self.mBtnEnd,function() self:OnClickBtnEnd() end)
	self:SetWndClick(self.mClickMask,function() self:ShowVipDesc() end)
end

function UIPeWishLandMin:OnClickBtnLeft()
	self:ChangePage(true)
end

function UIPeWishLandMin:OnPetDreamLandPointRewardResp(pb)
	local itemTypeMap = {}
	local itemMap = {}
	local itemId
	for i,v in ipairs(pb.itemList) do
		itemId = v.itemId
		if not itemTypeMap[itemId] then
			itemTypeMap[itemId] = v.type
		end
		local item = itemMap[itemId] or 0
		itemMap[itemId] = v.count + item
	end
	local itemList = {}
	for _itemId,itemNum in pairs(itemMap) do
		table.insert(itemList,{
			type = itemTypeMap[_itemId],
			itemId = _itemId,
			count = itemNum
		})
	end

	local pointRefId = pb.refId

	local showMySelfOutput = false
	if self._getRewardState then
		if self._targetPointData and self._targetPointData.refId == pointRefId then
			local petDreamlandLoss = gModelPetDreanLand:GetPetDreamlandLossPercentage()
			local loseItemList = {}
			for i,v in ipairs(itemList) do
				local num = math.floor(v.count * petDreamlandLoss)
				if num > 0 then
					table.insert(loseItemList,{
						type = v.type,
						itemId = v.itemId,
						count = num,
					})
				end
			end

			if self._wndTipsId == 440004 then
				self:OpenWndTips440004(loseItemList)
			elseif self._wndTipsId == 440005 then
				self:OpenWndTips440005(loseItemList)
			end

			self._atkFunc = nil
			self._wndTipsId = nil
			self._getRewardState = false
			self._targetPointData = nil

			self._mySelfOutputList = itemList
			showMySelfOutput = true
		end
	else
		self._mySelfOutputList = nil
		local outputInfo = self._recordMySelfOutputInfo
		if outputInfo then
			local refId = outputInfo.refId
			if refId == pointRefId then
				self._mySelfOutputList = itemList
				showMySelfOutput = true
			end
		end
	end
	if showMySelfOutput then
		self:InitShowList()
	end
end

function UIPeWishLandMin:StartNoCDTimer()
	local showTime = false
	local refId = self._refId
	if gModelPetDreanLand:CheckPointRefIdIsOccupy(refId) then
		---@type StructPetDreamLandPointData
		local data = gModelPetDreanLand:GetPointDatasByRefId(refId)
		if data then
			showTime = true
			local starOccupyTime = data.starOccupyTime
			local timeLeft = math.floor(GetTimestamp() - starOccupyTime)
			--self:SetWndText(self.mNoLimitedBotTime,LUtil.FormatTimespanNumber(timeLeft))
			self:SetWndText(self.mNoLimitedBotTime,LUtil.FormatTimeStr1(timeLeft))
		end
	end
	CS.ShowObject(self.mNoLimitedBotTime.parent,showTime)
end


------------------------------------------------------------------
return UIPeWishLandMin