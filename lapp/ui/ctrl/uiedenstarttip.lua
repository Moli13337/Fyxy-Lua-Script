---
--- Created by Administrator.
--- DateTime: 2023/10/15 11:08:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenStartTip:LWnd
local UIEdenStartTip = LxWndClass("UIEdenStartTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenStartTip:UIEdenStartTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenStartTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenStartTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenStartTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()

	self:InitWndPara()

	self:ShowDifList()

	self:RefreshContent()

	self:StartAni()
end

function UIEdenStartTip:InitUIEvent()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnStart,function ()
		self:OnClickStart()
	end)
end

function UIEdenStartTip:GetCurThemeRef()
	local type = self._themeType
	local themeRef = gModelWonderland:GetThemeByType(type,self._curPattern)
	return themeRef
end

function UIEdenStartTip:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItemRoot = self:FindWndTrans(AniRoot,"itemRoot")
	local itemRootRoot = self:FindWndTrans(AniRootItemRoot,"root")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")

	CS.ShowObject(AniRootImage,itemdata.isSpecial)
	self:CreateCommonIconImpl(itemRootRoot,itemdata.itemdata)
end

function UIEdenStartTip:OnClickStart()
	local pattern = self._curPattern
	local themeId = self:GetWndArg("themeId")

	local themeCfg = self:GetCurThemeRef()
	if not themeCfg then
		return
	end
	local themeType =self._themeType
	local canEnter = gModelWonderland:CheckCanEnterType(themeType,true)
	if not canEnter then
		return
	end


	local isInMap = gModelWonderland:IsInMap()
	if not isInMap then
		local patternName = nil
		if pattern == ModelWonderland.NORMAL then
			patternName = ccClientText(16793)
		elseif pattern == ModelWonderland.HARD then
			patternName = ccClientText(16794)
		else
			patternName = ccClientText(16795)
		end
		local name = string.format("%s[%s]",ccLngText(themeCfg.name),patternName)

		if pattern == ModelWonderland.TOUGH then
			GF.OpenWnd("UIEdenEnter",{themeId = themeId,enterFunc = function ()
				if self:IsWndClosed() then
					return
				end
				gModelWonderland:WonderlandRefreshReq(themeId,pattern) --请求进入地图
				GF.CloseWndByName("UIEdenStartTip")

				FireEvent(EventNames.PLAY_ENTER_WONDERLAND_EFF,themeId)
			end})
		else
			local wndId = 70009
			local func = function()
				if self:IsWndClosed() then
					return
				end
				gModelWonderland:WonderlandRefreshReq(themeId,pattern) --请求进入地图
				GF.CloseWndByName("UIEdenStartTip")
				FireEvent(EventNames.PLAY_ENTER_WONDERLAND_EFF,themeId)
			end

			gModelGeneral:OpenUIOrdinTips({refId = wndId,func= func,para={name}})
		end
	else
		GF.OpenWndBottom("UIEden")
		self:WndClose()
	end
end

function UIEdenStartTip:OnSelectPattern(itemdata)

	if not gModelWonderland:CheckCanEnterType(self._themeType,true) then
		return
	end

	local pattern = itemdata.pattern

	if not self:CheckIsOpen(itemdata,true) then
		return
	end



    if self._curPattern == pattern then
        return
    end

    self:DestroyWndEffectByKey("selectDif")


    self._curPattern = pattern
	local difList = self:FindUIScroll("difList")
	if difList then
		difList:DrawAllItems(false)
	end

	self:RefreshContent()

end


function UIEdenStartTip:InitWndPara()
	local themeId = self:GetWndArg("themeId")
	self._themeId = themeId
	local themeRef = gModelWonderland:GetThemeConfig(themeId)
	self._themeType = themeRef.type

	self._canEnter = gModelWonderland:CheckCanEnterType(self._themeType,false)

	self:SetWndButtonGray(self.mBtnStart,not self._canEnter)
end

function UIEdenStartTip:ShowDifList()
    self:DestroyWndEffectByKey("selectDif")


	self._curPattern = gModelWonderland:GetMaxUnlockPattern()

    local difList = self:FindUIScroll("difList")
    if not difList then
        difList = self:GetUIScroll("difList")
        difList:Create(self.mDifList,self._difDataList,function (...) self:OnDrawDif(...) end)
    else
        difList:RefreshList(self._difDataList)
    end

end

