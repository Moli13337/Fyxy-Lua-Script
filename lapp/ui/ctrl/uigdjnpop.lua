---
--- Created by BY.
--- DateTime: 2023/10/10 14:55:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdJNPop:LWnd
local UIGdJNPop = LxWndClass("UIGdJNPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdJNPop:UIGdJNPop()
	self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdJNPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdJNPop:OnCreate()
	LWnd.OnCreate(self)
	self._tabTransList={}		--标签列表Trans
	self._skillIconList={}		--内环技能IconTrans
	self._arrtIconList={}		--外环属性Trans
	self._arrtSelectList={}		--外环属性选中Trans
	self._currJob=nil			--当前职业
	self._fillAmount={0.1,0.24,0.4,0.6,0.75,0.9}
	self._changeTypeList={}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdJNPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion() or gLGameLanguage:IsVieVersion()
	CS.ShowObject(self.mTitle_En,self._isEnus)
	CS.ShowObject(self.mTitle,not self._isEnus)

	self._isVie = gLGameLanguage:IsVieVersion()
	
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:RefreshForeign()
end

function UIGdJNPop:InitCommand()
	self:SetWndButtonText(self.mUpBtn,ccClientText(13300))
	self:SetWndText(self.mResetText,ccClientText(13318))
	self:SetWndText(self.mLblBiaoti,ccClientText(12616))
	self:InitTextLineWithLanguage(self.mResetText, -30)
	self:SetWndText(self.mAddHeroText,ccClientText(13319))
	self:InitTextLineWithLanguage(self.mAddHeroText, -30)
	self._skillIconList={
		self.mSkill1Icon,
		self.mSkill2Icon,
		self.mSkill3Icon
	}
	self._arrtIconList={
		self.mArrt1Icon,
		self.mArrt2Icon,
		self.mArrt3Icon,
		self.mArrt4Icon,
		self.mArrt5Icon,
		self.mArrt6Icon,
	}
	self._arrtSelectList={
		self.mSelect1Image,
		self.mSelect2Image,
		self.mSelect3Image,
		self.mSelect4Image,
		self.mSelect5Image,
		self.mSelect6Image
	}
	local list=gModelGuild:GetGuildSkillJobRef()
	if(self._uiList)then
		self._uiList:RefreshList(list)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mTabScroll,list,function (...) self:ListItem(...) end)
	end
	self:OnClickJobTab(1)
	self:CreateWndEffect(self.mBgEff,"fx_GHJN_beijing","fx_GHJN_beijing",100,false,false)
end

function UIGdJNPop:OnClickCloseWnd(bBtnClick)
	gModelHero:ClearCareerTypeAttrList(self._changeTypeList)
	if not self:WndCloseAndBack() and bBtnClick then
		GF.OpenWnd("UIGdWin")
	end
end
function UIGdJNPop:RefreshForeign()
	if self._isVie then
		self:SetAnchorPos(self.mHelpBtn,Vector2.New(130,-104.6))

	end
end

function UIGdJNPop:OnClickReset()--点击重置
	local name=gModelGuild:GetGuildSkillJobRefNameByJobType(self._type)
	local item=gModelGuild:GetGuildSkillResetNeed(self._resetCount+1)
	local needStr=gModelItem:GetNameByRefId(item.itemId)..item.itemNum
	local itemList= gModelGuild:GetGuildSkillAttrRefNeedByRefId(self._attributeId)
	local resetRatio=gModelGuild:GetGuildSkillResetRatio()
	for i, v in ipairs(itemList) do
		v.itemNum=math.floor(v.itemNum*resetRatio)
	end
	local itemId  = item.itemId
	local itemNum = item.itemNum
	GF.OpenWnd("UIOrdinTip",{refId=51301,itemList=itemList,para={needStr,name},func=function (...)
		local num=gModelItem:GetNumByRefId(item.itemId)
		if(num<item.itemNum)then
			local wndName = self:GetWndName()
			gModelGeneral:OpenGetWayWnd({itemId=item.itemId,srcWnd = wndName})
			return
		end
		gModelGuild:OnGuildSkillResetReq(self._currJob)
	end , consume = {itemNum, itemId}})
end

function UIGdJNPop:SetArrtIconSelect(attributeId)--设置属性下级选中
	for i, v in ipairs(self._arrtSelectList) do
		CS.ShowObject(v,false)
	end
	local pos=gModelGuild:GetGuildSkillAttrRefPosByRefId(attributeId)
	if(self._pos and self._pos==6 and pos==1)then
		self:CreateWndEffect(self.mUpEff,"fx_GHJN_shengjie","fx_GHJN_shengjie",100,false,false)
	end
	local trans=self._arrtSelectList[pos]
	if(trans)then
		CS.ShowObject(trans,true)
		self:CreateWndEffect(trans,"fx_GHJN_shengji","fx_GHJN_shengji"..pos,100,false,false)
	end
	if(pos==-1)then
		pos=6
	end
	self.mBarImage.fillAmount=self._fillAmount[pos]
	self._pos = pos
end

function UIGdJNPop:RefreshData()
	local info = gModelGuild:GetGuildSkillInfoByType(self._job)
	local type=info.type					--职业类型： 1法师，2战士，3坦克，4.辅助
	self._type=info.type
	local attributeId=info.attributeId		--当前技能refId
	self._attributeId=attributeId
	local resetCount=info.resetCount
	self._resetCount=resetCount
	local skillIdList={}			--已激活最大等级的职业技能列表
	for i, v in pairs(info.skillId) do
		table.insert(skillIdList,v)
	end
	if(#skillIdList<3)then
		skillIdList=gModelGuild:GetSkillRefSkillListByTypeRefId(type,skillIdList)
	end
	self:SetTabTransList(type)
	self:SetArrtIconSelect(attributeId)
	local itemList= gModelGuild:GetGuildSkillRefUpNeedByRefId(type,attributeId)
	self._needItemList=itemList
	self:SetUpNeed()
	local list=gModelGuild:GetGuildSkillAttrRefAttrByRefId(type,attributeId)
	if(self._attrList)then
		self._attrList:RefreshList(list)
	else
		self._attrList = self:GetUIScroll("_attrList")
		self._attrList:Create(self.mArrtScroll,list,function (...) self:ArrtListItem(...) end)
	end
	local upArrt = gModelGuild:GetGuildSkillRefNexdArrtByRefId(type,attributeId)
	self:SetWndText(self.mUpArrtText,upArrt)
	local ref=gModelGuild:GetGuildSkillAttrRefByRefId(attributeId)
	local level=(ref and ref.level) or 0
	self:SetSkillIconList(level ,skillIdList)
	if(level>=gModelGuild:GetGuildSkillResetMinMax())then
		CS.ShowObject(self.mResetBtn,true)
	else
		CS.ShowObject(self.mResetBtn,false)
	end
	local titleStr=""
	if(type==1)then
		titleStr=string.replace(ccClientText(13302),level)
	elseif(type==2)then
		titleStr=string.replace(ccClientText(13301),level)
	elseif(type==3)then
		titleStr=string.replace(ccClientText(13304),level)
	elseif(type==4)then
		titleStr=string.replace(ccClientText(13303),level)
	end

	if self._isEnus then
		self:SetWndText(self.mTitleText_En,titleStr)
	else
		self:SetWndText(self.mTitleText,titleStr)
	end
end

function UIGdJNPop:SetSkillIconList(level,skillIdList)
	for i, v in ipairs(skillIdList) do
		local skillTrans= self._skillIconList[i]
		local mask=CS.FindTrans(skillTrans,"Mask")
		local lvBg=CS.FindTrans(skillTrans,"Image")
		local lvText=CS.FindTrans(lvBg,"SkillLvText")
		local ref= gModelGuild:GetGuildSkillRefByRefId(v)
		local skillIcon= gModelGuild:GetSkillRefIconByRefId(ref.skillId)
		local lv=ref.needLevel
		if(lv>level)then
			CS.ShowObject(mask,true)
			CS.ShowObject(lvBg,false)
			local maskText=CS.FindTrans(mask,"UIText")
			local str = string.replace(ccClientText(13312),lv)
			self:SetWndText(maskText,str)
		else
			CS.ShowObject(mask,false)
			CS.ShowObject(lvBg,true)
			self:SetWndText(lvText,ref.skillLevel)
		end
		self:SetWndEasyImage(skillTrans,skillIcon,function ()
			CS.ShowObject(skillTrans,true)
		end)
		self:SetWndClick(skillTrans, function(...)
			local skills = gModelGuild:GetGuildSkillRefByJobSkillType(self._job,i)
			local iref = skills[1]
			--GF.OpenWnd("UINewJNTip",{skill = iref.skillId, curSkillId = ref.skillId,wndType = 4,grade = level})
			gModelGeneral:OpenSkillWnd({skill = iref.skillId, curSkillId = ref.skillId,wndType = 4,grade = level})
		end)
	end
end

function UIGdJNPop:ListItem(list,item, itemdata, itempos)
	self._tabTransList[itemdata.jobType]=item
	local image=CS.FindTrans(item,"Image")
	local select=CS.FindTrans(item,"SelectImage")
	local text=CS.FindTrans(item,"UIText")

	CS.ShowObject(select,false)
	self:SetWndEasyImage(image,itemdata.tabIcon,function ()
		CS.ShowObject(image,true)
		local jobStr=""
		if(itemdata.jobType==1)then
			jobStr=ccClientText(13306)
		elseif(itemdata.jobType==2)then
			jobStr=ccClientText(13305)
		elseif(itemdata.jobType==3)then
			jobStr=ccClientText(13308)
		elseif(itemdata.jobType==4)then
			jobStr=ccClientText(13307)
		end

		local isForeign = gLGameLanguage:IsForeignRegion()
		jobStr = isForeign and "" or jobStr
		self:SetWndText(text,jobStr)
		self:SetWndClick(item, function(...) self:OnClickJobTab(itemdata.jobType) end)
	end)
end

function UIGdJNPop:OnClickAddHero()
	GF.OpenWnd("UIGdJNAddSagaPop")
end

function UIGdJNPop:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId=37})
end

