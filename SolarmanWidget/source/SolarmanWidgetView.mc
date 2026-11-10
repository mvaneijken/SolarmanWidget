using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Communications;
using Toybox.System;
using Toybox.Cryptography;

// Commands from the delegate
var DOWEBREQUEST=1;

// Status screens vars
var showRefrsh = false;
var showErr = false;
var errStr1 = "";
var errStr2 = "";
var errStr3 = "";
var errStr4 = "";

// vars to remember
var curr;
var today;
var thisMonth;
var thisYear;
var total;
var batterySoc;
var lastUpdTmLocal;
var lastUpdDtLocal;
var lstUpd;
var dataCenter;
var baseUrl = "https://globalhomeappapi.solarmanpv.com";
var userAgent = "okhttp/4.9.3";
var accessToken;
var plantid; //plant_id variable received when retrieving the plants.
var battery = false;

var glanceName = "";
var glanceVal = "";
var fUpdt = false;

// Settings
var currPage;
var usr = "-";
var pwrd = "-";

function NextPage()
{
    // Next Page pressed, increase the pagenumber
    currPage++;

    // Rotate is last page = met
    if(battery == false){
        if (currPage>6) {
            currPage=1;
        }
    }
    else{
        if (currPage>7) {
            currPage=1;
        }
    }

    // refresh the screen
    WatchUi.requestUpdate();
}

function PreviousPage()
{
    // Previous Page pressed, decrease the pagenumber
    currPage--;

    // Rotate is last page = met
    if(battery == false){
        if (currPage<1) {
            currPage=6;
        }
    }
    else{
        if (currPage<1) {
            currPage=7;
        }
    }

    // refresh the screen
    WatchUi.requestUpdate();
}

function RefreshPage()
{
    WatchUi.requestUpdate();
    fUpdt = true;
}

class SolarmanWidgetView extends WatchUi.View {

    //var icon as BitmapResource;
    //var logo as BitmapResource;

    function initialize() {
        //System.println("getDevicePartNumber: " + System.getDeviceSettings().deviceSettings.partNumber);
        retrieveSettings();
        View.initialize();
        //logo = WatchUi.loadResource(Rez.Drawables.solarmanlogo);
        //icon = WatchUi.loadResource(Rez.Drawables.SolarmanIcon);
    }

function retrieveSettings() {

        ////System.println("SolarmanWidgetView:retrieveSettings");
        dataCenter = Application.getApp().getProperty("DC");
        ////System.println("dataCenter: " + dataCenter);
        if(dataCenter == 2){
            baseUrl = "https://homeappapi.solarmanpv.com";
        }
        ////System.println("baseUrl: " + baseUrl);

        // Get Username From settings
        usr = Application.getApp().getProperty("PUN");
        ////System.println("Username: " + Username);

        // Get Password from Settings
        pwrd = Application.getApp().getProperty("PPS");

        // Get curr Page From settings
        currPage= Application.getApp().getProperty("PSP");
        if(currPage == null){currPage=1;}

        // Get the accesstoken
        accessToken=Application.getApp().getProperty("ACT");
//        if(accessToken == null){accessToken = null};

        // Get the plantid
        plantid=Application.getApp().getProperty("PPI");
        if(plantid == null){plantid = -1;}
        if(plantid instanceof String){plantid = -1;}

        // Get the battery status
        battery = Application.getApp().getProperty("BT");
        if(battery == null){battery = false;}
        if(battery instanceof String){battery = false;}

        //Allow to update credentials (gSettingsChanged will be set to true which calls this function twice)
        if(Application.getApp().getProperty("currUsr") != "" && usr != Application.getApp().getProperty("currUsr")){accessToken = "";plantid = -1;}
        if(Application.getApp().getProperty("currPwrd") != "" && pwrd != Application.getApp().getProperty("currPwrd")){accessToken = "";plantid = -1;}

        // Set initial glanceVal
        glanceName = Application.getApp().getProperty("AppName");
        glanceVal = "";
    }

