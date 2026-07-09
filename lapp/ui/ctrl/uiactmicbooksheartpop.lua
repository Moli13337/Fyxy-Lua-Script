---
--- Created by Administrator.
--- DateTime: 2023/10/21 10:14:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActMicBooksHeartPop:LWnd
local UIActMicBooksHeartPop = LxWndClass("UIActMicBooksHeartPop", LWnd)

local Tweening = DG.Tweening

UIActMicBooksHeartPop.DISPLAY_ITEM = "0"
UIActMicBooksHeartPop.DISPLAY_HERO = "1"
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActMicBooksHeartPop:UIActMicBooksHeartPop()
	self._key = 1
	self._themeIndex = 1
	self._moveTime = 0.25
	self._moveKey = "_moveKey"
	self._showAniKey = "showAniKey"
	self._suspendTweenKey = "_suspendTweenKey"
	self._itemCanvasGroupTweenStartKey = "_itemCanvasGroupTweenStartKey"
	self._heroDisplayChangeTimerKey = "_heroDisplayChangeTimerKey"
	self._descBgTweenKey = "_descBgTweenKey"

	self._displayItemPath = "DisplayItem"

	self._changeThemeEffName = "fx_ui_mfsk_zhutizhuanchang"
	self._itemEffName = "fx_mofashujiangli_01"
	self._bgSpineName = "fx_ui_mofashuku2"
	self._canvasRootAnimKey = "_canvasRootAnimKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActMicBooksHeartPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActMicBooksHeartPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActMicBooksHeartPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitParam()
	self:InitDrag()
	self:InitStaticContent()
	self:ShowBgSpine()
end

function UIActMicBooksHeartPop:PlayDescAnimation()
	self:TweenSeq_Suspend(self._descBgTweenKey,self.mDescBg, self._descFromPos,self._descEndPos,
			2,nil,Tweening.Ease.InOutFlash,true)
end


function UIActMicBooksHeartPop:ShowBgSpine()
	self:CreateWndSpine(self.mBgSpine,self._bgSpineName,self._bgSpineName,false,function (spine)
		self:OnSpineLoad(spine)
	end)
end

function UIActMicBooksHeartPop:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if self._sid ~= sid then
		return
	end

	self:ResetActivePageData(pb)
	self:RefreshView()
end

--#####################################################################################################################
--## Anim #############################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:PlayChangThemEff(isLeft)
	local scale = isLeft and Vector3.one or self._rightScale
	self.mChangThemeEff.transform.localScale = scale

	CS.ShowObject(self.mChangThemeEff, false)
	self:CreateWndEffect(self.mChangThemeEff,self._changeThemeEffName,self._changeThemeEffName,100, false, false)
	CS.ShowObject(self.mChangThemeEff, true)
end

function UIActMicBooksHeartPop:RefreshSelectBtn()
	local isSelect = self:CheckIsSelectTheme()
	self:SetWndButtonGray(self.mBtnSelect, isSelect)

	CS.ShowObject(self.mBtnSelectRedPoint, not self._isSelectTheme)
end

function UIActMicBooksHeartPop:CheckIsSelectTheme()
	if not self._isSelectTheme then
		return false
	end

	return  self._selectTheme == self._themeIndex
end

function UIActMicBooksHeartPop:PlayItemListAnimation()
	self:TweenSeq_Suspend(self._suspendTweenKey,self.mDisplayItem, self._itemFromPos,self._itemEndPos,
			2,nil,Tweening.Ease.InOutFlash,true)


	if self._isShowChangeAni then
		local endFunc = function()
			self:RefreshDisplayItemShow()
		end

		self:TweenSeq_FadeInStaysAway(self._itemCanvasGroupTweenStartKey, self.mDisplayItem,
				{
					waitTime = 3,
					showTime = 0.5,
					noShowTime = 0.5,
					endFunc = endFunc,
					openInteractable = true,
					isLoop = true,
				})
	end
end

function UIActMicBooksHeartPop:SetDisplayHero()
	self:TimerStop(self._itemDisplayTimerKey)
	self:StartDisplayHeroSpine()
end

function UIActMicBooksHeartPop:SetDisplayItem()
	self:StartDisplayItem()
end

