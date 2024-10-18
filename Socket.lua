local LrSocket = import 'LrSocket'
local LrTasks = import 'LrTasks'

LrTasks.startAsyncTask(function()
    local host = "api.example.com"
    local port = 80 -- HTTPの標準ポート

    -- クエリーパラメーターを設定
    local queryParams = "?key1=value1&key2=value2"
    local path = "/data" .. queryParams

    -- ソケットを作成
    local socket = LrSocket.bind {
        function(socket, error)
            if error then
                print("Socket Error:", error)
                return
            end

            -- 接続
            socket:connect(host, port, 5) -- タイムアウトを5秒に設定

            -- GETリクエストの構築
            local request = "GET " .. path .. " HTTP/1.1\r\n" ..
                            "Host: " .. host .. "\r\n" ..
                            "Connection: close\r\n" ..
                            "\r\n"

            -- リクエストを送信
            socket:send(request)

            -- レスポンスを受信
            local response = ""
            socket:receive(0, function(data)
                if data then
                    response = response .. data
                else
                    -- データの受信が完了したらレスポンスを表示
                    print("Response:", response)
                    socket:close()
                end
            end)
        end
    }
end)