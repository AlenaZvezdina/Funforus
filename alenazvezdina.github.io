<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Стол</title>
<link href="https://fonts.googleapis.com/css2?family=VT323&display=swap" rel="stylesheet">
<style>
  * { box-sizing: border-box; }
  html, body {
    margin: 0; padding: 0; height: 100%;
    background: #05080A;
    color: #33FF66;
    font-family: "VT323", "Courier New", monospace;
    overflow: hidden;
  }
  #bg {
    position: fixed; top: 0; left: 0;
    width: 100%; height: 100%; z-index: 0;
  }
  .scanlines {
    position: fixed; top: 0; left: 0;
    width: 100%; height: 100%;
    z-index: 3;
    pointer-events: none;
    background: repeating-linear-gradient(
      0deg, rgba(0,0,0,0.18) 0px, rgba(0,0,0,0.18) 1px, transparent 2px, transparent 3px
    );
    mix-blend-mode: multiply;
    animation: flicker 6s infinite;
  }
  @keyframes flicker {
    0%, 96%, 100% { opacity: 1; }
    97% { opacity: 0.85; }
    98% { opacity: 1; }
  }
  .wrap {
    position: relative; z-index: 1;
    display: flex; flex-direction: column; align-items: center;
    min-height: 100%;
    padding: 30px 16px 20px 16px;
    padding-top: calc(30px + env(safe-area-inset-top, 0px));
    padding-bottom: calc(20px + env(safe-area-inset-bottom, 0px));
  }
  .header {
    font-size: 18px;
    letter-spacing: 4px;
    color: #1F8A3E;
    text-transform: uppercase;
    border-bottom: 1px solid #1F8A3E;
    padding-bottom: 6px;
    margin-bottom: 10px;
  }
  #clock {
    font-size: 16vw;
    color: #33FF66;
    text-shadow: 0 0 12px rgba(51,255,102,0.6);
    letter-spacing: 4px;
  }
  #clock .cursor {
    display: inline-block;
    width: 0.5em;
    background: #33FF66;
    animation: blink 1s steps(1) infinite;
  }
  @keyframes blink { 50% { opacity: 0; } }
  #date {
    margin-top: 8px;
    font-size: 22px;
    color: #1F8A3E;
  }
  .panel {
    margin-top: 30px;
    width: 100%;
    max-width: 480px;
    background: rgba(10,18,14,0.9);
    border: 1px solid #1F8A3E;
    padding: 16px;
  }
  .panel h2 {
    margin: 0 0 10px 0;
    font-size: 20px;
    letter-spacing: 3px;
    color: #33FF66;
    text-transform: uppercase;
  }
  .panel h2 .tag {
    color: #1F8A3E;
    font-size: 14px;
    letter-spacing: 1px;
    float: right;
  }
  #noteInput {
    width: 100%;
    background: #05080A;
    border: 1px solid #1F8A3E;
    color: #33FF66;
    font-family: "VT323", monospace;
    font-size: 20px;
    padding: 8px 10px;
    outline: none;
  }
  #noteInput::placeholder { color: #1F8A3E; }
  #notes {
    list-style: none; margin: 12px 0 0 0; padding: 0;
    max-height: 28vh; overflow-y: auto;
  }
  #notes li {
    display: flex; align-items: center; justify-content: space-between; gap: 10px;
    border-bottom: 1px dashed #1F8A3E;
    color: #33FF66;
    padding: 8px 2px;
    font-size: 18px;
  }
  #notes li span { word-break: break-word; }
  #notes li span:before { content: "// "; color: #1F8A3E; }
  #notes li button {
    flex: none;
    background: transparent;
    border: 1px solid #1F8A3E;
    color: #33FF66;
    font-family: "VT323", monospace;
    font-size: 16px;
    cursor: pointer;
    padding: 2px 8px;
  }
  .empty {
    color: #1F8A3E; font-size: 16px; padding: 4px 0;
  }
</style>
</head>
<body>

<canvas id="bg"></canvas>
<div class="scanlines"></div>

<div class="wrap">
  <div class="header">СЕКРЕТНО // ДОСТУП ОГРАНИЧЕН</div>

  <div id="clock">--:-- <span class="cursor">&nbsp;</span></div>
  <div id="date"></div>

  <div class="panel">
    <h2>ДЕЛО <span class="tag">X</span></h2>
    <input id="noteInput" type="text" placeholder="ввести наблюдение...">
    <ul id="notes"></ul>
  </div>
</div>

