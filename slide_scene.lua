--[[
--[[
%% properties
%% events
%% globals
--]]
--[[
SLIDE Api
Author: Gabor de Wit
Contributors: Frank van Tussenbroek, Jim van Dok
Github referece: https://github.com/gabordewit/SLIDE

Versions
1.0 Initial release
1.0.1 Improved datamodel to limit amount global variables
1.0.2 Fix crashes during dry-run, simplified single slide creation in virtual device.
1.0.3 Improved global variable handling and error handling, improved instructions, additional icons.
1.0.4 Introduced handling on api status codes, improved logger for less-verbose mode.

ToDo
- request realtime status of current slide to be reflected in Virtual device
- set holiday modes
- start calibration of device
--]]
--set environment variables that can be used to switch logger on/off.
debug = true
dryrun = true
testIndividualSlide = false
slideIdToTest = "192.168.1.163"
slideCommandToTest = "close"

function debuglogger(contentToLog, loglevel)
    if debug == true then
        fibaro:debug(tostring(contentToLog))
    elseif debug == false and loglevel == "info" then
        fibaro:debug(" |INFO| " .. tostring(contentToLog))
    else
        return
    end
end

-- set userdata for SLIDE api including URL and include sceneID.
useCloud = false
userName = ""
password = ""
slideApiUrl = "https://api.goslide.io/api"

--[[ set global userdata variable for storing tokens. for dryrun purposes it's possible to take the output and store here.
Includes refresh_token that is currently not used yet.
--]]
authData = {
    ["access_token"] = "",
    ["token_type"] = "Bearer",
    ["expires_at"] = "2020-03-10 09:48:38",
    ["expires_in"] = "2592000",
    ["refresh_token"] = "",
    ["household_id"] = "15"
}

--[[ set global slides variable for storing slide information, including example data model
--]]
slides = {
    --[[
    ["slide1"] = {
        ["id"] = "1234",
        ["device_name"] = "superslide",
        ["device_id"] = "abc",
        ["zone_id"] = "kitchen",
        ["touch_go"] = false,
        ["device_info"] = {
            ["pos"] = 0.09
        }
    },
    ["slide2"] = {
        ["id"] = "5678",
        ["device_name"] = "superslider",
        ["device_id"] = "def",
        ["zone_id"] = "dining",
        ["touch_go"] = false,
        ["device_info"] = {
            ["pos"] = 0.09
        }
    },
    ["slidesInHousehold"] = 2,
    --]]
}

--function to set correct URL

--[[ In orde to use the SLIDE api, a user needs to be authenticated with the platform. The data used needs to be provisioned
above.
      --]]
function getToken(refreshHousehold)
    debuglogger("Calling getToken function for access", "info")
    -- setup variables to include in the call - include json encoding
    local requestStr = { email = userName, password = password }
    local requestStringToJSON = json.encode(requestStr)
    debuglogger("RequestStr:" .. requestStringToJSON)
    local selfhttp = net.HTTPClient()
    local endPoint = "/auth/login"
    local headers = {
        ["content-type"] = "application/json",
        ["X-Requested-With"] = "XMLHttpRequest"
    }
    local url = slideApiUrl .. endPoint
    debuglogger(url)
    -- The actual request
    selfhttp:request(
        url,
        {
            options = {
                headers = headers,
                method = "POST",
                data = requestStringToJSON
            },
            success = function(resp)
                -- Check for response coming from API
                debuglogger("Response code: " .. resp.status, "info")
                debuglogger("Response content: " .. resp.data)

                if resp.status == 200 then
                    decodedTokenResponse = json.decode(resp.data)

                    -- Store retrieved JSON response in a map
                    -- ToDo only try to store on
                    authData.access_token = decodedTokenResponse.access_token
                    authData.token_type = decodedTokenResponse.token_type
                    authData.expires_at = decodedTokenResponse.expires_at
                    authData.expires_in = decodedTokenResponse.expires_in
                    authData.household_id = decodedTokenResponse.household_id

                    -- store json value in global token (if this is not a dryrun)
                    -- set a small timer to ensure the data is properly stored and propagated
                    if dryrun == false then
                        fibaro:setGlobal("Slidetoken", json.encode(authData))
                    else
                        debuglogger("Performing dry-run, not storing tokens", "info")
                    end

                    debuglogger("Token needed for upcoming request: " .. authData.access_token, "info")
                    -- Loop over new values, evaluate if they are stored correctly
                    for tokenKey, value in pairs(authData) do
                        debuglogger("Authdata key: " .. tokenKey .. ", stored value: " .. value)
                    end

                    -- to speed up onboarding in Fibaro we're also getting household information already.
                    -- SLIDES will be provisioned in the virtual device so set that up first
                    if refreshHousehold then
                        debuglogger("Refresh of household triggered", "info")
                        fibaro:sleep(1000)
                        getHouseholdInfo()
                    else
                        debuglogger("Not refreshing household", "info")
                    end
                else
                    debuglogger("Request cancelled due to incorrect status on request", "info")
                    return
                end
            end,
            error = function(err)
                -- response = json.decode(err)
                fibaro:debug("error: " .. err)
            end
        }
    )
end

-- function to retrieve the correct tokentype, checked every time a function is called to prevent cached data.
function getFibaroToken()
    debuglogger("Calling FibaroToken function to get the right Token for Slide", "info")
    -- decoded global value for slidetoken
    if dryrun then
        fibaro:debug("Dry-run active, using data from local variable instead of global Slidetoken variable", "info")
        decodedGlobalToken = authData
        return decodedGlobalToken
    elseif dryrun == false and fibaro:getGlobalValue("Slidetoken") == "NaN" then
        fibaro:debug("Warning, token data is corrupt recreate Slidetoken variable or set to 0", "info")
        return
    elseif
        dryrun == false and fibaro:getGlobalValue("Slidetoken") ~= nil and fibaro:getGlobalValue("Slidetoken") ~= "0" and
        fibaro:getGlobalValue("Slidetoken") ~= "NaN"
    then
        fibaro:debug("Retrieving global Fibaro variable Slidetoken to run authentication", "info")
        retrieveToken = fibaro:getGlobalValue("Slidetoken")
        decodedGlobalToken = json.decode(retrieveToken)
        return decodedGlobalToken
    else
        fibaro:debug("Warning, global value for Slidetoken is not set or 0", "info")
        return
    end
end

-- function to set the json body
function setRequestPayload(command)
    if command == "open" then
        requestStr = { pos = 0 }
    elseif command == "close" then
        requestStr = { pos = 1 }
    else
        requestStr = { pos = command }
    end
    local requestStringToJSON = json.encode(requestStr)
    return requestStringToJSON
end

--[[ This is one of the most important API's, as this API will allow you to set the technical id's of the  slides to use
in other API's. The data is store in a global variable. The data  used here is dependent on the values of the block above:
if dryrun is true it uses local variables from getToken, otherwise it retrieves data from global variables.
      --]]
function getHouseholdInfo()
    debuglogger("Calling householdinfo for household parameters", "info")
    decodedGlobalToken = getFibaroToken()
    if decodedGlobalToken ~= nil then
        local selfhttp = net.HTTPClient()
        local endPoint = "/slides/overview"
        local headers = {
            ["content-type"] = "application/json",
            ["X-Requested-With"] = "XMLHttpRequest",
            ["Authorization"] = "Bearer " .. decodedGlobalToken.access_token
        }
        local url = slideApiUrl .. endPoint
        debuglogger(url)
        selfhttp:request(
            url,
            {
                options = {
                    headers = headers,
                    method = "GET"
                },
                success = function(resp)
                    debuglogger("Response code on household call: " .. resp.status, "info")
                    debuglogger("Response content on household call: " .. resp.data)

                    if resp.status == 200 then
                        decodedHouseholdResponse = json.decode(resp.data)
                        for slideCount = 1, #decodedHouseholdResponse.slides do
                            debuglogger(
                                "Looping over slides in api response, loop sequence: " ..
                                slideCount .. " ID found: " .. decodedHouseholdResponse.slides[slideCount].id,
                                "info"
                            )

                            dataInHousehold = {
                                ["id"] = decodedHouseholdResponse.slides[slideCount].id,
                                ["device_name"] = decodedHouseholdResponse.slides[slideCount].device_name,
                                ["device_id"] = decodedHouseholdResponse.slides[slideCount].device_id,
                                ["zone_id"] = decodedHouseholdResponse.slides[slideCount].zone_id,
                                ["touch_go"] = decodedHouseholdResponse.slides[slideCount].touch_go,
                                ["device_info"] = decodedHouseholdResponse.slides[slideCount].device_info
                            }

                            -- fill the datastore with relevant data, this includes individual slides and total number of slides.
                            slideNumberID = "slide" .. slideCount
                            slides["slidesInHousehold"] = slideCount
                            slides[slideNumberID] = dataInHousehold
                        end
                    else
                        debuglogger("Request cancelled due to incorrect status on request", "info")
                        return
                    end
                    --[[ store json values in global token, this needs to be set  before using these api's otherwise
                data is not available.--]]
                    if dryrun == false then
                        -- store slide data in a global variable - needs to be created first
                        fibaro:setGlobal("Slides", json.encode(slides))
                    elseif dryrun and testIndividualSlide then
                        debuglogger("Testing individual slide  in dryrun mode: " .. slideIdToTest, "info")
                        setSlide(slideIdToTest, slideCommandToTest)
                    else
                        debuglogger("Performing dry-run, not storing tokens or setting slides", "info")
                    end

                    --[[ list the amount of slides in the house and list the individual slides --]]
                    debuglogger("Number of slides in household: " .. slides["slidesInHousehold"], "info")
                    for slideData, value in pairs(slides) do
                        debuglogger("Data key to be stored in memory: " .. slideData .. " value: ")
                        debuglogger(value)
                    end
                end,
                error = function(err)
                    --response = json.decode(err)
                    fibaro:debug("error: " .. err)
                end
            }
        )
    else
        fibaro:debug("No token available, please check logs")
    end
end

--[[ In orde to set an individual SLIDE , we can send a request to an individual slide
the api already supports the setting of anything other than close and open but this is open for VFID to use.
      --]]
function setSlide(slideId, command)
    debuglogger("Calling setslide for specific slide", "info")
    local selfhttp = net.HTTPClient()
    local requestStr = { pos = 1 }
    jsonPayload = setRequestPayload(command)

    if useCloud then
        local endPoint = "/slide/" .. slideId .. "/position"
        debuglogger("Request send to slide is: " .. jsonPayload, "info")
        decodedGlobalToken = getFibaroToken()
        if decodedGlobalToken ~= nil then
            local headers = {
                ["content-type"] = "application/json",
                ["X-Requested-With"] = "XMLHttpRequest",
                ["Authorization"] = "Bearer " .. decodedGlobalToken.access_token
            }
            local url = slideApiUrl .. endPoint
            debuglogger(url)
            selfhttp:request(
                url,
                {
                    options = {
                        headers = headers,
                        method = "POST",
                        data = jsonPayload
                    },
                    success = function(resp)
                        debuglogger("Response code on set slide call: " .. resp.status, "info")
                        debuglogger("Response data on set slide call: " .. resp.data)
                        decodedSlideResponse = json.decode(resp.data)
                    end,
                    error = function(err)
                        -- response = json.decode(err)
                        fibaro:debug("error: " .. err)
                    end
                }
            )
        else
            fibaro:debug("No token available, please check logs")
        end
    else
        local localEndpoint = "https://" .. slideId .. "/rpc/Slide.SetPos"
        debuglogger(localEndpoint)
        selfhttp:request(
            localEndpoint,
            {
                options = {
                    method = "POST",
                    data = jsonPayload
                },
                success = function(resp)
                    debuglogger("Response code on set slide call: " .. resp.status, "info")
                    debuglogger("Response data on set slide call: " .. resp.data)
                    decodedSlideResponse = json.decode(resp.data)
                end,
                error = function(err)
                    -- response = json.decode(err)
                    fibaro:debug("error: " .. err)
                end
            }
        )
    end
end

--[[ If needed the information of an individual slide can be called (e.g. to see if the slide is open etc. For use in
future operations.
      --]]
function getSlideInfo(slideId)
    debuglogger("Calling slide info for slide parameters", "info")
    local selfhttp = net.HTTPClient()
    if useCloud then
        local endPoint = "/slides/" .. slideId
        decodedGlobalToken = getFibaroToken()
        if decodedGlobalToken ~= nil then
            local headers = {
                ["content-type"] = "application/json",
                ["X-Requested-With"] = "XMLHttpRequest",
                ["Authorization"] = "Bearer " .. decodedGlobalToken.access_token
            }
            local url = slideApiUrl .. endPoint
            debuglogger(url)
            selfhttp:request(
                url,
                {
                    options = {
                        headers = headers,
                        method = "GET"
                    },
                    success = function(resp)
                        debuglogger("Response code on slide info call: " .. resp.status)
                        debuglogger("Response data on slide info call: " .. resp.data)
                        decodedSlideResponse = json.decode(resp.data)
                    end,
                    error = function(err)
                        -- response = json.decode(err)
                        fibaro:debug("error: " .. err)
                    end
                }
            )
        else
            fibaro:debug("No token available, please check logs")
        end
    else
        local localEndpoint = "https://" .. slideId .. "/rpc/Slide.GetInfo"
        debuglogger(localEndpoint)
        selfhttp:request(
            localEndpoint,
            {
                options = {
                    method = "POST"
                },
                success = function(resp)
                    debuglogger("Response code on set slide call: " .. resp.status, "info")
                    debuglogger("Response data on set slide call: " .. resp.data)
                    decodedSlideResponse = json.decode(resp.data)
                end,
                error = function(err)
                    -- response = json.decode(err)
                    fibaro:debug("error: " .. err)
                end
            }
        )
    end
end

--[[ The scene uses a input command mechanism as if it was an API. Using Fibaro's method of allowing virtual devices to
call a scene with input parameters, the scene van be triggered from virtual devices.
      --]]
args = fibaro:args()
if dryrun and useCloud then
    debuglogger("Request for cloud dry run received", "info")
    refreshHousehold = true
    getToken(refreshHousehold)
elseif dryrun and useCloud == false then
    debuglogger("Request for localdry run received", "info")
    setSlide(slideIdToTest, slideCommandToTest)
elseif args == nil then
    debuglogger("No commands or dry run request received", "info")
elseif args ~= nil and args[1] == "requestNewToken" then
    request = args[1]
    refreshHousehold = args[2]
    debuglogger("Request " .. request, "info")
    getToken(refreshHousehold)
elseif args ~= nil and args[1] == "controlSlide" then
    request = args[1]
    slideToCommand = args[2]
    slideCommand = args[3]
    debuglogger("Request " .. request, "info")
    debuglogger("slideToCommand " .. slideToCommand, "info")
    debuglogger("slideCommand " .. slideCommand, "info")
    if useCloud then
        -- Check for existence of a token to be able to make calls
        decodedGlobalToken = getFibaroToken()
        if
            (decodedGlobalToken ~= nil and decodedGlobalToken.access_token ~= "" and
                os.date("%Y-%m-%d %X") < decodedGlobalToken.expires_at)
        then
            setSlide(slideToCommand, slideCommand)
            debuglogger("Token found and not expired, expiry date: " .. authData.expires_at, "info")
        else
            debuglogger(
                "No valid token found (not present or expired), triggering function to retrieve a new token",
                "info"
            )
            debuglogger(
                "The action you've intended to execute might have failed, please try again after token refresh",
                "info"
            )
            refreshHousehold = true
            getToken(refreshHousehold)
        end
    else
        setSlide(slideToCommand, slideCommand)
    end
elseif args ~= nil and args[1] == "refreshHousehold" then
    request = args[1]
    debuglogger("Request " .. request, "info")
    -- Check for existence of a token to be able to make calls
    decodedGlobalToken = getFibaroToken()
    if
        (decodedGlobalToken ~= nil and decodedGlobalToken.access_token ~= "" and
            os.date("%Y-%m-%d %X") < decodedGlobalToken.expires_at)
    then
        getHouseholdInfo()
    else
        debuglogger(
            "No valid token found (not present or expired), triggering function to retrieve a new token and refresh household",
            "info"
        )
        refreshHousehold = true
        getToken(refreshHousehold)
    end
else
    debuglogger("Unknown error occurred, please check configuration syntax and virtual device configuration", "info")
end
