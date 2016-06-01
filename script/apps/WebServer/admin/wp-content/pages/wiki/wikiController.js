/**
Title: wiki rendering
Author: LiXizhi
Date: 2016.5.30
*/

/**
* siteName, pageName, rootUrl should be filled on server side
*/
WikiPage = {
    ShowIndexBar: function (bShow) {
        if (bShow) {
            $("#content").addClass("col-md-9");
            $("#indexbar").show();
        }
        else {
            $("#indexbar").hide();
            $("#content").removeClass("col-md-9");
            $("#content").addClass("col-md-12");
        }
    },
    // preprocess to support wiki words like [[a|b]] and flash video [video](a.swf)
    preprocessMarkdown: function (data) {
        if (!data) {
            return
        }
        var newstr = data;
        var siteName = WikiPage.getSiteName();
        // [[a|b]] -->[a](b), and replace with wiki
        function replacer_1(match, p1, p2, offset, string) {
            return "[" + p1 + "](" + p2 + ")";
        }
        var re = /\[\[([^\|\]]+)\|([^\|\]]+)\]\]/g;
        newstr = newstr.replace(re, replacer_1);

        // [[a]] -->[a](a)
        function replacer_12(match, p1, offset, string) {
            var wiki = "/" + siteName + "/" + p1;
            var s = "[" + p1 + "](" + wiki + ")";
            return s;
        }
        var re = /\[\[([^\|\]]+)\]\]/g;
        newstr = newstr.replace(re, replacer_12);

        // [video](*.swf.*) --> <embed />
        function replace_video(match, p1, url, offset, string) {
            var s = "<span class='flashplayer'><embed src='" + url + "' type='application/x-shockwave-flash' width='750' height='540'></embed></span>"
            return s;
        }
        re = /\[([^\|\]]+)\]\(([^)]*\.swf[^)]*)\)/g;
        newstr = newstr.replace(re, replace_video);

        // []() --> []() with wikiword in our domain
        function replacer_2(match, p1, p2, offset, string) {
            var wiki = "/" + siteName + "/" + p2;
            var s = "[" + p1 + "](" + wiki + ")";
            return s;
        }
        re = /\[([^\|\]]+)\]\(([^\/\|\]\n]+)\)/g;
        newstr = newstr.replace(re, replacer_2);

        return newstr;
    },
    getSiteName: function () {
        if (!WikiPage.siteName)
            WikiPage.siteName = (window.location.pathname.split("/")[1] || "Paracraft");
        return WikiPage.siteName;
    },
    getPageName: function () {
        if (!WikiPage.pageName)
            WikiPage.pageName = window.location.pathname.split("/")[2] || "Home";
        return WikiPage.pageName;
    },
    getRootRawUrl: function () {
        // default to `SiteName/wiki` project
        if (!WikiPage.rootUrl)
            WikiPage.rootUrl = ("https://raw.githubusercontent.com/wiki/" + WikiPage.getSiteName() + "/wiki/");
        return WikiPage.rootUrl;
    },
    getPageUrl: function () {
        if (!WikiPage.pageUrl)
            WikiPage.pageUrl = WikiPage.getRootRawUrl() + WikiPage.getPageName() + ".md";
        return WikiPage.pageUrl;
    },
    getSidebarUrl: function () {
        if (!WikiPage.sidebarUrl)
            WikiPage.sidebarUrl = WikiPage.getRootRawUrl() + "_Sidebar.md";
        return WikiPage.sidebarUrl;
    }
};

// markdown controller module
angular.module('MyApp').controller('MarkdownController', function ($scope, $http) {
    var md = window.markdownit({
        highlight: function (str, lang) {
            if (lang && window.hljs.getLanguage(lang)) {
                try {
                    return hljs.highlight(lang, str, true).value;
                } catch (__) { }
            }
            return ''; // use external default escaping
        }
    });
    var idPage = "#wikipage";
    var idSidebar = "#wikisidebar";
    $scope.ShowSideBar = function (bShow) {
        if (bShow) {
            $(idPage).addClass("col-md-8");
            $(idSidebar).show();
        }
        else {
            $(idSidebar).hide();
            $(idPage).removeClass("col-md-8");
            $(idPage).addClass("col-md-12");
        }
    };
    $scope.load = function (url, container_name) {
        $http({
            method: 'GET',
            url: url,
            headers: {
                'Authorization': undefined,
            }, // remove auth header for this request
            skipAuthorization: true, // this is added by our satellizer module, so disable it for cross site requests.
            transformResponse: [function (data) {
                return data; // never transform to json, return as it is
            }],
        }).then(function successCallback(response) {
            if (response.status == 200) {
                var s = WikiPage.preprocessMarkdown(response.data);
                s = md.render(s);
                $(container_name).html(s);
            } else {
                $(container_name).html("<p>error</p>");
            }
            if (url == WikiPage.getSidebarUrl())
                $scope.ShowSideBar(true);
        }, function errorCallback(response) {
            if (response.status == 404) {
                if (url == WikiPage.getSidebarUrl())
                    $scope.ShowSideBar(false);
                else
                    $(container_name).html("<p>网页不存在</p>");
            }
            else
                $(container_name).html("<p>load failed.</p>");
        });
    }
    $scope.load(WikiPage.getPageUrl(), idPage);
    $scope.load(WikiPage.getSidebarUrl(), idSidebar);
    $scope.load("https://raw.githubusercontent.com/wiki/NPLPackages/wiki/index.md", "#indexbar");
})