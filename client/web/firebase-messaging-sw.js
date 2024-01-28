importScripts("https://www.gstatic.com/firebasejs/8.6.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.6.1/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyBBLw1OsrlY6ODXA9MyVLxRX3v51GHOwss",
    authDomain: "clientservercommands.firebaseapp.com",
    projectId: "clientservercommands",
    storageBucket: "clientservercommands.appspot.com",
    messagingSenderId: "139730155045",
    appId: "1:139730155045:web:99eee5865a29f4b34b71cc",
});

const messaging = firebase.messaging();