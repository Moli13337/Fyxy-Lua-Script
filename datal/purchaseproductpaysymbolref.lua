local _keys = {refId=1,type=2,name=3,symbol=4}
local _mt = {
    __index = function(t, k)
        local idx = _keys[k]
        if not idx then return nil end
        return rawget(t, idx)
    end,
    __newindex = function(t, k)
    end
}
local _set = setmetatable
local _datas = {
[1]=_set({1,"USD","usdPayPoint","$"},_mt),
[2]=_set({2,"HKD","hkdPayPoint","HK$"},_mt),
[3]=_set({3,"JPY","jpyPayPoint","¥"},_mt),
[4]=_set({4,"CHF","chfPayPoint",""},_mt),
[5]=_set({5,"BRL","brlPayPoint",""},_mt),
[6]=_set({6,"PKR","pkrPayPoint",""},_mt),
[7]=_set({7,"BDT","bdtPayPoint",""},_mt),
[8]=_set({8,"LKR","lkrPayPoint",""},_mt),
[9]=_set({9,"TWD","twdPayPoint","NT$"},_mt),
[10]=_set({10,"MMK","mmkPayPoint",""},_mt),
[11]=_set({11,"PHP","phpPayPoint",""},_mt),
[12]=_set({12,"EUR","eurPayPoint","€"},_mt),
[13]=_set({13,"CAD","cadPayPoint","C$"},_mt),
[14]=_set({14,"IDR","idrPayPoint",""},_mt),
[15]=_set({15,"VND","vndPayPoint",""},_mt),
[16]=_set({16,"THB","thbPayPoint",""},_mt),
[17]=_set({17,"MYR","myrPayPoint",""},_mt),
[18]=_set({18,"NZD","nzdPayPoint",""},_mt),
[19]=_set({19,"RUB","rubPayPoint","₽"},_mt),
[20]=_set({20,"AUD","audPayPoint",""},_mt),
[21]=_set({21,"GBP","gbpPayPoint","£"},_mt),
[22]=_set({22,"RMB","rmbPayPoint","￥"},_mt),
[23]=_set({23,"QAR","qarPayPoint",""},_mt),
[24]=_set({24,"SAR","sarPayPoint",""},_mt),
[25]=_set({25,"TRY","tryPayPoint",""},_mt),
[26]=_set({26,"ILS","ilsPayPoint",""},_mt),
[27]=_set({27,"COP","copPayPoint",""},_mt),
[28]=_set({28,"MXN","mxnPayPoint",""},_mt),
[29]=_set({29,"INR","indPayPoint",""},_mt),
[30]=_set({30,"CZK","czkPayPoint",""},_mt),
[31]=_set({31,"SGD","sgdPayPoint","S$"},_mt),
[32]=_set({32,"SEK","sekPayPoint",""},_mt),
[33]=_set({33,"PLN","plnPayPoint",""},_mt),
[34]=_set({34,"RON","ronPayPoint",""},_mt),
[35]=_set({35,"HUF","hufPayPoint",""},_mt),
[36]=_set({36,"KRW","krwPayPoint","₩"},_mt),
[37]=_set({37,"MAS","masPayPoint",""},_mt),
[38]=_set({38,"NUT","nutPayPoint",""},_mt),
[40]=_set({40,"DY","dyPayPoint","<sprite index=0>"},_mt)
}

return _datas