    function toMoment(string)
    {
        //System.println(string);
        return Gregorian.moment({
            :year   => string.toString().substring(0,4).toNumber(),
            :month  => string.toString().substring(5,7).toNumber(),
            :day    => string.toString().substring(8,10).toNumber(),
            :hour   => string.toString().substring(11,13).toNumber(),
            :minute => string.toString().substring(14,16).toNumber(),
            :second => string.toString().substring(17,19).toNumber()
        });
    }

    function frmtDtFromRFC3339 (string)
    {
        ////System.println("SolisWidgetView:frmtDtFromRFC3339");
        ////System.println(string.toString());
        var i = Gregorian.info(toMoment(string), Time.FORMAT_SHORT); //Time.FORMAT_SHORT

        return (Lang.format("$1$-$2$-$3$", [
            i.day.format("%01u"),
            i.month.format("%01u"),
            i.year.format("%02u")
        ]));
    }

    function frmtTmFromRFC3339 (string)
    {
        ////System.println("SolisWidgetView:frmtTmFromRFC3339");
        ////System.println(string.toString());
        var i = Gregorian.info(toMoment(string), Time.FORMAT_SHORT); //Time.FORMAT_SHORT

        return (Lang.format("$1$:$2$:$3$", [
            i.hour.format("%01u"),
            i.min.format("%02u"),
            i.sec.format("%02u")
        ]));

    }

    function frmtEnergy(power, inputunit)
    {
        // Only convert values that support toFloat(). Calling it on null or an unexpected type
        // raises an Unexpected Type Error that a try/catch does not reliably stop.
        if(power instanceof Lang.Number || power instanceof Lang.Long || power instanceof Lang.Float || power instanceof Lang.Double || power instanceof Lang.String){
            power = power.toFloat();
        }
        else{
            power = null;
        }

        if(power != null){
            if(null != inputunit && inputunit.equals("W")){
                if (power<1000)
                {
                    // > more than kWh, so present in in kWh
                    return power.format("%.1f") + " Wh";
                }
                else{
                    // > more than kWh, so present in in kWh
                    return (power / 1000).toFloat().format("%.2f") + " kWh";
                }
            }
            else{
                if (power<1)
                {
                // Less than 1 kWh Present in Wh
                    return (power * 1000).toNumber() + " Wh";
                }
                else if (power<1000)
                {
                    // > more than kWh, so present in in kWh
                    return power.format("%.1f") + " kWh";
                }
                else{
                    // > more than kWh, so present in in kWh
                    return (power / 1000).toFloat().format("%.2f") + " MWh";
                }
            }
        }
        else{
            return "No data received";
        }
    }

