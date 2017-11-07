var EMPopup = {

  /**
   * Extension background page.
   */
  background: chrome.extension.getBackgroundPage(),


  /**
   * Etymology search URL.
   */
  queryUrlPrefix: "http://www.etymonline.com/index.php?search=",


  /**
   * Populates the DOM.
   *
   * @public
   */
  populateDom: function() {
    var mainDiv = document.getElementById("main-div");

    mainDiv.innerHTML=
      '<h6 class="section-header">Search ' +
        '<a href="http://www.etymonline.com/" tabindex=-1>' +
          'Online Etymology Dictonary</a>' +
      '</h6>' +
      // Input box
      '<div class="">' +
        '<input class="u-full-width" type="text" ' +
          'placeholder="Enter word and hit Enter" ' +
          'id="search-box"/>' +
        '<p class="hide" id="last-search"></p>' +
      '</div>' +
      // Results area
      '<div class="hide" id="error-flash">' +
      '</div>' +
      '<div class="hide" id="results">' +
        '<div class = "row" id="result-row">' +
        '</div>' +
      '</div>';
    var inputEl = document.getElementById("search-box");
    inputEl.onkeypress=this.searchAndRender;
    inputEl.oninput = this.onInputChanged;
    inputEl.focus();

    this.displayLastSearch();
  },


  /**
   * Searches for the query when enter key is pressed and renders the
   * results.
   */
  searchAndRender: function(e) {
    if(e.which == 13) {
      var inputEl = document.getElementById("search-box");
      document.getElementById("results").className = "hide";
      var query = inputEl.value;
      // Enter key code is 13.
      inputEl.select();
      if (query.split(/\s+/).length > 1) {
        EMPopup.flashError("Enter only one word");
      } else {
        query = query.trim();
        EMPopup.displayLastSearch();
        EMPopup.background.EMBg.lastSearch = query;

        EMPopup.sendXhr(query).then(function(response) {
          EMPopup.renderResponse(response);
        }, function() {
          EMPopup.flashError("Failed to get results.");
        });
      }
    }
  },


  /**
   * Displays the last search query below the search box.
   */
  displayLastSearch: function() {
    var lastSearch = EMPopup.background.EMBg.lastSearch;
    if (lastSearch) {
      var el = document.getElementById('last-search');
      el.className = "visible";
      el.innerHTML = "Previous Query: " + lastSearch;
    }
  },

  /**
   * Event handler for when input changes. More specifically we check if there
   * is no input, in which case we hide any stale errors or results.
   */
  onInputChanged: function(e) {
    // Hide error message if search box is empty.
    var inputEl = document.getElementById("search-box");
    if (!inputEl.value) {
      document.getElementById("error-flash").className = "hide";
      document.getElementById("results").className = "hide";
    }
  },


  /**
   * Displays an error message above the results.
   */
  flashError: function(message) {
    var errorDiv = document.getElementById('error-flash');
    errorDiv.innerHTML = message;
    errorDiv.className = "flash";
  },


  /**
   * Returns promise to send an xhr. It is resolved with HTML document.
   */
  sendXhr: function(query) {
    return new Promise(function(resolve, reject) {
      var http = new XMLHttpRequest();
      var url = EMPopup.queryUrlPrefix + query;
      http.responseType = "document";
      http.open("GET", url, true);

      http.onload = function() {
        console.log(this.responseXML);
        resolve(this.responseXML);
      }
      http.onerror = function() {
        reject(Error("Network Error"));
      };
      http.send(query);
    });
  },


  /**
   * Parses the returned document to either show error or results.
   */
  renderResponse: function(response) {
    var dls = response.getElementsByTagName("dl");
    if (dls === null || typeof dls === "undefined" || dls.length === 0) {
      console.log("No results!");
      EMPopup.flashError("No results!");
      return;
    }
    var dl = dls[0];
    // Display top result
    var word = dl.children[0].children[0].innerHTML;
    var description = dl.children[1].innerHTML;
    document.getElementById("result-row").innerHTML = word + " " + description;
    document.getElementById("results").className = "visible";
  },

};


// This should really be done with the event registration API? The alternate
// to the following.
document.addEventListener('DOMContentLoaded', function () {
  EMPopup.populateDom();
});