<script>
(function () {
  "use strict";

  var clockEl = document.getElementById("clock");
  var dateEl = document.getElementById("date");
  var months = ["января","февраля","марта","апреля","мая","июня","июля","августа","сентября","октября","ноября","декабря"];
  var days = ["воскресенье","понедельник","вторник","среда","четверг","пятница","суббота"];

  function pad(n) { return n < 10 ? "0" + n : "" + n; }

  function tick() {
    var d = new Date();
    clockEl.innerHTML = pad(d.getHours()) + ":" + pad(d.getMinutes()) + ' <span class="cursor">&nbsp;</span>';
    dateEl.textContent = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()];
  }
  tick();
  setInterval(tick, 1000 * 10);

  var STORAGE_KEY = "desk_notes_v1";
  var input = document.getElementById("noteInput");
  var list = document.getElementById("notes");
  var notesRef = null;      // set once the online store is ready
  var currentNotes = [];
  var syncing = false;

  function loadLocal() {
    try {
      var raw = window.localStorage.getItem(STORAGE_KEY);
      return raw ? JSON.parse(raw) : [];
    } catch (e) { return []; }
  }
  function saveLocal(notes) {
    try { window.localStorage.setItem(STORAGE_KEY, JSON.stringify(notes)); } catch (e) {}
  }

  function render() {
    list.innerHTML = "";
    if (currentNotes.length === 0) {
      var li = document.createElement("li");
      li.className = "empty";
      li.style.border = "none";
      li.textContent = "нет записей";
      list.appendChild(li);
      return;
    }
    for (var i = 0; i < currentNotes.length; i++) {
      (function (index) {
        var li = document.createElement("li");
        var span = document.createElement("span");
        span.textContent = currentNotes[index];
        var btn = document.createElement("button");
        btn.textContent = "УДАЛИТЬ";
        btn.onclick = function () { removeNote(index); };
        li.appendChild(span);
        li.appendChild(btn);
        list.appendChild(li);
      })(i);
    }
  }

  function persist() {
    if (notesRef) {
      if (syncing) return;
      syncing = true;
      notesRef.set({ items: currentNotes }).catch(function () {}).then(function () {
        syncing = false;
      });
    } else {
      saveLocal(currentNotes);
      render();
    }
  }

  function addNote(val) {
    currentNotes.push(val);
    if (!notesRef) render();
    persist();
  }

  function removeNote(index) {
    currentNotes.splice(index, 1);
    if (!notesRef) render();
    persist();
  }

  input.addEventListener("keydown", function (e) {
    if (e.keyCode === 13 || e.key === "Enter") {
      var val = input.value.replace(/^\s+|\s+$/g, "");
      if (val.length > 0) {
        input.value = "";
        addNote(val);
      }
    }
  });

  // Start from whatever is local so the page is usable instantly,
  // then switch over to the online store once (if) it is available.
  currentNotes = loadLocal();
  render();

  (function initOnlineStore() {
    if (!window.claude || typeof window.claude.use !== "function") return;
    window.claude.use("db").then(function (db) {
      if (!db) return; // no online store available in this view; local storage keeps working
      notesRef = db.doc("notes/list");
      notesRef.onSnapshot(function (snap) {
        var data = snap.exists ? snap.data() : null;
        currentNotes = (data && data.items) || [];
        render();
      }, function () {
        notesRef = null; // subscription died; fall back to local storage
      });
    }).catch(function () {});
  })();

  // ---------- Night sky, flickering stars, sweeping light, drifting UFO ----------
  var canvas = document.getElementById("bg");
  var ctx = canvas.getContext("2d");
  var W, H;

  function resize() {
    W = canvas.width = window.innerWidth;
    H = canvas.height = window.innerHeight;
  }
  resize();
  window.addEventListener("resize", resize);

  var stars = [];
  function seedStars() {
    stars = [];
    var count = Math.floor((W * H) / 9000);
    for (var i = 0; i < count; i++) {
      stars.push({
        x: Math.random() * W,
        y: Math.random() * H,
        r: Math.random() * 1.4 + 0.3,
        phase: Math.random() * Math.PI * 2
      });
    }
  }
  seedStars();
  window.addEventListener("resize", seedStars);

  function drawStars(t) {
    for (var i = 0; i < stars.length; i++) {
      var s = stars[i];
      var a = 0.3 + 0.7 * Math.abs(Math.sin(t * 0.0015 + s.phase));
      ctx.globalAlpha = a;
      ctx.fillStyle = "#33FF66";
      ctx.fillRect(s.x, s.y, s.r, s.r);
    }
    ctx.globalAlpha = 1;
  }

  function drawUFO(x, y) {
    ctx.save();
    ctx.translate(x, y);
    ctx.fillStyle = "#0E2B16";
    ctx.strokeStyle = "#33FF66";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.ellipse(0, 0, 30, 8, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(0, -6, 12, Math.PI, 0);
    ctx.fill();
    ctx.stroke();
    // light beam
    ctx.beginPath();
    ctx.moveTo(-10, 6);
    ctx.lineTo(-40, 90);
    ctx.lineTo(40, 90);
    ctx.lineTo(10, 6);
    ctx.closePath();
    ctx.globalAlpha = 0.12;
    ctx.fillStyle = "#33FF66";
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.restore();
  }

  var ufo = { x: -60, y: 90, v: 0.5 };

  function step(t) {
    ctx.clearRect(0, 0, W, H);
    drawStars(t || 0);

    ufo.x += ufo.v;
    ufo.y = 90 + Math.sin((t || 0) * 0.001) * 20;
    if (ufo.x > W + 60) ufo.x = -60;
    drawUFO(ufo.x, ufo.y);

    window.requestAnimationFrame(step);
  }
  window.requestAnimationFrame(step);

})();
</script>

</body>
</html>
