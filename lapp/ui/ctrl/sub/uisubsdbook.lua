---
--- Created by Administrator.
--- DateTime: 2024/5/21 21:09:00
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSdBook:LChildWnd
local UISubSdBook = LxWndClass("UISubSdBook", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSdBook:UISubSdBook()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSdBook:OnWndClose()
	FireEvent(EventNames.CLOSE_BOOK_VIEW)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSdBook:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSdBook:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitData()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:RefreshView()
	self:RefreshForeign()
end





function UISubSdBook:InitHalidomIconList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans, list, function(...) self:OnDrawHalidomIconCell(...) end)
	end
end

function UISubSdBook:OnClickBtnAttrOverViewFunc()
	gModelHalidom:OpenAttrOverViewByMySelf()
end

function UISubSdBook:OnDrawAttrCell(list, item, itemdata, itempos)
	local AttrIcon = self:FindWndTrans(item,"AttrIcon")
	local AttrInfo = self:FindWndTrans(item,"AttrInfo")

	local attrRefId = itemdata.attrRefId
	local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
	self:SetWndEasyImage(AttrIcon,attrIcon,function() CS.ShowObject(AttrIcon,true) end)

	local name = gModelHero:GetAttributeNameById(attrRefId)
	local valStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId,itemdata.attrType,itemdata.attrNum)
	self:SetWndText(AttrInfo,string.replace(ccClientText(41536),name,valStr))
end

function UISubSdBook:InitText()
	self:SetTextTile(self.mBtnAttrOverView,ccClientText(41519))
end

function UISubSdBook:OnClickBtnBgFunc(itemdata)
	local jumpBackCB = function()
		GF.CloseWndByName("UISd")
	end
	local refId = itemdata.refId
	---@type StructHalidomObjInfo
	local halidomObj = itemdata.halidomObj
	if halidomObj then
		gModelHalidom:OpenOptHalidomTips({
			halidomObj = halidomObj,
			refId = refId,
			jumpBackCB = jumpBackCB,
		})
	else
		gModelHalidom:OpenFullMaxHalidomTips({
			refId = refId,
			jumpBackCB = jumpBackCB,
		})
	end
end

function UISubSdBook:OnDrawHalidomIconCell(list, item, itemdata, itempos)
	local BtnBg = self:FindWndTrans(item,"BtnBg")
	local yjsEffDRoot = self:FindWndTrans(item,"yjsEffDRoot")
	local yjsEffTRoot = self:FindWndTrans(item,"yjsEffTRoot")
	local kjsEffRoot = self:FindWndTrans(item,"kjsEffRoot")
	local Icon = self:FindWndTrans(item,"Icon")
	local BtnCollect = self:FindWndTrans(item,"BtnCollect")
	local CollectEffect = self:FindWndTrans(item,"CollectEffect")
	local StarList = self:FindWndTrans(item,"StarList")
	local NameTxt = self:FindWndTrans(item,"NameTxt")
	local lockImg = self:FindWndTrans(item,"lockImg")
	local redPoint = self:FindWndTrans(item,"redPoint")

	self:SetTextTile(BtnCollect,ccClientText(41520))

	self:SetWndText(NameTxt,itemdata.name)
	if gLGameLanguage:IsJapanVersion() then
		self:InitTextSizeWithLanguage(NameTxt,-6)
	end
	self:SetWndEasyImage(Icon,itemdata.icon,function()
		CS.ShowObject(Icon,true)
	end,true)

	local halidomRefId = itemdata.refId

	local isYJS = false
	local isKJS = false
	local showBtnCollect = false
	local showRed = false
	local star = 0
	---@type StructHalidomObjInfo
	local halidomObj = itemdata.halidomObj
	if halidomObj then
		star = halidomObj.starLv
		showRed = gModelHalidom:CheckRPHasUpStarByHalidomObj(halidomObj)

		showBtnCollect = halidomObj:CheckHasAddExp()
		isYJS = true

