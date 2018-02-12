
NPL.load("(gl)script/ide/System/os/HttpClient.lua")

describe(
    "http client",
    function ()
        context(
            "#http",
            function ()
                it(
                    "should return the content of a given url",
                    function ()
                        local code, msg, data = HttpClient({
                            url = "http://keepwork.com"
                        })
                        assert_equal(code, 200)
                    end
                )
                it(
                    "should return the content of a given url",
                    function ()
                        local code, msg, data = HttpClient:http({
                            url = "http://keepwork.com"
                        })
                        assert_equal(code, 200)
                    end
                )
            end
        )
        context(
            "#get",
            function()
                it(
                    "should return the content of a given url",
                    function ()
                        local code, msg, data = HttpClient:get("http://keepwork.com")
                        assert_equal(code, 200)
                    end
                )
                -- it(
                --     "should merge params into url",
                --     function()
                --         local code, msg, data = HttpClient:get("http://keepwork.com")
                --         assert_equal(code, 200)
                --     end
                -- )
            end
        )
        -- context(
        --     "#post",
        --     function()
        --         it(
        --             "should return the content of a given url",
        --             function ()
        --                 local code, msg, data = HttpClient:get("http://keepwork.com")
        --                 assert_equal(code, 200)
        --             end
        --         )
        --     end
        -- )
    end
)
