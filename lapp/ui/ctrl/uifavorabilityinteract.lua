---
--- Created by Administrator.
--- DateTime: 2024/4/26 17:19:23
---
------------------------------------------------------------------
---
local typeSpineClick = typeof(CS.SpineClick)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

---@type LUISpineSpCtrl
local LUISpineSpCtrl = LxRequire("LApp.UI.Display.LUISpineSpCtrl")

local LWnd = LWnd
---@class UIFavorabilityInteract:LWnd
local UIFavorabilityInteract = LxWndClass("UIFavorabilityInteract", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFavorabilityInteract:UIFavorabilityInteract()
    self.actionStr = {}
    self.allHeroList = {}
    self.allHeroIndx = {}
    self.allHeroLeng = 0
    self.effectListData = {}
	self.isHide = false
    self.curEffRefId = nil
    self.curEffRefIdIndx = nil
    self.selectItem = nil
    self.isShow = true
    self.tweenTime = 0.4
    self._ActionTimerKey = "_ActionTimerKey"

    ---@type LUISpineSpCtrl
    self._uiSpineSpCtrl = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFavorabilityInteract:OnWndClose()

    LUtil.ClearHashTable(self._uiHeroObjList)
    self._uiHeroObjList = nil
    self._curUIHeroObj = nil

    if self._uiSpineSpCtrl then
        self._uiSpineSpCtrl:Destroy()
    end
    if gModelGameHelper.IsSpeeded() then gLGame:SetBaseTimeScale(gModelGameHelper:GetGameSpeed()) end

    local from = self:GetWndArg("from")
	LWnd.OnWndClose(self)
    self._showTween = nil
    self._hideTween = nil
    if from then GF.OpenWnd(from) end
    self:TimerStop(self._ActionTimerKey)
    if self.delayTimer then 
        self.delayTimer = nil
        LxTimer.DelayTimeStop(self.delayTimer)
    end
    gLGameAudio:StopSingleSound()
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFavorabilityInteract:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFavorabilityInteract:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isJa = gLGameLanguage:IsJapanVersion()
    if self._isEnus or self._isJa then 
        self:InitTextSizeWithLanguage(self.mTxtSet,-2)
        
    end

    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isVie then
        self.mTxtSet.sizeDelta = Vector2.New(100,0)
        self:InitTextCharacterWithLanguage(self.mTxtSet,-2.5)
        local textTran = LxUiHelper.FindXTextCtrl(self.mTxtSet)
        textTran.enableWordWrapping = true

    end
    self.isCHN = gLGameLanguage:IsChinaRegion()
    self:InitUIData()
    self.curEffRefId =  self:GetWndArg("heroRefId")--英雄id或表现id
    self:InitHeroData()
	self:SetWndClick(self.mReturnBtn,function()
        self:ResetUISpineSpCtrl()
        self:WndClose()
    end)

	self:SetWndClick(self.mBtnCloseUp,function() self:OnCloseUp() end)
	self:SetWndClick(self.mBtnHideShow,function() self:OnHideOrShow(not self.isShow) end)
	self:SetWndClick(self.mBtnInteract,function() self:OnItemInteract() end)
	self:SetWndClick(self.mImgLove,function()
        self:ResetUISpineSpCtrl()
        gLGameAudio:StopSingleSound()
        if gModelGameHelper.IsSpeeded() then gLGame:SetBaseTimeScale(gModelGameHelper:GetGameSpeed()) end
        local heroRefId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
        gModelGeneral:OpenHeroStarPre({ refId = heroRefId, showTab = true,selectIndex = 5}) end)
    self:SetWndClick(self.mCurLeftBtn,function() self:OnUpdateCurHero(-1) end)
    self:SetWndClick(self.mCurRightBtn,function() self:OnUpdateCurHero(1) end)
	self:SetWndClick(self.mBtnSet,function() 
        gModelHeroExtra:OnHeroSetShowReq(self.curEffRefId) end)
    self:SetWndClick(self.mItemTips,function() CS.ShowObject(self.mItemTips,false) end)

	self:SetWndText(self.mTxtReturn,ccClientText(30205))
	self:SetWndText(self.mTxtHideShow,self.isHide and ccClientText(41304) or ccClientText(41300))
	self:SetWndText(self.mTxtSet,ccClientText(41318))
	self:SetWndText(self.mTxtInteract,ccClientText(41303))
	self:SetWndText(self.mTxtCloseUp,ccClientText(41321))
    self:SetWndText(self.mTxtLoveTitle,ccClientText(41302))
    self:SetWndText(self.mReturnTxt,ccClientText(42010))
    self:WndEventRecv(EventNames.FAVORABILITY_SPINE_UPDATE,function ()
        CS.ShowObject(self.mBtnSet,gModelHero._gardenShowHeroEffRefId~=self.curEffRefId)
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_INTERACT,function ()
        self:OnUpdateBtn()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_LOVE_UPLV,function ()
        --self:OnUpdateBtn()
        self:OnUpdateCurHero()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_EXP_UPDATE,function ()
        self:UpdateLoveLevel()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_UNLOCKACTION,function ()
        self:OnUpdateBtn()
    end)
    self:SetHideTop(true)
    self:SetHideBottom(true)

    self:SetAnchorPos(self.mListHero,Vector2.New(390,206))
    self:OnHideOrShow(self.isShow)
    self:OnUpdateCurHero()
    

end

function UIFavorabilityInteract:CurSpinePlayAni(aniName)
    --- 由CreateWndSpine 修改为 LUIHeroObject
    -- local spine = self:FindWndSpineByKey("GardenHeroInteract")
    -- if aniName and aniName~="" then
    --     spine:PlayAnimation(0,aniName,false)
    --     spine:SetAnimationCompleteFunc(function(ainName)
    --         if ainName == aniName then
    --             spine:PlayAnimation(0, "idle", true)
    --         end
    --     end)
    -- end
    if aniName ~= LSpineAniConst.idle then
        local resType = LPlayerPrefs.GetLocalization()
        if resType == 3 then return end
    end
    local curUIHeroObj = self._curUIHeroObj
    if curUIHeroObj and not string.isempty(aniName) then
        if gModelGameHelper.IsSpeeded() then gLGame:SetBaseTimeScale(1) end--開啓加速 and 重置時間縮放
        curUIHeroObj:PlayAni(aniName,false,nil,nil,true)
        local spine = curUIHeroObj:GetDisplaySpine()
        spine:SetAnimationCompleteFunc(function(ani)
            -- if ani == aniName then
            --     spine:PlayAnimation(0, "idle", true)
            -- end
            curUIHeroObj:PlayAni("idle",true,nil,nil,true)
            self.isPlayAction = false
            if gModelGameHelper.IsSpeeded() then gLGame:SetBaseTimeScale(gModelGameHelper:GetGameSpeed()) end
        end)
        -- spine:PlayAnimation(0,aniName,false)
    end
end

function UIFavorabilityInteract:OnUpdateList()
    table.sort(self.effectListData,function (a,b)
        local aActive = gModelHero:IsActiveHeroEffRefId(a.refId)
        local bActive = gModelHero:IsActiveHeroEffRefId(b.refId)
        local aActive = aActive and 1 or 2
        local bActive = bActive and 1 or 2
        if aActive~=bActive then
            return aActive<bActive
        else
            return a.refId<b.refId
        end
    end)

    if not self.curEffRefId then
        self.curEffRefIdIndx = 1
        self.curEffRefId = self.effectListData[self.curEffRefIdIndx].refId
    else
        for indx, value in ipairs(self.effectListData or {}) do
            if value.refId == self.curEffRefId then
                self.curEffRefIdIndx = indx
                break
            end
        end
        if not self.curEffRefIdIndx then
            self.curEffRefIdIndx = 1
            self.curEffRefId = self.effectListData[1].refId
        end

    end
    if(not self._uiList)then
		self._uiList = self:GetUIScroll("IconList")
		self._uiList:Create(self.mListHero,self.effectListData,function (...) self:ListItem(...) end,UIItemList.WRAP)
	else
		self._uiList:RefreshList(self.effectListData)
	end
end

function UIFavorabilityInteract:OnUpdateTxtTips(txtTips)
    if self.isCHN then
        return
    end
    CS.ShowObject(self.mItemTips,true)
    self:SetWndText(self.mTxtTranslate,ccLngText(txtTips))
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mItemTips)
end
function UIFavorabilityInteract:ListItem(list , item, itemdata, itempos)
	local IconBg = CS.FindTrans(item,"IconBg")
	local ImgIcon = CS.FindTrans(item,"ImgIcon")
	local ImgMask = CS.FindTrans(item,"ImgMask")
	local ImgSelect = CS.FindTrans(item,"ImgSelect")
	local ImgRed = CS.FindTrans(item,"ImgRed")

    local effRef = GameTable.CharacterEffectRef[itemdata.refId]
    local heroRef = GameTable.CharacterRef[itemdata.heroType]
    local qualityBg = "public_item_bg_"..(heroRef.quality or 0)
	self:SetWndEasyImage(IconBg,qualityBg)
	self:SetWndEasyImage(ImgIcon,effRef.icon)
    CS.ShowObject(ImgSelect,self.curEffRefId == itemdata.refId)
    local notActive = not gModelHero:IsActiveHeroEffRefId(itemdata.refId)

    CS.ShowObject(ImgMask,notActive)
    if self.curEffRefId == itemdata.refId then
        self.selectItem = item
        self.curEffRefIdIndx = itempos
        self:OnUpdateBtn()
    end
    local red =  not notActive
    if not notActive then
        red = gModelHero:GetFavorabilityInteractRed(itemdata.refId,true) or gModelHero:GetFavorabilityInteractRed(itemdata.refId)
    end
    CS.ShowObject(ImgRed,red)
	self:SetWndClick(item,function ()
        if notActive then
			if effRef.skinType<=1 and (not effRef.needStar or effRef.needStar <= 1) then --1阶
				GF.ShowMessage(string.replace(ccClientText(41319),ccLngText(effRef.name)))
            elseif effRef.skinType==2 then
                if not effRef.needStar or effRef.needStar<=0 then
					GF.ShowMessage(string.replace(ccClientText(41319),ccLngText(effRef.skinName)))
				else
                    local star = string.replace(ccClientText(41637),effRef.needStar)
					GF.ShowMessage(string.replace(ccClientText(41319),star..ccLngText(effRef.name)))
				end
			end
            return
        end
        if self.curEffRefId == itemdata.refId then return end
        gLGameAudio:StopSingleSound()
		self:OnClickIcon(item,itemdata,itempos)
	end)