function UIGdJNPop:SetUpNeed()--设置升级材料
	local itemList=self._needItemList
	self._needItemId=0
	if(not itemList or #itemList<=0)then
		CS.ShowObject(self.mNeedText,true)
		self:SetWndText(self.mNeedText,ccClientText(13311))
		CS.ShowObject(self.mConsume1,false)
		CS.ShowObject(self.mConsume2,false)
		CS.ShowObject(self.mUpBtn,false)
		CS.ShowObject(self.mUpArrtText,false)
		return
	end
	CS.ShowObject(self.mNeedText,false)
	CS.ShowObject(self.mConsume1,true)
	CS.ShowObject(self.mConsume2,true)
	CS.ShowObject(self.mUpBtn,true)
	CS.ShowObject(self.mUpArrtText,true)
	local item1=itemList[1]
	local item2=itemList[2]
	local num1= gModelItem:GetNumByRefId(item1.itemId)
	local num2= gModelItem:GetNumByRefId(item2.itemId)
	local color="<color=#734F22>#a1#</color>"
	if(num1>=item1.itemNum)then
		color="<color=#076b1c>#a1#</color>"
	else
		color="<color=#c81212>#a1#</color>"
		self._needItemId=item1.itemId
	end
	self:SetWndEasyImage(self.mConsume1Icon,gModelItem:GetItemIconByRefId(item1.itemId))
	self:SetWndText(self.mConsume1Text,string.replace(color,LUtil.NumberCoversion(num1).."/"..LUtil.NumberCoversion(item1.itemNum)))
	-- self:SetWndText(self.mConsume1Text,LUtil.NumberCoversion(num1).."/"..LUtil.NumberCoversion(item1.itemNum))
	if(num2>=item2.itemNum)then
		color="<color=#076b1c>#a1#</color>"
	else
		color="<color=#c81212>#a1#</color>"
		self._needItemId=item2.itemId
	end
	self:SetWndEasyImage(self.mConsume2Icon,gModelItem:GetItemIconByRefId(item2.itemId))
	self:SetWndText(self.mConsume2Text,string.replace(color,LUtil.NumberCoversion(num2).."/"..LUtil.NumberCoversion(item2.itemNum)))
	-- self:SetWndText(self.mConsume2Text,LUtil.NumberCoversion(num2).."/"..LUtil.NumberCoversion(item2.itemNum))
end

function UIGdJNPop:OnClickJobTab(job)--点击职业选择
	if(self._job~=job)then
		self._pos = nil
	end
	self._job = job
	--gModelGuild:OnGuildSkillInfoReq(job)
	local info = gModelGuild:GetGuildSkillInfoByType(self._job)
	if(not info)then
		gModelGuild:OnGuildSkillInfoReq(job)
		return
	end
	self:RefreshData()
end

function UIGdJNPop:ArrtListItem(list,item, itemdata, itempos)
	local iconTrans=CS.FindTrans(item,"Icon")
	local nameText=CS.FindTrans(item,"NameText")
	local valueText=CS.FindTrans(item,"NameText/ValueText")
	local icon=gModelHero:GetAttributeIconById(itemdata.refId)
	local name=gModelHero:GetAttributeNameById(itemdata.refId)
	local value= gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.refId,itemdata.numType,itemdata.value)
	self:SetWndEasyImage(iconTrans,icon)
	local color=""
	--if(gModelGuild:GetBoolGuildSkillAttrColor(itemdata.refId))then
	--	color="<color=#c5cced>%s</color>"
	--else
	--	color="<color=#29c5ff>%s</color>"
	--end
	self:SetWndText(nameText,name)
	self:SetWndText(valueText,"+"..value)
