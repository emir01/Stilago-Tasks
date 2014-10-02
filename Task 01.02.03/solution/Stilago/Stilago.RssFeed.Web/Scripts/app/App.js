/*
 * Defines the main App Module that actually runs all RSS Feed App initialization.
 * 
 * No need to run/organize any other modules.
 */
(function (stilagoRss, $) {

    var stilagoRssApp = (function () {
        
        /*
         * Propertioes
         */

        var rssFeedUrl = "http://www.rtvslo.si/novice/rss/";
        
        var initialCount = 20;

        /*
         * Public initialization and event setup
         * ========================================================
         */
        
        var init = function () {
            setupEvents();
            loadFeed();
        };

        var setupEvents = function() {
            $("#btn-refresh-news").on("click", loadFeed);
        };
        
        /*
         * Private functionality
         * ========================================================
         */

        var loadFeed = function() {
            $("#feed").FeedEk({
                FeedUrl: rssFeedUrl,
                MaxCount: initialCount,
                DateFormat: 'lll',
                DateFormatLang: "sl-SI"
            });
        };

        /*
         * Rmp
         * ========================================================
         */
        
        return {
            InitStilagoRssApp: init
        };
    })();

    // namespace the Module App. Anything can be used here. Our aproach so far has been
    // to use a custom namespacing solution. 
    // here just add it to the global object. StilagoRSS is the only global object where all custom code goes into.

    stilagoRss.App = stilagoRssApp;

})(window.StilagoRSS = window.StilagoRSS || {}, jQuery);