function UIActMicBooksHeartPop:OnDrawItem(item,itemdata,itempos)
	local bg 		= self:FindWndTrans(item, "Bg")
	local iconRoot = self:FindWndTrans(item, "Icon")
	local itemNum = self:FindWndTrans(item, "ItemNum")

	local instanceID = item:GetInstanceID()
	local itemCfg = gModelItem:GetRefByRefId(itemdata.itemId)
	local itemIconPath = itemCfg.icon
	self:SetWndEasyImage(iconRoot, itemIconPath)

	self:SetWndText(itemNum,itemdata.itemNum)

	self:SetWndClick(item, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)

	local effKey = self._itemEffName..instanceID
	self:CreateWndEffect(bg, self._itemEffName, effKey, 100,false, false)
end

function UIActMicBooksHeartPop:MovePage(moveX,moveTime)
	--todo 等待特效


	do return end
	local seqTween
	self:TweenSeqKill(self._moveKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._moveKey,function(seq)
			for i, v in ipairs(self._rootList) do
				CS.ShowObject(v,true)
				local vec = Vector2.New(v.localPosition.x + moveX,v.localPosition.y)
				local tweener = v:DOLocalMove(vec,moveTime)
				seq:Join(tweener)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._moveKey)
		self._bMove = true
		local keyi = self._key == 1 and 2 or 1
		CS.ShowObject(self._rootList[keyi],false)
	end)
end


--#####################################################################################################################
--## DisplayHero ######################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:StartDisplayHeroSpine()
	local itemList = self:GetCurDisplayItemList()
	local showIndex = 1
	self._curShowHeroIndex = showIndex
	local curHeroData = itemList[showIndex]
	if not curHeroData then return end

	local heroId = curHeroData[1].itemId
	self:CreateShowHeroLiHui(heroId)
end

--#####################################################################################################################
--## ViewRoot #########################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:RefreshView()
	local index = self._themeIndex

	local data = self._themeDataList[self._themeIndex]
	local cfg = self._themeCfgList[index]
	self:RefreshTopInfo(cfg)
	self:SetGiftInfo(data, cfg)
	self:RefreshSelectBtn()
end

function UIActMicBooksHeartPop:UIDragTryOnEnd(dragKey,eventData)
	self.mViewMove.transform.localPosition = Vector2.New(0,0)
	self._bDrag = true
end

--#####################################################################################################################
--## Timer ############################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end

function UIActMicBooksHeartPop:OnTimer(key)
	if key == self._heroDisplayChangeTimerKey then
		self:TimerStop(self._heroDisplayChangeTimerKey)
		self:CreateShowHeroLiHui(0)
	end
end

function UIActMicBooksHeartPop:OnClickReturnBtn()
	GF.CloseWndByName("UIActMicBooks")
	self:WndClose()
end

function UIActMicBooksHeartPop:OnClickHelp()
	local helpTips = self._themeHelpTips
	local title	  = gModelActivity:GetLngNameByActivitySid(self._sid)
	local str = string.gsub(helpTips,'\\n','\n')

	GF.OpenWndUp("UIBzTips",{title =title, text = str})
end

function UIActMicBooksHeartPop:ResetActivePageData(pb)
	for i, v in ipairs(pb.pages) do
		local pageData= gModelActivity:GenerateActivePageDataFromPb(v)
		if pageData then
			local pageId = v.pageId
			if pageId ~= ModelActivity.ACTIVITY_MAGIC_BOOKS_GOAL then
				--主题
				local themeDataList = {}
				for p,q in pairs(pageData.entry) do
					local entryId = q.entryId
					local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,q.pageId,entryId)
					if entryCfg then
						local moreInfo = string.split(entryCfg.moreInfo, '|')
						local curStep = tonumber(moreInfo[1])
						local displayIndex = tonumber(moreInfo[2])
						local isDisplay = displayIndex == 1
						if isDisplay then
							local reward = LxDataHelper.ParseItem(entryCfg.reward)
							if not themeDataList[curStep] then
								themeDataList[curStep] = {}
							end

							table.insert(themeDataList[curStep], reward)
						end
					end
				end

				local themeIndex = pageId - 1
				self._themeDataList[themeIndex] = themeDataList
			end
		end
	end
end

function UIActMicBooksHeartPop:MoveRoot(index)
	local _giftLen = self._giftLen
	if _giftLen <= 1 then
		return
	end
	local _themeIndex = self._themeIndex
	local move
	if index == 1 then
		_themeIndex = _themeIndex - 1
		if _themeIndex < 1 then
			_themeIndex = _giftLen
		end
	elseif index == 2 then
		_themeIndex = _themeIndex + 1
		if _themeIndex > _giftLen then
			_themeIndex = 1
		end
	end

	self._themeIndex = _themeIndex
	self:RefreshView()
	self:MovePage(move,self._moveTime)
	self:PlayChangThemEff(index == 1)
