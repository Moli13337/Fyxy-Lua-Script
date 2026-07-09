---
--- Created by Administrator.
--- DateTime: 2023/10/8 21:08:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHeartVdo:LWnd
local UIHeartVdo = LxWndClass("UIHeartVdo", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHeartVdo:UIHeartVdo()
	self._skipNum = 3
	self._videoSliderKey = "_videoSliderKey"

	self._waitPlayVideoTimerKey = "_waitPlayVideoTimerKey"
	self._videoPlayTimeKey = "_videoPlayTimeKey"
	self._releaseDragTimeKey = "_releaseDragTimeKey"

	self._canOpenJumpBtnTimeKey = "_canOpenJumpBtnTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHeartVdo:OnWndClose()
	gLGameVideo:StopVideo()
	if self._func then
		self._func()
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHeartVdo:OnCreate()
	LWnd.OnCreate(self)

	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHeartVdo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitView()

	gLxTKData:OnTAClientEventReq(LxTKData.PROJECTOR_VIDEO,nil,self._itemdata.refId,1)
end

function UIHeartVdo:ChangeTime()
	local slider = self:FindWndSlider(self.mSliderRoot)
	local value = slider.value
	local length = self:GetVideoLength()
	local curTime = value * length
	curTime = Mathf.Clamp(curTime,0,length)
	gLGameVideo:SetVideoTime(curTime)
	gLGameVideo:ContinueToPlayVideo()
end

function UIHeartVdo:CloseTipPart()
	CS.ShowObject(self.mTipPart,false)
end

function UIHeartVdo:RefreshTotalTimeTxt()
	local videoLength = self:GetVideoLength()
	local timeStr     = LUtil.FormatTimespanToMin2New(videoLength)
	self:SetWndText(self.mTotalTime, timeStr)
end

function UIHeartVdo:OnEndDrag()
	self:ChangeTime()

	self:TimerStart(self._videoPlayTimeKey,1,false,-1)
end

function UIHeartVdo:GetVideoLength()
	if self._length then
		return self._length
	end
	self._length = gLGameVideo:GetVideoLength()
	return self._length
end

function UIHeartVdo:CloseWndFunc()
	self:WndClose()
end

--#####################################################################################################################
--## Slider ###########################################################################################################
--#####################################################################################################################


function UIHeartVdo:RefreshSlider()
	local videoTime    = gLGameVideo:GetVideoTime()
	local videoLength  = self:GetVideoLength()
	local progress	   = videoTime / videoLength
	self:SetWndSliderPara(self.mSliderRoot,progress)
	self:RefreshCurTimeTxt(videoTime)
end

function UIHeartVdo:VideoPlayEndFunc()
	self:CloseWndFunc()
end

--#####################################################################################################################
--## Video ############################################################################################################
--#####################################################################################################################
function UIHeartVdo:VideoPlayStart()
	local itemdata = self._itemdata
	local playEndFunc = function()
		self:VideoPlayEndFunc()
	end

	CS.ShowObject(self.mVideoVert,self._isVertical)
	CS.ShowObject(self.mVideoHori,not self._isVertical)
	local videoTran = self._isVertical and self.mVideoVert or self.mVideoHori

	if itemdata.download == 1 then
		local filePath = gModelOneNight:GetVideoLocalPath(itemdata.videoRes)
		gLGameVideo:PlayRemoteVideo(filePath, playEndFunc, videoTran, false)
	else
		local videoName = itemdata.videoRes
		gLGameVideo:PlayVideoClipUI(videoName, playEndFunc, videoTran, false)
	end
end

function UIHeartVdo:OnBeginDrag()

	self:TimerStop(self._videoPlayTimeKey)

	gLGameVideo:PauseVideo()
end
--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIHeartVdo:InitView()
	self:SetSkipBtnShow(false)
	self:SetTextTile(self.mBtnSkip,ccClientText(23237))
	self:TimerStart(self._waitPlayVideoTimerKey, 0.5, false, 1)

	--local showBg = not string.isempty(self._itemdata.flillRes)
	--CS.ShowObject(self.mBg,showBg)
	--if showBg then
	--	self:SetWndEasyImage(self.mBg,self._itemdata.flillRes)
	--end
	local strs = string.split(self._itemdata.flillRes,"|")
	local imageUp = strs[1]
	local imageDown = strs[2]

	if not string.isempty(imageUp) then
		self:SetWndEasyImage(self.mImageUp,imageUp)
	end

	if not string.isempty(imageDown) then
		self:SetWndEasyImage(self.mImageDown,imageDown)
	end

	CS.ShowObject(self.mImageUp,not string.isempty(imageUp))
	CS.ShowObject(self.mImageDown,not string.isempty(imageDown))


	self._isVertical = true
	--self._isVertical = true

	local showSave = self._itemdata.keep == 1

	CS.ShowObject(self.mBtnSave,showSave)
end

function UIHeartVdo:OnClickSlider()
	self:ChangeTime()
end

function UIHeartVdo:SaveToPhoto()

	local itemdata = self._itemdata
	local para =
	{
		refId = 260002,
		funcMap =
		{
			[2] = function()
				gLxTKData:OnTAClientEventReq(LxTKData.PROJECTOR_VIDEO,nil,itemdata.refId,2)
				gModelOneNight:SaveVideoToPhoto(itemdata)
			end,
		}
	}

	self:ShowWndTip(para)

end

function UIHeartVdo:FastCloseWndFunc()
	self._func = nil
	self:WndClose()
end

function UIHeartVdo:OnDrag()
	local slider = self:FindWndSlider(self.mSliderRoot)
	local value = slider.value
	local length = self:GetVideoLength()
	local curTime = value * length
	curTime = Mathf.Clamp(curTime,0,length)
	self:RefreshCurTimeTxt(curTime)
end


function UIHeartVdo:InitData()
	self._itemdata = self:GetWndArg("itemdata")
	self._needSlider= true
	self._openJumpBtn  = true
	self._isCanJump = false

	self:InitTipWndData()
end

function UIHeartVdo:OnVideoLoadingEnd()
	self:CanSkipTimeStart()
	--加载结束，更新进度条，时间信息
	if self._needSlider then
		self:RefreshTotalTimeTxt()
		self:RefreshSlider()
		self:TimerStart(self._videoPlayTimeKey, 1, false,-1)
	end
end

function UIHeartVdo:OnClickBtn(index)
	local funcMap = self._funcMap or {}
	local func = funcMap[index]
	if func then
		func()
	end

	self:CloseTipPart()
end

function UIHeartVdo:SetCanSkip(isMust)
	self._isCanJump = true
	if self._openJumpBtn or isMust then
		self:SetSkipBtnShow(true)
	end
end

function UIHeartVdo:CanSkipTimeStart()
	if self:IsTimerExist(self._canOpenJumpBtnTimeKey) then
		return
	end
	self:TimerStart(self._canOpenJumpBtnTimeKey, 1.5, false, 1)
end

function UIHeartVdo:InitTipWndData()
	---@type table<string,UIObjPool>
	self._objPoolList = {}

	local objPool = UIObjPool:New()
	objPool:Create(self.mUnuse,self.mPublic_btn_1_1)
	self._objPoolList["public_btn_1_1"] = objPool
	objPool = UIObjPool:New()
	objPool:Create(self.mUnuse,self.mPublic_btn_1_2)
	self._objPoolList["public_btn_1_2"] = objPool
	objPool = UIObjPool:New()
	objPool:Create(self.mUnuse,self.mPublic_btn_1_3)
	self._objPoolList["public_btn_1_3"] = objPool
end

function UIHeartVdo:InitMsg()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:FastCloseWndFunc() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:FastCloseWndFunc() end)
	self:WndEventRecv(EventNames.LOADING_VIDEO_COMPLETE, function (...) self:OnVideoLoadingEnd(...) end)
	self:WndEventRecv(EventNames.LOADING_VIDEO_ERROR, function (...) self:OnVideoLoadingError(...) end)
