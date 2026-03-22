const { WebSocketServer } = require("ws");

const PORT = Number(process.env.PORT || 8080);
const MAX_PLAYERS_PER_ROOM = 4;

const rooms = new Map();
const clientState = new Map();

function safeSend(ws, payload) {
  if (!ws || ws.readyState !== ws.OPEN) {
    return;
  }
  ws.send(JSON.stringify(payload));
}

function getOrCreateRoom(roomId) {
  if (!rooms.has(roomId)) {
    rooms.set(roomId, { clients: new Set() });
  }
  return rooms.get(roomId);
}

function getPlayerList(room) {
  const players = [];
  for (const client of room.clients) {
    const state = clientState.get(client);
    if (state && state.playerId) {
      players.push(state.playerId);
    }
  }
  return players;
}

function removeClientFromRoom(ws) {
  const state = clientState.get(ws);
  if (!state || !state.roomId) {
    return;
  }
  const room = rooms.get(state.roomId);
  if (!room) {
    return;
  }
  room.clients.delete(ws);
  for (const client of room.clients) {
    safeSend(client, {
      version: 1,
      type: "player_left",
      payload: { player_id: state.playerId }
    });
  }
  if (room.clients.size === 0) {
    rooms.delete(state.roomId);
  }
}

const wss = new WebSocketServer({ port: PORT });

wss.on("connection", (ws) => {
  clientState.set(ws, {
    roomId: null,
    playerId: null
  });

  safeSend(ws, {
    version: 1,
    type: "hello",
    payload: { server: "dvx-relay", protocol: 1 }
  });

  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(String(raw));
    } catch (err) {
      safeSend(ws, {
        version: 1,
        type: "error",
        payload: { code: "bad_json", message: "Invalid JSON" }
      });
      return;
    }

    if (msg.type === "join_room") {
      const payload = msg.payload || {};
      const roomId = String(payload.room_id || "");
      const playerId = String(payload.player_id || "");
      if (!roomId || !playerId) {
        safeSend(ws, {
          version: 1,
          type: "error",
          payload: { code: "bad_join", message: "room_id and player_id required" }
        });
        return;
      }
      removeClientFromRoom(ws);
      const room = getOrCreateRoom(roomId);
      if (room.clients.size >= MAX_PLAYERS_PER_ROOM) {
        safeSend(ws, {
          version: 1,
          type: "error",
          payload: { code: "room_full", message: "Room is full" }
        });
        return;
      }
      room.clients.add(ws);
      clientState.set(ws, { roomId, playerId });
      safeSend(ws, {
        version: 1,
        type: "joined_room",
        payload: { room_id: roomId, players: getPlayerList(room) }
      });
      for (const client of room.clients) {
        if (client === ws) continue;
        safeSend(client, {
          version: 1,
          type: "player_joined",
          payload: { player_id: playerId }
        });
      }
      return;
    }

    if (msg.type === "leave_room") {
      removeClientFromRoom(ws);
      clientState.set(ws, { roomId: null, playerId: null });
      return;
    }

    if (msg.type === "command") {
      const state = clientState.get(ws);
      if (!state || !state.roomId) {
        safeSend(ws, {
          version: 1,
          type: "error",
          payload: { code: "not_joined", message: "Join a room first" }
        });
        return;
      }
      const room = rooms.get(state.roomId);
      if (!room) {
        return;
      }
      for (const client of room.clients) {
        safeSend(client, {
          version: 1,
          type: "command",
          payload: msg.payload || {}
        });
      }
      return;
    }

    if (msg.type === "events") {
      const state = clientState.get(ws);
      if (!state || !state.roomId) {
        safeSend(ws, {
          version: 1,
          type: "error",
          payload: { code: "not_joined", message: "Join a room first" }
        });
        return;
      }
      const room = rooms.get(state.roomId);
      if (!room) {
        return;
      }
      for (const client of room.clients) {
        safeSend(client, {
          version: 1,
          type: "events",
          payload: msg.payload || []
        });
      }
      return;
    }

    if (msg.type === "ping") {
      safeSend(ws, {
        version: 1,
        type: "pong",
        payload: { ts: Date.now() }
      });
      return;
    }

    safeSend(ws, {
      version: 1,
      type: "error",
      payload: { code: "unknown_type", message: "Unknown message type" }
    });
  });

  ws.on("close", () => {
    removeClientFromRoom(ws);
    clientState.delete(ws);
  });
});

console.log(`DVX relay listening on ws://localhost:${PORT}`);
console.log("Relay accepts websocket upgrade on any path (e.g. / or /ws).");
