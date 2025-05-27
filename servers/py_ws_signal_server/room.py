from dataclasses_json import dataclass_json, DataClassJsonMixin
from dataclasses import dataclass, field
from fastapi import WebSocket
@dataclass_json
@dataclass
class GameRoomCfg(DataClassJsonMixin):
    code: str
    name: str
    max_players: int


@dataclass
class GameRoom:
    code: str
    next_pid: int = 2 # in godot, pid=1 is reserved for the server
    sockets: dict[int, WebSocket] = field(default_factory=dict)

    def get_client(self, pid: int) -> WebSocket:
        return self.sockets[pid]

    def add_client(self, socket: WebSocket) -> int:
        self.sockets[self.next_pid] = socket
        self.next_pid += 1
        return self.next_pid - 1