end

function UIGdJNPop:OnClickUp()--点击升级
	if(self._needItemId and self._needItemId~=0)then
		local wndName = self:GetWndName()
		gModelGeneral:OpenGetWayWnd({itemId=self._needItemId,srcWnd = wndName})
		return
	end
	gModelGuild:OnGuildSkillUpReq(self._currJob)
end
function UIGdJNPop:InitEvent()
	--self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:OnClickCloseWnd() end)
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickCloseWnd(true) end)
	self:SetWndClick(self.mBgImage, function(...) self:OnClickCloseWnd(true) end)
	self:SetWndClick(self.mUpBtn, function(...) self:OnClickUp() end)
	self:SetWndClick(self.mResetBtn, function(...) self:OnClickReset() end)
	self:SetWndClick(self.mAddHeroBtn, function(...) self:OnClickAddHero() end)
	self:SetWndClick(self.mHelpBtn, function(...) self:OnClickHelp() end)
end

function UIGdJNPop:SetArrtIconList(job)--设置属性图片
	local list=gModelGuild:GetGuildSkillShowRefByJobType(job)
	for i, v in ipairs(list) do
		local arrtIcon=self._arrtIconList[i]
		local icon=CS.FindTrans(arrtIcon,"Image")
		self:SetWndEasyImage(arrtIcon,v.iconBg)
		self:SetWndEasyImage(icon,v.icon,function ()
			CS.ShowObject(arrtIcon,true)
		 end)
	end
end

function UIGdJNPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildSkillInfoResp,function (pb)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildSkillUpResp,function (pb)
		local type=pb.type
		self._changeTypeList[type]=type
	end)
	self:WndNetMsgRecv(LProtoIds.GuildSkillResetResp,function (pb)
		local type=pb.type
		self._changeTypeList[type]=type
	end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:SetUpNeed()
	end)
end

function UIGdJNPop:SetTabTransList(job)--设置标签
	if(self._currJob)then
		local trans= self._tabTransList[self._currJob]
		if(trans)then
			local select=CS.FindTrans(trans,"SelectImage")
			local text=CS.FindTrans(trans,"XUIText")
			CS.ShowObject(select,false)
			self:SetXUITextTransColor(text,"b9c9eb")
		end
	end
	local trans= self._tabTransList[job]
	if(trans)then
		local select=CS.FindTrans(trans,"SelectImage")
		local text=CS.FindTrans(trans,"XUIText")
		CS.ShowObject(select,true)
		self:SetXUITextTransColor(text,"fdfddd")
	end
	self._currJob=job
	local imageStr=gModelGuild:GetGuildSkillJobRefIconByJobType(self._currJob)
	self:SetWndEasyImage(self.mSkillJobImage,imageStr,function ()
		CS.ShowObject(self.mSkillJobImage,true)
	end)--设置职业大图
	self:SetArrtIconList(self._currJob)
end
------------------------------------------------------------------
return UIGdJNPop