end

function UIFavorabilityInteract:InitHeroData()
    local allListData = {}
	local refs = GameTable.CharacterRef
    local curTimeSpan = GetTimestamp()
	for k,v in pairs(refs) do
        local isOpen = gModelHero:GetHeroActShowState(v.refId,curTimeSpan)
        local heroEffects,hasActive = gModelHero:GetHeroEffectListByRefId(v.refId,true)
        if v.maxFavorability and v.maxFavorability>0 and isOpen and heroEffects and hasActive then
            table.insert(allListData,v)
        end
	end
	table.sort(allListData,function (a,b)
		local aActive = gModelHero:IsActiveHeroEffRefId(a.refId) and 1 or 2
		local bActive = gModelHero:IsActiveHeroEffRefId(b.refId) and 1 or 2
		if aActive ~= bActive then
			return aActive<bActive
		else
            if a.quality ~= b.quality then
                return a.quality>b.quality
            else
                return a.refId<b.refId
            end
		end
	end)
	self.allHeroList = allListData
    self.allHeroLeng = #allListData
    self.allHeroIndx = {}
    for index, value in ipairs(allListData) do
        self.allHeroIndx[value.refId] = index
    end
end

function UIFavorabilityInteract:InitUIData()
    self._initSpinePos = self.mHeroLiHuiPos.anchoredPosition
    self._uiSpineSpCtrl = LUISpineSpCtrl:New()

