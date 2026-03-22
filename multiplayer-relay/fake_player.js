const WebSocket = require("ws");

function getArg(name, fallback) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1 || idx + 1 >= process.argv.length) {
    return fallback;
  }
  return process.argv[idx + 1];
}

const wsUrl = getArg("url", "ws://127.0.0.1:8080/ws");
const roomId = getArg("room", "dvx_local_room");
const playerId = getArg("player", "p2");
const readyArg = String(getArg("ready", "on")).toLowerCase();
const readyOn = readyArg === "on" || readyArg === "true" || readyArg === "1";
const sessionId = getArg("session", "local_session");

console.log(`[fake_player] connecting url=${wsUrl} room=${roomId} player=${playerId} ready=${readyOn}`);

const ws = new WebSocket(wsUrl);

let sentReady = false;

function send(type, payload) {
  ws.send(JSON.stringify({
    version: 1,
    type,
    payload
  }));
}

ws.on("open", () => {
  send("join_room", {
    room_id: roomId,
    player_id: playerId
  });
});

ws.on("message", (raw) => {
  let msg = null;
  try {
    msg = JSON.parse(String(raw));
  } catch (err) {
    console.log("[fake_player] non-json message ignored");
    return;
  }

  if (msg.type === "joined_room" && !sentReady) {
    send("command", {
      version: 1,
      session_id: sessionId,
      sender_player_id: playerId,
      type: "set_ready",
      payload: {
        player_id: playerId,
        ready: readyOn
      },
      message_id: `fake_${playerId}_${Date.now()}`
    });
    sentReady = true;
    console.log(`[fake_player] sent set_ready=${readyOn} for ${playerId}`);
    setTimeout(() => {
      send("leave_room", {
        room_id: roomId,
        player_id: playerId
      });
      ws.close();
    }, 250);
    return;
  }

  if (msg.type === "error") {
    console.log("[fake_player] server error:", msg.payload);
  }
});

ws.on("close", () => {
  console.log("[fake_player] done.");
});

ws.on("error", (err) => {
  console.log("[fake_player] websocket error:", err.message);
});
