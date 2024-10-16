local LrHttp = import 'LrHttp'
local LrSocket = import 'LrSocket'
local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'

-- サーバーを起動する関数
local function startHttpServer()
    local serverSocket = LrSocket.bind {
        functionContext = functionContext,
        pluginContext = pluginContext,
        port = 8080, -- 使用するポート番号
        mode = "receive",
        
        onConnecting = function(socket, port)
            LrDialogs.message("Server started", "Listening on port: " .. port)
        end,

        onMessage = function(socket, message)
            -- リクエストが来たときの処理
            if message then
                -- 認可コードを取得
                local code = message:match("code=([^&%s]+)")
                if code then
                    LrDialogs.message("Authorization Code", "Received code: " .. code)
                    
                    -- 認可コードを受け取ったのでHTTPレスポンスを返す
                    local response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\nAuthorization code received! You can close this window."
                    socket:send(response)

                    -- アクセストークンを取得するために非同期でタスクを実行
                    LrTasks.startAsyncTask(function()
                        local tokenEndpoint = "https://authorization-server.com/token"
                        local client_id = "YOUR_CLIENT_ID"
                        local client_secret = "YOUR_CLIENT_SECRET"
                        local redirect_uri = "http://localhost:8080/callback"

                        local tokenResponse, headers = LrHttp.post(tokenEndpoint, {
                            client_id = client_id,
                            client_secret = client_secret,
                            code = code,
                            grant_type = "authorization_code",
                            redirect_uri = redirect_uri
                        })

                        if tokenResponse then
                            LrDialogs.message("Access Token", "Response: " .. tokenResponse)
                        else
                            LrDialogs.message("Error", "Failed to obtain access token")
                        end
                    end)

                else
                    -- 認可コードが見つからない場合、400エラーを返す
                    local response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/html\r\n\r\nAuthorization code not found."
                    socket:send(response)
                end
            end
        end,

        onClosed = function(socket)
            LrDialogs.message("Server closed", "Server has been stopped.")
        end,
    }
end

-- OAuthの認可リクエストをブラウザで開く
local function openBrowserForOAuth()
    local client_id = 'YOUR_CLIENT_ID'
    local redirect_uri = 'http://localhost:8080/callback'
    local authorization_endpoint = 'https://authorization-server.com/auth'
    
    -- 認可リクエストのパラメータ
    local params = {
        client_id = client_id,
        redirect_uri = redirect_uri,
        response_type = 'code',
        scope = 'email profile',
        state = 'random_state_string'
    }

    -- 認可エンドポイントのURLを作成
    local authorization_url = authorization_endpoint .. "?" .. LrHttp.encodeParameters(params)

    -- デフォルトブラウザでURLを開く
    LrHttp.openUrlInBrowser(authorization_url)
end

-- メインの処理
LrTasks.startAsyncTask(function()
    -- サーバーを開始
    startHttpServer()
    
    -- 認可リクエストをブラウザで送信
    openBrowserForOAuth()
end)