end

function UIActMicBooksHeartPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
end

function UIActMicBooksHeartPop:CreateShowHeroLiHui(showFirst,changeCallType)
	if self._themeType ~= UIActMicBooksHeartPop.DISPLAY_HERO then
		return
	end

	if showFirst == 0 then
		local itemList = self:GetCurDisplayItemList()
		local newIndex = self._curShowHeroIndex + 1
		if newIndex > #itemList then
			newIndex = 1
		end
		self._curShowHeroIndex = newIndex
		local curHeroData = itemList[newIndex]
		showFirst = curHeroData[1].itemId
	end
	showFirst = showFirst or 0
	if showFirst == 0 then return end

	local showHeroLiHuiList = self._showHeroLiHuiList
	if not showHeroLiHuiList then
		showHeroLiHuiList = {}
		self._showHeroLiHuiList = showHeroLiHuiList
	end

	local heroSpinePos = self.mHeroSpinePos
	heroSpinePos.localPosition = self._lihuiInitPos

	local curLiHuiPos = heroSpinePos.localPosition
	local curLiHuiPosX = curLiHuiPos.x
	local curLiHuiPosY = curLiHuiPos.y
	local curLiHuiPosZ = curLiHuiPos.z

	local startTimeFunc = function()
		local callHeroShowCd = 3
		self:CreateTimer(self._heroDisplayChangeTimerKey,callHeroShowCd,1)
	end

	local showNewLHFunc = function()
		local showHeroLiHui = showHeroLiHuiList[showFirst]
		if showHeroLiHui then
			showHeroLiHui:SetVisible(true)
		else
			local spine = gModelHero:GetHeroPrefabNameByRefId(showFirst,nil,true)
			if not spine then
				if LOG_INFO_ENABLED then
					printInfoNR("打印而已，莫慌    没有找到对应英雄的立绘，英雄refId = " .. showFirst)
				end
				return
			end
			showHeroLiHui = self:CreateWndSpine(heroSpinePos,spine,showFirst)
		end
		self._curShowSpine = showHeroLiHui
		self._curShowHero = showFirst
		showHeroLiHuiList[showFirst] = showHeroLiHui
	end

	local vanishTime = 0.5
	local showTime = 0.3
	local moveX = 80

	if self._curShowSpine and self._curShowHero and self._curShowHero ~= showFirst then
		if changeCallType then
			self:TweenSeqKill(self._showAniKey)
			self:SetCanvasGroupAlpha(heroSpinePos,1)
			self._curShowSpine:SetVisible(false)
			heroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
			showNewLHFunc()
			startTimeFunc()
		else
			local transInfoList = {
				{
					trans = heroSpinePos,
					aniStarPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
					vanishPos = Vector3(curLiHuiPosX - moveX,curLiHuiPosY,curLiHuiPosZ),
					aniShowPos = Vector3(curLiHuiPosX + moveX,curLiHuiPosY,curLiHuiPosZ),
					showPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
				}
			}
			local extraData = {
				initAlpha = 1,
				fromAlpha = 1,
				toAlpha = 0,
				vanishTime = vanishTime,
				showTime = showTime,
				nextShowAni = true,
				nextShowFunc = function()
					self._curShowSpine:SetVisible(false)
					showNewLHFunc()
				end,
				endFunc = function()
					heroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
					showNewLHFunc()
					startTimeFunc()
				end
			}
			self:TweenSeq_MoveFadeAni(self._showAniKey,transInfoList,extraData)
		end
	else
		if changeCallType then
			self:TweenSeqKill(self._showAniKey)
			self:SetCanvasGroupAlpha(heroSpinePos,1)
			heroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
			showNewLHFunc()
			startTimeFunc()
		else
			local transInfoList = {
				{
					trans = heroSpinePos,
					aniStarPos = Vector3(curLiHuiPosX + moveX,curLiHuiPosY,curLiHuiPosZ),
					vanishPos = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ),
				}
			}
			local extraData = {
				initAlpha = 0,
				fromAlpha = 0,
				toAlpha = 1,
				vanishTime = vanishTime,
				showTime = showTime,
				startShowFunc = function()
					showNewLHFunc()
				end,
				endFunc = function()
					heroSpinePos.localPosition = Vector3(curLiHuiPosX,curLiHuiPosY,curLiHuiPosZ)
					startTimeFunc()
				end
			}
			self:TweenSeq_MoveFadeAni(self._showAniKey,transInfoList,extraData)
		end
	end