function UIEdenStartTip:OnDrawDif(list,item,itemdata,itempos)
	local root = self:FindWndTrans(item,"root")
	local rootIcon = self:FindWndTrans(root,"icon")
	local rootSelect = self:FindWndTrans(root,"select")
	local rootMask = self:FindWndTrans(root,"mask")
	local maskLock = self:FindWndTrans(rootMask,"lock")
	local rootBg = self:FindWndTrans(root,"bg")
	local bgUIText = self:FindWndTrans(rootBg,"UIText")

	self:SetWndEasyImage(rootIcon,itemdata.icon)
    local isSelect = self._curPattern == itemdata.pattern
    CS.ShowObject(rootSelect,isSelect)
    self:SetWndText(bgUIText,itemdata.name)

    self:SetWndClick(root,function ()
        self:OnSelectPattern(itemdata)
    end)

	local isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.funId)



	isOpen = isOpen and self._canEnter

	CS.ShowObject(rootMask,not isOpen)

    if isSelect and isOpen then
        self:CreateWndEffect(root,"fx_qjtx_nandu_xuanzhong","selectDif",100)
    end

	local isShow = gModelFunctionOpen:CheckIsShow(itemdata.funId)
	CS.ShowObject(item,isShow)
end

function UIEdenStartTip:SetStaticContent()
	local str =ccClientText(10610)-- "通关奖励"
	self:SetWndText(self.mArrowTitle,str)
	str = ccClientText(16712)-- "出 发"
	self:SetWndButtonText(self.mBtnStart,str)

	self:CreateWndEffect(self.mBtnStart,"ui_fx_zhutixiangqing","ui_fx_zhutixiangqing",100)

end

function UIEdenStartTip:CheckIsOpen(itemdata,showTip)
	local isPass = gModelWonderland:CheckSelectPattern(itemdata.pattern)
	if not isPass then
		if showTip then
			local format =ccLngText(gModelWonderland:GetWonderlandPara("openTips"))
			local patternData = self._difDataList[itemdata.pattern -1]
			local str = string.replace(format,patternData.shortName)
			GF.ShowMessage(str)
		end

		return isPass
	end

	local isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.funId,showTip)
	--if not isOpen then
	--	if showTip then
	--		local str = string.replace(ccClientText(26206),gModelFunctionOpen:GetLevelLimit(itemdata.funId))
	--		GF.ShowMessage(str)
	--	end
	--end

	return isOpen
end

function UIEdenStartTip:StartAni()
	local time = 0.4
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("enterAni")
	self.mAniRoot.localPosition = Vector3.New(640,0,0)
	self.mAniRoot.localScale = Vector3.New(0.58,0.58,0.58)
	local tween = self.mAniRoot:DOLocalMoveX(0,time)
	seq:Append(tween)
	tween = self.mAniRoot:DOScale(Vector3.one,time)
	seq:Join(tween)
	local cg = self:GetCanvasGroup(self.mMask)
	cg.alpha= 0
	tween = cg:DOFade(1,time)
	seq:Join(tween)

	seq:PlayForward()
end



function UIEdenStartTip:InitData()
	local iconPathList = gModelWonderland:GetDifIconList()

	self._difDataList =
	{
		[1] =
		{
			icon = iconPathList[1],
			name =ccClientText(16793), --"普 通",
			shortName = ccClientText(26203),
			pattern = 1,
			funId = 16800020,

		},
		[2] =
		{
			icon = iconPathList[2],
			name = ccClientText(16794), --"困 难",
			shortName = ccClientText(26204),

			pattern = 2,
			funId = 16800030,

		},
		[3] =
		{
			icon = iconPathList[3],
			name = ccClientText(16795), --"深 渊",
			shortName = ccClientText(26205),

			pattern = 3,
			funId = 16800040,
		}
	}
end

function UIEdenStartTip:RefreshContent()
	local themeRef = self:GetCurThemeRef()


	self:SetWndText(self.mTitle,ccLngText(themeRef.name))
	local textId = themeRef.themeText
	local textCfg = gModelWonderland:GetEventTextConfig(textId)
	local txt = ccLngText(textCfg.dec)
	self:SetWndText(self.mIntro,txt)

	self:SetWndEasyImage(self.mBg,themeRef.themeIcon,nil,nil,true)


	local rewardList = {}

	local rareList = LxDataHelper.ParseItem(themeRef.exclusiveReward)
	if rareList then
		for k,v in ipairs(rareList) do
			local rewardInfo =
			{
				itemdata = v,
				isSpecial = true
			}

			table.insert(rewardList,rewardInfo)
		end
	end


	local itemList = LxDataHelper.ParseItem(themeRef.reward)
	if itemList then
		for k,v in ipairs(itemList) do
			local rewardInfo =
			{
				itemdata = v,
				isSpecial = false
			}

			table.insert(rewardList,rewardInfo)
		end
	end



	local uiList = self:FindUIScroll("rewardList")
	if not uiList then
		uiList = self:GetUIScroll("rewardList")
		uiList:Create(self.mItemList,rewardList,function (...) self:OnDrawItem(...) end)
		uiList:EnableScroll(#rewardList > 4,true)
	else
		uiList:RefreshList(rewardList)
	end
end

------------------------------------------------------------------
return UIEdenStartTip