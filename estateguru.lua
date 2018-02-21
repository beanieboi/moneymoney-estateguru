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
  "https://estateguru.co/j_spring_security_check",
  "j_username=" .. username .. "&j_password=" .. password,
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
  content = HTML(connection:get("https://estateguru.co/investment/main"))

  available = content:xpath('/html/body/div[1]/div[2]/div[3]/div/h2/div/div/div/div[1]/h2'):text()
  available = string.gsub(string.gsub(available, "€", ""), ",", ".")

  earnings = content:xpath('/html/body/div[1]/div[2]/div[3]/div/h2/div/div/div/div[2]/h2'):text()
  earnings = string.gsub(string.gsub(earnings, "€", ""), ",", ".")

  invested = content:xpath('/html/body/div[1]/div[2]/div[3]/div/h2/div/div/div/div[3]/h2'):text()
  invested = string.gsub(string.gsub(invested, "€", ""), ",", ".")

  local security = {
    name = "Account Summary",
    price = invested + available,
    purchasePrice = invested + available - earnings,
    quantity = 1,
    curreny = nil,
  }

  table.insert(s, security)

  return {securities = s}
end

function EndSession ()
end