end

function UIActMicBooksHeartPop:OnClickCloseBtn()
	if not self._isSelectTheme then
		GF.CloseWndByName("UIActMicBooks")
	end

	self:WndClose()
end

function UIActMicBooksHeartPop:OnSpineLoad(spine)
	CS.ShowObject(self.mBg, true)
	spine:PlayAnimation(0,"show",false)
	spine:SetAnimationCompleteFunc(function (aniname)
		local idleName = "idle"
		if idleName ~= aniname then
			spine:PlayAnimationSolid(idleName,true)
			CS.ShowObject(self.mCanvasRoot, true)
			self:TweenSeq_AlphaCanvasTrans(self._canvasRootAnimKey, self.mCanvasRoot, 0, 1, 1)
			self:PlayDescAnimation()
		end
	end)
end

function UIActMicBooksHeartPop:RefreshTopInfo(cfg)
	local themeName = cfg.themeName
	if LxUiHelper.IsImgPathValid(themeName) then
		self:SetWndEasyImage(self.mNameImage, themeName, nil, true)
		CS.ShowObject(self.mNameImage, true)
	end

	local themeNamePos = cfg.themeNamePos
	if not string.isempty(themeNamePos) then
		self:SetAnchorPos(self.mNameBg, LxDataHelper.ParseVector2NotEmpty3(themeNamePos))
	end

	local isShowHelp = not string.isempty(self._themeHelpTips)
	CS.ShowObject(self.mBtnLook, isShowHelp)
end

function UIActMicBooksHeartPop:InitParam()
	self._sid = self:GetWndArg("sid")
	if not self._sid then
		local subpage= self:GetWndArg("subPage") --支持跳转
		if subpage then
			self._sid = gModelActivity:GetSidByUniqueJump(subpage)
		end
	end

	self._themeDataList = {}

	self._themePageList = {}
	self._lihuiInitPos = self.mHeroSpinePos.localPosition
	local itemFromPos = self.mDisplayItem.localPosition
	self._itemFromPos = itemFromPos
	self._itemEndPos = itemFromPos + Vector3.New(0, 15, 0)

	local descFromPos = self.mDescBg.localPosition
	self._descFromPos = descFromPos
	self._descEndPos = descFromPos + Vector3.New(0, 8, 0)


	self._itemMaxNum = self.mDisplayItem.childCount

	self._rightScale = Vector3.New(-1, 1, 1)

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		gModelActivity:ReqActivityConfigData(self._sid)
	else
		self:InitData()
	end
end

--#####################################################################################################################
--## DisplayItem ######################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:StartDisplayItem()
	self._itemDataIndex = 0
	self:RefreshDisplayItemShow()
	self:PlayItemListAnimation()
end


--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:InitData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	self._activityData = activityData

	local activityMoreInfo = JSON.decode(activityData.moreInfo)

	self._selectTheme = 0
	local selectTheme = activityMoreInfo.selectTheme  or 0 --当前所选主题,默认0=未选择, 主题1 = 2
	if selectTheme > 0 then
		self._selectTheme = selectTheme - 1
		self._themeIndex = self._selectTheme
		self._isSelectTheme = true
	end

	self._themeCount  = activityMoreInfo.themeCount or 0 --主题选择次数，默认0次

	local config 	= webData.config
	self._config 	= config

	local themeType = string.split(config.themeType, '|')
	self._themeMaxNum = #themeType

	local themeName = string.split(config.themeName, '|')
	local themeNamePos = string.split(config.themeNamePos, '|')
	local themeInfo = string.split(config.themeInfo, '|')
	local themeNameText = string.split(config.themeNameText, '|')
	local themeList = {}
	for i = 1, self._themeMaxNum do
		local data = {
			themeType = themeType[i],
			themeName = themeName[i],
			themeNamePos = themeNamePos[i],
			themeInfo = themeInfo[i],
			themeNameText = themeNameText[i],
		}

		themeList[i] = data
	end
	self._themeCfgList = themeList

	self._giftLen = #self._themeCfgList

	self._themeHelpTips = config.themeHelpTips

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActMicBooksHeartPop:SetGiftInfo(data, cfg)
	local bgImg 		= self.mBgImg
	local displayItem	= self.mDisplayItem
	local displayHero	= self.mDisplayHero
	local descText		= self.mDescText

	CS.ShowObject(bgImg, true)

	local themeType = cfg.themeType
	CS.ShowObject(displayItem,  themeType == UIActMicBooksHeartPop.DISPLAY_ITEM)
	CS.ShowObject(displayHero,  themeType == UIActMicBooksHeartPop.DISPLAY_HERO)

	self._themeType = themeType
	if themeType == UIActMicBooksHeartPop.DISPLAY_ITEM then
		self:SetDisplayItem()
	else
		self:SetDisplayHero()
	end

	self:SetWndText(descText, cfg.themeInfo)
