WebBanking{
  version = 1.0,
  url = "https://estateguru.co",
  description = "Estateguru",
  services= { "Estateguru" },
}

local currency = "EUR" -- fixme: Don't hardcode
local currencyName = "EUR" -- fixme: Don't hardcode
local connection
local apiKey

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Estateguru"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  connection = Connection()
  content, charset, mimeType = connection:request("POST",
  "https://estateguru.co/portal/login/authenticate",
  "username=" .. MM.urlencode(username) .. "&password=" .. MM.urlencode(password),
  "application/x-www-form-urlencoded; charset=UTF-8")

  if string.match(connection:getBaseURL(), 'Sign In or Register') then
      return LoginFailed
  end
end

function ListAccounts (knownAccounts)
  local account = {
    name = "Estateguru",
    accountNumber = "Estateguru",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  content = HTML(connection:get("https://estateguru.co/portal/portfolio/overview?lang=en"))

  account_value = content:xpath('/html/body/section/div/div/div/div[2]/section[1]/div/div/div[3]/div/div[2]/ul/li[1]/div[1]/span[2]'):text()
  account_value = string.gsub(string.gsub(account_value, "€", ""), ",", "")

  invested = content:xpath('//*[@id="collapse0"]/ul/li[1]/div/span[2]'):text()
  invested = string.gsub(string.gsub(invested, "€", ""), ",", "")

  print("account value: " .. account_value)
  print("invested: " .. invested)

  local security = {
    name = "Account Summary",
    price = account_value,
    purchasePrice = invested,
    quantity = 1,
    curreny = nil,
  }

  table.insert(s, security)

  return {securities = s}
end

function EndSession ()
end
