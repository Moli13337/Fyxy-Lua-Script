---
--- 数数科技-客户端打点记录
--- https://www.thinkingdata.cn/
--
--  在LGameMemory之后初始化
-- http://[ServiceHttp]/api/{1}		service对外web服务api接口  {1} 占位参数
-----------------------------------------------------------------
local USystemInfo = CS.SystemInfo
-----------------------------------------------------------------
local LxBehaviour = require("LApp.component.LxBehaviour")
---@class LxTKData:LxBehaviour
local LxTKData = LxClass("LxTKData", LxBehaviour)
------------------------------------------------------------------
local CS = CS
local Time = Time


LxTKData.CLIENT_HERO_BOOK = "client_hero_book"
LxTKData.CLIENT_HERO_DETAIL = "client_hero_detail"
--LxTKData.CLIENT_HERO_SKIN = "client_hero_skin"
LxTKData.CLIENT_FIRST_RECHARGE = "client_first_recharge"	--首充
LxTKData.CLIENT_TIP = "client_tip"
LxTKData.CLIENT_ITEM_GOTO = "client_item_goto"
LxTKData.CLIENT_REPLAY = "client_replay"
LxTKData.CLIENT_RED_POINT = "client_red_point"
LxTKData.RECHARGE_CLIENT_ORDER = "recharge_client_order"
LxTKData.CLIENT_POPUP_GIFT = "client_popup_gift"
--LxTKData.CLIENT_SETTING = "client_setting"
LxTKData.CLIENT_CG = "client_cg"
LxTKData.CLIENT_STORY = "client_story"
LxTKData.CLIENT_INVASION = "client_alieninvasion"
LxTKData.CLIENT_CHAT = "client_chat"
LxTKData.CLIENT_SKIP = "client_skip"
--LxTKData.CLIENT_GUIDE = "client_guide"
LxTKData.ACTIVITY_BUTTON_CLICK = "activity_button_click"
LxTKData.CLIENT_INVITE = "client_invite"
LxTKData.CLIENT_PLAY = "client_play"
LxTKData.CLIENT_RATE_SCORE = "client_rate_score"
LxTKData.CLIENT_TEMP49 = "client_temp49"
LxTKData.CLIENT_TEMP51 = "client_temp51"

LxTKData.SOCIAL_SHARE_PHOTO = "social_share_photo"
LxTKData.SOCIAL_SPACE_SHARE = "social_space_share"

LxTKData.SYS_GUIDE = "sys_guide"

LxTKData.PROJECTOR_VIDEO = "projector_video"

LxTKData.CLIENT_LANGUAGE_SWITCH = "client_language_switch"
LxTKData.AD_START = "ad_start"
LxTKData.AD_END = "ad_end"


LxTKData.ADSHOP_EFF = "adShop_eff"

--- 微小实名认证打点
LxTKData.WXSMALL_REALNAME_SHOW = "wxsmall_realname_show"

LxTKData._ForbidEvents = {
	[LxTKData.CLIENT_ITEM_GOTO] = true,
	[LxTKData.CLIENT_INVITE] = true,
	[LxTKData.CLIENT_POPUP_GIFT] = true
}


------------------------------------------------------------------
function LxTKData:Initialize()
	LxBehaviour.Initialize(self)
	self.serviceUrl = ""
	local url = (LGameSettings.tga_url or "")
	if not string.isempty(url) then
		self.serviceUrl = url .."/"
	end
	if LOG_INFO_ENABLED then
		LogWarn("first tga url = "..tostring(self.serviceUrl))
	end

	self.updateBeginTime = 0
	self.loginBeginTime = 0
	self.extractResBeginTime = 0
	self.serverListBeginTime = 0
	self.enableStat = false
	self.enableLog = false
	self.guide2NoviceRef = {}
	self.story2NoviceRef = {}
	self.fixed2NoviceRef = {}

	self:InitEvents()
end

function LxTKData:InitEvents()
	self:AddEventHandler(EventNames.APPLICATION_DEVICE_START, self.OnDeviceStart, self)
end

function LxTKData:OnDeviceStart()
	LogWarn("LxTKData:OnUpdateSceneEnter LPlayerPrefs.uuidFirstBoot = "..tostring(LPlayerPrefs.uuidFirstBoot))
	self:InitBaseData()
	--uuid重新赋值当新设备激活
	if LPlayerPrefs.IS_NEW_UUID_SET then
		gLxTKData:StepDeviceActivate()
	end

	gLxTKData:StepDeviceStart()
end

function LxTKData:Dispose()

	LxBehaviour.Dispose(self)
end

function LxTKData:UpdateSensorProperties()
	local sensorProperties = gLSdkImpl and gLSdkImpl:CallMethod(LSdkMethod.GetSensorProperties) or nil
	if not string.isempty(sensorProperties) then
		sensorProperties = JSON.decode(sensorProperties)
		self.sensorProperties = sensorProperties
	else
		self.sensorProperties = nil
	end
end

