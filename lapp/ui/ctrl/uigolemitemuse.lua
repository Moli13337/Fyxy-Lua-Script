---
--- Created by LCM.
--- DateTime: 2022/10/31 18:32:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemItemUse:LWnd
local UIGolemItemUse = LxWndClass("UIGolemItemUse", LWnd)

local CS = CS
local UnityEngine = UnityEngine
local typeof = typeof
local typeUISlider = typeof(UnityEngine.UI.Slider)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemItemUse:UIGolemItemUse()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemItemUse:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemItemUse:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemItemUse:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitSlider()
	self:RefreshView()
end

function UIGolemItemUse:UpdataSliderValue(value)
	value = math.floor(value)
	local payUseNum
	if self:CheckIsMax(value) then
		local maxLvNeedExp = self:GetMaxLvNeedExp()
		if not maxLvNeedExp then return end
		local oldUseNum = self._useNum or 0
		local curExp = self:GetCurCanUpExp(oldUseNum)
		payUseNum = oldUseNum + (maxLvNeedExp - curExp)
	else
		payUseNum = value
	end
	self._useNum = payUseNum
	self:UpdateSlider()
	self:InitGolemActStatusList()
	self:RefreshUseNumTxt()
end

function UIGolemItemUse:InitSlider()
	self._sliderComponent = self.mSlider:GetComponent(typeUISlider)
	if (not self._sliderComponent) then
		self._sliderComponent = self.mSlider:AddComponent(typeUISlider)
	end

	LxUiHelper.SetProgress_ValueChanged(self.mSlider, function()
		if self:CheckGolemIsMaxLv() then
			self:UpdateSlider()
			GF.ShowMessage(ccClientText(33262))
		else
			local value = self._sliderComponent.value
			self:UpdataSliderValue(value)
		end
	end)

	self:RefreshSlider()
end

function UIGolemItemUse:GetMaxLvNeedExp()
	if not self._golemMaxLvInfo then return end
	return self._golemMaxLvInfo.exp
end

function UIGolemItemUse:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mSubBtn,function() self:OnClickSubBtnFunc() end)
	self:SetWndClick(self.mAddBtn,function() self:OnClickAddBtnFunc() end)
	self:SetWndClick(self.mCancelBtn,function() self:OnClickCancelBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function() self:OnClickEnterBtnFunc() end)

	self:SetWndClick(self.mValueBg,function() self:OnClickValueBgFunc() end)
end

function UIGolemItemUse:InitGolemActStatusList()
	local list = self:GetGolemActStatusList()
	local uiGolemActStatusList = self._uiGolemActStatusList
	if uiGolemActStatusList then
		uiGolemActStatusList:RefreshList(list)
	else
		uiGolemActStatusList = self:GetUIScroll("uiGolemActStatusList")
		self._uiGolemActStatusList = uiGolemActStatusList
		uiGolemActStatusList:Create(self.mGolemActStatusList,list,function(...) self:OnDrawGolemActStatusCell(...) end)
	end
end

function UIGolemItemUse:OnClickGolemActStatusFunc(itemdata)
	local lvRef = itemdata.lvRef
	if not lvRef then
		GF.ShowMessage(ccClientText(34801))
		--- 找不到这个经验值了
		return
	end
	local needExp = lvRef.needExp
	local curGolemExp = itemdata.curGolemExp
	if curGolemExp > needExp then
		--- 当前魔偶已经超过这个经验了
		return
	end
	local lostExp = needExp - curGolemExp
	local needItemNum = math.floor(lostExp / self._itemToExp)
	if self:CheckIsMax(needItemNum) then return end
	if needItemNum > self._haveNum then
		GF.ShowMessage(ccClientText(34800))
		--- 道具不足
		return
	end
	self._useNum = needItemNum
	self:RefreshIntensifyDiv()
end

