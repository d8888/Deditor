chrome.app.runtime.onLaunched.addListener(function() {
  chrome.app.window.create("deditor.html",
    {  frame: "none",
       id: "deditorWinID",
       innerBounds: {
         width: 360,
         height: 300,
         left: 600,
         minWidth: 1,
         minHeight: 1
      }
    }
  );
});