end
function UIFavorabilityInteract:OnClickIcon(item,itemdata,index)
    self:ResetUISpineSpCtrl()
    if self.selectItem then
        local oldItem = self.selectItem
        local oldSelect = CS.FindTrans(oldItem,"ImgSelect")
        CS.ShowObject(oldSelect,false)
    end
    self.curEffRefIdIndx = index
    self.curEffRefId = itemdata.refId
    if item then
        self.selectItem = item
        local ImgSelect = CS.FindTrans(item,"ImgSelect")
        CS.ShowObject(ImgSelect,true)
    end
    CS.ShowObject(self.mBtnSet,gModelHero._gardenShowHeroEffRefId~=self.curEffRefId)
    self:CreateLiHui()
    self:OnUpdateBtn()
end
function UIFavorabilityInteract:OnItemInteract()
    local ative = gModelHero:IsActiveHeroEffRefId(self.curEffRefId)
    if ative then
        self:ResetUISpineSpCtrl()
        local effectRef = GameTable.CharacterEffectRef[self.curEffRefId]
        local heroRefId = effectRef.heroType
        local loveInfo =  gModelHero:GetFavorabilityInfo(heroRefId)
        local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId) or 0
        local favorRefs = gModelHero:GetHeroSpActionSoundRef()
        local isEmptyCfg = favorRefs.heroPlayItemSpAction.unlockHeroPlayItemSpAction
        local isUnlockSpAction = true
        if  loveInfo and not string.isempty(isEmptyCfg) then
            isUnlockSpAction = loveInfo.isUnlockSpAction
        end
       if favorRefs.heroPlayItemSpAction and loveLevel>=favorRefs.heroPlayItemSpAction.refId then
           if isUnlockSpAction then
               local spAction = favorRefs.heroPlayItemSpAction.spAction
               local action = effectRef[spAction] or "idle"
               -- if action ~= "idle"  then--and spAction == "heroCloseUpSpAction"
               --     self:PlayCloseUpSp(tonumber(action) or 0)
               -- else
               self:CurSpinePlayAni(action)
               -- end

               local favorRef = favorRefs.heroPlayItemSpActionSound
               if favorRef and loveLevel>=favorRef.refId then
                   local actionSounds = string.split(effectRef[favorRef.SpActionSound] or "",";")
                   local soundsStr = string.split(effectRef.heroPlayItemSpActionDesc or "",";")
                   local index = math.random(1,#actionSounds)
                   local actionSound = actionSounds[index]
                   local soundStr = soundsStr[index] or soundsStr[1]
                   if actionSound~="" then
                       gLGameAudio:PlaySingleSound(actionSound, function()
                           self:TimerStart(self._ActionTimerKey, 0.3, false, -1)
                       end)
                       if soundStr~="" then self:OnUpdateTxtTips(soundStr) end
                   end
               end
               self.isPlayAction = true
               self:OnPlayIdle(action)
               if gModelHero:GetFavorabilityInteractRed(self.curEffRefId,true) then
                   local heroRefId = effectRef.heroType
                   gModelHeroExtra:OnHeroInteractionReq(heroRefId,self.curEffRefId,1)
               end
           else
               local costItemData = favorRefs.heroPlayItemSpAction.unlockHeroPlayItemSpAction
               local costItem =  LUtil.GetRefItemData(costItemData)
               local haveNum = gModelItem:GetNumByRefId(costItem.itemId)
               if haveNum < costItem.itemNum then
                   gModelGeneral:OpenGetWayWnd({ itemId = costItem.itemId })
                   return
               end

               local strName = gModelItem:GetNameByRefId(costItem.itemId).."*"..costItem.itemNum
               local nickName = ccLngText(effectRef.nickName)
               local para =
               {
                   refId = 10049,
                   para = { strName,nickName},
                   func = function()
                       gModelHeroExtra:OnHeroFavorabilityUnlockReq(1,heroRefId)
                   end,
               }
               gModelGeneral:OpenUIOrdinTips(para)
           end
       else
            if not favorRefs.heroPlayItemSpAction then
                GF.ShowMessage(ccClientText(41628))
            else
                GF.ShowMessage(string.replace(ccClientText(41650),favorRefs.heroPlayItemSpAction.refId))
            end
       end
    else
        GF.ShowMessage(ccClientText(41627))
    end
end

function UIFavorabilityInteract:PlayHideTween()
    local tweenSeq = YXTween.TweenSequenceIns()

    local moveFunc = function(value)
		self:SetAnchorPos(self.mBtnSet, Vector2.New(46, -65+value))
		self:SetAnchorPos(self.mBtnInteract, Vector2.New(-110, 224-value))
		self:SetAnchorPos(self.mBtnCloseUp, Vector2.New(89, 224-value))
        self:SetAnchorPos(self.mReturnBtn, Vector2.New(67, 60-value))
		self:SetAnchorPos(self.mImgLove, Vector2.New(238, 157-value))
		self:SetAnchorPos(self.mListHero, Vector2.New(-62+value, -318))
    end
    local moveTween = YXTween.TweenFloat(0, 160,self.tweenTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)

    tweenSeq:OnComplete(function()
        self._hideTween = nil
        CS.ShowObject(self.mBtnSet, false)
        CS.ShowObject(self.mBtnInteract, false)
        CS.ShowObject(self.mReturnBtn, false)
        CS.ShowObject(self.mBtnCloseUp,false)
        CS.ShowObject(self.mImgLove,false)
    end)

    self._hideTween = tweenSeq
    tweenSeq:PlayForward()

end
function UIFavorabilityInteract:FoldDoTween(isShow)
	local tweenSeq = YXTween.TweenSequenceIns()
	local moveTween = self.mBtnHideShow:DOLocalRotate(Vector3.New(0, 0, isShow and 0 or 180),self.tweenTime):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)
    tweenSeq:OnComplete(function()
        self._foldTween = nil
        self:SetWndText(self.mTxtHideShow,self.isShow and ccClientText(41300) or ccClientText(41304))
    end)
    self._foldTween = tweenSeq
    tweenSeq:PlayForward()
