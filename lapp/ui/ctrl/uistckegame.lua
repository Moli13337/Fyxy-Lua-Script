---
--- Created by ly.
--- DateTime: 2023/10/19 10:24:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIStCkeGame:LWnd
local UIStCkeGame = LxWndClass("UIStCkeGame", LWnd)

local typeRectTransform = typeof(UnityEngine.RectTransform)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIStCkeGame:UIStCkeGame()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIStCkeGame:OnWndClose()
	if self.cakeSpine then
		self.cakeSpine:Destroy()
		self.cakeSpine = nil
	end
	LWnd.OnWndClose(self)


end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIStCkeGame:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIStCkeGame:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:CreateCakeSpine()
	self._tweenKey = "_tweenKey"
	self:SetWndText(self.mCoinText,self._total)
	self:SetWndText(self.mGameTipsText,ccClientText(29706))
	CS.ShowObject(self.mGameOver,false)

	self:SetTweenMove()

	--gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil,"1|1",ModelActivity.PILEUP_CAKE_SUCCESS)
	gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil,"1|1",45)


	self:CreateWndSpine(self.mRoleImg,"Znq_nvpu","Znq_nvpuUI_key")
	local dpSpine = self:FindWndSpineByKey("Znq_nvpuUI_key")
	dpSpine:PlayAnimation(0,"idle",true)


	local pos=self:FindWndTrans(self.mPlayerSpriteImg,"AniRoot/Player")
	self:CreateWndSpine(pos,self._spineName,"Znq_xianzi_key")
	local xianziSpine = self:FindWndSpineByKey("Znq_xianzi_key")
	xianziSpine:PlayAnimation(0,"idle",true)


	local imgPath = self._signImage[1]                              --背景图片
	if LxUiHelper.IsImgPathValid(imgPath) then
		self:SetWndEasyImage(self.mBg,imgPath,function() CS.ShowObject(self.mBg,true) end, true)
	end
	
	imgPath = self._config.cakeIcon
	if LxUiHelper.IsImgPathValid(imgPath) then
		self:SetWndEasyImage(self.mCakeIcon,imgPath,function() CS.ShowObject(self.mCakeIcon,true) end)
	end
end

function UIStCkeGame:StopAllSeq()
	self:TweenSeqKill(self._tweenKey)

	if self._launchTweenKey then
		self:TweenSeqKill(self._launchTweenKey)
	end

	self:TimerStop(self._gameStartKey)
	self:TimerStop(self._doubleTimeKey)
end