end

function UIActMicBooksHeartPop:RefreshDisplayItemShow()
	local itemList = self:GetCurDisplayItemList()

	for i = 1, self._itemMaxNum do
		local index = self._itemDataIndex + i
		local itemDisplayRoot = self:FindWndTrans(self.mDisplayItem, self._displayItemPath..i)
		local itemData = itemList[index]

		local isShow = not table.isempty(itemData)
		CS.ShowObject(itemDisplayRoot, isShow)
		if isShow then
			self:OnDrawItem(itemDisplayRoot, itemData[1], i)
		end
	end

	local maxDataNum = #itemList
	local isShowChange = maxDataNum > self._itemMaxNum
	self._isShowChangeAni = isShowChange
	if not isShowChange then
		return
	end

	local newItemDataIndex = self._itemDataIndex + self._itemMaxNum
	if newItemDataIndex >= maxDataNum then
		newItemDataIndex = 0
	end
	self._itemDataIndex = newItemDataIndex
end

function UIActMicBooksHeartPop:OnClickBtnSelect()
	if self:CheckIsSelectTheme() then return end


	local callFunc = function()
		local pageId = self._themeIndex + 1
		local args = "1|"..pageId
		local sid = self._sid
		self:WndClose()

		gModelActivity:OnActivitySpecialOpReq(sid,nil,nil,nil, args, ModelActivity.MAGIC_BOOKS_OPS)
	end

	local cfg = self._config
	local themeSelectNum = cfg.themeSelectNum

	local wndPara
	if self._isSelectTheme then
		local index = self._themeIndex
		local themeCfg = self._themeCfgList[index]
		local themeNameText = themeCfg.themeNameText

		local themeCount = self._themeCount
		local durationNum = math.max(themeSelectNum - themeCount, 0)

		wndPara =
		{
			refId = 110077,
			sid  = self._sid,
			para = {themeNameText, durationNum},
			func = callFunc,
		}
	else
		local themeSelectStep = cfg.themeSelectStep
		wndPara =
		{
			refId = 110076,
			sid  = self._sid,
			para = {themeSelectNum,themeSelectStep},
			func = callFunc,
		}
	end

	gModelGeneral:OpenUIOrdinTips(wndPara)
end

function UIActMicBooksHeartPop:GetCurDisplayItemList()
	local curTheme = self._themeIndex
	local themeData = self._themeDataList[curTheme]
	if not themeData then
		LogError("self._themeDataList[curTheme] is a nil, curTheme = "..(curTheme or "nil"))
		return nil
	end

	local maxNum = #themeData
	local curLevelData = themeData[maxNum]
	return curLevelData
end

function UIActMicBooksHeartPop:InitEvent()
	self:SetWndClick(self.mCloseBtn, function(...) self:OnClickCloseBtn() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mReturnBtn, function(...) self:OnClickReturnBtn() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mArrowLeft, function() self:MoveRoot(1) end, LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mArrowRight, function() self:MoveRoot(2) end, LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mBtnSelect, function() self:OnClickBtnSelect() end, LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mBtnLook, function() self:OnClickHelp() end)
end
--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()
end

function UIActMicBooksHeartPop:InitStaticContent()
	self:SetWndButtonText(self.mBtnSelect, ccClientText(38206))
end

function UIActMicBooksHeartPop:UIDragOnDrag(dragKey,eventData)
	local moveX = self.mViewMove.transform.localPosition.x
	if(not self._bDrag)then
		return
	end
	if(moveX > self._distance )then
		self:MoveRoot(1)
		self._bDrag = false
	elseif(moveX < - self._distance)then
		self:MoveRoot(2)
		self._bDrag = false
	end
end

--#####################################################################################################################
--## Move #############################################################################################################
--#####################################################################################################################
function UIActMicBooksHeartPop:InitDrag()--拖动
	self:UIDragSetItem("MagicBooks","Pop/ViewMove",CS.YXUIDrag.DragMode.DragOrigin)
end


------------------------------------------------------------------
return UIActMicBooksHeartPop