end
function UIFavorabilityInteract:OnPlayIdle(action)
    if action and action =="idle" then
        self:OnUpdateTxtTips(ccClientText(41649))
        self.delayTimer = LxTimer.DelayTimeCall(function()
            CS.ShowObject(self.mItemTips,false)
            if gModelGameHelper.IsSpeeded() then gLGame:SetBaseTimeScale(gModelGameHelper:GetGameSpeed()) end
            LxTimer.DelayTimeStop(self.delayTimer)
            self.delayTimer = nil
            self.isPlayAction = false
        end,4)
    end
end

function UIFavorabilityInteract:PlayCloseUpSp(refId)
    self._uiSpineSpCtrl:StopPlayTween()
    self._uiSpineSpCtrl:Reset()

    local cbFunction = function()
        if not self:IsWndValid() then return end
        self._uiSpineSpCtrl:ResetPlayPos()
        self._curUIHeroObj:PlayIdleAni()
        if gModelGameHelper.IsSpeeded() then gLGame:SetBaseTimeScale(gModelGameHelper:GetGameSpeed()) end
        self.isPlayAction = false
    end
    if gModelGameHelper.IsSpeeded() then gLGame:SetBaseTimeScale(1) end
    self.isPlayAction = true
    self._uiSpineSpCtrl:StartPlayTween({
        type = 2,
        uiHeroObj = self._curUIHeroObj,
        bgImgTrans = self.mHeroBookImg,
        closeUpRefId = refId,
        initPos = self._initSpinePos,
        cb = cbFunction
    })