function UIStCkeGame:SetUpGrid(list,item,itemdata,itempos)
	local root=self:FindWndTrans(item,"Root/CommonUI/Icon")
	local itype = itemdata.itype
	local refId = itemdata.refId
	local num = tonumber(itemdata.num) or 1
	local InstanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceId)
	baseClass:Create(root)
	baseClass:SetCommonReward(itype, refId, num)
	baseClass:DoApply()
	self:SetWndClick(item,function ()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIStCkeGame:SetTimingProgress()
	LxUiHelper.SetProgress(self.mTimingBar,self._progress)
end


function UIStCkeGame:OnActivitySpecialOpResp(pb)

end

function UIStCkeGame:GameGameSettlement()

end


function UIStCkeGame:InitData()

	self._time= self:GetWndArg("time")                        --游戏时间
	self._doubleTime= self:GetWndArg("doubleTime")            --翻倍时间
	self._hSpeed= self:GetWndArg("hSpeed")                    --水平速度
	self._vSpeed= self:GetWndArg("vSpeed")                    --垂直速度
	self._upperIimit= self:GetWndArg("upperIimit")            --数量上限
	self._pages= self:GetWndArg("pages")                      --分页数据
	self._sid= self:GetWndArg("sid")                          --分页数据
	self._pageId= self:GetWndArg("pageId")                    --分页数据
	self._signImage= self:GetWndArg("signImage")                    --分页数据
	self._skewingSection= self:GetWndArg("skewingSection") or 0     --偏移数据
	self._spineName = self:GetWndArg("spineName") or "Znq_xianzi"
	self._config = self:GetWndArg("config") or {}
	self._cake=nil                       --正在移动的蛋糕
	self._cakeLast=self.mPlateImg        --盘子最上面蛋糕
	self._CakeList={}                    --已接住的列表
	self._reward=1                       --奖励
	self._isDouble=false                 --双倍时间内
	self._lastNum=0                      --最后一次添加的分数
	self._progress=0
	self._floor=0
	self._isMove=false
	self._rewardList={}                  --奖励列表
	self._isNext=false                   --继续下一个
	self._total=0                        --已接住的数量
	self._width = self._cakeLast:GetComponent(typeRectTransform).rect.width      --获取宽度
	self._gameStartKey="GameStart"
	self._doubleTimeKey="DoubleTime"
	self._failTime="failTime"
	self._flickerTimes=6    --闪烁次数
	self._flickerState=false    --闪烁状态
end

function UIStCkeGame:OnTimer(key)

	if key == self._gameStartKey then

		local time=self._time-1
		self:SetTimeImgLoop(time)
		self._time=time

		if self._time<=0 then
			self:GameOver()
		end

	end
	if key == self._doubleTimeKey then

		if self._isDouble then

			local fillValue=0.02/self._doubleTime --动画效果
			self._progress=self._progress+fillValue
			local isFill=self. _progress>1

			if isFill then
				self._progress=0
				self:SetWndText(self.mTimesText,"+"..self._progress)
				self._isDouble=false
				self._lastNum=self._reward
			end
			CS.ShowObject(self.mTipsBar,not isFill)
			self:SetTimingProgress()
		end
	end
	if key== self._failTime then
		if self._flickerTimes>0 then
			self._flickerTimes=self._flickerTimes-1
			local isShow= not self._flickerState
			CS.ShowObject(self._cakeLast,isShow)
			self._flickerState=isShow
		else
			if self._isNext==false then return end
			self:GameOver()
		end
	end

end

function UIStCkeGame:GameOver()

	self._isNext=false
	self:SetWndClick(self.mGameBtn,function() end)
	self:StopAllSeq()
	self:TimerStop(self._failTime)

	--gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil,"1|"..self._total,ModelActivity.PILEUP_CAKE_SUCCESS)
	gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil,"1|"..self._total,45)
	gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil,"2",45)


end


function UIStCkeGame:ShowRewardInfo(args,thingDetails)
	if self._config and tonumber(self._config.settlementReward) == 0 then
		GF.OpenWnd("UIStCkeResult", { args = args, config = self._config})
		return
	end


	local args=args
	local itemDetail=thingDetails

	CS.ShowObject(self.mGameOver,true)


	self:CreateWndSpine(self.mXianziRoot, "LH_Jinglingnvpu01", "LH_Jinglingnvpu01")
	-- local JinglingxianziSpine = self:FindWndSpineByKey("Jinglingxianzi_key")
	-- JinglingxianziSpine:PlayAnimation(0,"idle",true)

	local strs=string.split(args,'|')
	local txt1 = self._config.txt1 or ccClientText(29709)
	local str=string.replace(txt1,strs[1])


	local effectName = "fx_ui_gongxihuode"
	self:CreateWndEffect(self.mTitle,effectName,effectName,100)

	self:SetWndText(self.mFixedIntro,str)
	self:InitTextLineWithLanguage(self.mFixedIntro, -30)
	local rewardTips=self:FindWndTrans(self.mTextTitle,"UIText")
	self:SetWndText(rewardTips,ccClientText(29708))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	local txt2 = self._config.txt2 or ccClientText(29710)
	str=string.replace(txt2,strs[2],strs[3].."%")
	self:SetWndText(self.mFixedIntroB,str)
	self:InitTextLineWithLanguage(self.mFixedIntroB, -30)

	local itemList = {}


	for i,v in ipairs(itemDetail) do

		local items = v.items or {}
		local runes = v.runes or {}
		for idx,val in ipairs(items) do
			local item = gModelItem:GetServerDataByPb(val)
			table.insert(itemList,item)
		end

		for idx,val in ipairs(runes) do
			local rune = gModelRune:GetServerDataByPb(val)
			table.insert(itemList,rune)
		end

	end



	CS.ShowObject(self.mGameOver,true)
	local reward1List = itemList

	local instanceID="UIStCkeGame_rewardData"
	local _gridList = self:FindUIScroll(instanceID)
	local rewardData=reward1List
	if (_gridList) then
		_gridList:RefreshList(rewardData)
	else
		_gridList = self:GetUIScroll(instanceID)
		_gridList:Create(self.mAwardScroll,rewardData,function(...) self:SetUpGrid(...) end)
		_gridList:RefreshList(rewardData)
	end
	_gridList:DrawAllItems(false)
	_gridList:EnableScroll(false,false)




