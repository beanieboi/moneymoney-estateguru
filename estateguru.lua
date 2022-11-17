WebBanking {
    version = 1.1,
    url = "https://estateguru.co",
    description = "Estateguru",
    services = {"Estateguru"}
}

local currency = "EUR" -- fixme: Don't hardcode
local currencyName = "EUR" -- fixme: Don't hardcode
local connection

local credentialCache = {}

function SupportsBank(protocol, bankCode)
    return protocol == ProtocolWebBanking and bankCode == "Estateguru"
end

local function requestJSON(method, url, data)
    headers = {
        accept = "application/json"
    }

    content, charset, mimeType = connection:request(method, url, JSON():set(data):json(), "application/json", headers)

    return JSON(content):dictionary()
end

local function request2FA(username, password)
    data = {
        username = username,
        password = password
    }

    response = requestJSON("POST", "https://account.estateguru.co/api/login/2fa/resend", data)

    if response['status'] ~= 200 then
        return LoginFailed
    end

    credentialCache = {
        username = username,
        password = password
    }

    return {
        title = "Two-step authentication",
        challenge = "We sent a verification code to the phone number attached to your account. Please enter it here to log in.",
        label = "SMS-Code"
    }

end

local function authenticatePass(username, password)
    data = {
        username = username,
        password = password,
        rememberMe = false
    }

    response = requestJSON("POST", "https://account.estateguru.co/api/login", data)

    if response['status'] ~= 200 then
        return LoginFailed
    end

    if response['twoFactorAuthenticationMethods'][1] ~= "SMS" then
        return LoginFailed
    end

    return request2FA(username, password)
end

local function switchAccount()

    headers = {
        accept = "application/json"
    }

    content, charset, mimeType = connection:request("GET", "https://account.estateguru.co/api/user/info?username=" ..
        MM.urlencode(credentialCache.username), "", headers)

    response = JSON(content):dictionary()

    content, charset, mimeType = connection:request("POST", "https://account.estateguru.co/api/account/" ..
        response['defaultAccountId'] .. "/switch", "application/x-www-form-urlencoded; charset=UTF-8", headers)

    response = JSON(content):dictionary()

    if response['status'] ~= 200 then
        return "Could not switch account."
    end

    if response['token'] == '' then
        return "No token token received. Is this a bug?"
    end

    return nil
end

local function authenticate2FA(username, password, code)
    data = {
        username = username,
        password = password,
        twoFactorOtp = code,
        rememberMe = false
    }

    response = requestJSON("POST", "https://account.estateguru.co/api/login", data)

    -- flush credentials password
    credentialCache.password = nil

    if response['status'] ~= 200 then
        return "Incorrect 2FA Code."
    end

    if response['token'] == '' then
        return "No token token received. Is this a bug?"
    end

    return switchAccount()
end

function InitializeSession2(protocol, bankCode, step, credentials, interactive)
    if step == 1 then
        connection = Connection()
        -- Enforce english language
        connection:setCookie("lng=en-US; path=/")
        connection:setCookie("portal.lang=en; path=/")
        connection.language = "en-gb"
        return authenticatePass(credentials[1], credentials[2])
    elseif step == 2 then
        return authenticate2FA(credentialCache.username, credentialCache.password, credentials[1])
    end
end

function ListAccounts(knownAccounts)
    local account = {
        name = "Estateguru",
        accountNumber = "Estateguru",
        currency = currency,
        portfolio = true,
        type = "AccountTypePortfolio"
    }

    return {account}
end

function RefreshAccount(account, since)
    local s = {}
    content = HTML(connection:get("https://app.estateguru.co/portfolio/overview?lang=en"))

    account_value = content:xpath(
        '/html/body/section/div/div/div/div/section[1]/div/div/div[3]/div/div[2]/ul/li[1]/div[1]/span[2]'):text()
    account_value = string.gsub(string.gsub(account_value, "€", ""), ",", "")

    invested = content:xpath(
        '/html/body/section/div/div/div/div/section[1]/div/div/div[3]/div/div[2]/ul/li[2]/div[1]/span[2]'):text()
    invested = string.gsub(string.gsub(string.gsub(string.gsub(invested, "€", ""), ",", ""), "-", ""), "%s+", "")

    print("account value: " .. account_value)
    print("invested: " .. invested)

    local security = {
        name = "Account Summary",
        price = account_value,
        purchasePrice = invested,
        quantity = 1,
        curreny = nil
    }

    table.insert(s, security)

    return {
        securities = s
    }
end

function EndSession()
    content, charset, mimeType = connection:request("POST", "https://account.estateguru.co/api/logout",
        "application/x-www-form-urlencoded; charset=UTF-8", headers)

    return nil
end