end

function UIFavorabilityInteract:UpdateLoveLevel()
    local effectRef = gModelHero:GetShowEffectById(self.curEffRefId)
    local heroRefId = effectRef.heroType
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId)
    self:SetWndText(self.mTxtLove,loveLevel or 0)
end
function UIFavorabilityInteract:OnHideOrShow(setState)
    self.isShow = setState
    self:FoldDoTween(self.isShow)
    if self.isShow then
        self:PlayShowTween()
    else
        self:PlayHideTween()
    end
end

function UIFavorabilityInteract:OnUpdateCurHero(num)
    self:ResetUISpineSpCtrl()
    local curHeroRefId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
    local curHeroIndx = self.allHeroIndx[curHeroRefId]
    if not curHeroIndx then return end
    local newHeroIndx = curHeroIndx
    if num then
        newHeroIndx = curHeroIndx+num
        local nexHeroRef = self.allHeroList[newHeroIndx]
        self.curEffRefId = nexHeroRef.refId
    end
    gLGameAudio:StopSingleSound()
    local nexHeroIndx = newHeroIndx+1
    local nexHeroRef = self.allHeroList[nexHeroIndx]
    local nexHero = nexHeroRef and gModelHero:IsActiveHeroEffRefId(nexHeroRef.refId) or false
    self:OnUpdateSkinList()
    self:OnUpdateList()
    self:CreateLiHui()
    CS.ShowObject(self.mCurLeftBtn,newHeroIndx>1)
    CS.ShowObject(self.mCurRightBtn,newHeroIndx<self.allHeroLeng and nexHero)
    local effectRef = GameTable.CharacterEffectRef[self.curEffRefId]
    CS.ShowObject(self.mBtnSet,gModelHero._gardenShowHeroEffRefId~=self.curEffRefId)
    local imgPath = not string.isempty(effectRef.skinBg) and effectRef.skinBg or effectRef.heroBg
    self:SetWndEasyImage(self.mHeroBookImg,imgPath)
    self:OnUpdateArrowBtnRed()
end
function UIFavorabilityInteract:OnUpdateSkinList()
    local heroRefId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
    self.effectListData = gModelHero:GetHeroEffectListByRefId(heroRefId) or {}
end
function UIFavorabilityInteract:OnUpdateArrowBtnRed()
    local heroId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
    local curHeroIndx = self.allHeroIndx[heroId] or 0
    local leftRed = false
    for i=curHeroIndx-1,1,-1 do
        local curHeroRefId = self.allHeroList[i].refId
        if curHeroRefId>0 and gModelHero:GetFavorabilityInteractRed(curHeroRefId,true) or
            gModelHero:GetFavorabilityInteractRed(curHeroRefId,false) then
                leftRed = true
                break
        end
    end
    CS.ShowObject(self.mRedLeft,leftRed)
    local rightRed = false
    for i= curHeroIndx+1,self.allHeroLeng,1 do
        local curHeroRefId = self.allHeroList[i].refId
        if curHeroRefId>0 and gModelHero:GetFavorabilityInteractRed(curHeroRefId,true) or
            gModelHero:GetFavorabilityInteractRed(curHeroRefId,false) then
                rightRed = true
                break
        end
    end
    CS.ShowObject(self.mRedRight,rightRed)
end

--- 2024/6/4：按要求添加重置功能(播放特写动作的时候 切页签需要中止播放，还有返回按钮，切换其他形象的也加一下)
function UIFavorabilityInteract:ResetUISpineSpCtrl()
    if not self._uiSpineSpCtrl then return end
    self._uiSpineSpCtrl:ResetUI()
end
function UIFavorabilityInteract:OnTimer(key)
    if self._ActionTimerKey == key then
        local isPlaying = gLGameAudio:IsSingleSoundPlaying()
        if not isPlaying then
            CS.ShowObject(self.mItemTips,false)
            self:TimerStop(self._ActionTimerKey)
        end
    end
end

function UIFavorabilityInteract:OnCloseUp()
    local active = gModelHero:IsActiveHeroEffRefId(self.curEffRefId)
    if active then
        self:ResetUISpineSpCtrl()
        --self:CurSpinePlayAni("idle")

        local effectRef = GameTable.CharacterEffectRef[self.curEffRefId]
        local heroRefId = effectRef.heroType
        local loveInfo =  gModelHero:GetFavorabilityInfo(heroRefId)
        local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId) or 0
        local favorRefs = gModelHero:GetHeroSpActionSoundRef()
        local isEmptyCfg = favorRefs.heroCloseUpSpAction.unlockHeroCloseUpSpActionSound
        local isUnlockCloseUpSp = true
        if  loveInfo and not string.isempty(isEmptyCfg) then
            isUnlockCloseUpSp = loveInfo.isUnlockCloseUpSp
        end
       if favorRefs.heroCloseUpSpAction and loveLevel>=favorRefs.heroCloseUpSpAction.refId then
           if isUnlockCloseUpSp then
               local spAction = favorRefs.heroCloseUpSpAction.spAction
               local action = effectRef[spAction] or "idle"

               if action ~= "idle" then--and spAction == "heroCloseUpSpAction"
                   self:PlayCloseUpSp(tonumber(action) or 0)
               else
                   self:CurSpinePlayAni(action)
               end

               local favorRef = favorRefs.heroCloseUpSpActionSound
               if favorRef and loveLevel>=favorRef.refId then
                   local actionSounds = string.split(effectRef[favorRef.SpActionSound] or "",";")
                   local soundsStr = string.split(effectRef.heroCloseUpSpActionDesc or "",";")
                   local indx = math.random(1,#actionSounds)
                   local actionSound = actionSounds[indx]
                   local soundStr = soundsStr[indx] or soundsStr[1]
                   if actionSound~="" then
                       gLGameAudio:PlaySingleSound(actionSound, function()
                           self:TimerStart(self._ActionTimerKey, 0.3, false, -1)
                       end)
                       if soundStr~="" then self:OnUpdateTxtTips(soundStr) end
                   end
               end
               self:OnPlayIdle(action)
               if gModelHero:GetFavorabilityInteractRed(self.curEffRefId,false) then
                   local heroRefId = effectRef.heroType
                   gModelHeroExtra:OnHeroInteractionReq(heroRefId,self.curEffRefId,2)
               end

           else
               local costItemData = favorRefs.heroCloseUpSpAction.unlockHeroCloseUpSpActionSound
               local costItem =  LUtil.GetRefItemData(costItemData)
               local haveNum = gModelItem:GetNumByRefId(costItem.itemId)
               if haveNum < costItem.itemNum then
                   gModelGeneral:OpenGetWayWnd({ itemId = costItem.itemId })
                   return
               end

               local strName = gModelItem:GetNameByRefId(costItem.itemId).."*"..costItem.itemNum
               local nickName = ccLngText(effectRef.nickName)
               local para =
               {
                   refId = 10050,
                   para = { strName,nickName},
                   func = function()
                       -- 1母汤 2 特写
                       gModelHeroExtra:OnHeroFavorabilityUnlockReq(2,heroRefId)
                   end,
               }
               gModelGeneral:OpenUIOrdinTips(para)
           end

       else
            GF.ShowMessage(string.replace(ccClientText(41650),favorRefs.heroCloseUpSpAction.refId))
       end
    else
        GF.ShowMessage(ccClientText(41627))
    end
end

function UIFavorabilityInteract:PlayShowTween()
    local tweenSeq = YXTween.TweenSequenceIns()
	CS.ShowObject(self.mBtnSet, true)
	CS.ShowObject(self.mBtnInteract, true)
	CS.ShowObject(self.mReturnBtn, true)
	CS.ShowObject(self.mBtnCloseUp,true)
	CS.ShowObject(self.mImgLove,true)
    CS.ShowObject(self.mBtnSet,gModelHero._gardenShowHeroEffRefId~=self.curEffRefId)

    local moveFunc = function(value)
        if gLGameLanguage:IsJapanVersion() then
            self:SetAnchorPos(self.mBtnSet,Vector2.New(80,95-value))
        else
            self:SetAnchorPos(self.mBtnSet, Vector2.New(46, 95-value))
        end

		self:SetAnchorPos(self.mBtnInteract, Vector2.New(-110, 64+value))
		self:SetAnchorPos(self.mBtnCloseUp, Vector2.New(89, 64+value))
		self:SetAnchorPos(self.mReturnBtn, Vector2.New(67, -100+value))
		self:SetAnchorPos(self.mImgLove, Vector2.New(238, -3+value))
		self:SetAnchorPos(self.mListHero, Vector2.New(98-value, -318))
    end
    local moveTween = YXTween.TweenFloat(0, 160, self.tweenTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)

    tweenSeq:OnComplete(function()
        self._showTween = nil
    end)

    self._showTween = tweenSeq
    tweenSeq:PlayForward()

end
-- function UIFavorabilityInteract:CreateLiHui1()
--     local effectRef = gModelHero:GetShowEffectById(self.curEffRefId)
--     local heroRefId = effectRef.heroType
--     local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId)
--     self:SetWndText(self.mTxtLove,loveLevel or 0)
--     self:DestroyWndSpineByKey("GardenHeroInteract")
--     CS.ShowObject(self.mHeroLiHuiPos,false)
-- 	local drawing = effectRef.heroDrawing
-- 	local dpSpine = self:CreateWndSpine(self.mHeroLiHuiPos,drawing,"GardenHeroInteract",true,function (dpLoaded)
-- 		dpLoaded:PlayAnimation(0,"idle",true)
--         CS.ShowObject(self.mHeroLiHuiPos,true)
--         if not dpLoaded or not dpLoaded:IsDpValid() then return end--加点击事件
--             local spineTrans = dpLoaded:GetSpineTrans()
--             if not spineTrans then return end
--             self._clickCom = spineTrans.gameObject:AddComponent(typeSpineClick)
--             self._clickCom.isUISpine = true
--             self._clickCom.onClick = function()
--                 local action = gModelHero:GetHeroClickAction(self.curEffRefId)
--                 if action and action~="" then
--                     dpLoaded:PlayAnimation(0,action,false)
--                     dpLoaded:SetAnimationCompleteFunc(function(ainName)
--                         if ainName == action then
--                             dpLoaded:PlayAnimation(0, "idle", true)
--                         end
--                     end)
--                 end

--                 local actionSound,soundDesc = gModelHero:GetHeroClickSound(self.curEffRefId)
--                 if actionSound and actionSound ~="" then
--                     gLGameAudio:PlaySingleSound(actionSound, function()
--                         self:TimerStart(self._ActionTimerKey, 0.3, false, -1)
--                     end)
--                     if soundDesc~="" then self:OnUpdateTxtTips(soundDesc) end
--                 end
--                 self:OnPlayIdle(action)
--         end
-- 	end,true)
-- 	dpSpine:StartLoad()
-- end

function UIFavorabilityInteract:CreateLiHui()
    local effectRef = gModelHero:GetShowEffectById(self.curEffRefId)
    local heroRefId = effectRef.heroType
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId)
    self:SetWndText(self.mTxtLove,loveLevel or 0)
    local effectRef = gModelHero:GetShowEffectById(self.curEffRefId)
    if not effectRef then return end
    self.isPlayAction = false

    local uiHeroObjList = self._uiHeroObjList
    if not uiHeroObjList then
        uiHeroObjList = {}
        self._uiHeroObjList = uiHeroObjList
    end

    local heroDrawing = effectRef.heroDrawing

    ---@type LUIHeroObject
    local newUILiHuiObj = uiHeroObjList[heroDrawing]

    ---@type LUIHeroObject
    local oldUIHeroObj = self._curUIHeroObj
    if oldUIHeroObj and newUILiHuiObj ~= oldUIHeroObj then
        oldUIHeroObj:ShowHero(false)
    end

    if newUILiHuiObj then
        newUILiHuiObj:ShowHero(true)
    else
        newUILiHuiObj = LUIHeroObject:New(self)
        uiHeroObjList[heroDrawing] = newUILiHuiObj
        newUILiHuiObj:Create(self.mHeroLiHuiPos,heroDrawing,heroDrawing)
        newUILiHuiObj:SetHeroBgParams({
            effRef = effectRef,
            lihuiBgTrans = self.mHeroLiHuiBgPos,
            lihuiHdTrans = self.mHeroLiHuiHdPos,
        })
        --newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:ShowHero(true)
        newUILiHuiObj:SetLoadedFunction(function()
            local _displaySpine = newUILiHuiObj:GetDpObject()
            if _displaySpine then _displaySpine:SetRaycastTarget(true) end
            newUILiHuiObj:PlayIdleAni()
            CS.ShowObject(self.mHeroLiHuiPos,true)
        end)
        newUILiHuiObj:SetClickFunc(function()
            if self.isPlayAction then return end
            local action = gModelHero:GetHeroClickAction(self.curEffRefId)
            if action and action ~= "" then
                self:CurSpinePlayAni(action)
                -- newUILiHuiObj:PlayAni(action,false,nil,nil,true)
                -- local spine = newUILiHuiObj:GetDisplaySpine()
                -- spine:SetAnimationCompleteFunc(function(ainName)
                --     if ainName == action then
                --         spine:PlayAnimation(0, "idle", true)
                --     end
                -- end)
                -- spine:PlayAnimation(0,action,false)
            end

            local actionSound,soundDesc = gModelHero:GetHeroClickSound(self.curEffRefId)
            if actionSound and actionSound ~="" then
                gLGameAudio:PlaySingleSound(actionSound, function()
                    self:TimerStart(self._ActionTimerKey, 0.3, false, -1)
                end)
                if soundDesc ~= "" then
                    self:OnUpdateTxtTips(soundDesc)
                end
            end
            self:OnPlayIdle(action)
        end)
        newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:StartLoad()
    end
    self._curUIHeroObj = newUILiHuiObj