    function procRespCode(rspCode,data){
        ////System.println("SolarmanWidgetView:procRespCode");

        // Turn off refreshpage
        showRefrsh=false;
        showErr=false;
        ////System.println(rspCode);
        ////System.println(data);

        if (rspCode==200)
        {
            //Nothing, just continue
            showErr=false;
        }
        else if (rspCode==-104) //Communications.BLE_CONNECTION_UNAVAILABLE
        {
            // bluetooth connection issue
            showErr = true;
            errStr1=WatchUi.loadResource(Rez.Strings.B1);
            errStr2=WatchUi.loadResource(Rez.Strings.B2);
            errStr3=WatchUi.loadResource(Rez.Strings.B3);
            data=null;
        }
        else if (rspCode==-400) //Communications.INVALID_HTTP_BODY_IN_NETWORK_RESPONSE
        {
            // Invalid API key
            showErr = true;
            errStr1=WatchUi.loadResource(Rez.Strings.I1);
            errStr2=WatchUi.loadResource(Rez.Strings.I2);
            errStr3=WatchUi.loadResource(Rez.Strings.I3);
            data=null;
        }
        else if (rspCode==-300) //Communications.NETWORK_REQUEST_TIMED_OUT
        {
            // No Internet
            showErr = true;
            errStr1=WatchUi.loadResource(Rez.Strings.N1);
            errStr2=WatchUi.loadResource(Rez.Strings.N2);
            errStr3=WatchUi.loadResource(Rez.Strings.N3);
            data=null;
        }
        else if (rspCode==412)
        {
            // The body of an error response is not guaranteed to be a JSON dictionary
            var errResult = null;
            var errError = null;
            var errDescription = null;
            var errCode = null;
            var errIsDict = data instanceof Dictionary;
            if(errIsDict){
                errResult = data["result"];
                errError = data["error"];
                errDescription = data["error_description"];
                errCode = data["code"];
            }

            if(!errIsDict || errResult == null || (errError instanceof Lang.String && errError.length() > 0))
            {
                // Reset values to reinitiate login
                showErr=true;
                accessToken = "";
                plantid = -1;
                Application.getApp().setProperty("PPI",0);
                if(errDescription != null){
                    errStr1="API Error: "+ errDescription;
                }
                else{
                    errStr1="API Error: "+ rspCode;
                }
                if(errDescription == "invalid_token" || errCode == "AUTH_INVALID_USERNAME_OR_PASSWORD"){
                    errStr2=WatchUi.loadResource(Rez.Strings.A1);
                    errStr3=WatchUi.loadResource(Rez.Strings.A2);
                    errStr4=WatchUi.loadResource(Rez.Strings.A3);
                }
                else{
                    errStr2=WatchUi.loadResource(Rez.Strings.I1);
                    errStr3=WatchUi.loadResource(Rez.Strings.I2);
                    errStr4=WatchUi.loadResource(Rez.Strings.I3);
                }
                data=null;
            }
            else{
                showErr = true;
                errStr1="Error "+rspCode;
                errStr2=WatchUi.loadResource(Rez.Strings.E1);
                errStr3=WatchUi.loadResource(Rez.Strings.E2);
                errStr4=WatchUi.loadResource(Rez.Strings.E3);
            }
        }
        else{
            showErr = true;
            if(rspCode == null){
                rspCode = "unknown";
            }
            errStr1="Error "+rspCode;
            errStr2=WatchUi.loadResource(Rez.Strings.E1);
            errStr3=WatchUi.loadResource(Rez.Strings.E2);
            errStr4=WatchUi.loadResource(Rez.Strings.E3);
        }
        WatchUi.requestUpdate();
        return showErr;
    }

    function frmtScrLines(ln1val,ln2val,ln3val,ln4val,ln5val,ln6val,lines,dc){
        ////System.println("SolarmanWidgetView:frmtScrLines");

        var lnSpaceL = 2;
        var lnSpaceM = 2.6;
        var scrnDev = lines - 1;
        var ln1Font = 13; //Graphics.FONT_SYSTEM_LARGE;
        var ln2Font = 0;
        var ln3Font = 0;
        var ln4Font = 0;
        var ln5Font = 0;
        var ln6Font = 0;
        if(lines == 1 || lines == 2){
            scrnDev = 2;
        }
        if(lines >= 2){
            ln1Font = Graphics.FONT_SYSTEM_LARGE; //Graphics.FONT_SYSTEM_LARGE;
            ln2Font = Graphics.FONT_SYSTEM_LARGE; //Graphics.FONT_SYSTEM_LARGE;
        }
        if(lines >= 3){
            ln1Font = Graphics.FONT_SYSTEM_LARGE; //Graphics.FONT_SYSTEM_LARGE;
            ln2Font = Graphics.FONT_SYSTEM_LARGE; //Graphics.FONT_SYSTEM_LARGE;
            ln3Font = Graphics.FONT_SMALL; //Graphics.FONT_SMALL;
        }
        if(lines >= 4){
            ln1Font = Graphics.FONT_SYSTEM_LARGE; //Graphics.FONT_SYSTEM_LARGE;
            ln2Font = Graphics.FONT_SYSTEM_LARGE; //Graphics.FONT_SYSTEM_LARGE;
            ln3Font = Graphics.FONT_SMALL; //Graphics.FONT_SMALL;
            ln4Font  = Graphics.FONT_SMALL; //Graphics.FONT_SMALL;
        }
        if(lines >= 5){
            ln1Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln2Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln3Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln4Font  = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln5Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            lnSpaceL = 2.6;
        }
        if(lines >= 6){
            ln1Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln2Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln3Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln4Font  = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln5Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            ln6Font = Graphics.FONT_MEDIUM; //Graphics.FONT_MEDIUM;
            lnSpaceL = 2.6;
        }
        var ln1PosY = dc.getHeight() / scrnDev;
        var ln2PosY = ln1PosY + ((Graphics.getFontHeight(ln1Font) / lnSpaceM) + (Graphics.getFontHeight(ln1Font) / lnSpaceM));
        var ln3PosY = ln2PosY + ((Graphics.getFontHeight(ln2Font) / lnSpaceL) + (Graphics.getFontHeight(ln2Font) / lnSpaceL));
        var ln4PosY = ln3PosY + ((Graphics.getFontHeight(ln3Font) / lnSpaceM) + (Graphics.getFontHeight(ln3Font) / lnSpaceM));
        var ln5PosY = ln4PosY + ((Graphics.getFontHeight(ln4Font) / lnSpaceM) + (Graphics.getFontHeight(ln4Font) / lnSpaceM));
        var ln6PosY = ln5PosY + ((Graphics.getFontHeight(ln5Font) / lnSpaceM) + (Graphics.getFontHeight(ln5Font) / lnSpaceM));
        dc.drawText(
            dc.getWidth() / 2,
            ln1PosY,
            ln1Font,
            ln1val,
            1 //Graphics.TEXT_JUSTIFY_CENTER
        );
        if(lines >= 2){
            dc.drawText(
                dc.getWidth() / 2,
                ln2PosY,
                ln2Font,
                ln2val,
                1 //Graphics.TEXT_JUSTIFY_CENTER
            );
        }
        if(lines >= 3){
            dc.drawText(
                dc.getWidth() / 2,
                ln3PosY,
                ln3Font,
                ln3val,
                1 //Graphics.TEXT_JUSTIFY_CENTER
            );
        }
        if(lines >= 4){
            dc.drawText(
                dc.getWidth() / 2,
                ln4PosY,
                ln4Font,
                ln4val,
                1 //Graphics.TEXT_JUSTIFY_CENTER
            );
        }
        if(lines >= 5){
            dc.drawText(
                dc.getWidth() / 2,
                ln5PosY,
                ln5Font,
                ln5val,
                1 //Graphics.TEXT_JUSTIFY_CENTER
            );
        }
        if(lines >= 6){
            dc.drawText(
                dc.getWidth() / 2,
                ln6PosY,
                ln6Font,
                ln6val,
                1 //Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    function setNotParsable()
    {
        // not parsable
        curr = null;
        today = null;
        thisMonth = null;
        thisYear = null;
        total = null;
        lstUpd = null;
        lastUpdTmLocal = null;
        lastUpdDtLocal = null;
    }

    // Handle Command from Delegate view
    function HandleCommand (data)
    {
        // update of data requested
        if (data==DOWEBREQUEST)
        {
            //System.println("HandleCommand: makeReq");
            makeReq();
        }
    }

    function makeReq() {
        //System.println("makeReq");
        //System.println("makeReq uid:"+uid);

        fUpdt = false;
        // Show refreshing page
        showErr=false; // turn off an error screen (if any)
        showRefrsh=true; // make sure refreshingscreen is shown when UP the UI.
        WatchUi.requestUpdate();
        var url = baseUrl+"/oauth-s/oauth/token";

        // hash password to SHA256
        var pwrd_byte_array = Conversion.StringToByteArray(pwrd);
        var sha256hash = Hash.NewSha256HashObject();
        var sha256hash_bytes = Hash.ComputeHash(sha256hash,pwrd_byte_array);
        var hashedpassword = Conversion.ByteArrayToHexString(sha256hash_bytes);

        // Make the authentication request
        //System.println("makeReq url: "+url);
        Communications.makeWebRequest(url,{
            "system"=>"SOLARMAN",
            "grant_type"=>"password",
            "username"=> usr,
            "password"=> hashedpassword,
            "client_id"=>"test",
            "clear_text_pwd"=> pwrd,
            "identity_type"=>2
        },
        {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
                    "User-Agent" => userAgent,
                    "Accept" => "application/json, text/plain, */*"
                }
        },method(:onRec));
    }

    // Receive the data from the web request
    function onRec(rspCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void
    {
        //System.println("onRec");
        showErr = procRespCode(rspCode,data);

        if(showErr){
            WatchUi.requestUpdate();
        }
        else{
            showErr=false;
            accessToken = "Bearer " + data["access_token"];
            Application.getApp().setProperty("ACCESSTOKEN","Bearer " + data["access_token"]);
            Application.getApp().setProperty("REFRESHTOKEN",data["refresh_token"]);
            makeReqPlantId();
        }
    }

    function makeReqPlantId() {
        //System.println("makeReqPlantId");

        // Show refreshing page

            showRefrsh=true; // make sure refreshingscreen is shown when UP the UI.
            WatchUi.requestUpdate();
            var url = baseUrl+"/maintain-s/operating/station/search?page=1&size=10&order.direction=ASC&order.property=name";

            // Make the authentication request
            //System.println("makeReqPlantId url:"+url);
            Communications.makeWebRequest(url,{
                "region"=> {
                    "nationId" => null,
                    "level1" => null,
                    "level2" => null,
                    "level3" => null,
                    "level4" => null,
                    "level5" => null
                }
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "User-Agent" => userAgent,
                    "accept" => "application/json, text/plain, */*",
                    "Authorization" => Application.getApp().getProperty("ACCESSTOKEN")
                }
            },method(:onRecPlantId));
        }


    function onRecPlantId(rspCode as Lang.Number, data as Null or Lang.Dictionary or Lang.String) as Void
    {
        //System.println("onRecPlantId ");
        showErr = procRespCode(rspCode,data);

        if(showErr){
            WatchUi.requestUpdate();
        }
        else{
            if (data instanceof Dictionary){
                // The account can have no plants, so make sure the first plant exists
                var plants = data["data"];
                if(!(plants instanceof Lang.Array) || plants.size() < 1 || !(plants[0] instanceof Dictionary)){
                    showErr = true;
                    errStr1 = "No plants found";
                    errStr2 = WatchUi.loadResource(Rez.Strings.E1);
                    errStr3 = WatchUi.loadResource(Rez.Strings.E2);
                    errStr4 = WatchUi.loadResource(Rez.Strings.E3);
                    WatchUi.requestUpdate();
                    return;
                }
                var plant = plants[0];

                plantid = plant["id"];
                Application.getApp().setProperty("plantid",plantid);

                // Format curr
                curr = frmtEnergy(plant["generationPower"],"W");
                //System.println("curr: "+curr);

                // Format today
                today = frmtEnergy(plant["generationValue"], null);
                //System.println("today: "+today);

                // Format Month
                thisMonth = frmtEnergy(plant["generationMonth"], null);
                //System.println("thisMonth: "+thisMonth);

                // Format Year
                thisYear = frmtEnergy(plant["generationYear"], null);
                //System.println("thisYear: "+thisYear);

                // Format total
                total = frmtEnergy(plant["generationTotal"], null);
                //System.println("total: "+total);

                if(battery == true){
                    // Format battery
                    try{
                        batterySoc = plant["batterySoc"];
                        if(null != batterySoc){
                            if(batterySoc instanceof Lang.Number || batterySoc instanceof Lang.Long || batterySoc instanceof Lang.Float || batterySoc instanceof Lang.Double || batterySoc instanceof Lang.String){
                                batterySoc = batterySoc.toFloat();
                            }
                            else{
                                batterySoc = null;
                            }
                            if(null != batterySoc){
                                batterySoc = batterySoc.format("%.1f") + " %";
                            }
                            else{
                                batterySoc = "- %";
                            }
                        }
                        else{
                            batterySoc = "- %";
                        }
                    }
                    catch(ex){
                        batterySoc = "- %";
                    }
                    //System.println("battery: "+battery);
                }
                else{
                    batterySoc = null;
                }

                // Format Last Update
                var lastUpdateTime = plant["lastUpdateTime"];
                if(lastUpdateTime instanceof Lang.Number || lastUpdateTime instanceof Lang.Long || lastUpdateTime instanceof Lang.Float || lastUpdateTime instanceof Lang.Double || lastUpdateTime instanceof Lang.String){
                    var lastUpdateObject = Gregorian.utcInfo((new Time.Moment(lastUpdateTime.toNumber())),Time.FORMAT_SHORT);
                    lstUpd = Lang.format("$1$-$2$-$3$ $4$:$5$:$6$", [
                        lastUpdateObject.year.format("%04u"),
                        lastUpdateObject.month.format("%02u"),
                        lastUpdateObject.day.format("%02u"),
                        lastUpdateObject.hour.format("%02u"),
                        lastUpdateObject.min.format("%02u"),
                        lastUpdateObject.sec.format("%02u")
                    ]);
                    lastUpdTmLocal = frmtTmFromRFC3339(lstUpd);
                    lastUpdDtLocal = frmtDtFromRFC3339(lstUpd);
                }
                else{
                    // No usable timestamp; show a dash because the status page draws these values as text
                    lstUpd = "-";
                    lastUpdTmLocal = "-";
                    lastUpdDtLocal = "-";
                }
            }
            else{
                setNotParsable();
            }
            WatchUi.requestUpdate();
        }
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        //Sys.println("SolarmanWidgetView:onShow");

        //  Load saved data
        curr = Application.getApp().getProperty("curr");
        today = Application.getApp().getProperty("today");
        thisMonth = Application.getApp().getProperty("thisMonth");
        thisYear = Application.getApp().getProperty("thisYear");
        total = Application.getApp().getProperty("total");
        batterySoc = Application.getApp().getProperty("batterySoc");
        lstUpd= Application.getApp().getProperty("lstUpd");
        lastUpdTmLocal = Application.getApp().getProperty("lastUpdTmLocal");
        lastUpdDtLocal = Application.getApp().getProperty("lastUpdDtLocal");
        makeReq();
    }

    // Update the view
    function onUpdate(dc) {
        //Sys.println("SolarmanWidgetView:onUpdate");

        //Sys.println("Screen heigth: " + dc.getHeight());
        //Sys.println("Screen width: " + dc.getWidth());

        if (gSettingsChanged) {
            gSettingsChanged = false;
            retrieveSettings();
        }

        // Call the parent onUpdate function to redraw the layout
        // View.onUpdate(dc);
        dc.setColor(0x000000,0x000000); //(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(0xFFFFFF,-1); //(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Draw logo
        //var logowidth = logo.getWidth();
        //var logoPosX = (dc.getWidth() - logowidth) / 2;
        //var logoPosY = (dc.getHeight() - logowidth) / 5;
        ////Sys.println("logowidth: " + logowidth + " logoHeight: " + logo.getHeight());
        //dc.drawBitmap((dc.getWidth() - logowidth) / 2, logoPosY,logo);

        if (showErr) {
           // Show Error
            frmtScrLines(
                errStr1,
                errStr2,
                errStr3,
                errStr4,
                "",
                "",
                5,
                dc
            );
        }
        else  if (showRefrsh) {
            frmtScrLines(
                WatchUi.loadResource(Rez.Strings.UP),
                "",
                "",
                "",
                "",
                "",
                1,
                dc
            );
        }
        else {
            // Show status page
                if(currPage==1){
                    // curr pwr
                    frmtScrLines(
                        WatchUi.loadResource(Rez.Strings.O1),
                        curr,
                        lastUpdTmLocal,
                        lastUpdDtLocal,
                        "",
                        "",
                        4,
                        dc
                    );
                    glanceName = WatchUi.loadResource(Rez.Strings.O1);
                    glanceVal = curr;
                }
                if(currPage==2){
                    // today
                    frmtScrLines(
                        WatchUi.loadResource(Rez.Strings.O2),
                        today,
                        lastUpdTmLocal,
                        lastUpdDtLocal,
                        "",
                        "",
                        4,
                        dc
                    );
                    glanceName = WatchUi.loadResource(Rez.Strings.O2);
                    glanceVal = today;
                }
                if(currPage==3){
                    // This Month
                    frmtScrLines(
                        WatchUi.loadResource(Rez.Strings.O3),
                        thisMonth,
                        lastUpdTmLocal,
                        lastUpdDtLocal,
                        "",
                        "",
                        4,
                        dc
                    );
                    glanceName = WatchUi.loadResource(Rez.Strings.O3);
                    glanceVal = thisMonth;
                }
                if(currPage==4){
                    // This Year
                    frmtScrLines(
                        WatchUi.loadResource(Rez.Strings.O4),
                        thisYear,
                        lastUpdTmLocal,
                        lastUpdDtLocal,
                        "",
                        "",
                        4,
                        dc
                    );
                    glanceName = WatchUi.loadResource(Rez.Strings.O4);
                    glanceVal = thisYear;
                }
                if(currPage==5){
                    // total
                    frmtScrLines(
                        WatchUi.loadResource(Rez.Strings.O5),
                        total,
                        lastUpdTmLocal,
                        lastUpdDtLocal,
                        "",
                        "",
                        4,
                        dc
                    );
                    glanceName = WatchUi.loadResource(Rez.Strings.O5);
                    glanceVal = total;
                }
                if(currPage==6 && battery == true){
                    // battery
                    frmtScrLines(
                        WatchUi.loadResource(Rez.Strings.O7),
                        batterySoc,
                        lastUpdTmLocal,
                        lastUpdDtLocal,
                        "",
                        "",
                        4,
                        dc
                    );
                    glanceName = WatchUi.loadResource(Rez.Strings.O7);
                    glanceVal = batterySoc;
                }
                if(currPage==6 && battery == false || (currPage==7 && battery == true)){
                    if(battery){
                        frmtScrLines(
                            WatchUi.loadResource(Rez.Strings.O1)+": "+curr,
                            WatchUi.loadResource(Rez.Strings.O2)+": "+today,
                            WatchUi.loadResource(Rez.Strings.O3)+": "+thisMonth,
                            WatchUi.loadResource(Rez.Strings.O4)+": "+thisYear,
                            WatchUi.loadResource(Rez.Strings.O5)+": "+total,
                            WatchUi.loadResource(Rez.Strings.O7)+": "+batterySoc,
                            6,
                            dc
                        );
                    }
                    else{
                        frmtScrLines(
                            WatchUi.loadResource(Rez.Strings.O1)+": "+curr,
                            WatchUi.loadResource(Rez.Strings.O2)+": "+today,
                            WatchUi.loadResource(Rez.Strings.O3)+": "+thisMonth,
                            WatchUi.loadResource(Rez.Strings.O4)+": "+thisYear,
                            WatchUi.loadResource(Rez.Strings.O5)+": "+total,
                            "",
                            5,
                            dc
                        );
                    }
                }

            ////System.println("glanceVal: " + glanceVal + ", glanceName: " + glanceName );

            if(fUpdt == true){
                ////System.println("fUpdt = " + fUpdt);
                makeReq();
            }
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from memory.
    function onHide() {

        // Save data for later
        Application.getApp().setProperty("curr",curr);
        Application.getApp().setProperty("today", today);
        Application.getApp().setProperty("thisMonth", thisMonth);
        Application.getApp().setProperty("thisYear", thisYear);
        Application.getApp().setProperty("total",total);
        Application.getApp().setProperty("lstUpd", lstUpd);
        Application.getApp().setProperty("lastUpdTmLocal", lastUpdTmLocal);
        Application.getApp().setProperty("lastUpdDtLocal", lastUpdDtLocal);
        Application.getApp().setProperty("glanceName", glanceName);
        Application.getApp().setProperty("glanceVal", glanceVal);
        Application.getApp().setProperty("currusr", usr);
        Application.getApp().setProperty("currPwrd", pwrd);
    }
}