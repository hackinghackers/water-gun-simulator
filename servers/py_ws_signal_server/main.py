from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from contextlib import asynccontextmanager
import logging
from events import (
    SignalEvent,
    JoinRequest,
    JoinResponse,
    SdpEvent,
    IceEvent,
)

from dataclasses import dataclass, field


@asynccontextmanager
async def lifespan(app: FastAPI):
    global logger
    logger = logging.getLogger("uvicorn.access")
    logger.handlers.clear()
    handler = logging.StreamHandler()
    # handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
    logger.addHandler(handler)
    logger.info("Server startup complete — logging configured")
    yield
    logger.info("Server shutdown complete")


@dataclass
class GameRoom: 
    code : str
    next_pid : int = 1 
    sockets : dict[int, WebSocket] = field(default_factory=dict)

    def get_client(self, pid : int) -> WebSocket:
        return self.sockets[pid]
    
    def add_client(self, socket : WebSocket) -> int:
        self.sockets[self.next_pid] = socket
        self.next_pid += 1
        return self.next_pid - 1

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
    uvicorn.run(app, host='localhost', port=1145, lifespan='on', ws='wsproto')