function LxTKData:InitBaseData()
	if not string.isempty(self.dev_uuid) then return end

	local deviceProperties = gLSdkImpl and gLSdkImpl:CallMethod(LSdkMethod.GetDeviceProperties) or nil
	local sysVersion
	local networkInfo
	local imei
	local phoneModel
	local channel_id
	local platform_id
	if not string.isempty(deviceProperties) then
		local devicePropertiesTbl = JSON.decode(deviceProperties)
		if devicePropertiesTbl then
			--sysVersion = devicePropertiesTbl.phoneSysVersion or ""
			networkInfo = devicePropertiesTbl.networkInfo or ""
			imei = devicePropertiesTbl.imei or ""
			phoneModel = devicePropertiesTbl.phoneModel or ""
			channel_id = devicePropertiesTbl.platformIdSecond or ""
			platform_id = devicePropertiesTbl.platformId or ""
		end
	end

	self:UpdateSensorProperties()

	self.dev_uuid = string.urlencode(LPlayerPrefs.uuidFirstBoot or "")
	self.dev_imei = string.urlencode(imei or LNativeHelper.GetImei() or "")
	self.dev_mac = string.urlencode(LNativeHelper.GetMacAddress() or "")
	self.dev_type = tostring(LPlatformUtil.GetDeviceName())
	self.dev_cp = string.urlencode(gLGameMemory:GetDeviceCp())
	self.dev_model = string.urlencode(phoneModel or USystemInfo.deviceModel)
	self.dev_ver = string.urlencode(sysVersion or USystemInfo.operatingSystem)
	local devicWidth,devicHeight = LPlatformUtil.GetDeviceWH()
	self.dev_px = string.urlencode(devicWidth..","..devicHeight)
	self.dev_cpu = string.urlencode(gLGameMemory:GetCpuInfo())
	self.dev_ram = gLGameMemory:GetMemorySize()
	self.net_type = networkInfo or LPlatformUtil.GetNetworkName()
	self.net_ip = string.urlencode(CS.GetIPAddress())
	-- 改成安装包的资源版本号 
	self.app_ver = string.urlencode(gLxServerList.builtinAppVersion)

	self:InitLocalResVer()

	self.platform_id = platform_id or "0"
	self.channel_id = channel_id or "0"

	self.app_res_ver = ''
	self.web_res_ver = "0.0.0"
	self.channel_mapping_id = '0'
	self.platform_key = ''
	self.platform_name = ''
	self.package_mapping_id = '0'
	self.channel_key = ''
	self.channel_name = ''
	self.app_id = string.urlencode(LNativeHelper.GetPackageName())

	self.dev_region = ""

	self.sdk_udid = ""
	self.sdk_adid = ""

end

function LxTKData:OnUpdateInit()
	self:InitBaseData()
	self.app_res_ver = string.urlencode(gLxServerList.activePackageVersion)
	self.web_res_ver = string.urlencode(gLxServerList.webResVer)
	self:InitLocalResVer()

end

function LxTKData:InitLocalResVer()
	local resVer = gLxServerList.activePackageVersion
	self.local_res_ver = string.urlencode(resVer)
end

function LxTKData:OnServerList(resultTbl)
	if not resultTbl then return end

	self:InitBaseData()
	self.updateBeginTime = os.clock()
	
	local servicesUrl = resultTbl.servicesUrl or ''
	local channelInfo = resultTbl.channelInfo or {}

	if not string.isempty(servicesUrl) then
		servicesUrl = string.gsub(servicesUrl, "[/]+$", "")
	end
	self.serviceUrl = servicesUrl..'/stat/'
		
	self.channel_mapping_id = resultTbl.platformId or '0'
	self.platform_key = string.urlencode(resultTbl.platformKey or '')
	self.platform_name = string.urlencode(resultTbl.platformName or '')
	self.package_mapping_id = 0
	self.channel_key = ''
	self.channel_name = ''
	if channelInfo then
		self.package_mapping_id = channelInfo.channelId or 0
		self.channel_key = string.urlencode(channelInfo.channelKey) or ''
		self.channel_name = string.urlencode(channelInfo.channelName) or ''
	end
end
------------------------------------------------------------------
-- 尝试HTTP
function LxTKData:HttpPost(url1, urlSuffix, nextCall)
	if string.isempty(url1) or not string.startswith(url1, "http") then
		if LOG_INFO_ENABLED then
			printErrorN2("TKData", "invalid url = " ..tostring(url1))
		end
		return
	end
	local rePostCount = 1
	local OnHttpPost = nil
	OnHttpPost = function(ret,result,url)
		if ret ~= CS.YXWebRet.ok then
			
		end 
		if not self._isDestroy and nextCall then
			nextCall()
		end 	
	end

	urlSuffix = LUtil.MakeB64SendData(urlSuffix)
	
	LxHttpHelper.DoWebRequestURL(true, {url1}, urlSuffix, OnHttpPost)
end

-- 尝试HTTP json
function LxTKData:HttpJsonBody(url1,  bodyJson, nextCall)
	if string.isempty(url1) or not string.startswith(url1, "http") then
		if LOG_INFO_ENABLED then
			printErrorN2("TKData", "invalid url = " ..tostring(url1))
		end
		return
	end

	local httpHeaderData = self._httpHeaderData
	if not httpHeaderData then
		httpHeaderData = CS.HttpHeaderData.New()
		httpHeaderData:AddHeader("Content_Type","application/json")
		self._httpHeaderData = httpHeaderData
	end



	CS.HttpSignPost(url1,bodyJson,httpHeaderData,function (url,webRet,result)
		if webRet ~= CS.YXWebRet.ok then
			if LOG_INFO_ENABLED then
				printErrorN("[TA]error!"..tostring(url)..", result="..tostring(result)..", body="..tostring(bodyJson))
			end
		end
		if not self._isDestroy and nextCall then
			nextCall()
		end
	end)

	if LOG_INFO_ENABLED then
		local msg = tostring(bodyJson)
		local msgLen = #msg
		local len = 0
		printInfoN("[TA] body start")
		while(len < msgLen) do
			if msgLen - len <= 800 then
				print(string.sub(msg, len + 1))
				break
			end
			local s, e = string.find(msg, ",", len + 800)
			if s and e then
				print(string.sub(msg, len + 1, s))
				len = len + e
			else
				len = len + 800
			end
		end
		printInfoN("[TA] body end")

	end
end

function LxTKData:SendTAJson(url1, dataList, nextCall)
	local sensorProperties = self.sensorProperties
	if not sensorProperties then
		if LOG_INFO_ENABLED then
			printInfoN("sensorProperties is null, url="..tostring(url1))
		end
		return
	end
	local other = {}
	for k,v in ipairs(dataList) do
		local s, e = string.find(v, "=")
		if s and e then
			local key = string.sub(v, 1, s - 1)
			local value = string.sub(v, e + 1)
			other[key] = value
		end
	end
	sensorProperties.other = other
	local content = JSON.encode(sensorProperties)
	sensorProperties.other = nil
	if string.isempty(content) then
		if LOG_INFO_ENABLED then
			printInfoN("content is null, url="..tostring(url1))
		end
		return
	end
	self:HttpJsonBody(url1, content, nextCall)
