---
--- Created by Administrator.
--- DateTime: 2023/10/28 16:03:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBulin:LWnd
local UIBulin = LxWndClass("UIBulin", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local unityScreen = UnityEngine.Screen
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBulin:UIBulin()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBulin:OnWndClose()
	if self._isNeedDestroyWebView then
		gLSdkImpl:WebViewDestroy()
	end
	if self._closeWndCallBack then
		self._closeWndCallBack()
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBulin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBulin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetPara()
	self:InitStaticContent()
	self:InitEventAndClick()

	self:InitFirstShowUI()
end

function UIBulin:NoticeReq()
	local pb = LProtoHelper.CreateProto(LProtoIds.NoticeReq)
	SendMessage(pb,LProtoIds.NoticeReq)
end

function UIBulin:ParseHtmlToList(htmlStr)
	local s, e = string.find(htmlStr,"<body>.*</body>")
	if not s or not e then
		return {
			{showType = 1,text = htmlStr}
		}
	end

	local bodyStr = string.sub(htmlStr, s, e)
	local pattern = "(<p.->(.-)</p>)"
	local pTagList = {}
	for v1, v2 in string.gmatch(bodyStr, pattern) do
		local datas = self:ParseSpanTagListData(v2)
		if datas and #datas > 0 then
			for i,v in ipairs(datas) do
				table.insert(pTagList, v)
			end
		else
			table.insert(pTagList, {
				showType = 1,
				text = v2,
			})
		end
	end
	return pTagList
end

function UIBulin:ShowContent(index)
	local itemdata = self._list[index]
	if not itemdata then
		return
	end
	local url = itemdata.url

	printInfoN("notice url = "..(url or "nil"))

	if url == self._curUrl then
		return
	end

	self._curUrl = url

	if not string.find(url,"?") then
		url = string.format("%s?ost=%s",url,os.time())
	else
		url = string.format("%s&ost=%s",url,os.time())
	end

	if self._showViewType == 1 or self._showViewType == 3 then

		self:ShowUrlContent(url)

	elseif self._showViewType == 2 then
		if self._csBrowserUGUI and self._csBrowserUGUIReady then
			self:WinLoadUrl()
		end
	else
		gLSdkImpl:WebViewDestroy()
		local left,top,right,bottom = self._margin.left,self._margin.top,self._margin.right,self._margin.bottom
		gLSdkImpl:WebViewShow(url, left, top, right, bottom)
	end
end

function UIBulin:OnDrawTitle(list, item, itemdata, itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBtnTab = self:FindWndTrans(AniRoot,"BtnTab")
	local AniRootTag = self:FindWndTrans(AniRoot,"tag")

    if self._isEnus  then
        AniRootBtnTab = self:FindWndTrans(AniRoot,"BtnTab_Enus")
    end
	CS.ShowObject(AniRootBtnTab,true)

	self:SetWndTabText(AniRootBtnTab,itemdata.name)

	local show = false
	if LxUiHelper.IsImgPathValid(itemdata.tipsBg) then
		show = true
		self:SetWndEasyImage(AniRootTag,itemdata.tipsBg)
	end

	CS.ShowObject(AniRootTag,show)

	self:SetWndClick(AniRootBtnTab,function () self:OnClickTitle(itempos) end)

	local showSelect = self._curIndex == itempos
	local state =showSelect and  LWnd.StateOn or LWnd.StateOff

	self:SetWndTabStatus(AniRootBtnTab,state)
end

function UIBulin:InitStaticContent()
	-- 设置标题
	self:SetWndText(self.mTitle, ccClientText(13425))
end

function UIBulin:OnClickTitle(itempos)
	if itempos == self._curIndex then
		return
	end

	self._curIndex = itempos

	local uiList = self:GetUIScroll("uiList")
	uiList:DrawAllItems()

	self:ShowContent(itempos)

end

function UIBulin:CalculateMargin()

	local points={}
	for k=1,2 do
		local name = "point_"..k
		local point = self:FindWndTrans(self.mView,name)
		point = point:GetComponent(typeofRectTransform)
		table.insert(points,point)
	end

	local poses = {}
	local camera = gLGameUI:GetCSUICamera()
	for k= 1, 2 do
		local point = points[k]
		local screenPos =camera:WorldToScreenPoint(point.position)
		--print(string.format("margin%s x %s,y %s",k, screenPos.x,screenPos.y))
		table.insert(poses,screenPos)
	end

	local uWidth = unityScreen.width
	local uHeight = unityScreen.height

	local left = poses[1].x
	local bottom = poses[1].y
	local top = uHeight - poses[2].y
	local right = uWidth - poses[2].x

	if CS.IsOSAndroid() then
		local realRect = LNativeHelper.GetDeviceDisplayRect()
		if not string.isempty(realRect) then
			local arrResult = string.split(realRect,"|") or {}
			local rectW = tonumber(arrResult[1]) or 0
			local rectH = tonumber(arrResult[2]) or 0
			--print(string.format("unity screen rect=%s|%s , device now rect %s|%s", uWidth, uHeight, rectW,rectH))
			if rectW > 0 and rectH > 0 then
				if rectW ~= uWidth then
					local sx = rectW / uWidth
					left = left * sx
					right = right * sx
				end

				if rectH ~= uHeight then
					local sy = rectH / uHeight
					top = top * sy
					bottom = bottom * sy
				end
			end
		end
	end

	local data ={
		left = math.floor(left),
		top = math.floor(top),
		right = math.floor(right),
		bottom = math.floor(bottom),
	}

	--print(string.format("left %s,right %s,top %s,bottom %s",left,right,top,bottom))
	self._margin = data
end


function UIBulin:ShowUrlContentWithText(result)
	local contentStr = self:ParseHtmlToTMPText(result)
	self:SetXUITextText(self._showTextContent, contentStr)
	local height = self._showTextContent.preferredHeight
	local sizeDelta = self.mTextContent.sizeDelta
	sizeDelta.y = height + 20
	self.mTextContent.sizeDelta = sizeDelta
	self.mScrollView.normalizedPosition = Vector2(0, 1)
end

function UIBulin:InitFirstShowUI()
	if self._showViewType == 1 then
		CS.ShowObject(self.mBrowser, false)
		CS.ShowObject(self.mTextnode, true)

		---@type YXUIText
		self._showTextContent = self:FindWndText(self.mTextContent)

	elseif self._showViewType == 2 then
		CS.ShowObject(self.mTextnode, false)
		self:InitWinBrowser()
	else
		CS.ShowObject(self.mBrowser, false)
		CS.ShowObject(self.mTextnode, false)
	end

	if self._type == 1 then
		self:NoticeReq()
		local time = GetTimestamp()
		LPlayerPrefs.SetPlatformGameNotice(tostring(time))
	elseif self._type == 2 then
		self:InitBulletinList(self._list)
	end
end

function UIBulin:ParseHtmlToTMPText(htmlStr)
	local s, e = string.find(htmlStr,"<body>.*</body>")
	if not s or not e then
		return htmlStr
	end
	local bodyStr = string.sub(htmlStr, s, e)
	local pattern = "(<p.->(.-)</p>)"
	local pTagList = {}
	for v1, v2 in string.gmatch(bodyStr, pattern) do
		local str = self:ParseSpanTagHtml(v2)
		if string.isempty(str) then
			str = "<br>"
		end
		table.insert(pTagList, str)
	end

	local result = table.concat(pTagList, "<br><br>")
	result = string.gsub(result,"&#39;"	, "'")
	result = string.gsub(result,"&#apos;"	, "'")
	result = string.gsub(result,"&nbsp;"	, " ")
	result = string.gsub(result,"&lt;"	, "<")
	result = string.gsub(result,"&gt;"	, ">")
	result = string.gsub(result,"&amp;"	, "&")
	result = string.gsub(result,"&quot;"	, "\"")
	result = string.gsub(result,"&copy;"	, "@")
	--result = string.gsub(result,"&reg;"	, "®")
	--result = string.gsub(result,"&trade;"	, "™")
	--result = string.gsub(result,"&times;"	, "×")
	--result = string.gsub(result,"&divide;"	, "÷")

	return result
end


function UIBulin:ShowUrlContentWithList(result)
	self:InitWXList(result)
end

function UIBulin:SetPara()
	self._type = self:GetWndArg("type")
	self._closeWndCallBack = self:GetWndArg("closeWndCallBack")
	local list = self:GetWndArg("list")
	if list then
		local t={}
		for k,v in ipairs(list) do
			local data = {}
			data.name = v.name
			data.tabsBg = v.tabsBg
			data.tipsBg = v.tipsBg
			data.beginTime = v.beginTime
			data.endTime =v.endTime
			data.url = v.noticeUrl
			data.sort = v.orderNum
			table.insert(t,data)
		end

		table.sort(t,function (a,b)
			if a.sort~=b.sort then
				return a.sort<b.sort
			end
			return a.beginTime < b.beginTime
		end)

		self._list = t
	end

	self._showViewType = 0
	if CS.IsWebGL() then
		if LWxHelper.IsMiniGamePlatform() then
			self._showViewType = 3
		else
			self._showViewType = 1
		end
	elseif CS.IsOsWinOrEdit() then
		self._showViewType = 2
	else
		self._isNeedDestroyWebView = true
		self:CalculateMargin()
	end
end

function UIBulin:OnDrawWXCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local Img = self:FindWndTrans(item,"Img")
		itemCache = {
			UIText = self:FindWndTrans(item,"UIText"),
			Img = Img,
			ImgLE = Img:GetComponent(typeLayoutElement),
		}
		self:SetComponentCache(instanceID, itemCache)
	end
	local showType = itemdata.showType
	local isText = showType == 1
	if isText then
		self:SetWndText(itemCache.UIText,itemdata.text)
	end
	CS.ShowObject(itemCache.UIText,isText)

	local Img = itemCache.Img
	CS.ShowObject(Img,false)
	if showType == 2 then
		local uiPngTexture = Img:GetComponent("YXTextureImage")
		if uiPngTexture then
			self:SetWndImageColor(Img,Color.New(1, 1, 1, 0))
			CS.ShowObject(Img,true)
			uiPngTexture.isNativeSize = true
			uiPngTexture:SetImageFromFullPath(itemdata.imgUrl)
			uiPngTexture:SetLoadedCallback(function(imgUrl)
				CS.ShowObject(Img,false)
				LxTimer.DelayFrameCall(function()
					local itemSizeDelta = item.sizeDelta
					local imgSizeDelta = Img.sizeDelta
					local imgWidth = imgSizeDelta.x
					local imgHeight = imgSizeDelta.y
					local itemWidth = itemSizeDelta.x
					local newImgWidth,newImgHeight = imgWidth,imgHeight
					if imgWidth > itemWidth then
						local scaleWidth = itemWidth / imgWidth
						newImgWidth = imgWidth * scaleWidth
						newImgHeight = itemWidth / (imgWidth / imgHeight)
						Img.sizeDelta = Vector2(newImgWidth, newImgHeight)
					end
					---@type LayoutElement
					local ImgLE = itemCache.ImgLE
					ImgLE.preferredWidth = newImgWidth
					ImgLE.preferredHeight = newImgHeight
					self:SetWndImageColor(Img,Color.New(1, 1, 1, 1))
					CS.ShowObject(Img,true)
				end)
			end)
		end
	end
end

function UIBulin:InitProperties()
	LWnd.InitProperties(self)
	local order = self:GetWndArg("order")
	if order then
		self._propertyOrderInLayer = order
	end
end

function UIBulin:InitEventAndClick()
	self:WndEventRecv(EventNames.ON_WND_FINISH,function (...) self:OnTargetWndOpen(...) end)

	self:SetWndClick(self.mBtnClose,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	if self._type == 1 then
		self:WndNetMsgRecv(LProtoIds.NoticeResp,function (...) self:OnNoticeResp(...) end)
	end
end

---解析span段落标记
function UIBulin:ParseSpanTagHtml(inStr)
	local byteLen = #inStr
	local i = 1
	local endIdx = 0

	local tagList = {}

	local status = 0 -- 0 需要检测 < , 1 需要检测 >
	local start = 0
	local content

	local forwardSlashByte = 0x2F --"/"
	local openAngleBracketByte = 0x3C -- "<"
	local closeAngleBracketByte = 0x3E -- ">"

	while true do
		if i > byteLen then
			break
		end
		local c = inStr:byte(i)
		if c >= 0x00 and c <= 0x7F then
			endIdx = i + 1

			if status == 1 then
				if c == closeAngleBracketByte then
					status = 0
					content = string.sub(inStr, start, i)
					table.insert(tagList, {content =content, s=start, e = i, isclose = content:byte(2) == forwardSlashByte})
				end
			else
				if c == openAngleBracketByte then
					status = 1
					start = i
				end
			end

		elseif c >= 0xC2 and c <= 0xDF then
			endIdx = i + 2
		elseif c >= 0xE0 and c <= 0xEF then
			endIdx = i + 3
		elseif c >= 0xF0 and c <= 0xF4 then
			endIdx = i + 4
		else --invalid
			endIdx = i + 1
		end
		i = endIdx
	end

	local resultList = {}
	i = 1
	local len = #tagList
	local last = nil
	local openTag = {}
	local isignore = false
	while i <= len do
		local tag = tagList[i]
		content = tag.content
		isignore = false
		if not tag.isclose then
			local tagStatus = 0
			local isAddStatus = true
			if content == "<strong>" then
				table.insert(resultList, "<b>")
			elseif string.find(content, "<span") then
				local s, e, r, g, b = string.find(content, "rgb%((%d+),.-(%d+),.-(%d+)")

				if s and e and r and g and b then
					local color = string.format("%02x", r)..string.format("%02x", g)..string.format("%02x", b)
					table.insert(resultList, "<color=#"..color..">")
					tagStatus = tagStatus + 1
				end
				s,e = string.find(content, "underline")
				if s and e then
					table.insert(resultList, "<u>")
					tagStatus = tagStatus + 2
				end
			elseif content == "<br/>" or content == "<br>" then
				table.insert(resultList, "<br>")
				isignore = true
				isAddStatus = false
			elseif string.find(content, "<a") then
				if string.endswith(content, "/>") then
					isAddStatus = false
				else
					local s,e, linkurl = string.find(content,"<a.-href=\"(.-)\"")
					if not linkurl then
						linkurl = ""
					end
					table.insert(resultList, "<link=\""..linkurl.."\"><u>")
				end
			else
				if string.endswith(content, "/>") then
					isAddStatus = false
				end
				isignore = true
			end
			if isAddStatus then table.insert(openTag, tagStatus) end
		end

		if last and not isignore then
			local sIdx = last.e + 1
			local eIdx = tag.s - 1
			if sIdx <= eIdx then
				table.insert(resultList, string.sub(inStr, sIdx, eIdx))
			end
		end

		if tag.isclose then
			local tagStatus = table.remove(openTag)
			if content == "</strong>" then
				table.insert(resultList, "</b>")
			elseif content == "</span>" then
				if tagStatus >= 2 then
					table.insert(resultList, "</u>")
					tagStatus = tagStatus - 2
				end
				if tagStatus >= 1 then
					table.insert(resultList, "</color>")
				end
			elseif content == "</a>" then
				table.insert(resultList, "</u></link>")
			end
		end
		last = tag
		i = i + 1
	end
	if #resultList > 0 then
		return table.concat(resultList, "")
	else
		return ""
	end
end

function UIBulin:InitBulletinList(itemdataList)

	if #itemdataList>0 then
		self._curIndex = 1
	end

	local uiList = self:GetUIScroll("uiList")
	local listData =
	{
		root = self.mItemList,
		dataList = itemdataList,
		setFunc = function (...) self:OnDrawTitle(...) end,
		type = UIItemList.WRAP,
	}
	uiList:InitListData(listData)

	uiList:EnableScroll(true,true)

	if self._curIndex then
		self:ShowContent(self._curIndex)
	end
end

function UIBulin:WinLoadUrl()
	if not self._csBrowserUGUI then return end
	if self._csRawImage then
		self._csRawImage = Color.New(1,1,1,0)
	end
	if self._csBrowserUGUI then
		self._csBrowserUGUI:LoadUrl(self._curUrl)
	end
end


function UIBulin:OnTargetWndOpen(wndName)
	if wndName == "UIOrdinTip" then
		self:WndClose()
	end
end

function UIBulin:InitWinBrowser()
	if not self.mBrowser then return end

	local typeBrowser = CardEHT.BrowserUGUI
	if not typeBrowser then return end

	local typeofRawImage = typeof(UnityEngine.UI.RawImage)
	local rawImg = self.mBrowser:GetComponent(typeofRawImage)
	local obj = self.mBrowser.gameObject
	if not rawImg then
		rawImg = obj:AddComponent(typeofRawImage)
	end

	local typeofBrowser = typeof(typeBrowser)
	local csBrowserUGUI = self.mBrowser:GetComponent(typeofBrowser)
	if not csBrowserUGUI then
		local sizeDelta = self.mBrowser.sizeDelta
		csBrowserUGUI = obj:AddComponent(typeofBrowser)
		csBrowserUGUI.InputEnable = false
		csBrowserUGUI.BackgroundColor =  Color.New(0, 0, 0, 0)
		csBrowserUGUI.BrowserImage = rawImg
		csBrowserUGUI.Width = sizeDelta.x
		csBrowserUGUI.Height = sizeDelta.y
		csBrowserUGUI.EventCamera = gLGameUI:GetCSUICamera()
	end

	rawImg.color = Color.New(1,1,1,0)
	csBrowserUGUI.OnInitComplete = function()
		if not self:IsWndValid() then return end
		self._csBrowserUGUIReady = true
		self:WinLoadUrl()
	end

	csBrowserUGUI.OnBrowserPageLoaded  = function(loadedUrl)
		if not self:IsWndValid() then return end
		if(loadedUrl ~= self._curUrl) then
			return
		end
		rawImg.color = Color.New(1,1,1,1)
	end

	self._csRawImage = rawImg
	self._csBrowserUGUI = csBrowserUGUI
	CS.ShowObject(self.mBrowser, true)
end

function UIBulin:OnNoticeResp(pb)
	local t ={}
	for k,v in ipairs(pb.list) do
		table.insert(t,v)
	end

	table.sort(t,function (a,b)
		if a.sort~=b.sort then
			return a.sort<b.sort
		end
		return a.beginTime < b.beginTime
	end)
	self._list = t
	self:InitBulletinList(t)
end

function UIBulin:ParseSpanTagListData(inStr)
	local byteLen = #inStr
	local i = 1
	local endIdx = 0
	local tagList = {}
	local status = 0 -- 0 需要检测 < , 1 需要检测 >
	local start = 0
	local content
	local forwardSlashByte = 0x2F --"/"
	local openAngleBracketByte = 0x3C -- "<"
	local closeAngleBracketByte = 0x3E -- ">"
	while true do
		if i > byteLen then break end
		local c = inStr:byte(i)
		if c >= 0x00 and c <= 0x7F then
			endIdx = i + 1
			if status == 1 then
				if c == closeAngleBracketByte then
					status = 0
					content = string.sub(inStr, start, i)
					table.insert(tagList, {content = content, s = start, e = i, isclose = content:byte(2) == forwardSlashByte})
				end
			else
				if c == openAngleBracketByte then
					status = 1
					start = i
				end
			end
		elseif c >= 0xC2 and c <= 0xDF then
			endIdx = i + 2
		elseif c >= 0xE0 and c <= 0xEF then
			endIdx = i + 3
		elseif c >= 0xF0 and c <= 0xF4 then
			endIdx = i + 4
		else --invalid
			endIdx = i + 1
		end
		i = endIdx
	end

	local resultList = {}
	local strList = {}
	i = 1
	local len = #tagList
	local last = nil
	local openTag = {}
	local isignore = false
	local bImg = false
	while i <= len do
		local tag = tagList[i]
		content = tag.content
		isignore = false
		bImg = false
		if not tag.isclose then
			local tagStatus = 0
			local isAddStatus = true
			if string.find(content,"<img") then
				bImg = true
				local imgPath = string.match(content,"src%s*=%s*\"([^\"]+)\"")
				if imgPath then
					table.insert(resultList,{
						showType = 2,
						imgUrl = imgPath
					})
				end
				if string.endswith(content, "/>") then
					isAddStatus = false
				end
				isignore = true
			else
				if content == "<strong>" then
					table.insert(strList, "<b>")
				elseif string.find(content, "<span") then
					local s, e, r, g, b = string.find(content, "rgb%((%d+),.-(%d+),.-(%d+)")
					if s and e and r and g and b then
						local color = string.format("%02x", r)..string.format("%02x", g)..string.format("%02x", b)
						table.insert(strList, "<color=#"..color..">")
						tagStatus = tagStatus + 1
					end
					s,e = string.find(content, "underline")
					if s and e then
						table.insert(strList, "<u>")
						tagStatus = tagStatus + 2
					end
				elseif content == "<br/>" or content == "<br>" then
					table.insert(strList, "<br>")
					isignore = true
					isAddStatus = false
				elseif string.find(content, "<a") then
					if string.endswith(content, "/>") then
						isAddStatus = false
					else
						local s,e, linkurl = string.find(content,"<a.-href=\"(.-)\"")
						if not linkurl then
							linkurl = ""
						end
						table.insert(strList, "<link=\""..linkurl.."\"><u>")
					end
				else
					if string.endswith(content, "/>") then
						isAddStatus = false
					end
					isignore = true
				end
			end
			if isAddStatus then table.insert(openTag, tagStatus) end
		end

		if last and not isignore then
			local sIdx = last.e + 1
			local eIdx = tag.s - 1
			if sIdx <= eIdx then
				table.insert(strList, string.sub(inStr, sIdx, eIdx))
			end
		end

		if tag.isclose then
			local tagStatus = table.remove(openTag)
			if content == "</strong>" then
				table.insert(strList, "</b>")
			elseif content == "</span>" then
				if tagStatus >= 2 then
					table.insert(strList, "</u>")
					tagStatus = tagStatus - 2
				end
				if tagStatus >= 1 then
					table.insert(strList, "</color>")
				end
			elseif content == "</a>" then
				table.insert(strList, "</u></link>")
			elseif string.find(content,"/>") and bImg then
			end
		end
		last = tag
		i = i + 1
	end

	local newStrList = {}
	for idx,v in ipairs(strList) do
		v = string.gsub(v,"&#39;"	, "'")
		v = string.gsub(v,"&#apos;"	, "'")
		v = string.gsub(v,"&nbsp;"	, " ")
		v = string.gsub(v,"&lt;"	, "<")
		v = string.gsub(v,"&gt;"	, ">")
		v = string.gsub(v,"&amp;"	, "&")
		v = string.gsub(v,"&quot;"	, "\"")
		v = string.gsub(v,"&copy;"	, "@")
		table.insert(newStrList,v)
	end

	if #newStrList > 0 then
		table.insert(resultList,{
			showType = 1,
			text = table.concat(newStrList,"") .. "\n\n"
		})
	end

	local insCnt = 0
	local list = {}
	for idx,val in ipairs(resultList) do
		insCnt = insCnt + 1
		table.insert(list,val)
	end
	if #list < 1 then
		return { showType = 1,text = "<br>" }
	end
	return list
end

function UIBulin:InitWXList(result)
	local list = self:GetWXList(result)
	local hasData = #list > 0
	CS.ShowObject(self.mWXList,hasData)

	---@type UIItemList
	local uiWXList = self._uiWXList
	if uiWXList then
		uiWXList:RefreshList(list)
	else
		uiWXList = self:GetUIScroll("uiWXList")
		self._uiWXList = uiWXList
		uiWXList:Create(self.mWXList, list, function(...) self:OnDrawWXCell(...) end)
	end
	uiWXList:EnableScroll(true)
end



function UIBulin:GetWXList(result)
	if string.isempty(result) then return {} end

	return self:ParseHtmlToList(result)
end

function UIBulin:ShowUrlContent(reqUrl)
	self._reqUrl = reqUrl
	LxHttpHelper.DoWebRequestURL(false, {reqUrl}, "", function (ret, result, url)
		if not self:IsWndValid() then return end
		if self._reqUrl ~= url then return end
		if (ret ~= CS.YXWebRet.ok) then
			return
		else
			if self._showViewType == 1 then
				self:ShowUrlContentWithText(result)
			elseif self._showViewType == 3 then
				self:ShowUrlContentWithList(result)
			end
		end
	end)
end

------------------------------------------------------------------
return UIBulin


