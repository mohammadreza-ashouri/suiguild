module suiguild::APPID{

    friend suiguild::suiguild;

       // app ids for filterations
    
    const APP_ID_XMPP_SERVER: u8=2;
    const APP_ID_FOR_CHAT_APP: u8 = 0;
    const APP_ID_FOR_CHAT_WEB: u8 = 1;
    


    public fun GET_APP_ID_FOR_CHAT_APP() :u8 {
        return APP_ID_FOR_CHAT_APP
    }

    public fun GET_APP_ID_FOR_CHAT_WEB() :u8 {
        return APP_ID_FOR_CHAT_WEB
    }

    public fun GET_APP_ID_XMPP_SERVER() :u8 {
        return APP_ID_XMPP_SERVER
    }

}