end

function UIFavorabilityInteract:OnUpdateBtn()
    local effCfg = GameTable.CharacterEffectRef[self.curEffRefId]
    local heroRefId = effCfg.heroType
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId) or 0
    local refs = gModelHero:GetHeroSpActionSoundRef()
    local loveInfo =  gModelHero:GetFavorabilityInfo(heroRefId)
    local isEmptyCfgSpAction = refs.heroPlayItemSpAction.unlockHeroPlayItemSpAction
    local isEmptyCfgCloseUpSp = refs.heroCloseUpSpAction.unlockHeroCloseUpSpActionSound
    local isUnlockSpAction = true
    local isUnlockCloseUpSp = true
    if  loveInfo then
        if not string.isempty(isEmptyCfgSpAction) then
            isUnlockSpAction = loveInfo.isUnlockSpAction
        end
        if not string.isempty(isEmptyCfgCloseUpSp) then
            isUnlockCloseUpSp = loveInfo.isUnlockCloseUpSp
        end
    end
    local interactRef = refs.heroPlayItemSpAction
    local closeUpRef = refs.heroCloseUpSpAction
    self:SetWndImageGray(self.mBtnInteract,not (interactRef.refId<= loveLevel) or not isUnlockSpAction)
    self:SetWndImageGray(self.mBtnCloseUp,not (closeUpRef.refId<= loveLevel) or not isUnlockCloseUpSp)
    local res = not string.isempty(effCfg.playItemIcon) and effCfg.playItemIcon or "home_btn_icon_1"
    self:SetWndEasyImage(self.mBtnInteract, res, nil, true)
    local red = gModelHero:GetFavorabilityInteractRed(self.curEffRefId,true) and isUnlockSpAction
    CS.ShowObject(self.mImgInteractRed,red)
    local red2 = gModelHero:GetFavorabilityInteractRed(self.curEffRefId,false) and isUnlockCloseUpSp
    CS.ShowObject(self.mImgRed,red2)

    if self.selectItem then
        local ImgRed = CS.FindTrans(self.selectItem,"ImgRed")
        CS.ShowObject(ImgRed,red or red2)
    end
end

------------------------------------------------------------------
return UIFavorabilityInteract