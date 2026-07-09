--c#自动生成,无需手动填入

CsFunType = {
    --首屏
    HideLaunchScreen = 1,
    --像素比
    PixelRatio = 3,
    --垃圾回收
    Gc = 2,
    --上报
    Report = 4,
    --下载
    Down = 5,
    --初始化格子
    InitGridGraph = 6,
    --重新设置格子
    ResetBtIdleGridGraph = 7,
    --获取微信字体
    GetWxFont = 8,
}

CsValueType = {
    --微信系统信息
    WxSystemInfo = 1,
    --微信设备内存值
    WxDeviceMemorySize = 2,
    --获取游戏当前运行数据
    GetGameData = 3,
    -- ios高性能模式
    -- IsIOSHighPerformanceModePlus = 4,
    --纹理压缩
    IsTextureCompression = 5,
    --游戏启动进度值
    GetLaunchProgress = 6,
}

CsDownType = {
    --下载Lua ab分包资源
    DownLuaAbSubpackage = 1,
}