end

function UIStCkeGame:InitEvent()

	local gameTime=self._time
	self:SetTimeImgLoop(gameTime)
	self:SetWndClick(self.mGameBtn,function()
		self:DropCake()
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMaskBg,function()
		self:WndClose()
	end)

end

function UIStCkeGame:InitMessage()



	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		--self:OnActivitySpecialOpResp(pb)
		local sid = pb.sid
		if sid ~= self._sid then return end


	end)


	self:WndNetMsgRecv(LProtoIds.SpecialWindowResp,function (pb)

		local args = pb.args
		local thingDetails = pb.thingDetails

		self:ShowRewardInfo(args,thingDetails)

	end)
end




function UIStCkeGame:LaunchToween(trans,movePoint,speed,func)
	local trans = trans
	local func=func
	local instanceID=trans:GetInstanceID()
	local key = instanceID
	self:TweenSeqKill(key)
	local seqTween= self:TweenSeqCreate(key,function(seq)
			local moveTween = trans:DOLocalMove(movePoint,speed)
			seq:Append(moveTween)
			return seq
		end)
	seqTween:SetUpdate(true)
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)
		func()
	end)
	self._launchTweenKey=key

	seqTween:PlayForward()
end



function UIStCkeGame:SetTweenMove()
	if self._isMove then return end

	local speed=self._hSpeed
	local seqTween
	local key = self._tweenKey
	local trans = self.mPlayerSpriteImg
	local markX=math.abs(self.mPos.localPosition.x)
	local markY=self.mPos.localPosition.y
	self:TweenSeqKill(key)
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local moveTween = trans:DOLocalMove(Vector3.New(-markX,markY,0),speed)
			seq:Append(moveTween)
			local moveTween = trans:DOLocalMove(Vector3.New(0,markY,0),speed)
			seq:Append(moveTween)
			local moveTween = trans:DOLocalMove(Vector3.New(markX,markY,0),speed)
			seq:Append(moveTween)
			local moveTween = trans:DOLocalMove(Vector3.New(0,markY,0),speed)
			seq:Append(moveTween)
			return seq
		end)
	end
	seqTween:SetUpdate(true)
	seqTween:SetLoops(-1)
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)
	end)
	seqTween:PlayForward()

	self._isMove=true
end

function UIStCkeGame:CreateCakeSpine()
	self.cakeSpine = LDisplaySpine:New()
	self.cakeSpine:CreateSpine(self.mCakeSpine, "Znq_jiazi", LDisplaySpine.TYPE_UI)
	self.cakeSpine:SetLoadedFunction(function()
		self.cakeSpine:PlayAnimation(0, "idle", false, true)
	end)
	self.cakeSpine:StartLoad()
end

function UIStCkeGame:SetTimeImgLoop(time) --时分秒 图片连播
	-- local time=time
	-- local timerImgPath={}

	-- for i = 1, 10 do
	-- 	local index=i-1
	-- 	local path="activity_anniversary_num_"
	-- 	path=path..index
	-- if LxUiHelper.IsImgPathValid(path) then
	-- timerImgPath[index]=path
	-- end
	-- end
	-- local timeVaule = {}
	-- for i = 1, 4 do timeVaule[i] = 0 end
	-- local minuteCount = 0
	-- while (time >= 60) --分钟
	-- do
	-- 	time = time - 60
	-- 	minuteCount = minuteCount + 1
	-- end

	-- timeVaule[3] = minuteCount --秒
	-- if time > 9 and time < 60 then
	-- 	local value1, _ = math.modf(time / 10)
	-- 	timeVaule[2] = value1
	-- end
	-- timeVaule[1] = time - (timeVaule[2] * 10)
	-- -- local timeImg={
	-- -- 	self.mTimeImg1, --
	-- -- 	self.mTimeImg2, --
	-- -- 	self.mTimeImg3, --
	-- -- 	self.mTimeImg4, --
	-- -- }

	local s = ""
	if time > 60 then
		local min = math.floor(time / 60)
		local sec = math.floor(time) % 60

		local minS = min < 10 and "0" .. min or min
		local secS = sec < 10 and "0" .. sec or sec
		s = minS .. ":" .. secS
	else
		local sec = math.floor(time) % 60
		local secS = sec < 10 and "0" .. sec or sec
		s = "00:" .. secS
	end

	self:SetWndText(self.mTimeText, s)
	-- for i, v in pairs(timeImg) do
	-- 	local index=timeVaule[i]
	-- 	local path=timerImgPath[index]
	-- 	self:SetWndEasyImage(v,path)
	-- end
