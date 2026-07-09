---
--- Created by LCM.
--- DateTime: 2022/11/1 16:25:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGolemHeroAttrShow:LWnd
local UIGolemHeroAttrShow = LxWndClass("UIGolemHeroAttrShow", LWnd)

UIGolemHeroAttrShow.TYPE_SHOW_GOLEM = 1		--- 魔偶属性显示
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGolemHeroAttrShow:UIGolemHeroAttrShow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGolemHeroAttrShow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGolemHeroAttrShow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGolemHeroAttrShow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitText()
	self:RefreshView()
end

function UIGolemHeroAttrShow:OnDrawShowAttrCell(list,item,itemdata,itempos)
    local AttrIconTrans = self:FindWndTrans(item,"AttrIcon")
    local AttrNameTrans = self:FindWndTrans(item,"AttrName")
    local AttrValueTrans = self:FindWndTrans(item,"AttrValue")
	local attrRefId = itemdata.attrRefId
	local attrIcon = gModelHero:GetAttributeIconById(attrRefId)
	self:SetWndEasyImage(AttrIconTrans,attrIcon)
	local attrName = gModelHero:GetAttributeNameById(attrRefId)
	self:SetWndText(AttrNameTrans,attrName)

	local value = itemdata.attrNum

	local ref = gModelHero:GetAttributeRefById(attrRefId)
	local numType,saveNum
	if ref then
		numType,saveNum = ref.numType,ref.saveNum
	else
		numType,saveNum = 1,0
	end
	if saveNum == 0 then
		value = math.floor(value + 0.5)
	else
		local tempPow = 10 ^ saveNum
		local temp = math.floor(value * tempPow + 0.5)
		value = temp / tempPow
	end
	if numType == 2 then
		value = value * 100 .. "%"
	end
	self:SetWndText(AttrValueTrans,value)
end

function UIGolemHeroAttrShow:InitText()
	local viewType = self._viewType
	if not viewType then return end
	if viewType == UIGolemHeroAttrShow.TYPE_SHOW_GOLEM then
		self:SetTextTile(self.mShowAttrTitle,ccClientText(33229))
		self:SetWndText(self.mAttrDesc,ccClientText(33260))
	end
end
------------------------- List -------------------------


function UIGolemHeroAttrShow:GetShowAttrList()
	local attrList = self._attrList
	local showAttrMap = self._showAttrMap
	local list = {}
	if attrList then
		for k,v in pairs(attrList) do
			if showAttrMap then
				if showAttrMap[k] then
					table.insert(list,{
						attrRefId = k,
						attrType = gModelHero:GetAttrShowType(k),
						attrNum = v,
					})
				end
			else
				table.insert(list,{
					attrRefId = k,
					attrType = gModelHero:GetAttrShowType(k),
					attrNum = v,
				})
			end
		end
	end
	table.sort(list,function(a,b)
		local attrRefIdA,attrRefIdB = a.attrRefId,b.attrRefId
		local attrTypeA,attrTypeB = a.attrType,b.attrType
		local sortA
		if attrTypeA == 1 then
			sortA = gModelHero:GetAttributeSortById(attrRefIdA)
		elseif attrTypeA == 2 then
			sortA = gModelHero:GetAttributeSort2ById(attrRefIdA)
		end
		local sortB
		if attrTypeB == 1 then
			sortB = gModelHero:GetAttributeSortById(attrRefIdB)
		elseif attrTypeB == 2 then
			sortB = gModelHero:GetAttributeSort2ById(attrRefIdB)
		end
		return  sortA < sortB
	end)
	return list
end

function UIGolemHeroAttrShow:RefreshView()
	self:InitShowAttrList()
end

function UIGolemHeroAttrShow:InitMsg()
	self:WndNetMsgRecv(LProtoIds.HeroAttributeResp,function(pb,ret)
		if pb.id ~= self._heroId then return end
		self._attrList = gModelHero:GetHeroAttrAndEquipInfoById(self._heroId)
		self:InitShowAttrList()
	end)

	-- self:WndNetMsgRecv("xxx",function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIGolemHeroAttrShow:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIGolemHeroAttrShow:InitShowAttrList()
    local list = self:GetShowAttrList()
    local uiShowAttrList = self._uiShowAttrList
    if uiShowAttrList then
        uiShowAttrList:RefreshList(list)
    else
        uiShowAttrList = self:GetUIScroll("uiShowAttrList")
        self._uiShowAttrList = uiShowAttrList
        uiShowAttrList:Create(self.mShowAttrList,list,function(...) self:OnDrawShowAttrCell(...) end)
    end
end

function UIGolemHeroAttrShow:InitData()
	local viewType = self:GetWndArg("viewType")
	if not viewType then
		viewType = UIGolemHeroAttrShow.TYPE_SHOW_GOLEM
	end
	self._viewType = viewType

	self._heroId = self:GetWndArg("heroId")
	self._attrList = self:GetWndArg("attrList") or {}
	self._showAttrMap = self:GetWndArg("showAttrMap")

	local attrNum = 0
	for k,v in pairs(self._attrList) do
		attrNum = 1
		break
	end
	if attrNum == 0 and self._heroId then

		gModelHero:OnHeroAttributeReq(self._heroId)
	end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIGolemHeroAttrShow



