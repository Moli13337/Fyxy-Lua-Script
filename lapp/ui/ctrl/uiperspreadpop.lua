---
--- Created by BY.
--- DateTime: 2023/10/7 10:13:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPerSpreadPop:LWnd
local UIPerSpreadPop = LxWndClass("UIPerSpreadPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPerSpreadPop:UIPerSpreadPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPerSpreadPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPerSpreadPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPerSpreadPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIPerSpreadPop:InitCommand()
	local _StructPersonaliseInfo = self:GetWndArg("StructPersonaliseInfo")

	local refId = _StructPersonaliseInfo.refId
	local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(refId)
	--self:SetWndEasyImage(self.mQualityImg,"role_quality_"..ref.quality)
	local imgT = nil
	if ref.type == ModelPlayerSpace.ROLE_TITLE then
		imgT = self.mTitleImg
	elseif ref.type == ModelPlayerSpace.ROLE_MEDAL then
		imgT = self.mBadgeImg
	end
	CS.ShowObject(imgT,true)
	self:SetWndEasyImage(imgT,ref.icon,nil,true)

	local rankStr = ""
	local type = ref.type
	if type == 5 then
		local isType5Rank = gModelPlayer:IsRoleCrossGradingRankType(refId)
		if isType5Rank then
			rankStr = gModelPlayer:GetRankSeasonStr(refId)
		end
	end
	self:SetWndText(self.mCGSeasonTxt,rankStr)

	local badgeTipsSize = ref.badgeTipsSize
	if badgeTipsSize == 0 then
		badgeTipsSize = 80
		printInfoNR(refId .. "配置 badgeTipsSize = 0，默认" .. badgeTipsSize)
	end
	badgeTipsSize = badgeTipsSize / 100
	printInfoNR("badgeTipsSize = " .. badgeTipsSize)
	imgT.localScale = Vector3(badgeTipsSize,badgeTipsSize,badgeTipsSize)

	local rName = ccLngText(ref.name)
	local quality = ref.quality
	local qRef = gModelItem:GetQualityRef(quality)
	local name = LUtil.FormatColorStr(rName,"#"..qRef.nameColor)
	self:SetWndEasyImage(self.mQualityImg,"role_quality_"..quality)

	self:SetWndText(self.mNameText,name)
	local isBadge = ref.type == ModelPlayerSpace.ROLE_MEDAL and _StructPersonaliseInfo.createTime
	CS.ShowObject(self.mTimeText,isBadge)
	if isBadge then
		local y,m,d = LUtil.GetYmdByTimestamp(tonumber(_StructPersonaliseInfo.createTime/1000))
		self:SetWndText(self.mTimeText,y.."."..m.."."..d)
	end
	local arrDes,wayDes,playerDes,desDes
	local desStr = ""
	if ref.attributes ~= "" then
		local arrtStr = ""
		local arrtlist = LUtil.GetRefAttrData(ref.attributes)
		for i, v in ipairs(arrtlist) do
			local name = gModelHero:GetAttributeNameById(v.refId)
			local value = gModelHero:GetAttributeValueNoNameByIdAndVal(v.refId,v.numType,v.value)
			arrtStr = arrtStr ..name..LUtil.FormatColorStr("+"..value,"lightGreen") .. "  "
		end
		--self:SetWndText(self.mArrtText,arrtStr)
		arrDes = arrtStr
	--else
	--	CS.ShowObject(self.mArrtObj,false)
	--	self.mBgImg.sizeDelta = Vector2.New(382,295)
	end

	wayDes = ccLngText(ref.description)
	--self:SetWndText(self.mWayText,ccLngText(ref.description))
	if _StructPersonaliseInfo.playerName then
		--self:SetWndText(self.mPlayerText,string.replace(ccClientText(21146),_StructPersonaliseInfo.playerName))
		playerDes = string.replace(ccClientText(21146),_StructPersonaliseInfo.playerName)
	end
	desDes = ccLngText(ref.description2)
	--self:SetWndText(self.mDesText,ccLngText(ref.description2))
	if arrDes then
		desStr = arrDes.."\n\n"..wayDes
	else
		desStr = wayDes
	end
	if playerDes then
		desStr = desStr.."\n\n\n"..playerDes
	end
	if desDes ~= "" then
		desStr = desStr.."\n\n"..desDes
	end

	self:SetWndText(self.mDesText,desStr)
	self:SetWndText(self.mTestText,desDes)
	local desText = self:FindWndText(self.mDesText)
	local height = desText.preferredHeight
	local cH = height - 176

	local initH = 144
	if desDes == "" then
		initH = initH + 53
	end
	--if cH > 1 then
		self.mBgImg.sizeDelta = Vector2.New(382,initH + height)
	--end
	local testText = self:FindWndText(self.mTestText)
	local height = testText.preferredHeight
	if height <= 0 then
		return
	end
	local cH = height - 40
	if cH > 1 then
		self.mBgImg2.sizeDelta = Vector2.New(0,-176 - cH)
	end
end

function UIPerSpreadPop:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)

end

------------------------------------------------------------------
return UIPerSpreadPop