end
------------------------------------------------------------------
-- 添加设备
function LxTKData:AddNewDevice()
	--if not CS.IsDataMode() then return end
	if self:IsNotSendTK() then return end
	self:InitBaseData()
	local url1 = self.serviceUrl..'deviceSet4Tga.do'
	local urlSuffix = "?dev_uuid="..self.dev_uuid.."&first_user_type=4"
	self:HttpPost(url1, urlSuffix, function()
		self:StepDeviceActivate()
	end)
end
------------------------------------------------------------------
-- 设备激活
function LxTKData:StepDeviceActivate()
	--if not CS.IsDataMode() then return end
	if self:IsNotSendTK() then return end
	self:InitBaseData()

	local tokenList = {
		"dev_uuid="..self.dev_uuid,
		"dev_imei="..self.dev_imei,
		--"dev_mac="..self.dev_mac,
		"dev_type="..self.dev_type,
		"dev_cp="..self.dev_cp,
		"dev_model="..self.dev_model,
		"dev_ver="..self.dev_ver,
		"dev_px="..self.dev_px,
		"dev_cpu="..self.dev_cpu,
		"dev_ram="..self.dev_ram,
		"net_type="..self.net_type,
		"net_ip="..self.net_ip,
		"channel_mapping_id="..self.channel_mapping_id,
		"package_mapping_id="..self.package_mapping_id,
		"app_ver="..self.app_ver,
		"app_res_ver="..self.local_res_ver,
		"dev_region="..self.dev_region,
		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'activate.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devActivate4Tga', tokenList)
end
------------------------------------------------------------------
-- 设备启动
function LxTKData:StepDeviceStart()
	--if not CS.IsDataMode() then return end
	if self:IsNotSendTK() then return end
	self:InitBaseData()

	local tokenList = {
		"dev_uuid="..self.dev_uuid,
		"dev_imei="..self.dev_imei,
		--"dev_mac="..self.dev_mac,
		"dev_type="..self.dev_type,
		"dev_cp="..self.dev_cp,
		"dev_model="..self.dev_model,
		"dev_ver="..self.dev_ver,
		"dev_px="..self.dev_px,
		"dev_cpu="..self.dev_cpu,
		"dev_ram="..self.dev_ram,
		"net_type="..self.net_type,
		"net_ip="..self.net_ip,
		"channel_mapping_id="..self.channel_mapping_id,
		"package_mapping_id="..self.package_mapping_id,
		"app_ver="..self.app_ver,
		"app_res_ver="..self.local_res_ver,
		"dev_region="..self.dev_region,
		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'start.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devStart4Tga', tokenList)