function UIGolemItemUse:OnDrawGolemActStatusCell(list,item,itemdata,itempos)
	local NoSelImgTrans = self:FindWndTrans(item,"NoSelImg")
	local SelImgTrans = self:FindWndTrans(item,"SelImg")
	local BtnTrans = self:FindWndTrans(item,"Btn")

	local showSelStatus = false
	local intensifyLv = itemdata.intensifyLv
	local lvRef = itemdata.lvRef
	local isLvHaveUp = lvRef ~= nil
	if isLvHaveUp then
		local needExp = lvRef.needExp
		local nowGolemExp = itemdata.nowGolemExp
		if nowGolemExp >= needExp then
			showSelStatus = true
		end
	end
	self:SetTextTile(NoSelImgTrans,intensifyLv)
	CS.ShowObject(NoSelImgTrans,not showSelStatus)

	self:SetTextTile(SelImgTrans,intensifyLv)
	CS.ShowObject(SelImgTrans,showSelStatus)

	self:SetWndClick(BtnTrans,function()
		self:OnClickGolemActStatusFunc(itemdata)
	end)
end

function UIGolemItemUse:CheckIsMax(value)
	if not self._golemMaxLvInfo then
		return false
	end

	local golemInfo = self._golemInfo
	if not golemInfo then
		return true
	end

	if self:CheckGolemIsMaxLv() then
		GF.ShowMessage(ccClientText(33262))
		return true
	end

	local newExp = self:GetCurCanUpExp(value)
	local maxLvNeedExp = self:GetMaxLvNeedExp()

	if not newExp or not maxLvNeedExp then return false end

	if newExp > maxLvNeedExp then return true end
	return false
end


function UIGolemItemUse:GetUseItemRewardExp(useNum)
	return gModelGolem:GetUseItemRewardExp(useNum,self._itemToExp)
end

function UIGolemItemUse:RefreshSlider()
	self._sliderComponent.minValue = 0
	self._sliderComponent.maxValue = self._haveNum
end

function UIGolemItemUse:RefreshUseNumTxt(showNum)
	local useNum = self._useNum or 0
	showNum = showNum or useNum
	self:SetWndText(self.mValue,showNum)
end

function UIGolemItemUse:RefreshIntensifyDiv()
	self:ChangeSlider()
	self:InitGolemActStatusList()
end

function UIGolemItemUse:OnClickSubBtnFunc()
	if self._useNum <= 0 then
		return
	end
	self._useNum = self._useNum - 1
	self:RefreshIntensifyDiv()
end

function UIGolemItemUse:InitData()
	local itemId = self:GetWndArg("itemId")
	local haveNum = gModelItem:GetNumByRefId(itemId)
	self._itemId = itemId
	self._haveNum = haveNum
	self._useNum = self:GetWndArg("useNum") or 0
	self._itemToExp = gModelGolem:GetGolemItemChangeExpByItemId(self._itemId)
	local golemInfo = self:GetWndArg("golemInfo")
	self._golemInfo = golemInfo

	if golemInfo then
		local maxLvInfo = gModelGolem:GetGolemLvGroupMaxInfoByGolemInfo(golemInfo)
		if maxLvInfo then
			self._golemMaxLvInfo = maxLvInfo
		end
	end

	self._func = self:GetWndArg("func")
end

function UIGolemItemUse:RefreshItemInfo()
	local itemId = self._itemId
	if not itemId then return end

	local haveNum = self._haveNum or 0
	local itemRoot = self.mItemRoot
	local iconTrans = self:FindWndTrans(itemRoot,"CommonUI/Icon")
	local key = itemRoot:GetInstanceID()
	local baseClass = self:GetCommonIcon(key)
	baseClass:Create(iconTrans)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM,itemId,haveNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()

	local itemName = gModelItem:GetNameByRefId(itemId)
	self:SetWndText(self.mItemName,itemName)

	local itemNumStr = string.replace(ccClientText(33236),LUtil.NumberCoversion(haveNum))
	self:SetWndText(self.mItemHaveNum,itemNumStr)

	local desc = gModelItem:GetDescByRefId(itemId)
	self:SetWndText(self.mItemDesc,desc)
end

function UIGolemItemUse:RefreshView()
	self:RefreshItemInfo()
	self:RefreshIntensifyDiv()
end


function UIGolemItemUse:InitMsg()

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemItemUse:UpdateSlider()
	self._sliderComponent.value = self._useNum
