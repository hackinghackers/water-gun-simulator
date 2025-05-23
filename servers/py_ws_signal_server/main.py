from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from contextlib import asynccontextmanager
import logging
from room import GameRoom, GameRoomCfg
from events import (
    SignalEvent,
    JoinRequest,
    JoinResponse,
    SdpEvent,
    IceEvent,
    PeerJoined,
)



@asynccontextmanager
async def lifespan(app: FastAPI):
    global logger
    logger = logging.getLogger("uvicorn.error")
    # logger.handlers.clear()
    handler = logging.StreamHandler()
    logger.addHandler(handler)
    logger.info("Server startup complete — logging configured")
    yield
    logger.info("Server shutdown complete")


app = FastAPI(lifespan=lifespan)
rooms : dict[str, GameRoom] = {}


@app.websocket("/ws/{room_code}")
async def signaling(ws: WebSocket, room_code: str):
    await ws.accept()

    # 1) Ensure the room exists
    if room_code not in rooms:
        rooms[room_code] = GameRoom(code=room_code)
    room = rooms[room_code]

    # 2) Assign a new peer_id and store the socket
    my_pid = room.add_client(ws)

    # 3) Send back a JoinResponse so the client knows its own ID
    join_resp = JoinResponse(
        from_pid=0, 
        to_pid=my_pid,
        room_code=room_code,
    )

    await ws.send_text(join_resp.to_json())
    logger.info(f"Client {my_pid} joined room {room_code}")

    logger.info("Broadcasting new peer joined")
    for i, s in room.sockets.items():
        if s == ws : continue
        pev = PeerJoined(
            from_pid = 0,
            to_pid = i,
            room_code = room_code,
            joined_pid = my_pid,
        )
        await s.send_text(pev.to_json())
        logger.info(f"Notified {i}")

    try:
        # 4) Main loop: receive any event and route it
        while True:
            msg: dict = await ws.receive_json()
            assert isinstance(target := msg.get("to_pid"), int), "to_pid not int"
            target = int(target)
            # Only forward if the target is connected
            if target in room.sockets:
                await room.get_client(target).send_json(msg)
                logger.info(f"Forwarding message from {my_pid} to {target}: {msg}")

    except WebSocketDisconnect:
        # 5) Cleanup on disconnect
        logger.info(f"Client {my_pid} disconnected from room {room_code}")
        del room.sockets[my_pid]
        if not room.sockets:
            # Optionally delete empty rooms
            del rooms[room_code]


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host='localhost', port=1145, lifespan='on', ws='websockets')
