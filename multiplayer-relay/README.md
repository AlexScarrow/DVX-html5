# DVX Multiplayer Relay (Tiny Post Office)

This folder contains a minimal WebSocket relay server for early multiplayer testing.

## What it does

- Lets clients join a room by `room_id`
- Broadcasts `command` packets to everyone in that room
- Broadcasts `events` packets to everyone in that room
- Sends simple `joined_room`, `player_joined`, `player_left`, `error`, `pong` messages

It does **not** contain game logic; it only relays messages.

## Run locally

```bash
cd multiplayer-relay
npm start
```

Server listens at:

- `ws://localhost:8080`

## Current game config

In `main/game.script`, set:

- `MULTIPLAYER_TRANSPORT_MODE = "websocket"`
- `MULTIPLAYER_TRANSPORT_WS_URL = "ws://127.0.0.1:8080/ws"`
- `MULTIPLAYER_TRANSPORT_ROOM_ID = "dvx_local_room"`

Note: `/ws` path is accepted by the relay server; it uses one websocket endpoint.

## Next step

Replace the websocket adapter stub with a real Defold websocket runtime binding,
then test two clients in the same room.

## Fake friend client (single-computer test)

You can simulate another player from terminal while your game runs:

```bash
cd multiplayer-relay
node fake_player.js --player p2 --room dvx_local_room --ready on
```

Examples:

```bash
# Simulate p3 ready on
node fake_player.js --player p3 --room dvx_local_room --ready on

# Simulate p2 ready off
node fake_player.js --player p2 --room dvx_local_room --ready off
```