--[[		self:CreateWndEffect_Ex({
			trans = yjsEffDRoot,
			effName = "fx_ui_shengwu_yjs",
			effKey = yjsEffDRoot:GetInstanceID(),
			upSortOrder = 1
		})]]

		self:CreateWndEffect_Ex({
			trans = yjsEffDRoot,
			effName = "fx_ui_shengwu_yjs_down",
			effKey = yjsEffDRoot:GetInstanceID(),
			upSortOrder = 4,
--[[			---@param dpEff LDisplayEffect
			endFunc = function(dpEff)
				local trans = dpEff:GetDisplayTrans()
				local ui_shengwu = self:FindWndTrans(trans,"gua/ui_shengwu")
				if ui_shengwu then
					self:SetWndSpriteRenderer(ui_shengwu,itemdata.icon)
				end
			end]]
		})

		self:CreateWndEffect_Ex({
			trans = yjsEffTRoot,
			effName = "fx_ui_shengwu_yjs_up",
			effKey = yjsEffTRoot:GetInstanceID(),
			upSortOrder = 6,
		})
		--CS.ShowObject(Icon,false)
	else
		showRed = gModelHalidom:CheckRPHasActByRefId(halidomRefId)

		if showRed then
			isKJS = true
			self:CreateWndEffect_Ex({
				trans = kjsEffRoot,
				effName = "fx_ui_shengwu_kjs",
				effKey = kjsEffRoot:GetInstanceID(),
				upSortOrder = 6,
			})
		end
	end
	CS.ShowObject(redPoint,showRed)
	CS.ShowObject(kjsEffRoot,isKJS)
	CS.ShowObject(yjsEffDRoot,isYJS)
	CS.ShowObject(yjsEffTRoot,isYJS)

	local isLock = halidomObj == nil
	CS.ShowObject(lockImg,isLock and not isKJS)

	CS.ShowObject(BtnCollect,showBtnCollect)

	--- 不置灰，改成透明值 为 77，即 77/255，大概为 0.3
	self:SetWndImageGray(Icon,isLock)

	local alpha = isLock and 0.3 or 1
	self:SetImageAlpha(Icon,alpha)


	self:InitStarList(StarList,star,halidomRefId)

	local transInfo = {
		BtnCollectTrans = BtnCollect,
		CollectEffectTrans = CollectEffect,
	}

	self:SetWndClick(BtnCollect,function() self:OnClickBtnCollectFunc(itemdata,transInfo) end)

	self:SetWndClick(BtnBg,function() self:OnClickBtnBgFunc(itemdata) end)
end

function UISubSdBook:InitCollectListList()
	local list = self:GetCollectListList()
	local uiList = self:FindUIScroll("mCollectList")
	if uiList then
        uiList:RefreshList(list)
		uiList:DrawAllItems(false)
	else
		uiList = self:GetUIScroll("mCollectList")
		uiList:Create(self.mCollectList, list, function(...)
			self:OnDrawCollectCell(...)
		end,UIItemList.SUPER)
	end
end

function UISubSdBook:OnEventRefresBookView()
	self:RefreshView()
end

function UISubSdBook:DoEffectAni(refId,addExp)
	local transInfo = self._recordHalidomInfo[refId]
	if not transInfo then
		self:RefreshView()
		return
	end

	local effectTrans = transInfo.CollectEffectTrans
	if not effectTrans then
		self:RefreshView()
		return
	end

	local halidomType = gModelHalidom:GetHalidomTypeByRefId(refId)
	local collectTransInfo = self._recordCollectTrans[halidomType]
	if not collectTransInfo then
		self:RefreshView()
		return
	end

	local SliderTrans = collectTransInfo.SliderTrans
	if not SliderTrans then
		self:RefreshView()
		return
	end

	local DoEffTxtTrans = collectTransInfo.DoEffTxtTrans
	self:SetWndText(DoEffTxtTrans,string.replace("+#a1#",addExp))


	local key = effectTrans:GetInstanceID()
	local effect = self:FindWndEffectByKey(key)
	local doAniTransInfo = {
		effectTrans = effectTrans,
		moveEndTrans = SliderTrans,
		sliderEffTrans = collectTransInfo.SliderEffTrans,
		DoEffTxtTrans = DoEffTxtTrans
	}
	if effect then
		self:DoUpStarEffect(key,refId,doAniTransInfo)
	else
		self:CreateWndEffect_Ex({
			trans = effectTrans,
			effName = "fx_shengwu_bullet",
			effKey = key,
			upSortOrder = 6,
			endFunc = function()
				self:DoUpStarEffect(key,refId,doAniTransInfo)
			end
		})
--[[		self:CreateWndEffect(effectTrans,"fx_shengwu_bullet",key,100,false,false,false,
		false,false,false,false,function()
			self:DoUpStarEffect(key,refId,doAniTransInfo)
		end)]]
	end
end













function UISubSdBook:GetStarList(star,halidomRefId)
	local list = {}
	local info = gModelHalidom:GetShowStarImg(star,halidomRefId)
	local showNum = info.showNum
	local starImg = info.starImg
	for i = 1,showNum do
		table.insert(list,{ img = starImg, })
	end
	return list
end

function UISubSdBook:OnItemChange()
	self:RefreshView()
end

function UISubSdBook:OnClickBtnCollectFunc(itemdata,transInfo)
	---@type StructHalidomObjInfo
	local halidomObj = itemdata.halidomObj
	if not halidomObj then return end

	if not halidomObj:CheckHasAddExp() then return end

	local refId = itemdata.refId
	if self._recordHalidomInfo[refId] then return end

	self._recordHalidomInfo[refId] = transInfo

	--self:DoEffectAni(refId,1000)

	gModelHalidom:OnHalidomAddExpReq(refId)
end

function UISubSdBook:InitMsg()
	self:WndEventRecv(EventNames.REFRESH_BOOK_VIEW,function (...) self:OnEventRefresBookView() end)
	self:WndEventRecv(EventNames.On_Item_Change,function (...) self:OnItemChange() end)
	--self:WndNetMsgRecv(LProtoIds.HalidomStarUpResp,function(...) self:OnHalidomStarUpResp(...) end)
	self:WndNetMsgRecv(LProtoIds.HalidomCollectUpgradeResp,function(...) self:OnHalidomCollectUpgradeResp(...) end)
	self:WndNetMsgRecv(LProtoIds.HalidomAddExpResp,function(...) self:OnHalidomAddExpResp(...) end)
end

function UISubSdBook:DoUpStarEffect(key,refId,transInfo)
	local effectTrans,moveEndTrans = transInfo.effectTrans,transInfo.moveEndTrans

	---@type SequenceCom
	local seqCom = self:GetSeqCom()
	seqCom:DeleteSeq(key)
	CS.ShowObject(effectTrans,true)

	local DoEffTxtTrans = transInfo.DoEffTxtTrans
	CS.ShowObject(DoEffTxtTrans,true)

	local doEffTxtPos = DoEffTxtTrans.localPosition
	local recordlocalPos = effectTrans.localPosition

	local seq = seqCom:CreateSeq(key)
	local endPos = moveEndTrans.position
	seq:Append(effectTrans:DOMove(endPos,0.2))
	seq:AppendCallback(function()
		CS.ShowObject(effectTrans,false)
		self:RefreshView()
		effectTrans.localPosition = recordlocalPos
		CS.ShowObject(transInfo.sliderEffTrans,true)
	end)

	seq:Append(DoEffTxtTrans:DOLocalMoveY(doEffTxtPos.y + 10,0.4))

	seq:OnKill(function()
		CS.ShowObject(effectTrans,false)
		effectTrans.localPosition = recordlocalPos
		DoEffTxtTrans.localPosition = doEffTxtPos
		CS.ShowObject(DoEffTxtTrans,false)
		self:RefreshView()
	end)

	seq:OnComplete(function()
		seqCom:DeleteSeq(key)
		CS.ShowObject(transInfo.sliderEffTrans,false)
		DoEffTxtTrans.localPosition = doEffTxtPos
		self._recordHalidomInfo[refId] = nil
	end)
	seq:PlayForward()
end

function UISubSdBook:OnHalidomAddExpResp(pb)
	local obj = pb.obj
	if not obj then
		self:RefreshView()
		return
	end

	self:DoEffectAni(obj.refId,pb.addExp)
end

function UISubSdBook:OnHalidomStarUpResp()
	self:RefreshView()
end
function UISubSdBook:RefreshForeign()
	if self._isVie then
		local textTran =CS.FindTrans(self.mBtnAttrOverView,"UIText")
		self:InitTextLineWithLanguage(textTran,0)
		LxUiHelper.SetSizeWithCurAnchor(textTran,0,100)
	end
end

function UISubSdBook:InitStarList(trans,star,halidomRefId)
	local list = self:GetStarList(star,halidomRefId)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans, list, function(...) self:OnDrawStarCell(...) end)
	end
end