end

function UIStCkeGame:DropCake()

	if self._isNext then return end

	if not self:IsTimerExist(self._gameStartKey) then
		self:TimerStart(self._gameStartKey,1, false, -1)
	end


	CS.ShowObject(self.mTipsBg,false)
	local cake=LxResUtil.NewObject(self.mCakeTemplate)
	cake.transform:SetParent(self.mGameArea, false)
	CS.ShowObject(cake,true)
	cake.transform.localPosition=self.mPlayerSpriteImg.localPosition

	local height=cake:GetComponent(typeRectTransform).rect.height
	local len=#self._CakeList
	local yOffet=self.mPlateImg.localPosition.y+(len*height)

	local movePoint=Vector3.New(cake.localPosition.x,yOffet,0)
	local speed=self._vSpeed
	local width=self._width

	self._isNext=true

	self.cakeSpine:PlayAnimation(0, "open", false, true)
	-- CS.ShowObject(self.mPlyaerCloseState,false)
	-- CS.ShowObject(self.mPlyaerOpenState,true)

	local x1=cake.localPosition.x
	local x2=self._cakeLast.localPosition.x
	local offsetX=math.abs(x1-x2)

	local catchWidth=width*0.5
	CS.ShowObject(self.mHodingCakeImg,false)

	self:LaunchToween(cake,movePoint,speed,function()
		--下落逻辑判断
		if offsetX>width then   --完全脱离
			self:GameOver()
			CS.ShowObject(cake,false)

			LxUiHelper.PlayAudioSoundName(401)
		else

			self._cakeLast=cake
			if offsetX>catchWidth then  --接触面积过小
				self:StopAllSeq()
				if not self:IsTimerExist(self._failTime) then
					self:TimerStart(self._failTime,0.2, false, -1)
				end
				LxUiHelper.PlayAudioSoundName(401)
			else
				--成功接住
				local cakeImgTrans = self:FindWndTrans(cake,"Cake")
				local key=cake:GetInstanceID()
				self:CreateWndSpine(cake,"Znq_dangao",key,nil,function (dgSpine)
					CS.ShowObject(cakeImgTrans,false)
					dgSpine:PlayAnimation(0,"idle",false)
				end)
				table.insert(self._CakeList,cake)
				local num=self._reward
				if offsetX <=self._skewingSection and #self._CakeList~=1 then
					CS.ShowObject(self.mTipsBar,true)
					if not self:IsTimerExist(self._doubleTimeKey) then self:TimerStart(self._doubleTimeKey,0.02, false, -1) end
					self:CreateWndEffect(cake,"fx_activity_cake_score_01",cake:GetInstanceID(),100,false,false)
					if self._isDouble then
						self._progress=0
						self:SetTimingProgress()
						num=self._lastNum*2
					else
						self._isDouble=true
						num=self._reward*2
					end
					self:SetWndText(self.mTimesText,"+"..num)
				else
					num=self._reward
				end
				self._lastNum=num
				self._total=self._total+num

				local plate=self.mPlateImg
				cake.transform:SetParent(plate, true)
				local count=self._floor
				if count==2 then
					local move=Vector3.New(plate.localPosition.x,plate.localPosition.y-(height*2),0)
					self:LaunchToween(plate,move,speed,function()
						self._isNext=false
					end)
					local moveBg=Vector3.New(self.mBg.localPosition.x,self.mBg.localPosition.y-(height*2),0)
					self:LaunchToween(self.mBg,moveBg,speed,function()
					end)
					count=0
				else
					self._isNext=false
				end
				count=count+1
				self._floor=count
				self:SetWndText(self.mCoinText,self._total)
				gModelActivity:OnActivitySpecialOpReq(self._sid,nil,nil,nil,"1|"..self._total,45) --接住了

				LxUiHelper.PlayAudioSoundName(400)
			end
			-- CS.ShowObject(self.mPlyaerCloseState,true)
			-- CS.ShowObject(self.mPlyaerOpenState,false)
			self.cakeSpine:PlayAnimation(0, "idle", false, true)
		end
		CS.ShowObject(self.mHodingCakeImg,true)
	end)



end

------------------------------------------------------------------
return UIStCkeGame


