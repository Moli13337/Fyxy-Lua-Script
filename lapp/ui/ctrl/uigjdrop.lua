---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGjDrop:LWnd
local UIGjDrop = LxWndClass("UIGjDrop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGjDrop:UIGjDrop()
	---@type UIIconEasyList[]
	self._iconEasyListTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGjDrop:OnWndClose()
	if self._iconEasyListTbl then
		for k, v in pairs(self._iconEasyListTbl) do
			v:Destroy()
		end
		self._iconEasyListTbl = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGjDrop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGjDrop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:ShowContent()
end

function UIGjDrop:FormatChapterName(cfg)
    if not cfg then
        return ccClientText(10717)--"敬请期待"
    end
    local name = ccLngText(cfg.nameWorld)

    local chapterId = cfg.belongChapterId
	local chapterCfg = gModelInstance:GetInstanceChapterRefByRefId(chapterId)
	local prefix =ccLngText(chapterCfg.chapterNum)
    --local prefix =ccClientText(10726+chapterId)
    local str = string.format("%s %s",prefix,name)
    str = LUtil.FormatColorStr(str,"green")
    return str
end

function UIGjDrop:SetLittleItem(list,item,itemdata,itempos)
	local iconTran = self:FindWndTrans(item,"icon")
	local icon,ionBg = gModelItem:GetItemImgByRefId(itemdata.itemId)
	if icon then
		self:SetWndEasyImage(iconTran,icon)
	end
	local num = itemdata.itemNum..ccClientText(10714) --"/M"
	local text = self:FindWndTrans(item,"text")
	self:SetWndText(text,num)
end

function UIGjDrop:ShowContent()
    local dataList = gModelInstance:GetDiffDropPreData()
	for i=1,2 do
		if dataList[i] then
			local data = dataList[i]
			--local str = self._preFixList[i]..self:FormatChapterName(data)
			local itemList ={}
			if data then
				itemList = gModelInstance:GetShowReward(data.refId)
			end
			local uidata =
			{
				--title = str,
				itemList = itemList,
				dropPreData = data
			}
			self:SetItem(self._itemUIList[i],uidata, i)
			CS.ShowObject(self._itemUIList[i], true)
		else
			CS.ShowObject(self._itemUIList[i], false)
		end
	end
	if #dataList == 1 then
		LxUiHelper.SetSizeWithCurAnchor(self.mAniRoot, 1, 300)
		self.mTitle.transform.localPosition = Vector3.New(0, 117, 0)
		self.mBackBtn.transform.localPosition = Vector3.New(290.7, 117, 0)
		self.mIntro.transform.localPosition = Vector3.New(0, -124, 0)
	end
end



function UIGjDrop:InitData()
	self._itemUIList =
	{
		[1] = self.mItemTemplate_1,
		[2] = self.mItemTemplate_2,
	}
	self._preFixList =
	{
		[1] =ccClientText(10715),  --"挂机进度:",
		[2] =ccClientText(10716),-- "下一阶段:",
	}
end



function UIGjDrop:SetStaticContent()
    local str =ccClientText(10703) --"收益预告"
    self:SetWndText(self.mTitle,str)
    str =ccClientText(10718) --"当前每分钟固定收益(推图越远,收益越高)"
    self:SetWndText(self.mIntro,str)
    self:SetWndClick(self.mBackBtn,function () self:WndClose() end)
    self:SetWndClick(self.mMask,function () self:WndClose() end)

end

function UIGjDrop:SetItem(item,itemdata, itemPos)
    --local bg = self:FindWndTrans(item,"bg")
    local text = self:FindWndTrans(item,"text")
    local itemList = self:FindWndTrans(item,"itemList")
    local solidReward = self:FindWndTrans(item,"solidReward")
    local openDescTrans = self:FindWndTrans(item,"openDesc")
	local diffLvl = itemPos == 1 and 1 or 3
	local battleNode = gModelInstance:GetBattleNode(diffLvl)
	local diffIsOpen = diffLvl == 1 and true or gModelInstance:CheckDiffLvlFuncIsOpen(diffLvl)
	local titleStr
	if(battleNode and diffIsOpen)then
		local solidList =gModelInstance:GetMissionTimeRewardFix(battleNode)
		local list = self:GetUIScroll("initList"..itemPos)
		list:Create(solidReward,solidList,function (...) self:SetLittleItem(...) end)

		local dropPreData = itemdata.dropPreData
		local chapterName = self:FormatChapterName(dropPreData)
		-- local patternCfg = gModelInstance:GetInstancePattern(diffLvl)
		-- local diffName = ccLngText(patternCfg.name)..ccClientText(16326)
		local chapterNameColor = "#139057"
		-- titleStr = string.format("%s: <color=%s>%s</color>",diffName,chapterNameColor,chapterName)
		titleStr = string.format("<color=%s>%s</color>",chapterNameColor,chapterName)
	else
		local cfg = GameTable.FeatureOpenRef[10204000]
		local openDesc = ccLngText(cfg.openDesc)
		titleStr = ccClientText(10788)
		self:SetWndText(openDescTrans,openDesc)
	end
    self:SetWndText(text,titleStr)
	CS.ShowObject(openDescTrans,not battleNode or not diffIsOpen)
	CS.ShowObject(solidReward,battleNode and diffIsOpen)
	CS.ShowObject(itemList,battleNode and diffIsOpen)
	local instanceId = item:GetInstanceID()
	local uiEasyIconList = self._iconEasyListTbl[instanceId]
	if not uiEasyIconList then
		uiEasyIconList = UIIconEasyList:New()
		self._iconEasyListTbl[instanceId] = uiEasyIconList
		uiEasyIconList:Create(self, itemList)
		uiEasyIconList:EnableScroll(true, true)
		uiEasyIconList:SetShowNum(false)
	end
	uiEasyIconList:RefreshList(itemdata.itemList)
end
------------------------------------------------------------------
return UIGjDrop