end

function UIHeartVdo:RefreshCurTimeTxt(curVideoTime)
	if not curVideoTime then
		curVideoTime = gLGameVideo:GetVideoTime()
	end
	local timeStr     = LUtil.FormatTimespanToMin2New(curVideoTime)
	self:SetWndText(self.mCurTime, timeStr)
end

--#####################################################################################################################
--## Timer ############################################################################################################
--#####################################################################################################################
function UIHeartVdo:OnTimer(key)
	if key == self._videoPlayTimeKey then
		self:RefreshSlider()
	elseif key == self._canOpenJumpBtnTimeKey then
		self:SetCanSkip()
	elseif key == self._waitPlayVideoTimerKey then
		self:VideoPlayStart()
	end
end

function UIHeartVdo:OnVideoLoadingError()
	self:SetCanSkip(true)
end

function UIHeartVdo:OnClickMask()
	if not self._wndPara.touchAnyClose then
		return
	end

	self:CloseTipPart()
end

function UIHeartVdo:SetSkipBtnShow(isShow)
	CS.ShowObject(self.mBtnSkip, isShow)
end

function UIHeartVdo:OnSkipBtn()
	self:CloseWndFunc()
end

function UIHeartVdo:InitEvent()
	self:SetWndClick(self.mBtnSkip,function(...) self:OnSkipBtn() end)

	CS.SetOnBeginDrag(self.mSliderRoot.gameObject,function ()
		self:OnBeginDrag()
	end)

	CS.SetOnDrag(self.mSliderRoot.gameObject,function ()
		self:OnDrag()
	end)

	CS.SetOnEndDrag(self.mSliderRoot.gameObject,function ()
		self:OnEndDrag()
	end)

	CS.SetClick(self.mSliderRoot.gameObject,function ()
		self:OnClickSlider()
	end)

	self:SetWndClick(self.mBtnSave,function ()
		self:SaveToPhoto()
	end)

end

function UIHeartVdo:ShowWndTip(para)

	CS.ShowObject(self.mTipPart,true)

	local refId = para.refId
	self._funcMap = para.funcMap

	local ref =  GameTable.UIWindowAttRef[refId]

	local wndPara =
	{
		showCloseBtn = ref.closeBtn == 1,
		touchAnyClose = ref.touchAnyClose == 1,
		title = ccLngText(ref.title),
		text = ccLngText(ref.text),
	}

	local btnTextList = string.split(ccLngText(ref.btnTxt),'|')
	local btnPngList = string.split(ref.btnPng,'|')

	local btnList = {}
	for k,v in ipairs(btnTextList) do
		local btnData =
		{
			btnText = v,
			btnPng = btnPngList[k],
			index = k
		}

		table.insert(btnList,btnData)
	end

	wndPara.btnList = btnList

	self._wndPara = wndPara

	self:SetWndText(self.mTitle1,wndPara.title)

	CS.ShowObject(self.mCloseBtn1,wndPara.showCloseBtn)
	self:SetWndClick(self.mCloseBtn1,function ()
		self:CloseTipPart()
	end)

	self:SetWndClick(self.mTipPart,function ()
		self:OnClickMask()
	end)

	local text = self._wndPara.text
	self:SetWndText(self.mContent1,text)

	for k,v in pairs(self._objPoolList) do
		v:ReturnAllObj()
	end

	for k,v in ipairs(btnList) do
		local objPool = self._objPoolList[v.btnPng]
		if objPool then
			local obj = objPool:GetObj()
			local objTran = obj.transform
			CS.SetParentTrans(objTran,self.mBtnLayout_1)
			self:SetWndButtonText(objTran,v.btnText)
			self:SetWndClick(objTran,function ()
				self:OnClickBtn(v.index)
			end)
		end
	end

end



------------------------------------------------------------------
return UIHeartVdo


