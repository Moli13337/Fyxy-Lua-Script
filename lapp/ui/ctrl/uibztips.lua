---
--- Created by BY.
--- DateTime: 2023/10/21 21:18:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBzTips:LWnd
local UIBzTips = LxWndClass("UIBzTips", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBzTips:UIBzTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBzTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBzTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBzTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:SetText()
	self:SetBgSize()
end

-- 根据文本内容设置底图大小
function UIBzTips:SetBgSize()
	local curContenTextRectTransform = self.mContentText:GetComponent(typeof(UnityEngine.RectTransform))
    local curContenText = self.mContentText:GetComponent("YXUIText")
    local curContenTextHight = curContenText.preferredHeight > self._maxCount and self._maxCount or curContenText.preferredHeight
	local hight = curContenTextHight + 150

	-- 文本区域
	local size = Vector2.New(curContenTextRectTransform.rect.width, curContenTextHight)
	curContenTextRectTransform.sizeDelta = size

	-- 底图区域
	local size = Vector2.New(self.mBg1RectTrans.rect.width, hight)
	self.mBg1RectTrans.sizeDelta = size
	self.mMainTextRectTrans.sizeDelta = size

	-- 标题高度调整
	local tHeight = 50
	self.mUp.localPosition = Vector3(0,hight - tHeight,0)

	-- 滑动区域
	local size = Vector2.New(self.mScrollRectTrans.rect.width, curContenTextHight)
	self.mScrollRectTrans.sizeDelta = size
end

-- 设置文本内容
function UIBzTips:SetText()

	local text = self._text
	local para = self._contentPara

	if para then
		--text = string.replace(text,unpack(para))
		text = LStringUtil.ReplaceStringCommon(text,nil,unpack(para))
	end

	if self._bTransWarp then
		text = string.gsub(text,"\\n","\n")
	end

	----text = "3. สามารถดูรายงานการต่อสู้ของตัวเองและวิดีโอการต่อสู้ของเหล่าทวยเทพ"
	--text = "3.<&nbsp;>สามารถดูรายงานการต่อสู้ของตัวเองและวิดีโอการต่อสู้ของเหล่าทวยเทพ"

	self:SetWndText(self.mTitleText,self._title)
	self:SetWndText(self.mContentText,text)
	self:SetWndText(self.mCloseInfo,ccClientText(10103))
end

function UIBzTips:InitEvent()
	self:SetWndClick(self.mBg,function()
		if self._refID then
			if not self._jumpTAClient then
				gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_TIP,"close",self._refID)
			end
		end

		self:WndClose()
	end)
end

-- 获取帮助表文本数据
function UIBzTips:InitData()

	-- 帮助弹窗最大高度
	self._maxCount = 780
	self._bTransWarp = self:GetWndArg("bTransWarp")
	self._refID = self:GetWndArg("refId")
	self._contentPara = self:GetWndArg("para")
	self._jumpTAClient = self:GetWndArg("jumpTAClient") or false
	local title = self:GetWndArg("title")
	local text = self:GetWndArg("text")
	if self._refID then
		self._helpTipsRef = GameTable.SupportTipsRef[self._refID]
		local _title = ""
		local _text = ""
		if self._helpTipsRef then
			_title = ccLngText(self._helpTipsRef.title)
			_text = ccLngText(self._helpTipsRef.text)
		end
		self._title = _title
		self._text = _text

		if not self._jumpTAClient then
			gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_TIP,"open",self._refID)
		end

	else
		title = gModelActivity and gModelActivity:GetLngNameById(title)
		self._title = title
		self._text = text

	end

end

------------------------------------------------------------------
return UIBzTips