function UISubSdBook:OnDrawCollectCell(list, item, itemdata, itempos)
	local TopDiv = self:FindWndTrans(item,"TopDiv")
	local TitleBg = self:FindWndTrans(TopDiv,"TitleBg")
	local TitleName = self:FindWndTrans(TitleBg,"TitleName")
	local SliderTrans = self:FindWndTrans(TitleBg,"Slider")
	local SliderEff = self:FindWndTrans(SliderTrans,"SliderEff")
	local SliderNum = self:FindWndTrans(TitleBg,"SliderNum")
	local JFTxt = self:FindWndTrans(TitleBg,"JFBg/JFTxt")
	local DoEffTxt = self:FindWndTrans(TitleBg,"DoEffTxt")

	local InfoBg = self:FindWndTrans(TopDiv,"InfoBg")
	local AttrList = self:FindWndTrans(InfoBg,"AttrList")
	local LockDiv = self:FindWndTrans(InfoBg,"LockDiv")
	local LockDesc = self:FindWndTrans(LockDiv,"LockDesc")

	local HalidomIconList = self:FindWndTrans(item,"HalidomIconList")

	self:CreateWndEffect_Ex({
		trans = SliderEff,
		effName = "fx_shengwu_hit",
		effKey = SliderEff:GetInstanceID(),
		upSortOrder = 6,
	})
	--self:CreateWndEffect(SliderEff,"fx_shengwu_hit",SliderEff:GetInstanceID(),100)
	CS.ShowObject(SliderEff,false)

	self._recordCollectTrans[itemdata.refId] = {
		SliderTrans = SliderTrans,
		SliderEffTrans = SliderEff,
		DoEffTxtTrans = DoEffTxt,
	}

	self:SetWndText(TitleName,itemdata.name)

	local attrList = {}
	local lv = 0
	local showSliderNum = false
	local curNum,maxNum
	local progress = 0

	local isLock = itemdata.isLock

	--- 无对象时，默认为未激活图鉴
	---@type StructHalidomCollectObjInfo
	local collectObj = itemdata.collectObj
	if collectObj then
		local collectRefId = collectObj.refId
		lv = gModelHalidom:GetHalidomCollectLvByRefId(collectRefId)
		if gModelHalidom:CheckHalidomCollectIsMaxLv(collectRefId) then
			progress = 1
		else
			showSliderNum = true
			curNum = collectObj.exp
			maxNum = gModelHalidom:GetHalidomCollectExpByRefId(collectRefId)
			progress = curNum / maxNum
		end
		attrList = gModelHalidom:GetHalidomCollectAttrByRefId(collectRefId)
	else
		showSliderNum = true
		lv = gModelHalidom:GetInitHalidomCollectLvDatas(itemdata.refId)
		curNum = 0
		maxNum = gModelHalidom:GetInitHalidomCollectExpDatas(itemdata.refId)
		progress = curNum / maxNum
	end

	if isLock then
		self:SetWndText(LockDesc,itemdata.desc)
	end
	CS.ShowObject(LockDiv,isLock)

	local isHasList = #attrList > 0
	CS.ShowObject(AttrList,isHasList)
	if isHasList then
		self:InitAttrList(AttrList,attrList)
	end

	local showInfoBg = isLock or isHasList
	CS.ShowObject(InfoBg,showInfoBg)

	local sliderStr = ""
	if showSliderNum then
		sliderStr = string.replace(ccClientText(41518),curNum,maxNum)
	else
		sliderStr = ccClientText(41551)
	end
	self:SetWndText(SliderNum,sliderStr)

	local slider = self:UIProgressFind(SliderTrans,item:GetInstanceID(),progress)
	slider:SetUIProgress(progress)
	self:SetWndText(JFTxt,lv)

	local typeList = itemdata.typeList
	--- 25 = HalidomIconList 距离底部的高度 + HalidomIconList 和 TopDiv 的间距
	local height = 110 + math.ceil(#typeList / 3) * 194 + 25

	self:InitHalidomIconList(HalidomIconList,typeList)

	self:SetWndClick(TitleBg,function()
		gModelHalidom:OpenAttrOverViewMySelfByRefId(itemdata.refId)
	end)

	--LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end

function UISubSdBook:InitEvent()
	self:SetWndClick(self.mBtnHelp,function() self:OnClickBtnHelpFunc() end)
	self:SetWndClick(self.mBtnAttrOverView,function() self:OnClickBtnAttrOverViewFunc() end)
end

function UISubSdBook:RefreshView()
	self:InitCollectListList()
end

function UISubSdBook:OnClickBtnHelpFunc()
	GF.OpenWnd("UIBzTips",{refId = 163})
end
function UISubSdBook:InitData()
	--- 点击收藏记录的节点
	self._recordHalidomInfo = {}

	--- 收藏列表节点
	self._recordCollectTrans = {}
end

function UISubSdBook:OnHalidomCollectUpgradeResp()
	self:RefreshView()
end

function UISubSdBook:GetCollectListList()
	return gModelHalidom:GetHalidomTypeRefList()
end

function UISubSdBook:OnDrawStarCell(list, item, itemdata, itempos)
	local StarImg = self:FindWndTrans(item,"StarImg")
	self:SetWndEasyImage(StarImg,itemdata.img,function()
		CS.ShowObject(StarImg,true)
	end,true)
end





function UISubSdBook:InitAttrList(trans,list)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(trans, list, function(...) self:OnDrawAttrCell(...) end)
	end
end

------------------------------------------------------------------
return UISubSdBook