end
------------------------------------------------------------------
---sdk 登录setOnce
function LxTKData:StepSdkLoginOnce()
	if self:IsNotSendTK() then return end

	if checknumber(LPlayerPrefs.IsTKDataSdkOnce) > 0 then return end

	if self._isStepSdkLoginOnce then return end

	self._isStepSdkLoginOnce = true

	self:InitBaseData()

	local sdkaccount = ""
	local sex = -1
	local age = 0
	if gLSdkImpl then
		sdkaccount = gLSdkImpl:CallMethod(LSdkMethod.GetSdkAccount) or ""
		sex = gLSdkImpl:CallMethod(LSdkMethod.GetSdkSex) or -1
		age = gLSdkImpl:CallMethod(LSdkMethod.GetSdkUserAge) or 0
	end
	local tokenList = {
		"type=".."1",														--String  	//设置为1
		"dev_uuid="..self.dev_uuid,											--String	//设备UUID
		"create_sdk_account_id="..sdkaccount,								--String    \\SDK账号ID，创角时渠道方给用户生成的唯一标识，如3818851
		"create_channel_mapping_id="..self.channel_mapping_id,				--String    \\子渠道后台映射ID，后台配置的平台key的映射，即平台id；但实际上代表的是子渠道的映射ID
		"create_package_mapping_id="..self.package_mapping_id,				--String    \\子包后台映射ID，创角时后台配置的渠道key的映射，即渠道id；但实际上代表的是子包的映射ID

		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"create_platform_id="..self.platform_id,
		"create_channel_id="..self.channel_id,

		"dev_region="..self.dev_region,

		"u_role_real_age="..tostring(age),
		"u_role_real_gender="..tostring(sex),
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	--local url1 = self.serviceUrl..'sdksettga.do'
	--self:HttpPost(url1, urlSuffix)
	--self:SendTAJson(self.serviceUrl..'sdksettga', tokenList)
end

---sdk 登录 set
function LxTKData:StepSdkLogin()
	if self:IsNotSendTK() then return end

	self:InitBaseData()

	local sdkaccount = ""
	local sex = -1
	local age = 0
	if gLSdkImpl then
		sdkaccount = gLSdkImpl:CallMethod(LSdkMethod.GetSdkAccount) or ""
		sex = gLSdkImpl:CallMethod(LSdkMethod.GetSdkSex) or -1
		age = gLSdkImpl:CallMethod(LSdkMethod.GetSdkUserAge) or 0
	end
	local tokenList = {
		"type=".."2",												--String  	//设置为1
		"dev_uuid="..self.dev_uuid,									--String	//设备UUID
		"sdk_account_id="..sdkaccount,								--String    \\SDK账号ID，创角时渠道方给用户生成的唯一标识，如3818851
		"channel_mapping_id="..self.channel_mapping_id,				--String    \\子渠道后台映射ID，后台配置的平台key的映射，即平台id；但实际上代表的是子渠道的映射ID
		"package_mapping_id="..self.package_mapping_id,				--String    \\子包后台映射ID，创角时后台配置的渠道key的映射，即渠道id；但实际上代表的是子包的映射ID

		"dev_region="..self.dev_region,
		"u_role_real_age="..tostring(age),
		"u_role_real_gender="..tostring(sex),

		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"create_platform_id="..self.platform_id,
		"create_channel_id="..self.channel_id,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	--local url1 = self.serviceUrl..'sdksettga.do'
	--self:HttpPost(url1, urlSuffix)
	--self:SendTAJson(self.serviceUrl..'sdksettga', tokenList)
end

---sdk 登录事件
function LxTKData:StepSdkLoginEvent()
	if self:IsNotSendTK() then return end

	self:InitBaseData()
	local sdkaccount = ""
	local sdkguid = ""
	local sex = -1
	local age = 0
	if gLSdkImpl then
		sdkaccount = gLSdkImpl:CallMethod(LSdkMethod.GetSdkAccount) or ""
		sdkguid = gLSdkImpl:CallMethod(LSdkMethod.GetSdkGuid) or ""
		sex = gLSdkImpl:CallMethod(LSdkMethod.GetSdkSex) or -1
		age = gLSdkImpl:CallMethod(LSdkMethod.GetSdkUserAge) or 0
	end
	local tokenList = {
		"dev_uuid="..self.dev_uuid,
		"dev_imei="..self.dev_imei,
		"dev_mac="..self.dev_mac,
		"dev_type="..self.dev_type,
		"dev_cp="..self.dev_cp,
		"dev_model="..self.dev_model,
		"dev_ver="..self.dev_ver,
		"dev_px="..self.dev_px,
		"dev_cpu="..self.dev_cpu,
		"dev_ram="..self.dev_ram,
		"net_type="..self.net_type,
		"net_ip="..self.net_ip,

		"sdk_account_id="..sdkaccount,								--String    \\SDK账号ID，创角时渠道方给用户生成的唯一标识，如3818851
		"sdk_guid="..sdkguid,										--String    \\SDK [账号-游戏] ID，创角时渠道方给用户在游戏内生成的唯一标识，如42xiiq (这个ID跨区服是不变的，相当于[SDK账号-游戏]的组合标识)
		"package_mapping_id="..self.platform_key,					--String    \\子渠道标识，创角时的子渠道：发行商固定为baiioo，子渠道为baioo接入的渠道，如baioo-101
		"package_id="..self.channel_key,							--String    \\子包标识，创角时的子包标识，子包为子渠道上架的包体，如baioo-101-9527
		"channel_mapping_id="..self.channel_mapping_id,				--String    \\子渠道后台映射ID，后台配置的平台key的映射，即平台id；但实际上代表的是子渠道的映射ID
		"package_mapping_id="..self.package_mapping_id,				--String    \\子包后台映射ID，创角时后台配置的渠道key的映射，即渠道id；但实际上代表的是子包的映射ID
		"app_version="..self.app_ver,
		"res_version="..self.local_res_ver,

		"u_role_real_age="..tostring(age),
		"u_role_real_gender="..tostring(sex),
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	--local url1 = self.serviceUrl..'sdkLogin4Tga.do'
	--self:HttpPost(url1, urlSuffix)

end


-----------------------------------------------------------------
function LxTKData:SetConnectedServerTimer()
	self.connected_server_time = os.clock()
end

---设备启动，与(桥)服务端建立通信时setOnce------
function LxTKData:StepConnectedServerOnce()
	--移动到登录服务器前， 不能加这个判断
	--if not self.enableLog then return end

	if LGameSettings.platformSpecial == 1 then return end

	if self._isStepConnectedServerOnce then return end

	self._isStepConnectedServerOnce = true

	self:InitBaseData()

	local usertype = string.urlencode("设备")
	local connectedtime = self.connected_server_time or ""

	local tokenList = {
		"type=".."1",									--String  	//设置为1
		"user_type="..usertype,							--String	\\行为主体 (本页签都是设备行为主体)
		"create_dev_uuid="..self.dev_uuid,				--String   	\\设备uuid
		"create_dev_imei="..self.dev_imei,				--String    \\设备唯一标识，设备的imei/idfa，获取不到时不赋值
		"create_dev_type="..self.dev_type,				--String    \\设备类型
		"create_dev_model="..self.dev_model,			--String    \\设备型号，如iphone X 、iphone 8等
		"create_dev_version="..self.dev_ver,			--String    \\设备系统版本号
		"create_net_type="..self.net_type,				--String    \\网络类型
		"create_app_version="..self.app_ver,			--String    \\客户端app版本信息
		"create_res_version="..self.local_res_ver,		--String    \\客户端app版本信息
		"create_ip="..self.net_ip,						--String    \\首次通信IP
		"create_time="..connectedtime,					--String    \\首次通信时间

		"dev_region="..self.dev_region,
		"create_zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'devSet.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devsettga', tokenList)
end

---设备启动，与(桥)服务端建立通信时set
function LxTKData:StepConnectedServer()
	--移动到登录服务器前， 不能加这个判断
	--if not self.enableLog then return end

	self:InitBaseData()

	local usertype = string.urlencode("设备")
	local connectedtime = self.connected_server_time or ""
	local tokenList = {
		"type=".."0",										--String  	//设置为1
		"user_type="..usertype,								--String	\\行为主体 (本页签都是设备行为主体)
		"dev_uuid="..self.dev_uuid,							--String   	\\设备uuid
		"dev_imei="..self.dev_imei,							--String    \\设备唯一标识，设备的imei/idfa，获取不到时不赋值
		"dev_type="..self.dev_type,							--String    \\设备类型
		"dev_model="..self.dev_model,						--String    \\设备型号，如iphone X 、iphone 8等
		"dev_version="..self.dev_ver,						--String    \\设备系统版本号
		"net_type="..self.net_type,							--String    \\网络类型
		"app_version="..self.app_ver,						--String    \\客户端app版本信息
		"res_version="..self.local_res_ver,					--String    \\客户端app版本信息
		"lastest_ip="..self.net_ip,							--String    \\首次通信IP
		"laste_login_time="..connectedtime,					--String    \\首次通信时间

		"dev_region="..self.dev_region,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'devSet.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devsettga', tokenList)
end

------------------------------------------------------------------
-- 拉取服务器列表
function LxTKData:StartServerBeginTime()
	self.serverListBeginTime = os.clock()
end

function LxTKData:StepServerList(web_res_ver)
	self.web_res_ver = string.urlencode(gLxServerList.webResVer)
	--if not CS.IsDataMode() then return end
	if self:IsNotSendTK() then return end

	self:InitBaseData()
	
	web_res_ver = web_res_ver or ""
	local useTime = os.clock() - self.serverListBeginTime
	useTime = string.format("%.2f", useTime)
	local tokenList = {
		"dev_uuid="..self.dev_uuid,
		"dev_imei="..self.dev_imei,
		--"dev_mac="..self.dev_mac,
		"dev_type="..self.dev_type,
		"dev_cp="..self.dev_cp,
		"dev_model="..self.dev_model,
		"dev_ver="..self.dev_ver,
		"dev_px="..self.dev_px,
		"dev_cpu="..self.dev_cpu,
		"dev_ram="..self.dev_ram,
		"net_type="..self.net_type,
		"net_ip="..self.net_ip,
		"channel_mapping_id="..self.channel_mapping_id,
		"package_mapping_id="..self.package_mapping_id,
		"app_ver="..self.app_ver,
		"app_res_ver="..string.urlencode(web_res_ver),
		"time="..string.urlencode(useTime),
		"dev_region="..self.dev_region,
		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'serverList.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devList4Tga', tokenList)
end
------------------------------------------------------------------
-- 热更新客户端
function LxTKData:StepUpdateRes(stepType, updateResVer)
	--if not CS.IsDataMode() then return end
	if self:IsNotSendTK() then return end

	self:InitBaseData()
	
	self.app_res_ver = string.urlencode(updateResVer)
	stepType = stepType or 0
	local useTime = os.clock() - self.updateBeginTime
	useTime = string.format("%.2f", useTime)
	local tokenList = {
		"dev_uuid="..self.dev_uuid,
		"dev_imei="..self.dev_imei,		
		"dev_type="..self.dev_type,
		--"dev_mac="..self.dev_mac,
		"dev_cp="..self.dev_cp,
		"dev_model="..self.dev_model,
		"dev_ver="..self.dev_ver,
		"dev_px="..self.dev_px,
		"dev_cpu="..self.dev_cpu,
		"dev_ram="..self.dev_ram,
		"net_type="..self.net_type,
		"net_ip="..self.net_ip,
		"channel_mapping_id="..self.channel_mapping_id,
		"package_mapping_id="..self.package_mapping_id,
		"app_ver="..self.app_ver,
		"app_res_ver="..self.local_res_ver,
		"result="..self.app_res_ver,
		"type="..tostring(stepType),
		"time="..string.urlencode(useTime),
		"dev_region="..self.dev_region,
		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'update.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devUpdate4Tga', tokenList)
end
------------------------------------------------------------------
-- 海外货币
function LxTKData:SetRoleCurrency(identityid, currencytype)
	if not self.enableLog then return end
	if self:IsNotSendTK() then return end
	if string.isempty(identityid) or string.isempty(currencytype) then return end
	self:InitBaseData()
	local url1 = self.serviceUrl..'rolecurrency.do'
	local urlSuffix = "?identity_id="..identityid.. "&u_role_currency_type="..currencytype
	self:HttpPost(url1, urlSuffix)
end

------------------------------------------------------------------
-- 到达登录界面
function LxTKData:StepLoginUI(isUpdate, updateResVer)
	--if not CS.IsDataMode() then return end
	if self:IsNotSendTK() then return end
	self:InitBaseData()
	
	self.app_res_ver = string.urlencode(updateResVer)
	local useTime = os.clock() - self.updateBeginTime
	useTime = string.format("%.2f", useTime)
	local tokenList = {
		"dev_uuid="..self.dev_uuid,
		"dev_imei="..self.dev_imei,		
		"dev_type="..self.dev_type,
		--"dev_mac="..self.dev_mac,
		"dev_cp="..self.dev_cp,
		"dev_model="..self.dev_model,
		"dev_ver="..self.dev_ver,
		"dev_px="..self.dev_px,
		"dev_cpu="..self.dev_cpu,
		"dev_ram="..self.dev_ram,
		"net_type="..self.net_type,
		"net_ip="..self.net_ip,
		"channel_mapping_id="..self.channel_mapping_id,
		"package_mapping_id="..self.package_mapping_id,
		"app_ver="..self.app_ver,
		"app_res_ver="..self.app_res_ver,
		"type="..tostring(isUpdate),
		"time="..string.urlencode(useTime),
		"dev_region="..self.dev_region,
		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'loginUI.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devLoginUI4Tga', tokenList)
end
------------------------------------------------------------------
-- 到达主界面
function LxTKData:BeginLoginGame()
	self.loginBeginTime = os.clock()
end

function LxTKData:StepGameUI(server_id, ref_id, name)
	--if not CS.IsDataMode() then return end
	if not self.enableLog then return end

	self:InitBaseData()

	self.web_res_ver = string.urlencode(gLxServerList.webResVer)
	local useTime = os.clock() - self.loginBeginTime
	useTime = string.format("%.2f", useTime)
	local tokenList = {
		"dev_uuid="..self.dev_uuid,
		"dev_imei="..self.dev_imei,		
		"dev_type="..self.dev_type,
		--"dev_mac="..self.dev_mac,
		"dev_cp="..self.dev_cp,
		"dev_model="..self.dev_model,
		"dev_ver="..self.dev_ver,
		"dev_px="..self.dev_px,
		"dev_cpu="..self.dev_cpu,
		"dev_ram="..self.dev_ram,
		"net_type="..self.net_type,
		"net_ip="..self.net_ip,
		"channel_mapping_id="..self.channel_mapping_id,
		"package_mapping_id="..self.package_mapping_id,
		"app_ver="..self.app_ver,
		"app_res_ver="..self.app_res_ver,
		"server_id="..tostring(server_id),
		"ref_id="..tostring(ref_id),
		"name="..string.urlencode(name),
		"time="..string.urlencode(useTime),
		"dev_region="..self.dev_region,
		"platform_id="..self.platform_id,
		"channel_id="..self.channel_id,
		"zip_version="..self.web_res_ver,
	}
	local urlSuffix = '?'..table.concat(tokenList,"&")
	local url1 = self.serviceUrl..'devGameUI4Tga.do'
	self:HttpPost(url1, urlSuffix)
	self:SendTAJson(self.serviceUrl..'devGameUI4Tga', tokenList)
end

-----------------------------------------------------------------
function LxTKData:IsNotSendTK()
	if self._isNotSendTK == nil then
		self._isNotSendTK = false
	end
	return self._isNotSendTK
end

function LxTKData:InitEnableState(loginServer)
	local enableStat = tonumber(loginServer.enableStat) or 0
	local enableLog = tonumber(loginServer.enableLog) or 0
	self.enableStat = enableStat == 1
	self.enableLog = enableLog == 1
end
------------------------------------------------------------------
-- 登录后的数据打点 提交到服务端
function LxTKData:InitTKStepDatas(loginServer)
	--if not CS.IsDataMode() then return end
	if not loginServer then return end

	self:AddMsgHandler(LProtoIds.NoviceStepResp, self.OnNoviceStepResp, self)
	self:AddMsgHandler(LProtoIds.ClickInformResp, self.OnClickInformResp, self)
	self:AddMsgHandler(LProtoIds.TAClientEventResp, function(...) end)
	self:ParseTKStepDatas()
end

function LxTKData:ParseTKStepDatas()
	-- 初始化打点Ref数据
	local guide2NoviceRef = {}
	local story2NoviceRef = {}
	local fixed2NoviceRef = {}
	local cartoon2NoviceRef = {}
	for k,v in pairs(GameTable.NoviceStepsGuideRef) do
		local guideRefIdCfg = v.noviceSteps
		local guideRefIdList = string.split(guideRefIdCfg, ';') or {}
		for _,guideRefIdStr in ipairs(guideRefIdList) do
			local guideRefId = tonumber(guideRefIdStr) or 0
			if guideRefId > 0 then
				guide2NoviceRef[guideRefId] = v
			end
		end

		local storyRefIdCfg = v.storySteps
		local storyRefIdList = string.split(storyRefIdCfg, ';') or {}
		for _,storyRefIdStr in ipairs(storyRefIdList) do
			local storyRefId = tonumber(storyRefIdStr) or 0
			if storyRefId > 0 then
				story2NoviceRef[storyRefId] = v
			end
		end

		local fixedStoryRefIdCfg = v.jumpSteps
		local fixedStoryRefIdList = string.split(fixedStoryRefIdCfg, ';') or {}
		for _,storyRefIdStr in ipairs(fixedStoryRefIdList) do
			local storyRefId = tonumber(storyRefIdStr) or 0
			if storyRefId > 0 then
				fixed2NoviceRef[storyRefId] = v
			end
		end

		--local cartoonSteps = v.cartoonSteps
		--local strList = string.split(cartoonSteps, ';')
		--for k1,v1 in ipairs(strList) do
		--	local refId = tonumber(v1) or 0
		--	if refId > 0 then
		--		cartoon2NoviceRef[refId] = v
		--	end
		--end
	end
	self.guide2NoviceRef = guide2NoviceRef
	self.story2NoviceRef = story2NoviceRef
	self.fixed2NoviceRef = fixed2NoviceRef
	self.cartoon2NoviceRef = cartoon2NoviceRef
end

function LxTKData:NoviceStepReq(stepId)
	local pb = LProtoHelper.CreateProto(LProtoIds.NoviceStepReq)
	pb.stepId = stepId
	pb.platformId = tonumber(self.channel_mapping_id) or 0
	pb.channelId =  tonumber(self.package_mapping_id) or 0
	local int64Id = gLGameLogin:GetPlayerId() or "0"
	pb.playerId = int64Id
	SendMessage(pb,LProtoIds.NoviceStepReq)
	--printInfoN("<color=green>############### NoviceStepReq refId="..stepId.."</color>")
end

function LxTKData:OnNoviceStepResp(pb)
	-- /** 1-成功,0-失败 */
	-- required int32 result = 1;
end

function LxTKData:ClickInformReq(iType, name, desc, desc2)
	-- /** 上报类型,1-数数科技打点 */
	local pb = LProtoHelper.CreateProto(LProtoIds.ClickInformReq)
	pb.informType = iType or 1
	pb.buttonName = tostring(name)
	pb.buttonDesc = tostring(desc)
	pb.buttonDesc2 = tostring(desc2)
	SendMessage(pb,LProtoIds.ClickInformReq)
end
	
function LxTKData:OnClickInformResp(pb)
	
end
------------------------------------------------------------------
-- 新手打点
function LxTKData:OnGuideStep(guideEventRefId)
	--if not CS.IsDataMode() then return end
	if not self.enableStat then return end

	local noviceRef = self.guide2NoviceRef[guideEventRefId]
	if noviceRef then
		self:NoviceStepReq(noviceRef.refId)
	end
end
function LxTKData:OnStoryStep(storyRefId)
	--if not CS.IsDataMode() then return end
	if not self.enableStat then return end

	local noviceRef = self.story2NoviceRef[storyRefId]
	if noviceRef then
		self:NoviceStepReq(noviceRef.refId)
	end
end
-- 固定Key通知，目前只有skipA
function LxTKData:OnFixedStep(storyRefId)
	--if not CS.IsDataMode() then return end
	if not self.enableStat then return end

	local noviceRef = self.fixed2NoviceRef[storyRefId]
	if noviceRef then 
		self:NoviceStepReq(noviceRef.refId)
		
		self:ClickInformReq(1, ccClientText(217), ccClientText(218), storyRefId or "")
	end
end

function LxTKData:OnPreStoryStep(refId,type)
	if not self.enableStat then return end

	local dataMap = self.story2NoviceRef
	if type == 1 then
		dataMap = self.cartoon2NoviceRef
	end

	local noviceRef = dataMap[refId]
	if noviceRef then
		self:NoviceStepReq(noviceRef.refId)
	end
end
------------------------------------------------------------------------
-- 主界面活动点击
function LxTKData:OnMainUIActivityClick(activityData)
	--if not CS.IsDataMode() then return end
	if not self.enableLog or not activityData then return end

	local name = activityData.sid .. "|" .. activityData.title
	local desc = ccClientText(201)
	local desc2 = ccClientText(201)
	self:ClickInformReq(1, name, desc, desc2)
end
------------------------------------------------------------------------
------------------------------------------------------------------------
-- 后台活动点击
function LxTKData:OnWebActivityClick(activityData)
	--if not CS.IsDataMode() then return end
	if not self.enableLog or not activityData then return end

	local lng = gLGameLanguage:GetLanguageDefaultFlag()
	local activityTitle = gModelActivity:GetLngNameById(activityData.titleId,lng)
	
	local name = activityData.sid .. "|" .. activityTitle
	local desc = ccClientText(200)
	local desc2 = ccClientText(200)
	if activityData.showScene == 1 then
		desc = ccClientText(201)
		if activityData.type == 5 then
			desc2 = ccClientText(215)
		elseif activityData.type == 4 then
			desc2 = ccClientText(201)
		elseif activityData.type == 3 then
			desc2 = ccClientText(202)
		elseif activityData.type == 2 then
			desc2 = ccClientText(203)
		elseif activityData.type == 1 then
			desc2 = ccClientText(204)
		end
	else
		desc = ccClientText(205)
		if activityData.type == 5 then
			desc2 = ccClientText(215)
		elseif activityData.type == 3 then
			desc2 = ccClientText(202)
		elseif activityData.type == 2 then
			desc2 = ccClientText(203)
		elseif activityData.type == 1 then
			desc2 = ccClientText(204)
		elseif activityData.type == 6 then
			desc2 = ccClientText(229)
		end
	end
	
	self:ClickInformReq(1, name, desc, desc2)
end

function LxTKData:OnClickSecretLink(itemdata)
	if not self.enableLog then return end

	self:ClickInformReq(1, itemdata.name, itemdata.desc, itemdata.desc2)
end

-- 特殊活动处理
function LxTKData:OnClickSpecialAct(info)
	if not self.enableLog or not info then return end

	local iType = info.itype or 1
	local btnName = info.btnName
	local desc = info.desc
	local btnDesc = info.btnDesc
	self:ClickInformReq(iType, btnName, desc, btnDesc)
end
---------------------------------------------------------------------
-- 功能活动，礼包码、特权、实名认证、手机验证这些
function LxTKData:OnFuncActivityClick(activityData)
	--if not CS.IsDataMode() then return end
	if not self.enableLog or not activityData then return end
	
	local name = activityData.refId .. "|" .. ccLngText(activityData.name)
	local desc = ccClientText(205)
	local desc2 = ccClientText(200)
	if activityData.type == 5 then
		desc2 = ccClientText(215)
	elseif activityData.type == 3 then
		desc2 = ccClientText(202)
	elseif activityData.type == 2 then
		desc2 = ccClientText(203)
	elseif activityData.type == 1 then
		desc2 = ccClientText(204)
	end
	self:ClickInformReq(1, name, desc, desc2)
end
---------------------------------------------------------------------
-- 挂机界面的的点击
-- 按钮名称=100|拾取奖励   参数A=点击场景   参数B=冒险场景
-- 按钮名称=101|手动杀怪   参数A=点击场景   参数B=冒险场景
-- 按钮名称=102|点击据点   参数A=点击场景   参数B=冒险场景
-- 按钮名称=103|无效点击   参数A=点击场景   参数B=冒险场景
function LxTKData:OnBtIdleClick(clcikType)
	--if not CS.IsDataMode() then return end
	if not self.enableLog then return end
	
	local title = ccClientText(228)
	local desc = ccClientText(222)
	local desc2 = ccClientText(223)
	if clcikType == 100 then
		title = ccClientText(225)
	elseif clcikType == 101 then
		title = ccClientText(226)
	elseif clcikType == 102 then
		title = ccClientText(227)
	elseif clcikType == 103 then
		title = ccClientText(228)
	end
	local name = clcikType .. "|" .. title
	self:ClickInformReq(1, name, desc, desc2)
end
---------------------------------------------------------------------
-- 活动礼包 第3类
function LxTKData:OnPopupGiftClick(activityData)
	--if not CS.IsDataMode() then return end
	if not self.enableLog or not activityData then return end
	
	local name = activityData.refId .. "|" .. ccLngText(activityData.description)
	local desc = ccClientText(201)
	local desc2 = ccClientText(201)
	self:ClickInformReq(1, name, desc, desc2)
end
---------------------------------------------------------------------
-- 普通商店点击 第4类
function LxTKData:OnBaseShopClick(activityData)
	--if not CS.IsDataMode() then return end
	if not self.enableLog or not activityData then return end

	local name = activityData.refId .. "|" .. ccLngText(activityData.name)
	local desc = ccClientText(206)
	local desc2 = ccClientText(200)
	if activityData.shopStoreType == 1 then
		desc2 = ccClientText(207)
	else
		desc2 = ccClientText(209)
	end
	self:ClickInformReq(1, name, desc, desc2)
end
---------------------------------------------------------------------
-- 活动商店点击 第5类
function LxTKData:OnActivityShopClick(activityData)
	--if not CS.IsDataMode() then return end
	if not self.enableLog or not activityData then return end
	
	local name = activityData.sid .. "|" .. activityData.title.."|"..ccClientText(208)
	local desc = ccClientText(206)
	local desc2 = ccClientText(208)
	self:ClickInformReq(1, name, desc, desc2)
end
---------------------------------------------------------------------
-- 主要按钮点击
function LxTKData:OnUIBtnClick(uiKey, idx)
	--if not CS.IsDataMode() then return end
	if not self.enableLog then return end

	idx = idx or 0
	local name = ccClientText(200)
	local desc = ccClientText(200)
	local desc2 = ccClientText(200)
	if uiKey == "UIDian" then
		if idx == 0 then
			name = ccClientText(212)
			desc = ccClientText(210)
			desc2 = ccClientText(210)
		elseif idx == 3 then
			name = ccClientText(208)
			desc = ccClientText(211)
			desc2 = ccClientText(211)
		elseif idx == 2 then
			name = ccClientText(209)
			desc = ccClientText(211)
			desc2 = ccClientText(211)
		elseif idx == 1 then
			name = ccClientText(207)
			desc = ccClientText(211)
			desc2 = ccClientText(211)
		end
	elseif uiKey == "UIAct" then
		if idx == 0 then
			name = ccClientText(213)
			desc = ccClientText(210)
			desc2 = ccClientText(210)
		elseif idx == 1 then
			name = ccClientText(204)..ccClientText(203)
			desc = ccClientText(211)
			desc2 = ccClientText(211)
		elseif idx == 2 then
			name = ccClientText(203)..ccClientText(203)
			desc = ccClientText(211)
			desc2 = ccClientText(211)
		elseif idx == 3 then
			name = ccClientText(202)..ccClientText(203)
			desc = ccClientText(211)
			desc2 = ccClientText(211)
		end
	elseif uiKey == "UIHuiYPay" then
		if idx == 0 then
			name = ccClientText(214)
			desc = ccClientText(210)
			desc2 = ccClientText(210)
		elseif idx == 1 then
			name = ccClientText(216)
			desc = ccClientText(210)
			desc2 = ccClientText(210)
		elseif idx == 2 then
			name = ccClientText(215)
			desc = ccClientText(211)
			desc2 = ccClientText(211)
		end
	end
	self:ClickInformReq(1, name, desc, desc2)
end
---------------------------------------------------------------------
-- 新手剧情跳过
function LxTKData:OnStorySkipClick(btnIdx, storyId)
	if not self.enableLog then return end

	storyId = tostring(storyId) or ""
	-- btnIdx: 1-跳过剧情  2-确定跳过
	if btnIdx == 1 then
		self:ClickInformReq(1, ccClientText(217), ccClientText(218), storyId or "")
	else
		self:ClickInformReq(1, ccClientText(219), ccClientText(220), storyId or "")
	end
end
-- 新手剧情选择
function LxTKData:OnStorySelClick(eventId, storyId)
	if not self.enableLog then return end

	eventId = tostring(eventId) or ""
	storyId = tostring(storyId) or ""
	self:ClickInformReq(1, ccClientText(221), eventId, storyId)
end

function LxTKData:OnTAClientEventReqEmpty()
	local pb = LProtoHelper.CreateProto(LProtoIds.TAClientEventReq)
	pb.eventName = ""
	SendMessage(pb,LProtoIds.TAClientEventReq)
end

function LxTKData:OnTAClientEventReq(eventName,step,attr1,attr2,attr3)
	if not self.enableLog then return end
	if LxTKData._ForbidEvents[eventName] then return end

	local pb = LProtoHelper.CreateProto(LProtoIds.TAClientEventReq)
	if string.isempty(eventName) then
		printErrorN("OnTAClientEvent eventName is nil")
		return
	end
	pb.eventName = eventName
	if step then
		pb.step = tostring(step)
	end
	if attr1 then
		pb.attr1 = tostring(attr1)
	end
	if attr2 then
		pb.attr2 = tostring(attr2)
	end
	if attr3 then
		pb.attr3 = tostring(attr3)
	end
	SendMessage(pb,LProtoIds.TAClientEventReq)
end

function LxTKData:OnPayTAReq(data)
	if not self.enableLog then return end

	local TAData = {
		["recharge_goods_id"] = tostring(data.goodsId),
		["recharge_goods_price_cny"] = data.price,
		["recharge_goods_name"] = tostring(data.name),
		["recharge_goods_desc"] = tostring(data.desc),
		["recharge_goods_type"] = tostring(data.type),
		["recharge_sys"] = tostring(data.sys),
		["recharge_sys_name"] = tostring(data.sysName),
		["recharge_server_order_id"] = tostring(data.orderId),
		["reward"] =tostring(data.reward),
	}
	local attr1 = JSON.encode(TAData)
	self:OnTAClientEventReq(LxTKData.RECHARGE_CLIENT_ORDER,nil,attr1)
end

--function LxTKData:OnSettingTAReq()
--	if not self.enableLog then return end
--
--	local qualityLv = tonumber(LPlayerPrefs.qualityLv)
--	local highQuality = 0
--	if(qualityLv == LGameQuality.QUALITY_LV_NORMAL) then
--		highQuality = 1
--	end
--
--	local highFrameRate = 0
--	if tonumber(LPlayerPrefs.highFrameRate) == 1 then
--		highFrameRate = 1
--	end
--	local TAData =
--	{
--		["music"] = tostring(LPlayerPrefs.musicVolume),
--		["sound"] = tostring(LPlayerPrefs.soundVolume),
--		["language"] = tostring(LPlayerPrefs.lngFlag),
--		["highQuality"] = tostring(highQuality),
--		["highFrameRate"] = tostring(highFrameRate),
--		["push_explore"] = toboolean(LPlayerPrefs.notifyIdleReward) and "1" or "0",
--		["push_arena"] = toboolean(LPlayerPrefs.notifyArenaPeak) and "1" or "0",
--		--["push_dreamFountain"] = toboolean(LPlayerPrefs.notifyDreamFountain) and "1" or "0",
--
--	}
--	local attr1 = JSON.encode(TAData)
--
--	self:OnTAClientEventReq(LxTKData.CLIENT_SETTING,nil,attr1)
--
--end

function LxTKData:OnLanguageTAReq(oldRefId)
	if not self.enableLog then return end

	local lngRefId = LPlayerPrefs and LPlayerPrefs.lngFlag
	local attr1 = nil
	local attr2 = nil
	if oldRefId then
		local ref = GameTable.MulLanguageShowRef[oldRefId]
		if ref then
			attr1 = ref.desc
		end
	end
	if lngRefId then
		local ref =GameTable.MulLanguageShowRef[lngRefId]
		if ref then
			attr2 = ref.desc
		end
	end
	self:OnTAClientEventReq(LxTKData.CLIENT_LANGUAGE_SWITCH,nil,attr1 or oldRefId, attr2 or lngRefId)
end

return LxTKData