end

function UIGolemItemUse:OnClickCancelBtnFunc()
	self:WndClose()
end

function UIGolemItemUse:OnClickAddBtnFunc()
	if self._useNum >= self._haveNum then
		return
	end
	local value = self._useNum + 1
	if self:CheckIsMax(value) then return end
	self._useNum = value
	self:RefreshIntensifyDiv()
end

function UIGolemItemUse:OnClickEnterBtnFunc()
	local func = self._func
	if func then
		local data = {
			itemId = self._itemId,
			useNum = self._useNum,
		}
		func(data)
	end
	self._func = nil
	self:WndClose()
end

function UIGolemItemUse:GetCurCanUpExp(value)
	local golemInfo = self._golemInfo
	if not golemInfo then return end
	local golemExp = gModelGolem:GetGolemExpByGolemInfo(golemInfo)
	local itemUpExp = self:GetUseItemRewardExp(value)
	return golemExp + itemUpExp
end

function UIGolemItemUse:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(33235))
	self:SetTextTile(self.mUseTitle,ccClientText(33237))
	self:SetTextTile(self.mIntensifyTitle,ccClientText(33238))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(33240))
	self:SetWndButtonText(self.mCancelBtn,ccClientText(33239))
end

function UIGolemItemUse:OnClickValueBgFunc()
	local tab = {}
	tab.inputTran = self.mInputBg
	tab.minNum = 0
	tab.maxNum = self._haveNum
	tab.defaultNum = tonumber(self.mValue.text)
	tab.inputFunc = function(numStr,cmd)
		if self:IsWndClosed() then return end
		local num = tonumber(numStr)
		if num then
			if cmd == "C" then
				self:RefreshUseNumTxt(0)
			elseif cmd == "D" then
				if self:CheckIsMax(num) then
					if not self:CheckGolemIsMaxLv() then
						local newExp = self:GetCurCanUpExp(self._useNum)
						local maxLvNeedExp = self:GetMaxLvNeedExp()
						if newExp and maxLvNeedExp then
							local lostExp = maxLvNeedExp - newExp
							if lostExp > 0 then
								local itemToExp = self._itemToExp
								local tItemNum = math.floor(lostExp / itemToExp)
								if tItemNum < 1 then tItemNum = 1 end
								self._useNum = self._useNum + tItemNum
							end
						end
					end
				else
					self._useNum = num
				end
				self:RefreshIntensifyDiv()
			else
				self:RefreshUseNumTxt(num)
			end
		end
	end
	GF.OpenWndUp("UINuoardUI",tab)
end

------------------------- List -------------------------


function UIGolemItemUse:GetGolemActStatusList()
	local golemInfo = self._golemInfo
	if not golemInfo then return {} end
	local list = {}
	local intensifyLv,faceLv
	local configList = gModelGolem:GetGolemActItemUseList(golemInfo)
	local exp = gModelGolem:GetGolemExpByGolemInfo(golemInfo)
	local lvrGroupId = gModelGolem:GetGolemElementLvrGroupIdByGolemInfo(golemInfo)
	local itemUpExp = self:GetUseItemRewardExp(self._useNum)
	for i,v in ipairs(configList) do
		intensifyLv = v.intensifyLv
		faceLv = intensifyLv - 1
		table.insert(list,{
			intensifyLv = intensifyLv,
			lvRef = gModelGolem:GetGolemLvInfoByLvrGroupIdAndLv(lvrGroupId,faceLv),
			curGolemExp = exp,
			itemUpExp = itemUpExp,
			nowGolemExp = itemUpExp + exp,
		})
	end
	return list
end

function UIGolemItemUse:CheckGolemIsMaxLv()
	if not self._golemMaxLvInfo then return false end

	local golemInfo = self._golemInfo
	if not golemInfo then return true end

	local level = self._golemMaxLvInfo.level
	local golemLvl = gModelGolem:GetGolemLvlByGolemInfo(golemInfo)
	return level == golemLvl
end

function UIGolemItemUse:ChangeSlider()
	self:RefreshUseNumTxt()
	self:UpdateSlider()
end
------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemItemUse


